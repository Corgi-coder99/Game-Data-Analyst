extends SceneTree
# T-030 headless tests, part 1: the meta layer with an injected clock and temporary profile files.
# Run: --headless -s res://tests/test_t030_meta.gd
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Profile = preload("res://scripts/meta/profile.gd")
const Awards = preload("res://scripts/meta/awards.gd")
const InputLog = preload("res://scripts/meta/input_log.gd")
const LocalDaySource = preload("res://scripts/meta/local_day_source.gd")
const Life = preload("res://scripts/life/life_game.gd")
const Game = preload("res://scripts/world/world_game.gd")
const PATH := "user://t030_test_profile.json"
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func wipe() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func fresh(date: String) -> RefCounted:
	wipe()
	return Meta.new(PATH, Clock.new(date))

# A public day record without running the game: used to drive streaks, scores and awards.
func record(meta: RefCounted, date: String, index: int, accuracy: float = 1.0, timing: String = "on_time", confidence: String = "vua", rank: String = "thuc_tap", evidence_quality: float = 1.0, bonus: int = 0, delta: float = 4.0) -> Dictionary:
	var result := {"accuracy": accuracy, "evidence_quality": evidence_quality, "trust_delta": delta, "timing": timing, "pay": 100, "bonus": bonus, "rank": rank, "trust": 50}
	result["day_score"] = Awards.day_score(result, meta.cfg)
	var submission := {"question_id": "q1", "forecast": "tang", "confidence": confidence, "evidence": ["d1-a"], "actions": []}
	return InputLog.build("run", date, 1000 + index, index, submission, 570, {"focus_bonus": 0, "late_minutes": 0}, result)

func finish(meta: RefCounted, date: String, index: int = 1, accuracy: float = 1.0, timing: String = "on_time", confidence: String = "vua", rank: String = "thuc_tap") -> Dictionary:
	meta.clock.set_today(date)
	return meta.sink.submit_day(record(meta, date, index, accuracy, timing, confidence, rank))

func run() -> void:
	test_clock()
	test_profile_files()
	test_names()
	test_streaks()
	test_leave()
	test_ladder_steps()
	test_ladder_rules()
	test_fine_applied_once()
	test_rehire_keeps_history()
	test_employee_of_month()
	test_achievements_and_hall()
	test_daily_seed()
	test_input_log()
	test_meta_off_score_and_leak()
	wipe()
	print("test_t030_meta: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_clock() -> void:
	check(Clock.to_days("1970-01-01") == 0, "epoch is day 0")
	check(Clock.from_days(0) == "1970-01-01", "day 0 is the epoch")
	for date in ["2024-02-29", "2026-11-10", "2026-12-31", "2027-01-01", "2100-02-28", "2000-03-01"]:
		check(Clock.from_days(Clock.to_days(date)) == date, "round trip " + date)
	check(Clock.add_days("2024-02-28", 2) == "2024-03-01", "leap year Feb 29 exists")
	check(Clock.add_days("2026-02-28", 1) == "2026-03-01", "non leap year")
	check(Clock.add_days("2026-12-31", 1) == "2027-01-01", "year rollover")
	check(Clock.diff("2026-11-10", "2026-11-15") == 5 and Clock.diff("2026-11-15", "2026-11-10") == -5, "diff")
	check(Clock.month_key("2026-11-10") == "2026-11" and Clock.month_name("2026-11") == "Nov 2026", "month key and name")
	check(Clock.is_valid("2026-02-28") and not Clock.is_valid("2026-02-29") and not Clock.is_valid("2026-13-01") and not Clock.is_valid("nope") and Clock.is_valid("2024-02-29"), "date validation")
	var clock := Clock.new("2026-11-10")
	check(clock.today() == "2026-11-10", "fixed clock")
	clock.advance(25)
	check(clock.today() == "2026-12-05", "clock advance")
	check(Clock.is_valid(Clock.new().today()), "the real clock gives a valid date")

func test_profile_files() -> void:
	var meta := fresh("2026-11-10")
	check(meta.profile.load_status == "new" and meta.profile.data.display_name == "Analyst" and meta.profile.data.created == "2026-11-10", "new profile defaults")
	check(meta.profile.data.version == 1 and meta.profile.data.settings.attendance == true and meta.profile.data.reputation == 0, "default fields")
	meta.profile.data.display_name = "Nova"
	meta.profile.data.reputation = 42
	meta.profile.data.achievements["first_report"] = "2026-11-10"
	check(meta.profile.save() and FileAccess.file_exists(PATH), "save writes the file")
	check(not FileAccess.file_exists(PATH + ".tmp"), "no temp file left behind")
	var again := Meta.new(PATH, Clock.new("2026-11-10"))
	check(again.profile.load_status == "ok" and again.profile.data.display_name == "Nova" and again.profile.data.reputation == 42 and again.profile.data.achievements.has("first_report"), "load restores values")
	check(typeof(again.profile.data.reputation) == TYPE_INT, "numbers come back as integers")
	# Corrupt file: text that is not JSON.
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{this is not json")
	file.close()
	var corrupt := Meta.new(PATH, Clock.new("2026-11-11"))
	check(corrupt.profile.load_status == "corrupt" and corrupt.profile.data.display_name == "Analyst" and corrupt.profile.data.created == "2026-11-11", "corrupt file gives a fresh profile")
	check(FileAccess.file_exists(PATH + ".bak") and not FileAccess.file_exists(PATH), "corrupt file kept as .bak")
	# Wrong shapes and types: tolerated field by field.
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "display_name": 7, "reputation": "many", "streak": 3.0, "history": "no", "settings": {"attendance": "yes", "quiet_start": 5}, "leave": [{"date": "2026-11-12", "reason": "cat"}, 4], "extra": 1}))
	file.close()
	var odd := Meta.new(PATH, Clock.new("2026-11-10"))
	check(odd.profile.load_status == "ok" and odd.profile.data.display_name == "Analyst" and odd.profile.data.reputation == 0 and odd.profile.data.streak == 3, "wrong types fall back, good fields kept")
	check(odd.profile.data.history == [] and odd.profile.data.settings.attendance == true and odd.profile.data.settings.quiet_start == 5 and not odd.profile.data.has("extra"), "bad history, bool and unknown keys handled")
	check(odd.profile.data.leave.size() == 1, "non-dictionary leave entries dropped")
	# Empty file and a JSON array.
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[1,2]")
	file.close()
	check(Meta.new(PATH, Clock.new("2026-11-10")).profile.load_status == "corrupt", "a JSON array is corrupt")
	# Reset deletes the file.
	var meta2 := fresh("2026-11-10")
	meta2.profile.data.reputation = 9
	meta2.profile.save()
	meta2.reset_profile()
	check(meta2.profile.data.reputation == 0 and meta2.profile.data.history.is_empty(), "reset clears the profile")
	check(Meta.new(PATH, Clock.new("2026-11-10")).profile.data.reputation == 0, "reset persists")
	# The file holds no personal data beyond the display name.
	var text := FileAccess.get_file_as_string(PATH)
	check(not text.contains("@") and not text.to_lower().contains("email") and not text.to_lower().contains("password"), "profile file has no email or password fields")

func test_names() -> void:
	var meta := fresh("2026-11-10")
	var profile: RefCounted = meta.profile
	check(profile.clean_name("  Nova Star  ") == "Nova Star", "trim")
	check(profile.clean_name("") == "Analyst" and profile.clean_name("   ") == "Analyst", "empty gives default")
	check(profile.clean_name("me@mail.com") == "Analyst", "an email is never stored as a name")
	check(profile.clean_name("A<b>c;d") == "Abcd", "symbols dropped")
	check(profile.clean_name("ABCDEFGHIJKLMNOPQRSTUVWXYZ").length() == 16, "limited to 16 characters")
	check(profile.set_name("Rio") == "Rio" and profile.data.display_name == "Rio", "set_name")

func test_streaks() -> void:
	var meta := fresh("2026-11-10")
	check(meta.attendance.register_finished_day().streak == 1, "first day: streak 1")
	check(meta.attendance.register_finished_day().new_day == false, "same day twice does not count")
	meta.clock.set_today("2026-11-11")
	check(meta.attendance.register_finished_day().streak == 2, "next day: streak 2")
	meta.clock.set_today("2026-11-12")
	meta.attendance.register_finished_day()
	check(meta.profile.data.streak == 3 and meta.profile.data.best_streak == 3, "streak 3, best 3")
	# One missed day without leave or freeze breaks the streak.
	meta.clock.set_today("2026-11-14")
	check(meta.attendance.register_finished_day().streak == 1 and meta.profile.data.best_streak == 3, "a gap resets the streak but not the best")
	# A leave day on the gap keeps it.
	var covered := fresh("2026-12-01")
	covered.attendance.register_finished_day()
	check(covered.request_leave("2026-12-02", 1, "cat").ok, "book leave for tomorrow")
	covered.clock.set_today("2026-12-03")
	check(covered.attendance.register_finished_day().streak == 2, "a leave-covered gap keeps the streak")
	# Streak freeze: earned at 7, bridges one missed day.
	var freeze := fresh("2026-12-01")
	for i in 7:
		freeze.clock.set_today(Clock.add_days("2026-12-01", i))
		var info: Dictionary = freeze.attendance.register_finished_day()
		check(info.freeze_earned == (i == 6), "freeze earned only on day 7 (day %d)" % (i + 1))
	check(freeze.profile.data.freezes == 1 and freeze.profile.data.streak == 7, "7-day streak gives one freeze")
	freeze.clock.set_today("2026-12-09")
	var bridged: Dictionary = freeze.attendance.register_finished_day()
	check(bridged.frozen and bridged.streak == 8 and freeze.profile.data.freezes == 0, "the freeze bridges one missed day and is consumed")
	freeze.clock.set_today("2026-12-12")
	check(freeze.attendance.register_finished_day().streak == 1, "no freeze left: the streak breaks")
	# A freeze does not bridge two missed days.
	var two := fresh("2026-12-01")
	for i in 7:
		two.clock.set_today(Clock.add_days("2026-12-01", i))
		two.attendance.register_finished_day()
	two.clock.set_today("2026-12-10")
	check(two.attendance.register_finished_day().streak == 1 and two.profile.data.freezes == 1, "two missed days are not bridged and the freeze stays")
	# Freezes are capped.
	var cap := fresh("2026-12-01")
	for i in 22:
		cap.clock.set_today(Clock.add_days("2026-12-01", i))
		cap.attendance.register_finished_day()
	check(cap.profile.data.freezes == 2, "freezes capped at 2: %d" % cap.profile.data.freezes)

func test_leave() -> void:
	var meta := fresh("2026-11-10")
	check(meta.request_leave("2026-11-10", 1, "cat").ok, "leave for today is allowed")
	check(not meta.request_leave("2026-11-09", 1, "cat").ok and meta.request_leave("2026-11-09", 1, "cat").error == "past", "leave in the past is refused")
	check(meta.request_leave("2026-11-12", 0, "cat").error == "bad_days" and meta.request_leave("2026-11-12", 4, "cat").error == "bad_days", "1 to 3 days only")
	check(meta.request_leave("2026-11-12", 1, "nonsense").error == "bad_reason", "reason must come from the list")
	check(meta.request_leave("2026-12-30", 1, "cat").error == "too_far", "at most 14 days ahead")
	check(meta.request_leave("2026-13-40", 1, "cat").error == "bad_date", "bad date")
	check(meta.attendance.leave_left("2026-11-20") == 2, "2 of 3 left after one day")
	check(meta.request_leave("2026-11-11", 2, "tooth").ok and meta.attendance.leave_left("2026-11-20") == 0, "allowance used up")
	check(meta.request_leave("2026-11-14", 1, "plant").error == "allowance", "monthly allowance of 3 is enforced")
	check(meta.profile.data.leave.size() == 3, "a refused request books nothing")
	# Booking days already covered costs nothing.
	check(meta.request_leave("2026-11-10", 1, "cat").ok and meta.profile.data.leave.size() == 3, "re-booking a covered day is free")
	# Across a month boundary: counted per month.
	var edge := fresh("2026-11-28")
	check(edge.request_leave("2026-11-29", 3, "nap").ok, "3 days over 29, 30 Nov, 1 Dec")
	check(edge.attendance.leave_used("2026-11") == 2 and edge.attendance.leave_used("2026-12") == 1, "days counted in their own month")
	check(edge.attendance.leave_left("2026-12-05") == 2, "December has 2 left")
	check(edge.profile.data.leave[0].reason == "nap", "reason stored")
	check(edge.cfg.leave_reasons.size() >= 6, "a list of reasons")

func ladder_meta(missed: int, rep: int = 100) -> RefCounted:
	var meta := fresh("2026-12-01")
	meta.profile.data.last_finished_day = "2026-12-01"
	meta.profile.data.reputation = rep
	meta.profile.data.streak = 5
	meta.clock.set_today(Clock.add_days("2026-12-01", missed + 1))
	return meta

func test_ladder_steps() -> void:
	# Missed days -> expected step, reputation loss, fine added to the pending fine, bonus.
	var table := [[0, "", 0, 0, 0], [1, "reminder", 0, 0, 0], [2, "warning", 2, 0, 0], [3, "fine", 5, 6, 5], [4, "fine", 5, 6, 5], [5, "formal", 10, 9, 5], [6, "formal", 10, 9, 5], [7, "termination", 20, 12, 8], [8, "rehire", 30, 12, 10], [15, "rehire", 30, 12, 10]]
	for row in table:
		var meta := ladder_meta(row[0])
		var letter: Dictionary = meta.attendance.evaluate()
		if row[1] == "":
			check(letter.is_empty(), "no missed day: no letter")
			continue
		check(letter.step == row[1] and letter.missed == row[0], "missed %d -> %s (got %s)" % [row[0], row[1], str(letter.get("step"))])
		check(meta.profile.data.reputation == 100 - row[2] and letter.rep_loss == row[2], "missed %d: reputation loss %d (rep %d)" % [row[0], row[2], meta.profile.data.reputation])
		check(meta.profile.data.pending_fine == row[3] and letter.fine == row[3], "missed %d: fine %d (pending %d)" % [row[0], row[3], meta.profile.data.pending_fine])
		check(meta.profile.data.pending_bonus == row[4], "missed %d: welcome back bonus %d" % [row[0], row[4]])
	# Rehire flags.
	var rehired := ladder_meta(9)
	var letter: Dictionary = rehired.attendance.evaluate()
	check(letter.rehired and rehired.profile.data.title == "Intern" and rehired.profile.data.streak == 0 and rehired.profile.data.stats.rehired == 1, "8+ days: rehired as Intern, streak 0")
	var screen: Dictionary = rehired.letter_screen(letter)
	check(screen.type == "letter" and screen.effects.size() >= 3 and screen.from != "" and screen.body != "", "letter screen text built: " + str(screen.effects))

func test_ladder_rules() -> void:
	# Once per step: a second evaluation the same day is empty, a later day with a higher step applies the new step.
	var meta := ladder_meta(2)
	check(meta.attendance.evaluate().step == "warning", "warning at 2 missed days")
	check(meta.attendance.evaluate().is_empty(), "the same step is not applied twice")
	meta.clock.advance(1)
	check(meta.attendance.evaluate().step == "fine" and meta.profile.data.pending_fine == 6, "next day: the fine step")
	meta.clock.advance(1)
	check(meta.attendance.evaluate().is_empty(), "4 missed days: still the fine step, nothing new")
	meta.clock.advance(1)
	check(meta.attendance.evaluate().step == "formal" and meta.profile.data.pending_fine == 15, "5 missed days: formal warning, fines add up")
	meta.clock.advance(2)
	var termination: Dictionary = meta.attendance.evaluate()
	check(termination.step == "termination" and meta.profile.data.pending_fine == 20 and termination.fine == 5, "fines are capped at 20 in total: " + str(meta.profile.data.pending_fine))
	# Reputation never goes below zero.
	var floor_meta := ladder_meta(2, 1)
	floor_meta.attendance.evaluate()
	check(floor_meta.profile.data.reputation == 0, "reputation floor is 0")
	var zero := ladder_meta(8, 0)
	zero.attendance.evaluate()
	check(zero.profile.data.reputation == 0, "reputation stays 0")
	# Leave days reduce the missed count.
	var leave := ladder_meta(3)
	leave.profile.data.leave.append({"date": "2026-12-02", "reason": "cat"})
	leave.profile.data.leave.append({"date": "2026-12-03", "reason": "cat"})
	check(leave.attendance.missed_days(leave.clock.today()) == 1 and leave.attendance.evaluate().step == "reminder", "covered days are not missed")
	var all_covered := ladder_meta(2)
	all_covered.profile.data.leave.append({"date": "2026-12-02", "reason": "cat"})
	all_covered.profile.data.leave.append({"date": "2026-12-03", "reason": "cat"})
	check(all_covered.attendance.evaluate().is_empty(), "everything covered: no letter")
	# A day finished today means nothing is missed.
	var played := ladder_meta(5)
	played.profile.data.last_finished_day = played.clock.today()
	check(played.attendance.evaluate().is_empty(), "played today: no letter")
	var yesterday := ladder_meta(0)
	check(yesterday.attendance.missed_days(yesterday.clock.today()) == 0, "played yesterday: 0 missed")
	# The mechanic can be switched off.
	var off := ladder_meta(9)
	off.set_attendance(false)
	check(off.attendance.evaluate().is_empty() and off.profile.data.reputation == 100 and off.profile.data.pending_fine == 0, "attendance warnings OFF: nothing happens")
	off.set_attendance(true)
	check(off.attendance.evaluate().step == "rehire", "switched on again")
	# A brand-new profile has no ladder.
	var new_player := fresh("2026-12-01")
	check(new_player.attendance.evaluate().is_empty() and new_player.pre_run_screens().size() == 1, "new profile: only the intro screen")
	check(new_player.pre_run_screens().is_empty(), "the intro is shown once")
	# Letter text: at least 6 lines per step, English, no real-life shaming words.
	for step in ["reminder", "warning", "fine", "formal", "termination", "rehire"]:
		var lines: Array = new_player.cfg.letters[step].lines
		check(lines.size() >= 6, "%s has %d lines" % [step, lines.size()])
		for line in lines: check(str(line).length() > 20 and str(line).length() < 190, "letter line length ok: " + str(line).substr(0, 24))
	# pre_run_screens: the letter comes after the intro and is saved.
	var both := ladder_meta(3)
	var screens: Array = both.pre_run_screens()
	check(screens.size() == 2 and screens[0].type == "intro" and screens[1].type == "letter" and screens[1].step == "fine", "intro then letter")
	check(Meta.new(PATH, Clock.new(both.clock.today())).profile.data.ladder.step == "fine", "applied step is saved")

func test_fine_applied_once() -> void:
	var meta := ladder_meta(5)
	meta.attendance.evaluate()
	check(meta.profile.data.pending_fine == 9 and meta.profile.data.pending_bonus == 5, "pending fine 9 and bonus 5")
	var life := Life.new(3)
	life.enable_daily()
	check(life.wallet == 60, "start wallet is 60")
	var applied: Dictionary = meta.begin_run(life)
	check(applied.fine == 9 and applied.bonus == 5 and life.wallet == 56, "wallet 60 + 5 - 9 = 56: %d" % life.wallet)
	check(life.net_worth() == life.ledger_total() and life.net_worth() == 56, "ledger stays consistent")
	check(meta.profile.data.pending_fine == 0 and meta.profile.data.pending_bonus == 0, "pending values cleared")
	var life2 := Life.new(4)
	life2.enable_daily()
	var second: Dictionary = meta.begin_run(life2)
	check(second.fine == 0 and second.bonus == 0 and life2.wallet == 60, "the next run is untouched: fine applied once")
	check(Meta.new(PATH, Clock.new(meta.clock.today())).profile.data.pending_fine == 0, "cleared values are saved")

func test_rehire_keeps_history() -> void:
	var meta := fresh("2026-11-01")
	for i in 3: finish(meta, Clock.add_days("2026-11-01", i), i + 1)
	var count: int = meta.profile.data.history.size()
	var reputation: int = meta.profile.data.reputation
	check(count == 3 and reputation > 0, "three days of history, reputation %d" % reputation)
	meta.clock.set_today("2026-11-20")
	var letter: Dictionary = meta.attendance.evaluate()
	check(letter.step == "rehire" and letter.rehired, "17 days away: rehired")
	check(meta.profile.data.history.size() == count and meta.profile.data.display_name == "Analyst" and meta.profile.data.created == "2026-11-01", "history, name and creation date are kept")
	check(meta.profile.data.reputation == reputation - letter.rep_loss and meta.profile.data.title == "Intern", "reputation reduced, title Intern")
	check(FileAccess.file_exists(PATH), "the profile file is never deleted")
	finish(meta, "2026-11-20", 4)
	check(meta.profile.data.streak == 1 and meta.profile.data.best_streak == 3, "streak restarts, best kept")

func test_employee_of_month() -> void:
	# pick_winner: sum of the best n days; ties by accuracy; then by name.
	var a := {"name": "Ann", "days": [{"score": 100, "accuracy": 1.0}, {"score": 90, "accuracy": 1.0}, {"score": 10, "accuracy": 0.0}]}
	var b := {"name": "Ben", "days": [{"score": 95, "accuracy": 0.4}, {"score": 95, "accuracy": 0.4}, {"score": 50, "accuracy": 0.4}]}
	check(Awards.pick_winner([a, b], 2).name == "Ben" or Awards.pick_winner([a, b], 2).name == "Ann", "winner exists")
	check(Awards.pick_winner([a, b], 2).score == 190, "best 2 days of Ann = 190 vs Ben 190 (tie)")
	check(Awards.pick_winner([a, b], 2).name == "Ann", "tie on score goes to higher accuracy: Ann")
	check(Awards.pick_winner([a, b], 3).name == "Ben", "best 3 days: Ben 240 beats Ann 200")
	var c := {"name": "Cy", "days": [{"score": 100, "accuracy": 1.0}, {"score": 90, "accuracy": 1.0}]}
	var d := {"name": "Abe", "days": [{"score": 100, "accuracy": 1.0}, {"score": 90, "accuracy": 1.0}]}
	check(Awards.pick_winner([c, d], 2).name == "Abe", "full tie: alphabetical name")
	check(Awards.pick_winner([{"name": "X", "days": []}], 10).is_empty(), "no days: no winner")
	# The best N days of a month by score; N is configurable.
	var meta := fresh("2026-10-01")
	for i in 12:
		var date := Clock.add_days("2026-10-01", i)
		meta.clock.set_today(date)
		var accuracy := 1.0 if i % 2 == 0 else 0.0
		meta.sink.submit_day(record(meta, date, i + 1, accuracy, "on_time", "vua", "thuc_tap", 1.0, 0, 4.0 if accuracy > 0 else -6.0))
	check(meta.profile.data.winners.is_empty(), "no winner while the month is running")
	meta.clock.set_today("2026-11-01")
	meta.sink.submit_day(record(meta, "2026-11-01", 20))
	check(meta.profile.data.winners.size() == 1, "the winner appears at month rollover")
	var winner: Dictionary = meta.profile.data.winners[0]
	var winners_days: Array = meta.profile.data.history.filter(func(r): return r.date.begins_with("2026-10"))
	var scores: Array = winners_days.map(func(r): return r.result.day_score)
	scores.sort()
	scores.reverse()
	var expected := 0
	for i in 10: expected += int(scores[i])
	check(winner.month == "2026-10" and winner.days == 10 and winner.score == expected, "best 10 of 12 days: %d vs %d" % [winner.score, expected])
	check(winner.title == "Employee of the Month" and winner.name == "Analyst" and meta.cfg.avatars.has(winner.avatar), "winner plaque fields")
	meta.clock.set_today("2026-11-05")
	meta.sink.submit_day(record(meta, "2026-11-05", 21))
	check(meta.profile.data.winners.size() == 1, "the month is settled once")
	# Rollover at load time and an empty month in between.
	var later := Meta.new(PATH, Clock.new("2027-02-03"))
	check(later.profile.data.winners.size() == 2 and later.profile.data.winners[1].month == "2026-11", "loading in a later month settles November (December and January had no days)")
	check(Meta.new(PATH, Clock.new("2027-02-03")).profile.data.winners.size() == 2, "winners are permanent")

func test_achievements_and_hall() -> void:
	var meta := fresh("2026-11-01")
	var out: Dictionary = finish(meta, "2026-11-01", 1, 1.0, "on_time", "cao")
	check(out.toasts.has("Achievement: First Report") and out.toasts.has("Achievement: Perfect Day") and out.toasts.has("Achievement: Verified Before Reporting"), "first day toasts: " + str(out.toasts))
	check(meta.profile.data.achievements.size() == 3, "three achievements after day one")
	var second: Dictionary = finish(meta, "2026-11-02", 2, 1.0, "on_time", "cao")
	check(second.toasts.is_empty(), "achievements trigger only once")
	var dup: Dictionary = meta.sink.submit_day(record(meta, "2026-11-02", 2))
	check(dup.duplicate and meta.profile.data.history.size() == 2, "the same day id is not logged twice")
	for i in range(2, 7): finish(meta, Clock.add_days("2026-11-01", i), i + 1, 1.0, "on_time", "cao")
	check(meta.profile.data.achievements.has("zero_late_week") and meta.profile.data.achievements.has("streak_7"), "7 days on time give Zero Late Week and the 7-Day Streak")
	check(meta.profile.data.freezes == 1, "and a streak freeze")
	check(not meta.profile.data.achievements.has("senior") and not meta.profile.data.achievements.has("survived_10"), "senior and survived not yet")
	finish(meta, "2026-11-08", 8, 1.0, "on_time", "cao", "chuyen_vien_chinh")
	check(meta.profile.data.achievements.has("senior"), "Promoted to Senior")
	var run_out: Dictionary = meta.finish_run({"ending": "survived"})
	check(run_out.toasts.has("Achievement: Survived 10 Days") and meta.profile.data.stats.runs_survived == 1, "Survived 10 Days at the end of a run")
	check(meta.finish_run({"ending": "survived"}).toasts.is_empty(), "and only once")
	check(meta.profile.data.achievements.size() == meta.cfg.achievements.size(), "all seven earned")
	# The hall of awards.
	var hall: Array = Awards.hall(meta.profile.data, meta.cfg)
	var by_id := {}
	for item in hall: by_id[item.id] = item
	check(hall.size() == 5 and by_id.streak.earned and by_id.streak.value == "8 days", "longest streak plaque")
	check(by_id.rank.earned and by_id.rank.value == "Senior Analyst", "highest rank plaque")
	check(by_id.best_day.earned and by_id.honest.earned and not by_id.never_late.earned, "best day, honest earned; never late needs 10")
	for i in range(8, 10): finish(meta, Clock.add_days("2026-11-01", i), i + 1, 1.0, "on_time", "cao")
	check(Awards.hall(meta.profile.data, meta.cfg)[4].earned, "Never Late after 10 on-time days")
	# A new profile has only locked plaques.
	var empty: Array = Awards.hall(fresh("2026-11-01").profile.data, meta.cfg)
	check(empty.all(func(item): return not item.earned), "locked plaques for a new profile")
	# Honest needs a good rate with high confidence.
	var wrong := fresh("2026-11-01")
	for i in 4: finish(wrong, Clock.add_days("2026-11-01", i), i + 1, 0.0 if i < 2 else 1.0, "on_time", "cao")
	check(not Awards.hall(wrong.profile.data, wrong.cfg)[3].earned, "2 of 4 right is not Most Honest Analyst")
	# Day score: a late report scores lower than an on-time one.
	var on_time := Awards.day_score({"accuracy": 1.0, "trust_delta": 4.0, "bonus": 0, "timing": "on_time"}, meta.cfg)
	var late := Awards.day_score({"accuracy": 1.0, "trust_delta": 4.0, "bonus": 0, "timing": "late"}, meta.cfg)
	check(on_time == 120 and late == 115, "day score: %d / %d" % [on_time, late])

func test_daily_seed() -> void:
	var a := LocalDaySource.seed_for_date("2026-11-10")
	check(a == LocalDaySource.seed_for_date("2026-11-10"), "same date, same seed")
	var seen := {}
	for i in 120: seen[LocalDaySource.seed_for_date(Clock.add_days("2026-11-10", i))] = true
	check(seen.size() == 120, "120 consecutive dates give 120 different seeds")
	check(a >= 0 and a < 1000000, "seed in the usual range: %d" % a)
	var meta := fresh("2026-11-10")
	var other := Meta.new(PATH, Clock.new("2026-11-10"))
	check(meta.daily_seed() == other.daily_seed() and meta.daily_seed() == a, "two players on the same date get the same seed")
	meta.clock.advance(1)
	check(meta.daily_seed() != a, "the next date differs")
	var scenario_a := Game.new(a, 10)
	var scenario_b := Game.new(LocalDaySource.seed_for_date("2026-11-10"), 10)
	scenario_a.begin_day()
	scenario_b.begin_day()
	check(scenario_a.question_today() == scenario_b.question_today() and JSON.stringify(scenario_a.news_today()) == JSON.stringify(scenario_b.news_today()), "the same seed gives the same question and news")

func play_day(game: RefCounted, forecast: String = "tang") -> Dictionary:
	game.begin_day()
	var uid: String = game.news_today()[0].uid
	var submission := {"question_id": game.question_today().id, "forecast": forecast, "confidence": "vua", "evidence": [uid], "actions": []}
	var before: Dictionary = game.status()
	game.submit_report(submission)
	var pre: Dictionary = game.status()
	game.end_day()
	return {"submission": submission, "before": pre, "after": game.status(), "day": int(game.status().day), "start": before}

func test_input_log() -> void:
	var meta := fresh("2026-11-10")
	var game := Game.new(77, 10)
	var played := play_day(game)
	var out: Dictionary = meta.finish_day(game, played.day, played.submission, played.before, played.after, {"focus_bonus": 1, "late_minutes": 12}, "run", 77)
	var record_out: Dictionary = out.record
	check(InputLog.is_valid(record_out), "the record matches the schema")
	check(record_out.day_id == "run:77:1" and record_out.inputs.forecast == "tang" and record_out.inputs.evidence == [played.submission.evidence[0]] and record_out.context.late_minutes == 12 and record_out.context.focus_bonus == 1, "inputs and context stored")
	check(record_out.result.timing in ["on_time", "late", "missed"] and record_out.result.rank == played.after.rank, "public result parts stored")
	check(meta.profile.data.history.size() == 1 and meta.profile.data.history[0] == record_out, "the record is in the profile history")
	var line := InputLog.to_line(record_out)
	check(InputLog.from_line(line) == record_out, "JSON line round trip is exact")
	var reloaded := Meta.new(PATH, Clock.new("2026-11-10"))
	check(reloaded.profile.data.history[0] == record_out, "the saved profile history round trips")
	check(InputLog.day_id("daily", "2026-11-10", 5, 3) == "daily:2026-11-10:3", "daily day id uses the date")
	var bad: Dictionary = record_out.duplicate(true)
	bad["answer"] = "tang"
	check(not InputLog.is_valid(bad), "an extra key is rejected by the schema check")
	# Leak probe: nothing from the hidden review is in the record or the profile file.
	var review: Dictionary = game.review(played.day)
	var text := FileAccess.get_file_as_string(PATH) + line
	for key in ["answer", "original_answer", "shocks", "news", "states", "truth", "root_cause", "volatile", "shifted", "verification"]:
		check(not text.contains("\"" + key + "\""), "no '%s' key in the stored data" % key)
	for headline in review.news: check(not text.contains(str(headline.headline)), "no news headline text in the stored data")
	for shock in review.shocks: check(not text.contains(str(shock.get("root_cause", "@@"))), "no root cause text in the stored data")

func test_meta_off_score_and_leak() -> void:
	# The same reports score the same with the meta layer on or off.
	for seed_value in [21, 22, 23]:
		var plain := Game.new(seed_value, 10)
		var tracked := Game.new(seed_value, 10)
		var meta := fresh("2026-11-10")
		for day in 10:
			var forecast: String = ["tang", "giam", "ngang"][day % 3]
			play_day(plain, forecast)
			var played := play_day(tracked, forecast)
			meta.clock.advance(1)
			meta.finish_day(tracked, played.day, played.submission, played.before, played.after, {"focus_bonus": 0, "late_minutes": 0}, "run", seed_value)
		check(plain.status().score == tracked.status().score and plain.status().trust == tracked.status().trust, "seed %d: score identical with meta on and off" % seed_value)
		check(meta.profile.data.history.size() == int(tracked.status().day) and meta.profile.data.stats.days_total == int(tracked.status().day), "every played day is logged (%d)" % int(tracked.status().day))
	# Source scan of the meta layer.
	var banned := ["_scenario", "_answers", "root_cause", "_late_plan", "_reviews", ".review(", "hidden", "truth", "volatile", "_news", "_sim", "_career"]
	for filename in DirAccess.get_files_at("res://scripts/meta"):
		if not filename.ends_with(".gd"): continue
		var source := FileAccess.get_file_as_string("res://scripts/meta/" + filename)
		if filename == "local_day_source.gd":
			check(source.count(".review(") == 1, "only local_day_source.gd calls review(), once")
			for word in ["_scenario", "_answers", "root_cause", "_late_plan", "_reviews", "volatile", "original_answer", "review.answer", "review.news", "review.shocks", "review.states", "_news", "_sim", "_career"]:
				check(not source.contains(word), "local_day_source.gd does not touch " + word)
		else:
			for word in banned: check(not source.contains(word), "%s does not touch %s" % [filename, word])
	for filename in ["letter_scene.gd", "wall_scene.gd", "settings_scene.gd", "leave_scene.gd", "toast.gd"]:
		var source := FileAccess.get_file_as_string("res://scripts/v2/" + filename)
		for word in banned: check(not source.contains(word), "%s does not touch %s" % [filename, word])
		for word in ["truth", "kind", "link", "scenario", "states", "reliability"]:
			var pattern := RegEx.new()
			pattern.compile("\\b" + word + "\\b")
			check(pattern.search(source) == null, "%s excludes the v2 scan word %s" % [filename, word])
	var flow_source := FileAccess.get_file_as_string("res://scripts/v2/game_flow.gd")
	check(not flow_source.contains(".review(") and not flow_source.contains("Time.get_date"), "the flow never reads review() or the real clock directly")
	for filename in DirAccess.get_files_at("res://scripts/meta"):
		if filename.ends_with(".gd") and filename != "clock.gd":
			check(not FileAccess.get_file_as_string("res://scripts/meta/" + filename).contains("Time.get_"), filename + " does not read the real date")

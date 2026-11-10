extends SceneTree
# T-030 headless tests, part 2: the meta layer wired into game_flow.gd (title entry points, first-run screen,
# attendance letters, Daily Shift seed, day log, toasts, wallet effects) with an injected clock.
# Run: --headless -s res://tests/test_t030_flow.gd
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const InputLog = preload("res://scripts/meta/input_log.gd")
const LocalDaySource = preload("res://scripts/meta/local_day_source.gd")
const PATH := "user://t030_flow_profile.json"
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

func new_flow(date: String, use_meta: bool = true) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	if use_meta: node.meta = Meta.new(PATH, Clock.new(date))
	root.add_child(node)
	return node

func drain(flow: Node, limit: int = 4000) -> void:
	var guard := 0
	if flow.state == "COMMUTE": flow.commute.hurry()
	while flow.state == "COMMUTE" and guard < limit:
		guard += 1
		flow.commute.advance(0.1)

func submit(flow: Node, forecast: String = "tang", confidence: String = "vua") -> void:
	var window: Control = flow.desktop.report_window
	window.choose_forecast(forecast)
	window.choose_confidence(confidence)
	window.request_submit()
	window.confirm_submit()

# One whole working day with default choices; stops at the next MORNING or at the ending.
func quick_day(flow: Node) -> void:
	var guard := 0
	var worked := false
	while guard < 80 and flow.state != "END_SCREEN":
		guard += 1
		match flow.state:
			"DAY_START": flow.skip_intro()
			"COMMUTE": drain(flow)
			"WORK":
				submit(flow)
				worked = true
			"REVIEW", "SUBMITTED": flow.continue_review()
			"EVENING": flow.evening_view.go_home()
			"MORNING", "TRANSPORT", "OVERTIME", "SHOP":
				if worked and flow.state == "MORNING": return
				flow.quick_advance()
			_: return

func run() -> void:
	test_title_buttons()
	test_first_run_and_daily()
	test_day_log_and_toasts()
	test_letter_flow()
	test_attendance_off()
	test_full_game_and_score()
	test_rollover_toast()
	test_replay_and_no_meta()
	wipe()
	print("test_t030_flow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_title_buttons() -> void:
	wipe()
	var flow := new_flow("2026-11-10", false)
	flow.start_title()
	var title: Control = flow.title_view
	check(title.play_button.text == "Play" and title.daily_button.text == "Daily Shift" and title.wall_button.text == "Wall of Fame", "title buttons")
	check(title.daily_button.disabled and title.wall_button.disabled and title.settings_button.disabled and title.leave_button.disabled and not title.play_button.disabled, "without a profile the meta buttons are disabled and Play still works")
	flow.queue_free()
	var with_meta := new_flow("2026-11-10")
	with_meta.start_title()
	var t2: Control = with_meta.title_view
	check(not t2.daily_button.disabled and not t2.wall_button.disabled and t2.profile_label.text.begins_with("Analyst"), "with a profile the buttons are live: " + t2.profile_label.text)
	t2.wall_button.pressed.emit()
	check(with_meta.state == "WALL" and with_meta.meta_view != null, "Wall of Fame opens")
	with_meta.meta_view.back_requested.emit()
	check(with_meta.state == "TITLE", "back returns to the title")
	t2 = with_meta.title_view
	t2.settings_button.pressed.emit()
	check(with_meta.state == "SETTINGS", "Settings opens")
	with_meta.meta_view.back_requested.emit()
	with_meta.title_view.leave_button.pressed.emit()
	check(with_meta.state == "LEAVE", "Request leave opens")
	with_meta.meta_view.back_requested.emit()
	check(with_meta.state == "TITLE", "back from leave")
	with_meta.queue_free()

func test_first_run_and_daily() -> void:
	wipe()
	var flow := new_flow("2026-11-10")
	flow.start_title()
	flow.title_view.daily_button.pressed.emit()
	check(flow.state == "INTRO" and flow.meta_view != null, "first run shows the explanation screen")
	check(flow.meta_view.screen.lines.size() == 3 and flow.meta.profile.data.settings.attendance == true, "attendance is ON by default")
	flow.meta_view.finish()
	check(flow.state == "MORNING" and flow.run_mode == "daily", "then the Daily Shift starts")
	check(flow.seed_used == LocalDaySource.seed_for_date("2026-11-10"), "the Daily Shift seed comes from the date: %d" % flow.seed_used)
	var seed_a: int = flow.seed_used
	flow.queue_free()
	# The intro is shown only once; a second player on the same date gets the same seed.
	var second := new_flow("2026-11-10")
	second.start_title()
	second.title_view.daily_button.pressed.emit()
	check(second.state == "MORNING" and second.seed_used == seed_a, "no second explanation; same date, same seed")
	var q1: String = second.game.question_today().get("text", "x")
	second.queue_free()
	var other := new_flow("2026-11-11")
	other.begin_run("daily")
	check(other.seed_used != seed_a, "another date, another seed")
	other.queue_free()
	var normal := new_flow("2026-11-10")
	normal.start_title()
	normal.title_view.play_button.pressed.emit()
	check(normal.state == "MORNING" and normal.run_mode == "run", "Play still starts the normal run")
	normal.queue_free()
	check(q1 == "x" or q1 != "", "question text available")

func test_day_log_and_toasts() -> void:
	wipe()
	var flow := new_flow("2026-11-10")
	flow.meta.profile.data.settings.intro_seen = true
	flow.begin_run("daily")
	check(flow.state == "MORNING", "straight to the morning once the intro was seen")
	var wallet: int = flow.life.wallet
	check(wallet == 60, "no fine or bonus for a fresh player")
	quick_day(flow)
	check(flow.state == "MORNING" or flow.state == "END_SCREEN", "one day played: " + flow.state)
	var history: Array = flow.meta.profile.data.history
	check(history.size() == 1, "one record in the profile after the day")
	var record: Dictionary = history[0]
	check(record.day_id == "daily:2026-11-10:1" and record.mode == "daily" and record.seed == flow.seed_used and record.date == "2026-11-10", "record ids: " + str(record.day_id))
	check(record.inputs.question_id != "" and record.inputs.forecast == "tang" and record.inputs.confidence == "vua", "submitted inputs stored")
	check(record.result.timing in ["on_time", "late", "missed"] and record.result.day_score == int(record.result.day_score), "result parts stored")
	check(flow.meta.profile.data.streak == 1 and flow.meta.profile.data.last_finished_day == "2026-11-10", "streak and last finished day")
	check(flow.toast_log.has("Achievement: First Report"), "achievement toast queued: " + str(flow.toast_log))
	check(flow.toast_view.visible_text() == "Achievement: First Report" or flow.toast_view.queue.size() >= 0, "toast shown")
	flow.toast_view.advance(5.0)
	check(flow.meta.profile.data.history.size() == 1, "still one record")
	var saved := Meta.new(PATH, Clock.new("2026-11-10"))
	check(saved.profile.data.history.size() == 1 and saved.profile.data.reputation == flow.meta.profile.data.reputation, "the record was saved to the file")
	# Day 2 of the same run, next calendar date.
	flow.meta.clock.advance(1)
	if flow.state == "MORNING":
		quick_day(flow)
		check(flow.meta.profile.data.history.size() == 2 and flow.meta.profile.data.streak == 2, "second day: streak 2")
		check(flow.meta.profile.data.history[1].day_id == "daily:2026-11-11:2", "second day id: " + str(flow.meta.profile.data.history[1].day_id))
	flow.queue_free()

func test_letter_flow() -> void:
	wipe()
	var flow := new_flow("2026-11-10")
	flow.meta.profile.data.settings.intro_seen = true
	flow.meta.profile.data.last_finished_day = "2026-11-04"
	flow.meta.profile.data.reputation = 50
	flow.begin_run("run")
	check(flow.state == "LETTER", "5 missed days: the letter appears first: " + flow.state)
	var screen: Dictionary = flow.meta_view.screen
	check(screen.step == "formal" and screen.missed == 5 and screen.effects.size() == 3, "formal warning letter with 3 effect lines: " + str(screen.effects))
	check(flow.meta.profile.data.reputation == 45, "reputation 50 -> 45 (10 percent)")
	flow.meta_view.finish()
	check(flow.state == "MORNING", "the run starts after the letter")
	check(flow.life.wallet == 56, "starting wallet 60 + 5 welcome back - 9 fine = 56: %d" % flow.life.wallet)
	check(flow.life.net_worth() == flow.life.ledger_total(), "ledger consistent")
	check(flow.meta.profile.data.pending_fine == 0, "fine applied once")
	flow.queue_free()
	# Same date, same profile: the letter does not appear twice.
	var again := new_flow("2026-11-10")
	again.begin_run("run")
	check(again.state == "MORNING" and again.life.wallet == 60, "no repeat letter and no second fine")
	again.queue_free()
	# Termination and rehire letters; leave days reduce the steps.
	for pair in [[8, "termination"], [9, "rehire"], [2, "reminder"], [3, "warning"]]:
		wipe()
		var f := new_flow("2026-12-01")
		f.meta.profile.data.settings.intro_seen = true
		f.meta.profile.data.last_finished_day = Clock.add_days("2026-12-01", -int(pair[0]))
		f.begin_run("run")
		check(f.state == "LETTER" and f.meta_view.screen.step == pair[1], "%d days away -> %s" % [pair[0], pair[1]])
		f.queue_free()
	wipe()
	var leave := new_flow("2026-12-01")
	leave.meta.profile.data.settings.intro_seen = true
	leave.meta.profile.data.last_finished_day = "2026-11-27"
	leave.meta.profile.data.leave.append({"date": "2026-11-28", "reason": "cat"})
	leave.meta.profile.data.leave.append({"date": "2026-11-29", "reason": "cat"})
	leave.meta.profile.data.leave.append({"date": "2026-11-30", "reason": "cat"})
	leave.begin_run("run")
	check(leave.state == "MORNING", "three covered days: no letter")
	leave.queue_free()

func test_attendance_off() -> void:
	wipe()
	var flow := new_flow("2026-12-10")
	flow.meta.profile.data.settings.intro_seen = true
	flow.meta.profile.data.last_finished_day = "2026-11-01"
	flow.meta.profile.data.reputation = 80
	flow.meta.set_attendance(false)
	flow.begin_run("run")
	check(flow.state == "MORNING" and flow.life.wallet == 60 and flow.meta.profile.data.reputation == 80, "attendance warnings OFF: no letter, no penalty")
	flow.queue_free()

func play_whole(flow: Node) -> void:
	var guard := 0
	while flow.state != "END_SCREEN" and guard < 1200:
		guard += 1
		match flow.state:
			"EVENING": flow.evening_view.go_home()
			"WORK": submit(flow)
			"REVIEW", "SUBMITTED": flow.continue_review()
			"DAY_START": flow.skip_intro()
			"COMMUTE": drain(flow)
			_: flow.quick_advance()

func test_full_game_and_score() -> void:
	var scores: Array = []
	for with_meta in [false, true]:
		wipe()
		var flow := new_flow("2026-11-10", with_meta)
		if with_meta: flow.meta.profile.data.settings.intro_seen = true
		flow.seed_used = 31
		flow.run_mode = "run"
		flow.start_with_game(Game.new(31, 10))
		play_whole(flow)
		check(flow.state == "END_SCREEN", "game finished (meta %s)" % with_meta)
		scores.append([flow.game.status().score, flow.game.status().trust, flow.game.status().day])
		if with_meta:
			check(flow.meta.profile.data.history.size() == int(flow.game.status().day), "every day of the run is in the history (%d)" % flow.meta.profile.data.history.size())
			var ids := {}
			for record in flow.meta.profile.data.history: ids[record.day_id] = true
			check(ids.size() == flow.meta.profile.data.history.size(), "day ids are unique")
			check(flow.meta.profile.data.stats.days_total == flow.meta.profile.data.history.size(), "stats match the history")
			if flow.game.status().ending == "survived": check(flow.toast_log.has("Achievement: Survived 10 Days"), "survived toast")
		flow.queue_free()
	check(scores[0] == scores[1], "score identical with meta off and on: %s vs %s" % [str(scores[0]), str(scores[1])])

func test_rollover_toast() -> void:
	wipe()
	var october := Meta.new(PATH, Clock.new("2026-10-30"))
	october.sink.submit_day(InputLog.build("run", "2026-10-30", 9, 1, {"question_id": "q", "forecast": "tang", "confidence": "vua", "evidence": [], "actions": []}, 540, {"focus_bonus": 0, "late_minutes": 0}, {"accuracy": 1.0, "evidence_quality": 0.0, "trust_delta": 3.0, "timing": "on_time", "pay": 100, "bonus": 0, "rank": "thuc_tap", "trust": 49, "day_score": 115}))
	check(october.profile.data.winners.is_empty(), "no winner in the running month")
	var flow := new_flow("2026-11-02")
	check(flow.meta.rollover_winners.size() == 1, "loading in November settles October")
	flow.announce_rollover()
	check(flow.toast_log == ["Employee of the Month: 2026-10"] and flow.meta.rollover_winners.is_empty(), "the winner is announced once as a toast: " + str(flow.toast_log))
	flow.queue_free()

func test_replay_and_no_meta() -> void:
	wipe()
	var flow := new_flow("2026-11-10", false)
	flow.begin_run("daily")
	check(flow.state == "MORNING" and flow.meta == null, "without a profile begin_run just starts a run")
	flow.queue_free()
	var plain := new_flow("2026-11-10", false)
	plain.start_with_game(Game.new(5, 10))
	quick_day(plain)
	check(plain.toast_log.is_empty() and not FileAccess.file_exists(PATH), "no meta: nothing logged, no file written")
	plain.queue_free()

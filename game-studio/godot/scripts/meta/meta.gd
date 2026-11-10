extends RefCounted
# T-030: the meta layer facade used by game_flow.gd and the new screens: profile, attendance ladder,
# Daily Shift seed, finished-day log. Everything is local; there is no network and no notification.
const Clock = preload("res://scripts/meta/clock.gd")
const Profile = preload("res://scripts/meta/profile.gd")
const Attendance = preload("res://scripts/meta/attendance.gd")
const Awards = preload("res://scripts/meta/awards.gd")
const InputLog = preload("res://scripts/meta/input_log.gd")
const LocalDaySource = preload("res://scripts/meta/local_day_source.gd")
const LocalScoreSink = preload("res://scripts/meta/local_score_sink.gd")
var cfg: Dictionary
var clock: RefCounted
var profile: RefCounted
var attendance: RefCounted
var source: RefCounted
var sink: RefCounted
var rollover_winners: Array = []

func _init(profile_path: String = "user://profile.json", clock_ref: RefCounted = null) -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/meta.json"))
	clock = clock_ref if clock_ref != null else Clock.new()
	profile = Profile.new(profile_path, cfg)
	profile.load_or_create(clock.today())
	profile.data.history = profile.data.history.map(func(record): return InputLog.normalize(record))
	attendance = Attendance.new(profile, cfg, clock)
	source = LocalDaySource.new(clock)
	sink = LocalScoreSink.new(profile, cfg, clock, attendance)
	# Month rollover: the winner of every finished month is stored permanently.
	rollover_winners = Awards.settle_months(profile.data, cfg, clock.today())
	if not rollover_winners.is_empty(): profile.save()

func data() -> Dictionary:
	return profile.data

# ---- before a run ---------------------------------------------------------------------------

# The screens to show before a run starts, in order: the first-run explanation, then the HR/Boss letter
# when the attendance ladder triggers. Each is {type: "intro"|"letter", ...} with ready-to-show text.
func pre_run_screens() -> Array:
	var screens: Array = []
	var text: Dictionary = cfg.text
	if not bool(profile.data.settings.intro_seen):
		profile.data.settings.intro_seen = true
		screens.append({"type": "intro", "title": text.intro_title, "lines": text.intro_lines, "hint": text.intro_hint})
	var letter: Dictionary = attendance.evaluate()
	if not letter.is_empty():
		screens.append(letter_screen(letter))
	profile.save()
	return screens

# Turns an evaluate() result into screen text. The same lines are what a future notification would send.
func letter_screen(letter: Dictionary) -> Dictionary:
	var text: Dictionary = cfg.text
	var spec: Dictionary = cfg.letters[letter.step]
	var effects: Array = []
	if int(letter.rep_loss) > 0: effects.append(text.penalty_rep % int(letter.rep_loss))
	if int(letter.fine) > 0: effects.append(text.penalty_fine % int(letter.fine))
	if effects.is_empty(): effects.append(text.penalty_none)
	if int(letter.bonus) > 0: effects.append(text.welcome_back % int(letter.bonus))
	if bool(letter.rehired): effects.append(text.rehired_note)
	return {"type": "letter", "step": letter.step, "missed": int(letter.missed), "from": text[spec.from], "subject": spec.subject, "body": spec.lines[int(letter.line_index)], "effects": effects, "missed_line": text.missed_line % int(letter.missed), "hint": text.leave_hint}

func daily_seed() -> int:
	return source.seed_for("daily")

# A new run has started: the pending fine and welcome-back bonus change the starting wallet, once.
func begin_run(life: RefCounted) -> Dictionary:
	var applied: Dictionary = attendance.apply_to_run(life)
	profile.save()
	return applied

# ---- during a run ---------------------------------------------------------------------------

# A day has been reviewed. Builds the input-log record from the player's submission and the public
# result parts, hands it to the ScoreSink, and returns the sink's answer (including toast texts).
func finish_day(game: RefCounted, day: int, submission: Dictionary, before: Dictionary, after: Dictionary, context: Dictionary, mode: String, seed_value: int) -> Dictionary:
	var revealed: Dictionary = source.reveal(game, day, before, after)
	if revealed.is_empty(): return {"toasts": []}
	var result: Dictionary = revealed.result
	result["day_score"] = Awards.day_score(result, cfg)
	var record := InputLog.build(mode, clock.today(), seed_value, day, submission, int(revealed.submit_minutes), context, result)
	var outcome: Dictionary = sink.submit_day(record)
	outcome["record"] = record
	return outcome

func finish_run(status: Dictionary) -> Dictionary:
	return sink.finish_run(status)

# ---- settings and leave ---------------------------------------------------------------------

func set_attendance(enabled: bool) -> void:
	profile.data.settings.attendance = enabled
	profile.save()

func set_quiet_hours(start_hour: int, end_hour: int) -> void:
	profile.data.settings.quiet_start = clampi(start_hour, 0, 23)
	profile.data.settings.quiet_end = clampi(end_hour, 0, 23)
	profile.save()

func request_leave(start: String, days: int, reason_id: String) -> Dictionary:
	var result: Dictionary = attendance.request_leave(start, days, reason_id)
	if result.ok: profile.save()
	return result

func reset_profile() -> void:
	profile.reset(clock.today())
	profile.save()
	rollover_winners = []

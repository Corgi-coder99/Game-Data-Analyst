extends SceneTree
# T-045: the gentle Practice run. Logic part (headless, no window): the overrides never fire anyone and the default
# config is untouched. Flow part: begin_run("practice") skips morning/commute/evening and saves nothing.
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Balance = preload("res://tests/balance_world.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const PATH := "user://t045_profile.json"
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func play(bot: String, seed_value: int, overrides: Dictionary) -> Dictionary:
	var game := Game.new(seed_value, 10, overrides)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 10000
	var days := 0
	while not game.status().finished:
		game.begin_day()
		var submitted := game.submit_report(Balance.propose(game, bot, rng, {}))
		if not submitted.get("ok", false): return {"error": submitted.get("error", "submit")}
		game.end_day()
		days += 1
	var status: Dictionary = game.status()
	status["days_played"] = days
	return status

func run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	check(not config.career.has("trust_floor"), "the default config has no trust_floor")
	var fired_default := 0
	var fired_practice := 0
	var min_trust := 100.0
	var wins := 0
	var runs := 0
	for bot in ["random_reporter", "rumor_follower", "official_only"]:
		for index in 30:
			var seed_value := 400 + index
			var normal := play(bot, seed_value, {})
			var gentle := play(bot, seed_value, Flow.PRACTICE_OVERRIDES)
			check(not normal.has("error") and not gentle.has("error"), "%s %d plays to the end" % [bot, seed_value])
			if normal.get("ending", "") == "fired": fired_default += 1
			if gentle.get("ending", "") == "fired": fired_practice += 1
			check(gentle.get("ending", "") == "survived", "%s %d practice survives (%s)" % [bot, seed_value, gentle.get("ending", "")])
			check(gentle.get("days_played", 0) == 10, "practice reaches day 10")
			check(gentle.get("warnings", 1) == 0 and gentle.get("demotions", 1) == 0, "practice has no warnings or demotions")
			min_trust = minf(min_trust, float(gentle.get("trust", 0.0)))
			if gentle.get("won", false): wins += 1
			runs += 1
	print("practice: fired default %d / %d, practice %d, min trust %.1f, wins %d" % [fired_default, runs, fired_practice, min_trust, wins])
	check(fired_default > 0, "careless bots are fired on the normal config (control)")
	check(fired_practice == 0, "nobody is fired in practice")
	check(min_trust >= 30.0, "trust never falls below the floor")
	check(wins == runs, "finishing practice counts as a win")
	# The gentle run is more forgiving than the normal one for the same careless play.
	await test_flow()
	print("test_t045_practice: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func wipe() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func test_flow() -> void:
	wipe()
	var flow: Node = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	flow.meta = Meta.new(PATH, Clock.new("2026-11-20"))
	root.add_child(flow)
	flow.meta.profile.data.telemetry.seen = true
	flow.meta.profile.data.learn.tutorial = "skip"
	flow.start_title()
	await process_frame
	check(flow.title_view.practice_button != null and not flow.title_view.practice_button.disabled, "the title has an enabled Practice button")
	flow.title_view.practice_button.pressed.emit()
	var guard := 0
	while flow.state in ["INTRO", "LETTER", "CONSENT", "TUTORIAL_CHOICE"] and guard < 8:
		guard += 1
		if flow.state in ["INTRO", "LETTER"]: flow.meta_view.finished.emit()
		await process_frame
	check(flow.run_mode == "practice" and flow.practice_mode(), "run mode is practice")
	check(flow.game != null and flow.state != "MORNING" and flow.state != "COMMUTE", "practice skips the morning and the commute (state %s)" % flow.state)
	check(not flow.daily_active(), "no daily life in practice")
	for day in 2:
		guard = 0
		while guard < 60 and flow.state != "END_SCREEN":
			guard += 1
			match flow.state:
				"DAY_START": flow.skip_intro()
				"WORK":
					var window: Control = flow.desktop.report_window
					window.choose_forecast("tang")
					window.choose_confidence("vua")
					window.request_submit()
					window.confirm_submit()
				"REVIEW", "SUBMITTED": flow.continue_review()
				_: pass
			await process_frame
			if flow.game != null and int(flow.game.status().day) > day + 1: break
	check(flow.meta.profile.data.history.size() == 0, "practice saves no day history")
	check(not flow.meta.profile.data.achievements.has("first_report"), "practice earns no achievement")
	check(flow.state != "EVENING", "no evening in practice")
	flow.meta.profile.reset(flow.meta.clock.today())
	wipe()

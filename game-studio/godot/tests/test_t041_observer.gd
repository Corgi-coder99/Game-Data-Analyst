extends SceneTree
const Support = preload("res://tests/test_t041_support.gd")
const Playlog = preload("res://scripts/telemetry/playlog.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Observer = preload("res://scripts/telemetry/bot_observer.gd")
const Balance = preload("res://tests/balance_world.gd")
const Bots = preload("res://tests/telemetry_bots.gd")
var checks := 0
var failures := 0
var samples := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	Support.configure()
	call_deferred("run")

func compare(a: RefCounted, b: RefCounted, stage: String) -> void:
	check(a.status() == b.status(), "same status " + stage)
	check(a.report_snapshot() == b.report_snapshot(), "same report snapshot " + stage)

func scan_open(log: RefCounted, cursor: int) -> int:
	var rows: Array = log.writer.records()
	for row in rows.slice(cursor):
		check(row.e != "day_end", "no day_end before closed review")
		for key in ["label", "acc", "ev", "delta", "shifted", "root_cause", "_scenario", "_late_plan", "states", "headline", "uid", "text", "name", "display_name"]:
			check(not row.has(key), "open-day event excludes " + key)
		samples += 1
	return rows.size()

func run() -> void:
	var log := Playlog.new(null, "user://t041_observer/playlog.jsonl", "verifier")
	log.writer.delete_data()
	for seed_value in range(104, 116):
		var plain := Game.new(seed_value, 10)
		var observed := Observer.new(Game.new(seed_value, 10), log)
		log.run_start("run", seed_value, 10)
		var cursor: int = log.writer.records().size()
		while not plain.status().finished:
			plain.begin_day()
			observed.begin_day()
			compare(plain, observed, "day start")
			var question: Dictionary = plain.question_today()
			var item: Dictionary = plain.news_today()[0]
			var tool: String = plain.tools()[0].id
			check(plain.verify(item.uid, tool) == observed.verify(item.uid, tool), "same verification result")
			check(plain.verify(item.uid, tool) == observed.verify(item.uid, tool), "same cached verification result")
			check(plain.verify(item.uid, "invalid_tool") == observed.verify(item.uid, "invalid_tool"), "same failed verification result")
			check(plain.spend_minutes(7) == observed.spend_minutes(7), "same app minutes")
			check(plain.wait_for_data(3) == observed.wait_for_data(3), "same wait result")
			compare(plain, observed, "after tools and time")
			var report := {"question_id":question.id,"forecast":"ngang","confidence":"thap","evidence":[],"actions":[],"notes":"PRIVATE-".repeat(10)}
			check(plain.submit_report(report) == observed.submit_report(report), "same submission")
			cursor = scan_open(log, cursor)
			check(plain.end_day() == observed.end_day(), "same end day result")
			var day: int = plain.status().day
			check(plain.review(day) == observed.review(day), "same closed-day review")
			compare(plain, observed, "after end day")
			var rows: Array = log.writer.records()
			check(rows[-1].e == "day_end" and rows[-1].day == day, "day_end follows closed review")
			cursor = rows.size()
		log.run_end(observed.status())
	check(samples >= 450, "at least 450 open-day events scanned: %d" % samples)
	var rows: Array = log.writer.records()
	var count := 0
	for row in rows:
		if row.e == "wait": check(row.waited_minutes == 3 and row.app_minutes == 7, "time aggregated by day")
		if row.e == "report_submit": check(row.free_text_len_class == "41+", "only text length class retained")
		if row.e == "run_end": count += 1
		check(not JSON.stringify(row).contains("PRIVATE"), "typed content absent")
	check(count == 12, "twelve completed comparison runs")
	# Exercise each existing bot and both analyst variants without generating the large default batch.
	var bot_log := Playlog.new(null, "user://t041_bots/bot_playlog.jsonl", "fixture")
	bot_log.writer.delete_data()
	for bot in Bots.BOTS:
		bot_log.bot_pid = "bot-" + bot
		var result: Dictionary = Bots.run_one(bot, 104, 10, bot_log)
		check(not result.has("error") and result.get("finished", false), "generator completes " + bot)
	var bot_rows: Array = bot_log.writer.records()
	check(not bot_rows.is_empty(), "bot fixture is written")
	for row in bot_rows: check(row.src == "bot" and str(row.pid).begins_with("bot-"), "synthetic provenance")
	print("Bot validator fixture: ", ProjectSettings.globalize_path(bot_log.writer.path))
	print("Open-day events scanned: ", samples)
	print("test_t041_observer: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

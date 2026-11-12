extends SceneTree
# Synthetic data only. Run explicitly; never writes the human telemetry directory.
const Game = preload("res://scripts/world/world_game.gd")
const Balance = preload("res://tests/balance_world.gd")
const Session = preload("res://scripts/data/session.gd")
const Analyst = preload("res://tests/t036_analyst.gd")
const Playlog = preload("res://scripts/telemetry/playlog.gd")
const Observer = preload("res://scripts/telemetry/bot_observer.gd")
const BOTS := ["random_reporter", "rumor_follower", "official_only", "verifier", "careful_hedger", "late_verifier", "analyst_clean", "analyst_sloppy", "analyst_slow", "chart_misleader", "analyst_verify_first", "analyst_submit_early"]

func _initialize() -> void:
	call_deferred("generate")

static func run_one(bot: String, seed_value: int, days: int, log: RefCounted, overrides: Dictionary = {}) -> Dictionary:
	var world := Game.new(seed_value, days, overrides)
	var game := Observer.new(world, log)
	# Existing data-core construction happens before any day is open; it is not telemetry.
	var session: RefCounted = Session.new(world, seed_value) if bot.begins_with("analyst_") or bot == "chart_misleader" else null
	if session != null: session.world = game
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 10000
	log.run_start("run", seed_value, days)
	while not game.status().finished:
		game.begin_day()
		var report: Dictionary
		if session != null:
			session.begin_day(int(game.status().day))
			if bot == "analyst_verify_first":
				var qid: String = game.question_today().id
				var related: Array = game.news_today().filter(func(n): return n.topic == Balance.topic_for(qid) and n.day == game.status().day)
				if not related.is_empty():
					var tool := "truy_van_lich_su" if qid in ["q1", "q4", "q5"] else ("lam_sach_du_lieu" if qid == "q8" else "doi_chieu_nguon")
					game.verify(related[0].uid, tool)
			# Submit-early finishes the clean analyst's public data work and submits immediately.
			var strategy := "analyst_clean" if bot in ["analyst_verify_first", "analyst_submit_early"] else bot
			report = Balance.propose_analyst(game, session, strategy, {})
		else:
			report = Balance.propose(game, bot, rng, {})
		if bot == "late_verifier":
			while game.status().band == "on_time": game.wait_for_data()
		var submitted := game.submit_report(report)
		if not submitted.get("ok", false): return {"error": submitted.get("error", "submission_failed")}
		game.end_day()
	log.run_end(game.status())
	return game.status()

func generate() -> void:
	var games := 200
	var seed_value := 104
	var days := 10
	var destination := "user://telemetry_bots/bot_playlog.jsonl"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--games="): games = int(arg.trim_prefix("--games="))
		elif arg.begins_with("--seed="): seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--days="): days = int(arg.trim_prefix("--days="))
		elif arg.begins_with("--output="): destination = arg.trim_prefix("--output=")
	var writer := preload("res://scripts/telemetry/writer.gd").new(destination)
	if not writer.valid_path() or not destination.begins_with("user://telemetry_bots/") or games < 1 or days not in [10, 30]:
		printerr("Use --output=user://telemetry_bots/<file>.jsonl, --games=N, --days=10 or 30")
		quit(1)
		return
	var runs := 0
	for bot in BOTS:
		var log := Playlog.new(null, destination, bot)
		for index in games:
			var result := run_one(bot, seed_value + index, days, log)
			if result.has("error"):
				printerr("Bot failed: ", bot, " ", result.error)
				quit(1)
				return
			runs += 1
	print("Generated %d bot runs: %s" % [runs, ProjectSettings.globalize_path(destination)])
	quit(0)

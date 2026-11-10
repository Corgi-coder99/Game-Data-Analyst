extends SceneTree
# T-023 logic tests (headless): day clock, deadline bands, the 15:00 update, late grading,
# hidden-state leak probe, Mail clock/banner, Code Pad time cost, day-2 deadline tutorial step.
const Game = preload("res://scripts/world/world_game.gd")
const Flow = preload("res://scripts/v2/game_flow.gd")
const Desktop = preload("res://scenes/v2/desktop.tscn")
const Loader = preload("res://scripts/data.gd")
const HIDDEN_KEYS := ["volatile", "late_answer", "shifted", "original_answer", "honest", "late_plan", "submit_minutes", "truth", "kind", "answer"]
var checks := 0
var failures := 0
var config: Dictionary
var strings: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func clean(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			if key in HIDDEN_KEYS or not clean(value[key]): return false
	elif value is Array:
		for item in value:
			if not clean(item): return false
	return true

func fresh(seed_value: int = 104) -> RefCounted:
	var game := Game.new(seed_value, 10)
	game.begin_day()
	return game

func report(game: RefCounted, forecast: String = "ngang", confidence: String = "cao") -> Dictionary:
	return {"question_id":game.question_today().id, "forecast":forecast, "confidence":confidence, "evidence":[], "actions":[]}

func test_clock() -> void:
	var game := fresh()
	check(game.status().minutes == 510 and game.status().band == "on_time", "day starts 08:30 on time")
	var expected := {"truy_van_lich_su":30, "kiem_dinh_gia_thuyet":45, "doi_chieu_nguon":20, "lam_sach_du_lieu":35}
	for tool in game.tools(): check(tool.minutes == expected[tool.id], "tool minutes public: " + tool.id)
	var news: Array = game.news_today()
	var uid: String = news[0].uid
	var before: int = game.status().minutes
	var first: Dictionary = game.verify(uid, "doi_chieu_nguon")
	check(first.ok and game.status().minutes == before + 20, "doi_chieu_nguon costs 20 minutes")
	check(game.verify(uid, "doi_chieu_nguon").ok and game.status().minutes == before + 20, "cached repeat is free")
	var second: Dictionary = game.verify(news[1].uid, "kiem_dinh_gia_thuyet")
	check(second.ok and game.status().minutes == before + 65, "second tool adds its own cost")
	var bad: Dictionary = game.verify(news[1].uid, "not_a_tool")
	check(not bad.ok and game.status().minutes == before + 65, "invalid tool does not move the clock")
	# No energy: a refused check does not cost time either.
	game.verify(news[2].uid, "truy_van_lich_su")
	var spent: int = game.status().minutes
	var refused: Dictionary = game.verify(news[3].uid, "lam_sach_du_lieu")
	check(not refused.ok and game.status().minutes == spent, "out-of-energy check costs no time")
	# Next day restarts at 08:30.
	game.submit_report(report(game))
	game.end_day()
	game.begin_day()
	check(game.status().minutes == 510, "next day restarts at 08:30")

func test_bands_and_update() -> void:
	var game := fresh()
	check(game.wait_for_data(900 - 510).ok and game.status().minutes == 900 and game.status().band == "on_time", "15:00 sharp is still on time")
	check(not game.news_today().any(func(n): return n.uid.ends_with("-late")), "no update at 15:00 sharp or before")
	game.wait_for_data(1)
	check(game.status().band == "late", "15:01 is late")
	var update: Array = game.news_today().filter(func(n): return n.uid.ends_with("-late"))
	check(update.size() == 1, "exactly one update after 15:00")
	var item: Dictionary = update[0]
	check(item.source_name != "" and item.headline != "" and item.source_tier != "" and item.topic != "", "update has source, tier, topic and headline")
	check(clean(game.news_today()), "update exposes no hidden fields")
	var rejected: Dictionary = game.verify(item.uid, "doi_chieu_nguon")
	check(not rejected.ok and rejected.error == "update_final", "update cannot be verified")
	var twin := fresh()
	twin.wait_for_data(391)
	check(twin.news_today() == game.news_today(), "update is deterministic for the seed")
	game.wait_for_data(1020 - 901)
	check(game.status().band == "late" and game.status().minutes == 1020, "17:00 sharp is still late")
	game.wait_for_data(1)
	check(game.status().band == "missed", "17:01 is missed")
	check(game.wait_for_data().error == "too_late", "waiting after the deadline is refused")
	check(game.verify(game.news_today()[0].uid, "doi_chieu_nguon").error == "too_late", "new checks after the deadline are refused")
	check(game.status().deadline_on_time == 900 and game.status().deadline_late == 1020, "status exposes the two deadlines")
	# Evidence may cite the update.
	var cite := fresh(7)
	cite.wait_for_data(400)
	var input := report(cite)
	input.evidence = [cite.news_today().filter(func(n): return n.uid.ends_with("-late"))[0].uid]
	check(cite.submit_report(input).ok, "update can be cited as evidence")
	# After the day, the update is gone.
	cite.end_day()
	check(not cite.news_today().any(func(n): return n.uid.ends_with("-late")), "update closes with the day")

func test_missed_and_late_grading() -> void:
	var game := fresh()
	game.wait_for_data(600)
	check(game.status().band == "missed", "setup missed")
	var input := report(game, "tang", "cao")
	input.actions = [game.hand()[0].id] if not game.hand().is_empty() else []
	check(game.submit_report(input).ok, "a missed report can still be sent")
	var ended: Dictionary = game.end_day()
	check(ended.actions.is_empty() and clean(ended), "missed report proposes nothing")
	var review: Dictionary = game.review(1)
	check(review.timing == "missed" and is_equal_approx(review.result.delta, -float(config.late.missed_penalty)) and review.result.acc == 0.0, "missed counts as a penalty")
	# Late: reward cut, grading uses the shifted answer.
	var plans_flip := 0
	var plans_volatile := 0
	var plans_clean := true
	for seed_value in range(1, 41):
		var probe := Game.new(seed_value, 10)
		for day in 10:
			var plan: Dictionary = probe._late_plan[day]
			var original: String = probe._scenario._answers[day]
			if plan.volatile: plans_volatile += 1
			if plan.answer != original:
				plans_flip += 1
				if not plan.volatile: plans_clean = false
	check(plans_clean, "answers shift only on volatile days")
	check(plans_flip > 0 and plans_volatile > plans_flip, "some volatile days shift and some do not: %d of %d" % [plans_flip, plans_volatile])
	# End-to-end on a day that really flips: submit the original answer late, then on time.
	var shifted_seed := -1
	for seed_value in range(1, 200):
		var probe := Game.new(seed_value, 10)
		if probe._late_plan[0].answer != probe._scenario._answers[0]:
			shifted_seed = seed_value
			break
	check(shifted_seed > 0, "found a seed whose first day shifts")
	var on_time := fresh(shifted_seed)
	var original: String = on_time._scenario._answers[0]
	check(on_time.submit_report(report(on_time, original, "cao")).ok, "on-time submit")
	on_time.end_day()
	var good: Dictionary = on_time.review(1)
	check(good.timing == "on_time" and good.result.acc == 1.0 and good.answer == original and not good.shifted, "on-time report is graded on the original answer")
	var late := fresh(shifted_seed)
	late.wait_for_data(400)
	check(late.submit_report(report(late, original, "cao")).ok, "late submit")
	late.end_day()
	var bad: Dictionary = late.review(1)
	check(bad.timing == "late" and bad.shifted and bad.result.acc < 1.0 and bad.answer != original and bad.original_answer == original, "late report is graded on the shifted answer")
	var later := fresh(shifted_seed)
	later.wait_for_data(400)
	check(later.submit_report(report(later, later._late_plan[0].answer, "cao")).ok, "late submit of the shifted answer")
	later.end_day()
	var cut: Dictionary = later.review(1)
	var base := fresh(shifted_seed)
	base.submit_report(report(base, base._scenario._answers[0], "cao"))
	base.end_day()
	var full: float = base.review(1).result.delta
	check(cut.result.acc == 1.0 and absf(cut.result.delta - snappedf(full * float(config.late.reward_factor), 0.1)) < 0.001, "late reward is cut: %s vs %s" % [cut.result.delta, full])
	# Non-volatile day: late and on-time results differ only by the reward cut.
	var calm_seed := -1
	for seed_value in range(1, 200):
		var probe := Game.new(seed_value, 10)
		if not probe._late_plan[0].volatile:
			calm_seed = seed_value
			break
	var calm := fresh(calm_seed)
	calm.wait_for_data(400)
	calm.submit_report(report(calm, calm._scenario._answers[0], "cao"))
	calm.end_day()
	check(calm.review(1).result.acc == 1.0 and not calm.review(1).shifted, "calm day: late answer unchanged")

func test_leaks() -> void:
	var game := Game.new(104, 10)
	game.begin_day()
	game.wait_for_data(500)
	var uid: String = game.news_today()[0].uid
	var public: Array = [game.status(), game.news_today(), game.question_today(), game.tools(), game.hand(), game.report_snapshot(), game.verify(uid, "doi_chieu_nguon"), game.wait_for_data(1)]
	check(clean(public), "public APIs hide the late plan")
	check(game.review(1).get("error") == "day_not_reviewable", "review hidden while open")
	var sent: Dictionary = game.submit_report(report(game))
	check(clean(sent) and clean(game.end_day()), "submit and end_day hide the late plan")
	# The same visible state for volatile and calm seeds: only the public fields can differ.
	var keys := {}
	for key in game.status(): keys[key] = true
	check(not keys.has("volatile") and not keys.has("late_answer") and not keys.has("shifted"), "status has no hidden keys")
	# Source text scan: UI scripts never read the hidden plan.
	for path in ["res://scripts/v2/desktop.gd", "res://scripts/v2/windows/report_window.gd", "res://scripts/v2/windows/tools_window.gd", "res://scripts/v2/windows/news_window.gd", "res://scripts/v2/tutorial_panel.gd"]:
		var code := FileAccess.get_file_as_string(path)
		for word in ["_late_plan", "late_plan", "volatile", "original_answer", "shifted"]:
			check(not code.contains(word), "%s does not read %s" % [path, word])

func press(button: Button) -> void:
	button.pressed.emit()

func test_ui() -> void:
	var game := fresh(104)
	var desktop: Control = Desktop.instantiate()
	root.add_child(desktop)
	desktop.setup(game)
	desktop.open_window("report")
	var mail: Control = desktop.report_window
	check(mail.wait_button != null, "Mail shows a wait button")
	check(mail.content.find_child("DeadlineBar", true, false) != null, "Mail shows the deadline bar")
	check(mail.banner == null, "no late banner while on time")
	check(desktop.clock_band == "on_time" and desktop.clock.get_theme_color("font_color") == Color(Loader.load_json("res://data/palette_v2.json").colors[23]), "taskbar clock is green on time")
	var texts: Array = []
	for label in mail.content.find_children("ClockLabel", "Label", true, false): texts.append(label.text)
	check(texts.size() == 1 and "08:30" in texts[0] and "On time" in texts[0], "Mail clock text on time: " + str(texts))
	press(mail.wait_button)
	check(desktop.clock_minutes == 570 and "09:30" in desktop.clock.text, "Wait button advances the desktop clock")
	for i in 5: press(mail.wait_button)
	check(desktop.clock_minutes == 870 and mail.banner == null, "14:30 is still on time")
	press(mail.wait_button)
	check(desktop.clock_minutes == 930 and desktop.clock_band == "late", "15:30 is late")
	check(mail.banner != null and mail.banner.get_child(0).text.begins_with("Late:"), "yellow Late banner appears before Send")
	check(desktop.clock.get_theme_color("font_color") == Color(Loader.load_json("res://data/palette_v2.json").colors[27]), "taskbar clock is yellow when late")
	check(desktop.entries.any(func(e): return e.uid.ends_with("-late")), "Browser gets the market update")
	mail.choose_forecast("tang")
	mail.choose_confidence("vua")
	mail.request_submit()
	var asks: Array = []
	for label in mail.confirm_panel.find_children("*", "Label", true, false): asks.append(label.text)
	check(asks.size() == 1 and asks[0].begins_with("Send late?"), "confirmation warns about lateness")
	mail.cancel_submit()
	for i in 3: press(mail.wait_button)
	check(desktop.clock_band == "missed" and mail.banner != null and mail.banner.get_child(0).text.begins_with("Deadline missed"), "missed banner")
	check(mail.wait_button.disabled, "wait disabled after the deadline")
	# Code Pad shows the time cost.
	desktop.open_window("tools")
	var costs: Array = []
	for label in desktop.tools_window.content.find_children("*", "Label", true, false): costs.append(label.text)
	check(costs.any(func(t): return t.ends_with("30 min")) and costs.any(func(t): return t.ends_with("45 min")), "Code Pad lists minutes per tool")
	desktop.queue_free()

func test_tutorial() -> void:
	var flow: Node = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	root.add_child(flow)
	flow.start_with_game(Game.new(104, 10))
	flow.skip_intro()
	var desktop: Control = flow.desktop
	check(desktop.coach.current_id() != "deadline", "day 1 has no deadline step")
	desktop.report_window.choose_forecast("ngang")
	desktop.report_window.choose_confidence("thap")
	desktop.report_window.request_submit()
	desktop.report_window.confirm_submit()
	var guard := 0
	while flow.state == "REVIEW" and guard < 12:
		flow.continue_review()
		guard += 1
	flow.skip_intro()
	check(flow.state == "WORK" and flow.game.status().day == 2, "reached day 2")
	check(desktop.coach.active and desktop.coach.current_id() == "deadline", "day 2 shows the deadline step")
	check(desktop.coach.step_label.text.contains("New rule") and desktop.coach.text_label.text.contains("15:00"), "deadline step text")
	check(desktop.coach_rect() == desktop.clock.get_global_rect(), "deadline step points at the clock")
	desktop.coach.skip()
	check(not desktop.coach.active, "deadline step is skippable")
	desktop.open_tutorial()
	check(desktop.coach.active and desktop.coach.current_id() == "question", "Help reopens the full tutorial")
	flow.queue_free()

func run() -> void:
	config = Loader.load_json("res://data/world.json")
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	test_clock()
	test_bands_and_update()
	test_missed_and_late_grading()
	test_leaks()
	test_ui()
	await test_tutorial()
	print("test_v2_t023: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

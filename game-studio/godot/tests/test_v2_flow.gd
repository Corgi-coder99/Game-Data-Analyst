extends SceneTree
# Headless flow tests: the orchestrator is driven through its own API, never by the mouse.
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
const Bots = preload("res://tests/balance_world.gd")
const RANKS := ["thuc_tap", "chuyen_vien", "chuyen_vien_chinh", "truong_nhom", "giam_doc"]
var checks := 0
var failures := 0
var flow: Node
var strings: Dictionary
var categories_seen := {}
var endings_seen := {}
var worst_review_calls := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func new_flow() -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	# T-024: the old flow checks cover work and review only; the evening has its own test_life.
	node.evening_enabled = false
	root.add_child(node)
	return node

# ---- helpers -----------------------------------------------------------

func fixture(world_patch: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var config: Dictionary = Loader.load_json("res://data/world.json").duplicate(true)
	config.macro = {}
	config.noise_factor = 0
	for key in world_patch:
		if config.get(key) is Dictionary and world_patch[key] is Dictionary:
			for inner in world_patch[key]: config[key][inner] = world_patch[key][inner]
		else:
			config[key] = world_patch[key]
	var states: Array = []
	for day in 11:
		var values := {}
		for variable in config.variables: values[variable] = {"direction":"tang", "magnitude":"low"}
		states.append(values)
	var questions: Array = []
	for i in 7: questions.append({"id":"fixture%d" % i, "text":"Test question %d" % i, "variable":"lai_suat", "window_days":0, "answer_rule":"state"})
	var result := {"world":config, "questions":questions, "scenario":{"days":states, "shocks":[]}}
	for key in extra: result[key] = extra[key]
	return result

func submit_ui(forecast: String, confidence: String, pins: int = 0, action_count: int = 0) -> void:
	var desktop: Control = flow.desktop
	for i in pins: desktop.toggle_pin(desktop.entries[i].uid)
	var window: Control = desktop.report_window
	window.choose_forecast(forecast)
	window.choose_confidence(confidence)
	for i in action_count:
		if i < window.cards.size(): window.toggle_action(window.cards[i].id)
	check(window.request_submit(), "confirmation opens")
	check(window.confirming, "confirm box visible state")
	window.confirm_submit()

func finish_review() -> Array:
	var seen_steps: Array = []
	var guard := 0
	while flow.state == "REVIEW" and guard < 12:
		seen_steps.append(flow.review_view.step)
		flow.continue_review()
		guard += 1
	return seen_steps

func expected_reaction(review: Dictionary, confidence: String) -> String:
	var acc := float(review.result.acc)
	if acc >= 1.0: return "right"
	if acc > 0.0: return "partial"
	return {"cao":"wrong_high", "vua":"wrong_mid"}.get(confidence, "wrong_low")

func expected_career(before: Dictionary, after: Dictionary, review: Dictionary) -> String:
	if review.career.fired: return "fired"
	if after.ending == "bankrupt": return "bankrupt"
	if after.demotions > before.demotions: return "demotion"
	if RANKS.find(after.rank) > RANKS.find(before.rank): return "promotion"
	if after.warnings > before.warnings: return "warning"
	return ""

# Plays the current WORK day with a scripted report and verifies the boss lines of that day.
func scripted_day(forecast: String, confidence: String, pins: int = 0, action_count: int = 0) -> void:
	var game: RefCounted = flow.game
	var before: Dictionary = game.status()
	var log_start: int = flow.boss_log.size()
	flow.skip_intro()
	check(flow.state == "WORK", "intro skipped to WORK")
	submit_ui(forecast, confidence, pins, action_count)
	var day := int(before.day)
	var steps := finish_review()
	check(steps == [0, 1, 2, 3, 4, 5], "review shows six steps in order: " + str(steps))
	var review: Dictionary = game.review(day)
	var after: Dictionary = game.status()
	var entries: Array = flow.boss_log.slice(log_start)
	if flow.state == "END_SCREEN": entries = entries.slice(0, entries.size() - 1)
	var lines := entries.filter(func(e): return e.category != "question")
	var reaction := expected_reaction(review, confidence)
	check(not lines.is_empty() and lines[0].category == reaction and lines[0].text == strings.boss_lines[reaction], "boss reaction matches result: " + reaction)
	categories_seen[reaction] = true
	var career := expected_career(before, after, review)
	if career != "":
		check(lines.size() == 2 and lines[1].category == career and lines[1].text == strings.boss_lines[career], "boss career line: " + career)
		categories_seen[career] = true
	else:
		check(lines.size() == 1, "no career line without a career event")

func finish_ending(expect: String) -> void:
	check(flow.state == "END_SCREEN", "game ends on the end screen: " + flow.state)
	var status: Dictionary = flow.game.status()
	check(status.finished and status.ending == expect, "ending is " + expect + " (got " + str(status.ending) + ")")
	var last: Dictionary = flow.boss_log.back()
	var category: String = expect
	if expect == "survived": category = "survived_won" if status.won else "survived_lost"
	check(last.category == category and last.text == strings.boss_lines[category], "ending boss line: " + category)
	categories_seen[category] = true
	endings_seen[expect] = true

func expected_order(days: int) -> Array:
	var order := ["NEW_GAME"]
	for i in days: order.append_array(["DAY_START", "WORK", "SUBMITTED", "REVIEW"])
	order.append_array(["ENDING", "END_SCREEN"])
	return order

# ---- bots (only the public UI path) -------------------------------------

func verified_day_report(bot: String, rng: RandomNumberGenerator) -> void:
	var game: RefCounted = flow.game
	var desktop: Control = flow.desktop
	var question: Dictionary = game.question_today()
	var topic: String = Bots.topic_for(question.id)
	var forecast := "ngang"
	var confidence := "vua"
	var pins: Array = []
	if bot == "random":
		forecast = ["tang", "giam", "ngang"][rng.randi_range(0, 2)]
		confidence = "cao"
	else:
		var order: Array = ["doi_chieu_nguon", "truy_van_lich_su", "kiem_dinh_gia_thuyet", "lam_sach_du_lieu"]
		if question.id in ["q1", "q4", "q5"]: order = ["truy_van_lich_su", "kiem_dinh_gia_thuyet"]
		if question.id == "q8": order = ["lam_sach_du_lieu", "truy_van_lich_su", "doi_chieu_nguon", "kiem_dinh_gia_thuyet"]
		var today: Array = game.news_today().filter(func(n): return n.topic == topic and n.day == game.status().day)
		var exhausted := false
		for n in today:
			if exhausted: break
			desktop.select_news(n.uid)
			for tool in order:
				var result: Dictionary = desktop.use_tool(tool)
				if not result.ok:
					exhausted = result.error == "no_analysis_energy"
					break
				if result.result != "chua_du_can_cu": break
		var related: Array = game.news_today().filter(func(n): return n.topic == topic and n.verification == "xac_nhan")
		related.sort_custom(func(a, b): return a.day > b.day)
		if not related.is_empty():
			forecast = Bots.interpretation(related[0], question.id)
			for n in related.slice(0, 3): pins.append(n.uid)
		confidence = "cao" if not pins.is_empty() else "thap"
	for uid in pins: desktop.toggle_pin(uid)
	var window: Control = desktop.report_window
	window.choose_forecast(forecast)
	window.choose_confidence(confidence)
	for id in ["onboarding_redesign", "fix_checkout_bug", "support_automation", "loyalty_program", "seo_content", "ads_campaign", "discount"]:
		if window.action_buttons.has(id):
			window.toggle_action(id)
			break
	window.request_submit()
	window.confirm_submit()

func play_bot_game(game: RefCounted, bot: String, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 99
	flow.start_with_game(game)
	var days := 0
	while flow.state == "DAY_START":
		flow.skip_intro()
		if flow.state != "WORK": break
		var before: Dictionary = flow.game.status()
		var start_clock: String = flow.clock_text()
		verified_day_report(bot, rng)
		check(flow.state == "REVIEW" or flow.state == "WORK", "bot submission accepted or visibly rejected")
		if flow.state == "WORK":
			# A rejected bot report must not stall the run: submit a minimal valid one.
			flow.desktop.report_window.choose_forecast("ngang")
			flow.desktop.report_window.choose_confidence("thap")
			flow.desktop.report_window.request_submit()
			flow.desktop.report_window.confirm_submit()
		finish_review()
		days += 1
		check(int(before.day) == days, "day counter follows the loop")
		check(start_clock != "", "clock text present")
	check(flow.state == "END_SCREEN", "bot game reaches the end screen")
	check(flow.game.status().finished, "bot game finished")
	check(flow.visited == expected_order(days), "state order for " + bot + " seed " + str(seed_value) + ": " + str(flow.visited.size()))

# ---- cases --------------------------------------------------------------

func test_good_games() -> void:
	var survived := 0
	var won := 0
	for seed_value in [104, 7, 21, 33, 58, 77, 91, 123, 150, 202]:
		play_bot_game(Game.new(seed_value, 10), "verifier", seed_value)
		var status: Dictionary = flow.game.status()
		check(status.ending == "survived", "good game survives, seed " + str(seed_value) + " ending " + str(status.ending))
		check(status.day == 10, "good game plays ten days")
		if status.ending == "survived": survived += 1
		if status.won: won += 1
		finish_ending("survived")
		await process_frame
	check(survived == 10, "all good games survive")
	check(won >= 5, "good play reaches the winning rank in most seeds: " + str(won))

func test_tool_clock_and_phase() -> void:
	flow.start_with_game(Game.new(104, 10))
	flow.skip_intro()
	var desktop: Control = flow.desktop
	check(desktop.clock_minutes == 8 * 60 + 30 and "08:30" in flow.clock_text(), "work starts at 08:30")
	check(flow.phase == "sang", "morning phase at the start of work")
	desktop.select_news(desktop.entries[0].uid)
	var tool: Dictionary = flow.game.tools()[0]
	var energy: int = flow.game.status().energy
	var result: Dictionary = desktop.use_tool(tool.id)
	check(result.ok and flow.game.status().energy < energy, "tool spends analysis energy")
	check(desktop.clock_minutes == 9 * 60 and "09:00" in flow.clock_text(), "clock advances thirty minutes per tool use")
	check(flow.phase == "trua", "phase changes to noon after the first tool")
	check(desktop.use_tool(tool.id).ok and desktop.clock_minutes == 9 * 60, "cached repeat does not move the clock")
	desktop.select_news(desktop.entries[1].uid)
	desktop.use_tool(tool.id)
	check(desktop.clock_minutes == 9 * 60 + 30, "second paid use moves the clock again")
	check(not flow.game.review(1).has("day") and flow.game.review(1).get("error") == "day_not_reviewable", "day one is not reviewable while open")
	submit_ui("ngang", "thap")
	check(flow.phase == "chieu", "afternoon phase after submission")
	finish_review()
	flow.skip_intro()
	check(flow.state == "WORK" and flow.desktop.clock_minutes == 8 * 60 + 30, "next day restarts at 08:30")
	check(flow.desktop.get_pinned().is_empty() and not flow.desktop.report_window.locked and flow.desktop.report_window.forecast == "", "next day report window is fresh")

func test_bad_game() -> void:
	# Random reports with high confidence and a fragile start: dismissal is reached.
	var fired := false
	for seed_value in range(1, 40):
		var game := Game.new(seed_value, 10, {"world":{"career":{"initial_trust":12}}})
		play_bot_game(game, "random", seed_value)
		if flow.game.status().ending == "fired":
			fired = true
			finish_ending("fired")
			check(not flow.game.status().won, "fired is a loss")
			break
		await process_frame
	check(fired, "a random high-confidence game ends in dismissal")

func test_scripted_lines() -> void:
	# Fixture world: every answer is "tang", so forecasts are exactly right or wrong.
	# Warning, wrong with low confidence, then recovery to a winning promotion.
	var game := Game.new(77, 10, fixture())
	flow.start_with_game(game)
	scripted_day("giam", "thap")
	scripted_day("tang", "cao", 1)
	scripted_day("ngang", "vua")
	for i in 7: scripted_day("tang", "cao", 1)
	finish_ending("survived")
	check(flow.visited == expected_order(10), "scripted game state order")
	# Promotion early, then a wrong report that demotes.
	var promo := fixture({"grading":{"base":50}, "career":{"minimum_days":2, "correct_streak":2}})
	flow.start_with_game(Game.new(77, 10, promo))
	scripted_day("tang", "cao")
	scripted_day("tang", "cao")
	check(flow.game.status().rank == "chuyen_vien" and flow.game.status().max_actions == 2, "promotion changes the action limit")
	scripted_day("giam", "vua")
	check(flow.game.status().demotions == 1, "demotion happened")
	for i in 7: scripted_day("tang", "thap")
	finish_ending("survived")
	# Dismissal on the first day.
	flow.start_with_game(Game.new(77, 10, fixture({"career":{"initial_trust":1}})))
	scripted_day("giam", "cao")
	check(flow.visited == expected_order(1), "fired after one day")
	finish_ending("fired")
	check(flow.ending_view.ending == "fired" and not flow.ending_view.office.player.visible, "fired ending shows the empty desk")
	# The company runs out of money.
	var company: Dictionary = Loader.load_json("res://data/config.json").duplicate(true)
	company.initial.cash = 1
	flow.start_with_game(Game.new(77, 10, fixture({}, {"simulation":{"config":company}})))
	scripted_day("tang", "cao")
	finish_ending("bankrupt")
	check(flow.ending_view.summary_lines.size() == 6, "ending summary lines")
	# Survives without reaching the winning rank.
	flow.start_with_game(Game.new(77, 10, fixture({"grading":{"base":1}})))
	for i in 10: scripted_day("tang", "thap")
	finish_ending("survived")
	check(not flow.game.status().won and flow.ending_view.boss_category == "survived_lost", "unranked survival is a loss")
	# Partial credit.
	flow.start_with_game(Game.new(77, 10, fixture()))
	scripted_day("ngang", "vua")
	scripted_day("tang", "thap")
	for category in ["right", "partial", "wrong_low", "wrong_mid", "wrong_high", "warning", "promotion", "demotion", "fired", "bankrupt", "survived_won", "survived_lost"]:
		check(categories_seen.has(category), "boss line category exercised: " + category)
	for key in strings.boss_lines: check(categories_seen.has(key), "every boss line used at least once: " + key)

func test_invalid_reports() -> void:
	flow.start_with_game(Game.new(104, 10))
	flow.skip_intro()
	var game: RefCounted = flow.game
	var snapshot: Dictionary = game.status()
	var news: Array = game.news_today()
	var base := {"question_id":game.question_today().id, "forecast":"tang", "confidence":"vua", "evidence":[], "actions":[]}
	var cases := {
		"invalid_question": {"question_id":"nope"},
		"invalid_forecast": {"forecast":"len"},
		"invalid_confidence": {"confidence":"sieu"},
		"too_many_evidence": {"evidence":["a", "b", "c", "d"]},
		"too_many_actions": {"actions":["a", "b", "c", "d", "e"]},
		"invalid_evidence": {"evidence":["khong-co"]},
		"invalid_action": {"actions":["khong-co"]}}
	for code in cases:
		var input: Dictionary = base.duplicate(true)
		for key in cases[code]: input[key] = cases[code][key]
		var result: Dictionary = flow.submit_report(input)
		check(not result.ok and result.error == code, "rejected with " + code + " got " + str(result.get("error")))
		check(flow.last_message == strings.errors[code] and not flow.last_message.is_empty(), "Vietnamese message for " + code)
		check(flow.desktop.report_window.message == strings.errors[code] and flow.desktop.report_window.message_label.text == strings.errors[code], "message visible in the report window: " + code)
		check(flow.state == "WORK" and game.status() == snapshot and game.news_today() == news, "rejection changes nothing: " + code)
	# Every code the report path can return has a Vietnamese string.
	for code in ["invalid_question", "invalid_forecast", "invalid_confidence", "too_many_evidence", "too_many_actions", "invalid_evidence", "invalid_action", "day_closed", "already_submitted", "invalid_actions", "report_required", "day_not_reviewable"]:
		check(strings.errors.has(code) and not str(strings.errors[code]).is_empty(), "error string exists: " + code)
	# Window gating and confirmation.
	var window: Control = flow.desktop.report_window
	check(window.submit_button.disabled and not window.request_submit(), "submit disabled before a choice")
	window.choose_forecast("tang")
	check(window.submit_button.disabled, "submit still disabled without confidence")
	window.choose_confidence("thap")
	check(not window.submit_button.disabled, "submit enabled after both choices")
	check(window.request_submit() and window.confirming and window.confirm_panel != null, "confirmation box appears")
	window.cancel_submit()
	check(not window.confirming and flow.state == "WORK", "cancel keeps working")
	# Action limit follows the rank (one action for an intern).
	var cards: Array = window.cards
	check(window.max_actions == game.status().max_actions and window.max_actions == 1, "action limit shown from status")
	if cards.size() >= 2:
		check(window.toggle_action(cards[0].id) and not window.toggle_action(cards[1].id), "second action refused at the limit")
		check(window.message == strings.report.action_limit % 1, "limit message shown")
		for id in window.action_buttons:
			check(strings.actions.has(id) and window.action_buttons[id].text == strings.actions[id], "contextual action name: " + id)
	# Valid submission, then the second attempt.
	check(window.request_submit(), "confirmation opens again")
	window.confirm_submit()
	check(flow.state == "REVIEW" and not window.request_submit(), "locked window offers no new confirmation")
	var accepted: Dictionary = flow.submit_report(base)
	check(flow.state == "REVIEW" and not accepted.ok, "state is already past WORK so a second submission is rejected")
	check(accepted.error == "day_closed" and accepted.message == strings.errors.day_closed, "second submission message")
	check(game.submit_report(base).error == "day_closed" or game.submit_report(base).error == "already_submitted", "core also rejects a second submission")
	finish_review()

func test_review_only_after_close() -> void:
	var spy := Spy.new(Game.new(104, 10))
	flow.start_with_game(spy)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var days := 0
	while flow.state == "DAY_START":
		flow.skip_intro()
		check(spy.review_calls.size() == days, "review() is not called while the day is open")
		verified_day_report("verifier", rng)
		finish_review()
		days += 1
		check(spy.review_calls.size() == days, "exactly one review() call per finished day")
	for call in spy.review_calls:
		check(call.ended and call.ok, "review() only called for a day that already ended: " + str(call.day))
	check(spy.review_calls.size() == 10, "ten reviews for ten days")
	finish_ending("survived")

func test_title_and_screens() -> void:
	flow.start_title()
	check(flow.state == "TITLE" and flow.title_view != null, "title shown")
	var title: Control = flow.title_view
	check(title.disclaimer_label.text == strings.ui.disclaimer, "mandatory disclaimer on the title")
	check(strings.ui.disclaimer == "Data and names in this game are fictional and generated by simulation. Not real market data and not investment advice. Some content and code were created with AI assistance.", "disclaimer text is the exact English disclaimer")
	check(title.name_label.text == "Data Corp (working title)", "title name")
	check(title.play_button.text == "Play" and title.quit_button.text == "Quit", "title buttons")
	title.play_button.pressed.emit()
	check(flow.state == "DAY_START" and flow.visited.slice(-2) == ["NEW_GAME", "DAY_START"], "Play starts a new game")
	check(flow.game.status().day == 1, "first day began")
	# Day-one arrival: the player walks in, then the boss asks the question.
	var office: Node2D = flow.office
	check(office.arrival_active and not flow.boss_shown, "arrival animation runs on day one")
	office.advance(5.0)
	check(flow.boss_shown and office.dialog.visible and office.dialog_text.text == flow.game.question_today().text, "boss asks today's question after sitting down")
	office.hide_dialog()
	check(flow.state == "WORK", "closing the dialog starts work")
	# Esc and a desk click skip the animation on later steps.
	flow.start_with_game(Game.new(9, 10))
	check(flow.state == "DAY_START" and flow.office.arrival_active, "new game restarts the arrival")
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	flow._unhandled_input(escape)
	check(flow.boss_shown and flow.office.player_seated, "Esc skips the arrival")
	flow._unhandled_input(escape)
	check(flow.state == "WORK", "Esc again skips the boss dialog")
	scripted_submit_minimal()
	finish_review()
	check(flow.state == "DAY_START" and flow.office.player_seated, "later days start seated")
	flow.office.desk_clicked.emit()
	check(flow.boss_shown, "a desk click skips to the boss question")
	flow.office.desk_clicked.emit()
	check(flow.state == "WORK", "a desk click after the question starts work")

func scripted_submit_minimal() -> void:
	submit_ui("ngang", "thap")

func test_fade() -> void:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = true
	root.add_child(node)
	node.start_title()
	check(node.state == "TITLE" and node.fade_time >= 0.0, "fade started")
	var alphas: Array = []
	var swapped_at := -1
	for i in 9:
		node._process(0.0351)
		alphas.append(snappedf(node.fade_rect.color.a, 0.001))
		if swapped_at < 0 and node.title_view != null: swapped_at = i
	check(alphas.all(func(a): return a in [0.0, 0.25, 0.5, 0.75, 1.0]), "fade alpha moves in 25 percent steps: " + str(alphas))
	check(alphas.has(1.0) and alphas[-1] == 0.0 and node.fade_time < 0.0, "fade reaches full and ends clear")
	check(node.title_view != null and swapped_at >= 3, "view swapped at the dark point")
	check(Flow.FADE_STEP * 8.0 <= 0.3, "whole transition within 300 ms")
	check(node.fade_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE, "fade layer lets clicks through when idle")
	node.queue_free()

func test_static_rules() -> void:
	var review_calls := 0
	var files_with_review: Array = []
	var pattern := RegEx.new()
	pattern.compile("\\.review\\(")
	var hidden := RegEx.new()
	hidden.compile("\\b(truth|root_cause|states)\\b")
	for filename in DirAccess.get_files_at("res://scripts/v2"):
		if not filename.ends_with(".gd"): continue
		var source := FileAccess.get_file_as_string("res://scripts/v2/" + filename)
		var found := pattern.search_all(source).size()
		review_calls += found
		if found > 0: files_with_review.append(filename)
		if filename != "review_scene.gd": check(hidden.search(source) == null, filename + " does not read hidden labels")
	for filename in DirAccess.get_files_at("res://scripts/v2/windows"):
		if filename.ends_with(".gd"):
			var source := FileAccess.get_file_as_string("res://scripts/v2/windows/" + filename)
			check(pattern.search(source) == null and hidden.search(source) == null, filename + " is clean")
	check(files_with_review == ["review_scene.gd"] and review_calls == 1, "only review_scene.gd calls review(), exactly once: " + str(files_with_review))
	var flow_source := FileAccess.get_file_as_string("res://scripts/v2/game_flow.gd")
	check(flow_source.find("_sim") < 0 and flow_source.find("_career") < 0 and flow_source.find("_config") < 0, "flow touches no private WorldGame state")
	# Every ending, truth label and action name has a Vietnamese string.
	for key in ["fired", "bankrupt", "survived"]: check(strings.ending.has(key), "ending string " + key)
	for key in ["dung", "sai", "mot_phan", "cu", "khong_lien_quan"]: check(strings.truth.has(key), "truth label " + key)
	var cards: Array = Loader.load_json("res://data/cards.json").cards
	for card in cards:
		if card.category != "analysis": check(strings.actions.has(card.id), "action renamed: " + card.id)
	var events: Array = Loader.load_json("res://data/events.json").events
	for event in events: check(strings.shocks.has(event.id), "shock named: " + event.id)

func test_max_actions_in_status() -> void:
	var game := Game.new(104, 10)
	check(game.status().max_actions == 1, "intern limit is one action")

func test_twenty_seeds() -> void:
	var bots := ["verifier", "random", "verifier", "random", "verifier"]
	var ended := 0
	for i in 20:
		var seed_value := 1000 + i * 37
		play_bot_game(Game.new(seed_value, 10), bots[i % bots.size()], seed_value)
		if flow.state == "END_SCREEN" and flow.game.status().finished: ended += 1
		await process_frame
	check(ended == 20, "twenty automatic games finish without script failure: " + str(ended))

func run() -> void:
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	flow = new_flow()
	test_static_rules()
	test_max_actions_in_status()
	test_fade()
	test_title_and_screens()
	test_tool_clock_and_phase()
	test_invalid_reports()
	await test_good_games()
	await test_bad_game()
	test_scripted_lines()
	test_review_only_after_close()
	await test_twenty_seeds()
	print("test_v2_flow: %d checks, %d failures" % [checks, failures])
	print("endings seen: ", endings_seen.keys(), " boss categories: ", categories_seen.keys())
	quit(1 if failures else 0)

class Spy extends RefCounted:
	var inner: RefCounted
	var review_calls: Array = []
	var ended_days: Array = []
	func _init(value: RefCounted) -> void: inner = value
	func begin_day() -> void: inner.begin_day()
	func news_today() -> Array: return inner.news_today()
	func question_today() -> Dictionary: return inner.question_today()
	func tools() -> Array: return inner.tools()
	func verify(uid: String, tool_id: String) -> Dictionary: return inner.verify(uid, tool_id)
	func hand() -> Array: return inner.hand()
	func submit_report(input: Dictionary) -> Dictionary: return inner.submit_report(input)
	func end_day() -> Dictionary:
		var result: Dictionary = inner.end_day()
		if result.ok: ended_days.append(result.day)
		return result
	func review(day: int) -> Dictionary:
		var result: Dictionary = inner.review(day)
		review_calls.append({"day":day, "ended":day in ended_days, "ok":not result.has("error")})
		return result
	func status() -> Dictionary: return inner.status()
	func report_snapshot() -> Dictionary: return inner.report_snapshot()

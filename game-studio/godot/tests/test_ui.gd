extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var title = load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	check(title.get_node("Menu/Play").text == "Chơi", "title loaded with Vietnamese strings")
	title.queue_free()
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.start_game(105)
	check(game.simulation.horizon == 10, "demo horizon")
	check(game.get_node("Layout/Hand").get_child_count() == 4, "four cards")
	var original_hand: Array = game.simulation.hand.duplicate(true)
	check(not game.play_card("missing"), "reject unknown card")
	check(game.simulation.hand == original_hand, "rejection preserves hand")
	check(not game.get_node("Layout/Status").text.is_empty(), "rejection explained")
	var priority := ["onboarding_redesign", "fix_checkout_bug", "ads_campaign", "support_automation", "seo_content", "loyalty_program", "clean_data", "sql_deep_dive", "funnel_report", "ab_test", "discount", "influencer_campaign"]
	var weeks := 0
	while not game.ended and weeks < 10:
		for id in priority:
			for card in game.simulation.hand.duplicate():
				if card.id == id:
					game.play_card(id)
		game.finish_week()
		weeks += 1
	check(weeks == 10, "controller plays all ten weeks")
	check(game.ended and game.simulation.state.won, "demo win")
	var end_screen = game.get_node("End")
	check(end_screen.visible and not game.get_node("Layout").visible, "dedicated end screen")
	check(end_screen.get_node("Layout/Result").text == game.strings.end % [game.strings.won, game.simulation.score()], "win result and score agree with simulation")
	check(end_screen.get_node("Layout/Resolved").text == game.strings.resolved_events % game.simulation.state.resolved, "correctly handled event count")
	check(end_screen.observed.cash == game.displayed_report.cash, "truth table preserves last seen cash")
	check(end_screen.truth.cash == game.simulation.state.value("cash", game.simulation.config), "truth table shows actual final cash")
	check(end_screen.get_node("Layout/Table").get_child_count() == 27, "truth table contains eight metrics and headers")
	await process_frame
	check(end_screen.get_node("Layout").size.x <= 608 and end_screen.get_node("Layout").size.y <= 344, "end layout fits viewport")
	for cell in end_screen.get_node("Layout/Table").get_children():
		check(cell.get_minimum_size().x <= cell.size.x, "truth cell text fits width")
	var font: Font = end_screen.get_theme_font("font")
	for character in "ắằẳẵặấầẩẫậếềểễệốồổỗộớờởỡợứừửữựđĐ":
		check(font.has_char(character.unicode_at(0)), "Vietnamese glyph supported: " + character)
	var final_week: int = game.simulation.state.week
	game.finish_week()
	check(game.simulation.state.week == final_week, "end is terminal")
	check(not game.play_card("discount"), "cannot play after end")
		# Synthetic fixtures use only public simulation APIs to control event visibility.
	end_screen.get_node("Layout/Buttons/Replay").pressed.emit()
	check(not game.ended and not game.has_node("End") and game.get_node("Layout").visible, "replay button starts a new game")
	game.start_game(105)
	game.simulation.active_events.clear()
	var fixture_event: Dictionary = game.simulation.events[0]
	game.simulation.apply_event(fixture_event)
	game.simulation.hand = [game.simulation.cards[0]]
	game.refresh()
	var event_label = game.get_node("Layout/Body/Details/EventScroll/Events")
	check(event_label.text.contains(fixture_event.symptom), "symptom always visible")
	check(not event_label.text.contains(fixture_event.root_cause), "hidden root cause absent from rendered text")
	check(not event_label.text.contains(game.strings.root_cause.split("%s")[0]), "no cause label before reveal")
	check(game.play_card("sql_deep_dive"), "correct reveal card accepted")
	check(event_label.text.contains(fixture_event.root_cause), "root cause visible after reveal card")
	check(game.get_node("Layout/Body/Dashboard/Metrics").get_child_count() == 7, "seven metric tiles")
	var history_size: int = game.history.size()
	game.get_node("Layout/Body/Dashboard/Metrics").get_child(3).pressed.emit()
	check(game.selected_metric == "cac", "tile selects chart metric")
	check(game.get_node("Layout/Body/Dashboard/Chart").values.size() == history_size, "chart uses report history")
	check(game.history.size() == history_size, "chart selection does not request new report")
	check(game.history.back().report == game.displayed_report, "history stores observed report")
	game.simulation.apply_effect({"stat": "integrity", "add": -100}, 0)
	game.refresh()
	check(game.get_node("Layout/Body/Dashboard/Warning").text == game.strings.integrity_warning, "low integrity warning")
	check(game.get_node("Layout/Body/Dashboard/Metrics").get_child(0).text.ends_with(game.strings.uncertain), "low integrity question mark")
	game.start_game(105)
	check(game.history.size() == 1 and game.previous_week.is_empty(), "restart clears chart and weekly baseline")
	var chart = game.get_node("Layout/Body/Dashboard/Chart")
	check(chart.values.size() == 1 and chart.weeks == [1], "single point has week coordinate")
	check(chart.axis_labels.has("Tuần 1") and chart.axis_labels.size() == 3, "single point has min max and week labels")
	game.select_metric("retention")
	check(chart.axis_labels[0].ends_with("%"), "chart uses metric percentage units")
	game.simulation.hand = [game.simulation.cards[0]]
	game.refresh()
	check(not game.get_node("Layout/Hand").get_child(0).tooltip_text.is_empty(), "card hover details")
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	game._input(key)
	check(game.simulation.hand.is_empty(), "key one plays first card")
	key.keycode = KEY_ENTER
	game._input(key)
	check(game.simulation.state.week == 2, "enter finishes week")
	check(not game.previous_week.is_empty(), "weekly comparison baseline retained")
	check(game.get_node("Layout/Body/Details/Journal").text.contains("ước tính"), "journal identifies observed estimates")
	await process_frame
	check(game.get_node("Layout").size.y <= 360, "dashboard fits viewport height")
	check(game.get_node("Layout").size.x <= 640, "dashboard fits viewport width")
	game.start_game(105)
	# Synthetic bankruptcy fixture uses the public effect API, without changing sim data.
	game.simulation.apply_effect({"stat": "cash", "add": -1000000}, 0)
	game.refresh()
	weeks = 0
	while not game.ended and weeks < 10:
		game.finish_week()
		weeks += 1
	check(game.ended and game.simulation.state.lost, "bankruptcy fixture reaches lose branch")
	end_screen = game.get_node("End")
	check(end_screen.get_node("Layout/Result").text == game.strings.end % [game.strings.lost, game.simulation.score()], "lose result and score agree with simulation")
	check(end_screen.observed.users == game.displayed_report.users, "lose table preserves observed users")
	check(end_screen.truth.users == game.simulation.state.value("users", game.simulation.config), "lose table shows actual users")
	check(end_screen.get_node("Layout/Buttons/Replay").text == "Chơi lại" and end_screen.get_node("Layout/Buttons/Title").text == "Về tiêu đề", "Vietnamese navigation buttons")
	end_screen.get_node("Layout/Buttons/Title").pressed.emit()
	await process_frame
	await process_frame
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/title.tscn", "title button navigates to title scene")
	if current_scene != null:
		current_scene.queue_free()
	game.queue_free()
	await process_frame
	print("test_ui: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

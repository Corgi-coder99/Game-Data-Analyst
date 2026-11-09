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
	check(game.get_node("End").visible and not game.get_node("Layout").visible, "temporary end screen")
	check(game.get_node("End").text.begins_with(game.strings.won), "result agrees with simulation")
	var final_week: int = game.simulation.state.week
	game.finish_week()
	check(game.simulation.state.week == final_week, "end is terminal")
	check(not game.play_card("discount"), "cannot play after end")
		# Synthetic fixtures use only public simulation APIs to control event visibility.
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
	game.queue_free()
	await process_frame
	print("test_ui: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

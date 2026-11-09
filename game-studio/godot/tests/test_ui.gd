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
	game.queue_free()
	await process_frame
	print("test_ui: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


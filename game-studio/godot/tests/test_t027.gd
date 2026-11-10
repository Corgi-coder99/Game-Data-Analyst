extends SceneTree
# T-027 headless tests: free shop choice on the street (click any storefront, hover, keyboard selection,
# Go to work, visit minutes, one red light).
# Run: --headless -s res://tests/test_t027.gd
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func new_flow(seed_value: int = 7, transport: String = "walk") -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	node.daily_enabled = true
	node.commute_enabled = true
	root.add_child(node)
	node.seed_used = seed_value
	node.start_with_game(Game.new(seed_value, 10))
	node.quick_advance()
	node.morning_view.choose_transport(transport)
	return node

func run_until(c: Node2D, phase_name: String, limit: int = 4000) -> void:
	var guard := 0
	while c.phase != phase_name and guard < limit:
		guard += 1
		c.advance(0.05)

func key(c: Node, code: int, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.shift_pressed = shift
	c._unhandled_input(event)

func run() -> void:
	test_click_each_shop()
	test_hover()
	test_visit_minutes()
	test_zero_visits_quick_mode()
	test_multiple_visits()
	test_keyboard()
	test_single_light()
	test_vehicles_and_hurry()
	print("test_t027: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_click_each_shop() -> void:
	var ids := ["cafe", "noodle", "mart", "bank", "news", "books"]
	var panels := {"cafe": ["cafe"], "noodle": ["noodle"], "mart": ["mart", "pharmacy"], "bank": ["bank"], "news": ["news"], "books": ["books", "clothing"]}
	var flow := new_flow(4)
	var c: Node2D = flow.commute
	for i in range(ids.size()):
		var id: String = ids[i]
		var rect: Rect2 = c.shop_rect(i)
		check(c.shop_index_at(rect.get_center()) == i, "the storefront rectangle of %s is hit-testable" % id)
		check(c.visit_shop(id) and c.phase == "to_shop", "clicking %s starts the walk" % id)
		run_until(c, "shopping")
		check(flow.state == "SHOP" and flow.shop_view != null, "%s opens its panel" % id)
		check(absf(c.player_x - float(c.SHOP_STOPS[id])) < 1.0, "the player stands at the %s door" % id)
		check(flow.shop_view.shop_ids == panels[id], "%s panel offers %s" % [id, str(panels[id])])
		flow.shop_view.leave_shop()
		check(flow.state == "COMMUTE" and c.phase == "street", "leaving %s returns to the street" % id)
	check(flow.life.vitals.extra_minutes == 30 and flow.life.vitals.stops == 6, "six visits cost 6 x 5 minutes")
	check(not c.visit_shop("nowhere"), "an unknown shop is refused")
	flow.queue_free()

func test_hover() -> void:
	var flow := new_flow(4)
	var c: Node2D = flow.commute
	check(c.hover_index == -1 and not c.tooltip_panel.visible, "no hover at the start")
	var motion := InputEventMouseMotion.new()
	motion.position = c.shop_rect(2).get_center()
	c._unhandled_input(motion)
	check(c.hover_index == 2 and c.tooltip_panel.visible, "hovering CORNER MART highlights it and shows the tooltip")
	check("CORNER MART" in c.tooltip_label.text and "pharmacy" in c.tooltip_label.text and "5 min" in c.tooltip_label.text, "the tooltip names the shop, what it sells and the visit cost: " + c.tooltip_label.text)
	motion = InputEventMouseMotion.new()
	motion.position = Vector2(300, 300)
	c._unhandled_input(motion)
	check(c.hover_index == -1 and not c.tooltip_panel.visible, "leaving the storefront clears the highlight")
	c.visit_shop("cafe")
	c.set_hover(1)
	check(c.hover_index == 1, "hover also works while walking")
	run_until(c, "shopping")
	check(c.hover_index == 1 or c.hover_index == -1, "state is valid in the shop")
	c.set_hover(3)
	check(c.hover_index == -1 and not c.tooltip_panel.visible, "no hover while inside a shop")
	flow.queue_free()

func test_visit_minutes() -> void:
	var flow := new_flow(5)
	var c: Node2D = flow.commute
	var v: RefCounted = flow.life.vitals
	check(int(v.cfg.day.shop_visit_minutes) == 5, "life.json shop_visit_minutes is 5")
	var arrive0: int = c.clock_minutes()
	for i in range(3):
		c.visit_shop(["cafe", "mart", "news"][i])
		run_until(c, "shopping")
		flow.shop_view.leave_shop()
	check(v.extra_minutes == 15 and c.clock_minutes() == arrive0 + 15, "three visits add 15 minutes to the running arrival time")
	check("ARRIVE" in c.arrive_text(), "the clock chip shows the arrival time: " + c.arrive_text())
	flow.queue_free()
	# Many visits: lateness stays capped at +60.
	var late := new_flow(5)
	var lc: Node2D = late.commute
	for i in range(20):
		lc.visit_shop(["cafe", "books"][i % 2])
		run_until(lc, "shopping")
		late.shop_view.leave_shop()
	check(lc.late_minutes_now() == 60 and lc.clock_minutes() == 570, "the running arrival is capped at +60 minutes late")
	lc.go_to_work()
	if lc.phase == "light": lc.answer_prompt("wait")
	var guard := 0
	while late.state == "COMMUTE" and guard < 6000:
		guard += 1
		lc.advance(0.1)
	check(late.state == "DAY_START" and late.late_minutes == 60 and int(late.game.status().minutes) == 570, "the work clock starts exactly 60 minutes late")
	late.queue_free()

func test_zero_visits_quick_mode() -> void:
	var flow := new_flow(9, "bus")
	var c: Node2D = flow.commute
	check(c.selected_index == -1, "Go to work is the default selection")
	check(c.go_button.visible and c.go_button.text == "Go to work", "a Go to work button is shown")
	key(c, KEY_ENTER)
	check(c.phase in ["light", "to_work"], "one Enter ends the street phase")
	if c.phase == "light": key(c, KEY_ENTER)
	var guard := 0
	while flow.state == "COMMUTE" and guard < 4000:
		guard += 1
		c.advance(0.1)
		if c.fast_forward == false: key(c, KEY_ENTER)
	check(flow.state == "DAY_START" and flow.life.vitals.stops == 0, "quick mode: zero visits, arrived at work")
	check(flow.late_minutes == 0, "no visits: the bus arrives before 08:30")
	flow.queue_free()
	# Go to work button press.
	var f2 := new_flow(9)
	f2.commute.go_button.pressed.emit()
	check(f2.commute.phase in ["light", "to_work"] and not f2.commute.go_button.visible, "pressing the button leaves the street")
	f2.queue_free()
	# Esc hurries from anywhere.
	var f3 := new_flow(10)
	key(f3.commute, KEY_ESCAPE)
	check(f3.commute.hurrying and f3.commute.phase in ["waiting", "to_work"], "Esc hurries: wait at the light, then to work")
	var g3 := 0
	while f3.state == "COMMUTE" and g3 < 4000:
		g3 += 1
		f3.commute.advance(0.1)
	check(f3.state == "DAY_START", "Esc reaches the office")
	f3.queue_free()

func test_multiple_visits() -> void:
	var flow := new_flow(6)
	var c: Node2D = flow.commute
	var wallet: int = flow.life.wallet
	for round_number in range(3):
		c.visit_shop("cafe")
		run_until(c, "shopping")
		check(flow.state == "SHOP", "visit %d to the same shop opens the panel" % (round_number + 1))
		check(flow.shop_view.buy("coffee").ok, "coffee bought on visit %d" % (round_number + 1))
		flow.shop_view.leave_shop()
	check(flow.life.wallet == wallet - 12 and flow.life.vitals.extra_minutes == 15 and c.visits == ["cafe", "cafe", "cafe"], "three coffees: -$12 and 15 minutes")
	c.visit_shop("mart")
	run_until(c, "shopping")
	check(flow.shop_view.buy("sandwich").ok, "another shop in the same morning")
	flow.shop_view.leave_shop()
	check(c.visits.size() == 4, "four visits recorded")
	flow.queue_free()

func test_keyboard() -> void:
	var flow := new_flow(4)
	var c: Node2D = flow.commute
	key(c, KEY_TAB)
	check(c.selected_index == 0 and c.tooltip_panel.visible, "Tab selects the first shop and shows its tooltip")
	key(c, KEY_RIGHT)
	check(c.selected_index == 1, "Right selects the next shop")
	key(c, KEY_LEFT)
	key(c, KEY_LEFT)
	check(c.selected_index == -1, "Left goes back to Go to work")
	key(c, KEY_LEFT)
	check(c.selected_index == 5, "Left wraps to the last shop")
	key(c, KEY_TAB, true)
	check(c.selected_index == 4, "Shift+Tab selects the previous shop")
	key(c, KEY_TAB)
	key(c, KEY_TAB)
	check(c.selected_index == -1 and not c.tooltip_panel.visible, "Tab wraps through the Go to work slot")
	key(c, KEY_TAB)
	key(c, KEY_TAB)
	key(c, KEY_TAB)
	check(c.selected_index == 2, "selection is on CORNER MART")
	key(c, KEY_ENTER)
	check(c.phase == "to_shop" and c.target_shop == "mart", "Enter opens the selected shop (walks to its door)")
	run_until(c, "shopping")
	check(flow.state == "SHOP", "the mart panel opened from the keyboard")
	flow.shop_view.leave_shop()
	check(c.selected_index == 2, "the selection stays on the shop just visited")
	flow.queue_free()

func test_single_light() -> void:
	var with_light := 0
	var without := 0
	for seed_number in range(1, 40):
		var flow := new_flow(seed_number)
		var c: Node2D = flow.commute
		var red: bool = flow.life.vitals.light_red
		c.visit_shop("cafe")
		run_until(c, "shopping")
		flow.shop_view.leave_shop()
		c.visit_shop("books")
		run_until(c, "shopping")
		flow.shop_view.leave_shop()
		check(c.results.is_empty() and c.phase == "street", "no light event while shopping (seed %d)" % seed_number)
		c.go_to_work()
		if red:
			with_light += 1
			check(c.phase == "light" and c.paused == "light", "Go to work meets the light (seed %d)" % seed_number)
			c.answer_prompt("wait")
			check(c.phase == "waiting", "waiting pauses briefly")
		else:
			without += 1
			check(c.phase == "to_work", "no red light this morning (seed %d)" % seed_number)
		var guard := 0
		while flow.state == "COMMUTE" and guard < 6000:
			guard += 1
			c.advance(0.1)
		check(c.results.size() == (1 if red else 0), "the light happened exactly once or not at all (seed %d)" % seed_number)
		check(flow.late_minutes == 10 + (4 if red else 0), "two visits (+ light) = late %d (seed %d)" % [flow.late_minutes, seed_number])
		flow.queue_free()
	check(with_light > 0 and without > 0, "both light and no-light mornings occurred (%d/%d)" % [with_light, without])

func test_vehicles_and_hurry() -> void:
	for mode in ["bus", "moto", "taxi"]:
		var flow := new_flow(3, mode)
		var c: Node2D = flow.commute
		check(c.player_visible and c.player_vehicle.is_empty(), "%s: on foot while shopping" % mode)
		c.visit_shop("news")
		run_until(c, "shopping")
		flow.shop_view.leave_shop()
		c.go_to_work()
		if c.phase == "light": c.answer_prompt("run")
		if c.phase == "waiting": c.advance(2.0)
		check(c.phase == "to_work" and not c.player_vehicle.is_empty() and not c.player_visible, "%s: the vehicle takes the player to work" % mode)
		check(absf(c.player_vehicle.x - c.player_x) < 0.1, "%s: the vehicle starts where the player stood" % mode)
		var guard := 0
		while flow.state == "COMMUTE" and guard < 6000:
			guard += 1
			c.advance(0.1)
		check(flow.state == "DAY_START", "%s: arrived at work" % mode)
		flow.queue_free()

extends SceneTree
# T-027 real-mouse test (run WITHOUT --headless): real InputEventMouse events on the free-choice street:
# hover Moonbean Cafe, click it, buy coffee, click Corner Mart, buy a sandwich, Go to work, red light, desk.
# Add `-- --capture` to save screenshots to docs/screenshots-T-027.
const Game = preload("res://scripts/world/world_game.gd")
const Flow = preload("res://scripts/v2/game_flow.gd")
const SCREEN := Rect2(0, 0, 640, 360)
var checks := 0
var failures := 0
var flow: Node
var scale_factor := 2.0
var capture := "--capture" in OS.get_cmdline_user_args()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func settle(frames: int = 3) -> void:
	for i in frames: await process_frame

func shot(name: String) -> void:
	if not capture: return
	await settle(4)
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-027")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("T-027-mouse-" + name + ".png"))

func send_mouse(position: Vector2, pressed: bool, moving: bool = false) -> void:
	var window_position := position * scale_factor
	if moving:
		var motion := InputEventMouseMotion.new()
		motion.position = window_position
		motion.global_position = window_position
		Input.parse_input_event(motion)
	else:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = window_position
		event.global_position = window_position
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(event)
	await process_frame

func click(target: Control, label: String) -> void:
	check(target != null and is_instance_valid(target) and target.is_visible_in_tree(), "clickable: " + label)
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree(): return
	var rect := target.get_global_rect()
	check(SCREEN.encloses(rect), "click target on screen: %s %s" % [label, rect])
	var point := rect.get_center()
	await send_mouse(point, false, true)
	await send_mouse(point, true)
	await send_mouse(point, false)
	await settle(2)

func click_point(point: Vector2, label: String) -> void:
	await send_mouse(point, false, true)
	await send_mouse(point, true)
	await send_mouse(point, false)
	await settle(2)

func walk_until_shop(limit: int = 3000) -> void:
	var guard := 0
	while flow.state == "COMMUTE" and flow.commute.phase == "to_shop" and guard < limit:
		guard += 1
		flow.commute.advance(0.05)
		if guard % 20 == 0: await process_frame
	await settle(3)

# Lets the street run (stepped by hand for speed) until the commute pauses for a prompt.
func walk_until_prompt(limit: int = 3000) -> void:
	var guard := 0
	while flow.state == "COMMUTE" and flow.commute != null and flow.commute.paused == "" and guard < limit:
		guard += 1
		flow.commute.advance(0.05)
		if guard % 20 == 0: await process_frame
	await settle(3)

func red_seed() -> int:
	for seed_number in range(1, 100):
		var probe: Node = Flow.new()
		probe.autostart = false
		probe.fade_enabled = false
		root.add_child(probe)
		probe.start_with_game(Game.new(seed_number, 10))
		var red: bool = probe.life.vitals.light_red
		probe.queue_free()
		if red: return seed_number
	return 1

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t027_mouse needs a real display: run it without --headless")
		quit(2)
		return
	scale_factor = float(root.size.x) / 640.0
	var seed_number := red_seed()
	flow = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	root.add_child(flow)
	flow.seed_used = seed_number
	flow.start_with_game(Game.new(seed_number, 10))
	await settle(4)
	await click(flow.morning_view.buttons.home, "Eat at home")
	await click(flow.morning_view.buttons.walk, "Walk")
	check(flow.state == "COMMUTE", "COMMUTE started")
	await settle(3)
	var commute: Node2D = flow.commute
	check(commute.phase == "street" and commute.go_button.visible, "the street is idle with a Go to work button")
	# Hover the cafe with a real mouse move.
	await send_mouse(commute.shop_rect(0).get_center(), false, true)
	await settle(3)
	check(commute.hover_index == 0 and commute.tooltip_panel.visible, "mouse hover highlights MOONBEAN CAFE and shows the tooltip")
	await shot("hover-cafe")
	# Click the cafe, buy coffee.
	await click_point(commute.shop_rect(0).get_center(), "storefront MOONBEAN CAFE")
	check(commute.phase == "to_shop", "the click starts the walk")
	await walk_until_shop()
	check(flow.state == "SHOP", "the cafe panel opened: " + flow.state)
	var wallet: int = flow.life.wallet
	await click(flow.shop_view.rows.coffee, "Buy coffee")
	check(flow.life.wallet == wallet - 4, "coffee paid: " + str(flow.life.wallet))
	flow.shop_view.stage.advance(0.4)
	await shot("cafe-bought")
	await click(flow.shop_view.get_children().filter(func(c): return c is Button and c.text == "Leave")[0], "Leave")
	check(flow.state == "COMMUTE" and commute.phase == "street", "back on the street")
	await shot("street-after-cafe")
	# Click Corner Mart, buy a sandwich.
	await click_point(commute.shop_rect(2).get_center(), "storefront CORNER MART")
	await walk_until_shop()
	check(flow.state == "SHOP" and flow.shop_view.shop_ids == ["mart", "pharmacy"], "the mart panel opened")
	wallet = flow.life.wallet
	await click(flow.shop_view.rows.sandwich, "Buy sandwich")
	check(flow.life.wallet < wallet, "the sandwich was paid: " + str(flow.life.wallet))
	await click(flow.shop_view.get_children().filter(func(c): return c is Button and c.text == "Leave")[0], "Leave")
	check(flow.state == "COMMUTE" and flow.life.vitals.extra_minutes == 10, "two visits cost 10 minutes")
	# Go to work by the button; the seeded red light stops the player.
	await click(commute.go_button, "Go to work")
	check(commute.paused == "light" and commute.light_state() == "red", "the light turned red")
	await shot("red-light")
	var minutes: int = flow.life.vitals.extra_minutes
	await click(commute.prompt_primary, "Wait for green")
	check(flow.life.vitals.extra_minutes == minutes + 4, "waiting cost 4 minutes")
	var guard := 0
	while flow.state == "COMMUTE" and guard < 400:
		guard += 1
		commute.advance(0.05)
		if guard % 20 == 0: await process_frame
	await settle(3)
	check(flow.state == "DAY_START" and flow.late_minutes == 5 + 5 + 4, "arrived 14 minutes late (walk 40, two visits, wait): " + str(flow.late_minutes))
	flow.skip_intro()
	check(flow.state == "WORK", "at the desk")
	await shot("desktop")
	print("test_t027_mouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

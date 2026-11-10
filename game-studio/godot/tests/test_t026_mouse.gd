extends SceneTree
# T-026 real-mouse test (run WITHOUT --headless): real InputEventMouse events click through one whole
# life day: breakfast, transport, a shop, the red light, the desk (report by API), overtime, the
# evening and the next morning. Add `-- --capture` to save screenshots to docs/screenshots-T-026.
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
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-026")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("T-026-mouse-" + name + ".png"))

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
		printerr("test_t026_mouse needs a real display: run it without --headless")
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
	# Morning: breakfast then transport, by mouse.
	check(flow.state == "MORNING", "starts in the morning")
	await shot("morning")
	var morning: Control = flow.morning_view
	await click(morning.buttons.home, "Eat at home")
	check(flow.state == "TRANSPORT" and flow.life.wallet == 56, "breakfast clicked: -$4, TRANSPORT")
	await click(morning.buttons.walk, "Walk")
	check(flow.state == "COMMUTE" and flow.life.vitals.transport == "walk", "Walk clicked: COMMUTE")
	# Cafe: enter by mouse, buy a coffee, leave.
	await walk_until_prompt()
	var commute: Node2D = flow.commute
	check(commute.paused == "shop" and commute.prompt_panel.visible and commute.current_stop.id == "cafe", "the cafe prompt opened")
	await shot("shop-prompt")
	await click(commute.prompt_primary, "Enter (cafe)")
	check(flow.state == "SHOP", "clicking Enter opens the shop: " + flow.state)
	var wallet: int = flow.life.wallet
	await click(flow.shop_view.rows.coffee, "Buy coffee")
	check(flow.life.wallet == wallet - 4, "the coffee was paid exactly: " + str(flow.life.wallet))
	flow.shop_view.stage.advance(0.4)
	await shot("shop-bought")
	await click(flow.shop_view.get_children().filter(func(c): return c is Button and c.text == "Leave")[0], "Leave")
	check(flow.state == "COMMUTE" and commute.paused == "", "Leave resumes the street")
	# Skip shops by mouse until the red light.
	var guard := 0
	while flow.state == "COMMUTE" and commute.paused != "light" and guard < 12:
		guard += 1
		await walk_until_prompt()
		if commute.paused == "shop": await click(commute.prompt_secondary, "Skip shop " + str(commute.current_stop.id))
	check(commute.paused == "light" and commute.light_state() == "red", "the light turned red and the player stopped")
	await shot("red-light")
	var minutes: int = flow.life.vitals.extra_minutes
	await click(commute.prompt_primary, "Wait for green")
	check(flow.life.vitals.extra_minutes == minutes + 4, "waiting cost 4 minutes")
	guard = 0
	while flow.state == "COMMUTE" and guard < 40:
		guard += 1
		await walk_until_prompt()
		if flow.state != "COMMUTE" or not is_instance_valid(commute): break
		if commute.paused == "shop": await click(commute.prompt_secondary, "Skip shop " + str(commute.current_stop.id))
		elif commute.paused == "waiting":
			for i in 40: commute.advance(0.05)
	check(flow.state == "DAY_START" and flow.late_minutes == 10 + 4, "arrived 14 minutes late (walk + shop stop + wait): " + str(flow.late_minutes))
	flow.skip_intro()
	check(flow.state == "WORK" and flow.hud.show_focus, "work starts with the Focus line")
	await shot("desktop")
	var window: Control = flow.desktop.report_window
	window.choose_forecast("tang")
	window.choose_confidence("vua")
	window.request_submit()
	window.confirm_submit()
	flow.review_view.set_process(false)
	while flow.state == "REVIEW": flow.continue_review()
	await settle(3)
	check(flow.state == "OVERTIME", "overtime after the review")
	var wage_wallet: int = flow.life.wallet
	check(wage_wallet > 40, "the wage is in the wallet")
	await click(flow.overtime_view.buttons.h1, "1 h overtime")
	check(flow.overtime_view.phase == "done" and flow.life.wallet == wage_wallet + 14, "overtime paid $14")
	await shot("overtime")
	await click(flow.overtime_view.buttons.continue, "Continue")
	check(flow.state == "EVENING", "continue goes to the evening")
	await click(flow.evening_view.go_button, "Go home")
	check(flow.state == "MORNING" and flow.life.last_night.bills_paid == 12, "next morning; the bills were paid at night")
	await shot("next-morning")
	print("test_t026_mouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

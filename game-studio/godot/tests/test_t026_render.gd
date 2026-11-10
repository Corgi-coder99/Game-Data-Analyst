extends SceneTree
# T-026 real-window layout test (do NOT run with --headless). Builds every new screen of the daily
# life loop in a real window, measures every visible Control (inside 640x360, text not cut, no sibling
# overlap) and saves PNGs to docs/screenshots-T-026. Run:
#   Godot --path game-studio/godot -s res://tests/test_t026_render.gd
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const SCREEN := Rect2(0, 0, 640, 360)
const TOLERANCE := 0.51
var checks := 0
var failures := 0
var screens := 0
var measured := 0
var flow: Node
var folder := ""

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw

func text_fits(node: Control) -> String:
	if node is Label:
		if node.text.is_empty(): return ""
		var font: Font = node.get_theme_font("font")
		var size: int = node.get_theme_font_size("font_size")
		if node.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var lines: int = node.get_line_count()
			var limit: int = node.max_lines_visible if node.max_lines_visible > 0 else 9999
			if lines > limit: return "wrapped text needs %d lines, limit %d" % [lines, limit]
			var needed: float = lines * node.get_line_height() + (lines - 1) * node.get_theme_constant("line_spacing")
			if needed > node.size.y + TOLERANCE: return "wrapped text needs height %s of %s" % [needed, node.size.y]
			return ""
		if node.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING: return ""
		var width: float = font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if width > node.size.x + TOLERANCE: return "text width %s exceeds %s" % [width, node.size.x]
	elif node is Button:
		if node.text.is_empty(): return ""
		var font2: Font = node.get_theme_font("font")
		var size2: int = node.get_theme_font_size("font_size")
		var style: StyleBox = node.get_theme_stylebox("normal")
		var needed2: float = font2.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size2).x + style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT)
		if needed2 > node.size.x + TOLERANCE: return "button text needs %s of %s" % [needed2, node.size.x]
	return ""

func measure(node: Node, screen: String) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		measured += 1
		check(SCREEN.encloses(rect), "[%s] control inside 640x360: %s %s" % [screen, node.get_path(), rect])
		var problem := text_fits(node)
		check(problem == "", "[%s] text not cut: %s (%s) %s" % [screen, node.get_path(), node.get("text"), problem])
		var parent := node.get_parent()
		if parent is Control and not node.has_meta("overlay"):
			check(parent.get_global_rect().grow(TOLERANCE).encloses(rect), "[%s] child inside its parent: %s %s in %s" % [screen, node.get_path(), rect, parent.get_global_rect()])
		siblings(node, screen)
		if node is ScrollContainer: return
	for child in node.get_children(): measure(child, screen)

func siblings(parent: Control, screen: String) -> void:
	var controls: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not child is ColorRect and not child is Panel and not child.has_meta("overlay") and not child is TextureRect:
			controls.append(child)
	for i in controls.size():
		for j in range(i + 1, controls.size()):
			check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()), "[%s] siblings overlap: %s %s '%s' / %s %s '%s'" % [screen, controls[i].name, controls[i].get_global_rect(), controls[i].get("text"), controls[j].name, controls[j].get_global_rect(), controls[j].get("text")])

func inspect(screen: String, root_node: Node = null) -> void:
	await settle()
	screens += 1
	var before := measured
	measure(root_node if root_node != null else flow, screen)
	print("render ", screen, ": ", measured - before, " controls measured")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("T-026-" + screen + ".png"))

func new_flow(seed_value: int) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	root.add_child(node)
	node.seed_used = seed_value
	node.start_with_game(Game.new(seed_value, 10))
	return node

func red_seed() -> int:
	for seed_number in range(1, 100):
		var probe: Node = new_flow(seed_number)
		var red: bool = probe.life.vitals.light_red
		probe.queue_free()
		if red: return seed_number
	return 1

func walk_to(commute: Node2D, wanted_type: String, wanted_id: String, limit: int = 6000) -> void:
	var guard := 0
	while guard < limit and not (commute.paused == wanted_type and str(commute.current_stop.id) == wanted_id):
		guard += 1
		if commute.paused != "" and not (commute.paused == wanted_type and str(commute.current_stop.id) == wanted_id):
			commute.default_answer()
		commute.advance(0.03)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t026_render requires a real display; omit --headless")
		quit(2)
		return
	folder = ProjectSettings.globalize_path("res://docs/screenshots-T-026")
	var seed_number := red_seed()
	flow = new_flow(seed_number)
	await inspect("morning-breakfast")
	flow.morning_view.choose_breakfast("home")
	await inspect("morning-transport")
	flow.morning_view.choose_transport("walk")
	flow.commute.advance(1.0)
	await inspect("commute-walking")
	walk_to(flow.commute, "shop", "cafe")
	await inspect("commute-shop-prompt")
	check(flow.commute.prompt_panel.visible, "prompt visible")
	flow.commute.answer_prompt("enter")
	await inspect("shop-cafe")
	flow.shop_view.buy("coffee")
	flow.shop_view.stage.advance(0.4)
	await inspect("shop-cafe-bought")
	flow.shop_view.leave_shop()
	walk_to(flow.commute, "shop", "mart")
	flow.commute.answer_prompt("enter")
	await inspect("shop-mart")
	flow.shop_view.select_shop("pharmacy")
	await inspect("shop-pharmacy")
	flow.shop_view.leave_shop()
	walk_to(flow.commute, "light", "light")
	await inspect("commute-red-light")
	flow.commute.answer_prompt("run")
	flow.commute.advance(0.1)
	await inspect("commute-light-result")
	walk_to(flow.commute, "shop", "bank")
	flow.commute.answer_prompt("enter")
	await inspect("shop-bank")
	flow.shop_view.leave_shop()
	walk_to(flow.commute, "shop", "books")
	flow.commute.answer_prompt("enter")
	flow.shop_view.select_shop("clothing")
	await inspect("shop-clothing")
	flow.life.earn(100, "pay", "test")
	flow.shop_view.render()
	flow.shop_view.buy("outfit")
	flow.shop_view.stage.advance(0.4)
	await inspect("shop-clothing-bought")
	flow.life.charge_up_to(flow.life.wallet, "fine", "x")
	flow.shop_view.render()
	await inspect("shop-no-money")
	flow.shop_view.leave_shop()
	flow.commute.hurry()
	var guard := 0
	while flow.state == "COMMUTE" and guard < 4000:
		guard += 1
		flow.commute.advance(0.05)
	check(flow.state == "DAY_START", "arrived at the office: " + flow.state)
	flow.skip_intro()
	await inspect("desktop-hud-focus")
	var window: Control = flow.desktop.report_window
	window.choose_forecast("tang")
	window.choose_confidence("vua")
	window.request_submit()
	window.confirm_submit()
	flow.review_view.set_process(false)
	while flow.state == "REVIEW": flow.continue_review()
	check(flow.state == "OVERTIME", "overtime reached")
	flow.overtime_view.stage.advance(0.4)
	await inspect("overtime-choose")
	flow.overtime_view.work_overtime(3)
	flow.overtime_view.stage.advance(0.4)
	await inspect("overtime-done")
	flow.overtime_view.go_home()
	await inspect("evening-with-hud")
	flow.evening_view.go_home()
	await inspect("morning-next-day")
	flow.queue_free()
	# Poor morning: disabled options.
	flow = new_flow(5)
	flow.life.charge_up_to(flow.life.wallet - 3, "fine", "x")
	flow.morning_view.render()
	await inspect("morning-breakfast-poor")
	flow.morning_view.choose_breakfast("skip")
	await inspect("morning-transport-poor")
	flow.queue_free()
	# Sick day and an angry-bills morning.
	flow = new_flow(9)
	flow.life.vitals.sick_pending = true
	flow.life.vitals.sick_count = 1
	flow._enter_morning()
	await inspect("sick-day")
	flow.queue_free()
	# Low stats: red bars and the drained Focus line.
	flow = new_flow(4)
	flow.life.vitals.stamina = 12
	flow.life.vitals.stress = 90
	flow.life.vitals.health = 25
	flow.life.mood = 20
	flow.hud.queue_redraw()
	flow.morning_view.choose_breakfast("skip")
	flow.morning_view.choose_transport("walk")
	flow.commute.hurry()
	guard = 0
	while flow.state == "COMMUTE" and guard < 4000:
		guard += 1
		flow.commute.advance(0.05)
	flow.skip_intro()
	await inspect("desktop-drained")
	flow.queue_free()
	# Ending with the vitals lines.
	flow = new_flow(12)
	guard = 0
	while flow.state != "END_SCREEN" and guard < 400:
		guard += 1
		match flow.state:
			"EVENING": flow.evening_view.go_home()
			"WORK":
				flow.desktop.report_window.choose_forecast("tang")
				flow.desktop.report_window.choose_confidence("vua")
				flow.desktop.report_window.request_submit()
				flow.desktop.report_window.confirm_submit()
			"REVIEW", "SUBMITTED": flow.continue_review()
			"DAY_START": flow.skip_intro()
			"COMMUTE":
				flow.commute.hurry()
				for i in 400:
					if flow.commute == null: break
					flow.commute.advance(0.05)
			_: flow.quick_advance()
	await inspect("ending-life")
	flow.queue_free()
	print("test_t026_render: %d checks, %d failures, %d screens" % [checks, failures, screens])
	quit(1 if failures > 0 else 0)

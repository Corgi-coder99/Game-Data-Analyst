extends SceneTree
const Game = preload("res://scripts/world/world_game.gd")
const Desktop = preload("res://scenes/v2/desktop.tscn")
const SCREEN := Rect2(0, 0, 640, 360)
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func bounds(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		check(SCREEN.encloses(rect), "global bounds " + str(node.get_path()) + " " + str(rect))
		# Children intentionally scroll outside their viewport; the viewport itself must fit.
		if node is ScrollContainer: return
		siblings(node)
	for child in node.get_children(): bounds(child)

func siblings(parent: Control) -> void:
	var controls: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not child is ColorRect and not child is Panel:
			controls.append(child)
	for i in controls.size():
		for j in range(i + 1, controls.size()):
			check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()), "sibling overlap " + str(controls[i].get_path()) + " / " + str(controls[j].get_path()))

func inspect(desktop: Control, stage: String) -> void:
	print("render stage=", stage, " window=", root.size, " viewport=", root.get_visible_rect(), " scale=", root.content_scale_factor)
	bounds(desktop)
	for row in desktop.news_window.rows.values(): siblings(row)
	for button in desktop.task_buttons.values():
		var rect: Rect2 = button.get_global_rect()
		print("render task ", button.text, " rect=", rect, " minimum=", button.get_combined_minimum_size(), " font=", button.get_theme_font_size("font_size"))
		check(rect.position.y == 345 and rect.size == Vector2(108, 14), "task button exactly 108x14 at y345")
		check(Rect2(0, 344, 640, 16).encloses(rect), "task button within taskbar")
		var font: Font = button.get_theme_font("font")
		for state in ["normal", "pressed", "hover", "disabled", "focus"]:
			var style: StyleBox = button.get_theme_stylebox(state)
			check(font.get_height(button.get_theme_font_size("font_size")) + style.get_content_margin(SIDE_TOP) + style.get_content_margin(SIDE_BOTTOM) <= rect.size.y, "task text fits " + state)
	print("render clock rect=", desktop.clock.get_global_rect(), " minimum=", desktop.clock.get_combined_minimum_size(), " font=", desktop.clock.get_theme_font_size("font_size"))
	check(Rect2(0, 344, 640, 16).encloses(desktop.clock.get_global_rect()), "clock within taskbar")
	for child in desktop.get_children():
		if child is ColorRect and child.position.y == 344:
			check(child.get_global_rect() == Rect2(0, 344, 640, 16), "taskbar exactly 640x16")

func settle() -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_v2_layout_render requires a real display; omit --headless")
		quit(2)
		return
	# Keep project window size/stretch untouched; this reproduces production initialization.
	for early_setup in [true, false]:
		await exercise(early_setup)
	print("test_v2_layout_render: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func exercise(early_setup: bool) -> void:
	var game := Game.new(104, 10)
	game.begin_day()
	var desktop = Desktop.instantiate()
	if early_setup: desktop.setup(game)
	root.add_child(desktop)
	if not early_setup: desktop.setup(game)
	await settle()
	inspect(desktop, "early setup" if early_setup else "ready setup")
	desktop.select_news(desktop.entries[0].uid)
	desktop.use_tool(game.tools()[0].id)
	desktop.toggle_pin(desktop.entries[0].uid)
	for id in desktop.windows:
		desktop.toggle_window(id)
		desktop.toggle_window(id)
	await settle()
	inspect(desktop, "refresh and toggle")
	if "--capture" in OS.get_cmdline_user_args():
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("T-019b-layout-render-early.png" if early_setup else "T-019b-layout-render-ready.png"))
	desktop.queue_free()
	await process_frame

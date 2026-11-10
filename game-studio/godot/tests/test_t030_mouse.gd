extends SceneTree
# T-030 real-mouse test (run WITHOUT --headless): real InputEventMouse events through
# title -> Settings -> Wall of Fame -> back -> Daily Shift (first-run screen) -> one working day -> result saved
# -> title -> Wall of Fame shows the achievement. Add `-- --capture` to save screenshots to docs/screenshots-T-030.
const Flow = preload("res://scripts/v2/game_flow.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const LocalDaySource = preload("res://scripts/meta/local_day_source.gd")
const SCREEN := Rect2(0, 0, 640, 360)
const PATH := "user://t030_mouse_profile.json"
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
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-030")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("T-030-mouse-" + name + ".png"))

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
	await settle(3)

func wipe() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func drain() -> void:
	var guard := 0
	if flow.state == "COMMUTE": flow.commute.hurry()
	while flow.state == "COMMUTE" and guard < 4000:
		guard += 1
		flow.commute.advance(0.1)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t030_mouse needs a real display: run it without --headless")
		quit(2)
		return
	scale_factor = float(root.size.x) / 640.0
	wipe()
	flow = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	flow.meta = Meta.new(PATH, Clock.new("2026-11-10"))
	root.add_child(flow)
	flow.start_title()
	await settle(4)
	await shot("title")
	# Settings: toggle the attendance warnings off and on, change the name.
	await click(flow.title_view.settings_button, "Settings")
	check(flow.state == "SETTINGS", "Settings opened")
	var settings: Control = flow.meta_view
	await click(settings.attendance_button, "attendance toggle")
	check(flow.meta.profile.data.settings.attendance == false and settings.attendance_button.text == "OFF", "toggle OFF with a real click")
	await click(settings.attendance_button, "attendance toggle again")
	check(flow.meta.profile.data.settings.attendance == true and settings.attendance_button.text == "ON", "toggle ON again")
	settings.name_edit.text = "Mouse Tester"
	await click(settings.apply_button, "Save name")
	check(flow.meta.profile.data.display_name == "Mouse Tester", "display name saved")
	await shot("settings")
	await click(settings.back_button, "Back from settings")
	check(flow.state == "TITLE", "back on the title")
	# Wall of Fame: empty, then back.
	await click(flow.title_view.wall_button, "Wall of Fame")
	check(flow.state == "WALL" and flow.meta_view.plaque_nodes.has("empty_0"), "the wall is empty at first")
	await shot("wall-empty")
	await click(flow.meta_view.back_button, "Back from the wall")
	check(flow.state == "TITLE", "back on the title again")
	# Daily Shift: the first-run screen, then the morning with the date seed.
	await click(flow.title_view.daily_button, "Daily Shift")
	check(flow.state == "INTRO", "the first-run explanation appears")
	await shot("intro")
	await click(flow.meta_view.continue_button, "Continue")
	check(flow.state == "MORNING" and flow.run_mode == "daily" and flow.seed_used == LocalDaySource.seed_for_date("2026-11-10"), "Daily Shift started with the date seed")
	await click(flow.morning_view.buttons.home, "Eat at home")
	check(flow.morning_view.step == "transport" and flow.morning_view.buttons.has("bus"), "breakfast chosen with a real click, transport choices shown: " + str(flow.morning_view.buttons.keys()) + " " + flow.morning_view.step)
	if not flow.morning_view.buttons.has("bus"):
		print("test_t030_mouse: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	await click(flow.morning_view.buttons.bus, "Bus")
	check(flow.state == "COMMUTE", "commute")
	drain()
	await settle(3)
	flow.skip_intro()
	check(flow.state == "WORK", "at the desk")
	var window: Control = flow.desktop.report_window
	window.choose_forecast("tang")
	window.choose_confidence("vua")
	window.request_submit()
	window.confirm_submit()
	await settle(2)
	check(flow.state == "REVIEW", "review")
	var guard := 0
	while flow.state == "REVIEW" and guard < 30:
		guard += 1
		flow.continue_review()
		await settle(1)
	check(flow.meta.profile.data.history.size() == 1 and flow.meta.profile.data.history[0].day_id == "daily:2026-11-10:1", "the day result was saved")
	check(flow.toast_log.has("Achievement: First Report"), "achievement toast")
	await shot("after-day-toast")
	# Back to the title; the wall now shows the achievement and the stats.
	flow.start_title()
	await settle(3)
	await click(flow.title_view.wall_button, "Wall of Fame (with a result)")
	var wall: Control = flow.meta_view
	check(wall.plaque_nodes.has("ach_first_report") and flow.meta.profile.data.achievements.has("first_report"), "the wall lists First Report as earned")
	check(wall.plaque_nodes["award_best_day"].earned and wall.plaque_nodes["award_rank"].earned, "best day and rank plaques are earned")
	check(wall.plaque_nodes["ach_first_report"].get_theme_color("font_color") == Color.html(JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v4.json")).colors[88]), "earned achievement drawn in the earned color")
	await shot("wall-with-result")
	await click(wall.back_button, "Back")
	check(flow.state == "TITLE", "back to the title at the end")
	flow.meta.profile.reset(flow.meta.clock.today())
	wipe()
	print("test_t030_mouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

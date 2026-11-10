extends SceneTree
# T-030 real-window layout test (run WITHOUT --headless). Every new screen is built in a real window and
# every visible Control is measured: inside 640x360, text not cut, no overlapping siblings. Screenshots go
# to docs/screenshots-T-030 (add `-- --capture`).
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Awards = preload("res://scripts/meta/awards.gd")
const InputLog = preload("res://scripts/meta/input_log.gd")
const SCREEN := Rect2(0, 0, 640, 360)
const TOLERANCE := 0.51
const PATH := "user://t030_render_profile.json"
var checks := 0
var failures := 0
var screens := 0
var measured := 0
var flow: Node
var capture := "--capture" in OS.get_cmdline_user_args()
var folder := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw

func wipe() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func text_width(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func text_fits(node: Control) -> String:
	if node is Label:
		if node.text.is_empty(): return ""
		var font: Font = node.get_theme_font("font")
		var size: int = node.get_theme_font_size("font_size")
		if node.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var lines: int = node.get_line_count()
			var limit: int = node.max_lines_visible if node.max_lines_visible > 0 else 9999
			if lines > limit: return "wrapped text needs %d lines, limit %d" % [lines, limit]
			var needed_height: float = lines * node.get_line_height() + (lines - 1) * node.get_theme_constant("line_spacing")
			if needed_height > node.size.y + TOLERANCE: return "wrapped text needs height %s of %s (%d lines)" % [needed_height, node.size.y, lines]
			return ""
		if node.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING: return ""
		if text_width(font, node.text, size) > node.size.x + TOLERANCE: return "text width %s exceeds %s" % [text_width(font, node.text, size), node.size.x]
		if font.get_height(size) > node.size.y + TOLERANCE: return "text height %s exceeds %s" % [font.get_height(size), node.size.y]
	elif node is Button:
		if node.text.is_empty(): return ""
		var font: Font = node.get_theme_font("font")
		var size: int = node.get_theme_font_size("font_size")
		var style: StyleBox = node.get_theme_stylebox("normal")
		var needed: float = text_width(font, node.text, size) + style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT)
		if needed > node.size.x + TOLERANCE: return "button text needs %s of %s" % [needed, node.size.x]
	elif node is LineEdit:
		var font: Font = node.get_theme_font("font")
		if font.get_height(node.get_theme_font_size("font_size")) > node.size.y: return "line edit too short"
	return ""

func measure(node: Node, screen: String) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		measured += 1
		check(SCREEN.encloses(rect), "[%s] control inside 640x360: %s %s" % [screen, node.get_path(), rect])
		var minimum: Vector2 = node.get_combined_minimum_size()
		check(rect.size.x + TOLERANCE >= minimum.x and rect.size.y + TOLERANCE >= minimum.y, "[%s] size accommodates minimum: %s actual=%s minimum=%s" % [screen, node.get_path(), rect.size, minimum])
		var problem := text_fits(node)
		check(problem == "", "[%s] text not cut: %s (%s) %s" % [screen, node.get_path(), node.get("text"), problem])
		var parent := node.get_parent()
		if parent is Control and not node.has_meta("overlay"):
			check(parent.get_global_rect().grow(TOLERANCE).encloses(rect), "[%s] child inside its parent: %s %s" % [screen, node.get_path(), rect])
		siblings(node, screen)
	for child in node.get_children(): measure(child, screen)

func siblings(parent: Control, screen: String) -> void:
	var controls: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not child is ColorRect and not child is Panel and not child.has_meta("overlay") and not child is TextureRect:
			if child is Label and child.text == "": continue
			controls.append(child)
	for i in controls.size():
		for j in range(i + 1, controls.size()):
			check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()), "[%s] siblings overlap: %s %s '%s' / %s %s '%s'" % [screen, controls[i].name, controls[i].get_global_rect(), controls[i].get("text"), controls[j].name, controls[j].get_global_rect(), controls[j].get("text")])

func inspect(screen: String, node: Node = null) -> void:
	await settle()
	screens += 1
	var before := measured
	measure(node if node != null else flow, screen)
	print("render ", screen, ": ", measured - before, " controls measured")
	if capture:
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder.path_join("T-030-" + screen + ".png"))

func record(meta: RefCounted, date: String, index: int, accuracy: float, rank: String, confidence: String = "cao") -> Dictionary:
	var result := {"accuracy": accuracy, "evidence_quality": 1.0, "trust_delta": 4.0 if accuracy > 0 else -6.0, "timing": "on_time", "pay": 100, "bonus": 5 if accuracy > 0 else 0, "rank": rank, "trust": 60}
	result["day_score"] = Awards.day_score(result, meta.cfg)
	return InputLog.build("run", date, 500 + index, index, {"question_id": "q", "forecast": "tang", "confidence": confidence, "evidence": ["d1-a"], "actions": []}, 570, {"focus_bonus": 0, "late_minutes": 0}, result)

func populated(meta: RefCounted, days: int) -> void:
	for i in days:
		var date := Clock.add_days("2026-06-01", i)
		meta.clock.set_today(date)
		meta.sink.submit_day(record(meta, date, i + 1, 1.0 if i % 3 != 0 else 0.0, "chuyen_vien_chinh" if i > 20 else "chuyen_vien"))
	meta.finish_run({"ending": "survived"})

func new_flow(meta: RefCounted) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	node.meta = meta
	root.add_child(node)
	return node

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t030_render requires a real display; omit --headless")
		quit(2)
		return
	folder = ProjectSettings.globalize_path("res://docs/screenshots-T-030")
	wipe()
	var meta := Meta.new(PATH, Clock.new("2026-11-10"))
	flow = new_flow(meta)
	flow.start_title()
	await inspect("title")
	flow.open_meta_view("WALL")
	await inspect("wall-empty")
	check(flow.meta_view.plaque_nodes.has("empty_0") and flow.meta_view.plaque_nodes.has("award_streak") and not flow.meta_view.plaque_nodes["award_streak"].earned, "empty wall shows empty and locked plaques")
	# Populated: about five months of play.
	populated(meta, 160)
	meta.clock.set_today("2026-11-10")
	meta.profile.data.display_name = "Nova Starlight"
	check(meta.profile.data.winners.size() == 5, "five monthly winners settled: %d" % meta.profile.data.winners.size())
	flow.meta_view.open(meta)
	await inspect("wall-populated")
	check(flow.meta_view.next_button.visible and flow.meta_view.plaque_nodes.has("winner_3"), "winner paging visible and four plaques shown")
	flow.meta_view.turn_page(1)
	await inspect("wall-page-2")
	check(flow.meta_view.plaque_nodes.has("winner_0") and flow.meta_view.plaque_nodes.has("empty_1"), "page 2 has one winner and empty plaques")
	# Letters.
	meta.profile.data.settings.intro_seen = false
	var intro: Array = meta.pre_run_screens()
	flow.pre_run_queue = [intro[0]]
	flow._next_pre_run()
	var letter_scene: Control = flow.meta_view
	await inspect("intro")
	for step in ["reminder", "warning", "fine", "formal", "termination", "rehire"]:
		var screen: Dictionary = meta.letter_screen({"step": step, "missed": 3, "rep_loss": 12, "fine": 9, "bonus": 5, "rehired": step == "rehire", "line_index": 0})
		letter_scene.open(screen)
		await inspect("letter-" + step)
	# Request leave.
	flow.open_meta_view("LEAVE")
	await settle()
	await inspect("leave")
	flow.meta_view.step("date", 1)
	flow.meta_view.step("days", 1)
	flow.meta_view.step("reason", 3)
	flow.meta_view.submit()
	await inspect("leave-booked")
	check(flow.meta_view.last_result.ok and meta.profile.data.leave.size() == 2, "leave booked in the screen")
	flow.meta_view.step("date", 3)
	flow.meta_view.step("days", 1)
	flow.meta_view.submit()
	await inspect("leave-refused")
	check(not flow.meta_view.last_result.ok, "a request beyond the monthly allowance is refused")
	# Settings.
	flow.open_meta_view("SETTINGS")
	await settle()
	await inspect("settings")
	flow.meta_view.ask_reset()
	await inspect("settings-confirm")
	flow.meta_view.cancel_reset()
	# Toast over the title.
	flow.start_title()
	await settle()
	flow.toast("Achievement: Verified Before Reporting")
	await inspect("title-toast")
	check(flow.toast_view.visible_text() == "Achievement: Verified Before Reporting", "toast visible")
	flow.queue_free()
	wipe()
	print("test_t030_render: %d checks, %d failures, %d screens, %d controls measured" % [checks, failures, screens, measured])
	quit(1 if failures > 0 else 0)

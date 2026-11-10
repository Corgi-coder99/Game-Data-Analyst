extends SceneTree
# Real-window layout test (do NOT run with --headless: headless reports wrong control sizes).
# Every screen of the v2 loop is built in a real window, settled for a few frames, then every
# visible Control is measured with get_global_rect(). Run:
#   Godot --path game-studio/godot -s res://tests/test_v2_screens_render.gd [-- --capture] [-- --fault]
# --capture saves one PNG per screen to the system TEMP folder; --fault deliberately moves a button
# off screen and the run must then FAIL (used once to prove the test can fail).
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
const SCREEN := Rect2(0, 0, 640, 360)
const TOLERANCE := 0.51
var checks := 0
var failures := 0
var flow: Node
var strings: Dictionary
var captures := "--capture" in OS.get_cmdline_user_args()
var fault := "--fault" in OS.get_cmdline_user_args()
var screens := 0
var measured := 0

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

func text_width(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

# Text must not be cut: single lines fit their width, wrapped text fits its height and line limit.
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
		if node.icon != null: needed += node.icon.get_width() + node.get_theme_constant("h_separation")
		if needed > node.size.x + TOLERANCE: return "button text needs %s of %s" % [needed, node.size.x]
		if font.get_height(size) + style.get_content_margin(SIDE_TOP) + style.get_content_margin(SIDE_BOTTOM) > node.size.y + TOLERANCE: return "button height too small"
	return ""

func measure(node: Node, screen: String, scroll_viewport: bool = false) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		measured += 1
		check(SCREEN.encloses(rect), "[%s] control inside 640x360: %s %s" % [screen, node.get_path(), rect])
		var minimum: Vector2 = node.get_combined_minimum_size()
		check(rect.size.x + TOLERANCE >= minimum.x and rect.size.y + TOLERANCE >= minimum.y, "[%s] actual size accommodates minimum: %s actual=%s minimum=%s" % [screen, node.get_path(), rect.size, minimum])
		var problem := text_fits(node)
		check(problem == "", "[%s] text not cut: %s (%s) %s" % [screen, node.get_path(), node.get("text"), problem])
		var parent := node.get_parent()
		if parent is Control and not parent is ScrollContainer and not node is VScrollBar and not node is HScrollBar:
			var parent_rect: Rect2 = parent.get_global_rect()
			check(parent_rect.grow(TOLERANCE).encloses(rect), "[%s] child inside its parent: %s %s in %s" % [screen, node.get_path(), rect, parent_rect])
		siblings(node, screen)
		# Only the scrolling viewport itself must fit; its content is scrolled by design.
		if node is ScrollContainer: return
	for child in node.get_children(): measure(child, screen)

func siblings(parent: Control, screen: String) -> void:
	var controls: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not child is ColorRect and not child is Panel and not child.has_meta("overlay"):
			controls.append(child)
	for i in controls.size():
		for j in range(i + 1, controls.size()):
			var a: Rect2 = controls[i].get_global_rect()
			var b: Rect2 = controls[j].get_global_rect()
			check(not a.intersects(b), "[%s] siblings overlap: %s %s / %s %s" % [screen, controls[i].get_path(), a, controls[j].get_path(), b])

func inspect(screen: String) -> void:
	await settle()
	screens += 1
	if fault and screen == "title":
		flow.title_view.play_button.position = Vector2(630, 350)
		await settle()
	var before := measured
	measure(flow, screen)
	print("render ", screen, ": ", measured - before, " controls measured, window=", root.size, " viewport=", root.get_visible_rect())
	if captures:
		var image := root.get_texture().get_image()
		image.save_png(OS.get_environment("TEMP").path_join("T-022-" + screen + ".png"))

func fixture(world_patch: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var config: Dictionary = Loader.load_json("res://data/world.json").duplicate(true)
	config.macro = {}
	config.noise_factor = 0
	for key in world_patch:
		if config.get(key) is Dictionary and world_patch[key] is Dictionary:
			for inner in world_patch[key]: config[key][inner] = world_patch[key][inner]
		else:
			config[key] = world_patch[key]
	var states: Array = []
	for day in 11:
		var values := {}
		for variable in config.variables: values[variable] = {"direction":"tang", "magnitude":"low"}
		states.append(values)
	var questions: Array = []
	for i in 7: questions.append({"id":"fixture%d" % i, "text":"Test question %d" % i, "variable":"lai_suat", "window_days":0, "answer_rule":"state"})
	var result := {"world":config, "questions":questions, "scenario":{"days":states, "shocks":[]}}
	for key in extra: result[key] = extra[key]
	return result

func submit(forecast: String, confidence: String, pins: int = 0, action_count: int = 0) -> void:
	var desktop: Control = flow.desktop
	for i in pins: desktop.toggle_pin(desktop.entries[i].uid)
	var window: Control = desktop.report_window
	window.choose_forecast(forecast)
	window.choose_confidence(confidence)
	for i in action_count:
		if i < window.cards.size(): window.toggle_action(window.cards[i].id)
	window.request_submit()
	window.confirm_submit()

func review_steps(prefix: String, sweep_progress: float = -1.0) -> void:
	# Animations are stepped by hand so every capture is deterministic.
	flow.review_view.set_process(false)
	for step in 6:
		if step == 5 and sweep_progress >= 0.0: flow.review_view.advance(sweep_progress)
		if step == 0: flow.review_view.advance(0.1)
		await inspect("%s-step%d" % [prefix, step + 1])
		flow.continue_review()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_v2_screens_render needs a real display: run it without --headless")
		quit(2)
		return
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	flow = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	root.add_child(flow)
	# 1. Title.
	flow.start_title()
	await inspect("title")
	check(flow.title_view.disclaimer_label.text == strings.ui.disclaimer and flow.title_view.disclaimer_label.is_visible_in_tree(), "disclaimer visible on the title")
	var lowest: float = flow.title_view.disclaimer_label.get_global_rect().end.y
	check(lowest <= 360.0, "disclaimer sits above the bottom edge")
	# 2. Day start with the boss question, then work.
	flow.start_with_game(Game.new(104, 10))
	await settle()
	for i in 60: flow.commute.advance(0.05)
	await inspect("commute-day1")
	var late: Node2D = load("res://scenes/v2/commute.tscn").instantiate()
	late.day = 9
	flow.add_child(late)
	for i in 70: late.advance(0.05)
	await inspect("commute-day9")
	late.queue_free()
	flow.skip_commute()
	await settle()
	for room in ["data", "finance", "marketing", "executive", "reception", "sales", "meeting", "server", "break"]:
		flow.office.show_room(room)
		flow.office.advance(0.5)
		await inspect("office-" + room)
	flow.office.show_room("data")
	flow.office.advance(5.0)
	await inspect("day-start-boss")
	flow.skip_intro()
	var desktop: Control = flow.desktop
	await inspect("work-home")
	desktop.open_window("news")
	await inspect("work-browser")
	desktop.select_news(desktop.entries[0].uid)
	desktop.news_window.toggle_expanded(desktop.entries[0].uid)
	await inspect("work-browser-expanded")
	desktop.news_window.toggle_expanded(desktop.entries[0].uid)
	desktop.open_window("tools")
	desktop.use_tool(flow.game.tools()[0].id)
	await inspect("work-codepad")
	desktop.open_window("company")
	await inspect("work-bi")
	desktop.open_window("news")
	desktop.toggle_pin(desktop.entries[0].uid)
	desktop.toggle_pin(desktop.entries[1].uid)
	desktop.toggle_pin(desktop.entries[2].uid)
	await inspect("work-after-tool")
	# 3. Report tab: empty, filled, and the confirmation box.
	desktop.toggle_window("report")
	await inspect("work-report-empty")
	var window: Control = desktop.report_window
	window.choose_forecast("giam")
	window.choose_confidence("cao")
	if not window.cards.is_empty(): window.toggle_action(window.cards[0].id)
	if window.cards.size() > 1: window.toggle_action(window.cards[1].id)
	await inspect("work-report-filled")
	window.request_submit()
	await inspect("work-report-confirm")
	for action_name in window.action_buttons:
		var button: Button = window.action_buttons[action_name]
		check(text_width(button.get_theme_font("font"), button.text, 8) + 12 <= button.size.x, "action name fits its row: " + button.text)
	window.cancel_submit()
	window.confirm_submit()
	check(flow.state == "WORK", "cancelled confirmation keeps working")
	window.request_submit()
	window.confirm_submit()
	check(flow.state == "REVIEW", "report submitted")
	# 4. Review steps on the first day and on a later day with a shock.
	await review_steps("review-day1")
	check(flow.state == "DAY_START" or flow.state == "REVIEW", "review ended")
	var shock_seen := false
	flow.start_with_game(Game.new(104, 10, {"world":{"career":{"initial_trust":100}}}))
	var guard := 0
	while flow.state != "END_SCREEN" and guard < 12:
		guard += 1
		flow.skip_intro()
		desktop = flow.desktop
		await settle()
		desktop.select_news(desktop.entries[0].uid)
		desktop.use_tool(flow.game.tools()[1].id)
		submit("ngang", "vua", 1, 1)
		var day: int = flow.game.status().day
		if not shock_seen and not flow.game.review(day).shocks.is_empty():
			shock_seen = true
			await review_steps("review-shock-day")
		else:
			while flow.state == "REVIEW": flow.continue_review()
	check(shock_seen, "a day with a shock was rendered")
	if flow.state == "END_SCREEN": await inspect("ending-" + str(flow.game.status().ending))
	# 5. Promotion sweep, fired, bankrupt and a winning survival.
	flow.start_with_game(Game.new(77, 10, fixture({"grading":{"base":50}, "career":{"minimum_days":2, "correct_streak":2}})))
	for day in 2:
		flow.skip_intro()
		submit("tang", "cao")
		if day == 1:
			await review_steps("review-promotion", 0.2)
		else:
			while flow.state == "REVIEW": flow.continue_review()
	flow.start_with_game(Game.new(77, 10, fixture({"career":{"initial_trust":1}})))
	flow.skip_intro()
	submit("giam", "cao")
	await review_steps("review-fired")
	await inspect("ending-fired")
	var company: Dictionary = Loader.load_json("res://data/config.json").duplicate(true)
	company.initial.cash = 1
	flow.start_with_game(Game.new(77, 10, fixture({}, {"simulation":{"config":company}})))
	flow.skip_intro()
	submit("tang", "cao")
	while flow.state == "REVIEW": flow.continue_review()
	await inspect("ending-bankrupt")
	flow.start_with_game(Game.new(77, 10, fixture({"grading":{"base":30}, "career":{"minimum_days":2, "correct_streak":2}})))
	for day in 10:
		flow.skip_intro()
		submit("tang", "cao")
		while flow.state == "REVIEW": flow.continue_review()
	await inspect("ending-survived-won")
	check(flow.game.status().won and flow.ending_view.boss_category == "survived_won", "winning survival rendered")
	flow.start_with_game(Game.new(77, 10, fixture({"grading":{"base":1}})))
	for day in 10:
		flow.skip_intro()
		submit("tang", "thap")
		while flow.state == "REVIEW": flow.continue_review()
	await inspect("ending-survived-lost")
	print("test_v2_screens_render: %d checks, %d failures, %d screens, %d controls" % [checks, failures, screens, measured])
	quit(1 if failures else 0)

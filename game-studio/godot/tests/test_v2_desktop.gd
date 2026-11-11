extends SceneTree
const Game = preload("res://scripts/world/world_game.gd")
const Desktop = preload("res://scenes/v2/desktop.tscn")
var checks := 0
var failures := 0
var pins_log: Array = []
var toggles: Array = []
var uses: Array = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func scan(directory: String) -> void:
	for filename in DirAccess.get_files_at(directory):
		if not filename.ends_with(".gd"): continue
		var source := FileAccess.get_file_as_string(directory.path_join(filename))
		for identifier in ["truth", "kind", "link", "state_direction", "exaggerates", "scenario", "_scenario", "_news", "_reviews", "template_id", "verify_with", "reliability", "root_cause", "states"]:
			# T-019c: review_scene.gd alone may read the end-of-day truth fields, from review(day) of an ended day.
			if filename == "review_scene.gd" and identifier in ["truth", "kind", "root_cause", "states"]: continue
			var pattern := RegEx.new()
			pattern.compile("\\b" + identifier + "\\b")
			check(pattern.search(source) == null, filename + " excludes " + identifier)
	for child in DirAccess.get_directories_at(directory): scan(directory.path_join(child))

func check_strings(texts: Dictionary) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/news.json"))
	for source in data.sources: check(texts.tiers.has(source.tier), "source tier localized")
	for item in data.news: check(texts.topics.has(item.topic), "topic localized")
	for code in ["chua_kiem_chung", "xac_nhan", "bac_bo", "chua_du_can_cu", "cu"]:
		check(texts.verification.has(code), "verification localized")
	# Extract every literal error returned by the public core and its validators.
	var errors := RegEx.new()
	errors.compile('(?:"error":|return )"([a-z_]+)"')
	for file in ["world_game", "verifier", "report"]:
		var code := FileAccess.get_file_as_string("res://scripts/world/" + file + ".gd")
		for found in errors.search_all(code): check(texts.errors.has(found.get_string(1)), "error localized " + found.get_string(1))

func submission(game: RefCounted) -> Dictionary:
	return {"question_id":game.question_today().id,"forecast":"ngang","confidence":"thap","evidence":[],"actions":[]}

func check_bounds(node: Node, clip: Rect2 = Rect2(0, 0, 640, 360)) -> void:
	var next_clip := clip
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		# Scroll content can extend beyond its viewport; only its visible region is drawn.
		if rect.intersects(clip):
			var visible := rect.intersection(clip)
			check(Rect2(0, 0, 640, 360).encloses(visible), "visible control contained: " + str(node.name))
		var parent := node.get_parent()
		if parent is Control and not parent is ScrollContainer and not node is VScrollBar and not node is HScrollBar:
			check(Rect2(Vector2.ZERO, parent.size).encloses(node.get_rect()), "control fits parent: " + str(node.name) + " rect=" + str(node.get_rect()) + " parent=" + str(parent.size))
		if node.clip_contents: next_clip = clip.intersection(rect)
	for child in node.get_children(): check_bounds(child, next_clip)

# Read settled global geometry and intrinsic minimums: forcing size alone can hide overflow.
func measured_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	rect.size = rect.size.max(control.get_combined_minimum_size())
	return rect

func check_global_controls(node: Node, scroll_clip: Rect2 = Rect2()) -> void:
	if node is Control and node.is_visible_in_tree():
		var actual: Rect2 = node.get_global_rect()
		var measured := measured_rect(node)
		check(actual.size.x >= measured.size.x and actual.size.y >= measured.size.y, "actual size accommodates minimum: " + str(node.get_path()) + " actual=" + str(actual) + " minimum=" + str(measured.size))
		# Only scrolling content may extend offscreen. Test its viewport separately.
		if scroll_clip.has_area():
			if measured.intersects(scroll_clip):
				check(Rect2(0, 0, 640, 360).encloses(measured.intersection(scroll_clip)), "scrolled drawing inside screen")
		else:
			check(Rect2(0, 0, 640, 360).encloses(actual), "global control inside screen: " + str(node.get_path()) + str(actual))
		if node is ScrollContainer: scroll_clip = actual
	for child in node.get_children(): check_global_controls(child, scroll_clip)

func check_siblings(parent: Control) -> void:
	var controls: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not child is Panel and not child is ColorRect:
			controls.append(child)
	for i in controls.size():
		for j in range(i + 1, controls.size()):
			check(not measured_rect(controls[i]).intersects(measured_rect(controls[j])), "sibling rows disjoint: " + str(controls[i].get_path()) + " / " + str(controls[j].get_path()))

func settle() -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw

func check_layout(desktop: Control) -> void:
	# Each app is measured while it is the front window.
	for id in desktop.windows:
		desktop.open_window(id)
		await settle()
		var window: Control = desktop.windows[id]
		check_global_controls(desktop)
		check_siblings(window)
		check_siblings(window.content)
		check(Rect2(58, 30, 442, 290).encloses(window.get_rect()), "window inside the work area: " + id)
		if id == "news":
			var rows: Array = desktop.news_window.rows.values()
			for i in rows.size():
				for j in range(i + 1, rows.size()):
					check(not measured_rect(rows[i]).intersects(measured_rect(rows[j])), "news rows disjoint after layout")
			for row in rows: check_siblings(row)
	desktop.open_window("news")
	await settle()
	check_siblings(desktop.coach)
	var task_area := Rect2(0, 344, 640, 16)
	for button in desktop.task_buttons.values():
		var rect: Rect2 = button.get_global_rect()
		var minimum: Vector2 = button.get_combined_minimum_size()
		check(task_area.encloses(rect) and task_area.encloses(measured_rect(button)), "task button entirely in y344..360")
		check(rect.size.y <= 14 and minimum.y <= 14, "task button actual and minimum height <=14")
		var font: Font = button.get_theme_font("font")
		var font_height: float = font.get_height(button.get_theme_font_size("font_size"))
		for state in ["normal", "pressed", "hover", "disabled", "focus"]:
			var style: StyleBox = button.get_theme_stylebox(state)
			check(font_height + style.get_content_margin(SIDE_TOP) + style.get_content_margin(SIDE_BOTTOM) <= 14, "task button text and margins fit " + state)
		print("layout task ", button.text, ": ", rect, " minimum=", minimum, " font_height=", font_height)
	for child in desktop.get_children():
		if child is ColorRect and child.position.y == 344:
			check(child.get_global_rect() == task_area, "taskbar exactly 640x16 at y344")
	for child in desktop.tools_window.content.get_children():
		if child is Label and (child == desktop.tools_window.result_label or child.text.begins_with(desktop.strings.ui.energy)):
			print("layout tools ", child.text, ": ", child.get_global_rect())
	for window in desktop.windows.values():
		for child in window.get_children():
			if child is Label: print("layout title ", child.text, ": ", child.get_global_rect())
	for row in desktop.news_window.rows.values():
		for child in row.get_children():
			if child is Button:
				print("layout pin: ", child.get_global_rect())
		break
	var company: Control = desktop.company_window.content
	for child in company.get_children():
		if child is ProgressBar or (child is Label and child.text == desktop.strings.metrics.cash):
			print("layout company ", child.get_class(), ": ", child.get_global_rect(), " minimum=", child.get_combined_minimum_size())

func run() -> void:
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	var game := Game.new(104, 10)
	game.begin_day()
	var desktop = Desktop.instantiate()
	root.add_child(desktop)
	desktop.setup(game)
	desktop.evidence_changed.connect(func(ids): pins_log.append(ids.duplicate()))
	desktop.window_toggled.connect(func(id, shown): toggles.append([id, shown]))
	desktop.tool_used.connect(func(uid, id, result): uses.append([uid, id, result]))
	await process_frame
	check(desktop.news_window.rows.size() == game.news_today().size(), "all news shown")
	check(desktop.tools_window.buttons.values().all(func(b): return b.disabled), "no selection disables tools")
	check(not desktop.select_news("missing"), "invalid selection rejected")
	for i in 3: check(desktop.toggle_pin(desktop.entries[i].uid), "pin accepted")
	check(not desktop.toggle_pin(desktop.entries[3].uid), "fourth pin rejected")
	check(pins_log.size() == 3 and pins_log[-1] == desktop.get_pinned(), "pin signals exact")
	var copy: Array = desktop.get_pinned()
	copy.clear()
	check(desktop.get_pinned().size() == 3, "pins defensive copy")
	check(desktop.toggle_pin(desktop.entries[0].uid), "unpin")
	desktop.clear_pins()
	check(desktop.get_pinned().is_empty() and pins_log[-1].is_empty(), "clear emits")
	var uid: String = desktop.entries[0].uid
	check(desktop.select_news(uid), "select valid news")
	var tool: Dictionary = game.tools()[3]
	var before: int = game.status().energy
	var result: Dictionary = desktop.use_tool(tool.id)
	check(result.ok and game.status().energy == before - int(tool.energy), "verification consumes energy")
	check(desktop.news_window.rows[uid].get_meta("verification") == result.result, "verification label updated")
	var cash: float = game.status().cash_report
	check(desktop.use_tool(tool.id).ok and game.status().energy == before - int(tool.energy) and game.status().cash_report == cash, "cached verification free")
	for entry in desktop.entries:
		if game.status().energy == 0: break
		desktop.select_news(entry.uid)
		desktop.use_tool(tool.id)
	check(game.status().energy == 0, "energy exhausted")
	desktop.select_news(desktop.entries[-1].uid)
	check(desktop.tools_window.buttons[tool.id].disabled, "exhausted tool disabled")
	var unchanged: Dictionary = game.status()
	check(not desktop.use_tool(tool.id).ok and game.status() == unchanged, "resource failure preserves state")
	check(desktop.message == desktop.strings.errors.no_analysis_energy and desktop.tools_window.result_label.text == desktop.strings.errors.no_analysis_energy, "exhausted pool shows the no_analysis_energy message")
	check(desktop.tools_window.dots(game.status()) == "○○○" and desktop.tools_window.dots({"energy":2,"energy_max":3}) == "●●○", "energy dots follow the analysis pool")
	check(not desktop.strings.errors.no_analysis_energy.is_empty(), "no_analysis_energy string present")
	desktop.select_news(uid)
	check(not desktop.tools_window.buttons[tool.id].disabled and desktop.use_tool(tool.id).ok, "cached use enabled without energy")
	check(uses.size() >= 5, "tool signals emitted")
	# T-021: one app window at a time; icons open, the taskbar lists open windows, close removes them.
	check(desktop.front == "" and desktop.home.visible and desktop.windows.values().all(func(w): return not w.visible), "desktop starts at home with no window")
	check(desktop.task_buttons.values().all(func(b): return not b.visible), "taskbar lists no window at home")
	for id in desktop.windows:
		desktop.open_window(id)
		check(desktop.windows[id].visible and desktop.front == id and not desktop.home.visible, "window opened: " + id)
		check(desktop.task_buttons[id].visible and desktop.task_buttons[id].button_pressed, "taskbar lists open window: " + id)
		check(desktop.windows.keys().all(func(other): return other == id or not desktop.windows[other].visible), "only the front window shows")
		desktop.toggle_window(id)
		check(not desktop.windows[id].visible and desktop.task_buttons[id].visible and not desktop.task_buttons[id].button_pressed and desktop.home.visible, "taskbar minimizes the front window: " + id)
		desktop.toggle_window(id)
		check(desktop.windows[id].visible, "taskbar restores the window: " + id)
		desktop.close_window(id)
		check(not desktop.windows[id].visible and not desktop.task_buttons[id].visible and desktop.front == "", "window closed: " + id)
	check(toggles.size() == 4 * desktop.windows.size(), "window signals " + str(toggles.size()))
	check(desktop.report_window.max_actions == game.status().max_actions and game.status().max_actions == 1, "report window shows the rank action limit")
	desktop.open_window("report")
	check(desktop.report_window.get_rect() == Rect2(58, 30, 442, 290), "mail window fills the work area")
	desktop.open_window("company")
	check(desktop.company_window.visible and not desktop.report_window.visible, "opening another window replaces the front one")
	for id in desktop.windows: desktop.close_window(id)
	check(desktop.clock_minutes == 8 * 60 + 30 or desktop.clock_minutes > 8 * 60 + 30, "clock tracks tool use")
	await check_layout(desktop)
	scan("res://scripts/v2")
	if "--capture" in OS.get_cmdline_user_args():
		desktop.toggle_pin(uid)
		desktop.toggle_pin(desktop.entries[1].uid)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("T-019b-desktop.png"))
	check_strings(desktop.strings)
	for item in game.tools(): check(desktop.strings.tools.has(item.id), "tool localized")
	# Public-API fake supplies adversarial long text, no private state access by the UI.
	var fake := LongTextGame.new()
	desktop.setup(fake)
	await process_frame
	await process_frame
	check(desktop.entries.size() == 6, "six long items")
	check(desktop.entries[0].day == 6 and desktop.entries[-1].day == 1, "newest first")
	desktop.open_window("news")
	await process_frame
	await process_frame
	for row in desktop.news_window.rows.values():
		check(row.size.x <= desktop.news_window.scroll.size.x, "row width contained")
		for child in row.get_children():
			if child is Label and child.get_theme_font_size("font_size") == 12:
				check(child.get_visible_line_count() == 2, "long headline shows two lines")
				check(child.tooltip_text.length() == 200, "full headline tooltip")
				var tooltip: Control = child._make_custom_tooltip(child.tooltip_text)
				desktop.add_child(tooltip)
				await process_frame
				check(tooltip.size.x <= 320 and tooltip.size.y <= 320, "tooltip contained")
				tooltip.free()
	check_bounds(desktop)
	await check_layout(desktop)
	for a in desktop.windows:
		check(Rect2(58, 30, 442, 290).encloses(desktop.windows[a].get_rect()), "window bounds")
	check(desktop.company_window.current.integrity < 60, "low integrity fixture")
	check(desktop.tools_window.buttons.values().all(func(b): return b.disabled), "budget shortage disables tools")
	var keyboard := InputEventKey.new()
	keyboard.pressed = true
	keyboard.keycode = KEY_DOWN
	desktop.news_window._row_input(keyboard, desktop.entries[0].uid)
	check(desktop.selected == desktop.entries[1].uid, "arrow selects next row")
	keyboard.keycode = KEY_UP
	desktop.news_window._row_input(keyboard, desktop.entries[1].uid)
	check(desktop.selected == desktop.entries[0].uid, "arrow selects previous row")
	keyboard.keycode = KEY_ENTER
	desktop.news_window._row_input(keyboard, desktop.entries[0].uid)
	check(desktop.selected == desktop.entries[0].uid, "enter selects row")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("T-019b-desktop-long.png"))
	# Real seed 104 survives all ten days with this simple public report.
	game = Game.new(104, 10)
	desktop.setup(game)
	for day in range(1, 11):
		game.begin_day()
		desktop.refresh()
		check(game.status().day == day, "day progression")
		check(desktop.entries.size() == game.news_today().size(), "refresh consistent")
		var previous: Dictionary = desktop.company_window.previous.duplicate(true)
		desktop.refresh()
		check(desktop.company_window.previous == previous, "same day refresh preserves previous day")
		desktop.select_news(desktop.entries[0].uid)
		if game.status().energy > 0: check(desktop.use_tool(game.tools()[0].id).ok, "daily tool")
		desktop.clear_pins()
		check(desktop.toggle_pin(desktop.entries[0].uid), "daily pin")
		var input := submission(game)
		input.evidence = desktop.get_pinned()
		check(game.submit_report(input).ok, "daily submit")
		var closed: Dictionary = game.status()
		check(desktop.use_tool(game.tools()[0].id).error == "day_closed" and game.status() == closed, "closed error")
		check(game.end_day().ok, "daily end")
		desktop.refresh()
	check(game.status().finished and game.status().day == 10, "ten days complete")
	desktop.queue_free()
	await process_frame
	print("test_v2_desktop: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

class LongTextGame extends RefCounted:
	func news_today() -> Array:
		var out: Array = []
		for i in 6:
			out.append({"uid":str(i),"day":i + 1,"source_id":"fiction","source_tier":["chinh_thuc","bao_chi","mang_xa_hoi","noi_bo"][i % 4],"source_name":"Simulated source ".repeat(14),"headline":("Simulated long bulletin %d " % i).repeat(12).left(200),"topic":"suc_mua","verification":["chua_kiem_chung","xac_nhan","bac_bo","chua_du_can_cu","cu"][i % 5],"verified_by":[]})
		return out
	func question_today() -> Dictionary: return {"text":"Simulated question ".repeat(20)}
	func status() -> Dictionary: return {"day":6,"horizon":10,"rank":"giam_doc","trust":100,"energy":3,"energy_max":3,"cash_report":0,"finished":false}
	func report_snapshot() -> Dictionary: return {"cash":123456789,"users":1234567,"retention":0.5,"conversion":0.08,"cac":99,"arpu":88,"integrity":45}
	func tools() -> Array: return [{"id":"truy_van_lich_su","energy":1,"budget":60},{"id":"kiem_dinh_gia_thuyet","energy":1,"budget":80},{"id":"doi_chieu_nguon","energy":1,"budget":40},{"id":"lam_sach_du_lieu","energy":1,"budget":100}]

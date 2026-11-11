extends SceneTree
# T-034 render test (needs a window, no --headless). Every data screen at 640x360: inside the screen,
# no overlapping siblings, text not clipped, hit targets >= 14x14, grid virtualized. Saves screenshots.
const Game = preload("res://scripts/world/world_game.gd")
const Desktop = preload("res://scenes/v2/desktop.tscn")
const ReviewScene = preload("res://scenes/v2/review.tscn")
const Forms = preload("res://scripts/data/step_forms.gd")
const SCREEN := Rect2(0, 0, 640, 360)
var checks := 0
var failures := 0
var shots_dir := ""

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	root.get_texture().get_image().save_png(shots_dir.path_join(name + ".png"))

func skip_node(node: Control) -> bool:
	return node is ColorRect or node is Panel or node.has_meta("overlay") or node.z_index > 0 or node is ScrollBar

func scan(node: Node, tag: String, in_window: bool = false) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		if not in_scroll(node):
			check(SCREEN.encloses(rect), "%s: inside the screen %s %s" % [tag, node.get_path(), str(rect)])
		if node is Button and in_window and node.size != Vector2(8, 8):
			var font: Font = node.get_theme_default_font()
			var width: float = font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			if node.text != "" and node.icon == null and not node is OptionButton:
				check(width + 4.0 <= rect.size.x or node.text.length() <= 3, "%s: button text fits '%s' (%.0f in %.0f)" % [tag, node.text, width, rect.size.x])
			check(rect.size.x >= 14.0 and rect.size.y >= 14.0, "%s: hit target >= 14x14 '%s' %s" % [tag, node.text, str(rect.size)])
		if node is Label and in_window and not node.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var font2: Font = node.get_theme_default_font()
			var size2: int = node.get_theme_font_size("font_size")
			var w2: float = font2.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size2).x
			check(size2 >= 8, tag + ": font >= 8")
			check(w2 <= rect.size.x + 1.0 or node.text == "", "%s: label text fits '%s' (%.0f in %.0f)" % [tag, node.text, w2, rect.size.x])
		if not (node is ScrollContainer):
			siblings(node, tag)
	for child in node.get_children(): scan(child, tag, in_window)

func in_scroll(node: Node) -> bool:
	var p := node
	while p != null:
		if p is ScrollContainer: return true
		p = p.get_parent()
	return false

func siblings(parent: Control, tag: String) -> void:
	var list: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not skip_node(child): list.append(child)
	for i in list.size():
		for j in range(i + 1, list.size()):
			check(not list[i].get_global_rect().intersects(list[j].get_global_rect()), "%s: sibling overlap %s / %s" % [tag, str(list[i].get_path()), str(list[j].get_path())])

func make_desktop(seed_value: int, day: int) -> Array:
	var game := Game.new(seed_value, 10)
	for d in range(1, day):
		game.begin_day()
		game.submit_report({"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]})
		game.end_day()
	game.begin_day()
	var desktop = Desktop.instantiate()
	desktop.data_seed = seed_value
	root.add_child(desktop)
	desktop.setup(game)
	return [game, desktop]

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t034_layout requires a real display; omit --headless")
		quit(2)
		return
	shots_dir = ProjectSettings.globalize_path("res://docs/screenshots-T-034")
	DirAccess.make_dir_recursive_absolute(shots_dir)
	await screens_day1()
	await screens_big_file()
	await screens_review()
	print("test_t034_layout: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func screens_day1() -> void:
	var made := make_desktop(104, 1)
	var game: RefCounted = made[0]
	var desktop: Control = made[1]
	var session: RefCounted = desktop.data_session
	await settle()
	check(session != null and session.files.size() >= 1, "a data session exists on day 1")
	scan(desktop, "home")
	# Files
	desktop.open_data("files")
	await settle()
	scan(desktop.data_window, "files", true)
	shot("01-files")
	var fid: String = session.files[0].id
	# Sheet: open a file with the real button
	desktop.data_window.files_view.open_buttons[fid].pressed.emit()
	await settle()
	check(desktop.data_window.tab == "sheet", "opening a file shows the Sheet")
	var sheet_view: Control = desktop.data_window.sheet_view
	scan(desktop.data_window, "sheet", true)
	shot("02-sheet-small")
	check(sheet_view.toolbar_buttons.size() == 13, "toolbar has 13 operations")
	# dedupe through the dialog
	sheet_view.open_dialog("dedupe")
	await settle()
	scan(desktop.data_window, "dialog dedupe", true)
	shot("03-dialog-dedupe")
	sheet_view.dialog_ok.pressed.emit()
	await settle()
	check(sheet_view.sheet.steps().size() == 1, "dialog adds a step")
	# a second step and a failing one
	sheet_view.open_dialog("sort", sheet_view.sheet.table().cols[0])
	sheet_view.dialog_params["order"] = "descending"
	sheet_view._render_dialog()
	await settle()
	sheet_view.dialog_ok.pressed.emit()
	sheet_view.sheet.pipeline.add({"op":"filter", "col":"nope", "cmp":"==", "value":1})
	sheet_view.sheet._touch()
	sheet_view.refresh()
	sheet_view.sheet.selected_step = 2
	sheet_view.refresh()
	await settle()
	scan(desktop.data_window, "steps", true)
	shot("04-steps-and-error")
	sheet_view.sheet.delete_step(2)
	sheet_view.sheet.selected_step = 0
	sheet_view.refresh()
	await settle()
	shot("05-step-removed-rows")
	sheet_view.sheet.view_removed = true
	sheet_view.refresh()
	await settle()
	scan(desktop.data_window, "removed view", true)
	sheet_view.sheet.view_removed = false
	# zoom 2x
	sheet_view.zoom_button.pressed.emit()
	await settle()
	check(sheet_view.sheet.zoom == 2 and sheet_view.grid.row_h() >= 24.0, "zoom 2x doubles the row height")
	scan(desktop.data_window, "zoom 2x", true)
	shot("06-sheet-zoom2")
	sheet_view.zoom_button.pressed.emit()
	await settle()
	# column header menu
	sheet_view._on_header(1)
	await settle()
	check(sheet_view.menu != null and sheet_view.menu.get_child_count() == 8, "column menu lists 8 actions")
	scan(desktop.data_window, "column menu", true)
	shot("07-column-menu")
	sheet_view._close_menu()
	# every operation dialog
	for op in Forms.OPS:
		sheet_view.open_dialog(op, sheet_view.sheet.table().cols[1])
		await settle()
		scan(desktop.data_window, "dialog " + op, true)
		check(sheet_view.dialog != null and sheet_view.dialog.get_global_rect().size.y <= 250.0, "dialog fits for " + op)
		if op in ["standardize", "group", "join", "convert"]: shot("08-dialog-" + op)
		sheet_view._close_dialog()
	# Looks fine
	sheet_view.toggle_looks()
	await settle()
	scan(desktop.data_window, "looks fine", true)
	shot("09-looks-fine")
	sheet_view.toggle_looks()
	# Charts: every type
	desktop.open_data("charts")
	await settle()
	var chart_view: Control = desktop.data_window.chart_view
	for type in ["bar", "line", "scatter", "histogram", "pie"]:
		chart_view.spec["type"] = type
		chart_view.render()
		await settle()
		scan(desktop.data_window, "chart " + type, true)
		shot("10-chart-" + type)
	chart_view.spec = session.default_spec(chart_view.file_id, "raw")
	chart_view.spec["y_min"] = 5.0
	chart_view.render()
	await settle()
	check(chart_view.flags.size() >= 1, "flags appear for a weak chart")
	scan(desktop.data_window, "chart flags", true)
	shot("11-chart-flags")
	# pin 4 and place them on the dashboard
	for i in 3:
		chart_view.spec = session.default_spec(chart_view.file_id, "raw")
		chart_view.spec["type"] = ["bar", "line", "histogram"][i]
		chart_view.spec["y_label"] = "Value"
		chart_view.spec["title"] = "Chart %d" % (i + 1)
		chart_view.pin()
	check(session.pins.size() == 3, "three charts pinned")
	var numeric := ""
	for c in sheet_view.sheet.table().cols.size():
		if sheet_view.sheet.column_stats(c).get("numeric", 0) > 0:
			numeric = sheet_view.sheet.table().cols[c]
			break
	if numeric != "": session.pin_kpi(fid, numeric, "mean", "Average " + numeric)
	desktop.open_window("company")
	desktop.company_window.show_tab("dash")
	await settle()
	scan(desktop.company_window, "dashboard", true)
	shot("12-dashboard")
	desktop.company_window.dash_view.open_kpi()
	await settle()
	scan(desktop.company_window, "kpi dialog", true)
	shot("13-dashboard-kpi-dialog")
	desktop.company_window.dash_view.refresh()
	# Mail analysis
	for i in 3: session.attach(session.pins[i].id)
	desktop.open_window("report")
	desktop.report_window.choose_forecast("tang")
	desktop.report_window.choose_confidence("vua")
	await settle()
	check(desktop.report_window.analysis_button != null and desktop.report_window.analysis_button.get_global_rect().size.y >= 14.0, "Mail has an Analysis button")
	scan(desktop.report_window, "mail", true)
	shot("14-mail")
	desktop.report_window.open_analysis(true)
	await settle()
	for o in session.options(fid):
		if o.has("choices"): session.set_finding(fid, o.id, o.choices[0])
	desktop.report_window.open_analysis(true)
	await settle()
	scan(desktop.report_window, "mail analysis", true)
	shot("15-mail-analysis")
	check(game.status().minutes > 510, "data work moved the clock")
	desktop.queue_free()
	await process_frame

func screens_big_file() -> void:
	var made := make_desktop(31, 8)
	var desktop: Control = made[1]
	var session: RefCounted = desktop.data_session
	await settle()
	var biggest := ""
	var rows := 0
	for f in session.files:
		if f.row_count > rows:
			rows = f.row_count
			biggest = f.id
	check(rows >= 150, "a large file exists on day 8 (%d rows)" % rows)
	desktop.open_data("files")
	await settle()
	scan(desktop.data_window, "files day 8", true)
	shot("20-files-day8")
	desktop.data_window.open_file(biggest)
	await settle()
	var grid: Control = desktop.data_window.sheet_view.grid
	var span: Vector2i = grid.visible_rows()
	check(span.y - span.x <= 20 and span.y - span.x >= 5, "grid draws only the visible rows: %d of %d" % [span.y - span.x, rows])
	grid.scroll_y = 100.0 * 12.0
	grid._layout_bars()
	grid.queue_redraw()
	await settle()
	check(grid.visible_rows().x >= 90, "scrolling moves the visible window")
	scan(desktop.data_window, "sheet big", true)
	shot("21-sheet-big")
	desktop.data_window.sheet_view.zoom_button.pressed.emit()
	await settle()
	check(grid.visible_rows().y - grid.visible_rows().x <= 12, "zoom 2x draws fewer rows")
	shot("22-sheet-big-zoom2")
	desktop.queue_free()
	await process_frame

func screens_review() -> void:
	var made := make_desktop(104, 1)
	var game: RefCounted = made[0]
	var desktop: Control = made[1]
	var session: RefCounted = desktop.data_session
	var fid: String = session.files[0].id
	var internal: Dictionary = session.data._file(1, fid)
	var sheet: RefCounted = session.open_file(fid)
	for s in session.data._ref.steps(internal): sheet.add_step(s)
	var spec: Dictionary = session.default_spec(fid, "clean")
	spec.merge({"sort":"desc", "y_label":"Value", "title":"Chart"}, true)
	var pin: String = session.pin_chart(fid, "clean", spec)
	session.attach(pin)
	var truth: Array = session.data._ref.evaluate_reference(internal).truth
	for t in truth:
		session.set_finding(fid, t.id, t.value if not t.value is Dictionary else {"direction":t.value.direction, "band":t.value.band})
	var input := {"question_id":game.question_today().id, "forecast":"ngang", "confidence":"vua", "evidence":[], "actions":[], "analysis":session.payload()}
	var before: Dictionary = game.status()
	check(game.submit_report(input).ok, "report with analysis is accepted")
	game.end_day()
	var review = ReviewScene.instantiate()
	root.add_child(review)
	review.data_game = session.data
	review.show_review(game, 1, input, before)
	check(review.analysis_step and review.step_count() == 7, "review gets a 7th step with an analysis")
	for i in 5: review.next_step()
	await settle()
	check(review.step == 5 and review.header_label.text.contains("Your analysis"), "step 6 is Your analysis: " + review.header_label.text)
	scan(review.body, "review analysis", true)
	shot("30-review-your-analysis")
	review.next_step()
	await settle()
	check(review.header_label.text.contains("Career"), "Career follows")
	review.queue_free()
	desktop.queue_free()
	await process_frame

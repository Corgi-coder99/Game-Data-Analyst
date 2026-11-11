extends Control
# T-034: the Sheet app. Grid, 13-operation toolbar, column menu, operation dialog with a row-count preview,
# step list (edit, reorder, delete, undo/redo, reset), column summary, "Looks fine?" helper, zoom.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Grid = preload("res://scripts/v2/data/grid_view.gd")
const Forms = preload("res://scripts/data/step_forms.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const HintPopup = preload("res://scripts/v2/learn/hint_popup.gd")
signal changed
var session: RefCounted
var texts: Dictionary = {}
var sheet: RefCounted
var grid: Control
var top: Control
var steps_box: Control
var stats_label: Label
var note_label: Label
var toolbar_buttons: Dictionary = {}
var step_buttons: Array = []
var menu: Control
var menu_catcher: Control
var dialog: Panel
var dialog_op := ""
var dialog_index := -1
var dialog_params: Dictionary = {}
var dialog_ok: Button
var dialog_preview: Label
var looks_panel: Panel
var undo_button: Button
var redo_button: Button
var reset_button: Button
var zoom_button: Button
var pin_button: Button
var file_picker: Control
var remove_button: Button
var hint_button: Button
var note := ""

func build(p_session: RefCounted, p_texts: Dictionary) -> void:
	session = p_session
	texts = p_texts
	size = Vector2(434, 254)
	grid = Grid.new()
	grid.position = Vector2(0, 48)
	grid.size = Vector2(296, 174)
	add_child(grid)
	grid.header_clicked.connect(_on_header)
	grid.cell_clicked.connect(_on_cell)
	top = Control.new()
	top.size = Vector2(434, 14)
	add_child(top)
	for i in Forms.OPS.size():
		var op: String = Forms.OPS[i]
		var b := UI.button(self, texts.ops[op], Rect2((i % 7) * 62, 16 + (i / 7) * 16 - (i / 7), 61, 14), Forms.TITLES[op])
		b.pressed.connect(open_dialog.bind(op))
		toolbar_buttons[op] = b
	steps_box = Control.new()
	steps_box.position = Vector2(300, 48)
	steps_box.size = Vector2(134, 174)
	add_child(steps_box)
	stats_label = UI.label(self, "", Rect2(0, 224, 434, 14), 28)
	note_label = UI.label(self, "", Rect2(74, 240, 360, 14), 7)
	var looks := UI.button(self, texts.sheet.looks, Rect2(0, 240, 70, 14), texts.sheet.looks_title)
	looks.pressed.connect(toggle_looks)
	looks.name = "LooksButton"
	hint_button = HintPopup.add_button(self, self, Rect2(372, 31, 61, 14), session, func(): return sheet.file_id if sheet != null else session.hint_file())
	refresh()

func show_file(file_id: String) -> void:
	sheet = session.sheet(file_id)
	note = ""
	close_overlays()
	refresh()

func close_overlays() -> void:
	_close_menu()
	_close_dialog()
	if looks_panel != null and is_instance_valid(looks_panel):
		remove_child(looks_panel)
		looks_panel.queue_free()
	looks_panel = null

# ---- rendering ----------------------------------------------------------------------------------

func refresh() -> void:
	_render_top()
	_render_steps()
	_render_stats()
	if sheet != null:
		grid.visible = true
		grid.highlight = sheet.highlighted()
		grid.tint_color = 26 if sheet.view_removed else 28
		grid.selected_col = sheet.selected_col
		grid.set_table(sheet.shown_table(), sheet.zoom)
		if sheet.view_removed: grid.highlight = _all_rids(sheet.shown_table())
	else:
		grid.visible = false
		grid.highlight = {}
	for op in toolbar_buttons: toolbar_buttons[op].disabled = sheet == null
	if hint_button != null: hint_button.get_meta("refresh").call()
	note_label.text = note if note != "" else session.message
	changed.emit()

func _all_rids(ds: RefCounted) -> Dictionary:
	var out := {}
	for rid in ds.rids: out[rid] = true
	return out

func _render_top() -> void:
	UI.clear(top)
	var ids: Array = session.files.filter(func(f): return session.opened.has(f.id)).map(func(f): return f.id)
	var names: Array = session.files.filter(func(f): return session.opened.has(f.id)).map(func(f): return f.title)
	if sheet != null and not ids.is_empty():
		var pick := UI.picker(top, self, Rect2(0, 0, 118, 14), ids, sheet.file_id, names)
		pick.picked.connect(func(id):
			session.open_file(id)
			show_file(id))
		file_picker = pick
	else:
		UI.label(top, texts.sheet.none, Rect2(0, 1, 200, 12), 6)
	var rows_text: String = texts.sheet.rows % sheet.row_count() if sheet != null else ""
	UI.label(top, rows_text, Rect2(122, 1, 54, 12), 7)
	undo_button = UI.button(top, texts.sheet.undo, Rect2(178, 0, 34, 14))
	undo_button.disabled = sheet == null or not sheet.can_undo()
	undo_button.pressed.connect(func(): _do(func(): sheet.undo()))
	redo_button = UI.button(top, texts.sheet.redo, Rect2(214, 0, 34, 14))
	redo_button.disabled = sheet == null or not sheet.can_redo()
	redo_button.pressed.connect(func(): _do(func(): sheet.redo()))
	reset_button = UI.button(top, texts.sheet.reset, Rect2(250, 0, 30, 14), "Reset to the raw file")
	reset_button.disabled = sheet == null or sheet.steps().is_empty()
	reset_button.pressed.connect(func(): _do(func(): sheet.reset()))
	zoom_button = UI.button(top, "Zoom " + (texts.sheet.zoom2 if sheet != null and sheet.zoom == 2 else texts.sheet.zoom1), Rect2(282, 0, 44, 14), "Grid zoom 1x / 2x")
	zoom_button.disabled = sheet == null
	zoom_button.pressed.connect(toggle_zoom)
	pin_button = UI.button(top, texts.sheet.pin_table, Rect2(330, 0, 104, 14), "Pin this table so Mail can attach it")
	pin_button.disabled = sheet == null
	pin_button.pressed.connect(func():
		var id: String = session.pin_table(sheet.file_id)
		note = "Pinned." if id != "" else session.message
		refresh())

func _do(action: Callable) -> void:
	if sheet == null: return
	action.call()
	note = ""
	refresh()

func toggle_zoom() -> void:
	if sheet == null: return
	sheet.zoom = 2 if sheet.zoom == 1 else 1
	refresh()

func _render_steps() -> void:
	UI.clear(steps_box)
	step_buttons.clear()
	UI.panel(steps_box, Rect2(0, 0, 134, 174), 3, 4)
	var count: int = 0 if sheet == null else sheet.steps().size()
	UI.label(steps_box, "%s (%d)" % [texts.sheet.steps, count], Rect2(3, 1, 128, 12), 28)
	if sheet == null: return
	if count == 0:
		UI.wrapped(steps_box, texts.sheet.no_steps, Rect2(3, 16, 128, 36), 6, 3)
		return
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(2, 14)
	scroll.size = Vector2(130, 96)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	steps_box.add_child(scroll)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(120, maxi(1, count) * 16)
	scroll.add_child(holder)
	var list: Array = sheet.steps()
	for i in count:
		var report: Dictionary = sheet.step_report(i)
		var failed: bool = not report.get("ok", true)
		var main := UI.button(holder, "%d %s" % [i + 1, texts.ops[list[i].op]], Rect2(0, i * 16, 56, 14), Forms.describe(list[i]))
		main.toggle_mode = true
		main.button_pressed = i == sheet.selected_step
		main.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if failed: main.add_theme_color_override("font_color", Palette.color(26))
		main.pressed.connect(_select_step.bind(i))
		var edit := UI.button(holder, texts.sheet.edit, Rect2(57, i * 16, 14, 14), "Edit this step")
		edit.pressed.connect(edit_step.bind(i))
		var up := UI.button(holder, texts.sheet.up, Rect2(72, i * 16, 14, 14), "Move up")
		up.disabled = i == 0
		up.pressed.connect(func(): _do(func(): sheet.move_step(i, -1)))
		var down := UI.button(holder, texts.sheet.down, Rect2(87, i * 16, 14, 14), "Move down")
		down.disabled = i == count - 1
		down.pressed.connect(func(): _do(func(): sheet.move_step(i, 1)))
		var delete := UI.button(holder, texts.sheet.delete, Rect2(102, i * 16, 14, 14), "Delete this step")
		delete.pressed.connect(func(): _do(func(): sheet.delete_step(i)))
		step_buttons.append({"main":main, "edit":edit, "up":up, "down":down, "delete":delete})
	# detail of the selected step
	var y := 112
	if sheet.selected_step >= 0 and sheet.selected_step < count:
		var report: Dictionary = sheet.step_report(sheet.selected_step)
		UI.wrapped(steps_box, Forms.describe(list[sheet.selected_step]), Rect2(3, y, 128, 22), 7, 2)
		y += 23
		if report.get("ok", true):
			UI.label(steps_box, texts.sheet.preview % [report.get("rows_in", 0), report.get("rows_out", 0)], Rect2(3, y, 128, 12), 22)
			var diff: Dictionary = sheet.step_diff(sheet.selected_step)
			if diff.removed.size() > 0 or diff.changed.size() > 0:
				UI.label(steps_box, "%s  %s" % [texts.sheet.removed % diff.removed.size(), texts.sheet.changed % diff.changed.size()], Rect2(3, y + 12, 128, 12), 28)
			remove_button = UI.button(steps_box, texts.sheet.view_result if sheet.view_removed else texts.sheet.view_removed, Rect2(3, y + 25, 128, 14), "Look at the rows this step removed")
			remove_button.disabled = diff.removed.size() == 0
			remove_button.pressed.connect(func():
				sheet.view_removed = not sheet.view_removed
				refresh())
		else:
			var code := str(report.get("error", ""))
			UI.wrapped(steps_box, texts.sheet.error % [sheet.selected_step + 1, texts.sheet.errors.get(code, code)], Rect2(3, y, 128, 36), 26, 3)

func _select_step(i: int) -> void:
	if sheet == null: return
	sheet.selected_step = i
	sheet.view_removed = false
	refresh()

func _render_stats() -> void:
	if sheet == null:
		stats_label.text = ""
		return
	var st: Dictionary = sheet.column_stats(sheet.selected_col)
	if st.is_empty():
		stats_label.text = texts.sheet.stats_none
	elif st.numeric > 0:
		stats_label.text = texts.sheet.stats % [st.name, st.count, UI.fmt(st.mean), UI.fmt(st.median), UI.fmt(st.min), UI.fmt(st.max), st.nulls]
	else:
		stats_label.text = texts.sheet.stats_text % [st.name, st.count, st.nulls]

# ---- grid interaction ------------------------------------------------------------------------------

func _on_cell(col: int, row: int) -> void:
	if sheet == null: return
	grid.selected_row = row
	sheet.select_col(col)
	_render_stats()
	grid.selected_col = sheet.selected_col
	grid.queue_redraw()

func _on_header(col: int) -> void:
	if sheet == null: return
	sheet.select_col(col)
	_render_stats()
	grid.selected_col = col
	grid.queue_redraw()
	_open_menu(col)

func _close_menu() -> void:
	for node in [menu, menu_catcher]:
		if node != null and is_instance_valid(node):
			if node.get_parent() != null: node.get_parent().remove_child(node)
			node.queue_free()
	menu = null
	menu_catcher = null

func _open_menu(col: int) -> void:
	_close_menu()
	menu_catcher = Control.new()
	menu_catcher.size = size
	menu_catcher.z_index = 40
	menu_catcher.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _close_menu())
	add_child(menu_catcher)
	var col_name: String = str(sheet.shown_table().cols[col])
	var entries: Array = [
		[texts.sheet.menu_sort_asc, func(): _quick_sort(col_name, false)],
		[texts.sheet.menu_sort_desc, func(): _quick_sort(col_name, true)],
		[texts.sheet.menu_filter, func(): open_dialog("filter", col_name)],
		[texts.sheet.menu_text, func(): open_dialog("standardize", col_name)],
		[texts.sheet.menu_convert, func(): open_dialog("convert", col_name)],
		[texts.sheet.menu_missing, func(): open_dialog("missing", col_name)],
		[texts.sheet.menu_date, func(): open_dialog("parse_date", col_name)],
		[texts.sheet.menu_compute, func(): open_dialog("computed", col_name)]]
	menu = UI.panel(self, Rect2(clampf(grid.position.x + grid.column_left(col), 0.0, 296.0 - 124.0), grid.position.y + 14, 124, entries.size() * 14 + 4), 3, 94)
	menu.z_index = 41
	menu.name = "ColumnMenu"
	for i in entries.size():
		var b := UI.button(menu, entries[i][0], Rect2(2, 2 + i * 14, 120, 14))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var action: Callable = entries[i][1]
		b.pressed.connect(func():
			_close_menu()
			action.call())

func _quick_sort(col_name: String, desc: bool) -> void:
	if sheet == null: return
	var r: Dictionary = sheet.add_step({"op":"sort", "col":col_name, "desc":desc})
	note = texts.sheet.preview % [r.rows_before, r.rows_after] if r.get("ok", false) else str(r.get("error", ""))
	refresh()

# ---- operation dialog -----------------------------------------------------------------------------

func _close_dialog() -> void:
	if dialog != null and is_instance_valid(dialog):
		if dialog.get_parent() != null: dialog.get_parent().remove_child(dialog)
		dialog.queue_free()
	dialog = null
	dialog_ok = null
	dialog_preview = null

func open_dialog(op: String, col: String = "", index: int = -1) -> void:
	if sheet == null: return
	_close_menu()
	dialog_op = op
	dialog_index = index
	if index >= 0: dialog_params = Forms.params_from_step(sheet.steps()[index])
	else:
		dialog_params = Forms.default_params(op, col)
		_fix_defaults(op)
	_render_dialog()

func edit_step(index: int) -> void:
	if sheet == null or index < 0 or index >= sheet.steps().size(): return
	sheet.selected_step = index
	open_dialog(str(sheet.steps()[index].op), "", index)

# Columns, tables and defaults that depend on the table the step runs on.
func _fix_defaults(op: String) -> void:
	var cols: Array = _cols()
	for f in Forms.fields(op):
		if f.type == "col" and not cols.has(dialog_params.get(f.key, "")): dialog_params[f.key] = cols[0] if not cols.is_empty() else ""
		if f.type == "table": dialog_params[f.key] = sheet.context.keys()[0] if not sheet.context.is_empty() else ""
		if f.type == "other_col": dialog_params[f.key] = _other_cols(str(dialog_params.get("other", "")))[0] if not _other_cols(str(dialog_params.get("other", ""))).is_empty() else ""

func _cols() -> Array:
	return sheet.table_before(dialog_index).cols.duplicate()

func _other_cols(table_name: String) -> Array:
	return sheet.context[table_name].cols.duplicate() if sheet.context.has(table_name) else []

func _render_dialog() -> void:
	_close_dialog()
	dialog = UI.panel(self, Rect2(40, 8, 354, 236), 2, 94)
	dialog.z_index = 30
	dialog.name = "OperationDialog"
	var title: String = Forms.TITLES[dialog_op] if dialog_index < 0 else texts.sheet.dialog_edit + ": " + Forms.TITLES[dialog_op]
	UI.label(dialog, title, Rect2(6, 2, 340, 12), 28)
	var y := 18
	var cols := _cols()
	for f in Forms.fields(dialog_op):
		var key: String = f.key
		if dialog_op == "missing" and key == "value" and dialog_params.get("mode", "") != "value": continue
		if dialog_op == "convert":
			var mode: String = dialog_params.get("mode", "number")
			if key == "factor" and mode != "scale": continue
			if key in ["currency_col", "rates"] and mode != "currency": continue
		if dialog_op == "computed":
			var fn: String = dialog_params.get("fn", "add")
			if key in ["b", "b_value"] and fn not in ["add", "sub", "mul", "div"]: continue
			if key == "window" and fn != "moving_avg": continue
			if key == "b_value" and dialog_params.get("b", Forms.NONE) != Forms.NONE: continue
		if dialog_op == "filter" and key == "value" and dialog_params.get("cmp", "") in ["missing", "present"]: continue
		if dialog_op == "outliers" and key == "k" and false: continue
		if dialog_op == "sample" and key == "seed" and dialog_params.get("mode", "") != "seeded": continue
		UI.label(dialog, f.label, Rect2(6, y + 1, 128, 12), 7)
		match f.type:
			"col", "col_any", "col_none", "other_col", "table", "choice":
				var items: Array = []
				match f.type:
					"col": items = cols
					"col_any": items = [Forms.ALL] + cols
					"col_none": items = [Forms.NONE] + cols
					"other_col": items = _other_cols(str(dialog_params.get("other", "")))
					"table": items = sheet.context.keys()
					_: items = f.choices
				var pick := UI.picker(dialog, self, Rect2(136, y, 210, 14), items, dialog_params.get(key, ""))
				pick.name = "Field_" + key
				pick.picked.connect(func(v):
					dialog_params[key] = v
					if key == "col": dialog_params["merge"] = []
					if key == "other": dialog_params["right_key"] = ""
					_fix_defaults(dialog_op)
					_render_dialog())
				y += 17
			"number":
				var st := UI.stepper(dialog, Rect2(136, y, 110, 14), float(dialog_params.get(key, 0.0)), float(f.get("step", 1.0)), 0.0 if key in ["n", "window", "k"] else -1000000.0)
				st.name = "Field_" + key
				st.changed.connect(func(v):
					dialog_params[key] = v
					_update_preview())
				y += 17
			"text":
				var edit := UI.line_edit(dialog, Rect2(136, y, 210, 14), str(dialog_params.get(key, "")))
				edit.name = "Field_" + key
				edit.text_changed.connect(func(t):
					dialog_params[key] = t
					_update_preview())
				y += 17
			"cols", "values":
				var options: Array = cols if f.type == "cols" else sheet.distinct_values(sheet.table_before(dialog_index).col_index(str(dialog_params.get("col", ""))), 12)
				var chosen: Array = dialog_params.get(key, [])
				var cx := 0
				var cy := y
				for opt in options:
					var chip := UI.button(dialog, str(opt), Rect2(136 + cx * 71, cy, 70, 14), str(opt))
					chip.toggle_mode = true
					chip.button_pressed = chosen.has(opt)
					var option_value: String = str(opt)
					chip.pressed.connect(func():
						var list: Array = dialog_params.get(key, [])
						if list.has(option_value): list.erase(option_value)
						else: list.append(option_value)
						dialog_params[key] = list
						if key == "merge" and str(dialog_params.get("into", "")) == "" and not list.is_empty(): dialog_params["into"] = list[0].strip_edges()
						_render_dialog())
					cx += 1
					if cx == 3:
						cx = 0
						cy += 15
				y = cy + (15 if cx > 0 else 0) + 2
	dialog_preview = UI.label(dialog, "", Rect2(6, 192, 342, 12), 22)
	dialog_ok = UI.button(dialog, texts.sheet.save if dialog_index >= 0 else texts.sheet.apply, Rect2(6, 212, 100, 16))
	dialog_ok.name = "DialogOk"
	dialog_ok.pressed.connect(_dialog_confirm)
	var cancel := UI.button(dialog, texts.sheet.cancel, Rect2(112, 212, 70, 16))
	cancel.name = "DialogCancel"
	cancel.pressed.connect(_close_dialog)
	_update_preview()

func _update_preview() -> void:
	if dialog_preview == null or sheet == null: return
	var complete: bool = Forms.complete(dialog_op, dialog_params)
	var ok := false
	if not complete:
		dialog_preview.text = ""
	else:
		var step: Dictionary = Forms.build(dialog_op, dialog_params)
		var p: Dictionary = sheet.preview(step, dialog_index)
		if p.get("ok", false):
			dialog_preview.text = texts.sheet.preview % [p.rows_before, p.rows_after]
			dialog_preview.add_theme_color_override("font_color", Palette.color(22))
			ok = true
		else:
			var code := str(p.get("error", ""))
			dialog_preview.text = texts.sheet.errors.get(code, code) + " " + str(p.get("detail", ""))
			dialog_preview.add_theme_color_override("font_color", Palette.color(26))
	dialog_ok.disabled = not ok

func _dialog_confirm() -> void:
	if sheet == null or not Forms.complete(dialog_op, dialog_params): return
	var step: Dictionary = Forms.build(dialog_op, dialog_params)
	var r: Dictionary = sheet.edit_step(dialog_index, step) if dialog_index >= 0 else sheet.add_step(step)
	if not r.get("ok", false):
		_update_preview()
		return
	note = texts.sheet.preview % [r.rows_before, r.rows_after]
	_close_dialog()
	refresh()

# ---- "Looks fine?" -------------------------------------------------------------------------------

func toggle_looks() -> void:
	if looks_panel != null and is_instance_valid(looks_panel):
		remove_child(looks_panel)
		looks_panel.queue_free()
		looks_panel = null
		return
	if sheet == null: return
	looks_panel = UI.panel(self, Rect2(0, 16, 434, 222), 2, 94)
	looks_panel.z_index = 20
	looks_panel.name = "LooksPanel"
	UI.label(looks_panel, "%s  %s  %s" % [texts.sheet.looks_title, "-", texts.sheet.rows % sheet.row_count()], Rect2(6, 2, 330, 12), 28)
	var close := UI.button(looks_panel, texts.sheet.cancel, Rect2(364, 1, 66, 14))
	close.pressed.connect(toggle_looks)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 18)
	scroll.size = Vector2(426, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	looks_panel.add_child(scroll)
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 0)
	scroll.add_child(holder)
	for item in sheet.profile():
		var line := "%s (%s): %s, %s" % [item.name, item.type, texts.sheet.blank % item.blank, texts.sheet.distinct % item.distinct]
		var head := Label.new()
		head.text = line
		head.custom_minimum_size = Vector2(412, 12)
		head.add_theme_font_size_override("font_size", 8)
		head.add_theme_color_override("font_color", Palette.color(22))
		holder.add_child(head)
		if item.has("values"):
			var values := Label.new()
			values.text = "   " + ", ".join(item.values)
			values.custom_minimum_size = Vector2(412, 12)
			values.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			values.add_theme_font_size_override("font_size", 8)
			values.add_theme_color_override("font_color", Palette.color(7))
			holder.add_child(values)

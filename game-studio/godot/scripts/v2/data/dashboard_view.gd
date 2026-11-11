extends Control
# T-034: the Dashboard (formerly Insight BI): a 2x2 grid of pinned charts, tables and KPI tiles.
# The layout stays editable until the report is sent.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Canvas = preload("res://scripts/v2/data/chart_canvas.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const AGGS := ["sum", "mean", "median", "count", "min", "max"]
signal changed
var session: RefCounted
var texts: Dictionary = {}
var cells: Array = []
var kpi_panel: Panel
var kpi_params := {"file":"", "col":"", "fn":"mean", "label":""}
var locked := false

func build(p_session: RefCounted, p_texts: Dictionary) -> void:
	session = p_session
	texts = p_texts
	size = Vector2(434, 254)
	session.changed.connect(refresh)
	refresh()

func cell_rect(i: int) -> Rect2:
	return Rect2((i % 2) * 220, 18 + (i / 2) * 118, 214, 114)

func refresh() -> void:
	if session == null: return
	UI.clear(self)
	cells.clear()
	kpi_panel = null
	UI.label(self, texts.dash.title, Rect2(0, 0, 120, 14), 28, 12)
	UI.label(self, texts.dash.hint % session.dashboard.size(), Rect2(122, 2, 220, 12), 6)
	var kpi := UI.button(self, texts.dash.kpi, Rect2(346, 0, 86, 14), "Add a KPI tile from a cleaned file")
	kpi.name = "NewKpi"
	kpi.disabled = locked or session.sheets.is_empty() or not session.can_pin()
	kpi.pressed.connect(open_kpi)
	var ids: Array = [""]
	var names: Array = [texts.dash.empty]
	for p in session.pins:
		ids.append(p.id)
		names.append(p.title)
	for i in session.dashboard.size():
		var rect := cell_rect(i)
		var holder := UI.panel(self, rect, 3, 81)
		holder.name = "Cell%d" % i
		var pin: Dictionary = session.pin_by_id(session.dashboard[i])
		var pick := UI.picker(holder, self, Rect2(2, 2, 196, 14), ids, session.dashboard[i], names)
		pick.name = "Place%d" % i
		pick.disabled = locked
		pick.picked.connect(func(id): session.place(str(id), i))
		var clear := UI.button(holder, "x", Rect2(199, 2, 14, 14), texts.dash.clear)
		clear.disabled = locked or pin.is_empty()
		clear.pressed.connect(func(): session.place("", i))
		cells.append({"holder":holder, "pick":pick, "clear":clear, "item":pin})
		if pin.is_empty():
			UI.label(holder, texts.dash.empty, Rect2(6, 50, 200, 12), 6)
			continue
		match pin.type:
			"chart":
				var canvas := Canvas.new()
				canvas.position = Vector2(2, 18)
				canvas.size = Vector2(210, 94)
				holder.add_child(canvas)
				canvas.set_chart(session.pin_series(pin.id), pin.spec)
			"kpi":
				var value: Variant = session.kpi_value(pin.file_id, pin.spec.col, pin.spec.fn)
				UI.label(holder, UI.fmt(value if value != null else pin.get("value")), Rect2(4, 34, 206, 30), 28, 24)
				UI.label(holder, pin.title, Rect2(6, 72, 202, 12), 22)
				UI.label(holder, "%s of %s" % [pin.spec.fn, pin.spec.col], Rect2(6, 86, 202, 12), 7)
			_:
				UI.label(holder, texts.dash.tile_table, Rect2(6, 24, 200, 12), 7)
				UI.wrapped(holder, pin.title, Rect2(6, 40, 200, 24), 22, 2)
	changed.emit()

# ---- KPI tile dialog ----------------------------------------------------------------------------------

func open_kpi() -> void:
	if session.sheets.is_empty(): return
	var ids: Array = session.sheets.keys()
	if not ids.has(kpi_params.file): kpi_params.file = ids[0]
	_render_kpi()

func _render_kpi() -> void:
	if kpi_panel != null and is_instance_valid(kpi_panel):
		remove_child(kpi_panel)
		kpi_panel.queue_free()
	kpi_panel = UI.panel(self, Rect2(90, 30, 254, 130), 2, 94)
	kpi_panel.z_index = 30
	kpi_panel.name = "KpiDialog"
	UI.label(kpi_panel, texts.dash.kpi_title, Rect2(6, 2, 240, 12), 28)
	var ids: Array = session.sheets.keys()
	var names: Array = ids.map(func(id): return session.file_info(id).title)
	var model: RefCounted = session.sheet(kpi_params.file)
	var cols: Array = model.table().cols.duplicate()
	if not cols.has(kpi_params.col): kpi_params.col = cols[0] if not cols.is_empty() else ""
	UI.label(kpi_panel, texts.dash.kpi_file, Rect2(6, 19, 70, 12), 7)
	var file_pick := UI.picker(kpi_panel, self, Rect2(80, 18, 166, 14), ids, kpi_params.file, names)
	file_pick.picked.connect(func(v):
		kpi_params.file = v
		_render_kpi())
	UI.label(kpi_panel, texts.dash.kpi_col, Rect2(6, 37, 70, 12), 7)
	var col_pick := UI.picker(kpi_panel, self, Rect2(80, 36, 166, 14), cols, kpi_params.col)
	col_pick.name = "KpiColumn"
	col_pick.picked.connect(func(v): kpi_params.col = v)
	UI.label(kpi_panel, texts.dash.kpi_fn, Rect2(6, 55, 70, 12), 7)
	var fn_pick := UI.picker(kpi_panel, self, Rect2(80, 54, 166, 14), AGGS, kpi_params.fn)
	fn_pick.name = "KpiFn"
	fn_pick.picked.connect(func(v): kpi_params.fn = v)
	UI.label(kpi_panel, texts.dash.kpi_label, Rect2(6, 73, 70, 12), 7)
	var label_edit := UI.line_edit(kpi_panel, Rect2(80, 72, 166, 14), str(kpi_params.label))
	label_edit.name = "KpiLabel"
	label_edit.text_changed.connect(func(t): kpi_params.label = t)
	var add := UI.button(kpi_panel, texts.dash.kpi_add, Rect2(6, 100, 110, 16))
	add.name = "KpiAdd"
	add.pressed.connect(func():
		var id: String = session.pin_kpi(kpi_params.file, kpi_params.col, kpi_params.fn, kpi_params.label)
		if id != "":
			kpi_params.label = ""
			refresh())
	var cancel := UI.button(kpi_panel, texts.sheet.cancel, Rect2(122, 100, 70, 16))
	cancel.pressed.connect(refresh)

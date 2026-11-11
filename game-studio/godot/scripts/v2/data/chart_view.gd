extends Control
# T-034: the chart builder. Pick the table (raw file or the cleaned result), chart type, axes, aggregation,
# series, axis range, sort, title and unit. Live preview, friendly quality warnings, Pin chart.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Canvas = preload("res://scripts/v2/data/chart_canvas.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const DS = preload("res://scripts/data/dataset.gd")
const HintPopup = preload("res://scripts/v2/learn/hint_popup.gd")
const TYPES := ["bar", "line", "scatter", "histogram", "pie"]
const AGGS := ["sum", "mean", "median", "count", "min", "max"]
const SORTS := ["none", "asc", "desc", "x"]
signal changed
var session: RefCounted
var texts: Dictionary = {}
var ui_strings: Dictionary = {}
var file_id := ""
var source := "raw"
var spec: Dictionary = {}
var canvas: Control
var form: Control
var flag_box: Control
var teach_label: Label
var pin_button: Button
var pin_note: Label
var hint_button: Button
var flags: Array = []
var flag_index := 0
var fields: Dictionary = {}

func build(p_session: RefCounted, p_texts: Dictionary, all_strings: Dictionary) -> void:
	session = p_session
	texts = p_texts
	ui_strings = all_strings
	size = Vector2(434, 254)
	form = Control.new()
	form.size = Vector2(146, 254)
	add_child(form)
	canvas = Canvas.new()
	canvas.position = Vector2(150, 0)
	canvas.size = Vector2(284, 130)
	add_child(canvas)
	flag_box = Control.new()
	flag_box.position = Vector2(150, 134)
	flag_box.size = Vector2(284, 57)
	add_child(flag_box)
	teach_label = UI.wrapped(self, "", Rect2(150, 193, 284, 44), 22, 4)
	pin_button = UI.button(self, texts.charts.pin, Rect2(150, 238, 130, 16), "Save this chart so Mail can attach it")
	pin_button.name = "PinChart"
	pin_button.pressed.connect(pin)
	pin_note = UI.label(self, "", Rect2(284, 240, 72, 12), 7)
	hint_button = HintPopup.add_button(self, self, Rect2(360, 238, 74, 16), session, func(): return file_id if file_id != "" else session.hint_file())
	reset_spec()
	render()

func _opened_ids() -> Array:
	return session.files.filter(func(f): return session.opened.has(f.id)).map(func(f): return f.id)

func use_file(id: String) -> void:
	file_id = id
	if source == "clean" and session.sheet(id) == null: source = "raw"
	reset_spec()
	render()

func reset_spec() -> void:
	if file_id == "":
		var ids := _opened_ids()
		if ids.is_empty() and not session.files.is_empty(): ids = [session.files[0].id]
		file_id = ids[0] if not ids.is_empty() else ""
	spec = session.default_spec(file_id, source) if file_id != "" else {}

func table_cols() -> Array:
	if file_id == "": return []
	if source == "clean" and session.sheet(file_id) != null: return session.sheet(file_id).table().cols.duplicate()
	return session.file_info(file_id).table.columns.map(func(c): return c.name)

func render() -> void:
	UI.clear(form)
	fields.clear()
	if file_id == "":
		UI.wrapped(form, texts.charts.no_file, Rect2(2, 4, 140, 30), 6, 3)
		_refresh_preview()
		return
	var cols := table_cols()
	var y := 0
	var ids: Array = session.files.map(func(f): return f.id)
	var names: Array = session.files.map(func(f): return f.title)
	y = _row(y, texts.charts.table, "file", ids, file_id, names)
	y = _row(y, "Source", "source", ["raw", "clean"], source, [texts.charts.raw, texts.charts.clean])
	y = _row(y, texts.charts.type, "type", TYPES, spec.get("type", "bar"), TYPES.map(func(t): return texts.charts.types[t]))
	y = _row(y, texts.charts.x, "x", cols, spec.get("x", ""))
	y = _row(y, texts.charts.y, "y", cols, spec.get("y", ""))
	y = _row(y, texts.charts.agg, "agg", AGGS, spec.get("agg", "sum"))
	y = _row(y, texts.charts.series, "series", [""] + cols, spec.get("series", ""), ["(none)"] + cols)
	y = _row(y, texts.charts.sort, "sort", SORTS, spec.get("sort", "none"), SORTS.map(func(s): return texts.charts.sorts[s]))
	y = _range_row(y, texts.charts.ymin, "y_min")
	y = _range_row(y, texts.charts.ymax, "y_max")
	UI.label(form, texts.charts.chart_title, Rect2(0, y + 1, 44, 12), 7)
	var title_edit := UI.line_edit(form, Rect2(46, y, 98, 14), str(spec.get("title", "")))
	title_edit.name = "Field_title"
	title_edit.text_changed.connect(func(t):
		spec["title"] = t
		_refresh_preview())
	fields["title"] = title_edit
	y += 17
	UI.label(form, texts.charts.unit, Rect2(0, y + 1, 44, 12), 7)
	var unit_edit := UI.line_edit(form, Rect2(46, y, 98, 14), str(spec.get("y_label", "")))
	unit_edit.name = "Field_y_label"
	unit_edit.text_changed.connect(func(t):
		spec["y_label"] = t
		_refresh_preview())
	fields["y_label"] = unit_edit
	_refresh_preview()

func _row(y: int, caption: String, key: String, items: Array, value: Variant, labels: Array = []) -> int:
	UI.label(form, caption, Rect2(0, y + 1, 44, 12), 7)
	var pick := UI.picker(form, self, Rect2(46, y, 98, 14), items, value, labels)
	pick.name = "Field_" + key
	pick.picked.connect(_on_pick.bind(key))
	fields[key] = pick
	return y + 17

func _range_row(y: int, caption: String, key: String) -> int:
	UI.label(form, caption, Rect2(0, y + 1, 44, 12), 7)
	var st := UI.stepper(form, Rect2(46, y, 82, 14), float(spec.get(key, 0.0)) if spec.get(key) != null else 0.0, _range_step(), -1000000.0)
	st.name = "Field_" + key
	if spec.get(key) == null:
		st.auto_text = texts.charts.auto
		st.refresh()
	st.changed.connect(func(v):
		spec[key] = v
		st.auto_text = ""
		st.refresh()
		_refresh_preview())
	var auto := UI.button(form, "x", Rect2(130, y, 14, 14), "Back to automatic")
	auto.pressed.connect(func():
		spec[key] = null
		st.auto_text = texts.charts.auto
		st.refresh()
		_refresh_preview())
	fields[key] = st
	return y + 17

func _range_step() -> float:
	var data: Dictionary = session.chart_series(file_id, source, spec.merged({"y_min":null, "y_max":null}, true)) if file_id != "" and not spec.is_empty() else {}
	var top := 1.0
	for s in data.get("series", []):
		for p in s.points:
			if p.y != null: top = maxf(top, absf(float(p.y)))
	return maxf(1.0, pow(10.0, floor(log(top) / log(10.0)) - 1.0) * 5.0)

func _on_pick(value: Variant, key: String) -> void:
	match key:
		"file":
			use_file(str(value))
			return
		"source":
			source = str(value)
			if source == "clean" and session.sheet(file_id) == null: source = "raw"
			var cols := table_cols()
			if not cols.has(spec.get("x", "")) or not cols.has(spec.get("y", "")): spec = session.default_spec(file_id, source).merged({"type":spec.get("type", "bar")}, true)
		"series": spec["series"] = value
		_: spec[key] = value
	render()

func _refresh_preview() -> void:
	flags = []
	var series: Dictionary = {}
	if file_id != "" and not spec.is_empty():
		series = session.chart_series(file_id, source, spec)
		if series.get("ok", false): flags = session.chart_flags(file_id, source, spec)
	canvas.message = texts.charts.cannot
	canvas.set_chart(series, spec)
	UI.clear(flag_box)
	UI.label(flag_box, texts.charts.warnings if not flags.is_empty() else texts.charts.no_warnings, Rect2(0, 0, 284, 12), 28 if not flags.is_empty() else 24)
	flag_index = clampi(flag_index, 0, maxi(0, flags.size() - 1))
	for i in mini(flags.size(), 3):
		var f: Dictionary = flags[i]
		var b := UI.button(flag_box, "! " + str(ui_strings.get(f.text_key, f.id)), Rect2(0, 13 + i * 15, 284, 14))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.button_pressed = i == flag_index
		b.add_theme_color_override("font_color", Palette.color(26 if f.severity == "error" else 28))
		b.name = "Flag_" + str(f.id)
		b.pressed.connect(func():
			flag_index = i
			_refresh_preview())
	teach_label.text = str(ui_strings.get(flags[flag_index].teach_key, "")) if not flags.is_empty() else ""
	pin_button.disabled = file_id == "" or not series.get("ok", false)
	pin_note.text = "%s %d/%d" % [texts.charts.pinned, session.pins.size(), session.limit("max_pinned", 4)]
	changed.emit()

func pin() -> void:
	if file_id == "": return
	var id: String = session.pin_chart(file_id, source, spec)
	pin_note.text = (texts.charts.pinned + " " + str(session.pins.size()) + "/" + str(session.limit("max_pinned", 4))) if id != "" else session.message
	changed.emit()

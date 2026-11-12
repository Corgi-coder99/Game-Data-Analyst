extends Control
const FontTheme = preload("res://scripts/v2/theme_v2.gd")  # T-039: loading it installs the UI font
# T-034: virtualized table grid. Only the visible rows are drawn (400-row files stay cheap).
# 1x: font 8, row 12, header 14. 2x: everything doubled. Mouse wheel scrolls (Shift = sideways).
const Palette = preload("res://scripts/v2/palette.gd")
const BAR := 8
const TYPE_MARK := {"int":"#", "float":"#", "text":"A", "category":"A", "date":"D", "bool":"?"}
const TYPE_COLOR := {"int":19, "float":19, "text":29, "category":29, "date":24, "bool":28}
signal header_clicked(col: int)
signal cell_clicked(col: int, row: int)
var table: RefCounted
var zoom := 1
var selected_col := -1
var selected_row := -1
var highlight: Dictionary = {}
var tint_color := 28
var widths: Array = []
var scroll_x := 0.0
var scroll_y := 0.0
var vbar: VScrollBar
var hbar: HScrollBar

func _init() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	vbar = VScrollBar.new()
	hbar = HScrollBar.new()
	add_child(vbar)
	add_child(hbar)
	vbar.value_changed.connect(func(v): scroll_y = v; queue_redraw())
	hbar.value_changed.connect(func(v): scroll_x = v; queue_redraw())

func row_h() -> float:
	return 12.0 * zoom

func head_h() -> float:
	return 14.0 * zoom

func num_w() -> float:
	return 22.0 * zoom

func view_size() -> Vector2:
	return Vector2(size.x - BAR, size.y - BAR)

func set_table(value: RefCounted, p_zoom: int = -1) -> void:
	table = value
	if p_zoom > 0: zoom = p_zoom
	scroll_x = 0.0 if table == null else minf(scroll_x, 1.0e6)
	_measure()
	_layout_bars()
	queue_redraw()

func set_zoom(value: int) -> void:
	zoom = value
	_measure()
	_layout_bars()
	queue_redraw()

func _measure() -> void:
	widths.clear()
	if table == null: return
	var font: Font = get_theme_default_font()
	var fs := 8 * zoom
	for c in table.cols.size():
		var w: float = font.get_string_size(str(table.cols[c]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 14.0 * zoom
		for r in mini(table.rows.size(), 60):
			var v: Variant = table.rows[r][c]
			if v != null: w = maxf(w, font.get_string_size(str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 6.0 * zoom)
		widths.append(clampf(w, 30.0 * zoom, 130.0 * zoom))

func content_size() -> Vector2:
	var w := num_w()
	for x in widths: w += x
	var rows: int = 0 if table == null else table.rows.size()
	return Vector2(w, head_h() + rows * row_h())

func _layout_bars() -> void:
	var view := view_size()
	var content := content_size()
	vbar.position = Vector2(size.x - BAR, 0)
	vbar.size = Vector2(BAR, view.y)
	vbar.min_value = 0
	vbar.max_value = maxf(content.y, view.y)
	vbar.page = view.y
	hbar.position = Vector2(0, size.y - BAR)
	hbar.size = Vector2(view.x, BAR)
	hbar.min_value = 0
	hbar.max_value = maxf(content.x, view.x)
	hbar.page = view.x
	scroll_y = clampf(scroll_y, 0.0, maxf(0.0, content.y - view.y))
	scroll_x = clampf(scroll_x, 0.0, maxf(0.0, content.x - view.x))
	vbar.set_value_no_signal(scroll_y)
	hbar.set_value_no_signal(scroll_x)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and vbar != null: _layout_bars()

# Visible row range (first inclusive, last exclusive); tests use it to prove virtualization.
func visible_rows() -> Vector2i:
	if table == null: return Vector2i.ZERO
	var first := int(floor(scroll_y / row_h()))
	var last := int(ceil((scroll_y + view_size().y - head_h()) / row_h()))
	return Vector2i(clampi(first, 0, table.rows.size()), clampi(last + 1, 0, table.rows.size()))

func column_at(x: float) -> int:
	var cx := num_w() - scroll_x
	for c in widths.size():
		if x >= cx and x < cx + widths[c]: return c
		cx += widths[c]
	return -1

func column_left(c: int) -> float:
	var cx := num_w() - scroll_x
	for i in c: cx += widths[i]
	return cx

func scroll_to_col(c: int) -> void:
	if c < 0 or c >= widths.size(): return
	var left := column_left(c) + scroll_x
	var view := view_size()
	if left < scroll_x + num_w(): scroll_x = maxf(0.0, left - num_w())
	elif left + widths[c] > scroll_x + view.x: scroll_x = left + widths[c] - view.x
	_layout_bars()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var dir := -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			if mb.shift_pressed: scroll_x += dir * 24.0 * zoom
			else: scroll_y += dir * row_h() * 3.0
			_layout_bars()
			queue_redraw()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and table != null:
			var view := view_size()
			if mb.position.x >= view.x or mb.position.y >= view.y: return
			var c := column_at(mb.position.x)
			if mb.position.y < head_h():
				if c >= 0: header_clicked.emit(c)
			elif c >= 0:
				var r := int(floor((mb.position.y - head_h() + scroll_y) / row_h()))
				if r >= 0 and r < table.rows.size(): cell_clicked.emit(c, r)

func _draw() -> void:
	var view := view_size()
	draw_rect(Rect2(Vector2.ZERO, size), Palette.color(2))
	if table == null: return
	var font: Font = get_theme_default_font()
	var fs := 8 * zoom
	var rh := row_h()
	var hh := head_h()
	var span := visible_rows()
	for r in range(span.x, span.y):
		var y := hh + r * rh - scroll_y
		if y + rh < hh or y > view.y: continue
		var rid: int = table.rids[r]
		var back := Palette.color(2 if r % 2 == 0 else 3)
		draw_rect(Rect2(num_w(), y, view.x, rh), back)
		if highlight.has(rid): draw_rect(Rect2(0, y, view.x, rh), Color(Palette.color(tint_color), 0.38))
		if r == selected_row: draw_rect(Rect2(0, y, view.x, rh), Color(Palette.color(20), 0.25))
		draw_string(font, Vector2(2, y + rh - 3.0 * zoom), str(r + 1), HORIZONTAL_ALIGNMENT_LEFT, num_w() - 3.0, fs, Palette.color(6))
		var cx := num_w() - scroll_x
		for c in widths.size():
			var w: float = widths[c]
			if cx + w >= num_w() and cx <= view.x:
				if c == selected_col: draw_rect(Rect2(maxf(cx, num_w()), y, minf(w, view.x - cx), rh), Color(Palette.color(18), 0.55))
				var v: Variant = table.rows[r][c]
				var text := "-" if v == null else str(v)
				draw_string(font, Vector2(cx + 3.0 * zoom, y + rh - 3.0 * zoom), text, HORIZONTAL_ALIGNMENT_LEFT, w - 5.0 * zoom, fs, Palette.color(6 if v == null else 22))
			cx += w
	# header on top
	draw_rect(Rect2(0, 0, view.x, hh), Palette.color(4))
	var hx := num_w() - scroll_x
	for c in widths.size():
		var w: float = widths[c]
		if hx + w >= num_w() and hx <= view.x:
			if c == selected_col: draw_rect(Rect2(hx, 0, w, hh), Palette.color(19))
			var tp := str(table.types[c])
			var mark: String = TYPE_MARK.get(tp, "A")
			draw_rect(Rect2(hx + 1.0, 2.0 * zoom, 9.0 * zoom, 9.0 * zoom), Palette.color(TYPE_COLOR.get(tp, 29)))
			draw_string(font, Vector2(hx + 3.0 * zoom, hh - 4.0 * zoom), mark, HORIZONTAL_ALIGNMENT_LEFT, 8.0 * zoom, fs, Palette.color(1))
			draw_string(font, Vector2(hx + 11.0 * zoom, hh - 3.0 * zoom), str(table.cols[c]), HORIZONTAL_ALIGNMENT_LEFT, w - 12.0 * zoom, fs, Palette.color(8))
			draw_line(Vector2(hx + w - 0.5, 0), Vector2(hx + w - 0.5, hh), Palette.color(3), 1.0)
		hx += w
	draw_rect(Rect2(0, 0, num_w(), hh), Palette.color(3))
	draw_string(font, Vector2(2, hh - 3.0 * zoom), "#", HORIZONTAL_ALIGNMENT_LEFT, num_w(), fs, Palette.color(7))
	draw_line(Vector2(0, hh), Vector2(view.x, hh), Palette.color(7), 1.0)

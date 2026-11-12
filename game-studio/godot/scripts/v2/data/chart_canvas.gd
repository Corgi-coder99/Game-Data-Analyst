extends Control
const FontTheme = preload("res://scripts/v2/theme_v2.gd")  # T-039: loading it installs the UI font
# T-034: draws a chart in code (palette v4): axes, ticks, labels, gridlines, legend. `mini` draws only the
# shape (used for thumbnails). Input is the result of DataGame.chart_data and the chart spec.
const Palette = preload("res://scripts/v2/palette.gd")
const Juice = preload("res://scripts/v2/juice.gd")
const COLORS := [19, 24, 28, 26, 30, 53, 36, 50]
var data: Dictionary = {}
var spec: Dictionary = {}
var mini := false
var message := ""
# T-039: bars grow in and lines draw left to right on the first render only (0.3 s). 1.0 = fully drawn.
var reveal := 1.0
var revealed := false

func set_chart(series_data: Dictionary, chart_spec: Dictionary) -> void:
	data = series_data
	spec = chart_spec
	if not revealed and not mini and bool(series_data.get("ok", false)) and Juice.active() and is_inside_tree():
		revealed = true
		reveal = 0.0
		var tween := create_tween()
		tween.tween_method(_set_reveal, 0.0, 1.0, 0.3)
		Juice._track(tween, _set_reveal.bind(1.0))
	queue_redraw()

func _set_reveal(value: float) -> void:
	reveal = value
	queue_redraw()

static func short(text: String, chars: int) -> String:
	if text.length() <= chars: return text
	return text.substr(0, maxi(1, chars - 1)) + "."

# ISO dates lose the year on the axis (2026-02-15 becomes 02-15).
static func axis_text(text: String) -> String:
	if text.length() == 10 and text[4] == "-" and text[7] == "-": return text.substr(5)
	return text

func _text(pos: Vector2, text: String, color_index: int = 22, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, pos, text, align, width, 8, Palette.color(color_index))

func _fmt(v: float) -> String:
	var a := absf(v)
	if a >= 1000000.0: return "%.1fM" % (v / 1000000.0)
	if a >= 10000.0: return "%.0fk" % (v / 1000.0)
	if is_equal_approx(v, roundf(v)): return "%d" % int(roundf(v))
	if a >= 100.0: return "%.0f" % v
	if a >= 10.0: return "%.1f" % v
	return "%.2f" % v

func _categories(series: Array) -> Array:
	var cats: Array = []
	for s in series:
		for p in s.points:
			if not cats.has(p.x): cats.append(p.x)
	return cats

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.color(3))
	draw_rect(Rect2(Vector2.ZERO, size), Palette.color(5), false, 1.0)
	if not data.get("ok", false):
		if not mini: _text(Vector2(6, size.y * 0.5), message if message != "" else "Nothing to draw yet.", 7)
		return
	var type := str(data.get("type", ""))
	var series: Array = data.series
	if series.is_empty(): return
	var title_text := str(spec.get("title", ""))
	var unit := str(spec.get("y_label", ""))
	var top := 3.0
	var left := 3.0
	var bottom := 3.0
	if not mini:
		var head := title_text if unit == "" else (title_text + " (" + unit + ")" if title_text != "" else unit)
		_text(Vector2(4, 9), short(head, int((size.x - 8.0) / 4.4)), 22)
		top = 14.0
		left = 30.0 if type != "pie" else 4.0
		bottom = 14.0
		if series.size() > 1 and type != "pie":
			var lx := size.x - 4.0
			for i in range(series.size() - 1, -1, -1):
				var nm := short(str(series[i].name), 9)
				lx -= nm.length() * 4.4 + 10.0
				draw_rect(Rect2(lx, 2, 6, 6), Palette.color(COLORS[i % COLORS.size()]))
				_text(Vector2(lx + 8.0, 9), nm, 7)
			top = 14.0
	var plot := Rect2(left, top, size.x - left - 4.0, size.y - top - bottom)
	if plot.size.x < 8.0 or plot.size.y < 8.0: return
	match type:
		"pie": _draw_pie(series, plot)
		"scatter": _draw_scatter(series, plot)
		_: _draw_xy(type, series, plot)

func _range(values: Array, from_zero: bool) -> Vector2:
	var lo := 0.0
	var hi := 1.0
	if not values.is_empty():
		lo = float(values.min())
		hi = float(values.max())
	if from_zero: lo = minf(lo, 0.0)
	if spec.get("y_min") != null: lo = float(spec.y_min)
	if spec.get("y_max") != null: hi = float(spec.y_max)
	elif hi > lo: hi += (hi - lo) * 0.06
	if hi <= lo: hi = lo + 1.0
	return Vector2(lo, hi)

func _draw_axes(plot: Rect2, y_range: Vector2, x_range: Variant = null) -> void:
	if mini: return
	for i in 5:
		var v := y_range.x + (y_range.y - y_range.x) * float(i) / 4.0
		var y := plot.end.y - plot.size.y * float(i) / 4.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Palette.color(4), 1.0)
		_text(Vector2(1, y + 3.0), _fmt(v), 7, HORIZONTAL_ALIGNMENT_RIGHT, plot.position.x - 4.0)
	draw_line(plot.position, Vector2(plot.position.x, plot.end.y), Palette.color(7), 1.0)
	draw_line(Vector2(plot.position.x, plot.end.y), plot.end, Palette.color(7), 1.0)
	if x_range != null:
		for i in 5:
			var v: float = x_range.x + (x_range.y - x_range.x) * float(i) / 4.0
			_text(Vector2(plot.position.x + plot.size.x * float(i) / 4.0 - 12.0, plot.end.y + 10.0), _fmt(v), 7, HORIZONTAL_ALIGNMENT_CENTER, 24.0)

func _draw_xy(type: String, series: Array, plot: Rect2) -> void:
	var cats := _categories(series)
	var ys: Array = []
	for s in series:
		for p in s.points:
			if p.y != null: ys.append(float(p.y))
	var y_range := _range(ys, type != "line")
	_draw_axes(plot, y_range)
	var n := maxi(1, cats.size())
	var slot := plot.size.x / n
	var span := y_range.y - y_range.x
	var base := plot.end.y
	for si in series.size():
		var color := Palette.color(COLORS[si % COLORS.size()])
		var pts := PackedVector2Array()
		for p in series[si].points:
			if p.y == null: continue
			var ci := cats.find(p.x)
			var cx := plot.position.x + slot * (ci + 0.5)
			var y := clampf(base - (float(p.y) - y_range.x) / span * plot.size.y, plot.position.y, base)
			if type != "line": y = base - (base - y) * reveal
			if type == "line":
				pts.append(Vector2(cx, y))
			else:
				var group := slot * (0.86 if type == "histogram" else 0.7)
				var w := maxf(1.0, group / series.size())
				var x0 := cx - group * 0.5 + w * si
				draw_rect(Rect2(x0, y, maxf(1.0, w - (0.0 if type == "histogram" else 1.0)), base - y), color)
		if type == "line":
			if reveal < 1.0: pts = pts.slice(0, maxi(1, int(ceil(pts.size() * reveal))))
			if pts.size() > 1: draw_polyline(pts, color, 1.0)
			for pt in pts: draw_rect(Rect2(pt - Vector2(1, 1), Vector2(3, 3)), color)
	if mini: return
	var chars := int(slot / 4.2)
	var every := 1
	if chars < 4: every = int(ceil(4.0 / maxf(1.0, float(chars)) * 1.5))
	if type == "histogram" and cats.size() > 4: every = ceili(cats.size() / 3.0)
	for i in range(0, cats.size(), maxi(1, every)):
		var label_text := short(axis_text(str(cats[i])), maxi(4, chars * maxi(1, every)))
		_text(Vector2(plot.position.x + slot * (i + 0.5) - slot * 0.5 * maxi(1, every), plot.end.y + 10.0), label_text, 7, HORIZONTAL_ALIGNMENT_CENTER, slot * maxi(1, every))

func _draw_scatter(series: Array, plot: Rect2) -> void:
	var xs: Array = []
	var ys: Array = []
	for p in series[0].points:
		xs.append(float(p.x))
		ys.append(float(p.y))
	if xs.is_empty(): return
	var xr := Vector2(float(xs.min()), float(xs.max()))
	if xr.y <= xr.x: xr.y = xr.x + 1.0
	var yr := _range(ys, false)
	_draw_axes(plot, yr, xr)
	var color := Palette.color(COLORS[0])
	for i in xs.size():
		var px: float = plot.position.x + (xs[i] - xr.x) / (xr.y - xr.x) * plot.size.x
		var py: float = clampf(plot.end.y - (ys[i] - yr.x) / (yr.y - yr.x) * plot.size.y, plot.position.y, plot.end.y)
		draw_rect(Rect2(px - 1, py - 1, 3, 3), color)

func _draw_pie(series: Array, plot: Rect2) -> void:
	var points: Array = series[0].points.filter(func(p): return p.y != null and float(p.y) > 0.0)
	var total := 0.0
	for p in points: total += float(p.y)
	if total <= 0.0: return
	var radius := minf(plot.size.y * 0.5, plot.size.x * 0.4) - 1.0
	var center := Vector2(plot.position.x + radius + 4.0, plot.position.y + plot.size.y * 0.5)
	var angle := -PI / 2.0
	for i in points.size():
		var sweep := TAU * float(points[i].y) / total
		var poly := PackedVector2Array([center])
		var steps := maxi(2, int(sweep / 0.12))
		for k in steps + 1: poly.append(center + Vector2(cos(angle + sweep * k / steps), sin(angle + sweep * k / steps)) * radius)
		draw_colored_polygon(poly, Palette.color(COLORS[i % COLORS.size()]))
		angle += sweep
		if not mini and i < 7:
			var ly := plot.position.y + 4.0 + i * 11.0
			draw_rect(Rect2(center.x + radius + 10.0, ly, 6, 6), Palette.color(COLORS[i % COLORS.size()]))
			_text(Vector2(center.x + radius + 19.0, ly + 7.0), "%s %d%%" % [short(str(points[i].x), 10), roundi(100.0 * float(points[i].y) / total)], 7)

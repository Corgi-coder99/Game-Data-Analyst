extends Control

const Palette = preload("res://scripts/ui/palette.gd")
var values: Array = []
var weeks: Array = []
var week_format := ""
var value_format := "%.1f"
var value_scale := 1.0
var axis_labels: Array = []

func _ready() -> void:
	resized.connect(queue_redraw)

func set_values(samples: Array, sample_weeks: Array = [], week_label: String = "", number_format: String = "%.1f", scale: float = 1.0) -> void:
	values = samples.duplicate()
	weeks = sample_weeks.duplicate()
	week_format = week_label
	value_format = number_format
	value_scale = scale
	axis_labels.clear()
	if not values.is_empty():
		axis_labels.append(value_format % (float(values.min()) * value_scale))
		axis_labels.append(value_format % (float(values.max()) * value_scale))
		for week in weeks:
			var label := week_format % week
			if label not in axis_labels:
				axis_labels.append(label)
	queue_redraw()

func _draw() -> void:
	if values.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := 10
	var left := maxf(font.get_string_size(axis_labels[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, font.get_string_size(axis_labels[1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + 6.0
	var area := Rect2(Vector2(left, 10), Vector2(maxf(1, size.x - left - 24), maxf(1, size.y - 28)))
	draw_line(area.position, Vector2(area.position.x, area.end.y), Palette.ACCENT)
	draw_line(Vector2(area.position.x, area.end.y), area.end, Palette.ACCENT)
	draw_string(font, Vector2(0, area.end.y), axis_labels[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.TEXT)
	draw_string(font, Vector2(0, area.position.y), axis_labels[1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.TEXT)
	var low: float = values.min()
	var high: float = values.max()
	var points := PackedVector2Array()
	for i in values.size():
		var x := area.position.x + area.size.x * i / maxf(1, values.size() - 1)
		var y := area.get_center().y if is_equal_approx(low, high) else area.end.y - area.size.y * (float(values[i]) - low) / (high - low)
		points.append(Vector2(x, y))
	if points.size() > 1:
		draw_polyline(points, Palette.TEXT, 2.0, true)
	for point in points:
		draw_circle(point, 2.0, Palette.TEXT)
	if points.size() == 1:
		draw_string(font, points[0] + Vector2(5, -4), axis_labels[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.TEXT)
	# Keep repeated reports in the same week; label distinct weeks when space allows.
	var previous_week := -1
	var last_label_end := -100.0
	for i in weeks.size():
		if int(weeks[i]) == previous_week:
			continue
		previous_week = int(weeks[i])
		var label := week_format % weeks[i]
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var x := clampf(points[i].x - width / 2.0, 0, maxf(0, size.x - width))
		if x >= last_label_end + 4:
			draw_string(font, Vector2(x, size.y - 2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.TEXT)
			last_label_end = x + width

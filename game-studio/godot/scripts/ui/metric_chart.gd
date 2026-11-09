extends Control

const Palette = preload("res://scripts/ui/palette.gd")
var values: Array = []

func _ready() -> void:
	resized.connect(queue_redraw)

func set_values(samples: Array) -> void:
	values = samples.duplicate()
	queue_redraw()

func _draw() -> void:
	var area := Rect2(Vector2(8, 8), Vector2(maxf(1, size.x - 16), maxf(1, size.y - 16)))
	draw_line(area.position, Vector2(area.position.x, area.end.y), Palette.ACCENT)
	draw_line(Vector2(area.position.x, area.end.y), area.end, Palette.ACCENT)
	if values.is_empty():
		return
	var low: float = values.min()
	var high: float = values.max()
	var span := maxf(high - low, 0.001)
	var points := PackedVector2Array()
	for i in values.size():
		points.append(Vector2(area.position.x + area.size.x * i / maxf(1, values.size() - 1), area.end.y - area.size.y * (float(values[i]) - low) / span))
	if points.size() > 1:
		draw_polyline(points, Palette.TEXT, 2.0, true)
	for point in points:
		draw_circle(point, 2.0, Palette.TEXT)

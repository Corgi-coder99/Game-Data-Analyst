extends Control
const FontTheme = preload("res://scripts/v2/theme_v2.gd")  # T-039: loading it installs the UI font
# T-030: achievement and meta toasts. Same look as the money popups (floating coloured text that rises
# and fades) on a small dark plate. Toasts are shown one after another.
const Palette = preload("res://scripts/v2/palette.gd")
const Juice = preload("res://scripts/v2/juice.gd")  # T-039
const LIFETIME := 2.6
const RISE := 14.0
const GOOD := 24
signal shown(text: String)
var queue: Array = []
var history: Array = []
var current: Label
var plate: ColorRect
var elapsed := 0.0

func _ready() -> void:
	_build()

func _build() -> void:
	if plate != null: return
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate = ColorRect.new()
	plate.color = Color(Palette.color(65), 0.82)
	plate.size = Vector2(300, 18)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.visible = false
	plate.set_meta("overlay", true)
	add_child(plate)
	current = Label.new()
	current.size = Vector2(296, 14)
	current.position = Vector2(2, 2)
	current.add_theme_font_size_override("font_size", 8)
	current.add_theme_color_override("font_color", Palette.color(GOOD))
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(current)
	current.size = Vector2(296, 14)

func push(text: String) -> void:
	_build()
	history.append(text)
	queue.append(text)
	if not plate.visible: _next()

func _next() -> void:
	if queue.is_empty():
		plate.visible = false
		return
	var text: String = queue.pop_front()
	current.text = text
	elapsed = 0.0
	plate.position = Vector2(170, 44)
	plate.modulate = Color(1, 1, 1, 1)
	plate.visible = true
	shown.emit(text)

func advance(delta: float) -> void:
	if plate == null or not plate.visible: return
	elapsed += delta
	if elapsed >= LIFETIME:
		_next()
		return
	var t := elapsed / LIFETIME
	var slide := floorf(24.0 * (1.0 - minf(1.0, elapsed / 0.15))) if Juice.active() else 0.0
	plate.position = Vector2(170 + slide, 44.0 - RISE * minf(1.0, elapsed / 1.2))
	plate.modulate = Color(1, 1, 1, 1.0 if t < 0.75 else 1.0 - (t - 0.75) / 0.25)

func _process(delta: float) -> void:
	advance(delta)

func visible_text() -> String:
	return current.text if plate != null and plate.visible else ""

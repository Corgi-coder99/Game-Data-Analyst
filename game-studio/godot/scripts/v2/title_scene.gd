extends "res://scripts/v2/windows/window_base.gd"
const CityArt = preload("res://scripts/v2/city_art.gd")
signal play_requested
signal quit_requested
var strings: Dictionary

var name_label: Label
var tagline_label: Label
var play_button: Button
var quit_button: Button
var disclaimer_label: Label
var built := false

func _ready() -> void:
	_build()

func _build() -> void:
	if built: return
	built = true
	size = Vector2(640, 360)
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = WindowTheme.create()
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	# T-022: a dusk city skyline with the company tower is the title backdrop.
	var backdrop := TextureRect.new()
	backdrop.texture = CityArt.backdrop("title")
	backdrop.set_meta("overlay", true)
	backdrop.size = size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var plate := ColorRect.new()
	plate.color = Color(Palette.color(1), 0.72)
	plate.position = Vector2(150, 86)
	plate.size = Vector2(316, 130)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	name_label = label(self, strings.title.name, Rect2(0, 96, 640, 17), 8)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_label = label(self, strings.title.tagline, Rect2(0, 120, 640, 12), 7)
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_button = button(self, strings.title.play, Rect2(260, 156, 120, 24))
	quit_button = button(self, strings.title.quit, Rect2(260, 188, 120, 24))
	play_button.focus_mode = Control.FOCUS_NONE
	quit_button.focus_mode = Control.FOCUS_NONE
	play_button.pressed.connect(func(): play_requested.emit())
	quit_button.pressed.connect(func(): quit_requested.emit())
	var strip := ColorRect.new()
	strip.color = Palette.color(2)
	strip.position = Vector2(0, 328)
	strip.size = Vector2(640, 32)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	disclaimer_label = label(strip, strings.ui.disclaimer, Rect2(8, 2, 624, 28), 7)
	disclaimer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclaimer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclaimer_label.size = Vector2(624, 28)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		play_requested.emit()
		get_viewport().set_input_as_handled()

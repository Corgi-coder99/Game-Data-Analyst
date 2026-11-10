extends "res://scripts/v2/windows/window_base.gd"
const CityArt = preload("res://scripts/v2/city_art.gd")
signal play_requested
signal quit_requested
signal daily_requested
signal wall_requested
signal settings_requested
signal leave_requested
var strings: Dictionary

var name_label: Label
var tagline_label: Label
var play_button: Button
var quit_button: Button
var daily_button: Button
var wall_button: Button
var settings_button: Button
var leave_button: Button
var profile_label: Label
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
	plate.position = Vector2(150, 80)
	plate.size = Vector2(340, 180)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	name_label = label(self, strings.title.name, Rect2(0, 96, 640, 17), 8)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_label = label(self, strings.title.tagline, Rect2(0, 120, 640, 12), 7)
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_button = button(self, strings.title.play, Rect2(260, 142, 120, 22))
	daily_button = button(self, "Daily Shift", Rect2(260, 168, 120, 22))
	wall_button = button(self, "Wall of Fame", Rect2(196, 194, 120, 22))
	leave_button = button(self, "Request leave", Rect2(324, 194, 120, 22))
	settings_button = button(self, "Settings", Rect2(196, 220, 120, 22))
	quit_button = button(self, strings.title.quit, Rect2(324, 220, 120, 22))
	for b in [play_button, daily_button, wall_button, leave_button, settings_button, quit_button]: b.focus_mode = Control.FOCUS_NONE
	profile_label = label(self, "", Rect2(160, 246, 320, 12), 7)
	profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_button.pressed.connect(func(): daily_requested.emit())
	wall_button.pressed.connect(func(): wall_requested.emit())
	leave_button.pressed.connect(func(): leave_requested.emit())
	settings_button.pressed.connect(func(): settings_requested.emit())
	for b in [daily_button, wall_button, leave_button, settings_button]: b.disabled = true
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

# T-030: the profile-dependent buttons and the status line. Without a profile (older flows and tests)
# they stay disabled and the title behaves as before.
func set_profile(meta: RefCounted) -> void:
	_build()
	var on := meta != null
	for b in [daily_button, wall_button, leave_button, settings_button]: b.disabled = not on
	if not on:
		profile_label.text = ""
		return
	var data: Dictionary = meta.profile.data
	profile_label.text = "%s   Streak %d   Reputation %d" % [data.display_name, int(data.streak), int(data.reputation)]

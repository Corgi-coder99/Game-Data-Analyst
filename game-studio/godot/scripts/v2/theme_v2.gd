extends RefCounted
const Palette = preload("res://scripts/v2/palette.gd")
# T-039: the one place that decides the UI font. The pixel font (scripts/v2/pixel_font.gd) is the default;
# the Settings toggle "Pixel font" switches back to the engine font. The choice is installed as the
# engine fallback font (labels and draw_string calls outside a themed Control use it) and as the default
# font of every Theme made by create().
const PixelFont = preload("res://scripts/v2/pixel_font.gd")
static var pixel_font_on := true

static func _static_init() -> void:
	apply_font()

static func font() -> Font:
	var pixel: Font = PixelFont.font() if pixel_font_on else null
	return pixel if pixel != null else PixelFont.default_font()

static func apply_font() -> void:
	ThemeDB.fallback_font = font()
	# Controls with no Theme of their own resolve fonts through the engine default theme first.
	ThemeDB.get_default_theme().default_font = font()

static func set_pixel_font(on: bool) -> void:
	pixel_font_on = on
	apply_font()

static func box(background: int, border: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(background)
	style.border_color = Palette.color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.anti_aliasing = false
	style.shadow_color = Color(Palette.color(65), 0.45)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 1)
	style.content_margin_left = 1
	style.content_margin_right = 1
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style

# T-029: rounded pastel panel (soft drop shadow, 4 px corners) used by the street tooltip, prompts and buttons.
static func pastel(background: int, border: int, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(background)
	style.border_color = Palette.color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = false
	style.shadow_color = Color(Palette.color(65), 0.55)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1, 2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

# Night-blue rounded panel with a periwinkle border for the review, evening, ending and shop screens.
static func night(border: int = 81) -> StyleBoxFlat:
	var style := pastel(83, border, 5)
	style.set_border_width_all(2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	return style

# Applies the pastel look to a Button (cream normal, yellow hover, peach pressed, grey disabled).
static func pastel_button(node: Button, fill: int = 89, border: int = 97) -> void:
	node.add_theme_stylebox_override("normal", pastel(fill, border))
	node.add_theme_stylebox_override("hover", pastel(95, 98))
	node.add_theme_stylebox_override("pressed", pastel(92, 98))
	node.add_theme_stylebox_override("focus", pastel(95, 87))
	node.add_theme_stylebox_override("disabled", pastel(101, 100))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(key, Palette.color(66))
	node.add_theme_color_override("font_disabled_color", Palette.color(99))

static func create() -> Theme:
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = 8
	for type in ["Label", "Button", "TooltipLabel", "ProgressBar"]:
		result.set_font_size("font_size", type, 8)
	for type in ["Label", "Button", "ProgressBar"]:
		result.set_color("font_color", type, Palette.color(102))
	result.set_color("font_disabled_color", "Button", Palette.color(6))
	result.set_color("font_hover_color", "Button", Palette.color(8))
	result.set_color("font_pressed_color", "Button", Palette.color(22))
	result.set_stylebox("normal", "Button", box(4, 99))
	result.set_stylebox("hover", "Button", box(84, 94))
	result.set_stylebox("pressed", "Button", box(80, 82))
	result.set_stylebox("disabled", "Button", box(2, 4))
	result.set_stylebox("focus", "Button", box(84, 82))
	result.set_stylebox("background", "ProgressBar", box(3))
	result.set_stylebox("fill", "ProgressBar", box(91, 90))
	result.set_stylebox("panel", "TooltipPanel", box(2))
	result.set_color("font_color", "TooltipLabel", Palette.color(22))
	for type in ["VScrollBar", "HScrollBar"]:
		result.set_stylebox("scroll", type, box(2, 2))
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
			result.set_stylebox(state, type, box(5))
	return result

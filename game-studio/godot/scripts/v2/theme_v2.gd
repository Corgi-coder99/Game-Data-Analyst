extends RefCounted
const Palette = preload("res://scripts/v2/palette.gd")

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

static func create() -> Theme:
	var result := Theme.new()
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

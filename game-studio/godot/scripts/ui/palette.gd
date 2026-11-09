extends RefCounted

const BACKGROUND = Color("18202b")
const TEXT = Color("eef2f6")
const ACCENT = Color("334b62")

static func apply_to(control: Control) -> void:
	var shared := preload("res://assets/theme/main_theme.tres").duplicate() as Theme
	shared.set_color("font_color", "Label", TEXT)
	shared.set_color("font_color", "Button", TEXT)
	var panel := StyleBoxFlat.new()
	panel.bg_color = BACKGROUND
	shared.set_stylebox("panel", "PanelContainer", panel)
	var button := StyleBoxFlat.new()
	button.bg_color = ACCENT
	button.content_margin_left = 6
	button.content_margin_right = 6
	button.content_margin_top = 6
	button.content_margin_bottom = 6
	shared.set_stylebox("normal", "Button", button)
	control.theme = shared

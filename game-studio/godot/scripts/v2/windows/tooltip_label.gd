extends Label
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")

func _make_custom_tooltip(text: String) -> Object:
	var panel := PanelContainer.new()
	var style := WindowTheme.box(2)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	var body := Label.new()
	body.add_theme_font_size_override("font_size", 8)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 288
	body.text = text
	panel.add_child(body)
	return panel

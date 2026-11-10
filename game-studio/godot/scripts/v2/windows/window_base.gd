extends Control
const TooltipLabel = preload("res://scripts/v2/windows/tooltip_label.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const Sprites = preload("res://scripts/v2/sprite_lib.gd")
var sprites := Sprites.new()
var content: Control
signal minimize_requested

func build(title: String, area: Rect2) -> void:
	position = area.position
	size = area.size
	clip_contents = true
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", WindowTheme.box(2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var bar := ColorRect.new()
	bar.color = Palette.color(18)
	bar.position = Vector2(1, 1)
	bar.size = Vector2(size.x - 2, 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	label(self, title, Rect2(4, 0, size.x - 18, 12))
	var minimize := button(self, "", Rect2(size.x - 11, 3, 8, 8))
	var dash := ColorRect.new()
	dash.color = Palette.color(22)
	dash.position = Vector2(2, 4)
	dash.size = Vector2(4, 1)
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimize.add_child(dash)
	minimize.pressed.connect(func(): minimize_requested.emit())
	content = Control.new()
	content.position = Vector2(4, 16)
	content.size = size - Vector2(8, 20)
	content.clip_contents = true
	add_child(content)

func label(parent: Node, text: String, area: Rect2, color_index: int = 22) -> Label:
	var node := TooltipLabel.new()
	node.add_theme_font_size_override("font_size", 8)
	node.clip_text = true
	node.text = text
	node.position = area.position
	node.size = area.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_color_override("font_color", Palette.color(color_index))
	parent.add_child(node)
	node.size = area.size
	return node

func button(parent: Node, text: String, area: Rect2) -> Button:
	var node := Button.new()
	node.add_theme_font_size_override("font_size", 8)
	node.text = text
	node.position = area.position
	node.size = area.size
	node.add_theme_constant_override("outline_size", 0)
	parent.add_child(node)
	node.size = area.size
	return node

func icon(parent: Node, id: String, at: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = sprites.frame(id)
	node.position = at
	node.size = Vector2(8, 8)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func empty(parent: Node) -> void:
	for node in parent.get_children():
		parent.remove_child(node)
		node.queue_free()

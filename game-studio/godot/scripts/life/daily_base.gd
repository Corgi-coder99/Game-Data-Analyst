extends "res://scripts/v2/windows/window_base.gd"
# T-026: shared helpers for the daily-life screens (morning, shop interior, overtime).
const WindowTheme2 = preload("res://scripts/v2/theme_v2.gd")
var strings: Dictionary
var daily: Dictionary
var life: RefCounted
var built := false

func _prepare() -> void:
	size = Vector2(640, 360)
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = WindowTheme2.create()
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	daily = strings.daily

func _text(parent: Node, text: String, area: Rect2, color_index: int = 22, font_size: int = 8) -> Label:
	var node := label(parent, text, area, color_index)
	if font_size != 8: node.add_theme_font_size_override("font_size", font_size)
	return node

func _wrapped(parent: Node, text: String, area: Rect2, color_index: int = 22, lines: int = 2) -> Label:
	var node := _text(parent, text, area, color_index)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.clip_text = false
	node.max_lines_visible = lines
	return node

func _rect(parent: Node, color_index: int, area: Rect2) -> ColorRect:
	var node := ColorRect.new()
	node.color = Palette.color(color_index)
	node.position = area.position
	node.size = area.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set_meta("overlay", true)
	parent.add_child(node)
	return node

func _panel(parent: Node, area: Rect2) -> Panel:
	var node := Panel.new()
	node.position = area.position
	node.size = area.size
	node.add_theme_stylebox_override("panel", WindowTheme2.night())
	parent.add_child(node)
	return node

func _sprite(parent: Node, id: String, frame_index: int, at: Vector2, scale_factor: int) -> TextureRect:
	var node := TextureRect.new()
	node.texture = sprites.frame(id, frame_index)
	node.position = at
	var frame_size: Vector2 = node.texture.get_size()
	node.size = frame_size * scale_factor
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set_meta("overlay", true)
	parent.add_child(node)
	return node

# "-$4  Stamina +6  Mood +3" from a cost and a change dictionary.
func change_text(cost: int, change: Dictionary) -> String:
	var parts: Array = []
	if cost > 0: parts.append("-$%d" % cost)
	for id in ["stamina", "mood", "health", "stress"]:
		var amount := int(change.get(id, 0))
		if amount != 0: parts.append("%s %+d" % [daily.effects[id], amount])
	return "  ".join(parts)

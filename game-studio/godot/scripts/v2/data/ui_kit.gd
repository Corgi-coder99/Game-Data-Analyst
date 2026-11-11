extends RefCounted
# T-034: small widget helpers for the data apps (absolute layout like the other v2 windows).
# Fonts are 8 px or larger, hit targets are at least 14x14, colors come from palette v4 indices.
const TooltipLabel = preload("res://scripts/v2/windows/tooltip_label.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const ROW := 14

static func label(parent: Node, text: String, area: Rect2, color_index: int = 22, size: int = 8) -> Label:
	var node := TooltipLabel.new()
	node.add_theme_font_size_override("font_size", size)
	node.clip_text = true
	node.text = text
	node.position = area.position
	node.size = area.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_color_override("font_color", Palette.color(color_index))
	parent.add_child(node)
	node.size = area.size
	return node

static func wrapped(parent: Node, text: String, area: Rect2, color_index: int = 22, lines: int = 2) -> Label:
	var node := label(parent, text, area, color_index)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.max_lines_visible = lines
	node.tooltip_text = text
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	return node

static func button(parent: Node, text: String, area: Rect2, tip: String = "") -> Button:
	var node := Button.new()
	node.add_theme_font_size_override("font_size", 8)
	node.text = text
	node.clip_text = true
	node.position = area.position
	node.size = Vector2(maxf(area.size.x, 14.0), maxf(area.size.y, 14.0))
	node.focus_mode = Control.FOCUS_NONE
	node.tooltip_text = tip
	parent.add_child(node)
	node.size = Vector2(maxf(area.size.x, 14.0), maxf(area.size.y, 14.0))
	return node

static func panel(parent: Node, area: Rect2, background: int = 2, border: int = 81) -> Panel:
	var node := Panel.new()
	node.position = area.position
	node.size = area.size
	node.add_theme_stylebox_override("panel", WindowTheme.box(background, border))
	parent.add_child(node)
	return node

static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

static func fmt(v: Variant) -> String:
	if v == null: return "-"
	if v is String: return v
	var f := float(v)
	var a := absf(f)
	if a >= 1000000.0: return "%.1fM" % (f / 1000000.0)
	if a >= 10000.0: return "%.0fk" % (f / 1000.0)
	if is_equal_approx(f, roundf(f)): return "%d" % int(roundf(f))
	if a >= 100.0: return "%.0f" % f
	if a >= 10.0: return "%.1f" % f
	return "%.2f" % f

# ---- Picker: a button that opens a short list inside `host` -------------------------------------------

class Picker extends Button:
	signal picked(value: Variant)
	var items: Array = []
	var labels: Array = []
	var value: Variant = null
	var host: Control
	var catcher: Control
	var list: Panel

	func setup(p_host: Control, p_items: Array, p_value: Variant, p_labels: Array = []) -> void:
		host = p_host
		items = p_items
		labels = p_labels if p_labels.size() == p_items.size() else p_items.map(func(i): return str(i))
		add_theme_font_size_override("font_size", 8)
		clip_text = true
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		focus_mode = Control.FOCUS_NONE
		set_value(p_value)
		pressed.connect(open_list)

	func set_value(v: Variant) -> void:
		value = v
		var at := items.find(v)
		text = (str(labels[at]) if at >= 0 else str(v)) + "  v"

	func open_list() -> void:
		close_list()
		if items.is_empty() or host == null: return
		catcher = Control.new()
		catcher.size = host.size
		catcher.mouse_filter = Control.MOUSE_FILTER_STOP
		catcher.z_index = 50
		catcher.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed: close_list())
		host.add_child(catcher)
		var rows := mini(items.size(), 9)
		var width := maxf(size.x, 96.0)
		list = Panel.new()
		list.add_theme_stylebox_override("panel", WindowTheme.box(3, 94))
		list.z_index = 51
		var origin: Vector2 = get_global_rect().position - host.get_global_rect().position
		var h := rows * 14.0 + 4.0
		var y := origin.y + size.y
		if y + h > host.size.y: y = maxf(0.0, origin.y - h)
		var x := clampf(origin.x, 0.0, maxf(0.0, host.size.x - width))
		list.position = Vector2(x, y)
		list.size = Vector2(width, h)
		host.add_child(list)
		var scroll := ScrollContainer.new()
		scroll.position = Vector2(2, 2)
		scroll.size = Vector2(width - 4, rows * 14.0)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		list.add_child(scroll)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.custom_minimum_size = Vector2(width - 4 - (8 if items.size() > 9 else 0), 0)
		scroll.add_child(box)
		for i in items.size():
			var b := Button.new()
			b.text = str(labels[i])
			b.clip_text = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(width - 4 - (8 if items.size() > 9 else 0), 14)
			b.add_theme_font_size_override("font_size", 8)
			b.name = "Item%d" % i
			var chosen: Variant = items[i]
			b.pressed.connect(func():
				close_list()
				set_value(chosen)
				picked.emit(chosen))
			box.add_child(b)

	func close_list() -> void:
		for node in [catcher, list]:
			if node != null and is_instance_valid(node):
				if node.get_parent() != null: node.get_parent().remove_child(node)
				node.queue_free()
		catcher = null
		list = null

static func picker(parent: Node, host: Control, area: Rect2, items: Array, value: Variant, labels: Array = []) -> Picker:
	var node := Picker.new()
	node.position = area.position
	node.size = Vector2(area.size.x, maxf(area.size.y, 14.0))
	parent.add_child(node)
	node.size = Vector2(area.size.x, maxf(area.size.y, 14.0))
	node.setup(host, items, value, labels)
	return node

# ---- Stepper: [-] value [+] ---------------------------------------------------------------------------

class Stepper extends Control:
	signal changed(value: float)
	var value := 0.0
	var step := 1.0
	var low := -1000000.0
	var high := 1000000.0
	var shown: Label
	var minus: Button
	var plus: Button
	var auto_text := ""

	func setup(p_value: float, p_step: float, p_low: float, p_high: float) -> void:
		value = p_value
		step = p_step
		low = p_low
		high = p_high
		minus = Button.new()
		minus.text = "-"
		minus.position = Vector2(0, 0)
		minus.size = Vector2(14, 14)
		minus.focus_mode = Control.FOCUS_NONE
		add_child(minus)
		minus.size = Vector2(14, 14)
		plus = Button.new()
		plus.text = "+"
		plus.position = Vector2(size.x - 14, 0)
		plus.size = Vector2(14, 14)
		plus.focus_mode = Control.FOCUS_NONE
		add_child(plus)
		plus.size = Vector2(14, 14)
		shown = Label.new()
		shown.position = Vector2(16, 1)
		shown.size = Vector2(size.x - 32, 12)
		shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shown.add_theme_font_size_override("font_size", 8)
		add_child(shown)
		shown.size = Vector2(size.x - 32, 12)
		minus.pressed.connect(func(): bump(-1.0))
		plus.pressed.connect(func(): bump(1.0))
		refresh()

	func bump(direction: float) -> void:
		value = clampf(snappedf(value + direction * step, step / 10.0), low, high)
		refresh()
		changed.emit(value)

	func refresh() -> void:
		shown.text = auto_text if auto_text != "" else (str(snappedf(value, 0.01)))

static func stepper(parent: Node, area: Rect2, value: float, step: float, low: float = -1000000.0, high: float = 1000000.0) -> Stepper:
	var node := Stepper.new()
	node.position = area.position
	node.size = Vector2(area.size.x, 14)
	parent.add_child(node)
	node.size = Vector2(area.size.x, 14)
	node.setup(value, step, low, high)
	return node

static func line_edit(parent: Node, area: Rect2, text: String, placeholder: String = "") -> LineEdit:
	var node := LineEdit.new()
	node.position = area.position
	node.size = Vector2(area.size.x, maxf(area.size.y, 14.0))
	node.text = text
	node.placeholder_text = placeholder
	node.add_theme_font_size_override("font_size", 8)
	node.add_theme_constant_override("minimum_character_width", 2)
	node.custom_minimum_size = Vector2(0, 14)
	parent.add_child(node)
	node.size = Vector2(area.size.x, maxf(area.size.y, 14.0))
	return node

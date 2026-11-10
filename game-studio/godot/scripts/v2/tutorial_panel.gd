extends Control
# Right-hand strip of the desktop: Ms. Hanh's coach-mark bubble (day-1 tutorial) and the goal checklist.
# Progress comes from real player actions reported through note(); Continue and Skip are always available.
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const Sprites = preload("res://scripts/v2/sprite_lib.gd")
const TooltipLabel = preload("res://scripts/v2/windows/tooltip_label.gd")
const AREA := Rect2(504, 30, 132, 290)
const BUBBLE_HEIGHT := 128
const GOALS := ["read", "verify", "pin", "write", "send"]
# Each step ends when the player does the matching action; "question" waits for Continue.
const STEP_FLAGS := {"question":"", "browser":"opened_browser", "select":"selected", "codepad":"opened_tools", "check":"checked", "pin":"pinned", "mail":"opened_mail", "forecast":"composed", "send":"sent"}
var strings: Dictionary
var sprites := Sprites.new()
var steps: Array = []
var step := 0
var active := false
var skipped := false
var finished := false
var flags: Dictionary = {}
var goals: Dictionary = {}
var goals_enabled := true
var collapsed := false
var bubble: Panel
var step_label: Label
var text_label: Label
var continue_button: Button
var skip_button: Button
var goals_panel: Panel
var goals_header: Button
var goal_rows: Dictionary = {}
var overlay: Control
signal changed

class Overlay extends Control:
	var target := Rect2()
	var origin := Vector2.ZERO
	var phase := 0.0
	func _process(delta: float) -> void:
		phase += delta
		if visible: queue_redraw()
	func _draw() -> void:
		if target.size.x <= 0 or target.size.y <= 0: return
		var pulse := 0.65 + 0.35 * sin(phase * 5.0)
		var tint := Color(Palette.color(28), pulse)
		var frame := target.grow(2)
		draw_rect(frame, tint, false, 2.0)
		var nearest := Vector2(clampf(origin.x, frame.position.x, frame.end.x), clampf(origin.y, frame.position.y, frame.end.y))
		if nearest.distance_to(origin) < 6.0: return
		var direction := (nearest - origin).normalized()
		var side := Vector2(-direction.y, direction.x)
		var tip := nearest
		draw_line(origin, tip - direction * 4.0, tint, 1.0)
		draw_colored_polygon(PackedVector2Array([tip, tip - direction * 6.0 + side * 3.0, tip - direction * 6.0 - side * 3.0]), tint)

func build(texts: Dictionary) -> void:
	strings = texts
	steps = strings.tutorial.steps
	position = AREA.position
	size = AREA.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble = Panel.new()
	bubble.size = Vector2(AREA.size.x, BUBBLE_HEIGHT)
	bubble.add_theme_stylebox_override("panel", WindowTheme.box(2, 28))
	add_child(bubble)
	step_label = _label(bubble, "", Rect2(4, 3, 124, 12), 28)
	text_label = _label(bubble, "", Rect2(4, 17, 124, 78), 22)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button = _button(bubble, strings.tutorial["continue"], Rect2(4, 102, 60, 20))
	continue_button.pressed.connect(advance)
	skip_button = _button(bubble, strings.tutorial.skip, Rect2(68, 102, 60, 20))
	skip_button.pressed.connect(skip)
	goals_panel = Panel.new()
	goals_panel.add_theme_stylebox_override("panel", WindowTheme.box(2, 5))
	add_child(goals_panel)
	goals_header = _button(goals_panel, "", Rect2(1, 1, AREA.size.x - 2, 14))
	goals_header.pressed.connect(toggle_collapsed)
	for i in GOALS.size():
		var id: String = GOALS[i]
		var holder := Control.new()
		holder.position = Vector2(4, 18 + i * 13)
		holder.size = Vector2(124, 12)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		goals_panel.add_child(holder)
		var mark := TextureRect.new()
		mark.size = Vector2(8, 8)
		mark.position = Vector2(0, 2)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(mark)
		var name_label := _label(holder, strings.goals[id], Rect2(12, 0, 112, 12), 22)
		goal_rows[id] = {"holder":holder, "mark":mark, "label":name_label}
	overlay = Overlay.new()
	overlay.name = "CoachOverlay"
	overlay.size = Vector2(640, 360)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_meta("overlay", true)
	reset_goals()
	layout()

func _label(parent: Node, text: String, area: Rect2, color_index: int) -> Label:
	var node := TooltipLabel.new()
	node.add_theme_font_size_override("font_size", 8)
	node.text = text
	node.clip_text = true
	node.position = area.position
	node.size = area.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_color_override("font_color", Palette.color(color_index))
	parent.add_child(node)
	node.size = area.size
	return node

func _button(parent: Node, text: String, area: Rect2) -> Button:
	var node := Button.new()
	node.add_theme_font_size_override("font_size", 8)
	node.text = text
	node.clip_text = true
	node.position = area.position
	node.size = area.size
	parent.add_child(node)
	node.size = area.size
	return node

func reset_goals() -> void:
	goals.clear()
	for id in GOALS: goals[id] = false
	_refresh_goals()

func set_goal(id: String, value: bool = true) -> void:
	if not goals.has(id) or goals[id] == value: return
	goals[id] = value
	_refresh_goals()

func set_day(day: int) -> void:
	goals_enabled = day <= 2
	layout()

func toggle_collapsed() -> void:
	collapsed = not collapsed
	layout()

func _refresh_goals() -> void:
	if goals_header == null: return
	var done := goals.values().count(true)
	goals_header.text = strings.goals.title + " " + str(done) + "/" + str(GOALS.size()) + (" +" if collapsed else " -")
	goals_header.tooltip_text = strings.goals.show if collapsed else strings.goals.hide
	for id in GOALS:
		var row: Dictionary = goal_rows[id]
		row.mark.texture = sprites.frame("check" if goals[id] else "dash")
		row.label.add_theme_color_override("font_color", Palette.color(24 if goals[id] else 22))

func layout() -> void:
	if bubble == null: return
	bubble.visible = active
	goals_panel.visible = goals_enabled
	_refresh_goals()
	goals_panel.position = Vector2(0, BUBBLE_HEIGHT + 4 if active else 0)
	var rows_visible := not collapsed
	goals_panel.size = Vector2(AREA.size.x, 18 + GOALS.size() * 13 + 2 if rows_visible else 16)
	for id in GOALS: goal_rows[id].holder.visible = rows_visible
	overlay.visible = active
	if active:
		var current: Dictionary = steps[step]
		step_label.text = strings.tutorial.name + " · " + strings.tutorial.step % int(current.group)
		text_label.text = current.text
		overlay.origin = global_position + Vector2(0, BUBBLE_HEIGHT * 0.5)
	changed.emit()

func current_id() -> String:
	return str(steps[step].id) if active and step < steps.size() else ""

func start() -> void:
	skipped = false
	finished = false
	flags.clear()
	active = true
	step = 0
	layout()

func skip() -> void:
	active = false
	skipped = true
	layout()

func advance() -> void:
	if not active: return
	step += 1
	_after_step()

func _after_step() -> void:
	# Skip steps whose action the player already did.
	while active and step < steps.size() and flag_done(step): step += 1
	if step >= steps.size():
		active = false
		finished = true
	layout()

func flag_done(index: int) -> bool:
	var flag: String = STEP_FLAGS.get(str(steps[index].id), "")
	return flag != "" and bool(flags.get(flag, false))

# Records a real player action; the current step advances when it matches.
func note(flag: String) -> void:
	flags[flag] = true
	if not active:
		layout()
		return
	# Jump past the latest step the player has already completed.
	var latest := -1
	for index in range(step, steps.size()):
		if flag_done(index): latest = index
	if latest >= 0:
		step = latest + 1
		_after_step()
	else:
		layout()

func set_target(rect: Rect2) -> void:
	overlay.target = rect

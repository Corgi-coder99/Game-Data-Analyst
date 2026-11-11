extends Control
# T-035: the guided tutorial coach (days 1-5 of tutorial mode). Dr. Linh's bubble in the right strip shows
# the current step of the day's scripted case. The step advances when the REAL state matches (a file opened,
# a Sheet step added, a chart pinned, attached, a finding chosen, the forecast written, Send), never on a timer.
# "I'm stuck" shows how to do the current step; steps that are only about looking have a Next button.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const TutorialPanel = preload("res://scripts/v2/tutorial_panel.gd")
const TutorialScript = preload("res://scripts/learn/tutorial_script.gd")
const Sprites = preload("res://scripts/v2/sprite_lib.gd")
const AREA := Rect2(504, 30, 132, 290)
signal changed
var strings: Dictionary = {}
var texts: Dictionary = {}
var day := 0
var active := false
var manual: Dictionary = {}
var status: Dictionary = {}
var stuck_for := ""
var sprites := Sprites.new()
var panel: Panel
var title_label: Label
var step_label: Label
var text_label: Label
var stuck_label: Label
var next_button: Button
var stuck_button: Button
var overlay: Control

func build(all_strings: Dictionary) -> void:
	strings = all_strings
	texts = strings.learn.tutorial
	position = AREA.position
	size = AREA.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = UI.panel(self, Rect2(0, 0, 132, 176), 2, 21)
	var portrait := TextureRect.new()
	portrait.texture = sprites.frame("drlinh")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(4, 4)
	portrait.size = Vector2(24, 36)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)
	title_label = UI.wrapped(panel, "", Rect2(32, 4, 96, 30), 28, 3)
	step_label = UI.label(panel, "", Rect2(32, 30, 96, 10), 7)
	text_label = UI.wrapped(panel, "", Rect2(4, 44, 124, 60), 22, 6)
	stuck_label = UI.wrapped(panel, "", Rect2(4, 106, 124, 46), 21, 4)
	next_button = UI.button(panel, texts.next, Rect2(4, 156, 58, 16))
	next_button.name = "CoachNext"
	next_button.pressed.connect(press_next)
	stuck_button = UI.button(panel, texts.stuck, Rect2(66, 156, 62, 16))
	stuck_button.name = "CoachStuck"
	stuck_button.pressed.connect(show_stuck)
	overlay = TutorialPanel.Overlay.new()
	overlay.name = "CaseCoachOverlay"
	overlay.size = Vector2(640, 360)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_meta("overlay", true)
	visible = false
	overlay.visible = false

func start_day(value: int, enabled: bool) -> void:
	day = value
	active = enabled and TutorialScript.STEPS.has(value)
	manual.clear()
	stuck_for = ""
	status = {}
	visible = active
	if overlay != null: overlay.visible = active
	if active:
		title_label.text = texts.case % [day, texts.titles[str(day)]]
	changed.emit()

func current_id() -> String:
	if not active or status.is_empty() or int(status.index) < 0: return ""
	return str(status.steps[int(status.index)].id)

func current_is_manual() -> bool:
	var list: Array = TutorialScript.STEPS.get(day, [])
	var i := int(status.get("index", -1))
	return i >= 0 and i < list.size() and str(list[i][1]) == "manual"

func press_next() -> void:
	var id := current_id()
	if id == "": return
	manual[id] = true
	changed.emit()

func show_stuck() -> void:
	stuck_for = current_id()
	update_view()

# Called with the context of the session (TutorialScript.context) whenever something may have changed.
func refresh(ctx: Dictionary) -> void:
	if not active: return
	status = TutorialScript.status(day, ctx)
	update_view()

func update_view() -> void:
	if not active or status.is_empty(): return
	var id := current_id()
	step_label.text = texts.step % [mini(int(status.done_count) + 1, int(status.total)), int(status.total)] if id != "" else ""
	if id == "":
		text_label.text = texts.ready
		stuck_label.text = ""
	else:
		var pair: Array = texts.steps[str(day)].get(id, ["", ""])
		text_label.text = str(pair[0])
		stuck_label.text = str(pair[1]) if stuck_for == id else ""
	next_button.visible = current_is_manual()
	stuck_button.disabled = id == ""

func set_target(rect: Rect2) -> void:
	if overlay != null: overlay.target = rect if active else Rect2()
	if overlay != null: overlay.origin = global_position + Vector2(0, 40)

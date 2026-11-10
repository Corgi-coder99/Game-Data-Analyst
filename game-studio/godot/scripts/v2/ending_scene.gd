extends "res://scripts/v2/windows/window_base.gd"
const OfficeScene = preload("res://scenes/v2/office.tscn")
signal replay_requested
signal title_requested
var strings: Dictionary
var office: Node2D
var status: Dictionary = {}
var ending := ""
var boss_category := ""
var boss_line := ""
var summary_lines: Array = []
var replay_button: Button
var title_button: Button
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

func _text(parent: Node, text: String, area: Rect2, color_index: int = 22, font_size: int = 8) -> Label:
	var node := label(parent, text, area, color_index)
	if font_size != 8: node.add_theme_font_size_override("font_size", font_size)
	return node

func boss_category_for(value: Dictionary) -> String:
	match str(value.ending):
		"fired": return "fired"
		"bankrupt": return "bankrupt"
	return "survived_won" if bool(value.won) else "survived_lost"

func show_ending(final_status: Dictionary) -> void:
	_build()
	status = final_status.duplicate(true)
	ending = str(status.ending)
	empty(self)
	summary_lines.clear()
	# Backdrop: the boss waits at the door; an empty desk when the player was dismissed.
	office = OfficeScene.instantiate()
	add_child(office)
	office.set_hint_visible(false)
	office.desk_button.hide()
	office.set_process_unhandled_input(false)
	office.seat_now()
	office.set_phase("sang" if ending == "survived" else "chieu")
	office.set_clock(17, 30)
	office.boss.show()
	office.door.texture = office.lib.frame("door", 1)
	if ending == "fired": office.player.hide()
	var panel := Panel.new()
	panel.position = Vector2(120, 28)
	panel.size = Vector2(400, 244)
	panel.add_theme_stylebox_override("panel", WindowTheme.box(2, 21))
	add_child(panel)
	var heading := _text(panel, strings.ending[ending], Rect2(12, 8, 376, 17), 8, 12)
	boss_category = boss_category_for(status)
	boss_line = strings.boss_lines[boss_category]
	var quote := _text(panel, strings.flow.boss + ": " + boss_line, Rect2(12, 28, 376, 40), 7, 12)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.max_lines_visible = 2
	var y := 70
	if ending == "bankrupt":
		_text(panel, strings.ending.bankrupt_note, Rect2(12, 72, 376, 12), 26)
	elif ending == "fired":
		_text(panel, strings.ending.empty_desk, Rect2(12, 72, 376, 12), 26)
	y = 86
	var lines := [
		strings.ending.rank % strings.ranks[status.rank],
		strings.ending.trust % float(status.trust),
		strings.ending.days % int(status.day),
		strings.ending.pay % float(status.personal_pay),
		strings.ending.score % maxf(0.0, float(status.score))]
	for line in lines:
		_text(panel, line, Rect2(12, y, 376, 12), 22)
		summary_lines.append(line)
		y += 15
	y += 6
	var won := bool(status.won)
	icon(panel, "check" if won else "cross", Vector2(12, y + 4))
	var verdict := _text(panel, strings.ending.won if won else strings.ending.lost, Rect2(26, y, 360, 17), 24 if won else 26, 12)
	summary_lines.append(verdict.text)
	replay_button = button(panel, strings.ending.replay, Rect2(12, 208, 180, 24))
	title_button = button(panel, strings.ending.to_title, Rect2(208, 208, 180, 24))
	replay_button.focus_mode = Control.FOCUS_NONE
	title_button.focus_mode = Control.FOCUS_NONE
	replay_button.pressed.connect(func(): replay_requested.emit())
	title_button.pressed.connect(func(): title_requested.emit())
	heading.tooltip_text = heading.text

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		replay_requested.emit()
		get_viewport().set_input_as_handled()

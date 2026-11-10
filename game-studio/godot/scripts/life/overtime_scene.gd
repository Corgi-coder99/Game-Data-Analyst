extends "res://scripts/life/daily_base.gd"
# T-026: after the review the player can stay late. The day's wage arrives here (with a +$ popup);
# overtime adds pay but costs Stamina and Mood and raises Stress. Enter goes home.
const ReactionStage = preload("res://scripts/v2/reaction_stage.gd")
signal finished(hours: int)
var vitals: RefCounted
var public: Dictionary = {}
var stage: Control
var title_label: Label
var sub_label: Label
var wage_label: Label
var message_label: Label
var body: Control
var buttons: Dictionary = {}
var phase := "choose"
var hours_worked := 0
var message := ""
var wage := 0
var left := false

func _ready() -> void:
	_build()

func _build() -> void:
	if built: return
	built = true
	_prepare()
	_rect(self, 17, Rect2(0, 0, 640, 360))
	_rect(self, 18, Rect2(0, 0, 640, 120))
	_rect(self, 36, Rect2(0, 96, 640, 24))
	_rect(self, 3, Rect2(0, 232, 640, 128))
	# Office window with the dusk skyline and the wall clock.
	_rect(self, 5, Rect2(20, 28, 196, 98))
	_rect(self, 44, Rect2(24, 32, 188, 90))
	_rect(self, 36, Rect2(24, 80, 188, 42))
	for i in range(8):
		_rect(self, 17 if i % 2 == 0 else 39, Rect2(24 + i * 24, 70 - (i * 7) % 24, 20, 52 + (i * 7) % 24))
	_rect(self, 5, Rect2(116, 32, 3, 90))
	_rect(self, 62, Rect2(240, 36, 28, 28))
	_rect(self, 64, Rect2(243, 39, 22, 22))
	_rect(self, 1, Rect2(253, 43, 2, 10))
	_rect(self, 1, Rect2(253, 51, 8, 2))
	# Desk with a lit monitor.
	_rect(self, 9, Rect2(20, 190, 220, 10))
	_rect(self, 10, Rect2(24, 200, 212, 50))
	_rect(self, 62, Rect2(90, 142, 70, 48))
	_rect(self, 33, Rect2(94, 146, 62, 38))
	_rect(self, 34, Rect2(100, 152, 36, 3))
	_rect(self, 34, Rect2(100, 160, 46, 3))
	_rect(self, 34, Rect2(100, 168, 28, 3))
	_sprite(self, "player", 0, Vector2(30, 126), 3)
	stage = ReactionStage.new()
	stage.name = "Stage"
	stage.position = Vector2(8, 236)
	add_child(stage)
	stage.build()
	for node in stage.get_children():
		if node is ColorRect: node.hide()
	stage.neighbor_node.hide()
	title_label = _text(self, "", Rect2(8, 4, 330, 17), 22, 12)
	sub_label = _wrapped(self, "", Rect2(8, 22, 300, 24), 7, 2)
	var panel := _panel(self, Rect2(312, 28, 320, 190))
	body = Control.new()
	body.position = Vector2(8, 8)
	body.size = Vector2(304, 174)
	panel.add_child(body)
	wage_label = _text(self, "", Rect2(312, 224, 320, 12), 52)
	var chat := _panel(self, Rect2(312, 240, 320, 44))
	message_label = _wrapped(chat, "", Rect2(6, 4, 308, 36), 22, 3)
	_text(self, daily.overtime_hint, Rect2(8, 344, 296, 12), 6)

func open(life_game: RefCounted, status: Dictionary) -> void:
	_build()
	life = life_game
	vitals = life.vitals
	public = status.duplicate(true)
	left = false
	phase = "choose"
	hours_worked = 0
	title_label.text = daily.overtime_title
	sub_label.text = daily.overtime_sub
	stage.clear()
	wage = life.deposit_wage(public)
	if wage > 0: stage.show_money("pay", wage, 0.0, 0)
	wage_label.text = daily.overtime_wage % wage
	message = ""
	render()

func render() -> void:
	if life == null: return
	empty(body)
	buttons.clear()
	var max_hours := int(vitals.cfg.overtime.max_hours)
	if phase == "choose":
		var go := button(body, daily.overtime_go, Rect2(0, 0, 304, 24))
		go.focus_mode = Control.FOCUS_NONE
		go.pressed.connect(go_home)
		buttons["go"] = go
		var y := 34
		for hours in range(1, max_hours + 1):
			var pay := hours * int(vitals.cfg.overtime.pay_per_hour)
			var node := button(body, daily.overtime_hours % [hours, pay], Rect2(0, y, 304, 22))
			node.focus_mode = Control.FOCUS_NONE
			node.pressed.connect(work_overtime.bind(hours))
			node.tooltip_text = "Stamina %+d  Mood %+d  Stress %+d" % [hours * int(vitals.cfg.overtime.stamina), hours * int(vitals.cfg.overtime.mood), hours * int(vitals.cfg.overtime.stress)]
			buttons["h%d" % hours] = node
			y += 28
		_text(body, "Per hour: Stamina %+d  Mood %+d  Stress %+d" % [int(vitals.cfg.overtime.stamina), int(vitals.cfg.overtime.mood), int(vitals.cfg.overtime.stress)], Rect2(0, y + 4, 304, 12), 24)
	else:
		var cont := button(body, daily.continue, Rect2(0, 0, 304, 24))
		cont.focus_mode = Control.FOCUS_NONE
		cont.pressed.connect(go_home)
		buttons["continue"] = cont
	message_label.text = message

func work_overtime(hours: int) -> Dictionary:
	if phase != "choose" or left: return {"ok": false, "error": "phase"}
	var result: Dictionary = vitals.overtime(hours)
	if not result.ok: return result
	hours_worked = hours
	phase = "done"
	stage.show_money("bonus", int(result.pay), 0.0, 1)
	stage.set_emote("sad" if result.exhausted else "neutral")
	message = daily.overtime_result % [hours, int(result.pay)] + "  " + change_text(0, result.change)
	if result.exhausted: message += "\n" + daily.overtime_exhausted % absi(int(vitals.cfg.overtime.exhausted_health))
	render()
	return result

func go_home() -> void:
	if left: return
	left = true
	finished.emit(hours_worked)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or left: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		go_home()

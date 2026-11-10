extends "res://scripts/life/daily_base.gd"
# T-026: the morning at home. Step 1: breakfast (eat / skip / sleep in). Step 2: how to get to work.
# A sick day shows one screen instead and skips both. Enter takes the default choice, Esc hurries.
const HomeArt = preload("res://scripts/v2/home_art.gd")
signal breakfast_done(choice: String)
signal finished(transport_id: String)
var public: Dictionary = {}
var step := "breakfast"
var title_label: Label
var sub_label: Label
var message_label: Label
var hint_label: Label
var body: Control
var buttons: Dictionary = {}
var tips: Dictionary = {}
var message := ""
var closed := false
var sick_info: Dictionary = {}

func _ready() -> void:
	_build()

func _build() -> void:
	if built: return
	built = true
	_prepare()
	_build_room()
	title_label = _text(self, "", Rect2(8, 4, 330, 17), 65, 12)
	sub_label = _text(self, "", Rect2(8, 22, 296, 12), 66)
	var panel := _panel(self, Rect2(312, 28, 320, 276))
	body = Control.new()
	body.position = Vector2(8, 8)
	body.size = Vector2(304, 260)
	panel.add_child(body)
	var chat := _panel(self, Rect2(312, 308, 320, 40))
	message_label = _wrapped(chat, "", Rect2(6, 4, 308, 32), 22, 3)
	hint_label = _text(self, daily.default_hint, Rect2(8, 344, 296, 12), 65)

# T-028: a cozy bedroom (home_art.gd) with the alarm clock text on top and the player sprite.
func _build_room() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = HomeArt.texture()
	backdrop.size = Vector2(308, 360)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_meta("overlay", true)
	add_child(backdrop)
	_text(self, daily.alarm, Rect2(159, 159, 21, 10), 51)
	_sprite(self, "player", 0, Vector2(92, 196), 3)

# ---- steps ---------------------------------------------------------------------------------

func open(life_game: RefCounted, status: Dictionary, sick: Dictionary = {}) -> void:
	_build()
	life = life_game
	public = status.duplicate(true)
	closed = false
	sick_info = sick
	var day := int(public.get("day", 0)) + 1
	if not sick.is_empty():
		step = "sick"
		title_label.text = daily.sick_title % day
	else:
		step = "breakfast"
		title_label.text = daily.morning_title % day
	render()

func render() -> void:
	if life == null: return
	empty(body)
	buttons.clear()
	tips.clear()
	var v: RefCounted = life.vitals
	match step:
		"breakfast": _render_breakfast(v)
		"transport": _render_transport(v)
		"sick": _render_sick()
	message_label.text = message

func _heading(text: String) -> void:
	_text(body, text, Rect2(0, 0, 304, 14), 24, 12)

func _render_breakfast(v: RefCounted) -> void:
	sub_label.text = daily.morning_sub
	_heading(daily.breakfast_title)
	var y := 22
	for id in v.breakfast_options():
		var price: int = int(v.cfg.breakfast.home.price) if id == "home" else 0
		var text: String = daily.breakfast[id] % price if id == "home" else daily.breakfast[id]
		var node := button(body, text, Rect2(0, y, 304, 22))
		node.focus_mode = Control.FOCUS_NONE
		var enough: bool = life.wallet >= price
		node.disabled = not enough
		node.tooltip_text = daily.breakfast_tip[id] if enough else daily.no_money
		node.pressed.connect(choose_breakfast.bind(id))
		buttons[id] = node
		_wrapped(body, daily.breakfast_tip[id], Rect2(4, y + 25, 296, 22), 7, 2)
		y += 62

func _render_transport(v: RefCounted) -> void:
	sub_label.text = daily.transport_title
	_heading(daily.transport_title)
	var y := 22
	for id in v.transport_ids():
		var t: Dictionary = v.cfg.transport[id]
		var price := int(t.price)
		var node := button(body, daily.transport[id], Rect2(0, y, 304, 20))
		node.focus_mode = Control.FOCUS_NONE
		var enough: bool = life.wallet >= price
		node.disabled = not enough
		node.tooltip_text = daily.transport_tip[id] if enough else daily.no_money
		node.pressed.connect(choose_transport.bind(id))
		buttons[id] = node
		_text(body, daily.transport_line % [int(t.minutes), price, int(t.stress), int(t.stamina)], Rect2(4, y + 22, 296, 12), 24)
		_text(body, daily.transport_tip[id] if enough else daily.no_money, Rect2(4, y + 35, 296, 12), 7 if enough else 51)
		y += 56

func _render_sick() -> void:
	sub_label.text = ""
	_heading(daily.sick_title % (int(public.get("day", 0)) + 1))
	var line: String = daily.sick_text % int(sick_info.get("bill", 0))
	_wrapped(body, line, Rect2(0, 24, 304, 48), 22, 4)
	if bool(sick_info.get("hr", false)):
		_wrapped(body, daily.sick_hr, Rect2(0, 76, 304, 24), 28, 2)
	var node := button(body, daily.sick_continue, Rect2(0, 120, 304, 24))
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(continue_sick)
	buttons["continue"] = node

# ---- actions (also called by tests) -----------------------------------------------------

func choose_breakfast(choice: String) -> Dictionary:
	if step != "breakfast" or closed: return {"ok": false, "error": "step"}
	var result: Dictionary = life.vitals.eat_breakfast(choice)
	if not result.ok:
		message = daily.no_money
		render()
		return result
	match choice:
		"home": message = daily.breakfast_result.home % [int(result.cost), int(result.change.stamina), int(result.change.mood)]
		"skip": message = daily.breakfast_result.skip
		"sleep_in": message = daily.breakfast_result.sleep_in % int(result.change.stamina)
	step = "transport"
	render()
	breakfast_done.emit(choice)
	return result

func choose_transport(id: String) -> Dictionary:
	if step != "transport" or closed: return {"ok": false, "error": "step"}
	var result: Dictionary = life.vitals.choose_transport(id)
	if not result.ok:
		message = daily.no_money
		render()
		return result
	closed = true
	message = daily.transport_result % [daily.transport[id], int(result.cost)]
	render()
	finished.emit(id)
	return result

func continue_sick() -> void:
	if step != "sick" or closed: return
	closed = true
	finished.emit("")

# Enter: take the default (breakfast at home, bus). Without the money, the cheapest option.
func accept_default() -> void:
	if closed: return
	match step:
		"breakfast":
			var result: Dictionary = choose_breakfast("home")
			if not result.ok: choose_breakfast("skip")
		"transport":
			var result: Dictionary = choose_transport("bus")
			if not result.ok: choose_transport("walk")
		"sick": continue_sick()

func hurry() -> void:
	var guard := 0
	while not closed and guard < 4:
		guard += 1
		accept_default()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or closed: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			accept_default()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			hurry()

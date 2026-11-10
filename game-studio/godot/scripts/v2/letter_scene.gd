extends "res://scripts/life/daily_base.gd"
# T-030: paper-style screen for the first-run explanation and for the HR/Boss "while you were away"
# letters. In-game text only (data/meta.json); no notification is sent.
const CityArt = preload("res://scripts/v2/city_art.gd")
signal finished
var screen: Dictionary = {}
var continue_button: Button
var body_labels: Array = []
var done := false

func _ready() -> void:
	_prepare_once()

func _prepare_once() -> void:
	if built: return
	built = true
	_prepare()
	var backdrop := TextureRect.new()
	backdrop.texture = CityArt.backdrop("dusk")
	backdrop.set_meta("overlay", true)
	backdrop.size = size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	_rect(self, 65, Rect2(124, 28, 400, 300))
	_rect(self, 101, Rect2(120, 24, 400, 300))
	_rect(self, 102, Rect2(122, 26, 396, 296))

func open(data: Dictionary) -> void:
	_prepare_once()
	screen = data
	done = false
	for node in body_labels: node.queue_free()
	body_labels.clear()
	if str(data.type) == "intro": _build_intro()
	else: _build_letter()
	continue_button = button(self, "Continue", Rect2(220, 288, 200, 24))
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(finish)
	body_labels.append(continue_button)

func _add(node: Control) -> void:
	body_labels.append(node)

func _build_letter() -> void:
	_add(_text(self, str(screen.from), Rect2(140, 34, 360, 12), 87))
	_add(_text(self, str(screen.subject), Rect2(140, 50, 360, 16), 66, 12))
	_add(_rect(self, 100, Rect2(140, 70, 360, 1)))
	_add(_wrapped(self, str(screen.body), Rect2(140, 78, 360, 52), 65, 5))
	_add(_text(self, str(screen.missed_line), Rect2(140, 138, 360, 12), 88))
	var y := 154
	for line in screen.effects:
		_add(_wrapped(self, "- " + str(line), Rect2(140, y, 360, 12), 66, 1))
		y += 14
	_add(_wrapped(self, str(screen.hint), Rect2(140, 232, 360, 24), 99, 2))

func _build_intro() -> void:
	_add(_text(self, str(screen.title), Rect2(140, 34, 360, 16), 66, 12))
	_add(_rect(self, 100, Rect2(140, 54, 360, 1)))
	var y := 62
	for line in screen.lines:
		_add(_wrapped(self, str(line), Rect2(140, y, 360, 40), 65, 4))
		y += 46
	_add(_wrapped(self, str(screen.hint), Rect2(140, 232, 360, 24), 99, 2))

func finish() -> void:
	if done: return
	done = true
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey and event.pressed and not event.echo): return
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
		finish()
		get_viewport().set_input_as_handled()

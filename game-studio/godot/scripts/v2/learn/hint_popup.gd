extends Control
# T-035: the hint popup of Sheet, Charts and Mail. It lists the hints already given for today's case (three
# levels: problem type, method card, Sheet operation families) and offers the next one for analysis Energy.
# Opening it is free; only the "Get hint" button spends Energy, once per level and case. No answer is shown.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
signal closed
signal given(info: Dictionary)
var session: RefCounted
var file_id := ""
var texts: Dictionary = {}
var get_button: Button
var close_button: Button
var note_label: Label

func open(p_session: RefCounted, p_file_id: String, host: Control) -> void:
	session = p_session
	file_id = p_file_id
	texts = session.learn_text()
	name = "HintPopup"
	set_meta("overlay", true)
	size = Vector2(300, 190)
	position = Vector2(maxf(0.0, (host.size.x - size.x) / 2.0), maxf(0.0, (host.size.y - size.y) / 2.0))
	z_index = 60
	host.add_child(self)
	render()

func render() -> void:
	UI.clear(self)
	UI.panel(self, Rect2(0, 0, 300, 190), 2, 28)
	var used: int = session.hint_level(file_id)
	var total: int = int(session.learn_cfg.get("hint_levels", 3))
	UI.label(self, "%s  %d/%d" % [texts.hint_button, used, total], Rect2(6, 3, 200, 12), 28)
	var y := 18
	if used == 0:
		UI.wrapped(self, texts.hint_tip % session.hint_cost(), Rect2(6, y, 288, 30), 7, 3)
		y += 32
	for level in range(1, used + 1):
		var info: Dictionary = session.hint_text(file_id, level)
		UI.label(self, str(info.title), Rect2(6, y, 288, 10), 21)
		y += 10
		var lines := 2 if level != 2 else 5
		var body := UI.wrapped(self, str(info.text), Rect2(6, y, 288, 10 * lines), 22, lines)
		body.name = "HintText%d" % level
		y += 10 * lines + 2
	var cost_text: String = texts.hint_tip % session.hint_cost()
	get_button = UI.button(self, "%s (-%d)" % [texts.hint_button, session.hint_cost()], Rect2(6, 170, 110, 16), cost_text)
	get_button.name = "HintGet"
	get_button.disabled = used >= total
	get_button.pressed.connect(_request)
	close_button = UI.button(self, texts.hint_close, Rect2(240, 170, 54, 16))
	close_button.name = "HintClose"
	close_button.pressed.connect(close)
	note_label = UI.label(self, session.message, Rect2(120, 172, 118, 12), 26)

func _request() -> void:
	var info: Dictionary = session.request_hint(file_id)
	if info.get("ok", false): given.emit(info)
	render()

func close() -> void:
	closed.emit()
	if get_parent() != null: get_parent().remove_child(self)
	queue_free()

# A "Hint" button for a toolbar: opens the popup over `host` for the file given by `file_getter`.
static func add_button(parent: Control, host: Control, area: Rect2, p_session: RefCounted, file_getter: Callable) -> Button:
	var b := UI.button(parent, "Hint", area, "")
	b.name = "HintButton"
	var refresh := func():
		var learn_on: bool = p_session.learn != null
		b.disabled = not learn_on
		if learn_on:
			var text: Dictionary = p_session.learn_text()
			b.tooltip_text = text.hint_tip % p_session.hint_cost()
			var used: int = p_session.hint_level(file_getter.call()) if file_getter.call() != "" else 0
			b.text = "%s %d/%d" % [text.hint_button, used, int(p_session.learn_cfg.get("hint_levels", 3))]
	refresh.call()
	b.set_meta("refresh", refresh)
	b.pressed.connect(func():
		var id: String = file_getter.call()
		if id == "" or p_session.learn == null: return
		for child in host.get_children():
			if child.name == "HintPopup": return
		var popup: Control = load("res://scripts/v2/learn/hint_popup.gd").new()
		popup.open(p_session, id, host)
		popup.given.connect(func(_i): refresh.call())
		popup.closed.connect(func(): refresh.call()))
	return b

extends Control
# T-034: Files, the inbox of today's data exports. Name, row count, a NEW badge and one plain hint.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Palette = preload("res://scripts/v2/palette.gd")
signal open_requested(file_id: String)
var session: RefCounted
var texts: Dictionary = {}
var open_buttons: Dictionary = {}

func build(p_session: RefCounted, p_texts: Dictionary) -> void:
	session = p_session
	texts = p_texts
	size = Vector2(434, 254)
	refresh()

func refresh() -> void:
	UI.clear(self)
	open_buttons.clear()
	UI.label(self, texts.files.title, Rect2(0, 0, 300, 14), 28, 12)
	if session.files.is_empty():
		UI.label(self, texts.files.empty, Rect2(0, 22, 300, 12), 6)
		return
	for i in session.files.size():
		var f: Dictionary = session.files[i]
		var y: int = 20 + i * 52
		UI.panel(self, Rect2(0, y, 432, 48), 3, 81)
		var fresh: bool = session.is_new(f.id)
		UI.label(self, str(f.title), Rect2(8, y + 4, 240, 14), 22, 12)
		UI.label(self, "%s.csv" % f.name, Rect2(8, y + 20, 160, 12), 7)
		UI.label(self, texts.files.rows % f.row_count, Rect2(172, y + 20, 70, 12), 7)
		UI.label(self, session.messy_hint(), Rect2(8, y + 32, 240, 12), 6)
		if fresh:
			var badge := UI.panel(self, Rect2(252, y + 5, 34, 14), 24, 23)
			UI.label(badge, texts.files.new, Rect2(4, 1, 28, 12), 1)
		var open := UI.button(self, texts.files.open, Rect2(350, y + 14, 72, 20), texts.files.cost % session.limit("minutes_per_file", 10))
		open.name = "Open_" + str(f.id)
		open.pressed.connect(func(): open_requested.emit(f.id))
		open_buttons[f.id] = open
	UI.label(self, texts.files.cost % session.limit("minutes_per_file", 10), Rect2(0, 20 + session.files.size() * 52 + 2, 420, 12), 7)
	UI.label(self, texts.files.hint_note, Rect2(0, 20 + session.files.size() * 52 + 14, 420, 12), 6)

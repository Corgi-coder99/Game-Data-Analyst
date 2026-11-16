extends Control
# T-046: "How the job works": a short plain-English primer for players who know nothing about the field.
# Pages come from strings.primer.pages. Back / Next / Skip; the last page ends with Start. No hidden data.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Sprites = preload("res://scripts/v2/sprite_lib.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
signal finished
var sprites := Sprites.new()
var pages: Array = []
var texts: Dictionary = {}
var page := 0
var title_label: Label
var body_label: Label
var count_label: Label
var back_button: Button
var next_button: Button
var skip_button: Button

func open(copy: Dictionary) -> void:
	texts = copy
	pages = copy.pages
	size = Vector2(640, 360)
	theme = WindowTheme.create()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var back := ColorRect.new()
	back.color = Palette.color(66)
	back.size = size
	back.set_meta("overlay", true)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	UI.panel(self, Rect2(60, 30, 520, 300), 83, 81)
	var portrait := TextureRect.new()
	portrait.texture = sprites.frame("drlinh")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(76, 60)
	portrait.size = Vector2(64, 96)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	UI.label(self, copy.heading, Rect2(76, 38, 300, 14), 6)
	count_label = UI.label(self, "", Rect2(500, 38, 64, 14), 6)
	title_label = UI.label(self, "", Rect2(156, 62, 408, 18), 28, 12)
	title_label.name = "PrimerTitle"
	body_label = UI.wrapped(self, "", Rect2(156, 90, 408, 190), 22, 14)
	body_label.name = "PrimerBody"
	back_button = UI.button(self, copy.back, Rect2(76, 292, 90, 24))
	back_button.name = "PrimerBack"
	back_button.pressed.connect(func(): show_page(page - 1))
	skip_button = UI.button(self, copy.skip, Rect2(274, 292, 90, 24))
	skip_button.name = "PrimerSkip"
	skip_button.pressed.connect(func(): finished.emit())
	next_button = UI.button(self, copy.next, Rect2(474, 292, 90, 24))
	next_button.name = "PrimerNext"
	next_button.pressed.connect(func(): show_page(page + 1))
	show_page(0)

func show_page(index: int) -> void:
	if index >= pages.size():
		finished.emit()
		return
	page = clampi(index, 0, pages.size() - 1)
	title_label.text = pages[page].title
	body_label.text = pages[page].text
	count_label.text = "%d/%d" % [page + 1, pages.size()]
	back_button.disabled = page == 0
	next_button.text = texts.start if page == pages.size() - 1 else texts.next
	skip_button.visible = page < pages.size() - 1

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT]:
			show_page(page + 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT and page > 0:
			show_page(page - 1)
			get_viewport().set_input_as_handled()

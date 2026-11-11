extends Control
# T-035: the first-run choice before the first run: guided tutorial days 1-5 (recommended) or skip it.
# The choice is stored in the local profile by the flow.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Sprites = preload("res://scripts/v2/sprite_lib.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
signal chosen(mode: String)
var sprites := Sprites.new()
var tutorial_button: Button
var skip_button: Button

func open(texts: Dictionary) -> void:
	size = Vector2(640, 360)
	theme = WindowTheme.create()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var back := ColorRect.new()
	back.color = Palette.color(66)
	back.size = size
	back.set_meta("overlay", true)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	UI.panel(self, Rect2(100, 50, 440, 250), 83, 81)
	var portrait := TextureRect.new()
	portrait.texture = sprites.frame("drlinh")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(120, 80)
	portrait.size = Vector2(64, 96)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	UI.label(self, texts.title, Rect2(200, 70, 320, 18), 28, 12)
	var body := UI.wrapped(self, texts.text, Rect2(200, 94, 324, 80), 22, 7)
	body.name = "ChoiceText"
	tutorial_button = UI.button(self, texts.tutorial, Rect2(120, 220, 200, 26))
	tutorial_button.name = "ChoiceTutorial"
	tutorial_button.pressed.connect(func(): chosen.emit("on"))
	skip_button = UI.button(self, texts.skip, Rect2(332, 220, 192, 26))
	skip_button.name = "ChoiceSkip"
	skip_button.pressed.connect(func(): chosen.emit("skip"))
	UI.label(self, texts.note, Rect2(120, 268, 400, 12), 6)

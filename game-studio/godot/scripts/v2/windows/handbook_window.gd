extends "res://scripts/v2/windows/window_base.gd"
# T-035: the Analyst Handbook app. 49 method cards grouped by skill, searchable by title, with a detail view.
# Locked cards show their title and a lock only. Reading is free: no Energy, no clock, no session needed.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Content = preload("res://scripts/learn/content.gd")
const AREA := Rect2(58, 30, 442, 290)
const LIST_W := 156
signal card_shown(card_id: String)
var strings: Dictionary
var texts: Dictionary = {}
var learn: RefCounted
var selected := ""
var query := ""
var search_edit: LineEdit
var count_label: Label
var list_scroll: ScrollContainer
var list_box: VBoxContainer
var detail_scroll: ScrollContainer
var detail_box: VBoxContainer
var detail_title: Label
var detail_tag: Label
var card_buttons: Dictionary = {}
var link_buttons: Dictionary = {}
var locked_note: Label

func initialize(all_strings: Dictionary) -> void:
	strings = all_strings
	texts = strings.learn.handbook
	build(strings.windows.handbook, AREA)
	UI.label(content, texts.search, Rect2(0, 1, 34, 12), 7)
	search_edit = UI.line_edit(content, Rect2(34, 0, LIST_W - 34, 14), "", texts.placeholder)
	search_edit.name = "HandbookSearch"
	search_edit.text_changed.connect(func(t):
		query = t.strip_edges().to_lower()
		refresh())
	count_label = UI.label(content, "", Rect2(0, 15, LIST_W, 10), 6)
	list_scroll = ScrollContainer.new()
	list_scroll.position = Vector2(0, 32)
	list_scroll.size = Vector2(LIST_W, 238)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 0)
	list_box.custom_minimum_size = Vector2(LIST_W - 10, 0)
	list_scroll.add_child(list_box)
	var portrait := TextureRect.new()
	portrait.texture = sprites.frame("drlinh")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.name = "DrLinh"
	portrait.position = Vector2(398, 0)
	portrait.size = Vector2(32, 48)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait)
	UI.label(content, strings.learn.coaching.mentor.linh, Rect2(394, 50, 40, 12), 28)
	detail_title = UI.label(content, "", Rect2(LIST_W + 6, 0, 232, 18), 28, 12)
	detail_tag = UI.label(content, "", Rect2(LIST_W + 6, 20, 232, 12), 7)
	detail_scroll = ScrollContainer.new()
	detail_scroll.position = Vector2(LIST_W + 6, 36)
	detail_scroll.size = Vector2(228, 234)
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(detail_scroll)
	detail_box = VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 2)
	detail_box.custom_minimum_size = Vector2(216, 0)
	detail_scroll.add_child(detail_box)
	refresh()

func attach_learn(state: RefCounted) -> void:
	learn = state
	refresh()

func is_open(card_id: String) -> bool:
	return learn != null and learn.is_unlocked(card_id)

func _matches(card: Dictionary) -> bool:
	return query == "" or str(card.title).to_lower().contains(query)

func refresh() -> void:
	if list_box == null: return
	UI.clear(list_box)
	card_buttons.clear()
	var total := Content.cards().size()
	var open_count: int = learn.unlocked_count() if learn != null else 0
	count_label.text = texts.count % [open_count, total]
	var shown := 0
	for skill in Content.SKILLS:
		var cards: Array = Content.cards_of_skill(skill).filter(func(c): return _matches(c))
		if cards.is_empty(): continue
		var head := Label.new()
		head.text = "%s (%d)" % [texts.skills[skill], cards.size()]
		head.add_theme_font_size_override("font_size", 8)
		head.add_theme_color_override("font_color", Palette.color(91))
		head.custom_minimum_size = Vector2(LIST_W - 10, 12)
		head.clip_text = true
		list_box.add_child(head)
		for card in cards:
			shown += 1
			var b := Button.new()
			b.text = str(card.title)
			b.name = "Card_" + str(card.id)
			b.clip_text = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 8)
			b.custom_minimum_size = Vector2(LIST_W - 10, 14)
			if not is_open(card.id):
				b.icon = sprites.frame("lock")
				b.add_theme_color_override("font_color", Palette.color(100))
			if card.id == selected:
				b.add_theme_color_override("font_color", Palette.color(28))
			var cid: String = card.id
			b.pressed.connect(show_card.bind(cid))
			list_box.add_child(b)
			card_buttons[cid] = b
	if shown == 0:
		var none := Label.new()
		none.text = texts.no_match
		none.add_theme_font_size_override("font_size", 8)
		none.custom_minimum_size = Vector2(LIST_W - 10, 12)
		list_box.add_child(none)
	_render_detail()

func show_card(card_id: String) -> void:
	selected = card_id
	refresh()
	card_shown.emit(card_id)

func _heading(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Palette.color(21))
	l.custom_minimum_size = Vector2(216, 11)
	detail_box.add_child(l)

func _body(text: String, color_index: int = 22) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Palette.color(color_index))
	l.custom_minimum_size = Vector2(216, 10)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_child(l)
	return l

func _render_detail() -> void:
	UI.clear(detail_box)
	link_buttons.clear()
	locked_note = null
	if selected == "":
		detail_title.text = texts.title
		detail_tag.text = ""
		_body(strings.learn.handbook.linh_intro, 22)
		_body(texts.free, 6)
		return
	var card: Dictionary = Content.card_by_id(selected)
	if card.is_empty():
		selected = ""
		_render_detail()
		return
	detail_title.text = str(card.title)
	detail_tag.text = str(texts.skills[card.skill])
	if not is_open(selected):
		locked_note = _body(texts.locked, 28)
		locked_note.name = "LockedNote"
		_body(texts.locked_detail, 6)
		return
	_heading(texts.what)
	_body(str(card.what))
	_heading(texts.when)
	_body(str(card.when_to_use))
	_heading(texts.mistakes)
	for m in card.common_mistakes: _body("- " + str(m))
	_heading(texts.example)
	_body(str(card.example))
	_heading(texts.how)
	_body(str(card.how_in_game))
	_heading(texts.see_also)
	for see in card.see_also:
		var other: Dictionary = Content.card_by_id(str(see))
		if other.is_empty(): continue
		var see_btn := Button.new()
		see_btn.text = "> " + str(other.title)
		see_btn.name = "See_" + str(see)
		see_btn.clip_text = true
		see_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		see_btn.focus_mode = Control.FOCUS_NONE
		see_btn.add_theme_font_size_override("font_size", 8)
		see_btn.custom_minimum_size = Vector2(216, 14)
		if not is_open(str(see)): see_btn.icon = sprites.frame("lock")
		var target: String = str(see)
		see_btn.pressed.connect(show_card.bind(target))
		detail_box.add_child(see_btn)
		link_buttons[target] = see_btn
	detail_scroll.scroll_vertical = 0

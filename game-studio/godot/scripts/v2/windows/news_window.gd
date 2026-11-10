extends "res://scripts/v2/windows/window_base.gd"
# Browser: the news feed. Cards show only public fields (headline, source, topic, verification).
const Claim = preload("res://scripts/v2/windows/claim.gd")
const AREA := Rect2(58, 30, 442, 290)
const CARD_WIDTH := 412
const CARD_HEIGHT := 72
const EXPANDED_EXTRA := 54
const TIER_COLORS := {"chinh_thuc":18, "bao_chi":5, "mang_xa_hoi":29, "noi_bo":27}
const TIER_ICONS := {"chinh_thuc":"crest_chinh_thuc", "bao_chi":"crest_bao_chi", "mang_xa_hoi":"crest_mang_xa_hoi", "noi_bo":"crest_noi_bo"}
const DIRECTION_ICONS := {"tang":"arrow_up", "giam":"arrow_down", "ngang":"arrow_flat"}
const DIRECTION_WORDS := {"tang":"up", "giam":"down", "ngang":"flat"}
var rows: Dictionary = {}
var thumbs: Dictionary = {}
var pin_buttons: Dictionary = {}
var more_buttons: Dictionary = {}
var tools_buttons: Dictionary = {}
var expanded: Dictionary = {}
var items: Array = []
var last_pins: Array = []
var scroll: ScrollContainer
var list: VBoxContainer
var selected := ""
var strings: Dictionary
signal selected_uid(uid: String)
signal pin_requested(uid: String)
signal tools_requested(uid: String)

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.news, AREA)
	scroll = ScrollContainer.new()
	scroll.size = content.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

func thumb_id(topic: String) -> String:
	return "topic_" + topic if sprites.definitions.has("topic_" + topic) else "thumb"

func display(entries: Array, pins: Array, uid: String) -> void:
	var old_scroll := scroll.scroll_vertical
	empty(list)
	rows.clear()
	thumbs.clear()
	pin_buttons.clear()
	more_buttons.clear()
	tools_buttons.clear()
	items = entries.duplicate(true)
	last_pins = pins.duplicate()
	selected = uid
	for item in items:
		_card(item, item.uid in pins)
	scroll.set_deferred("scroll_vertical", old_scroll)

func _card(item: Dictionary, is_pinned: bool) -> void:
	var open: bool = expanded.get(item.uid, false)
	var row := Panel.new()
	row.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT + (EXPANDED_EXTRA if open else 0))
	row.clip_contents = true
	row.focus_mode = Control.FOCUS_ALL
	row.add_theme_stylebox_override("panel", WindowTheme.box(3 if item.uid == selected else 2, 21 if is_pinned else 5))
	list.add_child(row)
	rows[item.uid] = row
	row.set_meta("verification", item.verification)
	row.set_meta("uid", item.uid)
	row.gui_input.connect(_row_input.bind(item.uid))
	# Pictogram thumbnail by topic (public field only).
	var frame := Panel.new()
	frame.position = Vector2(4, 4)
	frame.size = Vector2(36, 36)
	frame.add_theme_stylebox_override("panel", WindowTheme.box(17, 4))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	var picture := TextureRect.new()
	picture.texture = sprites.frame(thumb_id(item.topic))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.position = Vector2(2, 2)
	picture.size = Vector2(32, 32)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(picture)
	thumbs[item.uid] = picture
	# Source badge with a crest per tier.
	var tier: String = item.source_tier
	var chip := ColorRect.new()
	chip.color = Palette.color(TIER_COLORS.get(tier, 5))
	chip.position = Vector2(46, 3)
	chip.size = Vector2(84, 12)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(chip)
	icon(row, TIER_ICONS.get(tier, "crest_bao_chi"), Vector2(48, 5))
	var tier_label := label(row, strings.tiers[tier], Rect2(59, 2, 70, 14))
	tier_label.tooltip_text = strings.glossary.get("tier_" + tier, "")
	tier_label.mouse_filter = Control.MOUSE_FILTER_PASS
	var source := label(row, item.source_name, Rect2(134, 2, 116, 14), 7)
	source.tooltip_text = item.source_name
	source.mouse_filter = Control.MOUSE_FILTER_PASS
	# What the headline claims, not whether it is right.
	var claimed := Claim.direction(item.headline)
	var figure := Claim.figure(item.headline)
	if claimed != "":
		var arrow := icon(row, DIRECTION_ICONS[claimed], Vector2(254, 0))
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_SCALE
		arrow.size = Vector2(16, 16)
		arrow.tooltip_text = strings.news_ui["claim_" + DIRECTION_WORDS[claimed]]
		arrow.mouse_filter = Control.MOUSE_FILTER_PASS
	if figure != "":
		var badge := Panel.new()
		badge.position = Vector2(272, 1)
		badge.size = Vector2(58, 15)
		badge.add_theme_stylebox_override("panel", WindowTheme.box(3, 28))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(badge)
		var figure_label := label(badge, figure, Rect2(1, 1, 56, 13), 28)
		figure_label.add_theme_font_size_override("font_size", 12)
		figure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		figure_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var headline := label(row, item.headline, Rect2(46, 17, 286, 40))
	headline.add_theme_font_size_override("font_size", 12)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.max_lines_visible = 2
	headline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	headline.tooltip_text = item.headline
	headline.mouse_filter = Control.MOUSE_FILTER_PASS
	label(row, strings.ui.published % item.day + " · " + strings.topics[item.topic], Rect2(46, 58, 120, 12), 7)
	if item.verification != "chua_kiem_chung":
		var status: String = item.verification
		icon(row, {"xac_nhan":"check", "bac_bo":"cross", "chua_du_can_cu":"question", "cu":"arrow_flat"}[status], Vector2(170, 60))
		label(row, strings.verification[status], Rect2(182, 58, 150, 12), {"xac_nhan":24, "bac_bo":26, "chua_du_can_cu":28, "cu":6}[status])
	var pin := button(row, strings.news_ui.pinned if is_pinned else strings.news_ui.pin, Rect2(338, 4, 70, 20))
	pin.icon = sprites.frame("flag")
	pin.clip_text = true
	pin.toggle_mode = true
	pin.button_pressed = is_pinned
	pin.tooltip_text = strings.ui.unpin if is_pinned else strings.ui.pin
	pin.pressed.connect(func(): pin_requested.emit(item.uid))
	pin_buttons[item.uid] = pin
	var more := button(row, strings.news_ui.less if open else strings.news_ui.read_more, Rect2(338, 28, 70, 16))
	more.clip_text = true
	more.pressed.connect(toggle_expanded.bind(item.uid))
	more_buttons[item.uid] = more
	if open:
		var body := label(row, item.headline, Rect2(46, 72, 358, 34))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.max_lines_visible = 3
		label(row, strings.news_ui.source % item.source_name, Rect2(46, 108, 214, 12), 7)
		var tools := button(row, strings.news_ui.open_tools, Rect2(264, 106, 140, 16))
		tools.clip_text = true
		tools.pressed.connect(func(): tools_requested.emit(item.uid))
		tools_buttons[item.uid] = tools

func toggle_expanded(uid: String) -> void:
	expanded[uid] = not expanded.get(uid, false)
	display(items, last_pins, selected)

func _row_input(event: InputEvent, uid: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_uid.emit(uid)
	elif event is InputEventKey and event.pressed:
		var index := items.find_custom(func(item): return item.uid == uid)
		if event.keycode in [KEY_UP, KEY_DOWN]:
			index = clampi(index + (-1 if event.keycode == KEY_UP else 1), 0, items.size() - 1)
			selected_uid.emit(items[index].uid)
			accept_event()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			selected_uid.emit(uid)
			accept_event()

func focus_selected() -> void:
	if rows.has(selected):
		rows[selected].grab_focus()
		scroll.ensure_control_visible(rows[selected])

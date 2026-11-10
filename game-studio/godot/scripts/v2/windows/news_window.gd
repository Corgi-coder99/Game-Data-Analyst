extends "res://scripts/v2/windows/window_base.gd"
var rows: Dictionary = {}
var items: Array = []
var scroll: ScrollContainer
var list: VBoxContainer
var selected := ""
var strings: Dictionary
signal selected_uid(uid: String)
signal pin_requested(uid: String)

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.news, Rect2(4, 20, 388, 320))
	scroll = ScrollContainer.new()
	scroll.size = content.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

func display(entries: Array, pins: Array, uid: String) -> void:
	var old_scroll := scroll.scroll_vertical
	empty(list)
	rows.clear()
	items = entries.duplicate(true)
	selected = uid
	for item in items:
		var row := Panel.new()
		row.custom_minimum_size = Vector2(360, 82)
		row.clip_contents = true
		row.focus_mode = Control.FOCUS_ALL
		row.add_theme_stylebox_override("panel", WindowTheme.box(3 if item.uid == selected else 2, 21 if item.uid in pins else 5))
		list.add_child(row)
		rows[item.uid] = row
		row.set_meta("verification", item.verification)
		row.set_meta("uid", item.uid)
		row.gui_input.connect(_row_input.bind(item.uid))
		var tier: String = item.source_tier
		var color_index: int = {"chinh_thuc":18,"bao_chi":5,"mang_xa_hoi":29,"noi_bo":27}.get(tier, 5)
		var chip := ColorRect.new()
		chip.color = Palette.color(color_index)
		chip.position = Vector2(3, 3)
		chip.size = Vector2(90, 12)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(chip)
		icon(row, {"chinh_thuc":"shield","bao_chi":"newspaper","mang_xa_hoi":"bubble","noi_bo":"lock"}.get(tier, "newspaper"), Vector2(5, 5))
		label(row, strings.tiers[tier], Rect2(16, 2, 76, 14))
		var source := label(row, item.source_name, Rect2(98, 2, 222, 14))
		source.tooltip_text = item.source_name
		source.mouse_filter = Control.MOUSE_FILTER_PASS
		var headline := label(row, item.headline, Rect2(5, 18, 314, 40))
		headline.add_theme_font_size_override("font_size", 12)
		headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		headline.max_lines_visible = 2
		headline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		headline.tooltip_text = item.headline
		headline.mouse_filter = Control.MOUSE_FILTER_PASS
		label(row, strings.ui.published % item.day + " · " + strings.topics[item.topic], Rect2(5, 61, 158, 16), 7)
		if item.verification != "chua_kiem_chung":
			var status: String = item.verification
			icon(row, {"xac_nhan":"check","bac_bo":"cross","chua_du_can_cu":"question","cu":"arrow_flat"}[status], Vector2(170, 65))
			label(row, strings.verification[status], Rect2(182, 61, 150, 16), {"xac_nhan":24,"bac_bo":26,"chua_du_can_cu":28,"cu":6}[status])
		var pin := button(row, "", Rect2(334, 24, 20, 20))
		pin.icon = sprites.frame("flag")
		pin.toggle_mode = true
		pin.button_pressed = item.uid in pins
		pin.tooltip_text = strings.ui.unpin if pin.button_pressed else strings.ui.pin
		pin.pressed.connect(func(): pin_requested.emit(item.uid))
	scroll.set_deferred("scroll_vertical", old_scroll)

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

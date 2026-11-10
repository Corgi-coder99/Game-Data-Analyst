extends Control
const TooltipLabel = preload("res://scripts/v2/windows/tooltip_label.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const NewsWindow = preload("res://scripts/v2/windows/news_window.gd")
const CompanyWindow = preload("res://scripts/v2/windows/company_window.gd")
const ToolsWindow = preload("res://scripts/v2/windows/tools_window.gd")
const PUBLIC_FIELDS := ["uid", "day", "source_id", "source_tier", "source_name", "headline", "topic", "verification", "verified_by"]
var game: RefCounted
var strings: Dictionary
var news_window: Control
var company_window: Control
var tools_window: Control
var windows: Dictionary = {}
var task_buttons: Dictionary = {}
var question_scroll: ScrollContainer
var question_offset := -36.0
var question: Label
var clock: Label
var entries: Array = []
var pinned: Array = []
var selected := ""
var message := ""
var built := false
signal evidence_changed(uids: Array)
signal tool_used(uid: String, tool_id: String, result: Dictionary)
signal window_toggled(window_id: String, visible: bool)

func _ready() -> void:
	_build()
	if game != null: refresh()

func _build() -> void:
	if built: return
	built = true
	size = Vector2(640, 360)
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = WindowTheme.create()
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	var background := ColorRect.new()
	background.color = Palette.color(17)
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	question_scroll = ScrollContainer.new()
	question_scroll.position = Vector2(4, 2)
	question_scroll.size = Vector2(632, 14)
	question_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	question_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(question_scroll)
	question = TooltipLabel.new()
	question.mouse_filter = Control.MOUSE_FILTER_PASS
	question_scroll.add_child(question)
	news_window = NewsWindow.new()
	company_window = CompanyWindow.new()
	tools_window = ToolsWindow.new()
	for pair in [["news", news_window], ["company", company_window], ["tools", tools_window]]:
		add_child(pair[1])
		pair[1].initialize(strings)
		windows[pair[0]] = pair[1]
		pair[1].minimize_requested.connect(toggle_window.bind(pair[0]))
	news_window.selected_uid.connect(_select_and_focus)
	news_window.pin_requested.connect(toggle_pin)
	tools_window.requested.connect(use_tool)
	var taskbar := ColorRect.new()
	taskbar.color = Palette.color(2)
	taskbar.position = Vector2(0, 344)
	taskbar.size = Vector2(640, 16)
	taskbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(taskbar)
	var i := 0
	for id in windows:
		var task := Button.new()
		task.add_theme_font_size_override("font_size", 8)
		task.text = strings.windows[id]
		task.position = Vector2(4 + i * 112, 345)
		task.size = Vector2(108, 14)
		task.toggle_mode = true
		task.button_pressed = true
		task.pressed.connect(toggle_window.bind(id))
		add_child(task)
		task.size = Vector2(108, 14)
		task_buttons[id] = task
		i += 1
	clock = TooltipLabel.new()
	clock.add_theme_font_size_override("font_size", 8)
	clock.position = Vector2(348, 344)
	clock.size = Vector2(288, 16)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.tooltip_text = strings.ui.disclaimer
	add_child(clock)
	clock.size = Vector2(288, 16)

func setup(value: RefCounted) -> void:
	_build()
	game = value
	company_window.reset_history()
	selected = ""
	clear_pins()
	message = strings.ui.select
	refresh()

func refresh() -> void:
	if game == null: return
	_build()
	entries.clear()
	for item in game.news_today():
		var entry := {}
		for field in PUBLIC_FIELDS:
			entry[field] = item[field].duplicate(true) if item[field] is Array else item[field]
		entries.append(entry)
	entries.sort_custom(func(a, b): return int(a.day) > int(b.day))
	var valid: Array = entries.map(func(item): return item.uid)
	var retained := pinned.filter(func(uid): return uid in valid)
	if retained != pinned:
		pinned = retained
		evidence_changed.emit(get_pinned())
	if selected not in valid: selected = ""
	var state: Dictionary = game.status()
	var question_text: String = strings.ui.question + str(game.question_today().get("text", ""))
	if question.text != question_text:
		question_offset = -36.0
	question.text = question_text
	question.tooltip_text = question.text
	clock.text = strings.ui.day % [state.day, state.horizon] + "  " + ToolsWindow.dots(state)
	news_window.display(entries, pinned, selected)
	company_window.display(game.report_snapshot(), state)
	tools_window.display(game.tools(), state, _selected_entry(), message)

func _selected_entry() -> Dictionary:
	for item in entries:
		if item.uid == selected: return item
	return {}

func get_pinned() -> Array:
	return pinned.duplicate()

func clear_pins() -> void:
	if pinned.is_empty(): return
	pinned.clear()
	evidence_changed.emit(get_pinned())
	if game != null: refresh()

func toggle_pin(uid: String) -> bool:
	if not entries.any(func(item): return item.uid == uid): return false
	if uid in pinned: pinned.erase(uid)
	elif pinned.size() < 3: pinned.append(uid)
	else:
		message = strings.ui.pin_limit
		refresh()
		return false
	evidence_changed.emit(get_pinned())
	refresh()
	return true

func select_news(uid: String) -> bool:
	if not entries.any(func(item): return item.uid == uid): return false
	selected = uid
	refresh()
	return true

func _select_and_focus(uid: String) -> void:
	if select_news(uid): news_window.focus_selected()

func use_tool(tool_id: String) -> Dictionary:
	var result: Dictionary = {"ok":false,"error":"day_closed"} if game == null else game.verify(selected, tool_id)
	if result.ok: message = strings.verification[result.result]
	else: message = strings.errors.get(result.error, strings.ui.unknown)
	refresh()
	tool_used.emit(selected, tool_id, result.duplicate(true))
	return result

func toggle_window(id: String) -> void:
	if not windows.has(id): return
	windows[id].visible = not windows[id].visible
	task_buttons[id].button_pressed = windows[id].visible
	window_toggled.emit(id, windows[id].visible)

func _process(delta: float) -> void:
	if question == null: return
	var overflow := maxf(0, question.size.x - question_scroll.size.x)
	if overflow <= 0: return
	question_offset += delta * 18.0
	if question_offset > overflow + 54: question_offset = -36.0
	question_scroll.scroll_horizontal = int(clampf(question_offset, 0, overflow))
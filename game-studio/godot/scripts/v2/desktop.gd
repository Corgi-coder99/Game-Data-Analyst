extends Control
const TooltipLabel = preload("res://scripts/v2/windows/tooltip_label.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const NewsWindow = preload("res://scripts/v2/windows/news_window.gd")
const CompanyWindow = preload("res://scripts/v2/windows/company_window.gd")
const ToolsWindow = preload("res://scripts/v2/windows/tools_window.gd")
const ReportWindow = preload("res://scripts/v2/windows/report_window.gd")
const START_MINUTES := 8 * 60 + 30
const TOOL_MINUTES := 30
const PUBLIC_FIELDS := ["uid", "day", "source_id", "source_tier", "source_name", "headline", "topic", "verification", "verified_by"]
var game: RefCounted
var strings: Dictionary
var news_window: Control
var company_window: Control
var tools_window: Control
var report_window: Control
var clock_minutes := START_MINUTES
var restore_visibility := {}
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
signal report_submitted(input: Dictionary)
signal time_changed(minutes: int)

func _ready() -> void:
	_build()
	if game != null: setup(game)

func _build() -> void:
	if built or not is_inside_tree(): return
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
	# The report shares the right column with Company and Tools; it is a tab toggled from the taskbar.
	report_window = ReportWindow.new()
	add_child(report_window)
	report_window.initialize(strings)
	report_window.hide()
	report_window.minimize_requested.connect(show_report.bind(false))
	report_window.unpin_requested.connect(toggle_pin)
	report_window.submit_requested.connect(func(input): report_submitted.emit(input))
	var taskbar := ColorRect.new()
	taskbar.color = Palette.color(2)
	taskbar.position = Vector2(0, 344)
	taskbar.size = Vector2(640, 16)
	taskbar.clip_contents = true
	taskbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(taskbar)
	var i := 0
	var task_ids: Array = windows.keys()
	task_ids.append("report")
	for id in task_ids:
		var task := Button.new()
		task.theme = theme
		task.custom_minimum_size = Vector2(108, 14)
		task.clip_contents = true
		task.add_theme_font_size_override("font_size", 8)
		task.text = strings.windows[id]
		task.position = Vector2(4 + i * 112, 1)
		task.size = Vector2(108, 14)
		task.toggle_mode = true
		task.button_pressed = id != "report"
		task.pressed.connect(toggle_window.bind(id))
		taskbar.add_child(task)
		task.size = Vector2(108, 14)
		task_buttons[id] = task
		i += 1
	clock = TooltipLabel.new()
	clock.add_theme_font_size_override("font_size", 8)
	clock.position = Vector2(452, 0)
	clock.size = Vector2(184, 16)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.tooltip_text = strings.ui.disclaimer
	taskbar.add_child(clock)
	clock.size = Vector2(184, 16)

func setup(value: RefCounted) -> void:
	game = value
	# Theme minimums are valid only inside the scene tree; _ready completes early setup.
	if not is_inside_tree(): return
	_build()
	company_window.reset_history()
	clock_minutes = START_MINUTES
	report_window.reset()
	selected = ""
	clear_pins()
	message = strings.ui.select
	refresh()

func refresh() -> void:
	if game == null or not is_inside_tree(): return
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
	clock.text = strings.ui.clock % [clock_minutes / 60, clock_minutes % 60] + "  " + strings.ui.day % [state.day, state.horizon] + "  " + ToolsWindow.dots(state)
	news_window.display(entries, pinned, selected)
	company_window.display(game.report_snapshot(), state)
	tools_window.display(game.tools(), state, _selected_entry(), message)
	# Test doubles without a hand keep the three original windows working.
	if game.has_method("hand"):
		var pinned_entries: Array = []
		for uid in pinned:
			for item in entries:
				if item.uid == uid: pinned_entries.append({"uid":item.uid, "headline":item.headline, "verification":item.verification})
		report_window.display(str(game.question_today().get("id", "")), game.hand(), pinned_entries, int(state.get("max_actions", 1)))

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
	var energy_before := 0 if game == null else int(game.status().get("energy", 0))
	var result: Dictionary = {"ok":false,"error":"day_closed"} if game == null else game.verify(selected, tool_id)
	if result.ok: message = strings.verification[result.result]
	else: message = strings.errors.get(result.error, strings.ui.unknown)
	# Each paid verification takes half an hour; repeated (cached) lookups are free.
	if result.ok and int(game.status().get("energy", 0)) < energy_before:
		clock_minutes += TOOL_MINUTES
		time_changed.emit(clock_minutes)
	refresh()
	tool_used.emit(selected, tool_id, result.duplicate(true))
	return result

func set_time(minutes: int) -> void:
	clock_minutes = minutes
	refresh()

# A new working day: the persistent desktop keeps its history for the Company arrows.
func start_day() -> void:
	clock_minutes = START_MINUTES
	selected = ""
	message = strings.ui.select if strings != null and not strings.is_empty() else ""
	if report_window != null: report_window.reset()
	show_report(false)
	clear_pins()
	refresh()

func show_report(value: bool) -> void:
	if report_window == null or report_window.visible == value: return
	report_window.visible = value
	if value:
		restore_visibility = {"company":company_window.visible, "tools":tools_window.visible}
		company_window.hide()
		tools_window.hide()
	else:
		company_window.visible = bool(restore_visibility.get("company", true))
		tools_window.visible = bool(restore_visibility.get("tools", true))
	for id in windows: task_buttons[id].button_pressed = windows[id].visible
	task_buttons["report"].button_pressed = value
	window_toggled.emit("report", value)

func toggle_window(id: String) -> void:
	if id == "report":
		show_report(not report_window.visible)
		return
	# Company and Tools share the column with the report: choosing them brings them back.
	if report_window != null and report_window.visible and id in ["company", "tools"]:
		show_report(false)
		return
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
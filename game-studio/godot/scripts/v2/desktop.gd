extends Control
# The player's desktop: app icons on the left, one app window at a time in the work area,
# a goal/tutorial strip on the right, the evidence tray and the taskbar at the bottom.
const TooltipLabel = preload("res://scripts/v2/windows/tooltip_label.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const Sprites = preload("res://scripts/v2/sprite_lib.gd")
const NewsWindow = preload("res://scripts/v2/windows/news_window.gd")
const CompanyWindow = preload("res://scripts/v2/windows/company_window.gd")
const ToolsWindow = preload("res://scripts/v2/windows/tools_window.gd")
const ReportWindow = preload("res://scripts/v2/windows/report_window.gd")
const DataWindow = preload("res://scripts/v2/windows/data_window.gd")
const DataSession = preload("res://scripts/data/session.gd")
const TutorialPanel = preload("res://scripts/v2/tutorial_panel.gd")
const CityArt = preload("res://scripts/v2/city_art.gd")
const START_MINUTES := 8 * 60 + 30
const TOOL_MINUTES := 30
const PUBLIC_FIELDS := ["uid", "day", "source_id", "source_tier", "source_name", "headline", "topic", "verification", "verified_by"]
const WORK_AREA := Rect2(58, 30, 442, 290)
# Icon order on the desktop: window id, sprite. "help" opens the tutorial instead of a window.
const ICONS := [["news", "app_news"], ["files", "app_files"], ["sheet", "app_sheet"], ["charts", "app_charts"], ["report", "app_mail"], ["company", "app_bi"], ["tools", "app_code"], ["help", "app_help"]]
# T-034: these icons open the Data window on a tab.
const DATA_TABS := ["files", "sheet", "charts"]
var game: RefCounted
var strings: Dictionary
var news_window: Control
var company_window: Control
var tools_window: Control
var report_window: Control
var data_window: Control
# T-034: the run's data session (files, sheets, pins). Created for a real world only; data_seed is set by the flow.
var data_session: RefCounted
var data_seed := 0
var coach: Control
var home: Panel
var home_question: Label
var home_heading: Label
var home_hint: Label
var clock_minutes := START_MINUTES
var windows: Dictionary = {}
var task_buttons: Dictionary = {}
var icon_buttons: Dictionary = {}
var tray_slots: Array = []
var open_ids: Array = []
var front := ""
var sprites := Sprites.new()
var question_scroll: ScrollContainer
var ticker_scroll: ScrollContainer
var ticker: Label
var question_offset := -36.0
var ticker_offset := -36.0
var question: Label
var clock: Label
var clock_bar: Control
var clock_band := "on_time"
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
	var background := TextureRect.new()
	background.name = "Wallpaper"
	background.set_meta("overlay", true)
	background.texture = CityArt.backdrop("wallpaper")
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var dock := ColorRect.new()
	dock.color = Color(Palette.color(83), 0.8)
	dock.position = Vector2(0, 28)
	dock.size = Vector2(56, 292)
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock)
	question_scroll = _strip(Rect2(4, 2, 632, 14))
	question = TooltipLabel.new()
	question.mouse_filter = Control.MOUSE_FILTER_PASS
	question_scroll.add_child(question)
	ticker_scroll = _strip(Rect2(4, 16, 632, 12))
	ticker = TooltipLabel.new()
	ticker.add_theme_color_override("font_color", Palette.color(21))
	ticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticker_scroll.add_child(ticker)
	_build_home()
	news_window = NewsWindow.new()
	company_window = CompanyWindow.new()
	tools_window = ToolsWindow.new()
	report_window = ReportWindow.new()
	data_window = DataWindow.new()
	for pair in [["news", news_window], ["company", company_window], ["tools", tools_window], ["report", report_window], ["data", data_window]]:
		add_child(pair[1])
		pair[1].initialize(strings)
		pair[1].hide()
		windows[pair[0]] = pair[1]
		pair[1].minimize_requested.connect(minimize_window.bind(pair[0]))
		pair[1].close_requested.connect(close_window.bind(pair[0]))
	news_window.selected_uid.connect(_select_and_focus)
	news_window.pin_requested.connect(toggle_pin)
	news_window.tools_requested.connect(_verify_from_browser)
	tools_window.requested.connect(use_tool)
	report_window.unpin_requested.connect(toggle_pin)
	report_window.clear_requested.connect(clear_pins)
	report_window.open_browser_requested.connect(open_window.bind("news"))
	report_window.draft_changed.connect(_on_draft_changed)
	report_window.locked_changed.connect(_on_report_locked)
	report_window.wait_requested.connect(wait_for_data)
	report_window.submit_requested.connect(func(input): report_submitted.emit(input))
	_build_icons()
	coach = TutorialPanel.new()
	add_child(coach)
	coach.build(strings)
	_build_tray()
	_build_taskbar()
	add_child(coach.overlay)

func _strip(area: Rect2) -> ScrollContainer:
	var node := ScrollContainer.new()
	node.position = area.position
	node.size = area.size
	node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	node.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(node)
	return node

func _plain_label(parent: Node, area: Rect2, font_size: int, color_index: int) -> Label:
	var node := TooltipLabel.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Palette.color(color_index))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.position = area.position
	node.size = area.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = area.size
	return node

func _build_home() -> void:
	home = Panel.new()
	home.position = WORK_AREA.position
	home.size = WORK_AREA.size
	var home_style := WindowTheme.box(83, 91)
	home_style.bg_color = Color(Palette.color(83), 0.82)
	home.add_theme_stylebox_override("panel", home_style)
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(home)
	var title := _plain_label(home, Rect2(12, 12, 418, 18), 12, 21)
	title.text = "Data Corp"
	home_heading = _plain_label(home, Rect2(12, 40, 418, 12), 8, 20)
	home_question = _plain_label(home, Rect2(12, 56, 418, 48), 12, 22)
	home_hint = _plain_label(home, Rect2(12, 116, 418, 36), 8, 21)

func _build_icons() -> void:
	for i in ICONS.size():
		var id: String = ICONS[i][0]
		var tile := Button.new()
		tile.name = "Icon_" + id
		tile.position = Vector2(2, 32 + i * 36)
		tile.size = Vector2(52, 34)
		tile.clip_contents = true
		tile.tooltip_text = strings.windows[id]
		for state in ["normal", "pressed", "disabled", "focus"]:
			tile.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		tile.add_theme_stylebox_override("hover", WindowTheme.box(80, 81))
		tile.pressed.connect(_on_icon.bind(id))
		add_child(tile)
		var picture := TextureRect.new()
		picture.texture = sprites.frame(ICONS[i][1])
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.position = Vector2(18, 1)
		picture.size = Vector2(16, 16)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(picture)
		var caption := Label.new()
		caption.text = strings.windows[id]
		caption.add_theme_font_size_override("font_size", 8)
		caption.add_theme_color_override("font_color", Palette.color(22))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.position = Vector2(0, 18)
		caption.size = Vector2(52, 14)
		caption.clip_text = true
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(caption)
		caption.size = Vector2(52, 14)
		tile.size = Vector2(52, 34)
		icon_buttons[id] = tile

func _build_tray() -> void:
	var tray := Panel.new()
	tray.name = "EvidenceTray"
	tray.position = Vector2(0, 320)
	tray.size = Vector2(640, 24)
	tray.add_theme_stylebox_override("panel", WindowTheme.box(83, 80))
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tray)
	var title := Label.new()
	title.text = strings.tray.title
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Palette.color(28))
	title.position = Vector2(6, 5)
	title.size = Vector2(50, 14)
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(title)
	title.size = Vector2(50, 14)
	for i in 3:
		var x := 60 + i * 190
		var jump := Button.new()
		jump.position = Vector2(x, 2)
		jump.size = Vector2(166, 20)
		jump.clip_contents = true
		tray.add_child(jump)
		var picture := TextureRect.new()
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.position = Vector2(2, 2)
		picture.size = Vector2(16, 16)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		jump.add_child(picture)
		var caption := Label.new()
		caption.add_theme_font_size_override("font_size", 8)
		caption.add_theme_color_override("font_color", Palette.color(22))
		caption.position = Vector2(21, 3)
		caption.size = Vector2(142, 14)
		caption.clip_text = true
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		jump.add_child(caption)
		caption.size = Vector2(142, 14)
		jump.size = Vector2(166, 20)
		var drop := Button.new()
		drop.text = "x"
		drop.position = Vector2(x + 168, 2)
		drop.size = Vector2(18, 20)
		drop.tooltip_text = strings.tray.drop
		tray.add_child(drop)
		drop.size = Vector2(18, 20)
		tray_slots.append({"jump":jump, "drop":drop, "icon":picture, "label":caption, "uid":""})
		jump.pressed.connect(func(): if tray_slots[i].uid != "": jump_to(tray_slots[i].uid))
		drop.pressed.connect(func(): if tray_slots[i].uid != "": toggle_pin(tray_slots[i].uid))

func _build_taskbar() -> void:
	var taskbar := ColorRect.new()
	taskbar.color = Palette.color(111)
	taskbar.position = Vector2(0, 344)
	taskbar.size = Vector2(640, 16)
	taskbar.clip_contents = true
	taskbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(taskbar)
	var i := 0
	for id in windows:
		var task := Button.new()
		task.theme = theme
		task.custom_minimum_size = Vector2(108, 14)
		task.clip_contents = true
		task.add_theme_font_size_override("font_size", 8)
		task.text = strings.windows[id]
		task.position = Vector2(4 + i * 112, 1)
		task.size = Vector2(108, 14)
		task.toggle_mode = true
		task.button_pressed = false
		task.visible = false
		task.pressed.connect(toggle_window.bind(id))
		taskbar.add_child(task)
		task.size = Vector2(108, 14)
		task_buttons[id] = task
		i += 1
	clock = TooltipLabel.new()
	clock.add_theme_font_size_override("font_size", 8)
	clock.position = Vector2(452, 0)
	clock.size = Vector2(184, 12)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.tooltip_text = strings.ui.disclaimer
	taskbar.add_child(clock)
	clock.size = Vector2(184, 12)

# Thin deadline bar under the taskbar clock: green until 15:00, yellow until 17:00, red after.
func _refresh_clock_bar(state: Dictionary) -> void:
	if clock_bar != null and is_instance_valid(clock_bar):
		clock_bar.get_parent().remove_child(clock_bar)
		clock_bar.queue_free()
		clock_bar = null
	if not state.has("band"): return
	clock_band = str(state.band)
	var info := {"minutes":clock_minutes, "band":clock_band, "deadline_on_time":state.deadline_on_time, "deadline_late":state.deadline_late}
	clock_bar = ReportWindow.deadline_bar(clock.get_parent(), Rect2(452, 12, 184, 3), info)
	clock.add_theme_color_override("font_color", Palette.color(ReportWindow.CLOCK_COLORS[clock_band]))

func setup(value: RefCounted) -> void:
	game = value
	# Theme minimums are valid only inside the scene tree; _ready completes early setup.
	if not is_inside_tree(): return
	_build()
	company_window.reset_history()
	clock_minutes = START_MINUTES
	report_window.reset()
	selected = ""
	message = ""
	clear_pins()
	open_ids.clear()
	front = ""
	coach.reset_goals()
	coach.skipped = false
	coach.finished = false
	coach.active = false
	var day := int(game.status().day)
	coach.set_day(day)
	if day == 1: coach.start()
	_make_data_session()
	_apply_windows()
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
	# The 15:00 market update (public uid suffix) sorts first within its day.
	entries.sort_custom(func(a, b): return int(a.day) * 2 + int(str(a.uid).ends_with("-late")) > int(b.day) * 2 + int(str(b.uid).ends_with("-late")))
	var valid: Array = entries.map(func(item): return item.uid)
	var retained := pinned.filter(func(uid): return uid in valid)
	if retained != pinned:
		pinned = retained
		evidence_changed.emit(get_pinned())
	if selected not in valid: selected = ""
	var state: Dictionary = game.status()
	var question_body: String = str(game.question_today().get("text", ""))
	var question_text: String = strings.ui.question + question_body
	if question.text != question_text:
		question_offset = -36.0
	question.text = question_text
	question.tooltip_text = question.text
	home_question.text = question_body
	home_heading.text = strings.home.question
	home_hint.text = strings.home.hint
	var ticker_text := "   ·   ".join(entries.map(func(item): return item.headline))
	if ticker.text != ticker_text: ticker_offset = -36.0
	ticker.text = ticker_text
	if state.has("minutes"): clock_minutes = int(state.minutes)
	clock.text = strings.ui.clock % [clock_minutes / 60, clock_minutes % 60] + "  " + strings.ui.day % [state.day, state.horizon] + "  " + ToolsWindow.dots(state)
	_refresh_clock_bar(state)
	news_window.display(entries, pinned, selected)
	company_window.display(game.report_snapshot(), state)
	tools_window.display(game.tools(), state, _selected_entry(), message)
	# Test doubles without a hand keep the three original windows working.
	if game.has_method("hand"):
		var pinned_entries: Array = []
		for uid in pinned:
			for item in entries:
				if item.uid == uid: pinned_entries.append({"uid":item.uid, "headline":item.headline, "verification":item.verification})
		report_window.display(str(game.question_today().get("id", "")), game.hand(), pinned_entries, int(state.get("max_actions", 1)), question_body, _clock_info(state))
	_refresh_tray()

func _clock_info(state: Dictionary) -> Dictionary:
	if not state.has("band"): return {}
	return {"minutes":clock_minutes, "band":state.band, "deadline_on_time":state.deadline_on_time, "deadline_late":state.deadline_late}

func _refresh_tray() -> void:
	for i in tray_slots.size():
		var slot: Dictionary = tray_slots[i]
		var entry := {}
		if i < pinned.size():
			for item in entries:
				if item.uid == pinned[i]: entry = item
		var has_entry := not entry.is_empty()
		slot.uid = entry.uid if has_entry else ""
		slot.jump.disabled = not has_entry
		slot.drop.disabled = not has_entry
		slot.label.text = entry.headline if has_entry else strings.tray.empty
		slot.label.add_theme_color_override("font_color", Palette.color(22 if has_entry else 6))
		slot.jump.tooltip_text = entry.headline if has_entry else ""
		slot.icon.texture = sprites.frame(news_window.thumb_id(entry.topic) if has_entry else "dash")
		slot.icon.visible = has_entry

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
	elif pinned.size() < 3:
		pinned.append(uid)
		_note("pinned")
		coach.set_goal("pin")
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
	_note("selected")
	coach.set_goal("read")
	refresh()
	return true

func _select_and_focus(uid: String) -> void:
	if select_news(uid): news_window.focus_selected()

# Tray slot: show the article in the Browser.
func jump_to(uid: String) -> void:
	open_window("news")
	if select_news(uid): news_window.focus_selected()

func _verify_from_browser(uid: String) -> void:
	if select_news(uid): open_window("tools")

func use_tool(tool_id: String) -> Dictionary:
	var energy_before := 0 if game == null else int(game.status().get("energy", 0))
	var result: Dictionary = {"ok":false,"error":"day_closed"} if game == null else game.verify(selected, tool_id)
	if result.ok:
		message = strings.verification[result.result]
		_note("checked")
		coach.set_goal("verify")
	else: message = strings.errors.get(result.error, strings.ui.unknown)
	# Each paid verification takes time (per tool, from world.json); repeated (cached) lookups are free.
	if result.ok and int(game.status().get("energy", 0)) < energy_before:
		var after: Dictionary = game.status()
		clock_minutes = int(after.minutes) if after.has("minutes") else clock_minutes + TOOL_MINUTES
		time_changed.emit(clock_minutes)
	refresh()
	tool_used.emit(selected, tool_id, result.duplicate(true))
	return result

# Mail's "Wait" button: only time passes; the 15:00 update may appear.
func wait_for_data() -> Dictionary:
	if game == null or not game.has_method("wait_for_data"): return {"ok":false, "error":"day_closed"}
	var result: Dictionary = game.wait_for_data()
	if result.ok:
		clock_minutes = int(result.minutes)
		time_changed.emit(clock_minutes)
		message = ""
	else: message = strings.errors.get(result.error, strings.ui.unknown)
	refresh()
	return result

func set_time(minutes: int) -> void:
	clock_minutes = minutes
	refresh()

# A new working day: the persistent desktop keeps its history for the Company arrows.
func start_day() -> void:
	clock_minutes = START_MINUTES
	selected = ""
	message = ""
	report_window.reset()
	clear_pins()
	coach.reset_goals()
	var day := 1 if game == null else int(game.status().day)
	coach.set_day(day)
	if day > 1 and coach.active:
		coach.active = false
		coach.layout()
	# Day 2 introduces the deadline once, unless the player skipped the coach.
	if day == 2 and not coach.skipped: coach.start_deadline()
	open_ids.clear()
	front = ""
	if day > 1:
		open_ids.append("news")
		front = "news"
	_start_data_day()
	_apply_windows()
	refresh()

# ---- windows -------------------------------------------------------------------------

func _apply_windows() -> void:
	var slot := 0
	# Up to four entries keep the classic 108 px width; more entries share the 448 px left of the clock.
	var pitch := mini(112, 448 / maxi(1, open_ids.size()))
	for id in windows:
		var shown: bool = id == front
		var was: bool = windows[id].visible
		windows[id].visible = shown
		var task: Button = task_buttons[id]
		task.visible = id in open_ids
		task.button_pressed = shown
		if task.visible:
			task.custom_minimum_size = Vector2(pitch - 4, 14)
			task.size = Vector2(pitch - 4, 14)
			task.position = Vector2(4 + slot * pitch, 1)
			slot += 1
		if was != shown: window_toggled.emit(id, shown)
	home.visible = front == ""

func open_window(id: String) -> void:
	if not windows.has(id): return
	if id not in open_ids: open_ids.append(id)
	front = id
	_apply_windows()
	match id:
		"news":
			_note("opened_browser")
			coach.set_goal("read")
		"tools": _note("opened_tools")
		"report": _note("opened_mail")

func minimize_window(id: String) -> void:
	if front != id: return
	front = ""
	_apply_windows()

func close_window(id: String) -> void:
	open_ids.erase(id)
	if front == id: front = ""
	_apply_windows()

# Taskbar behaviour: the front window is minimised, any other open window is brought forward.
func toggle_window(id: String) -> void:
	if not windows.has(id): return
	if front == id: minimize_window(id)
	else: open_window(id)

func show_report(value: bool) -> void:
	if value: open_window("report")
	else: minimize_window("report")

func _on_icon(id: String) -> void:
	if id == "help": open_tutorial()
	elif id in DATA_TABS: open_data(id)
	else: open_window(id)

# T-034: Files, Sheet and Charts are tabs of one Data window.
func open_data(tab: String) -> void:
	open_window("data")
	if data_session != null: data_window.show_tab(tab)
	match tab:
		"files": _note("opened_files")
		"sheet": _note("opened_sheet")
		"charts": _note("opened_charts")

# Opening files and pinning cost clock minutes in the world; the desktop clock follows.
func _sync_data() -> void:
	if game == null or not game.has_method("status"): return
	var minutes := int(game.status().get("minutes", clock_minutes))
	if data_session != null and not data_session.pins.is_empty(): _note("charted")
	if minutes != clock_minutes:
		clock_minutes = minutes
		time_changed.emit(clock_minutes)
		refresh()

func _make_data_session() -> void:
	if game == null or not game.has_method("spend_minutes"): return
	if data_session == null:
		data_session = DataSession.new(game, data_seed)
		data_window.attach_session(data_session)
		company_window.attach_session(data_session)
		report_window.attach_session(data_session)
		data_session.changed.connect(_sync_data)
		data_window.data_changed.connect(_sync_data)
	_start_data_day()

func _start_data_day() -> void:
	if data_session == null: return
	data_session.begin_day(int(game.status().day))
	data_window.reset_day()

func open_tutorial() -> void:
	coach.collapsed = false
	coach.start()

# ---- tutorial ------------------------------------------------------------------------

func _note(flag: String) -> void:
	if coach != null: coach.note(flag)

func _on_draft_changed() -> void:
	var ready: bool = report_window.forecast != "" and report_window.confidence != ""
	coach.set_goal("write", ready)
	if ready: _note("composed")

func _on_report_locked(value: bool) -> void:
	if not value: return
	coach.set_goal("send")
	_note("sent")

# Where the coach-mark highlight points, in desktop coordinates.
func coach_rect() -> Rect2:
	if coach == null or not coach.active: return Rect2()
	match coach.current_id():
		"question": return question_scroll.get_global_rect()
		"deadline": return clock.get_global_rect()
		"browser": return icon_buttons.news.get_global_rect()
		"select":
			if front == "news" and not news_window.rows.is_empty():
				return news_window.rows.values()[0].get_global_rect().intersection(news_window.scroll.get_global_rect())
			return icon_buttons.news.get_global_rect()
		"codepad": return icon_buttons.tools.get_global_rect()
		"check":
			if front == "tools" and not tools_window.buttons.is_empty(): return tools_window.buttons.values()[0].get_global_rect()
			return icon_buttons.tools.get_global_rect()
		"pin":
			if front == "news" and not news_window.pin_buttons.is_empty():
				var key: String = selected if news_window.pin_buttons.has(selected) else news_window.pin_buttons.keys()[0]
				return news_window.pin_buttons[key].get_global_rect().intersection(news_window.scroll.get_global_rect())
			return icon_buttons.news.get_global_rect()
		"files": return icon_buttons.files.get_global_rect()
		"sheet": return icon_buttons.sheet.get_global_rect()
		"chart": return icon_buttons.charts.get_global_rect()
		"mail": return icon_buttons.report.get_global_rect()
		"forecast":
			if front == "report" and not report_window.forecast_buttons.is_empty():
				var first: Rect2 = report_window.forecast_buttons.values()[0].get_global_rect()
				var last: Rect2 = report_window.confidence_buttons.values()[-1].get_global_rect()
				return first.merge(last)
			return icon_buttons.report.get_global_rect()
		"send":
			if front == "report" and report_window.submit_button != null: return report_window.submit_button.get_global_rect()
			return icon_buttons.report.get_global_rect()
	return Rect2()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo: return
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER] and coach != null and coach.active:
		coach.advance()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and front != "":
		minimize_window(front)
		get_viewport().set_input_as_handled()

func _scroll_strip(scroll: ScrollContainer, text_label: Label, offset: float, delta: float, speed: float) -> float:
	var overflow := maxf(0, text_label.size.x - scroll.size.x)
	if overflow <= 0: return offset
	offset += delta * speed
	if offset > overflow + 54: offset = -36.0
	scroll.scroll_horizontal = int(clampf(offset, 0, overflow))
	return offset

func _process(delta: float) -> void:
	if question == null: return
	question_offset = _scroll_strip(question_scroll, question, question_offset, delta, 18.0)
	ticker_offset = _scroll_strip(ticker_scroll, ticker, ticker_offset, delta, 30.0)
	if coach != null: coach.set_target(coach_rect())

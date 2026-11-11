extends "res://scripts/v2/windows/window_base.gd"
# T-034: the Data window. One window with three tabs: Files (inbox), Sheet and Charts.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const FilesView = preload("res://scripts/v2/data/files_view.gd")
const SheetView = preload("res://scripts/v2/data/sheet_view.gd")
const ChartView = preload("res://scripts/v2/data/chart_view.gd")
const AREA := Rect2(58, 30, 442, 290)
const TABS := ["files", "sheet", "charts"]
signal tab_shown(tab: String)
signal data_changed
var strings: Dictionary
var session: RefCounted
var tab := "files"
var tab_buttons: Dictionary = {}
var views: Dictionary = {}
var files_view: Control
var sheet_view: Control
var chart_view: Control

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.data, AREA)
	label(content, strings.data_ui.files.empty, Rect2(0, 0, 300, 12), 6)

# Called once the data session exists (a real world); test doubles never get one.
func attach_session(value: RefCounted) -> void:
	session = value
	empty(content)
	var ui_texts: Dictionary = strings.data_ui
	for i in TABS.size():
		var id: String = TABS[i]
		var b := UI.button(content, ui_texts.tabs[id], Rect2(i * 72, 0, 70, 14))
		b.toggle_mode = true
		b.name = "Tab_" + id
		b.pressed.connect(show_tab.bind(id))
		tab_buttons[id] = b
	files_view = FilesView.new()
	sheet_view = SheetView.new()
	chart_view = ChartView.new()
	for pair in [["files", files_view], ["sheet", sheet_view], ["charts", chart_view]]:
		pair[1].position = Vector2(0, 16)
		content.add_child(pair[1])
		views[pair[0]] = pair[1]
	files_view.build(session, ui_texts)
	sheet_view.build(session, ui_texts)
	chart_view.build(session, ui_texts, ui_texts)
	files_view.open_requested.connect(open_file)
	sheet_view.changed.connect(func(): data_changed.emit())
	chart_view.changed.connect(func(): data_changed.emit())
	show_tab("files")

func open_file(file_id: String) -> void:
	if session == null: return
	var model: RefCounted = session.open_file(file_id)
	if model == null:
		files_view.refresh()
		return
	sheet_view.show_file(file_id)
	chart_view.use_file(file_id)
	files_view.refresh()
	show_tab("sheet")
	data_changed.emit()

func show_tab(id: String) -> void:
	if not views.has(id): return
	tab = id
	for key in views:
		views[key].visible = key == id
		tab_buttons[key].button_pressed = key == id
	if id == "files": files_view.refresh()
	if id == "sheet": sheet_view.refresh()
	if id == "charts":
		if chart_view.file_id == "" or session.sheet(chart_view.file_id) == null and chart_view.source == "clean": chart_view.reset_spec()
		chart_view.render()
	tab_shown.emit(id)

# A new day: every view starts again from today's files.
func reset_day() -> void:
	if session == null: return
	sheet_view.sheet = null
	sheet_view.close_overlays()
	chart_view.file_id = ""
	chart_view.source = "raw"
	chart_view.reset_spec()
	sheet_view.refresh()
	chart_view.render()
	show_tab("files")

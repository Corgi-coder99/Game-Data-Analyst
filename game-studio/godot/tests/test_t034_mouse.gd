extends SceneTree
# T-034 real-mouse test (no --headless): real InputEventMouseButton events through the input system.
# Files -> open a file -> Dedupe from the toolbar -> edit the step -> Undo -> bar chart -> Pin chart -> Mail ->
# Attach -> choose a finding -> Send -> review step "Your analysis".
const Flow = preload("res://scripts/v2/game_flow.gd")
const SCREEN := Rect2(0, 0, 640, 360)
var checks := 0
var failures := 0
var flow: Node
var scale_factor := 2.0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func settle(frames: int = 3) -> void:
	for i in frames: await process_frame

func shot(name: String) -> void:
	await settle(4)
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-034")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("m-" + name + ".png"))

func send_mouse(position: Vector2, pressed: bool, moving: bool = false) -> void:
	var window_position := position * scale_factor
	if moving:
		var motion := InputEventMouseMotion.new()
		motion.position = window_position
		motion.global_position = window_position
		Input.parse_input_event(motion)
	else:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = window_position
		event.global_position = window_position
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(event)
	await process_frame

func click(target: Control, label: String) -> void:
	check(target != null and is_instance_valid(target) and target.is_visible_in_tree(), "clickable: " + label)
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree(): return
	var rect := target.get_global_rect()
	check(SCREEN.encloses(rect), "click target on screen: %s %s" % [label, rect])
	var point := rect.get_center()
	await send_mouse(point, false, true)
	await send_mouse(point, true)
	await send_mouse(point, false)
	await settle(2)

func pump_office() -> void:
	var guard := 0
	while flow.office != null and not flow.office.dialog.visible and guard < 60:
		flow.office.advance(0.5)
		await process_frame
		guard += 1

# Opens a Picker with a real click, then clicks its item number.
func pick(host: Node, picker_name: String, index: int) -> void:
	var p: Control = host.find_child(picker_name, true, false)
	await click(p, "picker " + picker_name)
	var item: Control = host.find_child("Item%d" % index, true, false)
	await click(item, "item %d of %s" % [index, picker_name])

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t034_mouse needs a real display: run it without --headless")
		quit(2)
		return
	scale_factor = float(root.size.x) / 640.0
	flow = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	flow.daily_enabled = false
	flow.commute_enabled = false
	root.add_child(flow)
	await settle()
	flow.seed_used = 104
	flow.start_with_game(preload("res://scripts/world/world_game.gd").new(104, 10))
	await settle(4)
	flow.skip_intro()
	await settle(2)
	for i in 40:
		if flow.state == "WORK": break
		if flow.office != null and not flow.office.dialog.visible: flow.office.advance(0.5)
		flow.skip_intro()
		await process_frame
	if flow.state != "WORK":
		await click(flow.office.desk_button, "desk")
		await pump_office()
		await click(flow.office.dialog, "dialog")
	check(flow.state == "WORK" and flow.desktop != null, "work starts")
	var desktop: Control = flow.desktop
	var game: RefCounted = flow.game
	var session: RefCounted = desktop.data_session
	await settle(4)
	await click(desktop.coach.skip_button, "skip tutorial")
	var minutes_before := int(game.status().minutes)
	# 1. Files
	await click(desktop.icon_buttons.files, "Files icon")
	check(desktop.front == "data" and desktop.data_window.tab == "files", "Files icon opens the Data window on Files")
	var fid: String = session.files[0].id
	check(desktop.data_window.files_view.open_buttons.has(fid), "the inbox lists today's file")
	await shot("1-files")
	await click(desktop.data_window.files_view.open_buttons[fid], "Open file")
	check(desktop.data_window.tab == "sheet" and session.opened.has(fid), "Open shows the Sheet")
	check(int(game.status().minutes) == minutes_before + 10 and int(game.status().energy) == 3, "opening cost 10 minutes and no Energy")
	var sheet_view: Control = desktop.data_window.sheet_view
	var rows_raw: int = sheet_view.sheet.row_count()
	# 2. Dedupe from the toolbar
	await click(sheet_view.toolbar_buttons.dedupe, "Dedupe toolbar button")
	check(sheet_view.dialog != null, "the Dedupe dialog opens")
	await shot("2-dialog")
	await click(sheet_view.dialog_ok, "Add step")
	check(sheet_view.sheet.steps().size() == 1 and sheet_view.sheet.steps()[0].op == "dedupe", "Dedupe step added")
	var rows_after: int = sheet_view.sheet.row_count()
	check(rows_after <= rows_raw, "dedupe did not add rows (%d -> %d)" % [rows_raw, rows_after])
	# 3. Edit the step: key on the first column
	await click(sheet_view.step_buttons[0].edit, "Edit step")
	check(sheet_view.dialog != null and sheet_view.dialog_index == 0, "edit opens the dialog for step 1")
	var chip: Button
	for child in sheet_view.dialog.get_children():
		if child is Button and child.toggle_mode and child.text != "": chip = child
	await click(chip, "key column chip")
	var chip_again: Button
	for child in sheet_view.dialog.get_children():
		if child is Button and child.toggle_mode and child.button_pressed: chip_again = child
	check(chip_again != null, "the chip is on")
	await click(sheet_view.dialog_ok, "Save step")
	check(sheet_view.sheet.steps()[0].cols.size() == 1, "step now keys on one column")
	await shot("3-edited")
	# 4. Undo
	await click(sheet_view.undo_button, "Undo")
	check(sheet_view.sheet.steps()[0].cols.is_empty(), "Undo restores the earlier step")
	# 5. Bar chart
	await click(desktop.icon_buttons.charts, "Charts icon")
	check(desktop.data_window.tab == "charts", "Charts icon shows the chart builder")
	var chart_view: Control = desktop.data_window.chart_view
	await pick(chart_view, "Field_source", 1)
	check(chart_view.source == "clean", "chart reads the cleaned table")
	await pick(chart_view, "Field_type", 0)
	check(chart_view.spec.type == "bar", "bar chart selected")
	await pick(chart_view, "Field_sort", 2)
	var unit: LineEdit = chart_view.find_child("Field_y_label", true, false)
	await click(unit, "unit field")
	unit.text = "Units"
	unit.text_changed.emit("Units")
	await settle(2)
	check(chart_view.spec.get("y_label", "") == "Units", "unit label set")
	await shot("4-chart")
	await click(chart_view.pin_button, "Pin chart")
	check(session.pins.size() == 1 and session.pins[0].type == "chart", "chart pinned")
	var pin_id: String = session.pins[0].id
	# 6. Mail
	await click(desktop.icon_buttons.report, "Mail icon")
	await click(desktop.report_window.forecast_buttons.tang, "forecast Up")
	await click(desktop.report_window.confidence_buttons.vua, "confidence Medium")
	await click(desktop.report_window.analysis_button, "Analysis button")
	check(desktop.report_window.analysis_panel != null, "analysis panel opens")
	await click(desktop.report_window.analysis_panel.attach_buttons[pin_id], "Attach")
	check(session.attached.has(pin_id), "chart attached")
	var panel: Control = desktop.report_window.analysis_panel
	var picked_key := ""
	for key in panel.finding_pickers:
		if picked_key == "" and key.ends_with("spike_error"): picked_key = key
	if picked_key == "": picked_key = panel.finding_pickers.keys()[0]
	var picker: Control = panel.finding_pickers[picked_key]
	await click(picker, "finding picker")
	var item: Control = desktop.report_window.find_child("Item1", true, false)
	await click(item, "finding choice")
	var chosen := 0
	for f in session.findings: chosen += session.findings[f].size()
	check(chosen == 1, "a finding is chosen")
	await shot("5-mail-analysis")
	await click(panel.find_child("AnalysisDone", true, false), "Done")
	check(desktop.report_window.analysis_panel == null, "panel closes")
	# 7. Send
	await click(desktop.report_window.submit_button, "Send")
	check(desktop.report_window.confirming, "confirmation shows")
	await click(desktop.report_window.confirm_yes, "Yes, send")
	await settle(6)
	check(flow.state == "REVIEW" and flow.submission.has("analysis"), "the report with the analysis is sent: " + flow.state)
	check(flow.review_view != null and flow.review_view.analysis_step, "the review has the analysis step")
	var guard := 0
	while flow.review_view != null and flow.review_view.step < 5 and guard < 8:
		await click(flow.review_view.continue_button, "Continue")
		guard += 1
	check(flow.review_view.step == 5 and flow.review_view.header_label.text.contains("Your analysis"), "reached the step Your analysis: " + flow.review_view.header_label.text)
	await shot("6-review-analysis")
	print("test_t034_mouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

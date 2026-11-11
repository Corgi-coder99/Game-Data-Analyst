extends SceneTree
# T-035 real-mouse test (no --headless): tutorial day 1 end to end with real InputEventMouseButton events.
# Files -> open -> Next -> Dedupe -> Text (standardize) -> Group -> bar chart -> Pin -> Mail -> Analysis -> Attach ->
# finding -> forecast -> Send -> review (coaching page, case solved popup) -> Handbook cards unlocked.
const Flow = preload("res://scripts/v2/game_flow.gd")
const LearnState = preload("res://scripts/learn/learn_state.gd")
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
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-035")
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

# Opens a Picker with a real click, then clicks the item whose text is `wanted`.
func pick_text(host: Node, picker_name: String, wanted: String) -> void:
	var p: Control = host.find_child(picker_name, true, false)
	await click(p, "picker " + picker_name)
	var found: Button
	for item in host.find_children("Item*", "Button", true, false):
		if item.text == wanted and item.is_visible_in_tree(): found = item
	check(found != null, "picker %s offers '%s'" % [picker_name, wanted])
	if found != null: await click(found, "item " + wanted)

func chip(dialog: Control, text: String) -> Button:
	for child in dialog.get_children():
		if child is Button and child.toggle_mode and child.text == text: return child
	return null

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t035_mouse needs a real display: run it without --headless")
		quit(2)
		return
	scale_factor = float(root.size.x) / 640.0
	flow = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	flow.daily_enabled = false
	flow.commute_enabled = false
	flow.learn_state = LearnState.new()
	flow.learn_state.set_tutorial("on")
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
	var coach: Control = desktop.case_coach
	await settle(4)
	check(coach.active and coach.visible and not desktop.coach.bubble.visible, "the tutorial coach (Dr. Linh) is showing, the classic bubble is not")
	check(session.tutorial_today() and session.files.size() == 1 and session.files[0].name == "sales_export_day1", "tutorial day 1 file")
	await shot("1-coach-open")
	# 1. Files and Open
	check(coach.current_id() == "open", "step 1 is Open")
	await click(desktop.icon_buttons.files, "Files icon")
	check(desktop.front == "data" and desktop.data_window.tab == "files", "Files icon opens Files")
	var fid: String = session.files[0].id
	await click(desktop.data_window.files_view.open_buttons[fid], "Open file")
	check(session.opened.has(fid) and desktop.data_window.tab == "sheet", "Open shows the Sheet")
	await settle(2)
	check(coach.current_id() == "look", "the coach moved on by itself after the real Open: " + coach.current_id())
	await shot("2-coach-look")
	var sheet_view: Control = desktop.data_window.sheet_view
	# stuck button
	await click(coach.stuck_button, "I'm stuck")
	check(coach.stuck_label.text != "", "I'm stuck shows how to do the step")
	await click(coach.next_button, "Next")
	check(coach.current_id() == "dedupe", "Next moves past the looking step: " + coach.current_id())
	# 2. Dedupe
	await click(sheet_view.toolbar_buttons.dedupe, "Dedupe")
	await click(sheet_view.dialog_ok, "Add Dedupe step")
	check(sheet_view.sheet.steps().size() == 1 and sheet_view.sheet.steps()[0].op == "dedupe", "Dedupe step added")
	check(sheet_view.sheet.row_count() == 12, "dedupe took 14 rows to 12 (%d)" % sheet_view.sheet.row_count())
	await settle(2)
	check(coach.current_id() == "standardize", "the coach asks for the Text step: " + coach.current_id())
	check(session.learn.is_unlocked("hb_duplicates"), "using Dedupe unlocked the Duplicate rows card")
	# 3. Text (standardize): merge the two odd spellings into Hanoi
	await click(sheet_view.toolbar_buttons.standardize, "Text")
	await pick_text(sheet_view, "Field_col", "region")
	var odd_a := chip(sheet_view.dialog, "Ha Noi")
	var odd_b := chip(sheet_view.dialog, "hanoi")
	check(odd_a != null and odd_b != null, "the dialog offers the two odd spellings as chips")
	await click(odd_a, "chip Ha Noi")
	await click(odd_b, "chip hanoi")
	var into: LineEdit = sheet_view.dialog.find_child("Field_into", true, false)
	await click(into, "Into field")
	into.text = "Hanoi"
	into.text_changed.emit("Hanoi")
	await settle(2)
	await shot("3-standardize-dialog")
	await click(sheet_view.dialog_ok, "Add Text step")
	check(sheet_view.sheet.steps().size() == 2 and sheet_view.sheet.steps()[1].op == "standardize", "Text step added")
	var regions := {}
	for r in sheet_view.sheet.table().rows: regions[r[1]] = true
	check(regions.size() == 3, "three regions remain after standardizing (%s)" % str(regions.keys()))
	await settle(2)
	check(coach.current_id() == "group", "the coach asks for Group: " + coach.current_id())
	# 4. Group by region, sum units
	await click(sheet_view.toolbar_buttons.group, "Group")
	await click(chip(sheet_view.dialog, "region"), "chip region")
	await pick_text(sheet_view, "Field_col", "units")
	await click(sheet_view.dialog_ok, "Add Group step")
	check(sheet_view.sheet.steps().size() == 3 and sheet_view.sheet.steps()[2].op == "group", "Group step added")
	check(sheet_view.sheet.row_count() == 3, "three rows after grouping")
	await settle(2)
	check(coach.current_id() == "chart", "the coach asks for the chart: " + coach.current_id())
	# 5. Chart: clean table, bar, sorted, unit, pin
	await click(desktop.icon_buttons.charts, "Charts icon")
	var chart_view: Control = desktop.data_window.chart_view
	await pick_text(chart_view, "Field_source", "Cleaned (my steps)")
	check(chart_view.source == "clean", "chart reads the cleaned table")
	await pick_text(chart_view, "Field_type", "Bar")
	check(chart_view.spec.x == "region" and chart_view.spec.y == "units_sum", "x is region, y is units_sum: %s / %s" % [chart_view.spec.x, chart_view.spec.y])
	await pick_text(chart_view, "Field_sort", "high to low")
	var unit: LineEdit = chart_view.find_child("Field_y_label", true, false)
	await click(unit, "unit field")
	unit.text = "Units"
	unit.text_changed.emit("Units")
	await settle(2)
	await shot("4-chart")
	await click(chart_view.pin_button, "Pin chart")
	check(session.pins.size() == 1 and session.pins[0].type == "chart", "chart pinned")
	var pin_id: String = session.pins[0].id
	await settle(2)
	check(coach.current_id() == "attach", "the coach asks to attach: " + coach.current_id())
	# Handbook while working: free, shows the unlocked card
	var minutes_before := int(game.status().minutes)
	await click(desktop.icon_buttons.handbook, "Handbook icon")
	check(desktop.front == "handbook" and desktop.handbook_window.visible, "Handbook opens")
	await click(desktop.handbook_window.card_buttons["hb_duplicates"], "card Duplicate rows")
	check(desktop.handbook_window.detail_title.text == "Duplicate rows" and desktop.handbook_window.locked_note == null, "the unlocked card reads in full")
	await click(desktop.handbook_window.card_buttons["hb_pvalue"], "card p-value (locked)")
	check(desktop.handbook_window.locked_note != null and desktop.handbook_window.locked_note.text == "Meet this case to unlock", "a locked card says Meet this case to unlock")
	check(int(game.status().minutes) == minutes_before and int(game.status().energy) == 3, "the Handbook cost no time and no Energy")
	await shot("5-handbook")
	# 6. Mail: attach, finding, forecast
	await click(desktop.icon_buttons.report, "Mail icon")
	await click(desktop.report_window.analysis_button, "Analysis button")
	var panel: Control = desktop.report_window.analysis_panel
	check(panel != null, "analysis panel opens")
	await click(panel.attach_buttons[pin_id], "Attach")
	check(session.attached.has(pin_id), "chart attached")
	await settle(2)
	check(coach.current_id() == "finding", "the coach asks for a finding: " + coach.current_id())
	var picker_name := "Pick_%s_top_region" % fid
	await pick_text(panel, picker_name, "Hanoi")
	check(session.finding(fid, "top_region") == "Hanoi", "finding chosen")
	await shot("6-mail-analysis")
	await click(panel.find_child("AnalysisDone", true, false), "Done")
	await settle(2)
	check(coach.current_id() == "forecast", "the coach asks for the forecast: " + coach.current_id())
	await click(desktop.report_window.forecast_buttons.tang, "forecast Up")
	await click(desktop.report_window.confidence_buttons.vua, "confidence Medium")
	await settle(2)
	check(coach.current_id() == "send", "the coach asks for Send: " + coach.current_id())
	await shot("7-coach-send")
	await click(desktop.report_window.submit_button, "Send")
	await click(desktop.report_window.confirm_yes, "Yes, send")
	await settle(6)
	check(flow.state == "REVIEW" and flow.submission.has("analysis"), "the report with the analysis is sent: " + flow.state)
	check(flow.review_view != null and flow.review_view.analysis_step, "the review has the analysis step")
	var guard := 0
	while flow.review_view != null and flow.review_view.step < 5 and guard < 8:
		await click(flow.review_view.continue_button, "Continue")
		guard += 1
	var review: Control = flow.review_view
	check(review.step == 5 and review.header_label.text.contains("Your analysis"), "reached Your analysis: " + review.header_label.text)
	var outcome: Dictionary = review.learn_outcome
	check(outcome.get("tutorial_day", false) or review.tutorial_day, "it is a tutorial day")
	check(outcome.get("solved", false), "the case is solved (perfect play)")
	check(review.celebration != null and review.celebration.visible, "the case-solved popup shows")
	await shot("8-review-celebration")
	await click(review.celebration.find_child("CelebrationOk", true, false), "Great")
	check(not review.celebration.visible, "the popup closes")
	await click(review.tab_buttons.coaching, "Coaching tab")
	check(review.analysis_page == "coaching", "coaching page")
	var tips: Array = review.coaching_tips(flow.desktop.data_session.data.analysis_review(1))
	check(tips.size() == 3, "two traps (duplicates, spellings) and the clean chart are coached on day 1: %d" % tips.size())
	for tip in tips:
		check(tip.voice == "linh" and tip.outcome == "praise", "Dr. Linh praises the fix: %s %s" % [tip.trap, tip.outcome])
	await shot("9-review-coaching")
	if tips.size() > 1:
		await click(review.tip_buttons.next, "next tip")
		check(review.tip_index == 1, "next tip")
		await shot("10-review-coaching-2")
	# skill bars
	check(review.skill_rows.size() == 5, "five skill bars in the review")
	check(int(outcome.gains.data_cleaning) > 0 and int(outcome.gains.charts) > 0, "XP for cleaning and for the chart")
	# the cards of the case are unlocked now
	check(flow.learn_state.is_unlocked("hb_double_counting") and flow.learn_state.is_unlocked("hb_text_standardize"), "the case cards are unlocked in the profile state")
	check(flow.learn_state.tutorial_days_done() == 1 and flow.learn_state.tutorial_mode() == "on", "day 1 counts for the tutorial")
	print("test_t035_mouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

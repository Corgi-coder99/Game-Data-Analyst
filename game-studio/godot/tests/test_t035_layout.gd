extends SceneTree
# T-035 render test (needs a window, no --headless). Handbook (list, detail, locked, search), hint popups in Sheet,
# Charts and Mail, the coaching review step (every tip, skill bars, celebration), tutorial coach marks for each of
# the five days, skill bars on the Wall of Fame, the Dr. Linh sprite, the first-run choice. Everything inside
# 640x360, no overlapping siblings, text not clipped. Saves screenshots to docs/screenshots-T-035.
const Game = preload("res://scripts/world/world_game.gd")
const Desktop = preload("res://scenes/v2/desktop.tscn")
const ReviewScene = preload("res://scenes/v2/review.tscn")
const WallScene = preload("res://scripts/v2/wall_scene.gd")
const TutorialChoice = preload("res://scripts/v2/learn/tutorial_choice.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const LearnState = preload("res://scripts/learn/learn_state.gd")
const LearnSettle = preload("res://scripts/learn/learn_settle.gd")
const TutorialScript = preload("res://scripts/learn/tutorial_script.gd")
const Content = preload("res://scripts/learn/content.gd")
const SCREEN := Rect2(0, 0, 640, 360)
var checks := 0
var failures := 0
var shots_dir := ""

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	root.get_texture().get_image().save_png(shots_dir.path_join(name + ".png"))

func skip_node(node: Control) -> bool:
	return node is ColorRect or node is Panel or node.has_meta("overlay") or node.z_index > 0 or node is ScrollBar

func in_scroll(node: Node) -> bool:
	var p := node
	while p != null:
		if p is ScrollContainer: return true
		p = p.get_parent()
	return false

func scan(node: Node, tag: String, in_window: bool = false) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		if not in_scroll(node):
			check(SCREEN.encloses(rect), "%s: inside the screen %s %s" % [tag, node.get_path(), str(rect)])
		if node is Button and in_window and node.size != Vector2(8, 8):
			var font: Font = node.get_theme_default_font()
			var width: float = font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			if node.text != "" and node.icon == null and not node is OptionButton:
				check(width + 4.0 <= rect.size.x or node.text.length() <= 3, "%s: button text fits '%s' (%.0f in %.0f)" % [tag, node.text, width, rect.size.x])
			if not in_scroll(node) or node.custom_minimum_size.y > 0.0:
				check(rect.size.x >= 14.0 and rect.size.y >= 14.0, "%s: hit target >= 14x14 '%s' %s" % [tag, node.text, str(rect.size)])
		if node is Label and in_window:
			var font2: Font = node.get_theme_default_font()
			var size2: int = node.get_theme_font_size("font_size")
			check(size2 >= 8, tag + ": font >= 8")
			if node.autowrap_mode == TextServer.AUTOWRAP_OFF:
				var w2: float = font2.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size2).x
				check(w2 <= rect.size.x + 1.0 or node.text == "", "%s: label text fits '%s' (%.0f in %.0f)" % [tag, node.text, w2, rect.size.x])
			elif node.max_lines_visible > 0:
				var lines: int = node.get_line_count()
				check(lines <= node.max_lines_visible, "%s: wrapped label fits in %d lines (needs %d) '%s'" % [tag, node.max_lines_visible, lines, node.text.left(40)])
		if not (node is ScrollContainer):
			siblings(node, tag)
	for child in node.get_children(): scan(child, tag, in_window)

func siblings(parent: Control, tag: String) -> void:
	var list: Array = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and not skip_node(child): list.append(child)
	for i in list.size():
		for j in range(i + 1, list.size()):
			check(not list[i].get_global_rect().intersects(list[j].get_global_rect()), "%s: sibling overlap %s / %s" % [tag, str(list[i].get_path()), str(list[j].get_path())])

func make_desktop(seed_value: int, day: int, learn: RefCounted = null) -> Array:
	var game := Game.new(seed_value, 10)
	for d in range(1, day):
		game.begin_day()
		game.submit_report({"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]})
		game.end_day()
	game.begin_day()
	var desktop = Desktop.instantiate()
	desktop.data_seed = seed_value
	desktop.learn = learn if learn != null else LearnState.new()
	root.add_child(desktop)
	desktop.setup(game)
	return [game, desktop]

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_t035_layout requires a real display; omit --headless")
		quit(2)
		return
	shots_dir = ProjectSettings.globalize_path("res://docs/screenshots-T-035")
	DirAccess.make_dir_recursive_absolute(shots_dir)
	await sprite_and_icon()
	await handbook_screens()
	await hint_screens()
	await review_coaching()
	await tutorial_days()
	await wall_screen()
	await choice_screen()
	print("test_t035_layout: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

# ---- Dr. Linh and the Handbook icon -----------------------------------------------------------------------

func sprite_and_icon() -> void:
	var made := make_desktop(104, 1)
	var desktop: Control = made[1]
	await settle()
	check(desktop.icon_buttons.has("handbook"), "the desktop has a Handbook icon")
	check(desktop.icon_buttons.size() == 9, "nine desktop icons")
	var rects: Array = []
	for id in desktop.icon_buttons:
		var r: Rect2 = desktop.icon_buttons[id].get_global_rect()
		check(SCREEN.encloses(r) and r.size.x >= 14 and r.size.y >= 14, "icon " + id + " fits and is a target " + str(r))
		check(r.end.y <= 320.0, "icon " + id + " stays above the tray")
		for other in rects: check(not other.intersects(r), "icons do not overlap")
		rects.append(r)
	var sprites := preload("res://scripts/v2/sprite_lib.gd").new()
	var linh := sprites.frame("drlinh")
	check(linh.get_size() == Vector2(16, 24), "Dr. Linh is 16x24 like the other staff")
	for other in ["hanh", "khoi", "player", "kai"]:
		check(sprites.frame(other).get_size() == linh.get_size(), "same size as " + other)
	# a zoomed gallery of the mentor and the new icon for the screenshot
	var gallery := Control.new()
	gallery.size = Vector2(640, 360)
	var back := ColorRect.new()
	back.color = Color("#2a1f33")
	back.size = Vector2(640, 360)
	gallery.add_child(back)
	var x := 40
	for id in ["drlinh", "linh", "hanh", "khoi"]:
		var t := TextureRect.new()
		t.texture = sprites.frame(id)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.position = Vector2(x, 60)
		t.size = Vector2(96, 144)
		gallery.add_child(t)
		x += 130
	var icon := TextureRect.new()
	icon.texture = sprites.frame("app_handbook")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(560, 60)
	icon.size = Vector2(64, 64)
	gallery.add_child(icon)
	desktop.visible = false
	root.add_child(gallery)
	await settle()
	shot("01-dr-linh-sprites")
	gallery.queue_free()
	desktop.queue_free()
	await process_frame

# ---- Handbook -----------------------------------------------------------------------------------------------

func handbook_screens() -> void:
	var learn := LearnState.new()
	learn.unlock_for_op("dedupe")
	learn.unlock_for_op("standardize")
	learn.unlock_for_case(Content.case_by_id("case_funnel_dropoff"))
	var made := make_desktop(104, 1, learn)
	var desktop: Control = made[1]
	await settle()
	desktop.open_window("handbook")
	await settle()
	var hb: Control = desktop.handbook_window
	check(desktop.front == "handbook" and hb.visible, "the Handbook icon opens the window")
	check(hb.card_buttons.size() == 49, "49 cards listed")
	scan(hb, "handbook list", true)
	shot("02-handbook-list")
	var locked_count := 0
	for id in hb.card_buttons:
		if not hb.is_open(id): locked_count += 1
	check(locked_count == 49 - learn.unlocked_count(), "locked cards are marked (%d)" % locked_count)
	check(hb.card_buttons["hb_funnel"].icon == null and hb.card_buttons["hb_pvalue"].icon != null, "locked cards show the lock icon")
	# unlocked card
	hb.show_card("hb_duplicates")
	await settle()
	scan(hb, "handbook detail", true)
	shot("03-handbook-detail")
	check(hb.detail_title.text == "Duplicate rows" and hb.link_buttons.size() >= 1, "detail shows the title and see-also links")
	# locked card
	hb.show_card("hb_pvalue")
	await settle()
	scan(hb, "handbook locked", true)
	shot("04-handbook-locked")
	check(hb.locked_note != null and hb.locked_note.text == "Meet this case to unlock", "locked card says Meet this case to unlock")
	check(hb.link_buttons.is_empty(), "a locked card shows no content")
	# search
	hb.search_edit.text = "dup"
	hb.search_edit.text_changed.emit("dup")
	await settle()
	check(hb.card_buttons.size() >= 1 and hb.card_buttons.size() < 10, "search filters by title (%d)" % hb.card_buttons.size())
	scan(hb, "handbook search", true)
	shot("05-handbook-search")
	hb.search_edit.text = "zzzz"
	hb.search_edit.text_changed.emit("zzzz")
	await settle()
	check(hb.card_buttons.is_empty(), "no match, no card")
	hb.search_edit.text = ""
	hb.search_edit.text_changed.emit("")
	# a link opens the other card
	hb.show_card("hb_duplicates")
	var first_link: String = hb.link_buttons.keys()[0]
	hb.link_buttons[first_link].pressed.emit()
	await settle()
	check(hb.selected == first_link, "a see-also link opens that card")
	# taskbar entry and no clock cost
	var minutes: int = int(made[0].status().minutes)
	desktop.open_window("handbook")
	check(int(made[0].status().minutes) == minutes and int(made[0].status().energy) == 3, "reading the Handbook costs no time and no Energy")
	check(desktop.task_buttons.has("handbook") and desktop.task_buttons.handbook.visible, "the Handbook has a taskbar button")
	desktop.queue_free()
	await process_frame

# ---- Hint popups ----------------------------------------------------------------------------------------------

func hint_screens() -> void:
	var made := make_desktop(104, 1)
	var desktop: Control = made[1]
	var session: RefCounted = desktop.data_session
	await settle()
	var fid: String = session.files[0].id
	desktop.open_data("files")
	desktop.data_window.open_file(fid)
	desktop.open_data("sheet")
	await settle()
	var sheet_view: Control = desktop.data_window.sheet_view
	check(sheet_view.hint_button != null and sheet_view.hint_button.get_global_rect().size.y >= 14.0, "Sheet has a Hint button")
	scan(desktop.data_window, "sheet with hint", true)
	sheet_view.hint_button.pressed.emit()
	await settle()
	var popup: Control = sheet_view.find_child("HintPopup", true, false)
	check(popup != null and popup.is_visible_in_tree(), "the Hint button opens the popup")
	check(int(made[0].status().energy) == 3, "opening the popup is free")
	scan(popup, "hint popup 0", true)
	shot("06-hint-popup-empty")
	popup.get_button.pressed.emit()
	await settle()
	check(int(made[0].status().energy) == 2 and session.hint_level(fid) == 1, "Get hint costs 1 Energy")
	popup.get_button.pressed.emit()
	await settle()
	popup.get_button.pressed.emit()
	await settle()
	check(int(made[0].status().energy) == 0 and session.hint_level(fid) == 3, "three levels cost 3 Energy")
	scan(popup, "hint popup 3", true)
	shot("07-hint-popup-three-levels")
	for level in [1, 2, 3]:
		var t: Label = popup.find_child("HintText%d" % level, true, false)
		check(t != null and t.get_line_count() <= t.max_lines_visible, "hint %d text fits (%d lines of %d)" % [level, t.get_line_count(), t.max_lines_visible])
	check(popup.get_button.disabled, "no fourth level")
	popup.close_button.pressed.emit()
	await settle()
	check(sheet_view.find_child("HintPopup", true, false) == null, "Close removes the popup")
	check(sheet_view.hint_button.text.contains("3/3"), "the button shows the levels used: " + sheet_view.hint_button.text)
	# Charts and Mail popups (read-only now: the Energy is spent)
	desktop.open_data("charts")
	await settle()
	var chart_view: Control = desktop.data_window.chart_view
	check(desktop.front == "data" and chart_view.is_visible_in_tree(), "the Charts tab is showing")
	check(chart_view.hint_button != null, "Charts has a Hint button")
	scan(desktop.data_window, "charts with hint", true)
	chart_view.hint_button.pressed.emit()
	await settle()
	scan(chart_view, "charts hint popup", true)
	shot("08-hint-popup-charts")
	chart_view.find_child("HintClose", true, false).pressed.emit()
	desktop.open_window("report")
	desktop.report_window.choose_forecast("tang")
	desktop.report_window.choose_confidence("vua")
	desktop.report_window.open_analysis(true)
	await settle()
	var panel: Control = desktop.report_window.analysis_panel
	var mail_hint: Button = panel.find_child("HintButton", true, false)
	check(mail_hint != null, "Mail > Analysis has a Hint button")
	scan(panel, "mail analysis with hint", true)
	mail_hint.pressed.emit()
	await settle()
	scan(panel, "mail hint popup", true)
	shot("09-hint-popup-mail")
	desktop.queue_free()
	await process_frame

# ---- Review: coaching page -------------------------------------------------------------------------------------

func play_day(desktop: Control, game: RefCounted, session: RefCounted, good: bool) -> Dictionary:
	var fid: String = session.files[0].id
	var internal: Dictionary = session.data._file(int(game.status().day), fid)
	var sheet: RefCounted = session.open_file(fid)
	var steps: Array = session.data._ref.steps(internal)
	for s in steps:
		if good or s.op in ["group", "sort"]: sheet.add_step(s)
	var spec: Dictionary = session.default_spec(fid, "clean")
	spec.merge({"sort": "desc", "y_label": "Value", "title": "Chart"}, true)
	var pin: String = session.pin_chart(fid, "clean", spec)
	if pin != "": session.attach(pin)
	var truth: Array = session.data._ref.evaluate_reference(internal).truth
	for t in truth:
		if good: session.set_finding(fid, t.id, t.value if not t.value is Dictionary else {"direction": t.value.direction, "band": t.value.band})
	return {"question_id": game.question_today().id, "forecast": "ngang", "confidence": "vua", "evidence": [], "actions": [], "analysis": session.payload()}

func review_coaching() -> void:
	for variant in ["good", "mixed"]:
		var learn := LearnState.new()
		var made := make_desktop(104, 1 if variant == "good" else 4, learn)
		var game: RefCounted = made[0]
		var desktop: Control = made[1]
		var session: RefCounted = desktop.data_session
		await settle()
		var fid: String = session.files[0].id
		session.open_file(fid)
		if variant == "mixed":
			session.request_hint(fid)
			session.request_hint(fid)
		var input := play_day(desktop, game, session, variant == "good")
		var before: Dictionary = game.status()
		check(game.submit_report(input).ok, "report accepted (" + variant + ")")
		game.end_day()
		var review = ReviewScene.instantiate()
		root.add_child(review)
		review.data_game = session.data
		review.learn_state = learn
		review.hints_by_file = session.hints_by_file()
		review.show_review(game, int(before.day), input, before)
		check(review.analysis_step and not review.learn_outcome.is_empty(), "the review settled the day (" + variant + ")")
		for i in 5: review.next_step()
		await settle()
		check(review.step == 5, "on the analysis step")
		scan(review.body, "review results " + variant, true)
		shot("10-review-results-" + variant)
		check(review.tab_buttons.has("results") and review.tab_buttons.has("coaching"), "two page tabs")
		if variant == "mixed": check(review.header_label.text.contains("Hint used"), "the Hint used tag shows in the review header")
		review.tab_buttons.coaching.pressed.emit()
		await settle()
		check(review.analysis_page == "coaching", "coaching page")
		var tips: Array = review.coaching_tips(session.data.analysis_review(int(before.day)))
		check(tips.size() >= 1, "at least one tip (%d)" % tips.size())
		for i in tips.size():
			review.tip_index = i
			review._render_step()
			await settle()
			scan(review.body, "review coaching %s tip %d" % [variant, i + 1], true)
			var line: Label = review.tip_nodes.get("line")
			check(line != null and line.get_line_count() <= line.max_lines_visible, "tip %d text fits (%d lines)" % [i + 1, line.get_line_count()])
			if i == 0: shot("11-review-coaching-%s-1" % variant)
			if i == 1: shot("11-review-coaching-%s-2" % variant)
		check(review.skill_rows.size() == 5, "five skill bars")
		var gain_total := 0
		for skill in review.skill_rows:
			var row: Dictionary = review.skill_rows[skill]
			check(row.fill.size.x >= 1.0 and row.fill.size.x <= 174.0, "bar width in range for " + skill)
			gain_total += int(review.learn_outcome.gains[skill])
		check(gain_total > 0, "the day gave some XP (%d)" % gain_total)
		review.tab_buttons.results.pressed.emit()
		await settle()
		review.queue_free()
		desktop.queue_free()
		await process_frame

# ---- Tutorial coach marks, one per day ------------------------------------------------------------------------------

func tutorial_days() -> void:
	var learn := LearnState.new()
	learn.set_tutorial("on")
	var game := Game.new(104, 10)
	var desktop = Desktop.instantiate()
	desktop.data_seed = 104
	desktop.learn = learn
	root.add_child(desktop)
	for day in range(1, 6):
		if day > 1:
			game.begin_day()
			desktop.start_day()
		else:
			game.begin_day()
			desktop.setup(game)
		await settle()
		var coach: Control = desktop.case_coach
		var session: RefCounted = desktop.data_session
		check(coach.active and coach.visible, "tutorial coach is active on day %d" % day)
		check(not desktop.coach.bubble.visible, "the classic coach is replaced on day %d" % day)
		check(session.tutorial_today() and session.files.size() == 1, "scripted file on day %d" % day)
		scan(coach, "case coach day %d step 1" % day, true)
		shot("20-tutorial-day%d-step1" % day)
		check(coach.current_id() == "open", "day %d starts with opening the file" % day)
		check(desktop.case_rect().size.x > 0, "the first step points at something")
		# open the file: the coach moves on without a click on Next
		desktop.open_data("files")
		await settle()
		check(coach.current_id() == "open", "the coach waits for the real action")
		desktop.data_window.open_file(session.files[0].id)
		await settle()
		check(coach.current_id() != "open", "opening the file advanced the coach to %s" % coach.current_id())
		scan(coach, "case coach day %d step 2" % day, true)
		# I'm stuck shows how
		coach.stuck_button.pressed.emit()
		await settle()
		check(coach.stuck_label.text != "", "I'm stuck shows the next step on day %d" % day)
		scan(coach, "case coach day %d stuck" % day, true)
		shot("21-tutorial-day%d-stuck" % day)
		if coach.current_is_manual():
			coach.next_button.pressed.emit()
			await settle()
		# finish the day with the scripted policy so the next day can begin
		var fid: String = session.files[0].id
		var internal: Dictionary = session.data._file(day, fid)
		var sheet: RefCounted = session.open_file(fid)
		for s in session.data._ref.steps(internal): sheet.add_step(s)
		await settle()
		check(coach.current_id() != "" or coach.status.complete, "coach has a next step after the Sheet work on day %d" % day)
		scan(coach, "case coach day %d mid" % day, true)
		var input := {"question_id": game.question_today().id, "forecast": "ngang", "confidence": "thap", "evidence": [], "actions": []}
		game.submit_report(input)
		game.end_day()
		desktop.report_window.lock(true)
	desktop.queue_free()
	await process_frame

# ---- Wall of Fame -----------------------------------------------------------------------------------------------------

func wall_screen() -> void:
	var path := "user://t035_wall_profile.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var meta := Meta.new(path)
	var learn := LearnState.new(meta.profile.data.learn)
	learn.add_xp("data_cleaning", 55)
	learn.add_xp("charts", 22)
	learn.add_xp("statistics", 150)
	learn.add_xp("causality", 5)
	meta.profile.data.achievements["first_clean"] = "2026-11-11"
	meta.profile.data.achievements["sharp_eye"] = "2026-11-11"
	var wall := WallScene.new()
	root.add_child(wall)
	wall.open(meta)
	await settle()
	check(wall.skill_nodes.size() == 5, "five skills on the Wall of Fame")
	check(wall.skill_nodes.data_cleaning.level == 3 and wall.skill_nodes.statistics.level == 5, "levels follow the XP")
	check(wall.skill_nodes.statistics.ratio == 1.0 and wall.skill_nodes.communication.ratio == 0.0, "bars follow the progress")
	check(wall.plaque_nodes.has("ach_first_clean") and wall.plaque_nodes.has("ach_tutorial_graduate"), "15 achievements listed")
	scan(wall, "wall of fame", true)
	shot("30-wall-of-fame-skills")
	wall.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await process_frame

func choice_screen() -> void:
	var choice := TutorialChoice.new()
	root.add_child(choice)
	choice.open(JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json")).learn.choice)
	await settle()
	check(choice.tutorial_button.text == "Tutorial days 1-5 (recommended)" and choice.skip_button.text == "Skip tutorial", "the two choices")
	scan(choice, "tutorial choice", true)
	shot("31-tutorial-choice")
	choice.queue_free()
	await process_frame

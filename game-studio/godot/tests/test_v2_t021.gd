extends SceneTree
# T-021 logic tests: desktop icons, Mail composer, evidence tray, visual news, tutorial and goals.
# Runs headless; the mouse-driven and layout checks live in test_v2_mouse.gd and the *_render tests.
const Game = preload("res://scripts/world/world_game.gd")
const Desktop = preload("res://scenes/v2/desktop.tscn")
const Claim = preload("res://scripts/v2/windows/claim.gd")
const Palette = preload("res://scripts/v2/palette.gd")
var checks := 0
var failures := 0
var strings: Dictionary
var submitted: Array = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func make_desktop(seed_value: int = 104) -> Control:
	var game := Game.new(seed_value, 10)
	game.begin_day()
	var desktop = Desktop.instantiate()
	root.add_child(desktop)
	desktop.setup(game)
	desktop.report_submitted.connect(func(input): submitted.append(input))
	return desktop

func press(button: Button) -> void:
	button.pressed.emit()

func texts_of(node: Node, out: Array) -> void:
	if node is Label: out.append(node.text)
	if node is Button: out.append(node.text)
	if node is Control and node.tooltip_text != "": out.append(node.tooltip_text)
	for child in node.get_children(): texts_of(child, out)

func test_icons(desktop: Control) -> void:
	check(desktop.icon_buttons.keys() == ["news", "files", "sheet", "charts", "report", "company", "tools", "help"], "eight desktop icons (T-034 adds Files, Sheet, Charts)")
	var captions := {"news":"Browser", "report":"Mail", "company":"Dashboard", "tools":"Code Pad", "help":"Help", "files":"Files", "sheet":"Sheet", "charts":"Charts"}
	for id in captions:
		var tile: Button = desktop.icon_buttons[id]
		var caption := ""
		for child in tile.get_children():
			if child is Label: caption = child.text
		check(caption == captions[id], "icon caption " + id)
	for id in ["news", "report", "company", "tools"]:
		press(desktop.icon_buttons[id])
		check(desktop.front == id and desktop.windows[id].visible and id in desktop.open_ids, "icon opens " + id)
		press(desktop.icon_buttons[id])
		check(desktop.front == id and desktop.windows[id].visible, "second click on an icon only focuses " + id)
		desktop.windows[id].minimize_requested.emit()
		check(desktop.front == "" and not desktop.windows[id].visible and desktop.task_buttons[id].visible, "minimize keeps the taskbar entry " + id)
		press(desktop.task_buttons[id])
		check(desktop.front == id, "taskbar entry restores " + id)
		desktop.windows[id].close_requested.emit()
		check(desktop.front == "" and id not in desktop.open_ids and not desktop.task_buttons[id].visible, "close removes the taskbar entry " + id)
	press(desktop.icon_buttons.news)
	press(desktop.icon_buttons.tools)
	check(desktop.front == "tools" and desktop.windows.news.visible == false and desktop.task_buttons.news.visible and desktop.task_buttons.tools.visible, "taskbar lists every open window")
	var first_x: float = desktop.task_buttons.news.position.x
	check(desktop.task_buttons.tools.position.x == first_x + 112, "taskbar entries line up")
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	desktop._unhandled_input(escape)
	check(desktop.front == "", "Esc minimizes the front window")
	for id in desktop.windows: desktop.close_window(id)

func test_news_cards(desktop: Control) -> void:
	desktop.open_window("news")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/news.json"))
	var topics := {}
	for item in catalog.news: topics[item.topic] = true
	for topic in topics: check(FileAccess.file_exists("res://assets/v2/topic_" + topic + ".png"), "pictogram for topic " + topic)
	check(desktop.news_window.thumbs.size() == desktop.entries.size() and not desktop.entries.is_empty(), "every card has a thumbnail")
	for item in desktop.entries:
		var thumb: TextureRect = desktop.news_window.thumbs[item.uid]
		var expected := Image.load_from_file("res://assets/v2/topic_" + item.topic + ".png")
		check(thumb.texture != null and thumb.texture.get_image().get_data() == expected.get_data(), "thumbnail shows the topic pictogram " + item.topic)
		check(thumb.size == Vector2(32, 32), "thumbnail is a 4x pixel icon")
		check(desktop.news_window.rows[item.uid].custom_minimum_size.y <= 72, "card stays compact")
	# Claim arrow and figure come from the headline text only.
	check(Claim.direction("Tan Lac Central Bank raises its policy rate by 3 points") == "tang" and Claim.figure("Tan Lac Central Bank raises its policy rate by 3 points") == "+3 pts", "claim: raise with figure")
	check(Claim.direction("The lac loses 1.0% against the world dollar in today's session") == "giam" and Claim.figure("The lac loses 1.0% against the world dollar in today's session") == "-1.0%", "claim: loss figure -1.0%")
	check(Claim.direction("Expert A says rates will fall, expert B says they will rise") == "", "claim: conflicting words give no arrow")
	check(Claim.direction("Central Bank holds its policy rate steady") == "ngang" and Claim.figure("Central Bank holds its policy rate steady") == "", "claim: flat without figure")
	check(Claim.direction("Regional economic summit discusses trade cooperation") == "", "claim: no claim")
	# Source badges: crest icon per tier, glossary tooltip on the tier name.
	for item in desktop.entries:
		var row: Control = desktop.news_window.rows[item.uid]
		var tier_tip := ""
		for child in row.get_children():
			if child is Label and child.text == strings.tiers[item.source_tier]: tier_tip = child.tooltip_text
		check(tier_tip == strings.glossary["tier_" + item.source_tier], "tier badge explains itself: " + item.source_tier)
	# Read more expands, shows the verify shortcut and collapses again.
	var uid: String = desktop.entries[0].uid
	var height_before: float = desktop.news_window.rows[uid].custom_minimum_size.y
	press(desktop.news_window.more_buttons[uid])
	check(desktop.news_window.expanded[uid] and desktop.news_window.rows[uid].custom_minimum_size.y > height_before and desktop.news_window.tools_buttons.has(uid), "Read more expands the card")
	press(desktop.news_window.tools_buttons[uid])
	check(desktop.selected == uid and desktop.front == "tools", "verify shortcut selects and opens Code Pad")
	desktop.open_window("news")
	press(desktop.news_window.more_buttons[uid])
	check(not desktop.news_window.expanded[uid], "Show less collapses the card")
	# No hidden truth is displayed anywhere on the desktop before a review.
	var game: RefCounted = desktop.game
	var secrets: Array = []
	for item in game._news._items:
		for key in ["truth", "kind", "template_id"]: secrets.append(str(item[key]))
	var forbidden := ["signal", "trap", "noise", "Partly true", "Irrelevant"]
	for word in strings.truth.values():
		if word not in ["Stale"]: forbidden.append(word)
	var shown: Array = []
	for id in desktop.windows: desktop.open_window(id)
	texts_of(desktop, shown)
	desktop.close_window("report")
	var blob := "\n".join(shown).to_lower()
	var padded := blob.replace("\n", " ")
	for word in forbidden:
		if word in ["True", "False"]: continue
		check(word.to_lower() not in blob, "UI text never shows hidden word: " + word)
	for secret in secrets:
		if secret in ["dung", "sai", "cu", "mot_phan", "khong_lien_quan"] or secret.length() > 4:
			var pattern := RegEx.new()
			pattern.compile("(^|[^a-z_])" + secret + "([^a-z_]|$)")
			check(pattern.search(padded) == null, "UI text never shows raw label: " + secret)
	for id in desktop.windows: desktop.close_window(id)

func test_mail(desktop: Control) -> void:
	var mail: Control = desktop.report_window
	desktop.open_window("report")
	check(mail.get_rect().size.x >= 320 and mail.get_rect().size.y >= 260, "Mail window is at least 320x260")
	check(mail.strings.report.to == "To: Ms. Hanh", "Mail is addressed to Ms. Hanh")
	check(desktop.game.question_today().text in mail.subject, "subject is today's question")
	check(mail.submit_button.disabled and not mail.request_submit(), "Send disabled with nothing chosen")
	check(mail.checklist_labels.any(func(l): return l.text == "Pick a forecast") and mail.checklist_labels.any(func(l): return l.text == "Pick confidence"), "checklist names what is missing")
	mail.choose_forecast("tang")
	check(mail.submit_button.disabled, "Send disabled with forecast only")
	check(mail.checklist_labels.any(func(l): return l.text == "Pick confidence"), "checklist still asks for confidence")
	mail.choose_confidence("vua")
	check(not mail.submit_button.disabled, "Send enabled with forecast and confidence")
	check(mail.checklist_labels.any(func(l): return l.text == mail.strings.report.todo_ok), "checklist shows ready")
	# Re-pick freely.
	mail.choose_forecast("giam")
	mail.choose_confidence("cao")
	mail.choose_forecast("ngang")
	check(mail.forecast == "ngang" and mail.confidence == "cao" and mail.forecast_buttons.ngang.button_pressed and not mail.forecast_buttons.giam.button_pressed, "forecast and confidence can be re-picked")
	# Evidence: add from Browser, remove from Mail, add again.
	var uids: Array = desktop.entries.map(func(item): return item.uid)
	check(desktop.toggle_pin(uids[0]) and desktop.toggle_pin(uids[1]), "pin two articles")
	check(mail.evidence.size() == 2 and mail.unpin_buttons.has(uids[0]) and mail.unpin_buttons.has(uids[1]), "Mail lists the pinned evidence with remove buttons")
	check(mail.evidence[0].headline == desktop.entries[0].headline and mail.evidence[0].verification == "chua_kiem_chung", "slot shows headline and verification stamp")
	press(mail.unpin_buttons[uids[0]])
	check(desktop.get_pinned() == [uids[1]] and mail.evidence.size() == 1, "x removes evidence")
	check(desktop.toggle_pin(uids[0]) and desktop.get_pinned() == [uids[1], uids[0]], "removed evidence can be added again")
	desktop.toggle_pin(uids[2])
	check(not desktop.toggle_pin(uids[3]) and desktop.get_pinned().size() == 3, "evidence is capped at 3")
	# The draft survives closing and reopening the window.
	desktop.close_window("report")
	desktop.open_window("report")
	check(mail.forecast == "ngang" and mail.confidence == "cao" and mail.evidence.size() == 3, "draft survives close and reopen")
	# Actions stay editable until Send.
	var cards: Array = mail.cards
	check(cards.size() >= 2 and mail.max_actions == 1, "actions are limited by rank")
	check(mail.toggle_action(cards[0].id) and mail.chosen == [cards[0].id], "pick an action")
	check(not mail.toggle_action(cards[1].id), "second action refused at the rank limit")
	check(mail.toggle_action(cards[0].id) and mail.chosen.is_empty(), "action can be unpicked")
	check(mail.toggle_action(cards[1].id) and mail.chosen == [cards[1].id], "a different action can be picked")
	# Send confirmation: cancel keeps editing, confirm emits the exact input.
	press(mail.submit_button)
	check(mail.confirming and mail.confirm_panel != null and "cannot edit" in mail.strings.report.confirm, "Send asks for confirmation")
	var before: int = submitted.size()
	press(mail.confirm_no)
	check(not mail.confirming and submitted.size() == before and mail.strings.report.no == "Keep editing", "Keep editing returns to the draft")
	check(mail.toggle_action(cards[1].id) and mail.toggle_action(cards[0].id), "still editable after cancelling")
	desktop.toggle_pin(uids[2])
	var expected := {"question_id":desktop.game.question_today().id, "forecast":"ngang", "confidence":"cao", "evidence":desktop.get_pinned(), "actions":[cards[0].id]}
	press(mail.submit_button)
	press(mail.confirm_yes)
	check(submitted.size() == before + 1 and submitted[-1] == expected, "Send emits the exact input: " + str(submitted[-1]) if submitted.size() > before else "Send emitted nothing")
	# After Send the draft is locked (the flow locks the window once the game accepted it).
	mail.lock(true)
	mail.choose_forecast("tang")
	check(mail.forecast == "ngang" and mail.submit_button.disabled and mail.clear_button.disabled and not mail.toggle_action(cards[1].id), "no edits after Send")
	mail.lock(false)
	# Clear all resets the draft including the evidence.
	check(mail.clear_all() and mail.forecast == "" and mail.confidence == "" and mail.chosen.is_empty() and desktop.get_pinned().is_empty(), "Clear all empties the draft and the evidence")
	press(mail.clear_button)
	for id in desktop.windows: desktop.close_window(id)

func test_tray(desktop: Control) -> void:
	var uids: Array = desktop.entries.map(func(item): return item.uid)
	check(desktop.tray_slots.size() == 3 and desktop.tray_slots.all(func(s): return s.uid == "" and s.label.text == strings.tray.empty and s.jump.disabled), "tray starts with three empty slots")
	desktop.toggle_pin(uids[2])
	desktop.toggle_pin(uids[4])
	var tray: Array = desktop.tray_slots
	var first: Dictionary = desktop.entries.filter(func(e): return e.uid == uids[2])[0]
	check(tray[0].uid == uids[2] and tray[0].label.text == first.headline and tray[1].uid == uids[4] and tray[2].uid == "", "tray mirrors the pins")
	check(tray[0].icon.visible and tray[0].icon.texture != null and not tray[2].icon.visible, "tray shows an icon card per pin")
	press(tray[0].jump)
	check(desktop.front == "news" and desktop.selected == uids[2], "tray slot jumps to the article")
	press(tray[0].drop)
	check(desktop.get_pinned() == [uids[4]] and tray[0].uid == uids[4] and tray[1].uid == "", "tray x unpins and the slots shift")
	desktop.toggle_pin(uids[4])
	check(desktop.tray_slots.all(func(s): return s.uid == ""), "tray empties with the pins")
	for id in desktop.windows: desktop.close_window(id)

func test_tutorial() -> void:
	var desktop := make_desktop()
	var coach: Control = desktop.coach
	check(coach.active and coach.current_id() == "question" and coach.bubble.visible, "tutorial starts on day 1")
	check(coach.goals_panel.visible and coach.goals.values().all(func(v): return not v), "goal checklist shows five open goals")
	check(coach.steps.size() == 12 and coach.steps.map(func(s): return int(s.group)).max() == 7, "seven tutorial groups (T-034 adds Files, Sheet, Charts)")
	check(desktop.coach_rect().size.x > 0 or not desktop.is_inside_tree(), "question step has a target")
	check(coach.text_label.text.begins_with("This is today's question"), "Ms. Hanh explains the question")
	# Continue moves on without an action; real actions move on by themselves.
	press(coach.continue_button)
	check(coach.current_id() == "browser", "Continue advances")
	press(desktop.icon_buttons.news)
	check(coach.current_id() == "select" and coach.goals.read, "opening the Browser advances the step and ticks Read news")
	desktop.select_news(desktop.entries[0].uid)
	check(coach.current_id() == "codepad", "selecting an article advances")
	press(desktop.icon_buttons.tools)
	check(coach.current_id() == "check" and "Energy" in coach.text_label.text and "Energy" in strings.tutorial.steps[3].text + strings.tutorial.steps[4].text, "opening Code Pad advances and Energy is explained")
	desktop.use_tool(desktop.game.tools()[0].id)
	check(coach.current_id() == "pin" and coach.goals.verify, "using a tool advances and ticks Verify")
	desktop.open_window("news")
	desktop.toggle_pin(desktop.entries[0].uid)
	check(coach.current_id() == "files" and coach.goals.pin, "pinning advances and ticks Pin")
	press(desktop.icon_buttons.report)
	check(coach.current_id() == "forecast", "opening Mail advances")
	desktop.report_window.choose_forecast("tang")
	check(coach.current_id() == "forecast" and not coach.goals.write, "forecast alone is not enough")
	desktop.report_window.choose_confidence("thap")
	check(coach.current_id() == "send" and coach.goals.write, "forecast and confidence advance and tick Write")
	desktop.report_window.lock(true)
	check(not coach.active and coach.finished and coach.goals.send and not coach.bubble.visible, "Send finishes the tutorial and ticks Send")
	# Help reopens it any time.
	press(desktop.icon_buttons.help)
	check(coach.active and coach.current_id() == "question" and coach.bubble.visible, "Help reopens the tutorial")
	press(coach.skip_button)
	check(not coach.active and coach.skipped and not coach.bubble.visible, "Skip hides the tutorial")
	desktop.select_news(desktop.entries[1].uid)
	check(not coach.active, "a skipped tutorial stays skipped")
	press(desktop.icon_buttons.help)
	check(coach.active, "Help works after Skip")
	# Enter advances like Continue.
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	var step_before: int = coach.step
	desktop._unhandled_input(enter)
	check(coach.step == step_before + 1, "Enter advances the coach")
	# Out-of-order actions skip ahead.
	desktop.open_tutorial()
	desktop.report_window.lock(false)
	desktop.report_window.choose_forecast("giam")
	desktop.report_window.choose_confidence("cao")
	desktop.open_window("report")
	check(coach.current_id() == "send", "doing a later step first skips ahead")
	# Goals widget collapses.
	check(coach.goal_rows.read.holder.visible, "goals expanded by default")
	press(coach.goals_header)
	check(coach.collapsed and not coach.goal_rows.read.holder.visible and coach.goals_panel.size.y < 30, "goals collapse")
	press(coach.goals_header)
	check(not coach.collapsed and coach.goal_rows.read.holder.visible, "goals expand again")
	desktop.queue_free()
	await process_frame
	# Day 3: the goal checklist is gone, the tutorial does not restart, and a skipped run stays skipped.
	desktop = make_desktop(105)
	var game: RefCounted = desktop.game
	desktop.coach.skip()
	for day in 2:
		var report := {"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]}
		check(game.submit_report(report).ok and game.end_day().ok, "day %d played" % (day + 1))
		game.begin_day()
		desktop.start_day()
		check(desktop.coach.goals_panel.visible == (int(game.status().day) <= 2), "goals visible only on days 1-2 (day %d)" % game.status().day)
	check(int(game.status().day) == 3 and not desktop.coach.active and not desktop.coach.goals_panel.visible, "day 3: no tutorial, no checklist")
	check(desktop.front == "news" and "news" in desktop.open_ids, "later days start with the Browser open")
	press(desktop.icon_buttons.help)
	check(desktop.coach.active, "Help still opens the tutorial on day 3")
	desktop.queue_free()
	await process_frame

func run() -> void:
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	root.content_scale_size = Vector2i(640, 360)
	var desktop := make_desktop()
	await process_frame
	check(desktop.front == "" and desktop.home.visible, "desktop opens at home")
	for part in [test_icons, test_news_cards, test_mail, test_tray]:
		part.call(desktop)
		await process_frame
	desktop.queue_free()
	await process_frame
	await test_tutorial()
	# Glossary strings exist and mention the key terms.
	for key in ["trust", "energy", "tier_chinh_thuc", "tier_bao_chi", "tier_mang_xa_hoi", "tier_noi_bo"]: check(strings.glossary.has(key) and strings.glossary[key].length() > 20, "glossary " + key)
	print("test_v2_t021: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

extends SceneTree
# T-021 mouse-driven test: real InputEventMouseButton events (move, press, release) are injected through
# the input system, so clicks reach the buttons exactly as a player's mouse would. Needs a real display:
# run WITHOUT --headless. Add `-- --seed=104 --capture` to save screenshots under docs/screenshots-T-022/.
const Game = preload("res://scripts/world/world_game.gd")
const Flow = preload("res://scripts/v2/game_flow.gd")
const SCREEN := Rect2(0, 0, 640, 360)
var checks := 0
var failures := 0
var flow: Node
var strings: Dictionary
var scale_factor := 2.0
var capture := false

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
	if not capture: return
	await settle(4)
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-022")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("T-022-" + name + ".png"))

# T-024 captures go to their own folder.
func shot_life(name: String) -> void:
	if not capture: return
	await settle(4)
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-024")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("T-024-mouse-" + name + ".png"))

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

# A real click on the centre of a control. The control must be visible and inside the screen.
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

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("test_v2_mouse needs a real display: run it without --headless")
		quit(2)
		return
	capture = "--capture" in OS.get_cmdline_user_args()
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	scale_factor = float(root.size.x) / 640.0
	flow = Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	root.add_child(flow)
	await settle()
	# 1. Title: click Play.
	flow.start_title()
	await settle(6)
	await click(flow.title_view.play_button, "Play")
	check(flow.state == "DAY_START", "Play starts the game by mouse: " + flow.state)
	await settle(4)
	check(flow.commute != null and flow.office == null, "the commute plays after Play")
	for i in 90: flow.commute.advance(0.05)
	await shot("commute-day1")
	await send_mouse(Vector2(320, 180), true)
	await send_mouse(Vector2(320, 180), false)
	await settle(4)
	check(flow.commute == null and flow.office != null, "a mouse click skips the commute")
	# 2. Office: click the desk, then the boss dialog.
	await click(flow.office.desk_button, "desk")
	await pump_office()
	check(flow.office.dialog.visible, "the boss asks the question")
	await click(flow.office.dialog, "dialog")
	check(flow.state == "WORK" and flow.desktop != null, "clicking the dialog starts work")
	var desktop: Control = flow.desktop
	var game: RefCounted = flow.game
	await settle(4)
	await shot("desktop-home")
	check(desktop.front == "" and desktop.home.visible and desktop.coach.active, "work starts on the desktop home with the tutorial")
	# 3. Tutorial by mouse.
	await click(desktop.coach.continue_button, "Continue")
	check(desktop.coach.current_id() == "browser", "Continue moved to the Browser step")
	await click(desktop.icon_buttons.news, "Browser icon")
	check(desktop.front == "news" and desktop.windows.news.visible and desktop.coach.current_id() == "select", "Browser icon opens the Browser and advances the tutorial")
	await shot("tutorial-select-article")
	var uid: String = desktop.entries[0].uid
	var row: Control = desktop.news_window.rows[uid]
	var thumb: Control = desktop.news_window.thumbs[uid]
	check(thumb.is_visible_in_tree() and SCREEN.encloses(thumb.get_global_rect()), "thumbnail visible on the first card")
	await click(row.get_children().filter(func(c): return c is Label and c.get_theme_font_size("font_size") == 12)[0], "headline of the first card")
	check(desktop.selected == uid and desktop.coach.current_id() == "codepad", "clicking a card selects it and advances the tutorial")
	await click(desktop.news_window.more_buttons[uid], "Read more")
	check(desktop.news_window.expanded.get(uid, false), "Read more expands the card")
	await shot("browser-expanded-card")
	await click(desktop.news_window.tools_buttons[uid], "Verify in Code Pad")
	check(desktop.front == "tools" and desktop.coach.current_id() == "check", "the verify shortcut opens Code Pad")
	var energy_before := int(game.status().energy)
	await shot("tutorial-use-tool")
	await click(desktop.tools_window.buttons.values()[0], "Use")
	check(int(game.status().energy) == energy_before - 1 and desktop.coach.goals.verify and desktop.coach.current_id() == "pin", "Use spends one Energy and advances the tutorial")
	# 4. Pin from the Browser via the taskbar and the pin button.
	await click(desktop.task_buttons.news, "Browser taskbar entry")
	check(desktop.front == "news", "taskbar brings the Browser back")
	await click(desktop.news_window.pin_buttons[uid], "Pin")
	check(desktop.get_pinned() == [uid] and desktop.coach.current_id() == "mail", "Pin adds evidence and advances the tutorial")
	check(desktop.tray_slots[0].uid == uid and desktop.tray_slots[0].jump.is_visible_in_tree(), "the evidence tray shows the pin")
	var second: String = desktop.entries[1].uid
	await click(desktop.news_window.pin_buttons[second], "Pin second article")
	check(desktop.get_pinned() == [uid, second], "second pin")
	await shot("evidence-tray")
	# Tray: click the second slot's x to unpin, then pin it again from the Browser.
	await click(desktop.tray_slots[1].drop, "tray x")
	check(desktop.get_pinned() == [uid], "tray x unpins by mouse")
	await click(desktop.news_window.pin_buttons[second], "Pin second article again")
	check(desktop.get_pinned() == [uid, second], "re-pin from the Browser")
	# 5. Mail: write the report.
	await click(desktop.icon_buttons.report, "Mail icon")
	var mail: Control = desktop.report_window
	check(desktop.front == "report" and mail.visible and desktop.coach.current_id() == "forecast", "Mail icon opens Mail")
	check(mail.submit_button.disabled and mail.submit_button.is_visible_in_tree() and SCREEN.encloses(mail.submit_button.get_global_rect()), "Send is visible but disabled")
	await shot("mail-empty")
	await click(mail.forecast_buttons.giam, "forecast Down")
	check(mail.forecast == "giam" and mail.submit_button.disabled, "forecast chosen by mouse, Send still disabled")
	await click(mail.confidence_buttons.vua, "confidence Medium")
	check(mail.confidence == "vua" and not mail.submit_button.disabled and desktop.coach.current_id() == "send", "confidence chosen by mouse, Send enabled")
	await click(mail.forecast_buttons.tang, "forecast Up (change of mind)")
	check(mail.forecast == "tang", "the forecast can be changed")
	await click(mail.action_buttons[mail.cards[0].id], "action 1")
	check(mail.chosen == [mail.cards[0].id], "action picked by mouse")
	await click(mail.action_buttons[mail.cards[0].id], "action 1 again")
	check(mail.chosen.is_empty(), "action unpicked by mouse")
	await click(mail.action_buttons[mail.cards[1].id], "action 2")
	check(mail.chosen == [mail.cards[1].id], "another action picked")
	# Remove evidence in Mail, jump to Browser from the empty slot, add it back, return.
	await click(mail.unpin_buttons[second], "evidence x")
	check(desktop.get_pinned() == [uid] and mail.evidence.size() == 1, "evidence removed from Mail by mouse")
	await click(mail.open_browser_buttons[0], "Open Browser from the empty slot")
	check(desktop.front == "news", "the empty slot opens the Browser")
	await click(desktop.news_window.pin_buttons[second], "Pin second article from the Browser")
	await click(desktop.task_buttons.report, "Mail taskbar entry")
	check(desktop.front == "report" and mail.forecast == "tang" and mail.confidence == "vua" and mail.evidence.size() == 2 and mail.chosen == [mail.cards[1].id], "the draft survived leaving and returning")
	await shot("mail-filled")
	# Clear all, then rebuild the draft.
	await click(mail.clear_button, "Clear all")
	check(mail.forecast == "" and mail.confidence == "" and mail.chosen.is_empty() and desktop.get_pinned().is_empty(), "Clear all resets the draft by mouse")
	await click(desktop.tray_slots[0].jump, "empty tray slot")
	check(desktop.front == "report", "an empty tray slot does nothing")
	await click(desktop.icon_buttons.news, "Browser icon")
	await click(desktop.news_window.pin_buttons[uid], "Pin")
	await click(desktop.icon_buttons.report, "Mail icon")
	await click(mail.forecast_buttons.giam, "forecast Down")
	await click(mail.confidence_buttons.cao, "confidence High")
	# 6. Send: cancel once, then confirm.
	await click(mail.submit_button, "Send")
	check(mail.confirming and mail.confirm_panel != null and flow.state == "WORK", "Send asks for confirmation")
	await shot("mail-confirm")
	await click(mail.confirm_no, "Keep editing")
	check(not mail.confirming and flow.state == "WORK" and mail.forecast == "giam", "Keep editing returns to the draft")
	await click(mail.confidence_buttons.thap, "confidence Low")
	check(mail.confidence == "thap", "still editable after cancelling")
	await click(mail.submit_button, "Send")
	await click(mail.confirm_yes, "Send (confirm)")
	check(flow.state == "REVIEW", "the report is sent by mouse: " + flow.state)
	check(flow.submission.forecast == "giam" and flow.submission.confidence == "thap" and flow.submission.evidence == [uid], "the sent report has the chosen content")
	# 7. Review by mouse until day 2 starts.
	var guard := 0
	while flow.state == "REVIEW" and guard < 40:
		flow.review_view.advance(0.5)
		await settle(1)
		await click(flow.review_view.continue_button, "review Continue")
		guard += 1
	# 7b. T-024: the Evening scene, driven by real clicks.
	check(flow.state == "EVENING", "the review leads to the Evening scene: " + flow.state)
	var evening: Control = flow.evening_view
	var life: RefCounted = flow.life
	check(evening.is_visible_in_tree() and life.wallet >= 100, "the evening shows the wallet with the day's pay")
	await shot_life("evening-start")
	var wallet_before: int = life.wallet
	var mood_before: int = life.mood
	await click(evening.action_buttons.food_noodle_cart, "Buy noodles")
	check(life.wallet == wallet_before - life.food_price("noodle_cart") and life.mood > mood_before and evening.mood_float.visible and evening.stage.emote == "happy", "clicking a street food button spends money and lifts mood")
	await shot_life("food-bought")
	await click(evening.tab_buttons.gold, "Gold tab")
	check(evening.tab == "gold" and evening.action_buttons.has("gold_buy1"), "the Gold tab opens by mouse")
	var units_before: int = life.gold_units
	await click(evening.action_buttons.gold_buy1, "Buy 1 gold")
	check(life.gold_units == units_before + 1, "Buy 1 gold works by mouse")
	await click(evening.action_buttons.gold_sell1, "Sell 1 gold")
	check(life.gold_units == units_before, "Sell 1 gold works by mouse (choices stay editable)")
	await shot_life("gold-tab")
	await click(evening.tab_buttons.savings, "Savings tab")
	await click(evening.action_buttons.deposit_all, "Deposit all")
	check(life.wallet == 0 and life.savings > 0, "Deposit all moves the wallet into savings")
	await click(evening.action_buttons.withdraw_all, "Withdraw all")
	check(life.savings == 0 and life.wallet > 0, "Withdraw all moves it back")
	await click(evening.tab_buttons.property, "Land/House tab")
	check(evening.action_buttons.land_buy.disabled, "land is disabled while the wallet is too small")
	await shot_life("property-tab")
	check(life.net_worth() == life.ledger_total(), "net worth stays consistent after the clicks")
	await click(evening.go_button, "Go home")
	check(flow.state == "DAY_START" and int(game.status().day) == 2, "Go home by mouse starts day 2: " + flow.state)
	check(flow.commute != null, "day 2 starts with the commute")
	await send_mouse(Vector2(320, 180), true)
	await send_mouse(Vector2(320, 180), false)
	await settle(4)
	await pump_office()
	if flow.office.dialog.visible: await click(flow.office.dialog, "dialog day 2")
	if flow.state == "DAY_START":
		await click(flow.office.desk_button, "desk day 2")
		await pump_office()
		if flow.office.dialog.visible: await click(flow.office.dialog, "dialog day 2")
	check(flow.state == "WORK" and flow.desktop.front == "news", "day 2 reaches the desktop with the Browser open: " + flow.state)
	# 8. Window chrome by mouse: minimize and close buttons.
	var window: Control = flow.desktop.windows.news
	var buttons: Array = window.get_children().filter(func(c): return c is Button)
	var minimize: Button = buttons.filter(func(b): return b.tooltip_text == "Minimize")[0]
	var close: Button = buttons.filter(func(b): return b.tooltip_text == "Close")[0]
	await click(minimize, "window minimize")
	check(flow.desktop.front == "" and flow.desktop.task_buttons.news.visible, "minimize button works")
	await click(flow.desktop.icon_buttons.news, "Browser icon")
	check(flow.desktop.front == "news", "icon reopens the minimized window")
	await click(close, "window close")
	check(flow.desktop.front == "" and not flow.desktop.task_buttons.news.visible, "close button works")
	await click(flow.desktop.icon_buttons.help, "Help icon")
	check(flow.desktop.coach.active and flow.desktop.coach.bubble.visible, "Help icon reopens the tutorial by mouse")
	await click(flow.desktop.coach.skip_button, "Skip")
	check(not flow.desktop.coach.active, "Skip button works")
	print("test_v2_mouse: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

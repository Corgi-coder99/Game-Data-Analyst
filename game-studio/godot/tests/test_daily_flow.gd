extends SceneTree
# T-026 headless tests, part 2: the daily-life flow (morning, transport, street, shops, light,
# overtime, sleep) driven through game_flow.gd, plus the new screens' behavior and a source scan.
# Run: --headless -s res://tests/test_daily_flow.gd
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func new_flow(seed_value: int = 7, daily: bool = true) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	node.daily_enabled = daily
	node.commute_enabled = true
	root.add_child(node)
	node.seed_used = seed_value
	node.start_with_game(Game.new(seed_value, 10))
	return node

func drain(flow: Node, limit: int = 4000) -> void:
	var guard := 0
	if flow.state == "COMMUTE": flow.commute.hurry()
	while flow.state == "COMMUTE" and guard < limit:
		guard += 1
		flow.commute.advance(0.1)

func submit(flow: Node, forecast: String = "tang", confidence: String = "vua") -> void:
	var window: Control = flow.desktop.report_window
	window.choose_forecast(forecast)
	window.choose_confidence(confidence)
	window.request_submit()
	window.confirm_submit()

# Plays one whole day with the default choices only (Enter everywhere).
func quick_day(flow: Node) -> void:
	var guard := 0
	while flow.state != "WORK" and flow.state != "END_SCREEN" and guard < 40:
		guard += 1
		match flow.state:
			"DAY_START": flow.skip_intro()
			"COMMUTE": drain(flow)
			_: flow.quick_advance()
	if flow.state != "WORK": return
	submit(flow)
	guard = 0
	while flow.state in ["REVIEW", "SUBMITTED"] and guard < 20:
		guard += 1
		flow.continue_review()

func run() -> void:
	test_order_and_defaults()
	test_quick_mode_full_game()
	test_choices()
	test_shop_and_light()
	test_overtime_and_sleep()
	test_focus_flow()
	test_sick_day_flow()
	test_legacy_flags()
	test_source_scan()
	print("test_daily_flow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_order_and_defaults() -> void:
	var flow := new_flow()
	check(flow.state == "MORNING" and flow.morning_view != null, "a daily game starts in MORNING")
	check(flow.hud_layer.visible and flow.hud.hud_text() == "S80 M70 H90 X20 $60", "HUD is visible in the morning with the starting stats: " + flow.hud.hud_text())
	check(int(flow.game.status().day) == 0, "the world day has not started yet")
	flow.quick_advance()
	check(flow.state == "TRANSPORT", "Enter on breakfast moves to TRANSPORT")
	check(flow.life.wallet == 56 and flow.life.vitals.fed_today, "default breakfast at home cost $4")
	flow.quick_advance()
	check(flow.state == "COMMUTE" and flow.commute.interactive, "Enter on transport starts the COMMUTE")
	check(flow.life.vitals.transport == "bus" and flow.life.wallet == 54, "default transport is the bus ($2)")
	drain(flow)
	check(flow.state == "DAY_START" and int(flow.game.status().day) == 1, "after arriving the work day begins")
	check(flow.visited.slice(0, 5) == ["NEW_GAME", "MORNING", "TRANSPORT", "COMMUTE", "DAY_START"], "state order: " + str(flow.visited))
	check(int(flow.game.status().energy) == 3 and flow.focus_info.bonus == 0, "neutral defaults give Energy 3 (Focus 0)")
	check(int(flow.game.status().minutes) == 510 and flow.late_minutes == 0, "bus with no stops arrives early: the clock starts at 08:30")
	flow.skip_intro()
	check(flow.state == "WORK", "Enter reaches the desktop")
	check(flow.hud_layer.visible and flow.hud.show_focus, "HUD and the Focus line are visible on the desktop")
	submit(flow)
	check(flow.state == "REVIEW", "report goes to REVIEW")
	while flow.state == "REVIEW": flow.continue_review()
	check(flow.state == "OVERTIME", "OVERTIME follows the review")
	check(flow.hud_layer.visible, "HUD visible in OVERTIME")
	flow.quick_advance()
	check(flow.state == "EVENING", "Enter goes home to the EVENING")
	check(flow.life.wallet > 54, "the wage arrived: $%d" % flow.life.wallet)
	flow.evening_view.go_home()
	check(flow.state == "MORNING" and int(flow.game.status().day) == 1, "after the evening a new MORNING starts")
	check(flow.life.vitals.day == 2, "the vitals day moved on")
	flow.queue_free()

func test_quick_mode_full_game() -> void:
	var flow := new_flow(11)
	var days := 0
	var guard := 0
	while flow.state != "END_SCREEN" and guard < 400:
		guard += 1
		match flow.state:
			"EVENING": flow.evening_view.go_home()
			"WORK":
				submit(flow)
				days += 1
			"REVIEW", "SUBMITTED": flow.continue_review()
			"DAY_START": flow.skip_intro()
			"COMMUTE": drain(flow)
			_: flow.quick_advance()
	check(flow.state == "END_SCREEN", "quick mode (Enter only) plays a whole game: " + flow.state)
	check(flow.ending_view.life_lines.size() == 5, "ending shows 5 life lines")
	check(flow.ending_view.summary_lines.any(func(l): return l.begins_with("Final: Stamina")), "ending lists the final vitals")
	check(flow.ending_view.summary_lines.any(func(l): return l.begins_with("Spent:")), "ending lists spending categories")
	check(flow.life.net_worth() == flow.life.ledger_total() and flow.life.wallet >= 0, "money stays consistent")
	check(not flow.hud_layer.visible, "HUD is hidden on the ending")
	flow.queue_free()

func test_choices() -> void:
	var flow := new_flow(5)
	var mo: Control = flow.morning_view
	check(mo.buttons.has("home") and mo.buttons.has("skip") and mo.buttons.has("sleep_in"), "three breakfast buttons")
	mo.choose_breakfast("sleep_in")
	check(flow.life.vitals.slept_in == 15 and flow.life.wallet == 60, "sleep in: later, free")
	for id in ["walk", "bus", "moto", "taxi"]:
		check(mo.buttons.has(id), "transport button " + id)
	mo.choose_transport("taxi")
	check(flow.state == "COMMUTE" and flow.life.wallet == 40, "taxi costs $20")
	drain(flow)
	check(flow.late_minutes == 0, "taxi is fast, so even after sleeping in the player is on time")
	flow.queue_free()
	# A poor player: the expensive options are disabled and tooltips say why.
	var poor := new_flow(6)
	poor.life.charge_up_to(58, "fine", "x")
	poor.morning_view.render()
	check(poor.morning_view.buttons.home.disabled and poor.morning_view.buttons.home.tooltip_text == "Not enough money.", "breakfast disabled with a tooltip")
	check(not poor.morning_view.choose_breakfast("home").ok, "breakfast cannot be bought without money")
	poor.morning_view.choose_breakfast("skip")
	check(poor.morning_view.buttons.taxi.disabled and poor.morning_view.buttons.walk.disabled == false, "taxi disabled, walking free")
	poor.quick_advance()
	check(poor.life.vitals.transport == "bus" and poor.life.wallet == 0, "default transport falls back to what the wallet allows")
	poor.queue_free()
	var broke := new_flow(6)
	broke.life.charge_up_to(60, "fine", "x")
	broke.quick_advance()
	broke.quick_advance()
	check(broke.life.vitals.transport == "walk" and broke.life.wallet == 0, "with $0 the default is to walk")
	broke.queue_free()

func test_shop_and_light() -> void:
	var flow := new_flow(8)
	flow.quick_advance()
	flow.morning_view.choose_transport("walk")
	var commute: Node2D = flow.commute
	check(flow.life.vitals.light_red == (flow.life.vitals.rng_for(1, 1).randf() < 0.65), "the light plan is seeded")
	# Walk to the first shop (cafe) and go in.
	var guard := 0
	while commute.paused == "" and guard < 2000:
		guard += 1
		commute.advance(0.05)
	check(commute.paused == "shop" and commute.current_stop.id == "cafe", "the commute pauses at the first shop door")
	check(commute.prompt_panel.visible, "the prompt is visible")
	var moving: float = commute.player_x
	commute.advance(1.0)
	check(commute.player_x == moving, "the player does not move while the prompt is open")
	var wallet: int = flow.life.wallet
	commute.answer_prompt("enter")
	check(flow.state == "SHOP" and flow.shop_view != null, "Enter opens the shop interior")
	check(flow.life.vitals.extra_minutes == 10, "a shop stop costs 10 minutes")
	var shop: Control = flow.shop_view
	var stamina: int = flow.life.vitals.stamina
	var result: Dictionary = shop.buy("coffee")
	check(result.ok and flow.life.wallet == wallet - 4 and flow.life.vitals.stamina == mini(100, stamina + 10), "coffee: wallet -$4 and stamina +10")
	check(shop.stage.popups.size() > 0 or shop.stage.popup_log.size() > 0, "a -$ popup appears")
	flow.life.charge_up_to(flow.life.wallet, "fine", "x")
	shop.render()
	check(shop.rows.pastry.disabled and shop.rows.pastry.tooltip_text == "Not enough money", "with no money buying is disabled with a tooltip")
	check(not shop.buy("pastry").ok, "cannot overspend")
	shop.leave_shop()
	check(flow.state == "COMMUTE" and commute.paused == "", "leaving the shop resumes the walk")
	# Skip the noodle stall with Enter.
	guard = 0
	while commute.paused == "" and guard < 2000:
		guard += 1
		commute.advance(0.05)
	check(commute.current_stop.id == "noodle", "next stop is the noodle stall")
	commute.default_answer()
	check(commute.paused == "" and flow.life.vitals.extra_minutes == 10, "skipping costs nothing")
	# Walk on to the mart, skip, then a red light (if the seed has one).
	var seen_light := false
	guard = 0
	while flow.state == "COMMUTE" and guard < 6000:
		guard += 1
		commute.advance(0.05)
		if commute.paused == "light":
			seen_light = true
			check(commute.light_state() == "red", "the light is red while the player waits")
			var before: int = flow.life.vitals.extra_minutes
			commute.answer_prompt("wait")
			check(flow.life.vitals.extra_minutes == before + 4, "waiting costs 4 minutes")
		elif commute.paused != "":
			commute.default_answer()
	check(seen_light == flow.life.vitals.light_red, "a red light stop appears exactly when the seeded plan says so")
	check(flow.state == "DAY_START" and flow.late_minutes == 10 + (4 if seen_light else 0), "arrival: walk 40 + one shop stop (+ light wait) is late by %d" % flow.late_minutes)
	check(int(flow.game.status().minutes) == 510 + flow.late_minutes, "the work clock starts %d minutes late" % flow.late_minutes)
	flow.queue_free()
	# Running the red.
	for seed_number in range(1, 80):
		var run := new_flow(seed_number)
		if not run.life.vitals.light_red:
			run.queue_free()
			continue
		run.quick_advance()
		run.morning_view.choose_transport("moto")
		var c: Node2D = run.commute
		var guard2 := 0
		while c.paused != "light" and guard2 < 4000:
			guard2 += 1
			c.advance(0.05)
			if c.paused == "shop": c.default_answer()
		check(c.paused == "light", "moto reaches the light (seed %d)" % seed_number)
		c.answer_prompt("run")
		check(c.paused == "" and c.results.size() == 1 and c.results[0].choice == "run", "running the red resolves at once")
		run.queue_free()
		break

func test_overtime_and_sleep() -> void:
	var flow := new_flow(3)
	quick_day_to_overtime(flow)
	check(flow.state == "OVERTIME", "overtime reached")
	var view: Control = flow.overtime_view
	check(view.buttons.has("go") and view.buttons.has("h1") and view.buttons.has("h3"), "overtime offers 1 to 3 hours")
	var wallet: int = flow.life.wallet
	var stamina: int = flow.life.vitals.stamina
	view.work_overtime(2)
	check(flow.life.wallet == wallet + 28 and flow.life.vitals.stamina == stamina - 16, "2 h: +$28, -16 stamina")
	check(view.phase == "done" and view.buttons.has("continue"), "a result is shown with a Continue button")
	check(flow.state == "OVERTIME", "still in the overtime screen until Continue")
	view.go_home()
	check(flow.state == "EVENING", "Continue leads to the evening")
	var calm: int = flow.life.vitals.stamina
	flow.evening_view.go_home()
	check(flow.life.vitals.overtime_hours == 0 and flow.state == "MORNING", "next morning resets the day counters")
	check(flow.life.vitals.stamina > calm, "sleep restored stamina")
	check(flow.life.last_night.bills_paid == 12, "daily bills were paid")
	flow.queue_free()

func quick_day_to_overtime(flow: Node) -> void:
	var guard := 0
	while flow.state != "OVERTIME" and guard < 60:
		guard += 1
		match flow.state:
			"DAY_START": flow.skip_intro()
			"COMMUTE": drain(flow)
			"WORK": submit(flow)
			"REVIEW", "SUBMITTED": flow.continue_review()
			_: flow.quick_advance()

func test_focus_flow() -> void:
	# Good vitals give +1 Energy, bad vitals -1, shown with a reason.
	var flow := new_flow(4)
	flow.life.vitals.stamina = 95
	flow.life.mood = 85
	flow.life.vitals.stress = 10
	flow.quick_advance()
	flow.morning_view.choose_transport("walk")
	drain(flow)
	check(flow.focus_info.bonus == 1 and int(flow.game.status().energy) == 4, "well fed, happy and rested: Energy 4")
	check(flow.hud.focus_text == "Focus: Well fed and happy: +1 Energy", "the Focus line explains why: " + flow.hud.focus_text)
	flow.queue_free()
	var tired := new_flow(4)
	tired.life.vitals.stamina = 10
	tired.quick_advance()
	tired.morning_view.choose_transport("walk")
	drain(tired)
	check(tired.focus_info.bonus == -1 and int(tired.game.status().energy) == 2, "drained: Energy 2")
	tired.queue_free()

func test_sick_day_flow() -> void:
	var flow := new_flow(9)
	flow.life.vitals.sick_pending = true
	flow.life.vitals.begin_morning(1)
	flow.queue_free()
	var sick := new_flow(9)
	sick.life.vitals.sick_pending = true
	# Re-enter the morning with a sick flag.
	sick.life.vitals.sick_count = 1
	sick._enter_morning()
	check(sick.state == "MORNING" and sick.morning_view.step == "sick", "a sick day shows the sick screen")
	var wallet: int = sick.life.wallet
	sick.quick_advance()
	check(sick.state == "DAY_START" and sick.late_minutes == 30, "the commute is lost: straight to the office, 30 minutes late")
	check(sick.focus_info.reason == "sick" and int(sick.game.status().energy) == 2, "Focus -1 on a sick day")
	check(sick.life.wallet == wallet, "(medical bill was charged when the morning began)")
	check(sick.life.vitals.hr_warning, "the second sick day sets the HR warning")
	sick.skip_intro()
	submit(sick)
	check(sick.review_view.life_note == "HR note: repeated sick days. Please look after yourself.", "the review shows the HR line")
	sick.queue_free()

func test_legacy_flags() -> void:
	var off := new_flow(3, false)
	check(off.state == "DAY_START" and off.life.vitals == null and not off.hud_layer.visible, "daily_enabled = false keeps the old flow")
	off.queue_free()
	var plain: Node = Flow.new()
	plain.autostart = false
	plain.fade_enabled = false
	plain.commute_enabled = false
	root.add_child(plain)
	plain.start_with_game(Game.new(3, 10))
	check(plain.state == "DAY_START" and plain.life.vitals == null, "commute_enabled = false also keeps the old flow")
	plain.queue_free()

func test_source_scan() -> void:
	var forbidden := ["_scenario", "_answers", "root_cause", "_late_plan", "_reviews", ".review(", "hidden", "truth", "volatile"]
	for path in ["res://scripts/life/vitals.gd", "res://scripts/life/hud.gd", "res://scripts/life/morning_scene.gd", "res://scripts/life/shop_panel.gd", "res://scripts/life/overtime_scene.gd", "res://scripts/life/daily_base.gd"]:
		var text := FileAccess.get_file_as_string(path)
		for word in forbidden:
			check(not text.contains(word), "%s does not touch hidden state (%s)" % [path, word])
	var commute := FileAccess.get_file_as_string("res://scripts/v2/commute_scene.gd")
	for word in forbidden:
		check(not commute.contains(word), "commute_scene does not touch hidden state (" + word + ")")
	var flow := FileAccess.get_file_as_string("res://scripts/v2/game_flow.gd")
	check(not flow.contains("_answers") and not flow.contains("root_cause"), "flow does not read hidden labels")

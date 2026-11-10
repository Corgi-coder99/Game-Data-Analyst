extends SceneTree
# T-024 headless tests: the life module (arithmetic, limits, seeded series), the Evening scene
# (skip, popups, actions) and the flow with the evening step. Run: --headless -s res://tests/test_life.gd
const Life = preload("res://scripts/life/life_game.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Flow = preload("res://scripts/v2/game_flow.gd")
const EveningScene = preload("res://scripts/life/evening_scene.gd")
const BOT_GAMES := 1000
var checks := 0
var failures := 0
var strings: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func public_status(day: int, pay: float, trust: float = 46.0, cash: float = 1000.0) -> Dictionary:
	return {"day": day, "horizon": 10, "personal_pay": pay, "trust": trust, "cash_report": cash}

# A life with no random event, so arithmetic is exact.
func quiet_life(seed_value: int = 1) -> RefCounted:
	return Life.new(seed_value, {"events": {"none": 1.0, "lost_wallet": 0.0, "gold_crash": 0.0, "vendor_hike": 0.0, "found_cash": 0.0, "street_fine": 0.0}})

func forced_life(event: String, seed_value: int = 1) -> RefCounted:
	var events := {"none": 0.0, "lost_wallet": 0.0, "gold_crash": 0.0, "vendor_hike": 0.0, "found_cash": 0.0, "street_fine": 0.0}
	events[event] = 1.0
	return Life.new(seed_value, {"events": events})

func consistent(life: RefCounted, label: String) -> void:
	check(life.net_worth() == life.ledger_total(), "%s: net worth %d equals ledger %d" % [label, life.net_worth(), life.ledger_total()])
	check(life.wallet >= 0 and life.savings >= 0 and life.gold_units >= 0 and life.land_value >= 0 and life.house_value >= 0, label + ": nothing negative")

func run() -> void:
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	test_arithmetic()
	test_limits()
	test_series()
	test_events()
	test_sources()
	await test_scene()
	await test_flow()
	test_bots()
	print("test_life: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_arithmetic() -> void:
	var life := quiet_life()
	var opening: Dictionary = life.begin_evening(public_status(1, 100.0))
	check(life.wallet == 100 and opening.events == [{"type": "pay", "amount": 100}], "first evening: pay arrives in the wallet: " + str(opening))
	check(life.begin_evening(public_status(1, 100.0)).has("repeat") and life.wallet == 100, "an evening opens only once")
	consistent(life, "after pay")
	var price: int = life.food_price("noodle_cart")
	var food: Dictionary = life.buy_food("noodle_cart")
	check(food.ok and life.wallet == 100 - price and life.mood == 50 + int(life.item("food", "noodle_cart").mood), "street food costs money and lifts mood")
	check(life.net_worth() == 100 - price, "food lowers net worth by its price")
	consistent(life, "after food")
	# Gold: buy at the price, sell with the fee.
	var gold_price: int = life.gold_price
	var wallet_before: int = life.wallet
	check(life.buy_gold(1).ok and life.wallet == wallet_before - gold_price and life.gold_units == 1, "gold purchase arithmetic")
	var worth: int = life.net_worth()
	var sold: Dictionary = life.sell_gold(1)
	var fee := ceili(float(gold_price) * 0.02)
	check(sold.ok and sold.fee == fee and life.gold_units == 0 and life.net_worth() == worth - fee, "gold sale charges the fee")
	check(not life.sell_gold(5).ok and life.sell_gold(5).error == "holdings", "cannot sell more gold than owned")
	consistent(life, "after gold")
	# Savings.
	var cash: int = life.wallet
	check(life.deposit(30).ok and life.savings == 30 and life.wallet == cash - 30 and life.net_worth() == life.ledger_total(), "deposit moves money")
	check(life.withdraw(10).ok and life.savings == 20 and life.wallet == cash - 20, "withdraw moves money back")
	check(life.withdraw(500).error == "holdings" and life.deposit(100000).error == "funds" and life.deposit(0).error == "amount", "savings errors")
	# Splurge: pure mood.
	var rich := quiet_life()
	rich.begin_evening(public_status(1, 400.0))
	var before: int = rich.net_worth()
	var spent: Dictionary = rich.splurge("gadget")
	check(spent.ok and rich.net_worth() == before - 40 and rich.mood == 70, "splurge costs money, adds mood, returns nothing")
	rich.end_evening()
	check(rich.mood == 64, "mood fades a little each evening: " + str(rich.mood))
	consistent(rich, "after splurge")

func test_limits() -> void:
	var life := quiet_life()
	life.begin_evening(public_status(1, 5000.0))
	var wallet: int = life.wallet
	check(life.buy_land().ok and life.wallet == wallet - 400 and life.land_value == 400, "land purchase")
	check(life.buy_land().error == "limit", "land can be bought only once")
	var land_fee := ceili(400.0 * 0.1)
	var sale: Dictionary = life.sell_land()
	check(sale.ok and sale.fee == land_fee and life.wallet == wallet - land_fee and not life.land_owned, "land sale charges the fee")
	check(life.buy_land().error == "limit", "land cannot be bought again after selling")
	check(life.sell_land().error == "holdings", "nothing to sell")
	check(life.buy_house().ok and life.house_value == 900, "house purchase")
	check(life.buy_house().error == "limit", "house only once")
	consistent(life, "after property")
	# Funds.
	var poor := quiet_life()
	poor.begin_evening(public_status(1, 80.0))
	check(poor.buy_house().error == "funds" and poor.buy_land().error == "funds" and poor.buy_food("rice_roll").ok, "cannot afford property, can afford food")
	check(poor.buy_gold(100).error == "funds" and poor.splurge("holiday").error == "funds", "gold and holiday need funds")
	check(poor.buy_food("nothing").error == "unknown", "unknown item")
	# Appreciation and rent on the next evening.
	var owner := quiet_life()
	owner.begin_evening(public_status(1, 3000.0))
	owner.buy_land()
	owner.buy_house()
	owner.deposit(1000)
	owner.end_evening()
	var wallet_a: int = owner.wallet
	var land_a: int = owner.land_value
	var house_a: int = owner.house_value
	var worth_a: int = owner.net_worth()
	owner.begin_evening(public_status(2, 3000.0))
	check(owner.land_value == land_a + roundi(land_a * 0.015) and owner.house_value == house_a + roundi(house_a * 0.01), "slow appreciation")
	check(owner.wallet == wallet_a + 12 + 10, "rent and savings interest are paid: " + str(owner.wallet - wallet_a))
	check(owner.net_worth() > worth_a - 1, "net worth does not shrink from income")
	consistent(owner, "after appreciation")
	# Pay never takes the wallet below zero.
	var broke := quiet_life()
	broke.begin_evening(public_status(1, 50.0))
	broke.buy_food("rice_roll")
	broke.end_evening()
	broke.begin_evening(public_status(2, 10.0))
	check(broke.wallet >= 0, "a pay drop cannot make the wallet negative")
	consistent(broke, "after pay drop")

func play_series(seed_value: int, trust: float, cash_drop: float) -> Array:
	var life := quiet_life(seed_value)
	var prices: Array = []
	for day in range(1, 10):
		life.begin_evening(public_status(day, 100.0 * day, trust, 1000.0 - cash_drop * day))
		prices.append(life.gold_price)
		life.end_evening()
	return prices

func test_series() -> void:
	check(play_series(7, 46.0, 0.0) == play_series(7, 46.0, 0.0), "the gold series is deterministic for a seed and public state")
	check(play_series(7, 46.0, 0.0) != play_series(8, 46.0, 0.0), "a different seed gives a different series")
	var weak := 0.0
	var strong := 0.0
	for seed_value in 200:
		var w := play_series(seed_value, 20.0, 150.0)
		var s := play_series(seed_value, 80.0, 0.0)
		weak += w.back()
		strong += s.back()
	check(weak > strong + 200.0 * 10.0, "gold tends to rise more when the public state is weak: %.1f vs %.1f" % [weak / 200.0, strong / 200.0])
	var low := 999
	var high := 0
	for seed_value in 100:
		for price in play_series(seed_value, 46.0, 0.0):
			low = mini(low, price)
			high = maxi(high, price)
	check(low >= 20 and high <= 140, "gold stays inside its band")
	var falls := 0
	for seed_value in 100:
		var series := play_series(seed_value, 80.0, 0.0)
		for i in range(1, series.size()):
			if series[i] < series[i - 1]: falls += 1
	check(falls > 50, "gold can also fall: " + str(falls))

func test_events() -> void:
	var lost := forced_life("lost_wallet")
	var opening: Dictionary = lost.begin_evening(public_status(1, 200.0))
	var fines: Array = opening.events.filter(func(e): return e.type == "fine")
	check(opening.event == "lost_wallet" and fines.size() == 1 and fines[0].amount < 0 and lost.wallet == 200 - absi(int(fines[0].amount)), "lost wallet is a visible loss: " + str(opening))
	var fined := forced_life("street_fine")
	var fine_opening: Dictionary = fined.begin_evening(public_status(1, 200.0))
	check(fine_opening.events.any(func(e): return e.type == "fine" and e.amount <= -4 and e.amount >= -12), "street fine is small")
	var found := forced_life("found_cash")
	var found_opening: Dictionary = found.begin_evening(public_status(1, 200.0))
	check(found_opening.events.any(func(e): return e.type == "bonus" and e.amount >= 5), "found cash is a gain")
	var hike := forced_life("vendor_hike")
	hike.begin_evening(public_status(1, 200.0))
	check(hike.food_price("noodle_cart") == 9 and hike.food_price("sweet_soup") == 5, "vendor price hike raises food prices for the evening")
	hike.end_evening()
	check(hike.food_price("noodle_cart") == 6, "prices return to normal")
	var crash := forced_life("gold_crash")
	crash.begin_evening(public_status(1, 400.0))
	crash.buy_gold(4)
	crash.end_evening()
	var worth: int = crash.net_worth()
	var crash_opening: Dictionary = crash.begin_evening(public_status(2, 400.0))
	check(crash.net_worth() < worth + 1 and crash_opening.events.any(func(e): return e.type == "fine"), "a gold crash shows as a loss when gold is held: " + str(crash_opening))
	consistent(crash, "after crash")
	# Real games: over a ten-evening run, losses appear in nearly every seed.
	var with_loss := 0
	for seed_value in 100:
		var life := Life.new(seed_value)
		var seen := false
		for day in range(1, 10):
			var result: Dictionary = life.begin_evening(public_status(day, 120.0 * day))
			if result.events.any(func(e): return e.type == "fine"): seen = true
			life.end_evening()
		if seen: with_loss += 1
	check(with_loss >= 90, "negative cash events appear in real games: %d of 100" % with_loss)

func test_sources() -> void:
	var pattern := RegEx.new()
	pattern.compile("\\.review\\(|\\b(truth|root_cause|states)\\b|\\b_sim\\b|\\b_career\\b|\\b_config\\b|\\b_scenario\\b")
	for filename in DirAccess.get_files_at("res://scripts/life"):
		if not filename.ends_with(".gd"): continue
		check(pattern.search(FileAccess.get_file_as_string("res://scripts/life/" + filename)) == null, filename + " reads no hidden state")
	var diacritics := RegEx.new()
	diacritics.compile("[À-ỹ]")
	for path in ["res://data/life.json", "res://data/strings_v2.json"]:
		check(diacritics.search(FileAccess.get_file_as_string(path)) == null, path + " is English only")

# ---- scene ---------------------------------------------------------------------

func make_scene(life: RefCounted, status: Dictionary) -> Control:
	var scene: Control = EveningScene.new()
	root.add_child(scene)
	scene.open(life, status)
	return scene

func test_scene() -> void:
	var life := forced_life("lost_wallet", 3)
	var scene := make_scene(life, public_status(1, 300.0))
	await process_frame
	var log: Array = scene.stage.popup_log
	check(log.any(func(r): return r.text == "+$300" and r.positive), "pay popup shows +$300: " + str(log))
	check(log.any(func(r): return not r.positive and r.text.begins_with("-$")), "loss popup shows -$ : " + str(log))
	check(scene.stage.emote == "sad", "a loss shows the sad emote")
	check(scene.wallet_label.text == strings.life.wallet % life.wallet and scene.net_label.text == strings.life.net_worth % life.net_worth(), "wallet and net worth are shown")
	var gains := forced_life("found_cash", 3)
	var gain_scene := make_scene(gains, public_status(1, 300.0))
	check(gain_scene.stage.popup_log.any(func(r): return r.positive and r.type == "bonus") and gain_scene.stage.emote == "happy", "a gain shows a green popup and the happy emote")
	# Actions through the scene.
	var wallet: int = life.wallet
	scene.select_tab("food")
	check(scene.action_buttons.has("food_noodle_cart") and not scene.action_buttons["food_noodle_cart"].disabled, "food buttons exist")
	var result: Dictionary = scene.buy_food("noodle_cart")
	check(result.ok and life.wallet == wallet - 6 and scene.mood_float.visible and scene.stage.emote == "happy", "buying street food shows the happy emote and +Mood")
	check(scene.mood_label.text == str(life.mood), "mood meter updates")
	scene.advance(1.1)
	check(not scene.mood_float.visible, "the +Mood float fades away")
	for id in scene.TABS:
		scene.select_tab(id)
		check(scene.menu_body.get_child_count() > 0, "tab renders: " + id)
	scene.select_tab("property")
	var before: int = life.wallet
	scene.buy_property("land")
	check(life.wallet == before, "an unaffordable purchase changes nothing, and says so: " + scene.message)
	# Skip and Go home.
	var seen: Array = []
	scene.finished.connect(func(skipped): seen.append(skipped))
	var ledger_size: int = life.ledger.size()
	scene.skip()
	scene.skip()
	scene.go_home()
	check(seen == [true] and life.ledger.size() == ledger_size, "Skip leaves once and changes nothing")
	var other_scene := make_scene(quiet_life(), public_status(1, 100.0))
	var home: Array = []
	other_scene.finished.connect(func(skipped): home.append(skipped))
	other_scene.go_home()
	check(home == [false], "Go home leaves the evening")
	# Choices stay editable until Go home: sell back what was bought.
	var editable := make_scene(quiet_life(), public_status(1, 1000.0))
	editable.buy_gold(3)
	editable.sell_gold(3)
	editable.deposit(100)
	editable.withdraw(100)
	editable.buy_property("land")
	editable.sell_property("land")
	check(editable.stage.popup_log.filter(func(r): return not r.positive).size() >= 2, "selling shows the fee as a loss popup")
	consistent(editable.life, "after editing choices")
	for node in [scene, gain_scene, other_scene, editable]: node.queue_free()

# ---- flow ----------------------------------------------------------------------

func new_flow(evening: bool) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	node.evening_enabled = evening
	# T-026: these checks cover the T-024 evening on its own; the daily loop has test_daily_flow.
	node.daily_enabled = false
	root.add_child(node)
	return node

# One day with a fixed minimal report. Returns once the review is over.
func work_day(flow: Node) -> void:
	flow.skip_intro()
	var game: RefCounted = flow.game
	var report := {"question_id": game.question_today().id, "forecast": "ngang", "confidence": "thap", "evidence": [], "actions": []}
	var result: Dictionary = flow.submit_report(report)
	check(result.ok, "report accepted: " + str(result))
	var guard := 0
	while flow.state == "REVIEW" and guard < 12:
		flow.continue_review()
		guard += 1

func test_flow() -> void:
	var flow := new_flow(true)
	flow.start_with_game(Game.new(104, 10))
	var evenings := 0
	var days := 0
	var guard := 0
	while flow.state == "DAY_START" and guard < 12:
		guard += 1
		work_day(flow)
		days += 1
		if flow.state == "EVENING":
			evenings += 1
			check(flow.evening_view != null and flow.evening_view.is_visible_in_tree(), "the Evening scene is shown after the review")
			check(flow.life.day == days, "the evening belongs to the finished day")
			if evenings == 1:
				flow.evening_view.buy_food("skewer_stall")
				flow.evening_view.go_home()
			else:
				flow.evening_view.skip()
	check(flow.state == "END_SCREEN", "game ends on the end screen: " + flow.state)
	check(evenings == days - 1 and evenings == 9, "an evening after every day except the last: %d" % evenings)
	var order: Array = ["NEW_GAME"]
	for i in 9: order.append_array(["DAY_START", "WORK", "SUBMITTED", "REVIEW", "EVENING"])
	order.append_array(["DAY_START", "WORK", "SUBMITTED", "REVIEW", "ENDING", "END_SCREEN"])
	check(flow.visited == order, "state order includes EVENING: " + str(flow.visited))
	var status: Dictionary = flow.game.status()
	check(flow.life.net_worth() == flow.life.ledger_total(), "net worth stays consistent through a whole game")
	check(flow.life.wallet >= 0, "wallet never negative")
	check(flow.ending_view.life_lines.size() == 3 and flow.ending_view.summary_lines.has(strings.life.ending_net % flow.life.net_worth()), "the ending summary shows net worth and mood")
	check(flow.life.wallet + flow.life.savings + flow.life.gold_units * flow.life.gold_price + flow.life.land_value + flow.life.house_value == flow.life.net_worth(), "ending net worth adds up")
	check(roundi(float(status.personal_pay)) == flow.life.synced_pay, "all pay reached the wallet by the ending")
	# The score formula is untouched: the same game without the evening gives the same status.
	var plain := new_flow(false)
	plain.start_with_game(Game.new(104, 10))
	guard = 0
	while plain.state == "DAY_START" and guard < 12:
		guard += 1
		work_day(plain)
	var plain_status: Dictionary = plain.game.status()
	check(plain_status.score == status.score and plain_status.personal_pay == status.personal_pay and plain_status.trust == status.trust and plain_status.rank == status.rank, "status().score is identical with and without the evening")
	# Esc skips the evening, in the flow.
	var esc := new_flow(true)
	esc.start_with_game(Game.new(105, 10))
	work_day(esc)
	check(esc.state == "EVENING", "evening reached")
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	esc.evening_view._unhandled_input(key)
	check(esc.state == "DAY_START" and int(esc.game.status().day) == 2, "Esc skips the evening and day 2 begins")
	for node in [flow, plain, esc]: node.queue_free()

# ---- bots ----------------------------------------------------------------------

func test_bots() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 24
	var all_good := true
	var worst := ""
	var losses_seen := 0
	for game_number in BOT_GAMES:
		var life := Life.new(game_number)
		var pay := 0.0
		var trust := 46.0
		var cash := 1000.0
		var bad := ""
		for day in range(1, 11):
			pay += float(rng.randi_range(0, 4) * 60 + 40) if rng.randf() > 0.1 else -float(rng.randi_range(0, 30))
			pay = maxf(pay, 0.0)
			trust = clampf(trust + rng.randf_range(-12.0, 12.0), 0.0, 100.0)
			cash += rng.randf_range(-200.0, 120.0)
			if day == 10:
				life.settle_for_ending(public_status(day, pay, trust, cash))
			else:
				var opening: Dictionary = life.begin_evening(public_status(day, pay, trust, cash))
				for event in opening.events:
					if event.type == "fine": losses_seen += 1
				for step in rng.randi_range(0, 12):
					match rng.randi_range(0, 13):
						0: life.buy_food(["noodle_cart", "skewer_stall", "rice_roll", "sweet_soup"][rng.randi_range(0, 3)])
						1: life.splurge(["gadget", "holiday"][rng.randi_range(0, 1)])
						2: life.buy_gold(rng.randi_range(-1, 6))
						3: life.sell_gold(rng.randi_range(-1, 6))
						4: life.deposit(rng.randi_range(-5, 400))
						5: life.withdraw(rng.randi_range(-5, 400))
						6: life.buy_land()
						7: life.sell_land()
						8: life.buy_house()
						9: life.sell_house()
						10: life.sell_gold(life.gold_units)
						11: life.deposit(life.wallet)
						12: life.withdraw(life.savings)
						_: life.buy_food("rice_roll")
					if life.wallet < 0 or life.savings < 0 or life.gold_units < 0 or life.land_value < 0 or life.house_value < 0 or life.mood < 0 or life.mood > 100:
						bad = "negative or out of range state on game %d day %d" % [game_number, day]
					if life.net_worth() != life.ledger_total():
						bad = "ledger mismatch on game %d day %d: %d vs %d" % [game_number, day, life.net_worth(), life.ledger_total()]
				life.end_evening()
		if life.net_worth() != life.ledger_total() or life.wallet < 0:
			bad = "final mismatch on game %d" % game_number
		if bad != "":
			all_good = false
			worst = bad
			break
	check(all_good, "1000 random-spending games keep every invariant: " + worst)
	check(losses_seen > 500, "the bots saw many loss events: " + str(losses_seen))

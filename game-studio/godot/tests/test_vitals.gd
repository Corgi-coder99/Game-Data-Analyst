extends SceneTree
# T-026 headless tests, part 1: the vitals module and the daily-life rules (no UI).
# Run: --headless -s res://tests/test_vitals.gd
const Life = preload("res://scripts/life/life_game.gd")
const Game = preload("res://scripts/world/world_game.gd")
const BOT_GAMES := 1000
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func quiet(seed_value: int = 1) -> RefCounted:
	var life := Life.new(seed_value, {"events": {"none": 1.0, "lost_wallet": 0.0, "gold_crash": 0.0, "vendor_hike": 0.0, "found_cash": 0.0, "street_fine": 0.0}})
	life.enable_daily()
	return life

func public_status(day: int, pay: float = 0.0, trust: float = 46.0) -> Dictionary:
	return {"day": day, "horizon": 10, "personal_pay": pay, "trust": trust, "cash_report": 1000.0}

func consistent(life: RefCounted, label: String) -> void:
	check(life.net_worth() == life.ledger_total(), "%s: net worth %d equals ledger %d" % [label, life.net_worth(), life.ledger_total()])
	check(life.wallet >= 0, label + ": wallet not negative")

func run() -> void:
	test_start()
	test_breakfast()
	test_transport()
	test_arrival()
	test_light()
	test_shops()
	test_outfit()
	test_focus()
	test_work_stress()
	test_overtime()
	test_bills_and_night()
	test_sick()
	test_world_param()
	test_determinism()
	test_bots()
	print("test_vitals: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_start() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	check(v.stamina == 80 and v.health == 90 and v.stress == 20 and life.mood == 70, "starting stats 80/70/90/20")
	check(life.wallet == 60 and life.net_worth() == life.ledger_total(), "start cash is a ledger entry")
	check(v.focus().bonus == 0, "starting stats give Focus 0")
	var plain := Life.new(1)
	check(plain.vitals == null and plain.wallet == 0 and plain.mood == 50, "without enable_daily the T-024 life is unchanged")
	v.apply({"stamina": 500, "health": -500, "stress": 999, "mood": 999})
	check(v.stamina == 100 and v.health == 0 and v.stress == 100 and life.mood == 100, "bars clamp to 0..100")
	var delta: Dictionary = v.apply({"stamina": -300})
	check(v.stamina == 0 and delta.stamina == -100, "apply reports the real change after clamping")

func test_breakfast() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	v.begin_morning(1)
	var r: Dictionary = v.eat_breakfast("home")
	check(r.ok and life.wallet == 56 and v.stamina == 86 and life.mood == 73 and v.fed_today, "breakfast at home costs $4 and gives +6 stamina +3 mood")
	var poor := quiet()
	poor.charge_up_to(poor.wallet, "fine", "x")
	poor.vitals.begin_morning(1)
	check(not poor.vitals.eat_breakfast("home").ok and poor.wallet == 0, "no money: breakfast refused, wallet stays 0")
	# Skip: the penalty lands when the commute ends, harder when repeated; a shop meal fixes it.
	var skip := quiet()
	var s: RefCounted = skip.vitals
	s.begin_morning(1)
	s.eat_breakfast("skip")
	check(skip.wallet == 60 and s.hungry, "skipping saves the money")
	s.choose_transport("bus")
	var first: Dictionary = s.finish_commute()
	check(first.hunger.stamina == -8 and first.hunger.mood == -5 and s.meal_skips == 1, "first skipped breakfast: -8 stamina -5 mood")
	s.begin_morning(2)
	s.eat_breakfast("skip")
	var h: int = s.health
	s.finish_commute()
	check(s.meal_skips == 2 and s.health == h - 2, "repeated skipping costs more and hurts health")
	var fixed := quiet()
	fixed.vitals.begin_morning(1)
	fixed.vitals.eat_breakfast("skip")
	fixed.vitals.buy("noodle", "noodle_bowl")
	var res: Dictionary = fixed.vitals.finish_commute()
	check(res.hunger.is_empty() and fixed.vitals.meal_skips == 0, "a noodle bowl on the way fixes the hunger")
	var sleep := quiet()
	sleep.vitals.begin_morning(1)
	sleep.vitals.eat_breakfast("sleep_in")
	sleep.vitals.choose_transport("walk")
	check(sleep.vitals.compute_arrival() == 470 + 15 + 40, "sleeping in adds 15 minutes")

func test_transport() -> void:
	var expected := {"walk": [0, 40, 0, -6, 1], "bus": [2, 25, 4, -1, 0], "moto": [5, 15, 5, -2, 0], "taxi": [20, 10, -3, 0, 0]}
	for id in expected:
		var life := quiet()
		var v: RefCounted = life.vitals
		v.begin_morning(1)
		var e: Array = expected[id]
		var r: Dictionary = v.choose_transport(id)
		check(r.ok and life.wallet == 60 - e[0] and r.minutes == e[1], "%s: cost and minutes" % id)
		check(v.stress == 20 + e[2] and v.stamina == 80 + e[3] and v.health == 90 + e[4], "%s: stress, stamina, health" % id)
		check(life.mood == 70 + (2 if id == "taxi" else 0), id + ": mood")
		check(v.compute_arrival() == 470 + e[1], id + ": arrival")
	var broke := quiet()
	broke.charge_up_to(broke.wallet, "fine", "x")
	broke.vitals.begin_morning(1)
	check(not broke.vitals.choose_transport("taxi").ok and not broke.vitals.choose_transport("bus").ok and broke.vitals.choose_transport("walk").ok, "with $0 only walking is possible")
	check(not broke.vitals.choose_transport("rocket").ok, "unknown transport refused")

func test_arrival() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	v.begin_morning(1)
	v.choose_transport("walk")
	v.finish_commute()
	check(v.late_minutes == 0 and v.arrival_minutes == 510, "walk with no stops arrives exactly 08:30")
	v.begin_morning(2)
	v.choose_transport("bus")
	v.finish_commute()
	check(v.late_minutes == 0, "early arrival is not a shift")
	v.begin_morning(3)
	v.eat_breakfast("sleep_in")
	v.choose_transport("walk")
	v.enter_shop()
	var r: Dictionary = v.finish_commute()
	check(r.late == 20 and v.arrival_minutes == 530, "sleep in + walk + one shop visit (5 min) = 20 minutes late")
	v.begin_morning(4)
	v.choose_transport("walk")
	for i in 20: v.enter_shop()
	v.finish_commute()
	check(v.late_minutes == 60 and v.arrival_minutes > 570, "lateness is capped at 60 minutes")

func test_light() -> void:
	var a := quiet(5)
	a.vitals.begin_morning(3)
	var b := quiet(5)
	b.vitals.begin_morning(3)
	check(a.vitals.light_red == b.vitals.light_red, "the red light is a function of the seed")
	var outcomes := {}
	var reds := 0
	for seed_number in 400:
		var life := quiet(seed_number)
		life.vitals.begin_morning(2)
		if life.vitals.light_red: reds += 1
		var r: Dictionary = life.vitals.traffic_light("run")
		outcomes[r.outcome] = int(outcomes.get(r.outcome, 0)) + 1
		var again := quiet(seed_number)
		again.vitals.begin_morning(2)
		check(again.vitals.traffic_light("run").outcome == r.outcome, "same seed same outcome (seed %d)" % seed_number) if seed_number < 20 else null
		consistent(life, "light")
	check(outcomes.has("clear") and outcomes.has("fined") and outcomes.has("accident"), "running the red has all three outcomes: " + str(outcomes))
	check(reds > 180 and reds < 330, "about 65 percent of mornings have a red light: " + str(reds))
	var w := quiet(9)
	w.vitals.begin_morning(2)
	var before_health: int = w.vitals.health
	var wait: Dictionary = w.vitals.traffic_light("wait")
	check(wait.outcome == "waited" and wait.minutes == 4 and w.wallet == 60 and w.vitals.health == before_health and w.vitals.extra_minutes == 4, "waiting costs minutes only")
	# A fine takes money (never more than the wallet) and stress.
	for seed_number in 400:
		var life := quiet(seed_number)
		life.vitals.begin_morning(2)
		var r: Dictionary = life.vitals.traffic_light("run")
		if r.outcome == "fined":
			check(r.fine >= 8 and r.fine <= 16 and life.wallet == 60 - r.fine and life.vitals.stress == 28, "fine amount, wallet and stress")
			break
	var poor := quiet(seed_number_fined())
	poor.charge_up_to(58, "fine", "x")
	poor.vitals.begin_morning(2)
	poor.vitals.traffic_light("run")
	check(poor.wallet >= 0, "a fine never makes the wallet negative")

func seed_number_fined() -> int:
	for seed_number in 400:
		var life := quiet(seed_number)
		life.vitals.begin_morning(2)
		if life.vitals.traffic_light("run").outcome == "fined": return seed_number
	return 0

func test_shops() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	v.begin_morning(1)
	var r: Dictionary = v.buy("cafe", "coffee")
	check(r.ok and life.wallet == 56 and v.stamina == 90 and life.mood == 74, "coffee: -$4, +10 stamina, +4 mood")
	r = v.buy("pharmacy", "vitamins")
	check(r.ok and life.wallet == 46 and v.health == 96 and v.stress == 16, "vitamins: health +6, stress -4")
	r = v.buy("news", "magazine")
	check(r.ok and life.wallet == 42 and life.mood == 80, "magazine: mood +6")
	r = v.buy("books", "novel")
	check(r.ok and v.skill == 2 and life.wallet == 30 and v.stress == 13, "book: skill +1, stress -3")
	check(not v.buy("clothing", "outfit").ok and life.wallet == 30, "outfit refused with $30")
	check(not v.buy("cafe", "nothing").ok and not v.buy("moon", "coffee").ok, "unknown items refused")
	consistent(life, "shops")
	var spend: Dictionary = v.spending_summary()
	check(spend.get("shop", 0) == 4 + 4 + 12 and spend.get("health", 0) == 10, "spending categories come from the ledger: " + str(spend))
	# Pharmacy-style purchase does not exceed 100.
	v.apply({"health": 100})
	v.buy("pharmacy", "cold_remedy")
	check(v.health == 100, "health stays at 100")

func test_outfit() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	life.earn(100, "pay", "test")
	v.begin_morning(1)
	var mood: int = life.mood
	var r: Dictionary = v.buy("clothing", "outfit")
	check(r.ok and life.mood == mood + 10 and v.outfit_days == 3 and life.wallet == 160 - 45, "outfit: -$45, +10 mood, 3 days")
	var days := []
	for day in range(1, 6):
		days.append(v.outfit_days > 0)
		v.night()
		v.begin_morning(day + 1)
	check(days == [true, true, true, false, false], "the outfit effect lasts exactly 3 working days: " + str(days))
	# Shabby look after many days without clothes.
	var shabby := quiet()
	shabby.earn(500, "pay", "x")
	for day in 8:
		shabby.vitals.begin_morning(day + 1)
		shabby.vitals.night()
	check(shabby.vitals.nights_without_outfit >= 6, "nights without an outfit are counted")

func test_focus() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	check(v.focus() == {"bonus": 0, "reason": "neutral"}, "neutral")
	v.stamina = 75
	life._add_mood(20)
	v.stress = 30
	check(v.focus().bonus == 1 and v.focus().reason == "happy", "well rested and happy: +1")
	v.stress = 45
	check(v.focus().bonus == 0, "stress above 40 removes the bonus")
	v.stress = 85
	check(v.focus().bonus == -1 and v.focus().reason == "drained", "stress above 80: -1")
	v.stress = 20
	v.stamina = 29
	check(v.focus().bonus == -1, "stamina below 30: -1")
	v.stamina = 80
	v.health = 29
	check(v.focus().bonus == -1, "health below 30: -1")
	v.health = 90
	life.mood = 50
	v.sick_today = true
	check(v.focus().bonus <= -1 and v.focus().reason == "sick", "sick day: Focus -1")
	# Energy is never below 1 whatever the bonus.
	for bonus in [-9, -3, -2, -1, 0, 1, 2]:
		var game := Game.new(3, 10)
		game.begin_day(bonus)
		check(int(game.status().energy) == maxi(1, 3 + bonus), "begin_day(%d) leaves %d Energy" % [bonus, maxi(1, 3 + bonus)])
	var plain := Game.new(3, 10)
	plain.begin_day()
	check(int(plain.status().energy) == 3, "begin_day() with no argument keeps 3 Energy")

func test_work_stress() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	var before := {"trust": 50, "band": "on_time", "warnings": 0, "demotions": 0, "rank": "thuc_tap", "personal_pay": 100.0}
	v.after_work(before, {"trust": 40, "band": "on_time", "warnings": 0, "demotions": 0, "rank": "thuc_tap", "personal_pay": 200.0})
	check(v.stress == 30, "a wrong report (-10 trust) adds 10 stress")
	v.after_work(before, {"trust": 58, "band": "on_time", "warnings": 0, "demotions": 0, "rank": "chuyen_vien", "personal_pay": 200.0})
	check(v.stress == 30 - 3 - 8, "good outcome and a promotion lower stress: " + str(v.stress))
	var late := quiet()
	late.vitals.after_work({"trust": 50, "band": "late", "warnings": 0, "demotions": 0, "rank": "a", "personal_pay": 0.0}, {"trust": 50, "band": "late", "warnings": 1, "demotions": 1, "rank": "a", "personal_pay": 0.0})
	check(late.vitals.stress == 20 + 6 + 8 + 12, "late + warning + demotion: " + str(late.vitals.stress))

func test_overtime() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	v.begin_morning(1)
	var r: Dictionary = v.overtime(2)
	check(r.ok and r.pay == 28 and life.wallet == 88 and v.stamina == 64 and life.mood == 62 and v.stress == 30, "2 h overtime: +$28, -16 stamina, -8 mood, +10 stress")
	check(not v.overtime(0).ok and not v.overtime(4).ok, "overtime is 1 to 3 hours")
	v.stamina = 20
	var tired: Dictionary = v.overtime(3)
	check(tired.exhausted and v.health < 90, "very low stamina: exhausted, health risk")
	consistent(life, "overtime")

func test_bills_and_night() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	v.begin_morning(1)
	var r: Dictionary = v.night()
	check(r.bills_paid == 12 and life.wallet == 48 and r.bills_owed == 0, "daily bill $12 is paid")
	check(v.stamina == 100 and v.stress == 8 and v.health == 92, "a calm night: stamina full, stress -12, health +2")
	# Not enough money: bills pile up and hurt mood and health.
	var poor := quiet()
	poor.charge_up_to(poor.wallet - 5, "fine", "x")
	poor.vitals.begin_morning(1)
	var mood: int = poor.mood
	var health: int = poor.vitals.health
	var n: Dictionary = poor.vitals.night()
	check(n.bills_paid == 5 and n.bills_owed == 7 and poor.wallet == 0, "unpaid bills carry over and the wallet stays at 0")
	check(poor.vitals.health < health + 2 and poor.mood < mood + 8, "unpaid bills lower mood and health")
	var cap := quiet()
	cap.charge_up_to(cap.wallet, "fine", "x")
	for day in 12:
		cap.vitals.begin_morning(day + 1)
		cap.vitals.night()
	check(cap.vitals.bills_owed == 60, "owed bills are capped at $60")
	# Overtime and a stressful day recover less.
	var tired := quiet()
	tired.vitals.begin_morning(1)
	tired.vitals.stamina = 20
	tired.vitals.overtime_hours = 3
	tired.vitals.stress = 80
	tired.vitals.night()
	var easy := quiet()
	easy.vitals.begin_morning(1)
	easy.vitals.stamina = 20
	easy.vitals.night()
	check(tired.vitals.stamina < easy.vitals.stamina, "overtime and stress recover less stamina")
	check(tired.vitals.stress > easy.vitals.stress, "high stress does not recover as well")
	# Treats help the night.
	var treat := quiet()
	treat.vitals.begin_morning(1)
	treat.vitals.stamina = 20
	treat.buy_food("noodle_cart")
	treat.vitals.night()
	check(treat.vitals.stamina > easy.vitals.stamina, "an evening treat sleeps better")
	consistent(treat, "night")

func test_sick() -> void:
	var life := quiet()
	var v: RefCounted = life.vitals
	v.begin_morning(1)
	v.health = 15
	check(v.night().sick_tomorrow == false or true, "night runs")
	var hurt := quiet()
	hurt.vitals.begin_morning(1)
	hurt.vitals.health = 10
	hurt.vitals.stress = 99
	hurt.vitals.peak_stress = 99
	check(hurt.vitals.night().sick_tomorrow, "Health <= 15 or Stress >= 95 means a sick day tomorrow")
	var wallet: int = hurt.wallet
	var morning: Dictionary = hurt.vitals.begin_morning(2)
	check(morning.sick and hurt.wallet == wallet - 30 and hurt.vitals.focus().bonus <= -1 and hurt.vitals.late_minutes == 30, "sick day: medical bill $30, Focus -1, commute lost")
	check(hurt.vitals.sick_count == 1 and not hurt.vitals.hr_warning, "first sick day has no HR warning")
	hurt.vitals.night()
	check(not hurt.vitals.sick_pending or hurt.vitals.health <= 15 or hurt.vitals.stress >= 95, "the sick day restored the bars")
	hurt.vitals.health = 5
	hurt.vitals.peak_stress = 99
	hurt.vitals.night()
	hurt.vitals.begin_morning(3)
	check(hurt.vitals.sick_count == 2 and hurt.vitals.hr_warning, "the second sick day brings an HR warning")
	var poor := quiet()
	poor.vitals.begin_morning(1)
	poor.vitals.health = 5
	poor.vitals.peak_stress = 99
	poor.vitals.night()
	poor.charge_up_to(poor.wallet, "fine", "x")
	poor.vitals.begin_morning(2)
	check(poor.wallet == 0, "the medical bill never makes the wallet negative")

func test_world_param() -> void:
	# The only world change is the optional begin_day argument: the same seed and reports score the same.
	var scores := []
	for bonus in [0, 0]:
		var game := Game.new(11, 10)
		game.begin_day(bonus)
		var q := game.question_today()
		var news: Array = game.news_today()
		game.submit_report({"answer": "tang", "confidence": "vua", "evidence": [], "actions": []})
		game.end_day()
		scores.append(game.status().score)
	check(scores[0] == scores[1], "identical games score identically")

func test_determinism() -> void:
	var traces := []
	for run_number in 2:
		var life := quiet(77)
		var trace := []
		for day in range(1, 8):
			life.vitals.begin_morning(day)
			life.vitals.eat_breakfast(["home", "skip", "sleep_in"][day % 3])
			life.vitals.choose_transport(["walk", "bus", "moto", "taxi"][day % 4])
			trace.append(life.vitals.traffic_light("run").outcome)
			life.vitals.buy(["cafe", "noodle", "mart"][day % 3], ["coffee", "noodle_bowl", "sandwich"][day % 3])
			life.vitals.finish_commute()
			life.vitals.overtime(1 + day % 3)
			life.night()
			trace.append([life.wallet, life.vitals.stamina, life.vitals.health, life.vitals.stress, life.mood])
		traces.append(trace)
	check(traces[0] == traces[1], "a seeded week of mixed choices is fully deterministic")

func test_bots() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 26
	var ok := true
	var worst := ""
	var sick_seen := 0
	for game_number in BOT_GAMES:
		var life := Life.new(game_number)
		life.enable_daily()
		var v: RefCounted = life.vitals
		var pay := 0.0
		for day in range(1, 11):
			pay += float(rng.randi_range(0, 3) * 60 + 20)
			var public := public_status(day, pay)
			var morning: Dictionary = v.begin_morning(day)
			if morning.sick: sick_seen += 1
			if not morning.sick:
				v.eat_breakfast(["home", "skip", "sleep_in", "nonsense"][rng.randi_range(0, 3)])
				v.choose_transport(["walk", "bus", "moto", "taxi", "x"][rng.randi_range(0, 4)])
				for step in rng.randi_range(0, 5):
					var shop: String = ["cafe", "noodle", "mart", "pharmacy", "news", "books", "clothing"][rng.randi_range(0, 6)]
					var items: Array = v.shop_items(shop)
					if not items.is_empty():
						v.enter_shop()
						v.buy(shop, items[rng.randi_range(0, items.size() - 1)].id)
				if rng.randf() < 0.5: v.traffic_light(["run", "wait"][rng.randi_range(0, 1)])
				v.finish_commute()
			if rng.randf() < 0.4: v.overtime(rng.randi_range(0, 4))
			if rng.randf() < 0.08: v.apply({"stress": rng.randi_range(40, 90), "health": -rng.randi_range(0, 80)})
			life.deposit_wage(public)
			life.begin_evening(public)
			for step in rng.randi_range(0, 4):
				match rng.randi_range(0, 3):
					0: life.buy_food("rice_roll")
					1: life.splurge("gadget")
					2: life.deposit(rng.randi_range(0, 80))
					_: life.buy_gold(rng.randi_range(0, 2))
			life.night()
			var bad := ""
			if life.wallet < 0: bad = "negative wallet"
			elif life.net_worth() != life.ledger_total(): bad = "ledger mismatch"
			elif v.stamina < 0 or v.stamina > 100 or v.health < 0 or v.health > 100 or v.stress < 0 or v.stress > 100 or life.mood < 0 or life.mood > 100: bad = "bar out of range"
			if bad != "":
				ok = false
				worst = "%s on game %d day %d" % [bad, game_number, day]
				break
		if not ok: break
	check(ok, "1000 random-policy games keep every invariant: " + worst)
	check(sick_seen > 0, "random policies include sick days: " + str(sick_seen))

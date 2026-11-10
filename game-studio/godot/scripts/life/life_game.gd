extends RefCounted
# T-024: the after-work life. A separate module: it only READS the public status of the world game
# (personal_pay, trust, cash_report, day) and never touches the simulation. All money is whole
# dollars. Every change of net worth is written to `ledger`, so net_worth() == sum of the ledger.
# Every random draw comes from a generator seeded by (seed, day), so a series is reproducible.
const CONFIG_PATH := "res://data/life.json"
var config: Dictionary
var seed_value := 0
var wallet := 0
var savings := 0
var gold_units := 0
var gold_price := 0
var gold_prev := 0
var land_value := 0
var house_value := 0
var land_owned := false
var house_owned := false
var land_bought := false
var house_bought := false
var mood := 0
var synced_pay := 0
var ref_cash := -INF
var day := 0
var evening_open := false
var food_factor := 1.0
var event_id := ""
var ledger: Array = []
var last_weakness := 0.0

func _init(seed_number: int = 0, overrides: Dictionary = {}) -> void:
	seed_value = seed_number
	config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	for key in overrides:
		if config.get(key) is Dictionary and overrides[key] is Dictionary:
			for inner in overrides[key]: config[key][inner] = overrides[key][inner]
		else:
			config[key] = overrides[key]
	mood = int(config.mood.start)
	gold_price = int(config.gold.start_price)
	gold_prev = gold_price

func _record(kind: String, delta: int, note: String = "") -> void:
	ledger.append({"day": day, "kind": kind, "delta": delta, "note": note})

func rng_for(day_number: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 100003 + day_number * 7919 + 13
	return rng

# ---- numbers ----------------------------------------------------------------

func gold_value() -> int:
	return gold_units * gold_price

func net_worth() -> int:
	return wallet + savings + gold_value() + land_value + house_value

func ledger_total() -> int:
	var total := 0
	for entry in ledger: total += int(entry.delta)
	return total

func mood_band() -> String:
	if mood >= int(config.mood.high): return "high"
	if mood <= int(config.mood.low): return "low"
	return "mid"

# 0..1, built from public values only: low trust and a falling company cash report.
func weakness(public: Dictionary) -> float:
	var w: Dictionary = config.weakness
	var trust_part := clampf((float(w.trust_ref) - float(public.get("trust", w.trust_ref))) / float(w.trust_span), 0.0, 1.0)
	var cash := float(public.get("cash_report", 0.0))
	var cash_part := 0.0
	if ref_cash > -INF:
		cash_part = clampf((ref_cash - cash) / maxf(absf(ref_cash), 1.0) / float(w.cash_span), 0.0, 1.0)
	return clampf(trust_part * float(w.trust_weight) + cash_part * float(w.cash_weight), 0.0, 1.0)

func food_price(id: String) -> int:
	for item in config.food:
		if item.id == id: return ceili(float(item.price) * food_factor)
	return -1

func item(list_name: String, id: String) -> Dictionary:
	for entry in config[list_name]:
		if entry.id == id: return entry
	return {}

# Public pay not yet in the wallet, as a net worth change that cannot push the wallet below zero.
func pending_pay(public: Dictionary) -> int:
	var delta := roundi(float(public.get("personal_pay", 0.0))) - synced_pay
	return maxi(delta, -wallet)

func projected_net_worth(public: Dictionary) -> int:
	return net_worth() + pending_pay(public)

# ---- the evening -------------------------------------------------------------

# Pay arrives, interest and rent are paid, prices move, one seeded event may happen. Returns
# {"events": [{"type": "pay"|"bonus"|"fine", "amount": n}], "event": id, "message_key": id}.
# Calling it twice for the same evening does nothing the second time.
func begin_evening(public: Dictionary) -> Dictionary:
	if evening_open: return {"events": [], "event": "", "repeat": true}
	evening_open = true
	day = int(public.get("day", day + 1))
	var rng := rng_for(day)
	food_factor = 1.0
	var pay := _settle_pay(public)
	var bonus := 0
	var fine := 0
	# Interest and rent.
	var interest := int(floor(float(savings) * float(config.savings.daily_rate)))
	if interest > 0:
		wallet += interest
		bonus += interest
		_record("interest", interest)
	if house_owned:
		var rent := int(config.house.rent)
		wallet += rent
		bonus += rent
		_record("rent", rent)
	# Slow appreciation (a gain in net worth that never touches the wallet).
	if land_owned:
		var gain := roundi(float(land_value) * float(config.land.daily_rate))
		land_value += gain
		_record("land_value", gain)
	if house_owned:
		var gain := roundi(float(house_value) * float(config.house.daily_rate))
		house_value += gain
		_record("house_value", gain)
	# Gold follows a seeded series that leans upward when the public company state is weak.
	last_weakness = weakness(public)
	var cash := float(public.get("cash_report", 0.0))
	if cash > ref_cash: ref_cash = cash
	var g: Dictionary = config.gold
	gold_prev = gold_price
	var noise := rng.randf() * 2.0 - 1.0
	var step := float(g.drift) + last_weakness * float(g.weak_drift) + noise * float(g.volatility)
	_move_gold(clampi(roundi(float(gold_price) * (1.0 + step)), int(g.min_price), int(g.max_price)))
	# One event at most.
	event_id = _roll_event(rng.randf())
	var param_roll := rng.randf()
	var params: Dictionary = config.event_params.get(event_id, {})
	match event_id:
		"lost_wallet":
			var loss := mini(wallet, clampi(roundi(float(wallet) * float(params.fraction)), int(params.min), int(params.max)))
			if loss > 0:
				wallet -= loss
				fine += loss
				_record("event", -loss, event_id)
			else:
				event_id = ""
		"street_fine":
			var loss := mini(wallet, int(params.min) + int(floor(param_roll * float(int(params.max) - int(params.min) + 1))))
			if loss > 0:
				wallet -= loss
				fine += loss
				_record("event", -loss, event_id)
			else:
				event_id = ""
		"found_cash":
			var found := int(params.min) + int(floor(param_roll * float(int(params.max) - int(params.min) + 1)))
			wallet += found
			bonus += found
			_record("event", found, event_id)
		"vendor_hike":
			food_factor = float(params.factor)
		"gold_crash":
			var crashed := maxi(int(g.min_price), roundi(float(gold_price) * float(g.crash_factor)))
			var lost := gold_units * (gold_price - crashed)
			_move_gold(crashed)
			fine += lost
	var events: Array = []
	if pay > 0: events.append({"type": "pay", "amount": pay})
	if bonus > 0: events.append({"type": "bonus", "amount": bonus})
	if fine > 0: events.append({"type": "fine", "amount": -fine})
	return {"events": events, "event": event_id}

func _roll_event(roll: float) -> String:
	var total := 0.0
	for key in config.events: total += float(config.events[key])
	var cursor := 0.0
	for key in config.events:
		cursor += float(config.events[key]) / total
		if roll < cursor: return "" if key == "none" else str(key)
	return ""

func _move_gold(new_price: int) -> void:
	if new_price == gold_price: return
	var delta := gold_units * (new_price - gold_price)
	gold_price = new_price
	if delta != 0: _record("gold_price", delta)

# Adds the public pay that is not in the wallet yet. Returns the amount that arrived.
func _settle_pay(public: Dictionary) -> int:
	var now := roundi(float(public.get("personal_pay", 0.0)))
	var delta := now - synced_pay
	synced_pay = now
	if delta >= 0:
		wallet += delta
		if delta != 0: _record("pay", delta)
		return delta
	var applied := mini(wallet, -delta)
	wallet -= applied
	if applied > 0: _record("pay", -applied)
	return 0

# Used by the ending: brings the wallet up to date without an evening.
func settle_for_ending(public: Dictionary) -> void:
	day = int(public.get("day", day))
	_settle_pay(public)
	if float(public.get("cash_report", -INF)) > ref_cash: ref_cash = float(public.cash_report)

func end_evening() -> void:
	if not evening_open: return
	evening_open = false
	mood = clampi(mood - int(config.mood.evening_decay), 0, int(config.mood.max))
	food_factor = 1.0

func _fail(code: String) -> Dictionary:
	return {"ok": false, "error": code}

func _spend(price: int, kind: String, note: String) -> void:
	wallet -= price
	_record(kind, -price, note)

func _add_mood(amount: int) -> int:
	var before := mood
	mood = clampi(mood + amount, 0, int(config.mood.max))
	return mood - before

# ---- actions ------------------------------------------------------------------

func buy_food(id: String) -> Dictionary:
	var entry := item("food", id)
	if entry.is_empty(): return _fail("unknown")
	var price := food_price(id)
	if wallet < price: return _fail("funds")
	_spend(price, "food", id)
	return {"ok": true, "cost": price, "mood": _add_mood(int(entry.mood))}

func splurge(id: String) -> Dictionary:
	var entry := item("splurge", id)
	if entry.is_empty(): return _fail("unknown")
	var price := int(entry.price)
	if wallet < price: return _fail("funds")
	_spend(price, "splurge", id)
	return {"ok": true, "cost": price, "mood": _add_mood(int(entry.mood))}

func buy_gold(units: int = 1) -> Dictionary:
	if units <= 0: return _fail("amount")
	var cost := units * gold_price
	if wallet < cost: return _fail("funds")
	wallet -= cost
	gold_units += units
	return {"ok": true, "cost": cost, "fee": 0}

func sell_gold(units: int = 1) -> Dictionary:
	if units <= 0: return _fail("amount")
	if gold_units < units: return _fail("holdings")
	var gross := units * gold_price
	var fee := ceili(float(gross) * float(config.gold.sell_fee))
	gold_units -= units
	wallet += gross - fee
	if fee > 0: _record("fee", -fee, "gold")
	return {"ok": true, "gross": gross, "fee": fee}

func deposit(amount: int) -> Dictionary:
	if amount <= 0: return _fail("amount")
	if wallet < amount: return _fail("funds")
	wallet -= amount
	savings += amount
	return {"ok": true}

func withdraw(amount: int) -> Dictionary:
	if amount <= 0: return _fail("amount")
	if savings < amount: return _fail("holdings")
	savings -= amount
	wallet += amount
	return {"ok": true}

func buy_land() -> Dictionary:
	if land_bought: return _fail("limit")
	var price := int(config.land.price)
	if wallet < price: return _fail("funds")
	wallet -= price
	land_value = price
	land_owned = true
	land_bought = true
	return {"ok": true, "cost": price}

func sell_land() -> Dictionary:
	if not land_owned: return _fail("holdings")
	var fee := ceili(float(land_value) * float(config.land.sell_fee))
	wallet += land_value - fee
	var gross := land_value
	land_value = 0
	land_owned = false
	_record("fee", -fee, "land")
	return {"ok": true, "gross": gross, "fee": fee}

func buy_house() -> Dictionary:
	if house_bought: return _fail("limit")
	var price := int(config.house.price)
	if wallet < price: return _fail("funds")
	wallet -= price
	house_value = price
	house_owned = true
	house_bought = true
	return {"ok": true, "cost": price}

func sell_house() -> Dictionary:
	if not house_owned: return _fail("holdings")
	var fee := ceili(float(house_value) * float(config.house.sell_fee))
	wallet += house_value - fee
	var gross := house_value
	house_value = 0
	house_owned = false
	_record("fee", -fee, "house")
	return {"ok": true, "gross": gross, "fee": fee}

# Food and splurge spend money; everything else only moves it between buckets. Fees are ledger
# entries too, so net_worth() always equals ledger_total().
func state() -> Dictionary:
	return {"wallet": wallet, "savings": savings, "gold_units": gold_units, "gold_price": gold_price, "land_value": land_value, "house_value": house_value, "net_worth": net_worth(), "mood": mood, "day": day}

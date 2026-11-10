extends RefCounted
# T-026: Stamina, Health and Stress bars plus the daily-life rules (breakfast, transport, traffic
# light, shops, work stress, overtime, bills, sleep, sick day). Mood and the wallet live in LifeGame
# (T-024); this module reaches them through a weak reference so there is no reference cycle.
# Every random draw comes from its own generator seeded by (seed, day, stream), separate from the
# world generators. Only public values (trust, warnings, demotions, band, rank, personal_pay) are read.
const BARS := ["stamina", "mood", "health", "stress"]
var cfg: Dictionary
var _life_ref: WeakRef
var seed_value := 0
var stamina := 0
var health := 0
var stress := 0
var day := 0
# Day state.
var hungry := false
var fed_today := false
var meal_skips := 0
var transport := ""
var slept_in := 0
var extra_minutes := 0
var stops := 0
var light_red := false
var light_resolved := false
var arrival_minutes := 0
var late_minutes := 0
var peak_stress := 0
var overtime_hours := 0
var treats_today := 0
var skill := 0
var outfit_days := 0
var nights_without_outfit := 0
var sick_pending := false
var sick_today := false
var sick_count := 0
var hr_warning := false
var bills_owed := 0
var unpaid_last_night := false
var notes: Array = []
var last_public: Dictionary = {}
var last_pay_delta := 0

func _init(life: RefCounted, seed_number: int = 0) -> void:
	_life_ref = weakref(life)
	seed_value = seed_number
	cfg = life.config.vitals
	stamina = int(cfg.start.stamina)
	health = int(cfg.start.health)
	stress = int(cfg.start.stress)
	peak_stress = stress

func life() -> RefCounted:
	return _life_ref.get_ref()

func rng_for(stream: int, day_number: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 1000003 + day_number * 15485863 + stream * 104729 + 29
	return rng

func _clamp(value: int) -> int:
	return clampi(value, 0, 100)

# Applies deltas to the bars and returns the real change of each (after clamping).
func apply(delta: Dictionary) -> Dictionary:
	var real := {}
	var l := life()
	var before := {"stamina": stamina, "health": health, "stress": stress, "mood": l.mood}
	stamina = _clamp(stamina + int(delta.get("stamina", 0)))
	health = _clamp(health + int(delta.get("health", 0)))
	stress = _clamp(stress + int(delta.get("stress", 0)))
	if int(delta.get("mood", 0)) != 0: l._add_mood(int(delta.mood))
	peak_stress = maxi(peak_stress, stress)
	real = {"stamina": stamina - before.stamina, "health": health - before.health, "stress": stress - before.stress, "mood": l.mood - before.mood}
	return real

func bar(id: String) -> int:
	match id:
		"stamina": return stamina
		"health": return health
		"stress": return stress
	return life().mood

# ---- focus (analysis Energy bonus) ------------------------------------------------

func effective_mood() -> int:
	return life().mood + (int(cfg.outfit.focus_mood) if outfit_days > 0 else 0)

# {"bonus": int, "reason": String}. Neutral and starting stats give 0.
func focus() -> Dictionary:
	var f: Dictionary = cfg.focus
	var bonus := 0
	var reason := "neutral"
	if stamina < int(f.bad_stamina) or stress > int(f.bad_stress) or health < int(f.bad_health):
		bonus = -1
		reason = "drained"
	elif effective_mood() >= int(f.good_mood) and stamina >= int(f.good_stamina) and stress <= int(f.good_stress) and not hungry:
		bonus = 1
		reason = "confident" if outfit_days > 0 else "happy"
	if sick_today:
		bonus -= 1
		reason = "sick"
	return {"bonus": bonus, "reason": reason}

# ---- morning ----------------------------------------------------------------------------

func begin_morning(day_number: int) -> Dictionary:
	day = day_number
	hungry = false
	fed_today = false
	transport = ""
	slept_in = 0
	extra_minutes = 0
	stops = 0
	light_resolved = false
	arrival_minutes = 0
	late_minutes = 0
	overtime_hours = 0
	treats_today = 0
	peak_stress = stress
	notes.clear()
	sick_today = sick_pending
	sick_pending = false
	light_red = rng_for(1, day).randf() < float(cfg.day.red_probability)
	var result := {"sick": sick_today}
	if sick_today:
		sick_count += 1
		hr_warning = sick_count >= 2
		var paid: int = life().charge_up_to(int(cfg.sick.bill), "medical", "sick day")
		apply({"health": int(cfg.sick.health_restore), "stress": -int(cfg.sick.stress_restore)})
		fed_today = true
		arrival_minutes = int(cfg.day.on_time) + int(cfg.sick.late_minutes)
		late_minutes = int(cfg.sick.late_minutes)
		result["bill"] = paid
	return result

func breakfast_options() -> Array:
	return ["home", "skip", "sleep_in"]

func can_afford(price: int) -> bool:
	return life().wallet >= price

func eat_breakfast(choice: String) -> Dictionary:
	var b: Dictionary = cfg.breakfast
	match choice:
		"home":
			var price := int(b.home.price)
			if not can_afford(price): return {"ok": false, "error": "funds"}
			life().spend_checked(price, "food", "breakfast")
			fed_today = true
			meal_skips = 0
			return {"ok": true, "cost": price, "change": apply(b.home)}
		"skip":
			hungry = true
			return {"ok": true, "cost": 0, "change": {}}
		"sleep_in":
			slept_in = int(b.sleep_in.minutes)
			hungry = true
			return {"ok": true, "cost": 0, "change": apply(b.sleep_in)}
	return {"ok": false, "error": "unknown"}

func transport_ids() -> Array:
	return cfg.transport.keys()

# Pays the fare and applies the ride effects. A ride the wallet cannot afford is refused.
func choose_transport(id: String) -> Dictionary:
	if not cfg.transport.has(id): return {"ok": false, "error": "unknown"}
	var t: Dictionary = cfg.transport[id]
	var price := int(t.price)
	if not can_afford(price): return {"ok": false, "error": "funds"}
	if price > 0: life().spend_checked(price, "transport", id)
	transport = id
	var change := apply({"stamina": t.stamina, "health": t.health, "stress": t.stress, "mood": t.mood})
	return {"ok": true, "cost": price, "minutes": int(t.minutes), "change": change}

# Minutes at which the player reaches the tower, from what has happened so far.
func compute_arrival() -> int:
	var minutes := 0
	if transport != "": minutes = int(cfg.transport[transport].minutes)
	arrival_minutes = int(cfg.day.leave) + slept_in + minutes + extra_minutes
	return arrival_minutes

# ---- the street ----------------------------------------------------------------------------

# One stop at a shop door costs minutes whether or not the player buys anything.
func enter_shop() -> void:
	stops += 1
	extra_minutes += int(cfg.day.shop_visit_minutes)

# red light: "wait" loses minutes, no risk; "run" saves them with a seeded chance of a fine or an accident.
# The same three draws are consumed whichever choice is made, so the outcome is a function of the seed.
func traffic_light(choice: String) -> Dictionary:
	var rng := rng_for(2, day)
	var fine_roll := rng.randf()
	var accident_roll := rng.randf()
	var amount_roll := rng.randf()
	light_resolved = true
	var l: Dictionary = cfg.light
	if choice != "run":
		extra_minutes += int(cfg.day.wait_minutes)
		return {"ok": true, "choice": "wait", "outcome": "waited", "minutes": int(cfg.day.wait_minutes), "fine": 0}
	if accident_roll < float(l.accident_probability):
		extra_minutes += int(l.accident_minutes)
		var change := apply({"health": -int(l.accident_health), "stress": int(l.accident_stress)})
		return {"ok": true, "choice": "run", "outcome": "accident", "minutes": int(l.accident_minutes), "fine": 0, "change": change}
	if fine_roll < float(l.fine_probability):
		var wanted := int(l.fine_min) + int(floor(amount_roll * float(int(l.fine_max) - int(l.fine_min) + 1)))
		var paid: int = life().charge_up_to(wanted, "fine", "red light")
		var change2 := apply({"stress": int(l.fine_stress)})
		return {"ok": true, "choice": "run", "outcome": "fined", "minutes": 0, "fine": paid, "change": change2}
	return {"ok": true, "choice": "run", "outcome": "clear", "minutes": 0, "fine": 0}

# Shop purchases ------------------------------------------------------------------------------

func shop_items(shop: String) -> Array:
	return cfg.shops.get(shop, [])

func item_data(shop: String, id: String) -> Dictionary:
	for entry in shop_items(shop):
		if entry.id == id: return entry
	return {}

func buy(shop: String, id: String) -> Dictionary:
	var entry := item_data(shop, id)
	if entry.is_empty(): return {"ok": false, "error": "unknown"}
	var price := int(entry.price)
	if not can_afford(price): return {"ok": false, "error": "funds"}
	var kind := "clothes" if bool(entry.get("outfit", false)) else ("health" if shop == "pharmacy" else "shop")
	life().spend_checked(price, kind, id)
	if bool(entry.get("meal", false)):
		hungry = false
		fed_today = true
		meal_skips = 0
	if bool(entry.get("outfit", false)):
		outfit_days = int(cfg.outfit.days)
		nights_without_outfit = 0
	skill += int(entry.get("skill", 0))
	treats_today += 1
	var change := apply({"stamina": entry.get("stamina", 0), "mood": entry.get("mood", 0), "health": entry.get("health", 0), "stress": entry.get("stress", 0)})
	return {"ok": true, "cost": price, "change": change}

# Called when the player reaches the tower: hunger and lateness are settled here.
func finish_commute() -> Dictionary:
	compute_arrival()
	var skipped_penalty := {}
	if hungry and not fed_today:
		meal_skips += 1
		var b: Dictionary = cfg.breakfast.skip
		var d := {"stamina": int(b.stamina), "mood": int(b.mood)}
		if meal_skips >= 2:
			d.stamina += int(b.repeat_stamina)
			d.mood += int(b.repeat_mood)
			d["health"] = int(b.repeat_health)
		skipped_penalty = apply(d)
		hungry = false
	late_minutes = clampi(arrival_minutes - int(cfg.day.on_time), 0, int(cfg.day.max_late))
	return {"late": late_minutes, "arrival": arrival_minutes, "hunger": skipped_penalty}

# ---- work ----------------------------------------------------------------------------------

# Uses only public values. `before` and `after` are status() dictionaries around the day's review.
func after_work(before: Dictionary, after: Dictionary) -> Dictionary:
	var w: Dictionary = cfg.work_stress
	var delta := 0
	var trust_change := int(after.get("trust", 0)) - int(before.get("trust", 0))
	if trust_change <= -6: delta += int(w.wrong)
	elif trust_change < 0: delta += int(w.loss)
	elif trust_change >= 5: delta += int(w.gain)
	var band := str(before.get("band", "on_time"))
	if band == "late": delta += int(w.late)
	elif band == "missed": delta += int(w.missed)
	if int(after.get("warnings", 0)) > int(before.get("warnings", 0)): delta += int(w.warning)
	if int(after.get("demotions", 0)) > int(before.get("demotions", 0)): delta += int(w.demotion)
	if str(after.get("rank", "")) != str(before.get("rank", "")) and int(after.get("demotions", 0)) == int(before.get("demotions", 0)): delta += int(w.promotion)
	var pay := roundi(float(after.get("personal_pay", 0.0)) - float(before.get("personal_pay", 0.0)))
	if pay > 0 and last_pay_delta > 0 and float(pay) > float(last_pay_delta) * 1.2: delta += int(w.bonus)
	if pay > 0: last_pay_delta = pay
	return apply({"stress": delta})

func overtime(hours: int) -> Dictionary:
	var o: Dictionary = cfg.overtime
	if hours < 1 or hours > int(o.max_hours): return {"ok": false, "error": "amount"}
	var pay := hours * int(o.pay_per_hour)
	life().earn(pay, "overtime", "%d h" % hours)
	overtime_hours += hours
	var change := apply({"stamina": hours * int(o.stamina), "mood": hours * int(o.mood), "stress": hours * int(o.stress)})
	var exhausted := stamina <= int(o.exhausted_stamina)
	if exhausted: change["health"] = int(apply({"health": int(o.exhausted_health)}).health)
	return {"ok": true, "pay": pay, "exhausted": exhausted, "change": change}

# ---- the night -------------------------------------------------------------------------------

func on_treat(mood_gain: int) -> void:
	treats_today += 1
	apply({"stamina": 2 + mood_gain / 4, "stress": -1})

# Pays bills, regenerates the bars and decides whether tomorrow is a sick day.
func night() -> Dictionary:
	var n: Dictionary = cfg.night
	var l := life()
	var due := int(cfg.bills.daily) + bills_owed
	var paid: int = l.charge_up_to(due, "bills", "rent")
	bills_owed = mini(due - paid, int(cfg.bills.owed_cap))
	unpaid_last_night = bills_owed > 0
	var peak := maxi(peak_stress, stress)
	var delta_stamina := int(n.stamina) - overtime_hours * int(n.overtime_penalty)
	if stress >= int(n.insomnia_stress): delta_stamina -= int(n.stress_penalty)
	if treats_today > 0: delta_stamina += int(n.treat_bonus)
	var delta_stress := -int(n.stress) / (2 if stress >= int(n.insomnia_stress) else 1)
	var delta_health := 0
	if stamina + delta_stamina >= 60 and not unpaid_last_night and meal_skips == 0: delta_health = int(n.health_gain)
	if meal_skips >= 2: delta_health -= int(n.health_loss)
	if health < 40: delta_stamina -= 6
	var delta_mood := 0
	if l.mood < int(n.mood_baseline): delta_mood = mini(int(n.mood_step), int(n.mood_baseline) - l.mood)
	if unpaid_last_night:
		delta_mood += int(cfg.bills.unpaid_mood)
		delta_health += int(cfg.bills.unpaid_health)
	nights_without_outfit += 1 if outfit_days <= 0 else 0
	outfit_days = maxi(0, outfit_days - 1)
	if nights_without_outfit >= int(cfg.outfit.shabby_after):
		delta_mood += int(cfg.outfit.shabby_mood)
		delta_stress += int(cfg.outfit.shabby_stress)
	apply({"stamina": delta_stamina, "stress": delta_stress, "health": delta_health, "mood": delta_mood})
	sick_pending = health <= int(cfg.sick.health) or peak >= int(cfg.sick.stress)
	peak_stress = stress
	return {"bills_paid": paid, "bills_owed": bills_owed, "sick_tomorrow": sick_pending}

func state() -> Dictionary:
	var l := life()
	return {"stamina": stamina, "mood": l.mood, "health": health, "stress": stress, "wallet": l.wallet, "outfit_days": outfit_days, "skill": skill, "sick_count": sick_count, "bills_owed": bills_owed}

# Money spent by category, read from the ledger (negative entries of the spending kinds).
func spending_summary() -> Dictionary:
	var result := {}
	for entry in life().ledger:
		if int(entry.delta) < 0 and entry.kind in ["food", "transport", "shop", "clothes", "health", "bills", "fine", "medical", "splurge"]:
			result[entry.kind] = int(result.get(entry.kind, 0)) - int(entry.delta)
	return result

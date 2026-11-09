extends RefCounted

const Loader = preload("res://scripts/data.gd")
const Company = preload("res://scripts/sim/company.gd")
var config: Dictionary
var cards: Array
var events: Array
var state: RefCounted
var rng := RandomNumberGenerator.new()
var report_rng := RandomNumberGenerator.new()
var week_open := false
var hand: Array = []
var active_events: Array = []
var prediction_multiplier := 1.0
var next_source := 0
var horizon: int

func _init(seed_value: int = 0, data: Dictionary = {}, weeks: int = 0) -> void:
	config = data.config if data.has("config") else Loader.load_json("res://data/config.json")
	cards = data.cards if data.has("cards") else Loader.load_json("res://data/cards.json").cards
	events = data.events if data.has("events") else Loader.load_json("res://data/events.json").events
	state = Company.new(config.initial)
	horizon = weeks if weeks > 0 else int(config.weeks.full)
	rng.seed = seed_value
	report_rng.seed = seed_value

func begin_week(with_events: bool = true) -> void:
	if state.lost or state.won or week_open:
		return
	week_open = true
	state.week += 1
	state.energy = int(config.energy)
	state.base.ad_spend = 0.0
	prediction_multiplier = 1.0
	state.modifiers = state.modifiers.filter(func(e): return e.end > state.week)
	active_events = active_events.filter(func(e): return e.end > state.week)
	var phase: Dictionary = config.phases.back()
	for candidate in config.phases:
		if state.week <= candidate.through:
			phase = candidate
			break
	state.base.integrity = maxf(0, state.base.integrity - phase.integrity_decay)
	if with_events:
		for i in int(phase.event_count):
			if rng.randf() < phase.event_chance:
				apply_event(events[rng.randi_range(0, events.size() - 1)])
	var deck := cards.duplicate()
	hand.clear()
	for i in mini(int(config.draw), deck.size()):
		var index := rng.randi_range(0, deck.size() - 1)
		hand.append(deck[index])
		deck.remove_at(index)

func apply_effect(effect: Dictionary, source: int) -> void:
	if effect.has("unless_flag") and state.flags.has(effect.unless_flag):
		return
	var delay := int(effect.get("delay", 0))
	if effect.has("duration") or delay > 0:
		state.modifiers.append({"stat":effect.stat,"add":effect.add,"start":state.week + delay,
			"end":state.week + delay + int(effect.get("duration", horizon + 1)),"source":source})
	else:
		state.base[effect.stat] += float(effect.add)
		if effect.stat == "users":
			state.base.users = maxf(0, state.base.users)

func apply_event(event: Dictionary) -> void:
	next_source += 1
	var end_week: int = state.week + 1
	for effect in event.effects:
		apply_effect(effect, next_source)
		end_week = maxi(end_week, state.week + int(effect.get("duration", 1)))
	active_events.append({"definition":event,"source":next_source,"revealed":false,"end":end_week})

func play(card_id: String) -> bool:
	if state.lost or state.won or not week_open:
		return false
	for i in hand.size():
		var card: Dictionary = hand[i]
		if card.id != card_id:
			continue
		if state.energy < card.energy or state.base.cash < card.budget:
			return false
		state.energy -= int(card.energy)
		state.base.cash -= float(card.budget)
		for event in active_events.duplicate():
			if card_id in event.definition.revealed_by:
				event.revealed = true
			if card_id in event.definition.resolved_by:
				var source: int = event.source
				state.modifiers = state.modifiers.filter(func(e): return e.source != source)
				active_events.erase(event)
				state.resolved += 1
		for effect in card.effects:
			apply_effect(effect, 0)
		if card.has("sets_flag"):
			state.flags[card.sets_flag] = true
		prediction_multiplier = float(card.get("prediction_multiplier", 1.0))
		hand.remove_at(i)
		return true
	return false

func report() -> Dictionary:
	var result := {}
	var amplitude: float = (1.0 - state.value("integrity", config) / config.limits.integrity[1]) * config.noise_scale * prediction_multiplier
	for stat in config.initial:
		result[stat] = state.value(stat, config) * (1.0 + report_rng.randf_range(-amplitude, amplitude))
	for event in active_events:
		for stat in event.definition.get("observed_effects", {}):
			result[stat] += event.definition.observed_effects[stat]
	return result

func event_reports() -> Array:
	var result := []
	for event in active_events:
		var visible := {"symptom":event.definition.symptom}
		if event.revealed:
			visible.root_cause = event.definition.root_cause
		result.append(visible)
	return result

func finish_week() -> Dictionary:
	if state.lost or state.won or not week_open:
		return {}
	week_open = false
	var ad_spend: float = state.value("ad_spend", config)
	var effective_cac: float = state.value("cac", config) * (1.0 + config.economy.ad_diminishing * ad_spend / config.economy.ad_unit)
	var new_users := ad_spend / effective_cac
	var churned: float = state.base.users * (1.0 - state.value("retention", config))
	state.base.users = maxf(0, state.base.users - churned + new_users)
	var revenue: float = state.base.users * state.value("conversion", config) * state.value("arpu", config)
	var fixed_cost: float = state.value("fixed_cost", config) + config.economy.cost_per_user * state.base.users
	# Campaign budgets were debited by play(); do not charge ad spend twice.
	state.base.cash += revenue - fixed_cost
	state.bad_ratio_weeks = state.bad_ratio_weeks + 1 if state.ratio(config) < config.loss.ratio else 0
	state.lost = state.base.cash <= config.loss.cash or (state.bad_ratio_weeks >= config.loss.streak and state.base.cash < config.loss.low_cash)
	state.won = not state.lost and state.week >= horizon
	return {"new_users":new_users,"churned":churned,"revenue":revenue,"fixed_cost":fixed_cost,"cash":state.base.cash}

func score() -> float:
	return state.base.cash * config.score.cash + state.ratio(config) * config.score.ratio + state.resolved * config.score.resolved

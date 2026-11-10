extends RefCounted

var _days: Array = []
var _shocks: Array = []
var _questions: Array = []
var _answers: Array = []

func _init(seed_value: int = 0, horizon: int = 0, config: Dictionary = {}, questions: Array = [], events: Array = [], fixed: Dictionary = {}) -> void:
	if horizon == 0: return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for day in range(horizon + 1):
		var states := {}
		for variable in config.variables:
			var direction: String = config.directions[rng.randi_range(0, config.directions.size() - 1)]
			if day > 0 and rng.randf() < config.markov_keep:
				direction = _days[day - 1][variable].direction
			states[variable] = {"direction":direction,"magnitude":config.magnitudes[rng.randi_range(0, config.magnitudes.size() - 1)]}
		_days.append(states)
	if fixed.has("days"):
		_days = fixed.days.duplicate(true)
	var available: Array = range(1, horizon + 1)
	for i in int(config.shock_count[str(horizon)]):
		var index := rng.randi_range(0, available.size() - 1)
		var day: int = available.pop_at(index)
		if rng.randf() > config.shock_probability:
			continue
		var weighted: Array = []
		for event in events:
			var weight := 1
			if config.precursors.has(event.id):
				var precursor: Dictionary = config.precursors[event.id]
				if _days[maxi(0, day - 2)][precursor.variable].direction == precursor.direction:
					weight = int(config.precursor_weight)
			for n in weight:
				weighted.append(event.id)
		var id: String = weighted[rng.randi_range(0, weighted.size() - 1)]
		var duration := 1
		for event in events:
			if event.id == id:
				for effect in event.effects:
					duration = maxi(duration, int(effect.get("duration", 1)))
		_shocks.append({"day":day,"id":id,"end":day + duration})
	if fixed.has("shocks"):
		_shocks = fixed.shocks.duplicate(true)
	for day in range(1, horizon + 1):
		var candidates := questions.filter(func(q):
			for previous in _questions.slice(maxi(0, _questions.size() - int(config.repeat_days))):
				if previous.id == q.id:
					return false
			return true)
		var question: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)
		_questions.append(question)
		_answers.append(_answer(day, question))

func _active(id: String, day: int) -> bool:
	for shock in _shocks:
		if shock.id == id and day >= shock.day and day < shock.end:
			return true
	return false

func _answer(day: int, q: Dictionary) -> String:
	match q.answer_rule:
		"next_state": return _days[day][q.variable].direction
		"state": return _days[day - 1][q.variable].direction
		"event":
			for d in range(day, day + int(q.window_days) + 1):
				if _active(q.variable, d): return "tang"
			return "ngang"
		"integrity": return "giam" if _active("logging_error", day) else "tang"
		"bank_rumor":
			var value: Dictionary = _days[day - 1].tin_dung
			return "giam" if value.direction == "giam" and value.magnitude == "high" else "ngang"
	return "ngang"

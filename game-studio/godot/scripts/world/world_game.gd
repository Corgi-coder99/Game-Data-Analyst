extends RefCounted

const Loader = preload("res://scripts/data.gd")
const Simulation = preload("res://scripts/sim/simulation.gd")
const Scenario = preload("res://scripts/world/world_scenario.gd")
const News = preload("res://scripts/world/news_engine.gd")
const Verifier = preload("res://scripts/world/verifier.gd")
const Report = preload("res://scripts/world/report.gd")
const Career = preload("res://scripts/world/career.gd")
static var _prepared: Dictionary = {}
var _config: Dictionary
var _sim: RefCounted
var _scenario: RefCounted
var _news: RefCounted
var _verifier: RefCounted
var _career: RefCounted
var _adopt_rng := RandomNumberGenerator.new()
var _day := 0
var _horizon: int
var _open := false
var _submitted := false
var _pending: Dictionary = {}
var _reviews: Dictionary = {}
var _ending := ""
var _cash_report := 0.0

func _init(seed_value: int, horizon: int, overrides: Dictionary = {}) -> void:
	assert(horizon in [10, 30])
	_horizon = horizon
	_config = Loader.load_json("res://data/world.json").duplicate(true)
	_merge_config(_config, overrides.get("world", {}))
	var questions: Array = overrides.get("questions", Loader.load_json("res://data/questions.json").questions)
	# v2 uses career survival, not v1's final Users/ratio victory gates.
	_sim = Simulation.new(seed_value, overrides.get("simulation", {}), horizon + 1)
	var cache_key := "%d:%d:%d" % [seed_value, horizon, hash(_config)]
	if overrides.is_empty() and _prepared.get("key") == cache_key:
		_scenario = Scenario.new()
		for field in ["_days", "_shocks", "_questions", "_answers"]:
			_scenario.set(field, _prepared[field].duplicate(true))
		_news = News.new(seed_value + 1, _config, Loader.load_json("res://data/news.json"))
		for field in ["_items", "_last", "_seen"]:
			_news.set(field, _prepared[field].duplicate(true))
	else:
		_scenario = Scenario.new(seed_value, horizon, _config, questions, _sim.events, overrides.get("scenario", {}))
		_news = News.new(seed_value + 1, _config, overrides.get("news", Loader.load_json("res://data/news.json")))
		# Rejection sampling conditions the scenario on a playable complete news pool.
		# No template or state is fabricated, and the resulting seed stream is stable.
		var attempt := 0
		while true:
			for day in range(1, horizon + 1):
				_news._generate(day, horizon, _scenario)
			var first_kinds := {}
			for item in _news._items:
				if item.day == 1: first_kinds[item.kind] = true
			if (first_kinds.size() == _config.kind_weights.size() and _news._seen.size() == _config.kind_weights.size() and _news._items.size() == horizon * int(_config.news_per_day[str(horizon)])) or overrides.has("scenario") or overrides.has("news"): break
			attempt += 1
			_scenario = Scenario.new(seed_value + attempt * 100003, horizon, _config, questions, _sim.events)
			_news = News.new(seed_value + 1, _config, overrides.get("news", Loader.load_json("res://data/news.json")))
		if overrides.is_empty():
			# A single immutable preparation is reused across bots on the same seed.
			# Deep copies isolate every game's verification and scenario fixtures.
			_prepared = {"key":cache_key}
			for field in ["_days", "_shocks", "_questions", "_answers"]:
				_prepared[field] = _scenario.get(field).duplicate(true)
			for field in ["_items", "_last", "_seen"]:
				_prepared[field] = _news.get(field).duplicate(true)
	_verifier = Verifier.new(seed_value + 2, _config)
	_career = Career.new(_config)
	_adopt_rng.seed = seed_value + 3
	_cash_report = _sim.report().cash

func begin_day() -> void:
	if _open or not _ending.is_empty(): return
	_day += 1
	_open = true
	_submitted = false
	_pending = {}
	_sim.begin_week(false)
	_cash_report = _sim.report().cash
	for shock in _scenario._shocks:
		if shock.day != _day: continue
		for event in _sim.events:
			if event.id == shock.id: _sim.apply_event(event)
	for variable in _config.macro:
		var value: Dictionary = _scenario._days[_day - 1][variable]
		for stat in _config.macro[variable].get(value.direction, {}):
			_sim.apply_effect({"stat":stat,"add":float(_config.macro[variable][value.direction][stat]) * float(_config.magnitude_scale[value.magnitude]),"duration":1}, -1)


func news_today() -> Array:
	return _news.news_today(_day)

func question_today() -> Dictionary:
	if _day == 0: return {}
	var q: Dictionary = _scenario._questions[_day - 1]
	return {"id":q.id,"text":q.text}

func tools() -> Array:
	var result: Array = []
	for id in _config.tools:
		for card in _sim.cards:
			if card.id == _config.tools[id]:
				result.append({"id":id,"name_key":id,"energy":card.energy,"budget":_config.tool_budget.get(id, card.budget)})
	return result

func verify(uid: String, tool_id: String) -> Dictionary:
	if not _open or _submitted: return {"ok":false,"error":"day_closed"}
	if not news_today().any(func(n): return n.uid == uid): return {"ok":false,"error":"invalid_uid"}
	var item: Dictionary = _news._find(uid)
	var already_verified: bool = item.results.has(tool_id)
	var result: Dictionary = _verifier.verify(item, tool_id, _sim)
	if result.ok and not already_verified:
		for card in _sim.cards:
			if card.id == _config.tools[tool_id]: _cash_report -= float(_config.tool_budget.get(tool_id, card.budget))
	return result

func hand() -> Array:
	return _sim.hand.filter(func(c): return c.category != "analysis").duplicate(true)

func submit_report(input: Dictionary) -> Dictionary:
	if not _open: return {"ok":false,"error":"day_closed"}
	if _submitted: return {"ok":false,"error":"already_submitted"}
	var error := Report.validate(input, question_today().id, hand(), news_today(), int(_config.ranks[_career.rank].actions), _config)
	if not error.is_empty(): return {"ok":false,"error":error}
	_pending = input.duplicate(true)
	_submitted = true
	return {"ok":true}

func end_day() -> Dictionary:
	if not _open: return {"ok":false,"error":"day_closed"}
	if not _submitted: return {"ok":false,"error":"report_required"}
	var actions: Array = []
	for id in _pending.actions:
		var adopted: bool = _adopt_rng.randf() < _career.adoption()
		var executed: bool = _sim.play(id) if adopted else false
		actions.append({"id":id,"adopted":adopted,"executed":executed})
	_sim.finish_week()
	_cash_report = _sim.report().cash
	var result := Report.grade(_pending, _scenario._answers[_day - 1], _news._items, _config)
	var career_result: Dictionary = _career.update(result)
	var today: Array = _news._items.filter(func(n): return n.day == _day).duplicate(true)
	var shocks: Array = _scenario._shocks.filter(func(s): return s.day == _day).duplicate(true)
	for shock in shocks:
		for event in _sim.events:
			if event.id == shock.id: shock["root_cause"] = event.root_cause
	_reviews[_day] = {"day":_day,"news":today,"shocks":shocks,"answer":_scenario._answers[_day - 1],"result":result,"career":career_result,"actions":actions,"states":_scenario._days[_day - 1].duplicate(true)}
	_open = false
	if _career.fired: _ending = "fired"
	elif _sim.state.lost: _ending = "bankrupt"
	elif _day >= _horizon: _ending = "survived"
	# Accuracy and trust delta are disclosed only by review().
	return {"ok":true,"day":_day,"actions":actions,"finished":not _ending.is_empty()}

func review(day: int) -> Dictionary:
	if not _reviews.has(day): return {"ok":false,"error":"day_not_reviewable"}
	return _reviews[day].duplicate(true)

func status() -> Dictionary:
	var minimum_rank: String = _config.win.demo if _horizon == 10 else _config.win.full
	var eligible := false
	for index in range(_career.rank + 1):
		if _config.ranks[index].id == minimum_rank: eligible = true
	var won: bool = _ending == "survived" and eligible
	var score: float = (float(_config.score.win_bonus) if won else 0.0) + _career.trust * float(_config.score.trust) + _career.positive_delta * float(_config.score.positive_delta) - _career.demotions * float(_config.score.demotion) - (float(_config.score.fired) if _ending == "fired" else 0.0)
	return {"energy":int(_sim.state.energy),"energy_max":int(_sim.config.energy),"day":_day,"horizon":_horizon,"rank":_config.ranks[_career.rank].id,"trust":_career.trust,"warnings":_career.warnings,"demotions":_career.demotions,"personal_pay":_career.personal_pay,"cash_report":_cash_report,"finished":not _ending.is_empty(),"ending":_ending,"won":won,"score":score}

func report_snapshot() -> Dictionary:
	return _sim.report().duplicate(true)

func _merge_config(base: Dictionary, patch: Dictionary) -> void:
	for key in patch:
		if base.get(key) is Dictionary and patch[key] is Dictionary and not patch[key].is_empty():
			_merge_config(base[key], patch[key])
		else:
			base[key] = patch[key].duplicate(true) if patch[key] is Array or patch[key] is Dictionary else patch[key]

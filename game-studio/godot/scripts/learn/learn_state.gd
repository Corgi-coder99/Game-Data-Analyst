extends RefCounted
# T-035: the learner's persistent state, kept in the local profile (profile.data.learn): Handbook unlocks,
# skill XP and levels, event counters (for achievements), hint total and the tutorial choice.
# Headless. Wraps a dictionary (the profile's) so a test can use a plain one.
const Content = preload("res://scripts/learn/content.gd")
const Loader = preload("res://scripts/data.gd")
var data: Dictionary
var cfg: Dictionary

static func defaults() -> Dictionary:
	return {"tutorial": "", "cards": {}, "xp": {"data_cleaning": 0, "charts": 0, "statistics": 0, "causality": 0, "communication": 0}, "events": {}, "tutorial_days": {}, "hints_used": 0}

func _init(learn_data: Dictionary = {}, config: Dictionary = {}) -> void:
	data = learn_data
	if data.is_empty():
		var base := defaults()
		for key in base: data[key] = base[key]
	cfg = config if not config.is_empty() else Loader.load_json("res://data/datasets.json").get("learn", {})

# ---- Handbook -------------------------------------------------------------------------------------

func is_unlocked(card_id: String) -> bool:
	return data.cards.has(card_id) or cfg.get("starter_cards", []).has(card_id)

func unlock(card_id: String, source: String = "") -> bool:
	if Content.card_by_id(card_id).is_empty() or is_unlocked(card_id): return false
	data.cards[card_id] = source if source != "" else "yes"
	return true

func unlock_many(ids: Array, source: String = "") -> Array:
	var fresh: Array = []
	for id in ids:
		if unlock(str(id), source): fresh.append(str(id))
	return fresh

func unlock_for_op(op: String) -> Array:
	return unlock_many(Content.OP_CARDS.get(op, []), "op:" + op)

func unlock_for_case(case_entry: Dictionary) -> Array:
	if case_entry.is_empty(): return []
	return unlock_many(case_entry.handbook_card_ids, "case:" + str(case_entry.id))

func unlocked_count() -> int:
	var n := 0
	for card in Content.cards():
		if is_unlocked(card.id): n += 1
	return n

# ---- skills ---------------------------------------------------------------------------------------

func xp(skill: String) -> int:
	return int(data.xp.get(skill, 0))

func level_of(points: int) -> int:
	var levels: Array = cfg.skills.levels
	var out := 1
	for i in levels.size():
		if points >= int(levels[i]): out = i + 1
	return out

func level(skill: String) -> int:
	return level_of(xp(skill))

func mean_level() -> float:
	var total := 0.0
	for skill in Content.SKILLS: total += float(level(skill))
	return total / float(Content.SKILLS.size())

# XP into the current level: {have, need} (need 0 at the top level).
func progress(skill: String) -> Dictionary:
	var levels: Array = cfg.skills.levels
	var lv := level(skill)
	if lv >= levels.size(): return {"have": xp(skill) - int(levels[levels.size() - 1]), "need": 0}
	return {"have": xp(skill) - int(levels[lv - 1]), "need": int(levels[lv]) - int(levels[lv - 1])}

# Adds XP; returns {skill, gained, from, to} (from == to when there is no level-up).
func add_xp(skill: String, amount: int) -> Dictionary:
	var before := level(skill)
	if amount > 0 and data.xp.has(skill): data.xp[skill] = xp(skill) + amount
	return {"skill": skill, "gained": maxi(0, amount), "from": before, "to": level(skill)}

# ---- events, hints, tutorial -----------------------------------------------------------------------------

func has_event(id: String) -> bool:
	return int(data.events.get(id, 0)) > 0

func bump_event(id: String) -> bool:
	var first := not has_event(id)
	data.events[id] = int(data.events.get(id, 0)) + 1
	return first

func tutorial_mode() -> String:
	return str(data.tutorial)

func set_tutorial(mode: String) -> void:
	if mode in ["", "on", "skip", "done"]: data.tutorial = mode

func tutorial_active() -> bool:
	return tutorial_mode() == "on"

func mark_tutorial_day(day: int) -> void:
	data.tutorial_days[str(day)] = true

func tutorial_days_done() -> int:
	return data.tutorial_days.size()

func record_hint() -> void:
	data.hints_used = int(data.hints_used) + 1

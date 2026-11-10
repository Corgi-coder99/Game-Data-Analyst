extends RefCounted

static func validate(input: Dictionary, question_id: String, available: Array, items: Array, limit: int, config: Dictionary) -> String:
	if input.get("question_id") != question_id: return "invalid_question"
	if input.get("forecast") not in config.directions: return "invalid_forecast"
	if not config.grading.confidence.has(input.get("confidence", "")): return "invalid_confidence"
	if not input.get("evidence") is Array: return "invalid_evidence"
	if not input.get("actions") is Array: return "invalid_actions"
	if input.evidence.size() > int(config.grading.max_evidence): return "too_many_evidence"
	if input.actions.size() > limit: return "too_many_actions"
	var seen := {}
	for uid in input.evidence:
		if not uid is String or seen.has(uid) or not items.any(func(n): return n.uid == uid): return "invalid_evidence"
		seen[uid] = true
	seen.clear()
	for id in input.actions:
		if not id is String or seen.has(id) or not available.any(func(c): return c.id == id and c.category != "analysis"): return "invalid_action"
		seen[id] = true
	return ""

static func grade(input: Dictionary, answer: String, items: Array, config: Dictionary) -> Dictionary:
	var g: Dictionary = config.grading
	var acc := 0.0
	if input.forecast == answer: acc = 1.0
	elif input.forecast == "ngang" or answer == "ngang": acc = float(g.adjacent)
	var evidence := 0.0
	for uid in input.evidence:
		for item in items:
			if item.uid != uid: continue
			if item.verification == "chua_kiem_chung": evidence += float(g.unverified[item.truth])
			else: evidence += float(g.evidence[item.verification])
	if not input.evidence.is_empty(): evidence /= input.evidence.size()
	var points: float = g.base * g.confidence[input.confidence]
	if acc == 0: points = -points
	elif acc < 1: points *= float(g.partial_reward)
	var delta := snappedf(points * (1.0 + float(g.evidence_factor) * evidence), 0.1)
	return {"acc":acc,"ev":evidence,"delta":delta,"label":"reward" if delta > 0 else "penalty"}

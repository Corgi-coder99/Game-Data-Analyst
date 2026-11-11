extends RefCounted
# T-035: review-only. Picks the mentor lines of the review step "Your analysis" from data/coaching.json by
# outcome (praise, miss, wrong_fix) and adds the plain explanation of what the data actually said.
# It reads the review record (manifest, grade), so it is only used after the day has ended.
const Content = preload("res://scripts/learn/content.gd")
const CaseMap = preload("res://scripts/learn/case_map.gd")
const VOICES := ["hanh", "khoi", "linh"]
const RANK := {"praise": 0, "miss": 1, "wrong_fix": 2}

static func voice_for(day: int, index: int, tutorial: bool = false) -> String:
	if tutorial: return "linh"
	return VOICES[posmod(day + index, VOICES.size())]

static func line_for(trap: String, outcome: String, voice: String) -> String:
	var lines: Array = Content.coaching().get("traps", {}).get(trap, {}).get(outcome, [])
	for entry in lines:
		if entry.voice == voice: return str(entry.text)
	return str(lines[0].text) if not lines.is_empty() else ""

static func outcome_of(entry: Dictionary) -> String:
	if int(entry.get("wrongly_removed", 0)) > 0: return "wrong_fix"
	if int(entry.get("missed", 0)) > 0 or int(entry.get("fixed", 0)) < int(entry.get("rows", 0)): return "miss"
	return "praise"

# One tip per trap of the file: {trap, outcome, voice, text, said, case_id, card_id, type}.
# `file` is one entry of DataGame.review(day).files; `hint_levels` the hint levels the player used on this file's case.
static func tips(file: Dictionary, day: int, hint_levels: int, texts: Dictionary, tutorial: bool = false, start_index: int = 0) -> Array:
	var order: Array = []
	var by_trap := {}
	for e in file.grade.cleaning.entries:
		var trap := Content.trap_of(str(e.type))
		if trap == "": continue
		var outcome := outcome_of(e)
		if not by_trap.has(trap):
			by_trap[trap] = {"trap": trap, "outcome": outcome, "type": str(e.type)}
			order.append(trap)
		elif RANK[outcome] > RANK[by_trap[trap].outcome]:
			by_trap[trap].outcome = outcome
	for item in file.grade.findings.items:
		var trap2: String = str(Content.FINDING_TRAP.get(str(item.id), ""))
		if trap2 == "" or by_trap.has(trap2): continue
		by_trap[trap2] = {"trap": trap2, "outcome": "praise" if float(item.score) >= 1.0 else "miss", "type": str(item.id)}
		order.append(trap2)
	var out: Array = []
	for i in order.size():
		var tip: Dictionary = by_trap[order[i]]
		var voice := voice_for(day, start_index + i, tutorial)
		var c: Dictionary = CaseMap.by_trap(tip.trap, str(file.get("name", "")))
		var text := line_for(tip.trap, tip.outcome, voice)
		if hint_levels > 0:
			text += " " + str(texts.hint_note_praise if tip.outcome == "praise" else texts.hint_note_miss)
		out.append({"trap": tip.trap, "outcome": tip.outcome, "voice": voice, "text": text, "said": str(c.get("trap", "")), "case_id": str(c.get("id", "")), "card_id": str(c.handbook_card_ids[0]) if not c.is_empty() and not c.handbook_card_ids.is_empty() else "", "type": tip.type})
	return out

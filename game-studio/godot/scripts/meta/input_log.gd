extends RefCounted
# T-030: the input log record of one finished day. This is the future server-verification payload
# (see docs/INPUT-LOG-FORMAT.md). It holds the player's submitted inputs and the public result parts,
# nothing else: the day answer, the news labels and the scenario data are never stored.
const VERSION := 1
const INPUT_KEYS := ["question_id", "forecast", "confidence", "evidence", "actions", "submit_minutes"]
const CONTEXT_KEYS := ["focus_bonus", "late_minutes"]
const RESULT_KEYS := ["accuracy", "evidence_quality", "trust_delta", "timing", "pay", "bonus", "rank", "trust", "day_score"]
const TOP_KEYS := ["v", "day_id", "mode", "date", "seed", "day_index", "inputs", "context", "result"]

static func day_id(mode: String, date: String, seed_value: int, day_index: int) -> String:
	if mode == "daily": return "daily:%s:%d" % [date, day_index]
	return "run:%d:%d" % [seed_value, day_index]

static func build(mode: String, date: String, seed_value: int, day_index: int, submission: Dictionary, submit_minutes: int, context: Dictionary, result: Dictionary) -> Dictionary:
	var inputs := {
		"question_id": str(submission.get("question_id", "")),
		"forecast": str(submission.get("forecast", "")),
		"confidence": str(submission.get("confidence", "")),
		"evidence": _strings(submission.get("evidence", [])),
		"actions": _strings(submission.get("actions", [])),
		"submit_minutes": submit_minutes,
	}
	return normalize({"v": VERSION, "day_id": day_id(mode, date, seed_value, day_index), "mode": mode, "date": date, "seed": seed_value, "day_index": day_index, "inputs": inputs, "context": context, "result": result})

static func _strings(values: Variant) -> Array:
	var out: Array = []
	if values is Array:
		for value in values: out.append(str(value))
	return out

# JSON turns every number into a float; this restores the integer fields so a record round-trips exactly.
static func normalize(record: Dictionary) -> Dictionary:
	var out := {}
	out["v"] = int(record.get("v", VERSION))
	out["day_id"] = str(record.get("day_id", ""))
	out["mode"] = str(record.get("mode", "run"))
	out["date"] = str(record.get("date", ""))
	out["seed"] = int(record.get("seed", 0))
	out["day_index"] = int(record.get("day_index", 0))
	var inputs: Dictionary = record.get("inputs", {})
	out["inputs"] = {
		"question_id": str(inputs.get("question_id", "")),
		"forecast": str(inputs.get("forecast", "")),
		"confidence": str(inputs.get("confidence", "")),
		"evidence": _strings(inputs.get("evidence", [])),
		"actions": _strings(inputs.get("actions", [])),
		"submit_minutes": int(inputs.get("submit_minutes", 0)),
	}
	var context: Dictionary = record.get("context", {})
	out["context"] = {"focus_bonus": int(context.get("focus_bonus", 0)), "late_minutes": int(context.get("late_minutes", 0))}
	var result: Dictionary = record.get("result", {})
	out["result"] = {
		"accuracy": float(result.get("accuracy", 0.0)),
		"evidence_quality": float(result.get("evidence_quality", 0.0)),
		"trust_delta": float(result.get("trust_delta", 0.0)),
		"timing": str(result.get("timing", "")),
		"pay": int(result.get("pay", 0)),
		"bonus": int(result.get("bonus", 0)),
		"rank": str(result.get("rank", "")),
		"trust": int(result.get("trust", 0)),
		"day_score": int(result.get("day_score", 0)),
	}
	return out

static func to_line(record: Dictionary) -> String:
	return JSON.stringify(record)

static func from_line(line: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(line)
	if not parsed is Dictionary: return {}
	return normalize(parsed)

# Schema check: exactly the documented keys at every level.
static func is_valid(record: Dictionary) -> bool:
	if record.keys().size() != TOP_KEYS.size(): return false
	for key in TOP_KEYS:
		if not record.has(key): return false
	for pair in [["inputs", INPUT_KEYS], ["context", CONTEXT_KEYS], ["result", RESULT_KEYS]]:
		var part: Variant = record[pair[0]]
		if not part is Dictionary or part.keys().size() != pair[1].size(): return false
		for key in pair[1]:
			if not part.has(key): return false
	return int(record.v) == VERSION and str(record.day_id) != ""

extends RefCounted
# T-035: the scripted steps of the five tutorial days. Each step is a check on the player's REAL state
# (opened a file, added a Sheet step, pinned a chart, attached it, chose a finding, wrote the forecast, sent),
# so the coach marks react to actions instead of timers. The words of each step live in strings_v2.learn.tutorial.
# Headless; reads only public session state. The expected findings are never mentioned here.
# Step: [id, check, argument, extra]. Checks: opened, manual (Continue button), op (a Sheet step with that
# operation), op_count (at least `extra` steps with that operation), chart (a pinned chart of that type),
# attached, finding, composed, sent.
const STEPS := {
	1: [["open", "opened"], ["look", "manual"], ["dedupe", "op", "dedupe"], ["standardize", "op", "standardize"], ["group", "op", "group"], ["chart", "chart", "bar"], ["attach", "attached"], ["finding", "finding"], ["forecast", "composed"], ["send", "sent"]],
	2: [["open", "opened"], ["line", "chart", "line"], ["attach", "attached"], ["outliers", "op", "outliers"], ["finding", "finding"], ["forecast", "composed"], ["send", "sent"]],
	3: [["open", "opened"], ["look", "manual"], ["filter", "op", "filter"], ["group", "op", "group"], ["chart", "chart", "bar"], ["attach", "attached"], ["finding", "finding"], ["forecast", "composed"], ["send", "sent"]],
	4: [["open", "opened"], ["group", "op", "group"], ["rate", "op", "computed"], ["finding", "finding"], ["forecast", "composed"], ["send", "sent"]],
	5: [["open", "opened"], ["group", "op", "group"], ["rate", "op", "computed"], ["finding", "finding"], ["forecast", "composed"], ["send", "sent"]]}

static func step_ids(day: int) -> Array:
	return STEPS.get(day, []).map(func(s): return s[0])

static func _done(step: Array, ctx: Dictionary) -> bool:
	match str(step[1]):
		"opened": return int(ctx.get("opened", 0)) > 0
		"manual": return ctx.get("manual", {}).has(step[0]) and int(ctx.get("opened", 0)) > 0
		"op": return ctx.get("ops", []).has(step[2])
		"op_count": return ctx.get("ops", []).count(step[2]) >= int(step[3])
		"chart": return ctx.get("chart_types", []).has(step[2])
		"attached": return int(ctx.get("attached", 0)) > 0
		"finding": return int(ctx.get("findings", 0)) > 0
		"composed": return bool(ctx.get("composed", false))
		"sent": return bool(ctx.get("sent", false))
	return false

# {steps: [{id, done}], index (first step not done, -1 when all are), total, done_count, complete}
static func status(day: int, ctx: Dictionary) -> Dictionary:
	var list: Array = STEPS.get(day, [])
	var out: Array = []
	var index := -1
	var done_count := 0
	for i in list.size():
		var ok := _done(list[i], ctx)
		out.append({"id": list[i][0], "done": ok})
		if ok: done_count += 1
		elif index < 0: index = i
	return {"steps": out, "index": index, "total": list.size(), "done_count": done_count, "complete": not list.is_empty() and index < 0}

# The context from a DataSession (public state only) plus what the desktop knows about Mail.
static func context(session: RefCounted, composed: bool, sent: bool, manual: Dictionary) -> Dictionary:
	var ops: Array = []
	for id in session.sheets:
		for step in session.sheets[id].steps(): ops.append(str(step.get("op", "")))
	var chart_types: Array = []
	for p in session.pins:
		if p.type == "chart": chart_types.append(str(p.spec.get("type", "")))
	var findings := 0
	for id in session.findings: findings += session.findings[id].size()
	return {"opened": session.opened.size(), "ops": ops, "chart_types": chart_types, "attached": session.attached.size(), "findings": findings, "composed": composed, "sent": sent, "manual": manual}

extends RefCounted
# T-035: maps a generated file (dataset type + defect types + day) to one case of data/cases.json.
# Hidden side: the defect types are known only to the engine and to review code. The UI never calls this
# with a run's defects before the review; DataGame exposes the public parts through case_public().
# Rule: the case whose catalog defects best overlap the file's defects wins (overlap x10, defects the file
# does not have x-4, same dataset type +6, closeness of difficulty to the file's defect count and day).
# No overlap at all: the closest case by dataset type with no defects (a statistical trap), else the first case.
const Content = preload("res://scripts/learn/content.gd")

static func wanted(dirt: Array) -> Dictionary:
	var out := {}
	for d in dirt:
		for name in Content.DIRT_TO_CASE.get(str(d), []): out[name] = true
	return out

# Returns the full catalog entry (callers decide which parts to show) or {} when the catalog is empty.
static func for_file(dataset: String, dirt: Array, day: int) -> Dictionary:
	var cases: Array = Content.cases()
	if cases.is_empty(): return {}
	var want := wanted(dirt)
	var target := clampf(float(dirt.size()) + float(day) / 6.0, 1.0, 5.0)
	var best := {}
	var best_score := -1000000.0
	for c in cases:
		var overlap := 0
		for name in c.dirt:
			if want.has(name): overlap += 1
		if overlap == 0 and not want.is_empty(): continue
		var missing: int = c.dirt.size() - overlap
		var score := float(overlap) * 10.0 - float(missing) * 4.0
		if c.dataset_type == dataset: score += 6.0
		score -= absf(float(c.difficulty) - target) * 0.5
		if score > best_score:
			best_score = score
			best = c
	if not best.is_empty(): return best
	for c in cases:
		if c.dirt.is_empty() and c.dataset_type == dataset: return c
	return cases[0]

# Public view of a case: id, title and skill only.
static func public(c: Dictionary) -> Dictionary:
	if c.is_empty(): return {}
	return {"id":c.id, "title":c.title, "skill":c.skill}

static func by_trap(trap_id: String, dataset: String = "") -> Dictionary:
	var fallback := {}
	for c in Content.cases():
		if c.trap_id != trap_id: continue
		if dataset == "" or c.dataset_type == dataset: return c
		if fallback.is_empty(): fallback = c
	return fallback

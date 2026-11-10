extends RefCounted
# T-033: ordered list of steps over a raw dataset. The result always recomputes from raw.
# A step that fails is reported (ok:false, error) and skipped, so one bad step never breaks the rest.
const Ops = preload("res://scripts/data/ops.gd")
const AGGREGATING := ["group", "pivot"]
var raw: RefCounted
var context: Dictionary = {}
var steps: Array = []
var _undo: Array = []
var _redo: Array = []

func _init(p_raw: RefCounted = null, p_context: Dictionary = {}) -> void:
	raw = p_raw
	context = p_context

func _snapshot() -> void:
	_undo.append(steps.duplicate(true))
	_redo.clear()
	if _undo.size() > 100: _undo.pop_front()

func add(step: Dictionary, index: int = -1) -> void:
	_snapshot()
	if index < 0 or index >= steps.size(): steps.append(step.duplicate(true))
	else: steps.insert(index, step.duplicate(true))

func edit(index: int, step: Dictionary) -> bool:
	if index < 0 or index >= steps.size(): return false
	_snapshot()
	steps[index] = step.duplicate(true)
	return true

func delete(index: int) -> bool:
	if index < 0 or index >= steps.size(): return false
	_snapshot()
	steps.remove_at(index)
	return true

func move(from: int, to: int) -> bool:
	if from < 0 or from >= steps.size() or to < 0 or to >= steps.size(): return false
	if from == to: return true
	_snapshot()
	var step = steps[from]
	steps.remove_at(from)
	steps.insert(to, step)
	return true

func reset() -> void:
	if steps.is_empty(): return
	_snapshot()
	steps.clear()

func undo() -> bool:
	if _undo.is_empty(): return false
	_redo.append(steps.duplicate(true))
	steps = _undo.pop_back()
	return true

func redo() -> bool:
	if _redo.is_empty(): return false
	_undo.append(steps.duplicate(true))
	steps = _redo.pop_back()
	return true

func to_array() -> Array:
	return steps.duplicate(true)

static func from_array(p_raw: RefCounted, list: Array, p_context: Dictionary = {}) -> RefCounted:
	var p = load("res://scripts/data/pipeline.gd").new(p_raw, p_context)
	p.steps = list.duplicate(true)
	return p

# Runs the first `upto` steps (-1 = all). Returns the final dataset, a per-step report
# (rows_in, rows_out, ok, error) and `row_level`: the table just before the first aggregating step.
func run(upto: int = -1) -> Dictionary:
	var current: RefCounted = raw.copy()
	var report: Array = []
	var row_level: RefCounted = null
	var count: int = steps.size() if upto < 0 else mini(upto, steps.size())
	for i in count:
		var step: Dictionary = steps[i]
		var before: int = current.row_count()
		if row_level == null and AGGREGATING.has(str(step.get("op", ""))): row_level = current
		var result: Dictionary = Ops.apply(current, step, context)
		if result.ok:
			current = result.dataset
			report.append({"index":i, "op":step.get("op", ""), "ok":true, "rows_in":before, "rows_out":current.row_count(), "error":"", "detail":""})
		else:
			report.append({"index":i, "op":step.get("op", ""), "ok":false, "rows_in":before, "rows_out":before, "error":result.error, "detail":result.detail})
	return {"dataset":current, "row_level":row_level if row_level != null else current, "report":report, "failed":report.filter(func(r): return not r.ok).size()}

# Row-count preview of a candidate step at `index` without changing the pipeline.
func preview(step: Dictionary, index: int = -1) -> Dictionary:
	var at: int = steps.size() if index < 0 else clampi(index, 0, steps.size())
	var base := run(at)
	var result: Dictionary = Ops.apply(base.dataset, step, context)
	if not result.ok: return {"ok":false, "error":result.error, "detail":result.detail, "rows_before":base.dataset.row_count()}
	return {"ok":true, "rows_before":base.dataset.row_count(), "rows_after":result.dataset.row_count()}

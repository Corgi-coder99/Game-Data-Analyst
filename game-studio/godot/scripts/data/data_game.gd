extends RefCounted
# T-033: public facade of the data engine for the future UI (T-034). Not wired into the game flow yet.
# Before the day's review only the dirty files and the player's own results are returned. The hidden
# generator state, manifest, reference and truth are reachable only through review(day).
# Source of hidden state: the world's scenario object (`world._scenario`), read only by generator.gd.
const Generator = preload("res://scripts/data/generator.gd")
const Reference = preload("res://scripts/data/reference.gd")
const Pipeline = preload("res://scripts/data/pipeline.gd")
const Charts = preload("res://scripts/data/charts.gd")
const Grader = preload("res://scripts/data/grader.gd")
const Loader = preload("res://scripts/data.gd")
var _gen: RefCounted
var _ref: RefCounted
var _charts: RefCounted
var _grader: RefCounted
var _world: RefCounted
var _cache: Dictionary = {}
var _submissions: Dictionary = {}
var _reviewed: Dictionary = {}

# `source` is a WorldGame (then the day gate follows the world's own review) or a bare scenario.
func _init(source: RefCounted, seed_value: int, cfg: Dictionary = {}) -> void:
	var scenario: RefCounted = source.get("_scenario") if source.get("_scenario") != null else source
	if source.get("_scenario") != null: _world = source
	var config: Dictionary = cfg if not cfg.is_empty() else Loader.load_json("res://data/datasets.json")
	_gen = Generator.new(scenario, seed_value, config)
	_ref = Reference.new(config)
	_charts = Charts.new(config)
	_grader = Grader.new(config)

func _files(day: int) -> Array:
	if not _cache.has(day): _cache[day] = _gen.generate(day)
	return _cache[day]

func _file(day: int, file_id: String) -> Dictionary:
	if not _allowed(day): return {}
	for f in _files(day):
		if f.id == file_id: return f
	return {}

func _allowed(day: int) -> bool:
	if day < 1: return false
	if _world != null and day > int(_world.status().day): return false
	return true

# Test/offline switch for a bare scenario; with a world the world's own review is the gate.
func mark_reviewed(day: int) -> void:
	_reviewed[day] = true

func _is_reviewed(day: int) -> bool:
	if _world != null: return _world.review(day).has("day")
	return _reviewed.has(day)

func files_today(day: int) -> Array:
	if not _allowed(day): return []
	var out: Array = []
	for f in _files(day):
		var tables: Array = []
		for t in f.aux: tables.append(f.aux[t].to_dict())
		out.append({"id":f.id, "name":f.name, "title":f.title, "table":f.raw.to_dict(), "row_count":f.raw.row_count(), "lookup_tables":tables, "findings":_ref.options(f)})
	return out

func _run(f: Dictionary, steps: Array) -> Dictionary:
	return Pipeline.from_array(f.raw, steps, f.aux).run()

func apply_pipeline(day: int, file_id: String, steps: Array) -> Dictionary:
	var f := _file(day, file_id)
	if f.is_empty(): return {"ok":false, "error":"unknown_file"}
	var run := _run(f, steps)
	return {"ok":true, "table":run.dataset.to_dict(), "row_count":run.dataset.row_count(), "report":run.report, "failed":run.failed}

func chart_data(day: int, file_id: String, steps: Array, spec: Dictionary) -> Dictionary:
	var f := _file(day, file_id)
	if f.is_empty(): return {"ok":false, "error":"unknown_file"}
	return _charts.series(_run(f, steps).dataset, spec)

func check_chart(day: int, file_id: String, steps: Array, spec: Dictionary) -> Dictionary:
	var f := _file(day, file_id)
	if f.is_empty(): return {"ok":false, "error":"unknown_file"}
	return {"ok":true, "flags":_charts.check(_run(f, steps).dataset, spec)}

# analysis: {pipeline: [steps], chart: {spec}, findings: {id: value}}. Stored, never graded here.
func submit_analysis(day: int, file_id: String, analysis: Dictionary) -> Dictionary:
	var f := _file(day, file_id)
	if f.is_empty(): return {"ok":false, "error":"unknown_file"}
	if _is_reviewed(day): return {"ok":false, "error":"day_closed"}
	_submissions["%d|%s" % [day, file_id]] = analysis.duplicate(true)
	return {"ok":true}

# Only after the day's review: manifest, reference result, truth, hidden values and the grade.
func review(day: int) -> Dictionary:
	if not _allowed(day) or not _is_reviewed(day): return {"ok":false, "error":"day_not_reviewable"}
	var out: Array = []
	for f in _files(day):
		var ev: Dictionary = _ref.evaluate_reference(f)
		var key := "%d|%s" % [day, f.id]
		var submission: Dictionary = _submissions.get(key, {})
		var grade: Dictionary = _grader.grade(f, _ref, ev.truth, submission)
		var manifest: Array = f.manifest.map(func(m): return {"type":m.type, "columns":m.columns, "rows":m.rows.size(), "row_ids":m.rows})
		out.append({"id":f.id, "name":f.name, "submitted":_submissions.has(key), "dirt":f.dirt_types, "manifest":manifest, "reference_steps":_ref.steps(f), "reference_table":ev.dataset.to_dict(), "truth":ev.truth, "hidden":f.hidden.duplicate(), "grade":grade})
	return {"ok":true, "day":day, "files":out}

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
# T-035: learning layer hooks (case mapping, hints, tutorial files). Hidden facts stay in this class.
const CaseMap = preload("res://scripts/learn/case_map.gd")
const Content = preload("res://scripts/learn/content.gd")
const TutorialFiles = preload("res://scripts/learn/tutorial_files.gd")
var _tutorial := false
var _gen: RefCounted
var _ref: RefCounted
var _charts: RefCounted
var _grader: RefCounted
var _world: RefCounted
var _cfg_data: Dictionary = {}
var _cache: Dictionary = {}
var _submissions: Dictionary = {}
var _reviewed: Dictionary = {}

# `source` is a WorldGame (then the day gate follows the world's own review) or a bare scenario.
func _init(source: RefCounted, seed_value: int, cfg: Dictionary = {}) -> void:
	var scenario: RefCounted = source.get("_scenario") if source.get("_scenario") != null else source
	if source.get("_scenario") != null: _world = source
	var config: Dictionary = cfg if not cfg.is_empty() else Loader.load_json("res://data/datasets.json")
	_cfg_data = config.get("data", {})
	_gen = Generator.new(scenario, seed_value, config)
	_ref = Reference.new(config)
	_charts = Charts.new(config)
	_grader = Grader.new(config)

func _files(day: int) -> Array:
	if not _cache.has(day):
		_cache[day] = [TutorialFiles.build(day)] if tutorial_day(day) else _gen.generate(day)
	return _cache[day]

# T-035: in tutorial mode days 1..5 use the five hand-built files instead of generated ones (set before day 1).
func set_tutorial(on: bool) -> void:
	_tutorial = on
	_cache.clear()

func tutorial_day(day: int) -> bool:
	return _tutorial and day >= 1 and day <= TutorialFiles.DAYS

# T-035: skill-based difficulty adjustment (learn/ramp.gd) for one day; ignored once the day's files exist.
func set_adjustment(day: int, adjustment: Dictionary) -> void:
	if not _cache.has(day) and not tutorial_day(day): _gen.adjustments[day] = adjustment.duplicate(true)

func _case_of(f: Dictionary) -> Dictionary:
	if f.has("case_id"): return Content.case_by_id(str(f.case_id))
	return CaseMap.for_file(str(f.name), f.dirt_types, int(f.get("day", 1)))

# T-035: the public part of the day's case: id, title and skill only (no trap, steps or wrong paths).
func case_public(day: int, file_id: String) -> Dictionary:
	var f := _file(day, file_id)
	return {} if f.is_empty() else CaseMap.public(_case_of(f))

# T-035: Handbook cards of the case, for tutorial days only (a guided case may open its cards at once).
func tutorial_cards(day: int, file_id: String) -> Array:
	var f := _file(day, file_id)
	return f.cards.duplicate() if not f.is_empty() and f.has("cards") else []

# T-035: structured hint parts for one level (1 problem type, 2 method card, 3 Sheet operation families).
# No text and no reference step leaves this class; learn/hints.gd turns the parts into words.
func hint(day: int, file_id: String, level: int) -> Dictionary:
	var f := _file(day, file_id)
	if f.is_empty() or _is_reviewed(day): return {"ok":false, "error":"day_closed"}
	if level < 1 or level > 3: return {"ok":false, "error":"bad_level"}
	var c := _case_of(f)
	var families: Array = []
	for step in _ref.steps(f):
		var family: String = str(Content.OP_FAMILY.get(str(step.op), ""))
		if family != "" and not families.has(family): families.append(family)
	families.sort()
	return {"ok":true, "level":level, "case_id":str(c.get("id", "")), "skill":str(c.get("skill", "data_cleaning")), "card_id":str(c.handbook_card_ids[0]) if not c.is_empty() and not c.handbook_card_ids.is_empty() else "", "families":families}

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

# T-034: the scoring hook used by WorldGame (via the flow). `analysis` is the report payload:
# {pipelines: {file_id: steps}, attachments: [{type, file_id, spec, steps, ...}], findings: {file_id: {id: value}}}.
# Stores one submission per file and returns only a signed number (no truth leaves this class).
# Default config: a good analysis (grade >= analysis_good) adds analysis_bonus * grade; the penalty is 0.
func score_analysis(day: int, analysis: Dictionary) -> float:
	if not _allowed(day) or _is_reviewed(day): return 0.0
	var ids: Array = []
	for source in [analysis.get("pipelines", {}), analysis.get("findings", {})]:
		for id in source:
			if not ids.has(id): ids.append(id)
	for item in analysis.get("attachments", []):
		if item is Dictionary and not ids.has(item.get("file_id", "")): ids.append(item.get("file_id", ""))
	var total := 0.0
	var count := 0
	var answered := 0
	for id in ids:
		var f := _file(day, str(id))
		if f.is_empty(): continue
		var chart: Dictionary = {}
		for item in analysis.get("attachments", []):
			if item is Dictionary and item.get("file_id", "") == id and item.get("type", "") == "chart" and chart.is_empty(): chart = item.get("spec", {})
		var submission := {"pipeline":analysis.get("pipelines", {}).get(id, []), "chart":chart, "findings":analysis.get("findings", {}).get(id, {})}
		submit_analysis(day, str(id), submission)
		answered += submission.findings.size()
		total += float(_grader.grade(f, _ref, _ref.evaluate_reference(f).truth, submission).total)
		count += 1
	if count == 0: return 0.0
	var grade := total / count
	var cfg: Dictionary = _cfg_data
	if grade >= float(cfg.get("analysis_good", 0.6)): return float(cfg.get("analysis_bonus", 1.0)) * grade
	if answered > 0 and grade < float(cfg.get("analysis_wrong_below", 0.3)): return -float(cfg.get("analysis_wrong_penalty", 0.0))
	return 0.0

# T-034: the review record for the "Your analysis" step; same gate as review().
func analysis_review(day: int) -> Dictionary:
	return review(day)

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
		var case_entry := _case_of(f)
		out.append({"case_id":str(case_entry.get("id", "")), "id":f.id, "name":f.name, "submitted":_submissions.has(key), "dirt":f.dirt_types, "manifest":manifest, "reference_steps":_ref.steps(f), "reference_table":ev.dataset.to_dict(), "truth":ev.truth, "hidden":f.hidden.duplicate(), "grade":grade})
	return {"ok":true, "day":day, "files":out}

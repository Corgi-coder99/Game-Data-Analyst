extends SceneTree
# T-034 headless logic tests: step forms, Sheet model, session (files, charts, pins, dashboard, findings),
# payload shape, scoring hook, bots through the UI-level API, leak scan of the new UI scripts.
const Game = preload("res://scripts/world/world_game.gd")
const Session = preload("res://scripts/data/session.gd")
const Sheet = preload("res://scripts/data/sheet_model.gd")
const Forms = preload("res://scripts/data/step_forms.gd")
const Loader = preload("res://scripts/data.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func eq(a: Variant, b: Variant, message: String) -> void:
	check(a == b, "%s (got %s, want %s)" % [message, str(a), str(b)])

func _initialize() -> void:
	call_deferred("run")

func make(seed_value: int = 104, day_count: int = 1) -> Array:
	var game := Game.new(seed_value, 10)
	var session := Session.new(game, seed_value)
	for d in day_count:
		if d > 0:
			game.submit_report({"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]})
			game.end_day()
		game.begin_day()
	session.begin_day(int(game.status().day))
	return [game, session]

func test_forms() -> void:
	eq(Forms.OPS.size(), 13, "13 operations in the toolbar")
	var fixture := Sheet.new({"id":"f", "title":"T", "table":{"name":"t", "columns":[{"name":"a", "type":"text"}, {"name":"n", "type":"text"}, {"name":"d", "type":"text"}], "rows":[["x", "1", "05/03/2026"], ["X ", "2k", "2026-03-06"], ["x", "1", "05/03/2026"], ["y", "", "Mar 7, 2026"], ["z", "4", "2026-03-08"], ["z", "5", "2026-03-09"], ["z", "6", "2026-03-10"]]}, "lookup_tables":[{"name":"lk", "columns":[{"name":"a", "type":"text"}, {"name":"w", "type":"text"}], "rows":[["x", "one"], ["y", "two"]]}]})
	for op in Forms.OPS:
		check(Forms.fields(op).size() > 0 and Forms.NAMES.has(op) and Forms.TITLES.has(op), "fields for " + op)
		check(Forms.describe({"op":op}) != "", "describe " + op)
	var params := {
		"sort":{"col":"a", "order":"descending"}, "filter":{"col":"a", "cmp":"==", "value":"x"}, "dedupe":{"cols":[]},
		"missing":{"col":"n", "mode":"drop", "zero":"no"}, "standardize":{"col":"a", "merge":["X "], "into":"x", "case":"none"},
		"convert":{"col":"n", "mode":"number"}, "parse_date":{"col":"d", "format":"auto"},
		"computed":{"name":"n2", "fn":"mul", "a":"n", "b":Forms.NONE, "b_value":2.0, "window":3},
		"group":{"by":["a"], "col":"n", "fn":"count", "col2":Forms.NONE, "fn2":"sum"},
		"pivot":{"index":"a", "columns":"a", "values":"n", "fn":"count"},
		"join":{"other":"lk", "left_key":"a", "right_key":"a", "join_type":"left"},
		"outliers":{"col":"n", "method":"iqr", "k":1.5, "action":"flag"}, "sample":{"n":2, "mode":"head", "seed":1}}
	for op in Forms.OPS:
		var p: Dictionary = Forms.default_params(op, "a")
		p.merge(params[op], true)
		var step: Dictionary = Forms.build(op, p)
		check(step.get("op", "") == op and Forms.complete(op, p), "complete form builds " + op)
		var r := fixture.preview(step)
		check(r.ok, "preview ok for %s: %s" % [op, str(r)])
	check(not Forms.complete("sort", Forms.default_params("sort")), "sort without a column is incomplete")
	eq(Forms.typed("12"), 12, "typed int")
	eq(Forms.typed("1.5"), 1.5, "typed float")
	eq(Forms.typed(" ab "), "ab", "typed text")
	eq(Forms.parse_rates("vnd=0.5, usd=1"), {"VND":0.5, "USD":1.0}, "rates text")

func test_roundtrip() -> void:
	var steps: Array = [
		{"op":"sort", "col":"a", "desc":true}, {"op":"filter", "col":"a", "cmp":">", "value":3}, {"op":"filter", "col":"a", "cmp":"missing"},
		{"op":"dedupe", "cols":["a", "b"]}, {"op":"missing", "col":"*", "mode":"drop", "zero_missing":false}, {"op":"missing", "col":"a", "mode":"value", "zero_missing":true, "value":0},
		{"op":"standardize", "col":"a", "case":"title", "map":{"x":"X", "y":"X"}}, {"op":"convert", "col":"a", "kind":"number"}, {"op":"convert", "col":"a", "kind":"scale", "factor":2.0},
		{"op":"parse_date", "col":"d", "format":"dmy"}, {"op":"computed", "name":"n", "fn":"div", "a":"a", "b":"b"}, {"op":"computed", "name":"n", "fn":"moving_avg", "a":"a", "window":4},
		{"op":"group", "by":["a"], "aggs":[{"col":"b", "fn":"sum"}, {"col":"c", "fn":"mean"}]}, {"op":"pivot", "index":"a", "columns":"b", "values":"c", "fn":"sum"},
		{"op":"join", "other":"lk", "left_key":"a", "right_key":"k", "kind":"inner"}, {"op":"outliers", "col":"a", "method":"z", "k":3.0, "action":"remove"}, {"op":"sample", "n":5, "mode":"seeded", "seed":7}]
	for step in steps:
		var rebuilt: Dictionary = Forms.build(step.op, Forms.params_from_step(step))
		check(JSON.stringify(rebuilt) == JSON.stringify(step) or str(rebuilt) == str(step), "step round trip %s: %s" % [step.op, str(rebuilt)])
		check(Forms.describe(step) != step.op, "describe in words: " + step.op)

func test_sheet() -> void:
	var made := make()
	var session: RefCounted = made[1]
	check(session.files.size() >= 1, "day 1 has a file")
	var fid: String = session.files[0].id
	var before_minutes: int = made[0].status().minutes
	var sheet: RefCounted = session.open_file(fid)
	check(sheet != null, "open file")
	eq(made[0].status().minutes, before_minutes + session.limit("minutes_per_file", 10), "opening a file costs minutes_per_file")
	eq(made[0].status().energy, 3, "opening a file costs no Energy")
	session.open_file(fid)
	eq(made[0].status().minutes, before_minutes + session.limit("minutes_per_file", 10), "reopening is free")
	var raw_rows: int = sheet.row_count()
	var p: Dictionary = sheet.preview({"op":"dedupe", "cols":[]})
	check(p.ok and p.rows_before == raw_rows and p.rows_after <= raw_rows, "row count preview")
	check(not sheet.add_step({"op":"sort", "col":"nope"}).ok and sheet.steps().is_empty(), "failing step is not added")
	var first: Dictionary = sheet.add_step({"op":"dedupe", "cols":[]})
	check(first.ok and sheet.steps().size() == 1 and sheet.selected_step == 0, "add step")
	sheet.add_step({"op":"sort", "col":sheet.table().cols[0], "desc":true})
	eq(sheet.steps().size(), 2, "two steps")
	check(sheet.move_step(1, -1) and sheet.steps()[0].op == "sort", "reorder up")
	check(sheet.undo() and sheet.steps()[0].op == "dedupe", "undo restores order")
	check(sheet.redo() and sheet.steps()[0].op == "sort", "redo")
	check(sheet.edit_step(0, {"op":"sort", "col":sheet.table().cols[0], "desc":false}).ok and not sheet.steps()[0].desc, "edit step")
	check(not sheet.edit_step(9, {"op":"dedupe"}).ok, "edit out of range")
	check(sheet.delete_step(0) and sheet.steps().size() == 1, "delete step")
	var diff: Dictionary = sheet.step_diff(0)
	eq(diff.rows_in - diff.rows_out, diff.removed.size(), "diff removed count equals row difference")
	eq(diff.removed_table.row_count(), diff.removed.size(), "removed rows table")
	sheet.reset()
	check(sheet.steps().is_empty() and sheet.row_count() == raw_rows and sheet.can_undo(), "reset to raw, undoable")
	check(sheet.undo() and sheet.steps().size() == 1, "undo a reset")
	# stats and profile
	var st: Dictionary = {}
	for c in sheet.table().cols.size():
		st = sheet.column_stats(c)
		if st.numeric > 0: break
	check(st.has("mean") and st.has("median") and st.has("min") and st.has("max") and st.has("nulls") and st.count > 0, "summary stats of a numeric column")
	var profile: Array = sheet.profile()
	eq(profile.size(), sheet.table().cols.size(), "profile has one entry per column")
	for item in profile:
		for key in item: check(not (str(key) in ["defect", "dirt", "manifest", "hint"]), "profile key " + str(key))
	# the same result as the public API
	var api: Dictionary = session.data.apply_pipeline(1, fid, sheet.steps())
	eq(api.table.rows, sheet.table().rows, "sheet result equals DataGame.apply_pipeline")
	# highlight of changed rows after a text clean
	sheet.reset()
	var text_col := ""
	for c in sheet.table().cols.size():
		if sheet.table().types[c] in ["text", "category"] and not sheet.distinct_values(c).is_empty():
			text_col = sheet.table().cols[c]
			break
	sheet.add_step({"op":"standardize", "col":text_col, "case":"upper", "map":{}})
	check(sheet.highlighted().size() >= 0 and sheet.step_diff(0).changed.size() == sheet.highlighted().size(), "highlight set matches diff")

func test_session() -> void:
	var made := make()
	var game: RefCounted = made[0]
	var session: RefCounted = made[1]
	var fid: String = session.files[0].id
	check(session.is_new(fid), "new badge before opening")
	check(session.messy_hint() != "", "plain difficulty hint")
	var sheet: RefCounted = session.open_file(fid)
	check(not session.is_new(fid), "badge gone after opening")
	var spec: Dictionary = session.default_spec(fid, "raw")
	var series: Dictionary = session.chart_series(fid, "raw", spec)
	check(series.get("ok", false), "default chart draws")
	check(session.chart_flags(fid, "raw", spec).any(func(f): return f.id == "missing_units"), "missing units flag")
	var before: int = game.status().minutes
	var pin: String = session.pin_chart(fid, "raw", spec, "My chart")
	check(pin != "" and session.pins.size() == 1 and session.dashboard[0] == pin, "pin chart lands on the dashboard")
	eq(game.status().minutes, before + session.limit("minutes_per_chart", 10), "pinning costs minutes_per_chart")
	check(not session.pin_chart(fid, "raw", {"type":"bar", "x":"zzz", "y":"zzz"}).is_empty() == false, "bad chart is not pinned")
	check(session.pin_table(fid) != "", "pin table")
	var col := ""
	for c in sheet.table().cols.size():
		if sheet.column_stats(c).get("numeric", 0) > 0:
			col = sheet.table().cols[c]
			break
	if col != "": check(session.pin_kpi(fid, col, "count", "Rows") != "", "pin KPI")
	while session.pins.size() < 4: session.pin_table(fid)
	eq(session.pin_table(fid), "", "fifth pin refused")
	eq(session.pins.size(), 4, "max 4 pinned")
	for i in 3: check(session.attach(session.pins[i].id), "attach %d" % i)
	check(not session.attach(session.pins[3].id), "fourth attachment refused")
	session.detach(session.pins[0].id)
	check(session.attach(session.pins[3].id), "attach after detach")
	var ids: Array = session.pins.map(func(p): return p.id)
	check(session.place(ids[3], 0) and session.dashboard[0] == ids[3] and session.dashboard.has(ids[0]), "placing swaps cells")
	session.unpin(ids[3])
	check(not session.dashboard.has(ids[3]) and not session.attached.has(ids[3]), "unpin clears attachment and cell")
	# findings
	var options: Array = session.options(fid)
	check(options.size() >= 1 and options[0].has("id"), "finding options come from the engine")
	session.set_finding(fid, options[0].id, "x")
	eq(session.finding(fid, options[0].id), "x", "finding stored")
	session.set_finding(fid, options[0].id, null)
	check(session.findings[fid].is_empty(), "finding cleared")
	session.set_finding(fid, options[0].id, "y")
	var payload: Dictionary = session.payload()
	check(payload.has("attachments") and payload.has("findings") and payload.has("pipelines"), "payload shape")
	eq(payload.attachments.size(), session.attached.size(), "payload attachments")
	var empty := make()
	eq(empty[1].payload(), {}, "no data work gives no analysis")
	# the world accepts the payload and rejects a non-dictionary
	var bad: Dictionary = game.submit_report({"question_id":game.question_today().id, "forecast":"tang", "confidence":"vua", "evidence":[], "actions":[], "analysis":5})
	eq(bad, {"ok":false, "error":"invalid_analysis"}, "analysis must be a dictionary")
	check(game.submit_report({"question_id":game.question_today().id, "forecast":"tang", "confidence":"vua", "evidence":[], "actions":[], "analysis":payload}).ok, "report with analysis accepted")

func play_day1(seed_value: int, bot: String) -> Dictionary:
	var made := make(seed_value)
	var game: RefCounted = made[0]
	var session: RefCounted = made[1]
	var input := {"question_id":game.question_today().id, "forecast":"ngang", "confidence":"vua", "evidence":[], "actions":[]}
	var grades: Array = []
	if bot != "none":
		for f in session.files:
			var internal: Dictionary = session.data._file(1, f.id)
			var truth: Array = session.data._ref.evaluate_reference(internal).truth
			var sheet: RefCounted = session.open_file(f.id)
			var steps: Array = session.data._ref.steps(internal) if bot == "cleaner" else [{"op":"missing", "col":"*", "mode":"drop"}]
			for s in steps: sheet.add_step(s)
			var spec: Dictionary = session.default_spec(f.id, "clean")
			spec.merge({"sort":"desc", "y_label":"Value", "title":"Chart"}, true)
			var pin: String = session.pin_chart(f.id, "clean", spec)
			if pin != "": session.attach(pin)
			for t in truth:
				if bot == "cleaner":
					session.set_finding(f.id, t.id, t.value if t.value == null else (t.value if not t.value is Dictionary else {"direction":t.value.direction, "band":t.value.band}))
				else:
					var wrong: Variant = null
					for o in session.options(f.id):
						if o.id != t.id: continue
						if o.has("choices"):
							for ch in o.choices:
								if ch != t.value: wrong = ch
						else:
							for d in o.directions:
								if not t.value is Dictionary or d != t.value.direction: wrong = {"direction":d, "band":o.bands[0]}
					session.set_finding(f.id, t.id, wrong)
	var payload: Dictionary = session.payload()
	if not payload.is_empty(): input["analysis"] = payload
	check(game.submit_report(input).ok, "submit " + bot)
	game.end_day()
	var review: Dictionary = game.review(1)
	var out := {"delta":float(review.result.delta), "adjust":float(review.result.get("analysis", 0.0)), "has_key":review.result.has("analysis"), "status":game.status(), "payload":payload}
	var dg_review: Dictionary = session.data.review(1)
	var total := 0.0
	for rf in dg_review.files: total += float(rf.grade.total)
	out["grade"] = total / maxf(1.0, dg_review.files.size())
	return out

func test_bots() -> void:
	var sum_clean := 0.0
	var sum_sloppy := 0.0
	var n := 0
	for seed_value in [104, 7, 31, 88, 250, 999]:
		var none := play_day1(seed_value, "none")
		var clean := play_day1(seed_value, "cleaner")
		var sloppy := play_day1(seed_value, "sloppy")
		check(not none.has_key and none.adjust == 0.0, "no analysis: hook never called (seed %d)" % seed_value)
		check(clean.grade > sloppy.grade, "cleaner grade %.2f above sloppy %.2f (seed %d)" % [clean.grade, sloppy.grade, seed_value])
		check(clean.grade >= 0.6 and clean.adjust > 0.0 and clean.delta > none.delta - 0.0001 + clean.adjust - 0.2, "cleaner earns a positive bonus (seed %d, grade %.2f)" % [seed_value, clean.grade])
		# T-036: a sloppy analysis is now worse than no analysis (wrong-analysis penalty and chart flag penalty).
		check(sloppy.adjust < 0.0, "sloppy analysis costs trust with the tuned config (seed %d, %.1f)" % [seed_value, sloppy.adjust])
		eq(sloppy.delta, snappedf(none.delta + sloppy.adjust, 0.1), "the penalty is added to the report delta (seed %d)" % seed_value)
		eq(clean.delta, snappedf(none.delta + clean.adjust, 0.1), "bonus is added to the report delta (seed %d)" % seed_value)
		sum_clean += clean.grade
		sum_sloppy += sloppy.grade
		n += 1
	print("bots: cleaner mean grade %.3f, sloppy mean grade %.3f over %d seeds" % [sum_clean / n, sum_sloppy / n, n])

func test_scores_hook_config() -> void:
	# a non-zero penalty config hurts a confidently wrong analysis (T-036: the tuned default is above zero)
	var cfg: Dictionary = Loader.load_json("res://data/datasets.json").duplicate(true)
	check(float(cfg.data.analysis_wrong_penalty) > 0.0, "the tuned wrong-analysis penalty is above 0")
	cfg.data.analysis_wrong_penalty = 2.0
	var game := Game.new(104, 10)
	var session := Session.new(game, 104, cfg)
	game.begin_day()
	session.begin_day(1)
	var fid: String = session.files[0].id
	var sheet: RefCounted = session.open_file(fid)
	sheet.add_step({"op":"missing", "col":"*", "mode":"drop"})
	for o in session.options(fid):
		if o.has("choices"): session.set_finding(fid, o.id, o.choices[0])
	var adjust: float = session.data.score_analysis(1, session.payload())
	check(adjust <= 0.0, "configured penalty is not a bonus")
	# a closed day scores nothing
	game.submit_report({"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]})
	game.end_day()
	eq(session.data.score_analysis(1, session.payload()), 0.0, "closed day scores 0")

func test_leak_scan() -> void:
	var hidden_words := ["manifest", "reference", "truth", "recipe", "expected", "hidden", "dirt_types", "reference_steps", "evaluate_reference", "_ref", "_gen", "grader"]
	var ui_files: Array = ["res://scripts/data/session.gd", "res://scripts/data/sheet_model.gd", "res://scripts/data/step_forms.gd"]
	for dir in ["res://scripts/v2/data"]:
		if DirAccess.open(dir) == null: continue
		for filename in DirAccess.get_files_at(dir):
			if filename.ends_with(".gd"): ui_files.append(dir + "/" + filename)
	for filename in DirAccess.get_files_at("res://scripts/v2/windows"):
		if filename.begins_with("data_") or filename.begins_with("dash") or filename.begins_with("analysis"): ui_files.append("res://scripts/v2/windows/" + filename)
	for path in ui_files:
		var source := FileAccess.get_file_as_string(path)
		var code := ""
		for line in source.split("\n"):
			if not line.strip_edges().begins_with("#"): code += line.split(" #")[0] + "\n"
		for word in hidden_words:
			var pattern := RegEx.new()
			pattern.compile("\\b" + word + "\\b")
			check(pattern.search(code) == null, "%s does not mention %s" % [path, word])
		check(not code.contains("scripts/data/reference") and not code.contains("scripts/data/grader") and not code.contains("scripts/data/generator"), path + " does not load hidden engine parts")
	check(ui_files.size() >= 3, "scanned %d UI scripts" % ui_files.size())

func run() -> void:
	test_forms()
	test_roundtrip()
	test_sheet()
	test_session()
	test_bots()
	test_scores_hook_config()
	test_leak_scan()
	print("test_t034_logic: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

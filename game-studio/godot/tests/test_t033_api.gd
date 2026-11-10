extends SceneTree
# T-033: charts and quality checker, grader, public facade, leak probe, world isolation, source scans.
const DS = preload("res://scripts/data/dataset.gd")
const Charts = preload("res://scripts/data/charts.gd")
const Grader = preload("res://scripts/data/grader.gd")
const Gen = preload("res://scripts/data/generator.gd")
const Ref = preload("res://scripts/data/reference.gd")
const DataGame = preload("res://scripts/data/data_game.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Scenario = preload("res://scripts/world/world_scenario.gd")
const Loader = preload("res://scripts/data.gd")
const Sim = preload("res://scripts/sim/simulation.gd")
const FORBIDDEN_KEYS := ["manifest", "truth", "recipe", "expected", "hidden", "reference_steps", "reference_table", "dirt", "dirt_types", "row_ids", "rids", "grade", "pct", "state_direction", "variable", "defects", "reference", "answer", "scenario", "volatile", "kind", "state"]
const FORBIDDEN_TEXT := ["lai_suat", "ty_gia", "nguyen_lieu", "suc_mua", "chung_khoan", "tin_dung", "app_bug", "competitor_discount", "logging_error", "checkout_outage", "server_outage", "trend_shift", "bad_traffic", "price_fatigue", "late_partial", "mixed_units", "mixed_dates", "category_typos", "missing_blank", "missing_na", "missing_zero", "refunds_negative", "test_accounts", "join_key_mismatch", "subtotal_rows", "repeated_header", "manifest"]
var checks := 0
var failures := 0
var charts: RefCounted
var ref: RefCounted
var data_cfg: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 30: printerr("FAIL: ", message)

func eq(actual: Variant, expected: Variant, message: String) -> void:
	check(JSON.stringify(actual) == JSON.stringify(expected), "%s | got %s expected %s" % [message, JSON.stringify(actual), JSON.stringify(expected)])

func merge(base: Dictionary, patch: Dictionary) -> Dictionary:
	return base.merged(patch, true)

func flag_ids(ds: RefCounted, spec: Dictionary) -> Array:
	return charts.check(ds, spec).map(func(f): return f.id)

func test_charts() -> void:
	var sales := DS.make("s", ["region", "units", "price", "day"], ["category", "int", "float", "date"], [
		["Hanoi", 5, 2.0, "2026-03-01"], ["Hue", 3, 4.0, "2026-03-01"], ["Hanoi", 4, 2.5, "2026-03-02"], ["Danang", 8, 1.0, "2026-03-02"], ["Hue", 1, 3.0, "2026-03-03"], ["Saigon", 6, 5.0, "2026-03-03"]])
	var good := {"type":"bar", "x":"region", "y":"units", "agg":"sum", "sort":"desc", "y_label":"Units sold"}
	eq(flag_ids(sales, good), [], "a good bar chart has no flags")
	eq(charts.series(sales, good).series[0].points, [{"x":"Hanoi", "y":9.0}, {"x":"Danang", "y":8.0}, {"x":"Saigon", "y":6.0}, {"x":"Hue", "y":4.0}], "bar sum sorted desc")
	eq(charts.series(sales, merge(good, {"sort":"asc"})).series[0].points.map(func(p): return p.x), ["Hue", "Saigon", "Danang", "Hanoi"], "bar sorted asc")
	eq(charts.series(sales, merge(good, {"sort":"x"})).series[0].points.map(func(p): return p.x), ["Danang", "Hanoi", "Hue", "Saigon"], "bar sorted by label")
	eq(charts.series(sales, merge(good, {"sort":"none"})).series[0].points.map(func(p): return p.x), ["Hanoi", "Hue", "Danang", "Saigon"], "bar keeps first-appearance order")
	eq(charts.series(sales, merge(good, {"agg":"mean", "sort":"none"})).series[0].points[0], {"x":"Hanoi", "y":4.5}, "bar mean")
	eq(charts.series(sales, merge(good, {"agg":"count", "y":""})).series[0].points[0], {"x":"Hanoi", "y":2}, "bar count needs no y column")
	var split: Dictionary = charts.series(sales, merge(good, {"series":"day", "sort":"x"}))
	eq([split.series.size(), split.series[0].name, split.series[0].points], [3, "2026-03-01", [{"x":"Hanoi", "y":5.0}, {"x":"Hue", "y":3.0}]], "series split")
	eq(flag_ids(sales, merge(good, {"y_min":10})), ["truncated_bar_axis"], "truncated bar axis")
	eq(flag_ids(sales, merge(good, {"y_min":0})), [], "a bar axis from zero is fine")
	eq(flag_ids(sales, merge(good, {"y2":"price"})), ["dual_axis"], "dual axis")
	eq(flag_ids(sales, merge(good, {"sort":"none"})), ["unsorted_bars"], "unsorted bars")
	eq(flag_ids(sales, merge(good, {"sort":"x"})), ["unsorted_bars"], "alphabetical bars are not sorted by value")
	var dated := DS.make("d", ["day", "v"], ["date", "float"])
	for i in 5: dated.add_row(["2026-03-%02d" % (i + 1), i])
	eq(flag_ids(dated, {"type":"bar", "x":"day", "y":"v", "y_label":"v"}), [], "bars over dates keep their time order")
	dated.types[0] = "category"
	eq(flag_ids(dated, {"type":"bar", "x":"day", "y":"v", "y_label":"v"}), ["unsorted_bars"], "the same bars as plain categories are flagged")
	eq(flag_ids(sales, merge(good, {"y_label":""})), ["missing_units"], "missing units")
	eq(flag_ids(sales, merge(good, {"y_label":"   "})), ["missing_units"], "blank units")
	var many := DS.make("m", ["k", "v"], ["category", "float"])
	for i in 15: many.add_row(["c%02d" % i, i + 1.0])
	eq(flag_ids(many, {"type":"bar", "x":"k", "y":"v", "sort":"desc", "y_label":"v"}), ["too_many_categories"], "too many bars")
	eq(flag_ids(many, {"type":"pie", "x":"k", "y":"v"}), ["pie_too_many_slices"], "pie with too many slices")
	eq(flag_ids(sales, {"type":"pie", "x":"region", "y":"units"}), [], "pie with four slices is accepted")
	var spike := DS.make("t", ["day", "v"], ["date", "float"])
	var values := [10, 11, 10, 12, 11, 60, 10, 11]
	for i in values.size(): spike.add_row(["2026-03-%02d" % (i + 1), values[i]])
	var line := {"type":"line", "x":"day", "y":"v", "agg":"sum", "y_label":"Orders"}
	eq(flag_ids(spike, line), [], "a plain line has no flags")
	eq(flag_ids(spike, merge(line, {"smoothing":3})), ["smoothing_hides_spikes"], "smoothing a spike away")
	var calm := DS.make("t", ["day", "v"], ["date", "float"])
	for i in 8: calm.add_row(["2026-03-%02d" % (i + 1), 10 + (i % 3)])
	eq(flag_ids(calm, merge(line, {"smoothing":3})), [], "smoothing a calm series is fine")
	eq(charts.series(spike, merge(line, {"smoothing":3})).series[0].points.slice(4, 7).map(func(p): return snappedf(p.y, 0.01)), [11.0, 27.67, 27.0], "smoothed line values (trailing mean)")
	eq(charts.series(spike, line).series[0].points[5], {"x":"2026-03-06", "y":60.0}, "unsmoothed line keeps the spike")
	eq(flag_ids(sales, {"type":"scatter", "x":"units", "y":"price", "y_label":"Price"}), [], "scatter without flags")
	eq(charts.series(sales, {"type":"scatter", "x":"units", "y":"price"}).series[0].points.size(), 6, "scatter points")
	var hist: Dictionary = charts.series(spike, {"type":"histogram", "y":"v", "bins":3})
	eq(hist.series[0].points.map(func(p): return p.y), [7, 0, 1], "histogram counts")
	eq(flag_ids(spike, {"type":"histogram", "y":"v"}), [], "histogram without flags")
	check(not charts.series(sales, {"type":"donut"}).ok and charts.series(sales, {"type":"donut"}).error == "bad_chart_type", "unknown chart type")
	check(not charts.series(sales, {"type":"bar", "x":"nope", "y":"units"}).ok, "unknown column")
	check(not charts.series(sales, {"type":"bar", "x":"region", "y":"units", "agg":"mode"}).ok, "unknown aggregation")
	eq(flag_ids(sales, {"type":"donut"}), [], "unknown type is not flagged, only refused when drawn")
	var combined := flag_ids(sales, {"type":"bar", "x":"region", "y":"units", "y_min":3, "y2":"price", "sort":"none", "y_label":""})
	eq(combined, ["truncated_bar_axis", "dual_axis", "unsorted_bars", "missing_units"], "several flags at once")
	var flag: Dictionary = charts.check(sales, merge(good, {"y_min":10}))[0]
	eq([flag.text_key, flag.teach_key, flag.severity], ["chart_flag_truncated_bar_axis", "chart_teach_truncated_bar_axis", "error"], "flags carry text keys")

func gen_file(seed_value: int, name: String, day: int) -> Dictionary:
	var sc := Scenario.new(seed_value, 10, Loader.load_json("res://data/world.json"), Loader.load_json("res://data/questions.json").questions, Sim.new(1, {}, 11).events)
	var g := Gen.new(sc, seed_value, data_cfg)
	var d := g.difficulty(day)
	return g.build_file(name, day, 0, d.dirt, d.scale)

func test_grader() -> void:
	var grader := Grader.new(data_cfg)
	var f := gen_file(5, "sales_export", 8)
	var ev: Dictionary = ref.evaluate_reference(f)
	var truth: Array = ev.truth
	var perfect := {"pipeline":ref.steps(f), "findings":{"metric_change":{"direction":truth[0].value.direction, "band":truth[0].value.band}, "spike_error":truth[1].value}, "chart":{"type":"line", "x":"date", "y":"units", "agg":"sum", "y_label":"Units"}}
	var g := grader.grade(f, ref, truth, perfect)
	eq([g.cleaning.score, g.cleaning.fixed_rows == g.cleaning.defect_rows, g.cleaning.wrongly_removed, g.cleaning.wrongly_changed], [1.0, true, 0, 0], "reference pipeline fixes everything and breaks nothing")
	check(g.cleaning.defect_rows > 0 and g.cleaning.entries.size() == f.manifest.size(), "one entry per manifest entry")
	eq([g.findings.score, g.chart.score, snappedf(g.total, 0.0001)], [1.0, 1.0, 1.0], "a perfect submission scores 1")
	var none := grader.grade(f, ref, truth, {})
	check(none.cleaning.fixed_rows < none.cleaning.defect_rows and none.cleaning.score < 1.0, "no cleaning misses defects")
	eq([none.findings.score, none.chart.score, none.chart.present], [0.0, 0.0, false], "nothing submitted scores zero for findings and chart")
	var broken := grader.grade(f, ref, truth, {"pipeline":ref.steps(f) + [{"op":"filter", "col":"region", "cmp":"!=", "value":"Hanoi"}]})
	check(broken.cleaning.wrongly_removed > 0 and broken.cleaning.score < 1.0, "removing good rows is counted as wrongly fixed")
	var bad_steps := grader.grade(f, ref, truth, {"pipeline":[{"op":"nonsense"}] + ref.steps(f)})
	check(bad_steps.failed_steps == 1 and bad_steps.cleaning.score == 1.0, "a failing step is reported and skipped")
	# findings scoring
	var want: Dictionary = truth[0].value
	var edges: Array = ref.bands()
	var bi: int = ref.band_index(want.band)
	var near: String = edges[bi + 1] if bi + 1 < edges.size() else edges[bi - 1]
	var far: String = edges[(bi + 3) % edges.size()]
	var score_of := func(given): return snappedf(grader.findings(ref, truth, given).items[0].score, 0.0001)
	eq(score_of.call({"metric_change":{"direction":want.direction, "band":want.band}}), 1.0, "direction and band right")
	eq(score_of.call({"metric_change":{"direction":want.direction, "band":near}}), 0.7, "adjacent band")
	eq(score_of.call({"metric_change":{"direction":want.direction, "band":far}}), 0.4, "direction only")
	eq(score_of.call({"metric_change":{"direction":want.direction}}), 0.4, "direction without a band")
	eq(score_of.call({"metric_change":{"direction":"giam" if want.direction != "giam" else "tang", "band":want.band}}), 0.0, "wrong direction")
	eq(score_of.call({}), 0.0, "missing finding")
	var other := gen_file(11, "ab_test_log", 6)
	var ab_truth: Array = ref.evaluate_reference(other).truth
	eq(grader.findings(ref, ab_truth, {"ab_significant":ab_truth[0].value, "ab_winner":ab_truth[1].value}).score, 1.0, "exact findings for A/B")
	eq(grader.findings(ref, ab_truth, {"ab_significant":not ab_truth[0].value, "ab_winner":ab_truth[1].value}).score, 0.5, "half right")
	# cleaning compared cell by cell: a wrong conversion is a miss, not a fix
	var f2 := gen_file(7, "sales_export", 9)
	var steps: Array = ref.steps(f2)
	var no_currency: Array = steps.filter(func(s): return not (s.op == "convert" and s.kind == "currency"))
	if f2.recipe.currency:
		check(grader.grade(f2, ref, ref.evaluate_reference(f2).truth, {"pipeline":no_currency}).cleaning.score < 1.0, "skipping the currency conversion leaves unit defects")

func public_scan(value: Variant, path: String) -> void:
	if value is Dictionary:
		for key in value:
			check(not FORBIDDEN_KEYS.has(str(key)), "public output has no key '%s' at %s" % [key, path])
			for t in FORBIDDEN_TEXT: check(not str(key).contains(t), "key %s hides text '%s'" % [key, t])
			public_scan(value[key], path + "." + str(key))
	elif value is Array:
		for item in value: public_scan(item, path + "[]")
	elif value is String:
		for t in FORBIDDEN_TEXT: check(not String(value).contains(t), "public string '%s' contains '%s' at %s" % [String(value).left(40), t, path])

func play_day(game: RefCounted) -> void:
	game.begin_day()
	game.submit_report({"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]})
	game.end_day()

func test_facade_and_leaks() -> void:
	var game := Game.new(104, 10)
	var dg := DataGame.new(game, 104, data_cfg)
	eq(dg.files_today(1), [], "no files before the day opens")
	check(not dg.review(1).ok and dg.review(1).error == "day_not_reviewable", "no review before the day is played")
	game.begin_day()
	var files: Array = dg.files_today(1)
	eq([files.size(), files[0].name], [1, "sales_export"], "day 1 offers the sales export")
	eq(dg.files_today(2), [], "future days stay closed")
	public_scan(files, "files")
	var f: Dictionary = files[0]
	check(f.row_count == f.table.rows.size() and f.row_count >= 40, "public file has its rows")
	var steps := [{"op":"dedupe"}, {"op":"parse_date", "col":"date"}, {"op":"group", "by":["region"], "aggs":[{"col":"units", "fn":"sum"}]}]
	var applied: Dictionary = dg.apply_pipeline(1, f.id, steps)
	check(applied.ok and applied.report.size() == 3 and applied.table.rows.size() > 0, "apply_pipeline returns table and per-step report")
	public_scan(applied, "applied")
	var spec := {"type":"bar", "x":"region", "y":"units_sum", "agg":"sum", "sort":"desc", "y_label":"Units"}
	var cd: Dictionary = dg.chart_data(1, f.id, steps, spec)
	check(cd.ok and cd.series[0].points.size() > 0, "chart_data")
	public_scan(cd, "chart")
	var cc: Dictionary = dg.check_chart(1, f.id, steps, merge(spec, {"y_min":5}))
	eq(cc.flags.map(func(x): return x.id), ["truncated_bar_axis"], "check_chart")
	public_scan(cc, "check")
	check(not dg.apply_pipeline(1, "nope", []).ok and not dg.chart_data(1, "nope", [], spec).ok and not dg.submit_analysis(1, "nope", {}).ok, "unknown file is refused")
	var sub_ok: Dictionary = dg.submit_analysis(1, f.id, {"pipeline":steps})
	eq(sub_ok, {"ok":true}, "submit_analysis returns only ok")
	check(not dg.review(1).ok, "still no review while the day is open")
	game.submit_report({"question_id":game.question_today().id, "forecast":"ngang", "confidence":"thap", "evidence":[], "actions":[]})
	check(not dg.review(1).ok, "no review after Send but before the day ends")
	# submit the reference pipeline and read the review once the world allows it
	var internal: Dictionary = dg._file(1, f.id)
	dg.submit_analysis(1, f.id, {"pipeline":dg._ref.steps(internal), "findings":{}})
	game.end_day()
	var review: Dictionary = dg.review(1)
	check(review.ok and review.files.size() == 1, "review opens after the day")
	var rf: Dictionary = review.files[0]
	check(rf.has("manifest") and rf.has("truth") and rf.has("hidden") and rf.has("reference_steps") and rf.has("grade") and rf.submitted, "review carries manifest, truth, hidden values and the grade")
	eq(rf.grade.cleaning.score, 1.0, "the submitted reference pipeline scores 1 for cleaning")
	eq(dg.submit_analysis(1, f.id, {}), {"ok":false, "error":"day_closed"}, "no submissions after the review")
	check(rf.manifest.size() == internal.manifest.size() and rf.manifest[0].rows == internal.manifest[0].rows.size(), "review manifest lists type, columns, affected rows")
	# a game that never draws data behaves exactly like one that generates every day
	var control := Game.new(104, 10)
	var probed := Game.new(104, 10)
	var probe := DataGame.new(probed._scenario, 104, data_cfg)
	for day in range(1, 11):
		probe.files_today(day)
		probe.mark_reviewed(day)
		probe.review(day)
	var same := true
	for day in 10:
		play_day(control)
		play_day(probed)
		same = same and JSON.stringify(control.review(day + 1)) == JSON.stringify(probed.review(day + 1)) and JSON.stringify(control.news_today()) == JSON.stringify(probed.news_today())
	check(same and JSON.stringify(control.status()) == JSON.stringify(probed.status()), "generating data does not change the world (reviews, news, status identical)")
	# bare scenario mode: the day gate is the explicit switch
	var bare := DataGame.new(Game.new(31, 10)._scenario, 31, data_cfg)
	check(bare.files_today(3).size() >= 1 and not bare.review(3).ok, "bare scenario: review closed until marked")
	bare.mark_reviewed(3)
	check(bare.review(3).ok, "bare scenario: review after mark_reviewed")

func test_sources() -> void:
	var rng_call := RegEx.new()
	rng_call.compile("(^|[^\\.\\w])(randi|randf|randomize|randi_range|randf_range|seed)\\(")
	for filename in DirAccess.get_files_at("res://scripts/data"):
		if not filename.ends_with(".gd"): continue
		var source := FileAccess.get_file_as_string("res://scripts/data/" + filename)
		check(not source.contains("Time.get_") and not source.contains("OS.get_"), "%s reads no clock or OS state" % filename)
		for line in source.split("\n"):
			check(rng_call.search(line) == null, "%s uses no global RNG: %s" % [filename, line.strip_edges()])
		var reads_hidden := source.contains("scenario._days") or source.contains("scenario._shocks") or source.contains("._answers") or source.contains("._questions")
		check(reads_hidden == (filename == "generator.gd"), "%s: only generator.gd reads trajectory state" % filename)
		check(source.contains("get(\"_scenario\")") == (filename == "data_game.gd"), "%s: only data_game.gd touches world._scenario" % filename)
		check(not source.contains("randomize()"), "%s never randomizes" % filename)
	for dir in ["res://scripts/v2", "res://scripts/v2/windows", "res://scripts/ui", "res://scripts/sim", "res://scripts/world", "res://scripts/life", "res://scripts/meta"]:
		for filename in DirAccess.get_files_at(dir):
			if filename.ends_with(".gd"): check(not FileAccess.get_file_as_string(dir + "/" + filename).contains("scripts/data/"), "%s/%s does not use the data engine yet" % [dir, filename])
	check(FileAccess.file_exists("res://data/datasets.json") and FileAccess.get_file_as_string("res://data/datasets.json").contains("suc_mua"), "config exists with the variable mapping")

func _init() -> void:
	data_cfg = Loader.load_json("res://data/datasets.json")
	charts = Charts.new(data_cfg)
	ref = Ref.new(data_cfg)
	test_charts()
	test_grader()
	test_facade_and_leaks()
	test_sources()
	print("test_t033_api: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

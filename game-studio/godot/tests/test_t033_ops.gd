extends SceneTree
# T-033: dataset, operations, pipeline (exact outputs on fixtures, invalid steps, determinism).
const DS = preload("res://scripts/data/dataset.gd")
const Ops = preload("res://scripts/data/ops.gd")
const Pipeline = preload("res://scripts/data/pipeline.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 30: printerr("FAIL: ", message)

func eq(actual: Variant, expected: Variant, message: String) -> void:
	var same := JSON.stringify(actual) == JSON.stringify(expected)
	check(same, "%s | got %s expected %s" % [message, JSON.stringify(actual), JSON.stringify(expected)])

func people() -> RefCounted:
	return DS.make("people", ["name", "city", "qty", "price", "day"], ["text", "category", "int", "text", "text"], [
		["Ann", "Hanoi", 3, "12.5", "2026-03-05"],
		["Bob", "Ha Noi", null, "1.2k", "05/03/2026"],
		["Cy", "hanoi", 5, "N/A", "Mar 5, 2026"],
		["Dee", "Hue", 2, "$1,000", "20260305"],
		["Bob", "Ha Noi", null, "1.2k", "05/03/2026"]])

func col(r: Dictionary, name: String) -> Array:
	return r.dataset.column_values(name)

func run_op(ds: RefCounted, step: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var r := Ops.apply(ds, step, ctx)
	check(r.ok, "op ok %s" % JSON.stringify(step))
	return r

func fails(ds: RefCounted, step: Dictionary, code: String, ctx: Dictionary = {}) -> void:
	var r := Ops.apply(ds, step, ctx)
	check(not r.ok and r.error == code, "%s -> %s (got %s)" % [JSON.stringify(step), code, JSON.stringify({"ok":r.ok, "error":r.get("error", "")})])

func test_dataset() -> void:
	var p := people()
	eq([p.row_count(), p.col_index("qty"), p.cell(0, "name"), p.cell(9, "name"), p.cell(0, "nope")], [5, 2, "Ann", null, null], "dataset access")
	eq(p.rids, [0, 1, 2, 3, 4], "rids")
	var c: RefCounted = p.copy()
	c.rows[0][0] = "Zed"
	eq(p.cell(0, "name"), "Ann", "copy is deep")
	var tricky := DS.make("t", ["a", "b", "c"], ["text", "int", "float"], [["x,y", 1, 2.5], ["say \"hi\"", null, null], ["line", 3, 0.5]])
	var back := DS.from_csv("t", tricky.to_csv(), ["text", "int", "float"])
	check(tricky.same_as(back), "csv round trip")
	eq(tricky.to_csv(), "a,b,c\n\"x,y\",1,2.5\n\"say \"\"hi\"\"\",,\nline,3,0.5\n", "csv text is deterministic")
	var d: Dictionary = tricky.to_dict()
	check(not d.has("rids") and DS.from_dict(d).same_as(tricky), "dict round trip without row ids")

func test_ops() -> void:
	var p := people()
	eq(col(run_op(p, {"op":"sort", "col":"qty"}), "name"), ["Dee", "Ann", "Cy", "Bob", "Bob"], "sort asc, nulls last, stable")
	eq(col(run_op(p, {"op":"sort", "col":"qty", "desc":true}), "name"), ["Cy", "Ann", "Dee", "Bob", "Bob"], "sort desc, nulls last")
	eq(run_op(p, {"op":"sort", "col":"name"}).dataset.rids, [0, 1, 4, 2, 3], "sort keeps row ids and order of ties")
	eq(col(run_op(p, {"op":"filter", "col":"qty", "cmp":">", "value":2}), "name"), ["Ann", "Cy"], "filter >")
	eq(col(run_op(p, {"op":"filter", "col":"qty", "cmp":"==", "value":5}), "name"), ["Cy"], "filter ==")
	eq(col(run_op(p, {"op":"filter", "col":"qty", "cmp":"<=", "value":3}), "name"), ["Ann", "Dee"], "filter <=")
	eq(col(run_op(p, {"op":"filter", "col":"city", "cmp":"contains", "value":"noi"}), "name"), ["Ann", "Bob", "Cy", "Bob"], "filter contains")
	eq(col(run_op(p, {"op":"filter", "col":"city", "cmp":"not_contains", "value":"hanoi"}), "name"), ["Bob", "Dee", "Bob"], "filter not_contains")
	eq(col(run_op(p, {"op":"filter", "col":"qty", "cmp":"missing"}), "name"), ["Bob", "Bob"], "filter missing")
	eq(col(run_op(p, {"op":"filter", "col":"qty", "cmp":"present"}), "name"), ["Ann", "Cy", "Dee"], "filter present")
	eq(col(run_op(p, {"op":"filter", "col":"city", "cmp":"!=", "value":"Hue"}), "name"), ["Ann", "Bob", "Cy", "Bob"], "filter !=")
	eq(col(run_op(p, {"op":"filter", "col":"name", "cmp":">", "value":2}), "name"), [], "filter never mixes text and numbers")
	eq(run_op(p, {"op":"dedupe"}).dataset.row_count(), 4, "dedupe all columns")
	eq(run_op(p, {"op":"dedupe", "cols":["name"]}).dataset.rids, [0, 1, 2, 3], "dedupe keeps first")
	eq(run_op(p, {"op":"dedupe", "cols":["city"]}).dataset.row_count(), 4, "dedupe by key column")
	# missing values
	eq(run_op(p, {"op":"missing", "col":"qty", "mode":"drop"}).dataset.row_count(), 3, "missing drop")
	eq(run_op(p, {"op":"missing", "col":"price", "mode":"drop"}).dataset.row_count(), 4, "missing drop N/A token")
	eq(col(run_op(p, {"op":"missing", "col":"qty", "mode":"value", "value":0}), "qty"), [3, 0, 5, 2, 0], "missing fill value")
	eq(col(run_op(p, {"op":"missing", "col":"qty", "mode":"median"}), "qty"), [3, 3.0, 5, 2, 3.0], "missing fill median")
	var mean_fill: Array = col(run_op(p, {"op":"missing", "col":"qty", "mode":"mean"}), "qty")
	check(absf(float(mean_fill[1]) - 10.0 / 3.0) < 1e-9, "missing fill mean")
	eq(col(run_op(p, {"op":"missing", "col":"qty", "mode":"prev"}), "qty"), [3, 3, 5, 2, 2], "missing fill previous")
	eq(col(run_op(p, {"op":"missing", "col":"price", "mode":"to_null"}), "price"), ["12.5", "1.2k", null, "$1,000", "1.2k"], "missing to_null")
	eq(col(run_op(p, {"op":"missing", "col":"*", "mode":"drop"}), "name"), ["Ann", "Dee"], "missing drop any column")
	var zeros := DS.make("z", ["v"], ["int"], [[0], [4], [0], [6]])
	eq(col(run_op(zeros, {"op":"missing", "col":"v", "mode":"drop"}), "v"), [0, 4, 0, 6], "zero is not missing by default")
	eq(col(run_op(zeros, {"op":"missing", "col":"v", "mode":"median", "zero_missing":true}), "v"), [5.0, 4, 5.0, 6], "zero as missing, median of the rest")
	# text
	eq(col(run_op(p, {"op":"standardize", "col":"city", "map":{"ha noi":"Hanoi", "hanoi":"Hanoi"}}), "city"), ["Hanoi", "Hanoi", "Hanoi", "Hue", "Hanoi"], "standardize map")
	eq(col(run_op(p, {"op":"standardize", "col":"city", "case":"upper"}), "city"), ["HANOI", "HA NOI", "HANOI", "HUE", "HA NOI"], "standardize upper")
	eq(col(run_op(p, {"op":"standardize", "col":"city", "case":"title"}), "city"), ["Hanoi", "Ha Noi", "Hanoi", "Hue", "Ha Noi"], "standardize title")
	var spaced := DS.make("s", ["c"], ["text"], [["  Ha   Noi "], [null], [5]])
	eq(col(run_op(spaced, {"op":"standardize", "col":"c"}), "c"), ["Ha Noi", null, 5], "standardize trims, collapses, leaves non-text")
	# numbers, units, currency
	eq(col(run_op(p, {"op":"convert", "kind":"number", "col":"price"}), "price"), [12.5, 1200.0, null, 1000.0, 1200.0], "convert number")
	eq(col(run_op(p, {"op":"convert", "kind":"scale", "col":"price", "factor":2}), "price"), [25.0, 2400.0, null, 2000.0, 2400.0], "convert scale")
	var added := run_op(p, {"op":"convert", "kind":"number", "col":"price", "out":"price_n"})
	eq([added.dataset.cols.size(), p.cols.size(), added.dataset.cell(1, "price_n"), added.dataset.cell(1, "price")], [6, 5, 1200.0, "1.2k"], "convert into a new column leaves the source")
	eq([Ops.parse_number_text("(40)"), Ops.parse_number_text("12%"), Ops.parse_number_text("3M"), Ops.parse_number_text("5 USD"), Ops.parse_number_text("abc"), Ops.parse_number_text(""), Ops.parse_number_text("-2.5k")], [-40.0, 0.12, 3000000.0, 5.0, null, null, -2500.0], "number text parsing")
	var money := DS.make("m", ["amt", "cur"], ["float", "category"], [[100, "USD"], [24000, "VND"], [5, "eur"], ["8", null]])
	eq(col(run_op(money, {"op":"convert", "kind":"currency", "col":"amt", "currency_col":"cur", "rates":{"VND":0.25, "USD":1.0}}), "amt"), [100.0, 6000.0, 5.0, 8.0], "convert currency, unknown code keeps the default rate")
	# dates
	var dates := DS.make("d", ["d"], ["text"], [["2026-03-05"], ["05/03/2026"], ["Mar 5, 2026"], ["20260305"], ["31/02/2026"], ["garbage"], ["2026-11-03T14:20:00+07:00"], ["3 Nov 2026"], [""], [null], ["2024-02-29"], ["2025-02-29"]])
	eq(col(run_op(dates, {"op":"parse_date", "col":"d"}), "d"), ["2026-03-05", "2026-03-05", "2026-03-05", "2026-03-05", null, null, "2026-11-03", "2026-11-03", null, null, "2024-02-29", null], "parse dates (auto, leap years, invalid)")
	eq(Ops.parse_date("03/04/2026", "mdy"), "2026-03-04", "mdy format")
	eq(Ops.parse_date("03/04/2026", "auto"), "2026-04-03", "auto is day first")
	# computed
	var nums := DS.make("n", ["a", "b"], ["float", "float"], [[2, 4], [3, 0], [null, 5]])
	eq(col(run_op(nums, {"op":"computed", "name":"s", "fn":"add", "a":"a", "b":"b"}), "s"), [6.0, 3.0, null], "computed add")
	eq(col(run_op(nums, {"op":"computed", "name":"r", "fn":"div", "a":"a", "b":"b"}), "r"), [0.5, null, null], "computed div (zero and null give null)")
	eq(col(run_op(nums, {"op":"computed", "name":"m", "fn":"mul", "a":"a", "b_value":10}), "m"), [20.0, 30.0, null], "computed with a constant")
	eq(col(run_op(nums, {"op":"computed", "name":"p", "fn":"pct_change", "a":"a"}), "p"), [null, 50.0, null], "computed pct change")
	eq(col(run_op(nums, {"op":"computed", "name":"w", "fn":"moving_avg", "a":"a", "window":2}), "w"), [null, 2.5, null], "computed moving average")
	# aggregate
	var g := DS.make("g", ["g", "v"], ["text", "float"], [["x", 1], ["y", 10], ["x", 3], ["y", null], ["z", 7]])
	var all: Dictionary = run_op(g, {"op":"group", "by":["g"], "aggs":[{"col":"v", "fn":"sum"}, {"col":"v", "fn":"mean"}, {"col":"v", "fn":"median"}, {"col":"v", "fn":"count", "as":"n"}, {"col":"v", "fn":"min"}, {"col":"v", "fn":"max"}]})
	eq(all.dataset.cols, ["g", "v_sum", "v_mean", "v_median", "n", "v_min", "v_max"], "group columns")
	eq(all.dataset.rows, [["x", 4.0, 2.0, 2.0, 2, 1.0, 3.0], ["y", 10.0, 10.0, 10.0, 1, 10.0, 10.0], ["z", 7.0, 7.0, 7.0, 1, 7.0, 7.0]], "group aggregates, sorted by key")
	eq(all.dataset.rids, [-1, -1, -1], "group drops row ids")
	eq(run_op(g, {"op":"group", "aggs":[{"col":"v", "fn":"sum"}]}).dataset.rows, [[21.0]], "group with no key is a grand total")
	var pv := DS.make("p", ["g", "h", "v"], ["text", "text", "float"], [["a", "p", 1], ["a", "q", 2], ["b", "p", 3], ["a", "p", 4]])
	eq(run_op(pv, {"op":"pivot", "index":"g", "columns":"h", "values":"v", "fn":"sum"}).dataset.rows, [["a", 5.0, 2.0], ["b", 3.0, null]], "pivot")
	# join
	var left := DS.make("l", ["id", "x"], ["text", "text"], [["1", "a"], ["2", "b"], ["3", "c"]])
	var right := DS.make("t", ["k", "label"], ["text", "text"], [["1", "one"], ["3", "three"], ["3", "again"]])
	var j := run_op(left, {"op":"join", "other":"t", "left_key":"id", "right_key":"k", "kind":"left", "take":["label"]}, {"t":right})
	eq(col(j, "label"), ["one", null, "three"], "join left, first match wins")
	eq(run_op(left, {"op":"join", "other":"t", "left_key":"id", "right_key":"k", "kind":"inner"}, {"t":right}).dataset.rids, [0, 2], "join inner keeps left row ids")
	var mismatch := DS.make("l", ["id"], ["text"], [["c1 "], ["C1"]])
	eq(col(run_op(mismatch, {"op":"join", "other":"t", "left_key":"id", "right_key":"k"}, {"t":DS.make("t", ["k", "v"], [], [["C1", 9]])}), "v"), [null, 9], "join keys must match exactly")
	# outliers
	var series := DS.make("o", ["v"], ["float"], [[10], [11], [12], [10], [11], [12], [10], [11], [500]])
	eq(col(run_op(series, {"op":"outliers", "col":"v", "method":"iqr", "action":"flag"}), "v_outlier"), [false, false, false, false, false, false, false, false, true], "outlier flag iqr")
	eq(run_op(series, {"op":"outliers", "col":"v", "method":"iqr", "action":"remove"}).dataset.row_count(), 8, "outlier remove iqr")
	eq(run_op(series, {"op":"outliers", "col":"v", "method":"z", "k":2.0, "action":"remove"}).dataset.row_count(), 8, "outlier z at 2 sd")
	eq(run_op(series, {"op":"outliers", "col":"v", "method":"z", "action":"remove"}).dataset.row_count(), 9, "z at 3 sd is masked by the outlier itself")
	# sample
	var ten := DS.make("s", ["v"], ["int"], [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]])
	eq(col(run_op(ten, {"op":"sample", "n":3}), "v"), [0, 1, 2], "sample head")
	eq(col(run_op(ten, {"op":"sample", "n":4, "mode":"every"}), "v"), [0, 4, 8], "sample every n-th")
	var s1: Array = col(run_op(ten, {"op":"sample", "n":4, "mode":"seeded", "seed":5}), "v")
	var s2: Array = col(run_op(ten, {"op":"sample", "n":4, "mode":"seeded", "seed":5}), "v")
	var s3: Array = col(run_op(ten, {"op":"sample", "n":4, "mode":"seeded", "seed":6}), "v")
	check(s1 == s2 and s1.size() == 4 and s1 != s3, "seeded sample is deterministic and depends on the seed")
	# the input is never changed by an operation
	eq(people().rows, p.rows, "operations do not mutate their input")

func test_invalid() -> void:
	var p := people()
	fails(p, {"op":"bogus"}, "unknown_op")
	fails(p, {}, "unknown_op")
	for op in ["sort", "filter", "standardize", "convert", "parse_date", "outliers"]:
		fails(p, {"op":op, "col":"nope", "cmp":"==", "value":1}, "unknown_column")
	fails(p, {"op":"filter", "col":"qty", "cmp":"~~", "value":1}, "bad_comparison")
	fails(p, {"op":"filter", "col":"qty", "cmp":">"}, "missing_value")
	fails(p, {"op":"missing", "col":"qty", "mode":"nope"}, "bad_mode")
	fails(p, {"op":"missing", "col":"qty", "mode":"value"}, "missing_value")
	fails(p, {"op":"missing", "col":"*", "mode":"median"}, "bad_mode")
	fails(p, {"op":"missing", "col":"name", "mode":"median"}, "no_values")
	fails(p, {"op":"dedupe", "cols":["nope"]}, "unknown_column")
	fails(p, {"op":"standardize", "col":"city", "case":"weird"}, "bad_mode")
	fails(p, {"op":"convert", "kind":"nope", "col":"price"}, "bad_kind")
	fails(p, {"op":"convert", "kind":"scale", "col":"price"}, "missing_value")
	fails(p, {"op":"convert", "kind":"currency", "col":"price", "currency_col":"nope"}, "unknown_column")
	fails(p, {"op":"parse_date", "col":"day", "format":"nope"}, "bad_mode")
	fails(p, {"op":"computed", "fn":"add", "a":"qty", "b":"qty"}, "missing_value")
	fails(p, {"op":"computed", "name":"x", "fn":"pow", "a":"qty"}, "bad_mode")
	fails(p, {"op":"computed", "name":"x", "fn":"add", "a":"qty", "b":"nope"}, "unknown_column")
	fails(p, {"op":"computed", "name":"x", "fn":"moving_avg", "a":"qty", "window":0}, "bad_window")
	fails(p, {"op":"group"}, "missing_value")
	fails(p, {"op":"group", "by":["nope"]}, "unknown_column")
	fails(p, {"op":"group", "by":["city"], "aggs":[{"col":"qty", "fn":"mode"}]}, "bad_mode")
	fails(p, {"op":"group", "by":["city"], "aggs":[{"col":"nope", "fn":"sum"}]}, "unknown_column")
	fails(p, {"op":"pivot", "index":"city", "columns":"nope", "values":"qty"}, "unknown_column")
	fails(p, {"op":"join", "other":"ghost", "left_key":"name", "right_key":"k"}, "unknown_table")
	fails(p, {"op":"join", "other":"t", "left_key":"nope", "right_key":"k"}, "unknown_column", {"t":DS.make("t", ["k"])})
	fails(p, {"op":"join", "other":"t", "left_key":"name", "right_key":"nope"}, "unknown_column", {"t":DS.make("t", ["k"])})
	fails(p, {"op":"outliers", "col":"qty"}, "too_few_values")
	fails(p, {"op":"outliers", "col":"qty", "method":"mad"}, "bad_mode")
	fails(p, {"op":"sample", "n":0}, "bad_count")
	fails(p, {"op":"sample", "n":2, "mode":"nope"}, "bad_mode")
	var empty := DS.make("e", ["a", "b"], ["int", "int"])
	for step in [{"op":"sort", "col":"a"}, {"op":"filter", "col":"a", "cmp":">", "value":1}, {"op":"dedupe"}, {"op":"missing", "col":"a", "mode":"drop"}, {"op":"group", "by":["a"], "aggs":[{"col":"b", "fn":"sum"}]}, {"op":"sample", "n":3}]:
		var r := Ops.apply(empty, step)
		check(r.ok and r.dataset.row_count() == 0, "empty table survives %s" % step.op)

func test_pipeline() -> void:
	var raw := people()
	var pl: RefCounted = Pipeline.new(raw)
	eq(pl.run().dataset.row_count(), 5, "empty pipeline is the raw table")
	pl.add({"op":"dedupe"})
	pl.add({"op":"missing", "col":"price", "mode":"drop"})
	pl.add({"op":"convert", "kind":"number", "col":"price"})
	var run: Dictionary = pl.run()
	eq(run.report.map(func(r): return [r.rows_in, r.rows_out, r.ok]), [[5, 4, true], [4, 3, true], [3, 3, true]], "row counts per step")
	eq(col(run, "price"), [12.5, 1200.0, 1000.0], "pipeline result")
	eq(raw.row_count(), 5, "raw is never changed")
	# edit
	pl.edit(1, {"op":"missing", "col":"qty", "mode":"drop"})
	eq(pl.run().dataset.row_count(), 3, "edited step recomputes from raw")
	# reorder
	var order_a: Dictionary = Pipeline.from_array(raw, [{"op":"dedupe"}, {"op":"filter", "col":"qty", "cmp":">", "value":2}]).run()
	var order_b: Dictionary = Pipeline.from_array(raw, [{"op":"filter", "col":"qty", "cmp":">", "value":2}, {"op":"dedupe"}]).run()
	eq(order_a.report.map(func(r): return r.rows_out), [4, 2], "dedupe then filter")
	eq(order_b.report.map(func(r): return r.rows_out), [2, 2], "filter then dedupe")
	var pm: RefCounted = Pipeline.from_array(raw, [{"op":"dedupe"}, {"op":"filter", "col":"qty", "cmp":">", "value":2}])
	check(pm.move(1, 0) and pm.steps[0].op == "filter" and pm.run().report.map(func(r): return r.rows_out) == [2, 2], "move step")
	check(not pm.move(0, 9) and not pm.move(-1, 0), "move out of range is refused")
	# delete and undo / redo
	var before: Array = pl.to_array()
	check(pl.delete(0), "delete step")
	eq(pl.steps.size(), 2, "one step fewer")
	check(pl.undo() and pl.to_array() == before, "undo restores the step list")
	check(pl.redo() and pl.steps.size() == 2, "redo")
	check(pl.undo() and pl.undo() and pl.undo() and pl.undo() and pl.undo(), "undo several")
	check(pl.steps.is_empty() and not pl.undo(), "undo stops at the start")
	pl.add({"op":"dedupe"})
	check(not pl.redo(), "a new edit clears redo")
	check(not pl.delete(5) and not pl.edit(5, {"op":"dedupe"}), "bad index is refused")
	pl.reset()
	check(pl.steps.is_empty() and pl.undo() and pl.steps.size() == 1, "reset to raw is undoable")
	# errors never crash and are skipped
	var bad: Dictionary = Pipeline.from_array(raw, [{"op":"bogus"}, {"op":"sort", "col":"nope"}, {"op":"dedupe"}]).run()
	eq(bad.report.map(func(r): return [r.ok, r.error]), [[false, "unknown_op"], [false, "unknown_column"], [true, ""]], "failing steps are reported")
	eq([bad.failed, bad.dataset.row_count()], [2, 4], "failing steps are skipped, the rest still runs")
	# row-level table before the first aggregation
	var agg: Dictionary = Pipeline.from_array(raw, [{"op":"dedupe"}, {"op":"group", "by":["city"], "aggs":[{"col":"qty", "fn":"sum"}]}]).run()
	eq([agg.row_level.row_count(), agg.dataset.row_count()], [4, 4], "row_level is the table before group")
	eq(agg.row_level.rids, [0, 1, 2, 3], "row_level keeps ids")
	# preview
	var pv: Dictionary = Pipeline.from_array(raw, [{"op":"dedupe"}]).preview({"op":"filter", "col":"qty", "cmp":">", "value":2})
	eq([pv.ok, pv.rows_before, pv.rows_after], [true, 4, 2], "preview the next step")
	check(not Pipeline.from_array(raw, []).preview({"op":"sort", "col":"zzz"}).ok, "preview of an invalid step is an error")
	# determinism
	var steps := [{"op":"dedupe"}, {"op":"sample", "n":3, "mode":"seeded", "seed":9}, {"op":"sort", "col":"name"}]
	check(Pipeline.from_array(raw, steps).run().dataset.same_as(Pipeline.from_array(people(), steps).run().dataset), "same steps, same result")
	var ctx_pipe: RefCounted = Pipeline.from_array(raw, [{"op":"join", "other":"t", "left_key":"name", "right_key":"k", "take":["v"]}], {"t":DS.make("t", ["k", "v"], [], [["Ann", 1]])})
	eq(col(ctx_pipe.run(), "v"), [1, null, null, null, null], "pipeline passes lookup tables to join")

func _init() -> void:
	test_dataset()
	test_ops()
	test_invalid()
	test_pipeline()
	print("test_t033_ops: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

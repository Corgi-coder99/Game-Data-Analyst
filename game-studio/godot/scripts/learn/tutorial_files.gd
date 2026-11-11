extends RefCounted
# T-035: the five hand-built tutorial files (docs/TUTORIAL-CASES.md) as hidden file records, in the same
# shape the generator produces (raw table, manifest, expected clean rows) plus explicit reference steps,
# truth statements and finding options. DataGame uses them for days 1-5 in tutorial mode only.
# The public side (DataGame.files_today) sees the raw table, the lookup tables and the finding options only.
# Hidden: manifest, expected rows, reference steps, truth. Quartiles of the Outliers step are linear
# interpolation like the rest of the engine; day 2 has exactly one flagged value either way (see the doc).
const DS = preload("res://scripts/data/dataset.gd")
const Stats = preload("res://scripts/learn/stats.gd")
const Loader = preload("res://scripts/data.gd")
const DAYS := 5

const SALES := """date,region,product,units,price,currency,channel
2026-03-02,Hanoi,Tea Box,30,4.0,USD,web
2026-03-02,Da Nang,Tea Box,25,4.0,USD,web
2026-03-02,Hue,Tea Box,22,4.0,USD,web
2026-03-03,Ha Noi,Tea Box,28,4.0,USD,web
2026-03-03,Da Nang,Tea Box,27,4.0,USD,web
2026-03-03,Da Nang,Tea Box,27,4.0,USD,web
2026-03-03,Hue,Tea Box,20,4.0,USD,web
2026-03-04,hanoi,Tea Box,32,4.0,USD,web
2026-03-04,Da Nang,Tea Box,26,4.0,USD,web
2026-03-04,Da Nang,Tea Box,26,4.0,USD,web
2026-03-04,Hue,Tea Box,21,4.0,USD,web
2026-03-05,Hanoi,Tea Box,30,4.0,USD,web
2026-03-05,Da Nang,Tea Box,24,4.0,USD,web
2026-03-05,Hue,Tea Box,23,4.0,USD,web"""
const STEEL := """date,series,value,unit,source
2026-03-02,Steel index,148,points,exchange
2026-03-03,Steel index,149,points,exchange
2026-03-04,Steel index,150,points,exchange
2026-03-05,Steel index,151,points,exchange
2026-03-06,Steel index,150,points,exchange
2026-03-09,Steel index,1520,points,exchange
2026-03-10,Steel index,152,points,exchange
2026-03-11,Steel index,153,points,exchange
2026-03-12,Steel index,152,points,exchange
2026-03-13,Steel index,171,points,exchange
2026-03-16,Steel index,172,points,exchange
2026-03-17,Steel index,170,points,exchange
2026-03-18,Steel index,171,points,exchange
2026-03-19,Steel index,173,points,exchange"""
const FUNNEL := """date,step,users,exported_at
2026-03-02,visit,500,23:59
2026-03-02,signup_start,150,23:59
2026-03-02,signup_done,105,23:59
2026-03-02,first_purchase,21,23:59
2026-03-03,visit,520,23:59
2026-03-03,signup_start,156,23:59
2026-03-03,signup_done,109,23:59
2026-03-03,first_purchase,22,23:59
2026-03-04,visit,480,23:59
2026-03-04,signup_start,144,23:59
2026-03-04,signup_done,101,23:59
2026-03-04,first_purchase,20,23:59
2026-03-05,visit,510,23:59
2026-03-05,signup_start,153,23:59
2026-03-05,signup_done,107,23:59
2026-03-05,first_purchase,21,23:59
2026-03-06,visit,190,10:00
2026-03-06,signup_start,57,10:00
2026-03-06,signup_done,20,10:00
2026-03-06,first_purchase,2,10:00"""
const ABTEST := """user_id,variant,converted,date
u01,A,0,2026-03-02
u02,A,0,2026-03-03
u03,A,1,2026-03-04
u04,A,0,2026-03-05
u05,A,1,2026-03-02
u06,A,0,2026-03-03
u07,A,0,2026-03-04
u08,A,1,2026-03-05
u09,A,0,2026-03-02
u10,A,0,2026-03-03
u11,A,1,2026-03-04
u12,A,0,2026-03-05
u13,B,0,2026-03-02
u14,B,1,2026-03-03
u15,B,1,2026-03-04
u16,B,0,2026-03-05
u17,B,0,2026-03-02
u18,B,1,2026-03-03
u19,B,0,2026-03-04
u20,B,1,2026-03-05
u21,B,1,2026-03-02
u22,B,0,2026-03-03
u23,B,0,2026-03-04
u24,B,1,2026-03-05"""
const CHECKOUT := """week,device,variant,visitors,orders
W1,desktop,A,200,40
W1,mobile,A,50,2
W1,desktop,B,50,11
W1,mobile,B,200,10
W2,desktop,A,200,40
W2,mobile,A,50,2
W2,desktop,B,50,11
W2,mobile,B,200,10
W3,desktop,A,200,40
W3,mobile,A,50,2
W3,desktop,B,50,11
W3,mobile,B,200,10
W4,desktop,A,200,40
W4,mobile,A,50,2
W4,desktop,B,50,11
W4,mobile,B,200,10"""

static func cfg() -> Dictionary:
	return Loader.load_json("res://data/datasets.json")

static func _parse(name: String, csv: String, types: Array) -> RefCounted:
	var lines: PackedStringArray = csv.replace("\r", "").split("\n", false)
	var cols: Array = Array(lines[0].split(",")).map(func(c): return str(c))
	var ds = DS.make(name, cols, types)
	for i in range(1, lines.size()):
		var cells: Array = []
		var parts: PackedStringArray = lines[i].split(",")
		for c in cols.size():
			match str(types[c]):
				"int": cells.append(int(parts[c]))
				"float": cells.append(float(parts[c]))
				_: cells.append(str(parts[c]))
		ds.add_row(cells)
	return ds

# rows: {rid: {col: value}} fixes; removed: [rid]. Returns {rid: row or null}.
static func _expected(raw: RefCounted, fixes: Dictionary, removed: Array) -> Dictionary:
	var out := {}
	for rid in raw.rows.size():
		if removed.has(rid):
			out[rid] = null
			continue
		var row: Array = raw.rows[rid].duplicate()
		for col in fixes.get(rid, {}): row[raw.col_index(col)] = fixes[rid][col]
		out[rid] = row
	return out

static func _bands() -> Array:
	var edges: Array = cfg().bands
	var out: Array = ["<%d" % int(edges[0])]
	for i in range(edges.size() - 1): out.append("%d..%d" % [int(edges[i]), int(edges[i + 1])])
	out.append(">%d" % int(edges[edges.size() - 1]))
	return out

static func _band_of(pct: float) -> String:
	var edges: Array = cfg().bands
	if pct < float(edges[0]): return "<%d" % int(edges[0])
	for i in range(edges.size() - 1):
		if pct < float(edges[i + 1]): return "%d..%d" % [int(edges[i]), int(edges[i + 1])]
	return ">%d" % int(edges[edges.size() - 1])

static func _record(day: int, name: String, title: String, raw: RefCounted, manifest: Array, expected: Dictionary, dirt: Array, ref_steps: Array, truth: Array, options: Array, case_id: String, cards: Array) -> Dictionary:
	return {"id": "tutorial_d%d" % day, "name": name, "title": title, "day": day, "index": 0, "raw": raw, "aux": {}, "manifest": manifest, "expected": expected,
		"recipe": {"name": name, "defects": [], "date_col": ""}, "hidden": {}, "meta": {}, "dirt_types": dirt, "tutorial": true, "case_id": case_id, "cards": cards,
		"ref_steps": ref_steps, "truth_list": truth, "options": options}

static func build(day: int) -> Dictionary:
	match day:
		1: return _day1()
		2: return _day2()
		3: return _day3()
		4: return _day4()
		5: return _day5()
	return {}

static func _day1() -> Dictionary:
	var raw := _parse("sales_export_day1", SALES, ["date", "category", "category", "int", "float", "category", "category"])
	var expected := _expected(raw, {3: {"region": "Hanoi"}, 7: {"region": "Hanoi"}}, [5, 9])
	var manifest := [{"type": "duplicates", "columns": raw.cols.duplicate(), "rows": [5, 9]}, {"type": "category_typos", "columns": ["region"], "rows": [3, 7]}]
	var steps := [{"op": "dedupe", "cols": []}, {"op": "standardize", "col": "region", "case": "none", "map": {"Ha Noi": "Hanoi", "hanoi": "Hanoi"}}, {"op": "group", "by": ["region"], "aggs": [{"col": "units", "fn": "sum"}]}, {"op": "sort", "col": "units_sum", "desc": true}]
	var truth := [{"id": "top_region", "value": "Hanoi"}]
	var options := [{"id": "top_region", "choices": ["Hanoi", "Da Nang", "Hue"]}]
	return _record(1, "sales_export_day1", "Sales export", raw, manifest, expected, ["duplicates", "category_typos"], steps, truth, options, "case_duplicate_export", ["hb_audit_first", "hb_duplicates", "hb_text_standardize"])

# Level change = last 7 days against the 7 days before, ending at the last date (same definition as the other files).
static func _day2() -> Dictionary:
	var raw := _parse("market_prices_day2", STEEL, ["date", "category", "float", "text", "text"])
	var expected := _expected(raw, {}, [5])
	var manifest := [{"type": "outliers", "columns": ["value"], "rows": [5]}]
	var steps := [{"op": "outliers", "col": "value", "method": "iqr", "k": 1.5, "action": "remove"}]
	var recent := [171.0, 172.0, 170.0, 171.0, 173.0]
	var earlier := [150.0, 152.0, 153.0, 152.0]
	var pct := (_mean(recent) / _mean(earlier) - 1.0) * 100.0
	var truth := [{"id": "metric_change", "value": {"pct": pct, "direction": "tang", "band": _band_of(pct)}}, {"id": "entry_error_date", "value": "2026-03-09"}]
	var options := [{"id": "metric_change", "directions": ["tang", "giam", "ngang"], "bands": _bands()}, {"id": "entry_error_date", "choices": ["none", "2026-03-05", "2026-03-09", "2026-03-13"]}]
	return _record(2, "market_prices_day2", "Steel index", raw, manifest, expected, ["outliers"], steps, truth, options, "case_entry_error_vs_spike", ["hb_line_time", "hb_outliers_iqr", "hb_entry_error_vs_spike"])

static func _mean(values: Array) -> float:
	var s := 0.0
	for v in values: s += float(v)
	return s / float(values.size())

static func _day3() -> Dictionary:
	var raw := _parse("web_funnel_day3", FUNNEL, ["date", "category", "int", "text"])
	var expected := _expected(raw, {}, [16, 17, 18, 19])
	var manifest := [{"type": "late_partial", "columns": ["date", "exported_at"], "rows": [16, 17, 18, 19]}]
	var steps := [{"op": "filter", "col": "date", "cmp": "<", "value": "2026-03-06"}, {"op": "group", "by": ["step"], "aggs": [{"col": "users", "fn": "sum"}]}]
	var truth := [{"id": "biggest_dropoff", "value": "signup_done>first_purchase"}]
	var options := [{"id": "biggest_dropoff", "choices": ["visit>signup_start", "signup_start>signup_done", "signup_done>first_purchase"]}]
	return _record(3, "web_funnel_day3", "Sign-up funnel", raw, manifest, expected, ["late_partial"], steps, truth, options, "case_funnel_dropoff", ["hb_funnel", "hb_late_data"])

static func _day4() -> Dictionary:
	var raw := _parse("ab_test_log_day4", ABTEST, ["text", "category", "int", "date"])
	var expected := _expected(raw, {}, [])
	var p := Stats.fisher_two_sided(4, 8, 6, 6)
	var steps := [{"op": "group", "by": ["variant"], "aggs": [{"col": "converted", "fn": "sum"}, {"col": "converted", "fn": "count"}]}, {"op": "computed", "name": "rate", "fn": "div", "a": "converted_sum", "b": "converted_count"}]
	var truth := [{"id": "ab_significant", "value": p < 0.05}, {"id": "ab_winner", "value": "none" if p >= 0.05 else "B"}]
	var options := [{"id": "ab_significant", "choices": [true, false]}, {"id": "ab_winner", "choices": ["A", "B", "none"]}]
	return _record(4, "ab_test_log_day4", "A/B test log", raw, [], expected, [], steps, truth, options, "case_ab_significance", ["hb_ab_test", "hb_pvalue", "hb_noise_sample", "hb_sample_size"])

static func _day5() -> Dictionary:
	var raw := _parse("checkout_by_device_day5", CHECKOUT, ["text", "category", "category", "int", "int"])
	var expected := _expected(raw, {}, [])
	var steps := [{"op": "group", "by": ["variant", "device"], "aggs": [{"col": "visitors", "fn": "sum"}, {"col": "orders", "fn": "sum"}]}, {"op": "computed", "name": "rate", "fn": "div", "a": "orders_sum", "b": "visitors_sum"}]
	var truth := [{"id": "better_version", "value": "B"}, {"id": "even_mix", "value": false}]
	var options := [{"id": "better_version", "choices": ["A", "B", "no clear winner"]}, {"id": "even_mix", "choices": [true, false]}]
	return _record(5, "checkout_by_device_day5", "Checkout by device", raw, [], expected, [], steps, truth, options, "case_simpson", ["hb_simpson", "hb_confounder", "hb_segmentation"])

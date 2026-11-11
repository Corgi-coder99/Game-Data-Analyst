extends RefCounted
# T-033: HIDDEN. The reference pipeline of a file (how a careful analyst cleans it) and the truth statements
# computed from a cleaned table (+ the hidden window change kept by the generator). Public code must never
# return anything from here before the day's review.
const DS = preload("res://scripts/data/dataset.gd")
const Ops = preload("res://scripts/data/ops.gd")
const Pipeline = preload("res://scripts/data/pipeline.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Loader = preload("res://scripts/data.gd")
const LABEL_COL := {"sales_export":"region", "market_prices":"venue", "competitor_scrape":"shop"}
const VENUES := ["Exchange A", "Exchange B", "Bank C", "Broker D"]
var cfg: Dictionary

func _init(p_cfg: Dictionary = {}) -> void:
	cfg = p_cfg if not p_cfg.is_empty() else Loader.load_json("res://data/datasets.json")

# ---------- reference / baseline pipelines ----------
func steps(file: Dictionary) -> Array:
	# T-035: hand-built tutorial files carry their own reference steps.
	if file.has("ref_steps"): return file.ref_steps.duplicate(true)
	var r: Dictionary = file.recipe
	var name: String = r.name
	var out: Array = []
	var has := func(d): return r.defects.has(d)
	if has.call("repeated_header"): out.append({"op":"filter", "col":r.id_col, "cmp":"!=", "value":r.id_col})
	if has.call("subtotal_rows"): out.append({"op":"filter", "col":r.id_col, "cmp":"!=", "value":"TOTAL"})
	if has.call("duplicates"): out.append({"op":"dedupe", "cols":[]})
	if has.call("test_accounts"):
		match name:
			"sales_export": out.append({"op":"filter", "col":"channel", "cmp":"!=", "value":"internal_test"})
			"support_tickets": out.append({"op":"filter", "col":"ticket_id", "cmp":"not_contains", "value":"TST-"})
			"ab_test_log": out.append({"op":"filter", "col":"user_id", "cmp":"not_contains", "value":"qa_"})
			"loan_book":
				out.append({"op":"standardize", "col":"customer_id", "case":"upper"})
				out.append({"op":"join", "other":"customers", "left_key":"customer_id", "right_key":"customer_id", "kind":"left", "take":["segment"]})
				out.append({"op":"filter", "col":"segment", "cmp":"!=", "value":"Test"})
	for m in r.missing:
		var step := {"op":"missing", "col":m.col, "mode":m.mode, "zero_missing":m.zero}
		if m.mode == "value": step["value"] = m.fill
		out.append(step)
	if has.call("refunds_negative"): out.append({"op":"filter", "col":"units", "cmp":">", "value":0})
	for col in r.typo_cols: out.append({"op":"standardize", "col":col, "map":r.typo_maps[col]})
	for col in r.suffix_cols: out.append({"op":"convert", "kind":"number", "col":col})
	if r.currency:
		out.append({"op":"convert", "kind":"currency", "col":"price", "currency_col":"currency", "rates":{"VND":1.0 / float(cfg.vnd_per_usd), "USD":1.0}})
		out.append({"op":"standardize", "col":"currency", "map":{"VND":"USD"}})
	if has.call("mixed_dates"): out.append({"op":"parse_date", "col":r.date_col, "format":"auto"})
	if r.last_date != "": out.append({"op":"filter", "col":r.date_col, "cmp":"<", "value":r.last_date})
	if has.call("outliers"): out.append({"op":"outliers", "col":r.outlier_col, "method":"iqr", "k":r.outlier_k, "action":"remove"})
	return out

func naive_steps(_file: Dictionary) -> Array:
	return []

# "Drop every row that has any missing value" and nothing else.
func sloppy_steps(_file: Dictionary) -> Array:
	return [{"op":"missing", "col":"*", "mode":"drop"}]

func run_steps(file: Dictionary, list: Array) -> Dictionary:
	return Pipeline.from_array(file.raw, list, file.aux).run()

# ---------- evaluation (truth statements from a table) ----------
func _valid_date(v: Variant) -> bool:
	return v is String and Clock.is_valid(String(v))

func _daily(file: Dictionary, ds: RefCounted) -> Dictionary:
	var name: String = file.name
	var dc: String = file.recipe.date_col
	var sums := {}
	var counts := {}
	var all_dates := {}
	var kind := "mean"
	if name in ["web_funnel"]: kind = "sum"
	if name in ["support_tickets"]: kind = "count"
	for r in ds.rows:
		var date: Variant = r[ds.col_index(dc)]
		if not _valid_date(date): continue
		all_dates[date] = true
		var value: Variant = null
		match name:
			"sales_export":
				var u: Variant = Ops.num(r[ds.col_index("units")])
				var p: Variant = Ops.num(r[ds.col_index("price")])
				if u != null and p != null: value = u * p
			"market_prices": value = Ops.num(r[ds.col_index("value")])
			"web_funnel":
				if r[ds.col_index("step")] == "purchase": value = Ops.num(r[ds.col_index("users")])
			"loan_book": value = Ops.num(r[ds.col_index("days_past_due")])
			"support_tickets": value = 1.0
			"competitor_scrape": value = Ops.num(r[ds.col_index("price")])
		if value == null: continue
		sums[date] = float(sums.get(date, 0.0)) + float(value)
		counts[date] = int(counts.get(date, 0)) + 1
	return {"kind":kind, "sums":sums, "counts":counts, "dates":all_dates}

# Percentage change of the last 7 days against the 7 days before, ending at the last date in the table.
func window_change(file: Dictionary, ds: RefCounted) -> Variant:
	var d := _daily(file, ds)
	if d.dates.is_empty(): return null
	var dates: Array = d.dates.keys()
	dates.sort()
	var end: String = dates[dates.size() - 1]
	var first: String = dates[0]
	var w := int(cfg.window)
	var means: Array = []
	for window in 2:
		var total := 0.0
		var n := 0
		for k in w:
			var day := Clock.add_days(end, -(window * w + k))
			if day < first: continue
			if d.kind == "mean":
				if d.counts.has(day):
					total += d.sums[day] / d.counts[day]
					n += 1
			else:
				total += float(d.sums.get(day, 0.0))
				n += 1
		if n < 3: return null
		means.append(total / n)
	if means[1] == 0.0: return null
	return (means[0] / means[1] - 1.0) * 100.0

func direction_of(pct: float) -> String:
	if pct >= float(cfg.dead_zone_pct): return "tang"
	if pct <= -float(cfg.dead_zone_pct): return "giam"
	return "ngang"

func band_of(pct: float) -> String:
	var edges: Array = cfg.bands
	if pct < float(edges[0]): return "<%d" % int(edges[0])
	for i in range(edges.size() - 1):
		if pct < float(edges[i + 1]): return "%d..%d" % [int(edges[i]), int(edges[i + 1])]
	return ">%d" % int(edges[edges.size() - 1])

func band_index(band: String) -> int:
	var all := bands()
	return all.find(band)

func bands() -> Array:
	var edges: Array = cfg.bands
	var out: Array = ["<%d" % int(edges[0])]
	for i in range(edges.size() - 1): out.append("%d..%d" % [int(edges[i]), int(edges[i + 1])])
	out.append(">%d" % int(edges[edges.size() - 1]))
	return out

func _window_rows(file: Dictionary, ds: RefCounted) -> Array:
	var dc: int = ds.col_index(file.recipe.date_col)
	var dates: Array = []
	for r in ds.rows:
		if _valid_date(r[dc]): dates.append(r[dc])
	if dates.is_empty(): return []
	dates.sort()
	var end: String = dates[dates.size() - 1]
	var start := Clock.add_days(end, -(int(cfg.window) - 1))
	return ds.rows.filter(func(r): return _valid_date(r[dc]) and r[dc] >= start and r[dc] <= end)

# All truth statements of a file, computed from the table `ds` (the reference table for the real truth,
# or any player's/naive table to see what that table would say).
func truth(file: Dictionary, ds: RefCounted, spike: String = "") -> Array:
	if file.has("truth_list"): return file.truth_list.duplicate(true)
	var name: String = file.name
	var out: Array = []
	if name != "ab_test_log":
		var pct: Variant = window_change(file, ds)
		out.append({"id":"metric_change", "value":null if pct == null else {"pct":pct, "direction":direction_of(pct), "band":band_of(pct)}})
	match name:
		"sales_export", "market_prices", "competitor_scrape":
			out.append({"id":"spike_error", "value":spike if spike != "" else "none"})
		"web_funnel":
			var step_sum := {}
			var si: int = ds.col_index("step")
			var ui: int = ds.col_index("users")
			for r in _window_rows(file, ds):
				var n: Variant = Ops.num(r[ui])
				if n != null: step_sum[r[si]] = float(step_sum.get(r[si], 0.0)) + n
			var best := ""
			var best_ratio := 2.0
			var order: Array = ["visit", "signup", "cart", "purchase"]
			for i in 3:
				if step_sum.has(order[i]) and step_sum.has(order[i + 1]) and step_sum[order[i]] > 0.0:
					var ratio: float = step_sum[order[i + 1]] / step_sum[order[i]]
					if ratio < best_ratio:
						best_ratio = ratio
						best = "%s>%s" % [order[i], order[i + 1]]
			out.append({"id":"biggest_dropoff", "value":best})
		"support_tickets":
			var cat := {}
			var ci: int = ds.col_index("category")
			for r in _window_rows(file, ds): cat[r[ci]] = int(cat.get(r[ci], 0)) + 1
			var top := ""
			var top_n := -1
			var keys: Array = cat.keys()
			keys.sort()
			for k in keys:
				if cat[k] > top_n:
					top_n = cat[k]
					top = str(k)
			out.append({"id":"top_category", "value":top})
		"ab_test_log":
			var vi: int = ds.col_index("variant")
			var xi: int = ds.col_index("converted")
			var n := {"A":0.0, "B":0.0}
			var x := {"A":0.0, "B":0.0}
			for r in ds.rows:
				var v: Variant = r[vi]
				var c: Variant = Ops.num(r[xi])
				if (v == "A" or v == "B") and c != null:
					n[v] += 1.0
					x[v] += c
			var significant := false
			var winner := "none"
			if n.A > 1.0 and n.B > 1.0:
				var pa: float = x.A / n.A
				var pb: float = x.B / n.B
				var pooled: float = (x.A + x.B) / (n.A + n.B)
				var se := sqrt(pooled * (1.0 - pooled) * (1.0 / n.A + 1.0 / n.B))
				if se > 0.0 and absf(pb - pa) / se >= float(cfg.datasets.ab_test_log.alpha_z):
					significant = true
					winner = "B" if pb > pa else "A"
			out.append({"id":"ab_significant", "value":significant})
			out.append({"id":"ab_winner", "value":winner})
	return out

# The entry-error label the reference pipeline removes (largest absolute value flagged), for spike_error.
func spike_label(file: Dictionary) -> String:
	if file.has("ref_steps"): return ""
	var r: Dictionary = file.recipe
	if not r.defects.has("outliers") or not LABEL_COL.has(file.name): return ""
	var list := steps(file)
	var at := -1
	for i in list.size():
		if list[i].op == "outliers": at = i
	var before: RefCounted = Pipeline.from_array(file.raw, list, file.aux).run(at).dataset
	var after: RefCounted = Pipeline.from_array(file.raw, list, file.aux).run(at + 1).dataset
	var kept := {}
	for rid in after.rids: kept[rid] = true
	var ci: int = before.col_index(r.outlier_col)
	var li: int = before.col_index(LABEL_COL[file.name])
	var best := -1.0
	var label := ""
	for i in before.rows.size():
		if kept.has(before.rids[i]): continue
		var v: Variant = Ops.num(before.rows[i][ci])
		if v != null and absf(v) > best:
			best = absf(v)
			label = str(before.rows[i][li])
	return label

# Everything the review needs: reference table, truth, spike label.
func evaluate_reference(file: Dictionary) -> Dictionary:
	var result := run_steps(file, steps(file))
	var spike := spike_label(file)
	return {"dataset":result.dataset, "report":result.report, "truth":truth(file, result.dataset, spike), "spike":spike}

# Choices offered to the player for each finding (no truth inside).
func options(file: Dictionary) -> Array:
	if file.has("options"): return file.options.duplicate(true)
	var out: Array = []
	var name: String = file.name
	if name != "ab_test_log": out.append({"id":"metric_change", "directions":["tang", "giam", "ngang"], "bands":bands()})
	match name:
		"sales_export", "market_prices", "competitor_scrape":
			var choices: Array = []
			match name:
				"sales_export": choices = cfg.datasets.sales_export.typos.region.keys()
				"market_prices": choices = VENUES.duplicate()
				_: choices = cfg.datasets.competitor_scrape.shops.map(func(sh): return sh.name)
			choices.append("none")
			out.append({"id":"spike_error", "choices":choices})
		"web_funnel": out.append({"id":"biggest_dropoff", "choices":["visit>signup", "signup>cart", "cart>purchase"]})
		"support_tickets": out.append({"id":"top_category", "choices":["billing", "bug", "account", "shipping"]})
		"ab_test_log":
			out.append({"id":"ab_significant", "choices":[true, false]})
			out.append({"id":"ab_winner", "choices":["A", "B", "none"]})
	return out

extends RefCounted
# T-036: honest analyst bots. PUBLIC APIs only: the Session (files, Sheet steps, charts, findings, payload),
# the world's question / news / verify, the engine's public Dataset and Ops classes and the public reading
# rules. Never review(), the manifest, the reference pipeline or any hidden field.
const DS = preload("res://scripts/data/dataset.gd")
const Ops = preload("res://scripts/data/ops.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Reading = preload("res://tests/t036_reading.gd")
const BOTS := ["analyst_clean", "analyst_sloppy", "analyst_slow", "chart_misleader"]
const LABEL_COL := {"sales_export":"region", "market_prices":"venue", "competitor_scrape":"shop"}
const VND_PER_USD := 24000.0
const FUNNEL := ["visit", "signup", "cart", "purchase"]

static func _norm(v: Variant) -> String:
	return str(v).strip_edges().to_lower().replace("_", " ")

static func _key(v: Variant) -> String:
	return str(v).strip_edges().to_lower().replace("_", "").replace(" ", "").replace("-", "")

# ---------- which file answers the question ----------
static func series_of(table: RefCounted) -> String:
	var c: int = table.col_index("series")
	if c < 0: return ""
	var counts := {}
	for r in table.rows:
		if r[c] is String and r[c] != "series": counts[_norm(r[c])] = int(counts.get(_norm(r[c]), 0)) + 1
	var best := ""
	for k in counts:
		if best == "" or counts[k] > counts[best]: best = k
	return best

static func pick_file(files: Array, qid: String) -> String:
	for option in Reading.QUESTION_FILES.get(qid, []):
		for f in files:
			if f.name != option[0]: continue
			if option[1] == "" or series_of(DS.from_dict(f.table)) == option[1]: return str(f.id)
	return ""

# ---------- heuristic cleaner ----------
static func _numeric_share(ds: RefCounted, c: int) -> float:
	var n := 0
	var total := 0
	for r in ds.rows:
		if Ops.is_missing(r[c]): continue
		total += 1
		if Ops.parse_number_text(r[c]) != null: n += 1
	return float(n) / maxf(1.0, total)

static func _is_date_col(ds: RefCounted, c: int) -> bool:
	return ds.types[c] == "date" or str(ds.cols[c]).contains("date")

static func _nums(ds: RefCounted, c: int) -> Array:
	var out: Array = []
	for r in ds.rows:
		var v: Variant = Ops.num(r[c])
		if v != null: out.append(v)
	return out

# Looks only at the visible table (and the lookup tables). Returns {steps, spike}.
static func clean_steps(raw: RefCounted, ctx: Dictionary, file_name: String) -> Dictionary:
	var steps: Array = []
	var st := {"cur":raw}
	var spike := "none"
	var push := func(step: Dictionary) -> bool:
		var r: Dictionary = Ops.apply(st.cur, step, ctx)
		if not r.ok: return false
		steps.append(step)
		st.cur = r.dataset
		return true
	# repeated header rows, subtotal rows
	for marker in ["__header__", "TOTAL"]:
		for c in st.cur.cols.size():
			var want: String = st.cur.cols[c] if marker == "__header__" else marker
			if st.cur.rows.any(func(r): return r[c] is String and r[c] == want):
				push.call({"op":"filter", "col":st.cur.cols[c], "cmp":"!=", "value":want})
				break
	# exact duplicate rows
	var seen := {}
	var dup := false
	for r in st.cur.rows:
		var k := JSON.stringify(r)
		if seen.has(k): dup = true
		seen[k] = true
	if dup: push.call({"op":"dedupe", "cols":[]})
	# test / internal accounts: through a lookup table that marks them, or by a visible marker in a text column
	for other_name in ctx:
		var other: RefCounted = ctx[other_name]
		for oc in other.cols.size():
			if not other.rows.any(func(r): return _norm(r[oc]) == "test"): continue
			for key in other.cols:
				if key != other.cols[oc] and st.cur.has_col(key):
					push.call({"op":"standardize", "col":key, "case":"upper"})
					push.call({"op":"join", "other":other_name, "left_key":key, "right_key":key, "kind":"left", "take":[other.cols[oc]]})
					push.call({"op":"filter", "col":other.cols[oc], "cmp":"!=", "value":"Test"})
					break
			break
	for token in ["test", "tst-", "qa_"]:
		for c in raw.cols.size():
			var ci: int = st.cur.col_index(raw.cols[c])
			if ci < 0 or _numeric_share(st.cur, ci) > 0.5: continue
			if st.cur.rows.any(func(r): return r[ci] is String and String(r[ci]).to_lower().contains(token)):
				push.call({"op":"filter", "col":st.cur.cols[ci], "cmp":"not_contains", "value":token})
	# missing values: numbers are dropped (zero counts as missing when it cannot be a real value), labels are filled
	for c in raw.cols.size():
		var ci: int = st.cur.col_index(raw.cols[c])
		if ci < 0 or _is_date_col(st.cur, ci): continue
		var numeric := _numeric_share(st.cur, ci) > 0.5
		var missing := 0
		var zeros := 0
		var nonzero := {}
		for r in st.cur.rows:
			if Ops.is_missing(r[ci]): missing += 1
			elif numeric:
				var v: Variant = Ops.parse_number_text(r[ci])
				if v != null and v == 0.0: zeros += 1
				elif v != null: nonzero[v] = true
		var zero_missing: bool = numeric and zeros > 0 and nonzero.size() > 2 and float(zeros) / maxf(1.0, st.cur.rows.size()) < 0.15
		if missing == 0 and not zero_missing: continue
		if numeric: push.call({"op":"missing", "col":st.cur.cols[ci], "mode":"drop", "zero_missing":zero_missing})
		else: push.call({"op":"missing", "col":st.cur.cols[ci], "mode":"value", "value":"unknown", "zero_missing":false})
	# negative quantities (refunds)
	for c in st.cur.cols.size():
		if _is_date_col(st.cur, c) or _numeric_share(st.cur, c) <= 0.5: continue
		if _nums(st.cur, c).any(func(v): return v < 0.0): push.call({"op":"filter", "col":st.cur.cols[c], "cmp":">", "value":0})
	# category spellings: variants that differ only by case / spaces / underscores, or that extend one known label
	for c in st.cur.cols.size():
		if _is_date_col(st.cur, c) or _numeric_share(st.cur, c) > 0.5 or st.cur.cols[c] in ["currency", "unit"]: continue
		var counts := {}
		for r in st.cur.rows:
			if r[c] is String: counts[r[c]] = int(counts.get(r[c], 0)) + 1
		var groups := {}
		for v in counts:
			var k := _key(v)
			if not groups.has(k): groups[k] = {"n":0, "best":"", "best_n":-1}
			groups[k].n += counts[v]
			var tidy: bool = String(v).strip_edges() == v
			if tidy and counts[v] > groups[k].best_n:
				groups[k].best = v
				groups[k].best_n = counts[v]
		if groups.size() > 14: continue
		var sizes: Array = groups.values().map(func(g): return g.n)
		sizes.sort()
		var big: float = float(sizes[sizes.size() - 1])
		var target := {}
		for k in groups:
			target[k] = groups[k].best if groups[k].best != "" else k
			if float(groups[k].n) >= 0.25 * big: continue
			var matches: Array = []
			for k2 in groups:
				if k2 != k and float(groups[k2].n) >= 0.25 * big and (k2.begins_with(k) or k.begins_with(k2) or k.ends_with(k2)): matches.append(k2)
			if matches.size() == 1 and groups[matches[0]].best != "": target[k] = groups[matches[0]].best
		var map := {}
		for v in counts:
			if target[_key(v)] != v: map[v] = target[_key(v)]
		if not map.is_empty(): push.call({"op":"standardize", "col":st.cur.cols[c], "map":map})
	# units: text numbers such as 1.23k, and prices quoted in another currency
	for c in st.cur.cols.size():
		if _is_date_col(st.cur, c) or _numeric_share(st.cur, c) <= 0.5: continue
		if st.cur.rows.any(func(r): return r[c] is String and Ops.num(r[c]) == null and Ops.parse_number_text(r[c]) != null):
			push.call({"op":"convert", "kind":"number", "col":st.cur.cols[c]})
	if st.cur.has_col("currency") and st.cur.has_col("price") and st.cur.column_values("currency").has("VND"):
		push.call({"op":"convert", "kind":"currency", "col":"price", "currency_col":"currency", "rates":{"VND":1.0 / VND_PER_USD, "USD":1.0}})
		push.call({"op":"standardize", "col":"currency", "map":{"VND":"USD"}})
	# dates in one format, then a partial last day
	var date_col: String = Reading.METRIC[file_name].date
	var dc: int = st.cur.col_index(date_col)
	if dc >= 0:
		if st.cur.rows.any(func(r): return not (r[dc] is String and Clock.is_valid(r[dc]))): push.call({"op":"parse_date", "col":date_col, "format":"auto"})
		var per_day := {}
		for r in st.cur.rows:
			if r[dc] is String and Clock.is_valid(r[dc]): per_day[r[dc]] = int(per_day.get(r[dc], 0)) + 1
		var days: Array = per_day.keys()
		days.sort()
		if days.size() >= 4:
			var last: String = days[days.size() - 1]
			var others: Array = days.slice(0, days.size() - 1).map(func(d): return per_day[d])
			others.sort()
			if float(per_day[last]) < 0.6 * float(others[others.size() / 2]): push.call({"op":"filter", "col":date_col, "cmp":"<", "value":last})
	# entry-error outliers: far outside the IQR fences
	for c in st.cur.cols.size():
		if _is_date_col(st.cur, c) or _numeric_share(st.cur, c) <= 0.5: continue
		var vals := _nums(st.cur, c)
		if vals.size() < 8: continue
		vals.sort()
		var q1 := Ops.quantile(vals, 0.25)
		var q3 := Ops.quantile(vals, 0.75)
		var iqr := q3 - q1
		if iqr <= 0.0 or float(vals[vals.size() - 1]) <= q3 + 6.0 * iqr: continue
		var before: RefCounted = st.cur
		if push.call({"op":"outliers", "col":st.cur.cols[c], "method":"iqr", "k":3.0, "action":"remove"}) and LABEL_COL.has(file_name) and spike == "none":
			var kept := {}
			for rid in st.cur.rids: kept[rid] = true
			var li: int = before.col_index(LABEL_COL[file_name])
			var top := -1.0
			for i in before.rows.size():
				if kept.has(before.rids[i]): continue
				var v: Variant = Ops.num(before.rows[i][c])
				if v != null and absf(v) > top and li >= 0:
					top = absf(v)
					spike = str(before.rows[i][li])
	return {"steps":steps, "spike":spike}

# ---------- the metric and the findings, from any table ----------
static func window_pct(file_name: String, ds: RefCounted) -> Variant:
	var m: Dictionary = Reading.METRIC[file_name]
	var dc: int = ds.col_index(m.date)
	if dc < 0: return null
	var sums := {}
	var counts := {}
	var dates := {}
	for r in ds.rows:
		if not (r[dc] is String and Clock.is_valid(r[dc])): continue
		dates[r[dc]] = true
		var value: Variant = null
		match file_name:
			"sales_export":
				var u: Variant = Ops.num(r[ds.col_index("units")])
				var p: Variant = Ops.num(r[ds.col_index("price")])
				if u != null and p != null: value = u * p
			"web_funnel":
				if r[ds.col_index("step")] == "purchase": value = Ops.num(r[ds.col_index("users")])
			"support_tickets": value = 1.0
			_: value = Ops.num(r[ds.col_index(m.value)])
		if value == null: continue
		sums[r[dc]] = float(sums.get(r[dc], 0.0)) + float(value)
		counts[r[dc]] = int(counts.get(r[dc], 0)) + 1
	if dates.is_empty(): return null
	var keys: Array = dates.keys()
	keys.sort()
	var end: String = keys[keys.size() - 1]
	var means: Array = []
	for window in 2:
		var total := 0.0
		var n := 0
		for k in Reading.WINDOW:
			var day := Clock.add_days(end, -(window * Reading.WINDOW + k))
			if day < keys[0]: continue
			if m.kind == "mean":
				if counts.has(day):
					total += sums[day] / counts[day]
					n += 1
			else:
				total += float(sums.get(day, 0.0))
				n += 1
		if n < 3: return null
		means.append(total / n)
	if means[1] == 0.0: return null
	return (means[0] / means[1] - 1.0) * 100.0

static func _window_rows(file_name: String, ds: RefCounted) -> Array:
	var dc: int = ds.col_index(Reading.METRIC[file_name].date)
	var dates: Array = []
	for r in ds.rows:
		if r[dc] is String and Clock.is_valid(r[dc]): dates.append(r[dc])
	if dates.is_empty(): return []
	dates.sort()
	var end: String = dates[dates.size() - 1]
	var start := Clock.add_days(end, -(Reading.WINDOW - 1))
	return ds.rows.filter(func(r): return r[dc] is String and Clock.is_valid(r[dc]) and r[dc] >= start and r[dc] <= end)

static func findings_from(file_name: String, ds: RefCounted, spike: String, pct: Variant) -> Dictionary:
	var out := {}
	if pct != null: out["metric_change"] = {"direction":Reading.direction_of(pct), "band":Reading.band_of(pct)}
	match file_name:
		"sales_export", "market_prices", "competitor_scrape": out["spike_error"] = spike
		"web_funnel":
			var sums := {}
			for r in _window_rows(file_name, ds):
				var n: Variant = Ops.num(r[ds.col_index("users")])
				if n != null: sums[r[ds.col_index("step")]] = float(sums.get(r[ds.col_index("step")], 0.0)) + n
			var best := ""
			var best_ratio := 2.0
			for i in 3:
				if sums.has(FUNNEL[i]) and sums.has(FUNNEL[i + 1]) and sums[FUNNEL[i]] > 0.0 and sums[FUNNEL[i + 1]] / sums[FUNNEL[i]] < best_ratio:
					best_ratio = sums[FUNNEL[i + 1]] / sums[FUNNEL[i]]
					best = "%s>%s" % [FUNNEL[i], FUNNEL[i + 1]]
			if best != "": out["biggest_dropoff"] = best
		"support_tickets":
			var cat := {}
			for r in _window_rows(file_name, ds): cat[r[ds.col_index("category")]] = int(cat.get(r[ds.col_index("category")], 0)) + 1
			var keys: Array = cat.keys().map(func(k): return str(k))
			keys.sort()
			var top := ""
			for k in keys:
				if top == "" or cat[k] > cat[top]: top = k
			if top != "": out["top_category"] = top
	return out

# ---------- charts ----------
static func good_chart(file_name: String) -> Dictionary:
	var m: Dictionary = Reading.METRIC[file_name]
	return {"type":"line", "x":m.date, "y":m.chart_y, "agg":"count" if m.kind == "count" else ("sum" if m.kind == "sum" else "mean"), "series":"", "sort":"none", "title":"%s per day" % m.chart_y, "y_label":m.unit, "y_min":null, "y_max":null}

# A bar per day (too many bars) on an axis that does not start at zero.
static func misleading_chart(file_name: String, ds: RefCounted) -> Dictionary:
	var spec := good_chart(file_name)
	spec.type = "bar"
	var vals := _nums(ds, ds.col_index(spec.y))
	spec.y_min = 1.0 if vals.is_empty() else maxf(0.5, float(vals.min()) * 0.9)
	return spec

# ---------- one day ----------
# Does the data work of `bot` through the Session and returns {read (forecast from the data or ""), file_id, pct}.
static func work(session: RefCounted, qid: String, bot: String, late_limit: int, world: RefCounted) -> Dictionary:
	var file_id := pick_file(session.files, qid)
	if file_id == "" and not session.files.is_empty(): file_id = str(session.files[0].id)
	if file_id == "": return {"read":"", "file_id":"", "pct":null}
	var name: String = session.file_info(file_id).name
	if bot == "analyst_slow":
		# Opens the other files too, as long as the rest of the work can still be delivered before the hard deadline.
		var reserve: int = session.limit("minutes_per_file", 10) * 2 + session.limit("minutes_per_clean", 0) + session.limit("minutes_findings", 0) + session.limit("minutes_per_chart", 10) + 45
		for f in session.files:
			if str(f.id) != file_id and int(world.status().minutes) + reserve <= late_limit: session.open_file(str(f.id))
	var sheet: RefCounted = session.open_file(file_id)
	var spike := "none"
	if bot == "analyst_sloppy":
		sheet.add_step({"op":"missing", "col":"*", "mode":"drop"})
	else:
		var plan := clean_steps(sheet.raw, sheet.context, name)
		# Same result as adding the steps one by one in the Sheet; only the last one goes through add_step
		# (it recomputes, and it is the step that tells the Session the file was cleaned).
		for i in plan.steps.size():
			if i < plan.steps.size() - 1: sheet.pipeline.add(plan.steps[i])
			else: sheet.add_step(plan.steps[i])
		spike = plan.spike
	var table: RefCounted = sheet.table()
	var pct: Variant = window_pct(name, table) if Reading.METRIC.has(name) and name != "ab_test_log" else null
	var found := findings_from(name, table, spike, pct)
	for id in found: session.set_finding(file_id, id, found[id])
	var spec := good_chart(name)
	if bot == "analyst_sloppy": spec = session.default_spec(file_id, "clean")
	if bot == "chart_misleader": spec = misleading_chart(name, table)
	var pin: String = session.pin_chart(file_id, "clean", spec)
	if pin != "": session.attach(pin)
	if bot == "analyst_slow":
		# Keeps charting every angle until the afternoon is gone (never past the hard deadline).
		var cost: int = session.limit("minutes_per_chart", 10)
		var extra := 0
		while session.can_pin() and int(world.status().minutes) + cost + 45 <= late_limit:
			var again := spec.duplicate(true)
			extra += 1
			again.title = "%s (view %d)" % [spec.title, extra + 1]
			again.agg = ["max", "min", "median"][extra % 3] if again.agg != "count" else "count"
			if session.pin_chart(file_id, "clean", again) == "": break
	return {"read":Reading.read_answer(qid, name, pct) if pct != null else "", "file_id":file_id, "pct":pct}

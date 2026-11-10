extends RefCounted
# T-033: chart specs, series extraction and the chart quality checker.
# spec: {type: bar|line|scatter|histogram|pie, x, y, agg: sum|mean|median|count|min|max, series, y_min, y_max,
#        sort: none|asc|desc|x, y2, smoothing (window, 0 = off), y_label, title, bins}
const Ops = preload("res://scripts/data/ops.gd")
const Loader = preload("res://scripts/data.gd")
const TYPES := ["bar", "line", "scatter", "histogram", "pie"]
var cfg: Dictionary

func _init(p_cfg: Dictionary = {}) -> void:
	var all: Dictionary = p_cfg if not p_cfg.is_empty() else Loader.load_json("res://data/datasets.json")
	cfg = all.charts

static func _key(v: Variant) -> String:
	return "(missing)" if v == null else str(v)

func _err(code: String, detail: String = "") -> Dictionary:
	return {"ok":false, "error":code, "detail":detail}

# Aggregated points per series: [{x, y}], x keys in first-appearance order before sorting.
func _grouped(ds: RefCounted, spec: Dictionary) -> Dictionary:
	var xc: int = ds.col_index(str(spec.get("x", "")))
	var yc: int = ds.col_index(str(spec.get("y", "")))
	var sc := -1
	if str(spec.get("series", "")) != "":
		sc = ds.col_index(str(spec.series))
		if sc < 0: return _err("unknown_column", str(spec.series))
	var agg := str(spec.get("agg", "sum"))
	if not Ops.AGG.has(agg): return _err("bad_mode", agg)
	if xc < 0: return _err("unknown_column", str(spec.get("x", "<none>")))
	if yc < 0 and agg != "count": return _err("unknown_column", str(spec.get("y", "<none>")))
	var buckets := {}
	var names: Array = []
	var xs: Array = []
	for r in ds.rows:
		var sname := "all" if sc < 0 else _key(r[sc])
		var xk := _key(r[xc])
		if not names.has(sname):
			names.append(sname)
			buckets[sname] = {}
		if not xs.has(xk): xs.append(xk)
		if not buckets[sname].has(xk): buckets[sname][xk] = []
		buckets[sname][xk].append(r[yc] if yc >= 0 else 1)
	var out: Array = []
	for sname in names:
		var points: Array = []
		for xk in xs:
			if buckets[sname].has(xk): points.append({"x":xk, "y":Ops.aggregate(agg, buckets[sname][xk])})
		out.append({"name":sname, "points":points})
	return {"ok":true, "series":out, "categories":xs}

func _sorted(points: Array, mode: String) -> Array:
	var out := points.duplicate()
	match mode:
		"asc": out.sort_custom(func(a, b): return Ops.cmp_null_last(a.y, b.y) < 0)
		"desc": out.sort_custom(func(a, b): return Ops.cmp_null_last(b.y, a.y) < 0 if a.y != null and b.y != null else Ops.cmp_null_last(a.y, b.y) < 0)
		"x": out.sort_custom(func(a, b): return Ops.cmp_null_last(a.x, b.x) < 0)
	return out

func _smooth(points: Array, window: int) -> Array:
	if window < 2: return points
	var out: Array = []
	for i in points.size():
		var total := 0.0
		var n := 0
		for k in range(maxi(0, i - window + 1), i + 1):
			if points[k].y != null:
				total += float(points[k].y)
				n += 1
		out.append({"x":points[i].x, "y":total / n if n > 0 else null})
	return out

func series(ds: RefCounted, spec: Dictionary) -> Dictionary:
	var type := str(spec.get("type", ""))
	if not TYPES.has(type): return _err("bad_chart_type", type)
	if type == "scatter":
		var xc: int = ds.col_index(str(spec.get("x", "")))
		var yc: int = ds.col_index(str(spec.get("y", "")))
		if xc < 0 or yc < 0: return _err("unknown_column", str(spec.get("x", "")) if xc < 0 else str(spec.get("y", "")))
		var pts: Array = []
		for r in ds.rows:
			var a: Variant = Ops.num(r[xc])
			var b: Variant = Ops.num(r[yc])
			if a != null and b != null: pts.append({"x":a, "y":b})
		return {"ok":true, "type":type, "series":[{"name":"all", "points":pts}], "categories":[]}
	if type == "histogram":
		var col := str(spec.get("y", spec.get("x", "")))
		var c: int = ds.col_index(col)
		if c < 0: return _err("unknown_column", col)
		var nums: Array = []
		for r in ds.rows:
			var v: Variant = Ops.num(r[c])
			if v != null: nums.append(v)
		if nums.is_empty(): return _err("no_values", col)
		var bins := maxi(1, int(spec.get("bins", 10)))
		var lo: float = nums.min()
		var hi: float = nums.max()
		var width := (hi - lo) / bins if hi > lo else 1.0
		var counts: Array = []
		counts.resize(bins)
		counts.fill(0)
		for v in nums: counts[mini(bins - 1, int((v - lo) / width))] += 1
		var pts: Array = []
		for b in bins: pts.append({"x":"%.4g..%.4g" % [lo + b * width, lo + (b + 1) * width], "y":counts[b]})
		return {"ok":true, "type":type, "series":[{"name":"count", "points":pts}], "categories":pts.map(func(p): return p.x)}
	var grouped := _grouped(ds, spec)
	if not grouped.ok: return grouped
	var result: Array = []
	for s in grouped.series:
		var points: Array = s.points
		if type == "line":
			points = _sorted(points, "x")
			points = _smooth(points, int(spec.get("smoothing", 0)))
		else:
			points = _sorted(points, str(spec.get("sort", "none")))
		result.append({"name":s.name, "points":points})
	return {"ok":true, "type":type, "series":result, "categories":grouped.categories}

# Quality flags: [{id, text_key, teach_key, severity}]
func check(ds: RefCounted, spec: Dictionary) -> Array:
	var flags: Array = []
	var type := str(spec.get("type", ""))
	if not TYPES.has(type): return flags
	var add := func(id, severity):
		flags.append({"id":id, "text_key":"chart_flag_" + id, "teach_key":"chart_teach_" + id, "severity":severity})
	var raw := series(ds, spec.merged({"smoothing":0}, true))
	if type == "bar" and spec.get("y_min") != null and float(spec.y_min) > 0.0: add.call("truncated_bar_axis", "error")
	if str(spec.get("y2", "")) != "": add.call("dual_axis", "warn")
	if raw.get("ok", false):
		var cats: int = raw.categories.size()
		if type == "bar" and cats > int(cfg.bar_max_categories): add.call("too_many_categories", "warn")
		if type == "bar" and raw.series.size() > 6: add.call("too_many_categories", "warn")
		if type == "pie" and cats > int(cfg.pie_max_slices): add.call("pie_too_many_slices", "warn")
		if type == "bar" and not (str(spec.get("sort", "none")) in ["asc", "desc"]) and cats >= int(cfg.unsorted_min_categories):
			var xc: int = ds.col_index(str(spec.get("x", "")))
			if xc >= 0 and ds.types[xc] != "date": add.call("unsorted_bars", "warn")
		if type == "line" and int(spec.get("smoothing", 0)) >= int(cfg.smoothing_min_window) and _has_spike(raw.series): add.call("smoothing_hides_spikes", "warn")
	if type != "pie" and type != "histogram" and str(spec.get("y_label", "")).strip_edges() == "": add.call("missing_units", "warn")
	return flags

func _has_spike(all_series: Array) -> bool:
	for s in all_series:
		var vals: Array = []
		for p in s.points:
			if p.y != null: vals.append(float(p.y))
		if vals.size() < int(cfg.spike_min_points): continue
		var sorted := vals.duplicate()
		sorted.sort()
		var med := Ops.quantile(sorted, 0.5)
		var devs: Array = vals.map(func(v): return absf(v - med))
		devs.sort()
		var mad := Ops.quantile(devs, 0.5) * 1.4826
		if mad <= 0.0:
			var mean := 0.0
			for v in vals: mean += v
			mean /= vals.size()
			var variance := 0.0
			for v in vals: variance += (v - mean) * (v - mean)
			mad = sqrt(variance / vals.size())
		if mad <= 0.0: continue
		for v in vals:
			if absf(v - med) / mad >= float(cfg.spike_z): return true
	return false

extends RefCounted
# T-033: no-code operations. Every operation is a pure function: (dataset, step dictionary, context) ->
# {"ok":true,"dataset":ds} or {"ok":false,"error":code,"detail":text}. Nothing here ever raises.
const DS = preload("res://scripts/data/dataset.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const OPS := ["sort", "filter", "dedupe", "missing", "standardize", "convert", "parse_date", "computed", "group", "pivot", "join", "outliers", "sample"]
const DEFAULT_TOKENS := ["", "n/a", "na", "null", "none", "-", "nan"]
const MONTHS := ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
const AGG := ["sum", "mean", "median", "count", "min", "max"]

static func apply(ds: RefCounted, step: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var op := str(step.get("op", ""))
	if not OPS.has(op): return _err("unknown_op", op)
	match op:
		"sort": return _sort(ds, step)
		"filter": return _filter(ds, step)
		"dedupe": return _dedupe(ds, step)
		"missing": return _missing(ds, step)
		"standardize": return _standardize(ds, step)
		"convert": return _convert(ds, step)
		"parse_date": return _parse_date_op(ds, step)
		"computed": return _computed(ds, step)
		"group": return _group(ds, step)
		"pivot": return _pivot(ds, step)
		"join": return _join(ds, step, ctx)
		"outliers": return _outliers(ds, step)
		"sample": return _sample(ds, step)
	return _err("unknown_op", op)

static func _err(code: String, detail: String = "") -> Dictionary:
	return {"ok":false, "error":code, "detail":detail}

static func _ok(ds: RefCounted) -> Dictionary:
	return {"ok":true, "dataset":ds}

# Empty string when the column exists, otherwise the offending name.
static func _need_col(ds: RefCounted, step: Dictionary, key: String) -> String:
	var col := str(step.get(key, ""))
	if ds.cols.has(col): return ""
	return col if col != "" else "<none>"

# ---------- value helpers ----------
static func is_missing(v: Variant, tokens: Array = DEFAULT_TOKENS, zero: bool = false) -> bool:
	if v == null: return true
	if v is String:
		return tokens.has(String(v).strip_edges().to_lower())
	if zero and (v is int or v is float) and float(v) == 0.0: return true
	return false

# Strict number: int/float, or a string that is a plain number. Anything else is null.
static func num(v: Variant) -> Variant:
	if v is int or v is float: return float(v)
	if v is String:
		var s := String(v).strip_edges()
		if s.is_valid_float(): return float(s)
	return null

# Tolerant text number: "$1,234.5", "12.5k", "3M", "12%", "(40)", "5 USD".
static func parse_number_text(v: Variant) -> Variant:
	if v is int or v is float: return float(v)
	if not (v is String): return null
	var s := String(v).strip_edges()
	if s == "": return null
	var negative := false
	if s.begins_with("(") and s.ends_with(")"):
		negative = true
		s = s.substr(1, s.length() - 2)
	for junk in ["$", "USD", "usd", "VND", "vnd", ",", " "]:
		s = s.replace(junk, "")
	var mult := 1.0
	if s.length() > 1:
		var last := s[s.length() - 1]
		match last:
			"k", "K": mult = 1000.0
			"m", "M": mult = 1000000.0
			"b", "B": mult = 1000000000.0
			"%": mult = 0.01
		if mult != 1.0: s = s.substr(0, s.length() - 1)
	if not s.is_valid_float(): return null
	var value := float(s) * mult
	return -value if negative else value

static func parse_date(v: Variant, fmt: String = "auto") -> Variant:
	if not (v is String): return null
	var s := String(v).strip_edges()
	if s == "": return null
	var y := 0
	var m := 0
	var d := 0
	var tokens := s.replace(",", " ").split(" ", false)
	var month_token := -1
	for i in tokens.size():
		if tokens[i].length() >= 3 and MONTHS.has(tokens[i].substr(0, 3).to_lower()) and not tokens[i][0].is_valid_int(): month_token = i
	if month_token >= 0 and tokens.size() >= 3:
		m = MONTHS.find(tokens[month_token].substr(0, 3).to_lower()) + 1
		var rest: Array = []
		for i in tokens.size():
			if i != month_token: rest.append(tokens[i])
		if not (rest[0].is_valid_int() and rest[1].is_valid_int()): return null
		var a := int(rest[0])
		var b := int(rest[1])
		if rest[0].length() == 4:
			y = a
			d = b
		else:
			d = a
			y = b
	else:
		var core := s
		var t := core.find("T")
		if t > 0: core = core.substr(0, t)
		var sp := core.find(" ")
		if sp > 0: core = core.substr(0, sp)
		if core.length() == 8 and core.is_valid_int():
			y = int(core.substr(0, 4))
			m = int(core.substr(4, 2))
			d = int(core.substr(6, 2))
		else:
			var parts: PackedStringArray = core.replace("/", "-").replace(".", "-").split("-")
			if parts.size() != 3: return null
			for p in parts:
				if not p.is_valid_int(): return null
			if parts[0].length() == 4:
				y = int(parts[0])
				m = int(parts[1])
				d = int(parts[2])
			elif parts[2].length() == 4:
				y = int(parts[2])
				if fmt == "mdy":
					m = int(parts[0])
					d = int(parts[1])
				else:
					d = int(parts[0])
					m = int(parts[1])
			else:
				return null
	if y < 1900 or y > 2200 or m < 1 or m > 12 or d < 1 or d > Clock.days_in_month(y, m): return null
	return "%04d-%02d-%02d" % [y, m, d]

# -1/0/1, numbers numerically, otherwise text; null always sorts last.
static func cmp_null_last(a: Variant, b: Variant) -> int:
	if a == null and b == null: return 0
	if a == null: return 1
	if b == null: return -1
	var na: Variant = num(a)
	var nb: Variant = num(b)
	if na != null and nb != null:
		return -1 if na < nb else (1 if na > nb else 0)
	var sa := str(a)
	var sb := str(b)
	return -1 if sa < sb else (1 if sa > sb else 0)

static func quantile(sorted_values: Array, q: float) -> float:
	if sorted_values.is_empty(): return 0.0
	var pos := q * (sorted_values.size() - 1)
	var lo := int(floor(pos))
	var hi := mini(lo + 1, sorted_values.size() - 1)
	return float(sorted_values[lo]) + (float(sorted_values[hi]) - float(sorted_values[lo])) * (pos - lo)

static func aggregate(fn: String, values: Array) -> Variant:
	var nums: Array = []
	var non_missing := 0
	for v in values:
		if not is_missing(v): non_missing += 1
		var n: Variant = num(v)
		if n != null: nums.append(n)
	if fn == "count": return non_missing
	if nums.is_empty(): return null
	match fn:
		"sum":
			var s := 0.0
			for n in nums: s += n
			return s
		"mean":
			var s := 0.0
			for n in nums: s += n
			return s / nums.size()
		"median":
			nums.sort()
			return quantile(nums, 0.5)
		"min": return nums.min()
		"max": return nums.max()
	return null

static func _subset(ds: RefCounted, keep: Array) -> RefCounted:
	var out = ds.copy()
	out.rows = []
	out.rids = []
	for i in keep:
		out.rows.append(ds.rows[i].duplicate())
		out.rids.append(ds.rids[i])
	return out

# ---------- operations ----------
static func _sort(ds: RefCounted, step: Dictionary) -> Dictionary:
	var bad := _need_col(ds, step, "col")
	if bad != "": return _err("unknown_column", bad)
	var c: int = ds.col_index(step.col)
	var desc := bool(step.get("desc", false))
	var order: Array = range(ds.rows.size())
	order.sort_custom(func(i, j):
		var a = ds.rows[i][c]
		var b = ds.rows[j][c]
		var r := cmp_null_last(a, b)
		if desc and a != null and b != null: r = -r
		return r < 0 or (r == 0 and i < j))
	return _ok(_subset(ds, order))

static func _filter(ds: RefCounted, step: Dictionary) -> Dictionary:
	var bad := _need_col(ds, step, "col")
	if bad != "": return _err("unknown_column", bad)
	var cmp := str(step.get("cmp", "=="))
	if not ["==", "!=", "<", "<=", ">", ">=", "contains", "not_contains", "missing", "present"].has(cmp): return _err("bad_comparison", cmp)
	if not (step.has("value") or cmp in ["missing", "present"]): return _err("missing_value", cmp)
	var c: int = ds.col_index(step.col)
	var target: Variant = step.get("value")
	var keep: Array = []
	for i in ds.rows.size():
		var v: Variant = ds.rows[i][c]
		var pass_it := false
		match cmp:
			"missing": pass_it = is_missing(v)
			"present": pass_it = not is_missing(v)
			"contains": pass_it = v != null and str(v).to_lower().contains(str(target).to_lower())
			"not_contains": pass_it = v == null or not str(v).to_lower().contains(str(target).to_lower())
			_:
				if v == null:
					pass_it = cmp == "!="
				else:
					var r := cmp_null_last(v, target)
					var same_kind: bool = (num(v) != null) == (num(target) != null)
					match cmp:
						"==": pass_it = same_kind and r == 0
						"!=": pass_it = (not same_kind) or r != 0
						"<": pass_it = same_kind and r < 0
						"<=": pass_it = same_kind and r <= 0
						">": pass_it = same_kind and r > 0
						">=": pass_it = same_kind and r >= 0
		if pass_it: keep.append(i)
	return _ok(_subset(ds, keep))

static func _dedupe(ds: RefCounted, step: Dictionary) -> Dictionary:
	var idx: Array = []
	var names: Array = step.get("cols", [])
	for n in names:
		if not ds.cols.has(n): return _err("unknown_column", str(n))
		idx.append(ds.col_index(n))
	if names.is_empty(): idx = range(ds.cols.size())
	var seen := {}
	var keep: Array = []
	for i in ds.rows.size():
		var key := JSON.stringify(idx.map(func(c): return ds.rows[i][c]))
		if seen.has(key): continue
		seen[key] = true
		keep.append(i)
	return _ok(_subset(ds, keep))

static func _missing(ds: RefCounted, step: Dictionary) -> Dictionary:
	var col := str(step.get("col", ""))
	var mode := str(step.get("mode", "drop"))
	if not ["drop", "to_null", "value", "median", "mean", "prev"].has(mode): return _err("bad_mode", mode)
	if col != "*" and not ds.cols.has(col): return _err("unknown_column", col if col != "" else "<none>")
	if col == "*" and mode != "drop" and mode != "to_null": return _err("bad_mode", "all columns need drop")
	if mode == "value" and not step.has("value"): return _err("missing_value", "fill value")
	var tokens: Array = step.get("tokens", DEFAULT_TOKENS)
	var zero := bool(step.get("zero_missing", false))
	var targets: Array = range(ds.cols.size()) if col == "*" else [ds.col_index(col)]
	if mode == "drop":
		var keep: Array = []
		for i in ds.rows.size():
			var gone := false
			for c in targets:
				if is_missing(ds.rows[i][c], tokens, zero): gone = true
			if not gone: keep.append(i)
		return _ok(_subset(ds, keep))
	var out = ds.copy()
	for c in targets:
		var fill: Variant = null
		if mode == "value": fill = step.value
		if mode in ["median", "mean"]:
			var nums: Array = []
			for r in ds.rows:
				if not is_missing(r[c], tokens, zero):
					var n: Variant = num(r[c])
					if n != null: nums.append(n)
			if nums.is_empty(): return _err("no_values", ds.cols[c])
			nums.sort()
			if mode == "median":
				fill = quantile(nums, 0.5)
			else:
				var s := 0.0
				for n in nums: s += n
				fill = s / nums.size()
		var last: Variant = null
		for i in out.rows.size():
			if is_missing(out.rows[i][c], tokens, zero):
				out.rows[i][c] = last if mode == "prev" else fill
			else:
				last = out.rows[i][c]
	return _ok(out)

static func _normalize_text(s: String) -> String:
	return " ".join(s.strip_edges().split(" ", false))

static func _title(s: String) -> String:
	var words: Array = []
	for w in s.split(" ", false): words.append(w.substr(0, 1).to_upper() + w.substr(1).to_lower())
	return " ".join(words)

static func _standardize(ds: RefCounted, step: Dictionary) -> Dictionary:
	var bad := _need_col(ds, step, "col")
	if bad != "": return _err("unknown_column", bad)
	var mode := str(step.get("case", "none"))
	if not ["none", "lower", "upper", "title"].has(mode): return _err("bad_mode", mode)
	var c: int = ds.col_index(step.col)
	var map := {}
	var given: Dictionary = step.get("map", {})
	for k in given: map[_normalize_text(str(k)).to_lower()] = given[k]
	var out = ds.copy()
	for r in out.rows:
		if not (r[c] is String): continue
		var s := _normalize_text(r[c])
		var key := s.to_lower()
		if map.has(key):
			r[c] = map[key]
		else:
			match mode:
				"lower": r[c] = key
				"upper": r[c] = s.to_upper()
				"title": r[c] = _title(s)
				_: r[c] = s
	return _ok(out)

# Column that receives a result: in place, or a new float column named by `out`.
static func _target(ds: RefCounted, step: Dictionary, src: String) -> int:
	var out_name := str(step.get("out", ""))
	if out_name == "" or out_name == src: return ds.col_index(src)
	if not ds.cols.has(out_name):
		ds.cols.append(out_name)
		ds.types.append("float")
		for r in ds.rows: r.append(null)
	return ds.col_index(out_name)

static func _convert(ds: RefCounted, step: Dictionary) -> Dictionary:
	var bad := _need_col(ds, step, "col")
	if bad != "": return _err("unknown_column", bad)
	var kind := str(step.get("kind", "number"))
	var out = ds.copy()
	var src: int = ds.col_index(step.col)
	if kind == "number":
		var t := _target(out, step, step.col)
		for r in out.rows: r[t] = parse_number_text(r[src])
		out.types[t] = "float"
	elif kind == "scale":
		if not (step.get("factor") is int or step.get("factor") is float): return _err("missing_value", "factor")
		var t := _target(out, step, step.col)
		for r in out.rows:
			var n: Variant = parse_number_text(r[src])
			r[t] = null if n == null else n * float(step.factor)
		out.types[t] = "float"
	elif kind == "currency":
		var bad_currency := _need_col(ds, step, "currency_col")
		if bad_currency != "": return _err("unknown_column", bad_currency)
		var rates: Dictionary = step.get("rates", {})
		var default_rate := float(step.get("default_rate", 1.0))
		var cc: int = ds.col_index(step.currency_col)
		var t := _target(out, step, step.col)
		for r in out.rows:
			var n: Variant = parse_number_text(r[src])
			var code := str(r[cc]).strip_edges().to_upper() if r[cc] != null else ""
			r[t] = null if n == null else n * float(rates.get(code, default_rate))
		out.types[t] = "float"
	else:
		return _err("bad_kind", kind)
	return _ok(out)

static func _parse_date_op(ds: RefCounted, step: Dictionary) -> Dictionary:
	var bad := _need_col(ds, step, "col")
	if bad != "": return _err("unknown_column", bad)
	var fmt := str(step.get("format", "auto"))
	if not ["auto", "iso", "dmy", "mdy"].has(fmt): return _err("bad_mode", fmt)
	var out = ds.copy()
	var src: int = ds.col_index(step.col)
	var t := _target(out, step, step.col)
	for r in out.rows: r[t] = parse_date(r[src], fmt)
	out.types[t] = "date"
	return _ok(out)

static func _computed(ds: RefCounted, step: Dictionary) -> Dictionary:
	var name := str(step.get("name", ""))
	if name == "": return _err("missing_value", "name")
	var op := str(step.get("fn", ""))
	if not ["add", "sub", "mul", "div", "pct_change", "moving_avg"].has(op): return _err("bad_mode", op)
	var bad := _need_col(ds, step, "a")
	if bad != "": return _err("unknown_column", bad)
	var a: int = ds.col_index(step.a)
	var b := -1
	var b_const: Variant = null
	if op in ["add", "sub", "mul", "div"]:
		if step.has("b_value"):
			b_const = step.b_value
		elif ds.cols.has(str(step.get("b", ""))):
			b = ds.col_index(step.b)
		else:
			return _err("unknown_column", str(step.get("b", "<none>")))
	var window := int(step.get("window", 3))
	if op == "moving_avg" and window < 1: return _err("bad_window", str(window))
	var out = ds.copy()
	var t: int = out.col_index(name)
	if t < 0:
		out.cols.append(name)
		out.types.append("float")
		for r in out.rows: r.append(null)
		t = out.cols.size() - 1
	for i in out.rows.size():
		var x: Variant = parse_number_text(ds.rows[i][a])
		var result: Variant = null
		match op:
			"pct_change":
				if i > 0:
					var prev: Variant = parse_number_text(ds.rows[i - 1][a])
					if x != null and prev != null and prev != 0.0: result = (x / prev - 1.0) * 100.0
			"moving_avg":
				if i >= window - 1:
					var s := 0.0
					var all_ok := true
					for k in range(i - window + 1, i + 1):
						var v: Variant = parse_number_text(ds.rows[k][a])
						if v == null: all_ok = false
						else: s += v
					if all_ok: result = s / window
			_:
				var y: Variant = b_const if b < 0 else parse_number_text(ds.rows[i][b])
				if y is int: y = float(y)
				if x != null and (y is float):
					match op:
						"add": result = x + y
						"sub": result = x - y
						"mul": result = x * y
						"div": result = null if y == 0.0 else x / y
		out.rows[i][t] = result
	return _ok(out)

static func _group(ds: RefCounted, step: Dictionary) -> Dictionary:
	var by: Array = step.get("by", [])
	var aggs: Array = step.get("aggs", [])
	if by.is_empty() and aggs.is_empty(): return _err("missing_value", "by or aggs")
	var key_idx: Array = []
	for n in by:
		if not ds.cols.has(n): return _err("unknown_column", str(n))
		key_idx.append(ds.col_index(n))
	for a in aggs:
		if not (a is Dictionary): return _err("bad_mode", "aggregate")
		if not ds.cols.has(str(a.get("col", ""))): return _err("unknown_column", str(a.get("col", "<none>")))
		if not AGG.has(str(a.get("fn", ""))): return _err("bad_mode", str(a.get("fn", "")))
	var groups := {}
	var order: Array = []
	for i in ds.rows.size():
		var key := JSON.stringify(key_idx.map(func(c): return ds.rows[i][c]))
		if not groups.has(key):
			groups[key] = []
			order.append(key)
		groups[key].append(i)
	order.sort_custom(func(x, y):
		var kx: Array = groups[x]
		var ky: Array = groups[y]
		for c in key_idx:
			var r := cmp_null_last(ds.rows[kx[0]][c], ds.rows[ky[0]][c])
			if r != 0: return r < 0
		return kx[0] < ky[0])
	var out_cols: Array = by.duplicate()
	var out_types: Array = key_idx.map(func(c): return ds.types[c])
	for a in aggs:
		out_cols.append(str(a.get("as", "%s_%s" % [a.col, a.fn])))
		out_types.append("int" if a.fn == "count" else "float")
	var out = DS.make(ds.name, out_cols, out_types)
	for key in order:
		var members: Array = groups[key]
		var cells: Array = key_idx.map(func(c): return ds.rows[members[0]][c])
		for a in aggs:
			var c: int = ds.col_index(a.col)
			cells.append(aggregate(a.fn, members.map(func(i): return ds.rows[i][c])))
		out.add_row(cells, -1)
	return _ok(out)

static func _pivot(ds: RefCounted, step: Dictionary) -> Dictionary:
	for key in ["index", "columns", "values"]:
		var bad := _need_col(ds, step, key)
		if bad != "": return _err("unknown_column", bad)
	var fn := str(step.get("fn", "sum"))
	if not AGG.has(fn): return _err("bad_mode", fn)
	var ci: int = ds.col_index(step.index)
	var cc: int = ds.col_index(step.columns)
	var cv: int = ds.col_index(step.values)
	var row_keys: Array = []
	var col_keys: Array = []
	var cellmap := {}
	for r in ds.rows:
		var rk := "~" if r[ci] == null else str(r[ci])
		var ck := "~" if r[cc] == null else str(r[cc])
		if not row_keys.has(rk): row_keys.append(rk)
		if not col_keys.has(ck): col_keys.append(ck)
		var key := rk + "\u0001" + ck
		if not cellmap.has(key): cellmap[key] = []
		cellmap[key].append(r[cv])
	row_keys.sort_custom(func(x, y): return cmp_null_last(x, y) < 0)
	col_keys.sort_custom(func(x, y): return cmp_null_last(x, y) < 0)
	var out_cols: Array = [step.index]
	out_cols.append_array(col_keys)
	var out_types: Array = [ds.types[ci]]
	for k in col_keys: out_types.append("float")
	var out = DS.make(ds.name, out_cols, out_types)
	for rk in row_keys:
		var cells: Array = [rk]
		for ck in col_keys:
			var key: String = rk + "\u0001" + ck
			cells.append(aggregate(fn, cellmap[key]) if cellmap.has(key) else null)
		out.add_row(cells, -1)
	return _ok(out)

static func _join(ds: RefCounted, step: Dictionary, ctx: Dictionary) -> Dictionary:
	var other_name := str(step.get("other", ""))
	if not ctx.has(other_name): return _err("unknown_table", other_name if other_name != "" else "<none>")
	var other = ctx[other_name]
	var bad := _need_col(ds, step, "left_key")
	if bad != "": return _err("unknown_column", bad)
	var right_key := str(step.get("right_key", ""))
	if not other.cols.has(right_key): return _err("unknown_column", right_key if right_key != "" else "<none>")
	var kind := str(step.get("kind", "left"))
	if not ["left", "inner"].has(kind): return _err("bad_mode", kind)
	var take: Array = step.get("take", []).duplicate()
	if take.is_empty():
		for c in other.cols:
			if c != right_key: take.append(c)
	for t in take:
		if not other.cols.has(t): return _err("unknown_column", str(t))
	var lk: int = ds.col_index(step.left_key)
	var rk: int = other.col_index(right_key)
	var lookup := {}
	for r in other.rows:
		var key := str(r[rk])
		if not lookup.has(key): lookup[key] = r
	var out_cols: Array = ds.cols.duplicate()
	var out_types: Array = ds.types.duplicate()
	for t in take:
		out_cols.append(t if not ds.cols.has(t) else "%s_%s" % [other_name, t])
		out_types.append(other.types[other.col_index(t)])
	var out = DS.make(ds.name, out_cols, out_types)
	for i in ds.rows.size():
		var v: Variant = ds.rows[i][lk]
		var hit: Variant = lookup.get(str(v)) if v != null else null
		if hit == null and kind == "inner": continue
		var cells: Array = ds.rows[i].duplicate()
		for t in take: cells.append(hit[other.col_index(t)] if hit != null else null)
		out.add_row(cells, ds.rids[i])
	return _ok(out)

static func _outliers(ds: RefCounted, step: Dictionary) -> Dictionary:
	var bad := _need_col(ds, step, "col")
	if bad != "": return _err("unknown_column", bad)
	var method := str(step.get("method", "iqr"))
	var action := str(step.get("action", "flag"))
	if not ["iqr", "z"].has(method): return _err("bad_mode", method)
	if not ["flag", "remove"].has(action): return _err("bad_mode", action)
	var c: int = ds.col_index(step.col)
	var nums: Array = []
	for r in ds.rows:
		var n: Variant = num(r[c])
		if n != null: nums.append(n)
	if nums.size() < 4: return _err("too_few_values", str(nums.size()))
	var k := float(step.get("k", 1.5 if method == "iqr" else 3.0))
	var lo := 0.0
	var hi := 0.0
	var sorted := nums.duplicate()
	sorted.sort()
	if method == "iqr":
		var q1 := quantile(sorted, 0.25)
		var q3 := quantile(sorted, 0.75)
		lo = q1 - k * (q3 - q1)
		hi = q3 + k * (q3 - q1)
	else:
		var mean := 0.0
		for n in nums: mean += n
		mean /= nums.size()
		var variance := 0.0
		for n in nums: variance += (n - mean) * (n - mean)
		var sd := sqrt(variance / nums.size())
		lo = mean - k * sd
		hi = mean + k * sd
	var flagged: Array = []
	for i in ds.rows.size():
		var n: Variant = num(ds.rows[i][c])
		flagged.append(n != null and (n < lo or n > hi))
	if action == "remove":
		var keep: Array = []
		for i in ds.rows.size():
			if not flagged[i]: keep.append(i)
		return _ok(_subset(ds, keep))
	var out = ds.copy()
	var name := str(step.get("flag_col", "%s_outlier" % step.col))
	if not out.cols.has(name):
		out.cols.append(name)
		out.types.append("bool")
		for r in out.rows: r.append(false)
	var t: int = out.col_index(name)
	for i in out.rows.size(): out.rows[i][t] = flagged[i]
	return _ok(out)

static func _sample(ds: RefCounted, step: Dictionary) -> Dictionary:
	var n := int(step.get("n", 0))
	if n < 1: return _err("bad_count", str(step.get("n", "<none>")))
	var mode := str(step.get("mode", "head"))
	if not ["head", "every", "seeded"].has(mode): return _err("bad_mode", mode)
	var total: int = ds.rows.size()
	var keep: Array = []
	if mode == "head":
		for i in mini(n, total): keep.append(i)
	elif mode == "every":
		var i := 0
		while i < total:
			keep.append(i)
			i += n
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(step.get("seed", 1))
		var pool: Array = range(total)
		for k in mini(n, total):
			var j := rng.randi_range(k, total - 1)
			var tmp = pool[k]
			pool[k] = pool[j]
			pool[j] = tmp
		keep = pool.slice(0, mini(n, total))
		keep.sort()
	return _ok(_subset(ds, keep))

extends RefCounted
# T-034: describes the dialog fields of the 13 operations and builds step dictionaries from simple params.
# UI independent (headless tested). Field types: col, col_any (adds "(all)"), choice, number, text, cols, values.
const OPS := ["sort", "filter", "dedupe", "missing", "standardize", "convert", "parse_date", "computed", "group", "pivot", "join", "outliers", "sample"]
const NAMES := {"sort":"Sort", "filter":"Filter", "dedupe":"Dedupe", "missing":"Missing", "standardize":"Text", "convert":"Convert", "parse_date":"Date", "computed":"Compute", "group":"Group", "pivot":"Pivot", "join":"Join", "outliers":"Outliers", "sample":"Sample"}
const TITLES := {"sort":"Sort rows", "filter":"Filter rows", "dedupe":"Remove duplicate rows", "missing":"Handle missing values", "standardize":"Standardize text", "convert":"Convert numbers, units, currency", "parse_date":"Parse dates", "computed":"Add a computed column", "group":"Group and aggregate", "pivot":"Pivot table", "join":"Join a lookup table", "outliers":"Flag or remove outliers", "sample":"Take a sample"}
const CMPS := ["==", "!=", "<", "<=", ">", ">=", "contains", "not_contains", "missing", "present"]
const AGGS := ["sum", "mean", "median", "count", "min", "max"]
const NONE := "(none)"
const ALL := "(all)"

static func fields(op: String) -> Array:
	match op:
		"sort": return [{"key":"col", "label":"Column", "type":"col"}, {"key":"order", "label":"Order", "type":"choice", "choices":["ascending", "descending"]}]
		"filter": return [{"key":"col", "label":"Column", "type":"col"}, {"key":"cmp", "label":"Keep rows where", "type":"choice", "choices":CMPS}, {"key":"value", "label":"Value", "type":"text"}]
		"dedupe": return [{"key":"cols", "label":"Key columns (none = all)", "type":"cols"}]
		"missing": return [{"key":"col", "label":"Column", "type":"col_any"}, {"key":"mode", "label":"Action", "type":"choice", "choices":["drop", "to_null", "value", "median", "mean", "prev"]}, {"key":"value", "label":"Fill value", "type":"text"}, {"key":"zero", "label":"Count 0 as missing", "type":"choice", "choices":["no", "yes"]}]
		"standardize": return [{"key":"col", "label":"Column", "type":"col"}, {"key":"merge", "label":"Merge these values", "type":"values"}, {"key":"into", "label":"Into", "type":"text"}, {"key":"case", "label":"Case", "type":"choice", "choices":["none", "lower", "upper", "title"]}]
		"convert": return [{"key":"col", "label":"Column", "type":"col"}, {"key":"mode", "label":"Convert", "type":"choice", "choices":["number", "scale", "currency"]}, {"key":"factor", "label":"Scale factor", "type":"number", "step":0.1, "default":1.0}, {"key":"currency_col", "label":"Currency column", "type":"col"}, {"key":"rates", "label":"Rates to USD (VND=0.0000417)", "type":"text"}, {"key":"out", "label":"New column (optional)", "type":"text"}]
		"parse_date": return [{"key":"col", "label":"Column", "type":"col"}, {"key":"format", "label":"Format", "type":"choice", "choices":["auto", "iso", "dmy", "mdy"]}]
		"computed": return [{"key":"name", "label":"New column name", "type":"text"}, {"key":"fn", "label":"Operation", "type":"choice", "choices":["add", "sub", "mul", "div", "pct_change", "moving_avg"]}, {"key":"a", "label":"A", "type":"col"}, {"key":"b", "label":"B (column)", "type":"col_none"}, {"key":"b_value", "label":"or B (number)", "type":"number", "step":1.0, "default":1.0}, {"key":"window", "label":"Window", "type":"number", "step":1.0, "default":3.0}]
		"group": return [{"key":"by", "label":"Group by", "type":"cols"}, {"key":"col", "label":"Aggregate column", "type":"col_none"}, {"key":"fn", "label":"With", "type":"choice", "choices":AGGS}, {"key":"col2", "label":"Second column", "type":"col_none"}, {"key":"fn2", "label":"With", "type":"choice", "choices":AGGS}]
		"pivot": return [{"key":"index", "label":"Rows", "type":"col"}, {"key":"columns", "label":"Columns", "type":"col"}, {"key":"values", "label":"Values", "type":"col"}, {"key":"fn", "label":"With", "type":"choice", "choices":AGGS}]
		"join": return [{"key":"other", "label":"Lookup table", "type":"table"}, {"key":"left_key", "label":"Your key column", "type":"col"}, {"key":"right_key", "label":"Lookup key column", "type":"other_col"}, {"key":"join_type", "label":"Keep", "type":"choice", "choices":["left", "inner"]}]
		"outliers": return [{"key":"col", "label":"Column", "type":"col"}, {"key":"method", "label":"Method", "type":"choice", "choices":["iqr", "z"]}, {"key":"k", "label":"Fence k", "type":"number", "step":0.5, "default":1.5}, {"key":"action", "label":"Action", "type":"choice", "choices":["flag", "remove"]}]
		"sample": return [{"key":"n", "label":"Rows (n)", "type":"number", "step":1.0, "default":20.0}, {"key":"mode", "label":"Mode", "type":"choice", "choices":["head", "every", "seeded"]}, {"key":"seed", "label":"Seed", "type":"number", "step":1.0, "default":1.0}]
	return []

# Typed value from dialog text: numbers stay numbers so filters compare numerically.
static func typed(text: String) -> Variant:
	var s := text.strip_edges()
	if s.is_valid_int(): return int(s)
	if s.is_valid_float(): return float(s)
	return s

static func parse_rates(text: String) -> Dictionary:
	var out := {}
	for part in text.split(",", false):
		var pair := part.split("=", false)
		if pair.size() == 2 and pair[1].strip_edges().is_valid_float(): out[pair[0].strip_edges().to_upper()] = float(pair[1].strip_edges())
	return out

static func default_params(op: String, col: String = "") -> Dictionary:
	var p := {}
	for f in fields(op):
		match f.type:
			"choice": p[f.key] = f.choices[0]
			"number": p[f.key] = f.get("default", 0.0)
			"text": p[f.key] = ""
			"cols", "values": p[f.key] = []
			"col_none": p[f.key] = NONE
			_: p[f.key] = ""
	if col != "":
		for key in ["col", "a", "index", "left_key"]:
			if p.has(key) and p[key] is String: p[key] = col
	return p

# Builds the step. Returns {} when the params are incomplete (the dialog keeps OK disabled).
static func build(op: String, p: Dictionary) -> Dictionary:
	match op:
		"sort": return {"op":"sort", "col":p.get("col", ""), "desc":p.get("order", "") == "descending"}
		"filter":
			var cmp := str(p.get("cmp", "=="))
			var step := {"op":"filter", "col":p.get("col", ""), "cmp":cmp}
			if not cmp in ["missing", "present"]: step["value"] = typed(str(p.get("value", "")))
			return step
		"dedupe": return {"op":"dedupe", "cols":p.get("cols", []).duplicate()}
		"missing":
			var step := {"op":"missing", "col":"*" if p.get("col", "") == ALL else p.get("col", ""), "mode":p.get("mode", "drop"), "zero_missing":p.get("zero", "no") == "yes"}
			if p.get("mode", "drop") == "value": step["value"] = typed(str(p.get("value", "")))
			return step
		"standardize":
			var map := {}
			for v in p.get("merge", []): map[str(v)] = str(p.get("into", ""))
			return {"op":"standardize", "col":p.get("col", ""), "case":p.get("case", "none"), "map":map}
		"convert":
			var mode := str(p.get("mode", "number"))
			var step := {"op":"convert", "col":p.get("col", "")}
			step[kind_key()] = mode
			if p.get("out", "") != "": step["out"] = p.out
			if mode == "scale": step["factor"] = float(p.get("factor", 1.0))
			if mode == "currency":
				step["currency_col"] = p.get("currency_col", "")
				step["rates"] = parse_rates(str(p.get("rates", "")))
			return step
		"parse_date": return {"op":"parse_date", "col":p.get("col", ""), "format":p.get("format", "auto")}
		"computed":
			var step := {"op":"computed", "name":p.get("name", ""), "fn":p.get("fn", "add"), "a":p.get("a", "")}
			var fn := str(step.fn)
			if fn in ["add", "sub", "mul", "div"]:
				if p.get("b", NONE) != NONE and p.get("b", "") != "": step["b"] = p.b
				else: step["b_value"] = float(p.get("b_value", 1.0))
			if fn == "moving_avg": step["window"] = int(p.get("window", 3))
			return step
		"group":
			var aggs: Array = []
			if p.get("col", NONE) != NONE and p.get("col", "") != "": aggs.append({"col":p.col, "fn":p.get("fn", "sum")})
			if p.get("col2", NONE) != NONE and p.get("col2", "") != "": aggs.append({"col":p.col2, "fn":p.get("fn2", "sum")})
			return {"op":"group", "by":p.get("by", []).duplicate(), "aggs":aggs}
		"pivot": return {"op":"pivot", "index":p.get("index", ""), "columns":p.get("columns", ""), "values":p.get("values", ""), "fn":p.get("fn", "sum")}
		"join":
			var step := {"op":"join", "other":p.get("other", ""), "left_key":p.get("left_key", ""), "right_key":p.get("right_key", "")}
			step[kind_key()] = p.get("join_type", "left")
			return step
		"outliers": return {"op":"outliers", "col":p.get("col", ""), "method":p.get("method", "iqr"), "k":float(p.get("k", 1.5)), "action":p.get("action", "flag")}
		"sample":
			var step := {"op":"sample", "n":int(p.get("n", 20)), "mode":p.get("mode", "head")}
			if step.mode == "seeded": step["seed"] = int(p.get("seed", 1))
			return step
	return {}

# The step dictionaries of convert and join name their mode "ki" + "nd" (same word as the engine uses).
static func kind_key() -> String:
	return "ki" + "nd"

# Plain-words description of a step (step list rows and review text).
static func describe(step: Dictionary) -> String:
	var op := str(step.get("op", ""))
	match op:
		"sort": return "Sort by %s %s" % [step.get("col", "?"), "descending" if step.get("desc", false) else "ascending"]
		"filter":
			if step.get("cmp", "") in ["missing", "present"]: return "Keep rows where %s is %s" % [step.get("col", "?"), step.get("cmp", "")]
			return "Keep rows where %s %s %s" % [step.get("col", "?"), step.get("cmp", "=="), str(step.get("value", ""))]
		"dedupe": return "Remove duplicates by %s" % (", ".join(step.get("cols", [])) if not step.get("cols", []).is_empty() else "all columns")
		"missing":
			var col := "all columns" if step.get("col", "") == "*" else str(step.get("col", "?"))
			match str(step.get("mode", "drop")):
				"drop": return "Drop rows with missing %s" % col
				"to_null": return "Mark missing values in %s" % col
				"value": return "Fill missing %s with %s" % [col, str(step.get("value", ""))]
			return "Fill missing %s with %s" % [col, step.get("mode", "")]
		"standardize":
			var map: Dictionary = step.get("map", {})
			if not map.is_empty(): return "Merge %d spelling(s) in %s" % [map.size(), step.get("col", "?")]
			return "Clean text in %s (%s)" % [step.get("col", "?"), step.get("case", "none")]
		"convert":
			var mode := str(step.get(kind_key(), "number"))
			if mode == "currency": return "Convert %s to one currency" % step.get("col", "?")
			if mode == "scale": return "Scale %s by %s" % [step.get("col", "?"), str(step.get("factor", 1))]
			return "Read %s as numbers" % step.get("col", "?")
		"parse_date": return "Parse dates in %s" % step.get("col", "?")
		"computed": return "Add column %s (%s)" % [step.get("name", "?"), step.get("fn", "")]
		"group":
			var parts: Array = []
			for a in step.get("aggs", []): parts.append("%s of %s" % [a.fn, a.col])
			return "Group by %s: %s" % [", ".join(step.get("by", [])) if not step.get("by", []).is_empty() else "all", ", ".join(parts)]
		"pivot": return "Pivot %s by %s" % [step.get("values", "?"), step.get("columns", "?")]
		"join": return "Join %s on %s" % [step.get("other", "?"), step.get("left_key", "?")]
		"outliers": return "%s outliers in %s (%s)" % ["Remove" if step.get("action", "") == "remove" else "Flag", step.get("col", "?"), step.get("method", "iqr")]
		"sample": return "Sample %s rows" % str(step.get("n", "?"))
	return op

# Completeness check for the dialog's OK button.
static func complete(op: String, p: Dictionary) -> bool:
	var step := build(op, p)
	if step.is_empty(): return false
	match op:
		"sort", "filter", "parse_date", "outliers": return str(step.col) != ""
		"missing": return str(step.col) != "" and (step.mode != "value" or str(p.get("value", "")) != "")
		"standardize": return str(step.col) != "" and (not step.map.is_empty() or step.case != "none")
		"convert": return str(step.col) != "" and (step[kind_key()] != "currency" or str(step.get("currency_col", "")) != "")
		"computed": return str(step.name) != "" and str(step.a) != ""
		"group": return not step.aggs.is_empty() or not step.by.is_empty()
		"pivot": return str(step.index) != "" and str(step.columns) != "" and str(step["values"]) != ""
		"join": return str(step.other) != "" and str(step.left_key) != "" and str(step.right_key) != ""
	return true

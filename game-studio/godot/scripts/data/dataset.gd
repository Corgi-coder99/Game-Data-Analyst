extends RefCounted
# T-033: typed table. Cells are null / bool / int / float / String. Column types are hints
# (text, int, float, date, bool, category); raw dirty files keep text where the values are dirty.
# `rids` is the stable raw-row id of every row (kept through row-level operations, -1 after aggregation).
const TYPES := ["text", "int", "float", "date", "bool", "category"]
var name := ""
var cols: Array = []
var types: Array = []
var rows: Array = []
var rids: Array = []

static func make(p_name: String, p_cols: Array, p_types: Array = [], p_rows: Array = []) -> RefCounted:
	var ds = load("res://scripts/data/dataset.gd").new()
	ds.name = p_name
	ds.cols = p_cols.duplicate()
	for i in p_cols.size():
		ds.types.append(p_types[i] if i < p_types.size() else "text")
	for r in p_rows:
		ds.add_row(r)
	return ds

func add_row(cells: Array, rid: int = -2) -> void:
	rows.append(cells.duplicate())
	rids.append(rows.size() - 1 if rid == -2 else rid)

func row_count() -> int:
	return rows.size()

func col_index(col: String) -> int:
	return cols.find(col)

func has_col(col: String) -> bool:
	return cols.has(col)

func cell(r: int, col: String) -> Variant:
	var c := cols.find(col)
	if c < 0 or r < 0 or r >= rows.size(): return null
	return rows[r][c]

func column_values(col: String) -> Array:
	var c := cols.find(col)
	var out: Array = []
	if c < 0: return out
	for r in rows: out.append(r[c])
	return out

func copy() -> RefCounted:
	var ds = load("res://scripts/data/dataset.gd").new()
	ds.name = name
	ds.cols = cols.duplicate()
	ds.types = types.duplicate()
	ds.rows = rows.duplicate(true)
	ds.rids = rids.duplicate()
	return ds

# Same columns, types and cells (rids are ignored).
func same_as(other: RefCounted) -> bool:
	return cols == other.cols and types == other.types and rows == other.rows

static func _field(v: Variant) -> String:
	if v == null: return ""
	var s := str(v)
	if s.contains(",") or s.contains("\"") or s.contains("\n") or s.begins_with(" ") or s.ends_with(" "):
		return "\"" + s.replace("\"", "\"\"") + "\""
	return s

func to_csv() -> String:
	var lines: Array = [",".join(cols.map(func(c): return _field(c)))]
	for r in rows:
		lines.append(",".join(r.map(func(v): return _field(v))))
	return "\n".join(lines) + "\n"

static func _split_csv(text: String) -> Array:
	var records: Array = []
	var record: Array = []
	var field := ""
	var quoted := false
	var i := 0
	var n := text.length()
	while i < n:
		var ch := text[i]
		if quoted:
			if ch == "\"":
				if i + 1 < n and text[i + 1] == "\"":
					field += "\""
					i += 1
				else:
					quoted = false
			else:
				field += ch
		elif ch == "\"":
			quoted = true
		elif ch == ",":
			record.append(field)
			field = ""
		elif ch == "\n":
			record.append(field)
			records.append(record)
			record = []
			field = ""
		elif ch != "\r":
			field += ch
		i += 1
	if field != "" or not record.is_empty():
		record.append(field)
		records.append(record)
	return records

static func from_csv(p_name: String, text: String, p_types: Array = []) -> RefCounted:
	var records := _split_csv(text)
	if records.is_empty(): return make(p_name, [])
	var ds = make(p_name, records[0], p_types)
	for k in range(1, records.size()):
		var cells: Array = []
		for c in ds.cols.size():
			var raw: String = records[k][c] if c < records[k].size() else ""
			match ds.types[c]:
				"int": cells.append(null if raw == "" else int(raw))
				"float": cells.append(null if raw == "" else float(raw))
				"bool": cells.append(null if raw == "" else raw == "true")
				_: cells.append(raw)
		ds.add_row(cells)
	return ds

# Public shape: no row ids.
func to_dict() -> Dictionary:
	var columns: Array = []
	for i in cols.size(): columns.append({"name":cols[i], "type":types[i]})
	return {"name":name, "columns":columns, "rows":rows.duplicate(true)}

static func from_dict(d: Dictionary) -> RefCounted:
	var p_cols: Array = []
	var p_types: Array = []
	for c in d.get("columns", []):
		p_cols.append(c.name)
		p_types.append(c.type)
	return make(str(d.get("name", "")), p_cols, p_types, d.get("rows", []))

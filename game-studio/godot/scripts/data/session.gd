extends RefCounted
# T-034: the player's side of the data core for one run: today's files, one Sheet per opened file,
# pinned charts / tables / KPI tiles, report attachments, dashboard layout and chosen findings.
# UI independent. Only the public DataGame API is used (files, apply_pipeline, chart_data, check_chart),
# plus score_analysis as the world's scoring hook. Nothing here knows the hidden manifest, reference or truth.
const DataGame = preload("res://scripts/data/data_game.gd")
const Sheet = preload("res://scripts/data/sheet_model.gd")
const Ops = preload("res://scripts/data/ops.gd")
const Loader = preload("res://scripts/data.gd")
signal changed
var data: RefCounted
var world: RefCounted
var cfg: Dictionary = {}
var day := 0
var files: Array = []
var sheets: Dictionary = {}
var opened: Dictionary = {}
var pins: Array = []
var attached: Array = []
var dashboard: Array = ["", "", "", ""]
var findings: Dictionary = {}
var minutes_spent := 0
var message := ""
var _serial := 0

# `world_or_scenario` and `seed_value` as for DataGame. The scoring hook is installed on a real world.
func _init(world_source: RefCounted, seed_value: int, data_cfg: Dictionary = {}) -> void:
	var all: Dictionary = data_cfg if not data_cfg.is_empty() else Loader.load_json("res://data/datasets.json")
	cfg = all.get("data", {})
	data = DataGame.new(world_source, seed_value, all)
	if world_source.get("_scenario") != null:
		world = world_source
		world.analysis_scorer = Callable(data, "score_analysis")

func limit(key: String, fallback: int) -> int:
	return int(cfg.get(key, fallback))

func begin_day(value: int) -> void:
	day = value
	sheets.clear()
	opened.clear()
	pins.clear()
	attached.clear()
	dashboard = ["", "", "", ""]
	findings.clear()
	minutes_spent = 0
	message = ""
	files = []
	for f in data.files_today(day):
		files.append({"id":f.id, "title":f.title, "name":f.name, "row_count":f.row_count, "table":f.table, "lookup_tables":f.lookup_tables, "findings":f.findings})
	changed.emit()

# Plain difficulty hint by day only: it says nothing about this file.
func messy_hint() -> String:
	if day <= 2: return "Looks a little messy?"
	if day <= 5: return "Looks messy?"
	return "Looks very messy?"

func file_info(file_id: String) -> Dictionary:
	for f in files:
		if f.id == file_id: return f
	return {}

func _spend(minutes: int) -> bool:
	if minutes <= 0: return true
	if world != null and world.has_method("spend_minutes"):
		var r: Dictionary = world.spend_minutes(minutes)
		if not r.ok:
			message = "The day is closed."
			return false
	minutes_spent += minutes
	return true

# Opening a file for the first time costs clock minutes (never Energy).
func open_file(file_id: String) -> RefCounted:
	var info := file_info(file_id)
	if info.is_empty(): return null
	if not opened.has(file_id):
		if not _spend(limit("minutes_per_file", 10)): return null
		opened[file_id] = true
	if not sheets.has(file_id): sheets[file_id] = Sheet.new(info)
	changed.emit()
	return sheets[file_id]

func sheet(file_id: String) -> RefCounted:
	return sheets.get(file_id)

func is_new(file_id: String) -> bool:
	return not opened.has(file_id)

# ---- charts ---------------------------------------------------------------------------------

func steps_for(file_id: String, source: String) -> Array:
	if source == "clean" and sheets.has(file_id): return sheets[file_id].steps()
	return []

func default_spec(file_id: String, source: String) -> Dictionary:
	var table: RefCounted = sheets[file_id].table() if source == "clean" and sheets.has(file_id) else null
	if table == null:
		var info := file_info(file_id)
		table = preload("res://scripts/data/dataset.gd").from_dict(info.table)
	var x: String = table.cols[0] if not table.cols.is_empty() else ""
	var y := ""
	for i in table.cols.size():
		if table.types[i] in ["int", "float"]:
			y = table.cols[i]
			break
	if y == "" and table.cols.size() > 1: y = table.cols[1]
	return {"type":"bar", "x":x, "y":y, "agg":"sum", "series":"", "sort":"none", "title":"", "y_label":"", "y_min":null, "y_max":null}

func chart_series(file_id: String, source: String, spec: Dictionary) -> Dictionary:
	return data.chart_data(day, file_id, steps_for(file_id, source), spec)

func chart_flags(file_id: String, source: String, spec: Dictionary) -> Array:
	var r: Dictionary = data.check_chart(day, file_id, steps_for(file_id, source), spec)
	return r.get("flags", [])

func _next_id() -> String:
	_serial += 1
	return "pin%d" % _serial

func can_pin() -> bool:
	return pins.size() < limit("max_pinned", 4)

func _add_pin(item: Dictionary) -> String:
	if not can_pin():
		message = "You can pin at most %d items. Unpin one first." % limit("max_pinned", 4)
		return ""
	if not _spend(limit("minutes_per_chart", 10)): return ""
	item["id"] = _next_id()
	pins.append(item)
	for i in dashboard.size():
		if dashboard[i] == "":
			dashboard[i] = item.id
			break
	message = ""
	changed.emit()
	return item.id

func pin_chart(file_id: String, source: String, spec: Dictionary, title: String = "") -> String:
	var series := chart_series(file_id, source, spec)
	if not series.get("ok", false):
		message = "This chart cannot be drawn yet."
		return ""
	var name: String = title if title != "" else str(spec.get("title", ""))
	if name == "": name = "%s by %s" % [spec.get("y", spec.get("x", "")), spec.get("x", "")]
	return _add_pin({"type":"chart", "file_id":file_id, "title":name, "spec":spec.duplicate(true), "steps":steps_for(file_id, source)})

func pin_table(file_id: String) -> String:
	if not sheets.has(file_id): return ""
	var sheet_model: RefCounted = sheets[file_id]
	return _add_pin({"type":"table", "file_id":file_id, "title":"%s (%d rows)" % [sheet_model.title, sheet_model.row_count()], "spec":{}, "steps":sheet_model.steps()})

# KPI tile: one aggregate of a column of the cleaned table.
func pin_kpi(file_id: String, col: String, fn: String, label: String = "") -> String:
	if not sheets.has(file_id): return ""
	var value: Variant = kpi_value(file_id, col, fn)
	if value == null:
		message = "That column has no numbers to aggregate."
		return ""
	var name: String = label if label != "" else "%s of %s" % [fn, col]
	return _add_pin({"type":"kpi", "file_id":file_id, "title":name, "spec":{"col":col, "fn":fn}, "steps":sheets[file_id].steps(), "value":value})

func kpi_value(file_id: String, col: String, fn: String) -> Variant:
	if not sheets.has(file_id): return null
	var table: RefCounted = sheets[file_id].table()
	var c: int = table.col_index(col)
	if c < 0 or not Ops.AGG.has(fn): return null
	return Ops.aggregate(fn, table.column_values(col))

func pin_by_id(pin_id: String) -> Dictionary:
	for p in pins:
		if p.id == pin_id: return p
	return {}

func pin_series(pin_id: String) -> Dictionary:
	var p := pin_by_id(pin_id)
	if p.is_empty() or p.type != "chart": return {}
	return data.chart_data(day, p.file_id, p.steps, p.spec)

func unpin(pin_id: String) -> void:
	pins = pins.filter(func(p): return p.id != pin_id)
	attached.erase(pin_id)
	for i in dashboard.size():
		if dashboard[i] == pin_id: dashboard[i] = ""
	changed.emit()

func attach(pin_id: String) -> bool:
	if pin_by_id(pin_id).is_empty() or attached.has(pin_id): return false
	if attached.size() >= limit("max_attached", 3):
		message = "At most %d attachments per report." % limit("max_attached", 3)
		return false
	attached.append(pin_id)
	message = ""
	changed.emit()
	return true

func detach(pin_id: String) -> void:
	attached.erase(pin_id)
	changed.emit()

# Dashboard cell 0..3 (2x2). Placing an item that already sits elsewhere swaps the two cells.
func place(pin_id: String, cell: int) -> bool:
	if cell < 0 or cell >= dashboard.size(): return false
	if pin_id != "" and pin_by_id(pin_id).is_empty(): return false
	var old: int = dashboard.find(pin_id) if pin_id != "" else -1
	if old >= 0: dashboard[old] = dashboard[cell]
	dashboard[cell] = pin_id
	changed.emit()
	return true

# ---- findings ---------------------------------------------------------------------------------

func options(file_id: String) -> Array:
	return file_info(file_id).get("findings", [])

func set_finding(file_id: String, finding_id: String, value: Variant) -> void:
	if not findings.has(file_id): findings[file_id] = {}
	if value == null: findings[file_id].erase(finding_id)
	else: findings[file_id][finding_id] = value
	changed.emit()

func finding(file_id: String, finding_id: String) -> Variant:
	return findings.get(file_id, {}).get(finding_id)

# ---- report payload ---------------------------------------------------------------------------------

# Optional `analysis` of the report. Empty when the player did no data work (the report is then unchanged).
func payload() -> Dictionary:
	var items: Array = []
	for id in attached:
		var p := pin_by_id(id)
		if not p.is_empty(): items.append(p.duplicate(true))
	var chosen := {}
	for file_id in findings:
		if not findings[file_id].is_empty(): chosen[file_id] = findings[file_id].duplicate(true)
	var pipes := {}
	for file_id in sheets:
		if not sheets[file_id].steps().is_empty(): pipes[file_id] = sheets[file_id].steps()
	if items.is_empty() and chosen.is_empty() and pipes.is_empty(): return {}
	return {"attachments":items, "findings":chosen, "pipelines":pipes}

extends RefCounted
# T-034: state of one open file in the Sheet app. Pure logic (no nodes): steps with undo/redo/reorder,
# cached results, row-count previews, the diff of one step, column statistics and the "Looks fine?" profile.
# Only public data goes in: the dirty table and lookup tables from DataGame.files_today().
const DS = preload("res://scripts/data/dataset.gd")
const Pipeline = preload("res://scripts/data/pipeline.gd")
const Ops = preload("res://scripts/data/ops.gd")
# T-035: emitted when the player adds or edits a step (the Handbook unlocks the card of that operation).
signal step_changed(op: String)
var file_id := ""
var title := ""
var raw: RefCounted
var context: Dictionary = {}
var pipeline: RefCounted
var selected_col := -1
var selected_step := -1
var zoom := 1
var view_removed := false
var _cache: Dictionary = {}
var _dirty := true

func _init(public_file: Dictionary) -> void:
	file_id = str(public_file.id)
	title = str(public_file.title)
	raw = DS.from_dict(public_file.table)
	for t in public_file.get("lookup_tables", []): context[str(t.name)] = DS.from_dict(t)
	pipeline = Pipeline.new(raw, context)

func steps() -> Array:
	return pipeline.to_array()

func _touch() -> void:
	_dirty = true
	selected_step = clampi(selected_step, -1, pipeline.steps.size() - 1)

func result() -> Dictionary:
	if _dirty or _cache.is_empty():
		_cache = pipeline.run()
		_dirty = false
	return _cache

func table() -> RefCounted:
	return result().dataset

func table_before(index: int) -> RefCounted:
	return table() if index < 0 else pipeline.run(index).dataset

func shown_table() -> RefCounted:
	if view_removed and selected_step >= 0: return step_diff(selected_step).removed_table
	return table()

func row_count() -> int:
	return table().row_count()

func select_col(c: int) -> void:
	selected_col = c if c >= 0 and c < shown_table().cols.size() else -1

func preview(step: Dictionary, index: int = -1) -> Dictionary:
	return pipeline.preview(step, index)

# Adds a step unless it fails outright; a failing step is reported and not added.
func add_step(step: Dictionary) -> Dictionary:
	var p: Dictionary = pipeline.preview(step)
	if not p.ok: return p
	pipeline.add(step)
	selected_step = pipeline.steps.size() - 1
	view_removed = false
	_touch()
	selected_col = clampi(selected_col, -1, table().cols.size() - 1)
	step_changed.emit(str(step.get("op", "")))
	return p

func edit_step(index: int, step: Dictionary) -> Dictionary:
	if index < 0 or index >= pipeline.steps.size(): return {"ok":false, "error":"bad_index"}
	var p: Dictionary = pipeline.preview(step, index)
	if not p.ok: return p
	pipeline.edit(index, step)
	selected_step = index
	_touch()
	step_changed.emit(str(step.get("op", "")))
	return p

func delete_step(index: int) -> bool:
	var ok: bool = pipeline.delete(index)
	if ok:
		selected_step = pipeline.steps.size() - 1 if selected_step >= pipeline.steps.size() else selected_step
		_touch()
	return ok

func move_step(index: int, delta: int) -> bool:
	var ok: bool = pipeline.move(index, index + delta)
	if ok:
		selected_step = index + delta
		_touch()
	return ok

func undo() -> bool:
	var ok: bool = pipeline.undo()
	if ok: _touch()
	return ok

func redo() -> bool:
	var ok: bool = pipeline.redo()
	if ok: _touch()
	return ok

func reset() -> void:
	pipeline.reset()
	selected_step = -1
	view_removed = false
	_touch()

func can_undo() -> bool:
	return not pipeline._undo.is_empty()

func can_redo() -> bool:
	return not pipeline._redo.is_empty()

func step_report(index: int) -> Dictionary:
	var rep: Array = result().report
	return rep[index] if index >= 0 and index < rep.size() else {}

# Rows removed and rows changed by step `index` (raw row ids), plus the removed rows as a table.
func step_diff(index: int) -> Dictionary:
	var before: RefCounted = pipeline.run(index).dataset
	var after: RefCounted = pipeline.run(index + 1).dataset
	var kept := {}
	for i in after.rids.size():
		if after.rids[i] >= 0: kept[after.rids[i]] = i
	var removed_table: RefCounted = before.copy()
	removed_table.rows = []
	removed_table.rids = []
	var removed: Array = []
	var changed: Array = []
	var shared: Array = []
	for c in before.cols:
		if after.cols.has(c): shared.append(c)
	for i in before.rids.size():
		var rid: int = before.rids[i]
		if rid < 0: continue
		if not kept.has(rid):
			removed.append(rid)
			removed_table.rows.append(before.rows[i].duplicate())
			removed_table.rids.append(rid)
			continue
		var j: int = kept[rid]
		for c in shared:
			if str(before.rows[i][before.col_index(c)]) != str(after.rows[j][after.col_index(c)]):
				changed.append(rid)
				break
	return {"rows_in":before.row_count(), "rows_out":after.row_count(), "removed":removed, "changed":changed, "removed_table":removed_table}

# Raw row ids highlighted in the grid: changed rows of the selected step (removed rows have their own view).
func highlighted() -> Dictionary:
	var out := {}
	if selected_step < 0 or view_removed: return out
	for rid in step_diff(selected_step).changed: out[rid] = true
	return out

# Statistics of one column of the shown table: count (non-blank), mean, median, min, max, nulls.
func column_stats(c: int) -> Dictionary:
	var ds: RefCounted = shown_table()
	if c < 0 or c >= ds.cols.size(): return {}
	var nums: Array = []
	var nulls := 0
	var count := 0
	for r in ds.rows:
		var v: Variant = r[c]
		if Ops.is_missing(v):
			nulls += 1
			continue
		count += 1
		var n: Variant = Ops.num(v)
		if n != null: nums.append(n)
	var out := {"name":ds.cols[c], "type":ds.types[c], "count":count, "nulls":nulls, "numeric":nums.size()}
	if not nums.is_empty():
		var sorted := nums.duplicate()
		sorted.sort()
		var total := 0.0
		for n in nums: total += n
		out["mean"] = total / nums.size()
		out["median"] = Ops.quantile(sorted, 0.5)
		out["min"] = sorted[0]
		out["max"] = sorted[sorted.size() - 1]
	return out

func distinct_values(c: int, limit: int = 24) -> Array:
	var ds: RefCounted = table()
	var out: Array = []
	if c < 0 or c >= ds.cols.size(): return out
	var seen := {}
	for r in ds.rows:
		if r[c] == null: continue
		var key := str(r[c])
		if seen.has(key): continue
		seen[key] = true
		out.append(key)
		if out.size() >= limit: break
	out.sort()
	return out

# "Looks fine?": what a person sees scanning the table. Row count, blanks, distinct values and the value
# list of short text columns. No defect names, no hints beyond the visible cells.
func profile() -> Array:
	var ds: RefCounted = table()
	var out: Array = []
	for c in ds.cols.size():
		var blanks := 0
		var counts := {}
		for r in ds.rows:
			if Ops.is_missing(r[c]): blanks += 1
			else: counts[str(r[c])] = int(counts.get(str(r[c]), 0)) + 1
		var item := {"name":ds.cols[c], "type":ds.types[c], "blank":blanks, "distinct":counts.size()}
		if counts.size() <= 12 and counts.size() > 0:
			var keys: Array = counts.keys()
			keys.sort()
			item["values"] = keys.map(func(k): return "%s (%d)" % [k, counts[k]])
		out.append(item)
	return out

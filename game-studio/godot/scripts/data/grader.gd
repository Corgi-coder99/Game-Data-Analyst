extends RefCounted
# T-033: HIDDEN. Scores a submitted analysis (pipeline result, findings, chart) against the reference.
const Ops = preload("res://scripts/data/ops.gd")
const Pipeline = preload("res://scripts/data/pipeline.gd")
const Charts = preload("res://scripts/data/charts.gd")
const Loader = preload("res://scripts/data.gd")
var cfg: Dictionary

func _init(p_cfg: Dictionary = {}) -> void:
	cfg = p_cfg if not p_cfg.is_empty() else Loader.load_json("res://data/datasets.json")

static func cells_equal(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return absf(float(a) - float(b)) <= 1e-6 * maxf(1.0, absf(float(b)))
	if a == null or b == null: return a == null and b == null
	return str(a) == str(b)

static func _loose_equal(a: Variant, b: Variant) -> bool:
	if a is String and b is String: return String(a).strip_edges().to_lower() == String(b).strip_edges().to_lower()
	return cells_equal(a, b)

# Cleaning: per manifest entry, fixed / missed / wrongly handled rows, plus unmarked rows that were wrongly
# removed or changed. `player` is the row-level table of the player's pipeline (rids kept).
func cleaning(file: Dictionary, player: RefCounted) -> Dictionary:
	var at := {}
	for i in player.rids.size():
		if player.rids[i] >= 0: at[player.rids[i]] = i
	var marked := {}
	var entries: Array = []
	var fixed_rows := 0
	var total_rows := 0
	for m in file.manifest:
		var fixed := 0
		var missed := 0
		var wrong := 0
		for rid in m.rows:
			total_rows += 1
			for c in m.columns: marked["%d|%s" % [rid, c]] = true
			var exp: Variant = file.expected[rid]
			if exp == null:
				if at.has(rid): missed += 1
				else: fixed += 1
			elif not at.has(rid):
				wrong += 1
			else:
				var ok := true
				for c in m.columns:
					var pc: int = player.col_index(c)
					var ec: int = file.raw.col_index(c)
					if pc < 0 or not cells_equal(player.rows[at[rid]][pc], exp[ec]): ok = false
				if ok: fixed += 1
				else: missed += 1
		fixed_rows += fixed
		entries.append({"type":m.type, "columns":m.columns, "rows":m.rows.size(), "fixed":fixed, "missed":missed, "wrongly_removed":wrong})
	var kept := 0
	var wrong_removed := 0
	var wrong_changed := 0
	for rid in file.expected:
		var exp: Variant = file.expected[rid]
		if exp == null: continue
		kept += 1
		if not at.has(rid):
			wrong_removed += 1
			continue
		for ec in file.raw.cols.size():
			var col: String = file.raw.cols[ec]
			if marked.has("%d|%s" % [rid, col]): continue
			var pc: int = player.col_index(col)
			if pc >= 0 and not _loose_equal(player.rows[at[rid]][pc], exp[ec]):
				wrong_changed += 1
				break
	var fixed_ratio: float = 1.0 if total_rows == 0 else float(fixed_rows) / total_rows
	var wrong_ratio: float = float(wrong_removed + wrong_changed) / maxf(1.0, kept)
	var score := clampf(fixed_ratio - float(cfg.grader.wrong_penalty) * minf(1.0, wrong_ratio * 4.0), 0.0, 1.0)
	return {"entries":entries, "defect_rows":total_rows, "fixed_rows":fixed_rows, "missed_rows":total_rows - fixed_rows, "wrongly_removed":wrong_removed, "wrongly_changed":wrong_changed, "score":score}

func _finding_score(ref: RefCounted, truth_item: Dictionary, given: Variant) -> float:
	if given == null: return 0.0
	if truth_item.id == "metric_change":
		var want: Variant = truth_item.value
		if want == null or not (given is Dictionary): return 0.0
		if given.get("direction", "") != want.direction: return 0.0
		var score := float(cfg.grader.direction_only)
		var gb: int = ref.band_index(str(given.get("band", "")))
		var wb: int = ref.band_index(want.band)
		if gb >= 0 and gb == wb: score = 1.0
		elif gb >= 0 and absi(gb - wb) == 1: score += (1.0 - float(cfg.grader.direction_only)) * float(cfg.grader.adjacent_band)
		return score
	return 1.0 if given == truth_item.value else 0.0

func findings(ref: RefCounted, truth_list: Array, submitted: Dictionary) -> Dictionary:
	var items: Array = []
	var total := 0.0
	for t in truth_list:
		var given: Variant = submitted.get(t.id)
		var s := _finding_score(ref, t, given)
		total += s
		items.append({"id":t.id, "submitted":given, "truth":t.value, "score":s})
	return {"items":items, "score":total / maxf(1.0, truth_list.size())}

func chart(final_table: RefCounted, spec: Dictionary) -> Dictionary:
	if spec.is_empty(): return {"flags":[], "score":0.0, "present":false}
	var flags := Charts.new(cfg).check(final_table, spec)
	var score := clampf(1.0 - float(cfg.grader.chart_flag_penalty) * flags.size(), 0.0, 1.0)
	return {"flags":flags, "score":score, "present":true}

func grade(file: Dictionary, ref: RefCounted, truth_list: Array, submission: Dictionary) -> Dictionary:
	var run: Dictionary = Pipeline.from_array(file.raw, submission.get("pipeline", []), file.aux).run()
	var c := cleaning(file, run.row_level)
	var f := findings(ref, truth_list, submission.get("findings", {}))
	var ch := chart(run.dataset, submission.get("chart", {}))
	var w: Dictionary = cfg.grader.weights
	var total: float = float(w.cleaning) * c.score + float(w.findings) * f.score + float(w.chart) * ch.score
	return {"cleaning":c, "findings":f, "chart":ch, "total":total, "failed_steps":run.failed}

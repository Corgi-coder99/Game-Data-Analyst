extends SceneTree
# T-033: generator, dirt manifest (independent detectors), difficulty ramp, solvability, information value.
const Gen = preload("res://scripts/data/generator.gd")
const Ref = preload("res://scripts/data/reference.gd")
const Scenario = preload("res://scripts/world/world_scenario.gd")
const Pipeline = preload("res://scripts/data/pipeline.gd")
const Grader = preload("res://scripts/data/grader.gd")
const DS = preload("res://scripts/data/dataset.gd")
const Ops = preload("res://scripts/data/ops.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Loader = preload("res://scripts/data.gd")
const Sim = preload("res://scripts/sim/simulation.gd")
const METRIC := ["sales_export", "market_prices", "web_funnel", "loan_book", "support_tickets", "competitor_scrape"]
var checks := 0
var failures := 0
var world_cfg: Dictionary
var questions: Array
var events: Array
var data_cfg: Dictionary
var scenarios := {}
var ref: RefCounted

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 40: printerr("FAIL: ", message)

func scenario(seed_value: int) -> RefCounted:
	if not scenarios.has(seed_value): scenarios[seed_value] = Scenario.new(seed_value, 10, world_cfg, questions, events)
	return scenarios[seed_value]

func gen(seed_value: int) -> RefCounted:
	return Gen.new(scenario(seed_value), seed_value, data_cfg)

# ---------- independent defect detectors (look only at the raw table) ----------
func structural(file: Dictionary, row: Array) -> bool:
	var id: int = file.raw.col_index(file.recipe.id_col)
	return row == file.raw.cols or row[id] == "TOTAL"

func norm_value(file: Dictionary, row: Array, col: String) -> Variant:
	var v: Variant = Ops.num(row[file.raw.col_index(col)])
	if v != null and file.raw.has_col("currency") and row[file.raw.col_index("currency")] == "VND": v = v / float(data_cfg.vnd_per_usd)
	return v

func detect(file: Dictionary, defect: String) -> Array:
	var raw: RefCounted = file.raw
	var name: String = file.name
	var spec: Dictionary = data_cfg.datasets[name]
	var out: Array = []
	if not spec.dirt.has(defect): return out
	var seen := {}
	var dc: int = raw.col_index(file.recipe.date_col)
	var fence := INF
	if defect == "outliers":
		var oc: int = raw.col_index(spec.outlier_col)
		var vals: Array = []
		for row in raw.rows:
			var n: Variant = norm_value(file, row, spec.outlier_col) if not structural(file, row) else null
			if n != null: vals.append(n)
		vals.sort()
		var q1 := Ops.quantile(vals, 0.25)
		var q3 := Ops.quantile(vals, 0.75)
		fence = q3 + 3.0 * (q3 - q1)
	var last := ""
	var late_rows: Array = []
	if defect == "late_partial":
		var per_day := {}
		for i in raw.rows.size():
			var d: Variant = Ops.parse_date(raw.rows[i][dc]) if not structural(file, raw.rows[i]) else null
			if d != null:
				per_day[d] = per_day.get(d, []) + [i]
		var days: Array = per_day.keys()
		days.sort()
		last = days[days.size() - 1]
		var counts: Array = days.slice(0, days.size() - 1).map(func(d): return per_day[d].size())
		counts.sort()
		if per_day[last].size() < 0.6 * counts[counts.size() / 2]: late_rows = per_day[last]
	for i in raw.rows.size():
		var row: Array = raw.rows[i]
		var is_struct := structural(file, row)
		if defect == "repeated_header":
			if row == raw.cols: out.append(i)
			continue
		if defect == "subtotal_rows":
			if row != raw.cols and row[raw.col_index(file.recipe.id_col)] == "TOTAL": out.append(i)
			continue
		if is_struct: continue
		var hit := false
		match defect:
			"duplicates":
				var key := JSON.stringify(row)
				hit = seen.has(key)
				seen[key] = true
			"missing_blank":
				for m in spec.missing_cols: hit = hit or row[raw.col_index(m.col)] is String and row[raw.col_index(m.col)] == ""
			"missing_na":
				for m in spec.missing_cols:
					var v: Variant = row[raw.col_index(m.col)]
					hit = hit or (v is String and String(v).to_lower() in ["n/a", "na"])
			"missing_zero":
				for m in spec.missing_cols:
					var v: Variant = row[raw.col_index(m.col)]
					hit = hit or (m.zero and (v is int or v is float) and float(v) == 0.0)
			"mixed_units":
				if name in ["sales_export", "competitor_scrape"]: hit = row[raw.col_index("currency")] == "VND"
				else:
					var v: Variant = row[raw.col_index("value" if name == "market_prices" else "balance")]
					hit = v is String and String(v).ends_with("k")
			"mixed_dates":
				hit = row[dc] is String and not Clock.is_valid(row[dc])
			"category_typos":
				for col in spec.typo_cols:
					var v: Variant = row[raw.col_index(col)]
					if v is String and v != "" and not (String(v).to_lower() in ["n/a", "na", "unknown"]) and not spec.typos[col].has(v): hit = true
			"outliers":
				var n: Variant = norm_value(file, row, spec.outlier_col)
				hit = n != null and n > fence
			"refunds_negative":
				var u: Variant = Ops.num(row[raw.col_index("units")])
				hit = u != null and u < 0
			"test_accounts":
				match name:
					"sales_export": hit = row[raw.col_index("channel")] == "internal_test"
					"loan_book": hit = int(String(row[1]).strip_edges().substr(1)) >= 9001
					"support_tickets": hit = String(row[0]).begins_with("TST-")
					"ab_test_log": hit = String(row[0]).begins_with("qa_")
			"join_key_mismatch":
				var id: String = row[raw.col_index("customer_id")]
				hit = id != id.strip_edges().to_upper()
			"late_partial":
				hit = late_rows.has(i)
		if hit: out.append(i)
	return out

func manifest_rows(file: Dictionary, defect: String) -> Array:
	var out: Array = []
	for m in file.manifest:
		if m.type == defect:
			for r in m.rows:
				if not out.has(r): out.append(r)
	out.sort()
	return out

func sorted(a: Array) -> Array:
	var c := a.duplicate()
	c.sort()
	return c

# ---------- helpers ----------
func rows_match(file: Dictionary, result: RefCounted) -> int:
	var at := {}
	for i in result.rids.size(): at[result.rids[i]] = i
	var bad := 0
	for rid in file.expected:
		var exp: Variant = file.expected[rid]
		if exp == null:
			if at.has(rid): bad += 1
			continue
		if not at.has(rid):
			bad += 1
			continue
		for c in file.raw.cols.size():
			var ci: int = result.col_index(file.raw.cols[c])
			if ci < 0 or not Grader.cells_equal(result.rows[at[rid]][ci], exp[c]):
				bad += 1
				break
	return bad

func clean_table(file: Dictionary) -> RefCounted:
	var t = DS.make(file.name, file.raw.cols, file.raw.types)
	for rid in range(file.raw.row_count()):
		if file.expected[rid] != null: t.add_row(file.expected[rid], rid)
	return t

func construction_spike(file: Dictionary) -> String:
	var rows := manifest_rows(file, "outliers")
	if rows.is_empty(): return ""
	var col: String = data_cfg.datasets[file.name].outlier_col
	var ci: int = file.raw.col_index(col)
	var li: int = file.raw.col_index(ref.LABEL_COL[file.name])
	var best := -1.0
	var label := ""
	for r in rows:
		var v := absf(float(file.raw.rows[r][ci]))
		if v > best:
			best = v
			label = str(file.raw.rows[r][li])
	var vocab: Dictionary = data_cfg.datasets[file.name].typos.get(ref.LABEL_COL[file.name], {})
	for canon in vocab:
		if canon == label or vocab[canon].has(label): return canon
	return label

func same_truth(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		if a[i].id != b[i].id: return false
		if a[i].id == "metric_change":
			if (a[i].value == null) != (b[i].value == null): return false
			if a[i].value != null and (a[i].value.direction != b[i].value.direction or a[i].value.band != b[i].value.band or absf(a[i].value.pct - b[i].value.pct) > 1e-6): return false
		elif a[i].value != b[i].value:
			return false
	return true

# Does the table say something different from the reference? (metric only, or any statement)
func differs(truth_ref: Array, truth_other: Array, metric_only: bool) -> bool:
	for i in truth_ref.size():
		if metric_only and truth_ref[i].id != "metric_change": continue
		var a: Dictionary = truth_ref[i]
		var b: Dictionary = truth_other[i]
		if a.id == "metric_change":
			if b.value == null or a.value.direction != b.value.direction or a.value.band != b.value.band: return true
		elif a.value != b.value:
			return true
	return false

# ---------- tests ----------
func test_determinism() -> void:
	var g := gen(21)
	var a: Array = g.generate(4)
	var b: Array = gen(21).generate(4)
	check(a.size() == b.size() and a.size() >= 1, "same seed, same file count")
	var same := a.size() == b.size()
	for i in a.size():
		same = same and a[i].raw.to_csv() == b[i].raw.to_csv() and JSON.stringify(a[i].manifest) == JSON.stringify(b[i].manifest) and JSON.stringify(a[i].aux.keys()) == JSON.stringify(b[i].aux.keys())
	check(same, "same seed and day give identical files and manifests")
	var before := JSON.stringify(scenario(21)._days) + JSON.stringify(scenario(21)._shocks)
	for d in range(1, 11): g.generate(d)
	check(JSON.stringify(scenario(21)._days) + JSON.stringify(scenario(21)._shocks) == before, "generating never changes the scenario")
	var other_day: Array = g.generate(5)
	check(a[0].raw.to_csv() != other_day[0].raw.to_csv(), "different days differ")
	var other_seed: Array = gen(22).generate(4)
	check(a[0].raw.to_csv() != other_seed[0].raw.to_csv(), "different seeds differ")
	# own RNG: global random state is not consumed
	seed(77)
	var x1 := randi()
	seed(77)
	gen(23).generate(6)
	check(randi() == x1, "generator does not touch the global RNG")
	var g2 := Gen.new(scenario(21), 21, data_cfg)
	check(g2.generate(4)[0].raw.to_csv() == a[0].raw.to_csv(), "generation order does not matter (day 4 after nothing else)")

func test_ranges_and_ramp() -> void:
	var rows_by_day := {}
	var dirt_by_day := {}
	var counts := {1:0, 2:0, 3:0}
	var all_types := {}
	var min_rows := 9999
	var max_rows := 0
	for s in range(1, 41):
		var g := gen(s)
		for day in range(1, 11):
			var files: Array = g.generate(day)
			var diff: Dictionary = g.difficulty(day)
			check(files.size() >= 1 and files.size() <= 3 and files.size() == diff.files, "file count 1..3 matches ramp (seed %d day %d)" % [s, day])
			counts[files.size()] += 1
			var names := {}
			for f in files:
				names[f.name] = true
				var n: int = f.raw.row_count()
				min_rows = mini(min_rows, n)
				max_rows = maxi(max_rows, n)
				check(n >= 40 and n <= 400, "rows in range %d (%s seed %d day %d)" % [n, f.name, s, day])
				rows_by_day[day] = rows_by_day.get(day, 0) + n
				dirt_by_day[day] = dirt_by_day.get(day, []) + [f.dirt_types.size()]
				for t in f.dirt_types: all_types[t] = true
				if day == 1: check(f.dirt_types.size() == 1, "day 1 has exactly one dirt type")
				check(f.dirt_types.size() <= 6 and f.dirt_types.size() >= 1, "dirt types 1..6")
			check(names.size() == files.size(), "files of one day are distinct types")
			if day == 1: check(files[0].name == "sales_export", "day 1 starts with the sales export")
	check(all_types.size() >= 12, "at least 12 defect types appear (%d)" % all_types.size())
	check(counts[1] > 0 and counts[2] > 0 and counts[3] > 0, "days with 1, 2 and 3 files exist")
	var avg_dirt := func(day): return float(dirt_by_day[day].reduce(func(a, b): return a + b, 0)) / dirt_by_day[day].size()
	check(avg_dirt.call(1) == 1.0 and avg_dirt.call(2) < avg_dirt.call(4) and avg_dirt.call(4) <= avg_dirt.call(7) and avg_dirt.call(10) >= 4.0, "dirt types ramp up with the day (%.2f %.2f %.2f %.2f)" % [avg_dirt.call(1), avg_dirt.call(2), avg_dirt.call(4), avg_dirt.call(10)])
	var avg_rows := func(day): return float(rows_by_day[day]) / (dirt_by_day[day].size())
	check(avg_rows.call(1) < 0.6 * avg_rows.call(8), "day 1 files are small (%.0f vs %.0f rows)" % [avg_rows.call(1), avg_rows.call(8)])
	print("rows range ", min_rows, "..", max_rows, "; defect types seen ", all_types.size(), "; files per day (1/2/3 files) ", counts)

func test_manifest() -> void:
	var per_type := {}
	var exact := ["repeated_header", "subtotal_rows", "duplicates", "missing_blank", "missing_na", "missing_zero", "mixed_units", "mixed_dates", "category_typos", "outliers", "refunds_negative", "test_accounts", "join_key_mismatch", "late_partial"]
	for s in range(1, 31):
		var g := gen(s)
		for day in range(2, 11):
			for f in g.generate(day):
				for defect in exact:
					var found := detect(f, defect)
					var listed := manifest_rows(f, defect)
					if f.dirt_types.has(defect) and defect == "outliers":
						per_type[defect] = per_type.get(defect, 0) + 1
						var missing_ones: Array = listed.filter(func(r): return not found.has(r))
						check(missing_ones.is_empty(), "every injected outlier is re-detected (%s seed %d day %d): %s" % [f.name, s, day, str(missing_ones)])
					elif f.dirt_types.has(defect):
						per_type[defect] = per_type.get(defect, 0) + 1
						check(sorted(found) == listed, "manifest %s matches detector (%s seed %d day %d): found %s listed %s" % [defect, f.name, s, day, str(sorted(found).slice(0, 8)), str(listed.slice(0, 8))])
					elif defect != "outliers":
						check(found.is_empty(), "no %s defect in %s seed %d day %d without the manifest (%s)" % [defect, f.name, s, day, str(found.slice(0, 5))])
	print("manifest-verified files per defect type: ", per_type)
	check(per_type.size() == 14, "all 14 defect types were generated and re-detected (%d)" % per_type.size())

func test_solvability() -> void:
	var seeds := 300
	var by_name := {}
	var wrong := {"all":0, "metric":0, "n":0}
	var by_defect := {}
	var ab_rows := {"sig_effect":0, "n_effect":0, "sig_none":0, "n_none":0, "winner_ok":0}
	var rebuild_bad := 0
	for s in range(1, seeds + 1):
		var g := gen(s)
		var day := 3 + s % 8
		var diff: Dictionary = g.difficulty(day)
		for name in Gen.NAMES:
			var f: Dictionary = g.build_file(name, day, 0, diff.dirt, diff.scale)
			var result: Dictionary = ref.run_steps(f, ref.steps(f))
			var bad := rows_match(f, result.dataset)
			check(bad == 0, "reference pipeline reproduces the clean table (%s seed %d day %d): %d row mismatches, dirt %s" % [name, s, day, bad, str(f.dirt_types)])
			check(result.failed == 0, "reference pipeline has no failing step (%s seed %d)" % [name, s])
			var truth_ref: Array = ref.truth(f, result.dataset, ref.spike_label(f))
			var truth_built: Array = ref.truth(f, clean_table(f), construction_spike(f) if ref.LABEL_COL.has(name) else "")
			if ref.LABEL_COL.has(name):
				for t in truth_built:
					if t.id == "spike_error" and t.value == "": t.value = "none"
			check(same_truth(truth_ref, truth_built), "truth from the reference pipeline equals truth from the construction (%s seed %d): %s vs %s" % [name, s, JSON.stringify(truth_ref), JSON.stringify(truth_built)])
			var naive: Dictionary = ref.run_steps(f, ref.naive_steps(f))
			var truth_naive: Array = ref.truth(f, naive.dataset, "")
			var any_wrong := differs(truth_ref, truth_naive, false)
			var metric_wrong: bool = name != "ab_test_log" and differs(truth_ref, truth_naive, true)
			if name == "ab_test_log": metric_wrong = any_wrong
			var slot: Dictionary = by_name.get(name, {"n":0, "any":0, "metric":0})
			slot.n += 1
			slot.any += 1 if any_wrong else 0
			slot.metric += 1 if metric_wrong else 0
			by_name[name] = slot
			wrong.n += 1
			wrong.all += 1 if any_wrong else 0
			wrong.metric += 1 if metric_wrong else 0
			for d in f.dirt_types:
				var dslot: Dictionary = by_defect.get(d, {"n":0, "metric":0})
				dslot.n += 1
				dslot.metric += 1 if metric_wrong else 0
				by_defect[d] = dslot
			if name == "ab_test_log":
				var effect: bool = absf(f.hidden.uplift) > 0.0
				var sig: bool = truth_ref[0].value
				ab_rows["n_effect" if effect else "n_none"] += 1
				if sig: ab_rows["sig_effect" if effect else "sig_none"] += 1
				if effect and truth_ref[1].value == ("B" if f.hidden.uplift > 0 else "A"): ab_rows.winner_ok += 1
			# rebuilding the same file gives the same answer
			if s % 50 == 0 and g.build_file(name, day, 0, diff.dirt, diff.scale).raw.to_csv() != f.raw.to_csv(): rebuild_bad += 1
	check(rebuild_bad == 0, "files rebuild identically")
	check(float(wrong.metric) / wrong.n > 0.3, "cleaning matters: no-cleaning gives a wrong metric answer in a measurable share of files (%.1f%%)" % (100.0 * wrong.metric / wrong.n))
	print("SOLVABILITY: ", seeds, " seeds x 7 dataset types = ", wrong.n, " files; reference pipeline mismatches: 0 required")
	print("NAIVE (no cleaning) differs from the reference answer in ", snappedf(100.0 * wrong.all / wrong.n, 0.1), "% of files on any statement, ", snappedf(100.0 * wrong.metric / wrong.n, 0.1), "% on the metric statement")
	for name in by_name: print("  ", name, ": any ", snappedf(100.0 * by_name[name].any / by_name[name].n, 0.1), "%  metric ", snappedf(100.0 * by_name[name].metric / by_name[name].n, 0.1), "%  (n=", by_name[name].n, ")")
	for d in by_defect: print("  files with ", d, ": naive metric wrong ", snappedf(100.0 * by_defect[d].metric / by_defect[d].n, 0.1), "% (n=", by_defect[d].n, ")")
	print("  A/B: significant when a real effect exists ", ab_rows.sig_effect, "/", ab_rows.n_effect, " (winner right in ", ab_rows.winner_ok, "); significant with no effect ", ab_rows.sig_none, "/", ab_rows.n_none)
	for d in ["outliers", "mixed_units", "duplicates"]:
		check(by_defect.has(d) and by_defect[d].metric > 0, "naive reading is wrong for some files with %s" % d)

func test_information_value() -> void:
	var total := 0
	var ok := {"reference":0, "none":0, "sloppy":0}
	var state_ok := 0
	var per_name := {}
	var null_count := {"reference":0, "none":0, "sloppy":0}
	for s in range(1, 201):
		var g := gen(s)
		for day in range(1, 11):
			var name: String = METRIC[(s + day) % 6]
			var diff: Dictionary = g.difficulty(day)
			var f: Dictionary = g.build_file(name, day, 0, diff.dirt, diff.scale)
			total += 1
			var modes := {"reference":ref.steps(f), "none":ref.naive_steps(f), "sloppy":ref.sloppy_steps(f)}
			for mode in modes:
				var result: Dictionary = ref.run_steps(f, modes[mode])
				var truth: Array = ref.truth(f, result.dataset, "")
				var v: Variant = truth[0].value
				if v == null: null_count[mode] += 1
				if v != null and v.direction == f.hidden.direction:
					ok[mode] += 1
					if mode == "reference":
						var slot: Dictionary = per_name.get(name, {"n":0, "ok":0})
						slot.ok += 1
						per_name[name] = slot
				if mode == "reference" and v != null and v.direction == f.hidden.state_direction: state_ok += 1
			var slot2: Dictionary = per_name.get(name, {"n":0, "ok":0})
			slot2.n += 1
			per_name[name] = slot2
	var pct := func(n): return 100.0 * n / total
	print("INFORMATION VALUE over ", total, " days: direction of the hidden 7-day change recovered: reference pipeline ", snappedf(pct.call(ok.reference), 0.1), "%, no cleaning ", snappedf(pct.call(ok.none), 0.1), "%, sloppy (drop any row with a missing value) ", snappedf(pct.call(ok.sloppy), 0.1), "%; unanswerable (no window) reference/none/sloppy ", null_count.reference, "/", null_count.none, "/", null_count.sloppy)
	print("  last-day state direction (single day, not the 7-day change) matched by the reference answer in ", snappedf(pct.call(state_ok), 0.1), "% of days")
	for name in per_name: print("  ", name, ": reference ", snappedf(100.0 * per_name[name].ok / per_name[name].n, 0.1), "% (n=", per_name[name].n, ")")
	check(total == 2000, "2000 days measured")
	check(pct.call(ok.reference) >= 80.0, "reference pipeline recovers the hidden direction in >= 80%% of days (%.1f%%)" % pct.call(ok.reference))
	check(pct.call(ok.none) < pct.call(ok.reference) - 10.0, "no cleaning is clearly lower (%.1f%% vs %.1f%%)" % [pct.call(ok.none), pct.call(ok.reference)])
	check(pct.call(ok.sloppy) < pct.call(ok.reference), "sloppy cleaning is lower than the reference (%.1f%%)" % pct.call(ok.sloppy))

func _init() -> void:
	data_cfg = Loader.load_json("res://data/datasets.json")
	world_cfg = Loader.load_json("res://data/world.json")
	questions = Loader.load_json("res://data/questions.json").questions
	events = Sim.new(1, {}, 11).events
	ref = Ref.new(data_cfg)
	var which: String = OS.get_environment("T033_PART")
	var t0 := Time.get_ticks_msec()
	if which in ["", "a"]:
		test_determinism()
		test_ranges_and_ramp()
		print("part a ", Time.get_ticks_msec() - t0, " ms")
	if which in ["", "b"]:
		test_manifest()
		print("part b ", Time.get_ticks_msec() - t0, " ms")
	if which in ["", "c"]:
		test_solvability()
		print("part c ", Time.get_ticks_msec() - t0, " ms")
	if which in ["", "d"]:
		test_information_value()
		print("part d ", Time.get_ticks_msec() - t0, " ms")
	print("test_t033_data: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

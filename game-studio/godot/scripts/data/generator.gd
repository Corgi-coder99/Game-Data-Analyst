extends RefCounted
# T-033: builds the day's dirty files from the hidden trajectory. This is the ONLY place (with reference.gd)
# that reads hidden state, and it reads it through the scenario object `scenario._days` / `scenario._shocks`
# (read-only; no change to the world code). It owns its RNG streams, seeded from (world seed, day, salt),
# so the world, news and life streams are never consumed.
const DS = preload("res://scripts/data/dataset.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Loader = preload("res://scripts/data.gd")
const Ops = preload("res://scripts/data/ops.gd")

const NAMES := ["sales_export", "market_prices", "web_funnel", "loan_book", "support_tickets", "ab_test_log", "competitor_scrape"]
const COLS := {
	"sales_export":["date", "order_id", "region", "product", "units", "price", "currency", "channel"],
	"market_prices":["date", "series", "venue", "value", "unit"],
	"web_funnel":["date", "step", "source", "users"],
	"loan_book":["snapshot_date", "customer_id", "balance", "days_past_due", "status"],
	"support_tickets":["ticket_id", "date", "category", "severity", "text"],
	"ab_test_log":["user_id", "variant", "converted", "date"],
	"competitor_scrape":["date", "shop", "item", "currency", "price"]}
const TYPES := {
	"sales_export":["date", "text", "category", "category", "int", "float", "category", "category"],
	"market_prices":["date", "category", "category", "float", "text"],
	"web_funnel":["date", "category", "category", "int"],
	"loan_book":["date", "text", "float", "int", "category"],
	"support_tickets":["text", "date", "category", "category", "text"],
	"ab_test_log":["text", "category", "int", "date"],
	"competitor_scrape":["date", "category", "category", "category", "float"]}
const DATE_COL := {"sales_export":"date", "market_prices":"date", "web_funnel":"date", "loan_book":"snapshot_date", "support_tickets":"date", "ab_test_log":"date", "competitor_scrape":"date"}
const ID_COL := {"sales_export":"order_id", "market_prices":"venue", "web_funnel":"source", "loan_book":"customer_id", "support_tickets":"ticket_id", "ab_test_log":"user_id", "competitor_scrape":"item"}
const SUM_COLS := {"sales_export":["units"], "market_prices":["value"], "web_funnel":["users"], "loan_book":["balance", "days_past_due"], "support_tickets":[], "ab_test_log":["converted"], "competitor_scrape":["price"]}
const PRODUCTS := {"Widget":9.0, "Gadget":16.0, "Gizmo":24.0}
const REGIONS := ["Hanoi", "Hue", "Danang", "Saigon"]
const CHANNELS := ["web", "store", "partner"]
const TEXTS := {
	"billing":["I was charged twice this month", "Invoice total looks wrong", "Please update my billing address"],
	"bug":["The app freezes on the checkout page", "Export button does nothing", "Dark mode text is unreadable"],
	"account":["I cannot reset my password", "Please merge my two accounts", "Change my login email"],
	"shipping":["My parcel has not arrived", "Tracking number shows no updates", "Wrong item in the box"]}
var cfg: Dictionary
var scenario: RefCounted
var seed_value: int

func _init(p_scenario: RefCounted = null, p_seed: int = 0, p_cfg: Dictionary = {}) -> void:
	scenario = p_scenario
	seed_value = p_seed
	cfg = p_cfg if not p_cfg.is_empty() else Loader.load_json("res://data/datasets.json")

# ---------- plan ----------
func _rng(day: int, salt: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("data|%d|%d|%s" % [seed_value, day, salt])
	return rng

# Largest threshold <= day from [[day, value], ...].
func _ramp(table: Array, day: int) -> float:
	var out := float(table[0][1])
	for row in table:
		if day >= int(row[0]): out = float(row[1])
	return out

func difficulty(day: int) -> Dictionary:
	return {"dirt":int(_ramp(cfg.ramp.dirt_count, day)), "files":int(_ramp(cfg.ramp.files, day)), "scale":_ramp(cfg.ramp.rows_scale, day)}

func plan(day: int) -> Dictionary:
	var rng := _rng(day, "plan")
	var diff := difficulty(day)
	var pool: Array = cfg.ramp.starter.duplicate() if day <= int(cfg.ramp.starter_until_day) else NAMES.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	if day == 1:
		pool.erase(cfg.ramp.first_file)
		pool.push_front(cfg.ramp.first_file)
	return {"names":pool.slice(0, mini(diff.files, pool.size())), "dirt":diff.dirt, "scale":diff.scale}

func generate(day: int) -> Array:
	var p := plan(day)
	var files: Array = []
	for i in p.names.size():
		files.append(build_file(p.names[i], day, i, p.dirt, p.scale))
	return files

# ---------- trajectory ----------
func _sign_of(direction: String) -> float:
	return 1.0 if direction == "tang" else (-1.0 if direction == "giam" else 0.0)

func _state(t: int, variable: String) -> Dictionary:
	var idx := clampi(t, 0, scenario._days.size() - 1)
	return scenario._days[idx][variable]

func _shock_factor(name: String, t: int, step: String) -> float:
	var f := 1.0
	for s in scenario._shocks:
		if t >= int(s.day) and t < int(s.end) and cfg.shocks.has(s.id):
			var m: Dictionary = cfg.shocks[s.id]
			if m.dataset == name and (not m.has("step") or m.step == step): f *= float(m.factor)
	return f

# Level per history day (index 0 is day-15 ... index 14 is day-1), mean of the smooth path normalised to 1,
# multiplied by the shock factor active on that day.
func levels(name: String, variable: String, sign: float, day: int, step: String = "") -> Array:
	var hist := int(cfg.history_days)
	var path: Array = []
	var p := 1.0
	for i in hist:
		var t := day - hist + i
		var st := _state(t, variable)
		p *= 1.0 + sign * _sign_of(st.direction) * float(cfg.step_pct[st.magnitude])
		path.append(p)
	var mean := 0.0
	for v in path: mean += v
	mean /= hist
	var out: Array = []
	for i in hist: out.append(path[i] / mean * _shock_factor(name, day - hist + i, step))
	return out

func window_pct(series: Array, end_index: int) -> float:
	var w := int(cfg.window)
	var cur := 0.0
	var prev := 0.0
	for k in w:
		cur += series[end_index - k]
		prev += series[end_index - w - k]
	return (cur / prev - 1.0) * 100.0

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

func date_of(day: int, index: int) -> String:
	return Clock.add_days(cfg.base_date, day - int(cfg.history_days) + index)

func _noise(rng: RandomNumberGenerator, amp: float) -> float:
	return 1.0 + amp * (rng.randf() * 2.0 - 1.0)

func _stoch(rng: RandomNumberGenerator, x: float) -> int:
	return int(floor(x + rng.randf()))

func _rec(raw: Array, day_index: int, prot: bool = false) -> Dictionary:
	return {"raw":raw, "clean":raw.duplicate(), "marks":{}, "day":day_index, "prot":prot, "extra":false}

# ---------- one file ----------
func build_file(name: String, day: int, index: int, dirt_count: int, scale: float) -> Dictionary:
	var spec: Dictionary = cfg.datasets[name]
	var rng := _rng(day, "file%d" % index)
	var hist := int(cfg.history_days)
	var info := {"aux":{}, "meta":{}}
	var recs: Array = []
	var level_series: Array = []
	var variable: String = spec.variable
	var sign: float = float(spec.sign)
	var step_key := ""
	match name:
		"market_prices":
			var s: Dictionary = spec.series[rng.randi_range(0, spec.series.size() - 1)]
			variable = s.variable
			info.meta = {"series":s.name, "unit":s.unit}
		"competitor_scrape":
			var it: Dictionary = spec.items[rng.randi_range(0, spec.items.size() - 1)]
			info.meta = {"item":it.name}
		"web_funnel":
			step_key = "purchase"
	level_series = levels(name, variable, sign, day, step_key)
	var dates: Array = []
	for i in hist: dates.append(date_of(day, i))
	match name:
		"sales_export": recs = _base_sales(rng, spec, scale, dates, level_series)
		"market_prices": recs = _base_market(rng, spec, scale, dates, day, variable, sign, info)
		"web_funnel": recs = _base_funnel(rng, spec, dates, day, variable, sign)
		"loan_book": recs = _base_loans(rng, spec, scale, dates, level_series, info)
		"support_tickets": recs = _base_tickets(rng, spec, scale, dates, level_series)
		"ab_test_log": recs = _base_ab(rng, spec, scale, dates, day, info)
		"competitor_scrape": recs = _base_competitor(rng, spec, scale, dates, level_series, info)
	# dirt selection
	var eligible: Array = spec.dirt.duplicate()
	var chosen: Array = []
	if day <= int(cfg.ramp.easy_until_day):
		var easy: Array = eligible.filter(func(d): return cfg.ramp.easy.has(d))
		eligible = easy
	for i in range(eligible.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = eligible[i]
		eligible[i] = eligible[j]
		eligible[j] = tmp
	chosen = eligible.slice(0, mini(dirt_count, eligible.size()))
	if chosen.has("join_key_mismatch") and not chosen.has("test_accounts"):
		if chosen[0] != "join_key_mismatch": chosen.pop_front()
		else: chosen.pop_back()
		chosen.append("test_accounts")
	var late := chosen.has("late_partial")
	var complete_last := hist - 2 if late else hist - 1
	var order: Array = cfg.dirt.order
	var ctx := {"name":name, "spec":spec, "dates":dates, "info":info, "complete_last":complete_last, "day":day, "counter":0}
	var recipe := {"name":name, "defects":[], "missing":[], "typo_cols":[], "currency":false, "suffix_cols":[], "outlier_col":"", "last_date":"", "date_col":DATE_COL[name], "id_col":ID_COL[name], "header":COLS[name], "complete_last":complete_last}
	for defect in order:
		if not chosen.has(defect): continue
		_inject(defect, recs, rng, ctx, recipe)
		if not recipe.defects.has(defect): recipe.defects.append(defect)
	return _finalize(name, day, index, recs, info, recipe, level_series, variable, sign, complete_last, spec)

# ---------- base tables ----------
func _count(rng: RandomNumberGenerator, spec: Dictionary, scale: float) -> int:
	return maxi(4, int(round(rng.randi_range(int(spec.per_day[0]), int(spec.per_day[1])) * scale)))

func _base_sales(rng: RandomNumberGenerator, spec: Dictionary, scale: float, dates: Array, lv: Array) -> Array:
	var recs: Array = []
	var n := _count(rng, spec, scale)
	var products: Array = PRODUCTS.keys()
	var serial := 1
	for i in dates.size():
		for k in n:
			var product: String = products[k % 3]
			var price := snappedf(float(PRODUCTS[product]) * lv[i] * _noise(rng, float(spec.noise)), 0.01)
			recs.append(_rec([dates[i], "O-%05d" % serial, REGIONS[k % 4], product, 1 + (k % 4), price, "USD", CHANNELS[k % 3]], i))
			serial += 1
	return recs

func _base_market(rng: RandomNumberGenerator, spec: Dictionary, scale: float, dates: Array, day: int, variable: String, sign: float, info: Dictionary) -> Array:
	var recs: Array = []
	var base := 1.0
	for s in spec.series:
		if s.name == info.meta.series: base = float(s.base)
	var lv := levels("market_prices", variable, sign, day)
	info["levels"] = lv
	var venues := ["Exchange A", "Exchange B", "Bank C", "Broker D"]
	var n := mini(4, maxi(3, int(round(rng.randi_range(int(spec.per_day[0]), int(spec.per_day[1])) * (0.75 + scale * 0.25)))))
	for i in dates.size():
		for k in n:
			recs.append(_rec([dates[i], info.meta.series, venues[k], snappedf(base * lv[i] * _noise(rng, float(spec.noise)), 0.01), info.meta.unit], i))
	return recs

func _base_funnel(rng: RandomNumberGenerator, spec: Dictionary, dates: Array, day: int, variable: String, sign: float) -> Array:
	var recs: Array = []
	var hist := dates.size()
	for i in hist:
		for s in spec.steps.size():
			var step: String = spec.steps[s]
			var lvl := levels("web_funnel", variable, sign, day, step)
			for src in spec.sources.size():
				var users := int(round(float(spec.step_base[s]) * float(spec.source_share[src]) * lvl[i] * _noise(rng, float(spec.noise))))
				recs.append(_rec([dates[i], step, spec.sources[src], users], i, step == "purchase"))
	return recs

func _base_loans(rng: RandomNumberGenerator, spec: Dictionary, scale: float, dates: Array, lv: Array, info: Dictionary) -> Array:
	var recs: Array = []
	var n := _count(rng, spec, scale)
	var customers = DS.make("customers", ["customer_id", "segment"], ["text", "category"])
	var segments := ["retail", "sme", "corporate"]
	for c in int(spec.customers): customers.add_row(["C%04d" % (c + 1), segments[c % 3]])
	for t in 5: customers.add_row(["C%04d" % (9001 + t), "Test"])
	info.aux["customers"] = customers
	for i in dates.size():
		for k in n:
			var dpd := int(round(float(spec.base_dpd) * lv[i] * _noise(rng, float(spec.noise))))
			var status := "current" if dpd < 15 else ("late" if dpd < 30 else "default")
			recs.append(_rec([dates[i], "C%04d" % (1 + (k * 7 + i * 13) % int(spec.customers)), snappedf(1000.0 + rng.randf() * 19000.0, 0.01), dpd, status], i))
	return recs

func _base_tickets(rng: RandomNumberGenerator, spec: Dictionary, scale: float, dates: Array, lv: Array) -> Array:
	var recs: Array = []
	var base := float(rng.randi_range(int(spec.per_day[0]), int(spec.per_day[1]))) * (0.5 + scale * 0.5)
	var cats := ["billing", "bug", "account", "shipping"]
	var weights := [0.3, 0.35, 0.2, 0.15]
	var sevs := ["low", "medium", "high"]
	var serial := 1
	for i in dates.size():
		var n := maxi(2, _stoch(rng, base * lv[i]))
		for k in n:
			var roll := rng.randf()
			var cat: String = cats[3]
			var acc := 0.0
			for c in 4:
				acc += weights[c]
				if roll < acc:
					cat = cats[c]
					break
			var sroll := rng.randf()
			var sev: String = sevs[0] if sroll < 0.5 else (sevs[1] if sroll < 0.85 else sevs[2])
			recs.append(_rec(["T-%05d" % serial, dates[i], cat, sev, TEXTS[cat][rng.randi_range(0, 2)]], i))
			serial += 1
	return recs

func _base_ab(rng: RandomNumberGenerator, spec: Dictionary, scale: float, dates: Array, day: int, info: Dictionary) -> Array:
	var recs: Array = []
	var st := _state(day - 1, spec.variable)
	var uplift := _sign_of(st.direction) * float(spec.uplift[st.magnitude])
	var p_a := float(spec.base_rate)
	var p_b := clampf(p_a * (1.0 + uplift), 0.02, 0.8)
	info.meta = {"p_a":p_a, "p_b":p_b, "uplift":uplift}
	var n := _count(rng, spec, scale)
	var serial := 1
	for i in dates.size():
		for k in n:
			var variant := "A" if rng.randf() < 0.5 else "B"
			var converted := 1 if rng.randf() < (p_a if variant == "A" else p_b) else 0
			recs.append(_rec(["U%05d" % serial, variant, converted, dates[i]], i))
			serial += 1
	return recs

func _base_competitor(rng: RandomNumberGenerator, spec: Dictionary, scale: float, dates: Array, lv: Array, info: Dictionary) -> Array:
	var recs: Array = []
	var base := 1.0
	for it in spec.items:
		if it.name == info.meta.item: base = float(it.base)
	var shops: Array = spec.shops.slice(0, mini(4, maxi(3, int(round(4 * (0.7 + scale * 0.3))))))
	for i in dates.size():
		for shop in shops:
			recs.append(_rec([dates[i], shop.name, info.meta.item, "USD", snappedf(base * (1.0 + float(shop.off)) * lv[i] * _noise(rng, float(spec.noise)), 0.01)], i))
	return recs

# ---------- dirt ----------
func _pick(rng: RandomNumberGenerator, pool: Array, k: int) -> Array:
	var copy := pool.duplicate()
	var out: Array = []
	for n in mini(k, copy.size()):
		out.append(copy.pop_at(rng.randi_range(0, copy.size() - 1)))
	return out

func _amount(rng: RandomNumberGenerator, defect: String, total: int) -> int:
	if cfg.dirt.count.has(defect):
		return rng.randi_range(int(cfg.dirt.count[defect][0]), int(cfg.dirt.count[defect][1]))
	var f: Array = cfg.dirt.fraction[defect]
	return maxi(2, int(round(total * lerpf(float(f[0]), float(f[1]), rng.randf()))))

func _mark(rec: Dictionary, defect: String, col_names: Array) -> void:
	if not rec.marks.has(defect): rec.marks[defect] = []
	for c in col_names:
		if not rec.marks[defect].has(c): rec.marks[defect].append(c)

func _cands(recs: Array, need_clean: bool = true) -> Array:
	var out: Array = []
	for i in recs.size():
		if recs[i].extra: continue
		if need_clean and recs[i].clean == null: continue
		out.append(i)
	return out

func _insert_extra(recs: Array, rng: RandomNumberGenerator, raw: Array, defect: String, col_names: Array, day_index: int) -> void:
	var positions: Array = []
	for i in recs.size():
		if recs[i].day == day_index: positions.append(i)
	var at: int = recs.size() if positions.is_empty() else positions[rng.randi_range(0, positions.size() - 1)] + 1
	var rec := {"raw":raw, "clean":null, "marks":{}, "day":day_index, "prot":false, "extra":true}
	_mark(rec, defect, col_names)
	recs.insert(at, rec)

func _extra_day(rng: RandomNumberGenerator, ctx: Dictionary) -> int:
	return rng.randi_range(0, int(ctx.complete_last))

func _col(name: String, col: String) -> int:
	return COLS[name].find(col)

func _inject(defect: String, recs: Array, rng: RandomNumberGenerator, ctx: Dictionary, recipe: Dictionary) -> void:
	var name: String = ctx.name
	var spec: Dictionary = ctx.spec
	var dc: int = _col(name, DATE_COL[name])
	var total: int = recs.size()
	match defect:
		"late_partial":
			var last: int = ctx.dates.size() - 1
			var idx: Array = []
			for i in recs.size():
				if recs[i].day == last: idx.append(i)
			var keep := maxi(1, int(ceil(float(cfg.late_keep) * idx.size())))
			var drop: Array = idx.slice(keep)
			drop.reverse()
			for i in drop: recs.remove_at(i)
			for i in idx.slice(0, keep):
				recs[i].clean = null
				_mark(recs[i], "late_partial", [DATE_COL[name]])
			recipe.last_date = ctx.dates[last]
		"outliers":
			var col: String = spec.outlier_col
			var c := _col(name, col)
			var pool := _cands(recs)
			var vals: Array = pool.map(func(i): return float(recs[i].clean[c]))
			vals.sort()
			var q1 := Ops.quantile(vals, 0.25)
			var q3 := Ops.quantile(vals, 0.75)
			var fence := q3 + 5.0 * maxf(q3 - q1, 0.05 * absf(q3))
			for i in _pick(rng, pool, _amount(rng, defect, total)):
				var v: float = float(recs[i].clean[c])
				var mult := 10.0
				while v * mult <= fence and mult < 100000.0: mult *= 10.0
				recs[i].raw[c] = int(v * mult) if TYPES[name][c] == "int" else v * mult
				recs[i].clean = null
				_mark(recs[i], "outliers", [col])
			recipe.outlier_col = col
		"missing_blank", "missing_na", "missing_zero":
			var options: Array = spec.missing_cols.filter(func(m): return defect != "missing_zero" or m.zero)
			var m: Dictionary = options[rng.randi_range(0, options.size() - 1)]
			var c := _col(name, m.col)
			var pool: Array = _cands(recs).filter(func(i):
				for k in recs[i].marks: if k.begins_with("missing"): return false
				return not (m.get("protect", "") != "" and recs[i].prot))
			for i in _pick(rng, pool, _amount(rng, defect, total)):
				match defect:
					"missing_blank": recs[i].raw[c] = ""
					"missing_na": recs[i].raw[c] = cfg.dirt.na_tokens[rng.randi_range(0, cfg.dirt.na_tokens.size() - 1)]
					_: recs[i].raw[c] = 0 if TYPES[name][c] == "int" else 0.0
				recs[i].clean = null if m.policy == "drop" else _filled(recs[i].clean, c, m.fill)
				_mark(recs[i], defect, [m.col])
			var entry := {"col":m.col, "mode":"drop" if m.policy == "drop" else "value", "fill":m.get("fill", ""), "zero":defect == "missing_zero"}
			var found := false
			for e in recipe.missing:
				if e.col == m.col:
					found = true
					e.zero = e.zero or entry.zero
			if not found: recipe.missing.append(entry)
		"refunds_negative":
			var n := _amount(rng, defect, total)
			for j in n:
				var di := _extra_day(rng, ctx)
				var uc: Array = ctx.dates
				_insert_extra(recs, rng, [uc[di], "RF-%05d" % (90001 + j), REGIONS[rng.randi_range(0, 3)], PRODUCTS.keys()[j % 3], -rng.randi_range(1, 2), snappedf(PRODUCTS.values()[j % 3] * 1.1, 0.01), "USD", CHANNELS[j % 3]], "refunds_negative", ["units"], di)
		"test_accounts":
			var n := _amount(rng, defect, total)
			var made: Array = []
			for j in n:
				var di := _extra_day(rng, ctx)
				var d: String = ctx.dates[di]
				var raw: Array = []
				var cols_marked: Array = []
				match name:
					"sales_export":
						raw = [d, "TST-%05d" % (j + 1), "Hanoi", "Widget", 1, 1.0, "USD", "internal_test"]
						cols_marked = ["channel"]
					"loan_book":
						raw = [d, "C%04d" % (9001 + j % 5), 100.0, 0, "current"]
						cols_marked = ["customer_id"]
					"support_tickets":
						raw = ["TST-%05d" % (j + 1), d, "billing", "low", "test ticket please ignore"]
						cols_marked = ["ticket_id"]
					"ab_test_log":
						raw = ["qa_user_%02d" % (j + 1), "B", 1, d]
						cols_marked = ["user_id"]
				_insert_extra(recs, rng, raw, "test_accounts", cols_marked, di)
		"join_key_mismatch":
			var tests: Array = []
			for r in recs:
				if r.extra and r.marks.has("test_accounts"): tests.append(r)
			var half := maxi(1, tests.size() / 2)
			for r in tests.slice(0, half):
				var id: String = r.raw[_col(name, "customer_id")]
				r.raw[_col(name, "customer_id")] = (" " + id.to_lower()) if int(id.substr(1)) % 2 == 1 else (id.to_lower() + " ")
				_mark(r, "join_key_mismatch", ["customer_id"])
		"category_typos":
			var col: String = spec.typo_cols[rng.randi_range(0, spec.typo_cols.size() - 1)]
			var c := _col(name, col)
			var vocab: Dictionary = spec.typos[col]
			var pool: Array = _cands(recs).filter(func(i): return vocab.has(recs[i].clean[c]) and not recs[i].marks.has("category_typos"))
			for i in _pick(rng, pool, _amount(rng, defect, total)):
				var variants: Array = vocab[recs[i].clean[c]]
				recs[i].raw[c] = variants[rng.randi_range(0, variants.size() - 1)]
				_mark(recs[i], "category_typos", [col])
			if not recipe.typo_cols.has(col): recipe.typo_cols.append(col)
		"mixed_units":
			if name in ["sales_export", "competitor_scrape"]:
				var pc := _col(name, "price")
				var cc := _col(name, "currency")
				var rate := 1.0 / float(cfg.vnd_per_usd)
				for i in _pick(rng, _cands(recs), _amount(rng, defect, total)):
					var vnd := int(round(float(recs[i].clean[pc]) * float(cfg.vnd_per_usd) / 1000.0)) * 1000
					if vnd < 1000: continue
					recs[i].raw[pc] = vnd
					recs[i].raw[cc] = "VND"
					recs[i].clean[pc] = float(vnd) * rate
					_mark(recs[i], "mixed_units", ["price", "currency"])
				recipe.currency = true
			else:
				var col := "value" if name == "market_prices" else "balance"
				var c := _col(name, col)
				var pool: Array = _cands(recs).filter(func(i): return float(recs[i].clean[c]) >= 1000.0)
				for i in _pick(rng, pool, _amount(rng, defect, total)):
					var v100: float = round(float(recs[i].clean[c]) / 100.0) * 100.0
					recs[i].raw[c] = "%.1fk" % (v100 / 1000.0)
					recs[i].clean[c] = v100
					_mark(recs[i], "mixed_units", [col])
				recipe.suffix_cols.append(col)
		"mixed_dates":
			var fmts: Array = cfg.dirt.date_formats
			for i in _pick(rng, _cands(recs), _amount(rng, defect, total)):
				var iso: String = recs[i].clean[dc]
				var y := int(iso.substr(0, 4))
				var mo := int(iso.substr(5, 2))
				var dd := int(iso.substr(8, 2))
				match fmts[rng.randi_range(0, fmts.size() - 1)]:
					"dmy": recs[i].raw[dc] = "%02d/%02d/%04d" % [dd, mo, y]
					"mon": recs[i].raw[dc] = "%s %d, %d" % [Ops.MONTHS[mo - 1].capitalize(), dd, y]
					"iso_tz": recs[i].raw[dc] = "%sT%02d:%02d:00%s" % [iso, rng.randi_range(0, 23), rng.randi_range(0, 59), cfg.dirt.tz[rng.randi_range(0, cfg.dirt.tz.size() - 1)]]
					_: recs[i].raw[dc] = "%04d%02d%02d" % [y, mo, dd]
				_mark(recs[i], "mixed_dates", [DATE_COL[name]])
		"duplicates":
			var pool: Array = _cands(recs).filter(func(i): return recs[i].marks.is_empty())
			var picks := _pick(rng, pool, _amount(rng, defect, total))
			picks.sort()
			picks.reverse()
			for i in picks:
				var copy := {"raw":recs[i].raw.duplicate(), "clean":null, "marks":{}, "day":recs[i].day, "prot":false, "extra":true}
				_mark(copy, "duplicates", COLS[name])
				recs.insert(i + 1, copy)
		"subtotal_rows":
			var days: Array = []
			for d in range(0, int(ctx.complete_last) + 1): days.append(d)
			for di in _pick(rng, days, _amount(rng, defect, total)):
				var raw: Array = []
				for c in COLS[name].size(): raw.append(null)
				raw[dc] = ctx.dates[di]
				raw[_col(name, ID_COL[name])] = "TOTAL"
				for sc in SUM_COLS[name]:
					var ci := _col(name, sc)
					var s := 0.0
					for r in recs:
						if r.day == di and not r.extra and r.clean != null: s += float(r.clean[ci])
					raw[ci] = s
				_insert_extra(recs, rng, raw, "subtotal_rows", [ID_COL[name]], di)
		"repeated_header":
			for j in _amount(rng, defect, total):
				_insert_extra(recs, rng, COLS[name].duplicate(), "repeated_header", [ID_COL[name]], rng.randi_range(0, recs[recs.size() - 1].day))

func _filled(clean: Variant, c: int, fill: String) -> Variant:
	var out: Array = clean.duplicate()
	out[c] = fill
	return out

# ---------- finalize ----------
func _finalize(name: String, day: int, index: int, recs: Array, info: Dictionary, recipe: Dictionary, lv: Array, variable: String, sign: float, complete_last: int, spec: Dictionary) -> Dictionary:
	var raw = DS.make(name, COLS[name], TYPES[name])
	var expected := {}
	var groups := {}
	var group_order: Array = []
	for i in recs.size():
		raw.add_row(recs[i].raw, i)
		expected[i] = recs[i].clean
		for defect in recs[i].marks:
			var cols_key: Array = recs[i].marks[defect]
			var key: String = defect + "|" + ",".join(cols_key)
			if not groups.has(key):
				groups[key] = {"type":defect, "columns":cols_key.duplicate(), "rows":[]}
				group_order.append(key)
			groups[key].rows.append(i)
	var manifest: Array = []
	for defect in cfg.dirt.order:
		for key in group_order:
			if groups[key].type == defect: manifest.append(groups[key])
	var pct := window_pct(lv, complete_last)
	var hidden := {"variable":variable, "sign":sign, "pct":pct, "direction":direction_of(pct), "band":band_of(pct), "state_direction":_dir_name(sign * _sign_of(_state(day - 1, variable).direction)), "complete_last":complete_last}
	if name == "ab_test_log": hidden["uplift"] = info.meta.uplift
	recipe["typo_maps"] = {}
	for col in recipe.typo_cols:
		var m := {}
		for canon in spec.typos[col]:
			for v in spec.typos[col][canon]: m[v] = canon
		recipe.typo_maps[col] = m
	var file := {"id":"%s_d%02d" % [name, day], "name":name, "title":spec.title, "day":day, "index":index, "raw":raw, "aux":info.aux, "manifest":manifest, "expected":expected, "recipe":recipe, "hidden":hidden, "meta":info.meta, "dirt_types":recipe.defects.duplicate()}
	return file

func _dir_name(signed: float) -> String:
	return "tang" if signed > 0 else ("giam" if signed < 0 else "ngang")

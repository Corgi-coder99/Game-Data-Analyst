extends RefCounted
# T-036: relevance of the day's files to the day's boss question (offline measurement, reads hidden state).
# A file is RELEVANT when it mirrors the question's target (variable, or the event's dataset).
# It AGREES when the answer read from the reference (cleaned) table's 7-day change, through the public
# reading rule of the question (Generator-independent copy below), equals the question's correct answer.
const Game = preload("res://scripts/world/world_game.gd")
const Generator = preload("res://scripts/data/generator.gd")
const Reference = preload("res://scripts/data/reference.gd")
const Loader = preload("res://scripts/data.gd")

# Question -> what a relevant file must mirror. q5 is an event question (the rival's discount shows in the
# competitor scrape); q8 (report integrity) has no data mirror.
const TARGET := {"q1":"nguyen_lieu", "q3":"lai_suat", "q4":"suc_mua", "q5":"@competitor_scrape", "q6":"tin_dung", "q8":"@web_funnel", "q9":"tin_dung"}
# Public reading thresholds (percent change of the file's metric, last 7 days vs the 7 before).
const DEAD := 2.0
const Q8_JUMP := 5.0
const Q9_RISE := 10.0
# Metric direction -> variable direction: the loan book's days past due move against credit health.
const SIGN := {"loan_book":-1.0}

static func is_relevant(file: Dictionary, qid: String) -> bool:
	var t: String = TARGET.get(qid, "")
	if t == "": return false
	if t.begins_with("@"): return file.name == t.substr(1)
	return file.name != "ab_test_log" and str(file.hidden.variable) == t

# PUBLIC reading rule (documented in PLAY-v2): the 7-day change of the relevant file -> forecast.
static func read_answer(qid: String, file_name: String, pct: float) -> String:
	var v := pct * float(SIGN.get(file_name, 1.0))
	match qid:
		"q5": return "tang" if pct <= -DEAD else "ngang"
		"q8": return "giam" if pct >= Q8_JUMP else "tang"
		"q9": return "giam" if pct >= Q9_RISE else "ngang"
	return "tang" if v >= DEAD else ("giam" if v <= -DEAD else "ngang")
static func measure(first_seed: int, seeds: int, horizon: int) -> Dictionary:
	var cfg: Dictionary = Loader.load_json("res://data/datasets.json")
	var ref := Reference.new(cfg)
	var out := {"days":0, "with_relevant":0, "agree":0, "agree_any_file":0, "by_q":{}, "by_day":{}, "by_name":{}}
	for s in seeds:
		var seed_value := first_seed + s
		var game := Game.new(seed_value, horizon)
		var sc: RefCounted = game._scenario
		var gen := Generator.new(sc, seed_value, cfg)
		for day in range(1, horizon + 1):
			var q: Dictionary = sc._questions[day - 1]
			var answer: String = sc._answers[day - 1]
			var files: Array = gen.generate(day)
			var row: Dictionary = out.by_q.get(q.id, {"days":0, "with_relevant":0, "agree":0})
			var drow: Dictionary = out.by_day.get(day, {"days":0, "with_relevant":0, "agree":0})
			out.days += 1
			row.days += 1
			drow.days += 1
			var relevant: Array = files.filter(func(f): return is_relevant(f, q.id))
			if not relevant.is_empty():
				out.with_relevant += 1
				row.with_relevant += 1
				drow.with_relevant += 1
				var f: Dictionary = relevant[0]
				var truth: Array = ref.evaluate_reference(f).truth
				var read := ""
				for t in truth:
					if t.id == "metric_change" and t.value != null: read = read_answer(q.id, f.name, float(t.value.pct))
				var nrow: Dictionary = out.by_name.get(f.name, {"days":0, "agree":0})
				nrow.days += 1
				if read == answer:
					out.agree += 1
					row.agree += 1
					drow.agree += 1
					nrow.agree += 1
				out.by_name[f.name] = nrow
			out.by_q[q.id] = row
			out.by_day[day] = drow
	return out

static func pct(a: int, b: int) -> float:
	return 100.0 * a / maxf(1.0, b)

static func print_report(r: Dictionary) -> void:
	print("RELEVANCE days=%d | days with a relevant file %.1f%% | agreement over all days %.1f%% | agreement on days with a relevant file %.1f%%" % [r.days, pct(r.with_relevant, r.days), pct(r.agree, r.days), pct(r.agree, r.with_relevant)])
	var qs: Array = r.by_q.keys()
	qs.sort()
	for q in qs:
		var row: Dictionary = r.by_q[q]
		print("  %s: days %d | relevant %.1f%% | agree(all) %.1f%% | agree(relevant) %.1f%%" % [q, row.days, pct(row.with_relevant, row.days), pct(row.agree, row.days), pct(row.agree, row.with_relevant)])
	var ds: Array = r.by_day.keys()
	ds.sort()
	for d in ds:
		var row: Dictionary = r.by_day[d]
		print("  day %d: relevant %.1f%% | agree(all) %.1f%%" % [d, pct(row.with_relevant, row.days), pct(row.agree, row.days)])
	for n in r.by_name:
		print("  file %s: used %d | agree %.1f%%" % [n, r.by_name[n].days, pct(r.by_name[n].agree, r.by_name[n].days)])

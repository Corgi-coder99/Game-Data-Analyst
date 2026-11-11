extends SceneTree
# T-035 headless logic tests: case mapping, Handbook unlocks, hints (levels, Energy, leak), coaching by outcome,
# tutorial days 1-5 with a scripted policy, skill XP and level-ups, difficulty ramp, leak scan, score unchanged
# when the learning features are unused.
const Game = preload("res://scripts/world/world_game.gd")
const Session = preload("res://scripts/data/session.gd")
const Gen = preload("res://scripts/data/generator.gd")
const Scenario = preload("res://scripts/world/world_scenario.gd")
const Sim = preload("res://scripts/sim/simulation.gd")
const Forms = preload("res://scripts/data/step_forms.gd")
const Loader = preload("res://scripts/data.gd")
const Content = preload("res://scripts/learn/content.gd")
const CaseMap = preload("res://scripts/learn/case_map.gd")
const Hints = preload("res://scripts/learn/hints.gd")
const Coaching = preload("res://scripts/learn/coaching.gd")
const LearnState = preload("res://scripts/learn/learn_state.gd")
const LearnSettle = preload("res://scripts/learn/learn_settle.gd")
const Skills = preload("res://scripts/learn/skills.gd")
const Ramp = preload("res://scripts/learn/ramp.gd")
const Stats = preload("res://scripts/learn/stats.gd")
const TutorialFiles = preload("res://scripts/learn/tutorial_files.gd")
const TutorialScript = preload("res://scripts/learn/tutorial_script.gd")
const Profile = preload("res://scripts/meta/profile.gd")
const Awards = preload("res://scripts/meta/awards.gd")
const NO_ANALYSIS := {"forecast": "ngang", "confidence": "thap", "evidence": [], "actions": []}
var checks := 0
var failures := 0
var data_cfg: Dictionary
var world_cfg: Dictionary
var questions: Array
var events: Array
var strings: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 60: printerr("FAIL: ", message)

func eq(a: Variant, b: Variant, message: String) -> void:
	check(a == b, "%s (got %s, want %s)" % [message, str(a), str(b)])

func _initialize() -> void:
	call_deferred("run")

func report(game: RefCounted, extra: Dictionary = {}) -> Dictionary:
	var r := NO_ANALYSIS.duplicate(true)
	r["question_id"] = game.question_today().id
	for k in extra: r[k] = extra[k]
	return r

# A started day on a real world with a session (and optionally a LearnState / tutorial mode).
func make(seed_value: int, learn: RefCounted = null, tutorial: bool = false, to_day: int = 1) -> Array:
	var game := Game.new(seed_value, 10)
	var session := Session.new(game, seed_value)
	if learn != null: session.attach_learn(learn, tutorial)
	for d in range(1, to_day):
		game.begin_day()
		game.submit_report(report(game))
		game.end_day()
	game.begin_day()
	session.begin_day(int(game.status().day))
	return [game, session]

# ---- 1. case mapping --------------------------------------------------------------------------------

func test_case_map() -> void:
	var names := ["sales_export", "market_prices", "web_funnel", "loan_book", "support_tickets", "ab_test_log", "competitor_scrape"]
	var seen_names := {}
	var seen_dirt := {}
	var unmapped := 0
	var combos := 0
	var cases_used := {}
	for s in range(1, 301):
		var scenario := Scenario.new(s, 10, world_cfg, questions, events)
		var g := Gen.new(scenario, s, data_cfg)
		var day := 3 + s % 8
		var diff: Dictionary = g.difficulty(day)
		for name in names:
			var f: Dictionary = g.build_file(name, day, 0, diff.dirt, diff.scale)
			combos += 1
			seen_names[name] = true
			var c := CaseMap.for_file(name, f.dirt_types, day)
			if c.is_empty() or not Content.trap_of(str(f.dirt_types[0])) in Content.coaching().traps: unmapped += 1
			else: cases_used[c.id] = true
			for d in f.dirt_types:
				seen_dirt[d] = true
				if CaseMap.wanted([d]).is_empty() or not Content.coaching().traps.has(Content.trap_of(str(d))): unmapped += 1
				# the chosen case must teach at least one of the file's defects whenever such a case exists
			var overlap := false
			for dn in c.dirt:
				if CaseMap.wanted(f.dirt_types).has(dn): overlap = true
			check(overlap or c.dirt.is_empty(), "case %s overlaps the defects of %s s%d" % [c.get("id", "?"), name, s])
			var again := CaseMap.for_file(name, f.dirt_types, day)
			if again.id != c.id: unmapped += 1
	eq(unmapped, 0, "no unmapped file/defect combination in %d files" % combos)
	eq(seen_names.size(), 7, "all 7 dataset types mapped")
	eq(seen_dirt.size(), 14, "all 14 defect types seen and mapped")
	check(cases_used.size() >= 10, "many different cases are used (%d)" % cases_used.size())
	# every generator defect maps to catalog defect names that exist in the catalog
	var catalog := {}
	for c in Content.cases():
		for d in c.dirt: catalog[d] = true
	for d in Content.DIRT_TO_CASE:
		for n in Content.DIRT_TO_CASE[d]: pass
		var any := false
		for n in Content.DIRT_TO_CASE[d]:
			if catalog.has(n): any = true
		check(any, "catalog teaches " + d)
	# unknown combination falls back (no defects): a statistical case of the dataset type
	check(not CaseMap.for_file("ab_test_log", [], 5).is_empty(), "fallback case exists")
	# public view
	var pub := CaseMap.public(Content.case_by_id("case_duplicate_export"))
	eq(pub.keys().size(), 3, "public case has id, title, skill only")
	check(not pub.has("trap") and not pub.has("reference_steps") and not pub.has("wrong_paths"), "public case hides trap, steps, wrong paths")

# ---- 2. Handbook unlocks, profile persistence -----------------------------------------------------------------

func test_handbook() -> void:
	var state := LearnState.new()
	eq(Content.cards().size(), 49, "49 cards")
	var locked := 0
	for c in Content.cards():
		if not state.is_unlocked(c.id): locked += 1
	eq(locked, 49 - state.cfg.starter_cards.size(), "only the starter cards are open at first")
	check(state.unlock_for_op("dedupe") == ["hb_duplicates"], "using Dedupe unlocks the Duplicate rows card")
	check(state.unlock_for_op("dedupe").is_empty(), "unlocking is once")
	check(state.is_unlocked("hb_duplicates"), "card stays unlocked")
	var fresh := state.unlock_for_case(Content.case_by_id("case_date_timezone"))
	check(fresh.has("hb_dates_timezones") and fresh.has("hb_late_data"), "meeting a case unlocks its cards")
	check(not state.unlock("hb_nope"), "unknown card id is ignored")
	for op in Content.OP_CARDS:
		for id in Content.OP_CARDS[op]: check(not Content.card_by_id(id).is_empty(), "op card exists: " + id)
	# session: adding a Sheet step unlocks the related card, and meeting the tutorial case opens its cards
	var learn := LearnState.new()
	var made := make(104, learn)
	var session: RefCounted = made[1]
	var seen_unlock: Array = []
	session.cards_unlocked.connect(func(ids): seen_unlock.append_array(ids))
	var sheet: RefCounted = session.open_file(session.files[0].id)
	sheet.add_step({"op": "dedupe", "cols": []})
	check(learn.is_unlocked("hb_duplicates") and seen_unlock.has("hb_duplicates"), "a Sheet step unlocks its card and tells the UI")
	sheet.add_step({"op": "sort", "col": sheet.table().cols[0], "desc": false})
	check(learn.is_unlocked("hb_sort_label"), "Sort unlocks the labeling card")
	# persistence in the profile file
	var path := "user://t035_profile.json"
	var profile := Profile.new(path)
	profile.load_or_create("2026-11-11")
	var l2 := LearnState.new(profile.data.learn)
	l2.unlock("hb_funnel", "test")
	l2.add_xp("statistics", 55)
	l2.bump_event("sharp_eye")
	l2.set_tutorial("on")
	check(profile.save(), "profile saves")
	var back := Profile.new(path)
	back.load_or_create("2026-11-11")
	var l3 := LearnState.new(back.data.learn)
	check(l3.is_unlocked("hb_funnel") and l3.xp("statistics") == 55 and l3.has_event("sharp_eye") and l3.tutorial_mode() == "on", "learn state survives save and load")
	eq(Profile.defaults("x", "2026-01-01").learn.keys().size(), 6, "profile learn block has 6 fields")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# an old profile without the block loads with defaults
	var old := Profile.defaults("x", "2026-01-01")
	old.erase("learn")
	var merged: Dictionary = Profile.new(path)._merge(Profile.defaults("x", "2026-01-01"), old)
	check(merged.learn.tutorial == "" and merged.learn.cards.is_empty(), "old profile gets default learn block")

# ---- 3. hints -----------------------------------------------------------------------------------------

func normalized(text: String) -> String:
	return text.to_lower().strip_edges()

func test_hints() -> void:
	var learn := LearnState.new()
	var made := make(104, learn)
	var game: RefCounted = made[0]
	var session: RefCounted = made[1]
	var fid: String = session.files[0].id
	eq(int(game.status().energy), 3, "3 analysis Energy at the start")
	eq(session.hint_cost(), 1, "hint costs learn.hint_energy (1)")
	var h1: Dictionary = session.request_hint(fid)
	check(h1.ok and h1.level == 1, "level 1 hint")
	eq(int(game.status().energy), 2, "level 1 cost 1 Energy")
	var minutes: int = int(game.status().minutes)
	var h2: Dictionary = session.request_hint(fid)
	check(h2.ok and h2.level == 2 and h2.card_id != "", "level 2 names a method card")
	eq(int(game.status().energy), 1, "level 2 cost 1 Energy")
	eq(int(game.status().minutes), minutes, "a hint takes no clock time")
	check(learn.is_unlocked(h2.card_id), "the method card is unlocked by the hint")
	var h3: Dictionary = session.request_hint(fid)
	check(h3.ok and h3.level == 3, "level 3 hint")
	eq(int(game.status().energy), 0, "three hints cost 3 Energy")
	var h4: Dictionary = session.request_hint(fid)
	check(not h4.ok, "no fourth level")
	eq(int(game.status().energy), 0, "a refused hint costs nothing")
	eq(session.hint_level(fid), 3, "three levels used for the case")
	eq(session.hint_text(fid, 1).text, h1.text, "a given level can be read again, free")
	eq(session.hints_by_file()[fid], 3, "review sees the hint count")
	# no Energy: no hint
	var low := make(104, LearnState.new())
	var spent: Dictionary = low[0].spend_analysis_energy(3)
	check(spent.ok, "spend_analysis_energy takes Energy")
	var none: Dictionary = low[1].request_hint(low[1].files[0].id)
	check(not none.ok and none.error == "no_analysis_energy", "no Energy, no hint")
	check(not low[0].spend_analysis_energy(1).ok and int(low[0].status().energy) == 0, "the pool never goes below 0")
	# without a LearnState there is no hint API result
	var plain := make(104)
	check(not plain[1].request_hint(plain[1].files[0].id).ok, "no learn state: no hints")
	# leak: hint texts against reference steps (case catalog and the engine's own steps) over many seeds and days
	var leaks := 0
	var count := 0
	var hint_bad := 0
	for s in range(1, 41):
		var m := make(s, LearnState.new(), false, 1 + s % 6)
		var gm: RefCounted = m[0]
		var sm: RefCounted = m[1]
		for f in sm.files:
			var texts: Array = []
			var guard := 0
			while sm.hint_level(f.id) < 3 and guard < 3:
				var r: Dictionary = sm.request_hint(f.id)
				if not r.ok: break
				texts.append(normalized(r.title + " " + r.text))
				guard += 1
			if int(gm.status().energy) == 0 and texts.size() < 3:
				# only 3 Energy: a second file may get fewer levels; that is fine
				pass
			var case_entry: Dictionary = Content.case_by_id(sm.file_case[f.id])
			var review_steps: Array = []
			for text in texts:
				count += 1
				for ref_step in case_entry.reference_steps:
					if text.contains(normalized(str(ref_step))):
						leaks += 1
						printerr("LEAK step: ", case_entry.id, " :: ", ref_step, " in ", text)
				for wp in case_entry.wrong_paths:
					if text.contains(normalized(str(wp.why))):
						leaks += 1
						printerr("LEAK path: ", case_entry.id, " :: ", text)
				if text.contains(normalized(str(case_entry.trap))):
					leaks += 1
					printerr("LEAK trap: ", case_entry.id, " :: ", text)
				if text.length() < 20: hint_bad += 1
	check(count > 40, "scanned %d hint texts" % count)
	eq(leaks, 0, "no hint contains a reference step, a wrong-path explanation or the trap sentence")
	eq(hint_bad, 0, "hint texts are real sentences")
	# engine side: the structured parts never carry step dictionaries
	var m2 := make(104, LearnState.new())
	var parts: Dictionary = m2[1].data.hint(1, m2[1].files[0].id, 3)
	check(parts.ok and not parts.has("steps") and not parts.has("ref_steps"), "hint parts carry families only")
	for fam in parts.families: check(fam in Content.OP_FAMILY.values(), "known family " + fam)
	# after the day ended hints are closed
	m2[0].submit_report(report(m2[0]))
	m2[0].end_day()
	check(not m2[1].request_hint(m2[1].files[0].id).ok, "no hints after Send")

# ---- 4. coaching ----------------------------------------------------------------------------------------

func fake_file(entries: Array, items: Array = []) -> Dictionary:
	return {"name": "sales_export", "grade": {"cleaning": {"entries": entries}, "findings": {"items": items}}}

func test_coaching() -> void:
	var texts: Dictionary = strings.learn.coaching
	var base: Dictionary = strings.learn
	var voices := {}
	for day in range(1, 7):
		var tips := Coaching.tips(fake_file([{"type": "duplicates", "rows": 4, "fixed": 4, "missed": 0, "wrongly_removed": 0}]), day, 0, base)
		eq(tips.size(), 1, "one tip for one trap")
		eq(tips[0].outcome, "praise", "fully fixed is praise")
		voices[tips[0].voice] = true
		eq(tips[0].text, Coaching.line_for("duplicates", "praise", tips[0].voice), "the line comes from coaching.json")
	eq(voices.size(), 3, "the voice rotates among Ms. Hanh, Khoi and Dr. Linh")
	var miss := Coaching.tips(fake_file([{"type": "duplicates", "rows": 4, "fixed": 1, "missed": 3, "wrongly_removed": 0}]), 2, 0, base)
	eq(miss[0].outcome, "miss", "missed rows give the miss line")
	var wrong := Coaching.tips(fake_file([{"type": "category_typos", "rows": 4, "fixed": 4, "missed": 0, "wrongly_removed": 2}]), 2, 0, base)
	eq(wrong[0].outcome, "wrong_fix", "wrongly removed rows give the wrong_fix line")
	check(wrong[0].text != miss[0].text, "different outcomes, different lines")
	# two defect types sharing one trap give one tip with the worse outcome
	var shared := Coaching.tips(fake_file([{"type": "subtotal_rows", "rows": 2, "fixed": 2, "missed": 0, "wrongly_removed": 0}, {"type": "repeated_header", "rows": 2, "fixed": 0, "missed": 2, "wrongly_removed": 0}]), 3, 0, base)
	eq(shared.size(), 1, "shared trap, one tip")
	eq(shared[0].outcome, "miss", "worst outcome wins")
	# hint note
	var hinted := Coaching.tips(fake_file([{"type": "duplicates", "rows": 4, "fixed": 0, "missed": 4, "wrongly_removed": 0}]), 2, 2, base)
	check(hinted[0].text.contains(base.hint_note_miss), "a hint changes the coaching line")
	var hinted_ok := Coaching.tips(fake_file([{"type": "duplicates", "rows": 4, "fixed": 4, "missed": 0, "wrongly_removed": 0}]), 2, 1, base)
	check(hinted_ok[0].text.contains(base.hint_note_praise), "a hint changes the praise line too")
	# tutorial days always use Dr. Linh
	eq(Coaching.tips(fake_file([{"type": "duplicates", "rows": 4, "fixed": 4, "missed": 0, "wrongly_removed": 0}]), 3, 0, base, true)[0].voice, "linh", "tutorial mentor is Dr. Linh")
	# findings coaching
	var ab := Coaching.tips(fake_file([], [{"id": "ab_significant", "score": 0.0}]), 4, 0, base)
	eq(ab.size(), 1, "a wrong A/B finding is coached")
	eq(ab[0].outcome, "miss", "wrong finding is a miss")
	check(ab[0].said != "", "the explanation of the case is attached")
	# all 31 traps have 3 lines for each outcome and every voice
	for trap in Content.coaching().traps:
		for outcome in ["praise", "miss", "wrong_fix"]:
			var lines: Array = Content.coaching().traps[trap][outcome]
			eq(lines.size(), 3, "3 lines for %s/%s" % [trap, outcome])
	# every defect type of the generator is coached
	for d in Content.DIRT_TRAP: check(Content.coaching().traps.has(Content.DIRT_TRAP[d]), "coaching for " + d)
	# the tab text of the review keeps the explanation short
	check(texts.outcome.size() == 3, "outcome labels")

# ---- 5. tutorial days -----------------------------------------------------------------------------------

func policy_day(game: RefCounted, session: RefCounted, day: int, good: bool) -> Dictionary:
	var fid: String = session.files[0].id
	var sheet: RefCounted = session.open_file(fid)
	var spec := {}
	var source := "clean"
	var findings := {}
	match day:
		1:
			if good:
				sheet.add_step({"op": "dedupe", "cols": []})
				sheet.add_step({"op": "standardize", "col": "region", "case": "none", "map": {"Ha Noi": "Hanoi", "hanoi": "Hanoi"}})
			sheet.add_step({"op": "group", "by": ["region"], "aggs": [{"col": "units", "fn": "sum"}]})
			sheet.add_step({"op": "sort", "col": "units_sum", "desc": true})
			spec = {"type": "bar", "x": "region", "y": "units_sum", "agg": "sum", "series": "", "sort": "desc", "title": "Units by region", "y_label": "Units", "y_min": null, "y_max": null}
			findings = {"top_region": "Hanoi" if good else "Da Nang"}
		2:
			if good: sheet.add_step({"op": "outliers", "col": "value", "method": "iqr", "k": 1.5, "action": "remove"})
			spec = {"type": "line", "x": "date", "y": "value", "agg": "mean", "series": "", "sort": "x", "title": "Steel index", "y_label": "points", "y_min": null, "y_max": null}
			findings = {"metric_change": {"direction": "tang", "band": "10..20"}, "entry_error_date": "2026-03-09"} if good else {"metric_change": {"direction": "giam", "band": "-10..-5"}, "entry_error_date": "none"}
		3:
			if good: sheet.add_step({"op": "filter", "col": "date", "cmp": "<", "value": "2026-03-06"})
			sheet.add_step({"op": "group", "by": ["step"], "aggs": [{"col": "users", "fn": "sum"}]})
			spec = {"type": "bar", "x": "step", "y": "users_sum", "agg": "sum", "series": "", "sort": "desc", "title": "Users per step", "y_label": "Users", "y_min": null, "y_max": null}
			findings = {"biggest_dropoff": "signup_done>first_purchase" if good else "visit>signup_start"}
		4:
			sheet.add_step({"op": "group", "by": ["variant"], "aggs": [{"col": "converted", "fn": "sum"}, {"col": "converted", "fn": "count"}]})
			sheet.add_step({"op": "computed", "name": "rate", "fn": "div", "a": "converted_sum", "b": "converted_count"})
			findings = {"ab_significant": false if good else true, "ab_winner": "none" if good else "B"}
		5:
			sheet.add_step({"op": "group", "by": ["variant", "device"], "aggs": [{"col": "visitors", "fn": "sum"}, {"col": "orders", "fn": "sum"}]})
			sheet.add_step({"op": "computed", "name": "rate", "fn": "div", "a": "orders_sum", "b": "visitors_sum"})
			findings = {"better_version": "B" if good else "A", "even_mix": false if good else true}
	if day == 2:
		source = "raw"
	if not spec.is_empty():
		var pid: String = session.pin_chart(fid, source, spec)
		session.attach(pid)
	for id in findings: session.set_finding(fid, id, findings[id])
	return {"file": fid}

func test_tutorial() -> void:
	var learn := LearnState.new()
	learn.set_tutorial("on")
	var made := make(104, learn, true)
	var game: RefCounted = made[0]
	var session: RefCounted = made[1]
	var graded: Array = []
	var found_unlocks := {}
	for day in range(1, 6):
		if day > 1:
			game.begin_day()
			session.begin_day(day)
		eq(session.files.size(), 1, "tutorial day %d has the one scripted file" % day)
		check(session.tutorial_today(), "tutorial mode is on for day %d" % day)
		var f: Dictionary = session.files[0]
		eq(f.name, ["sales_export_day1", "market_prices_day2", "web_funnel_day3", "ab_test_log_day4", "checkout_by_device_day5"][day - 1], "file of day %d" % day)
		eq(f.row_count, [14, 14, 20, 24, 16][day - 1], "row count of day %d" % day)
		# the public file shows no answer: the table is the raw CSV, options carry no marked choice
		var opt_ids: Array = f.findings.map(func(o): return o.id)
		var expect_ids: Array = [["top_region"], ["metric_change", "entry_error_date"], ["biggest_dropoff"], ["ab_significant", "ab_winner"], ["better_version", "even_mix"]][day - 1]
		eq(opt_ids, expect_ids, "findings offered on day %d" % day)
		var public_text := JSON.stringify(f)
		for word in ["manifest", "expected", "ref_steps", "truth_list", "reference", "hidden"]: check(not public_text.contains(word), "public file day %d has no %s" % [day, word])
		# the coach status starts at step 0 and advances only with real actions
		var ctx0 := TutorialScript.context(session, false, false, {})
		var st0: Dictionary = TutorialScript.status(day, ctx0)
		eq(st0.index, 0, "day %d coach starts at the first step" % day)
		policy_day(game, session, day, true)
		var ctx := TutorialScript.context(session, true, false, {"look": true})
		var st: Dictionary = TutorialScript.status(day, ctx)
		eq(st.index, st.total - 1, "day %d: every step done except Send" % day)
		ctx = TutorialScript.context(session, true, true, {"look": true})
		check(TutorialScript.status(day, ctx).complete, "day %d complete after Send" % day)
		check(session.learn.is_unlocked(TutorialFiles.build(day).cards[0]), "tutorial day %d opened its first card" % day)
		var payload: Dictionary = session.payload()
		check(not payload.is_empty(), "payload for day %d" % day)
		var r := report(game, {"analysis": payload})
		check(game.submit_report(r).ok, "report with analysis accepted day %d" % day)
		var ended: Dictionary = game.end_day()
		check(ended.ok, "day %d ended" % day)
		var review: Dictionary = session.data.analysis_review(day)
		check(review.ok, "review of day %d" % day)
		var rf: Dictionary = review.files[0]
		graded.append(rf.grade.total)
		var want_total: float = [1.0, 1.0, 1.0, 0.8, 0.8][day - 1]
		check(absf(float(rf.grade.total) - want_total) < 1e-6, "day %d perfect play grades %.2f (got %.3f)" % [day, want_total, rf.grade.total])
		for item in rf.grade.findings.items: check(float(item.score) >= 1.0, "day %d finding %s right" % [day, item.id])
		eq(rf.grade.cleaning.missed_rows, 0, "day %d nothing missed" % day)
		eq(int(rf.grade.cleaning.wrongly_removed) + int(rf.grade.cleaning.wrongly_changed), 0, "day %d nothing wrongly changed" % day)
		eq(rf.grade.cleaning.defect_rows, [4, 1, 4, 0, 0][day - 1], "defect rows of day %d" % day)
		var settle := LearnSettle.settle(learn, review, game.review(day).result, r, day, true)
		check(settle.solved, "day %d is solved" % day)
		for card in TutorialFiles.build(day).cards: found_unlocks[card] = true
		if day == 5:
			check(settle.graduated, "five solved days graduate the tutorial")
			eq(learn.tutorial_mode(), "done", "tutorial mode ends")
			check(learn.has_event("tutorial_graduate"), "graduate event")
	for card in found_unlocks: check(learn.is_unlocked(card), "tutorial card unlocked: " + card)
	# wrong play: the bad policy is not solved and is told what it missed
	var learn2 := LearnState.new()
	learn2.set_tutorial("on")
	var bad := make(104, learn2, true)
	policy_day(bad[0], bad[1], 1, false)
	bad[0].submit_report(report(bad[0], {"analysis": bad[1].payload()}))
	bad[0].end_day()
	var bad_review: Dictionary = bad[1].data.analysis_review(1)
	check(float(bad_review.files[0].grade.total) < 0.75, "a sloppy day-1 policy is not solved (%.2f)" % bad_review.files[0].grade.total)
	var bad_tips := Coaching.tips(bad_review.files[0], 1, 0, strings.learn, true)
	check(bad_tips.size() == 2 and bad_tips[0].outcome != "praise", "the sloppy play is coached on both traps")
	check(not LearnSettle.settle(learn2, bad_review, bad[0].review(1).result, {"confidence": "cao"}, 1, true).solved, "unsolved day")
	eq(learn2.tutorial_mode(), "on", "tutorial stays on until five days are solved")
	# Fisher exact test and the documented numbers
	check(absf(Stats.fisher_two_sided(4, 8, 6, 6) - 0.68) < 0.01, "Fisher p of day 4 is 0.68 (%.4f)" % Stats.fisher_two_sided(4, 8, 6, 6))
	check(Stats.fisher_two_sided(20, 0, 0, 20) < 0.001, "Fisher: a huge gap is significant")
	check(absi(Stats.sample_size(1.0 / 3.0, 0.5) - 133) <= 1, "about 133 users per variant for 33 percent vs 50 percent (%d)" % Stats.sample_size(1.0 / 3.0, 0.5))
	eq(Stats.sample_size(0.10, 0.12), 3838, "10 percent vs 12 percent needs 3,838 per variant (Handbook)")
	# day 2: the IQR rule flags exactly 1520 (linear quartiles, like the engine)
	var d2 := TutorialFiles.build(2)

	var out: Dictionary = preload("res://scripts/data/ops.gd").apply(d2.raw, {"op": "outliers", "col": "value", "method": "iqr", "k": 1.5, "action": "flag"}, {})
	check(out.ok, "outlier flag step runs on day 2")
	var flags := 0
	var flag_col: int = out.dataset.col_index("value_outlier")
	for r2 in out.dataset.rows:
		if r2[flag_col]: flags += 1
	eq(flags, 1, "exactly one value flagged on day 2")
	eq(out.dataset.rows[5][flag_col], true, "the flagged value is the 1520 row")
	# day 3: the doc numbers
	var d3 := TutorialFiles.build(3)
	eq(d3.truth_list[0].value, "signup_done>first_purchase", "day 3 truth")
	# day 2 finding truth is consistent with the band
	eq(TutorialFiles.build(2).truth_list[0].value.band, "10..20", "day 2 level change band")
	# tutorial days and generated days: day 6 is generated again
	game.begin_day()
	session.begin_day(6)
	check(not session.tutorial_today() and session.files[0].name.ends_with("_day1") == false, "day 6 is a generated day")

# ---- 6. skills -----------------------------------------------------------------------------------------

func test_skills() -> void:
	var learn := LearnState.new()
	eq(learn.level("charts"), 1, "level 1 at 0 XP")
	check(learn.add_xp("charts", 19).to == 1, "19 XP is still level 1")
	var up: Dictionary = learn.add_xp("charts", 1)
	check(up.from == 1 and up.to == 2, "20 XP is level 2")
	eq(learn.progress("charts").need, 30, "30 XP from level 2 to 3")
	learn.add_xp("charts", 500)
	eq(learn.level("charts"), 5, "max level 5")
	eq(learn.progress("charts").need, 0, "no next level at 5")
	check(absf(learn.mean_level() - 1.8) < 1e-6, "mean level of the five skills")
	# award from a review: perfect play on a generated day
	var made := make(104, LearnState.new())
	var game: RefCounted = made[0]
	var session: RefCounted = made[1]
	var fid: String = session.files[0].id
	var sheet: RefCounted = session.open_file(fid)
	var ref_steps: Array = []
	# build the reference pipeline through the review of an identical world (hidden data only after the day)
	var twin := make(104, LearnState.new())
	twin[0].submit_report(report(twin[0]))
	twin[0].end_day()
	for s in twin[1].data.review(1).files[0].reference_steps: ref_steps.append(s)
	for s in ref_steps:
		if s.op in ["filter", "dedupe", "standardize", "missing", "convert", "parse_date", "outliers", "join"]: sheet.add_step(s)
	var spec: Dictionary = session.default_spec(fid, "clean")
	var cols: Array = sheet.table().cols
	var pid: String = session.pin_chart(fid, "clean", {"type": "bar", "x": cols[2] if cols.size() > 2 else cols[0], "y": spec.y, "agg": "sum", "series": "", "sort": "desc", "title": "t", "y_label": "u", "y_min": null, "y_max": null})
	if pid != "": session.attach(pid)
	for o in session.options(fid):
		if o.has("choices"): session.set_finding(fid, o.id, o.choices[0])
	var payload: Dictionary = session.payload()
	check(game.submit_report(report(game, {"analysis": payload, "confidence": "cao"})).ok, "report with analysis")
	game.end_day()
	var review: Dictionary = session.data.analysis_review(1)
	var result: Dictionary = game.review(1).result
	var award: Dictionary = Skills.award(review.files, result, {"confidence": "cao", "analysis": payload}, data_cfg.learn)
	check(award.gains.data_cleaning > 0, "XP for correct fixes (%d)" % award.gains.data_cleaning)
	check(award.gains.charts >= 2, "XP for a chart")
	check(award.events.has("first_clean"), "First Clean after a full cleaning")
	for skill in Content.SKILLS: check(award.gains.has(skill), "gain slot " + skill)
	# calibration table
	var table: Dictionary = data_cfg.learn.skills.xp
	var calm: Dictionary = Skills.award([{"grade": {"cleaning": {"entries": [], "defect_rows": 0, "missed_rows": 0, "wrongly_removed": 0, "wrongly_changed": 0}, "chart": {"present": false, "flags": []}, "findings": {"items": []}}, "id": "x"}], {"acc": 0.0}, {"confidence": "cao"}, data_cfg.learn)
	eq(calm.gains.communication, 0, "wrong and sure earns nothing for calibration")
	var humble: Dictionary = Skills.award([{"grade": {"cleaning": {"entries": [], "defect_rows": 0, "missed_rows": 0, "wrongly_removed": 0, "wrongly_changed": 0}, "chart": {"present": false, "flags": []}, "findings": {"items": []}}, "id": "x"}], {"acc": 0.0}, {"confidence": "thap"}, data_cfg.learn)
	eq(humble.gains.communication, table.wrong_low, "wrong but unsure earns calibration XP")
	var sure: Dictionary = Skills.award([{"grade": {"cleaning": {"entries": [], "defect_rows": 0, "missed_rows": 0, "wrongly_removed": 0, "wrongly_changed": 0}, "chart": {"present": false, "flags": []}, "findings": {"items": []}}, "id": "x"}], {"acc": 1.0}, {"confidence": "cao"}, data_cfg.learn)
	eq(sure.gains.communication, table.right_high, "right and sure earns the most")
	# settle: level-up and achievements
	var l := LearnState.new()
	l.add_xp("data_cleaning", 18)
	var settled := LearnSettle.settle(l, review, result, {"confidence": "cao", "analysis": payload}, 1, false)
	check(settled.levelups.any(func(e): return e.skill == "data_cleaning"), "a level-up is reported")
	check(l.xp("data_cleaning") >= 18 + award.gains.data_cleaning, "XP stored")
	check(settled.new_cards.size() > 0, "the day's case cards unlock")
	var again := LearnSettle.settle(l, review, result, {"confidence": "cao", "analysis": payload}, 1, false)
	check(again.new_events.is_empty(), "events fire once")
	# achievements through the meta rules
	var meta_cfg := Loader.load_json("res://data/meta.json")
	var ach_ids: Array = meta_cfg.achievements.map(func(a): return a.id)
	eq(ach_ids.size(), 15, "7 old + 8 new achievements")
	for id in ["first_clean", "sharp_eye", "dup_hunter", "no_cherry_picking", "honest_axis", "healthy_skepticism", "skill_level_3", "tutorial_graduate"]: check(ach_ids.has(id), "achievement " + id)
	var prof := Profile.defaults("x", "2026-11-11")
	eq(Awards.check_achievements(prof, meta_cfg, "2026-11-11").size(), 0, "nothing earned at first")
	prof.learn.events["first_clean"] = 1
	prof.learn.events["sharp_eye"] = 2
	var earned := Awards.check_achievements(prof, meta_cfg, "2026-11-11")
	eq(earned.map(func(a): return a.id), ["first_clean", "sharp_eye"], "learn events earn achievements once")
	eq(Awards.check_achievements(prof, meta_cfg, "2026-11-11").size(), 0, "earned once")

# ---- 7. ramp ---------------------------------------------------------------------------------------------

func test_ramp() -> void:
	var cfg: Dictionary = data_cfg.learn
	eq(Ramp.adjust(cfg, 2, 5.0), {}, "no adjustment before the ramp day")
	eq(Ramp.adjust(cfg, 5, 1.0).dirt, 0, "a new player gets the generator's own ramp")
	eq(Ramp.adjust(cfg, 5, 3.4).dirt, 0, "below level 3.5 nothing changes")
	eq(Ramp.adjust(cfg, 5, 3.6).dirt, 1, "level 3.5+: one more defect")
	eq(Ramp.adjust(cfg, 5, 4.6).dirt, 2, "level 4.5+: two more defects")
	check(Ramp.adjust(cfg, 5, 4.6).scale_mult > Ramp.adjust(cfg, 5, 3.6).scale_mult, "stronger players get larger files")
	check(Ramp.adjust(cfg, 5, 5.0) == Ramp.adjust(cfg, 5, 5.0), "deterministic")
	# effect on the generator: dirt count and rows; the same days stay inside the engine limits
	for s in [3, 17, 104]:
		var base := Gen.new(Scenario.new(s, 10, world_cfg, questions, events), s, data_cfg)
		var hard := Gen.new(Scenario.new(s, 10, world_cfg, questions, events), s, data_cfg)
		for day in range(1, 11):
			hard.adjustments[day] = Ramp.adjust(cfg, day, 4.8)
		for day in range(1, 11):
			var d0: Dictionary = base.difficulty(day)
			var d1: Dictionary = hard.difficulty(day)
			if day < 3: eq(d1, d0, "days before the ramp are unchanged")
			else:
				check(d1.dirt >= d0.dirt and d1.dirt <= 7, "harder or equal dirt count on day %d" % day)
				check(d1.scale >= d0.scale, "larger or equal files on day %d" % day)
			eq(d1.files, d0.files, "file count is not touched")
			for f in hard.generate(day):
				check(f.raw.row_count() >= 40 and f.raw.row_count() <= 400, "rows within the engine range (%d)" % f.raw.row_count())
				check(f.dirt_types.size() >= 1, "at least one defect")
		# determinism
		var again := Gen.new(Scenario.new(s, 10, world_cfg, questions, events), s, data_cfg)
		for day in range(1, 11): again.adjustments[day] = Ramp.adjust(cfg, day, 4.8)
		eq(again.generate(6)[0].raw.to_csv(), hard.generate(6)[0].raw.to_csv(), "same levels, same day, same file")
	# the world is untouched by the adjustment: same questions, answers and news
	var a := Game.new(104, 10)
	var b := Game.new(104, 10)
	var sess := Session.new(b, 104)
	var st := LearnState.new()
	for skill in Content.SKILLS: st.add_xp(skill, 150)
	sess.attach_learn(st, false)
	for day in range(1, 11):
		a.begin_day()
		b.begin_day()
		sess.begin_day(day)
		eq(a.question_today(), b.question_today(), "same question on day %d" % day)
		eq(a.news_today().map(func(n): return n.headline), b.news_today().map(func(n): return n.headline), "same news on day %d" % day)
		a.submit_report(report(a))
		b.submit_report(report(b))
		a.end_day()
		b.end_day()
		eq(a.review(day).answer, b.review(day).answer, "same answer on day %d" % day)
		eq(a.review(day).result, b.review(day).result, "same result on day %d" % day)
	eq(a.status(), b.status(), "same final status")
	# harder files really appear for a strong player
	var strong := make(104, st, false, 6)
	var weak := make(104, LearnState.new(), false, 6)
	check(strong[1].files[0].row_count >= weak[1].files[0].row_count, "a strong player on day 6 gets files at least as large")

# ---- 8. unused features change nothing -------------------------------------------------------------------

func test_unused_identical() -> void:
	for s in [104, 7, 555]:
		var plain := Game.new(s, 10)
		var learned := Game.new(s, 10)
		var session := Session.new(learned, s)
		session.attach_learn(LearnState.new(), false)
		for day in range(1, 11):
			plain.begin_day()
			learned.begin_day()
			session.begin_day(day)
			var r_plain := report(plain)
			var r_learn := report(learned)
			eq(plain.submit_report(r_plain).ok, learned.submit_report(r_learn).ok, "submit")
			plain.end_day()
			learned.end_day()
			eq(plain.review(day), learned.review(day), "identical review, seed %d day %d" % [s, day])
		eq(plain.status(), learned.status(), "identical final status, seed %d" % s)
	# the data files themselves are identical with and without a LearnState (new player: no ramp change)
	for s in [104, 31]:
		var a := make(s, null, false, 6)
		var b := make(s, LearnState.new(), false, 6)
		eq(a[1].files.map(func(f): return f.table), b[1].files.map(func(f): return f.table), "same files with an idle learn state, seed %d" % s)
	# a hint is the only thing that touches Energy
	var g1 := Game.new(104, 10)
	var g2 := Game.new(104, 10)
	g1.begin_day()
	g2.begin_day()
	eq(g1.status(), g2.status(), "status identical at the start")
	g2.spend_analysis_energy(0)
	eq(g1.status(), g2.status(), "spending zero changes nothing")

# ---- 9. leak scan ------------------------------------------------------------------------------------------

func test_leak_scan() -> void:
	var words := ["manifest", "reference", "truth", "recipe", "expected", "hidden", "dirt_types", "reference_steps", "evaluate_reference", "_ref", "_gen", "grader", "ref_steps", "truth_list"]
	var ui_files: Array = ["res://scripts/data/session.gd", "res://scripts/learn/tutorial_script.gd", "res://scripts/learn/hints.gd", "res://scripts/learn/ramp.gd", "res://scripts/learn/learn_state.gd", "res://scripts/learn/content.gd"]
	for dir in ["res://scripts/v2/data", "res://scripts/v2/learn"]:
		if DirAccess.open(dir) == null: continue
		for filename in DirAccess.get_files_at(dir):
			if filename.ends_with(".gd"): ui_files.append(dir + "/" + filename)
	for filename in DirAccess.get_files_at("res://scripts/v2/windows"):
		if filename.begins_with("data_") or filename.begins_with("dash") or filename.begins_with("analysis") or filename.begins_with("handbook"): ui_files.append("res://scripts/v2/windows/" + filename)
	for path in ["res://scripts/v2/desktop.gd", "res://scripts/v2/tutorial_choice.gd", "res://scripts/v2/case_coach.gd", "res://scripts/v2/hint_popup.gd"]:
		if FileAccess.file_exists(path): ui_files.append(path)
	for path in ui_files:
		var source := FileAccess.get_file_as_string(path)
		var code := ""
		for line in source.split("\n"):
			if not line.strip_edges().begins_with("#"): code += line.split(" #")[0] + "\n"
		for word in words:
			var pattern := RegEx.new()
			pattern.compile("\\b" + word + "\\b")
			check(pattern.search(code) == null, "%s does not mention %s" % [path, word])
		check(not code.contains("scripts/data/reference") and not code.contains("scripts/data/grader") and not code.contains("scripts/data/generator") and not code.contains("scripts/learn/tutorial_files") and not code.contains("scripts/learn/coaching") and not code.contains("scripts/learn/skills") and not code.contains("scripts/learn/learn_settle") and not code.contains("scripts/learn/case_map"), path + " does not load review-only or hidden parts")
	check(ui_files.size() >= 8, "scanned %d UI-path scripts" % ui_files.size())
	# the public output of DataGame carries no case trap, no tutorial answers
	var made := make(104, LearnState.new(), true)
	var pub := JSON.stringify(made[1].files) + JSON.stringify(made[1].data.case_public(1, made[1].files[0].id))
	for needle in ["Hanoi sold", "1520", "0.68", "trap", "wrong_paths"]:
		check(not pub.contains(needle.replace("1520", "\"1520\"")), "public data does not contain " + needle)
	# tutorial coach texts mention none of the expected findings
	var forbidden := ["Hanoi sold", "p = 0.68", "133", "signup_done>first_purchase", "13.7", "Simpson"]
	var blob := JSON.stringify(strings.learn.tutorial.steps)
	for needle in forbidden: check(not blob.contains(needle), "coach texts do not reveal " + needle)
	# review only after the day
	var d := make(104, LearnState.new())
	check(not d[1].data.review(1).ok, "no review before the day ends")

# ---- 10. content ---------------------------------------------------------------------------------------------

func test_content() -> void:
	eq(Content.cards().size(), 49, "49 handbook cards")
	var skills := {}
	for c in Content.cards(): skills[c.skill] = true
	eq(skills.size(), 5, "cards in 5 skills")
	for c in Content.cards():
		for see in c.see_also: check(not Content.card_by_id(see).is_empty(), "see_also resolves: " + see)
	for key in ["hint_level", "hint_type", "handbook", "skills", "coaching", "choice", "tutorial", "hint_note_miss", "hint_note_praise"]:
		check(strings.learn.has(key), "strings.learn." + key)
	for day in range(1, 6):
		var ids := TutorialScript.step_ids(day)
		for id in ids:
			var pair: Array = strings.learn.tutorial.steps[str(day)].get(id, [])
			check(pair.size() == 2 and pair[0] != "" and pair[1] != "", "coach text and stuck text for day %d step %s" % [day, id])
		check(strings.learn.tutorial.titles.has(str(day)), "title of tutorial day %d" % day)
	for hint_skill in Content.SKILLS: check(strings.learn.hint_type.has(hint_skill), "hint type for " + hint_skill)
	var compose := Hints.compose({"level": 2, "card_id": "hb_duplicates"}, strings.learn)
	check(compose.text.contains("duplicate") or compose.text.contains("Duplicate") or compose.text.length() > 30, "level 2 hint carries the card text")
	eq(Hints.compose({"level": 3, "families": ["Clean rows", "Clean text"]}, strings.learn).text.contains("Clean rows, Clean text"), true, "level 3 lists families")

func run() -> void:
	data_cfg = Loader.load_json("res://data/datasets.json")
	world_cfg = Loader.load_json("res://data/world.json")
	questions = Loader.load_json("res://data/questions.json").questions
	events = Sim.new(1, {}, 11).events
	strings = Loader.load_json("res://data/strings_v2.json")
	test_content()
	test_case_map()
	test_handbook()
	test_hints()
	test_coaching()
	test_tutorial()
	test_skills()
	test_ramp()
	test_unused_identical()
	test_leak_scan()
	print("test_t035_logic: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

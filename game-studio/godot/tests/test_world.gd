extends SceneTree

const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
const Sim = preload("res://scripts/sim/simulation.gd")
const Grade = preload("res://scripts/world/report.gd")
const Career = preload("res://scripts/world/career.gd")
const Verify = preload("res://scripts/world/verifier.gd")
const Bots = preload("res://tests/balance_world.gd")
var checks := 0
var failures := 0
var config: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 30: printerr("FAIL: ", message)

func near(value: float, expected: float, message: String) -> void:
	check(absf(value - expected) < 0.00001, message)

func public_only(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			if key in ["truth", "kind", "link", "state_direction", "exaggerates", "answer", "scenario"]: return false
			if not public_only(value[key]): return false
	elif value is Array:
		for item in value:
			if not public_only(item): return false
	return true

func submission(game: RefCounted) -> Dictionary:
	return {"question_id":game.question_today().id,"forecast":"ngang","confidence":"thap","evidence":[],"actions":[]}

func test_public_and_replay() -> void:
	var a := Game.new(104, 10)
	var b := Game.new(104, 10, {"world":{}})
	var cached := Game.new(104, 10)
	check(cached._scenario._days == a._scenario._days and cached._news._items == a._news._items, "cache matches fresh generation")
	cached._news._items[0].headline = "mutated"
	check(a._news._items[0].headline != "mutated", "cache isolated by deep copy")
	var log_a: Array = []
	var log_b: Array = []
	check(not a.review(1).get("ok", true), "future review rejected")
	check(not a.submit_report({}).ok and not a.end_day().ok, "closed day rejected")
	while not a.status().finished:
		a.begin_day()
		b.begin_day()
		var day: int = a._day
		a.begin_day()
		check(a.status().day == day, "begin idempotent")
		check(not a.review(day).get("ok", true), "current review rejected")
		var result_a := [a.news_today(), a.question_today(), a.tools(), a.hand(), a.status(), a.report_snapshot()]
		var result_b := [b.news_today(), b.question_today(), b.tools(), b.hand(), b.status(), b.report_snapshot()]
		check(public_only(result_a), "all public read APIs hide secrets")
		check(result_a == result_b, "seed public read reproducibility")
		if not a.news_today().is_empty():
			var uid: String = a.news_today()[0].uid
			var v: Dictionary = a.verify(uid, a.tools()[0].id)
			check(v == b.verify(uid, b.tools()[0].id), "verification deterministic")
			check(public_only(v), "verify hides secrets")
		var invalid := submission(a)
		invalid.forecast = "invalid"
		check(a.submit_report(invalid).error == "invalid_forecast", "specific validation error")
		check(not a.end_day().ok, "invalid submit changes no phase")
		var ra: Dictionary = a.submit_report(submission(a))
		var rb: Dictionary = b.submit_report(submission(b))
		check(ra == rb and public_only(ra), "submit safe and deterministic")
		check(not a.submit_report(submission(a)).ok, "duplicate submit rejected")
		var ea: Dictionary = a.end_day()
		var eb: Dictionary = b.end_day()
		check(ea == eb and public_only(ea) and not ea.has("delta") and not ea.has("acc"), "end does not disclose grading")
		check(a._sim.state.week == day and not a._sim.week_open, "company day consistency")
		log_a.append(a.review(day))
		log_b.append(b.review(day))
		var copy: Dictionary = a.review(day)
		copy.news.clear()
		check(not a.review(day).news.is_empty(), "review defensive copy")
	check(hash(log_a) == hash(log_b), "whole log reproducible hash")
	check(a.status().ending == "survived", "complete public ten day integration")
	var first := Game.new(4, 10)
	first.begin_day()
	var news: Array = first.news_today()
	news[0].headline = "mutated"
	check(first.news_today()[0].headline != "mutated", "news defensive copy")
	var hand: Array = first.hand()
	if not hand.is_empty():
		hand[0].effects.clear()
		check(not first.hand()[0].effects.is_empty(), "hand defensive deep copy")

func test_news_questions() -> void:
	var seen := {}
	var event_seen := {}
	for seed_value in range(104, 304):
		var game := Game.new(seed_value, 10)
		var last := {}
		var kinds := {}
		var questions: Array = []
		for day in range(1, 11):
			var q: Dictionary = game._scenario._questions[day - 1]
			check(q.id not in questions.slice(maxi(0, questions.size() - 3)), "question three day cooldown")
			questions.append(q.id)
			var answer: String = game._scenario._answers[day - 1]
			var expected := "ngang"
			match q.answer_rule:
				"next_state": expected = game._scenario._days[day][q.variable].direction
				"state": expected = game._scenario._days[day - 1][q.variable].direction
				"event":
					for d in range(day, day + int(q.window_days) + 1):
						for s in game._scenario._shocks:
							if s.id == q.variable and d >= s.day and d < s.end: expected = "tang"
				"integrity":
					expected = "tang"
					for s in game._scenario._shocks:
						if s.id == "logging_error" and day >= s.day and day < s.end: expected = "giam"
				"bank_rumor":
					var state: Dictionary = game._scenario._days[day - 1].tin_dung
					if state.direction == "giam" and state.magnitude == "high": expected = "giam"
			check(answer == expected, "independent question answer rule")
		var daily := {}
		for item in game._news._items:
			seen[item.uid] = true
			kinds[item.kind] = true
			daily[item.day] = int(daily.get(item.day, 0)) + 1
			check(item.day - int(last.get(item.template_id, -100)) >= 3, "template cooldown")
			last[item.template_id] = item.day
			var template: Dictionary = {}
			for t in game._news._data.news:
				if t.id == item.template_id: template = t
			if str(item.link).begins_with("state:") and item.kind not in ["noise", "stale"]:
				var variable: String = item.link.trim_prefix("state:")
				var state: Dictionary = game._scenario._days[item.day - 1][variable]
				if item.kind == "trap": check(template.state_direction != state.direction or template.exaggerates, "trap valid")
				else:
					check(template.state_direction == state.direction, "signal/partial correct direction")
					if item.kind == "partial": check(item.magnitude != state.magnitude, "partial magnitude wrong")
					var changed: int = item.day
					while changed > 1 and game._scenario._days[changed - 2][variable].direction == state.direction: changed -= 1
					check(item.day - changed >= game._news._source(item.source_id).delay_days, "state source delay")
			elif str(item.link).begins_with("event:"):
				var valid := false
				for s in game._scenario._shocks:
					if item.link == "event:" + s.id and item.day >= s.day + game._news._source(item.source_id).delay_days and (item.day < s.end or item.day - s.day <= 2): valid = true
				check(valid, "event recent and source delay")
		check(kinds.size() == 5, "five kinds every scenario")
		for day in range(1, 11): check(daily.get(day, 0) == 6, "six stories every day")
		check(game._scenario._shocks.size() <= 4, "demo shock cap")
		var days := {}
		for s in game._scenario._shocks:
			check(not days.has(s.day), "one shock per day")
			days[s.day] = true
			event_seen[s.id] = true
	check(event_seen.size() == 8, "all eight shocks reachable")

func test_grade() -> void:
	var nominal := config.duplicate(true)
	nominal.grading.base = 10
	nominal.grading.confidence = {"thap":0.5,"vua":1.0,"cao":1.5}
	nominal.grading.evidence_factor = 0.25
	var confirmed := [{"uid":"one","truth":"dung","verification":"xac_nhan"}]
	near(Grade.grade({"forecast":"tang","confidence":"cao","evidence":["one"]}, "tang", confirmed, nominal).delta, 18.8, "hand computed nominal correct high with evidence")
	near(Grade.grade({"forecast":"giam","confidence":"vua","evidence":["one"]}, "tang", confirmed, nominal).delta, -12.5, "hand computed nominal opposite")
	near(Grade.grade({"forecast":"tang","confidence":"vua","evidence":["one"]}, "ngang", confirmed, nominal).delta, 3.8, "hand computed nominal adjacent")
	for forecast in config.directions:
		for answer in config.directions:
			for confidence in config.grading.confidence:
				var r: Dictionary = Grade.grade({"forecast":forecast,"confidence":confidence,"evidence":[]}, answer, [], config)
				var expected_acc := 1.0 if forecast == answer else (0.4 if forecast == "ngang" or answer == "ngang" else 0.0)
				near(r.acc, expected_acc, "accuracy table")
				var expected: float = config.grading.base * config.grading.confidence[confidence] * (1 if expected_acc == 1 else (0.3 if expected_acc > 0 else -1))
				near(r.delta, snappedf(expected, 0.1), "confidence grade table")
	for truth in ["dung", "sai", "mot_phan", "cu", "khong_lien_quan"]:
		for verification in ["chua_kiem_chung", "xac_nhan", "bac_bo", "chua_du_can_cu", "cu"]:
			var items := [{"uid":"one","truth":truth,"verification":verification}]
			var result: Dictionary = Grade.grade({"forecast":"tang","confidence":"vua","evidence":["one"]}, "tang", items, config)
			var expected: float = config.grading.unverified[truth] if verification == "chua_kiem_chung" else config.grading.evidence[verification]
			near(result.ev, expected, "evidence table")
			near(result.delta, snappedf(config.grading.base * (1 + float(config.grading.evidence_factor) * expected), 0.1), "evidence delta")
	var game := Game.new(42, 10)
	game.begin_day()
	var input := submission(game)
	input.evidence = ["missing"]
	check(game.submit_report(input).error == "invalid_evidence", "missing uid")
	input = submission(game)
	input.actions = ["sql_deep_dive"]
	check(game.submit_report(input).error == "invalid_action", "analysis cannot be proposed")
	input.actions = ["a", "b"]
	check(game.submit_report(input).error == "too_many_actions", "rank action limit")

func test_verification() -> void:
	var clean_config := config.duplicate(true)
	clean_config.noise_factor = 0
	for truth in ["dung", "mot_phan", "sai", "cu", "khong_lien_quan"]:
		var sim := Sim.new(42)
		sim.begin_week(false)
		var verifier := Verify.new(42, clean_config)
		var item := {"truth":truth,"verify_with":["truy_van_lich_su"],"verified_by":[],"results":{},"verification":"chua_kiem_chung"}
		var expected: String = {"dung":"xac_nhan","mot_phan":"xac_nhan","sai":"bac_bo","cu":"cu","khong_lien_quan":"chua_du_can_cu"}[truth]
		var hand: Array = sim.hand.duplicate(true)
		var result: Dictionary = verifier.verify(item, "truy_van_lich_su", sim)
		check(result.result == expected, "truth result table")
		var cash: float = sim.state.base.cash
		var energy: int = sim.state.energy
		check(verifier.verify(item, "truy_van_lich_su", sim) == result, "cached result")
		near(sim.state.base.cash, cash, "repeat free budget")
		check(sim.state.energy == energy and sim.hand == hand, "repeat free energy and untouched hand")
		check(verifier.verify(item, "doi_chieu_nguon", sim).result == "chua_du_can_cu", "wrong tool inconclusive")
		check(item.verification == expected, "inconclusive does not overwrite finding")
	var sim := Sim.new(42)
	sim.begin_week(false)
	sim.state.energy = 0
	var item := {"truth":"dung","verify_with":["lam_sach_du_lieu"],"verified_by":[],"results":{},"verification":"chua_kiem_chung"}
	var before := item.duplicate(true)
	var verifier := Verify.new(42, config)
	check(not verifier.verify(item, "lam_sach_du_lieu", sim).ok and item == before, "energy refusal atomic")
	sim.state.energy = 3
	sim.state.base.cash = 0
	check(not verifier.verify(item, "truy_van_lich_su", sim).ok and item == before, "budget refusal atomic")
	for i in 100:
		var dirty := Sim.new(i)
		dirty.begin_week(false)
		dirty.state.base.integrity = 0
		var test := {"truth":"dung","verify_with":["truy_van_lich_su"],"verified_by":[],"results":{},"verification":"chua_kiem_chung"}
		check(Verify.new(i, config).verify(test, "truy_van_lich_su", dirty).result in ["xac_nhan", "chua_du_can_cu"], "noise never inverts truth")

func test_career() -> void:
	var career := Career.new(config)
	var good := {"acc":1.0,"ev":1.0,"delta":15.0}
	career.update(good)
	check(career.rank == 0, "minimum tenure")
	career.update(good)
	check(career.rank == 1 and career.trust == config.career.reset_promotion, "promotion and reset")
	near(career.personal_pay, 300, "salary and half salary bonus")
	var warning := Career.new(config)
	warning.trust = 50
	warning.update({"acc":0.4,"ev":0,"delta":-16})
	warning.update({"acc":0.4,"ev":0,"delta":0})
	check(warning.warnings == 1, "warning only crossing")
	warning.update({"acc":0.4,"ev":0,"delta":5})
	warning.update({"acc":0.4,"ev":0,"delta":-5})
	check(warning.warnings == 2, "new crossing counts")
	career.trust = 26
	career.update({"acc":0,"ev":0,"delta":-2})
	check(career.rank == 0 and career.trust == 40 and career.demotions == 1, "demotion resets")
	career.rank = 1
	career.trust = 26
	career.update({"acc":0,"ev":0,"delta":-2})
	check(career.fired and career.demotions == 2, "two demotions fired")
	var intern := Career.new(config)
	intern.trust = 25
	intern.update({"acc":0,"ev":0,"delta":0})
	check(not intern.fired, "intern first wrong")
	intern.update({"acc":0,"ev":0,"delta":0})
	check(intern.fired, "intern two wrong fired")
	var zero := Career.new(config)
	zero.update({"acc":0,"ev":0,"delta":-100})
	check(zero.fired, "zero trust fired")
	var previous := -1.0
	for trust in range(101):
		zero.trust = trust
		check(zero.adoption() >= previous, "adoption monotonic")
		previous = zero.adoption()

func test_score_sweep() -> void:
	var max_daily_gain: float = config.grading.base * config.grading.confidence.values().max() * (1.0 + config.grading.evidence_factor)
	var upper_loss: float = 100 * config.score.trust + 30 * max_daily_gain * config.score.positive_delta
	check(config.score.win_bonus - config.career.max_demotions * config.score.demotion > upper_loss, "analytical score separation for 30 days")
	var min_win := INF
	var max_loss := -INF
	var wins := 0
	var losses := 0
	for seed_value in range(104, 604):
		for bot in ["random_reporter", "rumor_follower", "official_only", "verifier", "careful_hedger"]:
			var result: Dictionary = Bots.run_game(seed_value, 10, bot)
			if result.won:
				wins += 1
				min_win = minf(min_win, result.score)
			else:
				losses += 1
				max_loss = maxf(max_loss, result.score)
	check(wins > 0 and losses > 0 and min_win > max_loss, "all losing scores below all winning scores")
	print("score sweep 500/bot: wins=%d losses=%d min_win=%.2f max_loss=%.2f" % [wins, losses, min_win, max_loss])

func _init() -> void:
	config = Loader.load_json("res://data/world.json")
	test_public_and_replay()
	test_news_questions()
	test_grade()
	test_verification()
	test_career()
	test_overrides_and_endings()
	if "--quick" not in OS.get_cmdline_user_args(): test_score_sweep()
	print("test_world: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_overrides_and_endings() -> void:
	var states: Array = []
	for day in 11:
		var values := {}
		for variable in config.variables: values[variable] = {"direction":"tang","magnitude":"low"}
		states.append(values)
	var questions: Array = []
	for i in 7:
		questions.append({"id":"fixture%d" % i,"text":"Fixture","variable":"lai_suat","window_days":0,"answer_rule":"state"})
	var fixture_config := config.duplicate(true)
	fixture_config.macro = {}
	fixture_config.noise_factor = 0
	var overrides := {"world":fixture_config,"questions":questions,"scenario":{"days":states,"shocks":[]}}
	var fixture := Game.new(77, 10, overrides)
	fixture.begin_day()
	check(fixture._scenario._days == states and fixture._scenario._shocks.is_empty(), "fixed scenario override")
	var invalid := submission(fixture)
	invalid.evidence = [fixture.news_today()[0].uid, fixture.news_today()[0].uid]
	check(fixture.submit_report(invalid).error == "invalid_evidence", "duplicate evidence rejected")
	invalid = submission(fixture)
	invalid.evidence = ["a", "b", "c", "d"]
	check(fixture.submit_report(invalid).error == "too_many_evidence", "evidence limit")
	check(public_only(fixture.verify("missing", "truy_van_lich_su")), "verification error safe")
	var fired_config := fixture_config.duplicate(true)
	fired_config.career.initial_trust = 1
	var fired_overrides := overrides.duplicate(true)
	fired_overrides.world = fired_config
	var fired := Game.new(77, 10, fired_overrides)
	fired.begin_day()
	var input := submission(fired)
	input.forecast = "giam"
	input.confidence = "cao"
	check(fired.submit_report(input).ok, "firing fixture submit")
	fired.end_day()
	check(fired.status().ending == "fired" and not fired.status().won, "fired ending")
	var company_config: Dictionary = Loader.load_json("res://data/config.json").duplicate(true)
	company_config.initial.cash = 1
	var bankrupt_overrides := overrides.duplicate(true)
	bankrupt_overrides.simulation = {"config":company_config}
	var bankrupt := Game.new(77, 10, bankrupt_overrides)
	bankrupt.begin_day()
	input = submission(bankrupt)
	input.forecast = "tang"
	bankrupt.submit_report(input)
	bankrupt.end_day()
	check(bankrupt.status().ending == "bankrupt" and bankrupt._sim.state.lost, "bankrupt ending company consistent")
	var win_config := fixture_config.duplicate(true)
	win_config.grading.base = 50
	var win_overrides := overrides.duplicate(true)
	win_overrides.world = win_config
	var win := Game.new(77, 10, win_overrides)
	while not win.status().finished:
		win.begin_day()
		input = submission(win)
		input.forecast = "tang"
		win.submit_report(input)
		win.end_day()
	check(win.status().ending == "survived" and win.status().won, "promoted survival wins")
	near(fired.status().score, fired._career.trust * float(config.score.trust) + fired._career.positive_delta * float(config.score.positive_delta) - float(config.score.fired), "exact score formula without loss cap")
	check(win.status().score > fired.status().score and win.status().score > bankrupt.status().score, "ending score separation fixtures")
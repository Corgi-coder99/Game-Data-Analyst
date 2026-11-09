extends SceneTree

const Sim = preload("res://scripts/sim/simulation.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func near(actual: float, expected: float, message: String) -> void:
	check(absf(actual - expected) < 0.00001, message)

func _init() -> void:
	var sim := Sim.new(42)
	sim.begin_week(false)
	sim.state.base.ad_spend = 1000.0
	sim.state.base.cash -= 1000.0
	var result := sim.finish_week()
	near(result.new_users, 60.6060606061, "effective CAC = 16.5")
	near(result.churned, 600.0, "churn")
	near(sim.state.base.users, 460.6060606061, "users")
	near(result.revenue, 230.303030303, "revenue")
	near(result.cash, 8407.2727272727, "cash including variable server cost")
	var a := Sim.new(789)
	var b := Sim.new(789)
	while not a.state.lost and not a.state.won:
		a.begin_week()
		b.begin_week()
		check(a.hand == b.hand, "same seed draws")
		check(a.event_reports() == b.event_reports(), "same seed events")
		check(a.report() == b.report(), "same seed noise")
		for card in a.hand.duplicate():
			check(a.play(card.id) == b.play(card.id), "same actions")
		a.finish_week()
		b.finish_week()
		check(a.state.base == b.state.base, "same seed state")
		check(a.state.lost or a.state.base.cash > 0, "nonpositive cash implies loss")
	var event_sim := Sim.new(1)
	event_sim.begin_week(false)
	event_sim.apply_event(event_sim.events[0])
	check(not event_sim.event_reports()[0].has("root_cause"), "hidden root cause")
	event_sim.hand = [event_sim.cards[0], event_sim.cards[5]]
	check(event_sim.play("sql_deep_dive"), "analysis playable")
	check(event_sim.event_reports()[0].has("root_cause"), "analysis reveals root cause")
	check(event_sim.play("onboarding_redesign"), "resolution playable")
	check(event_sim.active_events.is_empty() and event_sim.state.resolved == 1, "resolved once")
	near(event_sim.state.value("retention", event_sim.config), 0.65, "remove event modifier")
	check(not event_sim.play("onboarding_redesign"), "cannot replay consumed card")
	var timed := Sim.new(1)
	timed.begin_week(false)
	timed.hand = [timed.cards[9], timed.cards[10]]
	timed.play("loyalty_program")
	timed.play("seo_content")
	near(timed.state.value("retention", timed.config), 0.48, "temporary loyalty")
	near(timed.state.value("cac", timed.config), 15, "SEO delayed")
	for i in 2:
		timed.finish_week()
		timed.begin_week(false)
	near(timed.state.value("cac", timed.config), 14.2, "SEO starts after two weeks")
	for i in 2:
		timed.finish_week()
		timed.begin_week(false)
	near(timed.state.value("retention", timed.config), 0.4, "loyalty expires")
	var poor := Sim.new()
	poor.begin_week(false)
	poor.state.base.cash = 0
	poor.finish_week()
	check(poor.state.lost, "cash bankruptcy")
	var low_ratio := Sim.new()
	low_ratio.state.base.arpu = 0
	low_ratio.state.base.cash = 1999
	for i in 4:
		low_ratio.begin_week(false)
		low_ratio.state.base.fixed_cost = -100000
		low_ratio.config = low_ratio.config.duplicate(true)
		low_ratio.config.limits.fixed_cost[0] = 0
		low_ratio.config.economy.cost_per_user = 0
		low_ratio.finish_week()
	check(low_ratio.state.lost and low_ratio.state.bad_ratio_weeks == 4, "four low ratio weeks")
	var demo := Sim.new(1, {}, 10)
	demo.state.base.cash = 1000000
	for i in 10:
		demo.begin_week(false)
		demo.finish_week()
	check(demo.state.won and demo.state.week == 10, "demo horizon")
	var boundaries := Sim.new(19)
	check(boundaries.finish_week().is_empty(), "cannot finish before beginning")
	boundaries.begin_week(false)
	boundaries.begin_week(false)
	check(boundaries.state.week == 1, "cannot begin twice")
	boundaries.hand = [boundaries.cards[7], boundaries.cards[8]]
	boundaries.state.energy = 0
	check(not boundaries.play("ads_campaign"), "energy enforced")
	boundaries.state.energy = 3
	boundaries.state.base.cash = 699
	check(not boundaries.play("ads_campaign"), "budget enforced")
	boundaries.state.base.cash = 10000
	boundaries.play("ads_campaign")
	var charged := boundaries.finish_week()
	near(charged.cash, 10000 - 700 + charged.revenue - charged.fixed_cost, "campaign charged once")
	check(boundaries.finish_week().is_empty(), "cannot settle twice")
	var clean := Sim.new(19)
	clean.state.base.integrity = 100
	near(clean.report().retention, 0.4, "perfect integrity has no noise")
	var untouched := Sim.new(19)
	for i in 10:
		clean.report()
	clean.begin_week()
	untouched.begin_week()
	check(clean.hand == untouched.hand and clean.event_reports() == untouched.event_reports(), "reports do not change gameplay RNG")
	var logging := Sim.new(1)
	logging.begin_week(false)
	logging.apply_event(logging.events[2])
	near(logging.state.value("retention", logging.config), 0.4, "logging error changes observation only")
	var clamped := Sim.new(1)
	clamped.begin_week(false)
	clamped.state.base.users = 1
	clamped.apply_event(clamped.events[4])
	near(clamped.state.base.users, 0, "outage cannot create negative users")
	var influencer := Sim.new(1)
	influencer.begin_week(false)
	influencer.hand = [influencer.cards[8]]
	influencer.play("influencer_campaign")
	near(influencer.state.value("retention", influencer.config), 0.28, "influencer penalty before onboarding")
	var onboarded := Sim.new(1)
	onboarded.begin_week(false)
	onboarded.state.flags.onboarding = true
	onboarded.hand = [onboarded.cards[8]]
	onboarded.play("influencer_campaign")
	near(onboarded.state.value("retention", onboarded.config), 0.4, "onboarding prevents influencer penalty")
	var full := Sim.new(1)
	full.state.base.cash = 1000000
	for i in int(full.config.weeks.full):
		full.begin_week(false)
		full.finish_week()
	check(full.state.won and full.state.week == 30, "full horizon")
	var noisy := Sim.new(5)
	noisy.begin_week(false)
	noisy.state.base.integrity = 0
	var before_state: Dictionary = noisy.state.base.duplicate(true)
	var noisy_report := noisy.report()
	check(noisy_report.retention >= 0.2 and noisy_report.retention <= 0.6, "noise bounded by integrity")
	check(noisy.state.base == before_state, "observation does not change true state")
	noisy.hand = [noisy.cards[1], noisy.cards[3]]
	noisy.play("ab_test")
	var preview := noisy.report()
	check(absf(preview.retention - 0.4) <= 0.02, "A/B improves next action preview")
	noisy.play("clean_data")
	near(noisy.state.base.integrity, 25, "clean data restores integrity")
	near(noisy.prediction_multiplier, 1, "A/B consumed by next action")
	near(a.score(), b.score(), "same seed and actions produce same score")
	test_scores()
	print("test_sim: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_scores() -> void:
	var fixture := Sim.new(104)
	check(fixture.config.score.loss_cap < fixture.config.score.win_bonus, "loss cap below win bonus")
	fixture.state.base.cash = -444.0
	fixture.state.base.retention = 0.98
	fixture.state.base.cac = 15.0
	fixture.state.base.arpu = 21.0
	fixture.state.week = 30
	fixture.state.resolved = 20
	fixture.state.lost = true
	near(fixture.state.ratio(fixture.config), 70.0, "high ratio loss fixture")
	near(fixture.score(), 900.0, "high ratio loss capped without cash or ratio")
	fixture.state.week = 2
	fixture.state.resolved = 1
	near(fixture.score(), 130.0, "uncapped loss uses week and resolved weights")
	fixture.state.lost = false
	fixture.state.won = true
	fixture.state.base.cash = 1.0
	fixture.state.resolved = 0
	fixture.state.base.arpu = 1.5
	near(fixture.state.ratio(fixture.config), 5.0, "ratio cap boundary fixture")
	var capped_score := fixture.score()
	near(capped_score, 1500.1, "winning score uses configured weights")
	check(capped_score > fixture.config.score.loss_cap, "small cash win exceeds every loss")
	fixture.state.base.arpu = 21.0
	near(fixture.score(), capped_score, "ratio from 5 to 70 does not change score")
	fixture.state.won = false
	near(fixture.score(), 500.1, "unfinished game excludes win bonus")
	fixture.state.base.cash = -444.0
	near(fixture.score(), 500.0, "unfinished negative cash clamped")
	print("score fixtures: loss cash=-444 ratio=70 week=30 resolved=20 score=900; loss week=2 resolved=1 score=130; win cash=1 ratio=5/70 resolved=0 score=1500.1")
	var min_win := INF
	var max_loss := -INF
	var wins := 0
	var losses := 0
	for strategy in ["random", "ads_only", "optimization_only", "balanced"]:
		for game in 500:
			var sim := Sim.new(int(fixture.config.balance.seed) + game)
			while not sim.state.lost and not sim.state.won:
				sim.begin_week()
				var choices: Array = []
				if strategy == "random":
					var pool := sim.hand.duplicate()
					while not pool.is_empty():
						var index := sim.rng.randi_range(0, pool.size() - 1)
						choices.append(pool[index].id)
						pool.remove_at(index)
				else:
					choices = sim.config.balance.priorities[strategy]
				for id in choices:
					sim.play(id)
				sim.finish_week()
			var points := sim.score()
			if sim.state.won:
				wins += 1
				min_win = minf(min_win, points)
				check(points >= sim.config.score.win_bonus, "swept win above bonus")
			else:
				losses += 1
				max_loss = maxf(max_loss, points)
				check(points <= sim.config.score.loss_cap, "swept loss below cap")
			if game == 0:
				print("score sample: strategy=%s seed=%d won=%s cash=%.2f score=%.2f" % [strategy, int(fixture.config.balance.seed), sim.state.won, sim.state.base.cash, points])
	check(wins > 0 and losses > 0, "sweep includes wins and losses")
	check(max_loss < min_win, "all swept losses below minimum win across strategies")
	print("score sweep: 500 games/strategy; wins=%d losses=%d min_win=%.2f max_loss=%.2f" % [wins, losses, min_win, max_loss])

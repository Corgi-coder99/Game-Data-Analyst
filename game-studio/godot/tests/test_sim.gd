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
	print("test_sim: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

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
	test_use_tool()
	var ui_fixture := Sim.new(105, {}, 10)
	while not ui_fixture.state.lost and not ui_fixture.state.won:
		ui_fixture.begin_week()
		for id in ui_fixture.config.balance.priorities.balanced:
			ui_fixture.play(id)
		ui_fixture.finish_week()
	print("UI fixture: cash=%.2f users=%.2f ratio=%.2f" % [ui_fixture.state.base.cash, ui_fixture.state.base.users, ui_fixture.state.ratio(ui_fixture.config)])
	check(ui_fixture.state.won, "current UI fixture policy seed 105 wins demo")
	var sim := Sim.new(42)
	sim.begin_week(false)
	sim.state.base.ad_spend = 1000.0
	sim.state.base.cash -= 1000.0
	var result := sim.finish_week()
	near(result.new_users, 12.3762376238, "effective CAC = 80.8")
	near(result.churned, 150.0, "churn")
	near(sim.state.base.users, 862.3762376238, "users")
	near(result.revenue, 206.9702970297, "revenue")
	near(result.cash, 16963.8514851485, "cash including variable server cost")
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
	near(event_sim.state.value("retention", event_sim.config), 0.93, "remove event modifier")
	check(not event_sim.play("onboarding_redesign"), "cannot replay consumed card")
	var timed := Sim.new(1)
	timed.begin_week(false)
	timed.hand = [timed.cards[9], timed.cards[10]]
	timed.play("loyalty_program")
	timed.play("seo_content")
	near(timed.state.value("retention", timed.config), 0.89, "temporary loyalty")
	near(timed.state.value("cac", timed.config), 80, "SEO delayed")
	for i in 2:
		timed.finish_week()
		timed.begin_week(false)
	near(timed.state.value("cac", timed.config), 73.6, "SEO starts after two weeks")
	for i in 2:
		timed.finish_week()
		timed.begin_week(false)
	near(timed.state.value("retention", timed.config), 0.85, "loyalty expires")
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
	demo.config = demo.config.duplicate(true)
	demo.config.win = {}
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
	boundaries.state.base.cash = 299
	check(not boundaries.play("ads_campaign"), "budget enforced")
	boundaries.state.base.cash = 10000
	boundaries.play("ads_campaign")
	var charged := boundaries.finish_week()
	near(charged.cash, 10000 - 1000 + charged.revenue - charged.fixed_cost, "campaign charged once")
	check(boundaries.finish_week().is_empty(), "cannot settle twice")
	var clean := Sim.new(19)
	clean.state.base.integrity = 100
	near(clean.report().retention, 0.85, "perfect integrity has no noise")
	var untouched := Sim.new(19)
	for i in 10:
		clean.report()
	clean.begin_week()
	untouched.begin_week()
	check(clean.hand == untouched.hand and clean.event_reports() == untouched.event_reports(), "reports do not change gameplay RNG")
	var logging := Sim.new(1)
	logging.begin_week(false)
	logging.apply_event(logging.events[2])
	near(logging.state.value("retention", logging.config), 0.85, "logging error changes observation only")
	var clamped := Sim.new(1)
	clamped.begin_week(false)
	clamped.state.base.users = 1
	clamped.apply_event(clamped.events[4])
	near(clamped.state.base.users, 0, "outage cannot create negative users")
	var influencer := Sim.new(1)
	influencer.begin_week(false)
	influencer.hand = [influencer.cards[8]]
	influencer.play("influencer_campaign")
	near(influencer.state.value("retention", influencer.config), 0.35, "influencer penalty before onboarding")
	var onboarded := Sim.new(1)
	onboarded.begin_week(false)
	onboarded.state.flags.onboarding = true
	onboarded.hand = [onboarded.cards[8]]
	onboarded.play("influencer_campaign")
	near(onboarded.state.value("retention", onboarded.config), 0.85, "onboarding prevents influencer penalty")
	var full := Sim.new(1)
	full.state.base.cash = 1000000
	full.config = full.config.duplicate(true)
	full.config.win = {}
	for i in int(full.config.weeks.full):
		full.begin_week(false)
		full.finish_week()
	check(full.state.won and full.state.week == 30, "full horizon")
	var noisy := Sim.new(5)
	noisy.begin_week(false)
	noisy.state.base.integrity = 0
	var before_state: Dictionary = noisy.state.base.duplicate(true)
	var noisy_report := noisy.report()
	check(noisy_report.retention >= 0.425 and noisy_report.retention <= 1.275, "noise bounded by integrity")
	check(noisy.state.base == before_state, "observation does not change true state")
	noisy.hand = [noisy.cards[1], noisy.cards[3]]
	noisy.play("ab_test")
	var preview := noisy.report()
	check(absf(preview.retention - 0.85) <= 0.0425, "A/B improves next action preview")
	noisy.play("clean_data")
	near(noisy.state.base.integrity, 25, "clean data restores integrity")
	near(noisy.prediction_multiplier, 1, "A/B consumed by next action")
	near(a.score(), b.score(), "same seed and actions produce same score")
	test_balance_rules()
	test_revealed_resolution()
	test_full_rules()
	test_economy_scale()
	test_scores()
	test_remedy_reports()
	print("test_sim: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func card_by_id(sim: RefCounted, id: String) -> Dictionary:
	for card in sim.cards:
		if card.id == id:
			return card
	return {}

func test_remedy_reports() -> void:
	var source := Sim.new(130)
	for definition in source.events:
		var a := Sim.new(130)
		var b := Sim.new(130)
		for sim in [a, b]:
			sim.begin_week(false)
			sim.apply_event(definition)
			var hidden: Dictionary = sim.event_reports()[0]
			check(hidden.symptom == definition.symptom, "hidden symptom: " + definition.id)
			check(not hidden.has("root_cause") and not hidden.has("remedies"), "hidden report omits cause and remedies: " + definition.id)
			sim.hand = [card_by_id(sim, definition.revealed_by[0])]
			check(sim.play(definition.revealed_by[0]), "reveal accepted: " + definition.id)
			var revealed: Dictionary = sim.event_reports()[0]
			check(revealed.root_cause == definition.root_cause, "revealed cause: " + definition.id)
			check(revealed.remedies == definition.resolved_by, "remedies preserve data order: " + definition.id)
			# A caller must not be able to mutate event data through its report.
			revealed.remedies.clear()
			check(sim.event_reports()[0].remedies == definition.resolved_by, "remedies are a snapshot: " + definition.id)
		check(a.event_reports() == b.event_reports(), "same seed revealed reports: " + definition.id)
		for week in 7:
			check(a.finish_week() == b.finish_week(), "same seed settlement after reveal")
			a.begin_week()
			b.begin_week()
			check(a.hand == b.hand and a.event_reports() == b.event_reports(), "same seed progression after reveal")

func test_economy_scale() -> void:
	var sim := Sim.new(42, {}, 10)
	check(sim.config.initial.retention >= 0.75 and sim.config.initial.retention <= 0.85, "weekly initial retention range")
	check(sim.config.limits.retention[1] >= 0.92 and sim.config.limits.retention[1] <= 0.95, "weekly retention cap range")
	check(sim.config.win.demo.min_users >= 0.7 * sim.config.initial.users and sim.config.win.demo.min_users <= 0.8 * sim.config.initial.users, "absolute meaningful demo user gate")
	check(not sim.config.economy.has("full_cost_multiplier") and not sim.config.economy.has("full_card_cost_multiplier"), "no phase cost subsidies")
	var previous_chance := -1.0
	var previous_count := 0
	for phase in sim.config.phases:
		check(phase.event_chance > previous_chance and phase.event_count >= previous_count, "incident pressure increases by phase")
		previous_chance = phase.event_chance
		previous_count = phase.event_count
	sim.begin_week(false)
	var result := sim.finish_week()
	check(result.revenue < result.fixed_cost and result.fixed_cost - result.revenue < 0.01 * sim.config.initial.cash, "initial company loses slightly without action")
	check(sim.state.base.users >= 0.75 * sim.config.initial.users and sim.state.base.users < sim.config.initial.users, "initial company shrinks slowly")
	var ceiling := Sim.new(42, {}, 10)
	ceiling.state.base.cash = 1000000
	ceiling.state.base.retention = 1.0
	for week in 10:
		ceiling.begin_week(false)
		ceiling.finish_week()
	near(ceiling.state.base.users, 1000 * pow(0.95, 10), "retention alone cannot create users even at cap")
	check(ceiling.state.lost and not ceiling.state.won, "survival without enough users cannot win")
	var campaign := card_by_id(sim, "ads_campaign")
	near(campaign.budget, campaign.effects[0].add, "advertising spend equals its real budget")

func test_revealed_resolution() -> void:
	for index in 8:
		for next_week in [false, true]:
			var sim := Sim.new(901)
			sim.state.base.cash = 1000000
			sim.begin_week(false)
			var definition: Dictionary = sim.events[index]
			var remedy: String = definition.resolved_by[0]
			var analysis: String = definition.revealed_by[0]
			sim.apply_event(definition)
			sim.hand = [card_by_id(sim, remedy)]
			check(sim.play(remedy), "hidden remedy remains playable: " + definition.id)
			check(sim.active_events.size() == 1 and sim.state.resolved == 0, "hidden remedy cannot resolve or score")
			check(sim.upgrade_plays.get(remedy, 0) == 1, "hidden remedy applies and counts normal card play")
			if remedy == "onboarding_redesign":
				near(sim.state.base.retention, 0.93, "hidden remedy retains its own upgrade")
			sim.state.energy = 3
			sim.hand = [card_by_id(sim, analysis)]
			check(sim.play(analysis), "analysis after blind remedy")
			check(sim.state.resolved == 0 and sim.event_reports()[0].has("root_cause"), "analysis reveals without retroactive resolution")
			if next_week:
				sim.finish_week()
				sim.begin_week(false)
				check(sim.event_reports()[0].has("root_cause"), "reveal persists across weeks")
			sim.hand = [card_by_id(sim, remedy)]
			check(sim.play(remedy), "revealed remedy playable in same or following week")
			check(sim.active_events.is_empty() and sim.state.resolved == 1, "only valid removal increments resolved")
			check(sim.state.modifiers.all(func(effect): return effect.source == 0), "resolution removes incident modifiers only")
			sim.state.energy = 3
			sim.hand = [card_by_id(sim, remedy)]
			sim.play(remedy)
			check(sim.state.resolved == 1, "resolved incident cannot count twice")
	var expired := Sim.new(901)
	expired.state.base.cash = 1000000
	expired.begin_week(false)
	expired.apply_event(expired.events[0])
	var end_week: int = expired.active_events[0].end
	while expired.state.week < end_week:
		expired.finish_week()
		expired.begin_week(false)
	check(expired.active_events.is_empty() and expired.state.resolved == 0, "hidden event expires without resolution credit")

func test_full_rules() -> void:
	for horizon in [10, 30]:
		for gate in ["min_cash", "min_ratio", "min_users"]:
			var sim := Sim.new(42, {}, horizon)
			sim.config = sim.config.duplicate(true)
			sim.state.week = horizon - 1
			sim.state.base.cash = 1000000
			var key := "demo" if horizon == 10 else "full"
			sim.config.win[key][gate] = 1000000000
			sim.begin_week(false)
			sim.finish_week()
			check(sim.state.lost and not sim.state.won, "independent horizon gate: " + key + "/" + gate)
	var full := Sim.new(42)
	full.state.week = 10
	full.begin_week(false)
	full.hand = [full.cards[7]]
	var cash_before: float = full.state.base.cash
	check(full.play("ads_campaign"), "full campaign playable")
	near(cash_before - full.state.base.cash, full.cards[7].budget, "full card pays same budget as demo")
	var settlement := full.finish_week()
	near(settlement.fixed_cost, full.state.value("fixed_cost", full.config) + full.config.economy.cost_per_user * full.state.base.users, "full operating costs use common economy")
	near(settlement.cash, cash_before - full.cards[7].budget + settlement.revenue - settlement.fixed_cost, "full campaign not charged again during settlement")

func test_balance_rules() -> void:
	var sim := Sim.new(42)
	sim.begin_week(false)
	for index in [4, 5, 6, 10]:
		var card: Dictionary = sim.cards[index]
		var effect: Dictionary = card.effects[0]
		var initial: float = sim.state.base[effect.stat]
		for repetition in 3:
			sim.hand = [card]
			sim.state.energy = 3
			sim.state.base.cash = 1000000
			check(sim.play(card.id), "upgrade remains playable to resolve future incidents")
			near(sim.state.base[effect.stat] if index != 10 else sim.state.modifiers.back().add,
				initial + float(effect.add) * (2.0 - pow(0.5, repetition)) if index != 10 else float(effect.add) * pow(0.5, repetition),
				"upgrade effect halves on each repeat including delayed SEO")
		near(sim.upgrade_plays[card.id], 3, "successful upgrades counted")
	# A rejected play must not consume the next upgrade's strength.
	sim.hand = [sim.cards[5]]
	sim.state.energy = 0
	check(not sim.play("onboarding_redesign"), "reject upgrade without energy")
	near(sim.upgrade_plays.onboarding_redesign, 3, "rejected upgrade not counted")
	sim.state.energy = 3
	sim.apply_event(sim.events[0])
	sim.hand = [sim.cards[0], sim.cards[5]]
	sim.play("sql_deep_dive")
	sim.state.energy = 3
	check(sim.play("onboarding_redesign"), "repeated upgrade can still resolve")
	check(sim.active_events.is_empty() and sim.state.resolved == 1, "diminishing does not weaken resolution")
	for stat in ["retention", "conversion", "cac", "fixed_cost"]:
		sim.state.base[stat] = 1000000
		near(sim.state.value(stat, sim.config), sim.config.limits[stat][1], "upper stat cap")
		sim.state.base[stat] = -1000000
		near(sim.state.value(stat, sim.config), sim.config.limits[stat][0], "lower stat cap")
	# Settle the final week with a controlled economy to test each independent gate.
	for failed_gate in ["none", "min_cash", "min_ratio", "min_users"]:
		var demo := Sim.new(42, {}, 10)
		demo.config = demo.config.duplicate(true)
		demo.state.week = 9
		demo.state.base.cash = 1000000
		demo.state.base.users = 2000
		demo.state.base.retention = 0.95
		if failed_gate != "none":
			demo.config.win.demo[failed_gate] = 1000000000
		demo.begin_week(false)
		demo.finish_week()
		check(demo.state.won == (failed_gate == "none"), "demo final gate " + failed_gate)
		check(demo.state.lost != demo.state.won, "horizon always ends in exactly one outcome")
		check(demo.score() >= demo.config.score.win_bonus if demo.state.won else demo.score() <= demo.config.score.loss_cap, "gate failure preserves score ordering")
	var definitions := Sim.new()
	check(definitions.cards.size() == 12 and definitions.events.size() == 8, "content counts preserved")
	check(definitions.config.weeks.demo == 10, "demo remains ten weeks")

func test_scores() -> void:
	var fixture := Sim.new(104)
	# Isolate score arithmetic from gameplay stat caps.
	fixture.config = fixture.config.duplicate(true)
	fixture.config.limits.retention[1] = 0.98
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

func test_use_tool() -> void:
	var sim := Sim.new(42)
	check(not sim.use_tool("sql_deep_dive"), "tool requires open week")
	sim.begin_week(false)
	var hand_before: Array = sim.hand.duplicate(true)
	var cash: float = sim.state.base.cash
	check(not sim.use_tool("onboarding_redesign"), "reject non analysis tool")
	check(not sim.use_tool("missing"), "reject unknown tool")
	check(sim.hand == hand_before and sim.state.base.cash == cash, "rejection atomic")
	sim.apply_event(sim.events[0])
	check(sim.use_tool("sql_deep_dive"), "analysis available outside hand")
	check(sim.hand == hand_before, "tool never consumes hand")
	near(sim.state.base.cash, cash - 500, "tool budget")
	check(sim.active_events[0].revealed, "tool reveals cause")
	check(sim.use_tool("ab_test"), "hypothesis tool")
	near(sim.prediction_multiplier, 0.1, "tool prediction effect")
	var integrity: float = sim.state.base.integrity
	check(sim.use_tool("clean_data"), "clean tool")
	near(sim.state.base.integrity, integrity + 25, "tool applies effects")
	sim.state.energy = 0
	cash = sim.state.base.cash
	check(not sim.use_tool("clean_data") and sim.state.base.cash == cash, "energy refusal atomic")
	sim.state.energy = 3
	sim.state.base.cash = 0
	check(not sim.use_tool("sql_deep_dive"), "budget refusal")
	sim.state.base.cash = cash
	sim.finish_week()
	check(not sim.use_tool("sql_deep_dive"), "closed week tool refusal")
	var discounted := Sim.new(42)
	discounted.begin_week(false)
	discounted.state.base.cash = 60
	var original_hand: Array = discounted.hand.duplicate(true)
	var original_energy: int = discounted.state.energy
	check(discounted.use_tool("sql_deep_dive", 60), "override affordable when default is not")
	near(discounted.state.base.cash, 0, "override charges exact amount")
	check(discounted.state.energy == original_energy and discounted.hand == original_hand, "override preserves energy cost and hand")
	check(not discounted.use_tool("ab_test", 80), "override rejects insufficient budget")
	check(discounted.state.energy == original_energy and discounted.state.base.cash == 0, "override refusal atomic")
	check(discounted.use_tool("ab_test", 0), "zero override supported")
	check(not discounted.use_tool("onboarding_redesign", 0), "override cannot bypass category")
	var free_energy := Sim.new(42)
	free_energy.begin_week(false)
	free_energy.state.energy = 0
	var free_cash: float = free_energy.state.base.cash
	check(not free_energy.use_tool("clean_data") and free_energy.state.base.cash == free_cash, "default still requires and spends energy")
	check(free_energy.use_tool("clean_data", -1.0, false) and free_energy.state.energy == 0, "spend_energy=false neither requires nor spends energy")
	near(free_energy.state.base.cash, free_cash - 300, "spend_energy=false still charges the card budget")
	check(not free_energy.use_tool("onboarding_redesign", 0, false), "spend_energy=false cannot bypass category")

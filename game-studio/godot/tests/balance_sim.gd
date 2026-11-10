extends SceneTree
const Sim = preload("res://scripts/sim/simulation.gd")

func _init() -> void:
	var started := Time.get_ticks_msec()
	var template := Sim.new()
	var count := int(template.config.balance.games)
	var horizons := [10, 30]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			count = int(argument.trim_prefix("--games="))
		if argument.begins_with("--seed="):
			template.config.balance.seed = int(argument.trim_prefix("--seed="))
		if argument.begins_with("--weeks="):
			horizons = [int(argument.trim_prefix("--weeks="))]
	if count <= 0 or horizons.any(func(w): return w not in [10, 30]):
		quit(1)
		return
	print("weeks | strategy | games | win % | loss median week | losses before 15 % | cash min/p25/p50/p75/max | winner retention % / conversion % / ratio")
	for weeks in horizons:
		for strategy in ["random", "ads_only", "optimization_only", "balanced", "analyst"]:
			var wins := 0
			var early := 0
			var losses: Array = []
			var cash: Array = []
			var retention: Array = []
			var conversion: Array = []
			var ratios: Array = []
			for game in count:
				var sim := Sim.new(int(template.config.balance.seed) + game, {"config":template.config,"cards":template.cards,"events":template.events}, weeks)
				while not sim.state.lost and not sim.state.won:
					sim.begin_week()
					if strategy == "analyst":
						play_analyst(sim)
					var choices: Array = []
					if strategy == "random":
						var pool := sim.hand.duplicate()
						while not pool.is_empty():
							var index := sim.rng.randi_range(0, pool.size() - 1)
							choices.append(pool[index].id)
							pool.remove_at(index)
					else:
						choices = template.config.balance.priorities["balanced" if strategy == "analyst" else strategy]
					for id in choices:
						if strategy == "analyst" and id in ["sql_deep_dive", "funnel_report", "ab_test"]:
							continue
						if strategy in ["balanced", "analyst"] and id == "influencer_campaign" and sim.report().retention < 0.7:
							continue
						if strategy == "random" or useful_upgrade(sim, id):
							sim.play(id)
					sim.finish_week()
				if sim.state.won:
					wins += 1
					retention.append(100 * sim.state.value("retention", sim.config))
					conversion.append(100 * sim.state.value("conversion", sim.config))
					ratios.append(sim.state.ratio(sim.config))
				else:
					losses.append(sim.state.week)
					if sim.state.week < 15:
						early += 1
				cash.append(sim.state.base.cash)
				if count == 1:
					print("sample users=%.2f ratio=%.2f" % [sim.state.base.users, sim.state.ratio(sim.config)])

			cash.sort()
			var quantiles := []
			for q in template.config.balance.quantiles:
				quantiles.append(snappedf(cash[int(round(q * (count - 1)))], 0.01))
			print("%d | %s | %d | %.2f | %s | %.2f | %s | %s / %s / %s" % [weeks,strategy,count,100.0*wins/count,median_of(losses),100.0*early/count,str(quantiles),median_of(retention),median_of(conversion),median_of(ratios)])
	print("elapsed_seconds=%.3f" % ((Time.get_ticks_msec()-started)/1000.0))
	quit(0)

# Match public symptoms to candidate definitions; ambiguous symptoms reveal both candidates.
# Only a revealed cause can select a remedy. No true company state or hidden instance is read.
func play_analyst(sim: RefCounted) -> void:
	for visible in sim.event_reports():
		if visible.has("root_cause"):
			continue
		for definition in sim.events:
			if definition.symptom == visible.symptom:
				for id in definition.revealed_by:
					sim.play(id)
	for visible in sim.event_reports():
		if not visible.has("root_cause"):
			continue
		for definition in sim.events:
			if definition.root_cause == visible.root_cause:
				for id in definition.resolved_by:
					if sim.play(id):
						break

# Counts are public action history; remedies bypass this filter in play_analyst.
func useful_upgrade(sim: RefCounted, id: String) -> bool:
	for card in sim.cards:
		if card.id == id and card.get("diminishing", false):
			return sim.upgrade_plays.get(id, 0) < 3
	return true

func median_of(values: Array) -> String:
	if values.is_empty():
		return "n/a"
	values.sort()
	var middle := values.size() / 2
	var value := float(values[middle]) if values.size() % 2 else (float(values[middle - 1]) + float(values[middle])) / 2.0
	return "%.2f" % value

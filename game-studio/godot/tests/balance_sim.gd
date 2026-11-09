extends SceneTree
const Sim = preload("res://scripts/sim/simulation.gd")

func _init() -> void:
	var started := Time.get_ticks_msec()
	var template := Sim.new()
	var count := int(template.config.balance.games)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			count = int(argument.trim_prefix("--games="))
	if count <= 0:
		quit(1)
		return
	print("strategy | games | win % | loss median week | losses before 15 % | cash min/p25/p50/p75/max")
	for strategy in ["random", "ads_only", "optimization_only", "balanced"]:
		var wins := 0
		var early := 0
		var losses: Array = []
		var cash: Array = []
		for game in count:
			var sim := Sim.new(int(template.config.balance.seed) + game, {"config":template.config,"cards":template.cards,"events":template.events})
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
					choices = template.config.balance.priorities[strategy]
				for id in choices:
					sim.play(id)
				sim.finish_week()
			if sim.state.won:
				wins += 1
			else:
				losses.append(sim.state.week)
				if sim.state.week < 15:
					early += 1
			cash.append(sim.state.base.cash)
		cash.sort()
		losses.sort()
		var quantiles := []
		for q in template.config.balance.quantiles:
			quantiles.append(snappedf(cash[int(round(q * (count - 1)))], 0.01))
		var median = "n/a" if losses.is_empty() else str(median_of(losses))
		print("%s | %d | %.2f | %s | %.2f | %s" % [strategy,count,100.0*wins/count,median,100.0*early/count,str(quantiles)])
	print("elapsed_seconds=%.3f" % ((Time.get_ticks_msec()-started)/1000.0))
	quit(0)

func median_of(values: Array) -> float:
	var middle := values.size() / 2
	return float(values[middle]) if values.size() % 2 else (float(values[middle - 1]) + float(values[middle])) / 2.0

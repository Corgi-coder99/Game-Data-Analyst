extends RefCounted

var base: Dictionary
var modifiers: Array = []
var flags: Dictionary = {}
var week := 0
var energy := 0
var bad_ratio_weeks := 0
var resolved := 0
var lost := false
var won := false

func _init(initial: Dictionary) -> void:
	base = initial.duplicate(true)

func value(stat: String, config: Dictionary) -> float:
	var result := float(base.get(stat, 0.0))
	for effect in modifiers:
		if effect.stat == stat and effect.start <= week and effect.end > week:
			result += float(effect.add)
	if config.limits.has(stat):
		result = clampf(result, config.limits[stat][0], config.limits[stat][1])
	return result

func ratio(config: Dictionary) -> float:
	return value("arpu", config) / maxf(config.economy.churn_floor, 1.0 - value("retention", config)) / value("cac", config)

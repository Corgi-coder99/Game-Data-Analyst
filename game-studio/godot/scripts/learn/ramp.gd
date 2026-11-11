extends RefCounted
# T-035: difficulty ramp after the tutorial. The generator's own day ramp (config `ramp`) gives the base
# defect count, file count and file size. This adds a small adjustment from the player's mean skill level
# (1..5). XP only grows, so the ramp only goes up: below mean level 3.5 nothing changes (a new player sees
# exactly the generator's day ramp); from 3.5 one more defect and 10 percent larger files; from 4.5 two more
# defects and 20 percent larger files (never above max_dirt, files stay within the engine's 40..400 rows). It changes only what the generator builds from its own RNG stream; the world,
# the questions, the news, the answers and the balance are untouched. Deterministic: same levels, same day.
# Config: datasets.json `learn.ramp` (from_day, dirt and scale tables keyed by mean level, min/max defects).

# Largest threshold <= value from [[threshold, amount], ...].
static func _step(table: Array, value: float) -> float:
	var out := float(table[0][1])
	for row in table:
		if value >= float(row[0]): out = float(row[1])
	return out

# Returns {} (no change) or {dirt: int, scale_mult: float, min_dirt: int, max_dirt: int}.
static func adjust(learn_cfg: Dictionary, day: int, mean_level: float) -> Dictionary:
	var ramp: Dictionary = learn_cfg.get("ramp", {})
	if ramp.is_empty() or day < int(ramp.from_day): return {}
	return {"dirt": int(_step(ramp.dirt, mean_level)), "scale_mult": _step(ramp.scale, mean_level), "min_dirt": int(ramp.min_dirt), "max_dirt": int(ramp.max_dirt)}

extends RefCounted
# T-030: day score, profile statistics, achievements, all-time awards and Employee of the Month.
# Pure functions over the profile dictionary and data/meta.json; no clock, no file access.
const Clock = preload("res://scripts/meta/clock.gd")

# Day score from the public result parts only. Integer, so ties are exact.
static func day_score(result: Dictionary, cfg: Dictionary) -> int:
	var s: Dictionary = cfg.scoring
	var score := float(s.accuracy) * float(result.accuracy) + float(s.trust) * float(result.trust_delta)
	if int(result.bonus) > 0: score += float(s.bonus_flag)
	if result.timing == "late": score += float(s.late)
	elif result.timing == "missed": score += float(s.missed)
	return int(round(score))

static func rank_index(cfg: Dictionary, rank_id: String) -> int:
	return cfg.ranks.keys().find(rank_id)

static func rank_name(cfg: Dictionary, rank_id: String) -> String:
	return str(cfg.ranks.get(rank_id, rank_id))

# Folds one finished day into the profile statistics, reputation and history.
static func apply_day(profile: Dictionary, record: Dictionary, cfg: Dictionary) -> Dictionary:
	var result: Dictionary = record.result
	var stats: Dictionary = profile.stats
	var score := int(result.day_score)
	stats.days_total = int(stats.days_total) + 1
	stats.best_rank_index = maxi(int(stats.best_rank_index), rank_index(cfg, str(result.rank)))
	if result.timing == "on_time": stats.ontime_streak = int(stats.ontime_streak) + 1
	else: stats.ontime_streak = 0
	stats.best_ontime = maxi(int(stats.best_ontime), int(stats.ontime_streak))
	if record.inputs.confidence == str(cfg.awards_rules.honest_confidence):
		stats.honest_days = int(stats.honest_days) + 1
		if float(result.accuracy) >= 1.0: stats.honest_right = int(stats.honest_right) + 1
	if float(result.accuracy) >= 1.0 and float(result.evidence_quality) >= 0.99 and result.timing == "on_time": stats.perfect_days = int(stats.perfect_days) + 1
	if not record.inputs.evidence.is_empty() and float(result.evidence_quality) >= 0.5: stats.verified_days = int(stats.verified_days) + 1
	var best: Dictionary = stats.best_day
	if best.is_empty() or score > int(best.get("score", -999999)):
		stats.best_day = {"score": score, "date": record.date, "day_id": record.day_id}
	var gain := maxi(0, score / int(cfg.scoring.reputation_divisor))
	profile.reputation = int(profile.reputation) + gain
	profile.title = rank_name(cfg, str(result.rank))
	profile.history.append(record)
	var cap := int(cfg.profile.history_cap)
	while profile.history.size() > cap: profile.history.pop_front()
	return {"reputation_gain": gain}

static func rule_met(rule: Dictionary, profile: Dictionary) -> bool:
	var stats: Dictionary = profile.stats
	var value := int(rule.value)
	match str(rule.rule):
		"days_total": return int(stats.days_total) >= value
		"perfect_day": return int(stats.perfect_days) >= 1
		"verified": return int(stats.verified_days) >= 1
		"run_survived": return int(stats.runs_survived) >= 1
		"rank_index": return int(stats.best_rank_index) >= value
		"best_ontime": return int(stats.best_ontime) >= value
		"best_streak": return int(profile.best_streak) >= value
	return false

# Unlocks every achievement whose rule is met and that is not owned yet. Each is earned exactly once.
static func check_achievements(profile: Dictionary, cfg: Dictionary, date: String) -> Array:
	var fresh: Array = []
	for entry in cfg.achievements:
		if profile.achievements.has(entry.id): continue
		if rule_met(entry, profile):
			profile.achievements[entry.id] = date
			fresh.append(entry)
	return fresh

# The five all-time plaques: {id, name, earned, value, empty}.
static func hall(profile: Dictionary, cfg: Dictionary) -> Array:
	var stats: Dictionary = profile.stats
	var rules: Dictionary = cfg.awards_rules
	var out: Array = []
	for entry in cfg.awards:
		var item := {"id": entry.id, "name": entry.name, "empty": entry.empty, "earned": false, "value": ""}
		match str(entry.id):
			"streak":
				item.earned = int(profile.best_streak) >= 2
				item.value = "%d days" % int(profile.best_streak)
			"rank":
				item.earned = int(stats.best_rank_index) >= 0
				if item.earned: item.value = str(cfg.ranks.values()[int(stats.best_rank_index)])
			"best_day":
				var best: Dictionary = stats.best_day
				item.earned = not best.is_empty()
				if item.earned: item.value = "%d pts, %s" % [int(best.score), str(best.date)]
			"honest":
				var days := int(stats.honest_days)
				item.earned = days >= int(rules.honest_min_days) and float(stats.honest_right) / float(days) >= float(rules.honest_min_rate)
				item.value = "%d of %d right" % [int(stats.honest_right), days]
			"never_late":
				item.earned = int(stats.best_ontime) >= int(rules.never_late_days)
				item.value = "%d on time" % int(stats.best_ontime)
		out.append(item)
	return out

# Employee of the Month: sum of the best n days of the month by day score; ties by the sum of
# accuracy over those days, then by name. candidates = [{name, days: [{score, accuracy}]}].
static func pick_winner(candidates: Array, n: int) -> Dictionary:
	var best := {}
	for candidate in candidates:
		var days: Array = candidate.days.duplicate()
		days.sort_custom(func(a, b): return a.score > b.score or (a.score == b.score and a.accuracy > b.accuracy))
		var total := 0
		var accuracy := 0.0
		var used := mini(n, days.size())
		for i in used:
			total += int(days[i].score)
			accuracy += float(days[i].accuracy)
		var entry := {"name": candidate.name, "score": total, "accuracy": accuracy, "days": used}
		if used == 0: continue
		if best.is_empty() or total > best.score or (total == best.score and accuracy > best.accuracy) or (total == best.score and accuracy == best.accuracy and str(entry.name) < str(best.name)):
			best = entry
	return best

static func avatar_for(name: String, cfg: Dictionary) -> String:
	var sum := 0
	for i in name.length(): sum += name.unicode_at(i) * (i + 1)
	return str(cfg.avatars[sum % cfg.avatars.size()])

# Settles every finished month (before the month of `today`) that has history and no winner yet.
# Only the local profile competes today; an online board would feed more candidates into pick_winner.
static func settle_months(profile: Dictionary, cfg: Dictionary, today: String) -> Array:
	var current := Clock.month_key(today)
	var have := {}
	for winner in profile.winners: have[str(winner.month)] = true
	var months := {}
	for record in profile.history:
		var key := Clock.month_key(str(record.date))
		if key < current and not have.has(key): months[key] = true
	var keys: Array = months.keys()
	keys.sort()
	var fresh: Array = []
	for key in keys:
		var days: Array = []
		for record in profile.history:
			if Clock.month_key(str(record.date)) == key: days.append({"score": int(record.result.day_score), "accuracy": float(record.result.accuracy)})
		var picked := pick_winner([{"name": profile.display_name, "days": days}], int(cfg.monthly.best_n))
		if picked.is_empty(): continue
		var winner := {"month": key, "name": profile.display_name, "score": picked.score, "days": picked.days, "title": "Employee of the Month", "avatar": avatar_for(str(profile.display_name), cfg)}
		profile.winners.append(winner)
		fresh.append(winner)
	return fresh

extends "res://scripts/meta/score_sink.gd"
# T-030: the offline ScoreSink. Appends the day's record to the local profile, updates streak, reputation,
# statistics, achievements and the monthly winners, then saves the profile file.
const Awards = preload("res://scripts/meta/awards.gd")
var profile: RefCounted
var cfg: Dictionary
var clock: RefCounted
var attendance: RefCounted

func _init(profile_ref: RefCounted, config: Dictionary, clock_ref: RefCounted, attendance_ref: RefCounted) -> void:
	profile = profile_ref
	cfg = config
	clock = clock_ref
	attendance = attendance_ref

func submit_day(record: Dictionary) -> Dictionary:
	var data: Dictionary = profile.data
	for old in data.history:
		if str(old.day_id) == str(record.day_id): return {"toasts": [], "duplicate": true}
	var toasts: Array = []
	var streak: Dictionary = attendance.register_finished_day()
	var gain: Dictionary = Awards.apply_day(data, record, cfg)
	if bool(streak.get("frozen", false)): toasts.append("Streak freeze used. Your streak is safe.")
	if bool(streak.get("freeze_earned", false)): toasts.append("Streak freeze earned!")
	for entry in Awards.check_achievements(data, cfg, clock.today()): toasts.append("Achievement: " + str(entry.name))
	for winner in Awards.settle_months(data, cfg, clock.today()): toasts.append("Employee of the Month: " + str(winner.month))
	profile.save()
	return {"toasts": toasts, "score": int(record.result.day_score), "reputation_gain": int(gain.reputation_gain), "streak": int(streak.streak), "duplicate": false}

func finish_run(status: Dictionary) -> Dictionary:
	var data: Dictionary = profile.data
	var toasts: Array = []
	if str(status.get("ending", "")) == "survived": data.stats.runs_survived = int(data.stats.runs_survived) + 1
	for entry in Awards.check_achievements(data, cfg, clock.today()): toasts.append("Achievement: " + str(entry.name))
	profile.save()
	return {"toasts": toasts}

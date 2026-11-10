extends RefCounted
# T-030: streaks, leave days and the simulated attendance ladder (docs/DESIGN-online.md section 5).
# Only local meta values change: reputation points, a small fine and a welcome-back bonus that are
# applied to the NEXT run's starting wallet, and the title. Nothing touches the simulation or the score.
const Clock = preload("res://scripts/meta/clock.gd")
var profile: RefCounted
var cfg: Dictionary
var clock: RefCounted

func _init(profile_ref: RefCounted, config: Dictionary, clock_ref: RefCounted) -> void:
	profile = profile_ref
	cfg = config
	clock = clock_ref

func rules() -> Dictionary:
	return cfg.attendance

# ---- leave -----------------------------------------------------------------------------------

func is_covered(date: String) -> bool:
	for entry in profile.data.leave:
		if str(entry.date) == date: return true
	return false

func leave_used(month_key: String) -> int:
	var used := 0
	for entry in profile.data.leave:
		if Clock.month_key(str(entry.date)) == month_key: used += 1
	return used

func leave_left(date: String) -> int:
	return maxi(0, int(rules().leave_allowance_per_month) - leave_used(Clock.month_key(date)))

func reason_ids() -> Array:
	return cfg.leave_reasons.map(func(r): return r.id)

# Marks 1..3 consecutive days covered, starting today or later (at most 14 days ahead), for a reason
# from the list. All or nothing: a request that would exceed the monthly allowance is refused.
func request_leave(start: String, days: int, reason_id: String) -> Dictionary:
	var r := rules()
	if not Clock.is_valid(start): return {"ok": false, "error": "bad_date"}
	if days < 1 or days > int(r.leave_max_days): return {"ok": false, "error": "bad_days"}
	if not reason_id in reason_ids(): return {"ok": false, "error": "bad_reason"}
	var today: String = clock.today()
	var offset := Clock.diff(today, start)
	if offset < 0: return {"ok": false, "error": "past"}
	if offset > int(r.leave_lookahead_days): return {"ok": false, "error": "too_far"}
	var fresh: Array = []
	for i in days:
		var date := Clock.add_days(start, i)
		if not is_covered(date): fresh.append(date)
	var added := {}
	for date in fresh: added[Clock.month_key(date)] = int(added.get(Clock.month_key(date), 0)) + 1
	for key in added:
		if leave_used(key) + int(added[key]) > int(r.leave_allowance_per_month): return {"ok": false, "error": "allowance"}
	for date in fresh: profile.data.leave.append({"date": date, "reason": reason_id})
	return {"ok": true, "covered": fresh}

# ---- missed days -----------------------------------------------------------------------------

# Calendar days strictly between the last finished day and today that no leave covers.
func missed_days(today: String) -> int:
	var last: String = profile.data.last_finished_day
	if last == "": return 0
	var missed := 0
	for i in range(1, Clock.diff(last, today)):
		if not is_covered(Clock.add_days(last, i)): missed += 1
	return missed

func step_for(missed: int) -> Dictionary:
	var found := {}
	for step in rules().steps:
		if missed >= int(step.missed): found = step
	return found

func step_index(step_id: String) -> int:
	var steps: Array = rules().steps
	for i in steps.size():
		if steps[i].id == step_id: return i
	return -1

# Runs the ladder for `today`. Returns {} when nothing is due (attendance switched off, no history,
# no missed day, or this step was already applied for this last-finished day). Otherwise applies the
# local penalties once and returns what the HR letter has to show.
func evaluate() -> Dictionary:
	var data: Dictionary = profile.data
	if not data.settings.attendance: return {}
	var today: String = clock.today()
	var missed := missed_days(today)
	var step := step_for(missed)
	if step.is_empty(): return {}
	var last: String = data.last_finished_day
	var applied := step_index(str(data.ladder.step)) if str(data.ladder.for_day) == last else -1
	if step_index(step.id) <= applied: return {}
	var before_rep := int(data.reputation)
	var loss := int(step.rep_flat) + int(floor(float(before_rep) * float(step.rep_pct) / 100.0))
	data.reputation = maxi(0, before_rep - loss)
	var fine_raw := int(round(float(rules().start_wallet) * float(step.fine_pct) / 100.0))
	var fine_before := int(data.pending_fine)
	data.pending_fine = mini(int(rules().fine_total_cap), fine_before + fine_raw)
	data.pending_bonus = maxi(int(data.pending_bonus), int(step.bonus))
	var rehired: bool = step.id == "rehire"
	if rehired:
		data.title = cfg.ranks.values()[0]
		data.streak = 0
		data.stats.rehired = int(data.stats.rehired) + 1
	data.ladder = {"for_day": last, "step": step.id}
	var line_count: int = cfg.letters[step.id].lines.size()
	var pick: int = (Clock.to_days(today) + step_index(step.id)) % line_count
	return {"step": step.id, "missed": missed, "rep_loss": before_rep - int(data.reputation), "fine": int(data.pending_fine) - fine_before, "bonus": int(data.pending_bonus), "rehired": rehired, "line_index": pick, "date": today}

# ---- streak ----------------------------------------------------------------------------------

# Called when a day is finished today. Returns {streak, frozen, freeze_earned}. Leave-covered gaps keep
# the streak; one uncovered missed day can be bridged by a streak freeze item.
func register_finished_day() -> Dictionary:
	var data: Dictionary = profile.data
	var today: String = clock.today()
	var last: String = data.last_finished_day
	if last == today: return {"streak": int(data.streak), "frozen": false, "freeze_earned": false, "new_day": false}
	var frozen := false
	if last == "":
		data.streak = 1
	else:
		var missed := missed_days(today)
		if missed == 0:
			data.streak = int(data.streak) + 1
		elif int(data.freezes) > 0 and missed <= 1:
			data.freezes = int(data.freezes) - 1
			data.streak = int(data.streak) + 1
			frozen = true
		else:
			data.streak = 1
	data.best_streak = maxi(int(data.best_streak), int(data.streak))
	data.last_finished_day = today
	var earned := false
	var every := int(rules().freeze_streak)
	if int(data.streak) % every == 0 and int(data.freezes) < int(rules().freeze_cap):
		data.freezes = int(data.freezes) + 1
		earned = true
	return {"streak": int(data.streak), "frozen": frozen, "freeze_earned": earned, "new_day": true}

# ---- next run -------------------------------------------------------------------------------

# Applies the pending fine and welcome-back bonus to a freshly started life (once), then clears them.
func apply_to_run(life: RefCounted) -> Dictionary:
	var data: Dictionary = profile.data
	var bonus := int(data.pending_bonus)
	var fine := int(data.pending_fine)
	if bonus > 0: life.earn(bonus, "bonus", "welcome back")
	var paid := 0
	if fine > 0: paid = life.charge_up_to(fine, "fine", "attendance fine")
	data.pending_bonus = 0
	data.pending_fine = 0
	return {"bonus": bonus, "fine": paid}

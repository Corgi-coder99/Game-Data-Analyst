extends RefCounted

var rank := 0
var trust: float
var warnings := 0
var demotions := 0
var personal_pay := 0.0
var fired := false
var positive_delta := 0.0
var _tenure := 0
var _correct := 0
var _low_days := 0
var _config: Dictionary

func _init(config: Dictionary) -> void:
	_config = config
	trust = float(config.career.initial_trust)

func adoption() -> float:
	return lerpf(_config.career.adopt_min, _config.career.adopt_max, trust / 100.0)

func update(result: Dictionary) -> Dictionary:
	var c: Dictionary = _config.career
	var before := trust
	trust = clampf(trust + float(result.delta), 0, 100)
	positive_delta += maxf(0, result.delta)
	_tenure += 1
	_correct = _correct + 1 if result.acc >= 1 else 0
	_low_days = _low_days + 1 if trust <= c.demote else 0
	var salary: float = _config.ranks[rank].salary
	var bonus := salary * float(c.bonus_fraction) if result.acc >= 1 and result.ev >= 0.5 else 0.0
	personal_pay += salary + bonus
	if before > c.warning and trust <= c.warning: warnings += 1
	# Low trust must persist before dismissing an intern. A correct report
	# never triggers this sanction, even while recovering from earlier errors.
	# Firing is tested before demotion can reset trust.
	if trust <= 0 or (rank == 0 and result.acc < 1 and _low_days >= int(c.low_trust_days)):
		fired = true
	elif trust <= c.demote and result.acc == 0 and rank > 0:
		rank -= 1
		demotions += 1
		trust = float(c.reset_demotion)
		_low_days = 0
		_tenure = 0
		if demotions >= int(c.max_demotions): fired = true
	elif rank < _config.ranks.size() - 1 and trust >= _config.ranks[rank].promote and _correct >= int(c.correct_streak) and _tenure >= int(c.minimum_days):
		rank += 1
		# A correct report must never reduce trust, including on promotion.
		trust = maxf(trust, float(c.reset_promotion))
		_tenure = 0
	return {"bonus":bonus,"rank":_config.ranks[rank].id,"trust":trust,"fired":fired}

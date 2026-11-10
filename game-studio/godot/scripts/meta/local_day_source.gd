extends "res://scripts/meta/day_source.gd"
# T-030: the offline DaySource. The daily seed is derived from the calendar date, so the same date gives
# the same scenario for everyone (the future online mode will publish the same seed from a server).
# This is the single place of the meta layer that reads the finished day's review; it copies only the
# public result parts the review screen shows. The answer, the news labels and the scenario never leave it.
var clock: RefCounted

func _init(clock_ref: RefCounted) -> void:
	clock = clock_ref

func date() -> String:
	return clock.today()

static func seed_for_date(date_string: String) -> int:
	var digits := int(date_string.replace("-", ""))
	return int(absi(digits * 2654435761 + 12345) % 1000000)

func seed_for(mode: String) -> int:
	if mode == "daily": return seed_for_date(clock.today())
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi() % 1000000

func reveal(game: RefCounted, day: int, before: Dictionary, after: Dictionary) -> Dictionary:
	var review: Dictionary = game.review(day)
	if review.has("error") or not review.has("result"): return {}
	var career: Dictionary = review.career
	var bonus := roundi(float(career.bonus))
	var pay := roundi(float(after.personal_pay) - float(before.get("personal_pay", after.personal_pay))) - bonus
	return {
		"submit_minutes": int(review.submit_minutes),
		"result": {
			"accuracy": float(review.result.acc),
			"evidence_quality": float(review.result.ev),
			"trust_delta": float(review.result.delta),
			"timing": str(review.timing),
			"pay": pay,
			"bonus": bonus,
			"rank": str(career.rank),
			"trust": roundi(float(career.trust)),
		},
	}

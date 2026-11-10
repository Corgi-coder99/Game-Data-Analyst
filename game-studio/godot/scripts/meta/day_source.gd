extends RefCounted
# T-030: DaySource is where a day's seed and its revealed result come from. This base class is the
# interface (what an online DaySource must provide); local_day_source.gd is the offline implementation.
# The game flow only calls these methods, so a server-backed source can replace it later.

# Seed for a run mode: "daily" (the calendar date) or "run" (a fresh run).
func seed_for(_mode: String) -> int:
	return 0

# The calendar date the source works with (YYYY-MM-DD).
func date() -> String:
	return ""

# The public result parts of a finished day, once the game has revealed it to the player:
# {"submit_minutes": int, "result": {accuracy, evidence_quality, trust_delta, timing, pay, bonus, rank, trust}}.
func reveal(_game: RefCounted, _day: int, _before: Dictionary, _after: Dictionary) -> Dictionary:
	return {}

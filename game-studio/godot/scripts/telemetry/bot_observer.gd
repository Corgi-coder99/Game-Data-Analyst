extends RefCounted
# Delegates public calls unchanged; records their results for the headless generator.
var world: RefCounted
var log: RefCounted

func _init(world_ref: RefCounted, playlog: RefCounted) -> void:
	world = world_ref
	log = playlog

func status() -> Dictionary: return world.status()
func question_today() -> Dictionary: return world.question_today()
func news_today() -> Array: return world.news_today()
func hand() -> Array: return world.hand()
func tools() -> Array: return world.tools()
func report_snapshot() -> Dictionary: return world.report_snapshot()
func review(day: int) -> Dictionary: return world.review(day)

func begin_day(bonus: int = 0) -> void:
	world.begin_day(bonus)
	log.day_start(status(), question_today(), news_today())

func verify(uid: String, tool: String) -> Dictionary:
	var item := {}
	for news in news_today():
		if news.uid == uid:
			item = news
			break
	var result: Dictionary = world.verify(uid, tool)
	log.verification(status(), tool, result, item)
	return result

func wait_for_data(minutes: int = -1) -> Dictionary:
	var result: Dictionary = world.wait_for_data(minutes)
	log.time_spent(status(), false)
	return result

func spend_minutes(minutes: int) -> Dictionary:
	var result: Dictionary = world.spend_minutes(minutes)
	log.time_spent(status(), true)
	return result

func spend_analysis_energy(amount: int) -> Dictionary:
	return world.spend_analysis_energy(amount)

func submit_report(report: Dictionary) -> Dictionary:
	var result: Dictionary = world.submit_report(report)
	if result.get("ok", false): log.report_submit(status(), report)
	return result

func end_day() -> Dictionary:
	var result: Dictionary = world.end_day()
	if result.get("ok", false): log.day_end(status(), review(int(result.day)))
	return result

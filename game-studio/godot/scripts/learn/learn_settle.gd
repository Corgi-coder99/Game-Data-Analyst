extends RefCounted
# T-035: review-only. Settles one finished day into the learner's profile state: skill XP and level-ups,
# learning events (achievements), Handbook cards of the day's cases, tutorial progress.
# Called once per day by the flow, after the day ended, with the review records.
const Content = preload("res://scripts/learn/content.gd")
const Skills = preload("res://scripts/learn/skills.gd")
const CaseMap = preload("res://scripts/learn/case_map.gd")
const Loader = preload("res://scripts/data.gd")

# data_review: DataGame.review(day); game_result: WorldGame.review(day).result; submission: the sent report.
# Returns {gains, levelups: [{skill, from, to}], new_cards: [ids], new_events: [ids], solved, tutorial_day, graduated}.
static func settle(learn: RefCounted, data_review: Dictionary, game_result: Dictionary, submission: Dictionary, day: int, tutorial_day: bool) -> Dictionary:
	var files: Array = data_review.get("files", [])
	var award: Dictionary = Skills.award(files, game_result, submission, learn.cfg)
	var levelups: Array = []
	for skill in Content.SKILLS:
		var r: Dictionary = learn.add_xp(skill, int(award.gains[skill]))
		if int(r.to) > int(r.from): levelups.append({"skill": skill, "from": r.from, "to": r.to})
	var new_events: Array = []
	for id in award.events:
		if learn.bump_event(id): new_events.append(id)
	var reached_three := false
	for l in levelups:
		if int(l.to) >= 3: reached_three = true
	if reached_three and learn.bump_event("skill_level_3"): new_events.append("skill_level_3")
	var new_cards: Array = []
	var solved := false
	for f in files:
		var c: Dictionary = Content.case_by_id(str(f.get("case_id", "")))
		new_cards.append_array(learn.unlock_for_case(c))
		# Every trap the coaching explains opens its own case cards too.
		for e in f.grade.cleaning.entries:
			var trap_case: Dictionary = CaseMap.by_trap(Content.trap_of(str(e.type)), str(f.get("name", "")))
			new_cards.append_array(learn.unlock_for_case(trap_case))
		if float(f.grade.total) >= float(learn.cfg.tutorial.solved): solved = true
	var graduated := false
	if tutorial_day and learn.tutorial_active():
		if solved: learn.mark_tutorial_day(day)
		if learn.tutorial_days_done() >= int(learn.cfg.tutorial.days):
			learn.set_tutorial("done")
			graduated = true
			if learn.bump_event("tutorial_graduate"): new_events.append("tutorial_graduate")
	return {"gains": award.gains, "levelups": levelups, "new_cards": new_cards, "new_events": new_events, "solved": solved, "tutorial_day": tutorial_day, "graduated": graduated, "events": award.events}

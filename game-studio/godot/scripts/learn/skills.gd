extends RefCounted
# T-035: review-only. Turns the graded analysis of a finished day into skill XP and learning events.
# Pure: it reads the review record and the player's submission, it changes nothing. LearnState applies it.
const Content = preload("res://scripts/learn/content.gd")
# Which skill a correct finding trains.
const FINDING_SKILL := {"metric_change": "statistics", "top_category": "statistics", "ab_significant": "statistics", "top_region": "statistics",
	"spike_error": "causality", "entry_error_date": "causality", "biggest_dropoff": "causality", "ab_winner": "causality", "better_version": "causality"}

# review_files: DataGame.review(day).files (with grade). result: WorldGame.review(day).result (acc).
# submission: the sent report. Returns {gains: {skill: int}, reasons: [{skill, xp, type}], events: [ids]}.
static func award(review_files: Array, result: Dictionary, submission: Dictionary, learn_cfg: Dictionary) -> Dictionary:
	var table: Dictionary = learn_cfg.skills.xp
	var gains := {}
	for skill in Content.SKILLS: gains[skill] = 0
	var events: Array = []
	var reasons: Array = []
	var attached: Array = submission.get("analysis", {}).get("attachments", [])
	for f in review_files:
		var grade: Dictionary = f.grade
		var c: Dictionary = grade.cleaning
		if int(c.defect_rows) > 0 and int(c.missed_rows) == 0 and int(c.wrongly_removed) + int(c.wrongly_changed) == 0: events.append("first_clean")
		for e in c.entries:
			var rows := maxi(1, int(e.rows))
			var xp := int(floor(float(table.entry_fixed) * float(e.fixed) / float(rows)))
			if xp > 0:
				gains.data_cleaning += xp
				reasons.append({"skill": "data_cleaning", "xp": xp, "type": str(e.type)})
			if int(e.rows) > 0 and int(e.fixed) == int(e.rows):
				if e.type == "outliers": events.append("sharp_eye")
				if e.type == "duplicates": events.append("dup_hunter")
		if grade.chart.present:
			var clean: bool = grade.chart.flags.is_empty()
			gains.charts += int(table.chart_clean if clean else table.chart_flagged)
			if clean:
				for item in attached:
					if item is Dictionary and item.get("file_id", "") == f.id and item.get("type", "") == "chart" and item.get("spec", {}).get("type", "") == "bar":
						events.append("honest_axis")
		for item in grade.findings.items:
			var skill: String = FINDING_SKILL.get(str(item.id), "statistics")
			if float(item.score) >= 1.0:
				gains[skill] += int(table.finding_right)
				if item.id == "metric_change": events.append("no_cherry_picking")
				if item.id == "ab_significant": events.append("healthy_skepticism")
			elif float(item.score) > 0.0:
				gains[skill] += int(table.finding_close)
	if not review_files.is_empty():
		var acc := float(result.get("acc", 0.0))
		var conf := str(submission.get("confidence", ""))
		var calibrated := 0
		if acc >= 1.0: calibrated = int(table.right_high if conf == "cao" else table.right_other)
		elif acc > 0.0: calibrated = int(table.partial_mid if conf == "vua" else table.partial_other)
		elif conf == "thap": calibrated = int(table.wrong_low)
		elif conf == "vua": calibrated = int(table.wrong_mid)
		gains.communication += calibrated
	var unique: Array = []
	for id in events:
		if not unique.has(id): unique.append(id)
	return {"gains": gains, "reasons": reasons, "events": unique}

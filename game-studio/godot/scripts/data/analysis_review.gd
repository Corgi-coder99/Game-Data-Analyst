extends RefCounted
# T-034: turns DataGame.review(day) into the lines of the review step "Your analysis".
# Review code: it reads the hidden record, so it is only used after the day has ended.
const Forms = preload("res://scripts/data/step_forms.gd")
const Loader = preload("res://scripts/data.gd")
const MAX_LINES := 16
# Which case of data/cases.json teaches each defect type of the generator (minimal mapping, T-035 extends it).
const DIRT_CASE := {"duplicates":"case_duplicate_export", "category_typos":"case_category_typos", "missing_zero":"case_missing_as_zero", "missing_blank":"case_missing_as_zero", "missing_na":"case_missing_as_zero", "mixed_units":"case_mixed_currency", "mixed_dates":"case_date_timezone", "outliers":"case_entry_error_vs_spike", "late_partial":"case_late_data", "test_accounts":"case_test_accounts", "subtotal_rows":"case_subtotal_rows", "repeated_header":"case_subtotal_rows", "refunds_negative":"case_negative_refunds", "join_key_mismatch":"case_join_mismatch"}
const DIR_WORDS := {"tang":"up", "giam":"down", "ngang":"flat"}

static func value_text(value: Variant) -> String:
	if value == null: return "skipped"
	if value is Dictionary: return "%s, %s %%" % [DIR_WORDS.get(value.get("direction", ""), "?"), value.get("band", "?")]
	if value is bool: return "yes" if value else "no"
	return str(value)

static func case_for(dirt: Array, missed: Array) -> Dictionary:
	var order: Array = missed + dirt
	var cases: Array = Loader.load_json("res://data/cases.json").cases
	var cards: Array = Loader.load_json("res://data/handbook.json").cards
	for type in order:
		var case_id: String = DIRT_CASE.get(type, "")
		for c in cases:
			if c.id != case_id: continue
			var title := ""
			for card in cards:
				if not c.handbook_card_ids.is_empty() and card.id == c.handbook_card_ids[0]: title = card.title
			return {"id":c.id, "title":c.title, "trap":c.trap, "card":title}
	return {}

# Returns {"left": [{text, color}], "right": [...], "bonus": float}. `texts` is strings.data_ui; colors are palette indices.
static func build(review: Dictionary, submission: Dictionary, texts: Dictionary, bonus: float = 0.0) -> Dictionary:
	var left: Array = []
	var right: Array = []
	var t: Dictionary = texts.review
	var analysis: Dictionary = submission.get("analysis", {})
	for rf in review.get("files", []):
		var grade: Dictionary = rf.grade
		var c: Dictionary = grade.cleaning
		left.append({"text":str(rf.name), "color":28})
		left.append({"text":t.cleaning % [c.fixed_rows, c.defect_rows, c.missed_rows, int(c.wrongly_removed) + int(c.wrongly_changed)], "color":24 if c.missed_rows == 0 and c.wrongly_removed == 0 else 22})
		for e in c.entries:
			if left.size() >= MAX_LINES: break
			left.append({"text":"  " + t.entry % [str(e.type).replace("_", " "), e.fixed, e.rows], "color":24 if e.fixed == e.rows else (26 if e.fixed == 0 else 28)})
		for item in grade.findings.items:
			if left.size() >= MAX_LINES: break
			var word: String = t.finding_none if item.submitted == null else (t.finding_ok if item.score >= 1.0 else (t.finding_close if item.score > 0.0 else t.finding_wrong))
			left.append({"text":"%s: %s (%s)" % [str(item.id).replace("_", " "), t.you % value_text(item.submitted), word], "color":24 if item.score >= 1.0 else (28 if item.score > 0.0 else 26)})
			left.append({"text":"  " + t.truth % value_text(item.truth), "color":7})
		var ch: Dictionary = grade.chart
		if ch.present:
			if ch.flags.is_empty(): right.append({"text":t.chart + ": " + t.flag_none, "color":24})
			for flag in ch.flags: right.append({"text":t.chart + ": " + str(texts.get(flag.text_key, flag.id)), "color":28})
		else:
			right.append({"text":t.chart + ": -", "color":7})
		right.append({"text":t.ref, "color":28})
		var steps: Array = rf.reference_steps
		for i in steps.size():
			if i >= 5:
				right.append({"text":"  " + t["more"] % (steps.size() - 5), "color":7})
				break
			right.append({"text":"  %d. %s" % [i + 1, Forms.describe(steps[i])], "color":22})
		var missed: Array = []
		for e in c.entries:
			if e.missed > 0 or e.wrongly_removed > 0: missed.append(e.type)
		var info := case_for(rf.dirt, missed)
		if not info.is_empty():
			right.append({"text":t.handbook % info.card, "color":20})
	if left.is_empty(): left.append({"text":t.no_analysis, "color":7})
	if bonus != 0.0: right.append({"text":t.bonus % bonus, "color":24 if bonus > 0 else 26})
	return {"left":left.slice(0, MAX_LINES), "right":right.slice(0, MAX_LINES + 4), "has_analysis":not analysis.is_empty()}

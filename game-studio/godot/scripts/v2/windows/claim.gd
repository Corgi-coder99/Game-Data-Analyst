extends RefCounted
# What a headline says, read from its visible text only: a direction and an optional figure.
# This is the claim of the source, not a verdict: it can be wrong, stale or exaggerated.
const UP_PATTERN := "\\b(?:rise|rose|raise|hike|jump|climb|doubl|lift|gain|pricier|higher|buying more|recover|increase|soar)|\\bup\\b"
const DOWN_PATTERN := "\\b(?:fall|fell|lose|drop|collapse|lower|slump|sold off|decline|struggle|tighten|empty|go bust|slide)|\\b(?:down|cut|cuts)\\b"
const FLAT_PATTERN := "\\b(?:steady|holds|unchanged|flat|stable)"

static func _matches(pattern: String, text: String) -> bool:
	var regex := RegEx.new()
	regex.compile(pattern)
	return regex.search(text) != null

static func direction(headline: String) -> String:
	var text := headline.to_lower()
	var up := _matches(UP_PATTERN, text)
	var down := _matches(DOWN_PATTERN, text)
	if up and down: return ""
	if up: return "tang"
	if down: return "giam"
	if _matches(FLAT_PATTERN, text): return "ngang"
	return ""

# The first figure stated in the headline ("3%", "1.5 points"), with a sign from the claimed direction.
static func figure(headline: String) -> String:
	var pattern := RegEx.new()
	pattern.compile("(\\d+(?:\\.\\d+)?)\\s?(%|points|percent)")
	var found := pattern.search(headline)
	if found == null: return ""
	var sign := ""
	match direction(headline):
		"tang": sign = "+"
		"giam": sign = "-"
	var unit := "%" if found.get_string(2) in ["%", "percent"] else " pts"
	return sign + found.get_string(1) + unit

extends RefCounted
# What a headline says, read from its visible text only: a direction and an optional figure.
# This is the claim of the source, not a verdict: it can be wrong, stale or exaggerated.
const UP_WORDS := ["rise", "rose", "raises", "raised", "hike", "jump", "climb", "doubled", "lifts", "gain", "pricier", "higher", "tick up", "prices up", " up ", "buying more", "recover", "increase", "soar"]
const DOWN_WORDS := ["fall", "fell", "lose", "drop", "down", "cut ", "collapse", "lower", "slump", "sold off", "decline", "struggle", "tighten", "empty", "go bust", "slide"]
const FLAT_WORDS := ["steady", "holds", "unchanged", "flat", "stable"]

static func direction(headline: String) -> String:
	var text := " " + headline.to_lower() + " "
	var up := UP_WORDS.any(func(word): return word in text)
	var down := DOWN_WORDS.any(func(word): return word in text)
	if up and down: return ""
	if up: return "tang"
	if down: return "giam"
	if FLAT_WORDS.any(func(word): return word in text): return "ngang"
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

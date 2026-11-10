extends RefCounted
# Alphabet order maps directly to palette indices 1..32; dot is transparent.
const ALPHABET := "0123456789abcdefghijklmnopqrstuv"
static func colors() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v2.json")).colors
static func color(index: int) -> Color:
	assert(index >= 1 and index <= 32)
	return Color(colors()[index - 1])
static func decode(symbol: String) -> Color:
	if symbol == ".":
		return Color(0, 0, 0, 0)
	var index := ALPHABET.find(symbol)
	assert(index >= 0, "Unknown palette symbol: " + symbol)
	return color(index + 1)

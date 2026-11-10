extends RefCounted
# Palette v3: 64 colors, indices 1..64. Indices 1..32 equal palette v2.
# Alphabet order maps directly to palette indices; dot is transparent.
const ALPHABET := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#$"
static var cache: Array = []
static var parsed: Array = []
static func colors() -> Array:
	if cache.is_empty():
		cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v3.json")).colors
		for hex in cache:
			parsed.append(Color(hex))
	return cache
static func color(index: int) -> Color:
	assert(index >= 1 and index <= 64)
	colors()
	return parsed[index - 1]
static func decode(symbol: String) -> Color:
	if symbol == ".":
		return Color(0, 0, 0, 0)
	var index := ALPHABET.find(symbol)
	assert(index >= 0, "Unknown palette symbol: " + symbol)
	return color(index + 1)

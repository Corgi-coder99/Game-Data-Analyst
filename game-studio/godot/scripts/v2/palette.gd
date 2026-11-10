extends RefCounted
# Palette v4: 112 colors, indices 1..112. Indices 1..64 equal palette v3 (and 1..32 equal v2).
# Alphabet order maps directly to palette indices; dot is transparent.
# Symbols 1..64: 0-9 a-z A-Z # $ (as v3). Symbols 65..112: % & * + - / : ; < = > ? @ ^ _ ~ ! | ( ) [ ] { } , ' ` then Greek alpha..phi.
const ALPHABET := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&*+-/:;<=>?@^_~!|()[]{},'`αβγδεζηθικλμνξοπρστυφ"
const COUNT := 112
static var cache: Array = []
static var parsed: Array = []
static func colors() -> Array:
	if cache.is_empty():
		cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v4.json")).colors
		for hex in cache:
			parsed.append(Color(hex))
	return cache
static func color(index: int) -> Color:
	assert(index >= 1 and index <= COUNT)
	colors()
	return parsed[index - 1]
static func decode(symbol: String) -> Color:
	if symbol == ".":
		return Color(0, 0, 0, 0)
	var index := ALPHABET.find(symbol)
	assert(index >= 0, "Unknown palette symbol: " + symbol)
	return color(index + 1)

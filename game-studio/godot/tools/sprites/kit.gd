extends RefCounted
# T-028 helpers for building palette-letter sprite rows from code (Pen drawing or legend text-art).
const Palette = preload("res://scripts/v2/palette.gd")
const Pen = preload("res://scripts/v2/pen.gd")

static func symbol(index: int) -> String:
	return Palette.ALPHABET.substr(index - 1, 1)

# Image -> rows of palette symbols ("." for transparent).
static func to_rows(img: Image) -> Array:
	Pen._build_maps()
	var rows: Array = []
	for y in range(img.get_height()):
		var row := ""
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				row += "."
			else:
				var i: int = Pen._index_of.get(c.to_rgba32(), 0)
				assert(i > 0, "kit: color not in palette")
				row += symbol(i)
		rows.append(row)
	return rows

# Draw with a Pen on a fresh transparent image; returns the symbol rows.
static func paint(width: int, height: int, drawer: Callable) -> Array:
	var image := Pen.canvas(width, height)
	drawer.call(Pen.new(image))
	return to_rows(image)

# Legend text-art: each char of `art` rows maps to a palette index through `legend`; "." is transparent.
static func art(rows: Array, legend: Dictionary) -> Array:
	var out: Array = []
	for row in rows:
		var line := ""
		for i in range(row.length()):
			var ch: String = row.substr(i, 1)
			if ch == ".":
				line += "."
			else:
				assert(legend.has(ch), "kit: legend has no " + ch)
				line += symbol(int(legend[ch]))
		out.append(line)
	return out

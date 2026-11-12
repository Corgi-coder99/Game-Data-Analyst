extends SceneTree
# T-039: builds the pixel font from the text-art glyphs in tools/fonts/*.gd (no external font).
#   Godot --headless --path game-studio/godot -s res://tools/gen_font.gd
# Output per face: assets/v2/fonts/<name>.png (white on transparent, binary alpha, one cell per glyph)
# and assets/v2/fonts/<name>.json (metrics: ascent, descent, cell size, per glyph column/row/width/advance).
# scripts/v2/pixel_font.gd turns both into a FontFile at load time. Output is deterministic.
const FACES := [preload("res://tools/fonts/body.gd"), preload("res://tools/fonts/title.gd")]
const COLUMNS := 16
const DIR := "res://assets/v2/fonts"

# Rows of one glyph as an array of equal-length strings, plus the top offset from the cap line.
static func parse(spec: String, bold: bool) -> Dictionary:
	var text := spec
	var embolden := bold
	if text.begins_with("!"):
		embolden = false
		text = text.substr(1)
	var top := 0
	var bar := text.find("|")
	if bar > 0 and text.substr(0, bar).is_valid_int():
		top = int(text.substr(0, bar))
		text = text.substr(bar + 1)
	var rows: Array = Array(text.split("/"))
	var width := 0
	for row in rows: width = maxi(width, str(row).length())
	var out: Array = []
	for row in rows:
		var line: String = str(row).rpad(width, ".")
		if embolden:
			var thick := ""
			for x in width + 1:
				var on := (x < width and line[x] == "#") or (x > 0 and line[x - 1] == "#")
				thick += "#" if on else "."
			line = thick
		out.append(line)
	return {"top": top, "rows": out, "width": width + (1 if embolden else 0)}

# Returns {"image": Image, "json": String, "error": String} for one face script.
static func build(face: Script) -> Dictionary:
	var meta: Dictionary = face.META
	var source: Dictionary = face.glyphs()
	var codes: Array = []
	var parsed := {}
	for key in source:
		var code: int = str(key).unicode_at(0)
		if str(key).length() != 1 or parsed.has(code): return {"error": "bad or duplicate glyph key %s" % key}
		parsed[code] = parse(str(source[key]), bool(meta.bold))
		codes.append(code)
	codes.append(32)
	parsed[32] = {"top": 0, "rows": [], "width": 0}
	codes.sort()
	var cell_h: int = int(meta.ascent) + int(meta.descent)
	var cap_top: int = int(meta.ascent) - int(meta.cap)
	var cell_w := 1
	for code in codes:
		var g: Dictionary = parsed[code]
		cell_w = maxi(cell_w, int(g.width))
		for row in g.rows:
			if str(row).length() != int(g.width): return {"error": "ragged glyph U+%04X" % code}
			for i in str(row).length():
				if not str(row)[i] in ["#", "."]: return {"error": "bad symbol in glyph U+%04X" % code}
		if cap_top + int(g.top) + g.rows.size() > cell_h: return {"error": "glyph U+%04X is taller than the cell" % code}
	var rows_total := int(ceil(float(codes.size()) / COLUMNS))
	var image := Image.create(cell_w * COLUMNS, cell_h * rows_total, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	var lines: Array = []
	for index in codes.size():
		var code: int = codes[index]
		var g: Dictionary = parsed[code]
		var col := index % COLUMNS
		var row := index / COLUMNS
		for y in g.rows.size():
			for x in int(g.width):
				if str(g.rows[y])[x] == "#":
					image.set_pixel(col * cell_w + x, row * cell_h + cap_top + int(g.top) + y, Color(1, 1, 1, 1))
		var advance: int = int(meta.space) if code == 32 else int(g.width) + int(meta.gap)
		lines.append("\"%d\":[%d,%d,%d,%d]" % [code, col, row, int(g.width), advance])
	var json := "{\"name\":\"%s\",\"size\":%d,\"ascent\":%d,\"descent\":%d,\"cap\":%d,\"cell\":[%d,%d],\"glyphs\":{\n%s\n}}\n" % [meta.name, int(meta.size), int(meta.ascent), int(meta.descent), int(meta.cap), cell_w, cell_h, ",\n".join(lines)]
	return {"image": image, "json": json, "error": "", "name": str(meta.name), "count": codes.size()}

static func generate() -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	for face in FACES:
		var built := build(face)
		if str(built.error) != "":
			printerr("gen_font: ", built.error)
			return false
		var png: PackedByteArray = built.image.save_png_to_buffer()
		_write(DIR + "/" + built.name + ".png", png)
		_write(DIR + "/" + built.name + ".json", str(built.json).to_utf8_buffer())
		print("Generated font face ", built.name, ": ", built.count, " glyphs, atlas ", built.image.get_size())
	return true

static func _write(path: String, bytes: PackedByteArray) -> void:
	if FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path) == bytes: return
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func _init() -> void:
	quit(0 if generate() else 1)

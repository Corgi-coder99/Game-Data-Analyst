extends SceneTree
# T-039 (headless): the pixel font. Generator determinism, glyph coverage of every character used in the
# game's strings, the metrics rule against the default font, one-place application and the toggle.
const Gen = preload("res://tools/gen_font.gd")
const PixelFont = preload("res://scripts/v2/pixel_font.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const DATA := ["strings_v2", "strings", "news", "handbook", "coaching", "cases", "meta", "life", "questions", "world", "datasets", "cards", "events", "config"]
# Characters without a Title glyph (they exist in Body); at 12 px they come from the default font.
const TITLE_FALLBACK := [0x25CF, 0x25CB, 0x25B2, 0x25BC, 0x00B1, 0x2265, 0x2264]
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	test_determinism()
	var texts := collect_texts()
	test_coverage(texts)
	test_metrics(texts)
	test_application()
	print("test_t039_font: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_determinism() -> void:
	for face in Gen.FACES:
		var a: Dictionary = Gen.build(face)
		var b: Dictionary = Gen.build(face)
		check(str(a.error) == "", "face builds: " + str(a.get("error", "")))
		var png_a: PackedByteArray = a.image.save_png_to_buffer()
		check(png_a == b.image.save_png_to_buffer() and a.json == b.json, "same bytes twice: " + str(a.name))
		var base: String = Gen.DIR + "/" + str(a.name)
		check(FileAccess.get_file_as_bytes(base + ".png") == png_a, "atlas on disk is the generator output: " + str(a.name))
		check(FileAccess.get_file_as_string(base + ".json") == a.json, "metrics on disk are the generator output: " + str(a.name))
		var image: Image = a.image
		var clean := true
		for y in image.get_height():
			for x in image.get_width():
				var p := image.get_pixel(x, y)
				if not (p.a8 == 0 or (p.a8 == 255 and p.r8 == 255 and p.g8 == 255 and p.b8 == 255)): clean = false
		check(clean, "atlas is white on transparent with binary alpha: " + str(a.name))
		for code in range(33, 127):
			check(JSON.parse_string(a.json).glyphs.has(str(code)), "%s has ASCII %d" % [a.name, code])

# Every string value of the data files, plus string literals of scripts and scenes.
func collect_texts() -> Array:
	var texts: Array = []
	for name in DATA:
		var stack: Array = [JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % name))]
		while not stack.is_empty():
			var v: Variant = stack.pop_back()
			if v is Dictionary: stack.append_array(v.values())
			elif v is Array: stack.append_array(v)
			elif v is String and v != "": texts.append(v)
	return texts

func source_chars() -> Dictionary:
	var found := {}
	var dirs: Array = ["res://scripts", "res://scenes"]
	while not dirs.is_empty():
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir): dirs.append(dir + "/" + sub)
		for file in DirAccess.get_files_at(dir):
			if not (file.ends_with(".gd") or file.ends_with(".tscn")): continue
			var text := FileAccess.get_file_as_string(dir + "/" + file)
			for i in text.length():
				var code := text.unicode_at(i)
				if code > 126: found[code] = dir + "/" + file
	return found

func test_coverage(texts: Array) -> void:
	var used := {}
	for text in texts:
		for i in str(text).length(): used[str(text).unicode_at(i)] = true
	var sources := source_chars()
	for code in sources: used[code] = true
	check(used.size() > 80, "the scan found the game's characters (%d)" % used.size())
	var non_ascii: Array = []
	for code in used:
		if code < 32: continue  # line breaks and tabs are layout, not glyphs
		if code > 126: non_ascii.append("U+%04X" % code)
		check(PixelFont.has_glyph(8, code), "Body glyph for U+%04X" % code)
		check(PixelFont.has_glyph(16, code), "Body 2x glyph for U+%04X" % code)
		check(PixelFont.has_glyph(12, code) or code in TITLE_FALLBACK, "Title glyph or documented fallback for U+%04X" % code)
	non_ascii.sort()
	print("coverage: %d distinct characters; non-ASCII in use: %s" % [used.size(), " ".join(non_ascii)])
	# Documented exclusions: palette.gd writes its Greek sprite symbols as \u escapes (never shown as text)
	# and ops.gd uses \u0001 as an internal separator.
	check(not PixelFont.has_glyph(8, 0x4E2D), "a character outside the set has no pixel glyph (falls back)")
	var f: Font = PixelFont.font()
	check(f.get_string_size("中", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x >= 0.0 and f.fallbacks.size() == 1 and f.fallbacks[0] == PixelFont.default_font(), "missing glyphs fall back to the default font")

func test_metrics(texts: Array) -> void:
	var pixel: Font = PixelFont.font()
	var base: Font = PixelFont.default_font()
	check(pixel != null and pixel != base, "the pixel font loads")
	print("metrics table (real strings of data/*.json, %d strings)" % texts.size())
	print("size | font    | line height | ascent | descent | avg advance px/char | strings wider than default")
	for size in [8, 12]:
		var total_default := 0.0
		var total_pixel := 0.0
		var chars := 0
		var wider := 0
		var worst := 0.0
		var worst_text := ""
		for text in texts:
			var line: String = str(text).replace("\n", " ")
			var d := base.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var p := pixel.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			total_default += d
			total_pixel += p
			chars += line.length()
			if p > d:
				wider += 1
				if p - d > worst:
					worst = p - d
					worst_text = line
		print("%4d | default | %11.1f | %6.1f | %7.1f | %19.3f |" % [size, base.get_height(size), base.get_ascent(size), base.get_descent(size), total_default / chars])
		print("%4d | pixel   | %11.1f | %6.1f | %7.1f | %19.3f | %d of %d (worst +%d px: \"%s\")" % [size, pixel.get_height(size), pixel.get_ascent(size), pixel.get_descent(size), total_pixel / chars, wider, texts.size(), int(worst), worst_text.left(40)])
		check(pixel.get_height(size) <= base.get_height(size), "line height at %d is no larger than the default" % size)
		check(total_pixel / chars <= total_default / chars, "average advance at %d is no larger than the default (%.3f vs %.3f)" % [size, total_pixel / chars, total_default / chars])
	check(pixel.get_height(16) <= base.get_height(16), "line height at 16 (Body 2x) is no larger than the default")
	check(pixel.get_string_size("Hello", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x == 2.0 * pixel.get_string_size("Hello", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, "16 px is the Body face doubled")
	check(pixel.get_string_size("Hello", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x == base.get_string_size("Hello", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, "other sizes use the default font")
	for pair in [["0", "O"], ["1", "l"], ["1", "I"], ["l", "I"], ["5", "S"], ["|", "l"], [".", ","], [":", ";"], ["u", "v"], ["c", "e"]]:
		for face in Gen.FACES:
			var src: Dictionary = face.glyphs()
			check(Gen.parse(src[pair[0]], face.META.bold).rows != Gen.parse(src[pair[1]], face.META.bold).rows or Gen.parse(src[pair[0]], face.META.bold).top != Gen.parse(src[pair[1]], face.META.bold).top, "%s and %s differ in %s" % [pair[0], pair[1], face.META.name])
	check(pixel.antialiasing == TextServer.FONT_ANTIALIASING_NONE and pixel.hinting == TextServer.HINTING_NONE and pixel.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED and not pixel.generate_mipmaps, "no antialiasing, hinting, subpixel positioning or mipmaps")

func test_application() -> void:
	var pixel: Font = PixelFont.font()
	var base: Font = PixelFont.default_font()
	check(WindowTheme.pixel_font_on and WindowTheme.font() == pixel, "the pixel font is on by default")
	check(ThemeDB.fallback_font == pixel, "loading theme_v2 installs the pixel font as the fallback font")
	check(WindowTheme.create().default_font == pixel, "themes made by create() carry the pixel font")
	var plain := Label.new()
	root.add_child(plain)
	check(plain.get_theme_font("font") == pixel, "a Label outside any theme draws with the pixel font")
	var themed := Control.new()
	themed.theme = WindowTheme.create()
	root.add_child(themed)
	var button := Button.new()
	themed.add_child(button)
	check(button.get_theme_font("font") == pixel and button.get_theme_font_size("font_size") == 8, "a themed Button uses the pixel font at 8")
	WindowTheme.set_pixel_font(false)
	check(ThemeDB.fallback_font == base and ThemeDB.get_default_theme().default_font == base and WindowTheme.create().default_font == base and WindowTheme.font() == base, "off restores the default font")
	check(plain.get_theme_font("font") == base, "the plain Label follows the toggle")
	WindowTheme.set_pixel_font(true)
	check(ThemeDB.fallback_font == pixel and plain.get_theme_font("font") == pixel, "on again")
	plain.free()
	themed.free()

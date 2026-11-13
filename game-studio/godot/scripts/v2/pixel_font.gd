extends RefCounted
const ImageIO = preload("res://scripts/v2/image_io.gd")
# T-039: the pixel font, built at load time from the atlases written by tools/gen_font.gd.
# One FontFile holds three bitmap size caches: 8 (Body), 12 (Title) and 16 (Body doubled, for the 2x
# sheet zoom). Any other size, and any character without a glyph, falls back to the engine default font.
# Choice (documented in HANDOFF-T-039): a FontFile filled through set_texture_image / glyph rects instead
# of BMFont .fnt files, because .fnt needs the editor importer (*.import is not in the repo) and one
# BMFont holds a single size. No filtering, no antialiasing, no hinting, no subpixel positioning.
const DIR := "res://assets/v2/fonts/"
# [requested size, face file, integer scale, ascent, descent]. Line heights equal the default font's.
const SIZES := [[8, "body", 1, 9, 3], [12, "title", 1, 13, 4], [16, "body", 2, 18, 5]]
static var _font: FontFile
static var _tried := false
static var _default: Font

# The engine's own fallback font, captured before anything replaces it.
static func default_font() -> Font:
	if _default == null: _default = ThemeDB.fallback_font
	return _default

static func font() -> FontFile:
	if _tried: return _font
	_tried = true
	default_font()
	_font = _build()
	return _font

static func has_glyph(size: int, code: int) -> bool:
	var f := font()
	if f == null: return false
	return f.get_glyph_list(0, Vector2i(size, 0)).has(code)

static func _build() -> FontFile:
	var result := FontFile.new()
	result.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	result.hinting = TextServer.HINTING_NONE
	result.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	result.generate_mipmaps = false
	result.multichannel_signed_distance_field = false
	result.allow_system_fallback = false
	result.force_autohinter = false
	result.oversampling = 1.0
	result.font_name = "AI Company Pixel"
	for entry in SIZES:
		var size: int = entry[0]
		var scale: int = entry[2]
		var base: String = DIR + str(entry[1])
		if not ImageIO.exists(base + ".png") or not FileAccess.file_exists(base + ".json"): return null
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
		var image := ImageIO.load_image(base + ".png")
		if not meta is Dictionary or image == null: return null
		image.convert(Image.FORMAT_RGBA8)
		if scale > 1: image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
		var key := Vector2i(size, 0)
		result.set_cache_ascent(0, size, float(entry[3]))
		result.set_cache_descent(0, size, float(entry[4]))
		result.set_cache_underline_position(0, size, 1.0 * scale)
		result.set_cache_underline_thickness(0, size, 1.0 * scale)
		result.set_cache_scale(0, size, 1.0)
		result.set_texture_image(0, key, 0, image)
		var cell_w: int = int(meta.cell[0]) * scale
		var cell_h: int = int(meta.cell[1]) * scale
		# The cell's baseline sits at the face's own ascent; glyph offsets are relative to the baseline.
		var top := -float(int(meta.ascent) * scale)
		for code_text in meta.glyphs:
			var g: Array = meta.glyphs[code_text]
			var code := int(code_text)
			var width: int = int(g[2]) * scale
			result.set_glyph_advance(0, size, code, Vector2(int(g[3]) * scale, 0))
			result.set_glyph_offset(0, key, code, Vector2(0, top))
			result.set_glyph_size(0, key, code, Vector2(width, cell_h))
			result.set_glyph_uv_rect(0, key, code, Rect2(int(g[0]) * cell_w, int(g[1]) * cell_h, width, cell_h))
			result.set_glyph_texture_idx(0, key, code, 0)
	result.fallbacks = [default_font()]
	return result

extends RefCounted
# Palette-index drawing helper. Draws to an Image (static art) or a CanvasItem (animated art).
# Every call uses a palette v4 index (1..112); there is no anti-aliasing and no alpha blending.
const Palette = preload("res://scripts/v2/palette.gd")
var img: Image
var item: CanvasItem
var oy := 0
var origin := Vector2i.ZERO

func _init(target = null) -> void:
	if target is Image:
		img = target
	else:
		item = target

static func canvas(width: int, height: int) -> Image:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image

static func texture(image: Image) -> ImageTexture:
	return ImageTexture.create_from_image(image)

func r(x: int, y: int, w: int, h: int, i: int) -> void:
	if w <= 0 or h <= 0:
		return
	if img != null:
		img.fill_rect(Rect2i(x + origin.x, y + oy + origin.y, w, h), Palette.color(i))
	else:
		item.draw_rect(Rect2(x + origin.x, y + oy + origin.y, w, h), Palette.color(i))

func px(x: int, y: int, i: int) -> void:
	r(x, y, 1, 1, i)

# Three-tone box: light on the top and left edge, shade on the bottom and right edge.
func box(x: int, y: int, w: int, h: int, base: int, light: int, shade: int) -> void:
	r(x, y, w, h, base)
	r(x, y, w, 1, light)
	r(x, y, 1, h, light)
	r(x, y + h - 1, w, 1, shade)
	r(x + w - 1, y, 1, h, shade)

func frame(x: int, y: int, w: int, h: int, i: int) -> void:
	r(x, y, w, 1, i)
	r(x, y + h - 1, w, 1, i)
	r(x, y, 1, h, i)
	r(x + w - 1, y, 1, h, i)

func checker(x: int, y: int, w: int, h: int, a: int, b: int, step: int = 1) -> void:
	r(x, y, w, h, a)
	for yy in range(0, h, step):
		for xx in range(0, w, step):
			if ((xx / step) + (yy / step)) % 2 == 1:
				r(x + xx, y + yy, mini(step, w - xx), mini(step, h - yy), b)

func disc(cx: int, cy: int, radius: int, i: int) -> void:
	for dy in range(-radius, radius + 1):
		var half := int(sqrt(float(radius * radius - dy * dy)) + 0.5)
		r(cx - half, cy + dy, half * 2 + 1, 1, i)

func text(value: String, x: int, y: int, i: int, size: int = 8) -> void:
	if item == null:
		return
	item.draw_string(ThemeDB.fallback_font, Vector2(x, y + size - 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Palette.color(i))

static func text_width(value: String, size: int = 8) -> int:
	return int(ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)

# ---- T-028 cozy helpers (image targets only for the tone passes) -------------------------------

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
static var _lit_map: Array = []
static var _shade_map: Array = []
static var _index_of: Dictionary = {}

static func _nearest(target: Color, self_index: int) -> int:
	var best := self_index
	var best_d := 1.0e9
	for j in range(1, Palette.COUNT + 1):
		var c := Palette.color(j)
		var d := (c.r - target.r) * (c.r - target.r) * 0.9 + (c.g - target.g) * (c.g - target.g) + (c.b - target.b) * (c.b - target.b) * 1.1
		if d < best_d:
			best_d = d
			best = j
	return best

static func _build_maps() -> void:
	if not _lit_map.is_empty():
		return
	_lit_map.resize(Palette.COUNT + 1)
	_shade_map.resize(Palette.COUNT + 1)
	for i in range(1, Palette.COUNT + 1):
		var c := Palette.color(i)
		_index_of[c.to_rgba32()] = i
		var lit := c.lerp(Color(1.0, 0.9, 0.55), 0.26)
		lit = Color(minf(lit.r + 0.04, 1.0), minf(lit.g + 0.03, 1.0), lit.b)
		_lit_map[i] = _nearest(lit, i)
		var dark := c.lerp(Color(0.2, 0.15, 0.45), 0.34)
		dark = Color(dark.r * 0.9, dark.g * 0.9, dark.b * 0.96)
		_shade_map[i] = _nearest(dark, i)

func index_at(x: int, y: int) -> int:
	if img == null or x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return 0
	var c := img.get_pixel(x, y)
	if c.a < 0.5:
		return 0
	return _index_of.get(c.to_rgba32(), 0)

# Replaces one pixel by the warmer (mode 1) or cooler (mode -1) palette neighbour of its color.
func tone_px(x: int, y: int, mode: int) -> void:
	if img == null:
		return
	_build_maps()
	var i := index_at(x + origin.x, y + oy + origin.y)
	if i == 0:
		return
	var j: int = _lit_map[i] if mode > 0 else _shade_map[i]
	if j != i:
		img.set_pixel(x + origin.x, y + oy + origin.y, Palette.color(j))

# Dithered warm light: strength 0..1 at the center falls off to the radius.
func glow(cx: int, cy: int, radius: int, strength: float = 1.0, squash: float = 1.0) -> void:
	for dy in range(-int(radius * squash), int(radius * squash) + 1):
		for dx in range(-radius, radius + 1):
			var d := sqrt(float(dx * dx) + float(dy * dy) / (squash * squash)) / float(radius)
			if d >= 1.0:
				continue
			var level := (1.0 - d) * strength * 1.5
			var threshold := float(BAYER[((cy + dy) & 3) * 4 + ((cx + dx) & 3)]) / 16.0
			if level > threshold:
				tone_px(cx + dx, cy + dy, 1)
				if level > threshold + 0.7:
					tone_px(cx + dx, cy + dy, 1)

# Dithered cool shade over a rectangle (density 0..1).
func shade(x: int, y: int, w: int, h: int, density: float) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var threshold := float(BAYER[(yy & 3) * 4 + (xx & 3)]) / 16.0
			if density > threshold:
				tone_px(xx, yy, -1)

# A light shaft: slanted parallelogram of dithered warm light, strongest near the top.
func shaft(x: int, y: int, top_w: int, length: int, slant: int, strength: float = 0.8) -> void:
	for row in range(length):
		var fall := 1.0 - float(row) / float(length)
		var left := x + int(float(row) * float(slant) / float(length))
		for xx in range(left, left + top_w):
			var threshold := float(BAYER[((y + row) & 3) * 4 + (xx & 3)]) / 16.0
			if fall * strength * 1.3 > threshold:
				tone_px(xx, y + row, 1)

# Rectangle with the four corner pixels removed (a rounded look) and an optional outline.
func rr(x: int, y: int, w: int, h: int, fill: int, outline: int = 0) -> void:
	if outline > 0:
		r(x + 1, y, w - 2, h, outline)
		r(x, y + 1, w, h - 2, outline)
		r(x + 1, y + 1, w - 2, h - 2, fill)
	else:
		r(x + 1, y, w - 2, h, fill)
		r(x, y + 1, w, h - 2, fill)

func ellipse(cx: int, cy: int, rx: int, ry: int, i: int) -> void:
	for dy in range(-ry, ry + 1):
		var half := int(float(rx) * sqrt(maxf(0.0, 1.0 - float(dy * dy) / float(ry * ry))) + 0.5)
		r(cx - half, cy + dy, half * 2 + 1, 1, i)

# Horizontal two-color dither between rows (soft gradient helper).
func dither_rect(x: int, y: int, w: int, h: int, a: int, b: int, density: float) -> void:
	for yy in range(h):
		for xx in range(w):
			var threshold := float(BAYER[((y + yy) & 3) * 4 + ((x + xx) & 3)]) / 16.0
			px(x + xx, y + yy, b if density > threshold else a)

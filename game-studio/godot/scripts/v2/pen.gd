extends RefCounted
# Palette-index drawing helper. Draws to an Image (static art) or a CanvasItem (animated art).
# Every call uses a palette v3 index (1..64); there is no anti-aliasing and no alpha blending.
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

extends RefCounted
# T-028 cozy prop library: every function draws with palette v4 indices through a Pen (Image targets).
# Props are drawn bottom-up (shadow, body, highlight). Lights (glow, shafts) are applied afterwards by the caller.
const Pen = preload("res://scripts/v2/pen.gd")
const OUT := 65
const SHADOW := 66
const BERRY := 67
const TERRA_D := 68
const CLAY := 69
const PEACH := 70
const WARM := 71
const CREAM_L := 72
const LEAF_DD := 73
const LEAF_D := 74
const LEAF_M := 75
const LEAF_L := 76
const LEAF_HI := 77
const CREAM := 102
const PLUM_BLACK := 103
const ACCENTS := [85, 89, 91, 93, 94, 97, 87, 90]

static func drop_shadow(p: Pen, x: int, y: int, w: int, h: int, density: float = 0.6) -> void:
	p.shade(x + 2, y + h - 3, w, 6, density)

# ---- plants --------------------------------------------------------------------------------

static func leaf(p: Pen, x: int, y: int, size: int, lean: int = 0) -> void:
	p.ellipse(x, y, size, maxi(2, size - 1), LEAF_DD)
	p.ellipse(x - 1 + lean, y - 1, size - 1, maxi(1, size - 2), LEAF_D)
	p.ellipse(x - 2 + lean, y - 2, maxi(1, size - 3), maxi(1, size - 3), LEAF_M)
	p.px(x - 2 + lean, y - 3, LEAF_HI)
	p.px(x - 1 + lean, y - 3, LEAF_L)

static func pot(p: Pen, x: int, y: int, w: int, h: int, body: int = CLAY, rim: int = PEACH) -> void:
	p.r(x, y, w, h, body)
	p.r(x - 1, y, w + 2, 3, rim)
	p.r(x - 1, y, w + 2, 1, WARM)
	p.r(x + w - 3, y + 3, 3, h - 3, TERRA_D)
	p.r(x, y + h - 1, w, 1, BERRY)
	p.r(x - 1, y + 1, 1, 2, OUT)
	p.r(x + w, y + 1, 1, 2, OUT)
	p.r(x - 1, y + h, w + 2, 1, OUT)

static func plant_small(p: Pen, x: int, y: int, variant: int = 0) -> void:
	# Origin is the top-left of a 12x14 footprint.
	drop_shadow(p, x, y + 4, 12, 10, 0.45)
	pot(p, x + 2, y + 8, 8, 5)
	match variant % 3:
		0:
			leaf(p, x + 6, y + 3, 4)
			leaf(p, x + 2, y + 6, 2, -1)
			leaf(p, x + 10, y + 6, 2, 1)
		1:
			p.r(x + 6, y, 1, 8, LEAF_D)
			p.r(x + 3, y + 2, 1, 6, LEAF_D)
			p.r(x + 9, y + 3, 1, 5, LEAF_D)
			leaf(p, x + 6, y + 1, 3)
			leaf(p, x + 3, y + 3, 2)
			leaf(p, x + 9, y + 4, 2)
		_:
			# Succulent rosette with a pink flower.
			for i in range(5):
				p.r(x + 2 + i * 2, y + 5 - (i % 2) * 2, 2, 4 + (i % 2) * 2, LEAF_M if i % 2 == 0 else LEAF_D)
			p.px(x + 6, y + 2, 85)
			p.px(x + 5, y + 3, 85)
			p.px(x + 7, y + 3, 85)
			p.px(x + 6, y + 3, 89)

static func plant_big(p: Pen, x: int, y: int, variant: int = 0) -> void:
	# 22x34 footprint: a floor pot with a tall leafy plant.
	drop_shadow(p, x, y + 18, 22, 16, 0.5)
	pot(p, x + 4, y + 22, 14, 11, CLAY if variant % 2 == 0 else 87, PEACH if variant % 2 == 0 else 85)
	p.r(x + 10, y + 8, 2, 14, LEAF_D)
	p.r(x + 5, y + 12, 1, 10, LEAF_D)
	p.r(x + 16, y + 11, 1, 11, LEAF_D)
	leaf(p, x + 11, y + 5, 7)
	leaf(p, x + 5, y + 12, 5, -1)
	leaf(p, x + 17, y + 12, 5, 1)
	leaf(p, x + 11, y + 15, 4)
	leaf(p, x + 4, y + 19, 3, -1)
	leaf(p, x + 18, y + 19, 3, 1)
	if variant % 2 == 1:
		p.px(x + 7, y + 7, 85)
		p.px(x + 16, y + 6, 89)

static func hanging_plant(p: Pen, x: int, y: int, length: int = 14) -> void:
	p.r(x + 3, y - 12, 1, 12, OUT)
	pot(p, x, y, 8, 5, 87, 85)
	for i in range(6):
		p.r(x + i + 1, y + 5 + (i * 3) % length, 1, 3 + i % 3, LEAF_D)
		p.px(x + i + 1, y + 7 + (i * 3) % length, LEAF_L)
	leaf(p, x + 4, y - 1, 4)

# ---- lights --------------------------------------------------------------------------------

static func floor_lamp(p: Pen, x: int, y: int) -> Vector2i:
	# Returns the glow center. 10 wide, 34 tall.
	drop_shadow(p, x, y + 20, 12, 14, 0.4)
	p.r(x + 4, y + 8, 2, 24, SHADOW)
	p.r(x + 4, y + 8, 1, 24, 99)
	p.r(x + 1, y + 31, 8, 2, SHADOW)
	p.r(x, y + 33, 10, 1, OUT)
	p.r(x + 1, y, 8, 9, 96)
	p.r(x, y + 2, 10, 7, 97)
	p.r(x + 1, y, 8, 1, CREAM_L)
	p.r(x, y + 2, 1, 6, 95)
	p.r(x + 2, y + 3, 6, 4, 95)
	p.r(x, y + 8, 10, 1, 98)
	return Vector2i(x + 5, y + 6)

static func desk_lamp(p: Pen, x: int, y: int) -> Vector2i:
	p.r(x, y + 10, 8, 2, SHADOW)
	p.r(x + 3, y + 3, 2, 8, 99)
	p.r(x + 1, y, 7, 4, 97)
	p.r(x + 1, y, 7, 1, CREAM_L)
	p.r(x, y + 3, 9, 1, 98)
	return Vector2i(x + 4, y + 5)

static func string_lights(p: Pen, x1: int, x2: int, y: int, sag: int, seed_value: int, glows: Array) -> void:
	var span := x2 - x1
	for i in range(span + 1):
		var t := float(i) / float(span)
		var yy := y + int(sin(t * PI) * sag)
		p.px(x1 + i, yy, SHADOW)
	var count := maxi(3, span / 14)
	for i in range(count + 1):
		var t := float(i) / float(count)
		var bx := x1 + int(t * span)
		var by := y + int(sin(t * PI) * sag) + 1
		var color: int = [89, 85, 91, 97, 93][(i + seed_value) % 5]
		p.r(bx, by, 1, 2, SHADOW)
		p.r(bx - 1, by + 2, 3, 3, color)
		p.px(bx - 1, by + 2, CREAM_L)
		glows.append(Vector2i(bx, by + 3))

# ---- small things --------------------------------------------------------------------------

static func mug(p: Pen, x: int, y: int, color: int = 85) -> void:
	p.r(x, y, 5, 5, CREAM)
	p.r(x, y + 2, 5, 1, color)
	p.r(x + 5, y + 1, 2, 3, CREAM)
	p.px(x + 6, y + 2, OUT)
	p.r(x, y, 5, 1, CREAM_L)
	p.r(x, y + 5, 5, 1, OUT)
	p.px(x + 1, y - 2, 101)
	p.px(x + 2, y - 3, 101)

static func books(p: Pen, x: int, y: int, count: int, seed_value: int) -> void:
	var yy := y
	for i in range(count):
		var w := 9 + (seed_value + i * 3) % 4
		var color: int = ACCENTS[(seed_value + i) % ACCENTS.size()]
		p.r(x + (i % 2), yy - 3, w, 3, color)
		p.r(x + (i % 2), yy - 3, w, 1, CREAM_L)
		p.r(x + (i % 2) + 2, yy - 2, w - 4, 1, CREAM)
		p.r(x + (i % 2), yy, w, 1, OUT)
		yy -= 3

static func sticky_notes(p: Pen, x: int, y: int, w: int, h: int, seed_value: int) -> void:
	var i := 0
	for yy in range(y, y + h - 6, 8):
		for xx in range(x, x + w - 6, 8):
			var color: int = [89, 86, 90, 92, 94][(i * 3 + seed_value) % 5]
			p.r(xx, yy, 6, 6, color)
			p.r(xx, yy, 6, 1, CREAM_L)
			p.px(xx + 1, yy + 2, SHADOW)
			p.px(xx + 3, yy + 3, SHADOW)
			p.px(xx + 2, yy + 4, SHADOW)
			i += 1

static func poster(p: Pen, x: int, y: int, w: int, h: int, variant: int) -> void:
	p.r(x, y, w, h, OUT)
	var bg: int = [92, 94, 90, 93, 86][variant % 5]
	p.r(x + 1, y + 1, w - 2, h - 2, bg)
	p.r(x + 1, y + 1, w - 2, 1, CREAM_L)
	match variant % 5:
		0:
			p.disc(x + w / 2, y + h / 2 - 2, mini(w, h) / 4, 97)
			p.r(x + 3, y + h - 6, w - 6, 2, CREAM)
		1:
			for i in range(3):
				p.r(x + 3 + i * 4, y + h - 5 - i * 3, 3, 3 + i * 3, 84 if i % 2 == 0 else 80)
		2:
			p.r(x + 3, y + 4, w - 6, 2, 74)
			p.r(x + 3, y + 8, (w - 6) / 2, 6, 75)
			p.px(x + w - 5, y + 6, 85)
		3:
			p.disc(x + w / 2, y + h / 2, mini(w, h) / 3, 85)
			p.disc(x + w / 2 - 1, y + h / 2 - 1, mini(w, h) / 5, 89)
		_:
			p.r(x + 3, y + 3, w - 6, h - 6, 85)
			p.r(x + 5, y + 5, w - 10, 2, CREAM)
			p.r(x + 5, y + 9, w - 14, 2, CREAM)
	p.r(x, y + h - 1, w, 1, SHADOW)

static func picture(p: Pen, x: int, y: int, w: int, h: int, variant: int) -> void:
	p.r(x, y, w, h, WARM)
	p.frame(x, y, w, h, OUT)
	p.r(x + 2, y + 2, w - 4, h - 4, [94, 90, 86, 95][variant % 4])
	p.r(x + 2, y + h - 6, w - 4, 4, [74, 75, 76, 69][variant % 4])
	p.disc(x + w - 6, y + 6, 2, 89)

static func cushion(p: Pen, x: int, y: int, color: int, dark: int) -> void:
	p.rr(x, y, 9, 8, color, OUT)
	p.r(x + 1, y + 1, 4, 1, 102)
	p.r(x + 6, y + 3, 2, 4, dark)
	p.px(x + 4, y + 4, dark)

# ---- big furniture -------------------------------------------------------------------------

static func sofa(p: Pen, x: int, y: int, w: int, body: int, light: int, shade: int, c1: int = 89, c2: int = 91) -> void:
	drop_shadow(p, x, y + 18, w + 4, 12, 0.55)
	p.rr(x, y, w, 14, shade, OUT)
	p.r(x + 2, y + 2, w - 4, 1, body)
	p.rr(x - 4, y + 8, 9, 22, body, OUT)
	p.rr(x + w - 5, y + 8, 9, 22, body, OUT)
	p.r(x - 3, y + 9, 1, 18, light)
	p.r(x + w - 4, y + 9, 1, 18, light)
	p.rr(x + 4, y + 12, w - 8, 15, body, OUT)
	p.r(x + 5, y + 13, w - 10, 1, light)
	p.r(x + w / 2, y + 14, 1, 12, shade)
	p.r(x + 6, y + 27, 3, 3, OUT)
	p.r(x + w - 9, y + 27, 3, 3, OUT)
	cushion(p, x + 8, y + 5, c1, shade)
	cushion(p, x + w - 17, y + 6, c2, shade)

static func shelf(p: Pen, x: int, y: int, w: int, rows: int, seed_value: int) -> void:
	var h := rows * 14 + 4
	drop_shadow(p, x, y + h - 6, w, 10, 0.4)
	p.r(x, y, w, h, OUT)
	p.r(x + 1, y + 1, w - 2, h - 2, TERRA_D)
	for r_ in range(rows):
		var by := y + 2 + r_ * 14
		p.r(x + 2, by, w - 4, 12, SHADOW)
		p.r(x + 2, by + 12, w - 4, 2, PEACH)
		p.r(x + 2, by + 12, w - 4, 1, WARM)
		var bx := x + 3
		var i := 0
		while bx < x + w - 8:
			var variant := (i * 7 + r_ * 3 + seed_value) % 9
			if variant < 6:
				var bw := 2 + (i + r_) % 3
				var bh := 6 + (i * 5 + r_ * 2) % 6
				var color: int = ACCENTS[(i + r_ * 3 + seed_value) % ACCENTS.size()]
				p.r(bx, by + 12 - bh, bw, bh, color)
				p.r(bx, by + 12 - bh, 1, bh, CREAM_L)
				bx += bw + (1 if i % 4 != 3 else 3)
			elif variant == 6:
				pot(p, bx, by + 7, 5, 5)
				leaf(p, bx + 2, by + 4, 3)
				bx += 8
			elif variant == 7:
				p.r(bx, by + 4, 6, 8, 94)
				p.frame(bx, by + 4, 6, 8, OUT)
				p.px(bx + 2, by + 7, 89)
				bx += 8
			else:
				p.disc(bx + 3, by + 9, 3, 85)
				p.px(bx + 2, by + 8, CREAM_L)
				bx += 8
			i += 1

static func rug(p: Pen, x: int, y: int, w: int, h: int, base: int, alt: int, accent: int, style: int = 0) -> void:
	drop_shadow(p, x, y, w, h, 0.2)
	p.rr(x, y, w, h, OUT)
	p.rr(x + 1, y + 1, w - 2, h - 2, accent)
	p.rr(x + 3, y + 3, w - 6, h - 6, alt)
	p.rr(x + 5, y + 5, w - 10, h - 10, base)
	for i in range(0, w - 14, 6):
		p.px(x + 7 + i, y + 7, alt)
		p.px(x + 7 + i, y + h - 8, alt)
	match style % 3:
		0:
			for yy in range(y + 9, y + h - 9, 6):
				for xx in range(x + 9 + ((yy - y) / 6 % 2) * 3, x + w - 12, 6):
					p.r(xx, yy, 2, 2, accent)
					p.px(xx, yy, alt)
		1:
			var cx := x + w / 2
			var cy := y + h / 2
			p.ellipse(cx, cy, maxi(4, w / 4), maxi(3, h / 4), alt)
			p.ellipse(cx, cy, maxi(2, w / 8), maxi(2, h / 8), accent)
		_:
			for xx in range(x + 8, x + w - 8, 8):
				p.r(xx, y + 6, 1, h - 12, alt)
	for xx in range(x + 2, x + w - 2, 2):
		p.px(xx, y - 1, accent)
		p.px(xx, y + h, accent)

# ---- room surfaces -------------------------------------------------------------------------

static func planks(p: Pen, x: int, y: int, w: int, h: int, base: int, light: int, dark: int, seam: int, plank_h: int = 8) -> void:
	p.r(x, y, w, h, base)
	var row := 0
	for yy in range(y, y + h, plank_h):
		p.r(x, yy, w, 1, seam)
		p.r(x, yy + 1, w, 1, light)
		var shift := (row * 37) % 60
		for xx in range(x + shift - 60, x + w, 60):
			if xx >= x:
				p.r(xx, yy + 1, 1, plank_h - 1, seam)
		for g in range(8):
			var gx := x + ((row * 53 + g * 29) % maxi(1, w - 8))
			p.r(gx, yy + 3 + (g % 3), 4 + g % 4, 1, dark)
			if g % 3 == 0:
				p.px(gx + 2, yy + 2, light)
		row += 1

static func carpet(p: Pen, x: int, y: int, w: int, h: int, base: int, weave: int, seam: int, tile: int = 32) -> void:
	p.r(x, y, w, h, base)
	for yy in range(y, y + h, 2):
		for xx in range(x + (((yy - y) / 2) % 2) * 2, x + w, 4):
			p.px(xx, yy, weave)
	for xx in range(x, x + w, tile):
		p.r(xx, y, 1, h, seam)
	for yy in range(y, y + h, tile):
		p.r(x, yy, w, 1, seam)

static func tiles(p: Pen, x: int, y: int, w: int, h: int, a: int, b: int, grout: int, size: int = 16) -> void:
	p.r(x, y, w, h, grout)
	for yy in range(y, y + h, size):
		for xx in range(x, x + w, size):
			var color := a if (((xx - x) / size) + ((yy - y) / size)) % 2 == 0 else b
			p.r(xx + 1, yy + 1, size - 1, size - 1, color)
			p.r(xx + 1, yy + 1, size - 1, 1, 102 if color == a else color)
			p.px(xx + 3, yy + 4, 102)

static func wallpaper(p: Pen, x: int, y: int, w: int, h: int, base: int, stripe: int, dot: int) -> void:
	p.r(x, y, w, h, base)
	for xx in range(x, x + w, 8):
		p.r(xx, y, 2, h, stripe)
		p.px(xx + 5, y + 3 + (xx / 8 % 3) * 4, dot)
		p.px(xx + 5, y + 15 + (xx / 8 % 3) * 4, dot)
		p.px(xx + 5, y + 27 + (xx / 8 % 3) * 4, dot)

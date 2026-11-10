extends RefCounted
# T-029 cozy shop interiors (palette v4): one small illustration per shop, a distinct shopkeeper character per
# shop, and 16x16 menu icons. Everything is drawn in code with Pen and cached. The interior is split in a back
# layer (wall, shelves, floor) and a front layer (the counter), so the keeper stands behind the counter.
const Pen = preload("res://scripts/v2/pen.gd")
const Cozy = preload("res://scripts/v2/cozy.gd")
const OUT := 65
const SHADOW := 66
const W := 224
const H := 360
const COUNTER_Y := 168
const FLOOR_Y := 232
const RUGS := {"cafe": [86, 85, 87], "noodle": [112, 87, 88], "mart": [94, 84, 79], "pharmacy": [90, 91, 75], "bank": [84, 80, 79],
	"news": [93, 82, 80], "books": [96, 97, 98], "clothing": [85, 86, 87]}
static var cache := {}

# wall = [base, stripe/accent, wainscot], floor = [a, b, seam], form = floor style.
const SPECS := {
	"cafe": {"wall": [70, 92, 78], "floor": [69, 70, 68], "form": "planks", "accent": 87, "lamp": 97, "rug": [86, 85, 87]},
	"noodle": {"wall": [78, 91, 73], "floor": [70, 69, 68], "form": "tiles", "accent": 112, "lamp": 97},
	"mart": {"wall": [94, 35, 84], "floor": [101, 61, 100], "form": "tiles", "accent": 97, "lamp": 95},
	"pharmacy": {"wall": [90, 102, 91], "floor": [102, 90, 100], "form": "tiles", "accent": 75, "lamp": 95},
	"bank": {"wall": [101, 102, 99], "floor": [102, 101, 100], "form": "tiles", "accent": 28, "lamp": 96},
	"news": {"wall": [86, 85, 88], "floor": [11, 10, 9], "form": "planks", "accent": 93, "lamp": 97},
	"books": {"wall": [82, 93, 79], "floor": [109, 108, 9], "form": "planks", "accent": 89, "lamp": 97},
	"clothing": {"wall": [86, 102, 87], "floor": [12, 13, 11], "form": "planks", "accent": 85, "lamp": 95}}

static func interior(shop: String) -> Dictionary:
	if cache.has(shop):
		return cache[shop]
	var spec: Dictionary = SPECS.get(shop, SPECS.cafe)
	var back_image := Pen.canvas(W, H)
	var back := Pen.new(back_image)
	_room(back, spec, shop)
	var front_image := Pen.canvas(W, H)
	var front := Pen.new(front_image)
	_counter(front, spec, shop)
	var out := {"back": Pen.texture(back_image), "front": Pen.texture(front_image)}
	cache[shop] = out
	return out

# ---- room shell -----------------------------------------------------------------------------

static func _room(p: Pen, spec: Dictionary, shop: String) -> void:
	var wall: Array = spec.wall
	var floor_c: Array = spec.floor
	# Wall with stripes and a wainscot.
	Cozy.wallpaper(p, 0, 0, W, FLOOR_Y, wall[0], wall[1], 102)
	p.r(0, 150, W, FLOOR_Y - 150, wall[2])
	p.r(0, 150, W, 2, 102)
	p.r(0, 152, W, 1, OUT)
	for x in range(6, W, 14):
		p.r(x, 156, 8, 70, wall[2])
		p.r(x, 156, 8, 1, 101)
		p.r(x + 7, 157, 1, 69, SHADOW)
	p.r(0, FLOOR_Y - 5, W, 5, 102)
	p.r(0, FLOOR_Y - 5, W, 1, 101)
	p.r(0, FLOOR_Y - 1, W, 1, OUT)
	# Floor.
	if spec.form == "planks":
		Cozy.planks(p, 0, FLOOR_Y, W, H - FLOOR_Y, floor_c[0], floor_c[1], floor_c[2], SHADOW, 8)
	else:
		Cozy.tiles(p, 0, FLOOR_Y, W, H - FLOOR_Y, floor_c[0], floor_c[1], floor_c[2], 16)
	p.shade(0, FLOOR_Y, W, 14, 0.7)
	# Rug in front of the counter, a doormat and a small plant, so the floor is not bare.
	var rug_colors: Array = RUGS.get(shop, [85, 86, 87])
	Cozy.rug(p, 22, 282, 180, 58, rug_colors[0], rug_colors[1], rug_colors[2], SPECS.keys().find(shop) % 3)
	Cozy.plant_small(p, 206, 300, SPECS.keys().find(shop))
	p.r(8, 340, 40, 10, 99)
	p.r(8, 340, 40, 1, 100)
	for mx in range(10, 46, 4):
		p.r(mx, 342, 2, 6, 100)
	# Label plate for the shopkeeper's line.
	p.rr(4, 232, 216, 26, SHADOW)
	p.rr(5, 233, 214, 24, 103)
	p.r(7, 234, 210, 1, 99)
	# Header band with a scalloped valance.
	p.r(0, 0, W, 22, SHADOW)
	p.r(0, 0, W, 2, 99)
	p.r(0, 20, W, 2, OUT)
	for sx in range(0, W, 12):
		p.rr(sx, 21, 12, 6, spec.accent)
		p.r(sx + 2, 22, 3, 1, 102)
	p.r(0, 21, W, 1, spec.accent)
	# Pendant lamps with a warm glow.
	for lx in [70, 150, 206]:
		p.r(lx, 27, 1, 14, OUT)
		p.rr(lx - 6, 41, 13, 7, OUT)
		p.r(lx - 5, 42, 11, 5, spec.lamp)
		p.r(lx - 5, 42, 11, 1, 95)
		p.px(lx - 3, 43, 102)
	for lx in [70, 150, 206]:
		p.glow(lx, 52, 30, 0.9, 0.9)
	# Window with a light shaft on the left wall.
	p.rr(8, 34, 44, 52, OUT)
	p.r(9, 35, 42, 50, 99)
	p.r(11, 37, 38, 46, 94)
	p.r(11, 37, 38, 10, 35)
	p.r(11, 61, 38, 22, 90 if shop != "bank" else 75)
	p.ellipse(22, 66, 10, 5, 75)
	p.ellipse(40, 68, 9, 4, 74)
	p.ellipse(45, 45, 6, 3, 102)
	p.r(29, 37, 2, 46, 99)
	p.r(11, 58, 38, 2, 99)
	p.r(6, 84, 48, 4, 102)
	p.r(6, 88, 48, 1, 100)
	p.shaft(14, 40, 18, 120, 28, 1.0)
	# Common props: floor plant and a hanging plant.
	Cozy.plant_big(p, 2, 190, 0)
	if shop in ["cafe", "books"]:
		Cozy.hanging_plant(p, 104, 56, 14)
	match shop:
		"cafe": _decor_cafe(p)
		"noodle": _decor_noodle(p)
		"mart": _decor_mart(p)
		"pharmacy": _decor_pharmacy(p)
		"bank": _decor_bank(p)
		"news": _decor_news(p)
		"books": _decor_books(p)
		"clothing": _decor_clothing(p)
	# Soft shade under the shelves and the corner.
	p.shade(0, 24, W, 4, 0.8)

# ---- goods ----------------------------------------------------------------------------------

static func _shelf_board(p: Pen, x: int, y: int, w: int) -> void:
	p.r(x, y, w, 3, 71)
	p.r(x, y, w, 1, 72)
	p.r(x, y + 2, w, 1, 68)
	p.r(x, y + 3, w, 1, OUT)
	p.r(x + 1, y + 4, w - 2, 2, 66)

static func _rack(p: Pen, x: int, y: int, w: int, rows: int, row_h: int) -> void:
	p.shade(x - 1, y + rows * row_h - 4, w + 4, 8, 0.4)
	p.rr(x - 1, y - 1, w + 2, rows * row_h + 3, OUT)
	p.r(x, y, w, rows * row_h + 1, 68)
	p.r(x, y, w, rows * row_h, 67)
	for r in range(rows):
		p.r(x + 1, y + 1 + r * row_h, w - 2, row_h - 3, SHADOW)

static func _goods(p: Pen, x: int, base_y: int, w: int, form: String, seed_value: int) -> void:
	var cx := x
	var i := 0
	while cx < x + w - 6:
		var tint: int = [85, 89, 91, 93, 94, 97, 87, 90, 86, 92][(i * 3 + seed_value) % 10]
		var roll := (i * 7 + seed_value * 3) % 5
		match form:
			"cups":
				p.r(cx, base_y - 5, 5, 5, 102)
				p.r(cx, base_y - 3, 5, 1, tint)
				p.r(cx + 5, base_y - 4, 2, 3, 102)
				p.px(cx + 6, base_y - 3, OUT)
				p.r(cx, base_y - 1, 5, 1, 101)
				cx += 8
			"jars":
				var h := 7 + roll % 3
				p.r(cx, base_y - h, 6, h, 94)
				p.r(cx + 1, base_y - h + 3, 4, h - 4, tint if roll % 2 == 0 else 69)
				p.r(cx, base_y - h - 1, 6, 2, 100)
				p.px(cx + 1, base_y - h + 2, 102)
				cx += 8
			"cans":
				var hh := 8 + roll % 3
				p.rr(cx, base_y - hh, 6, hh, OUT)
				p.r(cx + 1, base_y - hh + 1, 4, hh - 2, tint)
				p.r(cx + 1, base_y - hh + 3, 4, 3, 102)
				p.r(cx + 1, base_y - hh + 1, 1, hh - 2, 102)
				cx += 8
			"bottles":
				var bh := 11 + roll % 3
				p.r(cx + 1, base_y - bh, 2, 4, 100)
				p.r(cx, base_y - bh + 4, 4, bh - 4, tint)
				p.r(cx, base_y - bh + 6, 4, 3, 102)
				p.px(cx, base_y - bh + 5, 102)
				cx += 6
			"books":
				var bw := 2 + roll % 3
				var bh2 := 9 + (i * 5 + seed_value) % 7
				p.r(cx, base_y - bh2, bw, bh2, tint)
				p.r(cx, base_y - bh2, 1, bh2, 102)
				p.r(cx, base_y - bh2 + 2, bw, 1, 102)
				p.r(cx, base_y - 3, bw, 1, 66)
				cx += bw + 1
			"boxes":
				var bh3 := 8 + roll % 4
				p.r(cx, base_y - bh3, 7, bh3, tint)
				p.r(cx, base_y - bh3, 7, 2, 102)
				p.r(cx, base_y - bh3, 1, bh3, 102)
				p.r(cx + 2, base_y - bh3 + 4, 3, 3, 102)
				p.px(cx + 3, base_y - bh3 + 5, tint)
				cx += 9
			"pills":
				p.r(cx, base_y - 8, 7, 8, 102)
				p.r(cx, base_y - 8, 7, 2, tint)
				p.r(cx + 3, base_y - 6, 1, 4, 75)
				p.r(cx + 2, base_y - 5, 3, 1, 75)
				cx += 9
			"bowls":
				p.rr(cx, base_y - 5, 8, 5, OUT)
				p.r(cx + 1, base_y - 4, 6, 3, tint)
				p.r(cx + 1, base_y - 4, 6, 1, 102)
				cx += 10
			"clothes":
				var ch := 3 + roll % 2
				for k in range(3):
					p.r(cx, base_y - ch * (k + 1), 11, ch, [85, 94, 89, 93, 87, 90][(i + k) % 6])
					p.r(cx, base_y - ch * (k + 1), 11, 1, 102)
				cx += 13
			_:
				p.r(cx, base_y - 6, 5, 6, tint)
				cx += 7
		i += 1

static func _frame_picture(p: Pen, x: int, y: int, w: int, h: int, variant: int) -> void:
	Cozy.picture(p, x, y, w, h, variant)
	p.px(x + 1, y + 1, 102)

# ---- decor per shop -------------------------------------------------------------------------

static func _decor_cafe(p: Pen) -> void:
	_shelf_board(p, 80, 66, 132)
	_shelf_board(p, 80, 100, 132)
	_goods(p, 84, 66, 124, "cups", 1)
	_goods(p, 84, 100, 124, "jars", 2)
	# Chalkboard menu on the right wall.
	p.rr(174, 106, 40, 36, OUT)
	p.r(175, 107, 38, 34, 69)
	p.r(177, 109, 34, 30, 103)
	p.r(180, 112, 20, 2, 102)
	for yy in [118, 124, 130]:
		p.r(180, yy, 18, 1, 101)
		p.r(201, yy, 6, 1, 89)
	p.r(180, 135, 12, 1, 85)
	_frame_picture(p, 58, 100, 14, 18, 1)
	# Espresso machine on a back counter.
	p.r(78, 138, 50, 30, 69)
	p.r(78, 138, 50, 2, 71)
	p.rr(86, 118, 32, 20, OUT)
	p.r(87, 119, 30, 18, 100)
	p.r(87, 119, 30, 3, 101)
	p.r(90, 126, 6, 8, 103)
	p.r(104, 126, 6, 8, 103)
	p.px(112, 123, 112)
	p.px(114, 123, 76)

static func _decor_noodle(p: Pen) -> void:
	# Noren curtain, menu boards and bowls on a shelf.
	for nx in range(78, 130, 13):
		p.r(nx, 28, 11, 16, 102)
		p.r(nx, 28, 11, 2, 112)
		p.r(nx + 5, 30, 1, 14, 101)
	_shelf_board(p, 134, 66, 78)
	_goods(p, 138, 66, 70, "bowls", 3)
	_shelf_board(p, 134, 98, 78)
	_goods(p, 138, 98, 70, "jars", 4)
	for lx in [84, 108]:
		p.r(lx, 60, 1, 6, OUT)
		p.ellipse(lx, 74, 6, 8, 112)
		p.r(lx - 6, 72, 13, 1, 87)
		p.r(lx - 3, 66, 7, 1, 97)
		p.r(lx - 3, 82, 7, 1, 97)
		p.px(lx - 2, 70, 85)
		p.glow(lx, 74, 14, 0.8)
	p.rr(176, 106, 38, 30, OUT)
	p.r(177, 107, 36, 28, 102)
	p.r(180, 111, 26, 2, 112)
	for yy in [117, 122, 127, 131]:
		p.r(180, yy, 22, 1, 99)
		p.r(205, yy, 5, 1, 112)
	# Stock pot on the back counter.
	p.r(78, 140, 50, 28, 69)
	p.r(78, 140, 50, 2, 71)
	p.rr(88, 122, 22, 18, OUT)
	p.r(89, 123, 20, 16, 100)
	p.r(89, 123, 20, 3, 101)
	p.r(86, 120, 26, 3, 99)

static func _decor_mart(p: Pen) -> void:
	_rack(p, 80, 56, 134, 3, 30)
	_goods(p, 84, 83, 126, "cans", 1)
	_goods(p, 84, 113, 126, "boxes", 2)
	_goods(p, 84, 143, 126, "bottles", 3)
	for yy in [83, 113, 143]:
		_shelf_board(p, 80, yy, 134)
	p.r(100, 50, 40, 5, 97)
	p.r(100, 50, 40, 1, 95)
	p.rr(160, 46, 26, 8, OUT)
	p.r(161, 47, 24, 6, 112)
	p.r(164, 49, 18, 2, 102)
	_frame_picture(p, 58, 98, 14, 18, 3)

static func _decor_pharmacy(p: Pen) -> void:
	_rack(p, 80, 56, 134, 3, 30)
	_goods(p, 84, 83, 126, "pills", 1)
	_goods(p, 84, 113, 126, "bottles", 2)
	_goods(p, 84, 143, 126, "boxes", 5)
	for yy in [83, 113, 143]:
		_shelf_board(p, 80, yy, 134)
	# Green cross sign.
	p.rr(176, 28, 26, 22, OUT)
	p.r(177, 29, 24, 20, 102)
	p.r(186, 32, 6, 14, 75)
	p.r(182, 36, 14, 6, 75)
	p.r(186, 32, 1, 14, 76)
	p.glow(189, 39, 18, 0.8)
	Cozy.poster(p, 58, 98, 14, 18, 2)

static func _decor_bank(p: Pen) -> void:
	# Columns, a clock, the vault door and a flag.
	for cx in [76, 118, 200]:
		p.rr(cx, 28, 10, 140, OUT)
		p.r(cx + 1, 29, 8, 138, 102)
		p.r(cx + 1, 29, 1, 138, 64)
		p.r(cx + 7, 29, 2, 138, 100)
		p.r(cx - 1, 28, 12, 4, 101)
		p.r(cx - 1, 164, 12, 4, 101)
	p.disc(146, 48, 14, OUT)
	p.disc(146, 48, 12, 102)
	p.disc(146, 48, 10, 64)
	p.r(146, 40, 1, 9, SHADOW)
	p.r(146, 48, 6, 1, SHADOW)
	for a in range(12):
		p.px(146 + int(sin(a * 0.5236) * 9.0), 48 - int(cos(a * 0.5236) * 9.0), 99)
	p.px(146, 48, 112)
	p.rr(160, 100, 36, 50, OUT)
	p.r(161, 101, 34, 48, 100)
	p.disc(178, 125, 14, OUT)
	p.disc(178, 125, 12, 99)
	p.disc(178, 125, 7, 100)
	p.r(177, 117, 3, 16, 28)
	p.r(170, 124, 16, 3, 28)
	p.r(150, 62, 1, 36, 99)
	p.r(151, 64, 14, 8, 112)
	p.r(151, 66, 14, 1, 87)
	_frame_picture(p, 58, 98, 14, 18, 0)

static func _decor_news(p: Pen) -> void:
	# Magazine wall: rows of covers.
	p.rr(79, 54, 134, 96, OUT)
	p.r(80, 55, 132, 94, 66)
	for row in range(4):
		var yy := 58 + row * 23
		p.r(80, yy + 21, 132, 2, 69)
		p.r(80, yy + 21, 132, 1, 71)
		for col in range(10):
			var cc: int = [85, 89, 91, 93, 94, 97, 87, 90, 86, 92, 80, 74][(row * 5 + col * 3) % 12]
			p.r(83 + col * 13, yy, 10, 20, cc)
			p.r(83 + col * 13, yy, 10, 2, 102)
			p.r(83 + col * 13, yy, 1, 20, 102)
			p.r(85 + col * 13, yy + 4, 6, 6, 102)
			p.r(85 + col * 13, yy + 13, 6, 1, SHADOW)
			p.r(85 + col * 13, yy + 16, 4, 1, SHADOW)
	p.disc(60, 108, 8, OUT)
	p.disc(60, 108, 7, 102)
	p.r(60, 103, 1, 5, SHADOW)
	p.r(60, 108, 4, 1, SHADOW)

static func _decor_books(p: Pen) -> void:
	# A tall bookcase with a ladder, a globe and a reading lamp.
	p.rr(78, 52, 136, 112, OUT)
	p.r(79, 53, 134, 110, 68)
	for row in range(4):
		var yy := 56 + row * 27
		p.r(80, yy, 132, 25, SHADOW)
		_goods(p, 83, yy + 22, 125, "books", row * 3 + 1)
		p.r(80, yy + 22, 132, 3, 71)
		p.r(80, yy + 22, 132, 1, 72)
	p.r(206, 54, 3, 108, 99)
	p.r(214, 54, 2, 108, 99)
	for yy in range(60, 160, 14):
		p.r(206, yy, 10, 1, 99)
	p.disc(60, 118, 10, OUT)
	p.disc(60, 118, 9, 94)
	p.ellipse(58, 116, 5, 3, 75)
	p.ellipse(63, 121, 3, 4, 75)
	p.r(58, 128, 5, 3, 71)
	p.r(55, 131, 11, 2, 69)
	_frame_picture(p, 58, 60, 16, 20, 2)

static func _decor_clothing(p: Pen) -> void:
	# A clothes rail, folded stacks, a mirror and a hat shelf.
	p.r(80, 62, 130, 2, 99)
	p.r(80, 62, 130, 1, 100)
	p.r(80, 62, 2, 100, 99)
	p.r(208, 62, 2, 100, 99)
	for hx in range(86, 206, 12):
		p.r(hx + 4, 62, 1, 3, 100)
		var cc: int = [85, 94, 89, 93, 87, 90, 97, 86][(hx / 12) % 8]
		p.r(hx, 65, 10, 26, cc)
		p.r(hx, 65, 10, 3, 102)
		p.r(hx - 2, 67, 3, 14, cc)
		p.r(hx + 9, 67, 3, 14, cc)
		p.r(hx, 88, 10, 3, 87 if cc != 87 else 85)
		p.r(hx + 1, 66, 1, 24, 102)
	_shelf_board(p, 80, 100, 134)
	_goods(p, 84, 100, 124, "clothes", 3)
	p.rr(58, 92, 16, 42, OUT)
	p.r(59, 93, 14, 40, 94)
	p.r(59, 93, 14, 6, 35)
	p.r(61, 100, 3, 24, 102)
	for hx in [140, 164, 188]:
		p.ellipse(hx, 110 + 1, 7, 3, 89 if hx == 164 else 85)
		p.r(hx - 4, 108, 8, 4, 89 if hx == 164 else 85)

# ---- counter (front layer) --------------------------------------------------------------------

static func _counter(p: Pen, spec: Dictionary, shop: String) -> void:
	var x := 70
	var w := 148
	p.shade(x - 2, FLOOR_Y - 2, w + 6, 10, 0.9)
	p.rr(x, COUNTER_Y, w, FLOOR_Y - COUNTER_Y + 1, OUT)
	p.r(x + 1, COUNTER_Y + 8, w - 2, FLOOR_Y - COUNTER_Y - 8, 69)
	# Front panels with grain and a lit left edge.
	for px_ in range(x + 3, x + w - 3, 18):
		p.r(px_, COUNTER_Y + 11, 16, FLOOR_Y - COUNTER_Y - 14, 70)
		p.r(px_, COUNTER_Y + 11, 16, 1, 71)
		p.r(px_ + 15, COUNTER_Y + 11, 1, FLOOR_Y - COUNTER_Y - 14, 68)
		for g in range(4):
			p.r(px_ + 3 + g * 3, COUNTER_Y + 16 + (g * 11) % 30, 1, 5, 68)
		p.px(px_ + 7, COUNTER_Y + 28, 71)
	p.r(x + 1, COUNTER_Y + 8, w - 2, 3, 68)
	# Counter top slab.
	p.rr(x - 2, COUNTER_Y, w + 4, 8, OUT)
	p.r(x - 1, COUNTER_Y + 1, w + 2, 6, 71)
	p.r(x - 1, COUNTER_Y + 1, w + 2, 2, 72)
	p.r(x - 1, COUNTER_Y + 6, w + 2, 1, 70)
	# A kick plate and glow from the lamps onto the counter.
	p.r(x + 1, FLOOR_Y - 5, w - 2, 4, 67)
	p.glow(150, COUNTER_Y + 2, 36, 0.8, 0.4)
	p.glow(206, COUNTER_Y + 2, 24, 0.7, 0.4)
	# Things on the counter.
	match shop:
		"cafe":
			_cake_stand(p, 84, COUNTER_Y)
			_register(p, 188, COUNTER_Y)
			Cozy.mug(p, 126, COUNTER_Y - 6, 85)
		"noodle":
			_bowl_stack(p, 84, COUNTER_Y)
			_steam_bowl(p, 120, COUNTER_Y)
			_register(p, 190, COUNTER_Y)
		"mart":
			_basket(p, 84, COUNTER_Y)
			_register(p, 176, COUNTER_Y)
			_goods(p, 118, COUNTER_Y, 40, "cans", 4)
		"pharmacy":
			_scale(p, 84, COUNTER_Y)
			_goods(p, 118, COUNTER_Y, 40, "pills", 2)
			_register(p, 188, COUNTER_Y)
		"bank":
			_bars(p, x, w)
			_register(p, 190, COUNTER_Y)
			_coin_stack(p, 84, COUNTER_Y)
		"news":
			_paper_stack(p, 84, COUNTER_Y)
			_paper_stack(p, 122, COUNTER_Y)
			_register(p, 190, COUNTER_Y)
		"books":
			Cozy.books(p, 82, COUNTER_Y, 4, 3)
			Cozy.desk_lamp(p, 112, COUNTER_Y - 12)
			_register(p, 190, COUNTER_Y)
		"clothing":
			_goods(p, 80, COUNTER_Y, 40, "clothes", 1)
			_hanger(p, 150, COUNTER_Y)
			_register(p, 190, COUNTER_Y)

static func _register(p: Pen, x: int, y: int) -> void:
	p.rr(x, y - 10, 18, 11, OUT)
	p.r(x + 1, y - 9, 16, 9, 100)
	p.r(x + 1, y - 9, 16, 1, 101)
	p.r(x + 3, y - 17, 12, 8, OUT)
	p.r(x + 4, y - 16, 10, 6, 75)
	p.r(x + 5, y - 15, 3, 1, 77)
	p.r(x + 3, y - 6, 12, 3, 99)
	for k in range(4):
		p.px(x + 4 + k * 3, y - 5, 101)

static func _cake_stand(p: Pen, x: int, y: int) -> void:
	p.r(x + 6, y - 6, 2, 6, 100)
	p.r(x + 2, y - 1, 10, 2, 100)
	p.ellipse(x + 7, y - 7, 8, 2, 102)
	p.rr(x + 1, y - 14, 12, 7, OUT)
	p.r(x + 2, y - 13, 10, 5, 85)
	p.r(x + 2, y - 13, 10, 2, 102)
	p.px(x + 5, y - 14, 87)
	p.px(x + 9, y - 15, 87)
	p.r(x + 16, y - 6, 12, 6, 102)
	p.r(x + 17, y - 9, 10, 4, 70)
	p.r(x + 17, y - 9, 10, 1, 71)
	p.px(x + 20, y - 8, 102)
	p.px(x + 23, y - 8, 102)

static func _bowl_stack(p: Pen, x: int, y: int) -> void:
	for k in range(3):
		p.rr(x, y - 5 - k * 4, 14, 5, OUT)
		p.r(x + 1, y - 4 - k * 4, 12, 3, 102)
		p.r(x + 1, y - 4 - k * 4, 12, 1, 112 if k % 2 == 0 else 87)

static func _steam_bowl(p: Pen, x: int, y: int) -> void:
	p.rr(x, y - 8, 20, 9, OUT)
	p.r(x + 1, y - 7, 18, 7, 102)
	p.r(x + 1, y - 7, 18, 3, 71)
	p.r(x + 3, y - 8, 14, 2, 89)
	p.r(x + 5, y - 8, 1, 2, 97)
	p.r(x + 10, y - 8, 1, 2, 97)
	for k in range(3):
		p.px(x + 6 + k * 4, y - 11 - k, 101)
		p.px(x + 7 + k * 4, y - 13 - k, 101)
		p.px(x + 6 + k * 4, y - 15 - k, 100)

static func _basket(p: Pen, x: int, y: int) -> void:
	p.rr(x, y - 10, 24, 11, OUT)
	p.r(x + 1, y - 9, 22, 9, 97)
	for k in range(0, 22, 3):
		p.r(x + 1 + k, y - 9, 1, 9, 98)
	p.r(x + 4, y - 14, 3, 5, 112)
	p.r(x + 10, y - 16, 4, 7, 76)
	p.r(x + 16, y - 13, 4, 4, 89)
	p.r(x + 2, y - 12, 20, 1, 100)

static func _scale(p: Pen, x: int, y: int) -> void:
	p.rr(x, y - 6, 22, 7, OUT)
	p.r(x + 1, y - 5, 20, 5, 102)
	p.rr(x + 5, y - 14, 12, 9, OUT)
	p.r(x + 6, y - 13, 10, 7, 101)
	p.r(x + 10, y - 12, 1, 3, 112)
	p.r(x + 8, y - 11, 2, 1, 99)

static func _bars(p: Pen, x: int, w: int) -> void:
	# Teller window: brass bars and a glass sign above the counter.
	p.r(x - 2, 124, w + 4, 2, 28)
	for bx in range(x + 4, x + w - 2, 8):
		p.r(bx, 126, 1, 42, 28)
		p.px(bx, 126, 95)
	p.rr(x + 40, 112, 60, 12, OUT)
	p.r(x + 41, 113, 58, 10, 102)
	p.r(x + 44, 117, 52, 2, 84)
	p.r(x - 2, 124, w + 4, 1, 95)

static func _coin_stack(p: Pen, x: int, y: int) -> void:
	for k in range(4):
		p.rr(x, y - 3 - k * 3, 10, 4, OUT)
		p.r(x + 1, y - 2 - k * 3, 8, 2, 96 if k % 2 == 0 else 89)
	p.rr(x + 14, y - 6, 8, 7, OUT)
	p.r(x + 15, y - 5, 6, 5, 28)
	p.r(x + 17, y - 4, 2, 3, 95)

static func _paper_stack(p: Pen, x: int, y: int) -> void:
	for k in range(3):
		p.rr(x + k % 2, y - 4 - k * 4, 30, 5, OUT)
		p.r(x + 1 + k % 2, y - 3 - k * 4, 28, 3, 102)
		p.r(x + 3 + k % 2, y - 3 - k * 4, 10, 1, 99)
		p.r(x + 15 + k % 2, y - 3 - k * 4, 8, 1, [85, 94, 89][k])
	p.r(x + 4, y - 18, 22, 1, 100)

static func _hanger(p: Pen, x: int, y: int) -> void:
	p.r(x + 6, y - 14, 1, 3, 100)
	p.r(x + 5, y - 15, 3, 1, 100)
	p.r(x, y - 11, 14, 1, 100)
	p.r(x + 1, y - 10, 12, 9, 85)
	p.r(x - 3, y - 10, 5, 4, 85)
	p.r(x + 12, y - 10, 5, 4, 85)
	p.r(x + 1, y - 10, 12, 1, 86)

# ---- shopkeepers (16x24) ----------------------------------------------------------------------

const KEEPERS := {
	"cafe": {"skin": 104, "hair": 108, "style": "bun", "shirt": 102, "apron": 91, "accent": 87, "extra": "tag"},
	"noodle": {"skin": 32, "hair": 103, "style": "toque", "shirt": 102, "apron": 112, "accent": 112, "extra": "bandana"},
	"mart": {"skin": 50, "hair": 103, "style": "cap", "shirt": 84, "apron": 112, "accent": 112, "extra": "vest"},
	"pharmacy": {"skin": 106, "hair": 109, "style": "bob", "shirt": 102, "apron": 102, "accent": 75, "extra": "glasses"},
	"news": {"skin": 31, "hair": 101, "style": "flatcap", "shirt": 87, "apron": 109, "accent": 97, "extra": "mustache"},
	"books": {"skin": 106, "hair": 100, "style": "bun", "shirt": 80, "apron": 82, "accent": 89, "extra": "roundglasses"},
	"clothing": {"skin": 104, "hair": 85, "style": "long", "shirt": 103, "apron": 94, "accent": 94, "extra": "scarf"},
	"bank": {"skin": 107, "hair": 103, "style": "short", "shirt": 84, "apron": 102, "accent": 112, "extra": "tie"}}

static func _dark(c: int) -> int:
	Pen._build_maps()
	return Pen._shade_map[c]

static func keeper(shop: String) -> ImageTexture:
	var key := "keeper_" + shop
	if cache.has(key):
		return cache[key]
	var spec: Dictionary = KEEPERS.get(shop, KEEPERS.cafe)
	var image := Pen.canvas(16, 24)
	var p := Pen.new(image)
	var skin: int = spec.skin
	var hair: int = spec.hair
	var shirt: int = spec.shirt
	# Legs and shoes.
	p.r(5, 20, 3, 3, 3)
	p.r(8, 20, 3, 3, 3)
	p.r(4, 23, 4, 1, 103)
	p.r(8, 23, 4, 1, 103)
	# Body, arms and hands.
	p.rr(3, 11, 10, 10, shirt, _dark(shirt))
	p.r(4, 12, 3, 1, 102)
	p.r(2, 12, 1, 6, shirt)
	p.r(13, 12, 1, 6, shirt)
	p.px(2, 18, skin)
	p.px(13, 18, skin)
	# Apron or jacket detail.
	match spec.extra:
		"vest":
			p.r(4, 12, 3, 8, spec.apron)
			p.r(9, 12, 3, 8, spec.apron)
			p.r(7, 12, 2, 8, shirt)
		"bandana":
			p.r(5, 11, 6, 2, 112)
			p.px(7, 13, 112)
			p.r(5, 14, 6, 6, 102)
		"scarf":
			p.r(4, 11, 8, 3, spec.accent)
			p.r(10, 13, 2, 5, spec.accent)
			p.px(11, 17, 102)
		"tie":
			p.r(7, 12, 2, 7, 112)
			p.r(6, 11, 4, 1, 102)
			p.r(4, 12, 2, 4, 102)
			p.r(10, 12, 2, 4, 102)
		"tag":
			p.rr(5, 14, 6, 6, spec.apron, _dark(int(spec.apron)))
			p.r(5, 13, 6, 1, spec.apron)
			p.r(9, 15, 2, 1, 102)
		"glasses":
			p.r(7, 12, 2, 8, 102)
			p.r(9, 14, 2, 2, 75)
			p.px(10, 14, 77)
		"mustache", "roundglasses":
			p.r(5, 14, 6, 6, spec.apron)
			p.r(5, 14, 6, 1, 71)
	# Head.
	p.rr(4, 2, 8, 9, skin, _dark(skin))
	p.px(5, 7, 105)
	p.px(10, 7, 105)
	p.px(6, 6, 103)
	p.px(9, 6, 103)
	p.px(7, 8, 105)
	p.px(8, 8, 105)
	# Hair and hats.
	match spec.style:
		"bun":
			p.r(4, 2, 8, 3, hair)
			p.px(4, 5, hair)
			p.px(11, 5, hair)
			p.rr(6, 0, 4, 3, hair)
			p.px(7, 1, 109 if hair == 108 else 101)
		"short":
			p.r(4, 2, 8, 3, hair)
			p.px(4, 5, hair)
			p.px(11, 5, hair)
			p.r(5, 2, 4, 1, 99)
		"bob":
			p.r(4, 2, 8, 3, hair)
			p.r(3, 3, 1, 7, hair)
			p.r(12, 3, 1, 7, hair)
			p.r(5, 2, 3, 1, 107)
		"long":
			p.r(4, 1, 8, 4, hair)
			p.r(3, 3, 2, 12, hair)
			p.r(11, 3, 2, 12, hair)
			p.px(5, 1, 86)
		"cap":
			p.r(3, 1, 10, 3, 112)
			p.r(4, 0, 8, 1, 112)
			p.r(8, 4, 6, 1, 26)
			p.px(6, 2, 102)
		"flatcap":
			p.r(3, 2, 10, 3, 109)
			p.r(4, 1, 8, 1, 109)
			p.r(9, 4, 5, 1, 108)
			p.px(5, 2, 69)
		"toque":
			p.r(4, 3, 8, 2, hair)
			p.rr(3, 0, 10, 4, 102, 101)
			p.rr(4, 0, 8, 2, 102)
			p.r(4, 3, 8, 1, 101)
	match spec.extra:
		"glasses":
			p.r(5, 5, 3, 3, 103)
			p.r(8, 5, 3, 3, 103)
			p.px(6, 6, 35)
			p.px(9, 6, 35)
			p.px(8, 6, 103)
		"roundglasses":
			p.r(5, 5, 3, 3, 89)
			p.r(8, 5, 3, 3, 89)
			p.px(6, 6, 35)
			p.px(9, 6, 35)
			p.px(8, 6, 89)
		"mustache":
			p.r(6, 8, 4, 1, 101)
			p.px(5, 9, 101)
			p.px(10, 9, 101)
	var texture := Pen.texture(image)
	cache[key] = texture
	return texture

# ---- 16x16 menu icons -------------------------------------------------------------------------

static func icon(id: String) -> ImageTexture:
	var key := "icon_" + id
	if cache.has(key):
		return cache[key]
	var image := Pen.canvas(16, 16)
	var p := Pen.new(image)
	match id:
		"coffee":
			p.r(3, 14, 10, 1, 66)
			p.rr(3, 6, 9, 8, OUT)
			p.r(4, 7, 7, 6, 102)
			p.r(4, 9, 7, 1, 85)
			p.r(4, 7, 7, 2, 70)
			p.r(12, 8, 3, 4, OUT)
			p.px(14, 9, 66)
			p.r(12, 9, 2, 2, 102)
			p.px(5, 3, 101)
			p.px(6, 2, 101)
			p.px(8, 3, 101)
			p.px(9, 1, 100)
		"pastry":
			p.ellipse(8, 9, 7, 4, OUT)
			p.ellipse(8, 9, 6, 3, 97)
			p.r(3, 7, 10, 1, 96)
			p.px(5, 8, 98)
			p.px(8, 7, 98)
			p.px(11, 8, 98)
			p.r(4, 10, 8, 1, 98)
			p.px(6, 6, 89)
			p.px(10, 6, 89)
			p.r(2, 12, 12, 1, 66)
		"noodle_bowl":
			p.r(4, 2, 1, 5, 109)
			p.r(8, 1, 1, 6, 109)
			p.rr(1, 7, 14, 8, OUT)
			p.r(2, 8, 12, 6, 112)
			p.r(2, 8, 12, 1, 26)
			p.r(2, 7, 12, 3, 89)
			p.px(4, 7, 97)
			p.px(7, 8, 97)
			p.px(10, 7, 97)
			p.px(12, 8, 76)
			p.r(5, 13, 6, 1, 87)
		"spring_rolls":
			p.rr(1, 4, 11, 4, OUT)
			p.r(2, 5, 9, 2, 97)
			p.px(11, 6, 70)
			p.rr(3, 8, 11, 4, OUT)
			p.r(4, 9, 9, 2, 96)
			p.px(13, 10, 70)
			p.r(5, 5, 4, 1, 98)
			p.r(6, 9, 4, 1, 98)
			p.rr(6, 12, 6, 3, OUT)
			p.r(7, 13, 4, 1, 112)
			p.px(2, 12, 76)
			p.px(3, 13, 75)
		"sandwich":
			p.rr(1, 3, 14, 4, OUT)
			p.r(2, 4, 12, 2, 70)
			p.r(2, 4, 12, 1, 71)
			p.r(1, 7, 14, 2, 76)
			p.px(3, 8, 75)
			p.px(7, 8, 75)
			p.px(11, 8, 75)
			p.r(2, 9, 12, 2, 112)
			p.r(2, 11, 12, 1, 89)
			p.rr(1, 12, 14, 3, OUT)
			p.r(2, 12, 12, 2, 70)
			p.px(4, 5, 89)
			p.px(9, 5, 89)
		"energy_drink":
			p.rr(4, 2, 8, 13, OUT)
			p.r(5, 3, 6, 11, 91)
			p.r(5, 3, 1, 11, 90)
			p.r(5, 3, 6, 2, 100)
			p.r(5, 12, 6, 2, 78)
			p.r(8, 5, 2, 3, 89)
			p.r(7, 8, 3, 1, 89)
			p.r(7, 9, 2, 3, 89)
			p.px(6, 2, 102)
		"vitamins":
			p.rr(3, 4, 10, 11, OUT)
			p.r(4, 5, 8, 9, 97)
			p.r(4, 5, 1, 9, 96)
			p.rr(3, 2, 10, 3, OUT)
			p.r(4, 2, 8, 2, 102)
			p.r(5, 8, 6, 4, 102)
			p.r(7, 8, 2, 4, 75)
			p.r(6, 9, 4, 2, 75)
			p.px(10, 6, 89)
		"cold_remedy":
			p.rr(2, 5, 12, 10, OUT)
			p.r(3, 6, 10, 8, 102)
			p.r(3, 6, 10, 2, 91)
			p.r(7, 9, 2, 5, 112)
			p.r(5, 11, 6, 2, 112)
			p.rr(10, 1, 5, 6, OUT)
			p.r(11, 2, 3, 4, 85)
			p.px(11, 2, 102)
		"magazine":
			p.rr(3, 1, 10, 14, OUT)
			p.r(4, 2, 8, 12, 94)
			p.r(4, 2, 8, 3, 112)
			p.r(5, 3, 6, 1, 102)
			p.r(5, 6, 4, 4, 102)
			p.r(5, 6, 4, 4, 89)
			p.r(10, 6, 2, 1, 102)
			p.r(10, 8, 2, 1, 102)
			p.r(5, 11, 6, 1, 102)
			p.r(5, 13, 4, 1, 102)
			p.px(4, 2, 102)
		"novel":
			p.rr(2, 2, 12, 13, OUT)
			p.r(3, 3, 10, 11, 80)
			p.r(3, 3, 1, 11, 81)
			p.r(5, 5, 6, 1, 89)
			p.r(5, 7, 6, 1, 89)
			p.r(6, 9, 4, 3, 89)
			p.r(3, 13, 10, 1, 79)
			p.r(2, 14, 12, 1, 102)
		"outfit":
			p.r(1, 3, 3, 5, OUT)
			p.r(12, 3, 3, 5, OUT)
			p.rr(3, 2, 10, 13, OUT)
			p.r(4, 3, 8, 11, 94)
			p.r(1, 4, 3, 3, 94)
			p.r(12, 4, 3, 3, 94)
			p.r(6, 2, 4, 2, OUT)
			p.r(4, 3, 1, 11, 35)
			p.r(8, 9, 3, 3, 84)
			p.r(4, 12, 8, 2, 84)
		"pouch":
			p.rr(3, 5, 10, 10, OUT)
			p.r(4, 6, 8, 8, 69)
			p.r(4, 6, 2, 8, 70)
			p.r(6, 3, 4, 3, OUT)
			p.r(7, 4, 2, 1, 71)
			p.r(4, 5, 8, 2, 112)
			p.r(7, 8, 2, 4, 89)
			p.r(6, 9, 4, 1, 89)
			p.r(6, 11, 4, 1, 89)
			p.px(11, 13, 68)
		_:
			p.rr(3, 3, 10, 10, OUT)
			p.r(4, 4, 8, 8, 89)
	var texture := Pen.texture(image)
	cache[key] = texture
	return texture

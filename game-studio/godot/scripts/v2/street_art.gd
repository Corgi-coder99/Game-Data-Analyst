extends RefCounted
# T-029 cozy street art (palette v4): sky, layered skyline, storefronts, pavement, asphalt, props, foreground trees.
# Everything is drawn once with Pen into images and cached per (day, mood). Animated bits (string lights, rain
# splashes, steam, falling leaves) are drawn by the commute scene on top of these textures.
const Pen = preload("res://scripts/v2/pen.gd")
const Cozy = preload("res://scripts/v2/cozy.gd")
const CityArt = preload("res://scripts/v2/city_art.gd")
const W := 640
const H := 360
const SIDEWALK_Y := 232
const ROAD_Y := 266
const SHOP_TOP := 114
const FRONT_Y := 290
const OUT := 65
const SHADOW := 66
const SKY := {
	"clear_dawn": [81, 82, 86, 92, 95, 89, 89],
	"clear": [94, 34, 35, 35, 22, 22, 102],
	"overcast": [5, 6, 40, 41, 41, 7, 7],
	"gloom": [3, 4, 5, 5, 6, 40, 40]}
const SHOPS := [
	{"x": 0, "variety": "cafe", "wall": [70, 71, 69], "trim": 68, "awn": [87, 102], "plate": 66, "ink": 95, "mode": "brick"},
	{"x": 84, "variety": "noodle", "wall": [78, 91, 73], "trim": 73, "awn": [112, 102], "plate": 103, "ink": 96, "mode": "siding"},
	{"x": 168, "variety": "mart", "wall": [84, 94, 79], "trim": 79, "awn": [96, 102], "plate": 103, "ink": 102, "mode": "panel"},
	{"x": 252, "variety": "bank", "wall": [101, 102, 100], "trim": 99, "awn": [84, 102], "plate": 84, "ink": 102, "mode": "stone"},
	{"x": 336, "variety": "news", "wall": [87, 85, 88], "trim": 88, "awn": [93, 102], "plate": 103, "ink": 86, "mode": "clap"},
	{"x": 420, "variety": "books", "wall": [80, 81, 79], "trim": 79, "awn": [74, 102], "plate": 103, "ink": 89, "mode": "brick"}]
const FLOWERS := [85, 89, 93, 87, 97, 86]
static var cache := {}

static func _h(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ 83492791) % 100

static func sky_key(day: int, crisis: int) -> String:
	if crisis == 2:
		return "gloom"
	if crisis == 1:
		return "overcast"
	return "clear_dawn" if day <= 2 else "clear"

# Returns {sky, cloud, layers, street, front, signs, bulbs, puddles}.
static func build(day: int, crisis: int, names: Array, headlines: Array) -> Dictionary:
	var key := "%d_%d" % [day, crisis]
	if cache.has(key):
		return cache[key]
	var out := {}
	var skey := sky_key(day, crisis)
	out.sky = _sky(day, crisis, skey)
	out.cloud = _clouds(day, crisis, skey)
	var layers: Array = []
	for i in range(3):
		layers.append(_skyline(i, day, crisis, SKY[skey][SKY[skey].size() - 1]))
	out.layers = layers
	var signs: Array = []
	var bulbs: Array = []
	var puddles: Array = []
	var street_image := Pen.canvas(W, H)
	var p := Pen.new(street_image)
	_build_street(p, day, crisis, names, headlines, signs, bulbs, puddles)
	out.street = Pen.texture(street_image)
	var front_image := Pen.canvas(W, H - FRONT_Y)
	var front := Pen.new(front_image)
	front.origin = Vector2i(0, -FRONT_Y)
	_build_front(front, day, crisis)
	out.front = Pen.texture(front_image)
	out.signs = signs
	out.bulbs = bulbs
	out.puddles = puddles
	cache[key] = out
	return out

# ---- sky and skyline ------------------------------------------------------------------------

static func _sky(day: int, crisis: int, skey: String) -> ImageTexture:
	var image := Pen.canvas(W, SIDEWALK_Y)
	var p := Pen.new(image)
	var bands: Array = SKY[skey]
	CityArt._sky(p, bands, 168)
	p.r(0, 168, W, SIDEWALK_Y - 168, bands[bands.size() - 1])
	if crisis == 0:
		var rim := 96 if day <= 2 else 89
		p.disc(502, 64, 18, rim)
		p.disc(502, 64, 14, 89 if day <= 2 else 95)
		p.disc(502, 64, 10, 102)
		p.glow(502, 64, 64, 1.0)
		if day <= 2:
			p.glow(502, 74, 110, 0.9, 0.7)
	elif crisis == 1:
		p.disc(502, 64, 9, 7)
		p.disc(502, 64, 6, 41)
	else:
		p.disc(502, 64, 8, 5)
	return Pen.texture(image)

static func _clouds(day: int, crisis: int, skey: String) -> ImageTexture:
	var image := Pen.canvas(1280, 90)
	var p := Pen.new(image)
	var light := 102 if crisis == 0 else (41 if crisis == 1 else 6)
	var shade := (85 if day <= 2 else 82) if crisis == 0 else (6 if crisis == 1 else 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 * day
	var count := 7 if crisis == 0 else 12
	for i in range(count):
		var cx := rng.randi_range(20, 1240)
		var cy := rng.randi_range(14, 60)
		var puffs := rng.randi_range(3, 5)
		for k in range(puffs):
			p.disc(cx + k * 10 - 12, cy + 3 + (k % 2) * -3, 6 + (k % 3) * 2, shade)
		for k in range(puffs):
			p.disc(cx + k * 10 - 12, cy + (k % 2) * -3, 6 + (k % 3) * 2, light)
		for k in range(puffs):
			p.px(cx + k * 10 - 14, cy - 3 + (k % 2) * -3, 102 if crisis == 0 else 8)
		p.r(cx - 14, cy + 7, puffs * 10 + 8, 3, shade)
	return Pen.texture(image)

static func _skyline(layer: int, day: int, crisis: int, haze: int) -> ImageTexture:
	var baselines := [190, 205, 218]
	var mins := [100, 105, 104]
	var maxs := [150, 145, 128]
	var seeds := [21, 22, 23]
	var palettes: Array
	if crisis == 0:
		palettes = [[82, 94, 81], [81, 82, 80], [80, 81, 79]]
	elif crisis == 1:
		palettes = [[41, 7, 40], [40, 41, 6], [5, 6, 4]]
	else:
		palettes = [[6, 40, 5], [5, 6, 4], [3, 4, 2]]
	var colors: Array = palettes[layer]
	var baseline: int = baselines[layer]
	var image := Pen.canvas(760, baseline)
	var p := Pen.new(image)
	var local := RandomNumberGenerator.new()
	local.seed = int(seeds[layer]) * 101 + day * 3
	var lit_chance := (0.2 if layer == 0 else 0.3) if crisis == 0 else 0.4
	var lit_colors: Array = [95, 96] if layer < 2 else [96, 97, 95]
	var x := -6
	while x < 760:
		var bw := local.randi_range(22, 46)
		var bh := local.randi_range(int(mins[layer]), int(maxs[layer]))
		var top := baseline - bh
		p.box(x, top, bw, bh, colors[0], colors[1], colors[2])
		p.r(x, top - 1, bw, 1, colors[2])
		var roof := local.randi_range(0, 5)
		match roof:
			0:
				p.r(x + bw / 2, top - 11, 1, 10, colors[2])
				p.px(x + bw / 2, top - 12, 87 if layer == 2 else colors[1])
			1:
				p.r(x + 3, top - 4, 8, 3, colors[2])
				p.r(x + 4, top - 8, 6, 4, colors[0])
				p.r(x + 4, top - 8, 6, 1, colors[1])
				p.r(x + 5, top - 4, 1, 2, colors[2])
				p.r(x + 8, top - 4, 1, 2, colors[2])
			2:
				p.r(x + 2, top - 3, bw - 4, 2, colors[1])
				for gx in range(x + 4, x + bw - 4, 5):
					p.r(gx, top - 5, 2, 2, 75 if layer == 2 and crisis == 0 else colors[2])
			3:
				p.r(x + bw - 10, top - 5, 7, 4, colors[2])
				p.r(x + bw - 9, top - 6, 5, 1, colors[1])
		var window_h := 4
		for wy in range(top + 6, baseline - 6, 7):
			for wx in range(x + 4, x + bw - 5, 6):
				var roll := local.randf()
				if roll < lit_chance:
					var color: int = lit_colors[local.randi_range(0, lit_colors.size() - 1)]
					p.r(wx, wy, 3, window_h, color)
					p.px(wx, wy, 102)
				elif layer > 0:
					p.r(wx, wy, 3, window_h, colors[2])
					if roll > 0.88:
						p.px(wx + 1, wy, colors[1])
		x += bw + local.randi_range(0, 4)
	# Layered haze: the lower part of every layer fades into the sky color.
	var depth := 70 if layer == 0 else (56 if layer == 1 else 34)
	var peak := 0.8 if layer == 0 else (0.55 if layer == 1 else 0.3)
	for y in range(baseline - depth, baseline):
		var density := float(y - (baseline - depth)) / float(depth) * peak
		for xx in range(760):
			var threshold := float(Pen.BAYER[(y & 3) * 4 + (xx & 3)]) / 16.0
			if density > threshold and image.get_pixel(xx, y).a > 0.5:
				image.set_pixel(xx, y, Pen.Palette.color(haze))
	return Pen.texture(image)

# ---- pavement and road ----------------------------------------------------------------------

static func _paving(p: Pen, y0: int, y1: int, base: int, alt: int, hi: int, grout: int, seed_value: int) -> void:
	p.r(0, y0, W, y1 - y0, grout)
	var row := 0
	for yy in range(y0, y1, 8):
		var shift := 8 if row % 2 == 1 else 0
		for xx in range(-shift, W, 16):
			var color := alt if _h(xx / 16 + seed_value, row) < 22 else base
			var sh := mini(7, y1 - yy - 1)
			if sh <= 0:
				continue
			p.r(maxi(xx + 1, 0), yy + 1, 15 - (0 if xx >= 0 else -xx), sh, color)
			p.r(maxi(xx + 1, 0), yy + 1, 15 - (0 if xx >= 0 else -xx), 1, hi)
			if _h(xx + 3, yy) < 45:
				p.px(xx + 3 + _h(xx, yy) % 9, yy + 3 + _h(yy, xx) % 3, grout)
			if _h(xx + 9, yy + 5) < 16:
				p.px(xx + 6, yy + 5, hi)
		row += 1

static func _asphalt(p: Pen, day: int, crisis: int, puddles: Array) -> void:
	var top := ROAD_Y
	var bottom := 328
	p.r(0, top, W, bottom - top, 99)
	for y in range(top, bottom):
		for x in range(W):
			var roll := _h(x, y)
			if roll < 7:
				p.px(x, y, 100)
			elif roll > 95:
				p.px(x, y, SHADOW)
	# Tire wear bands and cracks.
	p.shade(0, 276, W, 10, 0.16)
	p.shade(0, 306, W, 10, 0.16)
	for i in range(14):
		var cx := (i * 83 + day * 17) % (W - 30)
		var cy := top + 6 + (i * 41) % 50
		p.r(cx, cy, 6 + i % 5, 1, SHADOW)
		p.r(cx + 5 + i % 5, cy + 1, 3, 1, SHADOW)
		p.r(cx + 8 + i % 5, cy + 2, 2, 1, SHADOW)
	# Patches and a manhole.
	p.r(60, 308, 22, 9, 66)
	p.r(60, 308, 22, 1, 99)
	p.disc(430, 312, 5, SHADOW)
	p.disc(430, 312, 4, 100)
	p.r(427, 311, 7, 1, SHADOW)
	p.r(430, 308, 1, 8, SHADOW)
	# Painted lane line, dashed and worn.
	for x in range(8, W, 30):
		if x > 240 and x < 290:
			continue
		p.r(x, 296, 16, 2, SHADOW)
		p.r(x, 295, 16, 2, 89)
		for k in range(4):
			var wx := x + _h(x, k) % 16
			p.px(wx, 295 + _h(k, x) % 2, 99)
	# Painted curb edge lines.
	p.r(0, 267, W, 1, 4)
	# Cobbled crosswalk: light and dark bands of stones.
	for yy in range(top, bottom, 4):
		var band := ((yy - top) / 8) % 2
		var row := (yy - top) / 4
		for xx in range(246 + (row % 2) * 3, 284, 6):
			var color: int = [100, 100, 101][_h(xx, yy) % 3] if band == 0 else [99, 99, 66][_h(xx, yy) % 3]
			p.r(maxi(xx, 246), yy, mini(5, 284 - xx), 3, color)
			p.r(maxi(xx, 246), yy, mini(5, 284 - xx), 1, 101 if band == 0 else 100)
	p.r(246, top, 1, bottom - top, SHADOW)
	p.r(283, top, 1, bottom - top, SHADOW)
	if crisis >= 1:
		var spots := [[120, 280, 14, 3], [360, 312, 18, 3], [500, 290, 12, 2], [70, 318, 10, 2]]
		if crisis >= 2:
			spots += [[220, 304, 12, 3], [430, 276, 16, 3], [580, 322, 14, 2]]
		for s in spots:
			p.ellipse(s[0], s[1], s[2], s[3], 84)
			p.ellipse(s[0] - 1, s[1] - 1, s[2] - 2, maxi(1, s[3] - 1), 83)
			p.r(s[0] - s[2] / 2, s[1] - 1, s[2] / 2, 1, 94)
			p.px(s[0] - s[2] / 3, s[1], 102)
			puddles.append(Vector3(s[0], s[1], s[2]))

# ---- storefronts ----------------------------------------------------------------------------

static func _wall_texture(p: Pen, x: int, top: int, w: int, h: int, wall: Array, mode: String) -> void:
	p.r(x, top, w, h, wall[0])
	match mode:
		"brick":
			for yy in range(top + 6, top + h, 4):
				p.r(x, yy, w, 1, wall[2])
				var shift := ((yy - top) / 4) % 2 * 5
				for xx in range(x + shift, x + w, 10):
					p.r(xx, yy + 1, 1, 3, wall[2])
				for xx in range(x + shift + 2, x + w, 20):
					p.px(xx, yy + 2, wall[1])
		"siding":
			for xx in range(x + 2, x + w, 4):
				p.r(xx, top + 6, 1, h - 6, wall[2])
				p.r(xx + 1, top + 6, 1, h - 6, wall[1])
		"panel":
			for yy in range(top + 10, top + h, 12):
				p.r(x, yy, w, 1, wall[2])
				p.r(x, yy + 1, w, 1, wall[1])
		"stone":
			for yy in range(top + 6, top + h, 7):
				p.r(x, yy, w, 1, wall[2])
				var shift := ((yy - top) / 7) % 2 * 9
				for xx in range(x + shift, x + w, 18):
					p.r(xx, yy + 1, 1, 6, wall[2])
		_:
			for yy in range(top + 8, top + h, 5):
				p.r(x, yy, w, 1, wall[2])
				p.r(x, yy + 1, w, 1, wall[1])

static func _planter(p: Pen, x: int, y: int, w: int, seed_value: int) -> void:
	# A flower box: wood body, leaves and a row of blooms. (x, y) is the top-left of the box.
	for i in range(w):
		var lean := _h(x + i, seed_value) % 3
		p.r(x + i, y - 1 - lean, 1, 2 + lean, 74 if i % 2 == 0 else 75)
		if i % 3 == seed_value % 3:
			p.px(x + i, y - 3 - lean, FLOWERS[(i + seed_value) % FLOWERS.size()])
			p.px(x + i, y - 2 - lean, 77 if i % 2 == 0 else 102)
	p.r(x, y + 1, w, 4, 69)
	p.r(x, y + 1, w, 1, 70)
	p.r(x, y + 4, w, 1, 68)
	p.r(x - 1, y + 1, 1, 4, OUT)
	p.r(x + w, y + 1, 1, 4, OUT)
	p.r(x, y + 5, w, 1, OUT)

static func _upper_window(p: Pen, wx: int, top: int, s: Dictionary, closed: bool, index: int, window_index: int) -> void:
	var wall: Array = s.wall
	p.r(wx - 1, top + 11, 22, 20, OUT)
	p.r(wx, top + 12, 20, 18, wall[1])
	var glass := 83 if closed else (95 if (index + window_index) % 3 != 1 else 94)
	p.r(wx + 2, top + 14, 16, 14, glass)
	if not closed:
		if glass == 95:
			p.r(wx + 2, top + 22, 16, 6, 96)
			p.r(wx + 2, top + 26, 16, 2, 97)
			p.glow(wx + 10, top + 24, 12, 0.7, 0.7)
		else:
			p.r(wx + 2, top + 14, 16, 4, 35)
			p.r(wx + 2, top + 18, 16, 3, 34)
		# Curtains and a small plant on the sill.
		p.r(wx + 2, top + 14, 4, 14, 86 if window_index == 0 else 102)
		p.r(wx + 14, top + 14, 4, 14, 86 if window_index == 0 else 102)
		p.r(wx + 5, top + 14, 1, 14, 85)
		p.r(wx + 14, top + 14, 1, 14, 85)
		p.r(wx + 2, top + 14, 16, 1, 87)
	p.r(wx + 9, top + 14, 2, 14, wall[1])
	p.r(wx + 2, top + 20, 16, 1, wall[1])
	p.px(wx + 3, top + 15, 102)
	p.px(wx + 4, top + 16, 102)
	p.r(wx - 2, top + 30, 24, 3, wall[1])
	p.r(wx - 2, top + 32, 24, 1, wall[2])
	_planter(p, wx - 1, top + 31, 22, index + window_index * 2)

static func _door(p: Pen, x: int, top: int, w: int, bottom: int, frame: int, hi: int, lit: bool) -> void:
	p.rr(x - 1, top - 1, w + 2, bottom - top + 1, OUT)
	p.r(x, top, w, bottom - top, frame)
	p.r(x, top, w, 1, hi)
	p.r(x, top, 1, bottom - top, hi)
	var glass := 96 if lit else 83
	p.r(x + 2, top + 2, w - 4, bottom - top - 5, glass)
	p.r(x + 2, top + 2, w - 4, 3, 95 if lit else 84)
	p.r(x + w / 2, top + 2, 1, bottom - top - 5, frame)
	p.r(x + 2, top + (bottom - top) / 2, w - 4, 1, frame)
	p.px(x + w / 2 - 2, top + (bottom - top) / 2 + 4, 89)
	p.px(x + w / 2 + 2, top + (bottom - top) / 2 + 4, 89)
	p.r(x + 4, top + 6, 2, 1, 102)
	p.r(x + 5, top + 7, 2, 1, 102)
	p.r(x + 4, bottom - 1, w - 8, 1, 66)
	if lit:
		p.glow(x + w / 2, top + (bottom - top) / 2, 14, 0.8, 1.0)

static func _shop(p: Pen, s: Dictionary, index: int, day: int, crisis: int, name: String, signs: Array, bulbs: Array, headlines: Array) -> void:
	var x: int = s.x
	var w := 84
	var wall: Array = s.wall
	var top := SHOP_TOP
	var bottom := SIDEWALK_Y
	var variety: String = s.variety
	var closed := crisis >= 2 and index in [0, 5]
	_wall_texture(p, x, top, w, bottom - top, wall, s.mode)
	# Edge light on the left, shade on the right, dark seam between shops.
	p.r(x, top, 1, bottom - top, wall[1])
	p.r(x + w - 3, top, 2, bottom - top, wall[2])
	p.r(x + w - 1, top - 5, 1, bottom - top + 5, OUT)
	# Roof parapet and cornice with dentils.
	p.r(x, top - 5, w, 5, wall[1])
	p.r(x, top - 5, w, 1, OUT)
	p.r(x, top - 1, w, 1, wall[2])
	p.r(x, top, w, 5, wall[1])
	for dx in range(x + 1, x + w - 2, 4):
		p.r(dx, top + 2, 2, 3, wall[2])
	p.r(x, top + 5, w, 1, OUT)
	match variety:
		"cafe":
			p.box(x + 60, top - 12, 10, 8, 100, 101, 99)
			p.r(x + 62, top - 10, 6, 1, SHADOW)
			p.r(x + 6, top - 9, 3, 4, 68)
		"noodle":
			p.r(x + 12, top - 12, 6, 8, 68)
			p.r(x + 11, top - 13, 8, 2, 69)
			Cozy.leaf(p, x + 54, top - 7, 4)
			Cozy.leaf(p, x + 62, top - 6, 3)
		"mart":
			p.box(x + 10, top - 14, 14, 10, 69, 70, 68)
			p.r(x + 9, top - 15, 16, 2, 68)
			p.r(x + 12, top - 4, 1, 3, 66)
			p.r(x + 21, top - 4, 1, 3, 66)
		"bank":
			p.r(x + 41, top - 16, 1, 12, 99)
			p.r(x + 42, top - 16, 7, 4, 112)
			p.r(x + 42, top - 14, 7, 1, 87)
		"news":
			p.r(x + 60, top - 12, 1, 8, 99)
			p.r(x + 56, top - 11, 9, 1, 99)
			p.px(x + 60, top - 13, 112)
		"books":
			p.rr(x + 30, top - 11, 14, 8, OUT)
			p.r(x + 32, top - 9, 10, 4, 95 if crisis == 0 else 84)
			p.r(x + 36, top - 9, 1, 4, wall[2])
	# Upper windows and the news board.
	if variety == "news":
		p.rr(x + 3, top + 9, 78, 25, OUT)
		p.r(x + 4, top + 10, 76, 23, 103)
		p.r(x + 5, top + 11, 74, 21, 4)
		p.r(x + 5, top + 11, 74, 1, 5)
		var headline: String = headlines[clampi(day - 1, 0, headlines.size() - 1)]
		signs.append({"text": headline, "x": x + 4 + (76 - Pen.text_width(headline, 8)) / 2, "y": top + 17, "ink": 95, "size": 8})
		signs.append({"text": "NEWS FLASH", "x": x + 4 + (76 - Pen.text_width("NEWS FLASH", 8)) / 2, "y": top + 6, "ink": 102, "size": 8})
		p.glow(x + 42, top + 22, 30, 0.7, 0.45)
	else:
		for wi in range(2):
			_upper_window(p, x + (10 if wi == 0 else 54), top, s, closed, index, wi)
	# Sign plate with a warm glow.
	var sign_y := top + 38
	p.rr(x + 3, sign_y - 1, w - 6, 17, OUT)
	p.r(x + 4, sign_y, w - 8, 15, s.plate)
	p.r(x + 4, sign_y, w - 8, 1, 99 if s.plate in [103, 66] else 102)
	p.r(x + 4, sign_y + 14, w - 8, 1, OUT)
	for px_ in [x + 6, x + w - 7]:
		p.px(px_, sign_y + 2, 71)
		p.px(px_, sign_y + 12, 71)
	for lx in [x + 12, x + w - 13]:
		p.r(lx, sign_y - 5, 1, 4, OUT)
		p.r(lx - 2, sign_y - 6, 5, 2, 97)
	p.glow(x + 42, sign_y + 7, 40, 0.5, 0.5)
	signs.append({"text": name, "x": x + 4 + (w - 8 - Pen.text_width(name, 8)) / 2, "y": sign_y + 3, "ink": s.ink, "size": 8})
	# Awning with stripes, fabric folds and a scalloped edge.
	var awn: Array = s.awn
	var awning_y := sign_y + 17
	if variety != "bank":
		for sx in range(0, w, 8):
			var color: int = awn[(sx / 8) % 2]
			p.r(x + sx, awning_y, 8, 8, color)
			p.r(x + sx + 1, awning_y + 8, 6, 2, color)
			p.r(x + sx + 2, awning_y + 10, 4, 1, color)
			p.r(x + sx + 1, awning_y + 11, 4, 1, OUT)
			# Fold: a lit crease on the left, a shaded one on the right.
			for yy in range(awning_y + 1, awning_y + 9):
				p.tone_px(x + sx + 1, yy, 1)
				p.tone_px(x + sx + 6, yy, -1)
				p.tone_px(x + sx + 7, yy, -1)
			p.r(x + sx + 1, awning_y + 9, 1, 1, OUT)
		p.r(x, awning_y - 1, w, 1, OUT)
		p.r(x, awning_y, w, 1, 102 if awn[0] != 102 else 101)
		p.r(x, awning_y + 1, w, 1, 71)
		p.shade(x, awning_y + 11, w, 12, 0.7)
	else:
		p.r(x + 2, awning_y - 1, w - 4, 1, OUT)
		p.r(x + 2, awning_y, w - 4, 4, 102)
		p.r(x + 2, awning_y + 4, w - 4, 1, 99)
		p.r(x + 12, awning_y - 5, 60, 5, 101)
		p.r(x + 12, awning_y - 5, 60, 1, 102)
		p.r(x + 22, awning_y - 9, 40, 4, 101)
		p.r(x + 22, awning_y - 9, 40, 1, 102)
	var win_top := awning_y + 12
	var win_h := bottom - win_top - 2
	match variety:
		"cafe":
			_window_frame(p, x + 6, win_top, 46, win_h)
			var interior := 83 if closed else 92
			p.r(x + 7, win_top + 1, 44, win_h - 2, interior)
			if not closed:
				p.r(x + 7, win_top + 1, 44, 12, 86)
				# Shelf of cups, chalkboard, pendant lamps and the counter with a cake stand.
				p.r(x + 9, win_top + 10, 18, 1, 69)
				for cx in range(x + 10, x + 26, 4):
					p.r(cx, win_top + 7, 3, 3, 102)
					p.px(cx + 3, win_top + 8, 102)
				p.r(x + 30, win_top + 3, 17, 11, OUT)
				p.r(x + 31, win_top + 4, 15, 9, 103)
				p.r(x + 33, win_top + 6, 8, 1, 102)
				p.r(x + 33, win_top + 9, 11, 1, 89)
				p.r(x + 36, win_top + 11, 5, 1, 102)
				for lx in [x + 14, x + 28, x + 42]:
					p.r(lx, win_top + 1, 1, 5, OUT)
					p.rr(lx - 2, win_top + 6, 5, 4, 97)
					p.glow(lx, win_top + 12, 8, 0.8)
				p.r(x + 7, win_top + 22, 44, win_h - 23, 69)
				p.r(x + 7, win_top + 22, 44, 2, 70)
				p.r(x + 7, win_top + 24, 44, 1, 68)
				p.r(x + 14, win_top + 17, 11, 1, 102)
				p.ellipse(x + 19, win_top + 15, 5, 2, 102)
				p.px(x + 17, win_top + 14, 70)
				p.px(x + 20, win_top + 14, 97)
				p.px(x + 22, win_top + 14, 85)
				p.r(x + 33, win_top + 17, 5, 5, 102)
				p.r(x + 41, win_top + 18, 4, 4, 85)
				p.px(x + 34, win_top + 15, 101)
			else:
				p.r(x + 7, win_top + 1, 44, win_h - 2, 4)
				for sy in range(win_top + 2, win_top + win_h - 2, 3):
					p.r(x + 7, sy, 44, 1, 5)
			_door(p, x + 56, awning_y + 12, 22, bottom, 69, 70, not closed)
			# Outdoor table with an umbrella.
			_table_umbrella(p, x + 14, 245)
			if crisis >= 2:
				p.rr(x + 58, awning_y + 20, 18, 10, OUT)
				p.r(x + 59, awning_y + 21, 16, 8, 102)
				signs.append({"text": "CLOSED", "x": x + 60, "y": awning_y + 21, "ink": 112, "size": 8})
		"noodle":
			_window_frame(p, x + 6, win_top, 72, win_h)
			p.r(x + 7, win_top + 1, 70, win_h - 2, 88)
			p.r(x + 7, win_top + 1, 70, 8, 67)
			for lx in [x + 12, x + 40, x + 66]:
				p.r(lx + 4, win_top + 1, 1, 4, OUT)
				p.ellipse(lx + 4, win_top + 9, 4, 5, 112)
				p.r(lx, win_top + 8, 9, 1, 87)
				p.r(lx + 2, win_top + 5, 5, 1, 97)
				p.r(lx + 2, win_top + 13, 5, 1, 97)
				p.px(lx + 2, win_top + 7, 102)
				p.glow(lx + 4, win_top + 9, 10, 0.7)
			p.r(x + 7, win_top + win_h - 14, 70, 12, 69)
			p.r(x + 7, win_top + win_h - 14, 70, 2, 71)
			p.r(x + 7, win_top + win_h - 3, 70, 1, 68)
			p.rr(x + 12, win_top + win_h - 25, 16, 11, OUT)
			p.r(x + 13, win_top + win_h - 24, 14, 9, 5)
			p.r(x + 13, win_top + win_h - 24, 14, 2, 6)
			p.r(x + 11, win_top + win_h - 26, 18, 2, 99)
			for bx in [x + 36, x + 44, x + 52]:
				p.r(bx, win_top + win_h - 20, 6, 5, 102)
				p.r(bx, win_top + win_h - 20, 6, 1, 71)
				p.r(bx + 1, win_top + win_h - 21, 4, 1, 89)
			p.rr(x + 60, win_top + 3, 16, 12, OUT)
			p.r(x + 61, win_top + 4, 14, 10, 102)
			p.r(x + 62, win_top + 8, 12, 1, 112)
			p.r(x + 62, win_top + 11, 9, 1, 112)
			signs.append({"text": "MENU", "x": x + 61, "y": win_top + 4, "ink": 112, "size": 8})
		"mart":
			_window_frame(p, x + 6, win_top, 46, win_h)
			p.r(x + 7, win_top + 1, 44, win_h - 2, 102)
			for row in range(3):
				var sy := win_top + 3 + row * 14
				p.r(x + 8, sy + 11, 42, 2, 99)
				p.r(x + 8, sy + 13, 42, 1, 100)
				for bx in range(x + 9, x + 47, 5):
					var kind := _h(bx, row + 1) % 4
					var tint: int = [85, 89, 91, 93, 94, 97, 87, 90][_h(bx + row, 7) % 8]
					if kind == 0:
						p.r(bx, sy + 1, 3, 10, tint)
						p.r(bx + 1, sy, 1, 2, 100)
						p.r(bx, sy + 1, 1, 9, 102)
					elif kind == 1:
						p.r(bx, sy + 3, 4, 8, tint)
						p.r(bx, sy + 3, 4, 1, 102)
						p.r(bx + 1, sy + 6, 2, 2, 102)
					else:
						p.r(bx, sy + 5, 4, 6, tint)
						p.r(bx, sy + 5, 1, 6, 102)
			p.glow(x + 29, win_top + 22, 22, 0.55, 0.9)
			_door(p, x + 56, awning_y + 12, 22, bottom, 79, 84, true)
		"bank":
			for cx in [x + 6, x + 26, x + 50, x + 70]:
				p.rr(cx, awning_y + 4, 8, 44, OUT)
				p.r(cx + 1, awning_y + 5, 6, 42, 102)
				p.r(cx + 1, awning_y + 5, 1, 42, 64)
				p.r(cx + 6, awning_y + 5, 1, 42, 100)
				p.r(cx + 3, awning_y + 5, 1, 42, 101)
				p.r(cx - 1, awning_y + 4, 10, 3, 101)
				p.r(cx - 1, awning_y + 46, 10, 3, 101)
			p.r(x + 14, awning_y + 6, 56, 3, 71)
			_door(p, x + 34, awning_y + 12, 22, bottom, 27, 28, true)
			p.r(x + 36, awning_y + 14, 18, 3, 28)
			for wx2 in [x + 10, x + 58]:
				p.rr(wx2, awning_y + 20, 16, 24, OUT)
				p.r(wx2 + 1, awning_y + 21, 14, 22, 94)
				p.r(wx2 + 1, awning_y + 21, 14, 4, 35)
				for bx in range(wx2 + 3, wx2 + 14, 4):
					p.r(bx, awning_y + 21, 1, 22, 28)
				p.r(wx2 + 1, awning_y + 36, 14, 7, 71)
				p.px(wx2 + 3, awning_y + 24, 102)
		"news":
			_window_frame(p, x + 6, win_top, 46, win_h)
			p.r(x + 7, win_top + 1, 44, win_h - 2, 102)
			for row in range(2):
				p.r(x + 8, win_top + 12 + row * 14, 42, 2, 99)
				for col in range(5):
					var cc: int = [85, 89, 91, 93, 94, 97, 87, 90, 86, 92][row * 5 + col]
					p.r(x + 9 + col * 8, win_top + 2 + row * 14, 6, 10, cc)
					p.r(x + 9 + col * 8, win_top + 2 + row * 14, 6, 1, 102)
					p.r(x + 10 + col * 8, win_top + 4 + row * 14, 4, 2, 102)
					p.r(x + 10 + col * 8, win_top + 8 + row * 14, 4, 1, 66)
			_door(p, x + 56, awning_y + 12, 22, bottom, 88, 87, true)
			_news_rack(p, x + 8, 241)
		"books":
			_window_frame(p, x + 6, win_top, 46, win_h)
			p.r(x + 7, win_top + 1, 44, win_h - 2, 108 if closed else 69)
			for row in range(3):
				var by := win_top + 4 + row * 14
				p.r(x + 8, by + 10, 42, 2, 68)
				p.r(x + 8, by + 10, 42, 1, 71)
				var bx := x + 9
				var n := 0
				while bx < x + 48:
					var bw := 2 + _h(bx, row) % 3
					var bh := 6 + _h(row, bx) % 5
					var cc: int = [85, 89, 91, 93, 94, 97, 87, 90, 80, 74][_h(bx, row + 3) % 10]
					p.r(bx, by + 10 - bh, bw, bh, cc)
					p.r(bx, by + 10 - bh, 1, bh, 102)
					p.r(bx, by + 10 - bh, bw, 1, 102)
					bx += bw + 1
					n += 1
			p.glow(x + 29, win_top + 16, 24, 0.6, 0.8)
			_door(p, x + 56, awning_y + 12, 22, bottom, 79, 80, not closed)
	# Shadow under the awning onto the window displays.
	p.shade(x + 4, win_top, w - 8, 8, 0.7)
	# Closing-down banner and posters on crisis days.
	if variety == "books" and day >= 4:
		p.rr(x + 3, 120, 78, 12, OUT)
		p.r(x + 4, 121, 76, 10, 112)
		p.r(x + 4, 121, 76, 1, 26)
		signs.append({"text": "CLOSING SALE", "x": x + 6, "y": 122, "ink": 102, "size": 8})
		for tx in [x + 12, x + 34]:
			p.r(tx, win_top + 14, 8, 11, 102)
			p.r(tx + 1, win_top + 16, 6, 1, 112)
			p.r(tx + 1, win_top + 19, 6, 1, 112)
			p.r(tx + 1, win_top + 22, 4, 1, 112)

static func _window_frame(p: Pen, x: int, y: int, w: int, h: int) -> void:
	p.rr(x - 1, y - 1, w + 2, h + 1, OUT)
	p.r(x, y, 1, h - 1, 99)

static func _table_umbrella(p: Pen, cx: int, y: int) -> void:
	# Chairs, round table, a mug and a striped parasol. y is the table top.
	p.shade(cx - 14, y + 4, 28, 12, 0.5)
	for chx in [cx - 12, cx + 8]:
		p.r(chx, y + 4, 5, 2, 94)
		p.r(chx, y - 2, 1, 6, 84)
		p.r(chx + 4, y - 2, 1, 6, 84)
		p.r(chx, y + 6, 1, 6, OUT)
		p.r(chx + 4, y + 6, 1, 6, OUT)
	p.ellipse(cx, y, 8, 2, 102)
	p.r(cx - 7, y + 1, 15, 1, 101)
	p.r(cx - 1, y + 2, 2, 11, 99)
	p.r(cx - 3, y + 13, 7, 1, OUT)
	p.r(cx - 3, y - 2, 3, 2, 85)
	p.px(cx - 2, y - 4, 101)
	# Parasol canopy.
	p.r(cx, y - 14, 1, 14, 100)
	p.ellipse(cx, y - 13, 15, 4, OUT)
	p.ellipse(cx, y - 13, 14, 3, 102)
	for sx in range(cx - 14, cx + 14, 4):
		p.r(sx, y - 15, 2, 5, 87)
	p.r(cx - 12, y - 11, 25, 1, 85)
	p.px(cx, y - 17, 100)

static func _news_rack(p: Pen, x: int, y: int) -> void:
	p.shade(x - 2, y + 14, 24, 8, 0.5)
	p.r(x, y + 15, 1, 7, OUT)
	p.r(x + 17, y + 15, 1, 7, OUT)
	p.rr(x - 1, y, 20, 16, OUT)
	p.r(x, y + 1, 18, 14, 101)
	for row in range(3):
		for col in range(4):
			var cc: int = [85, 89, 91, 93, 94, 97, 87, 90, 86, 92, 80, 74][row * 4 + col]
			p.r(x + 1 + col * 4, y + 2 + row * 4, 3, 4, cc)
			p.r(x + 1 + col * 4, y + 2 + row * 4, 3, 1, 102)
		p.r(x, y + 5 + row * 4, 18, 1, 100)
	p.r(x + 22, y + 8, 8, 14, OUT)
	p.r(x + 23, y + 9, 6, 12, 69)
	p.r(x + 24, y + 11, 4, 2, 102)
	p.r(x + 24, y + 15, 4, 1, 102)

static func _food_cart(p: Pen, x: int, y: int) -> void:
	# A noodle cart on the sidewalk. (x, y) is the top-left; 30 wide, 22 tall.
	p.shade(x - 2, y + 18, 36, 8, 0.6)
	p.rr(x + 1, y + 7, 28, 12, OUT)
	p.r(x + 2, y + 8, 26, 10, 69)
	p.r(x + 2, y + 8, 26, 2, 71)
	p.r(x + 2, y + 17, 26, 1, 68)
	p.r(x + 5, y + 12, 8, 4, 102)
	p.r(x + 6, y + 13, 6, 1, 112)
	p.px(x + 17, y + 11, 89)
	p.px(x + 20, y + 11, 97)
	p.px(x + 23, y + 11, 85)
	p.rr(x + 15, y + 3, 11, 5, OUT)
	p.r(x + 16, y + 4, 9, 3, 99)
	p.r(x + 16, y + 4, 9, 1, 100)
	p.disc(x + 7, y + 20, 3, OUT)
	p.disc(x + 7, y + 20, 2, 100)
	p.disc(x + 23, y + 20, 3, OUT)
	p.disc(x + 23, y + 20, 2, 100)
	p.r(x, y + 10, 2, 8, OUT)
	# Canopy.
	p.r(x + 2, y + 2, 1, 6, 99)
	p.r(x + 27, y + 2, 1, 6, 99)
	for sx in range(0, 30, 5):
		p.r(x + sx, y - 3, 5, 5, 87 if (sx / 5) % 2 == 0 else 102)
		p.r(x + sx + 1, y + 2, 3, 1, 87 if (sx / 5) % 2 == 0 else 102)
	p.r(x, y - 4, 30, 1, OUT)

static func _bench(p: Pen, x: int, y: int, w: int) -> void:
	p.shade(x, y + 8, w + 4, 6, 0.55)
	p.r(x, y, w, 2, 70)
	p.r(x, y, w, 1, 71)
	p.r(x, y + 2, w, 3, 69)
	p.r(x, y + 4, w, 1, 68)
	p.r(x, y + 6, w, 2, 11)
	p.r(x, y + 6, w, 1, 12)
	p.r(x + 1, y + 8, 2, 4, OUT)
	p.r(x + w - 3, y + 8, 2, 4, OUT)
	p.r(x - 1, y - 1, 1, 8, OUT)
	p.r(x + w, y - 1, 1, 8, OUT)

static func _bin(p: Pen, x: int, y: int, color: int, light: int) -> void:
	p.shade(x - 1, y + 8, 12, 5, 0.5)
	p.rr(x, y, 9, 12, OUT)
	p.r(x + 1, y + 1, 7, 10, color)
	p.r(x + 1, y + 1, 1, 10, light)
	p.r(x + 6, y + 1, 2, 10, 4 if color == 100 else 74)
	p.r(x - 1, y - 1, 11, 2, light)
	p.r(x - 1, y - 1, 11, 1, 102)
	p.px(x + 4, y + 5, 102)

static func _bike_rack(p: Pen, x: int, y: int, bike_color: int) -> void:
	p.shade(x - 2, y + 8, 30, 5, 0.5)
	for i in range(3):
		var rx := x + 2 + i * 8
		p.r(rx, y, 1, 10, 99)
		p.r(rx + 1, y, 3, 1, 99)
		p.r(rx + 4, y, 1, 10, 99)
	p.r(x, y + 10, 26, 1, OUT)
	# A parked bicycle with a basket.
	for wx in [x + 7, x + 17]:
		p.disc(wx, y + 6, 4, OUT)
		p.disc(wx, y + 6, 3, 66)
		p.disc(wx, y + 6, 1, 100)
	p.r(x + 7, y + 2, 11, 1, bike_color)
	p.r(x + 10, y + 2, 1, 5, bike_color)
	p.r(x + 15, y + 2, 2, 5, bike_color)
	p.r(x + 17, y, 3, 2, 100)
	p.rr(x + 18, y - 3, 6, 4, 11)
	p.px(x + 20, y - 4, 85)
	p.px(x + 22, y - 4, 89)

static func _hydrant(p: Pen, x: int, y: int) -> void:
	p.r(x, y + 8, 6, 2, OUT)
	p.r(x + 1, y + 2, 4, 7, 112)
	p.r(x + 1, y + 2, 1, 7, 26)
	p.r(x, y + 1, 6, 2, 112)
	p.r(x + 1, y, 4, 1, 26)
	p.r(x - 1, y + 4, 8, 2, 112)
	p.px(x + 3, y + 5, 89)

static func _planter_pot(p: Pen, x: int, y: int, seed_value: int) -> void:
	# A round planter with a small bush and flowers; (x, y) is the top-left of a 12x16 footprint.
	p.shade(x - 1, y + 11, 14, 5, 0.5)
	p.ellipse(x + 6, y + 4, 6, 5, 74)
	p.ellipse(x + 5, y + 3, 4, 3, 75)
	for i in range(5):
		p.px(x + 2 + i * 2, y + 2 + (i * 3 + seed_value) % 5, FLOWERS[(i + seed_value) % FLOWERS.size()])
	p.px(x + 4, y + 1, 77)
	Cozy.pot(p, x + 2, y + 8, 9, 6, 69, 70)

static func _lamp_post(p: Pen, x: int, day: int, crisis: int, glows: Array) -> void:
	p.r(x - 1, 196, 4, 2, OUT)
	p.r(x, 198, 2, 60, 99)
	p.r(x, 198, 1, 60, 100)
	p.rr(x - 2, 256, 6, 5, OUT)
	p.r(x - 1, 257, 4, 3, 99)
	p.r(x - 5, 193, 10, 4, OUT)
	p.r(x - 4, 194, 8, 2, 100)
	p.r(x - 6, 188, 12, 6, OUT)
	p.r(x - 5, 189, 10, 4, 97 if crisis == 0 else 96)
	p.r(x - 5, 189, 10, 1, 95)
	p.r(x - 3, 190, 2, 2, 102)
	glows.append(Vector2i(x, 192))
	# A hanging pennant banner on the post.
	p.r(x + 2, 202, 1, 2, OUT)
	p.r(x + 3, 203, 7, 14, 87 if crisis == 0 else 99)
	p.r(x + 3, 203, 7, 1, 85 if crisis == 0 else 100)
	p.r(x + 3, 217, 3, 2, 87 if crisis == 0 else 99)
	p.r(x + 7, 217, 3, 1, 87 if crisis == 0 else 99)
	p.r(x + 5, 207, 3, 3, 102)
	p.px(x + 6, 208, 87)

static func _string_lights(p: Pen, x1: int, x2: int, y: int, sag: int, seed_value: int, bulbs: Array) -> void:
	var span := x2 - x1
	for i in range(span + 1):
		var t := float(i) / float(span)
		p.px(x1 + i, y + int(sin(t * PI) * sag), SHADOW)
	var count := maxi(3, span / 11)
	for i in range(count + 1):
		var t := float(i) / float(count)
		var bx := x1 + int(t * span)
		var by := y + int(sin(t * PI) * sag) + 1
		var color: int = [89, 85, 91, 97, 93][(i + seed_value) % 5]
		p.r(bx, by, 1, 1, SHADOW)
		p.r(bx, by + 1, 2, 2, color)
		p.px(bx, by + 1, 102)
		bulbs.append(Vector3(bx, by + 1, color))

static func _bunting(p: Pen, x1: int, x2: int, y: int, sag: int, crisis: int) -> void:
	var span := x2 - x1
	for i in range(span + 1):
		var t := float(i) / float(span)
		p.px(x1 + i, y + int(sin(t * PI) * sag), SHADOW)
	var colors: Array = [85, 89, 91, 93, 97, 87] if crisis == 0 else [99, 100, 101, 6, 40]
	var count := span / 8
	for i in range(1, count):
		var t := float(i) / float(count)
		var fx := x1 + int(t * span) - 2
		var fy := y + int(sin(t * PI) * sag) + 1
		var color: int = colors[i % colors.size()]
		p.r(fx, fy, 5, 2, color)
		p.r(fx + 1, fy + 2, 3, 2, color)
		p.px(fx + 2, fy + 4, color)
		p.px(fx, fy, 102 if crisis == 0 else 101)

static func _tower(p: Pen, day: int, crisis: int, signs: Array) -> void:
	var x := 504
	var w := 136
	var top := 36
	var tone := [84, 94, 79] if crisis == 0 else ([5, 7, 4] if crisis == 1 else [4, 6, 3])
	p.r(x, top, w, SIDEWALK_Y - top, tone[0])
	p.r(x, top, 2, SIDEWALK_Y - top, tone[1])
	p.r(x + w - 4, top, 4, SIDEWALK_Y - top, tone[2])
	p.r(x - 1, top - 8, 1, SIDEWALK_Y - top + 8, OUT)
	# Glass grid with a sky reflection gradient and a few lit offices.
	for gy in range(top + 24, SIDEWALK_Y - 52, 12):
		for gx in range(x + 8, x + w - 10, 14):
			var on := ((gx / 14 + gy / 12 + day) % 5) < 2
			var glass := 94 if crisis == 0 else 6
			if gy > 120 and crisis == 0:
				glass = 34
			p.r(gx, gy, 12, 10, 96 if (on and crisis >= 1) else (95 if (on and gy > 100) else glass))
			p.r(gx, gy, 12, 2, 35 if crisis == 0 else 7)
			p.r(gx, gy + 9, 12, 1, 84 if crisis == 0 else 4)
			p.px(gx + 2, gy + 3, 102)
			p.px(gx + 3, gy + 4, 102)
		p.r(x + 4, gy + 10, w - 8, 2, tone[2])
	p.rr(x + 4, top - 8, w - 8, 8, OUT)
	p.r(x + 5, top - 7, w - 10, 7, tone[1])
	p.r(x + 12, top - 14, w - 24, 6, tone[0])
	p.r(x + w / 2 - 1, top - 30, 2, 16, 99)
	p.px(x + w / 2 - 1, top - 31, 112)
	# Sign plate on the tower.
	p.rr(x + 12, top + 5, w - 24, 16, OUT)
	p.r(x + 13, top + 6, w - 26, 14, 103)
	p.r(x + 13, top + 6, w - 26, 1, 99)
	p.glow(x + w / 2, top + 13, 40, 0.8, 0.4)
	var name := "LUC CHAU DATA CORP"
	signs.append({"text": name, "x": x + 14 + (w - 28 - Pen.text_width(name, 8)) / 2, "y": top + 9, "ink": 95, "size": 8})
	# Entrance: canopy, glass doors with warm light, planters with bushes.
	p.rr(x + 34, SIDEWALK_Y - 54, 66, 8, OUT)
	p.r(x + 35, SIDEWALK_Y - 53, 64, 6, 102)
	p.r(x + 35, SIDEWALK_Y - 53, 64, 1, 64)
	for sx in range(x + 35, x + 99, 8):
		p.r(sx, SIDEWALK_Y - 52, 4, 5, 94)
	p.rr(x + 38, SIDEWALK_Y - 46, 58, 46, OUT)
	p.r(x + 39, SIDEWALK_Y - 45, 56, 45, 99)
	p.r(x + 42, SIDEWALK_Y - 42, 22, 42, 96)
	p.r(x + 68, SIDEWALK_Y - 42, 22, 42, 96)
	p.r(x + 42, SIDEWALK_Y - 42, 22, 4, 35)
	p.r(x + 68, SIDEWALK_Y - 42, 22, 4, 35)
	p.r(x + 42, SIDEWALK_Y - 24, 22, 24, 95)
	p.r(x + 68, SIDEWALK_Y - 24, 22, 24, 95)
	p.r(x + 62, SIDEWALK_Y - 22, 2, 5, 71)
	p.r(x + 68, SIDEWALK_Y - 22, 2, 5, 71)
	p.glow(x + 66, SIDEWALK_Y - 22, 26, 0.9, 1.0)
	for px_ in [x + 12, x + 108]:
		p.shade(px_ - 2, SIDEWALK_Y - 6, 22, 8, 0.5)
		Cozy.pot(p, px_, SIDEWALK_Y - 14, 14, 14, 69, 70)
		p.ellipse(px_ + 7, SIDEWALK_Y - 21, 8, 7, 74)
		p.ellipse(px_ + 5, SIDEWALK_Y - 23, 5, 4, 75)
		p.px(px_ + 3, SIDEWALK_Y - 25, 77)
		p.px(px_ + 9, SIDEWALK_Y - 22, 85)
		p.px(px_ + 11, SIDEWALK_Y - 20, 89)

static func _build_street(p: Pen, day: int, crisis: int, names: Array, headlines: Array, signs: Array, bulbs: Array, puddles: Array) -> void:
	var glows: Array = []
	# Back sidewalk and curb.
	_paving(p, SIDEWALK_Y, 262, 101, 61, 102, 100, 3)
	p.r(0, 262, W, 1, 102)
	p.r(0, 263, W, 2, 100)
	p.r(0, 265, W, 1, SHADOW)
	_asphalt(p, day, crisis, puddles)
	# Shops, tower.
	for i in range(SHOPS.size()):
		_shop(p, SHOPS[i], i, day, crisis, str(names[i]), signs, bulbs, headlines)
	_tower(p, day, crisis, signs)
	# Warm shadow under the facades and light spilling from the shop windows onto the pavement.
	p.shade(0, SIDEWALK_Y, W, 8, 0.75)
	for spill in [[26, 244], [60, 244], [122, 244], [200, 244], [296, 244], [380, 244], [452, 244]]:
		var strength := 0.85 if crisis == 0 else 1.0
		p.glow(spill[0], spill[1], 30, strength, 0.38)
	# Street furniture.
	for x in [78, 166, 334, 418]:
		_lamp_post(p, x, day, crisis, glows)
	_string_lights(p, 80, 166, 197, 6, 0, bulbs)
	_string_lights(p, 168, 334, 192, 7, 2, bulbs)
	_string_lights(p, 336, 418, 197, 6, 1, bulbs)
	_bunting(p, 80, 164, 205, 5, crisis)
	_bunting(p, 338, 416, 205, 5, crisis)
	_food_cart(p, 124, 236)
	_bench(p, 296, 246, 26)
	_bin(p, 60, 246, 100, 101)
	_bin(p, 72, 246, 74, 75)
	_bin(p, 442, 246, 100, 101)
	_bike_rack(p, 472, 246, 87)
	_hydrant(p, 236, 249)
	for px_ in [86, 166, 252, 322, 424]:
		_planter_pot(p, px_, 244, px_ % 5)
	# Fallen leaves on the pavement.
	for i in range(34):
		var lx := (i * 71 + day * 9) % 500
		var ly := 249 + (i * 29) % 12
		var color: int = [97, 98, 70, 69, 89][i % 5] if crisis < 2 else [68, 69, 99, 67][i % 4]
		p.r(lx, ly, 2, 1, color)
		p.px(lx + 1, ly + 1, color)
	# Mood: golden morning light early on, cool grey-blue haze on crisis days.
	if crisis == 0 and day <= 4:
		for sx in [40, 190, 340, 470]:
			p.shaft(sx, 60, 28, 170, 70, 0.9)
		_warm_pass(p, 0, 0, W, 262, 0.15)
	elif crisis >= 1:
		p.shade(0, 0, W, 262, 0.26 if crisis == 1 else 0.38)
		p.shade(0, 262, W, 66, 0.16 if crisis == 1 else 0.26)

static func _warm_pass(p: Pen, x: int, y: int, w: int, h: int, density: float) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var threshold := float(Pen.BAYER[(yy & 3) * 4 + (xx & 3)]) / 16.0
			if density > threshold:
				p.tone_px(xx, yy, 1)

# ---- foreground (drawn over the traffic) ------------------------------------------------------

static func _tree(p: Pen, x: int, y: int, size: int, crisis: int, seed_value: int) -> void:
	# A dense tree: trunk with roots, then clusters of foliage blobs in four tones with light dots.
	p.shade(x - size, y - 1, size * 2 + 4, 8, 0.7)
	p.r(x - 2, y - 18, 4, 19, 109)
	p.r(x - 2, y - 18, 1, 19, 69)
	p.r(x + 1, y - 18, 1, 19, 108)
	p.r(x - 4, y - 2, 3, 3, 109)
	p.r(x + 1, y - 2, 4, 3, 108)
	var dark := 73 if crisis < 2 else 78
	var mid := 74 if crisis == 0 else 78
	var lite := 75 if crisis == 0 else 74
	var hi := 76 if crisis == 0 else 75
	var spec := 77 if crisis == 0 else 76
	var blobs := [[0, -26, size], [-9, -21, size - 3], [9, -21, size - 3], [-14, -14, size - 5], [14, -14, size - 5], [0, -16, size - 3]]
	for b in blobs:
		p.ellipse(x + b[0], y + b[1] + 2, b[2], b[2] - 1, dark)
	for b in blobs:
		p.ellipse(x + b[0] - 1, y + b[1], b[2] - 1, b[2] - 2, mid)
	for b in blobs:
		p.ellipse(x + b[0] - 3, y + b[1] - 2, maxi(2, b[2] - 5), maxi(2, b[2] - 6), lite)
	for b in blobs:
		p.ellipse(x + b[0] - 4, y + b[1] - 3, maxi(1, b[2] / 3), maxi(1, b[2] / 4), hi)
	for i in range(26):
		var lx := x - size - 8 + _h(i, seed_value) % (size * 2 + 14)
		var ly := y - 40 + _h(seed_value, i) % 34
		if p.index_at(lx + p.origin.x, ly + p.origin.y) == mid or p.index_at(lx + p.origin.x, ly + p.origin.y) == lite:
			p.px(lx, ly, spec if i % 3 == 0 else hi)
		elif p.index_at(lx + p.origin.x, ly + p.origin.y) == dark:
			p.px(lx, ly, mid)
	if crisis == 0:
		for i in range(5):
			p.px(x - 12 + _h(i, seed_value) % 24, y - 36 + _h(seed_value, i + 5) % 22, 85 if i % 2 == 0 else 89)

static func _build_front(p: Pen, day: int, crisis: int) -> void:
	# p has origin (0, -FRONT_Y): drawing uses absolute screen coordinates.
	var top := 328
	p.r(0, top, W, 2, 4)
	p.r(0, top + 2, W, 1, 102)
	p.r(0, top + 3, W, 2, 100)
	_paving(p, top + 5, H, 101, 61, 102, 100, 11)
	p.shade(0, top + 5, W, 6, 0.55)
	for tx in [36, 150, 300, 446, 590]:
		_tree(p, tx, 349, 14, crisis, tx)
	for lx in [96, 360, 520]:
		p.r(lx - 1, 322, 4, 2, OUT)
		p.r(lx, 324, 2, 34, 99)
		p.r(lx, 324, 1, 34, 100)
		p.rr(lx - 6, 316, 12, 8, OUT)
		p.r(lx - 5, 317, 10, 6, 97 if crisis == 0 else 96)
		p.r(lx - 5, 317, 10, 1, 95)
		p.px(lx - 3, 318, 102)
		p.glow(lx, 320, 22, 0.9, 0.8)
	_bench(p, 214, 338, 26)
	_bike_rack(p, 392, 340, 94)
	_bin(p, 560, 340, 100, 101)
	for px_ in [100, 240, 380, 500]:
		_planter_pot(p, px_, 340, px_ % 7)
	for i in range(40):
		var lx := (i * 59 + day * 7) % W
		var ly := 336 + (i * 31) % 22
		var color: int = [97, 98, 70, 69, 89][i % 5] if crisis < 2 else [68, 69, 99, 67][i % 4]
		p.r(lx, ly, 2, 1, color)
		p.px(lx + 1, ly + 1, color)
	if crisis >= 1:
		p.shade(0, top, W, H - top, 0.2)

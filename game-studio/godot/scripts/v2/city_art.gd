extends RefCounted
# Procedural cozy city backdrops (palette v4) for the desktop wallpaper, title, review and ending screens.
const Pen = preload("res://scripts/v2/pen.gd")
const Cozy = preload("res://scripts/v2/cozy.gd")
const SKIES := {
	"dusk": [83, 79, 79, 80, 80, 81, 93, 85, 85, 92, 97],
	"dawn": [94, 94, 35, 35, 86, 86, 92, 89, 95],
	"night": [111, 83, 83, 79, 79, 84, 80],
	"gloom": [3, 99, 99, 100, 100, 101]}

static var cache := {}

static func backdrop(variety: String) -> ImageTexture:
	if cache.has(variety):
		return cache[variety]
	var tex := _build(variety)
	cache[variety] = tex
	return tex

static func _sky(p: Pen, bands: Array, height: int) -> void:
	var count := bands.size()
	var band_height := float(height) / float(count)
	for y in range(height):
		var position := float(y) / band_height
		var index := mini(int(position), count - 1)
		var fraction := position - float(index)
		if fraction > 0.6 and index + 1 < count:
			for x in range(640):
				var threshold := float(Pen.BAYER[(y & 3) * 4 + (x & 3)]) / 16.0
				p.r(x, y, 1, 1, bands[index + 1] if (fraction - 0.6) / 0.4 > threshold else bands[index])
		else:
			p.r(0, y, 640, 1, bands[index])

static func _cloud(p: Pen, x: int, y: int, w: int, light: int, shade: int) -> void:
	p.ellipse(x + w / 2, y + 4, w / 2, 4, shade)
	p.ellipse(x + w / 3, y + 2, w / 4, 4, light)
	p.ellipse(x + w * 2 / 3, y + 3, w / 4, 3, light)
	p.r(x + 4, y + 6, w - 8, 1, shade)

static func _layer(p: Pen, seed_value: int, baseline: int, min_h: int, max_h: int, colors: Array, lit: Array, lit_chance: float) -> void:
	var local := RandomNumberGenerator.new()
	local.seed = seed_value
	var x := -4
	while x < 640:
		var bw := local.randi_range(20, 44)
		var bh := local.randi_range(min_h, max_h)
		var top := baseline - bh
		p.r(x, top, bw, bh, colors[0])
		p.r(x, top, bw, 2, colors[1])
		p.r(x, top, 1, bh, colors[1])
		p.r(x + bw - 3, top + 2, 3, bh - 2, colors[2])
		var variant := local.randi_range(0, 3)
		if variant == 0:
			p.r(x + bw / 2, top - 8, 1, 8, colors[2])
			p.px(x + bw / 2, top - 9, 87)
		elif variant == 1:
			p.r(x + 4, top - 5, 8, 5, colors[2])
			p.r(x + 3, top - 6, 10, 1, colors[1])
		elif variant == 2:
			p.r(x + 2, top - 2, bw - 4, 2, colors[1])
		for wy in range(top + 5, baseline - 4, 6):
			for wx in range(x + 4, x + bw - 6, 6):
				if local.randf() < lit_chance:
					var color: int = lit[local.randi_range(0, lit.size() - 1)]
					p.r(wx, wy, 3, 3, color)
					p.px(wx, wy, 72)
		x += bw + local.randi_range(0, 3)

static func _tree(p: Pen, x: int, y: int, size: int) -> void:
	p.r(x - 1, y, 3, size, 109)
	p.ellipse(x, y - size / 2, size, size, 73)
	p.ellipse(x - 1, y - size / 2 - 1, size - 2, size - 2, 74)
	p.ellipse(x - 2, y - size / 2 - 2, size / 2, size / 2, 75)
	p.px(x - 3, y - size / 2 - 3, 77)

static func _build(variety: String) -> ImageTexture:
	var image := Pen.canvas(640, 360)
	var p := Pen.new(image)
	var sky_key := "dusk"
	match variety:
		"ending_good":
			sky_key = "dawn"
		"ending_bad":
			sky_key = "night"
	_sky(p, SKIES[sky_key], 300)
	p.r(0, 300, 640, 60, 83)
	if sky_key in ["dusk", "night"]:
		for i in range(46):
			p.px((i * 97 + 13) % 640, (i * 41 + 5) % 110, 102 if i % 3 == 0 else 101)
	var cloud_light := 86 if sky_key != "night" else 80
	var cloud_shade := 85 if sky_key != "night" else 79
	for c in [[40, 70, 90], [210, 40, 70], [380, 96, 100], [520, 60, 80]]:
		_cloud(p, c[0], c[1], c[2], cloud_light, cloud_shade)
	if sky_key == "dawn":
		p.disc(120, 210, 30, 96)
		p.disc(120, 210, 22, 89)
		p.glow(120, 210, 70, 0.9)
	else:
		p.disc(540, 56, 12, 72)
		p.disc(545, 54, 10, SKIES[sky_key][2])
		p.glow(540, 56, 40, 0.8)
	var far := [80, 81, 79]
	var mid := [79, 84, 83]
	var near := [83, 79, 111]
	if sky_key == "dawn":
		far = [93, 82, 81]
		mid = [81, 80, 79]
		near = [79, 84, 83]
	_layer(p, 11, 250, 60, 150, far, [95, 96], 0.1)
	_layer(p, 23, 275, 50, 120, mid, [96, 89, 95, 85], 0.3)
	_layer(p, 37, 300, 40, 100, near, [96, 89, 95, 91, 85], 0.4)
	if variety == "title":
		var x := 470
		var top := 60
		p.rr(x, top, 110, 245, 65)
		p.r(x + 1, top + 1, 108, 243, 84)
		p.r(x + 1, top + 1, 2, 243, 94)
		p.r(x + 6, top - 12, 98, 12, 84)
		p.r(x + 16, top - 22, 78, 10, 80)
		p.r(x + 54, top - 46, 3, 24, 100)
		p.px(x + 55, top - 47, 87)
		p.glow(x + 55, top - 47, 20, 1.0)
		p.r(x + 6, top + 10, 98, 12, 83)
		for gy in range(top + 30, 290, 12):
			for gx in range(x + 8, x + 100, 14):
				var on := ((gx / 14) * 3 + (gy / 12) * 5) % 7 < 4
				p.r(gx, gy, 10, 8, 96 if on else 79)
				p.r(gx, gy, 10, 1, 72 if on else 80)
		p.rr(x + 36, 262, 38, 43, 65)
		p.r(x + 40, 266, 14, 39, 97)
		p.r(x + 56, 266, 14, 39, 96)
	Cozy.planks(p, 0, 300, 640, 60, 4, 5, 3, 83, 10)
	p.r(0, 300, 640, 4, 99)
	p.r(0, 304, 640, 2, 66)
	for x in range(0, 640, 36):
		p.r(x, 336, 20, 2, 89)
	for tx in [30, 150, 290, 420, 610]:
		_tree(p, tx, 304, 8)
	for lx in [90, 230, 370, 520]:
		p.r(lx, 276, 2, 28, 66)
		p.r(lx - 3, 273, 8, 4, 97)
		p.r(lx - 2, 273, 6, 2, 95)
		p.glow(lx + 1, 280, 26, 1.0, 0.9)
	return Pen.texture(image)

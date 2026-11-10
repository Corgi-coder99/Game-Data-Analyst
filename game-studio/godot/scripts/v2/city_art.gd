extends RefCounted
# Procedural city backdrops (palette v3) for the desktop wallpaper, title, review and ending screens.
const Pen = preload("res://scripts/v2/pen.gd")
const SKIES := {
	"dusk": [39, 39, 29, 38, 38, 37, 37, 36, 36, 45],
	"dawn": [33, 33, 34, 34, 35, 36, 45, 28],
	"night": [1, 1, 2, 2, 39, 3, 4],
	"gloom": [2, 2, 3, 3, 4, 4, 5]}

static var cache := {}

static func backdrop(kind: String) -> ImageTexture:
	if cache.has(kind):
		return cache[kind]
	var tex := _build(kind)
	cache[kind] = tex
	return tex

static func _sky(p: Pen, bands: Array, height: int) -> void:
	var count := bands.size()
	var band_height := float(height) / float(count)
	for y in range(height):
		var position := float(y) / band_height
		var index := mini(int(position), count - 1)
		var fraction := position - float(index)
		if fraction > 0.7 and index + 1 < count:
			for x in range(640):
				var next := ((x + y) % 2 == 0) if fraction > 0.85 else (x % 2 == 0 and y % 2 == 0)
				p.r(x, y, 1, 1, bands[index + 1] if next else bands[index])
		else:
			p.r(0, y, 640, 1, bands[index])

static func _layer(p: Pen, seed_value: int, baseline: int, min_h: int, max_h: int, colors: Array, lit: int, lit_chance: float) -> void:
	var local := RandomNumberGenerator.new()
	local.seed = seed_value
	var x := -4
	while x < 640:
		var bw := local.randi_range(20, 44)
		var bh := local.randi_range(min_h, max_h)
		var top := baseline - bh
		p.box(x, top, bw, bh, colors[0], colors[1], colors[2])
		if local.randf() < 0.3:
			p.r(x + bw / 2, top - 8, 1, 8, colors[2])
		for wy in range(top + 5, baseline - 4, 6):
			for wx in range(x + 4, x + bw - 4, 6):
				if local.randf() < lit_chance:
					p.r(wx, wy, 3, 3, lit)
		x += bw + local.randi_range(0, 3)

static func _build(kind: String) -> ImageTexture:
	var image := Pen.canvas(640, 360)
	var p := Pen.new(image)
	var sky_key := "dusk"
	match kind:
		"ending_good":
			sky_key = "dawn"
		"ending_bad":
			sky_key = "night"
		"review":
			sky_key = "dusk"
	_sky(p, SKIES[sky_key], 300)
	p.r(0, 300, 640, 60, 1)
	# Stars on dark skies.
	if sky_key in ["dusk", "night"]:
		for i in range(40):
			p.px((i * 97 + 13) % 640, (i * 41 + 5) % 100, 7 if i % 3 == 0 else 6)
	if sky_key == "dawn":
		p.disc(120, 210, 30, 36)
		p.disc(120, 210, 22, 52)
	else:
		p.disc(540, 56, 12, 64)
		p.disc(544, 54, 10, SKIES[sky_key][2])
	var far := [29, 38, 39]
	var mid := [39, 29, 2]
	var near := [2, 3, 1]
	if sky_key == "dawn":
		far = [40, 41, 5]
		mid = [18, 19, 17]
		near = [17, 18, 1]
	_layer(p, 11, 250, 60, 150, far, 36, 0.08)
	_layer(p, 23, 275, 50, 120, mid, 52, 0.25)
	_layer(p, 37, 300, 40, 100, near, 52, 0.3)
	if kind == "title":
		# The company tower, with a glowing crown.
		var x := 470
		var top := 60
		p.box(x, top, 110, 245, 18, 19, 17)
		p.r(x + 6, top - 12, 98, 12, 19)
		p.r(x + 16, top - 22, 78, 10, 18)
		p.r(x + 54, top - 46, 3, 24, 6)
		p.px(x + 55, top - 47, 51)
		p.r(x + 6, top + 10, 98, 12, 1)
		for gy in range(top + 30, 290, 12):
			for gx in range(x + 8, x + 100, 14):
				var on := ((gx / 14) * 3 + (gy / 12) * 5) % 7 < 3
				p.r(gx, gy, 10, 8, 52 if on else 20)
				p.r(gx, gy, 10, 1, 64 if on else 21)
		p.box(x + 36, 262, 38, 43, 5, 6, 4)
		p.r(x + 40, 266, 14, 39, 34)
		p.r(x + 56, 266, 14, 39, 34)
	# Street at the bottom.
	p.r(0, 300, 640, 60, 62)
	p.r(0, 300, 640, 3, 63)
	for x in range(0, 640, 36):
		p.r(x, 330, 20, 2, 52)
	return Pen.texture(image)

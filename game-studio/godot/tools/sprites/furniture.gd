extends RefCounted
# T-028 cozy furniture sprites, drawn in code with palette v4 indices and converted to palette-letter rows.
# Sizes and frame counts are unchanged from T-022.
const Kit = preload("res://tools/sprites/kit.gd")
const Pen = preload("res://scripts/v2/pen.gd")

static func _leaf(p: Pen, x: int, y: int, size: int, dark: int, mid: int, light: int, lean: int = 0) -> void:
	# A rounded leaf cluster: dark base disc, mid body, light top-left highlight.
	p.ellipse(x, y, size, maxi(2, size - 1), dark)
	p.ellipse(x - 1 + lean, y - 1, size - 1, maxi(1, size - 2), mid)
	p.r(x - size + 2 + lean, y - 2, maxi(1, size - 2), 1, light)
	p.px(x - 1 + lean, y - 3, light)

static func desk(frame_index: int) -> Array:
	return Kit.paint(48, 24, func(p: Pen):
		# Under-desk shadow and legs / drawer pedestal.
		p.r(2, 19, 43, 5, 66)
		p.r(3, 18, 9, 6, 68)
		p.r(3, 18, 9, 1, 69)
		p.r(3, 18, 1, 6, 65)
		p.r(11, 18, 1, 6, 65)
		p.r(5, 20, 5, 1, 71)
		p.r(5, 21, 5, 2, 67)
		p.r(39, 18, 5, 6, 68)
		p.r(39, 18, 1, 6, 65)
		p.r(43, 18, 1, 6, 65)
		p.r(3, 23, 9, 1, 65)
		p.r(39, 23, 5, 1, 65)
		# Desk top: highlight edge, warm board with grain, shadowed front.
		p.r(1, 13, 44, 1, 72)
		p.r(1, 14, 44, 3, 70)
		p.r(1, 17, 44, 2, 69)
		p.r(1, 19, 44, 1, 107)
		for gx in range(4, 44, 7):
			p.r(gx, 15, 3, 1, 71)
			p.r(gx + 3, 16, 2, 1, 69)
		p.r(0, 14, 1, 5, 65)
		p.r(45, 14, 1, 5, 65)
		p.r(1, 12, 44, 1, 65)
		# Monitor: dark bezel, glossy screen, stand.
		p.rr(15, 0, 19, 12, 103, 65)
		p.r(16, 1, 17, 9, 83)
		if frame_index == 0:
			p.r(17, 2, 15, 7, 84)
			p.r(18, 3, 6, 2, 94)
			p.r(25, 3, 6, 1, 85)
			p.r(25, 5, 4, 1, 89)
			for i in range(5):
				p.r(18 + i * 3, 8 - i % 3 - 1, 2, 1 + i % 3, 91)
		else:
			p.r(17, 2, 15, 7, 79)
			p.r(18, 3, 13, 1, 81)
			p.r(18, 5, 8, 1, 82)
			p.r(18, 7, 10, 1, 85)
			p.r(28, 5, 3, 3, 89)
		p.r(17, 1, 4, 1, 82)
		p.r(22, 10, 5, 1, 66)
		p.r(21, 11, 7, 1, 65)
		# Keyboard.
		p.r(17, 12, 15, 1, 101)
		p.r(18, 12, 13, 1, 100)
		# Mug with a pink band, steam dot.
		p.r(3, 8, 5, 5, 102)
		p.r(3, 10, 5, 1, 85)
		p.r(8, 9, 2, 3, 102)
		p.px(9, 10, 65)
		p.r(3, 8, 5, 1, 72)
		p.r(3, 12, 5, 1, 65)
		p.px(5, 6, 101)
		p.px(6, 5, 101)
		# Sticky notes and a pencil cup.
		p.r(11, 10, 4, 3, 89)
		p.r(11, 10, 4, 1, 72)
		p.r(13, 9, 3, 3, 86)
		p.r(13, 9, 3, 1, 102)
		# Little potted plant on the right.
		p.r(38, 9, 5, 4, 69)
		p.r(38, 9, 5, 1, 70)
		p.r(38, 12, 5, 1, 67)
		p.ellipse(40, 6, 3, 3, 74)
		p.ellipse(39, 5, 2, 2, 75)
		p.px(38, 4, 77)
		p.px(42, 7, 76)
		p.px(44, 10, 87)
		p.r(44, 10, 1, 2, 87)
		p.px(44, 9, 85))

static func chair() -> Array:
	return Kit.paint(16, 24, func(p: Pen):
		# Rounded rose cushion chair seen from behind, with a light star base.
		p.rr(2, 2, 12, 13, 87, 65)
		p.rr(3, 3, 10, 11, 85, 0)
		p.r(3, 3, 5, 1, 86)
		p.r(3, 4, 1, 4, 86)
		p.r(10, 4, 3, 10, 87)
		p.r(3, 12, 10, 2, 87)
		p.r(5, 8, 6, 1, 87)
		p.rr(1, 15, 14, 4, 88, 65)
		p.r(2, 15, 12, 1, 87)
		p.r(7, 19, 2, 3, 100)
		p.r(7, 19, 1, 3, 101)
		p.r(3, 22, 10, 1, 99)
		p.r(2, 22, 1, 1, 65)
		p.r(13, 22, 1, 1, 65)
		p.r(5, 23, 6, 1, 65))

static func plant_frame(sway: int) -> Array:
	return Kit.paint(16, 24, func(p: Pen):
		# Terracotta pot with a rim and shadow side.
		p.r(3, 17, 10, 6, 69)
		p.r(2, 16, 12, 2, 70)
		p.r(2, 16, 12, 1, 71)
		p.r(11, 18, 2, 5, 68)
		p.r(3, 22, 10, 1, 67)
		p.r(2, 18, 1, 1, 65)
		p.r(4, 19, 2, 2, 70)
		p.r(3, 23, 10, 1, 65)
		# Stems and big monstera-like leaves.
		p.r(8, 10, 1, 7, 74)
		p.r(5, 12, 1, 5, 74)
		p.r(11, 11, 1, 6, 74)
		_leaf(p, 8 + sway, 6, 4, 73, 75, 77, sway)
		_leaf(p, 4 + sway, 10, 3, 73, 74, 76, sway)
		_leaf(p, 12 + sway, 9, 3, 73, 75, 76, sway)
		_leaf(p, 8, 11, 2, 73, 74, 75)
		p.px(8 + sway, 5, 73)
		p.px(7, 7, 73)
		p.px(12, 8, 73)
		p.px(4, 9, 73))

static func cabinet() -> Array:
	return Kit.paint(24, 32, func(p: Pen):
		# Wooden storage cabinet with books on top, drawers with brass handles.
		p.r(1, 10, 22, 21, 68)
		p.r(0, 9, 24, 3, 70)
		p.r(0, 9, 24, 1, 72)
		p.r(0, 9, 1, 22, 65)
		p.r(23, 9, 1, 22, 65)
		p.r(0, 31, 24, 1, 65)
		p.r(0, 8, 24, 1, 65)
		for i in range(3):
			var y := 13 + i * 6
			p.r(2, y, 20, 5, 69)
			p.r(2, y, 20, 1, 70)
			p.r(2, y + 5, 20, 1, 66)
			p.r(10, y + 2, 4, 1, 96)
			p.r(10, y + 2, 1, 1, 72)
			p.px(4, y + 2, 107)
		p.r(21, 12, 2, 18, 67)
		# Books and a small succulent on top.
		p.r(2, 2, 3, 6, 87)
		p.r(5, 1, 3, 7, 94)
		p.r(8, 3, 3, 5, 89)
		p.r(11, 2, 2, 6, 91)
		p.r(2, 2, 1, 6, 85)
		p.r(5, 1, 1, 7, 82)
		p.r(8, 3, 1, 5, 72)
		p.r(16, 4, 5, 4, 69)
		p.r(16, 4, 5, 1, 70)
		p.ellipse(18, 3, 2, 2, 75)
		p.px(17, 2, 77)
		p.px(19, 1, 76)
		p.r(2, 8, 11, 1, 65))

static func clock() -> Array:
	return Kit.paint(16, 16, func(p: Pen):
		p.disc(8, 8, 7, 65)
		p.disc(8, 8, 6, 71)
		p.disc(8, 8, 5, 102)
		p.r(3, 4, 2, 1, 72)
		p.r(7, 3, 2, 1, 69)
		p.r(7, 12, 2, 1, 69)
		p.r(3, 7, 1, 2, 69)
		p.r(12, 7, 1, 2, 69)
		p.r(5, 10, 6, 1, 101)
		p.r(12, 3, 1, 1, 72))

static func door(open: bool) -> Array:
	return Kit.paint(24, 40, func(p: Pen):
		p.r(0, 0, 24, 40, 65)
		p.r(1, 1, 22, 39, 70)
		p.r(1, 1, 22, 1, 72)
		p.r(1, 1, 1, 39, 71)
		if not open:
			p.r(3, 3, 18, 34, 69)
			p.r(3, 3, 18, 1, 71)
			p.r(3, 3, 1, 34, 70)
			p.r(20, 3, 1, 34, 68)
			p.r(3, 36, 18, 1, 68)
			# Frosted glass pane with a warm glow and a floral sticker.
			p.r(6, 6, 12, 10, 65)
			p.r(7, 7, 10, 8, 95)
			p.r(7, 7, 10, 3, 72)
			p.r(8, 12, 3, 2, 96)
			p.px(13, 9, 85)
			p.px(14, 10, 85)
			p.px(13, 10, 89)
			# Lower panels and a brass handle.
			p.r(6, 20, 12, 6, 68)
			p.r(6, 20, 12, 1, 67)
			p.r(6, 28, 12, 6, 68)
			p.r(6, 28, 12, 1, 67)
			p.r(6, 25, 12, 1, 70)
			p.r(6, 33, 12, 1, 70)
			p.r(17, 18, 2, 3, 96)
			p.r(17, 18, 1, 1, 72)
			p.r(18, 38, 4, 1, 66)
		else:
			p.r(3, 3, 18, 34, 66)
			p.r(4, 4, 16, 33, 95)
			p.r(4, 4, 16, 8, 72)
			for gy in range(12, 36, 4):
				p.dither_rect(4, gy, 16, 4, 95, 96, 0.35 + float(gy - 12) / 40.0)
			p.r(3, 3, 3, 34, 70)
			p.r(3, 3, 3, 1, 72)
			p.r(4, 6, 1, 28, 71)
			p.r(6, 3, 1, 34, 69)
			p.r(18, 38, 4, 1, 66))

static func window(index: int) -> Array:
	return Kit.paint(32, 32, func(p: Pen):
		var sky: Array = [[34, 94, 35], [94, 35, 35], [97, 85, 93]][index]
		var far: int = [84, 100, 79][index]
		var near: int = [79, 99, 83][index]
		p.r(0, 0, 32, 32, 65)
		p.rr(1, 1, 30, 30, 69, 0)
		p.r(1, 1, 30, 1, 71)
		p.r(3, 3, 26, 22, 65)
		p.r(4, 4, 24, 7, sky[0])
		p.r(4, 11, 24, 7, sky[1])
		p.r(4, 18, 24, 7, sky[2])
		for i in range(0, 24, 4):
			var bh := 5 + (i * 5) % 9
			p.r(4 + i, 25 - bh, 4, bh, far if i % 8 == 0 else near)
			if index == 2:
				p.px(5 + i, 25 - bh + 2, 96)
		if index != 2:
			p.r(6, 6, 5, 1, 72)
			p.r(8, 5, 4, 1, 72)
		p.r(15, 3, 2, 22, 69)
		p.r(3, 14, 26, 2, 69)
		p.r(15, 3, 1, 22, 71)
		p.r(3, 14, 26, 1, 71)
		# Curtains and a sill with a plant.
		p.r(3, 3, 4, 21, 87)
		p.r(3, 3, 1, 21, 85)
		p.r(5, 6, 1, 17, 88)
		p.r(25, 3, 4, 21, 87)
		p.r(28, 3, 1, 21, 88)
		p.r(26, 6, 1, 17, 85)
		p.r(0, 25, 32, 3, 70)
		p.r(0, 25, 32, 1, 72)
		p.r(0, 28, 32, 2, 67)
		p.r(0, 30, 32, 2, 65)
		p.r(6, 22, 4, 3, 69)
		p.ellipse(8, 21, 2, 2, 75)
		p.px(7, 20, 77)
		p.r(21, 22, 3, 3, 102)
		p.px(22, 21, 85))

static func floor_tile() -> Array:
	return Kit.paint(16, 16, func(p: Pen):
		p.r(0, 0, 16, 16, 70)
		for row in range(2):
			var y := row * 8
			p.r(0, y, 16, 1, 107)
			p.r(0, y + 1, 16, 1, 71)
			p.r((row * 5 + 7) % 16, y + 2, 1, 6, 107)
			for g in range(3):
				p.r((g * 5 + row * 3) % 14, y + 3 + g % 3 * 2, 3, 1, 69)
				p.px((g * 7 + 4 + row * 2) % 15, y + 4, 72))

static func wall_tile() -> Array:
	return Kit.paint(16, 16, func(p: Pen):
		p.r(0, 0, 16, 16, 92)
		for x in range(0, 16, 4):
			p.r(x, 0, 1, 15, 104)
			p.px(x + 2, 4, 86)
			p.px(x + 2, 10, 86)
		p.r(0, 15, 16, 1, 107))

static func baseboard_tile() -> Array:
	return Kit.paint(16, 16, func(p: Pen):
		p.r(0, 0, 16, 16, 92)
		for x in range(0, 16, 4):
			p.r(x, 0, 1, 9, 104)
		p.r(0, 9, 16, 1, 72)
		p.r(0, 10, 16, 4, 102)
		p.r(0, 14, 16, 1, 101)
		p.r(0, 15, 16, 1, 100))

static var _cache: Dictionary = {}
static func definitions() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	_cache = {
		&"baseboard": {"frames": [baseboard_tile()], "size": Vector2i(16, 16)},
		&"cabinet": {"frames": [cabinet()], "size": Vector2i(24, 32)},
		&"chair": {"frames": [chair()], "size": Vector2i(16, 24)},
		&"clock": {"frames": [clock()], "size": Vector2i(16, 16)},
		&"desk": {"frames": [desk(0), desk(1)], "size": Vector2i(48, 24)},
		&"door": {"frames": [door(false), door(true)], "size": Vector2i(24, 40)},
		&"floor": {"frames": [floor_tile()], "size": Vector2i(16, 16)},
		&"plant": {"frames": [plant_frame(0), plant_frame(1)], "size": Vector2i(16, 24)},
		&"wall": {"frames": [wall_tile()], "size": Vector2i(16, 16)},
		&"window": {"frames": [window(0), window(1), window(2)], "size": Vector2i(32, 32)}}
	return _cache

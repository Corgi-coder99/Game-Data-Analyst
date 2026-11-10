extends RefCounted
# T-028: the cozy bedroom backdrop (308x360) used by the morning scene. Palette v4 only.
const Pen = preload("res://scripts/v2/pen.gd")
const Cozy = preload("res://scripts/v2/cozy.gd")

static func texture() -> ImageTexture:
	var image := Pen.canvas(308, 360)
	draw(Pen.new(image))
	return Pen.texture(image)

static func draw(p: Pen) -> void:
	var lights: Array = []
	# Wall: warm peach wallpaper with stripes, wainscot, baseboard.
	Cozy.wallpaper(p, 0, 0, 308, 232, 92, 104, 86)
	p.r(0, 0, 308, 5, 71)
	p.r(0, 5, 308, 1, 66)
	p.r(0, 190, 308, 40, 93)
	p.r(0, 190, 308, 2, 102)
	for x in range(6, 300, 24):
		p.r(x, 197, 18, 28, 82)
		p.r(x, 197, 18, 1, 102)
		p.r(x, 224, 18, 1, 81)
	p.r(0, 228, 308, 6, 67)
	p.r(0, 228, 308, 1, 71)
	# Floor: honey planks.
	Cozy.planks(p, 0, 234, 308, 126, 70, 71, 107, 68, 10)
	# Window with city view, curtains, plant on the sill.
	p.r(192, 34, 90, 82, 65)
	p.rr(193, 35, 88, 80, 69)
	p.r(193, 35, 88, 1, 71)
	p.r(198, 40, 78, 66, 83)
	for i in range(3):
		p.r(198, 40 + i * 12, 78, 12, [79, 80, 81][i])
	for i in range(0, 78, 6):
		var bh := 8 + (i * 7) % 18
		p.r(198 + i, 106 - bh, 6, bh, 84 if i % 12 == 0 else 83)
		for wy in range(106 - bh + 3, 104, 5):
			if (wy + i) % 3 == 0:
				p.r(200 + i, wy, 2, 2, 96)
	p.disc(256, 56, 7, 72)
	p.disc(259, 54, 6, 80)
	for sx in [210, 226, 242, 268]:
		p.px(sx, 46, 102)
	p.r(235, 40, 3, 66, 69)
	p.r(198, 72, 78, 3, 69)
	p.r(196, 38, 10, 70, 87)
	p.r(196, 38, 2, 70, 85)
	p.r(201, 44, 1, 58, 88)
	p.r(270, 38, 10, 70, 87)
	p.r(278, 38, 2, 70, 88)
	p.r(190, 112, 94, 5, 70)
	p.r(190, 112, 94, 1, 72)
	p.r(190, 117, 94, 3, 67)
	Cozy.plant_small(p, 200, 100, 1)
	p.shaft(196, 126, 70, 90, -40, 0.7)
	lights.append(Vector2i(236, 74))
	# String lights over the window and bed.
	var glows: Array = []
	Cozy.string_lights(p, 4, 180, 10, 10, 1, glows)
	for g in glows:
		lights.append(g)
	# Pictures and a calendar.
	Cozy.picture(p, 24, 56, 28, 22, 0)
	Cozy.picture(p, 60, 48, 18, 26, 2)
	Cozy.poster(p, 100, 52, 26, 32, 3)
	p.r(140, 60, 24, 24, 102)
	p.frame(140, 60, 24, 24, 65)
	p.r(141, 61, 22, 5, 87)
	for yy in range(70, 82, 4):
		for xx in range(143, 160, 5):
			p.px(xx, yy, 99)
	# Plant shelf on the wall.
	p.r(100, 108, 70, 4, 70)
	p.r(100, 108, 70, 1, 72)
	p.r(104, 112, 2, 6, 67)
	p.r(164, 112, 2, 6, 67)
	Cozy.plant_small(p, 104, 94, 0)
	Cozy.books(p, 126, 108, 3, 2)
	Cozy.plant_small(p, 150, 94, 2)
	Cozy.hanging_plant(p, 70, 128, 10)
	# Bed: frame, pillows, patchwork quilt.
	Cozy.drop_shadow(p, 12, 190, 128, 22, 0.6)
	p.r(12, 166, 124, 18, 67)
	p.r(12, 166, 124, 2, 71)
	p.rr(12, 176, 126, 22, 65)
	p.r(14, 178, 122, 18, 86)
	p.r(14, 144, 14, 70, 68)
	p.r(14, 144, 14, 1, 71)
	p.rr(16, 140, 38, 18, 65)
	p.r(18, 142, 34, 14, 102)
	p.r(18, 142, 34, 3, 72)
	p.r(20, 152, 30, 2, 101)
	p.rr(56, 144, 34, 14, 65)
	p.r(58, 146, 30, 10, 94)
	p.r(58, 146, 30, 2, 35)
	p.rr(14, 156, 122, 40, 65)
	for yy in range(158, 194, 9):
		for xx in range(16, 134, 12):
			var c: int = [85, 89, 91, 93, 86, 90][((xx / 12) + (yy / 9) * 2) % 6]
			p.r(xx, yy, 11, 8, c)
			p.r(xx, yy, 11, 1, 102)
			p.px(xx + 5, yy + 4, 102)
	p.r(14, 192, 122, 4, 88)
	p.r(14, 156, 122, 2, 102)
	p.r(14, 196, 6, 16, 67)
	p.r(130, 196, 6, 16, 67)
	# Nightstand with the alarm clock and a lamp.
	Cozy.drop_shadow(p, 150, 190, 38, 30, 0.6)
	p.r(150, 176, 38, 40, 65)
	p.r(152, 178, 34, 36, 70)
	p.r(152, 178, 34, 2, 72)
	p.r(152, 197, 34, 2, 107)
	p.r(166, 186, 6, 2, 96)
	p.r(166, 205, 6, 2, 96)
	p.r(154, 214, 3, 4, 65)
	p.r(183, 214, 3, 4, 65)
	p.rr(154, 154, 28, 22, 65)
	p.r(156, 156, 24, 18, 85)
	p.r(158, 158, 22, 12, 103)
	p.r(158, 154, 6, 3, 96)
	p.r(174, 154, 6, 3, 96)
	var lamp := Cozy.desk_lamp(p, 192, 166)
	lights.append(lamp)
	# Desk with a laptop and mug against the right wall.
	Cozy.drop_shadow(p, 220, 190, 80, 26, 0.5)
	p.r(214, 176, 90, 6, 70)
	p.r(214, 176, 90, 1, 72)
	p.r(214, 182, 90, 3, 67)
	p.r(218, 185, 4, 32, 68)
	p.r(298, 185, 4, 32, 68)
	p.r(226, 156, 30, 20, 65)
	p.r(228, 158, 26, 15, 84)
	p.r(230, 160, 12, 2, 94)
	p.r(230, 164, 18, 2, 85)
	p.r(230, 168, 10, 2, 89)
	p.r(222, 174, 38, 3, 99)
	Cozy.mug(p, 268, 168, 91)
	Cozy.books(p, 282, 176, 3, 4)
	# Chair at the desk and a floor plant.
	p.rr(246, 192, 22, 26, 65)
	p.r(248, 194, 18, 22, 85)
	p.r(248, 194, 18, 3, 86)
	Cozy.plant_big(p, 270, 200, 0)
	# Rugs.
	Cozy.rug(p, 40, 288, 200, 56, 91, 90, 78, 1)
	# Light pass.
	for l in lights:
		p.glow(l.x, l.y, 30, 0.9, 0.9)

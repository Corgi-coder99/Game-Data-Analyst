extends RefCounted
# Static art for the T-022 floor plan, drawn once into a 1280x560 image with palette v3 colors.
# Row A (top): Data Analytics, Finance, Marketing, Executive. Corridor y 252..300.
# Row B (bottom): Reception, Sales, Meeting, Server, Break. Animated parts live in office.gd.
const Pen = preload("res://scripts/v2/pen.gd")
const WORLD := Vector2i(1280, 560)
const WALL_H := 56
# rect, title, wall (base, light, shade), floor (base, seam), accent text color, short name for the minimap.
const ROOMS := {
	"data": {"rect": Rect2i(0, 0, 400, 252), "title": "DATA ANALYTICS", "wall": [18, 19, 17], "floor": [57, 17], "accent": 53, "short": "DATA"},
	"finance": {"rect": Rect2i(400, 0, 300, 252), "title": "FINANCE", "wall": [46, 47, 2], "floor": [58, 22], "accent": 52, "short": "FIN"},
	"marketing": {"rect": Rect2i(700, 0, 300, 252), "title": "MARKETING", "wall": [59, 30, 29], "floor": [29, 59], "accent": 54, "short": "MKT"},
	"executive": {"rect": Rect2i(1000, 0, 280, 252), "title": "EXECUTIVE OFFICE", "wall": [10, 11, 9], "floor": [11, 10], "accent": 27, "short": "EXEC"},
	"reception": {"rect": Rect2i(0, 300, 240, 260), "title": "RECEPTION", "wall": [38, 30, 29], "floor": [60, 10], "accent": 52, "short": "REC"},
	"sales": {"rect": Rect2i(240, 300, 320, 260), "title": "SALES", "wall": [42, 43, 9], "floor": [60, 10], "accent": 55, "short": "SALES"},
	"meeting": {"rect": Rect2i(560, 300, 300, 260), "title": "MEETING ROOM", "wall": [4, 5, 3], "floor": [61, 6], "accent": 34, "short": "MEET"},
	"server": {"rect": Rect2i(860, 300, 160, 260), "title": "SERVER ROOM", "wall": [2, 3, 1], "floor": [62, 63], "accent": 48, "short": "SRV"},
	"break": {"rect": Rect2i(1020, 300, 260, 260), "title": "BREAK ROOM", "wall": [44, 45, 43], "floor": [61, 45], "accent": 53, "short": "BREAK"}}
const CORRIDOR := Rect2i(0, 252, 1280, 48)
const ROOM_ORDER := ["data", "finance", "marketing", "executive", "reception", "sales", "meeting", "server", "break"]

static func draw_world(p: Pen) -> void:
	_corridor(p)
	for key in ROOM_ORDER:
		_room_shell(p, key)
	_data_room(p)
	_finance_room(p)
	_marketing_room(p)
	_executive_room(p)
	_reception_room(p)
	_sales_room(p)
	_meeting_room(p)
	_server_room(p)
	_break_room(p)
	exec_desk(p)
	reception_counter(p)
	meeting_table(p)
	coffee_machine(p)
	for bx in [400, 700, 1000]:
		_partition(p, bx, 0, 252)
	for bx in [240, 560, 860, 1020]:
		_partition(p, bx, 300, 260)

static func rect_of(key: String) -> Rect2i:
	return ROOMS[key].rect

static func _corridor(p: Pen) -> void:
	var c := CORRIDOR
	p.r(c.position.x, c.position.y, c.size.x, c.size.y, 61)
	for x in range(0, c.size.x, 24):
		p.r(x, c.position.y, 1, c.size.y, 7)
	p.r(0, c.position.y + 24, c.size.x, 1, 7)
	# Runner carpet down the middle, with a gold border.
	p.r(0, c.position.y + 12, c.size.x, 26, 25)
	p.r(0, c.position.y + 12, c.size.x, 2, 28)
	p.r(0, c.position.y + 36, c.size.x, 2, 28)
	for x in range(0, c.size.x, 16):
		p.r(x + 4, c.position.y + 22, 8, 6, 26)
		p.r(x + 6, c.position.y + 24, 4, 2, 28)
	p.r(0, c.position.y, c.size.x, 4, 6)
	p.r(0, c.end.y - 4, c.size.x, 4, 6)

static func _room_shell(p: Pen, key: String) -> void:
	var t: Dictionary = ROOMS[key]
	var r: Rect2i = t.rect
	var wall: Array = t.wall
	var floor_colors: Array = t.floor
	# Back wall with cornice, chair rail, wainscot and baseboard.
	p.r(r.position.x, r.position.y, r.size.x, WALL_H, wall[0])
	p.r(r.position.x, r.position.y, r.size.x, 3, wall[1])
	p.r(r.position.x, r.position.y + 3, r.size.x, 1, wall[2])
	p.r(r.position.x, r.position.y + 36, r.size.x, 17, wall[2])
	p.r(r.position.x, r.position.y + 36, r.size.x, 1, wall[1])
	p.r(r.position.x, r.position.y + 53, r.size.x, 3, 1)
	# Floor.
	var fy := r.position.y + WALL_H
	var fh := r.size.y - WALL_H
	p.r(r.position.x, fy, r.size.x, fh, floor_colors[0])
	match key:
		"data", "finance", "marketing":
			for x in range(r.position.x, r.end.x, 32):
				p.r(x, fy, 1, fh, floor_colors[1])
			for y in range(fy, r.end.y, 32):
				p.r(r.position.x, y, r.size.x, 1, floor_colors[1])
			for i in range(60):
				p.px(r.position.x + (i * 47) % r.size.x, fy + (i * 29) % fh, floor_colors[1])
		"sales", "reception":
			for y in range(fy, r.end.y, 8):
				p.r(r.position.x, y, r.size.x, 1, floor_colors[1])
				var shift := ((y - fy) / 8 * 37) % 48
				for x in range(r.position.x + shift, r.end.x, 48):
					p.r(x, y, 1, 8, floor_colors[1])
		"executive":
			for y in range(fy, r.end.y, 10):
				p.r(r.position.x, y, r.size.x, 1, floor_colors[1])
				for x in range(r.position.x + ((y - fy) / 10 * 29) % 40, r.end.x, 40):
					p.r(x, y, 1, 10, floor_colors[1])
		"meeting":
			for x in range(r.position.x, r.end.x, 20):
				p.r(x, fy, 1, fh, floor_colors[1])
			for y in range(fy, r.end.y, 20):
				p.r(r.position.x, y, r.size.x, 1, floor_colors[1])
		"server":
			p.checker(r.position.x, fy, r.size.x, fh, 62, 63, 8)
			for x in range(r.position.x, r.end.x, 40):
				p.r(x, fy, 2, fh, 1)
		"break":
			p.checker(r.position.x, fy, r.size.x, fh, 61, 45, 16)
	# Front edge: Row A gets a low glass front wall with a door gap, Row B gets a door in the back wall.
	if r.position.y == 0:
		var gap_x := 208 if key == "data" else r.position.x + r.size.x / 2 - 24
		p.r(r.position.x, r.end.y - 10, r.size.x, 10, 3)
		p.r(r.position.x, r.end.y - 10, r.size.x, 1, 6)
		p.r(r.position.x + 3, r.end.y - 8, r.size.x - 6, 4, 34)
		for gx in range(r.position.x + 24, r.end.x - 8, 48):
			p.r(gx, r.end.y - 8, 2, 4, 5)
		p.r(gap_x, r.end.y - 10, 48, 10, 61)
		p.r(gap_x - 3, r.end.y - 12, 3, 12, 52)
		p.r(gap_x + 48, r.end.y - 12, 3, 12, 52)
		p.r(gap_x, r.end.y - 12, 48, 2, 27)
		p.r(gap_x + 8, r.end.y - 4, 32, 3, 51)
	else:
		var door_x := r.position.x + r.size.x / 2 - 14
		p.box(door_x, r.position.y + 10, 28, 46, 5, 6, 3)
		p.r(door_x + 3, r.position.y + 13, 22, 43, 34)
		p.r(door_x + 3, r.position.y + 13, 22, 3, 35)
		p.r(door_x + 13, r.position.y + 13, 2, 43, 5)
		p.r(door_x + 10, r.position.y + 36, 2, 5, 52)
		p.r(door_x + 16, r.position.y + 36, 2, 5, 52)
		p.r(door_x - 4, r.position.y + 6, 36, 3, 1)

static func _partition(p: Pen, bx: int, y: int, h: int) -> void:
	p.r(bx - 4, y, 8, h, 5)
	p.r(bx - 3, y, 6, WALL_H, 4)
	p.r(bx - 3, y + WALL_H, 6, h - WALL_H, 34)
	p.r(bx - 3, y + WALL_H, 1, h - WALL_H, 35)
	for yy in range(y + WALL_H + 20, y + h - 10, 40):
		p.r(bx - 4, yy, 8, 2, 5)
	p.r(bx - 4, y, 1, h, 6)
	p.r(bx + 3, y, 1, h, 3)

# ---- helpers -----------------------------------------------------------


static func window_city(p: Pen, x: int, y: int, w: int, h: int, phase: String) -> void:
	# A window frame with a sky and a skyline silhouette, drawn per time of day.
	var sky: Array = [33, 34, 35]
	var skyline := 17
	var skyline2 := 18
	if phase == "trua":
		sky = [34, 35, 35]
		skyline = 40
		skyline2 = 41
	elif phase == "chieu":
		sky = [38, 37, 36]
		skyline = 39
		skyline2 = 2
	p.box(x, y, w, h, 9, 10, 1)
	var gx := x + 3
	var gy := y + 3
	var gw := w - 6
	var gh := h - 6
	var third := gh / 3
	p.r(gx, gy, gw, third, sky[0])
	p.r(gx, gy + third, gw, third, sky[1])
	p.r(gx, gy + third * 2, gw, gh - third * 2, sky[2])
	for i in range(0, gw, 5):
		var bh := 6 + (i * 7) % 11
		p.r(gx + i, gy + gh - bh, 5, bh, skyline if i % 10 == 0 else skyline2)
		if phase == "chieu" and i % 10 == 0:
			p.px(gx + i + 2, gy + gh - bh + 3, 52)
	p.r(x + w / 2 - 1, y + 3, 2, h - 6, 9)
	p.r(gx, y + h / 2, gw, 2, 9)

static func _sofa(p: Pen, x: int, y: int, w: int, base: int, light: int, shade: int) -> void:
	p.box(x, y, w, 12, shade, base, 1)
	p.box(x, y + 10, w, 14, base, light, shade)
	p.box(x - 4, y + 6, 8, 20, base, light, shade)
	p.box(x + w - 4, y + 6, 8, 20, base, light, shade)
	p.r(x + w / 2, y + 12, 1, 10, shade)
	p.r(x + 4, y + 25, 3, 3, 1)
	p.r(x + w - 7, y + 25, 3, 3, 1)

static func _table_top(p: Pen, x: int, y: int, w: int, h: int, top: int, light: int, edge: int) -> void:
	p.r(x, y + h, w, 4, edge)
	p.box(x, y, w, h, top, light, edge)

static func _rack(p: Pen, x: int, y: int) -> void:
	p.box(x, y, 28, 70, 1, 3, 1)
	p.r(x + 2, y + 2, 24, 66, 2)
	for ry in range(y + 4, y + 64, 8):
		p.box(x + 3, ry, 22, 6, 3, 4, 1)
		p.r(x + 5, ry + 2, 8, 2, 1)
	p.r(x + 4, y + 66, 20, 2, 5)

static func _chart_board(p: Pen, x: int, y: int, w: int, h: int, seed_value: int) -> void:
	p.box(x, y, w, h, 64, 7, 6)
	p.frame(x + 2, y + 2, w - 4, h - 4, 7)
	var bars := (w - 14) / 8
	for i in range(bars):
		var bh := 6 + ((i * 13 + seed_value * 7) % (h - 20))
		var col: int = [53, 56, 55, 54, 47][i % 5]
		p.r(x + 6 + i * 8, y + h - 6 - bh, 6, bh, col)
	p.r(x + 5, y + h - 6, w - 10, 1, 1)
	for i in range(1, bars):
		p.px(x + 6 + i * 8 - 4, y + h - 10 - ((i * 11 + seed_value) % (h - 24)), 51)

static func _cooler(p: Pen, x: int, y: int) -> void:
	p.box(x, y + 12, 12, 22, 7, 64, 6)
	p.r(x + 2, y, 8, 12, 34)
	p.r(x + 2, y, 8, 2, 35)
	p.r(x + 4, y + 18, 4, 2, 56)
	p.r(x + 3, y + 34, 6, 2, 1)

static func _bookshelf(p: Pen, x: int, y: int, w: int, rows: int) -> void:
	p.box(x, y, w, rows * 12 + 4, 9, 10, 1)
	for r_ in range(rows):
		var by := y + 2 + r_ * 12
		p.r(x + 2, by + 10, w - 4, 2, 9)
		var bx := x + 3
		var i := 0
		while bx < x + w - 6:
			var bw := 2 + (i * 3 + r_) % 3
			var bh := 6 + (i * 5 + r_ * 2) % 5
			p.r(bx, by + 10 - bh, bw, bh, [51, 53, 54, 56, 52, 47, 38, 55, 7][(i + r_ * 3) % 9])
			bx += bw + 1
			i += 1

static func _plant_big(p: Pen, x: int, y: int) -> void:
	p.box(x, y + 14, 14, 12, 43, 44, 42)
	p.disc(x + 7, y + 6, 8, 46)
	p.disc(x + 4, y + 3, 5, 47)
	p.disc(x + 10, y + 5, 4, 48)

# ---- rooms ---------------------------------------------------------------

static func _data_room(p: Pen) -> void:
	p.oy = 4
	# Wall: dashboard display, clock zone, whiteboard.
	p.box(112, 10, 184, 38, 1, 3, 1)
	p.r(116, 14, 176, 30, 2)
	# Charts on the dashboard (animated cursor is drawn in office.gd).
	p.r(120, 18, 52, 22, 3)
	for i in range(0, 52, 4):
		p.r(121 + i, 38 - ((i * 7) % 16) - 4, 3, ((i * 7) % 16) + 4, 53 if i % 8 == 0 else 33)
	p.r(178, 18, 60, 22, 3)
	for i in range(0, 58, 2):
		p.px(179 + i, 36 - int(6.0 * sin(float(i) / 7.0)) - (i / 8), 52)
	p.r(244, 18, 44, 10, 23)
	p.r(244, 30, 20, 10, 51)
	p.r(268, 30, 20, 10, 56)
	p.oy = 0
	# Rug and watercooler.
	p.r(120, 138, 150, 50, 56)
	p.frame(120, 138, 150, 50, 28)
	p.frame(124, 142, 142, 42, 33)
	p.r(130, 146, 130, 34, 17)
	# Analysis table with charts on the rug.
	p.disc(195, 170, 22, 1)
	p.disc(195, 164, 22, 5)
	p.disc(195, 163, 20, 64)
	p.r(176, 154, 12, 8, 7)
	p.r(178, 156, 8, 1, 53)
	p.r(178, 158, 6, 1, 51)
	p.r(200, 160, 14, 8, 33)
	p.r(202, 163, 10, 1, 52)
	p.box(188, 148, 14, 8, 1, 3, 1)
	p.r(190, 150, 10, 4, 56)
	_cooler(p, 372, 100)
	# Printer table.
	_table_top(p, 340, 160, 40, 14, 7, 64, 6)
	p.box(346, 150, 28, 12, 6, 7, 5)
	p.r(350, 156, 20, 2, 1)
	p.r(352, 162, 16, 3, 64)

static func _finance_room(p: Pen) -> void:
	p.oy = 4
	_chart_board(p, 450, 8, 120, 42, 3)
	p.box(590, 10, 40, 36, 1, 2, 1)
	for i in range(5):
		p.r(594 + i * 7, 40 - (i * 5 + 4) % 24, 5, (i * 5 + 4) % 24 + 2, 52)
	p.oy = 0
	# Coin stack and safe.
	p.box(648, 140, 34, 40, 4, 5, 3)
	p.disc(665, 160, 9, 6)
	p.disc(665, 160, 6, 5)
	p.r(664, 154, 2, 12, 27)
	p.r(659, 159, 12, 2, 27)
	for i in range(3):
		p.box(436, 176 - i * 6, 14, 5, 28, 52, 27)
	p.box(660, 70, 28, 56, 7, 64, 6)
	p.r(662, 74, 24, 24, 6)
	p.r(662, 102, 24, 22, 6)
	p.r(672, 80, 4, 4, 5)
	p.r(672, 108, 4, 4, 5)
	p.r(410, 140, 6, 40, 47)

static func _marketing_room(p: Pen) -> void:
	p.oy = 4
	# Mood board: colorful notes.
	p.box(730, 8, 150, 42, 7, 64, 6)
	var i := 0
	for yy in range(12, 46, 12):
		for xx in range(734, 872, 14):
			var col: int = [54, 52, 53, 55, 56, 47, 37, 36][(i * 3) % 8]
			p.r(xx, yy, 11, 10, col)
			p.r(xx, yy, 11, 1, 64)
			i += 1
	# Posters.
	p.box(900, 10, 30, 38, 54, 37, 38)
	p.disc(915, 26, 8, 52)
	p.r(905, 38, 20, 6, 64)
	p.box(940, 14, 30, 30, 56, 33, 17)
	p.r(944, 20, 22, 4, 64)
	p.r(944, 28, 14, 3, 52)
	p.oy = 0
	# Easel with a canvas and a camera tripod.
	p.r(940, 150, 3, 36, 10)
	p.r(970, 150, 3, 36, 10)
	p.box(938, 130, 38, 30, 64, 7, 6)
	p.r(944, 136, 12, 16, 54)
	p.r(958, 140, 12, 12, 53)
	p.r(980, 160, 2, 28, 1)
	p.box(976, 152, 10, 8, 3, 5, 1)
	p.disc(981, 156, 2, 34)
	_sofa(p, 722, 172, 56, 54, 37, 38)

static func _executive_room(p: Pen) -> void:
	p.oy = 4
	window_city(p, 1030, 8, 100, 42, "sang")
	p.box(1150, 10, 22, 36, 17, 18, 16)
	p.r(1154, 14, 14, 20, 27)
	p.r(1158, 18, 6, 12, 26)
	_bookshelf(p, 1190, 8, 80, 3)
	p.oy = 0
	# Rug.
	p.r(1060, 112, 170, 90, 25)
	p.frame(1060, 112, 170, 90, 28)
	p.frame(1064, 116, 162, 82, 26)
	p.r(1100, 134, 90, 44, 26)
	# Visitor chairs in front of the desk and a plant.
	p.box(1088, 172, 22, 16, 25, 26, 9)
	p.box(1180, 172, 22, 16, 25, 26, 9)
	_plant_big(p, 1010, 150)
	_plant_big(p, 1250, 70)

static func _reception_room(p: Pen) -> void:
	p.oy = 4
	# Company logo wall.
	p.box(60, 312, 120, 34, 1, 3, 1)
	p.disc(84, 329, 10, 52)
	p.disc(84, 329, 7, 1)
	p.r(80, 325, 8, 8, 53)
	p.r(100, 322, 70, 3, 52)
	p.r(100, 330, 54, 3, 64)
	p.r(100, 338, 40, 2, 6)
	p.oy = 0
	# Rug and sofas.
	p.r(10, 450, 220, 90, 56)
	p.frame(10, 450, 220, 90, 28)
	p.frame(14, 454, 212, 82, 33)
	_sofa(p, 28, 488, 70, 52, 28, 27)
	_sofa(p, 140, 488, 70, 55, 44, 43)
	_table_top(p, 100, 500, 36, 10, 64, 7, 6)
	p.r(112, 496, 6, 4, 53)
	_plant_big(p, 12, 420)

static func _sales_room(p: Pen) -> void:
	p.oy = 4
	# Sales board: target thermometer and weekly bars.
	p.box(262, 308, 150, 40, 64, 7, 6)
	p.r(268, 314, 100, 6, 7)
	p.r(268, 314, 74, 6, 47)
	p.r(268, 324, 100, 6, 7)
	p.r(268, 324, 52, 6, 55)
	p.r(268, 334, 100, 6, 7)
	p.r(268, 334, 88, 6, 53)
	p.disc(388, 336, 5, 51)
	p.r(386, 316, 5, 20, 51)
	# Pennants and a plant.
	p.oy = 0
	for i in range(5):
		p.r(430 + i * 14, 312, 12, 12, [51, 52, 53, 54, 56][i])
		p.r(432 + i * 14, 324, 8, 3, [51, 52, 53, 54, 56][i])
	_plant_big(p, 520, 420)
	_cooler(p, 292, 440)
	p.r(300, 480, 220, 40, 42)
	p.frame(300, 480, 220, 40, 28)
	p.r(306, 486, 208, 28, 43)

static func _meeting_room(p: Pen) -> void:
	p.oy = 4
	# Whiteboard with a chart and a screen.
	_chart_board(p, 600, 306, 130, 44, 5)
	p.box(750, 308, 70, 40, 1, 3, 1)
	p.r(754, 312, 62, 30, 56)
	p.r(758, 328, 14, 10, 52)
	p.r(776, 322, 14, 16, 53)
	p.r(794, 316, 14, 22, 54)
	_plant_big(p, 572, 400)

static func _server_room(p: Pen) -> void:
	p.oy = 0
	for i in range(4):
		_rack(p, 870 + i * 34, 360)
	# Cable tray, cold-aisle floor strip and AC unit.
	p.r(866, 330, 148, 8, 3)
	for x in range(868, 1012, 6):
		p.r(x, 330, 2, 8, [51, 56, 52, 53][(x / 6) % 4])
	p.box(900, 308, 80, 18, 5, 6, 3)
	for x in range(906, 976, 5):
		p.r(x, 312, 2, 10, 3)
	p.r(870, 460, 140, 6, 56)
	p.r(870, 468, 140, 2, 53)
	p.box(880, 480, 50, 22, 4, 5, 3)
	p.r(884, 484, 42, 14, 2)
	p.r(1000, 440, 10, 60, 5)

static func _break_room(p: Pen) -> void:
	p.oy = 0
	# Kitchen counter, fridge, vending machine, sofa.
	p.box(1100, 358, 100, 8, 7, 64, 6)
	p.box(1100, 366, 100, 42, 8, 9, 1)
	p.r(1104, 372, 28, 32, 2)
	p.r(1136, 372, 28, 32, 2)
	p.r(1168, 372, 28, 32, 2)
	p.box(1034, 326, 24, 50, 64, 7, 6)
	p.r(1036, 352, 20, 1, 6)
	p.r(1054, 336, 2, 12, 5)
	p.box(1212, 322, 30, 54, 51, 25, 24)
	p.r(1216, 328, 22, 28, 1)
	for i in range(3):
		for j in range(3):
			p.r(1218 + j * 7, 330 + i * 9, 5, 7, [52, 53, 54, 56, 55, 47, 38, 64, 36][(i * 3 + j)])
	p.r(1220, 360, 18, 8, 3)
	_sofa(p, 1080, 454, 90, 54, 37, 38)
	_table_top(p, 1184, 470, 40, 12, 10, 11, 9)
	p.r(1198, 482, 4, 24, 9)
	p.r(1200, 458, 6, 10, 7)
	_plant_big(p, 1258, 410)
	p.r(1040, 420, 24, 8, 1)

static func exec_desk(p: Pen) -> void:
	p.oy = 0
	p.box(1096, 102, 100, 24, 10, 11, 9)
	p.r(1096, 102, 100, 5, 13)
	p.r(1096, 126, 100, 14, 9)
	p.r(1102, 130, 38, 8, 8)
	p.r(1150, 130, 38, 8, 8)
	p.box(1104, 92, 18, 10, 1, 3, 1)
	p.r(1106, 94, 14, 6, 56)
	p.r(1176, 96, 6, 6, 27)
	p.r(1178, 90, 2, 6, 7)

static func coffee_machine(p: Pen) -> void:
	p.oy = 0
	p.box(1124, 330, 22, 28, 3, 5, 1)
	p.r(1128, 334, 14, 8, 2)
	p.r(1130, 336, 4, 4, 53)
	p.r(1136, 336, 4, 4, 51)
	p.r(1130, 346, 10, 10, 1)
	p.r(1132, 350, 6, 6, 7)
	p.r(1132, 350, 6, 2, 9)

static func reception_counter(p: Pen) -> void:
	p.oy = 0
	p.box(60, 390, 130, 26, 10, 11, 9)
	p.r(60, 390, 130, 5, 13)
	p.r(60, 416, 130, 14, 9)
	p.r(66, 420, 28, 8, 8)
	p.r(98, 420, 28, 8, 8)
	p.r(130, 420, 28, 8, 8)
	p.box(150, 380, 22, 14, 1, 3, 1)
	p.r(152, 382, 18, 8, 53)

static func meeting_table(p: Pen) -> void:
	p.oy = 0
	p.oy = 0
	p.box(620, 450, 220, 52, 34, 35, 5)
	p.r(624, 454, 212, 6, 35)
	p.r(620, 502, 220, 6, 5)
	p.r(640, 508, 6, 20, 3)
	p.r(814, 508, 6, 20, 3)
	for i in range(5):
		p.r(640 + i * 34, 470, 12, 8, 64)
	p.disc(730, 480, 5, 56)

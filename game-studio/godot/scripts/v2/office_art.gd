extends RefCounted
# Static art for the T-022 floor plan (T-028 cozy restyle), drawn once into a 1280x560 image with palette v4 colors.
# Row A (top): Data Analytics, Finance, Marketing, Executive. Corridor y 252..300.
# Row B (bottom): Reception, Sales, Meeting, Server, Break. Animated parts live in office.gd.
const Pen = preload("res://scripts/v2/pen.gd")
const Cozy = preload("res://scripts/v2/cozy.gd")
const WORLD := Vector2i(1280, 560)
const WALL_H := 56
# rect, title, wall (base, light, shade), floor (base, seam), accent text color, short name for the minimap.
const ROOMS := {
	"data": {"rect": Rect2i(0, 0, 400, 252), "title": "DATA ANALYTICS", "wall": [94, 21, 84], "floor": [57, 84], "accent": 53, "short": "DATA"},
	"finance": {"rect": Rect2i(400, 0, 300, 252), "title": "FINANCE", "wall": [90, 77, 74], "floor": [58, 78], "accent": 52, "short": "FIN"},
	"marketing": {"rect": Rect2i(700, 0, 300, 252), "title": "MARKETING", "wall": [86, 85, 87], "floor": [59, 88], "accent": 54, "short": "MKT"},
	"executive": {"rect": Rect2i(1000, 0, 280, 252), "title": "EXECUTIVE OFFICE", "wall": [68, 69, 67], "floor": [109, 108], "accent": 27, "short": "EXEC"},
	"reception": {"rect": Rect2i(0, 300, 240, 260), "title": "RECEPTION", "wall": [93, 82, 81], "floor": [70, 69], "accent": 52, "short": "REC"},
	"sales": {"rect": Rect2i(240, 300, 320, 260), "title": "SALES", "wall": [92, 104, 105], "floor": [60, 107], "accent": 55, "short": "SALES"},
	"meeting": {"rect": Rect2i(560, 300, 300, 260), "title": "MEETING ROOM", "wall": [100, 101, 99], "floor": [101, 100], "accent": 34, "short": "MEET"},
	"server": {"rect": Rect2i(860, 300, 160, 260), "title": "SERVER ROOM", "wall": [83, 84, 79], "floor": [3, 4], "accent": 48, "short": "SRV"},
	"break": {"rect": Rect2i(1020, 300, 260, 260), "title": "BREAK ROOM", "wall": [97, 96, 98], "floor": [102, 90], "accent": 53, "short": "BREAK"}}
const CORRIDOR := Rect2i(0, 252, 1280, 48)
const ROOM_ORDER := ["data", "finance", "marketing", "executive", "reception", "sales", "meeting", "server", "break"]
static var lights: Array = []

static func draw_world(p: Pen) -> void:
	lights = []
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
	for bx in [400, 700, 1000]:
		_partition(p, bx, 0, 252)
	for bx in [240, 560, 860, 1020]:
		_partition(p, bx, 300, 260)
	# Light pass: lamps and string lights glow, window shafts fall on the floor.
	for l in lights:
		p.glow(l.x, l.y, l.r, l.s, 0.8)
	exec_desk(p)
	reception_counter(p)
	meeting_table(p)
	coffee_machine(p)

static func _glow(x: int, y: int, r: int, s: float = 0.9) -> void:
	lights.append({"x": x, "y": y, "r": r, "s": s})

static func rect_of(key: String) -> Rect2i:
	return ROOMS[key].rect

static func _corridor(p: Pen) -> void:
	var c := CORRIDOR
	Cozy.planks(p, c.position.x, c.position.y, c.size.x, c.size.y, 70, 71, 107, 68, 8)
	# Runner rug with a patterned border.
	p.r(0, c.position.y + 10, c.size.x, 28, 65)
	p.r(0, c.position.y + 11, c.size.x, 26, 88)
	p.r(0, c.position.y + 13, c.size.x, 22, 87)
	p.r(0, c.position.y + 15, c.size.x, 18, 80)
	for x in range(0, c.size.x, 16):
		p.r(x + 5, c.position.y + 21, 6, 6, 81)
		p.r(x + 7, c.position.y + 23, 2, 2, 89)
		p.px(x + 1, c.position.y + 18, 82)
		p.px(x + 9, c.position.y + 30, 82)
		p.px(x + 2, c.position.y + 12, 89)
	p.r(0, c.position.y, c.size.x, 3, 67)
	p.r(0, c.position.y + 3, c.size.x, 1, 66)
	p.r(0, c.end.y - 3, c.size.x, 3, 67)
	for x in range(40, c.size.x, 160):
		Cozy.plant_small(p, x, c.position.y - 2, (x / 160) % 3)

static func _room_shell(p: Pen, key: String) -> void:
	var t: Dictionary = ROOMS[key]
	var r: Rect2i = t.rect
	var wall: Array = t.wall
	var floor_colors: Array = t.floor
	var fy := r.position.y + WALL_H
	var fh := r.size.y - WALL_H
	Cozy.wallpaper(p, r.position.x, r.position.y, r.size.x, WALL_H, wall[0], wall[2], wall[1])
	p.r(r.position.x, r.position.y, r.size.x, 3, wall[1])
	p.r(r.position.x, r.position.y + 3, r.size.x, 1, 66)
	p.r(r.position.x, r.position.y + 36, r.size.x, 17, wall[2])
	p.r(r.position.x, r.position.y + 36, r.size.x, 2, 102)
	p.r(r.position.x, r.position.y + 38, r.size.x, 1, 101)
	for x in range(r.position.x + 4, r.end.x - 8, 20):
		p.r(x, r.position.y + 41, 16, 9, wall[0])
		p.r(x, r.position.y + 41, 16, 1, wall[1])
		p.r(x, r.position.y + 49, 16, 1, 66)
	p.r(r.position.x, r.position.y + 53, r.size.x, 3, 67)
	p.r(r.position.x, r.position.y + 53, r.size.x, 1, 71)
	match key:
		"data":
			Cozy.carpet(p, r.position.x, fy, r.size.x, fh, floor_colors[0], 80, floor_colors[1], 32)
		"finance":
			Cozy.carpet(p, r.position.x, fy, r.size.x, fh, floor_colors[0], 91, floor_colors[1], 32)
		"marketing":
			Cozy.carpet(p, r.position.x, fy, r.size.x, fh, floor_colors[0], 85, floor_colors[1], 32)
		"executive":
			Cozy.planks(p, r.position.x, fy, r.size.x, fh, floor_colors[0], 107, floor_colors[1], 66, 10)
		"reception":
			Cozy.planks(p, r.position.x, fy, r.size.x, fh, 70, 71, 107, 68, 8)
		"sales":
			Cozy.planks(p, r.position.x, fy, r.size.x, fh, 60, 71, 107, 108, 8)
		"meeting":
			Cozy.tiles(p, r.position.x, fy, r.size.x, fh, 101, 100, 99, 20)
		"server":
			Cozy.tiles(p, r.position.x, fy, r.size.x, fh, 3, 4, 2, 16)
			for x in range(r.position.x + 8, r.end.x, 40):
				p.r(x, fy, 1, fh, 78)
		"break":
			Cozy.tiles(p, r.position.x, fy, r.size.x, fh, 102, 90, 100, 16)
	p.shade(r.position.x, fy, r.size.x, 8, 0.7)
	if r.position.y == 0:
		var gap_x := 208 if key == "data" else r.position.x + r.size.x / 2 - 24
		p.r(r.position.x, r.end.y - 10, r.size.x, 10, 83)
		p.r(r.position.x, r.end.y - 10, r.size.x, 1, 101)
		p.r(r.position.x + 3, r.end.y - 8, r.size.x - 6, 4, 94)
		p.r(r.position.x + 3, r.end.y - 8, r.size.x - 6, 1, 35)
		for gx in range(r.position.x + 24, r.end.x - 8, 48):
			p.r(gx, r.end.y - 8, 2, 4, 100)
			p.px(gx + 6, r.end.y - 7, 102)
		p.r(gap_x, r.end.y - 10, 48, 10, 70)
		p.r(gap_x - 3, r.end.y - 12, 3, 12, 97)
		p.r(gap_x + 48, r.end.y - 12, 3, 12, 97)
		p.r(gap_x, r.end.y - 12, 48, 2, 96)
		p.r(gap_x + 8, r.end.y - 4, 32, 3, 87)
		p.r(gap_x + 8, r.end.y - 4, 32, 1, 85)
	else:
		var door_x := r.position.x + r.size.x / 2 - 14
		p.rr(door_x, r.position.y + 10, 28, 46, 65)
		p.r(door_x + 2, r.position.y + 12, 24, 44, 94)
		p.r(door_x + 2, r.position.y + 12, 24, 4, 35)
		p.r(door_x + 13, r.position.y + 12, 2, 44, 100)
		p.r(door_x + 10, r.position.y + 36, 2, 5, 96)
		p.r(door_x + 16, r.position.y + 36, 2, 5, 96)
		p.r(door_x - 4, r.position.y + 6, 36, 3, 66)
		_glow(door_x + 14, r.position.y + 50, 26, 0.6)

static func _partition(p: Pen, bx: int, y: int, h: int) -> void:
	p.r(bx - 4, y, 8, h, 100)
	p.r(bx - 3, y, 6, WALL_H, 99)
	p.r(bx - 3, y + WALL_H, 6, h - WALL_H, 94)
	p.r(bx - 3, y + WALL_H, 1, h - WALL_H, 35)
	p.r(bx + 1, y + WALL_H, 1, h - WALL_H, 21)
	for yy in range(y + WALL_H + 20, y + h - 10, 40):
		p.r(bx - 4, yy, 8, 2, 100)
	p.r(bx - 4, y, 1, h, 101)
	p.r(bx + 3, y, 1, h, 66)

# ---- helpers -------------------------------------------------------------------------------

static func window_city(p: Pen, x: int, y: int, w: int, h: int, phase: String) -> void:
	var sky: Array = [34, 94, 35]
	var far := 84
	var near := 79
	var evening := false
	if phase == "trua":
		sky = [94, 35, 35]
		far = 100
		near = 99
	elif phase == "chieu":
		sky = [97, 85, 93]
		far = 79
		near = 83
		evening = true
	p.r(x, y, w, h, 65)
	p.rr(x + 1, y + 1, w - 2, h - 2, 69)
	p.r(x + 1, y + 1, w - 2, 1, 71)
	var gx := x + 3
	var gy := y + 3
	var gw := w - 6
	var gh := h - 11
	var third := gh / 3
	p.r(gx, gy, gw, third, sky[0])
	p.r(gx, gy + third, gw, third, sky[1])
	p.r(gx, gy + third * 2, gw, gh - third * 2, sky[2])
	for i in range(0, gw, 4):
		var bh := 5 + (i * 5) % 9
		p.r(gx + i, gy + gh - bh, 4, bh, far if i % 8 == 0 else near)
		if evening:
			p.px(gx + i + 1, gy + gh - bh + 2, 96)
	if not evening:
		p.r(gx + 3, gy + 3, 5, 1, 72)
		p.r(gx + 5, gy + 2, 4, 1, 72)
	p.r(x + w / 2 - 1, gy, 2, gh, 69)
	p.r(gx, y + h / 2 - 3, gw, 2, 69)
	p.r(gx, gy, 4, gh, 87)
	p.r(gx + gw - 4, gy, 4, gh, 87)
	p.r(gx + 1, gy, 1, gh, 85)
	p.r(gx + gw - 3, gy + 2, 1, gh - 2, 88)
	p.r(x, y + h - 8, w, 3, 70)
	p.r(x, y + h - 8, w, 1, 72)
	p.r(x, y + h - 5, w, 3, 67)

static func _chart_board(p: Pen, x: int, y: int, w: int, h: int, seed_value: int) -> void:
	p.r(x, y, w, h, 65)
	p.r(x + 1, y + 1, w - 2, h - 2, 102)
	p.r(x + 1, y + 1, w - 2, 1, 72)
	p.r(x, y + h, w, 1, 66)
	var bars := (w - 14) / 8
	for i in range(bars):
		var bh := 6 + ((i * 13 + seed_value * 7) % (h - 20))
		var col: int = [85, 91, 89, 93, 94][i % 5]
		p.r(x + 6 + i * 8, y + h - 6 - bh, 6, bh, col)
		p.r(x + 6 + i * 8, y + h - 6 - bh, 6, 1, 72)
	p.r(x + 5, y + h - 6, w - 10, 1, 99)
	p.r(x + 3, y + h - 3, 10, 1, 87)

static func _cooler(p: Pen, x: int, y: int) -> void:
	Cozy.drop_shadow(p, x, y + 18, 14, 18, 0.5)
	p.r(x, y + 12, 12, 22, 102)
	p.r(x, y + 12, 1, 22, 101)
	p.r(x + 11, y + 12, 1, 22, 100)
	p.r(x + 2, y, 8, 12, 94)
	p.r(x + 2, y, 8, 2, 35)
	p.r(x + 3, y + 3, 1, 6, 102)
	p.r(x + 3, y + 18, 3, 2, 85)
	p.r(x + 7, y + 18, 3, 2, 94)
	p.r(x + 2, y + 34, 8, 2, 65)

static func _desk_rug(p: Pen, x: int, y: int, seed_value: int) -> void:
	var i := seed_value % 4
	Cozy.rug(p, x - 4, y + 30, 56, 30, [81, 91, 85, 90][i], [82, 90, 86, 91][i], [80, 78, 87, 84][i], seed_value)

static func _glows_for(p: Pen, x1: int, x2: int, y: int, sag: int, seed_value: int) -> void:
	var glows: Array = []
	Cozy.string_lights(p, x1, x2, y, sag, seed_value, glows)
	for g in glows:
		_glow(g.x, g.y, 9, 0.7)

# ---- rooms ---------------------------------------------------------------------------------

static func _data_room(p: Pen) -> void:
	p.rr(112, 8, 184, 38, 65)
	p.r(115, 11, 178, 32, 83)
	p.r(120, 16, 52, 24, 79)
	for i in range(0, 52, 4):
		p.r(121 + i, 36 - ((i * 7) % 16) - 2, 3, ((i * 7) % 16) + 3, 91 if i % 8 == 0 else 94)
	p.r(178, 16, 60, 24, 79)
	for i in range(0, 58, 2):
		p.px(179 + i, 34 - int(6.0 * sin(float(i) / 7.0)) - (i / 8), 89)
	p.r(244, 16, 44, 10, 74)
	p.r(244, 29, 20, 11, 87)
	p.r(268, 29, 20, 11, 84)
	_glows_for(p, 8, 108, 6, 6, 0)
	_glows_for(p, 300, 396, 6, 6, 2)
	Cozy.poster(p, 368, 14, 22, 28, 0)
	for spot in [[40, 100], [208, 100], [40, 192], [208, 192]]:
		_desk_rug(p, spot[0], spot[1] - 6, (spot[0] + spot[1]) / 8)
	Cozy.rug(p, 112, 130, 82, 56, 79, 80, 87, 1)
	Cozy.rug(p, 196, 130, 82, 56, 79, 80, 87, 1)
	p.shade(160, 168, 70, 8, 0.8)
	p.disc(195, 168, 22, 66)
	p.disc(195, 162, 22, 100)
	p.disc(195, 161, 20, 102)
	p.r(176, 152, 12, 8, 94)
	p.r(178, 154, 8, 1, 84)
	p.r(178, 156, 6, 1, 85)
	p.r(200, 158, 14, 8, 89)
	p.r(202, 161, 10, 1, 87)
	Cozy.mug(p, 190, 150, 91)
	_cooler(p, 372, 100)
	Cozy.drop_shadow(p, 340, 160, 40, 14)
	p.r(340, 160, 40, 14, 70)
	p.r(340, 160, 40, 2, 72)
	p.r(340, 174, 40, 2, 67)
	p.r(346, 148, 28, 13, 101)
	p.r(346, 148, 28, 2, 102)
	p.r(350, 154, 20, 2, 99)
	p.r(352, 160, 16, 2, 102)
	p.r(354, 143, 10, 5, 89)
	Cozy.plant_small(p, 4, 112, 0)
	Cozy.plant_small(p, 372, 186, 2)
	var lamp := Cozy.floor_lamp(p, 288, 100)
	_glow(lamp.x, lamp.y + 6, 36, 1.0)
	_glow(120, 30, 40, 0.5)

static func _finance_room(p: Pen) -> void:
	_chart_board(p, 450, 8, 120, 42, 3)
	p.rr(590, 8, 40, 38, 65)
	p.r(592, 10, 36, 34, 83)
	for i in range(5):
		p.r(595 + i * 6, 40 - (i * 5 + 4) % 24, 4, (i * 5 + 4) % 24 + 2, [89, 91, 85, 94, 90][i])
	_glows_for(p, 404, 440, 6, 4, 1)
	_glows_for(p, 640, 696, 6, 4, 3)
	Cozy.poster(p, 640, 12, 20, 26, 1)
	Cozy.picture(p, 668, 14, 18, 22, 1)
	Cozy.rug(p, 420, 120, 130, 80, 78, 91, 74, 0)
	Cozy.rug(p, 556, 120, 130, 80, 78, 91, 74, 2)
	Cozy.drop_shadow(p, 658, 100, 34, 44)
	p.rr(658, 96, 34, 44, 65)
	p.r(660, 98, 30, 40, 99)
	p.r(660, 98, 30, 2, 100)
	p.disc(675, 118, 8, 65)
	p.disc(675, 118, 6, 97)
	p.r(674, 112, 2, 12, 71)
	p.r(669, 117, 12, 2, 71)
	p.r(668, 140, 3, 3, 65)
	p.r(680, 140, 3, 3, 65)
	for i in range(3):
		p.r(432, 176 - i * 6, 14, 5, 96)
		p.r(432, 176 - i * 6, 14, 1, 95)
		p.r(432, 180 - i * 6, 14, 1, 98)
	Cozy.plant_big(p, 402, 104, 0)
	Cozy.plant_small(p, 680, 190, 1)
	Cozy.mug(p, 640, 170, 89)
	var lamp := Cozy.floor_lamp(p, 640, 112)
	_glow(lamp.x, lamp.y + 6, 34, 1.0)

static func _marketing_room(p: Pen) -> void:
	p.rr(728, 6, 154, 44, 65)
	p.r(730, 8, 150, 40, 102)
	Cozy.sticky_notes(p, 734, 10, 142, 36, 2)
	Cozy.poster(p, 900, 10, 30, 38, 3)
	Cozy.poster(p, 940, 14, 30, 30, 4)
	Cozy.poster(p, 976, 10, 18, 36, 2)
	_glows_for(p, 886, 996, 4, 6, 4)
	Cozy.rug(p, 724, 150, 120, 90, 86, 85, 87, 1)
	p.r(940, 150, 3, 36, 109)
	p.r(970, 150, 3, 36, 109)
	p.rr(936, 128, 42, 32, 65)
	p.r(938, 130, 38, 28, 102)
	p.r(942, 134, 12, 18, 85)
	p.r(956, 138, 14, 12, 91)
	p.disc(962, 142, 3, 89)
	p.r(986, 160, 2, 28, 65)
	p.r(982, 152, 10, 8, 66)
	p.disc(987, 156, 2, 94)
	Cozy.sofa(p, 744, 190, 56, 87, 85, 88, 89, 91)
	Cozy.plant_big(p, 976, 190, 1)
	Cozy.plant_small(p, 704, 120, 2)
	var lamp := Cozy.floor_lamp(p, 722, 110)
	_glow(lamp.x, lamp.y + 6, 34, 1.0)
	_glow(840, 60, 50, 0.4)

static func _executive_room(p: Pen) -> void:
	window_city(p, 1030, 8, 100, 42, "sang")
	p.shaft(1034, 62, 90, 70, 26, 0.9)
	p.rr(1150, 10, 22, 38, 65)
	p.r(1152, 12, 18, 34, 79)
	p.r(1155, 16, 12, 20, 96)
	p.r(1158, 20, 6, 12, 97)
	Cozy.shelf(p, 1188, 6, 84, 3, 4)
	Cozy.rug(p, 1056, 112, 176, 96, 87, 88, 96, 0)
	p.r(1100, 134, 90, 44, 88)
	Cozy.plant_big(p, 1004, 150, 0)
	Cozy.plant_big(p, 1246, 70, 1)
	p.r(1104, 172, 22, 16, 87)
	p.r(1104, 172, 22, 1, 85)
	p.r(1180, 172, 22, 16, 87)
	p.r(1180, 172, 22, 1, 85)
	var lamp := Cozy.floor_lamp(p, 1210, 100)
	_glow(lamp.x, lamp.y + 6, 36, 1.0)
	Cozy.poster(p, 1004, 14, 14, 24, 1)
	_glows_for(p, 1136, 1188, 4, 4, 0)

static func _reception_room(p: Pen) -> void:
	p.rr(58, 310, 124, 36, 65)
	p.r(60, 312, 120, 32, 83)
	p.disc(84, 328, 10, 97)
	p.disc(84, 328, 7, 83)
	p.r(80, 324, 8, 8, 91)
	p.r(100, 322, 70, 3, 89)
	p.r(100, 330, 54, 3, 102)
	p.r(100, 338, 40, 2, 100)
	_glow(120, 330, 56, 0.5)
	_glows_for(p, 6, 56, 308, 4, 3)
	_glows_for(p, 186, 236, 308, 4, 1)
	Cozy.rug(p, 8, 440, 226, 100, 85, 86, 87, 0)
	Cozy.sofa(p, 28, 488, 70, 93, 82, 81, 89, 85)
	Cozy.sofa(p, 140, 488, 70, 91, 90, 78, 85, 89)
	Cozy.drop_shadow(p, 100, 500, 36, 10)
	p.r(100, 498, 36, 10, 102)
	p.r(100, 498, 36, 1, 72)
	p.r(100, 508, 36, 2, 100)
	Cozy.mug(p, 108, 490, 85)
	Cozy.books(p, 120, 498, 2, 3)
	Cozy.plant_big(p, 8, 400, 0)
	Cozy.plant_big(p, 206, 380, 1)
	var lamp := Cozy.floor_lamp(p, 194, 430)
	_glow(lamp.x, lamp.y + 6, 34, 1.0)
	Cozy.picture(p, 190, 330, 14, 18, 0)

static func _sales_room(p: Pen) -> void:
	p.rr(260, 306, 154, 42, 65)
	p.r(262, 308, 150, 38, 102)
	p.r(268, 314, 100, 6, 101)
	p.r(268, 314, 74, 6, 91)
	p.r(268, 324, 100, 6, 101)
	p.r(268, 324, 52, 6, 97)
	p.r(268, 334, 100, 6, 101)
	p.r(268, 334, 88, 6, 85)
	p.disc(390, 336, 5, 87)
	p.r(388, 316, 4, 20, 87)
	for i in range(5):
		var col: int = [85, 89, 91, 93, 97][i]
		p.r(430 + i * 14, 312, 12, 12, col)
		p.r(430 + i * 14, 312, 12, 1, 72)
		p.r(432 + i * 14, 324, 8, 3, col)
	_glows_for(p, 424, 500, 304, 5, 2)
	for spot in [[262, 392], [346, 392], [430, 392]]:
		_desk_rug(p, spot[0], spot[1] - 6, spot[0] / 84)
	Cozy.rug(p, 296, 480, 224, 44, 70, 71, 98, 2)
	Cozy.plant_big(p, 520, 410, 0)
	_cooler(p, 292, 430)
	Cozy.plant_small(p, 250, 330, 1)
	Cozy.poster(p, 520, 316, 20, 26, 0)
	var lamp := Cozy.floor_lamp(p, 244, 450)
	_glow(lamp.x, lamp.y + 6, 34, 1.0)

static func _meeting_room(p: Pen) -> void:
	_chart_board(p, 600, 306, 130, 44, 5)
	p.rr(750, 308, 70, 40, 65)
	p.r(752, 310, 66, 36, 83)
	p.r(758, 318, 14, 24, 94)
	p.r(776, 326, 14, 16, 85)
	p.r(794, 322, 14, 20, 89)
	Cozy.rug(p, 590, 424, 262, 112, 99, 100, 81, 0)
	Cozy.plant_big(p, 568, 396, 0)
	Cozy.plant_big(p, 836, 396, 1)
	Cozy.picture(p, 830, 314, 16, 22, 2)
	_glow(710, 340, 60, 0.4)

static func _server_room(p: Pen) -> void:
	for i in range(4):
		var x := 870 + i * 34
		p.shade(x - 3, 420, 34, 10, 0.5)
		p.rr(x, 360, 28, 70, 65)
		p.r(x + 2, 362, 24, 66, 83)
		for ry in range(364, 424, 8):
			p.r(x + 3, ry, 22, 6, 4)
			p.r(x + 3, ry, 22, 1, 5)
			p.r(x + 5, ry + 3, 8, 2, 2)
		p.r(x + 4, 426, 20, 2, 99)
	p.r(866, 330, 148, 8, 3)
	for x in range(868, 1012, 6):
		p.r(x, 330, 2, 8, [85, 91, 89, 93][(x / 6) % 4])
	p.rr(900, 308, 80, 18, 65)
	p.r(902, 310, 76, 14, 99)
	for x in range(906, 976, 5):
		p.r(x, 312, 2, 10, 4)
	p.r(870, 460, 140, 4, 78)
	p.r(870, 466, 140, 2, 91)
	p.rr(880, 478, 50, 24, 65)
	p.r(882, 480, 46, 20, 84)
	p.r(884, 482, 42, 6, 94)
	Cozy.plant_small(p, 980, 440, 2)
	Cozy.mug(p, 960, 486, 91)
	_glow(940, 400, 60, 0.35)

static func _break_room(p: Pen) -> void:
	p.r(1100, 358, 100, 8, 102)
	p.r(1100, 358, 100, 1, 72)
	p.r(1100, 366, 100, 42, 69)
	p.r(1100, 366, 100, 1, 65)
	for i in range(3):
		p.r(1104 + i * 32, 372, 28, 32, 68)
		p.r(1104 + i * 32, 372, 28, 1, 70)
		p.r(1116 + i * 32, 386, 4, 2, 96)
	Cozy.mug(p, 1180, 351, 85)
	Cozy.plant_small(p, 1100, 346, 0)
	p.rr(1034, 324, 24, 52, 65)
	p.r(1036, 326, 20, 48, 102)
	p.r(1036, 326, 2, 48, 72)
	p.r(1036, 350, 20, 1, 100)
	p.r(1052, 334, 2, 12, 100)
	p.r(1040, 330, 5, 5, 85)
	p.r(1046, 336, 4, 4, 89)
	p.rr(1212, 320, 30, 56, 65)
	p.r(1214, 322, 26, 52, 87)
	p.r(1216, 326, 22, 28, 83)
	for i in range(3):
		for j in range(3):
			p.r(1218 + j * 7, 328 + i * 9, 5, 7, [85, 89, 91, 93, 94, 97, 90, 92, 86][i * 3 + j])
	p.r(1220, 358, 18, 8, 66)
	_glow(1227, 340, 28, 0.6)
	Cozy.rug(p, 1066, 440, 160, 70, 90, 102, 91, 0)
	Cozy.sofa(p, 1080, 454, 90, 97, 96, 98, 85, 91)
	Cozy.drop_shadow(p, 1184, 470, 40, 12)
	p.r(1184, 468, 40, 12, 70)
	p.r(1184, 468, 40, 2, 72)
	p.r(1198, 480, 4, 20, 107)
	Cozy.mug(p, 1190, 460, 91)
	Cozy.books(p, 1204, 468, 2, 1)
	Cozy.plant_big(p, 1240, 400, 0)
	_glows_for(p, 1030, 1130, 304, 6, 0)
	_glows_for(p, 1140, 1270, 304, 7, 3)
	var lamp := Cozy.floor_lamp(p, 1058, 420)
	_glow(lamp.x, lamp.y + 6, 34, 1.0)

static func exec_desk(p: Pen) -> void:
	p.r(1096, 102, 100, 24, 70)
	p.r(1096, 102, 100, 1, 65)
	p.r(1096, 102, 100, 5, 72)
	p.r(1096, 126, 100, 14, 68)
	p.r(1096, 126, 100, 1, 65)
	p.r(1096, 139, 100, 1, 65)
	p.r(1102, 130, 38, 8, 107)
	p.r(1150, 130, 38, 8, 107)
	p.r(1118, 133, 6, 2, 96)
	p.r(1166, 133, 6, 2, 96)
	p.rr(1104, 90, 20, 12, 65)
	p.r(1106, 92, 16, 8, 94)
	p.r(1106, 92, 16, 1, 35)
	Cozy.mug(p, 1170, 96, 85)
	p.r(1180, 94, 8, 6, 102)
	p.r(1181, 93, 6, 1, 89)

static func coffee_machine(p: Pen) -> void:
	p.rr(1122, 328, 26, 30, 65)
	p.r(1124, 330, 22, 26, 99)
	p.r(1124, 330, 22, 2, 100)
	p.r(1128, 334, 14, 8, 83)
	p.r(1130, 336, 4, 4, 91)
	p.r(1136, 336, 4, 4, 85)
	p.r(1130, 346, 10, 10, 66)
	p.r(1132, 350, 6, 6, 102)
	p.r(1132, 350, 6, 2, 85)

static func reception_counter(p: Pen) -> void:
	p.r(60, 390, 130, 26, 70)
	p.r(60, 390, 130, 1, 65)
	p.r(60, 390, 130, 5, 72)
	p.r(60, 416, 130, 14, 68)
	p.r(60, 416, 130, 1, 65)
	p.r(60, 429, 130, 1, 65)
	for x in [66, 98, 130]:
		p.r(x, 420, 28, 8, 107)
		p.r(x + 12, 423, 5, 2, 96)
	p.rr(150, 378, 22, 16, 65)
	p.r(152, 380, 18, 10, 91)
	p.r(152, 380, 18, 1, 90)
	Cozy.mug(p, 72, 384, 85)
	p.r(130, 386, 8, 4, 89)

static func meeting_table(p: Pen) -> void:
	p.rr(620, 450, 220, 52, 65)
	p.r(622, 452, 216, 48, 94)
	p.r(622, 452, 216, 6, 35)
	p.r(624, 460, 40, 1, 102)
	p.r(620, 502, 220, 6, 100)
	p.r(620, 507, 220, 1, 65)
	p.r(640, 508, 6, 20, 99)
	p.r(814, 508, 6, 20, 99)
	for i in range(5):
		p.r(640 + i * 34, 470, 12, 8, 102)
		p.r(640 + i * 34, 470, 12, 1, 101)
	p.disc(730, 482, 6, 85)
	p.disc(730, 481, 4, 89)
	Cozy.mug(p, 690, 462, 91)
	Cozy.mug(p, 790, 466, 97)

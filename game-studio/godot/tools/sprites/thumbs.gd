extends RefCounted
# T-029 news thumbnails: seven 32x32 illustrated scenes (palette v4), one per topic id. Same ids as before
# (topic_<id>), now 32x32 instead of 8x8. Drawn in code with Pen and converted to palette-letter rows.
const Kit = preload("res://tools/sprites/kit.gd")
const Pen = preload("res://scripts/v2/pen.gd")
const OUT := 65

static func definitions() -> Dictionary:
	var scenes := {"lai_suat": scene_lai_suat, "ty_gia": scene_ty_gia, "nguyen_lieu": scene_nguyen_lieu, "suc_mua": scene_suc_mua,
		"chung_khoan": scene_chung_khoan, "tin_dung": scene_tin_dung, "noi_bo": scene_noi_bo}
	var out := {}
	for topic in scenes:
		out["topic_" + topic] = {"size": Vector2i(32, 32), "frames": [Kit.paint(32, 32, scenes[topic])]}
	return out

# Vertical two-color dithered gradient background with rounded corners and a plum outline.
static func _backdrop(p: Pen, top: int, bottom: int, mid: int = 0) -> void:
	for y in range(32):
		var t := float(y) / 31.0
		for x in range(32):
			var threshold := float(Pen.BAYER[(y & 3) * 4 + (x & 3)]) / 16.0
			var use_bottom := t > threshold
			p.px(x, y, bottom if use_bottom else top)
	if mid > 0:
		for y in range(10, 22):
			for x in range(32):
				var threshold := float(Pen.BAYER[(y & 3) * 4 + (x & 3)]) / 16.0
				if 0.3 > threshold:
					p.px(x, y, mid)

static func _frame(p: Pen) -> void:
	p.frame(0, 0, 32, 32, OUT)
	for c in [Vector2i(0, 0), Vector2i(31, 0), Vector2i(0, 31), Vector2i(31, 31)]:
		p.img.set_pixel(c.x, c.y, Color(0, 0, 0, 0))
	p.px(1, 1, OUT)
	p.px(30, 1, OUT)
	p.px(1, 30, OUT)
	p.px(30, 30, OUT)

static func _line(p: Pen, x1: int, y1: int, x2: int, y2: int, color: int) -> void:
	var steps := maxi(absi(x2 - x1), absi(y2 - y1))
	for i in range(steps + 1):
		var t := float(i) / float(maxi(1, steps))
		p.px(x1 + int(round(float(x2 - x1) * t)), y1 + int(round(float(y2 - y1) * t)), color)

static func _sparkle(p: Pen, x: int, y: int, color: int = 102) -> void:
	p.px(x, y, color)
	p.px(x - 1, y, 89)
	p.px(x + 1, y, 89)
	p.px(x, y - 1, 89)
	p.px(x, y + 1, 89)

# Interest rate: a bank with a percent board and a falling arrow.
static func scene_lai_suat(p: Pen) -> void:
	_backdrop(p, 94, 35)
	p.disc(6, 7, 3, 89)
	p.disc(6, 7, 2, 102)
	# Bank building.
	p.r(3, 24, 26, 6, 101)
	p.r(3, 24, 26, 1, 102)
	p.rr(5, 15, 22, 9, OUT)
	p.r(6, 16, 20, 7, 102)
	p.r(8, 12, 16, 3, 101)
	p.r(11, 10, 10, 3, 101)
	p.r(11, 10, 10, 1, 102)
	for cx in [7, 12, 17, 22]:
		p.r(cx, 17, 3, 7, 101)
		p.r(cx, 17, 1, 7, 64)
		p.r(cx + 2, 17, 1, 7, 100)
	p.r(14, 20, 4, 4, 69)
	p.r(3, 29, 26, 1, OUT)
	# Percent board.
	p.rr(8, 2, 16, 9, OUT)
	p.r(9, 3, 14, 7, 89)
	p.r(9, 3, 14, 1, 95)
	p.disc(12, 5, 1, 112)
	p.disc(19, 8, 1, 112)
	_line(p, 18, 3, 13, 9, 112)
	# Falling arrow on the right.
	p.r(26, 4, 2, 7, 112)
	p.r(24, 10, 6, 1, 112)
	p.r(25, 11, 4, 1, 112)
	p.r(26, 12, 2, 1, 112)
	p.r(26, 4, 1, 7, 26)
	_frame(p)

# Exchange rate: two coins with swap arrows.
static func scene_ty_gia(p: Pen) -> void:
	_backdrop(p, 84, 91)
	_sparkle(p, 5, 6)
	_sparkle(p, 27, 24)
	# Left gold coin.
	p.disc(11, 17, 8, OUT)
	p.disc(11, 17, 7, 96)
	p.disc(11, 17, 5, 89)
	p.r(10, 13, 3, 9, 97)
	p.r(8, 15, 7, 2, 97)
	p.r(8, 19, 7, 2, 97)
	p.px(7, 13, 102)
	p.px(8, 12, 102)
	# Right silver coin.
	p.disc(22, 17, 8, OUT)
	p.disc(22, 17, 7, 101)
	p.disc(22, 17, 5, 102)
	p.r(19, 14, 7, 2, 99)
	p.r(19, 18, 7, 2, 99)
	p.r(21, 12, 2, 10, 99)
	p.px(18, 12, 64)
	# Swap arrows above and below.
	_line(p, 8, 5, 23, 5, 102)
	p.px(22, 4, 102)
	p.px(21, 3, 102)
	p.px(22, 6, 102)
	p.px(21, 7, 102)
	_line(p, 9, 29, 24, 29, 102)
	p.px(9, 28, 102)
	p.px(10, 27, 102)
	p.px(9, 30, 102)
	p.px(10, 31, 102)
	_frame(p)

# Materials: crates, a barrel and copper ingots in a warehouse.
static func scene_nguyen_lieu(p: Pen) -> void:
	_backdrop(p, 99, 100)
	for y in range(0, 20, 5):
		p.r(1, y, 30, 1, 66)
	p.r(1, 25, 30, 6, 69)
	p.r(1, 25, 30, 1, 71)
	for x in range(1, 31, 7):
		p.r(x, 26, 1, 5, 68)
	# Big crate.
	p.rr(2, 12, 13, 13, OUT)
	p.r(3, 13, 11, 11, 70)
	p.r(3, 13, 11, 1, 71)
	_line(p, 3, 13, 13, 23, 69)
	_line(p, 13, 13, 3, 23, 69)
	p.r(3, 13, 1, 11, 69)
	p.r(13, 13, 1, 11, 68)
	# Small crate on top.
	p.rr(5, 5, 9, 8, OUT)
	p.r(6, 6, 7, 6, 12)
	p.r(6, 6, 7, 1, 13)
	p.r(9, 6, 1, 6, 11)
	# Barrel.
	p.ellipse(22, 18, 6, 8, OUT)
	p.ellipse(22, 18, 5, 7, 69)
	p.r(17, 12, 11, 1, 68)
	p.r(17, 18, 11, 1, 99)
	p.r(17, 23, 11, 1, 68)
	p.r(18, 14, 1, 8, 70)
	p.r(21, 14, 1, 8, 71)
	# Copper ingots.
	p.rr(17, 25, 9, 4, OUT)
	p.r(18, 26, 7, 2, 70)
	p.r(18, 26, 7, 1, 71)
	p.rr(22, 21, 8, 4, OUT)
	p.r(23, 22, 6, 2, 98)
	p.r(23, 22, 6, 1, 97)
	_sparkle(p, 28, 8)
	_frame(p)

# Consumer spending: shopping bags with a heart and a price tag.
static func scene_suc_mua(p: Pen) -> void:
	_backdrop(p, 86, 82)
	p.disc(26, 6, 3, 89)
	p.disc(26, 6, 2, 102)
	# Back bag (teal).
	p.rr(14, 9, 14, 19, OUT)
	p.r(15, 10, 12, 17, 91)
	p.r(15, 10, 2, 17, 90)
	p.r(24, 10, 3, 17, 58)
	p.r(18, 6, 1, 4, OUT)
	p.r(23, 6, 1, 4, OUT)
	p.r(18, 6, 6, 1, OUT)
	p.r(18, 14, 6, 2, 102)
	# Front bag (pink).
	p.rr(3, 13, 14, 16, OUT)
	p.r(4, 14, 12, 14, 87)
	p.r(4, 14, 2, 14, 85)
	p.r(13, 14, 3, 14, 88)
	p.r(7, 10, 1, 4, OUT)
	p.r(12, 10, 1, 4, OUT)
	p.r(7, 10, 6, 1, OUT)
	# Heart.
	p.r(6, 18, 3, 2, 102)
	p.r(10, 18, 3, 2, 102)
	p.r(6, 20, 7, 2, 102)
	p.r(7, 22, 5, 1, 102)
	p.r(9, 23, 1, 1, 102)
	# Price tag and sparkles.
	p.r(20, 21, 8, 5, 89)
	p.r(20, 21, 8, 1, 95)
	p.px(21, 23, 112)
	p.px(23, 23, 112)
	p.px(25, 23, 112)
	_sparkle(p, 5, 5)
	_sparkle(p, 29, 17, 102)
	_frame(p)

# Stock market: candlesticks and a rising line on a dark board.
static func scene_chung_khoan(p: Pen) -> void:
	_backdrop(p, 83, 111)
	for y in [8, 14, 20]:
		p.r(2, y, 28, 1, 79)
	for x in range(5, 30, 6):
		p.r(x, 3, 1, 25, 79)
	var candles := [[3, 20, 27, 23, 0], [8, 17, 24, 19, 1], [13, 19, 25, 22, 0], [18, 11, 21, 14, 1], [23, 7, 18, 10, 1]]
	for c in candles:
		var up: bool = c[4] == 1
		var body: int = 75 if up else 112
		var edge: int = 76 if up else 26
		p.r(c[0] + 2, c[1] - 2, 1, c[2] - c[1] + 4, 102 if up else 101)
		p.r(c[0], c[1] + 1, 5, c[3] - c[1], OUT)
		p.r(c[0] + 1, c[1] + 2, 3, c[3] - c[1] - 2, body)
		p.r(c[0] + 1, c[1] + 2, 1, c[3] - c[1] - 2, edge)
	_line(p, 3, 25, 12, 20, 89)
	_line(p, 12, 20, 18, 14, 89)
	_line(p, 18, 14, 28, 5, 89)
	p.px(28, 5, 102)
	p.px(27, 4, 89)
	p.r(2, 29, 28, 1, 99)
	p.px(26, 28, 85)
	_frame(p)

# Credit and banking: cards with a chip and a coin stack.
static func scene_tin_dung(p: Pen) -> void:
	_backdrop(p, 84, 79)
	# Back card.
	p.rr(8, 4, 22, 14, OUT)
	p.r(9, 5, 20, 12, 87)
	p.r(9, 8, 20, 3, 88)
	# Front card.
	p.rr(2, 10, 22, 14, OUT)
	p.r(3, 11, 20, 12, 94)
	p.r(3, 11, 20, 1, 35)
	p.r(3, 14, 20, 3, 84)
	p.r(5, 18, 4, 3, 96)
	p.r(5, 18, 4, 1, 95)
	p.r(11, 19, 3, 1, 102)
	p.r(15, 19, 3, 1, 102)
	p.r(19, 19, 3, 1, 102)
	p.px(5, 12, 102)
	# Coin stack.
	for k in range(5):
		p.rr(19, 27 - k * 3, 11, 4, OUT)
		p.r(20, 28 - k * 3, 9, 2, 96 if k % 2 == 0 else 89)
	_sparkle(p, 4, 28)
	_sparkle(p, 27, 5)
	_frame(p)

# Insider: a figure in a hat at a door with light spilling out, holding a sealed envelope.
static func scene_noi_bo(p: Pen) -> void:
	_backdrop(p, 111, 103)
	for y in range(3, 27, 2):
		p.r(1, y, 30, 1, 83)
	p.r(1, 27, 30, 4, 66)
	# Door with a light spill.
	p.rr(18, 5, 11, 22, OUT)
	p.r(19, 6, 9, 20, 96)
	p.r(19, 6, 9, 3, 95)
	for y in range(27, 31):
		p.r(14 - (y - 27) * 2, y, 14 + (y - 27) * 3, 1, 97 if y % 2 == 0 else 98)
	p.r(19, 6, 2, 20, 69)
	p.glow(23, 16, 14, 1.0)
	# Figure.
	p.ellipse(10, 29, 6, 1, 4)
	p.rr(5, 15, 10, 14, 4)
	p.r(6, 16, 8, 12, 83)
	p.r(7, 16, 2, 12, 84)
	p.rr(6, 8, 8, 8, 4)
	p.r(7, 11, 6, 4, 104)
	p.px(8, 12, 103)
	p.px(11, 12, 103)
	p.r(3, 8, 14, 2, 4)
	p.r(5, 5, 10, 4, 4)
	p.r(5, 5, 10, 1, 83)
	# Envelope with a red seal.
	p.rr(13, 19, 9, 6, OUT)
	p.r(14, 20, 7, 4, 102)
	_line(p, 14, 20, 17, 22, 100)
	_line(p, 20, 20, 17, 22, 100)
	p.px(17, 22, 112)
	_frame(p)

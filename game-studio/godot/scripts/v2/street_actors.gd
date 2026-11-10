extends RefCounted
# T-029 cozy street actors (palette v4): pedestrians, cars, buses, motorbikes and bicycles drawn with Pen on a
# CanvasItem each frame. Rounded shapes with a plum outline, drop shadows, window highlights and visible passengers.
const Pen = preload("res://scripts/v2/pen.gd")
const OUT := 65
const SHADOW := 66
const RING := [Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -3), Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-3, -1), Vector2i(3, -1),
	Vector2i(-3, 0), Vector2i(3, 0), Vector2i(-3, 1), Vector2i(3, 1), Vector2i(-2, 2), Vector2i(2, 2), Vector2i(-1, 3), Vector2i(0, 3), Vector2i(1, 3)]
const SKIN_TONES := [106, 104, 32, 50, 31, 107]
const HAIR_TONES := [103, 108, 109, 110, 107, 66]

static func dark(color: int) -> int:
	Pen._build_maps()
	return Pen._shade_map[color]

static func lit(color: int) -> int:
	Pen._build_maps()
	return Pen._lit_map[color]

# ---- pedestrians ------------------------------------------------------------------------------

static func walker(p: Pen, w: Dictionary, elapsed: float) -> void:
	var x := roundi(w.x)
	var y := roundi(w.y)
	var moving: bool = absf(w.vx) > 0.0 or w.variety == "cross"
	var step := (int((elapsed + w.phase) * 4.0) % 2) if moving else 0
	var d := 1 if w.vx >= 0.0 else -1
	var skin: int = w.skin
	var shirt: int = w.shirt
	var pants: int = w.pants
	var hair: int = w.hair
	var style := int(w.phase * 3.0) % 4
	# Soft floor shadow.
	p.ellipse(x + 4, y, 6, 1, 99 if y <= 262 else SHADOW)
	# Legs and shoes.
	p.r(x + 1, y - 7, 3, 6 - step, pants)
	p.r(x + 4, y - 7, 3, 5 + step, pants)
	p.r(x + 4, y - 7, 1, 5 + step, dark(pants))
	p.r(x + 1, y - 1 - step, 3, 1, 103)
	p.r(x + 4, y - 2 + step, 3, 1, 103)
	p.px(x + 1, y - 1 - step, 102)
	# Torso: rounded with a lit left edge and a shaded bottom.
	p.rr(x, y - 15, 8, 9, shirt, dark(shirt))
	p.r(x + 1, y - 14, 3, 1, lit(shirt))
	p.r(x + 1, y - 7, 6, 1, dark(shirt))
	p.r(x - 1, y - 14 + step, 1, 5, shirt)
	p.r(x + 8, y - 14 + (1 - step), 1, 5, shirt)
	p.px(x - 1, y - 9 + step, skin)
	p.px(x + 8, y - 9 + (1 - step), skin)
	# Head: round with blush, small eyes and one of four hair styles.
	p.rr(x, y - 23, 8, 8, skin, dark(skin))
	p.r(x + 1, y - 22, 6, 2, hair)
	p.px(x + 1, y - 20, hair)
	p.px(x + 6, y - 20, hair)
	match style:
		1:
			p.r(x, y - 21, 1, 5, hair)
			p.r(x + 7, y - 21, 1, 5, hair)
		2:
			p.rr(x + 2, y - 26, 4, 4, hair)
			p.px(x + 3, y - 25, lit(hair))
		3:
			p.r(x, y - 22, 8, 2, shirt)
			p.r(x + (6 if d > 0 else -1), y - 21, 3, 1, dark(shirt))
	p.px(x + 2, y - 19, 103)
	p.px(x + 5, y - 19, 103)
	p.px(x + 1, y - 18, 105)
	p.px(x + 6, y - 18, 105)
	var hand := x + (9 if d > 0 else -4)
	match w.variety:
		"umbrella":
			var col: int = [85, 93, 94, 89][roundi(w.phase) % 4]
			p.ellipse(x + 4, y - 29, 9, 4, dark(col))
			p.ellipse(x + 4, y - 30, 8, 3, col)
			p.r(x - 3, y - 31, 4, 1, lit(col))
			for sx in range(x - 4, x + 13, 3):
				p.px(sx, y - 26, dark(col))
			p.r(x + 4, y - 26, 1, 12, 99)
			p.px(x + 4, y - 14, 100)
		"cup":
			p.r(hand, y - 12, 3, 4, 102)
			p.r(hand, y - 11, 3, 1, 85)
			p.px(hand + 1, y - 14 - (int(elapsed * 3.0 + w.phase) % 2), 101)
		"phone":
			p.r(x + (8 if d > 0 else -1), y - 18, 2, 4, 103)
			p.px(x + (8 if d > 0 else -1), y - 18, 91)
		"read":
			p.r(x + 7, y - 14, 8, 6, 102)
			p.r(x + 7, y - 14, 8, 1, 101)
			p.r(x + 9, y - 12, 4, 1, 99)
			p.r(x + 9, y - 10, 5, 1, 99)
		"queue":
			p.r(x - 4, y - 9, 4, 5, 70)
			p.r(x - 4, y - 9, 4, 1, 71)
			p.px(x - 3, y - 11, 99)
			p.px(x - 2, y - 11, 99)
		"cross":
			p.rr(x - 3, y - 14, 4, 8, 87, OUT)
			p.px(x - 2, y - 13, 85)

# ---- vehicles ---------------------------------------------------------------------------------

static func _vr(p: Pen, v: Dictionary, off: int, y: int, w: int, h: int, c: int) -> void:
	var x := roundi(v.x)
	if int(v.dir) > 0:
		p.r(x + off, y, w, h, c)
	else:
		p.r(x + int(v.len) - off - w, y, w, h, c)

static func _wheel(p: Pen, cx: int, cy: int, big: bool = true) -> void:
	p.disc(cx, cy, 3, 103)
	p.disc(cx, cy, 2, 99)
	p.px(cx, cy, 102)
	if big:
		p.px(cx - 1, cy - 1, 100)

static func _bike_wheel(p: Pen, cx: int, cy: int) -> void:
	for point in RING:
		p.px(cx + point.x, cy + point.y, 103)
	p.px(cx, cy, 100)
	p.px(cx - 1, cy, 99)
	p.px(cx + 1, cy, 99)

static func _head(p: Pen, x: int, y: int, skin: int, hair: int) -> void:
	p.r(x, y, 4, 3, skin)
	p.r(x, y - 1, 4, 2, hair)
	p.px(x + 1, y + 1, 103)

static func vehicle(p: Pen, v: Dictionary, player_texture: Texture2D, elapsed: float) -> void:
	var x := roundi(v.x)
	var y: int = v.bottom
	var dir: int = v.dir
	var base: int = v.color
	var shade: int = v.shade
	var light: int = v.light
	var length: int = v.len
	var rider_index: int = int(v.rider)
	var skin: int = SKIN_TONES[rider_index % SKIN_TONES.size()]
	var hair: int = HAIR_TONES[(rider_index + 2) % HAIR_TONES.size()]
	var is_player := v.has("player")
	p.ellipse(x + length / 2, y, length / 2 + 1, 2, SHADOW)
	match v.variety:
		"car":
			p.rr(x, y - 11, length, 9, base, OUT)
			p.r(x + 2, y - 10, length - 4, 1, light)
			p.r(x + 1, y - 4, length - 2, 2, shade)
			p.rr(x + 7, y - 18, 16, 8, base, OUT)
			p.r(x + 9, y - 17, 12, 1, light)
			p.r(x + 9, y - 16, 5, 4, 34)
			p.r(x + 15, y - 16, 6, 4, 34)
			p.px(x + 9, y - 16, 102)
			p.px(x + 10, y - 15, 102)
			p.px(x + 15, y - 16, 102)
			p.px(x + 16, y - 15, 102)
			# Passengers: the driver in the front window, the player in the back window of the player's taxi.
			var front_window := x + (16 if dir > 0 else 9)
			var back_window := x + (9 if dir > 0 else 16)
			_head(p, front_window + 1, y - 15, skin, hair)
			if is_player and player_texture != null:
				p.item.draw_texture_rect_region(player_texture, Rect2(back_window, y - 16, 5, 4), Rect2(5, 6, 5, 4))
			else:
				_head(p, back_window + 1, y - 15, SKIN_TONES[(rider_index + 3) % SKIN_TONES.size()], HAIR_TONES[(rider_index + 1) % HAIR_TONES.size()])
			if is_player:
				p.r(x + length / 2 - 3, y - 20, 6, 2, 89)
				p.r(x + length / 2 - 3, y - 20, 6, 1, 102)
			_vr(p, v, length - 3, y - 9, 3, 3, 95)
			_vr(p, v, 0, y - 9, 2, 3, 112)
			_vr(p, v, length - 2, y - 5, 2, 2, 71)
			p.r(x + 12, y - 8, 6, 1, shade)
			_wheel(p, x + 7, y - 3)
			_wheel(p, x + length - 8, y - 3)
		"bus":
			p.rr(x, y - 21, length, 18, 91, OUT)
			p.r(x + 2, y - 20, length - 4, 1, 90)
			p.r(x + 1, y - 9, length - 2, 3, 102)
			p.r(x + 1, y - 6, length - 2, 2, 78)
			p.r(x + 1, y - 4, length - 2, 1, 73)
			p.r(x + 18, y - 24, 16, 3, 101)
			p.r(x + 18, y - 24, 16, 1, 102)
			p.r(x + 17, y - 24, 1, 3, OUT)
			p.r(x + 34, y - 24, 1, 3, OUT)
			var window_index := 0
			for wx in range(x + 4, x + length - 14, 9):
				p.r(wx, y - 19, 7, 8, 34)
				p.r(wx, y - 19, 7, 1, 35)
				var seat := (window_index * 7 + rider_index) % 4
				if is_player and window_index == 1 and player_texture != null:
					p.item.draw_texture_rect_region(player_texture, Rect2(wx, y - 19, 7, 7), Rect2(4, 4, 7, 7))
				elif seat != 3:
					var tone: int = SKIN_TONES[(window_index + seat) % SKIN_TONES.size()]
					var cut: int = HAIR_TONES[(window_index * 2 + seat) % HAIR_TONES.size()]
					var shirt_c: int = [85, 94, 89, 93][(window_index + seat) % 4]
					p.r(wx + 2, y - 15, 3, 3, tone)
					p.r(wx + 2, y - 16, 3, 1, cut)
					p.r(wx + 1, y - 12, 5, 1, shirt_c)
				p.px(wx, y - 19, 102)
				p.px(wx + 1, y - 18, 102)
				window_index += 1
			# Door glass and driver at the front, destination sign, lights.
			var front := x + (length - 11 if dir > 0 else 2)
			p.r(front, y - 19, 9, 11, 34)
			p.r(front, y - 19, 9, 1, 35)
			p.r(front + (5 if dir > 0 else 3), y - 19, 1, 11, 91)
			_head(p, front + (1 if dir > 0 else 5), y - 15, SKIN_TONES[(rider_index + 1) % SKIN_TONES.size()], HAIR_TONES[rider_index % HAIR_TONES.size()])
			p.r(x + (length - 12 if dir > 0 else 3), y - 21, 9, 2, 97)
			p.px(x + (length - 11 if dir > 0 else 4), y - 21, 95)
			_vr(p, v, length - 3, y - 7, 3, 3, 95)
			_vr(p, v, 0, y - 7, 2, 3, 112)
			_wheel(p, x + 9, y - 3)
			_wheel(p, x + length - 12, y - 3)
		"moto":
			_wheel(p, x + 3, y - 3)
			_wheel(p, x + 11, y - 3)
			p.rr(x + 3, y - 9, 9, 4, base, OUT)
			p.r(x + 4, y - 8, 7, 1, light)
			p.r(x + 4, y - 6, 7, 1, shade)
			_vr(p, v, length - 4, y - 12, 2, 4, 99)
			_vr(p, v, length - 3, y - 12, 3, 1, 100)
			_vr(p, v, length - 1, y - 9, 2, 2, 95)
			if is_player and player_texture != null:
				p.item.draw_texture_rect_region(player_texture, Rect2(x + 1, y - 27, 12, 17), Rect2(2, 1, 12, 17))
			else:
				var shirt: int = [85, 94, 89, 93, 97, 91][rider_index % 6]
				p.rr(x + 4, y - 18, 6, 9, shirt, dark(shirt))
				p.r(x + 5, y - 17, 2, 1, lit(shirt))
				p.r(x + 5, y - 10, 2, 4, 4)
				p.ellipse(x + 7, y - 22, 4, 4, [87, 97, 91, 94][rider_index % 4])
				p.r(x + (7 if dir > 0 else 3), y - 22, 4, 2, 35)
				p.px(x + 5, y - 24, 102)
				p.r(x + (9 if dir > 0 else 3), y - 15, 3, 2, shirt)
		"bike":
			_bike_wheel(p, x + 2, y - 3)
			_bike_wheel(p, x + 10, y - 3)
			p.r(x + 3, y - 8, 7, 1, base)
			p.r(x + 6, y - 8, 1, 5, base)
			p.r(x + 9, y - 9, 1, 5, light)
			_vr(p, v, 9, y - 11, 3, 1, 100)
			var shirt2: int = [85, 94, 89, 93, 97, 91][rider_index % 6]
			p.rr(x + 3, y - 15, 5, 8, shirt2, dark(shirt2))
			p.r(x + 4, y - 14, 2, 1, lit(shirt2))
			p.rr(x + 3, y - 20, 5, 5, skin, dark(skin))
			p.r(x + 3, y - 20, 5, 2, hair)
			p.px(x + 4, y - 17, 103)
			var step := int(elapsed * 6.0) % 2
			p.r(x + 5, y - 8, 2, 3 - step, 4)
			_vr(p, v, 10, y - 11, 3, 3, 74)
			_vr(p, v, 10, y - 12, 1, 1, 85)
			_vr(p, v, 12, y - 12, 1, 1, 89)

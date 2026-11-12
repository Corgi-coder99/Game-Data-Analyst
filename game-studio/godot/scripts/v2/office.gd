extends Node2D
const FontTheme = preload("res://scripts/v2/theme_v2.gd")  # T-039: loading it installs the UI font
# T-022: a multi-room floor plan (1280x560 world) seen through a 640x360 camera.
# The camera starts on the Data Analytics room (the player's desk); the minimap or Tab pans to other rooms.
signal seated
signal dialog_closed
signal desk_clicked
const Palette = preload("res://scripts/v2/palette.gd")
const Library = preload("res://scripts/v2/sprite_lib.gd")
const Pen = preload("res://scripts/v2/pen.gd")
const Art = preload("res://scripts/v2/office_art.gd")
const DESK_POS := Vector2i(208, 192)
const SEAT_POS := Vector2i(224, 176)
const DESK_RECT := Rect2(208, 192, 48, 24)
const MINIMAP_RECT := Rect2(508, 4, 130, 58)
const WALK_TIMES := [0.16, 0.12, 0.16, 0.12]
const TYPE_TIMES := [0.12, 0.16]
const PAN_SPEED := 1200.0
var lib := Library.new()
var phase := "sang"
var clock_hour := 8
var clock_minute := 0
var windows: Array = []
var colleagues: Array = []
var idlers: Array = []
var walkers: Array = []
var name_tags: Array = []
var player: Sprite2D
var boss: Sprite2D
var exec_boss: Sprite2D
var door: Sprite2D
var phone_bubble: Sprite2D
var world: Node2D
var fx: Node2D
var minimap: Node2D
var dialog: Panel
var speaker_label: Label
var dialog_text: RichTextLabel
var arrival_active := false
var player_seated := false
var travel := 0.0
var elapsed := 0.0
var desk_button: Button
var hint_label: Label
var hint_enabled := true
var camera := Vector2i.ZERO
var pan_target := Vector2i.ZERO
var panning := false
var current_room := "data"
var window_textures: Dictionary = {}
var clock_sprite: Sprite2D
var coffee_user: Sprite2D
var phone_user: Sprite2D
var floor_image: Image

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	floor_image = Pen.canvas(Art.WORLD.x, Art.WORLD.y)
	Art.draw_world(Pen.new(floor_image))
	var background := Sprite2D.new()
	background.name = "Floorplan"
	background.texture = Pen.texture(floor_image)
	background.centered = false
	world.add_child(background)
	for key in ["sang", "trua", "chieu"]:
		var window_image := Pen.canvas(32, 32)
		Art.window_city(Pen.new(window_image), 0, 0, 32, 32, key)
		window_textures[key] = Pen.texture(window_image)
	for x in [12, 60]:
		var window := _plain_sprite(window_textures["sang"], Vector2i(x, 16))
		window.name = "Window"
		windows.append(window)
	clock_sprite = place("clock", Vector2i(306, 20))
	door = place("door", Vector2i(346, 20))
	place("plant", Vector2i(8, 62))
	place("plant", Vector2i(372, 204), 1)
	place("plant", Vector2i(404, 60))
	place("cabinet", Vector2i(640, 28))
	# Data Analytics: back row first so the front row overlaps it.
	_desk("khoi", Vector2i(40, 100), "Khoi")
	_desk("mai", Vector2i(208, 100), "Mai")
	_desk("tu", Vector2i(40, 192), "Tu")
	player = _desk("player", DESK_POS, "You")
	# Finance, Marketing and Sales desks.
	_desk("rin", Vector2i(436, 112), "Rin")
	_desk("bao", Vector2i(560, 112), "Bao")
	_desk("linh", Vector2i(740, 112), "Linh")
	_desk("dat", Vector2i(864, 112), "Dat")
	phone_user = _desk("an", Vector2i(262, 392), "An", true)
	_desk("vy", Vector2i(346, 392), "Vy")
	_desk("sam", Vector2i(430, 392), "Sam")
	# Executive office: Hanh behind the big desk (the desk overlay hides her legs).
	exec_boss = place("hanh", Vector2i(1136, 86))
	_overlay(Rect2i(1090, 84, 116, 60), Art.exec_desk)
	# Reception: the receptionist behind the counter.
	var receptionist := place("ngoc", Vector2i(104, 372))
	idlers.append({"node": receptionist, "id": "ngoc", "offset": 0.7})
	_overlay(Rect2i(56, 376, 136, 56), Art.reception_counter)
	# Meeting room: two attendees behind the glass table.
	for spot in [Vector2i(668, 432), Vector2i(776, 432)]:
		place("chair", spot)
	var attendee_a := place("lead", Vector2i(668, 430))
	var attendee_b := place("intern", Vector2i(776, 430))
	idlers.append({"node": attendee_a, "id": "lead", "offset": 0.2})
	idlers.append({"node": attendee_b, "id": "intern", "offset": 1.4})
	_overlay(Rect2i(616, 446, 228, 64), Art.meeting_table)
	for spot in [Vector2i(700, 500), Vector2i(744, 500)]:
		place("chair", spot)
	# Server room technician and break room coffee.
	var tech := place("ops", Vector2i(930, 430))
	idlers.append({"node": tech, "id": "ops", "offset": 2.1})
	coffee_user = place("pat", Vector2i(1112, 388))
	idlers.append({"node": coffee_user, "id": "pat", "offset": 0.4})
	# People walking the corridor.
	for entry in [["kai", 300.0, 258, 34.0], ["mei", 520.0, 266, -30.0], ["linh", 900.0, 262, -28.0], ["cat", 700.0, 282, 18.0]]:
		var walker := place(entry[0], Vector2i(int(entry[1]), entry[2]))
		walkers.append({"node": walker, "id": entry[0], "x": entry[1], "y": entry[2], "vx": entry[3]})
	phone_bubble = place("bubble", Vector2i(272, 376))
	boss = place("hanh", Vector2i(350, 38))
	boss.visible = false
	fx = Node2D.new()
	fx.name = "Fx"
	world.add_child(fx)
	fx.draw.connect(_draw_fx)
	# Screen space: desk button, hint, minimap, dialog.
	desk_button = Button.new()
	desk_button.name = "DeskButton"
	desk_button.position = DESK_RECT.position
	desk_button.size = DESK_RECT.size
	desk_button.flat = true
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		desk_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	desk_button.focus_mode = Control.FOCUS_NONE
	desk_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	desk_button.pressed.connect(func(): desk_clicked.emit())
	add_child(desk_button)
	hint_label = Label.new()
	hint_label.name = "Hint"
	hint_label.text = "Enter: open your desk"
	hint_label.position = Vector2i(262, 198)
	hint_label.add_theme_font_size_override("font_size", 8)
	hint_label.add_theme_color_override("font_color", Palette.color(52))
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Palette.color(1)
	hint_style.content_margin_left = 3
	hint_style.content_margin_right = 3
	hint_style.content_margin_top = 1
	hint_style.content_margin_bottom = 1
	hint_label.add_theme_stylebox_override("normal", hint_style)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_label)
	minimap = Node2D.new()
	minimap.name = "Minimap"
	minimap.position = MINIMAP_RECT.position
	add_child(minimap)
	minimap.draw.connect(_draw_minimap)
	_build_dialog()
	set_phase("sang")
	_apply_camera()
	play_arrival()

func _plain_sprite(texture: Texture2D, point: Vector2i) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = texture
	node.centered = false
	node.position = point
	world.add_child(node)
	return node

func place(id: String, point: Vector2i, frame_index: int = 0) -> Sprite2D:
	var node := lib.sprite(id, frame_index)
	node.position = point
	node.name = id.capitalize()
	world.add_child(node)
	return node

# One workstation: chair, person, then the desk on top so it hides the legs.
func _desk(id: String, point: Vector2i, label: String, phone: bool = false) -> Sprite2D:
	place("chair", point + Vector2i(16, 8))
	var person := place(id, point + Vector2i(16, -16), 6)
	place("desk", point, 1)
	name_tags.append({"text": label, "pos": point + Vector2i(0, 28), "ink": 8 if id == "player" else 7})
	if id != "player" and not phone:
		colleagues.append({"node": person, "id": id, "offset": float(colleagues.size()) * 0.53})
	elif phone:
		idlers.append({"node": person, "id": id, "offset": 1.1})
	return person

# A copy of a region of the floor plan drawn above the people (counters, tables, desks).
func _overlay(region: Rect2i, drawer: Callable) -> void:
	var image := Pen.canvas(region.size.x, region.size.y)
	var pen := Pen.new(image)
	pen.origin = -region.position
	drawer.call(pen)
	var sprite := _plain_sprite(Pen.texture(image), region.position)
	sprite.name = "Overlay"

func _build_dialog() -> void:
	dialog = Panel.new()
	dialog.name = "Dialog"
	dialog.position = Vector2i(24, 272)
	dialog.size = Vector2i(592, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(2)
	style.border_color = Palette.color(5)
	style.set_border_width_all(1)
	style.anti_aliasing = false
	dialog.add_theme_stylebox_override("panel", style)
	add_child(dialog)
	speaker_label = Label.new()
	speaker_label.position = Vector2i(12, 4)
	speaker_label.size = Vector2i(568, 16)
	speaker_label.add_theme_font_size_override("font_size", 12)
	speaker_label.add_theme_color_override("font_color", Palette.color(8))
	speaker_label.clip_text = true
	dialog.add_child(speaker_label)
	dialog_text = RichTextLabel.new()
	dialog_text.position = Vector2i(12, 28)
	dialog_text.size = Vector2i(568, 44)
	dialog_text.add_theme_font_size_override("normal_font_size", 12)
	dialog_text.add_theme_color_override("default_color", Palette.color(7))
	dialog_text.bbcode_enabled = false
	dialog_text.scroll_active = true
	dialog.add_child(dialog_text)
	dialog.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_dialog())
	dialog_text.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_dialog())
	dialog.hide()

# ---- camera --------------------------------------------------------------

func room_camera(key: String) -> Vector2i:
	if key == "data":
		return Vector2i.ZERO
	var r: Rect2i = Art.rect_of(key)
	var target := Vector2i(r.position.x + r.size.x / 2 - 320, r.position.y + r.size.y / 2 - 150)
	return Vector2i(clampi(target.x, 0, Art.WORLD.x - 640), clampi(target.y, 0, Art.WORLD.y - 360))

func show_room(key: String) -> bool:
	if not Art.ROOMS.has(key):
		return false
	current_room = key
	camera = room_camera(key)
	pan_target = camera
	panning = false
	_apply_camera()
	return true

func pan_to(key: String) -> bool:
	if not Art.ROOMS.has(key):
		return false
	current_room = key
	pan_target = room_camera(key)
	panning = pan_target != camera
	return true

func _apply_camera() -> void:
	world.position = Vector2(-camera.x, -camera.y)
	desk_button.position = Vector2(DESK_POS - camera)
	desk_button.visible = Rect2(0, 0, 640, 360).encloses(Rect2(desk_button.position, desk_button.size))
	if hint_label != null:
		hint_label.position = Vector2(Vector2i(262, 198) - camera)
		hint_label.visible = hint_enabled and camera == Vector2i.ZERO
	if minimap != null:
		minimap.queue_redraw()

func next_room() -> void:
	var index := Art.ROOM_ORDER.find(current_room)
	pan_to(Art.ROOM_ORDER[(index + 1) % Art.ROOM_ORDER.size()])

func room_at_minimap(point: Vector2) -> String:
	var local := point - MINIMAP_RECT.position - Vector2(1, 1)
	for key in Art.ROOM_ORDER:
		var r: Rect2i = Art.rect_of(key)
		if Rect2(Vector2(r.position) / 10.0, Vector2(r.size) / 10.0).has_point(local):
			return key
	return ""

# ---- state ---------------------------------------------------------------

func set_phase(value: String) -> bool:
	if not value in ["sang", "trua", "chieu"]:
		return false
	phase = value
	for window in windows:
		window.texture = window_textures[phase]
	queue_redraw()
	if fx != null:
		fx.queue_redraw()
	return true

func set_clock(hour: int, minute: int) -> void:
	clock_hour = posmod(hour, 24)
	clock_minute = posmod(minute, 60)
	if fx != null:
		fx.queue_redraw()

func play_arrival() -> void:
	if player == null:
		return
	player.position = Vector2i(-16, 264)
	player_seated = false
	arrival_active = true
	travel = 0.0

func seat_now() -> void:
	# Skips the arrival animation (later days start seated, Esc skips on day one).
	if player == null:
		return
	var was_arriving := arrival_active
	arrival_active = false
	player.position = SEAT_POS
	player.texture = lib.frame("player", 6)
	if not player_seated:
		player_seated = true
		if was_arriving:
			seated.emit()

func play_boss_appears(line: String) -> void:
	door.texture = lib.frame("door", 1)
	boss.show()
	exec_boss.hide()
	show_room("data")
	show_dialog("Ms. Hanh", line)

func show_dialog(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	dialog_text.text = text
	dialog_text.scroll_to_line(0)
	dialog.show()
	desk_button.disabled = true

func hide_dialog() -> void:
	if not dialog.visible:
		return
	dialog.hide()
	desk_button.disabled = false
	boss.hide()
	exec_boss.show()
	door.texture = lib.frame("door", 0)
	dialog_closed.emit()

func set_hint_visible(value: bool) -> void:
	hint_enabled = value
	if hint_label != null:
		hint_label.visible = value and camera == Vector2i.ZERO

func _unhandled_input(event: InputEvent) -> void:
	var confirm: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)
	if confirm:
		if dialog.visible:
			hide_dialog()
		else:
			desk_clicked.emit()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		next_room()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and MINIMAP_RECT.has_point(event.position):
		var key := room_at_minimap(event.position)
		if key != "":
			pan_to(key)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	advance(delta)

func animation_frame(time: float, durations: Array) -> int:
	var total := 0.0
	for duration in durations:
		total += duration
	var cursor := fposmod(time, total)
	for i in range(durations.size()):
		cursor -= durations[i]
		if cursor < 0:
			return i
	return 0

func advance(delta: float) -> void:
	elapsed += delta
	for colleague in colleagues:
		var time: float = elapsed + colleague.offset
		var frame_index := 6 + animation_frame(time, TYPE_TIMES)
		if fposmod(time, 4.0) > 3.6:
			frame_index = 1 if fposmod(time, 4.0) > 3.84 else 0
		colleague.node.texture = lib.frame(colleague.id, frame_index)
	for idler in idlers:
		var blink: float = fposmod(elapsed + idler.offset * 1.7, 3.6)
		idler.node.texture = lib.frame(idler.id, 1 if blink > 3.45 else 0)
	for walker in walkers:
		walker.x += walker.vx * delta
		if walker.x > Art.WORLD.x + 16:
			walker.x = -16.0
		elif walker.x < -16:
			walker.x = float(Art.WORLD.x + 16)
		walker.node.position = Vector2i(roundi(walker.x), walker.y)
		walker.node.flip_h = walker.vx < 0
		walker.node.texture = lib.frame(walker.id, 2 + animation_frame(elapsed + walker.x * 0.01, WALK_TIMES))
	phone_bubble.visible = fposmod(elapsed, 1.6) < 0.9
	if panning:
		var step := int(PAN_SPEED * delta) + 1
		var difference := pan_target - camera
		camera = Vector2i(camera.x + clampi(difference.x, -step, step), camera.y + clampi(difference.y, -step, step))
		if camera == pan_target:
			panning = false
		_apply_camera()
	if arrival_active:
		travel += delta * 80.0
		var horizontal: float = float(SEAT_POS.x + 16)
		var vertical: float = float(264 - SEAT_POS.y)
		if travel < horizontal:
			player.position = Vector2i(roundi(-16 + travel), 264)
		elif travel < horizontal + vertical:
			player.position = Vector2i(SEAT_POS.x, roundi(264 - (travel - horizontal)))
		else:
			player.position = SEAT_POS
			arrival_active = false
			player_seated = true
			seated.emit()
		player.texture = lib.frame("player", 2 + animation_frame(elapsed, WALK_TIMES) if arrival_active else 6)
	elif player_seated:
		player.texture = lib.frame("player", 6 + animation_frame(elapsed, TYPE_TIMES))
	if fx != null:
		fx.queue_redraw()
	if minimap != null and int(elapsed * 2.0) != int((elapsed - delta) * 2.0):
		minimap.queue_redraw()

# ---- animated overlays ---------------------------------------------------

func _hash(a: int) -> int:
	return ((a * 1103515245 + 12345) >> 8) & 0xffff

func _draw_fx() -> void:
	var p := Pen.new(fx)
	# Room name plates sit on the cornice of every room.
	for key in Art.ROOM_ORDER:
		var t: Dictionary = Art.ROOMS[key]
		var r: Rect2i = t.rect
		var width := Pen.text_width(t.title, 8) + 10
		p.r(r.position.x + 8, r.position.y + 1, width, 12, 1)
		p.frame(r.position.x + 8, r.position.y + 1, width, 12, t.accent)
		p.text(t.title, r.position.x + 13, r.position.y + 3, t.accent)
	for tag in name_tags:
		var width := Pen.text_width(tag.text, 8)
		p.r(tag.pos.x + 24 - width / 2 - 2, tag.pos.y - 1, width + 4, 10, 1)
		p.text(tag.text, tag.pos.x + 24 - width / 2, tag.pos.y, tag.ink)
	p.r(1112, 154, 76, 11, 1)
	p.text("MS. HANH", 1122, 155, 28)
	p.text("ENTRANCE >", 8, 262, 52)
	# Dashboard cursor.
	var cursor := 118 + int(fposmod(elapsed * 22.0, 172.0))
	p.r(cursor, 22, 1, 30, 53)
	# Clock hands (whole-pixel lines, no rotation).
	var center := Vector2(clock_sprite.position.x + 8, clock_sprite.position.y + 8)
	var minute_angle := float(clock_minute) * TAU / 60.0 - PI / 2
	var hour_angle := float(clock_hour % 12 + clock_minute / 60.0) * TAU / 12.0 - PI / 2
	fx.draw_line(center, (center + Vector2(cos(minute_angle), sin(minute_angle)) * 5).round(), Palette.color(3), 1, false)
	fx.draw_line(center, (center + Vector2(cos(hour_angle), sin(hour_angle)) * 3).round(), Palette.color(3), 1, false)
	# Server rack LEDs blink in pseudo-random patterns.
	var slot := int(elapsed * 4.0)
	for rack in range(4):
		for row in range(8):
			for led in range(3):
				var state := _hash(slot * 31 + rack * 97 + row * 13 + led * 7 + (row * rack)) % 6
				var color: int = [48, 48, 51, 52, 56, 2][state]
				p.r(870 + rack * 34 + 6 + led * 5 + (12 if led == 2 else 0), 364 + row * 8 + 3, 3, 2, color)
	# Coffee steam above the machine.
	for i in range(3):
		var rise := fposmod(elapsed * 10.0 + i * 5.0, 15.0)
		p.r(1130 + i * 4 + int(sin(elapsed * 2.0 + i) * 1.5), 326 - int(rise), 2, 2, 7 if rise < 9.0 else 6)

func _draw_minimap() -> void:
	var p := Pen.new(minimap)
	p.r(0, 0, int(MINIMAP_RECT.size.x), int(MINIMAP_RECT.size.y), 1)
	p.frame(0, 0, int(MINIMAP_RECT.size.x), int(MINIMAP_RECT.size.y), 5)
	for key in Art.ROOM_ORDER:
		var t: Dictionary = Art.ROOMS[key]
		var r: Rect2i = t.rect
		var rx := 1 + r.position.x / 10
		var ry := 1 + r.position.y / 10
		var rw := r.size.x / 10 - 1
		var rh := r.size.y / 10 - 1
		p.r(rx, ry, rw, rh, t.wall[0] if key != "server" else 4)
		p.frame(rx, ry, rw, rh, 1 if key != current_room else 52)
		p.text(t.short, rx + 2, ry + rh / 2 - 4, 64)
	var view := Rect2i(1 + camera.x / 10, 1 + camera.y / 10, 64, 36)
	p.frame(view.position.x, view.position.y, view.size.x, view.size.y, 52)
	if player != null:
		var blip := Vector2i(1 + roundi((player.position.x + 8) / 10.0), 1 + roundi((player.position.y + 12) / 10.0))
		if int(elapsed * 2.0) % 2 == 0:
			p.r(blip.x - 1, blip.y - 1, 3, 3, 64)

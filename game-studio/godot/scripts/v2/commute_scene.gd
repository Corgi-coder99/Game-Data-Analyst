extends Node2D
# The morning commute (about 7 s, skippable): a city street with parallax skyline, shops, traffic with a
# simple traffic light, pedestrians, and the player walking to the company tower.
# Mood cues use only public values: the day number and the public trust value.
signal finished
signal shop_requested(shop_ids: Array, storefront: String)
signal prompt_opened(stop_type: String)
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Pen = preload("res://scripts/v2/pen.gd")
const Library = preload("res://scripts/v2/sprite_lib.gd")
const W := 640
const H := 360
const DURATION := 7.0
const SIDEWALK_Y := 232
const ROAD_Y := 266
const LANE_UP := 292      # bottom edge of vehicles driving left (far lane)
const LANE_DOWN := 324    # bottom edge of vehicles driving right (near lane)
const FEET_Y := 258
const FRONT_Y := 290
const DOOR_X := 566
const STOP_RIGHT := 246.0 # front edge limit for vehicles driving right
const STOP_LEFT := 282.0  # front edge limit for vehicles driving left
const WALK_TIMES := [0.16, 0.12, 0.16, 0.12]
const SKY_BANDS := {
	"clear_dawn": [33, 33, 34, 34, 35, 36, 45],
	"clear": [33, 33, 34, 34, 35, 35, 35],
	"overcast": [40, 40, 41, 41, 6, 6, 7],
	"gloom": [4, 4, 5, 5, 40, 40, 41]}
const SHIRTS := [51, 53, 52, 54, 56, 55, 7, 47, 38, 36]
const PANTS := [3, 4, 17, 58, 10, 2, 9]
const HAIRS := [1, 9, 10, 27, 1, 2]
const SKINS := [32, 31, 50, 49, 32]
const SHOP_NAMES := ["MOONBEAN CAFE", "SIZZLE NOODLES", "CORNER MART", "HARBOR BANK", "DAILY NEWS", "MOTH BOOKS"]
const HEADLINES := ["FRESH START", "FRESH START", "MARKETS EDGY", "MARKETS EDGY", "SHOPS CLOSING", "QUEUES GROW", "QUEUES GROW", "CRISIS DEEPENS", "CRISIS DEEPENS", "CRISIS DEEPENS"]
var lib := Library.new()
var day := 1
var trust := 50
var crisis := 0
var elapsed := 0.0
var done := false
var skipped := false
var frames_run := 0
var rng := RandomNumberGenerator.new()
var built := false
var sky_tex: ImageTexture
var cloud_tex: ImageTexture
var layer_tex: Array = []
var street_tex: ImageTexture
var front_tex: ImageTexture
var vehicles: Array = []
var walkers: Array = []
var crossers: Array = []
var signs: Array = []
var light_offset := 0.0
var player_x := -16.0
var player_visible := true
var door_open := false
var enter_time := -1.0
var lit_shop_windows: Array = []
# T-026: interactive daily commute. The player moves with the chosen transport, pauses at shop doors
# and at a red light. Without `interactive` the scene behaves exactly as in T-022.
const STOREFRONTS := ["cafe", "noodle", "mart", "bank", "news", "books"]
const SHOP_STOPS := {"cafe": 30, "noodle": 110, "mart": 190, "bank": 282, "news": 366, "books": 450}
const SHOP_TOP := 114
const WALK_SPEED := 150.0
const START_X := 6.0
const WALK_LIGHT_X := 232
const VEHICLE_LEN := {"walk": 0, "bus": 56, "moto": 14, "taxi": 30}
var interactive := false
var vitals: RefCounted
var mode := "walk"
var paused := ""
# T-027: the street is free choice. phase: street (idle) | to_shop | shopping | light | waiting | to_work.
var phase := "street"
var current_stop: Dictionary = {}
var target_shop := ""
var hover_index := -1
var selected_index := -1    # -1 is the Go to work button (the default), 0..5 a storefront
var visits: Array = []
var go_button: Button
var tooltip_panel: Panel
var tooltip_label: Label
var facing := 1
var wait_timer := 0.0
var toast_time := -1.0
var fast_forward := false
var hurrying := false
var daily_strings: Dictionary = {}
var ui: Control
var prompt_panel: Panel
var prompt_label: Label
var prompt_primary: Button
var prompt_secondary: Button
var toast_panel: Panel
var toast_label: Label
var player_vehicle: Dictionary = {}
var results: Array = []
var emote_name := ""
var emote_time := 0.0

func setup(day_number: int, trust_value: int = 50) -> void:
	day = clampi(day_number, 1, 30)
	trust = trust_value
	crisis = 0
	if day >= 8 or trust <= 20:
		crisis = 2
	elif day >= 5 or trust <= 35:
		crisis = 1
	rng.seed = 7919 * day + 13
	light_offset = rng.randf_range(0.0, 7.0)
	_build_art()
	_build_actors()
	built = true
	queue_redraw()

# Starts the interactive commute. `vitals_module` supplies the seeded red light and applies every effect.
func setup_interactive(day_number: int, trust_value: int, vitals_module: RefCounted, transport_id: String) -> void:
	interactive = true
	vitals = vitals_module
	mode = transport_id
	daily_strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json")).daily
	setup(day_number, trust_value)
	var length: int = VEHICLE_LEN.get(mode, 0)
	if length > 0:
		vehicles = vehicles.filter(func(v): return v.dir < 0)
	player_visible = true
	player_x = START_X
	phase = "street"
	selected_index = -1
	_build_prompt()

func _build_prompt() -> void:
	ui = Control.new()
	ui.size = Vector2(W, H)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = WindowTheme.create()
	add_child(ui)
	prompt_panel = Panel.new()
	prompt_panel.size = Vector2(176, 52)
	prompt_panel.add_theme_stylebox_override("panel", WindowTheme.box(2))
	prompt_panel.hide()
	ui.add_child(prompt_panel)
	prompt_label = _prompt_text(prompt_panel, Rect2(6, 4, 164, 14))
	prompt_primary = _prompt_button(prompt_panel, Rect2(6, 26, 78, 20))
	prompt_secondary = _prompt_button(prompt_panel, Rect2(92, 26, 78, 20))
	toast_panel = Panel.new()
	toast_panel.position = Vector2(120, 22)
	toast_panel.size = Vector2(400, 30)
	toast_panel.add_theme_stylebox_override("panel", WindowTheme.box(2))
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.hide()
	ui.add_child(toast_panel)
	toast_label = _prompt_text(toast_panel, Rect2(6, 4, 388, 24))
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.clip_text = false
	toast_label.max_lines_visible = 2
	tooltip_panel = Panel.new()
	tooltip_panel.size = Vector2(176, 52)
	tooltip_panel.add_theme_stylebox_override("panel", WindowTheme.box(2))
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.hide()
	ui.add_child(tooltip_panel)
	tooltip_label = _prompt_text(tooltip_panel, Rect2(6, 3, 164, 46))
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.clip_text = false
	tooltip_label.max_lines_visible = 4
	go_button = _prompt_button(ui, Rect2(200, 334, 140, 20))
	go_button.text = str(daily_strings.go_to_work)
	go_button.pressed.connect(go_to_work)

func _prompt_text(parent: Node, area: Rect2) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", 8)
	node.add_theme_color_override("font_color", Color("#d4f0fb"))
	node.position = area.position
	node.size = area.size
	node.clip_text = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = area.size
	return node

func _prompt_button(parent: Node, area: Rect2) -> Button:
	var node := Button.new()
	node.add_theme_font_size_override("font_size", 8)
	node.position = area.position
	node.size = area.size
	node.focus_mode = Control.FOCUS_NONE
	parent.add_child(node)
	return node

# ---- T-027: free shop choice ---------------------------------------------------------------

func shop_rect(index: int) -> Rect2:
	return Rect2(index * 84, SHOP_TOP, 84, SIDEWALK_Y - SHOP_TOP)

func shop_index_at(point: Vector2) -> int:
	for i in range(STOREFRONTS.size()):
		if shop_rect(i).has_point(point): return i
	return -1

func shop_label(index: int) -> String:
	var id: String = STOREFRONTS[index]
	return "%s\n%s\n%s" % [daily_strings.storefronts[id], daily_strings.shop_sells[id], daily_strings.shop_visit_tip % int(vitals.cfg.day.shop_visit_minutes)]

func street_active() -> bool:
	return interactive and phase in ["street", "to_shop"]

func set_hover(index: int) -> void:
	hover_index = index if street_active() else -1
	_update_tooltip()

func _update_tooltip() -> void:
	var index := hover_index if hover_index >= 0 else selected_index
	if not street_active() or index < 0:
		tooltip_panel.hide()
		return
	tooltip_label.text = shop_label(index)
	var rect := shop_rect(index)
	tooltip_panel.position = Vector2(clampf(rect.position.x + 4.0, 4.0, W - 180.0), 62)
	tooltip_panel.show()

# Click a storefront (or confirm a keyboard selection): walk to its door, then open the shop panel.
func visit_shop(id: String) -> bool:
	if not street_active() or not STOREFRONTS.has(id): return false
	target_shop = id
	phase = "to_shop"
	selected_index = STOREFRONTS.find(id)
	_update_tooltip()
	return true

func select_step(direction: int) -> void:
	if not street_active(): return
	var count := STOREFRONTS.size() + 1
	selected_index = (selected_index + 1 + direction + count) % count - 1
	_update_tooltip()

func activate_selected() -> void:
	if not street_active(): return
	if selected_index < 0:
		go_to_work()
	else:
		visit_shop(STOREFRONTS[selected_index])

# Ends the street phase. The red light, if the seed has one, is met here exactly once.
func go_to_work() -> void:
	if not interactive or phase not in ["street", "to_shop"]: return
	target_shop = ""
	hover_index = -1
	tooltip_panel.hide()
	go_button.hide()
	if vitals.light_red and not vitals.light_resolved:
		_open_light()
	else:
		_start_to_work()

func _open_light() -> void:
	phase = "light"
	paused = "light"
	current_stop = {"stop_type": "light", "id": "light", "x": player_x}
	for connection in prompt_primary.pressed.get_connections(): prompt_primary.pressed.disconnect(connection.callable)
	for connection in prompt_secondary.pressed.get_connections(): prompt_secondary.pressed.disconnect(connection.callable)
	prompt_label.text = daily_strings.light_title
	prompt_primary.text = daily_strings.wait % int(vitals.cfg.day.wait_minutes)
	prompt_secondary.text = daily_strings.run
	prompt_primary.pressed.connect(answer_prompt.bind("wait"))
	prompt_secondary.pressed.connect(answer_prompt.bind("run"))
	prompt_label.size = Vector2(164, 14)
	prompt_panel.position = Vector2(clampf(player_x - 60.0, 4.0, 456.0), 90)
	prompt_panel.show()
	prompt_opened.emit("light")
	if hurrying: default_answer()

func _start_to_work() -> void:
	phase = "to_work"
	paused = ""
	var length: int = VEHICLE_LEN.get(mode, 0)
	if length > 0:
		var look: Array = {"bus": [56, 17, 33], "moto": [55, 43, 36], "taxi": [52, 27, 64]}[mode]
		player_vehicle = {"variety": "bus" if mode == "bus" else ("moto" if mode == "moto" else "car"), "dir": 1, "x": player_x, "len": length, "speed": 0.0, "max": 0.0, "color": look[0], "shade": look[1], "light": look[2], "rider": 3, "bottom": LANE_DOWN, "player": true}
		vehicles.append(player_vehicle)
		player_visible = false
	facing = 1

# choice: "wait" | "run" at the light.
func answer_prompt(choice: String) -> void:
	if phase != "light" or not interactive: return
	var result: Dictionary = vitals.traffic_light(choice)
	results.append(result)
	var text: String = daily_strings.light_result[result.outcome]
	match result.outcome:
		"waited": text = text % int(result.minutes)
		"fined": text = text % int(result.fine)
		"accident": text = text % [int(vitals.cfg.light.accident_health), int(result.minutes)]
	show_toast(text, 2.4)
	if result.outcome in ["fined", "accident"]:
		emote_name = "emote_sad"
		emote_time = 2.4
	prompt_panel.hide()
	if choice == "run":
		_start_to_work()
	else:
		phase = "waiting"
		paused = "waiting"
		wait_timer = 1.1

# Called by the flow when the shop panel closes: the player stands at that door again.
func resume() -> void:
	if phase == "shopping":
		phase = "street"
		paused = ""
		go_button.show()
		_update_tooltip()

func show_toast(text: String, seconds: float = 2.2) -> void:
	toast_label.text = text
	toast_panel.show()
	toast_time = seconds

# The cheap default for Enter/Space: in the street go to work, at the light wait.
func default_answer() -> void:
	if phase in ["street", "to_shop"]: go_to_work()
	elif phase == "light": answer_prompt("wait")

func light_override() -> String:
	if vitals == null: return ""
	if phase == "light": return "red"
	if player_x >= 120.0 and player_x < 330.0:
		return "green"
	return ""

# Running arrival time at the tower from everything decided so far (visits, waits, transport), capped at +60 late.
func clock_minutes() -> int:
	if vitals == null: return 0
	var travel: int = int(vitals.cfg.transport[mode].minutes)
	var total: int = int(vitals.cfg.day.leave) + int(vitals.slept_in) + int(vitals.extra_minutes) + travel
	return mini(total, int(vitals.cfg.day.on_time) + int(vitals.cfg.day.max_late))

func late_minutes_now() -> int:
	return maxi(0, clock_minutes() - int(vitals.cfg.day.on_time))

func _walk_toward(target: float, delta: float) -> bool:
	var speed := WALK_SPEED * (4.0 if fast_forward else 1.0)
	if absf(target - player_x) < 0.5:
		return true
	facing = 1 if target > player_x else -1
	player_x = move_toward(player_x, target, speed * delta)
	return absf(target - player_x) < 0.5

func _advance_interactive(delta: float) -> void:
	if emote_time > 0.0: emote_time -= delta
	if toast_time >= 0.0:
		toast_time -= delta
		if toast_time < 0.0: toast_panel.hide()
	if enter_time >= 0.0:
		if elapsed - enter_time >= 0.7: _finish()
		return
	match phase:
		"waiting":
			wait_timer -= delta
			if wait_timer <= 0.0: _start_to_work()
		"to_shop":
			if _walk_toward(float(SHOP_STOPS[target_shop]), delta):
				vitals.enter_shop()
				visits.append(target_shop)
				current_stop = {"stop_type": "shop", "id": target_shop, "x": player_x}
				phase = "shopping"
				paused = "shopping"
				go_button.hide()
				tooltip_panel.hide()
				facing = 1
				shop_requested.emit(vitals.cfg.storefronts[target_shop], target_shop)
		"to_work":
			var speed: float = float(vitals.cfg.transport[mode].speed)
			if fast_forward: speed *= 4.0
			player_x += speed * delta
			if player_x >= float(DOOR_X) - 4.0:
				player_x = float(DOOR_X) - 4.0
				player_visible = false
				door_open = true
				enter_time = elapsed
				if not player_vehicle.is_empty():
					vehicles.erase(player_vehicle)
					player_vehicle = {}
			if not player_vehicle.is_empty(): player_vehicle.x = player_x

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not built:
		setup(day, trust)

# ---- static art -------------------------------------------------------

func sky_key() -> String:
	if crisis == 2:
		return "gloom"
	if crisis == 1:
		return "overcast"
	return "clear_dawn" if day <= 2 else "clear"

func _build_art() -> void:
	var sky_image := Pen.canvas(W, SIDEWALK_Y)
	var sky := Pen.new(sky_image)
	var bands: Array = SKY_BANDS[sky_key()]
	var count := bands.size()
	var band_height := float(SIDEWALK_Y) / float(count)
	for y in range(SIDEWALK_Y):
		var position := float(y) / band_height
		var index := mini(int(position), count - 1)
		var fraction := position - float(index)
		if fraction > 0.78 and index + 1 < count:
			var near_edge := fraction > 0.9
			for x in range(0, W, 2):
				var first := (y % 2 == 0)
				var use_next := (not first) or (not near_edge and x % 4 == 0)
				if near_edge:
					use_next = not (first and x % 4 == 0)
				sky.r(x, y, 1, 1, bands[index + 1] if use_next else bands[index])
				sky.r(x + 1, y, 1, 1, bands[index + 1] if (not first or near_edge) else bands[index])
		else:
			sky.r(0, y, W, 1, bands[index])
	if crisis == 0:
		sky.disc(502, 64, 17, 36 if day <= 2 else 35)
		sky.disc(502, 64, 12, 52)
		sky.disc(500, 62, 5, 64)
	else:
		sky.disc(502, 64, 9, 41 if crisis == 1 else 5)
	sky_tex = Pen.texture(sky_image)
	# Clouds: a wide strip that drifts slowly.
	var cloud_image := Pen.canvas(1280, 90)
	var cloud := Pen.new(cloud_image)
	var cloud_light := 64 if crisis == 0 else (6 if crisis == 1 else 4)
	var cloud_shade := 35 if crisis == 0 else (5 if crisis == 1 else 3)
	var cloud_count := 7 if crisis == 0 else 12
	var cloud_rng := RandomNumberGenerator.new()
	cloud_rng.seed = 31 * day
	for i in range(cloud_count):
		var cx := cloud_rng.randi_range(20, 1240)
		var cy := cloud_rng.randi_range(14, 60)
		var puffs := cloud_rng.randi_range(3, 5)
		for p in range(puffs):
			cloud.disc(cx + p * 10 - 12, cy + 3 + (p % 2) * -3, 6 + (p % 3) * 2, cloud_shade)
		for p in range(puffs):
			cloud.disc(cx + p * 10 - 12, cy + (p % 2) * -3, 6 + (p % 3) * 2, cloud_light)
		cloud.r(cx - 14, cy + 7, puffs * 10 + 8, 3, cloud_shade)
	cloud_tex = Pen.texture(cloud_image)
	layer_tex.clear()
	var palettes: Array
	if crisis == 0:
		palettes = [[6, 7, 5], [5, 6, 4], [18, 19, 17]]
	elif crisis == 1:
		palettes = [[41, 7, 40], [40, 41, 5], [4, 5, 3]]
	else:
		palettes = [[5, 6, 4], [4, 5, 3], [2, 3, 1]]
	var specs := [[190, 100, 150, 21], [205, 105, 145, 22], [218, 104, 128, 23]]
	for i in range(3):
		layer_tex.append(_skyline(palettes[i], specs[i][0], specs[i][1], specs[i][2], specs[i][3], i))
	var street_image := Pen.canvas(W, H)
	var street := Pen.new(street_image)
	_build_street(street)
	street_tex = Pen.texture(street_image)
	var front_image := Pen.canvas(W, H - FRONT_Y)
	var front := Pen.new(front_image)
	_build_front(front)
	front_tex = Pen.texture(front_image)

func _skyline(colors: Array, baseline: int, min_h: int, max_h: int, seed_value: int, layer: int) -> ImageTexture:
	var image := Pen.canvas(760, baseline)
	var pen := Pen.new(image)
	var local := RandomNumberGenerator.new()
	local.seed = seed_value * 101 + day * 3
	var x := -6
	while x < 760:
		var bw := local.randi_range(22, 46)
		var bh := local.randi_range(min_h, max_h)
		var top := baseline - bh
		pen.box(x, top, bw, bh, colors[0], colors[1], colors[2])
		if local.randf() < 0.3:
			pen.r(x + bw / 2, top - 9, 1, 9, colors[2])
			pen.px(x + bw / 2, top - 10, 51 if layer == 2 else colors[1])
		if local.randf() < 0.35:
			pen.r(x + 3, top - 3, 8, 3, colors[2])
		var lit_chance := 0.28 if crisis == 0 else 0.4
		for wy in range(top + 6, baseline - 6, 7):
			for wx in range(x + 4, x + bw - 5, 6):
				if local.randf() < lit_chance:
					pen.r(wx, wy, 3, 4, 52 if layer == 2 else (20 if layer == 1 else colors[1]))
				elif layer > 0:
					pen.r(wx, wy, 3, 4, colors[2])
		x += bw + local.randi_range(0, 4)
	return Pen.texture(image)

# Sidewalk, road and the shop row. Signs are collected as text overlays.
func _build_street(p: Pen) -> void:
	signs.clear()
	lit_shop_windows.clear()
	# Sidewalk and shadow under the facades.
	p.r(0, SIDEWALK_Y, W, 30, 61)
	for x in range(0, W, 16):
		p.r(x, SIDEWALK_Y + 2, 1, 28, 7)
	p.r(0, SIDEWALK_Y + 14, W, 1, 7)
	p.r(0, SIDEWALK_Y, W, 3, 6)
	p.r(0, 262, W, 1, 64)
	p.r(0, 263, W, 3, 5)
	# Road.
	p.r(0, ROAD_Y, W, 62, 62)
	for i in range(40):
		var rx := (i * 97 + day * 13) % W
		var ry := ROAD_Y + 3 + (i * 53) % 56
		p.r(rx, ry, 5 + i % 7, 1, 63)
	for x in range(8, W, 30):
		p.r(x, 296, 16, 2, 52)
	for y in range(ROAD_Y, 328, 6):
		p.r(250, y, 28, 3, 64)
	p.r(0, 328, W, 2, 5)
	p.r(0, 330, W, 2, 61)
	# Shops.
	var shops := [
		{"x": 0, "wall": [43, 44, 42], "awn": [53, 64], "plate": 9, "ink": 45, "variety": "cafe"},
		{"x": 84, "wall": [23, 24, 46], "awn": [51, 52], "plate": 46, "ink": 52, "variety": "noodle"},
		{"x": 168, "wall": [56, 33, 17], "awn": [52, 64], "plate": 7, "ink": 56, "variety": "mart"},
		{"x": 252, "wall": [13, 64, 12], "awn": [17, 28], "plate": 17, "ink": 28, "variety": "bank"},
		{"x": 336, "wall": [59, 54, 38], "awn": [54, 64], "plate": 2, "ink": 52, "variety": "news"},
		{"x": 420, "wall": [38, 30, 29], "awn": [55, 64], "plate": 10, "ink": 45, "variety": "books"}]
	for i in range(shops.size()):
		_shop(p, shops[i], i)
	_tower(p)
	# Street furniture on the sidewalk: lamp posts and hydrant.
	for x in [78, 166, 334, 418]:
		_lamp(p, x)
	p.r(236, 250, 5, 8, 51)
	p.r(235, 249, 7, 2, 25)

func _lamp(p: Pen, x: int) -> void:
	p.r(x, 196, 2, 62, 3)
	p.r(x - 1, 258, 4, 3, 2)
	p.r(x - 4, 194, 10, 3, 3)
	p.box(x - 5, 190, 6, 5, 52 if crisis > 0 else 27, 64, 26)

func _shop(p: Pen, s: Dictionary, index: int) -> void:
	var x: int = s.x
	var w := 84
	var wall: Array = s.wall
	var top := 114
	var bottom := SIDEWALK_Y
	p.box(x, top, w, bottom - top, wall[0], wall[1], wall[2])
	# Cornice, upper windows with sills and planters.
	p.r(x, top, w, 5, wall[2])
	p.r(x, top, w, 1, wall[1])
	var closed := crisis >= 2 and index in [0, 5]
	var window_xs: Array = [x + 10, x + 54]
	if s.variety == "news":
		window_xs = []
		p.box(x + 4, top + 10, 76, 22, 1, 2, 1)
		p.r(x + 6, top + 12, 72, 1, 51)
		var headline: String = HEADLINES[clampi(day - 1, 0, HEADLINES.size() - 1)]
		signs.append({"text": headline, "x": x + 4 + (76 - Pen.text_width(headline, 8)) / 2, "y": top + 17, "ink": 52, "size": 8})
		signs.append({"text": "NEWS FLASH", "x": x + 4 + (76 - Pen.text_width("NEWS FLASH", 8)) / 2, "y": top + 6, "ink": 64, "size": 8})
	for wx in window_xs:
		p.box(wx, top + 12, 20, 18, 6, 7, 5)
		p.r(wx + 2, top + 14, 16, 14, 18 if closed else 34)
		p.r(wx + 2, top + 14, 16, 2, 20 if not closed else 17)
		p.r(wx + 9, top + 14, 2, 14, 6)
		if not closed and crisis == 0:
			p.r(wx + 3, top + 17, 5, 8, 36)
		p.r(wx - 2, top + 30, 24, 3, wall[2])
		if index % 2 == 0:
			p.r(wx + 2, top + 27, 4, 3, 47)
			p.r(wx + 4, top + 25, 2, 2, 51)
	# Sign plate.
	var plate: int = s.plate
	var name: String = SHOP_NAMES[index]
	var sign_y := top + 38
	p.box(x + 4, sign_y, w - 8, 15, plate, mini(plate + 1, 64) if plate != 7 else 64, 1)
	signs.append({"text": name, "x": x + 4 + (w - 8 - Pen.text_width(name, 8)) / 2, "y": sign_y + 3, "ink": s.ink, "size": 8})
	# Awning with scalloped edge.
	var awn: Array = s.awn
	var awning_y := sign_y + 17
	if s.variety != "bank":
		for sx in range(0, w, 8):
			p.r(x + sx, awning_y, 8, 8, awn[(sx / 8) % 2])
			p.r(x + sx, awning_y, 8, 1, 64 if awn[(sx / 8) % 2] != 64 else 6)
			p.r(x + sx + 1, awning_y + 8, 6, 2, awn[(sx / 8) % 2])
			p.r(x + sx + 2, awning_y + 10, 4, 1, awn[(sx / 8) % 2])
		p.r(x, awning_y + 8, w, 1, 1)
	else:
		# Columns and pediment.
		p.r(x + 2, awning_y, w - 4, 3, 64)
		p.r(x + 2, awning_y + 3, w - 4, 1, 12)
		for cx in [x + 6, x + 26, x + 50, x + 70]:
			p.box(cx, awning_y + 4, 8, 36, 64, 7, 12)
	var win_top := awning_y + 12
	var win_h := bottom - win_top - 2
	match s.variety:
		"cafe":
			p.box(x + 6, win_top, 44, win_h, 34, 35, 5)
			p.r(x + 6, win_top + win_h - 12, 44, 12, 10)
			for tx in [x + 14, x + 34]:
				p.r(tx, win_top + 10, 8, 2, 11)
				p.r(tx + 3, win_top + 12, 2, 8, 9)
				p.r(tx + 5, win_top + 6, 3, 4, 7)
				p.r(tx + 5, win_top + 6, 3, 1, 51)
			for lx in [x + 12, x + 26, x + 40]:
				p.r(lx, win_top + 1, 1, 4, 1)
				p.disc(lx, win_top + 6, 2, 52)
			p.r(x + 6, win_top, 44, 2, 35)
			p.r(x + 10, win_top + 3, 1, 12, 35)
			_door(p, x + 56, awning_y + 12, 22, bottom, 9)
			if crisis >= 2:
				p.box(x + 58, awning_y + 20, 18, 8, 7, 64, 6)
				signs.append({"text": "CLOSED", "x": x + 60, "y": awning_y + 20, "ink": 51, "size": 8})
		"noodle":
			p.r(x + 6, win_top, 72, win_h, 2)
			p.r(x + 6, win_top, 72, 2, 1)
			p.box(x + 8, win_top + win_h - 14, 68, 14, 10, 11, 9)
			p.box(x + 14, win_top + win_h - 24, 14, 10, 5, 6, 4)
			p.r(x + 12, win_top + win_h - 26, 18, 3, 6)
			p.box(x + 36, win_top + win_h - 20, 12, 6, 7, 64, 6)
			p.box(x + 54, win_top + win_h - 20, 12, 6, 52, 64, 26)
			for lx in [x + 10, x + 36, x + 62]:
				p.r(lx + 4, awning_y + 11, 1, 5, 1)
				p.box(lx, awning_y + 16, 9, 8, 51, 25, 24)
				p.r(lx + 3, awning_y + 24, 3, 2, 52)
			p.box(x + 56, win_top + 4, 18, 12, 1, 2, 1)
			signs.append({"text": "MENU", "x": x + 59, "y": win_top + 6, "ink": 52, "size": 8})
		"mart":
			p.box(x + 6, win_top, 44, win_h, 34, 35, 5)
			var shelf_rng := RandomNumberGenerator.new()
			shelf_rng.seed = 77
			for row in range(3):
				var sy := win_top + 4 + row * 11
				p.r(x + 8, sy + 8, 40, 2, 6)
				for bx in range(x + 9, x + 47, 5):
					p.r(bx, sy + 1, 4, 7, [51, 52, 53, 54, 56, 55, 47][shelf_rng.randi_range(0, 6)])
			_door(p, x + 56, awning_y + 12, 22, bottom, 7)
		"bank":
			p.box(x + 14, awning_y + 6, 56, 3, 17, 18, 1)
			_door(p, x + 34, awning_y + 12, 22, bottom, 27)
			p.box(x + 10, awning_y + 20, 16, 22, 34, 35, 5)
			p.box(x + 58, awning_y + 20, 16, 22, 34, 35, 5)
			for bx in [x + 14, x + 18, x + 22, x + 62, x + 66, x + 70]:
				p.r(bx, awning_y + 21, 1, 20, 27)
		"news":
			p.box(x + 6, win_top, 44, win_h, 34, 35, 5)
			for row in range(2):
				for col in range(5):
					p.r(x + 9 + col * 8, win_top + 4 + row * 12, 6, 9, [51, 52, 53, 54, 56, 55, 47, 7, 36, 38][row * 5 + col])
					p.r(x + 10 + col * 8, win_top + 6 + row * 12, 4, 2, 64)
			_door(p, x + 56, awning_y + 12, 22, bottom, 9)
		"books":
			p.box(x + 6, win_top, 44, win_h, 34, 35, 5)
			var book_rng := RandomNumberGenerator.new()
			book_rng.seed = 91
			for row in range(3):
				var by := win_top + 3 + row * 11
				p.r(x + 8, by + 9, 40, 2, 9)
				var bx := x + 9
				while bx < x + 46:
					var bwid := book_rng.randi_range(2, 4)
					var bh := book_rng.randi_range(6, 9)
					p.r(bx, by + 9 - bh, bwid, bh, [51, 53, 54, 56, 52, 47, 38, 55][book_rng.randi_range(0, 7)])
					bx += bwid + 1
			_door(p, x + 56, awning_y + 12, 22, bottom, 9)
	# Crisis banners are drawn here so they stay on the facade.
	if s.variety == "books" and day >= 4:
		p.box(x + 4, 120, 76, 10, 51, 26, 25)
		signs.append({"text": "CLOSING SALE", "x": x + 6, "y": 121, "ink": 64, "size": 8})
		for tx in [x + 12, x + 34, x + 58]:
			p.r(tx, win_top + 12, 8, 10, 64)
			p.r(tx + 1, win_top + 14, 6, 1, 51)
			p.r(tx + 1, win_top + 17, 6, 1, 51)

func _door(p: Pen, x: int, top: int, w: int, bottom: int, frame_color: int) -> void:
	p.box(x, top, w, bottom - top, frame_color, mini(frame_color + 1, 64), 1)
	p.r(x + 2, top + 2, w - 4, bottom - top - 2, 34)
	p.r(x + 2, top + 2, w - 4, 2, 35)
	p.r(x + w / 2, top + 2, 1, bottom - top - 2, frame_color)
	p.r(x + w / 2 - 3, top + (bottom - top) / 2, 2, 3, 52)
	p.r(x + w / 2 + 2, top + (bottom - top) / 2, 2, 3, 52)

func _tower(p: Pen) -> void:
	var x := 504
	var w := 136
	var top := 36
	p.box(x, top, w, SIDEWALK_Y - top, 17, 18, 1)
	# Glass grid with day/dusk sky reflection.
	for gy in range(top + 24, SIDEWALK_Y - 52, 12):
		for gx in range(x + 8, x + w - 10, 14):
			var on := ((gx / 14 + gy / 12 + day) % 5) < 2
			p.r(gx, gy, 12, 10, 52 if (on and crisis == 0 and gy > 100) else 34)
			p.r(gx, gy, 12, 2, 35)
			p.r(gx, gy + 9, 12, 1, 5)
	p.r(x + 4, top - 8, w - 8, 8, 18)
	p.r(x + 12, top - 14, w - 24, 6, 17)
	p.r(x + w / 2 - 1, top - 30, 2, 16, 6)
	p.px(x + w / 2 - 1, top - 31, 51)
	# Sign plate on the tower.
	p.box(x + 14, top + 6, w - 28, 14, 1, 4, 1)
	var name := "LUC CHAU DATA CORP"
	signs.append({"text": name, "x": x + 14 + (w - 28 - Pen.text_width(name, 8)) / 2, "y": top + 9, "ink": 52, "size": 8})
	# Entrance with canopy, glass doors, planters.
	p.box(x + 36, SIDEWALK_Y - 52, 62, 6, 1, 3, 1)
	p.box(x + 38, SIDEWALK_Y - 46, 58, 46, 5, 6, 4)
	p.r(x + 42, SIDEWALK_Y - 42, 22, 42, 34)
	p.r(x + 68, SIDEWALK_Y - 42, 22, 42, 34)
	p.r(x + 42, SIDEWALK_Y - 42, 22, 3, 35)
	p.r(x + 68, SIDEWALK_Y - 42, 22, 3, 35)
	p.r(x + 62, SIDEWALK_Y - 22, 2, 5, 52)
	p.r(x + 68, SIDEWALK_Y - 22, 2, 5, 52)
	for px_ in [x + 12, x + 108]:
		p.box(px_, SIDEWALK_Y - 14, 14, 14, 9, 10, 8)
		p.disc(px_ + 7, SIDEWALK_Y - 20, 7, 46)
		p.disc(px_ + 5, SIDEWALK_Y - 22, 4, 47)
		p.disc(px_ + 4, SIDEWALK_Y - 23, 2, 48)

func _build_front(p: Pen) -> void:
	# Foreground sidewalk below the road with trees and lamp posts (drawn over the traffic).
	var top := 328 - FRONT_Y
	var rows := H - FRONT_Y - top
	p.r(0, top, W, 2, 5)
	p.r(0, top + 2, W, rows, 61)
	for x in range(0, W, 16):
		p.r(x, top + 4, 1, rows, 7)
	p.r(0, top + 4, W, 2, 6)
	for tx in [36, 150, 300, 446, 590]:
		p.box(tx - 8, top + 22, 16, 8, 9, 10, 8)
		p.r(tx - 1, top + 12, 3, 12, 9)
		p.disc(tx, top + 8, 10, 46)
		p.disc(tx - 3, top + 5, 7, 47)
		p.disc(tx - 5, top + 3, 3, 48 if crisis == 0 else 47)
	for lx in [96, 360, 520]:
		p.r(lx, top - 12, 2, 40, 3)
		p.box(lx - 5, top - 16, 7, 5, 52 if crisis > 0 else 27, 64, 26)
	# A bench and a bicycle rack in the foreground.
	p.r(214, top + 18, 26, 3, 10)
	p.r(214, top + 15, 26, 2, 11)
	p.r(216, top + 21, 2, 5, 3)
	p.r(236, top + 21, 2, 5, 3)
	p.r(398, top + 18, 3, 8, 6)
	p.r(412, top + 18, 3, 8, 6)
	p.r(398, top + 16, 17, 2, 6)

# ---- actors -----------------------------------------------------------

func _outfit(local: RandomNumberGenerator) -> Dictionary:
	return {"shirt": SHIRTS[local.randi_range(0, SHIRTS.size() - 1)], "pants": PANTS[local.randi_range(0, PANTS.size() - 1)], "hair": HAIRS[local.randi_range(0, HAIRS.size() - 1)], "skin": SKINS[local.randi_range(0, SKINS.size() - 1)]}

func _make_walker(local: RandomNumberGenerator, x: float, y: float, vx: float, variety: String) -> Dictionary:
	var out := _outfit(local)
	out.merge({"x": x, "y": y, "vx": vx, "variety": variety, "phase": local.randf_range(0.0, 3.0)})
	return out

func _build_actors() -> void:
	vehicles.clear()
	walkers.clear()
	crossers.clear()
	var local := RandomNumberGenerator.new()
	local.seed = 4001 + day
	# Traffic: fewer vehicles on crisis days.
	var kinds_down := ["car", "bus", "moto", "car", "bike", "car"] if crisis < 2 else ["car", "moto", "car"]
	var kinds_up := ["car", "moto", "car", "bus", "bike"] if crisis < 2 else ["bus", "car"]
	var colors := [51, 56, 52, 53, 54, 55, 7]
	var shades := {51: 25, 56: 17, 52: 27, 53: 58, 54: 38, 55: 43, 7: 6}
	var lights := {51: 26, 56: 33, 52: 64, 53: 34, 54: 37, 55: 36, 7: 64}
	for lane in range(2):
		var kinds: Array = kinds_down if lane == 0 else kinds_up
		var dir := 1 if lane == 0 else -1
		var cursor := 0.0
		for i in range(kinds.size()):
			var variety: String = kinds[i]
			var length: int = {"car": 30, "bus": 56, "moto": 14, "bike": 12}[variety]
			var speed: float = {"car": 86.0, "bus": 64.0, "moto": 92.0, "bike": 38.0}[variety] * local.randf_range(0.85, 1.1)
			var color: int = colors[local.randi_range(0, colors.size() - 1)]
			var vx: float = cursor if dir > 0 else float(W) - cursor - length
			vehicles.append({"variety": variety, "dir": dir, "x": vx, "len": length, "speed": speed, "max": speed, "color": color, "shade": shades[color], "light": lights[color], "rider": local.randi_range(0, SHIRTS.size() - 1), "bottom": LANE_DOWN if dir > 0 else LANE_UP})
			cursor += length + local.randf_range(36.0, 90.0)
	# Pedestrians walking along the sidewalk.
	var count := 9 if crisis < 2 else 5
	for i in range(count):
		var y: float = [246.0, 250.0, 254.0, 258.0][i % 4]
		var direction := 1.0 if i % 3 != 0 else -1.0
		var w := _make_walker(local, local.randf_range(20.0, 600.0), y, direction * local.randf_range(14.0, 26.0), "walk")
		if i == 1 or i == 6:
			w.variety = "cup"
		if i == 3:
			w.variety = "phone"
		if crisis >= 1 and i % 2 == 0:
			w.variety = "umbrella"
		walkers.append(w)
	# Customers standing at shops.
	walkers.append(_make_walker(local, 48.0, 252.0, 0.0, "cup"))
	walkers.append(_make_walker(local, 62.0, 254.0, 0.0, "cup"))
	walkers.append(_make_walker(local, 112.0, 256.0, 0.0, "stand"))
	walkers.append(_make_walker(local, 372.0, 252.0, 0.0, "read"))
	if day >= 6 or crisis >= 1 and trust <= 35:
		for q in range(5):
			walkers.append(_make_walker(local, 322.0 + q * 11.0, 253.0 + (q % 2) * 2.0, 0.0, "queue"))
	# Pedestrians crossing the road when the light is red.
	for c in range(2):
		var cr := _make_walker(local, 256.0 + c * 12.0, 268.0 + c * 10.0, 0.0, "cross")
		cr.dir = 1.0 if c == 0 else -1.0
		cr.vy = 15.0
		crossers.append(cr)
		if c == 1:
			cr.y = 322.0

func light_state(time: float = -1.0) -> String:
	if interactive and time < 0.0:
		var forced := light_override()
		if forced != "": return forced
	var t := elapsed if time < 0.0 else time
	var phase := fposmod(t + light_offset, 7.0)
	if phase < 3.3:
		return "green"
	if phase < 4.1:
		return "yellow"
	return "red"

# ---- simulation -------------------------------------------------------

func advance(delta: float) -> void:
	if done or not built:
		return
	elapsed += delta
	frames_run += 1
	var state := light_state()
	for v in vehicles:
		if v.has("player"): continue
		_update_vehicle(v, state, delta)
	for w in walkers:
		if absf(w.vx) > 0.0:
			w.x += w.vx * delta
			if w.vx > 0.0 and w.x > W + 16:
				w.x = -16.0
			elif w.vx < 0.0 and w.x < -16:
				w.x = W + 16.0
	for c in crossers:
		if state == "red":
			c.y += c.dir * c.vy * delta
			if c.y > 322.0:
				c.y = 322.0
				c.dir = -1.0
			elif c.y < 268.0:
				c.y = 268.0
				c.dir = 1.0
	# The player walks along the sidewalk to the tower door.
	if interactive:
		_advance_interactive(delta)
	elif enter_time < 0.0:
		player_x += delta * (float(DOOR_X) + 10.0) / (DURATION - 0.9)
		if player_x >= DOOR_X - 4:
			player_x = DOOR_X - 4
			player_visible = false
			door_open = true
			enter_time = elapsed
	elif elapsed - enter_time >= 0.7:
		_finish()
	if elapsed >= DURATION + 1.0 and not interactive:
		_finish()
	queue_redraw()

func _update_vehicle(v: Dictionary, state: String, delta: float) -> void:
	var dir: int = v.dir
	var length: float = v.len
	var front: float = v.x + (length if dir > 0 else 0.0)
	var target: float = v.max
	var stop_x := STOP_RIGHT if dir > 0 else STOP_LEFT
	var dist := (stop_x - front) * float(dir)
	if state == "red" and dist >= -2.0 and dist < 46.0:
		target = minf(target, maxf(0.0, v.max * (dist - 3.0) / 40.0))
	elif state == "yellow" and dist >= 16.0 and dist < 46.0:
		target = minf(target, maxf(0.0, v.max * (dist - 3.0) / 40.0))
	for u in vehicles:
		if u == v or u.dir != dir:
			continue
		var gap: float = (u.x - (v.x + length)) if dir > 0 else (v.x - (u.x + u.len))
		var closing: float = maxf(0.0, v.speed - u.speed)
		if gap >= -1.0 and gap < closing * closing / 200.0 + 12.0:
			target = minf(target, 0.0 if gap < 6.0 else u.speed * 0.8)
	v.speed = move_toward(v.speed, target, 150.0 * delta)
	v.x += float(dir) * v.speed * delta
	if dir > 0 and v.x > W + 4:
		var spawn := -length - 4.0
		for u in vehicles:
			if u != v and u.dir == dir:
				spawn = minf(spawn, u.x - length - 14.0)
		v.x = spawn
	elif dir < 0 and v.x < -length - 4:
		var spawn_left := float(W) + 4.0
		for u in vehicles:
			if u != v and u.dir == dir:
				spawn_left = maxf(spawn_left, u.x + u.len + 14.0)
		v.x = spawn_left

# Esc: leave for work now, taking the cheap default at the light, and speed up.
func hurry() -> void:
	if done or not interactive: return
	fast_forward = true
	hurrying = true
	if phase in ["street", "to_shop", "light"]: default_answer()

func skip() -> void:
	if done:
		return
	if interactive:
		hurry()
		return
	skipped = true
	_finish()

func _finish() -> void:
	if done:
		return
	done = true
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if done or not is_visible_in_tree():
		return
	if interactive:
		_interactive_input(event)
		return
	var key: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if key or click:
		get_viewport().set_input_as_handled()
		skip()

func _interactive_input(event: InputEvent) -> void:
	if phase == "shopping": return
	if event is InputEventMouseMotion:
		set_hover(shop_index_at(make_input_local(event).position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index := shop_index_at(make_input_local(event).position)
		if index >= 0 and street_active():
			get_viewport().set_input_as_handled()
			visit_shop(STOREFRONTS[index])
	elif event is InputEventKey and event.pressed and not event.echo:
		var handled := true
		match event.keycode:
			KEY_ESCAPE: hurry()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if phase in ["street", "to_shop"]: activate_selected()
				elif phase == "light": default_answer()
				else: fast_forward = true
			KEY_TAB: select_step(-1 if event.shift_pressed else 1)
			KEY_RIGHT: select_step(1)
			KEY_LEFT: select_step(-1)
			_: handled = false
		if handled: get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	advance(delta)

# ---- drawing ----------------------------------------------------------

func progress() -> float:
	return clampf(player_x / float(DOOR_X), 0.0, 1.0)

func _draw() -> void:
	if not built:
		return
	var p := Pen.new(self)
	draw_texture(sky_tex, Vector2(0, 0))
	draw_texture(cloud_tex, Vector2(-int(fposmod(elapsed * 4.0, 640.0)), 6))
	var shift := progress()
	var offsets := [6.0, 14.0, 26.0]
	var baselines := [190, 205, 218]
	for i in range(3):
		var tex: ImageTexture = layer_tex[i]
		draw_texture(tex, Vector2(-int(shift * offsets[i]), baselines[i] - tex.get_height()))
	draw_texture(street_tex, Vector2(0, 0))
	_draw_dynamic(p)
	draw_texture(front_tex, Vector2(0, FRONT_Y))
	_draw_overlay(p)

func _draw_dynamic(p: Pen) -> void:
	# Steam from the noodle stall.
	for i in range(4):
		var rise := fposmod(elapsed * 14.0 + i * 6.0, 24.0)
		p.r(104 + i * 3 + int(sin(elapsed * 2.0 + i) * 2.0), 208 - int(rise), 2, 2, 7 if rise < 16.0 else 41)
	# Neon OPEN sign on the mart.
	if int(elapsed * 2.0) % 2 == 0 or crisis == 0:
		p.box(222, 198, 26, 10, 1, 2, 1)
		p.text("OPEN", 226, 199, 53 if crisis == 0 else 51)
	# Doors: tower door opens when the player enters.
	if door_open:
		p.r(504 + 42, SIDEWALK_Y - 42, 22, 42, 2)
		p.r(504 + 42, SIDEWALK_Y - 42, 22, 3, 1)
		p.r(504 + 68, SIDEWALK_Y - 42, 22, 42, 2)
		p.r(504 + 68, SIDEWALK_Y - 42, 22, 3, 1)
		p.r(504 + 56, SIDEWALK_Y - 30, 20, 30, 52)
	# Sidewalk actors sorted by feet position.
	var drawables: Array = []
	for w in walkers:
		drawables.append({"y": w.y, "w": w})
	if player_visible:
		drawables.append({"y": float(FEET_Y), "player": true})
	drawables.sort_custom(func(a, b): return a.y < b.y)
	for d in drawables:
		if d.has("player"):
			var frame_index := 2 + _walk_frame(elapsed)
			var pos := Vector2(roundi(player_x), FEET_Y - 22)
			draw_texture(lib.frame("player", frame_index), pos)
			var bob := int(elapsed * 4.0) % 2
			p.r(roundi(player_x) + 4, FEET_Y - 32 + bob, 9, 1, 1)
			p.r(roundi(player_x) + 5, FEET_Y - 31 + bob, 7, 1, 52)
			p.r(roundi(player_x) + 6, FEET_Y - 30 + bob, 5, 1, 52)
			p.r(roundi(player_x) + 7, FEET_Y - 29 + bob, 3, 1, 52)
			p.r(roundi(player_x) + 8, FEET_Y - 28 + bob, 1, 1, 52)
		else:
			_draw_walker(p, d.w)
	# Vehicles and crossing pedestrians, far lane first.
	var road_items: Array = []
	for v in vehicles:
		road_items.append({"y": v.bottom, "v": v})
	for c in crossers:
		road_items.append({"y": c.y, "c": c})
	road_items.sort_custom(func(a, b): return a.y < b.y)
	for item in road_items:
		if item.has("v"):
			_draw_vehicle(p, item.v)
		else:
			_draw_walker(p, item.c)
	# Traffic lights on the sidewalk.
	var state := light_state()
	for lx in [244, 280]:
		p.r(lx, 214, 2, 46, 3)
		p.box(lx - 3, 204, 8, 18, 1, 2, 1)
		p.r(lx - 1, 206, 4, 4, 51 if state == "red" else 25)
		p.r(lx - 1, 211, 4, 4, 52 if state == "yellow" else 27)
		p.r(lx - 1, 216, 4, 4, 48 if state == "green" else 46)
	# Rain on the gloomiest days.
	if crisis >= 2:
		for i in range(70):
			var rx := (i * 53 + int(elapsed * 40.0)) % W
			var ry := (i * 37 + int(elapsed * 260.0)) % 300
			p.r(rx, ry, 1, 5, 6)

func _walk_frame(time: float) -> int:
	var total := 0.0
	for duration in WALK_TIMES:
		total += duration
	var cursor := fposmod(time, total)
	for i in range(WALK_TIMES.size()):
		cursor -= WALK_TIMES[i]
		if cursor < 0.0:
			return i
	return 0

func _draw_walker(p: Pen, w: Dictionary) -> void:
	var x := roundi(w.x)
	var y := roundi(w.y)
	var moving: bool = absf(w.vx) > 0.0 or w.variety == "cross"
	var step := (int((elapsed + w.phase) * 4.0) % 2) if moving else 0
	var skin: int = w.skin
	p.r(x - 1, y - 1, 10, 2, 63 if y > 262 else 5)
	# Legs and shoes.
	p.r(x + 1, y - 7, 3, 6 - step, w.pants)
	p.r(x + 4, y - 7, 3, 5 + step, w.pants)
	p.r(x + 1, y - 1 - step, 3, 1, 1)
	p.r(x + 4, y - 2 + step, 3, 1, 1)
	# Torso with a lit left edge and shaded bottom.
	p.r(x, y - 14, 8, 7, w.shirt)
	p.r(x, y - 14, 1, 7, 64 if w.shirt in [7] else 7)
	p.r(x, y - 8, 8, 1, 2)
	p.r(x - 1, y - 13, 1, 5, w.shirt)
	p.r(x + 8, y - 13, 1, 5, w.shirt)
	p.r(x - 1, y - 8, 1, 1, skin)
	p.r(x + 8, y - 8, 1, 1, skin)
	# Head and hair.
	p.r(x + 1, y - 19, 6, 5, skin)
	p.r(x + 1, y - 20, 6, 2, w.hair)
	p.r(x + 1, y - 18, 1, 3, w.hair)
	p.px(x + 3, y - 17, 1)
	p.px(x + 5, y - 17, 1)
	match w.variety:
		"umbrella":
			var col: int = [54, 56, 51, 52][roundi(w.phase) % 4]
			p.r(x - 4, y - 26, 16, 2, col)
			p.r(x - 2, y - 28, 12, 2, col)
			p.r(x + 1, y - 29, 6, 1, col)
			p.r(x + 4, y - 24, 1, 6, 5)
		"cup":
			p.r(x + 8, y - 11, 3, 3, 7)
			p.r(x + 8, y - 11, 3, 1, 51)
		"phone":
			p.r(x + 7, y - 20, 2, 4, 1)
			p.px(x + 7, y - 20, 53)
		"read":
			p.r(x + 7, y - 12, 7, 5, 64)
			p.r(x + 7, y - 12, 7, 1, 51)
		"queue":
			p.r(x - 3, y - 7, 3, 4, 10)
		"cross":
			p.r(x + 8, y - 11, 3, 6, 10)

func _draw_vehicle(p: Pen, v: Dictionary) -> void:
	var x := roundi(v.x)
	var y: int = v.bottom
	var dir: int = v.dir
	var base: int = v.color
	var shade: int = v.shade
	var light: int = v.light
	var length: int = v.len
	p.r(x + 1, y - 1, length - 2, 2, 1)
	match v.variety:
		"car":
			p.r(x, y - 9, length, 6, base)
			p.r(x, y - 9, length, 1, light)
			p.r(x, y - 4, length, 2, shade)
			p.r(x + 7, y - 15, 16, 6, base)
			p.r(x + 7, y - 15, 16, 1, light)
			p.r(x + 9, y - 14, 5, 4, 34)
			p.r(x + 16, y - 14, 5, 4, 34)
			p.r(x + 9, y - 14, 5, 1, 35)
			p.r(x + (length - 2 if dir > 0 else 0), y - 7, 2, 2, 52)
			p.r(x + (0 if dir > 0 else length - 2), y - 7, 2, 2, 51)
			for wx in [x + 4, x + length - 10]:
				p.r(wx, y - 5, 6, 5, 1)
				p.r(wx + 2, y - 3, 2, 2, 6)
		"bus":
			p.r(x, y - 17, length, 14, 53)
			p.r(x, y - 17, length, 2, 33)
			p.r(x, y - 7, length, 3, 64)
			p.r(x, y - 4, length, 2, 58)
			for wx in range(x + 4, x + length - 12, 9):
				p.r(wx, y - 15, 7, 6, 34)
				p.r(wx, y - 15, 7, 1, 35)
			var front_x := x + (length - 10 if dir > 0 else 1)
			p.r(front_x, y - 15, 9, 8, 34)
			p.r(x + (length - 3 if dir > 0 else 0), y - 6, 3, 2, 52)
			p.r(x + (0 if dir > 0 else length - 3), y - 6, 3, 2, 51)
			p.r(x + length / 2 - 6, y - 18, 12, 1, 52)
			for wx in [x + 6, x + length - 14]:
				p.r(wx, y - 5, 8, 5, 1)
				p.r(wx + 3, y - 3, 2, 2, 6)
		"moto":
			p.disc(x + 3, y - 3, 3, 1)
			p.disc(x + 11, y - 3, 3, 1)
			p.px(x + 3, y - 3, 6)
			p.px(x + 11, y - 3, 6)
			p.r(x + 3, y - 8, 9, 3, base)
			p.r(x + 3, y - 8, 9, 1, light)
			p.r(x + (10 if dir > 0 else 2), y - 10, 2, 3, 6)
			var shirt: int = SHIRTS[v.rider]
			p.r(x + 5, y - 15, 5, 7, shirt)
			p.r(x + 6, y - 20, 4, 5, 32)
			p.r(x + 6, y - 21, 4, 3, 1 if v.rider % 2 == 0 else 51)
		"bike":
			for wx in [x + 2, x + 9]:
				p.disc(wx, y - 3, 3, 1)
				p.disc(wx, y - 3, 1, 62)
			p.r(x + 3, y - 7, 7, 1, 6)
			p.r(x + 6, y - 7, 1, 4, 6)
			var shirt2: int = SHIRTS[v.rider]
			p.r(x + 4, y - 14, 4, 7, shirt2)
			p.r(x + 4, y - 18, 4, 4, 31)
			p.r(x + 4, y - 19, 4, 2, 9)

func arrive_text() -> String:
	var total := clock_minutes()
	var text: String = str(daily_strings.arrive_chip) % [day, total / 60, total % 60]
	var late := late_minutes_now()
	if late > 0: text += "   " + str(daily_strings.late_chip) % late
	return text

func _draw_highlight(p: Pen) -> void:
	var index := hover_index if hover_index >= 0 else selected_index
	var pulse := 64 if int(elapsed * 4.0) % 2 == 0 else 52
	if street_active() and index >= 0:
		var rect := shop_rect(index)
		var x := int(rect.position.x)
		p.frame(x, SHOP_TOP, 84, SIDEWALK_Y - SHOP_TOP, pulse)
		p.frame(x + 1, SHOP_TOP + 1, 82, SIDEWALK_Y - SHOP_TOP - 2, pulse)
		p.frame(x + 2, SHOP_TOP + 2, 80, SIDEWALK_Y - SHOP_TOP - 4, 53)
		# Sign glow around the plate.
		p.frame(x + 3, SHOP_TOP + 35, 78, 21, pulse)
		p.frame(x + 4, SHOP_TOP + 36, 76, 19, 52)
	if street_active() and selected_index < 0 and go_button != null:
		p.frame(197, 331, 146, 26, pulse)
		p.frame(198, 332, 144, 24, 53)

func _draw_overlay(p: Pen) -> void:
	if interactive:
		_draw_highlight(p)
	if interactive and emote_time > 0.0 and emote_name != "":
		var vehicle_len: int = VEHICLE_LEN.get(mode, 0)
		var ey := FEET_Y - 46 if vehicle_len == 0 else LANE_DOWN - 52
		draw_texture(lib.frame(emote_name), Vector2(roundi(player_x) + vehicle_len / 2 - 4, ey))
	for s in signs:
		p.text(s.text, s.x, s.y, s.ink, s.size)
	# Header chip with day and the morning clock.
	var minute := 40 + int(elapsed / DURATION * 20.0)
	var label := "DAY %d   %d:%02d AM" % [day, 8 if minute >= 60 else 7, minute % 60]
	if interactive:
		var total := clock_minutes()
		label = arrive_text()
	p.r(4, 4, Pen.text_width(label, 8) + 10, 14, 1)
	p.frame(4, 4, Pen.text_width(label, 8) + 10, 14, 5)
	p.text(label, 9, 7, 52)
	var hint := "Esc / click: skip" if not interactive else str(daily_strings.commute_hint)
	var hw := Pen.text_width(hint, 8)
	p.r(W - hw - 14, H - 17, hw + 10, 13, 1)
	p.text(hint, W - hw - 9, H - 15, 6)

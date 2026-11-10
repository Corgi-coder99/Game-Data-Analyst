extends Node2D
# The morning commute (about 7 s, skippable): a city street with parallax skyline, shops, traffic with a
# simple traffic light, pedestrians, and the player walking to the company tower.
# Mood cues use only public values: the day number and the public trust value.
signal finished
signal shop_requested(shop_ids: Array, storefront: String)
signal prompt_opened(stop_type: String)
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const Pen = preload("res://scripts/v2/pen.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const Library = preload("res://scripts/v2/sprite_lib.gd")
const StreetArt = preload("res://scripts/v2/street_art.gd")
const Actors = preload("res://scripts/v2/street_actors.gd")
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
const SHIRTS := [85, 91, 89, 93, 94, 97, 102, 75, 87, 90]
const PANTS := [83, 4, 84, 79, 108, 3, 80]
const HAIRS := [103, 108, 109, 110, 103, 107]
const SKINS := [106, 104, 32, 50, 31, 107]
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
var bulbs: Array = []
var puddles: Array = []
# T-026: interactive daily commute. The player moves with the chosen transport, pauses at shop doors
# and at a red light. Without `interactive` the scene behaves exactly as in T-022.
const STOREFRONTS := ["cafe", "noodle", "mart", "bank", "news", "books"]
const SHOP_STOPS := {"cafe": 30, "noodle": 110, "mart": 190, "bank": 282, "news": 366, "books": 450}
const SHOP_TOP := 114
const TOOLTIP_Y := 44
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
	prompt_panel.add_theme_stylebox_override("panel", WindowTheme.pastel(102, 82))
	prompt_panel.hide()
	ui.add_child(prompt_panel)
	prompt_label = _prompt_text(prompt_panel, Rect2(6, 4, 164, 14))
	prompt_primary = _prompt_button(prompt_panel, Rect2(6, 26, 78, 20))
	prompt_secondary = _prompt_button(prompt_panel, Rect2(92, 26, 78, 20))
	toast_panel = Panel.new()
	toast_panel.position = Vector2(120, 22)
	toast_panel.size = Vector2(400, 30)
	toast_panel.add_theme_stylebox_override("panel", WindowTheme.pastel(102, 82))
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.hide()
	ui.add_child(toast_panel)
	toast_label = _prompt_text(toast_panel, Rect2(6, 4, 388, 24))
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.clip_text = false
	toast_label.max_lines_visible = 2
	tooltip_panel = Panel.new()
	tooltip_panel.size = Vector2(176, 52)
	tooltip_panel.add_theme_stylebox_override("panel", WindowTheme.pastel(102, 82))
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.hide()
	ui.add_child(tooltip_panel)
	tooltip_label = _prompt_text(tooltip_panel, Rect2(6, 3, 164, 46))
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.clip_text = false
	tooltip_label.max_lines_visible = 4
	go_button = _prompt_button(ui, Rect2(200, 334, 140, 20))
	WindowTheme.pastel_button(go_button)
	go_button.text = str(daily_strings.go_to_work)
	go_button.pressed.connect(go_to_work)

func _prompt_text(parent: Node, area: Rect2) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", 8)
	node.add_theme_color_override("font_color", Palette.color(66))
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
	WindowTheme.pastel_button(node)
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
	tooltip_panel.position = Vector2(clampf(rect.position.x + 4.0, 4.0, W - 180.0), TOOLTIP_Y)
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
		var look: Array = {"bus": [91, 78, 90], "moto": [97, 98, 96], "taxi": [110, 27, 95]}[mode]
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
	var art: Dictionary = StreetArt.build(day, crisis, SHOP_NAMES, HEADLINES)
	sky_tex = art.sky
	cloud_tex = art.cloud
	layer_tex = art.layers.duplicate()
	street_tex = art.street
	front_tex = art.front
	signs = art.signs.duplicate()
	bulbs = art.bulbs
	puddles = art.puddles
	lit_shop_windows.clear()

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
	var colors := [87, 97, 91, 93, 94, 89, 112]
	var shades := {87: 88, 97: 98, 91: 78, 93: 80, 94: 84, 89: 97, 112: 67}
	var lights := {87: 85, 97: 96, 91: 90, 93: 82, 94: 35, 89: 95, 112: 26}
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
	# Steam from the food cart.
	for i in range(4):
		var rise := fposmod(elapsed * 14.0 + i * 6.0, 24.0)
		p.r(144 + i * 3 + int(sin(elapsed * 2.0 + i) * 2.0), 232 - int(rise), 2, 2, 102 if rise < 14.0 else (101 if rise < 20.0 else 100))
	# Neon OPEN sign on the mart.
	if int(elapsed * 2.0) % 2 == 0 or crisis == 0:
		p.rr(212, 198, 26, 11, 65)
		p.r(213, 199, 24, 9, 103)
		p.text("OPEN", 216, 199, 91 if crisis == 0 else 85)
	# String lights twinkle: a bright pixel travels along the wire.
	for i in range(bulbs.size()):
		var b: Vector3 = bulbs[i]
		if (int(elapsed * 2.0) + i) % 3 == 0:
			p.px(int(b.x) - 1, int(b.y), 102)
			p.px(int(b.x) + 2, int(b.y) + 1, 95)
	# Doors: tower door opens when the player enters.
	if door_open:
		p.r(504 + 42, SIDEWALK_Y - 42, 22, 42, 66)
		p.r(504 + 42, SIDEWALK_Y - 42, 22, 3, 65)
		p.r(504 + 68, SIDEWALK_Y - 42, 22, 42, 66)
		p.r(504 + 68, SIDEWALK_Y - 42, 22, 3, 65)
		p.r(504 + 56, SIDEWALK_Y - 30, 20, 30, 95)
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
			p.ellipse(roundi(player_x) + 8, FEET_Y, 7, 1, 99)
			draw_texture(lib.frame("player", frame_index), pos)
			var bob := int(elapsed * 4.0) % 2
			p.r(roundi(player_x) + 4, FEET_Y - 32 + bob, 9, 1, 65)
			p.r(roundi(player_x) + 5, FEET_Y - 31 + bob, 7, 1, 89)
			p.r(roundi(player_x) + 6, FEET_Y - 30 + bob, 5, 1, 89)
			p.r(roundi(player_x) + 7, FEET_Y - 29 + bob, 3, 1, 97)
			p.r(roundi(player_x) + 8, FEET_Y - 28 + bob, 1, 1, 97)
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
		p.r(lx, 214, 2, 46, 99)
		p.r(lx, 214, 1, 46, 100)
		p.rr(lx - 3, 203, 8, 20, 65)
		p.r(lx - 2, 204, 6, 18, 103)
		p.r(lx - 1, 206, 4, 4, 112 if state == "red" else 4)
		p.r(lx - 1, 211, 4, 4, 89 if state == "yellow" else 4)
		p.r(lx - 1, 216, 4, 4, 76 if state == "green" else 4)
		if state == "red": p.px(lx - 1, 206, 85)
		if state == "yellow": p.px(lx - 1, 211, 102)
		if state == "green": p.px(lx - 1, 216, 77)
	# Wet streets: puddle sparkle, rain streaks and splash rings on the gloomy days.
	if crisis >= 1:
		for i in range(puddles.size()):
			var pd: Vector3 = puddles[i]
			if (int(elapsed * 2.0) + i) % 4 == 0:
				p.px(int(pd.x) + 2 + i, int(pd.y) - 1, 102)
	if crisis >= 2:
		for i in range(70):
			var rx := (i * 53 + int(elapsed * 40.0)) % W
			var ry := (i * 37 + int(elapsed * 260.0)) % 300
			p.r(rx, ry, 1, 5, 82 if i % 3 == 0 else 6)
		for i in range(10):
			var phase_t := fposmod(elapsed * 2.2 + float(i) * 0.37, 1.0)
			var sx := (i * 97 + 31) % (W - 20) + 6
			var sy := 270 + (i * 43) % 52
			var radius := 1 + int(phase_t * 3.0)
			if phase_t < 0.8:
				p.r(sx - radius, sy, radius * 2 + 1, 1, 101 if phase_t < 0.4 else 100)
				p.px(sx - radius, sy - 1, 101)
				p.px(sx + radius, sy - 1, 101)
	# Fallen leaves drift past on calm days.
	if crisis == 0:
		for i in range(6):
			var fx := (i * 113 + int(elapsed * 14.0 + float(i) * 40.0)) % W
			var fy := int(fposmod(elapsed * 22.0 + float(i) * 51.0, 260.0)) + 20
			p.px(fx, fy, 97 if i % 2 == 0 else 98)
			p.px(fx + 1, fy + 1, 70)

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
	Actors.walker(p, w, elapsed)

func _draw_vehicle(p: Pen, v: Dictionary) -> void:
	Actors.vehicle(p, v, lib.frame("player", 0), elapsed)

func arrive_text() -> String:
	var total := clock_minutes()
	var text: String = str(daily_strings.arrive_chip) % [day, total / 60, total % 60]
	var late := late_minutes_now()
	if late > 0: text += "   " + str(daily_strings.late_chip) % late
	return text

func _draw_highlight(p: Pen) -> void:
	var index := hover_index if hover_index >= 0 else selected_index
	var pulse := 102 if int(elapsed * 4.0) % 2 == 0 else 89
	if street_active() and index >= 0:
		var rect := shop_rect(index)
		var x := int(rect.position.x)
		p.frame(x, SHOP_TOP, 84, SIDEWALK_Y - SHOP_TOP, pulse)
		p.frame(x + 1, SHOP_TOP + 1, 82, SIDEWALK_Y - SHOP_TOP - 2, pulse)
		p.frame(x + 2, SHOP_TOP + 2, 80, SIDEWALK_Y - SHOP_TOP - 4, 91)
		# Sign glow around the plate.
		p.frame(x + 3, SHOP_TOP + 35, 78, 21, pulse)
		p.frame(x + 4, SHOP_TOP + 36, 76, 19, 97)
	if street_active() and index >= 0 and tooltip_panel != null and tooltip_panel.visible:
		# Pointer from the tooltip down to the roofline, clear of the shop signs.
		var cx := int(shop_rect(index).position.x) + 42
		var ty := int(tooltip_panel.position.y + tooltip_panel.size.y) + 3
		p.r(cx - 4, ty - 1, 9, 1, 102)
		p.r(cx - 3, ty, 7, 1, 102)
		p.r(cx - 2, ty + 1, 5, 1, 102)
		p.r(cx - 1, ty + 2, 3, 1, 102)
		p.px(cx, ty + 3, 102)
		p.px(cx - 4, ty, 82)
		p.px(cx + 4, ty, 82)
		p.px(cx - 3, ty + 1, 82)
		p.px(cx + 3, ty + 1, 82)
		p.px(cx - 2, ty + 2, 82)
		p.px(cx + 2, ty + 2, 82)
		p.px(cx - 1, ty + 3, 82)
		p.px(cx + 1, ty + 3, 82)
		p.px(cx, ty + 4, 82)
	if street_active() and selected_index < 0 and go_button != null:
		p.frame(197, 331, 146, 26, pulse)
		p.frame(198, 332, 144, 24, 91)

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
	var label_w := Pen.text_width(label, 8) + 10
	p.rr(5, 6, label_w, 14, 66)
	p.rr(4, 4, label_w, 14, 102, 82)
	p.r(6, 5, label_w - 4, 1, 64)
	p.text(label, 9, 7, 66)
	var hint := "Esc / click: skip" if not interactive else str(daily_strings.commute_hint)
	var hw := Pen.text_width(hint, 8)
	p.rr(W - hw - 14, H - 17, hw + 10, 13, 66)
	p.text(hint, W - hw - 9, H - 15, 101)

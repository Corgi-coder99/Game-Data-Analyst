extends SceneTree
# T-022 tests (headless): palette v4 (T-028), procedural art colors, commute scene, office floor plan, camera.
const Palette = preload("res://scripts/v2/palette.gd")
const Checker = preload("res://tools/check_palette.gd")
const Pen = preload("res://scripts/v2/pen.gd")
const Art = preload("res://scripts/v2/office_art.gd")
const CityArt = preload("res://scripts/v2/city_art.gd")
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const CommuteScene = preload("res://scenes/v2/commute.tscn")
const OfficeScene = preload("res://scenes/v2/office.tscn")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_palette()
	test_art_colors()
	test_commute()
	test_commute_flow()
	test_office()
	test_camera()
	test_leak_probe()
	print("test_v2_commute: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

func test_palette() -> void:
	var v4: Array = Palette.colors()
	var v3: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v3.json")).colors
	var v2: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v2.json")).colors
	check(v4.size() == 112, "palette v4 has 112 colors")
	check(v3.size() == 64, "palette v3 file still has 64 colors")
	check(v2.size() == 32, "palette v2 still has 32 colors")
	for i in range(v3.size()):
		check(v4[i] == v3[i], "v4 keeps v3 color %d" % i)
	for i in range(v2.size()):
		check(v4[i] == v2[i], "v4 keeps v2 color %d" % i)
	var seen := {}
	for hex in v4: seen[hex] = true
	check(seen.size() == 112, "palette v4 colors are unique")
	check(Palette.ALPHABET.length() == 112, "sprite alphabet covers 112 colors")
	var symbols := {}
	for i in range(Palette.ALPHABET.length()): symbols[Palette.ALPHABET.substr(i, 1)] = true
	check(symbols.size() == 112 and not symbols.has("."), "alphabet symbols are unique and never the transparent dot")
	for i in range(112): check(Palette.decode(Palette.ALPHABET.substr(i, 1)) == Palette.color(i + 1), "alphabet maps to index %d" % (i + 1))
	check(FileAccess.get_file_as_bytes("res://data/palette_v4.json") == FileAccess.get_file_as_bytes(ProjectSettings.globalize_path("res://../../shared/style-bible/palette-v4.json")), "shared and game palette v4 copies identical")
	check(Checker.validate(), "all generated sprite PNGs use only palette v4 colors with binary alpha")

func image_ok(image: Image, label: String) -> void:
	check(image != null and image.get_width() > 0 and Checker.validate_image(image, label, true), "procedural art uses only v4 colors and binary alpha: " + label)

func test_art_colors() -> void:
	for variety in ["wallpaper", "title", "review", "ending_good", "ending_bad"]:
		image_ok(CityArt.backdrop(variety).get_image(), "city " + variety)
	var office: Node2D = OfficeScene.instantiate()
	root.add_child(office)
	image_ok(office.floor_image, "office floor plan")
	for key in office.window_textures: image_ok(office.window_textures[key].get_image(), "window " + key)
	check(office.floor_image.get_size() == Vector2i(1280, 560), "floor plan size")
	office.free()
	for day in [1, 6, 9]:
		var commute: Node2D = CommuteScene.instantiate()
		commute.day = day
		root.add_child(commute)
		for texture in [commute.sky_tex, commute.cloud_tex, commute.street_tex, commute.front_tex] + commute.layer_tex:
			image_ok(texture.get_image(), "commute day %d" % day)
		commute.free()

func test_commute() -> void:
	var commute: Node2D = CommuteScene.instantiate()
	commute.day = 1
	root.add_child(commute)
	commute.set_process(false)
	var emitted := [0]
	commute.finished.connect(func(): emitted[0] += 1)
	var states := {}
	var violations := 0
	var overlaps := 0
	var red_age := 0.0
	var frames := 0
	while not commute.done and frames < 900:
		var before := []
		for v in commute.vehicles: before.append(v.x + (v.len if v.dir > 0 else 0.0))
		commute.advance(1.0 / 60.0)
		frames += 1
		var state: String = commute.light_state()
		states[state] = true
		red_age = red_age + 1.0 / 60.0 if state == "red" else 0.0
		for i in range(commute.vehicles.size()):
			var v: Dictionary = commute.vehicles[i]
			var front: float = v.x + (v.len if v.dir > 0 else 0.0)
			var line: float = commute.STOP_RIGHT if v.dir > 0 else commute.STOP_LEFT
			var was: float = (line - before[i]) * v.dir
			var now: float = (line - front) * v.dir
			if red_age > 0.5 and was >= 2.0 and now < -1.0: violations += 1
			for j in range(i + 1, commute.vehicles.size()):
				var u: Dictionary = commute.vehicles[j]
				if u.dir == v.dir and v.x < u.x + u.len and u.x < v.x + v.len and absf(v.x - u.x) < 200.0: overlaps += 1
	check(commute.done and emitted[0] == 1, "commute ends with exactly one finished signal")
	check(frames >= 6 * 60 and frames <= 9 * 60, "commute lasts about 6 to 9 seconds (%d frames)" % frames)
	check(commute.frames_run == frames and commute.frames_run > 300, "commute ran N frames without errors")
	check(not commute.player_visible and commute.door_open, "player walked into the company tower")
	check(violations == 0, "no vehicle runs a red light (%d violations)" % violations)
	check(overlaps == 0, "vehicles in one lane never overlap (%d)" % overlaps)
	check(states.has("green") and states.has("red"), "traffic light cycles through green and red: " + str(states.keys()))
	commute.advance(1.0)
	check(emitted[0] == 1, "no second finished signal")
	commute.free()
	# Skippable at any time.
	var quick: Node2D = CommuteScene.instantiate()
	root.add_child(quick)
	quick.set_process(false)
	var quick_count := [0]
	quick.finished.connect(func(): quick_count[0] += 1)
	for i in 20: quick.advance(0.05)
	quick.skip()
	quick.skip()
	check(quick.done and quick.skipped and quick_count[0] == 1, "commute is skippable and emits once")
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	var again: Node2D = CommuteScene.instantiate()
	root.add_child(again)
	again.set_process(false)
	var esc_count := [0]
	again.finished.connect(func(): esc_count[0] += 1)
	again._unhandled_input(key)
	check(esc_count[0] == 1 and again.skipped, "Esc skips the commute")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var third: Node2D = CommuteScene.instantiate()
	root.add_child(third)
	third.set_process(false)
	var click_count := [0]
	third.finished.connect(func(): click_count[0] += 1)
	third._unhandled_input(click)
	check(click_count[0] == 1, "a click skips the commute")
	quick.free()
	again.free()
	third.free()
	# Mood follows public values only: day number and public trust.
	var moods := {}
	for entry in [[1, 50], [4, 50], [5, 50], [8, 50], [1, 30], [1, 15], [3, 80]]:
		var c: Node2D = CommuteScene.instantiate()
		c.day = entry[0]
		c.trust = entry[1]
		root.add_child(c)
		moods[str(entry)] = c.crisis
		c.free()
	check(moods["[1, 50]"] == 0 and moods["[4, 50]"] == 0 and moods["[5, 50]"] == 1 and moods["[8, 50]"] == 2, "sky mood by day number: " + str(moods))
	check(moods["[1, 30]"] == 1 and moods["[1, 15]"] == 2 and moods["[3, 80]"] == 0, "sky mood by public trust: " + str(moods))
	var early: Node2D = CommuteScene.instantiate()
	early.day = 1
	root.add_child(early)
	var late: Node2D = CommuteScene.instantiate()
	late.day = 9
	root.add_child(late)
	var early_text := ""
	for s in early.signs: early_text += s.text + "|"
	var late_text := ""
	for s in late.signs: late_text += s.text + "|"
	check(not "CLOSING" in early_text and "CLOSING" in late_text, "closing-down sign appears only on late days")
	check("FRESH START" in early_text and "CRISIS DEEPENS" in late_text, "newsstand headline follows the day number")
	check(late.walkers.filter(func(w): return w.variety == "queue").size() >= 5 and early.walkers.filter(func(w): return w.variety == "queue").is_empty(), "bank queue only on crisis days")
	for name in ["MOONBEAN CAFE", "SIZZLE NOODLES", "CORNER MART", "HARBOR BANK", "DAILY NEWS", "MOTH BOOKS"]:
		check(name in early_text, "shop sign: " + name)
	check(early.vehicles.size() >= 9 and early.walkers.size() >= 12, "traffic and pedestrians present")
	var kinds := {}
	for v in early.vehicles: kinds[v.variety] = true
	check(kinds.has("car") and kinds.has("bus") and kinds.has("moto") and kinds.has("bike"), "cars, bus, motorbikes and bicycles: " + str(kinds.keys()))
	early.free()
	late.free()

func test_commute_flow() -> void:
	var flow: Node = Flow.new()
	flow.autostart = false
	flow.evening_enabled = false
	flow.daily_enabled = false
	flow.fade_enabled = false
	root.add_child(flow)
	flow.start_with_game(Game.new(104, 10))
	check(flow.state == "DAY_START" and flow.commute != null and flow.office == null, "day starts with the commute, before the office")
	check(flow.commute.day == 1, "commute shows the current day")
	for i in 20: flow.commute.advance(0.05)
	flow.commute.advance(10.0)
	check(flow.commute == null and flow.office != null and flow.state == "DAY_START", "finished commute leads into the office")
	flow.skip_intro()
	check(flow.state == "WORK", "intro skipped into work (state order unchanged)")
	var visited_before: Array = flow.visited.duplicate()
	var window: Control = flow.desktop.report_window
	window.choose_forecast("giam")
	window.choose_confidence("vua")
	check(window.request_submit(), "report confirmation opens")
	window.confirm_submit()
	var guard := 0
	while flow.state == "REVIEW" and guard < 12:
		flow.continue_review()
		guard += 1
	check(flow.state == "DAY_START" and flow.commute != null and flow.commute.day == 2, "day 2 also starts with a commute")
	flow.skip_commute()
	check(flow.commute == null and flow.office != null, "skip_commute leads to the office")
	check(visited_before == ["NEW_GAME", "DAY_START", "WORK"], "state order has no new states: " + str(visited_before))
	# A whole game through commute -> office -> desktop -> review.
	var days := 2
	while flow.state == "DAY_START" and days < 12:
		flow.skip_intro()
		if flow.state != "WORK": break
		var w: Control = flow.desktop.report_window
		w.choose_forecast("tang")
		w.choose_confidence("vua")
		w.request_submit()
		w.confirm_submit()
		var g := 0
		while flow.state == "REVIEW" and g < 12:
			flow.continue_review()
			g += 1
		days += 1
	check(flow.state == "END_SCREEN" or flow.state == "ENDING", "the game reaches an ending through the commute flow: " + flow.state)
	flow.free()

func test_office() -> void:
	var office: Node2D = OfficeScene.instantiate()
	root.add_child(office)
	office.set_process(false)
	var expected_titles := {"data": "DATA ANALYTICS", "finance": "FINANCE", "marketing": "MARKETING", "sales": "SALES", "executive": "EXECUTIVE OFFICE", "meeting": "MEETING ROOM", "server": "SERVER ROOM", "break": "BREAK ROOM", "reception": "RECEPTION"}
	for key in expected_titles:
		check(Art.ROOMS.has(key) and Art.ROOMS[key].title == expected_titles[key], "room exists: " + key)
	check(Art.ROOMS.size() == 9, "nine rooms")
	# Rooms do not overlap each other or the corridor.
	var keys: Array = Art.ROOMS.keys()
	for i in range(keys.size()):
		var a: Rect2i = Art.rect_of(keys[i])
		check(not a.intersects(Art.CORRIDOR), "room %s clear of the corridor" % keys[i])
		check(Rect2i(Vector2i.ZERO, Art.WORLD).encloses(a), "room %s inside the world" % keys[i])
		for j in range(i + 1, keys.size()):
			check(not a.intersects(Art.rect_of(keys[j])), "rooms %s and %s do not overlap" % [keys[i], keys[j]])
	check(office.player.position == Vector2(-16, 264) and office.arrival_active, "player arrives from the corridor")
	office.advance(6.0)
	# People per room (stationary staff).
	var staff: Array = []
	for c in office.colleagues: staff.append(c.node)
	for idler in office.idlers: staff.append(idler.node)
	staff.append(office.player)
	staff.append(office.exec_boss)
	var counts := {}
	for node in staff:
		var center := Vector2i(node.position) + Vector2i(8, 12)
		for key in keys:
			if Art.rect_of(key).has_point(center):
				counts[key] = int(counts.get(key, 0)) + 1
	var expected_counts := {"data": 4, "finance": 2, "marketing": 2, "sales": 3, "executive": 1, "reception": 1, "meeting": 2, "server": 1, "break": 1}
	check(counts == expected_counts, "NPC counts per room: " + str(counts))
	check(office.walkers.size() == 4, "three people and the office cat walk the corridor")
	# Desks do not overlap each other or other furniture, and stay inside their rooms below the wall.
	var desks: Array = []
	var furniture: Array = []
	for child in office.world.get_children():
		if child is Sprite2D and child.texture is AtlasTexture:
			var rect := Rect2i(Vector2i(child.position), Vector2i(child.texture.region.size))
			if rect.size == Vector2i(48, 24): desks.append(rect)
			elif child.texture.atlas == office.lib.textures.get("plant") or child.texture.atlas == office.lib.textures.get("cabinet"): furniture.append(rect)
	check(desks.size() == 11, "eleven workstations: %d" % desks.size())
	for i in range(desks.size()):
		var inside := false
		for key in keys:
			var r: Rect2i = Art.rect_of(key)
			if Rect2i(r.position + Vector2i(0, Art.WALL_H), r.size - Vector2i(0, Art.WALL_H + 10)).encloses(desks[i]): inside = true
		check(inside, "desk %d sits inside a room floor" % i)
		for j in range(i + 1, desks.size()):
			check(not desks[i].intersects(desks[j]), "desks %d and %d do not overlap" % [i, j])
		for f in furniture:
			check(not desks[i].intersects(f), "desk %d does not overlap a plant or cabinet" % i)
	office.advance(6.0)
	check(office.player_seated and office.player.position == Vector2(office.SEAT_POS), "player seats at the Data Analytics desk")
	check(Art.rect_of("data").has_point(Vector2i(office.player.position)), "player desk is in the Data Analytics room")
	# Khoi, boss dialog and money popups keep working: dialog + reactions are covered in test_v2_popups/test_v2_flow.
	office.play_boss_appears("Test question")
	check(office.boss.visible and not office.exec_boss.visible and office.dialog.visible, "boss leaves the executive office for the dialog")
	office.hide_dialog()
	check(office.exec_boss.visible and not office.boss.visible, "boss returns to the executive office")
	check(office.minimap.get_parent() == office and office.MINIMAP_RECT.size == Vector2(130, 58), "minimap present")
	office.free()

func test_camera() -> void:
	var office: Node2D = OfficeScene.instantiate()
	root.add_child(office)
	office.set_process(false)
	check(office.camera == Vector2i.ZERO and office.current_room == "data", "camera starts on the Data Analytics room")
	check(office.desk_button.position == Vector2(208, 192), "desk button sits on the player's desk at the default camera")
	for key in Art.ROOM_ORDER:
		check(office.show_room(key), "show_room " + key)
		var cam: Vector2i = office.camera
		check(cam.x >= 0 and cam.y >= 0 and cam.x <= 640 and cam.y <= 200, "camera inside the world for " + key)
		check(office.world.position == Vector2(-cam.x, -cam.y) and office.world.position == office.world.position.round(), "integer camera for " + key)
		var r: Rect2i = Art.rect_of(key)
		var visible := Rect2i(cam, Vector2i(640, 360))
		check(visible.intersection(r).get_area() >= r.get_area() / 3, "room %s is mostly in view" % key)
		check(office.room_at_minimap(office.MINIMAP_RECT.position + Vector2(1, 1) + Vector2(r.get_center()) / 10.0) == key, "minimap click finds " + key)
	office.show_room("data")
	check(office.pan_to("break") and office.panning, "pan starts")
	var guard := 0
	while office.panning and guard < 100:
		office.advance(0.02)
		guard += 1
	check(not office.panning and office.camera == office.room_camera("break"), "pan ends on the target room")
	check(not office.show_room("nope") and not office.pan_to("nope"), "unknown room rejected")
	office.show_room("data")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	office._unhandled_input(tab)
	check(office.current_room == "finance" and office.panning, "Tab pans to the next room")
	office.free()

func test_leak_probe() -> void:
	# The new art code never reads hidden truth: no review(), truth, root cause or state access.
	var banned := ["truth", "root_cause", ".states", "review(", "hidden", "scenario", "_sim"]
	for path in ["res://scripts/v2/commute_scene.gd", "res://scripts/v2/office.gd", "res://scripts/v2/office_art.gd", "res://scripts/v2/city_art.gd", "res://scripts/v2/pen.gd"]:
		var source := FileAccess.get_file_as_string(path)
		for word in banned:
			check(not word in source, "%s does not mention %s" % [path, word])
		check(not "game." in source and not "WorldGame" in source, path + " has no game dependency")
	var flow_source := FileAccess.get_file_as_string("res://scripts/v2/game_flow.gd")
	var start := flow_source.find("func _build_commute")
	var end := flow_source.find("func _commute_done")
	var block := flow_source.substr(start, end - start)
	check("game.status().trust" in block and not "review" in block and not "truth" in block, "flow passes only day and public trust to the commute")
	# All visible text of the commute and the office is English and free of hidden labels.
	var commute: Node2D = CommuteScene.instantiate()
	root.add_child(commute)
	var texts: Array = []
	for s in commute.signs: texts.append(s.text)
	var office: Node2D = OfficeScene.instantiate()
	root.add_child(office)
	for tag in office.name_tags: texts.append(tag.text)
	for key in Art.ROOMS: texts.append(Art.ROOMS[key].title)
	var regex := RegEx.create_from_string("[^\\x20-\\x7e]")
	for text in texts:
		check(regex.search(str(text)) == null, "English ASCII text only: " + str(text))
		for word in ["dung", "sai", "tang", "giam", "ngang"]:
			check(not (" " + str(text).to_lower() + " ").contains(" " + word + " "), "no hidden label word '%s' in: %s" % [word, text])
	commute.free()
	office.free()

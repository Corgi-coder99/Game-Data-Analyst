extends Control
# T-020: the player and the desk neighbor, with floating money text, an emote icon and the
# neighbor's reaction. Purely visual: it only shows values handed in by the review scene.
const Palette = preload("res://scripts/v2/palette.gd")
const Library = preload("res://scripts/v2/sprite_lib.gd")
const STAGE_SIZE := Vector2(208, 120)
const POPUP_TIME := 1.2
const POPUP_RISE := 14
const POPUP_Y := 22
const SLAM_STEP := 0.09
const SLAM_CYCLES := 3
const CHEER_STEP := 0.12
const CHEER_CYCLES := 4
const PLAYER_POS := Vector2(24, 62)
const NEIGHBOR_POS := Vector2(128, 62)
# Each slam frame: sprite frame of the neighbor, vertical offset, desk shake.
const SLAM_FRAMES := [[0, -2, 0], [7, 2, 1], [6, 0, -1]]
const CHEER_FRAMES := [[0, -4], [1, 0]]
const GOOD := 24
const BAD := 26
signal popup_started(record: Dictionary)
signal reacted(mood: String, line: String)
var lib := Library.new()
var strings: Dictionary
var player_node: TextureRect
var neighbor_node: TextureRect
var neighbor_desk: ColorRect
var emote_node: TextureRect
var thumb_node: TextureRect
var bubble: Panel
var bubble_label: Label
var popups: Array = []
var popup_log: Array = []
var emote := ""
var mood := ""
var shout := ""
var reaction_time := -1.0
var built := false

func _ready() -> void:
	build()

func build() -> void:
	if built: return
	built = true
	custom_minimum_size = STAGE_SIZE
	size = STAGE_SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	_slab(Vector2(PLAYER_POS.x - 8, 106), Vector2(48, 8))
	neighbor_desk = _slab(Vector2(NEIGHBOR_POS.x - 8, 106), Vector2(48, 8))
	player_node = _person("player", PLAYER_POS)
	neighbor_node = _person("khoi", NEIGHBOR_POS)
	emote_node = TextureRect.new()
	emote_node.position = Vector2(PLAYER_POS.x + 8, 42)
	emote_node.size = Vector2(16, 16)
	emote_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emote_node.stretch_mode = TextureRect.STRETCH_SCALE
	emote_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emote_node.hide()
	add_child(emote_node)
	thumb_node = TextureRect.new()
	thumb_node.texture = lib.frame("thumb")
	thumb_node.position = Vector2(NEIGHBOR_POS.x + 36, 78)
	thumb_node.size = Vector2(16, 16)
	thumb_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb_node.stretch_mode = TextureRect.STRETCH_SCALE
	thumb_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_node.hide()
	add_child(thumb_node)
	bubble = Panel.new()
	bubble.position = Vector2(100, 40)
	bubble.size = Vector2(104, 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(8)
	style.border_color = Palette.color(5)
	style.set_border_width_all(1)
	style.anti_aliasing = false
	bubble.add_theme_stylebox_override("panel", style)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.hide()
	add_child(bubble)
	bubble_label = Label.new()
	bubble_label.position = Vector2(3, 2)
	bubble_label.size = Vector2(98, 14)
	bubble_label.clip_text = true
	bubble_label.add_theme_font_size_override("font_size", 8)
	bubble_label.add_theme_color_override("font_color", Palette.color(1))
	bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(bubble_label)
	bubble_label.size = Vector2(98, 14)

func _slab(at: Vector2, extent: Vector2) -> ColorRect:
	var top := ColorRect.new()
	top.color = Palette.color(11)
	top.position = at
	top.size = extent
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var edge := ColorRect.new()
	edge.color = Palette.color(10)
	edge.position = Vector2(0, extent.y - 3)
	edge.size = Vector2(extent.x, 3)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(edge)
	return top

func _person(id: String, at: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = lib.frame(id, 0)
	node.position = at
	node.size = Vector2(32, 48)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

# ---- API ---------------------------------------------------------------

# Removes every popup, the emote and the reaction.
func clear() -> void:
	build()
	for record in popups:
		record.label.queue_free()
	popups.clear()
	popup_log.clear()
	emote = ""
	mood = ""
	shout = ""
	reaction_time = -1.0
	emote_node.hide()
	thumb_node.hide()
	bubble.hide()
	neighbor_node.position = NEIGHBOR_POS
	neighbor_node.texture = lib.frame("khoi", 0)
	neighbor_desk.position.x = NEIGHBOR_POS.x - 8

# type is "pay", "bonus" or "fine"; amount is the absolute value shown (fine is drawn negative).
func show_money(type: String, amount: int, delay: float = 0.0, column: int = 0) -> Dictionary:
	build()
	var negative := type == "fine"
	var text: String = (strings.money.minus if negative else strings.money.plus) % absi(amount)
	var node := Label.new()
	node.text = text
	node.position = Vector2(2 + column * 56, POPUP_Y)
	node.size = Vector2(54, 15)
	node.clip_text = true
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_color_override("font_color", Palette.color(BAD if negative else GOOD))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.visible = delay <= 0.0
	add_child(node)
	node.size = Vector2(54, 15)
	var record := {"type": type, "amount": -absi(amount) if negative else absi(amount), "text": text, "positive": not negative, "label": node, "time": 0.0, "delay": delay, "done": false, "column": column}
	popups.append(record)
	popup_log.append({"type": type, "amount": record.amount, "text": text, "positive": not negative})
	popup_started.emit(record)
	_apply_popup(record)
	return record

func set_emote(name: String) -> void:
	build()
	if name != "": preload("res://scripts/audio/audio_manager.gd").emit_for(self, "select" if name == "happy" else "warning")
	emote = name
	if name == "":
		emote_node.hide()
		return
	emote_node.texture = lib.frame("emote_" + name)
	emote_node.show()

# mood: "angry" (slam + shout), "happy" (cheer + thumbs up), anything else clears the reaction.
func react(value: String, pick: int = 0) -> String:
	build()
	mood = ""
	shout = ""
	bubble.hide()
	thumb_node.hide()
	reaction_time = -1.0
	if not value in ["angry", "happy"]: return ""
	var lines: Array = strings.coworker[value]
	shout = str(lines[posmod(pick, lines.size())])
	mood = value
	bubble_label.text = shout
	bubble.show()
	thumb_node.visible = value == "happy"
	reaction_time = 0.0
	_apply_reaction()
	preload("res://scripts/audio/audio_manager.gd").emit_for(self, "keyboard_slam" if mood == "angry" else "confirm")
	reacted.emit(mood, shout)
	return shout

func animating() -> bool:
	for record in popups:
		if not record.done: return true
	return reaction_time >= 0.0 and reaction_time < _reaction_length()

# Skip: popups finish at once and the neighbor settles. Nothing is blocked by the stage.
func skip() -> void:
	for record in popups:
		record.time = POPUP_TIME + record.delay
		_apply_popup(record)
	if reaction_time >= 0.0:
		reaction_time = _reaction_length()
		_apply_reaction()

func _reaction_length() -> float:
	if mood == "angry": return SLAM_STEP * SLAM_FRAMES.size() * SLAM_CYCLES
	if mood == "happy": return CHEER_STEP * CHEER_FRAMES.size() * CHEER_CYCLES
	return 0.0

# The text rises in whole pixels and fades in 25 percent steps over the last 60 percent.
func _apply_popup(record: Dictionary) -> void:
	var node: Label = record.label
	var local: float = record.time - record.delay
	if local < 0.0:
		node.visible = false
		return
	if not record.get("sounded", false): record.sounded = true; preload("res://scripts/audio/audio_manager.gd").emit_for(self, "coin_gain" if record.positive else "coin_spend")
	var progress := clampf(local / POPUP_TIME, 0.0, 1.0)
	record.done = progress >= 1.0
	node.visible = not record.done
	node.position.y = POPUP_Y - floorf(progress * POPUP_RISE)
	var fade := floorf(clampf((progress - 0.4) / 0.6, 0.0, 1.0) * 4.0)
	node.modulate.a = maxf(1.0 - 0.25 * fade, 0.25)

func _apply_reaction() -> void:
	if mood == "":
		return
	var finished := reaction_time >= _reaction_length()
	if mood == "angry":
		if finished:
			neighbor_node.texture = lib.frame("khoi", 0)
			neighbor_node.position = NEIGHBOR_POS
			neighbor_desk.position.x = NEIGHBOR_POS.x - 8
			return
		var frame: Array = SLAM_FRAMES[int(reaction_time / SLAM_STEP) % SLAM_FRAMES.size()]
		neighbor_node.texture = lib.frame("khoi", frame[0])
		neighbor_node.position = NEIGHBOR_POS + Vector2(0, frame[1])
		neighbor_desk.position.x = NEIGHBOR_POS.x - 8 + frame[2]
	else:
		var hop: Array = CHEER_FRAMES[0] if finished else CHEER_FRAMES[int(reaction_time / CHEER_STEP) % CHEER_FRAMES.size()]
		neighbor_node.texture = lib.frame("khoi", 0 if finished else hop[0])
		neighbor_node.position = NEIGHBOR_POS + Vector2(0, 0 if finished else hop[1])

func advance(delta: float) -> void:
	for record in popups:
		if record.done: continue
		record.time += delta
		_apply_popup(record)
	if reaction_time >= 0.0 and reaction_time < _reaction_length():
		reaction_time += delta
		_apply_reaction()

func _process(delta: float) -> void:
	advance(delta)

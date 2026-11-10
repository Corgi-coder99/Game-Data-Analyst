extends Node2D
signal seated
signal dialog_closed
signal desk_clicked
const Palette = preload("res://scripts/v2/palette.gd")
const Library = preload("res://scripts/v2/sprite_lib.gd")
const DESK_RECT := Rect2(136,200,48,24)
const WALK_TIMES := [0.16,0.12,0.16,0.12]
const TYPE_TIMES := [0.12,0.16]
var lib := Library.new()
var phase := "sang"
var clock_hour := 8
var clock_minute := 0
var windows: Array = []
var colleagues: Array = []
var player: Sprite2D
var boss: Sprite2D
var door: Sprite2D
var dialog: Panel
var speaker_label: Label
var dialog_text: RichTextLabel
var arrival_active := false
var player_seated := false
var travel := 0.0
var elapsed := 0.0
var desk_button: Button
var hint_label: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for y in range(0,128,16):
		for x in range(0,640,16):
			place("wall",Vector2i(x,y))
	for y in range(128,360,16):
		for x in range(0,640,16):
			place("floor",Vector2i(x,y))
	for x in range(0,640,16):
		place("baseboard",Vector2i(x,120))
	# Opaque pools of light sit behind furniture.
	var light_layer := Node2D.new()
	light_layer.name = "Light"
	add_child(light_layer)
	light_layer.draw.connect(_draw_light.bind(light_layer))
	for x in [56,96,208,248]:
		windows.append(place("window",Vector2i(x,48)))
	place("clock",Vector2i(408,48))
	var hands := Node2D.new()
	hands.name = "ClockHands"
	add_child(hands)
	hands.draw.connect(_draw_clock.bind(hands))
	door = place("door",Vector2i(560,88))
	place("cabinet",Vector2i(480,112))
	place("plant",Vector2i(32,120))
	place("plant",Vector2i(608,128),1)
	add_label("LỤC CHÂU / PHÒNG PHÂN TÍCH",Vector2i(48,16),12,8)
	add_label("TÀI CHÍNH",Vector2i(544,72),8,7)
	var names := ["Bạn","Anh Khôi","Bé Mai","Chú Tư"]
	var ids := ["player","khoi","mai","tu"]
	for i in range(4):
		var x := 136 + i*112
		place("chair",Vector2i(x+16,208))
		var person := place(ids[i],Vector2i(x+16,184),6)
		if i == 0:
			player = person
		else:
			colleagues.append({"node":person,"id":ids[i],"offset":i*0.53})
		place("desk",Vector2i(x,200),1 if i == 0 else 0)
		add_label(names[i],Vector2i(x,240),8,8 if i == 0 else 7)
	boss = place("hanh",Vector2i(564,104))
	boss.visible = false
	desk_button = Button.new()
	desk_button.name = "DeskButton"
	desk_button.position = DESK_RECT.position
	desk_button.size = DESK_RECT.size
	desk_button.flat = true
	for state in ["normal","hover","pressed","focus","disabled"]:
		desk_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	desk_button.focus_mode = Control.FOCUS_NONE
	desk_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	desk_button.pressed.connect(func(): desk_clicked.emit())
	add_child(desk_button)
	add_label("LỐI VÀO  →",Vector2i(8,280),8,7)
	hint_label = add_label("Enter : mở bàn làm việc",Vector2i(136,264),8,7)
	_build_dialog()
	set_phase("sang")
	play_arrival()

func place(id: String, point: Vector2i, frame_index: int = 0) -> Sprite2D:
	var node := lib.sprite(id,frame_index)
	node.position = point
	node.name = id.capitalize()
	add_child(node)
	return node

func add_label(text: String, point: Vector2i, font_size: int, ink: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Palette.color(ink))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _build_dialog() -> void:
	dialog = Panel.new()
	dialog.name = "Dialog"
	dialog.position = Vector2i(24,272)
	dialog.size = Vector2i(592,80)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(2)
	style.border_color = Palette.color(5)
	style.set_border_width_all(1)
	style.anti_aliasing = false
	dialog.add_theme_stylebox_override("panel",style)
	add_child(dialog)
	speaker_label = Label.new()
	speaker_label.position = Vector2i(12,4)
	speaker_label.size = Vector2i(568,16)
	speaker_label.add_theme_font_size_override("font_size",12)
	speaker_label.add_theme_color_override("font_color",Palette.color(8))
	speaker_label.clip_text = true
	dialog.add_child(speaker_label)
	dialog_text = RichTextLabel.new()
	dialog_text.position = Vector2i(12,23)
	dialog_text.size = Vector2i(568,45)
	dialog_text.add_theme_font_size_override("normal_font_size",12)
	dialog_text.add_theme_color_override("default_color",Palette.color(7))
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

func set_phase(value: String) -> bool:
	if not value in ["sang","trua","chieu"]:
		return false
	phase = value
	var index := ["sang","chieu","trua"].find(phase)
	for window in windows:
		window.texture = lib.frame("window",index)
	if has_node("Light"):
		get_node("Light").queue_redraw()
	queue_redraw()
	return true

func set_clock(hour: int, minute: int) -> void:
	clock_hour = posmod(hour,24)
	clock_minute = posmod(minute,60)
	if has_node("ClockHands"):
		get_node("ClockHands").queue_redraw()
	queue_redraw()

func play_arrival() -> void:
	if player == null:
		return
	player.position = Vector2i(-16,264)
	player_seated = false
	arrival_active = true
	travel = 0.0

func seat_now() -> void:
	# T-019c: skip the arrival animation (later days start seated, Esc skips on day one).
	if player == null:
		return
	var was_arriving := arrival_active
	arrival_active = false
	player.position = Vector2i(152,184)
	player.texture = lib.frame("player",6)
	if not player_seated:
		player_seated = true
		if was_arriving:
			seated.emit()

func play_boss_appears(line: String) -> void:
	door.texture = lib.frame("door",1)
	boss.show()
	show_dialog("Chị Hạnh",line)

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
	door.texture = lib.frame("door",0)
	dialog_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	var confirm: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)
	if confirm:
		if dialog.visible:
			hide_dialog()
		else:
			desk_clicked.emit()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	advance(delta)

func animation_frame(time: float, durations: Array) -> int:
	var total := 0.0
	for duration in durations:
		total += duration
	var cursor := fposmod(time,total)
	for i in range(durations.size()):
		cursor -= durations[i]
		if cursor < 0:
			return i
	return 0

func advance(delta: float) -> void:
	elapsed += delta
	for colleague in colleagues:
		var time: float = elapsed + colleague.offset
		var frame_index := 6 + animation_frame(time,TYPE_TIMES)
		if fposmod(time,4.0) > 3.6:
			frame_index = 1 if fposmod(time,4.0) > 3.84 else 0
		colleague.node.texture = lib.frame(colleague.id,frame_index)
	if arrival_active:
		travel += delta * 72.0
		if travel < 168:
			player.position = Vector2i(roundi(-16+travel),264)
		elif travel < 248:
			player.position = Vector2i(152,roundi(264-(travel-168)))
		else:
			player.position = Vector2i(152,184)
			arrival_active = false
			player_seated = true
			seated.emit()
		player.texture = lib.frame("player",2+animation_frame(elapsed,WALK_TIMES) if arrival_active else 6)
	elif player_seated:
		player.texture = lib.frame("player",6+animation_frame(elapsed,TYPE_TIMES))

func _draw_light(layer: Node2D) -> void:
	var ink := 14 if phase == "sang" else (28 if phase == "chieu" else 20)
	for x in [56,208]:
		layer.draw_colored_polygon(PackedVector2Array([Vector2(x,136),Vector2(x+72,136),Vector2(x+128,184),Vector2(x+40,184)]),Palette.color(ink))
		# Mullion shadows are opaque palette colors.
		layer.draw_line(Vector2(x+36,136),Vector2(x+88,184),Palette.color(3),2,false)

func _draw_clock(layer: Node2D) -> void:
	# Clock hands are rounded to whole pixels; no texture rotation.
	var center := Vector2(416,56)
	var minute_angle := float(clock_minute)*TAU/60.0-PI/2
	var hour_angle := float(clock_hour%12+clock_minute/60.0)*TAU/12.0-PI/2
	layer.draw_line(center,(center+Vector2(cos(minute_angle),sin(minute_angle))*5).round(),Palette.color(3),1,false)
	layer.draw_line(center,(center+Vector2(cos(hour_angle),sin(hour_angle))*3).round(),Palette.color(3),1,false)




func set_hint_visible(value: bool) -> void:
	if hint_label != null:
		hint_label.visible = value

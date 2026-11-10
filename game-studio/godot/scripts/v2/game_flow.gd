extends Node
# Orchestrates one ten-day game: TITLE -> NEW_GAME -> DAY_START -> WORK -> SUBMITTED -> REVIEW
# -> (EVENING -> DAY_START | ENDING) -> END_SCREEN. Only the public WorldGame API is used here;
# the hidden labels are read solely by review_scene.gd after a day has ended.
const Game = preload("res://scripts/world/world_game.gd")
const Palette = preload("res://scripts/v2/palette.gd")
const OfficeScene = preload("res://scenes/v2/office.tscn")
const DesktopScene = preload("res://scenes/v2/desktop.tscn")
const TitleScene = preload("res://scenes/v2/title.tscn")
const ReviewScene = preload("res://scenes/v2/review.tscn")
const EndingScene = preload("res://scenes/v2/ending.tscn")
const EveningScene = preload("res://scripts/life/evening_scene.gd")
const LifeGame = preload("res://scripts/life/life_game.gd")
const HORIZON := 10
const FADE_STEP := 0.035
const NOON := 12 * 60
signal state_changed(new_state: String)
@export var autostart := true
var fade_enabled := true
var state := ""
var visited: Array = []
var game: RefCounted
var seed_used := 0
var strings: Dictionary
var phase := "sang"
var current: Node
var desktop: Control
var office: Node2D
var title_view: Control
var review_view: Control
var ending_view: Control
var evening_view: Control
var life: RefCounted
var evening_enabled := true
var submission: Dictionary = {}
var before_status: Dictionary = {}
var last_message := ""
var boss_log: Array = []
var boss_shown := false
var first_tool_done := false
var fade_layer: CanvasLayer
var fade_rect: ColorRect
var fade_time := -1.0
var fade_builder := Callable()
var fade_swapped := false
var fade_queued := Callable()

func _ready() -> void:
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.size = Vector2(640, 360)
	fade_rect.color = Color(Palette.color(1), 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	if autostart: start_title()

func _set_state(value: String) -> void:
	state = value
	visited.append(value)
	state_changed.emit(value)

# ---- transitions -------------------------------------------------------

# Builds a view, fading to the dark layer and back in 25 percent steps (about 280 ms in total).
func _show(builder: Callable) -> void:
	if not fade_enabled or fade_rect == null:
		builder.call()
		return
	if fade_time >= 0.0:
		fade_queued = builder
		return
	fade_builder = builder
	fade_time = 0.0
	fade_swapped = false
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	if fade_time < 0.0: return
	fade_time += delta
	var step := int(fade_time / FADE_STEP)
	var alpha := 0.0
	if step >= 8:
		fade_time = -1.0
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_rect.color = Color(Palette.color(1), 0.0)
		if not fade_queued.is_null():
			var queued := fade_queued
			fade_queued = Callable()
			_show(queued)
		return
	if step >= 4:
		if not fade_swapped:
			fade_swapped = true
			fade_builder.call()
		alpha = 1.0 - 0.25 * float(step - 3)
	else:
		alpha = 0.25 * float(step + 1)
	fade_rect.color = Color(Palette.color(1), alpha)

func _swap(view: Node) -> void:
	if current != null and is_instance_valid(current) and current != view:
		if current == desktop:
			desktop.hide()
		else:
			remove_child(current)
			current.queue_free()
	current = view
	if view.get_parent() == null: add_child(view)
	if view is CanvasItem: view.show()

func _reset_game() -> void:
	if desktop != null and is_instance_valid(desktop):
		if desktop.get_parent() != null: remove_child(desktop)
		if current == desktop: current = null
		desktop.queue_free()
	desktop = null
	office = null
	review_view = null
	ending_view = null
	evening_view = null
	submission = {}
	before_status = {}
	boss_shown = false
	first_tool_done = false

# ---- steps ------------------------------------------------------------

func start_title() -> void:
	_reset_game()
	game = null
	_set_state("TITLE")
	_show(func():
		title_view = TitleScene.instantiate()
		_swap(title_view)
		title_view.play_requested.connect(new_game.bind(-1, {}))
		title_view.quit_requested.connect(func(): get_tree().quit()))

func new_game(seed_value: int = -1, overrides: Dictionary = {}) -> void:
	var chosen := seed_value
	if chosen < 0:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--seed="): chosen = int(argument.trim_prefix("--seed="))
	if chosen < 0: chosen = int(Time.get_unix_time_from_system() * 1000.0) % 1000000
	seed_used = chosen
	start_with_game(Game.new(chosen, HORIZON, overrides))

func start_with_game(value: RefCounted) -> void:
	_reset_game()
	boss_log.clear()
	visited.clear()
	last_message = ""
	game = value
	life = LifeGame.new(seed_used)
	_set_state("NEW_GAME")
	_enter_day_start()

func _enter_day_start() -> void:
	_set_state("DAY_START")
	game.begin_day()
	phase = "sang"
	boss_shown = false
	first_tool_done = false
	var day := int(game.status().day)
	_show(func(): _build_office(day))

func _build_office(day: int) -> void:
	office = OfficeScene.instantiate()
	_swap(office)
	office.set_phase("sang")
	office.set_clock(8, 30)
	office.seated.connect(_on_seated)
	office.dialog_closed.connect(_on_dialog_closed)
	office.desk_clicked.connect(_on_desk_clicked)
	if day > 1: office.seat_now()

func _on_seated() -> void:
	if state != "DAY_START" or boss_shown or office == null: return
	boss_shown = true
	var text := str(game.question_today().get("text", ""))
	boss_log.append({"category":"question", "text":text})
	office.set_hint_visible(false)
	office.play_boss_appears(text)

func _on_dialog_closed() -> void:
	if state == "DAY_START" and boss_shown: _enter_work()

func _on_desk_clicked() -> void:
	if state != "DAY_START" or office == null: return
	if not boss_shown: office.seat_now()
	else: _enter_work()

# Skips the arrival animation, then the boss line, straight to the desk.
func skip_intro() -> void:
	if state != "DAY_START" or office == null: return
	if not boss_shown: office.seat_now()
	if state == "DAY_START" and office.dialog.visible: office.hide_dialog()

func _unhandled_input(event: InputEvent) -> void:
	if state != "DAY_START" or office == null: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		skip_intro()
		get_viewport().set_input_as_handled()

func _enter_work() -> void:
	if state != "DAY_START": return
	_set_state("WORK")
	_show(_build_desktop)

func _build_desktop() -> void:
	if desktop == null:
		desktop = DesktopScene.instantiate()
		desktop.setup(game)
		desktop.tool_used.connect(_on_tool_used)
		desktop.time_changed.connect(_on_time_changed)
		desktop.report_submitted.connect(submit_report)
	else:
		desktop.start_day()
	_swap(desktop)
	desktop.refresh()

func _on_tool_used(_uid: String, _tool_id: String, _result: Dictionary) -> void:
	pass

func _on_time_changed(minutes: int) -> void:
	# The window light changes after the first tool use or once the clock passes noon.
	if not first_tool_done or minutes >= NOON:
		first_tool_done = true
		phase = "trua"

func clock_text() -> String:
	return "" if desktop == null else desktop.clock.text

func submit_report(input: Dictionary) -> Dictionary:
	if state != "WORK" or game == null: return _reject("day_closed")
	var result: Dictionary = game.submit_report(input)
	if not result.ok: return _reject(str(result.error))
	_set_state("SUBMITTED")
	submission = input.duplicate(true)
	if desktop != null: desktop.report_window.lock(true)
	before_status = game.status()
	var ended: Dictionary = game.end_day()
	phase = "chieu"
	_enter_review(int(ended.day))
	return {"ok":true}

func _reject(code: String) -> Dictionary:
	last_message = str(strings.errors.get(code, strings.ui.unknown))
	if state == "WORK" and desktop != null: desktop.report_window.show_error(code)
	return {"ok":false, "error":code, "message":last_message}

func _enter_review(day: int) -> void:
	_set_state("REVIEW")
	_show(func(): _build_review(day))

func _build_review(day: int) -> void:
	review_view = ReviewScene.instantiate()
	_swap(review_view)
	review_view.line_shown.connect(func(category, text): boss_log.append({"category":category, "text":text}))
	review_view.finished.connect(_after_review)
	review_view.life_text = strings.life.review_line % [life.projected_net_worth(game.status()), life.mood]
	review_view.show_review(game, day, submission, before_status)

# Used by tests and scripts: one press of Continue.
func continue_review() -> void:
	if state == "REVIEW" and review_view != null: review_view.next_step()

func _after_review() -> void:
	if state != "REVIEW": return
	if bool(game.status().finished): _enter_ending()
	elif evening_enabled: _enter_evening()
	else: _enter_day_start()

# T-024: after-work life between two working days.
func _enter_evening() -> void:
	_set_state("EVENING")
	var public: Dictionary = game.status()
	_show(func(): _build_evening(public))

func _build_evening(public: Dictionary) -> void:
	evening_view = EveningScene.new()
	_swap(evening_view)
	evening_view.finished.connect(_after_evening)
	evening_view.open(life, public)

func _after_evening(_skipped: bool = false) -> void:
	if state != "EVENING": return
	life.end_evening()
	_enter_day_start()

func _enter_ending() -> void:
	_set_state("ENDING")
	var final_status: Dictionary = game.status()
	life.settle_for_ending(final_status)
	_show(func(): _build_ending(final_status))
	_set_state("END_SCREEN")

func _build_ending(final_status: Dictionary) -> void:
	ending_view = EndingScene.instantiate()
	_swap(ending_view)
	ending_view.replay_requested.connect(new_game.bind(-1, {}))
	ending_view.title_requested.connect(start_title)
	ending_view.life_lines = [strings.life.ending_net % life.net_worth(), strings.life.ending_mood % [life.mood, strings.life.mood_names[life.mood_band()]], strings.life.ending_flavor[life.mood_band()]]
	ending_view.show_ending(final_status)
	boss_log.append({"category":ending_view.boss_category, "text":ending_view.boss_line})

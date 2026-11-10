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
const CommuteScene = preload("res://scenes/v2/commute.tscn")
const MorningScene = preload("res://scripts/life/morning_scene.gd")
const ShopPanel = preload("res://scripts/life/shop_panel.gd")
const OvertimeScene = preload("res://scripts/life/overtime_scene.gd")
const Hud = preload("res://scripts/life/hud.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const LetterScene = preload("res://scripts/v2/letter_scene.gd")
const WallScene = preload("res://scripts/v2/wall_scene.gd")
const SettingsScene = preload("res://scripts/v2/settings_scene.gd")
const LeaveScene = preload("res://scripts/v2/leave_scene.gd")
const Toast = preload("res://scripts/v2/toast.gd")
const HUD_STATES := ["MORNING", "TRANSPORT", "COMMUTE", "SHOP", "DAY_START", "WORK", "OVERTIME", "EVENING"]
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
var commute: Node2D
var commute_enabled := true
var title_view: Control
var review_view: Control
var ending_view: Control
var evening_view: Control
var life: RefCounted
var evening_enabled := true
# T-026: the daily life loop (morning, transport, street, shops, overtime, bills, sleep). It runs only
# when both daily_enabled and commute_enabled are true, so older flows keep their old behavior.
var daily_enabled := true
var overtime_enabled := true
var hud_layer: CanvasLayer
var hud: Control
var morning_view: Control
var shop_view: Control
var overtime_view: Control
var late_minutes := 0
# T-030: the local meta layer (profile, attendance, Daily Shift, wall of fame). It is created only for the
# real game (autostart); tests inject their own with a temporary profile path and a fixed clock.
var meta: RefCounted
var meta_enabled := true
var run_mode := "run"
var pre_run_queue: Array = []
var meta_view: Control
var toast_layer: CanvasLayer
var toast_view: Control
var toast_log: Array = []
var focus_info: Dictionary = {"bonus": 0, "reason": "neutral"}
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
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 6
	hud_layer.visible = false
	add_child(hud_layer)
	hud = Hud.new()
	hud_layer.add_child(hud)
	toast_layer = CanvasLayer.new()
	toast_layer.layer = 8
	add_child(toast_layer)
	toast_view = Toast.new()
	toast_layer.add_child(toast_view)
	if autostart and meta_enabled and meta == null: meta = Meta.new()
	if autostart: start_title()

func toast(text: String) -> void:
	toast_log.append(text)
	if toast_view != null: toast_view.push(text)

func daily_active() -> bool:
	return daily_enabled and commute_enabled

func _set_state(value: String) -> void:
	state = value
	visited.append(value)
	_update_hud()
	state_changed.emit(value)

func _update_hud() -> void:
	if hud_layer == null: return
	var on: bool = life != null and life.vitals != null and state in HUD_STATES
	hud_layer.visible = on
	if on:
		hud.set_focus(strings.daily.focus_label % strings.daily.focus[focus_info.reason], state == "WORK")

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
	commute = null
	office = null
	review_view = null
	ending_view = null
	evening_view = null
	morning_view = null
	shop_view = null
	overtime_view = null
	late_minutes = 0
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
		title_view.set_profile(meta)
		title_view.play_requested.connect(begin_run.bind("run"))
		title_view.daily_requested.connect(begin_run.bind("daily"))
		title_view.wall_requested.connect(open_meta_view.bind("WALL"))
		title_view.settings_requested.connect(open_meta_view.bind("SETTINGS"))
		title_view.leave_requested.connect(open_meta_view.bind("LEAVE"))
		title_view.quit_requested.connect(func(): get_tree().quit()))

# ---- T-030: meta screens and the run entry ---------------------------------------------------------

# Play or Daily Shift from the title: first-run explanation and attendance letter first, then the run.
func begin_run(mode: String) -> void:
	run_mode = mode
	if meta == null:
		new_game(-1, {})
		return
	pre_run_queue = meta.pre_run_screens()
	_next_pre_run()

func _next_pre_run() -> void:
	if pre_run_queue.is_empty():
		new_game(meta.daily_seed() if run_mode == "daily" else -1, {})
		return
	var screen: Dictionary = pre_run_queue.pop_front()
	_set_state("INTRO" if screen.type == "intro" else "LETTER")
	_show(func():
		meta_view = LetterScene.new()
		_swap(meta_view)
		meta_view.open(screen)
		meta_view.finished.connect(_next_pre_run, CONNECT_ONE_SHOT))

func open_meta_view(which: String) -> void:
	if meta == null: return
	_set_state(which)
	_show(func():
		match which:
			"WALL": meta_view = WallScene.new()
			"SETTINGS": meta_view = SettingsScene.new()
			_: meta_view = LeaveScene.new()
		_swap(meta_view)
		meta_view.open(meta)
		meta_view.back_requested.connect(start_title, CONNECT_ONE_SHOT))

func _replay() -> void:
	run_mode = "run"
	new_game(-1, {})

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
	focus_info = {"bonus": 0, "reason": "neutral"}
	if daily_active():
		life.enable_daily()
		if meta != null: meta.begin_run(life)
		hud.bind(life)
	else:
		hud.bind(null)
	_set_state("NEW_GAME")
	_enter_day_start()

func _enter_day_start() -> void:
	if daily_active():
		_enter_morning()
		return
	_set_state("DAY_START")
	game.begin_day()
	phase = "sang"
	boss_shown = false
	first_tool_done = false
	var day := int(game.status().day)
	if commute_enabled:
		_show(func(): _build_commute(day))
	else:
		_show(func(): _build_office(day))

# ---- T-026: the daily life morning ---------------------------------------------------------------

func _enter_morning() -> void:
	_set_state("MORNING")
	var public: Dictionary = game.status()
	var info: Dictionary = life.vitals.begin_morning(int(public.day) + 1)
	var sick := {}
	if bool(info.sick): sick = {"bill": int(info.get("bill", 0)), "hr": life.vitals.hr_warning}
	_show(func(): _build_morning(public, sick))

func _build_morning(public: Dictionary, sick: Dictionary) -> void:
	morning_view = MorningScene.new()
	_swap(morning_view)
	morning_view.breakfast_done.connect(func(_choice): _set_state("TRANSPORT"))
	morning_view.finished.connect(_on_transport_chosen)
	morning_view.open(life, public, sick)

func _on_transport_chosen(id: String) -> void:
	if state != "MORNING" and state != "TRANSPORT": return
	var public: Dictionary = game.status()
	if id == "":
		late_minutes = life.vitals.late_minutes
		_begin_work_day()
		return
	_set_state("COMMUTE")
	var day := int(public.day) + 1
	_show(func(): _build_daily_commute(day, int(public.trust), id))

func _build_daily_commute(day: int, trust: int, id: String) -> void:
	office = null
	commute = CommuteScene.instantiate()
	commute.day = day
	commute.trust = trust
	commute.setup_interactive(day, trust, life.vitals, id)
	_swap(commute)
	commute.shop_requested.connect(_open_shop)
	commute.finished.connect(_arrived, CONNECT_ONE_SHOT)

func _open_shop(ids: Array, _storefront: String) -> void:
	if state != "COMMUTE": return
	_set_state("SHOP")
	shop_view = ShopPanel.new()
	add_child(shop_view)
	shop_view.closed.connect(_close_shop)
	shop_view.open(life, ids, game.status())

func _close_shop() -> void:
	if state != "SHOP": return
	if shop_view != null and is_instance_valid(shop_view):
		remove_child(shop_view)
		shop_view.queue_free()
	shop_view = null
	_set_state("COMMUTE")
	if commute != null and is_instance_valid(commute): commute.resume()

func _arrived() -> void:
	if state != "COMMUTE": return
	var result: Dictionary = life.vitals.finish_commute()
	late_minutes = int(result.late)
	commute = null
	_begin_work_day()

# The day starts once the player reaches the office: Focus decides the analysis Energy bonus and a
# late arrival moves the work clock (never by more than an hour).
func _begin_work_day() -> void:
	focus_info = life.vitals.focus()
	_set_state("DAY_START")
	game.begin_day(int(focus_info.bonus))
	if late_minutes > 0:
		game.set("_minutes", int(game.status().minutes) + late_minutes)
	phase = "sang"
	boss_shown = false
	first_tool_done = false
	var day := int(game.status().day)
	_update_hud()
	_show(func(): _build_office(day))

# One press of Enter in whatever daily screen is open (used by tests and the quick mode).
func quick_advance() -> void:
	match state:
		"MORNING", "TRANSPORT":
			if morning_view != null: morning_view.accept_default()
		"COMMUTE":
			if commute != null and is_instance_valid(commute): commute.hurry()
		"SHOP":
			if shop_view != null: shop_view.leave_shop()
		"OVERTIME":
			if overtime_view != null: overtime_view.go_home()

# T-022: the morning commute plays before the office; it only uses public values (day, trust).
func _build_commute(day: int) -> void:
	office = null
	commute = CommuteScene.instantiate()
	commute.day = day
	commute.trust = int(game.status().trust)
	commute.setup(day, commute.trust)
	_swap(commute)
	commute.finished.connect(func(): _commute_done(day), CONNECT_ONE_SHOT)

func _commute_done(day: int) -> void:
	if state != "DAY_START": return
	commute = null
	_show(func(): _build_office(day))

func skip_commute() -> void:
	if commute != null and is_instance_valid(commute): commute.skip()

func _build_office(day: int) -> void:
	office = OfficeScene.instantiate()
	_swap(office)
	office.set_phase("sang")
	var arrival := 510 + late_minutes if daily_active() else 510
	office.set_clock(arrival / 60, arrival % 60)
	office.seated.connect(_on_seated)
	office.dialog_closed.connect(_on_dialog_closed)
	office.desk_clicked.connect(_on_desk_clicked)
	if day > 1: office.seat_now()

func _on_seated() -> void:
	if state != "DAY_START" or boss_shown or office == null: return
	boss_shown = true
	var text := str(game.question_today().get("text", ""))
	if daily_active() and late_minutes > 0:
		var remark: String = strings.daily.late_remark
		boss_log.append({"category":"late", "text":remark})
		text = remark + " " + text
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
	if state != "DAY_START": return
	if commute != null and is_instance_valid(commute): skip_commute()
	if office == null: return
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
	if life != null and life.vitals != null: life.vitals.after_work(before_status, game.status())
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
	if life.vitals != null and life.vitals.hr_warning and life.vitals.sick_today: review_view.life_note = strings.daily.hr_line
	review_view.show_review(game, day, submission, before_status)

# Used by tests and scripts: one press of Continue.
func continue_review() -> void:
	if state == "REVIEW" and review_view != null: review_view.next_step()

func _after_review() -> void:
	if state != "REVIEW": return
	_record_day()
	if bool(game.status().finished): _enter_ending()
	elif daily_active() and overtime_enabled: _enter_overtime()
	elif evening_enabled: _enter_evening()
	else: _close_day()

# T-030: the finished day goes to the ScoreSink (public parts only); achievements appear as toasts.
func _record_day() -> void:
	if meta == null or game == null: return
	var after: Dictionary = game.status()
	var context := {"focus_bonus": int(focus_info.bonus), "late_minutes": late_minutes}
	var outcome: Dictionary = meta.finish_day(game, int(after.day), submission, before_status, after, context, run_mode, seed_used)
	for text in outcome.get("toasts", []): toast(str(text))

# T-026: stay late or go home. The day's wage arrives here.
func _enter_overtime() -> void:
	_set_state("OVERTIME")
	var public: Dictionary = game.status()
	_show(func(): _build_overtime(public))

func _build_overtime(public: Dictionary) -> void:
	overtime_view = OvertimeScene.new()
	_swap(overtime_view)
	overtime_view.finished.connect(_after_overtime)
	overtime_view.open(life, public)

func _after_overtime(_hours: int = 0) -> void:
	if state != "OVERTIME": return
	if evening_enabled: _enter_evening()
	else: _close_day()

func _close_day() -> void:
	life.night()
	_enter_day_start()

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
	life.night()
	_enter_day_start()

func _enter_ending() -> void:
	_set_state("ENDING")
	var final_status: Dictionary = game.status()
	life.settle_for_ending(final_status)
	if meta != null:
		for text in meta.finish_run(final_status).get("toasts", []): toast(str(text))
	_show(func(): _build_ending(final_status))
	_set_state("END_SCREEN")

func _build_ending(final_status: Dictionary) -> void:
	ending_view = EndingScene.instantiate()
	_swap(ending_view)
	ending_view.replay_requested.connect(_replay)
	ending_view.title_requested.connect(start_title)
	ending_view.life_lines = [strings.life.ending_net % life.net_worth(), strings.life.ending_mood % [life.mood, strings.life.mood_names[life.mood_band()]], strings.life.ending_flavor[life.mood_band()]]
	if life.vitals != null:
		var v: RefCounted = life.vitals
		ending_view.life_lines.append(strings.daily.ending_vitals % [v.stamina, life.mood, v.health, v.stress])
		var spend: Dictionary = v.spending_summary()
		var parts: Array = []
		for key in spend: parts.append("%s $%d" % [strings.daily.spend_names[key], int(spend[key])])
		ending_view.life_lines.append(strings.daily.ending_spend % ", ".join(parts) if not parts.is_empty() else strings.daily.ending_spend_none)
	ending_view.show_ending(final_status)
	boss_log.append({"category":ending_view.boss_category, "text":ending_view.boss_line})

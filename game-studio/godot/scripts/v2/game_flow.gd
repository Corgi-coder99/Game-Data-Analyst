extends Node
const FontTheme = preload("res://scripts/v2/theme_v2.gd")  # T-039: loading it installs the UI font
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
const ConsentScene = preload("res://scripts/v2/consent_scene.gd")
const Playlog = preload("res://scripts/telemetry/playlog.gd")
var telemetry: RefCounted
const LeaveScene = preload("res://scripts/v2/leave_scene.gd")
const Toast = preload("res://scripts/v2/toast.gd")
const Juice = preload("res://scripts/v2/juice.gd")  # T-039: feedback animations (visual only)
# T-035: the learning layer (state in the profile, first-run choice, daily settlement of XP and cards).
const LearnState = preload("res://scripts/learn/learn_state.gd")
const TutorialChoice = preload("res://scripts/v2/learn/tutorial_choice.gd")
const HUD_STATES := ["MORNING", "TRANSPORT", "COMMUTE", "SHOP", "DAY_START", "WORK", "OVERTIME", "EVENING"]
const HORIZON := 10
# T-045: world-config overrides for the gentle Practice run. Only data: the rules code is unchanged
# (trust_floor is the one additive career key; absent means 0, so every other mode is identical).
const PRACTICE_OVERRIDES := {"world": {
	"career": {"initial_trust": 60, "trust_floor": 30, "warning": 0, "demote": 0, "low_trust_days": 99, "max_demotions": 99},
	"analysis_energy": 5,
	"clock": {"on_time": 1080, "late": 1200},
	"kind_weights": {"signal": 70, "trap": 8, "partial": 6, "stale": 6, "noise": 10},
	"grading": {"wrong_factor": 1.2},
	"win": {"demo": "thuc_tap"},
}}
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
var learn_state: RefCounted
var learn_outcome: Dictionary = {}
var tutorial_choice_enabled := false
var choice_view: Control
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
	if autostart and meta_enabled and meta == null:
		meta = Meta.new()
		tutorial_choice_enabled = true
	if autostart: preload("res://scripts/audio/audio_manager.gd").install(self)
	add_child(preload("res://scripts/v2/juice_hooks.gd").new())
	apply_display_settings()
	announce_rollover()
	if meta != null and telemetry == null: telemetry = Playlog.new(meta.profile)
	if telemetry != null: telemetry.session_start()
	if autostart: start_title()

# T-039: the profile's display settings (pixel font, reduce motion). Without a profile the defaults stay.
func apply_display_settings() -> void:
	if meta == null or meta.profile == null: return
	var settings: Dictionary = meta.profile.data.settings
	FontTheme.set_pixel_font(bool(settings.get("pixel_font", true)))
	Juice.reduce_motion = bool(settings.get("reduce_motion", false))

# A month ended since the last session: its Employee of the Month plaque was just settled.
func announce_rollover() -> void:
	if meta == null: return
	for winner in meta.rollover_winners: toast("Employee of the Month: %s" % winner.month)
	meta.rollover_winners = []

func toast(text: String) -> void:
	preload("res://scripts/audio/audio_manager.gd").emit_for(self, "achievement")
	toast_log.append(text)
	Juice.confetti(toast_layer, Vector2(320, 52))
	if toast_view != null: toast_view.push(text)

func daily_active() -> bool:
	return daily_enabled and commute_enabled and not practice_mode()

# T-045: the gentle "Practice" run: no firing, no morning/commute/evening, nothing saved to the profile.
func practice_mode() -> bool:
	return run_mode == "practice"

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
	if not fade_enabled or fade_rect == null or Juice.reduce_motion or not Juice.enabled or Juice.instant:
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
	if telemetry != null and game != null: telemetry.quit_run(state, game.status())
	_reset_game()
	game = null
	_set_state("TITLE")
	_show(func():
		title_view = TitleScene.instantiate()
		_swap(title_view)
		title_view.set_profile(meta)
		title_view.play_requested.connect(begin_run.bind("run"))
		title_view.daily_requested.connect(begin_run.bind("daily"))
		title_view.practice_requested.connect(begin_run.bind("practice"))
		title_view.wall_requested.connect(open_meta_view.bind("WALL"))
		title_view.settings_requested.connect(open_meta_view.bind("SETTINGS"))
		title_view.leave_requested.connect(open_meta_view.bind("LEAVE"))
		title_view.quit_requested.connect(_quit_game))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit_game()

func _quit_game() -> void:
	if telemetry != null and game != null: telemetry.quit_run(state, game.status())
	get_tree().quit()

# ---- T-030: meta screens and the run entry ---------------------------------------------------------

# Play or Daily Shift from the title: first-run explanation and attendance letter first, then the run.
func begin_run(mode: String) -> void:
	run_mode = mode
	if meta == null:
		new_game(-1, PRACTICE_OVERRIDES if practice_mode() else {})
		return
	pre_run_queue = meta.pre_run_screens()
	_next_pre_run()

func _next_pre_run() -> void:
	if telemetry != null and not bool(meta.profile.data.telemetry.seen) and (pre_run_queue.is_empty() or str(pre_run_queue[0].get("type", "")) != "intro"):
		_enter_consent(_next_pre_run)
		return
	if pre_run_queue.is_empty():
		if tutorial_choice_enabled and meta != null and str(meta.profile.data.learn.tutorial) == "":
			_enter_tutorial_choice()
			return
		_start_selected_run()
		return
	var screen: Dictionary = pre_run_queue.pop_front()
	_set_state("INTRO" if screen.type == "intro" else "LETTER")
	_show(func():
		meta_view = LetterScene.new()
		_swap(meta_view)
		meta_view.open(screen)
		meta_view.finished.connect(_next_pre_run, CONNECT_ONE_SHOT))

func _enter_consent(after: Callable) -> void:
	# Persist No before displaying: closing here must not opt in or prompt again.
	meta.profile.data.telemetry.seen = true
	meta.profile.save()
	_set_state("CONSENT")
	_show(func():
		meta_view = ConsentScene.new()
		_swap(meta_view)
		meta_view.chosen.connect(func(value):
			telemetry.set_consent(value)
			after.call(), CONNECT_ONE_SHOT))

# T-035: the first-run choice: guided tutorial days 1-5 or skip. Remembered in the profile.
func _enter_tutorial_choice() -> void:
	_set_state("TUTORIAL_CHOICE")
	_show(func():
		choice_view = TutorialChoice.new()
		_swap(choice_view)
		choice_view.open(strings.learn.choice)
		choice_view.chosen.connect(_on_tutorial_chosen, CONNECT_ONE_SHOT))

func _on_tutorial_chosen(mode: String) -> void:
	if state != "TUTORIAL_CHOICE": return
	meta.profile.data.learn.tutorial = mode
	meta.profile.save()
	_start_selected_run()

func open_meta_view(which: String) -> void:
	if meta == null: return
	_set_state(which)
	_show(func():
		match which:
			"WALL": meta_view = WallScene.new()
			"SETTINGS": meta_view = SettingsScene.new()
			_: meta_view = LeaveScene.new()
		_swap(meta_view)
		if which == "SETTINGS":
			meta_view.telemetry = telemetry
			meta_view.consent_requested.connect(func(): _enter_consent(func(): open_meta_view("SETTINGS")))
		meta_view.open(meta)
		meta_view.back_requested.connect(start_title, CONNECT_ONE_SHOT))

func _replay() -> void:
	if not practice_mode(): run_mode = "run"
	_start_selected_run()

func _start_selected_run() -> void:
	if practice_mode(): new_game(-1, PRACTICE_OVERRIDES)
	else: new_game(meta.daily_seed() if run_mode == "daily" and meta != null else -1, {})

func new_game(seed_value: int = -1, overrides: Dictionary = {}) -> void:
	var chosen := seed_value
	if chosen < 0:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--seed="): chosen = int(argument.trim_prefix("--seed="))
	if chosen < 0: chosen = int(Time.get_unix_time_from_system() * 1000.0) % 1000000
	seed_used = chosen
	start_with_game(Game.new(chosen, HORIZON, overrides))

func start_with_game(value: RefCounted) -> void:
	if telemetry != null and game != null: telemetry.quit_run(state, game.status())
	_reset_game()
	boss_log.clear()
	visited.clear()
	last_message = ""
	game = value
	life = LifeGame.new(seed_used)
	# T-035: the profile learn block when there is a profile; a transient state otherwise (tests may preset one).
	if meta != null: learn_state = LearnState.new(meta.profile.data.learn)
	elif learn_state == null: learn_state = LearnState.new()
	learn_outcome = {}
	focus_info = {"bonus": 0, "reason": "neutral"}
	if telemetry != null:
		telemetry.run_start(run_mode, seed_used, int(game.status().horizon), str(learn_state.data.tutorial), int(floor(learn_state.mean_level())))
	if daily_active():
		life.enable_daily()
		if meta != null: meta.begin_run(life)
		hud.bind(life)
	else:
		hud.bind(null)
	_set_state("NEW_GAME")
	_enter_day_start()
	if practice_mode(): toast(strings.practice.note)

func _enter_day_start() -> void:
	if daily_active():
		_enter_morning()
		return
	_set_state("DAY_START")
	game.begin_day()
	_telemetry_day_start()
	phase = "sang"
	boss_shown = false
	first_tool_done = false
	var day := int(game.status().day)
	if commute_enabled and not practice_mode():
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
	_telemetry_day_start()
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
	Juice.title_card(toast_layer, "Day %d" % day)
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
	var fresh := desktop == null
	if desktop == null:
		desktop = DesktopScene.instantiate()
		desktop.data_seed = seed_used
		desktop.learn = learn_state
		desktop.cards_unlocked.connect(func(ids): toast(strings.learn.skills.unlocked % ids.size()))
		desktop.setup(game)
		desktop.tool_used.connect(_on_tool_used)
		desktop.time_changed.connect(_on_time_changed)
		desktop.report_submitted.connect(submit_report)
	else:
		desktop.start_day()
	_swap(desktop)
	if fresh and telemetry != null:
		desktop.report_window.wait_requested.connect(func(): telemetry.time_spent(game.status(), false))
		if desktop.data_session != null:
			desktop.data_session.changed.connect(func(): telemetry.time_spent(game.status(), true))
			desktop.data_session.hint_given.connect(func(_info): telemetry.hint(game.status()))
	desktop.refresh()

func _telemetry_day_start() -> void:
	if telemetry != null: telemetry.day_start(game.status(), game.question_today(), game.news_today())

func _on_tool_used(uid: String, tool_id: String, result: Dictionary) -> void:
	if telemetry == null: return
	var item := {}
	for news in game.news_today():
		if str(news.get("uid", "")) == uid:
			item = news
			break
	telemetry.verification(game.status(), tool_id, result, item)

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
	if telemetry != null: telemetry.report_submit(game.status(), input)
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
	review_view.line_shown.connect(func(category, _text): preload("res://scripts/audio/audio_manager.gd").review_for(self, category))
	review_view.line_shown.connect(func(category, _text): if category == "promotion": Juice.confetti(toast_layer, Vector2(320, 120)))
	review_view.finished.connect(_after_review)
	review_view.life_text = strings.life.review_line % [life.projected_net_worth(game.status()), life.mood]
	if life.vitals != null and life.vitals.hr_warning and life.vitals.sick_today: review_view.life_note = strings.daily.hr_line
	# T-034: the data core's review (cleaning, findings, chart) is read only here, after the day ended.
	if desktop != null and desktop.data_session != null:
		review_view.data_game = desktop.data_session.data
		review_view.learn_state = learn_state
		review_view.hints_by_file = desktop.data_session.hints_by_file()
		review_view.tutorial_day = desktop.data_session.tutorial_today()
	review_view.show_review(game, day, submission, before_status)
	if telemetry != null: telemetry.day_end(game.status(), review_view.data)

# Used by tests and scripts: one press of Continue.
func continue_review() -> void:
	if state == "REVIEW" and review_view != null: review_view.next_step()

func _after_review() -> void:
	if state != "REVIEW": return
	_learn_toasts()
	_record_day()
	if bool(game.status().finished): _enter_ending()
	elif daily_active() and overtime_enabled: _enter_overtime()
	elif evening_enabled and not practice_mode(): _enter_evening()
	else: _close_day()

# T-030: the finished day goes to the ScoreSink (public parts only); achievements appear as toasts.
# T-035: level-ups, new Handbook cards and the tutorial graduation of the finished day, as toasts.
func _learn_toasts() -> void:
	# The review scene settled the day (XP, cards, events) while it was built; the profile is saved with the day.
	learn_outcome = review_view.learn_outcome if review_view != null else {}
	if meta != null and not learn_outcome.is_empty(): meta.profile.save()
	for up in learn_outcome.get("levelups", []): toast(strings.learn.skills.levelup % [strings.learn.handbook.skills[up.skill], int(up.to)])
	if not learn_outcome.get("new_cards", []).is_empty(): toast(strings.learn.skills.unlocked % learn_outcome.new_cards.size())
	if bool(learn_outcome.get("graduated", false)): toast(strings.learn.tutorial.graduate)
	if practice_mode(): toast(strings.practice.note)

func _record_day() -> void:
	if meta == null or game == null or practice_mode(): return
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
	if telemetry != null: telemetry.run_end(final_status)
	life.settle_for_ending(final_status)
	if meta != null and not practice_mode():
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

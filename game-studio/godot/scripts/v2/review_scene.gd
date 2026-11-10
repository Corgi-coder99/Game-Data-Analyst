extends "res://scripts/v2/windows/window_base.gd"
# End-of-day meeting. This is the only v2 script allowed to read the hidden labels,
# and only from the review record of a day that has already ended.
const CityArt = preload("res://scripts/v2/city_art.gd")
const RANK_ORDER := ["thuc_tap", "chuyen_vien", "chuyen_vien_chinh", "truong_nhom", "giam_doc"]
const TRUTH_ICONS := {"dung":"check", "sai":"cross", "mot_phan":"question", "cu":"clock_old", "khong_lien_quan":"dash"}
const TRUTH_COLORS := {"dung":24, "sai":26, "mot_phan":28, "cu":6, "khong_lien_quan":6}
const DIRECTION_ICONS := {"tang":"arrow_up", "giam":"arrow_down", "ngang":"arrow_flat"}
const STEP_COUNT := 6
const FLOAT_TIME := 0.6
const SWEEP_TIME := 0.4
const SWEEP_WIDTH := 48
const BODY_WIDTH := 608
const SWEEP_AREA := 396
const STAGE_AT := Vector2(400, 0)
const ReactionStage = preload("res://scripts/v2/reaction_stage.gd")
signal finished
signal line_shown(category: String, text: String)
var strings: Dictionary
var game: RefCounted
var day := 0
var submission: Dictionary = {}
var before: Dictionary = {}
var data: Dictionary = {}
var status: Dictionary = {}
var step := -1
var lines_shown: Array = []
var panel: Panel
var header_label: Label
var body: Control
var dialog_speaker: Label
var dialog_text: Label
var continue_button: Button
var float_label: Label
var float_time := -1.0
var sweep_root: Control
var sweep_outer: ColorRect
var sweep_inner: ColorRect
var sweep_time := -1.0
var title_label: Label
var stage: Control
var skipped := false
# T-024: one extra line under the career step (net worth and mood); empty hides it.
var life_text := ""
# T-026: an optional second line (HR note after repeated sick days).
var life_note := ""
var built := false

func _ready() -> void:
	_build()

func _build() -> void:
	if built: return
	built = true
	size = Vector2(640, 360)
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = WindowTheme.create()
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	var background := TextureRect.new()
	background.texture = CityArt.backdrop("review")
	background.set_meta("overlay", true)
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	title_label = _text(self, "", Rect2(8, 4, 624, 17), 8, 12)
	panel = Panel.new()
	panel.position = Vector2(8, 24)
	panel.size = Vector2(624, 240)
	panel.add_theme_stylebox_override("panel", WindowTheme.box(2))
	add_child(panel)
	header_label = _text(panel, "", Rect2(8, 4, 608, 12), 8)
	body = Control.new()
	body.position = Vector2(8, 20)
	body.size = Vector2(BODY_WIDTH, 214)
	body.clip_contents = true
	panel.add_child(body)
	stage = ReactionStage.new()
	stage.name = "Stage"
	stage.position = STAGE_AT
	body.add_child(stage)
	stage.hide()
	var dialog := Panel.new()
	dialog.position = Vector2(24, 272)
	dialog.size = Vector2(592, 80)
	dialog.add_theme_stylebox_override("panel", WindowTheme.box(2))
	add_child(dialog)
	var portrait := TextureRect.new()
	portrait.texture = sprites.frame("hanh")
	portrait.position = Vector2(8, 16)
	portrait.size = Vector2(32, 48)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(portrait)
	dialog_speaker = _text(dialog, strings.flow.boss, Rect2(52, 3, 300, 17), 8, 12)
	dialog_text = _text(dialog, "", Rect2(52, 22, 424, 52), 7, 12)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button = button(dialog, strings.review["continue"], Rect2(484, 48, 96, 24))
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(next_step)

func _text(parent: Node, text: String, area: Rect2, color_index: int = 22, font_size: int = 8) -> Label:
	var node := label(parent, text, area, color_index)
	if font_size != 8: node.add_theme_font_size_override("font_size", font_size)
	return node

func _wrapped(parent: Node, text: String, area: Rect2, color_index: int = 22, lines: int = 2) -> Label:
	var node := _text(parent, text, area, color_index)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.max_lines_visible = lines
	node.tooltip_text = text
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	return node

# The ended day is the only day ever requested: `ended_day` comes from the flow after end_day().
func show_review(value: RefCounted, ended_day: int, report: Dictionary, status_before: Dictionary) -> bool:
	_build()
	game = value
	day = ended_day
	submission = report.duplicate(true)
	before = status_before.duplicate(true)
	data = game.review(day)
	if data.has("error"): return false
	status = game.status()
	lines_shown.clear()
	title_label.text = strings.review.title + " · " + strings.ui.day % [day, int(status.horizon)]
	step = -1
	next_step()
	return true

func next_step() -> void:
	if data.is_empty(): return
	if step >= STEP_COUNT - 1:
		finished.emit()
		return
	step += 1
	_render_step()

func rank_index(rank: String) -> int:
	return RANK_ORDER.find(rank)

func reaction_category() -> String:
	var acc := float(data.result.acc)
	if acc >= 1.0: return "right"
	if acc > 0.0: return "partial"
	match str(submission.get("confidence", "")):
		"cao": return "wrong_high"
		"vua": return "wrong_mid"
	return "wrong_low"

func career_category() -> String:
	if bool(data.career.fired) or str(status.ending) == "fired": return "fired"
	if str(status.ending) == "bankrupt": return "bankrupt"
	if int(status.demotions) > int(before.get("demotions", 0)): return "demotion"
	if rank_index(str(status.rank)) > rank_index(str(before.get("rank", status.rank))): return "promotion"
	if int(status.warnings) > int(before.get("warnings", 0)): return "warning"
	return ""

func _say(category: String, text: String) -> void:
	dialog_text.text = text
	if category != "":
		lines_shown.append({"step":step, "category":category, "text":text})
		line_shown.emit(category, text)

func _render_step() -> void:
	body.remove_child(stage)
	empty(body)
	body.add_child(stage)
	stage.clear()
	stage.hide()
	float_label = null
	float_time = -1.0
	sweep_time = -1.0
	sweep_root = null
	header_label.text = "%d/%d  %s" % [step + 1, STEP_COUNT, strings.review.steps[step]]
	var last := step == STEP_COUNT - 1
	continue_button.text = strings.review["continue"] if not last else (strings.review.to_ending if bool(status.finished) else strings.review.next_day)
	if step >= 1 and step <= 4: _say("", strings.review.say[step])
	match step:
		0: _step_reaction()
		1: _step_answer()
		2: _step_news()
		3: _step_shocks()
		4: _step_actions()
		5: _step_career()

func _step_reaction() -> void:
	var category := reaction_category()
	var line: String = strings.boss_lines[category]
	var timing := str(data.get("timing", "on_time"))
	if timing != "on_time": line += " " + strings.review["line_" + timing]
	_say(category, line)
	var trust_before := float(before.get("trust", status.trust))
	_text(body, strings.review.trust % [trust_before, float(status.trust)], Rect2(0, 0, 300, 17), 22, 12)
	var bar := ProgressBar.new()
	bar.theme = theme
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(300, 7)
	bar.position = Vector2(0, 26)
	bar.size = Vector2(300, 7)
	bar.value = clampf(float(status.trust), 0, 100)
	body.add_child(bar)
	bar.size = Vector2(300, 7)
	var delta := float(data.result.delta)
	float_label = _text(body, strings.review.delta % delta, Rect2(308, 20, 80, 17), 24 if delta > 0 else (26 if delta < 0 else 7), 12)
	float_time = 0.0
	_apply_float()
	var acc := float(data.result.acc)
	icon(body, "check" if acc >= 1.0 else ("question" if acc > 0.0 else "cross"), Vector2(0, 50))
	_text(body, strings.review.accuracy % _accuracy_text(), Rect2(12, 46, 380, 17), 22, 12)
	if timing != "on_time":
		var tag_key := "timing_late" if timing == "late" else "timing_missed"
		_text(body, strings.review[tag_key], Rect2(0, 66, 380, 14), 28 if timing == "late" else 26, 12)
	_show_stage(category)

func _accuracy_text() -> String:
	var acc := float(data.result.acc)
	return strings.review.acc_exact if acc >= 1.0 else (strings.review.acc_near if acc > 0.0 else strings.review.acc_wrong)

func _step_answer() -> void:
	var forecast: String = str(submission.get("forecast", ""))
	var confidence: String = str(submission.get("confidence", ""))
	var line: String = strings.review.your % [strings.forecast.get(forecast, "?"), strings.confidence.get(confidence, "?"), strings.forecast[data.answer]]
	_wrapped(body, line, Rect2(0, 0, 608, 36), 22, 2).add_theme_font_size_override("font_size", 12)
	var acc := float(data.result.acc)
	icon(body, "check" if acc >= 1.0 else ("question" if acc > 0.0 else "cross"), Vector2(0, 44))
	_text(body, strings.review.accuracy % _accuracy_text(), Rect2(12, 40, 590, 17), 24 if acc >= 1.0 else (28 if acc > 0.0 else 26), 12)
	var cited: Array = submission.get("evidence", [])
	_text(body, strings.review.evidence_count % cited.size() if not cited.is_empty() else strings.review.no_evidence, Rect2(0, 66, 608, 12), 7)
	if bool(data.get("shifted", false)):
		_wrapped(body, strings.review.shifted % [strings.forecast[data.original_answer], strings.forecast[data.answer]], Rect2(0, 82, 608, 24), 28, 2)

func _step_news() -> void:
	var cited: Array = submission.get("evidence", [])
	for i in data.news.size():
		var item: Dictionary = data.news[i]
		var y: int = i * 28
		var verdict: String = item.truth
		var chip := ColorRect.new()
		chip.color = Palette.color(3)
		chip.position = Vector2(0, y)
		chip.size = Vector2(112, 14)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(chip)
		icon(chip, TRUTH_ICONS[verdict], Vector2(3, 3))
		_text(chip, strings.truth[verdict], Rect2(14, 1, 96, 12), TRUTH_COLORS[verdict])
		_wrapped(body, item.headline, Rect2(116, y, 388, 24), 22, 2)
		if item.uid in cited:
			icon(body, "flag", Vector2(510, y + 2))
			_text(body, strings.review.cited, Rect2(522, y, 84, 12), 21)

func _step_shocks() -> void:
	var y := 0
	if data.shocks.is_empty():
		_text(body, strings.review.no_shock, Rect2(0, 0, 608, 12), 7)
	for shock in data.shocks:
		icon(body, "question", Vector2(0, y + 2))
		_text(body, strings.shocks.get(shock.id, shock.id), Rect2(12, y, 590, 12), 28)
		_wrapped(body, strings.review.cause % strings.root_causes.get(shock.id, strings.shocks.get(shock.id, shock.id)), Rect2(12, y + 13, 590, 12), 7, 1)
		y += 28
	_text(body, strings.review.world, Rect2(0, 112, 608, 12), 8)
	var index := 0
	for variable in data.states:
		var info: Dictionary = data.states[variable]
		var column := index % 2
		var row := index / 2
		var x := column * 304
		var line_y := 128 + row * 16
		_text(body, strings.topics.get(variable, variable), Rect2(x, line_y, 100, 12), 7)
		icon(body, DIRECTION_ICONS[info.direction], Vector2(x + 104, line_y + 2))
		_text(body, strings.review.direction[info.direction] + " " + strings.magnitude[info.magnitude], Rect2(x + 116, line_y, 140, 12), 22)
		index += 1

func _step_actions() -> void:
	if data.actions.is_empty():
		_text(body, strings.review.no_actions, Rect2(0, 0, 608, 12), 7)
	for i in data.actions.size():
		var action: Dictionary = data.actions[i]
		var y: int = i * 32
		_text(body, strings.actions.get(action.id, action.id), Rect2(0, y, 608, 12), 22)
		var adopted := bool(action.adopted)
		icon(body, "check" if adopted else "cross", Vector2(0, y + 15))
		_text(body, strings.review.adopted if adopted else strings.review.rejected, Rect2(12, y + 13, 160, 12), 24 if adopted else 26)
		if adopted:
			var executed := bool(action.executed)
			icon(body, "check" if executed else "cross", Vector2(180, y + 15))
			_text(body, strings.review.executed if executed else strings.review.not_executed, Rect2(192, y + 13, 200, 12), 24 if executed else 26)

func _step_career() -> void:
	var category := career_category()
	if category != "": _say(category, strings.boss_lines[category])
	else: _say("", strings.review.say[5])
	var y := 0
	_text(body, strings.review.rank % strings.ranks[status.rank], Rect2(0, y, 392, 17), 22, 12)
	y += 22
	_text(body, strings.review.trust % [float(before.get("trust", status.trust)), float(status.trust)], Rect2(0, y, 392, 12), 7)
	y += 16
	var events := money_events()
	var shown := {}
	for event in events: shown[event.type] = int(event.amount)
	if shown.has("pay"):
		_text(body, strings.review.pay % shown.pay, Rect2(0, y, 392, 12), 24)
		y += 14
	var bonus := float(data.career.bonus)
	_text(body, strings.review.bonus % roundi(bonus) if bonus > 0 else strings.review.no_bonus, Rect2(0, y, 392, 12), 24 if bonus > 0 else 7)
	y += 14
	if shown.has("fine"):
		_text(body, strings.review.fine % absi(int(shown.fine)), Rect2(0, y, 392, 12), 26)
		y += 14
	y += 6
	match category:
		"promotion":
			_text(body, strings.review.promoted % strings.ranks[status.rank], Rect2(0, y, 392, 17), 24, 12)
			_start_sweep()
		"demotion": _text(body, strings.review.demoted % strings.ranks[status.rank], Rect2(0, y, 392, 17), 26, 12)
		"warning": _text(body, strings.review.warned, Rect2(0, y, 392, 17), 28, 12)
		"fired": _text(body, strings.review.fired, Rect2(0, y, 392, 17), 26, 12)
		"bankrupt": _text(body, strings.review.bankrupt, Rect2(0, y, 392, 17), 26, 12)
		_: _text(body, strings.review.steady, Rect2(0, y, 392, 12), 7)
	if life_text != "": _text(body, life_text, Rect2(0, 150, 392, 12), 28)
	if life_note != "": _text(body, life_note, Rect2(0, 164, 392, 12), 26)
	_show_stage(category if category != "" else "steady")
	var delay := 0.0
	for event in events:
		stage.show_money(event.type, int(event.amount), delay, 1 if event.type == "bonus" else 0)
		delay += 0.5
	if skipped: stage.skip()

# Pay, bonus and fine from values the review already shows: the public personal_pay change
# and the bonus in the career record. Nothing hidden is read.
func money_events() -> Array:
	var out: Array = []
	var total := float(status.personal_pay) - float(before.get("personal_pay", status.personal_pay))
	var bonus := float(data.career.bonus)
	var pay := total - bonus
	if pay > 0.5: out.append({"type": "pay", "amount": roundi(pay)})
	if bonus > 0.5: out.append({"type": "bonus", "amount": roundi(bonus)})
	if pay < -0.5: out.append({"type": "fine", "amount": -roundi(-pay)})
	return out

# Emote for the player and the coworker's reaction for one boss/career category.
func emote_for(category: String) -> String:
	match category:
		"right", "promotion": return "happy"
		"partial", "steady": return "neutral"
		"wrong_high", "fired": return "angry"
	return "sad"

func coworker_mood_for(category: String) -> String:
	match category:
		"right", "promotion": return "happy"
		"wrong_low", "wrong_mid", "wrong_high", "demotion", "fired", "bankrupt": return "angry"
	return ""

func _show_stage(category: String) -> void:
	stage.show()
	stage.set_emote(emote_for(category))
	stage.react(coworker_mood_for(category), day * 3 + step)
	if skipped: stage.skip()

func _start_sweep() -> void:
	sweep_root = Control.new()
	sweep_root.position = Vector2(0, 100)
	sweep_root.size = Vector2(SWEEP_AREA, 24)
	sweep_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(sweep_root)
	sweep_outer = ColorRect.new()
	sweep_outer.color = Palette.color(14)
	sweep_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweep_root.add_child(sweep_outer)
	sweep_inner = ColorRect.new()
	sweep_inner.color = Palette.color(28)
	sweep_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweep_root.add_child(sweep_inner)
	sweep_time = 0.0
	_apply_sweep()

# A band of light crossing the body in 400 ms, kept inside the body at every frame.
func _apply_sweep() -> void:
	if sweep_root == null: return
	var progress := clampf(sweep_time / SWEEP_TIME, 0.0, 1.0)
	var left := roundi(lerpf(-SWEEP_WIDTH, SWEEP_AREA, progress))
	_place_band(sweep_outer, left, SWEEP_WIDTH)
	_place_band(sweep_inner, left + 14, SWEEP_WIDTH - 28)
	sweep_root.visible = sweep_time < SWEEP_TIME

func _place_band(node: ColorRect, left: int, width: int) -> void:
	var from := maxi(0, left)
	var to := mini(SWEEP_AREA, left + width)
	node.visible = to > from
	node.position = Vector2(from, 0)
	node.size = Vector2(maxi(0, to - from), sweep_root.size.y)

# The trust change appears large, holds briefly and fades in 25 percent steps over 600 ms.
func _apply_float() -> void:
	if float_label == null: return
	var progress := clampf(float_time / FLOAT_TIME, 0.0, 1.0)
	var alpha := 1.0 - floorf(progress * 4.0) * 0.25
	float_label.modulate.a = maxf(alpha, 0.0)
	float_label.position.y = 20 - floorf(progress * 4.0) * 2.0
	float_label.visible = progress < 1.0

func advance(delta: float) -> void:
	if float_time >= 0.0 and float_label != null:
		float_time += delta
		_apply_float()
	if sweep_time >= 0.0 and sweep_root != null:
		sweep_time += delta
		_apply_sweep()

func _process(delta: float) -> void:
	advance(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# Esc finishes the popups and the coworker animation at once; it never blocks the flow.
		skipped = true
		if stage != null: stage.skip()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		next_step()
		get_viewport().set_input_as_handled()

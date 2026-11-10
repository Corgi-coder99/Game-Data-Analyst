extends "res://scripts/v2/windows/window_base.gd"
const FORECASTS := ["tang", "giam", "ngang"]
const CONFIDENCES := ["thap", "vua", "cao"]
const FORECAST_ICONS := {"tang":"arrow_up", "giam":"arrow_down", "ngang":"arrow_flat"}
const VERIFY_ICONS := {"xac_nhan":"check", "bac_bo":"cross", "chua_du_can_cu":"question", "cu":"arrow_flat", "chua_kiem_chung":"dash"}
const VERIFY_COLORS := {"xac_nhan":24, "bac_bo":26, "chua_du_can_cu":28, "cu":6, "chua_kiem_chung":28}
var strings: Dictionary
var question_id := ""
var forecast := ""
var confidence := ""
var chosen: Array = []
var cards: Array = []
var evidence: Array = []
var max_actions := 1
var locked := false
var confirming := false
var message := ""
var message_is_error := false
var forecast_buttons: Dictionary = {}
var confidence_buttons: Dictionary = {}
var action_buttons: Dictionary = {}
var unpin_buttons: Dictionary = {}
var submit_button: Button
var confirm_panel: Panel
var confirm_yes: Button
var confirm_no: Button
var message_label: Label
signal submit_requested(input: Dictionary)
signal unpin_requested(uid: String)

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.report, Rect2(396, 20, 240, 320))

# `pinned` holds public news entries: only uid, headline and verification are read.
func display(question: String, hand: Array, pinned: Array, limit: int) -> void:
	question_id = question
	cards = hand.duplicate(true)
	evidence = pinned.duplicate(true)
	max_actions = limit
	var ids: Array = cards.map(func(card): return card.id)
	chosen = chosen.filter(func(id): return id in ids)
	while chosen.size() > max_actions: chosen.pop_back()
	render()

func reset() -> void:
	forecast = ""
	confidence = ""
	chosen.clear()
	locked = false
	confirming = false
	message = ""
	message_is_error = false
	if content != null: render()

func ready_to_submit() -> bool:
	return forecast != "" and confidence != "" and not locked

func choose_forecast(id: String) -> void:
	if locked or confirming or id not in FORECASTS: return
	forecast = id
	message = ""
	render()

func choose_confidence(id: String) -> void:
	if locked or confirming or id not in CONFIDENCES: return
	confidence = id
	message = ""
	render()

func toggle_action(id: String) -> bool:
	if locked or confirming or not action_buttons.has(id): return false
	if id in chosen:
		chosen.erase(id)
		message = ""
	elif chosen.size() >= max_actions:
		message = strings.report.action_limit % max_actions
		message_is_error = true
		render()
		return false
	else:
		chosen.append(id)
		message = ""
	render()
	return true

func build_input() -> Dictionary:
	return {"question_id":question_id, "forecast":forecast, "confidence":confidence, "evidence":evidence.map(func(item): return item.uid), "actions":chosen.duplicate()}

func request_submit() -> bool:
	if not ready_to_submit() or confirming: return false
	confirming = true
	render()
	return true

func cancel_submit() -> void:
	confirming = false
	render()

func confirm_submit() -> bool:
	if not confirming: return false
	confirming = false
	render()
	submit_requested.emit(build_input())
	return true

func show_error(code: String) -> void:
	message = strings.errors.get(code, strings.ui.unknown)
	message_is_error = true
	confirming = false
	render()

func lock(value: bool) -> void:
	locked = value
	confirming = false
	if value:
		message = strings.report.locked
		message_is_error = false
	render()

func _chip(parent: Node, text: String, area: Rect2, icon_id: String, selected: bool) -> Button:
	var node := button(parent, text, area)
	node.clip_text = true
	node.toggle_mode = true
	node.button_pressed = selected
	if icon_id != "": node.icon = sprites.frame(icon_id)
	return node

func render() -> void:
	if content == null: return
	empty(content)
	forecast_buttons.clear()
	confidence_buttons.clear()
	action_buttons.clear()
	unpin_buttons.clear()
	label(content, strings.report.forecast, Rect2(0, 0, 232, 12), 7)
	for i in FORECASTS.size():
		var id: String = FORECASTS[i]
		var chip := _chip(content, strings.forecast[id], Rect2(i * 78, 12, 76, 18), FORECAST_ICONS[id], forecast == id)
		chip.pressed.connect(choose_forecast.bind(id))
		forecast_buttons[id] = chip
	label(content, strings.report.confidence, Rect2(0, 33, 232, 12), 7)
	for i in CONFIDENCES.size():
		var id: String = CONFIDENCES[i]
		var chip := _chip(content, strings.confidence[id], Rect2(i * 78, 45, 76, 18), "", confidence == id)
		chip.pressed.connect(choose_confidence.bind(id))
		confidence_buttons[id] = chip
	label(content, strings.report.evidence % evidence.size(), Rect2(0, 66, 232, 12), 7)
	var y := 78
	var any_unverified := false
	if evidence.is_empty():
		label(content, strings.report.no_evidence, Rect2(0, y, 232, 12), 6)
		y += 15
	for item in evidence:
		var headline := label(content, item.headline, Rect2(0, y, 122, 12))
		headline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		headline.tooltip_text = item.headline
		headline.mouse_filter = Control.MOUSE_FILTER_PASS
		var status: String = item.verification
		if status == "chua_kiem_chung": any_unverified = true
		icon(content, VERIFY_ICONS[status], Vector2(126, y + 2))
		var status_text: String = strings.report.unverified if status == "chua_kiem_chung" else strings.verification[status]
		label(content, status_text, Rect2(136, y, 70, 12), VERIFY_COLORS[status])
		var unpin := button(content, strings.report.unpin, Rect2(208, y, 24, 14))
		unpin.clip_text = true
		unpin.tooltip_text = strings.ui.unpin
		unpin.pressed.connect(func(): if not locked: unpin_requested.emit(item.uid))
		unpin_buttons[item.uid] = unpin
		y += 15
	y += 2
	label(content, strings.report.actions % [chosen.size(), max_actions], Rect2(0, y, 232, 12), 7)
	y += 12
	if cards.is_empty():
		label(content, strings.report.no_actions, Rect2(0, y, 232, 12), 6)
		y += 15
	for card in cards:
		var name_text: String = strings.actions.get(card.id, card.name)
		var row := _chip(content, name_text, Rect2(0, y, 178, 14), "", card.id in chosen)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.tooltip_text = name_text
		row.pressed.connect(toggle_action.bind(card.id))
		action_buttons[card.id] = row
		label(content, strings.report.cost % [int(card.energy), int(card.budget)], Rect2(180, y + 1, 52, 12), 7)
		y += 15
	var message_y := 216
	var text := message
	var color := 26 if message_is_error else 28
	if text == "":
		if not ready_to_submit() and not locked: text = strings.report.need_choice
		elif any_unverified: text = strings.report.unverified_note
	message_label = label(content, text, Rect2(0, message_y, 232, 24), color)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.max_lines_visible = 2
	message_label.tooltip_text = text
	message_label.mouse_filter = Control.MOUSE_FILTER_PASS
	submit_button = button(content, strings.report.submit, Rect2(0, 244, 232, 22))
	submit_button.disabled = not ready_to_submit()
	submit_button.pressed.connect(request_submit)
	confirm_panel = null
	if confirming:
		confirm_panel = Panel.new()
		confirm_panel.position = Vector2(8, 96)
		confirm_panel.size = Vector2(216, 70)
		confirm_panel.add_theme_stylebox_override("panel", WindowTheme.box(2, 21))
		content.add_child(confirm_panel)
		var ask := label(confirm_panel, strings.report.confirm, Rect2(6, 6, 204, 24))
		ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		confirm_yes = button(confirm_panel, strings.report.yes, Rect2(6, 40, 98, 22))
		confirm_no = button(confirm_panel, strings.report.no, Rect2(112, 40, 98, 22))
		confirm_yes.pressed.connect(confirm_submit)
		confirm_no.pressed.connect(cancel_submit)

extends "res://scripts/v2/windows/window_base.gd"
# Mail: the report composer. Everything stays editable until Send is confirmed.
const FORECASTS := ["tang", "giam", "ngang"]
const CONFIDENCES := ["thap", "vua", "cao"]
const FORECAST_ICONS := {"tang":"arrow_up", "giam":"arrow_down", "ngang":"arrow_flat"}
const VERIFY_ICONS := {"xac_nhan":"check", "bac_bo":"cross", "chua_du_can_cu":"question", "cu":"arrow_flat", "chua_kiem_chung":"dash"}
const VERIFY_COLORS := {"xac_nhan":24, "bac_bo":26, "chua_du_can_cu":28, "cu":6, "chua_kiem_chung":28}
const AREA := Rect2(58, 30, 442, 290)
const SLOTS := 3
var strings: Dictionary
var question_id := ""
var subject := ""
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
var slot_panels: Array = []
var open_browser_buttons: Array = []
var submit_button: Button
var clear_button: Button
var confirm_panel: Panel
var confirm_yes: Button
var confirm_no: Button
var message_label: Label
var checklist_labels: Array = []
signal submit_requested(input: Dictionary)
signal unpin_requested(uid: String)
signal clear_requested
signal open_browser_requested
signal draft_changed
signal locked_changed(value: bool)

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.report, AREA)

# `pinned` holds public news entries: only uid, headline and verification are read.
func display(question: String, hand: Array, pinned: Array, limit: int, subject_text: String = "") -> void:
	question_id = question
	subject = subject_text
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

func missing() -> Array:
	var todo: Array = []
	if forecast == "": todo.append("todo_forecast")
	if confidence == "": todo.append("todo_confidence")
	return todo

func choose_forecast(id: String) -> void:
	if locked or confirming or id not in FORECASTS: return
	forecast = id
	message = ""
	render()
	draft_changed.emit()

func choose_confidence(id: String) -> void:
	if locked or confirming or id not in CONFIDENCES: return
	confidence = id
	message = ""
	render()
	draft_changed.emit()

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
	draft_changed.emit()
	return true

# Reset the whole draft; the desktop also drops the pinned evidence.
func clear_all() -> bool:
	if locked or confirming: return false
	forecast = ""
	confidence = ""
	chosen.clear()
	message = ""
	clear_requested.emit()
	render()
	draft_changed.emit()
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
	locked_changed.emit(value)

func _chip(parent: Node, text: String, area: Rect2, icon_id: String, selected: bool) -> Button:
	var node := button(parent, text, area)
	node.clip_text = true
	node.toggle_mode = true
	node.button_pressed = selected
	node.disabled = locked
	if icon_id != "": node.icon = sprites.frame(icon_id)
	return node

func render() -> void:
	if content == null: return
	empty(content)
	forecast_buttons.clear()
	confidence_buttons.clear()
	action_buttons.clear()
	unpin_buttons.clear()
	slot_panels.clear()
	open_browser_buttons.clear()
	checklist_labels.clear()
	label(content, strings.report.to, Rect2(0, 0, 210, 12), 7)
	var subject_label := label(content, strings.report.subject % subject, Rect2(0, 12, 210, 24))
	subject_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subject_label.max_lines_visible = 2
	subject_label.tooltip_text = subject
	subject_label.mouse_filter = Control.MOUSE_FILTER_PASS
	label(content, strings.report.forecast, Rect2(0, 40, 210, 12), 7)
	for i in FORECASTS.size():
		var id: String = FORECASTS[i]
		var chip := _chip(content, strings.forecast[id], Rect2(i * 72, 52, 66, 18), FORECAST_ICONS[id], forecast == id)
		chip.pressed.connect(choose_forecast.bind(id))
		forecast_buttons[id] = chip
	label(content, strings.report.confidence, Rect2(0, 74, 210, 12), 7)
	for i in CONFIDENCES.size():
		var id: String = CONFIDENCES[i]
		var chip := _chip(content, strings.confidence[id], Rect2(i * 72, 86, 66, 18), "", confidence == id)
		chip.pressed.connect(choose_confidence.bind(id))
		confidence_buttons[id] = chip
	label(content, strings.report.evidence % evidence.size(), Rect2(0, 108, 210, 12), 7)
	var any_unverified := false
	for i in SLOTS:
		var slot := Panel.new()
		slot.position = Vector2(0, 120 + i * 30)
		slot.size = Vector2(210, 28)
		slot.add_theme_stylebox_override("panel", WindowTheme.box(2, 21 if i < evidence.size() else 4))
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(slot)
		slot_panels.append(slot)
		if i >= evidence.size():
			var hint := label(slot, strings.report.no_evidence, Rect2(4, 0, 138, 26), 6)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.max_lines_visible = 2
			hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if i == evidence.size() and not locked:
				var go := button(slot, strings.report.slot_open, Rect2(146, 6, 60, 16))
				go.clip_text = true
				go.pressed.connect(func(): open_browser_requested.emit())
				open_browser_buttons.append(go)
			continue
		var item: Dictionary = evidence[i]
		var headline := label(slot, item.headline, Rect2(4, 1, 176, 12))
		headline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		headline.tooltip_text = item.headline
		headline.mouse_filter = Control.MOUSE_FILTER_PASS
		var status: String = item.verification
		if status == "chua_kiem_chung": any_unverified = true
		icon(slot, VERIFY_ICONS[status], Vector2(4, 16))
		var status_text: String = strings.report.unverified if status == "chua_kiem_chung" else strings.verification[status]
		label(slot, status_text, Rect2(16, 14, 160, 12), VERIFY_COLORS[status])
		var unpin := button(slot, strings.report.unpin, Rect2(184, 6, 22, 16))
		unpin.tooltip_text = strings.report.remove
		unpin.disabled = locked
		unpin.pressed.connect(func(): if not locked: unpin_requested.emit(item.uid))
		unpin_buttons[item.uid] = unpin
	# Right column: actions, messages, Clear all and the big Send button.
	label(content, strings.report.actions % [chosen.size(), max_actions], Rect2(218, 40, 216, 12), 7)
	if cards.is_empty():
		label(content, strings.report.no_actions, Rect2(218, 52, 216, 12), 6)
	var step := 16 if cards.size() <= 6 else 13
	for i in mini(cards.size(), 8):
		var card: Dictionary = cards[i]
		var y := 52 + i * step
		var name_text: String = strings.actions.get(card.id, card.name)
		var row := _chip(content, name_text, Rect2(218, y, 150, step - 2), "", card.id in chosen)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.tooltip_text = name_text
		row.pressed.connect(toggle_action.bind(card.id))
		action_buttons[card.id] = row
		label(content, strings.report.cost % [int(card.energy), int(card.budget)], Rect2(372, y, 62, 12), 7)
	var text := message
	var color := 26 if message_is_error else 28
	if text == "" and any_unverified and not locked: text = strings.report.unverified_note
	message_label = label(content, text, Rect2(218, 172, 216, 24), color)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.max_lines_visible = 2
	message_label.tooltip_text = text
	message_label.mouse_filter = Control.MOUSE_FILTER_PASS
	clear_button = button(content, strings.report.clear, Rect2(218, 198, 100, 16))
	clear_button.tooltip_text = strings.report.clear_tip
	clear_button.disabled = locked
	clear_button.pressed.connect(clear_all)
	submit_button = button(content, strings.report.submit, Rect2(218, 222, 216, 44))
	submit_button.add_theme_font_size_override("font_size", 12)
	submit_button.disabled = not ready_to_submit()
	submit_button.pressed.connect(request_submit)
	# Checklist beside the Send button.
	var todo := missing()
	var y_list := 216
	for key in ["todo_forecast", "todo_confidence"]:
		var done: bool = key not in todo
		icon(content, "check" if done else "dash", Vector2(0, y_list + 2))
		checklist_labels.append(label(content, strings.report[key], Rect2(12, y_list, 196, 12), 24 if done else 28))
		y_list += 13
	var has_evidence := not evidence.is_empty()
	icon(content, "check" if has_evidence else "dash", Vector2(0, y_list + 2))
	checklist_labels.append(label(content, strings.report.todo_evidence, Rect2(12, y_list, 196, 12), 24 if has_evidence else 6))
	y_list += 13
	if todo.is_empty() and not locked:
		checklist_labels.append(label(content, strings.report.todo_ok, Rect2(0, y_list, 208, 12), 24))
	confirm_panel = null
	if confirming:
		confirm_panel = Panel.new()
		confirm_panel.position = Vector2(110, 70)
		confirm_panel.size = Vector2(216, 76)
		confirm_panel.add_theme_stylebox_override("panel", WindowTheme.box(2, 21))
		content.add_child(confirm_panel)
		var ask := label(confirm_panel, strings.report.confirm, Rect2(6, 6, 204, 26))
		ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		confirm_yes = button(confirm_panel, strings.report.yes, Rect2(6, 42, 98, 26))
		confirm_no = button(confirm_panel, strings.report.no, Rect2(112, 42, 98, 26))
		confirm_yes.pressed.connect(confirm_submit)
		confirm_no.pressed.connect(cancel_submit)

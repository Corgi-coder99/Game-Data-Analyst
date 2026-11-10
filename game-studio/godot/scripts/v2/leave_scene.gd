extends "res://scripts/life/daily_base.gd"
# T-030: Request leave. Pick a start day (today or later), 1-3 days and a funny but valid reason.
# Covered days do not count as missed and do not break the streak. 3 leave days per month.
const Clock = preload("res://scripts/meta/clock.gd")
signal back_requested
var meta: RefCounted
var offset := 0
var length := 1
var reason_index := 0
var info_label: Label
var date_label: Label
var days_label: Label
var reason_label: Label
var result_label: Label
var booked_labels: Array = []
var buttons2: Dictionary = {}
var submit_button: Button
var back_button: Button
var last_result: Dictionary = {}

func _ready() -> void:
	_prepare_once()

func _prepare_once() -> void:
	if built: return
	built = true
	_prepare()
	_rect(self, 83, Rect2(0, 0, 640, 360))
	_panel(self, Rect2(80, 14, 480, 332))
	_text(self, "REQUEST LEAVE", Rect2(100, 22, 400, 16), 89, 12)
	info_label = _text(self, "", Rect2(100, 44, 440, 12), 91)
	_text(self, "Start day", Rect2(100, 72, 90, 12), 22)
	_text(self, "Number of days", Rect2(100, 98, 100, 12), 22)
	_text(self, "Reason", Rect2(100, 124, 90, 12), 22)
	date_label = _text(self, "", Rect2(250, 72, 100, 12), 89)
	days_label = _text(self, "", Rect2(250, 98, 100, 12), 89)
	reason_label = _text(self, "", Rect2(250, 124, 250, 12), 89)
	_arrows("date", 68, 72)
	_arrows("days", 94, 98)
	_arrows("reason", 120, 124)
	result_label = _wrapped(self, "", Rect2(100, 150, 440, 24), 91, 2)
	submit_button = button(self, "Request leave", Rect2(100, 182, 150, 22))
	submit_button.focus_mode = Control.FOCUS_NONE
	submit_button.pressed.connect(submit)
	back_button = button(self, "Back", Rect2(260, 182, 100, 22))
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(func(): back_requested.emit())
	_text(self, "Booked leave", Rect2(100, 216, 300, 12), 91)
	for i in 5:
		booked_labels.append(_text(self, "", Rect2(100, 232 + i * 14, 440, 12), 7))

func _arrows(id: String, y: int, _label_y: int) -> void:
	var minus := button(self, "<", Rect2(214, y, 28, 18))
	var plus := button(self, ">", Rect2(358 if id != "reason" else 504, y, 28 if id != "reason" else 28, 18))
	for b in [minus, plus]: b.focus_mode = Control.FOCUS_NONE
	minus.pressed.connect(step.bind(id, -1))
	plus.pressed.connect(step.bind(id, 1))
	buttons2[id + "_minus"] = minus
	buttons2[id + "_plus"] = plus

func open(meta_ref: RefCounted) -> void:
	_prepare_once()
	meta = meta_ref
	offset = 0
	length = 1
	reason_index = 0
	last_result = {}
	result_label.text = ""
	refresh()

func start_date() -> String:
	return Clock.add_days(meta.clock.today(), offset)

func step(id: String, delta: int) -> void:
	var rules: Dictionary = meta.cfg.attendance
	match id:
		"date": offset = clampi(offset + delta, 0, int(rules.leave_lookahead_days))
		"days": length = clampi(length + delta, 1, int(rules.leave_max_days))
		"reason": reason_index = posmod(reason_index + delta, meta.cfg.leave_reasons.size())
	refresh()

func reason_id() -> String:
	return str(meta.cfg.leave_reasons[reason_index].id)

func submit() -> Dictionary:
	last_result = meta.request_leave(start_date(), length, reason_id())
	if bool(last_result.ok):
		result_label.text = "Leave booked for %d day(s). Your boss rolled eyes, then signed." % last_result.covered.size()
	else:
		var messages := {"allowance": "Not enough leave days left this month.", "past": "Leave must start today or later.", "too_far": "That is too far ahead.", "bad_days": "Pick 1 to 3 days.", "bad_reason": "Pick a reason.", "bad_date": "That date is not valid."}
		result_label.text = str(messages.get(last_result.error, "Could not book that leave."))
	refresh()
	return last_result

func refresh() -> void:
	if meta == null: return
	var start := start_date()
	info_label.text = "Leave days left in %s: %d of %d" % [Clock.month_name(Clock.month_key(start)), meta.attendance.leave_left(start), int(meta.cfg.attendance.leave_allowance_per_month)]
	date_label.text = start + (" (today)" if offset == 0 else "")
	days_label.text = "%d" % length
	reason_label.text = str(meta.cfg.leave_reasons[reason_index].text)
	var today: String = meta.clock.today()
	var upcoming: Array = meta.profile.data.leave.filter(func(entry): return str(entry.date) >= today)
	upcoming.sort_custom(func(a, b): return str(a.date) < str(b.date))
	for i in booked_labels.size():
		if i < upcoming.size():
			var reason_text := ""
			for reason in meta.cfg.leave_reasons:
				if reason.id == upcoming[i].reason: reason_text = str(reason.text)
			booked_labels[i].text = "%s   %s" % [upcoming[i].date, reason_text]
		else:
			booked_labels[i].text = "(none)" if i == 0 and upcoming.is_empty() else ""

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		back_requested.emit()
		get_viewport().set_input_as_handled()

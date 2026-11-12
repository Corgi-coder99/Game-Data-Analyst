extends "res://scripts/life/daily_base.gd"
# No I/O on display. The flow records the screen as seen before showing it, so close means No.
signal chosen(value: bool)
var yes_button: Button
var no_button: Button

func _ready() -> void:
	_prepare()
	_rect(self, 83, Rect2(0, 0, 640, 360))
	_panel(self, Rect2(48, 28, 544, 304))
	var copy: Dictionary = strings.telemetry
	_text(self, copy.title, Rect2(68, 44, 504, 24), 89, 12)
	_wrapped(self, copy.body, Rect2(68, 82, 504, 140), 22, 11)
	_wrapped(self, copy.pseudonymous, Rect2(68, 230, 504, 32), 7, 2)
	yes_button = button(self, copy.yes, Rect2(160, 284, 144, 26))
	no_button = button(self, copy.no, Rect2(336, 284, 144, 26))
	yes_button.pressed.connect(func(): chosen.emit(true))
	no_button.pressed.connect(func(): chosen.emit(false))
	no_button.grab_focus()

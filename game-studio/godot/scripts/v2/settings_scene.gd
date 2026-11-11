extends "res://scripts/life/daily_base.gd"
# T-030: settings. Display name, attendance warnings on/off, quiet hours (stored for the future, not used
# yet) and a confirmed profile reset. Everything is stored in the local profile file only.
const WindowTheme3 = preload("res://scripts/v2/theme_v2.gd")
signal back_requested
signal profile_reset
var meta: RefCounted
var name_edit: LineEdit
var apply_button: Button
var attendance_button: Button
var quiet_start_label: Label
var quiet_end_label: Label
var quiet_buttons: Dictionary = {}
var reset_button: Button
var confirm_label: Label
var confirm_button: Button
var cancel_button: Button
var back_button: Button
var status_label: Label
var confirming := false
const AudioManager = preload("res://scripts/audio/audio_manager.gd")
var audio_sliders: Dictionary = {}
var audio_labels: Dictionary = {}
var mute_button: Button
var sound_test_button: Button

func _ready() -> void:
	_prepare_once()

func _prepare_once() -> void:
	if built: return
	built = true
	_prepare()
	_rect(self, 83, Rect2(0, 0, 640, 360))
	_panel(self, Rect2(120, 14, 400, 332))
	_text(self, "SETTINGS", Rect2(140, 22, 360, 16), 89, 12)
	_text(self, "Display name", Rect2(140, 52, 90, 12), 22)
	name_edit = LineEdit.new()
	name_edit.position = Vector2(236, 48)
	name_edit.size = Vector2(170, 20)
	name_edit.max_length = 16
	name_edit.add_theme_font_size_override("font_size", 8)
	name_edit.add_theme_color_override("font_color", Palette.color(22))
	name_edit.add_theme_stylebox_override("normal", WindowTheme3.box(3, 99))
	name_edit.add_theme_stylebox_override("focus", WindowTheme3.box(3, 91))
	add_child(name_edit)
	name_edit.size = Vector2(170, 20)
	name_edit.text_submitted.connect(func(_text): apply_name())
	apply_button = button(self, "Save name", Rect2(414, 48, 90, 20))
	apply_button.focus_mode = Control.FOCUS_NONE
	apply_button.pressed.connect(apply_name)
	status_label = _text(self, "", Rect2(140, 72, 364, 12), 91)
	_text(self, "Attendance warnings", Rect2(140, 98, 220, 12), 22)
	attendance_button = button(self, "ON", Rect2(414, 94, 90, 20))
	attendance_button.focus_mode = Control.FOCUS_NONE
	attendance_button.pressed.connect(toggle_attendance)
	_wrapped(self, "When ON, skipped days bring funny letters from the boss and a small in-game fine. Switch OFF to play without that pressure.", Rect2(140, 118, 364, 24), 7, 2)
	_text(self, "Quiet hours (for the future, unused)", Rect2(140, 156, 270, 12), 22)
	_text(self, "Quiet from", Rect2(140, 176, 90, 12), 7)
	_text(self, "Quiet until", Rect2(140, 198, 90, 12), 7)
	quiet_start_label = _text(self, "", Rect2(278, 176, 60, 12), 22)
	quiet_end_label = _text(self, "", Rect2(278, 198, 60, 12), 22)
	for which in ["start", "end"]:
		var y := 172 if which == "start" else 194
		var minus := button(self, "-", Rect2(240, y, 30, 18))
		var plus := button(self, "+", Rect2(346, y, 30, 18))
		for b in [minus, plus]: b.focus_mode = Control.FOCUS_NONE
		minus.pressed.connect(adjust_quiet.bind(which, -1))
		plus.pressed.connect(adjust_quiet.bind(which, 1))
		quiet_buttons[which + "_minus"] = minus
		quiet_buttons[which + "_plus"] = plus
	reset_button = button(self, "Reset profile", Rect2(140, 232, 130, 20))
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.pressed.connect(ask_reset)
	confirm_label = _wrapped(self, "Delete your whole profile (history, plaques, streak)? This cannot be undone.", Rect2(280, 228, 224, 24), 26, 2)
	confirm_button = button(self, "Yes, reset", Rect2(280, 256, 100, 20))
	cancel_button = button(self, "Keep it", Rect2(390, 256, 100, 20))
	for b in [confirm_button, cancel_button]: b.focus_mode = Control.FOCUS_NONE
	confirm_button.pressed.connect(confirm_reset)
	cancel_button.pressed.connect(cancel_reset)
	_wrapped(self, "Your profile is stored only on this computer (profile.json). It holds your display name and game progress. No account, no network.", Rect2(140, 284, 364, 24), 99, 2)
	back_button = button(self, "Back", Rect2(270, 316, 100, 22))
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(close)
	_build_audio()

func open(meta_ref: RefCounted) -> void:
	_prepare_once()
	meta = meta_ref
	confirming = false
	refresh()

func refresh() -> void:
	if meta == null: return
	var data: Dictionary = meta.profile.data
	if not name_edit.has_focus(): name_edit.text = str(data.display_name)
	attendance_button.text = "ON" if bool(data.settings.attendance) else "OFF"
	quiet_start_label.text = "%02d:00" % int(data.settings.quiet_start)
	quiet_end_label.text = "%02d:00" % int(data.settings.quiet_end)
	confirm_label.visible = confirming
	confirm_button.visible = confirming
	cancel_button.visible = confirming
	reset_button.disabled = confirming
	_refresh_audio()

func apply_name() -> void:
	var saved: String = meta.profile.set_name(name_edit.text)
	meta.profile.save()
	name_edit.text = saved
	status_label.text = "Saved as: " + saved

func toggle_attendance() -> void:
	meta.set_attendance(not bool(meta.profile.data.settings.attendance))
	refresh()

func adjust_quiet(which: String, delta: int) -> void:
	var settings: Dictionary = meta.profile.data.settings
	var start_hour := int(settings.quiet_start)
	var end_hour := int(settings.quiet_end)
	if which == "start": start_hour = posmod(start_hour + delta, 24)
	else: end_hour = posmod(end_hour + delta, 24)
	meta.set_quiet_hours(start_hour, end_hour)
	refresh()

func ask_reset() -> void:
	confirming = true
	refresh()

func cancel_reset() -> void:
	confirming = false
	refresh()

func confirm_reset() -> void:
	if not confirming: return
	meta.reset_profile()
	confirming = false
	status_label.text = "Profile reset."
	refresh()
	profile_reset.emit()

func close() -> void:
	apply_name_if_changed()
	back_requested.emit()

func apply_name_if_changed() -> void:
	if meta != null and name_edit.text != str(meta.profile.data.display_name): apply_name()

func _build_audio() -> void:
	_panel(self, Rect2(524, 48, 112, 226))
	_text(self, "AUDIO", Rect2(532, 56, 96, 14), 89)
	for i in 3:
		var key: String = ["master", "music", "sfx"][i]
		var y := 80 + i * 44
		audio_labels[key] = _text(self, key.capitalize(), Rect2(532, y, 96, 14), 22)
		var slider := HSlider.new()
		slider.position = Vector2(532, y + 16)
		slider.size = Vector2(96, 16)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		add_child(slider)
		audio_sliders[key] = slider
		slider.value_changed.connect(_audio_changed.bind(key))
	mute_button = button(self, "Mute: OFF", Rect2(532, 214, 96, 20))
	mute_button.pressed.connect(_toggle_mute)
	sound_test_button = button(self, "Sound test", Rect2(532, 244, 96, 20))
	sound_test_button.pressed.connect(func(): AudioManager.emit_for(self, "success"))

func _refresh_audio() -> void:
	var values: Dictionary = meta.profile.data.settings.get("audio", AudioManager.DEFAULTS)
	for key in audio_sliders:
		audio_sliders[key].set_value_no_signal(values.get(key, AudioManager.DEFAULTS[key]))
		audio_labels[key].text = "%s %d" % [str(key).capitalize(), audio_sliders[key].value]
	mute_button.text = "Mute: ON" if values.get("mute", false) else "Mute: OFF"
	var manager := AudioManager.find_for(self)
	if manager != null: manager.bind_profile(meta.profile)

func _audio_changed(value: float, key: String) -> void:
	if meta == null: return
	var values: Dictionary = meta.profile.data.settings.get("audio", AudioManager.DEFAULTS.duplicate())
	values[key] = int(value)
	meta.profile.data.settings.audio = values
	meta.profile.save()
	_refresh_audio()

func _toggle_mute() -> void:
	if meta == null: return
	var values: Dictionary = meta.profile.data.settings.get("audio", AudioManager.DEFAULTS.duplicate())
	values.mute = not values.get("mute", false)
	meta.profile.data.settings.audio = values
	meta.profile.save()
	_refresh_audio()
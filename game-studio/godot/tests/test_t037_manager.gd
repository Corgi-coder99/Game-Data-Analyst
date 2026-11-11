extends SceneTree
const Manager = preload("res://scripts/audio/audio_manager.gd")
const Settings = preload("res://scripts/v2/settings_scene.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
var checks := 0
var failures := 0
var played: Array = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var started := Time.get_ticks_msec()
	var manager := Manager.new()
	root.add_child(manager)
	check(manager.music_start_error == OK, "low priority worker started")
	check(manager.music._thread.is_started(), "music uses Thread")
	var initial_request := Time.get_ticks_usec()
	manager.play_music("home")
	manager.play_music("work")
	check(Time.get_ticks_usec() - initial_request < 50000, "unready music requests return immediately")
	check(manager.requested_mood == "work", "latest pending mood wins")
	var build_deadline := Time.get_ticks_msec() + 15000
	var build_frames := 0
	while not manager.is_ready("work") and Time.get_ticks_msec() < build_deadline:
		await process_frame
		build_frames += 1
	check(manager.is_ready("work") and build_frames > 0, "frames continue while worker publishes music")
	manager.sfx_played.connect(func(id): played.append(id))
	for key in ["master", "music", "sfx"]:
		check(manager.settings[key] == Manager.DEFAULTS[key], "default " + key)
	manager.apply_settings({"master":50, "music":25, "sfx":0, "mute":true})
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)), "master logarithmic math")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.25)), "music math")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), -80.0), "zero volume")
	check(AudioServer.is_bus_mute(0), "mute")
	manager.apply_settings(Manager.DEFAULTS)
	var button := Button.new()
	root.add_child(button)
	button.pressed.emit()
	check(played == ["click"], "new button sounds exactly once")
	button.disabled = true
	button.pressed.emit()
	button.mouse_entered.emit()
	check(played.size() == 1, "disabled silent")
	button.disabled = false
	button.set_meta("no_sound", true)
	button.pressed.emit()
	check(played.size() == 1, "no_sound silent")
	button.set_meta("no_sound", false)
	button.mouse_entered.emit()
	check(played.back() == "hover", "hover sound")
	for i in 10: manager.play_sfx("click")
	var oldest: AudioStreamPlayer = manager.voices[0]
	manager.play_sfx("success")
	check(manager.voices.size() == 8 and not oldest in manager.voices, "drop oldest voice")
	check(manager.ducked, "jingle ducks")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), Manager.volume_db(40) - 9), "duck math")
	for i in 8: manager.play_sfx("click")
	check(not manager.ducked, "duck restores after jingle dropped")
	manager.play_sfx("success")
	await create_timer(0.9).timeout
	check(not manager.ducked, "duck restores on completion")
	for state in ["TITLE", "MORNING", "TRANSPORT", "COMMUTE", "SHOP", "WORK", "REVIEW", "EVENING"]:
		var expected: String = {"TITLE":"home", "MORNING":"home", "TRANSPORT":"street", "COMMUTE":"street", "SHOP":"street", "WORK":"work", "REVIEW":"work", "EVENING":"evening"}[state]
		check(Manager.mood_for(state, {"day":1, "trust":50}) == expected, "state mood " + state)
		check(Manager.mood_for(state, {"day":3, "trust":20}) == "crisis", "public crisis " + state)
	check(Manager.mood_for("WORK", {"day":1, "trust":20}) == "work", "crisis day guard")
	for pair in [["right","success"], ["wrong_high","fail"], ["promotion","promotion"], ["fired","fired"]]:
		Manager.review_for(button, pair[0])
		check(played.back() == pair[1], "review " + pair[0])
	var request_started := Time.get_ticks_usec()
	manager.play_music("home")
	manager.play_music("work")
	check(Time.get_ticks_usec() - request_started < 50000, "music requests never synthesize on main thread")
	var deadline := Time.get_ticks_msec() + 15000
	var frames := 0
	while not manager.is_ready("work") and Time.get_ticks_msec() < deadline:
		await process_frame
		frames += 1
	check(manager.is_ready("work"), "worker publishes requested mood")
	check(frames > 0 or manager.is_ready("home"), "main thread remains responsive during build")
	manager.play_music("home")
	await create_timer(0.1).timeout
	check(manager.mood == "home", "crossfade starts requested ready mood")
	manager.play_music("work")
	await create_timer(1.7).timeout
	check(manager.mood == "work", "music transition")
	if manager.dummy_driver:
		check(manager.music_players.filter(func(p): return p.volume_db > -1.0).size() == 1, "dummy crossfade reaches one audible voice")
	else:
		check(manager.music_players.filter(func(p): return p.playing).size() == 1, "crossfade stops outgoing")
	var meta := Meta.new("user://t037_settings_test.json", Clock.new("2026-11-11"))
	var screen := Settings.new()
	root.add_child(screen)
	screen.open(meta)
	for key in screen.audio_sliders:
		var slider: HSlider = screen.audio_sliders[key]
		check(slider.min_value == 0 and slider.max_value == 100, "slider range " + key)
		check(Rect2(Vector2.ZERO, Vector2(640,360)).encloses(slider.get_global_rect()), "slider fits " + key)
	screen.audio_sliders.master.value = 33
	var loaded := Meta.new("user://t037_settings_test.json", Clock.new("2026-11-11"))
	check(loaded.profile.data.settings.audio.master == 33 and manager.settings.master == 33, "UI saves and applies")
	screen.mute_button.pressed.emit()
	check(manager.settings.mute, "UI mute applies")
	screen.ask_reset()
	for control in [screen.confirm_button, screen.cancel_button, screen.mute_button, screen.sound_test_button]:
		check(Rect2(Vector2.ZERO, Vector2(640,360)).encloses(control.get_global_rect()), "settings control fits")
	if "--listen" in OS.get_cmdline_user_args():
		manager.apply_settings(Manager.DEFAULTS)
		for id in manager.bank.EFFECTS:
			print("Playing: ", id)
			manager.play_sfx(id)
			await create_timer(0.7).timeout
		for mood in manager.music.MOODS:
			manager.play_music(mood)
			await create_timer(5.0).timeout
	screen.queue_free()
	button.queue_free()
	manager.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	for suffix in ["", ".tmp"]:
		var path: String = "user://t037_settings_test.json" + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("test_t037_manager: %d checks, %d failures, %d ms" % [checks, failures, Time.get_ticks_msec() - started])
	quit(1 if failures else 0)

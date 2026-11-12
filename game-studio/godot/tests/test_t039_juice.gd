extends SceneTree
# T-039 (headless): Juice switches, final-state equality, nothing left after a skip, and the two display
# settings (Pixel font, Reduce motion) in the profile.
const Juice = preload("res://scripts/v2/juice.gd")
const Hooks = preload("res://scripts/v2/juice_hooks.gd")
const Profile = preload("res://scripts/meta/profile.gd")
const Settings = preload("res://scripts/v2/settings_scene.gd")
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const PixelFont = preload("res://scripts/v2/pixel_font.gd")
const ChartCanvas = preload("res://scripts/v2/data/chart_canvas.gd")
const PATH := "user://t039_profile_test.json"
var checks := 0
var failures := 0

class FakeMeta extends RefCounted:
	var profile: RefCounted

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in n: await process_frame

func make(at: Vector2 = Vector2(100, 80)) -> Panel:
	var node := Panel.new()
	node.position = at
	node.size = Vector2(120, 60)
	node.pivot_offset = Vector2(3, 4)
	node.modulate = Color(1, 1, 1, 0.9)
	root.add_child(node)
	return node

func state(node: Control) -> Array:
	return [node.position, node.size, node.scale, node.modulate, node.self_modulate, node.pivot_offset, node.visible]

func run() -> void:
	await process_frame
	await test_switches()
	await test_final_state()
	await test_particles()
	await test_hooks()
	await test_chart()
	test_profile()
	await test_settings()
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("test_t039_juice: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func all_effects(node: Control) -> void:
	Juice.pop_in(node)
	Juice.pulse(node)
	Juice.shake(node, 2, 0.25)
	Juice.set_pulse(node, true)

func test_switches() -> void:
	check(Juice.enabled and not Juice.instant and not Juice.reduce_motion and not Juice.force, "defaults: enabled, not instant, motion not reduced")
	check(not Juice.active(), "headless is safe by default: nothing animates")
	var plain := make()
	var before := state(plain)
	all_effects(plain)
	Juice.hop(plain)
	Juice.bounce(plain)
	check(state(plain) == before and Juice.pending() == 0, "inactive helpers change nothing and start nothing")
	var called := [0]
	Juice.pop_out(plain, func(): called[0] += 1)
	check(called[0] == 1, "pop_out runs its callback at once when inactive")
	var got := [0]
	Juice.count(plain, func(n): got[0] = n, 5, 42)
	check(got[0] == 42, "count lands on the final number at once when inactive")
	check(Juice.confetti(plain, Vector2.ZERO) == null and Juice.sparkle(plain, Vector2.ZERO) == null and Juice.title_card(plain, "Day 1") == null, "no particles or cards when inactive")
	Juice.force = true
	check(Juice.active(), "force lets a headless test animate")
	for flag in ["instant", "reduce_motion"]:
		if flag == "instant": Juice.instant = true
		else: Juice.reduce_motion = true
		check(not Juice.active(), flag + " turns motion off")
		all_effects(plain)
		check(state(plain) == before and Juice.pending() == 0, flag + ": state changes are instant")
		Juice.instant = false
		Juice.reduce_motion = false
	Juice.enabled = false
	check(not Juice.active(), "enabled = false turns everything off")
	Juice.enabled = true
	plain.free()

# The animated path, skipped or played to the end, lands exactly where the instant path is.
func test_final_state() -> void:
	Juice.force = true
	for mode in ["skip", "play"]:
		var reference := make()
		var before := state(reference)
		var node := make()
		all_effects(node)
		check(Juice.pending() >= 3, mode + ": tweens are running (%d)" % Juice.pending())
		await frames(2)
		check(state(node) != before, mode + ": the control is in motion")
		if mode == "skip":
			Juice.finish_all()
		else:
			await create_timer(0.7).timeout
			Juice.set_pulse(node, false)
		check(state(node) == before, mode + ": final state equals the instant state " + str(state(node)) + " vs " + str(before))
		check(not node.has_meta("juice_pop") and not node.has_meta("juice_pulse") and not node.has_meta("juice_move") and not node.has_meta("juice_loop"), mode + ": no markers left")
		check(Juice.pending() == 0, mode + ": no leftover tweens (%d)" % Juice.pending())
		for extra in ["hop", "bounce"]:
			if extra == "hop": Juice.hop(node)
			else: Juice.bounce(node)
			await frames(2)
			Juice.finish_all()
			check(state(node) == before and Juice.pending() == 0, mode + ": " + extra + " returns to the start")
		var closed := [0]
		Juice.pop_out(node, func(): closed[0] += 1)
		check(closed[0] == 0, mode + ": pop_out waits for its animation")
		Juice.finish_all()
		check(closed[0] == 1 and state(node) == before, mode + ": skipping pop_out runs the callback once and restores the control")
		var got := [0]
		Juice.count(node, func(n): got[0] = n, 0, 250)
		await frames(2)
		Juice.finish_all()
		check(got[0] == 250, mode + ": a skipped count shows the final number")
		reference.free()
		node.free()
	# A freed control with a running tween must not break the skip.
	var gone := make()
	all_effects(gone)
	gone.free()
	Juice.finish_all()
	check(Juice.pending() == 0, "skipping after the control was freed is safe")
	Juice.force = false

func test_particles() -> void:
	Juice.force = true
	var host := Control.new()
	root.add_child(host)
	var burst: Node = Juice.confetti(host, Vector2(100, 100), 200)
	check(burst != null and burst.parts.size() < 60 and is_equal_approx(burst.life, 0.8), "confetti: fewer than 60 particles, 0.8 s")
	check(burst.mouse_filter == Control.MOUSE_FILTER_IGNORE, "confetti never takes input")
	var colors_ok := true
	var allowed := {}
	for hex in preload("res://scripts/v2/palette.gd").colors(): allowed[Color(hex).to_rgba32()] = true
	for p in burst.parts:
		if not allowed.has(Color(p.color).to_rgba32()): colors_ok = false
	check(colors_ok, "confetti uses palette v4 colors only")
	var spark: Node = Juice.sparkle(host, Vector2(50, 50))
	var card: Node = Juice.title_card(host, "Day 3")
	check(spark != null and spark.parts.size() <= 8 and card != null and card.mouse_filter == Control.MOUSE_FILTER_IGNORE, "sparkle is a few pixels; the day card never takes input")
	check(Juice.pending() == 3, "three effect nodes alive")
	Juice.finish_all()
	await frames(2)
	check(not is_instance_valid(burst) and not is_instance_valid(spark) and not is_instance_valid(card) and Juice.pending() == 0, "no leftover particles after a skip")
	var again: Node = Juice.confetti(host, Vector2(100, 100))
	await create_timer(1.0).timeout
	await frames(2)
	check(not is_instance_valid(again) and Juice.pending() == 0, "confetti removes itself after 0.8 s")
	host.free()
	Juice.force = false

func test_hooks() -> void:
	var hooks := Hooks.new()
	root.add_child(hooks)
	var button := Button.new()
	button.position = Vector2(10, 10)
	button.size = Vector2(60, 16)
	root.add_child(button)
	button.size = Vector2(60, 16)
	button.button_down.emit()
	check(button.position == Vector2(10, 10), "headless: a pressed button does not move")
	button.button_up.emit()
	Juice.force = true
	button.button_down.emit()
	check(button.position == Vector2(10, 11), "pressed: 1 px offset")
	button.button_down.emit()
	check(button.position == Vector2(10, 11), "the offset is applied once")
	button.button_up.emit()
	check(button.position == Vector2(10, 10), "released: back in place")
	Juice.finish_all()
	check(button.self_modulate == Color(1, 1, 1, 1), "the highlight ends on the normal color")
	var off := Button.new()
	off.disabled = true
	off.position = Vector2(100, 10)
	root.add_child(off)
	off.button_down.emit()
	check(off.position == Vector2(100, 10), "a disabled button does not move")
	var card := make(Vector2(200, 200))
	Juice.hover_lift(card)
	card.mouse_entered.emit()
	check(card.position == Vector2(200, 199), "hover lifts a card by 1 px")
	card.mouse_exited.emit()
	check(card.position == Vector2(200, 200), "leaving puts it back")
	Juice.force = false
	card.mouse_entered.emit()
	check(card.position == Vector2(200, 200), "no lift when motion is off")
	# Esc skips everything.
	Juice.force = true
	var node := make()
	var before := state(node)
	all_effects(node)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	hooks._input(esc)
	check(state(node) == before and Juice.pending() == 0, "Esc lands every animation on its final state")
	Juice.force = false
	for n in [hooks, button, off, card, node]: n.free()

func test_chart() -> void:
	var data := {"ok": true, "type": "bar", "series": [{"name": "a", "points": [{"x": "p", "y": 3.0}, {"x": "q", "y": 5.0}]}]}
	var chart := ChartCanvas.new()
	chart.size = Vector2(200, 100)
	root.add_child(chart)
	chart.set_chart(data, {})
	check(chart.reveal == 1.0 and Juice.pending() == 0, "headless: the chart is drawn in full at once")
	chart.free()
	Juice.force = true
	chart = ChartCanvas.new()
	chart.size = Vector2(200, 100)
	root.add_child(chart)
	chart.set_chart(data, {})
	check(chart.reveal == 0.0 and Juice.pending() == 1, "first render: bars start growing")
	await create_timer(0.45).timeout
	check(chart.reveal == 1.0 and Juice.pending() == 0, "the chart is complete after 0.3 s")
	chart.set_chart(data, {})
	check(chart.reveal == 1.0 and Juice.pending() == 0, "later renders do not animate again")
	chart.free()
	Juice.force = false

func test_profile() -> void:
	var defaults: Dictionary = Profile.defaults("A", "2026-01-01").settings
	check(defaults.pixel_font == true and defaults.reduce_motion == false, "defaults: Pixel font on, Reduce motion off")
	# An old profile file (before T-039) has neither key.
	var old: Dictionary = Profile.defaults("Old", "2026-01-01")
	old.settings.erase("pixel_font")
	old.settings.erase("reduce_motion")
	old.settings.attendance = false
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var loaded := Profile.new(PATH)
	check(loaded.load_or_create("2026-01-02") == "ok", "an old profile file loads")
	check(loaded.data.settings.pixel_font == true and loaded.data.settings.reduce_motion == false and loaded.data.settings.attendance == false and loaded.data.display_name == "Old", "old profile: new settings get their defaults, the rest is kept")
	loaded.data.settings.pixel_font = false
	loaded.data.settings.reduce_motion = true
	check(loaded.save(), "the profile saves")
	var again := Profile.new(PATH)
	again.load_or_create("2026-01-03")
	check(again.data.settings.pixel_font == false and again.data.settings.reduce_motion == true, "both toggles persist")
	var bad: Dictionary = Profile.defaults("Bad", "2026-01-01")
	bad.settings.pixel_font = "yes"
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(bad))
	file.close()
	var fixed := Profile.new(PATH)
	fixed.load_or_create("2026-01-02")
	check(fixed.data.settings.pixel_font == true, "a wrong type falls back to the default")

func test_settings() -> void:
	var profile := Profile.new(PATH)
	profile.reset("2026-01-01")
	var meta := FakeMeta.new()
	meta.profile = profile
	var view := Settings.new()
	root.add_child(view)
	view.open(meta)
	await frames(2)
	var pixel: Font = PixelFont.font()
	check(view.pixel_font_button.text == "ON" and view.motion_button.text == "OFF", "Settings shows Pixel font ON and Reduce motion OFF")
	check(view.pixel_font_button.get_theme_font("font") == pixel, "the settings screen uses the pixel font")
	view.toggle_pixel_font()
	await frames(1)
	check(view.pixel_font_button.text == "OFF" and not WindowTheme.pixel_font_on and view.pixel_font_button.get_theme_font("font") == PixelFont.default_font(), "Pixel font OFF restores the default font at once")
	view.toggle_reduce_motion()
	check(view.motion_button.text == "ON" and Juice.reduce_motion, "Reduce motion ON")
	var stored := Profile.new(PATH)
	stored.load_or_create("2026-01-02")
	check(stored.data.settings.pixel_font == false and stored.data.settings.reduce_motion == true, "the toggles are saved in the profile file")
	view.toggle_pixel_font()
	view.toggle_reduce_motion()
	check(WindowTheme.pixel_font_on and not Juice.reduce_motion and view.pixel_font_button.text == "ON" and view.motion_button.text == "OFF", "both toggles switch back")
	for node in [view.pixel_font_button, view.motion_button]:
		check(Rect2(0, 0, 640, 360).encloses(node.get_global_rect()) and node.size.y >= 14, "toggle on screen: " + node.text)
	view.free()

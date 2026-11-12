extends "res://tests/test_v2_screens_render.gd"
# T-039 real-window layout test (do NOT run with --headless). Runs every screen of test_v2_screens_render
# (85 screens: title, commute, office, desktop and all windows, review, ending, evening) in another mode:
#   Godot --path game-studio/godot -s res://tests/test_t039_layout.gd -- --font=off
#   Godot --path game-studio/godot -s res://tests/test_t039_layout.gd -- --motion=reduce
# --font=off: the Settings toggle "Pixel font" is off (engine default font), animations instant.
# --motion=reduce: pixel font on, the Settings toggle "Reduce motion" is on and the instant test switch
# is NOT used, so the run proves that Reduce motion alone leaves every layout at rest.
# Optional: --capture --out=<folder> saves one PNG per screen there.
const WindowTheme = preload("res://scripts/v2/theme_v2.gd")
const PixelFont = preload("res://scripts/v2/pixel_font.gd")
const Juice = preload("res://scripts/v2/juice.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var font_off := "--font=off" in args
	var reduce := "--motion=reduce" in args
	for a in args:
		if a.begins_with("--out="):
			capture_dir = a.trim_prefix("--out=")
			capture_prefix = ""
			DirAccess.make_dir_recursive_absolute(capture_dir)
	WindowTheme.set_pixel_font(not font_off)
	Juice.reduce_motion = reduce
	check(font_off or reduce or captures, "pick a mode: --font=off or --motion=reduce")
	check(ThemeDB.fallback_font == (PixelFont.default_font() if font_off else PixelFont.font()), "the font mode is applied")
	check(not reduce or not Juice.active(), "Reduce motion: nothing animates")
	print("test_t039_layout mode: font=%s motion=%s" % ["off" if font_off else "pixel", "reduce" if reduce else "instant"])
	call_deferred("run")
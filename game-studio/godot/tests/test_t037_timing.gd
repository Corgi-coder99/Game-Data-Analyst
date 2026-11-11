extends SceneTree
const Music = preload("res://scripts/audio/music.gd")
const Bank = preload("res://scripts/audio/sfx_bank.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var total := Time.get_ticks_msec()
	var bank := Bank.new()
	var started := Time.get_ticks_msec()
	for id in Bank.EFFECTS: bank.get_effect(id)
	var sfx_ms := Time.get_ticks_msec() - started
	print("TIMING all_27_sfx_ms=", sfx_ms, " target=5000 hard_limit=15000")
	check(bank.cache.size() == 27, "all SFX built")
	check(sfx_ms < 15000, "SFX 3x budget")
	var music := Music.new()
	for mood in Music.MOODS:
		started = Time.get_ticks_msec()
		var wave := music.get_loop(mood)
		var elapsed := Time.get_ticks_msec() - started
		print("TIMING mood=", mood, " ms=", elapsed, " target=3000 hard_limit=9000")
		check(wave != null and music.is_ready(mood), "mood built " + mood)
		check(elapsed < 9000, "music 3x budget " + mood)
		# Stop immediately if the requested machine budget is missed; no further optimization passes.
		if elapsed >= 3000 or sfx_ms >= 5000:
			check(false, "requested performance budget missed; stop")
			break
	print("test_t037_timing: %d checks, %d failures, %d ms" % [checks, failures, Time.get_ticks_msec() - total])
	quit(1 if failures else 0)

extends SceneTree
const Music = preload("res://scripts/audio/music.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run")
func inspect_wave(wave: AudioStreamWAV, mood: String, bars: int) -> void:
	var bytes := wave.data
	var count := bytes.size() / 2
	check(wave.mix_rate == 16000 and wave.format == AudioStreamWAV.FORMAT_16_BITS and not wave.stereo, "music format " + mood)
	check(count == int(round(60.0 / Music.BPM[mood] * bars * 4 * 16000)), "sample count " + mood)
	check(wave.loop_mode == AudioStreamWAV.LOOP_FORWARD and wave.loop_begin == 0 and wave.loop_end == count, "full loop " + mood)
	check(bytes.decode_s16(0) == 0 and bytes.decode_s16(bytes.size() - 2) == 0, "exact seamless endpoints " + mood)
	var energy := 0.0
	var peak := 0
	for i in count:
		var sample := bytes.decode_s16(i * 2)
		peak = maxi(peak, absi(sample))
		var normalized := float(sample) / 32767.0
		energy += normalized * normalized
	var rms := sqrt(energy / count)
	check(peak < 30000 and rms > 0.005 and rms < 0.2, "non silent unclipped " + mood)
func run() -> void:
	var started := Time.get_ticks_msec()
	var music := Music.new()
	var full := music.get_loop("home")
	inspect_wave(full, "home", 8)
	check(full.get_length() >= 22 and full.get_length() <= 30, "8 bar length")
	check(full == music.get_loop("home"), "full loop cache")
	var plucks_after_first := music.pluck_cache.size()
	var second_length := music.get_loop("home", 4)
	check(second_length != full and music.pluck_cache.size() == plucks_after_first, "pluck cache reused across loop lengths")
	var independent := Music.new()
	check(full.data == independent.get_loop("home").data, "full mood byte identical across fresh renderers")
	var hashes: Array = [hash(full.data)]
	for mood in ["street", "work", "evening", "crisis"]:
		var wave := music.get_loop(mood, 2)
		inspect_wave(wave, mood, 2)
		var digest := hash(wave.data)
		check(not digest in hashes, "different mood " + mood)
		hashes.append(digest)
	check(music.is_ready("home") and not music.is_ready("crisis"), "readiness requires full production loop")
	check(music.get_ready("home") == full and music.get_ready("crisis") == null, "ready lookup never builds")
	check(music.get_loop("missing") == null and music.get_loop("home", 0) == null, "invalid requests safe")
	print("test_t037_music: %d checks, %d failures, %d ms" % [checks, failures, Time.get_ticks_msec() - started])
	quit(1 if failures else 0)

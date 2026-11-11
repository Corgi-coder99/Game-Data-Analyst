extends SceneTree
const Synth = preload("res://scripts/audio/synth.gd")
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
	var started := Time.get_ticks_msec()
	for shape in ["sine", "triangle", "square", "noise"]:
		var samples := Synth.tone(440, 0.2, 0.3, shape, 220)
		check(samples.size() == 4410, "sample count " + shape)
		check(Synth.wav(samples).data == Synth.wav(Synth.tone(440, 0.2, 0.3, shape, 220)).data, "determinism " + shape)
		var filtered := Synth.low_pass(samples)
		check(filtered.size() == samples.size() and Synth.echo(filtered).size() == samples.size(), "filter and echo length")
		var valid := true
		for sample in samples:
			if not is_finite(sample) or absf(sample) > 1: valid = false
		check(valid, "all samples finite and unclipped " + shape)
	check(Synth.adsr(-0.1, 0.2) == 0 and Synth.adsr(0.2, 0.2) == 0, "ADSR outside bounds")
	var impulses := PackedFloat32Array()
	impulses.resize(6615)
	impulses[0] = 1.0
	var echoed := Synth.echo(impulses, 0.025, 0.5)
	check(echoed[0] == 1 and echoed[int(0.025 * Synth.RATE)] == 0.5, "echo taps")
	var mixed := PackedFloat32Array([0, 0, 0])
	Synth.mix(mixed, PackedFloat32Array([0.5, 0.25]), 1)
	check(mixed == PackedFloat32Array([0, 0.5, 0.25]), "mix offsets")
	check(Synth.wav(PackedFloat32Array([NAN, INF, 2, -2])).data == PackedByteArray([0, 0, 0, 0, 255, 127, 1, 128]), "WAV guards invalid samples and clips safely")
	var bank := Bank.new()
	var duplicate := Bank.new()
	check(Bank.EFFECTS.size() == 27, "27 effects")
	for id in Bank.EFFECTS:
		var wave := bank.get_effect(id)
		# Resource data is read once. Never invoke a resource getter in the sample loop.
		var bytes := wave.data
		var count := bytes.size() / 2
		var energy := 0.0
		var peak := 0.0
		for i in count:
			var sample := float(bytes.decode_s16(i * 2)) / 32767.0
			energy += sample * sample
			peak = maxf(peak, absf(sample))
		var rms := sqrt(energy / count)
		check(rms > (0.001 if id == "hover" else 0.003) and rms < 0.25, "RMS " + id + " " + str(rms))
		check(peak < 0.95, "headroom " + id)
		check(wave.get_length() <= 0.601 and absf(wave.get_length() - float(Bank.EFFECTS[id][1])) < 0.001, "short duration " + id)
		check(wave == bank.get_effect(id), "cache " + id)
		check(bytes == duplicate.get_effect(id).data, "SFX deterministic " + id)
		check(wave.format == AudioStreamWAV.FORMAT_16_BITS and not wave.stereo and wave.mix_rate == 22050, "SFX format " + id)
	check(bank.get_effect("missing") == null, "unknown effect safe")
	print("test_t037_synth: %d checks, %d failures, %d ms" % [checks, failures, Time.get_ticks_msec() - started])
	quit(1 if failures else 0)

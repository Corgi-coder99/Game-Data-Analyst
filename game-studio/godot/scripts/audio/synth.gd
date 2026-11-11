extends RefCounted
# Deterministic 16-bit mono SFX synthesis; music has its own 16 kHz renderer.
const RATE := 22050
const TABLE_SIZE := 1024
static var sine_table: PackedFloat32Array = _make_table()

static func _make_table() -> PackedFloat32Array:
	var table := PackedFloat32Array()
	table.resize(TABLE_SIZE)
	for i in TABLE_SIZE: table[i] = sin(TAU * i / TABLE_SIZE)
	return table

static func oscillator(phase: float, shape: String = "sine") -> float:
	var cycle := fposmod(phase / TAU, 1.0)
	match shape:
		"triangle": return 1.0 - 4.0 * absf(fposmod(cycle + 0.25, 1.0) - 0.5)
		"square": return 1.0 if cycle < 0.5 else -1.0
	return sine_table[int(cycle * TABLE_SIZE) & 1023]

static func adsr(t: float, duration: float, attack: float = 0.008, decay: float = 0.06, sustain: float = 0.4, release: float = 0.08) -> float:
	if t < 0.0 or t >= duration: return 0.0
	var envelope := sustain
	if t < attack: envelope = t / maxf(attack, 0.0001)
	elif t < attack + decay: envelope = lerpf(1.0, sustain, (t - attack) / maxf(decay, 0.0001))
	return envelope * minf(1.0, (duration - t) / maxf(release, 0.0001))

static func tone(frequency: float, duration: float, amplitude: float = 0.3, shape: String = "sine", end_frequency: float = -1.0, seed_value: int = 37) -> PackedFloat32Array:
	var count := maxi(0, int(round(duration * RATE)))
	var samples := PackedFloat32Array()
	samples.resize(count)
	var table := sine_table
	var phase := 0.0
	var increment := frequency * TABLE_SIZE / RATE
	var final_frequency := end_frequency if end_frequency >= 0.0 else frequency
	var glide := (final_frequency - frequency) * TABLE_SIZE / RATE / maxi(count, 1)
	var noise_state := seed_value & 0xffffffff
	var attack := 0.008 * RATE
	var decay := 0.06 * RATE
	var release := mini(int(0.08 * RATE), maxi(1, count / 3))
	for i in count:
		phase += increment
		increment += glide
		var index := int(phase) & 1023
		var wave: float
		match shape:
			"noise":
				noise_state = (noise_state * 1664525 + 1013904223) & 0xffffffff
				wave = float(noise_state) / 2147483648.0 - 1.0
			"triangle": wave = 1.0 - absf(float(((index + 256) & 1023) - 512)) / 256.0
			"square": wave = 1.0 if index < 512 else -1.0
			_: wave = table[index]
		var envelope := 0.4
		if i < attack: envelope = i / attack
		elif i < attack + decay: envelope = 1.0 - 0.6 * (i - attack) / decay
		if i >= count - release: envelope *= float(count - 1 - i) / release
		samples[i] = wave * amplitude * envelope
	return samples

static func low_pass(samples: PackedFloat32Array, amount: float = 0.2) -> PackedFloat32Array:
	var out := samples.duplicate()
	var previous := 0.0
	var alpha := clampf(amount, 0.0, 1.0)
	for i in out.size():
		previous += (out[i] - previous) * alpha
		out[i] = previous
	return out

static func mix(target: PackedFloat32Array, source: PackedFloat32Array, offset: int = 0, gain: float = 1.0) -> void:
	var first := maxi(0, -offset)
	var last := mini(source.size(), target.size() - offset)
	for i in range(first, last): target[i + offset] += source[i] * gain

static func echo(samples: PackedFloat32Array, delay: float = 0.075, gain: float = 0.22) -> PackedFloat32Array:
	var out := samples.duplicate()
	var offset := int(delay * RATE)
	var tap_gain := gain
	for tap in range(1, 4):
		mix(out, samples, offset * tap, tap_gain)
		tap_gain *= gain
	return out

static func wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var count := samples.size()
	bytes.resize(count * 2)
	for i in count:
		var value := samples[i]
		if not is_finite(value): value = 0.0
		bytes.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream

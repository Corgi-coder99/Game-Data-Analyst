extends RefCounted
# A renderer can be used synchronously by tests. The game uses start()/get_ready() only.
const RATE := 16000
const LOOP_BARS := 8
const MOODS := ["home", "street", "work", "evening", "crisis"]
const BPM := {"home": 80.0, "street": 84.0, "work": 78.0, "evening": 76.0, "crisis": 70.0}
var cache: Dictionary = {}
var pluck_cache: Dictionary = {}
var build_ms: Dictionary = {}
var _sine := PackedFloat32Array()
var _mutex := Mutex.new()
var _thread: Thread
var _stopping := false

func _init() -> void:
	_sine.resize(1024)
	for i in 1024: _sine[i] = sin(TAU * i / 1024.0)

# Build one mood at a time, publishing completed resources under a mutex.
func start() -> Error:
	if _thread != null: return ERR_ALREADY_IN_USE
	_thread = Thread.new()
	return _thread.start(_build_all, Thread.PRIORITY_LOW)

func _build_all() -> void:
	for value in MOODS:
		if _cancelled(): break
		get_loop(value)

func _cancelled() -> bool:
	_mutex.lock()
	var value := _stopping
	_mutex.unlock()
	return value

func stop() -> void:
	_mutex.lock()
	_stopping = true
	_mutex.unlock()
	if _thread != null and _thread.is_started(): _thread.wait_to_finish()
	_thread = null

func is_ready(mood: String) -> bool:
	_mutex.lock()
	var ready := cache.has(mood + ":8")
	_mutex.unlock()
	return ready

func get_ready(mood: String) -> AudioStreamWAV:
	_mutex.lock()
	var stream: AudioStreamWAV = cache.get(mood + ":8")
	_mutex.unlock()
	return stream

func timings() -> Dictionary:
	_mutex.lock()
	var values := build_ms.duplicate()
	_mutex.unlock()
	return values

# Short, cached electric-piano plucks, including two echo taps. No sin/ADSR calls per sample.
func _pluck(mood: String, note: int, beat: float) -> PackedFloat32Array:
	var key := mood + ":" + str(note)
	if pluck_cache.has(key): return pluck_cache[key]
	var count := int(beat * RATE * 1.7)
	var body := int(beat * RATE * 0.7)
	var delay := int(beat * RATE * 0.5)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var table := _sine
	var frequency := 130.8128 * pow(2.0, float(MOODS.find(mood) + note) / 12.0)
	var step := frequency * 1024.0 / RATE
	var phase := 0.0
	var amplitude := 0.11
	var damping := pow(0.003, 1.0 / body)
	var attack := 64.0
	for i in body:
		var index := int(phase) & 1023
		var sample := (table[index] + 0.22 * table[(index * 2) & 1023]) * amplitude
		if i < attack: sample *= i / attack
		# Fade the final 5 ms to zero before the echo tail.
		if i >= body - 80: sample *= float(body - 1 - i) / 80.0
		samples[i] = sample
		phase += step
		amplitude *= damping
	# Iterate backwards so the taps always read the original dry waveform.
	for i in range(body - 1, -1, -1):
		var sample := samples[i]
		samples[i + delay] += sample * 0.18
		samples[i + delay * 2] += sample * 0.04
	pluck_cache[key] = samples
	return samples

func get_loop(mood: String, loop_bars: int = LOOP_BARS) -> AudioStreamWAV:
	if not mood in MOODS or loop_bars < 1 or loop_bars > LOOP_BARS: return null
	var key := mood + ":" + str(loop_bars)
	_mutex.lock()
	var cached: AudioStreamWAV = cache.get(key)
	_mutex.unlock()
	if cached != null: return cached
	var started := Time.get_ticks_usec()
	var beat: float = 60.0 / BPM[mood]
	var count := int(round(beat * loop_bars * 4 * RATE))
	var samples := PackedFloat32Array()
	samples.resize(count)
	var chords := [[0, 4, 7, 11], [-3, 0, 4, 7], [2, 5, 9, 12], [-5, -1, 2, 5]]
	if mood == "crisis": chords = [[0, 3, 7, 10], [-4, 0, 3, 7], [2, 5, 8, 12], [-5, -1, 2, 5]]
	# Render percussion once, reuse the sample arrays at each beat.
	var kick := PackedFloat32Array()
	kick.resize(2400)
	var phase := 0.0
	var step := 95.0 * 1024.0 / RATE
	var gain := 0.1
	var table := _sine
	for i in kick.size():
		kick[i] = table[int(phase) & 1023] * gain
		phase += step
		step *= 0.9995
		gain *= 0.997
	var snare := PackedFloat32Array()
	snare.resize(1400)
	var noise_state := 3700 + MOODS.find(mood)
	gain = 0.055
	var previous := 0.0
	for i in snare.size():
		noise_state = (noise_state * 1664525 + 1013904223) & 0xffffffff
		previous += (float(noise_state) / 2147483648.0 - 1.0 - previous) * 0.3
		snare[i] = previous * gain
		gain *= 0.996
	for bar in loop_bars:
		if _cancelled(): return null
		var chord: Array = chords[bar % 4]
		for n in 4:
			var pluck := _pluck(mood, int(chord[n]), beat)
			var offset := int((bar * 4 + n * 0.5) * beat * RATE)
			var limit := mini(pluck.size(), count - offset)
			for i in limit: samples[offset + i] += pluck[i]
		for tick in 4:
			if mood == "crisis" or (mood == "work" and tick != 0): continue
			var drum := kick if tick % 2 == 0 else snare
			var offset := int((bar * 4 + tick) * beat * RATE)
			for i in mini(drum.size(), count - offset): samples[offset + i] += drum[i]
			if mood == "street":
				var pluck := _pluck(mood, int(chord[tick]) + 12, beat)
				offset += int(beat * 0.6 * RATE)
				for i in mini(pluck.size(), count - offset): samples[offset + i] += pluck[i] * 0.55
	# A short periodic noise tile supplies quiet vinyl texture, built once with a fixed seed.
	var crackle := PackedFloat32Array()
	crackle.resize(2048)
	for i in crackle.size():
		noise_state = (noise_state * 1664525 + 1013904223) & 0xffffffff
		crackle[i] = (float(noise_state) / 2147483648.0 - 1.0) * (0.008 if i % 683 == 0 else 0.0015)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var sample := samples[i] + crackle[i & 2047]
		# Exact zero endpoints with a 25 ms fade prevent loop clicks.
		if i < 400: sample *= i / 400.0
		elif i >= count - 400: sample *= (count - 1 - i) / 400.0
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	if _cancelled(): return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	_mutex.lock()
	cache[key] = stream
	build_ms[key] = (Time.get_ticks_usec() - started) / 1000.0
	_mutex.unlock()
	return stream

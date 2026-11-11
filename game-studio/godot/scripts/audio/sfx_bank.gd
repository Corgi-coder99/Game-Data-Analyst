extends RefCounted
const Synth = preload("res://scripts/audio/synth.gd")
# frequency, duration, shape, final pitch, gain. Small original acoustic gestures.
const EFFECTS := {
	"click": [760, 0.055, "triangle", 500, 0.18],
	"hover": [900, 0.035, "sine", 850, 0.045],
	"confirm": [520, 0.22, "sine", 780, 0.3],
	"cancel": [330, 0.18, "triangle", 220, 0.24],
	"error": [140, 0.25, "square", 110, 0.16],
	"select": [650, 0.09, "sine", 720, 0.22],
	"toggle_on": [400, 0.13, "sine", 620, 0.24],
	"toggle_off": [620, 0.13, "sine", 400, 0.24],
	"coin_gain": [980, 0.27, "triangle", 1400, 0.28],
	"coin_spend": [900, 0.2, "triangle", 540, 0.25],
	"notification": [660, 0.38, "sine", 880, 0.28],
	"achievement": [440, 0.6, "triangle", 880, 0.3],
	"success": [520, 0.55, "sine", 780, 0.32],
	"fail": [160, 0.45, "square", 100, 0.18],
	"warning": [440, 0.35, "triangle", 330, 0.25],
	"keyboard_slam": [100, 0.18, "noise", 60, 0.48],
	"door_open": [180, 0.45, "triangle", 300, 0.22],
	"footstep": [80, 0.12, "noise", 40, 0.32],
	"page_turn": [200, 0.23, "noise", 100, 0.25],
	"typing": [400, 0.3, "noise", 350, 0.26],
	"alarm": [880, 0.6, "square", 880, 0.15],
	"coffee_pour": [300, 0.6, "noise", 200, 0.3],
	"cash_register": [1200, 0.42, "triangle", 1600, 0.27],
	"deadline_tick": [600, 0.065, "sine", 500, 0.07],
	"sick_day": [250, 0.6, "triangle", 110, 0.22],
	"promotion": [392, 0.6, "triangle", 784, 0.32],
	"fired": [220, 0.6, "triangle", 73, 0.3],
}
const JINGLES := ["achievement", "success", "fail", "promotion", "fired"]
var cache: Dictionary = {}

func get_effect(id: String) -> AudioStreamWAV:
	if not EFFECTS.has(id): return null
	if cache.has(id): return cache[id]
	var p: Array = EFFECTS[id]
	var samples := Synth.tone(p[0], p[1], p[4], p[2], p[3], 37 + EFFECTS.keys().find(id))
	if id in JINGLES and id != "fired":
		var notes := [1.0, 1.25, 1.5, 2.0]
		samples.fill(0.0)
		for n in notes.size():
			Synth.mix(samples, Synth.tone(float(p[0]) * notes[n], float(p[1]) * 0.4, 0.24, p[2]), int(float(n) * float(p[1]) * 0.2 * Synth.RATE))
	if id == "typing" or id == "alarm":
		for i in samples.size(): samples[i] *= 1.0 if int(float(i) / Synth.RATE * 20.0) % 2 == 0 else 0.1
	samples = Synth.echo(Synth.low_pass(samples, 0.28 if p[2] == "noise" else 0.65))
	cache[id] = Synth.wav(samples)
	return cache[id]

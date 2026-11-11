extends Node
const Bank = preload("res://scripts/audio/sfx_bank.gd")
const Music = preload("res://scripts/audio/music.gd")
const Hooks = preload("res://scripts/audio/audio_hooks.gd")
const DEFAULTS := {"master": 70, "music": 40, "sfx": 70, "mute": false}
const CROSSFADE := 1.5
signal sfx_played(id: String)
var settings: Dictionary = DEFAULTS.duplicate()
var bank := Bank.new()
var music := Music.new()
var voices: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var mood := ""
var requested_mood := ""
var music_start_error: Error = OK
var ducked := false
var dummy_driver := false
var fade: Tween
var profile: RefCounted

static func find_for(node: Node) -> Node:
	if not node.is_inside_tree(): return null
	return node.get_tree().get_first_node_in_group("procedural_audio")

static func emit_for(node: Node, id: String) -> void:
	var manager := find_for(node)
	if manager != null: manager.play_sfx(id)

static func install(flow: Node) -> void:
	if find_for(flow) != null: return
	var manager := load("res://scripts/audio/audio_manager.gd").new() as Node
	flow.add_child(manager)
	manager.bind_profile(flow.meta.profile if flow.meta != null else null)
	flow.state_changed.connect(func(state): manager.play_music(mood_for(state, flow.game.status() if flow.game != null else {})))

static func mood_for(state: String, public: Dictionary = {}) -> String:
	if int(public.get("day", 0)) >= 2 and float(public.get("trust", 100)) < 30.0: return "crisis"
	if state in ["TRANSPORT", "COMMUTE", "SHOP"]: return "street"
	if state in ["DAY_START", "WORK", "SUBMITTED", "REVIEW", "OVERTIME"]: return "work"
	if state in ["EVENING", "ENDING", "END_SCREEN"]: return "evening"
	return "home"

# Review categories are public presentation outcomes emitted by the existing review view.
static func review_for(node: Node, category: String) -> void:
	var id := str({"right":"success", "partial":"confirm", "wrong_low":"fail", "wrong_mid":"fail", "wrong_high":"fail", "promotion":"promotion", "fired":"fired", "bankrupt":"fired", "demotion":"warning", "warning":"warning"}.get(category, ""))
	if id != "": emit_for(node, id)

func _ready() -> void:
	dummy_driver = AudioServer.get_driver_name() == "Dummy"
	add_to_group("procedural_audio")
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		music_players.append(player)
	apply_settings(settings)
	var hooks := Hooks.new()
	hooks.manager = self
	add_child(hooks)
	music_start_error = music.start()

func bind_profile(value: RefCounted) -> void:
	profile = value
	apply_settings(profile.data.settings.get("audio", DEFAULTS) if profile != null else DEFAULTS)

func apply_settings(values: Dictionary, save: bool = false) -> void:
	for key in ["master", "music", "sfx"]:
		var value: Variant = values.get(key, DEFAULTS[key])
		settings[key] = clampi(int(value), 0, 100) if (value is int or value is float) else DEFAULTS[key]
	settings.mute = values.get("mute", false) == true
	for key in ["master", "music", "sfx"]:
		var index := AudioServer.get_bus_index("SFX" if key == "sfx" else str(key).capitalize())
		if index >= 0: AudioServer.set_bus_volume_db(index, volume_db(settings[key]))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), settings.mute)
	_update_duck()
	if save and profile != null:
		profile.data.settings.audio = settings.duplicate()
		profile.save()

static func volume_db(percent: float) -> float:
	return linear_to_db(percent / 100.0) if percent > 0 else -80.0

func play_sfx(id: String) -> void:
	var stream := bank.get_effect(id)
	if stream == null: return
	while voices.size() >= 8:
		var oldest := voices.pop_front() as AudioStreamPlayer
		oldest.stop()
		oldest.queue_free()
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.set_meta("jingle", id in Bank.JINGLES)
	add_child(player)
	voices.append(player)
	if dummy_driver:
		# Dummy has no mixer/device: preserve voice lifetime and ducking with a timer.
		get_tree().create_timer(stream.get_length()).timeout.connect(_finish_voice.bind(weakref(player)))
	else:
		player.finished.connect(_finish_voice.bind(weakref(player)))
		player.play()
	_update_duck()
	sfx_played.emit(id)

func _update_duck() -> void:
	ducked = false
	for voice in voices:
		if voice.get_meta("jingle", false): ducked = true
	var index := AudioServer.get_bus_index("Music")
	if index >= 0: AudioServer.set_bus_volume_db(index, volume_db(settings.music) - (9.0 if ducked else 0.0))

func is_ready(value: String) -> bool:
	return music.is_ready(value)

func _process(_delta: float) -> void:
	if requested_mood != mood and music.is_ready(requested_mood):
		_crossfade(requested_mood, music.get_ready(requested_mood))

func _exit_tree() -> void:
	if fade != null: fade.kill()
	for player in music_players: player.stop(); player.stream = null
	for player in voices: player.stop(); player.stream = null
	music.stop()

func play_music(value: String) -> void:
	if not value in Music.MOODS: return
	requested_mood = value
	# Until a loop is ready, keep SFX and any previous music playing. No main-thread synthesis.
	# Coalesce requests in _process so a loop is never started and stopped in the same frame.

func _crossfade(value: String, stream: AudioStreamWAV) -> void:
	mood = value
	if fade != null: fade.kill()
	# Keep the louder voice on an interrupted transition, then recycle the other.
	var outgoing := music_players[0]
	if music_players[1].volume_db > outgoing.volume_db: outgoing = music_players[1]
	var incoming := music_players[1] if outgoing == music_players[0] else music_players[0]
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -80.0
	if not dummy_driver: incoming.play()
	fade = create_tween().set_parallel(true)
	fade.tween_property(incoming, "volume_db", 0.0, CROSSFADE)
	fade.tween_property(outgoing, "volume_db", -80.0, CROSSFADE)
	fade.chain().tween_callback(outgoing.stop)

func _finish_voice(reference: WeakRef) -> void:
	var player := reference.get_ref() as AudioStreamPlayer
	if player == null or not player in voices: return
	voices.erase(player)
	player.queue_free()
	_update_duck()
extends SceneTree
const Flow = preload("res://scripts/v2/game_flow.gd")
const Manager = preload("res://scripts/audio/audio_manager.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const PATH := "user://t037_flow_profile.json"
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
	var flow := Flow.new()
	flow.fade_enabled = false
	flow.commute_enabled = false
	flow.daily_enabled = false
	flow.evening_enabled = false
	flow.meta = Meta.new(PATH, Clock.new("2026-11-11"))
	root.add_child(flow)
	var manager := Manager.find_for(flow)
	check(manager != null, "real autostart installs audio")
	Manager.install(flow)
	check(get_nodes_in_group("procedural_audio").size() == 1, "install is idempotent")
	check(manager.requested_mood == "home", "title state requests home")
	manager.sfx_played.connect(func(id): played.append(id))
	flow.open_meta_view("SETTINGS")
	check(flow.meta_view.audio_sliders.size() == 3, "real settings screen includes audio")
	flow.start_title()
	flow.new_game(104)
	flow.skip_intro()
	check(flow.state == "WORK" and manager.requested_mood == "work", "work state requests work")
	var report := {"question_id": flow.game.question_today().id, "forecast":"tang", "confidence":"vua", "evidence":[], "actions":[]}
	var result: Dictionary = flow.submit_report(report)
	check(result.ok and flow.state == "REVIEW", "real report reaches review")
	check(played.has("success") or played.has("fail") or played.has("confirm"), "review public outcome triggers audio")
	for pair in [["right","success"], ["wrong_low","fail"], ["promotion","promotion"], ["fired","fired"]]:
		played.clear()
		flow.review_view.line_shown.emit(pair[0], "")
		check(played == [pair[1]], "review signal wired exactly once " + pair[0])
	var deadline := Time.get_ticks_msec() + 15000
	while not manager.is_ready("work") and Time.get_ticks_msec() < deadline: await process_frame
	await create_timer(0.05).timeout
	check(manager.mood == "work", "worker music reaches real game")
	flow.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	check(get_nodes_in_group("procedural_audio").is_empty(), "manager removed with flow")
	for suffix in ["", ".tmp"]:
		var path: String = PATH + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("test_t037_flow: %d checks, %d failures, %d ms" % [checks, failures, Time.get_ticks_msec() - started])
	quit(1 if failures else 0)

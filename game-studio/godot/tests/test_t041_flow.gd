extends SceneTree
const Support = preload("res://tests/test_t041_support.gd")
const Flow = preload("res://scripts/v2/game_flow.gd")
const Meta = preload("res://scripts/meta/meta.gd")
const Clock = preload("res://scripts/meta/clock.gd")
const Playlog = preload("res://scripts/telemetry/playlog.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	Support.configure()
	create_timer(30).timeout.connect(func():
		printerr("FAIL: test_t041_flow exceeded 30 seconds")
		quit(1))
	call_deferred("run")

func run() -> void:
	var path := "user://t041_flow_profile.json"
	var initial := Playlog.new(Support.profile_at(path), "user://t041_flow/playlog.jsonl")
	Support.clean(initial)
	var flow := Flow.new()
	flow.autostart = false
	flow.fade_enabled = false
	flow.commute_enabled = false
	flow.evening_enabled = false
	flow.meta = Meta.new(path, Clock.new("2026-11-12"))
	flow.telemetry = Playlog.new(flow.meta.profile, initial.writer.path)
	root.add_child(flow)
	flow.begin_run("run")
	check(flow.state == "INTRO", "explanation before consent")
	flow.meta_view.finished.emit()
	check(flow.state == "CONSENT", "consent follows explanation")
	check(flow.meta.profile.data.telemetry.seen and not flow.telemetry.enabled(), "closing consent means remembered No")
	check(flow.meta_view.no_button.has_focus(), "No thanks default focus")
	check(flow.meta_view.yes_button.size == flow.meta_view.no_button.size, "equal prominence")
	flow.meta_view.no_button.pressed.emit()
	check(flow.state == "DAY_START", "No thanks continues game")
	check(not FileAccess.file_exists(initial.writer.path), "No thanks writes nothing")
	flow.start_title()
	flow.open_meta_view("SETTINGS")
	check(flow.meta_view.telemetry_button.text == "OFF", "Settings off by default")
	flow.meta_view.telemetry_button.pressed.emit()
	check(flow.state == "CONSENT", "Settings offers same consent screen")
	flow.meta_view.yes_button.pressed.emit()
	check(flow.state == "SETTINGS" and flow.telemetry.enabled(), "Yes opts in and returns to Settings")
	flow.meta_view.export_button.pressed.emit()
	check(flow.meta_view.export_toast.visible and flow.meta_view.export_toast.text.contains(ProjectSettings.globalize_path("user://t041_flow")), "full exported OS path in toast")
	var pid: String = flow.telemetry.pid()
	flow.meta_view.delete_button.pressed.emit()
	check(flow.meta_view.telemetry_button.text == "ON" and flow.telemetry.pid() == "", "Delete keeps toggle and clears identity")
	check(not FileAccess.file_exists(initial.writer.path), "Delete removes file")
	flow.start_title()
	flow.begin_run("run")
	check(flow.state == "DAY_START", "consent shown once")
	check(flow.telemetry.pid() != pid, "run after Delete regenerates identity")
	flow.skip_intro()
	check(flow.state == "WORK", "headless reaches desktop")
	var desktop: Control = flow.desktop
	var item: Dictionary = flow.game.news_today()[0]
	desktop.select_news(item.uid)
	desktop.use_tool(str(flow.game.tools()[0].id))
	desktop.use_tool(str(flow.game.tools()[0].id))
	desktop.report_window.wait_requested.emit()
	var session: RefCounted = desktop.data_session
	if not session.files.is_empty():
		session.open_file(session.files[0].id)
		session.changed.emit()
		var hinted: Dictionary = session.request_hint(session.files[0].id)
		check(hinted.ok, "real hint succeeds")
	var result: Dictionary = flow.submit_report({"question_id":flow.game.question_today().id,"forecast":"ngang","confidence":"thap","actions":[],"evidence":[],"text":"sensitive typed report"})
	check(result.ok and flow.state == "REVIEW", "successful submission enters review")
	var rows: Array = flow.telemetry.writer.records()
	var counts := {}
	for row in rows: counts[row.e] = int(counts.get(row.e, 0)) + 1
	for event in ["session_start", "run_start", "day_start", "wait", "report_submit", "day_end", "hint"]:
		check(counts.get(event, 0) == 1, "one observed " + event)
	check(counts.get("verify", 0) == 2, "paid and cached verify hooks")
	var wait_rows: Array = rows.filter(func(row): return row.e == "wait")
	check(wait_rows.size() == 1 and wait_rows[0].waited_minutes > 0 and wait_rows[0].app_minutes > 0, "flow distinguishes wait and app time")
	check(rows[-1].e == "day_end" and not flow.telemetry.day_open, "review closes observed day")
	flow.start_title()
	rows = flow.telemetry.writer.records()
	check(rows[-1].e == "quit", "leaving open run records quit")
	flow.open_meta_view("SETTINGS")
	flow.meta_view.telemetry_button.pressed.emit()
	check(not flow.telemetry.enabled() and flow.telemetry.pid() == "", "one-click withdrawal")
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://t041_flow")), "withdraw removes exports too")
	Support.clean(flow.telemetry)
	flow.free()
	await process_frame
	print("test_t041_flow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

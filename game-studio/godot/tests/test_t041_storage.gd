extends SceneTree
const Support = preload("res://tests/test_t041_support.gd")
const Playlog = preload("res://scripts/telemetry/playlog.gd")
const Bots = preload("res://tests/telemetry_bots.gd")
const Writer = preload("res://scripts/telemetry/writer.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	Support.configure()
	call_deferred("run")

func run() -> void:
	var profile := Support.profile_at("user://t041_storage_profile.json")
	var log := Playlog.new(profile, "user://t041_storage/playlog.jsonl")
	Support.clean(log)
	check(not log.enabled() and log.pid() == "", "fresh profile defaults off without identity")
	Bots.run_one("official_only", 104, 10, log)
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://t041_storage")), "off creates no telemetry directory after a game")
	check(profile.data.telemetry.player_pid == "", "off game has no pseudonym")
	log.set_consent(true)
	check(log.pid().length() == 32 and log.pid().is_valid_hex_number(false), "Crypto 128-bit hex pseudonym")
	check(FileAccess.file_exists(log.writer.path), "consent writes local playlog")
	if not FileAccess.file_exists(log.writer.path):
		printerr("Storage fixture is not writable: ", ProjectSettings.globalize_path(log.writer.path))
		finish()
		return
	var original: String = log.pid()
	var result: Dictionary = Bots.run_one("official_only", 104, 10, log)
	check(result.get("day", 0) == 10, "fixture reaches ten days")
	Bots.run_one("official_only", 104, 10, log)
	var rows: Array = log.writer.records()
	var counts := {}
	var ids := {}
	for row in rows:
		counts[row.e] = int(counts.get(row.e, 0)) + 1
		check(row.pid == original, "runs share install identity")
		if row.e == "run_start": ids[row.run_id] = true
	check(ids.size() == 2, "run ids differ")
	for event in ["run_start", "run_end"]: check(counts.get(event, 0) == 2, "two " + event)
	for event in ["day_start", "day_end", "report_submit", "wait"]: check(counts.get(event, 0) == 20, "twenty " + event)
	check(counts.get("session_start", 0) == 1 and counts.get("consent", 0) == 1, "one session and opt-in event")
	var exported: String = log.writer.export_data()
	check(exported != "", "export succeeds")
	if exported != "":
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(exported))
		check(payload is Dictionary and payload.schema_version == 1 and payload.runs.size() == 2, "export groups runs in array")
	var loaded := Support.profile_at(profile.path)
	loaded.load_or_create("2026-11-12")
	check(loaded.data.telemetry.player_pid == original and loaded.data.telemetry.enabled, "consent and identity survive profile load")
	log.set_consent(false)
	check(not log.enabled() and log.pid() == "" and profile.data.telemetry.player_pid == "", "withdraw resets identity and disables")
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://t041_storage")), "withdraw removes log and exports folder")
	log.set_consent(true)
	check(log.pid() != original, "new consent creates different identity")
	log.delete_data()
	check(log.enabled() and profile.data.telemetry.player_pid == "", "delete keeps toggle but resets identity")
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://t041_storage")), "delete removes directory")
	log.run_start("run", 104, 10)
	check(log.pid() != original and log.pid().length() == 32, "next run after delete creates new identity")
	var cap := Writer.new("user://t041_cap/playlog.jsonl")
	cap.delete_data()
	# Valid, large runs: pass 2 MiB in a bounded fixture, never write oversized strings.
	var padding := "a".repeat(40)
	var fixture := ""
	for index in 6:
		var id := "%016x" % (index + 1)
		fixture += JSON.stringify({"v":1,"pid":original,"run_id":id,"t":0,"e":"run_start","src":"human","mode":"run","seed":104,"horizon":10}) + "\n"
		for event_index in 2400:
			fixture += JSON.stringify({"v":1,"pid":original,"run_id":id,"t":event_index,"e":"verify","src":"human","tool":padding,"topic":padding,"source_tier":padding,"error":padding,"ok":false,"day":1}) + "\n"
		fixture += JSON.stringify({"v":1,"pid":original,"run_id":id,"t":2400,"e":"run_end","src":"human","days_played":1}) + "\n"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cap.path.get_base_dir()))
	var cap_file := FileAccess.open(cap.path, FileAccess.WRITE)
	cap_file.store_string(fixture)
	cap_file.close()
	check(cap.stored_bytes() > Writer.MAX_BYTES, "fixture actually exceeds cap")
	cap.append({"v":1,"pid":original,"run_id":"","t":0,"e":"session_start","src":"human","date":"2026-11-12"})
	check(cap.stored_bytes() <= Writer.MAX_BYTES, "2 MiB cap")
	var retained := {}
	for row in cap.records():
		if row.run_id == "": continue
		if not retained.has(row.run_id): retained[row.run_id] = {"start":0,"end":0}
		if row.e == "run_start": retained[row.run_id].start += 1
		if row.e == "run_end": retained[row.run_id].end += 1
	check(retained.size() < 6 and retained.size() > 0, "oldest runs dropped")
	check(not retained.has("0000000000000001"), "oldest run removed first")
	for id in retained: check(retained[id].start == 1 and retained[id].end == 1, "whole runs retained")
	cap.delete_data()
	# Leave a synthetic, human-schema fixture for the external Python validator.
	log.delete_data()
	log.run_start("run", 104, 10)
	log.run_end({"day":0,"ending":"survived","won":false,"score":0})
	print("Validator fixture: ", ProjectSettings.globalize_path(log.writer.path))
	finish()

func finish() -> void:
	print("test_t041_storage: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

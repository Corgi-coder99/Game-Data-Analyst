extends RefCounted
# Pseudonymous personal data: consent gates every write and identity creation.
# Receives only public API snapshots. It never holds or mutates a WorldGame.
const Writer = preload("res://scripts/telemetry/writer.gd")
const FIELDS := {
	"session_start": ["date", "build", "mode"], "consent": ["value"],
	"run_start": ["mode", "seed", "horizon", "tutorial", "learn_level"],
	"day_start": ["day", "rank", "trust", "energy_max", "question_id", "news_count"],
	"verify": ["day", "tool", "ok", "error", "energy_left", "minutes", "band", "source_tier", "topic"],
	"wait": ["day", "waited_minutes", "app_minutes"], "hint": ["day", "energy_left"],
	"report_submit": ["day", "minutes", "band", "answer", "n_actions", "n_evidence", "has_analysis", "free_text_len_class"],
	"day_end": ["day", "timing", "label", "delta", "acc", "ev", "trust", "rank", "adopted", "executed", "shifted"],
	"run_end": ["ending", "won", "score", "days_played", "rank", "trust", "warnings", "demotions"],
	"quit": ["state", "day"]
}
var writer: RefCounted
var profile: RefCounted
var src := "human"
var bot_pid := ""
var run_id := ""
var started := Time.get_ticks_msec()
var session_written := false
var day_open := false
var last_minutes := 0
var waited := 0
var app_minutes := 0

func _init(profile_ref: RefCounted = null, file_path: String = "user://telemetry/playlog.jsonl", bot_name: String = "") -> void:
	profile = profile_ref
	writer = Writer.new(file_path)
	if bot_name != "":
		src = "bot"
		bot_pid = "bot-" + bot_name

func enabled() -> bool:
	return bot_pid != "" or (profile != null and bool(profile.data.get("telemetry", {}).get("enabled", false)))

func pid() -> String:
	if not enabled(): return ""
	if bot_pid != "": return bot_pid
	return str(profile.data.telemetry.get("player_pid", ""))

func _identity() -> void:
	if not enabled() or src == "bot" or pid() != "": return
	profile.data.telemetry.player_pid = Crypto.new().generate_random_bytes(16).hex_encode()
	profile.save()

func set_consent(value: bool) -> void:
	if profile == null: return
	profile.data.telemetry.seen = true
	profile.data.telemetry.enabled = value
	if not value:
		delete_data()
	else:
		_identity()
		profile.save()
		session_start()
		emit_event("consent", {"value": true})
		# The first write may have created user:// for a new install.
		profile.save()

func delete_data() -> void:
	writer.delete_data()
	if profile != null:
		profile.data.telemetry.player_pid = ""
		profile.save()
	run_id = ""
	day_open = false
	session_written = false

func session_start() -> void:
	if not enabled() or session_written: return
	_identity()
	session_written = true
	emit_event("session_start", {"date": Time.get_date_string_from_system(true), "build": str(ProjectSettings.get_setting("application/config/version", "unversioned")), "mode": "none"})

func emit_event(event: String, fields: Dictionary = {}) -> void:
	if not enabled() or not FIELDS.has(event): return
	_identity()
	var row := {"v": 1, "pid": pid(), "run_id": run_id, "t": int((Time.get_ticks_msec() - started) / 1000), "e": event, "src": src}
	for key in FIELDS[event]:
		var value: Variant = fields.get(key)
		if value is float: row[key] = snappedf(value, 0.01)
		elif value is int or value is bool: row[key] = value
		elif value is String and value.length() <= 40: row[key] = value
	writer.append(row)

func run_start(mode: String, seed_value: int, horizon: int, tutorial: String = "", level: int = 1) -> void:
	if not enabled(): return
	session_start()
	run_id = Crypto.new().generate_random_bytes(8).hex_encode()
	emit_event("run_start", {"mode": mode, "seed": seed_value, "horizon": horizon, "tutorial": tutorial, "learn_level": level})

func day_start(status: Dictionary, question: Dictionary, news: Array) -> void:
	if not enabled() or run_id == "": return
	day_open = true
	waited = 0
	app_minutes = 0
	last_minutes = int(status.get("minutes", 0))
	var fields := _select(status, ["day", "rank", "trust", "energy_max"])
	if question.has("id"): fields.question_id = question.id
	fields.news_count = news.size()
	emit_event("day_start", fields)

func verification(status: Dictionary, tool: String, result: Dictionary, item: Dictionary) -> void:
	if not day_open: return
	last_minutes = int(status.get("minutes", last_minutes))
	var fields := _select(status, ["day", "minutes", "band"])
	fields.merge({"tool": tool, "ok": bool(result.get("ok", false)), "error": str(result.get("error", "")), "energy_left": int(status.get("energy", 0))})
	fields.merge(_select(item, ["source_tier", "topic"]))
	emit_event("verify", fields)

func time_spent(status: Dictionary, in_app: bool) -> void:
	if not day_open: return
	var minutes := int(status.get("minutes", last_minutes))
	if in_app: app_minutes += maxi(0, minutes - last_minutes)
	else: waited += maxi(0, minutes - last_minutes)
	last_minutes = minutes

func hint(status: Dictionary) -> void:
	if day_open: emit_event("hint", {"day": status.day, "energy_left": status.energy})

func report_submit(status: Dictionary, report: Dictionary) -> void:
	if not day_open: return
	emit_event("wait", {"day": status.day, "waited_minutes": waited, "app_minutes": app_minutes})
	var fields := _select(status, ["day", "minutes", "band"])
	var length := _text_length(report)
	fields.merge({"answer": report.get("forecast", ""), "n_actions": report.get("actions", []).size(), "n_evidence": report.get("evidence", []).size(), "has_analysis": report.has("analysis"), "free_text_len_class": "0" if length == 0 else ("1-40" if length <= 40 else "41+")})
	emit_event("report_submit", fields)

func day_end(status: Dictionary, review: Dictionary) -> void:
	if not day_open or not review.has("result"): return
	day_open = false
	var fields := _select(status, ["day", "trust", "rank"])
	fields.merge(_select(review, ["timing", "shifted"]))
	fields.merge(_select(review.result, ["label", "delta", "acc", "ev"]))
	fields.adopted = 0
	fields.executed = 0
	for action in review.get("actions", []):
		fields.adopted += int(action.get("adopted", false))
		fields.executed += int(action.get("executed", false))
	emit_event("day_end", fields)

func run_end(status: Dictionary) -> void:
	if run_id == "": return
	var fields := _select(status, ["ending", "won", "score", "rank", "trust", "warnings", "demotions"])
	fields.days_played = int(status.get("day", 0))
	emit_event("run_end", fields)
	run_id = ""
	day_open = false

func quit_run(state: String, status: Dictionary) -> void:
	if run_id == "": return
	if day_open: emit_event("wait", {"day": status.get("day", 0), "waited_minutes": waited, "app_minutes": app_minutes})
	emit_event("quit", {"state": state, "day": status.get("day", 0)})
	run_id = ""
	day_open = false

func _select(source: Dictionary, keys: Array) -> Dictionary:
	var out := {}
	for key in keys:
		if source.has(key): out[key] = source[key]
	return out

func _text_length(report: Dictionary) -> int:
	# Only length escapes this function; no arbitrary report keys reach the writer.
	var length := 0
	for key in ["text", "reason", "reasoning", "notes", "comment"]:
		if report.get(key) is String: length += report[key].length()
	return length

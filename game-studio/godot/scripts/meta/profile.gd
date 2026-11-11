extends RefCounted
# T-030: the local player profile, saved as JSON (default user://profile.json). Versioned, tolerant of a
# missing or corrupt file (a corrupt file is kept as <path>.bak and a fresh profile is started).
# Holds only a display name and public in-game numbers. No real name, no email, no network.
const VERSION := 1
var path := "user://profile.json"
var data: Dictionary = {}
var load_status := "new"
var _cfg: Dictionary

func _init(file_path: String = "user://profile.json", config: Dictionary = {}) -> void:
	path = file_path
	_cfg = config

static func defaults(display_name: String, today: String) -> Dictionary:
	return {
		"version": VERSION,
		"display_name": display_name,
		"created": today,
		"reputation": 0,
		"streak": 0,
		"best_streak": 0,
		"last_finished_day": "",
		"freezes": 0,
		"title": "",
		"leave": [],
		"achievements": {},
		"history": [],
		"winners": [],
		"pending_fine": 0,
		"pending_bonus": 0,
		"ladder": {"for_day": "", "step": ""},
		"settings": {"attendance": true, "quiet_start": 21, "quiet_end": 8, "intro_seen": false, "audio": {"master": 70, "music": 40, "sfx": 70, "mute": false}},
		"stats": {"days_total": 0, "best_rank_index": -1, "ontime_streak": 0, "best_ontime": 0, "honest_days": 0, "honest_right": 0, "runs_survived": 0, "rehired": 0, "perfect_days": 0, "verified_days": 0, "best_day": {}},
	}

func default_name() -> String:
	return str(_cfg.get("profile", {}).get("default_name", "Analyst"))

# Loads the file. Missing: a fresh profile. Corrupt or wrong shape: backup, then a fresh profile.
func load_or_create(today: String) -> String:
	data = defaults(default_name(), today)
	if not FileAccess.file_exists(path):
		load_status = "new"
		return load_status
	var text := FileAccess.get_file_as_string(path)
	var parser := JSON.new()
	var parsed: Variant = parser.data if parser.parse(text) == OK else null
	if not parsed is Dictionary or not parsed.has("version"):
		_backup()
		load_status = "corrupt"
		return load_status
	data = _merge(data, parsed)
	data.version = VERSION
	load_status = "ok"
	return load_status

func _backup() -> void:
	var bak := path + ".bak"
	if FileAccess.file_exists(bak): DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(bak))

# Field by field: unknown keys are dropped, wrong types fall back to the default.
func _merge(base: Variant, incoming: Variant) -> Variant:
	if base is Dictionary:
		if not incoming is Dictionary: return base
		var out: Dictionary = {}
		if base.is_empty():
			# Free-form maps (achievements, best_day) keep their keys.
			for key in incoming: out[str(key)] = incoming[key]
			return out
		for key in base: out[key] = _merge(base[key], incoming[key]) if incoming.has(key) else base[key]
		return out
	if base is bool: return bool(incoming) if incoming is bool else base
	if base is int: return int(incoming) if (incoming is float or incoming is int) else base
	if base is String: return str(incoming) if incoming is String else base
	if base is Array:
		if not incoming is Array: return base
		return incoming.filter(func(e): return e is Dictionary)
	return base

func save() -> bool:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var real := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path): DirAccess.remove_absolute(real)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), real) == OK

# Deletes the file and starts again. History is not kept (this is the player's explicit reset).
func reset(today: String) -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	data = defaults(default_name(), today)
	load_status = "new"

# Display name rules: letters, digits, space, - _ . ' only; 1..name_max characters; no "@" (an email
# must never end up here). Empty or rejected input gives the default name.
func clean_name(raw: String) -> String:
	var limit := int(_cfg.get("profile", {}).get("name_max", 16))
	if raw.contains("@"): return default_name()
	var out := ""
	for i in raw.length():
		var ch := raw[i]
		var code := ch.unicode_at(0)
		var ok := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or ch in [" ", "-", "_", ".", "'"]
		if ok: out += ch
	out = out.strip_edges()
	if out.length() > limit: out = out.substr(0, limit).strip_edges()
	return out if out != "" else default_name()

func set_name(raw: String) -> String:
	data.display_name = clean_name(raw)
	return data.display_name

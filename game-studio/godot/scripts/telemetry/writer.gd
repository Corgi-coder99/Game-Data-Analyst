extends RefCounted
# Local JSONL only. No handle survives an event; disk failures are never game failures.
const MAX_BYTES := 2 * 1024 * 1024
var path: String
var suppressed_run := ""

func _init(file_path: String = "user://telemetry/playlog.jsonl") -> void:
	path = file_path

func valid_path() -> bool:
	return path.begins_with("user://") and not ".." in path and path.ends_with(".jsonl")

func records() -> Array:
	var out: Array = []
	if not valid_path() or not FileAccess.file_exists(path): return out
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return out
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty(): continue
		var parser := JSON.new()
		if parser.parse(line) == OK and parser.data is Dictionary: out.append(parser.data)
	return out

func append(event: Dictionary) -> void:
	if not valid_path(): return
	var run := str(event.get("run_id", ""))
	if suppressed_run != "" and run == suppressed_run: return
	var line := JSON.stringify(event) + "\n"
	var bytes := line.to_utf8_buffer().size()
	var size_bytes := stored_bytes()
	if size_bytes + bytes > MAX_BYTES:
		var kept := records()
		kept.append(event)
		# Drop a run as a unit, even if it spans sessions. Session-only records are units too.
		while _bytes(kept) > MAX_BYTES and not kept.is_empty():
			var oldest := str(kept[0].get("run_id", ""))
			if oldest == "": kept.pop_front()
			else:
				kept = kept.filter(func(row): return str(row.get("run_id", "")) != oldest)
				if oldest == run: suppressed_run = run
		_replace(kept)
		return
	if not _ensure_directory(): return
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file == null: return
	file.seek_end()
	file.store_string(line)
	file.flush()

func _ensure_directory() -> bool:
	# make_dir_recursive emits engine errors on failure. Single-level calls return errors silently.
	var directory := DirAccess.open("user://")
	if directory == null: return false
	for part in path.trim_prefix("user://").get_base_dir().split("/", false):
		if not directory.dir_exists(part) and directory.make_dir(part) != OK: return false
		if directory.change_dir(part) != OK: return false
	return true

func _bytes(rows: Array) -> int:
	var total := 0
	for row in rows: total += JSON.stringify(row).to_utf8_buffer().size() + 1
	return total

func _replace(rows: Array) -> void:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return
	for row in rows: file.store_line(JSON.stringify(row))
	file.flush()
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))

func stored_bytes() -> int:
	if not valid_path() or not FileAccess.file_exists(path): return 0
	var file := FileAccess.open(path, FileAccess.READ)
	return 0 if file == null else file.get_length()

func summary() -> Dictionary:
	var runs := {}
	for row in records():
		if str(row.get("run_id", "")) != "": runs[row.run_id] = true
	return {"runs": runs.size(), "kb": ceili(stored_bytes() / 1024.0)}

func export_data() -> String:
	if not valid_path() or not FileAccess.file_exists(path): return ""
	var date := Time.get_date_string_from_system(true).replace("-", "")
	var destination := path.get_base_dir().path_join("export_" + date + ".json")
	var runs: Array = []
	var outside: Array = []
	var indices := {}
	for row in records():
		var id := str(row.get("run_id", ""))
		if id == "": outside.append(row)
		else:
			if not indices.has(id):
				indices[id] = runs.size()
				runs.append({"run_id": id, "events": []})
			runs[indices[id]].events.append(row)
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null: return ""
	file.store_string(JSON.stringify({"schema_version": 1, "runs": runs, "events": outside}))
	file.flush()
	return ProjectSettings.globalize_path(destination)

func delete_data() -> void:
	# Only the writer's dedicated user:// directory; never follow nested folders or links.
	if not valid_path(): return
	var folder := path.get_base_dir()
	if folder == "user:/" or folder == "user://": return
	var directory := DirAccess.open(folder)
	if directory == null: return
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	suppressed_run = ""

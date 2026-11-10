extends SceneTree
# T-031 headless test: the repository is English-only. Fails if player-facing data or code contains
# Vietnamese diacritics ([À-ỹ]) anywhere under res://data, res://scripts, res://scenes, res://tests, res://tools.
# Allowlist (documented): the three test files whose source contains the regex literal itself. The ASCII ids "tang", "giam", "ngang" are logic ids, not display text.
const ROOTS := ["res://data", "res://scripts", "res://scenes", "res://tests", "res://tools"]
const EXTENSIONS := ["json", "gd", "tscn", "tres"]
const ALLOWLIST: Array = ["res://tests/test_t031_english.gd", "res://tests/test_life.gd", "res://tests/test_v2_popups.gd"]
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func collect(dir: String, out: Array) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in EXTENSIONS: out.append(dir + "/" + file)
	for sub in DirAccess.get_directories_at(dir):
		collect(dir + "/" + sub, out)

func run() -> void:
	var pattern := RegEx.new()
	pattern.compile("[À-ỹ]")
	var files: Array = []
	for root_dir in ROOTS: collect(root_dir, files)
	check(files.size() > 50, "scanned a realistic number of files: %d" % files.size())
	for path in files:
		if path in ALLOWLIST: continue
		var found := pattern.search(FileAccess.get_file_as_string(path))
		check(found == null, "English only: " + path + (" (found '" + found.get_string() + "')" if found != null else ""))
	print("test_t031_english: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

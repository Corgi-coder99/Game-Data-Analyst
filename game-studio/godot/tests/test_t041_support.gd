extends RefCounted
const Profile = preload("res://scripts/meta/profile.gd")
const Playlog = preload("res://scripts/telemetry/playlog.gd")

static func configure() -> void:
	# Isolated disposable fixture data. No actual player's profile is opened or removed.
	OS.set_environment("APPDATA", OS.get_environment("TEMP"))
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "ai-company-t041")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))

static func profile_at(path: String) -> RefCounted:
	var profile := Profile.new(path)
	profile.data = Profile.defaults("Synthetic", "2026-11-12")
	return profile

static func clean(log: RefCounted) -> void:
	log.delete_data()
	if log.profile != null:
		for suffix in ["", ".tmp", ".bak"]:
			var path: String = log.profile.path + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

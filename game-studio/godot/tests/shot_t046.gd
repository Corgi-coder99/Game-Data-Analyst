extends SceneTree
# T-046 screenshots (run WITHOUT --headless): primer pages and the title, saved to docs/screenshots-T-046.
const Primer = preload("res://scripts/v2/learn/primer_scene.gd")
const Title = preload("res://scenes/v2/title.tscn")
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://docs/screenshots-T-046")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
func run() -> void:
	var strings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	var view := Primer.new()
	root.add_child(view)
	view.open(strings.primer)
	for i in view.pages.size():
		view.show_page(i)
		await snap("primer-%d" % (i + 1))
	view.queue_free()
	var title := Title.instantiate()
	root.add_child(title)
	await snap("title")
	quit(0)

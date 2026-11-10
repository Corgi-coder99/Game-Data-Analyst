extends SceneTree
# Screenshot helper (needs a real display, run without --headless):
#   Godot --path game-studio/godot -s res://tools/shot.gd -- --scene=commute --day=1 --t=3.0 --out=C:/path/file.png
# Scenes: commute, office (--room=data|finance|...), title, desktop, review, ending.
const Palette = preload("res://scripts/v2/palette.gd")
func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.trim_prefix("--" + name + "=")
	return fallback
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene := arg("scene", "commute")
	var day := int(arg("day", "1"))
	var t := float(arg("t", "3.0"))
	var out := arg("out", OS.get_environment("TEMP") + "/shot.png")
	var node: Node
	if scene == "commute":
		node = load("res://scenes/v2/commute.tscn").instantiate()
		node.day = day
		node.trust = int(arg("trust", "50"))
		root.add_child(node)
		var steps := int(t / 0.05)
		for i in range(steps):
			node.advance(0.05)
	elif scene == "office":
		node = load("res://scenes/v2/office.tscn").instantiate()
		root.add_child(node)
		node.set_phase(arg("phase", "sang"))
		node.seat_now()
		for i in range(int(t / 0.05)):
			node.advance(0.05)
		var room := arg("room", "data")
		if room != "data":
			node.show_room(room)
		if arg("dialog", "") != "":
			node.play_boss_appears(arg("dialog", ""))
	elif scene == "title":
		node = load("res://scenes/v2/title.tscn").instantiate()
		root.add_child(node)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out)
	print("saved ", out, " ", image.get_size())
	quit(0)

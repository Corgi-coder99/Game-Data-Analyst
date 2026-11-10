extends SceneTree
# T-029 screenshot set (needs a real display, run WITHOUT --headless):
#   Godot --path game-studio/godot -s res://tools/shots_t029.gd -- --out=<folder> [--only=commute,hover,shops,light,browser]
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
const Commute = preload("res://scripts/v2/commute_scene.gd")
const ShopPanel = preload("res://scripts/life/shop_panel.gd")
var out := ""
var only := ""
var flow: Node

func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.trim_prefix("--" + name + "=")
	return fallback

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	DirAccess.make_dir_recursive_absolute(out)
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("saved ", name)

func wants(group: String) -> bool:
	return only == "" or group in only.split(",")

func new_flow(daily: bool = true) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	node.daily_enabled = daily
	root.add_child(node)
	return node

func street(day: int, trust: int, transport: String = "walk") -> Node2D:
	var c: Node2D = Commute.new()
	c.setup_interactive(day, trust, flow.life.vitals, transport)
	root.add_child(c)
	return c

func run() -> void:
	out = arg("out", OS.get_environment("TEMP") + "/t029")
	only = arg("only", "")
	flow = new_flow()
	flow.start_with_game(Game.new(104, 10))
	await settle()
	if wants("commute"):
		for spec in [[1, 60], [5, 40], [9, 20]]:
			var c := street(spec[0], spec[1])
			for i in 30: c.advance(0.1)
			await shot("commute-day%d" % spec[0])
			c.queue_free()
		var cb := street(2, 55, "bus")
		for i in 30: cb.advance(0.1)
		cb.player_x = 300
		cb._start_to_work()
		for i in 5: cb.advance(0.1)
		await shot("commute-bus")
		cb.queue_free()
	if wants("hover"):
		var c2 := street(1, 60)
		c2.set_hover(0)
		for i in 10: c2.advance(0.1)
		await shot("hover-cafe")
		c2.set_hover(3)
		await shot("hover-bank")
		c2.queue_free()
	if wants("light"):
		var c3 := street(3, 50)
		c3.player_x = 232
		for i in 5: c3.advance(0.1)
		c3.phase = "street"
		c3._open_light()
		await shot("red-light")
		c3.queue_free()
	if wants("shops"):
		var life: RefCounted = flow.life
		for ids in [["cafe"], ["noodle"], ["mart", "pharmacy"], ["bank"], ["news"], ["books", "clothing"]]:
			var s: Control = ShopPanel.new()
			root.add_child(s)
			s.open(life, ids, {})
			s.stage.advance(0.3)
			await shot("shop-" + "-".join(ids))
			if ids.size() > 1:
				s.select_shop(ids[1])
				await shot("shop-" + ids[1])
			s.queue_free()
	if wants("browser"):
		flow.queue_free()
		flow = new_flow(false)
		flow.start_with_game(Game.new(104, 10))
		flow.skip_intro()
		flow.desktop.open_window("news")
		await shot("browser")
	quit(0)

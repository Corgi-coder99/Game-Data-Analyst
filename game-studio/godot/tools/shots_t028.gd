extends SceneTree
# T-028 screenshot set (needs a real display, run WITHOUT --headless):
#   Godot --path game-studio/godot -s res://tools/shots_t028.gd -- --out=<folder> [--only=title,office]
# Saves title, home (morning), 9 office rooms, desktop home, browser, mail, review, evening and ending.
const Flow = preload("res://scripts/v2/game_flow.gd")
const Game = preload("res://scripts/world/world_game.gd")
var flow: Node
var out := ""
var only := ""

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

func new_flow(daily: bool, evening: bool = false) -> Node:
	var node: Node = Flow.new()
	node.autostart = false
	node.fade_enabled = false
	node.evening_enabled = evening
	node.daily_enabled = daily
	root.add_child(node)
	return node

func submit(forecast: String, confidence: String) -> void:
	var window: Control = flow.desktop.report_window
	window.choose_forecast(forecast)
	window.choose_confidence(confidence)
	window.request_submit()
	window.confirm_submit()

func run() -> void:
	out = arg("out", OS.get_environment("TEMP") + "/t028")
	only = arg("only", "")
	if wants("title"):
		flow = new_flow(false)
		flow.start_title()
		await shot("title")
		flow.queue_free()
	if wants("home"):
		flow = new_flow(true)
		flow.start_with_game(Game.new(104, 10))
		await shot("home")
		flow.queue_free()
	if wants("office"):
		flow = new_flow(false)
		flow.start_with_game(Game.new(104, 10))
		await settle()
		flow.skip_commute()
		await settle()
		for room in ["data", "finance", "marketing", "executive", "reception", "sales", "meeting", "server", "break"]:
			flow.office.show_room(room)
			flow.office.advance(0.5)
			await shot("office-" + room)
		flow.queue_free()
	if wants("desktop") or wants("review") or wants("ending"):
		flow = new_flow(false)
		flow.start_with_game(Game.new(104, 10))
		flow.skip_intro()
		var desktop: Control = flow.desktop
		await shot("desktop-home")
		desktop.open_window("news")
		await shot("browser")
		desktop.select_news(desktop.entries[0].uid)
		desktop.news_window.toggle_expanded(desktop.entries[0].uid)
		await shot("browser-expanded")
		desktop.toggle_window("report")
		await shot("mail")
		desktop.open_window("company")
		await shot("bi")
		desktop.open_window("tools")
		desktop.use_tool(flow.game.tools()[0].id)
		await shot("codepad")
		desktop.open_window("report")
		submit("tang", "cao")
		flow.review_view.set_process(false)
		flow.review_view.advance(0.1)
		for step in 5:
			if step == 2:
				await shot("review")
			if step == 4:
				await shot("review-career")
			flow.continue_review()
		flow.queue_free()
		flow = new_flow(false)
		flow.start_with_game(Game.new(104, 10, {"world": {"career": {"initial_trust": 1}}}))
		flow.skip_intro()
		submit("giam", "cao")
		var guard := 0
		while flow.state != "END_SCREEN" and guard < 20:
			guard += 1
			flow.continue_review()
		await shot("ending")
		flow.queue_free()
	if wants("evening"):
		flow = new_flow(false, true)
		flow.start_with_game(Game.new(104, 10))
		flow.skip_intro()
		submit("tang", "cao")
		flow.review_view.set_process(false)
		var guard2 := 0
		while flow.state == "REVIEW" and guard2 < 20:
			guard2 += 1
			flow.continue_review()
		await shot("evening")
		flow.queue_free()
	quit(0)

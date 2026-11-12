extends SceneTree
# T-020 headless tests: English-only player-facing data, money/emotion popups, coworker reactions.
const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
const ReviewScene = preload("res://scenes/v2/review.tscn")
const Stage = preload("res://scripts/v2/reaction_stage.gd")
const DATA_FILES := ["res://data/strings_v2.json", "res://data/news.json", "res://data/questions.json", "res://data/world.json", "res://data/palette_v2.json"]
var checks := 0
var failures := 0
var strings: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func fixture() -> Dictionary:
	var config: Dictionary = Loader.load_json("res://data/world.json").duplicate(true)
	config.macro = {}
	config.noise_factor = 0
	var states: Array = []
	for day in 11:
		var values := {}
		for variable in config.variables: values[variable] = {"direction":"tang", "magnitude":"low"}
		states.append(values)
	var questions: Array = []
	for i in 7: questions.append({"id":"fixture%d" % i, "text":"Test question %d" % i, "variable":"lai_suat", "window_days":0, "answer_rule":"state"})
	return {"world":config, "questions":questions, "scenario":{"days":states, "shocks":[]}}

# Plays one day with the given forecast and returns a review scene showing step 0.
func review_for(forecast: String, confidence: String) -> Control:
	var game: RefCounted = Game.new(7, 10, fixture())
	game.begin_day()
	var report := {"question_id": game.question_today().id, "forecast": forecast, "confidence": confidence, "evidence": [], "actions": []}
	check(game.submit_report(report).ok, "report accepted (" + forecast + ")")
	var before: Dictionary = game.status()
	var ended: Dictionary = game.end_day()
	var scene: Control = ReviewScene.instantiate()
	root.add_child(scene)
	check(scene.show_review(game, int(ended.day), report, before), "review opens")
	return scene

func step_to(scene: Control, index: int) -> void:
	var guard := 0
	while scene.step < index and guard < 8:
		scene.next_step()
		guard += 1

func scan_diacritics() -> void:
	var pattern := RegEx.new()
	pattern.compile("[À-ỹ]")
	for path in DATA_FILES:
		var text := FileAccess.get_file_as_string(path)
		check(not text.is_empty(), "readable " + path)
		var found := pattern.search(text)
		check(found == null, "no Vietnamese diacritics in " + path + (" (found " + found.get_string() + ")" if found != null else ""))
	for dir in ["res://scripts/v2", "res://scripts/v2/windows", "res://scenes/v2"]:
		for file in DirAccess.get_files_at(dir):
			var source := FileAccess.get_file_as_string(dir + "/" + file)
			check(pattern.search(source) == null, "no Vietnamese diacritics in " + dir + "/" + file)

func test_strings() -> void:
	for mood in ["angry", "happy"]:
		var lines: Array = strings.coworker[mood]
		check(lines.size() >= 6, "at least 6 coworker lines for " + mood)
		var unique := {}
		for line in lines:
			unique[line] = true
			check(str(line).length() > 0 and str(line).length() <= 16, "short shout: " + str(line))
		check(unique.size() == lines.size(), "coworker lines are distinct for " + mood)
	for key in strings.boss_lines:
		check(str(strings.boss_lines[key]).length() > 0, "boss line " + key)
	check(strings.money.plus % 120 == "+$120" and strings.money.minus % 80 == "-$80", "money formats")
	for item in Loader.load_json("res://data/news.json").news:
		check(not item.headline.is_empty(), "headline present " + item.id)
	check(Loader.load_json("res://data/questions.json").questions.size() >= 7, "all questions kept (T-038 grew the list from 7 to 20)")

func test_stage_popups() -> void:
	var stage: Control = Stage.new()
	root.add_child(stage)
	var pay: Dictionary = stage.show_money("pay", 120)
	var bonus: Dictionary = stage.show_money("bonus", 40, 0.5, 1)
	var fine: Dictionary = stage.show_money("fine", 80, 1.0, 2)
	check(pay.text == "+$120" and pay.amount == 120 and pay.positive, "pay popup text and sign")
	check(bonus.text == "+$40" and bonus.amount == 40, "bonus popup text and sign")
	check(fine.text == "-$80" and fine.amount == -80 and not fine.positive, "fine popup text and sign")
	var pay_label: Label = pay.label
	var fine_label: Label = fine.label
	check(pay_label.get_theme_color("font_color") == Color("#57c27a"), "pay is green")
	check(fine_label.get_theme_color("font_color") == Color("#e05d5d"), "fine is red")
	check(pay_label.visible and not bonus.label.visible and not fine_label.visible, "delayed popups wait")
	check(stage.popup_log.size() == 3 and stage.popup_log[2].text == "-$80", "popup log keeps every popup")
	var start_y := pay_label.position.y
	stage.advance(0.6)
	check(pay_label.position.y < start_y and pay_label.position.y == roundf(pay_label.position.y), "popup rises in whole pixels")
	check(bonus.label.visible, "bonus appears after its delay")
	stage.advance(0.3)
	check(pay_label.modulate.a < 1.0, "popup fades")
	stage.advance(0.4)
	check(pay.done and not pay_label.visible, "pay popup gone after 1.2 s")
	check(stage.animating(), "later popups still animate")
	stage.skip()
	check(not stage.animating() and not bonus.label.visible and not fine_label.visible, "skip finishes every popup")
	for node in stage.find_children("*", "Control", true, false):
		check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE or node is Panel, "stage never takes the mouse: " + node.name)
	check(stage.get("mouse_filter") == Control.MOUSE_FILTER_IGNORE, "stage root ignores the mouse")
	stage.clear()
	check(stage.popups.is_empty() and stage.emote == "" and not stage.bubble.visible, "clear resets the stage")
	stage.free()

func test_stage_emotes_and_coworker() -> void:
	var stage: Control = Stage.new()
	root.add_child(stage)
	for name in ["happy", "sad", "angry", "neutral"]:
		stage.set_emote(name)
		check(stage.emote == name and stage.emote_node.visible, "emote " + name)
	stage.set_emote("")
	check(not stage.emote_node.visible, "emote hidden")
	var line: String = stage.react("angry", 2)
	check(line == strings.coworker.angry[2] and stage.bubble.visible and stage.bubble_label.text == line, "angry shout picked by index")
	check(stage.react("happy", 9) == strings.coworker.happy[9 % strings.coworker.happy.size()] and stage.thumb_node.visible, "cheer shows thumbs up")
	check(stage.react("none") == "" and not stage.bubble.visible and not stage.thumb_node.visible, "no reaction clears the bubble")
	stage.react("angry", 0)
	var seen := {}
	var base_y: float = stage.NEIGHBOR_POS.y
	for i in 30:
		stage.advance(0.03)
		seen[[stage.neighbor_node.position, stage.neighbor_desk.position.x]] = true
		check(stage.neighbor_node.position == stage.neighbor_node.position.round(), "slam keeps integer positions")
	check(seen.size() >= 3, "slam uses at least three distinct frames")
	check(stage.neighbor_node.position == stage.NEIGHBOR_POS and not stage.animating(), "slam settles")
	check(stage.bubble.visible, "shout stays readable after the slam")
	stage.free()

func test_review_outcomes() -> void:
	# Right report: cheer plus a happy emote.
	var right: Control = review_for("tang", "cao")
	check(right.reaction_category() == "right", "right category")
	check(right.stage.visible and right.stage.mood == "happy" and right.stage.emote == "happy", "right report: coworker cheers, player is happy")
	check(right.stage.shout in strings.coworker.happy, "cheer line is from the happy pool")
	check(right.stage.popups.is_empty(), "no money popup before the career step")
	step_to(right, 1)
	check(not right.stage.visible, "stage hidden on the answer step")
	step_to(right, 5)
	var status: Dictionary = right.status
	var expected_pay := roundi(float(status.personal_pay) - float(right.before.personal_pay) - float(right.data.career.bonus))
	check(expected_pay > 0, "the day paid a salary")
	check(right.stage.popup_log.size() >= 1 and right.stage.popup_log[0].type == "pay" and right.stage.popup_log[0].text == "+$%d" % expected_pay, "pay popup matches the review: +$%d" % expected_pay)
	check(right.stage.popup_log[0].positive, "pay popup is positive")
	var seen_text := false
	for node in right.body.find_children("*", "Label", true, false):
		if node.text == strings.review.pay % expected_pay: seen_text = true
	check(seen_text, "review shows the same pay amount as the popup")
	right.queue_free()
	# Wrong report with high confidence: slam, shout and an angry face.
	var wrong: Control = review_for("giam", "cao")
	check(wrong.reaction_category() == "wrong_high", "wrong category")
	check(wrong.stage.mood == "angry" and wrong.stage.emote == "angry", "wrong report: coworker slams, player is angry")
	check(wrong.stage.shout in strings.coworker.angry and wrong.stage.bubble.visible, "slam shows a shout")
	wrong.stage.advance(0.1)
	check(wrong.stage.animating(), "slam animation runs")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	wrong._unhandled_input(escape)
	check(not wrong.stage.animating() and wrong.skipped, "Esc skips the stage animation")
	var before_step: int = wrong.step
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	wrong._unhandled_input(enter)
	check(wrong.step == before_step + 1, "input still advances the review after Esc")
	wrong.queue_free()
	var low: Control = review_for("giam", "thap")
	check(low.stage.emote == "sad" and low.stage.mood == "angry", "wrong with low confidence: sad face, coworker still slams")
	low.queue_free()

func test_mappings_and_money() -> void:
	var scene: Control = ReviewScene.instantiate()
	root.add_child(scene)
	var moods := {"right":"happy", "promotion":"happy", "wrong_low":"angry", "wrong_mid":"angry", "wrong_high":"angry", "demotion":"angry", "fired":"angry", "bankrupt":"angry", "partial":"", "warning":"", "steady":""}
	for category in moods:
		check(scene.coworker_mood_for(category) == moods[category], "coworker mood for " + category)
	var emotes := {"right":"happy", "promotion":"happy", "partial":"neutral", "steady":"neutral", "wrong_low":"sad", "demotion":"sad", "warning":"sad", "wrong_high":"angry", "fired":"angry"}
	for category in emotes:
		check(scene.emote_for(category) == emotes[category], "emote for " + category)
	scene.status = {"personal_pay": 520.0}
	scene.before = {"personal_pay": 300.0}
	scene.data = {"career": {"bonus": 80.0}}
	var events: Array = scene.money_events()
	check(events.size() == 2 and events[0].type == "pay" and events[0].amount == 140 and events[1].type == "bonus" and events[1].amount == 80, "pay and bonus split: " + str(events))
	scene.status = {"personal_pay": 100.0}
	scene.data = {"career": {"bonus": 0.0}}
	events = scene.money_events()
	check(events.size() == 1 and events[0].type == "fine" and events[0].amount == -200, "a drop in personal pay is a fine: " + str(events))
	scene.status = {"personal_pay": 300.0}
	check(scene.money_events().is_empty(), "no money event when nothing changed")
	scene.queue_free()

func run() -> void:
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	scan_diacritics()
	test_strings()
	test_stage_popups()
	test_stage_emotes_and_coworker()
	test_review_outcomes()
	test_mappings_and_money()
	print("test_v2_popups: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)

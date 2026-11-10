extends "res://scripts/v2/windows/window_base.gd"
# T-024: the evening screen after each day's review. It shows the wallet, a simple city backdrop
# and a menu of ways to spend money. It reads only the public status and the life module.
const ReactionStage = preload("res://scripts/v2/reaction_stage.gd")
const TABS := ["food", "gold", "savings", "property", "treats"]
const MOOD_FLOAT_TIME := 1.0
const BODY_AT := Vector2(8, 30)
signal finished(skipped: bool)
signal acted(kind: String, result: Dictionary)
var strings: Dictionary
var life: RefCounted
var public: Dictionary = {}
var tab := "food"
var tab_buttons: Dictionary = {}
var action_buttons: Dictionary = {}
var stage: Control
var wallet_label: Label
var net_label: Label
var mood_bar: ProgressBar
var mood_label: Label
var holdings_a: Label
var holdings_b: Label
var message_label: Label
var title_label: Label
var menu_body: Control
var go_button: Button
var skip_button: Button
var mood_float: Label
var mood_float_time := -1.0
var opening: Dictionary = {}
var message := ""
var left := false
var built := false

func _ready() -> void:
	_build()

func _text(parent: Node, text: String, area: Rect2, color_index: int = 22, font_size: int = 8) -> Label:
	var node := label(parent, text, area, color_index)
	if font_size != 8: node.add_theme_font_size_override("font_size", font_size)
	return node

func _rect(parent: Node, color_index: int, area: Rect2) -> ColorRect:
	var node := ColorRect.new()
	node.color = Palette.color(color_index)
	node.position = area.position
	node.size = area.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _build() -> void:
	if built: return
	built = true
	size = Vector2(640, 360)
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = WindowTheme.create()
	strings = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings_v2.json"))
	_build_backdrop()
	title_label = _text(self, "", Rect2(8, 4, 400, 17), 22, 12)
	var stats := Panel.new()
	stats.position = Vector2(8, 24)
	stats.size = Vector2(208, 84)
	stats.add_theme_stylebox_override("panel", WindowTheme.box(2))
	add_child(stats)
	wallet_label = _text(stats, "", Rect2(6, 3, 196, 17), 24, 12)
	net_label = _text(stats, "", Rect2(6, 21, 196, 17), 22, 12)
	_text(stats, strings.life.mood, Rect2(6, 41, 34, 12), 7)
	mood_bar = ProgressBar.new()
	mood_bar.theme = theme
	mood_bar.show_percentage = false
	mood_bar.custom_minimum_size = Vector2(110, 7)
	mood_bar.position = Vector2(40, 44)
	mood_bar.size = Vector2(110, 7)
	mood_bar.max_value = 100
	stats.add_child(mood_bar)
	mood_bar.size = Vector2(110, 7)
	mood_label = _text(stats, "", Rect2(154, 41, 48, 12), 22)
	holdings_a = _text(stats, "", Rect2(6, 55, 196, 12), 7)
	holdings_b = _text(stats, "", Rect2(6, 68, 196, 12), 7)
	stage = ReactionStage.new()
	stage.name = "Stage"
	stage.position = Vector2(8, 110)
	add_child(stage)
	stage.build()
	for node in stage.get_children():
		if node is ColorRect: node.hide()
	stage.neighbor_node.hide()
	mood_float = _text(self, "", Rect2(84, 170, 60, 12), 24)
	mood_float.set_meta("overlay", true)
	mood_float.hide()
	var chat := Panel.new()
	chat.position = Vector2(8, 234)
	chat.size = Vector2(208, 64)
	chat.add_theme_stylebox_override("panel", WindowTheme.box(2))
	add_child(chat)
	message_label = _text(chat, "", Rect2(6, 3, 196, 58), 22)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.max_lines_visible = 4
	var menu := Panel.new()
	menu.position = Vector2(224, 24)
	menu.size = Vector2(408, 240)
	menu.add_theme_stylebox_override("panel", WindowTheme.box(2))
	add_child(menu)
	var x := 6
	for id in TABS:
		var tab_button := button(menu, strings.life.tabs[id], Rect2(x, 5, 76, 18))
		tab_button.focus_mode = Control.FOCUS_NONE
		tab_button.pressed.connect(select_tab.bind(id))
		tab_buttons[id] = tab_button
		x += 80
	menu_body = Control.new()
	menu_body.position = Vector2(6, 28)
	menu_body.size = Vector2(396, 206)
	menu_body.clip_contents = true
	menu.add_child(menu_body)
	_rect(self, 2, Rect2(224, 268, 408, 28))
	var hint := _text(self, strings.life.hint, Rect2(224, 270, 408, 24), 7)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.max_lines_visible = 2
	skip_button = button(self, strings.life.skip, Rect2(224, 322, 128, 24))
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.pressed.connect(skip)
	go_button = button(self, strings.life["go_home"], Rect2(488, 322, 144, 24))
	go_button.focus_mode = Control.FOCUS_NONE
	go_button.pressed.connect(go_home)

# A stylized city evening: sky, moon, stars, a skyline with lit windows, and the street.
func _build_backdrop() -> void:
	_rect(self, 17, Rect2(0, 0, 640, 360))
	_rect(self, 18, Rect2(0, 150, 640, 110))
	for star in [[40, 10], [90, 34], [150, 8], [330, 6], [420, 14], [470, 5], [560, 12], [610, 30], [250, 22], [380, 40]]:
		_rect(self, 21, Rect2(star[0], star[1], 1, 1))
	_rect(self, 22, Rect2(594, 8, 14, 14))
	_rect(self, 18, Rect2(600, 8, 8, 8))
	var skyline := [[0, 190, 36], [30, 170, 40], [72, 200, 30], [106, 160, 44], [154, 185, 38], [196, 175, 32], [232, 150, 46], [282, 190, 36], [322, 165, 40], [366, 195, 32], [402, 155, 46], [452, 180, 38], [494, 170, 40], [538, 200, 34], [576, 160, 46]]
	for index in skyline.size():
		var b: Array = skyline[index]
		_rect(self, 3 if index % 2 == 0 else 4, Rect2(b[0], b[1], b[2], 300 - b[1]))
		var row := 0
		for y in range(b[1] + 6, 292, 14):
			for wx in range(b[0] + 5, b[0] + b[2] - 6, 10):
				if (index * 7 + row * 3 + wx / 10) % 3 != 0:
					_rect(self, 28, Rect2(wx, y, 4, 6))
			row += 1
	_rect(self, 2, Rect2(0, 292, 640, 68))
	_rect(self, 3, Rect2(0, 292, 640, 3))
	for lamp in [60, 250, 440, 600]:
		_rect(self, 5, Rect2(lamp, 262, 2, 30))
		_rect(self, 28, Rect2(lamp - 2, 258, 6, 4))
	for dash in range(10, 640, 64):
		_rect(self, 5, Rect2(dash, 352, 24, 2))

# ---- opening ------------------------------------------------------------------

# Starts the evening: pay arrives, prices move, one seeded event may happen.
func open(life_game: RefCounted, status: Dictionary) -> Dictionary:
	_build()
	life = life_game
	public = status.duplicate(true)
	left = false
	opening = life.begin_evening(public)
	stage.clear()
	stage.neighbor_node.hide()
	var delay := 0.0
	var gains := 0
	var losses := 0
	for event in opening.events:
		var column := 0 if event.type == "pay" else (1 if event.type == "bonus" else 2)
		stage.show_money(event.type, absi(int(event.amount)), delay, column)
		delay += 0.4
		if event.type == "fine": losses += absi(int(event.amount))
		else: gains += int(event.amount)
	var key := str(opening.get("event", ""))
	message = strings.life.welcome + "\n" + strings.life.events.get(key, strings.life.events[""])
	if losses > 0: stage.set_emote("sad")
	elif gains > 0 or life.mood_band() == "high": stage.set_emote("happy")
	else: stage.set_emote("neutral")
	title_label.text = strings.life.title % [int(public.get("day", 1)), int(public.get("horizon", 10))]
	select_tab("food")
	return opening

func select_tab(id: String) -> void:
	tab = id
	for key in tab_buttons:
		tab_buttons[key].disabled = key == id
	render()

# Rebuilds the stats, the message and the rows of the selected tab.
func render() -> void:
	if life == null: return
	wallet_label.text = strings.life.wallet % life.wallet
	net_label.text = strings.life.net_worth % life.net_worth()
	mood_bar.value = life.mood
	mood_label.text = str(life.mood)
	holdings_a.text = strings.life.holdings_a % [life.gold_units, life.gold_price, life.savings]
	holdings_b.text = strings.life.holdings_b % [life.land_value, life.house_value]
	message_label.text = message
	empty(menu_body)
	action_buttons.clear()
	match tab:
		"food": _tab_food()
		"gold": _tab_gold()
		"savings": _tab_savings()
		"property": _tab_property()
		"treats": _tab_treats()

func _row_button(id: String, text: String, area: Rect2, enabled: bool, action: Callable) -> Button:
	var node := button(menu_body, text, area)
	node.focus_mode = Control.FOCUS_NONE
	node.disabled = not enabled
	node.pressed.connect(action)
	action_buttons[id] = node
	return node

func _note(text: String, y: int, lines: int = 3) -> Label:
	var node := _text(menu_body, text, Rect2(0, y, 392, 12 * lines), 7)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.max_lines_visible = lines
	node.tooltip_text = text
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	return node

func _tab_food() -> void:
	var y := 0
	for entry in life.config.food:
		var id: String = entry.id
		var price: int = life.food_price(id)
		_text(menu_body, strings.life.food[id], Rect2(0, y + 3, 170, 12), 22, 8)
		_text(menu_body, strings.life.per_mood % int(entry.mood), Rect2(178, y + 3, 70, 12), 24)
		_text(menu_body, "$%d" % price, Rect2(250, y + 3, 40, 12), 28 if price > int(entry.price) else 22)
		_row_button("food_" + id, strings.life.buy, Rect2(312, y, 80, 20), life.wallet >= price, buy_food.bind(id))
		y += 26
	_note(strings.life.food_note, y + 6, 2)

func _tab_treats() -> void:
	var y := 0
	for entry in life.config.splurge:
		var id: String = entry.id
		_text(menu_body, strings.life.treats[id], Rect2(0, y + 3, 170, 12), 22)
		_text(menu_body, strings.life.per_mood % int(entry.mood), Rect2(178, y + 3, 70, 12), 24)
		_text(menu_body, "$%d" % int(entry.price), Rect2(250, y + 3, 40, 12), 22)
		_row_button("treat_" + id, strings.life.buy, Rect2(312, y, 80, 20), life.wallet >= int(entry.price), splurge.bind(id))
		y += 26
	_note(strings.life.treats_note, y + 6, 2)

func _tab_gold() -> void:
	var arrow := "arrow_up" if life.gold_price > life.gold_prev else ("arrow_down" if life.gold_price < life.gold_prev else "arrow_flat")
	icon(menu_body, arrow, Vector2(0, 3))
	_text(menu_body, strings.life.gold_line % [life.gold_price, life.gold_prev], Rect2(12, 0, 380, 14), 28, 12)
	_text(menu_body, strings.life.gold_hold % [life.gold_units, life.gold_value()], Rect2(0, 20, 392, 12), 22)
	var price: int = life.gold_price
	_row_button("gold_buy1", strings.life.gold_buy1, Rect2(0, 42, 92, 20), life.wallet >= price, buy_gold.bind(1))
	_row_button("gold_buy5", strings.life.gold_buy5, Rect2(100, 42, 92, 20), life.wallet >= price * 5, buy_gold.bind(5))
	_row_button("gold_sell1", strings.life.gold_sell1, Rect2(200, 42, 92, 20), life.gold_units >= 1, sell_gold.bind(1))
	_row_button("gold_sell_all", strings.life.gold_sell_all, Rect2(300, 42, 92, 20), life.gold_units >= 1, sell_gold.bind(life.gold_units))
	_note(strings.life.gold_note % roundi(float(life.config.gold.sell_fee) * 100.0), 74, 3)

func _tab_savings() -> void:
	_text(menu_body, strings.life.savings_line % life.savings, Rect2(0, 0, 392, 14), 24, 12)
	_row_button("deposit50", strings.life.deposit50, Rect2(0, 24, 92, 20), life.wallet >= 50, deposit.bind(50))
	_row_button("deposit_all", strings.life.deposit_all, Rect2(100, 24, 92, 20), life.wallet >= 1, deposit.bind(life.wallet))
	_row_button("withdraw50", strings.life.withdraw50, Rect2(200, 24, 92, 20), life.savings >= 50, withdraw.bind(50))
	_row_button("withdraw_all", strings.life.withdraw_all, Rect2(300, 24, 92, 20), life.savings >= 1, withdraw.bind(life.savings))
	_note(strings.life.savings_note % (float(life.config.savings.daily_rate) * 100.0), 56, 2)

func _tab_property() -> void:
	_property_row("land", 0, strings.life.land, life.land_owned, life.land_bought, life.land_value, int(life.config.land.price), float(life.config.land.sell_fee))
	_property_row("house", 70, strings.life.house, life.house_owned, life.house_bought, life.house_value, int(life.config.house.price), float(life.config.house.sell_fee))
	_note(strings.life.land_note % roundi(float(life.config.land.sell_fee) * 100.0), 140, 2)
	_note(strings.life.house_note % [int(life.config.house.rent), roundi(float(life.config.house.sell_fee) * 100.0)], 164, 2)

func _property_row(id: String, y: int, name: String, owned: bool, bought: bool, value: int, price: int, fee_rate: float) -> void:
	_text(menu_body, name, Rect2(0, y, 250, 14), 22, 12)
	var status_text: String = strings.life.owned_value % value if owned else (strings.life.sold_once if bought else strings.life.not_owned)
	_text(menu_body, status_text, Rect2(0, y + 18, 266, 12), 24 if owned else 7)
	if owned:
		var fee := ceili(float(value) * fee_rate)
		_row_button(id + "_sell", strings.life.sell_with_fee % fee, Rect2(272, y + 2, 120, 22), true, sell_property.bind(id))
	else:
		_row_button(id + "_buy", strings.life.buy_price % price, Rect2(272, y + 2, 120, 22), not bought and life.wallet >= price, buy_property.bind(id))

# ---- actions (also callable from tests) -------------------------------------------

func _after(kind: String, result: Dictionary, success_text: String) -> Dictionary:
	if result.ok:
		message = success_text
	else:
		message = strings.life.errors.get(str(result.get("error", "")), strings.life.errors.unknown)
	acted.emit(kind, result)
	render()
	return result

func _gain_mood(amount: int) -> void:
	if amount <= 0: return
	mood_float.text = strings.life.mood_gain % amount
	mood_float.position = Vector2(84, 170)
	mood_float.modulate.a = 1.0
	mood_float.show()
	mood_float_time = 0.0
	stage.set_emote("happy")

func buy_food(id: String) -> Dictionary:
	var result: Dictionary = life.buy_food(id)
	if result.ok: _gain_mood(int(result.mood))
	return _after("food", result, strings.life.results.food)

func splurge(id: String) -> Dictionary:
	var result: Dictionary = life.splurge(id)
	if result.ok: _gain_mood(int(result.mood))
	return _after("treat", result, strings.life.results.treat)

func buy_gold(units: int) -> Dictionary:
	var result: Dictionary = life.buy_gold(units)
	return _after("gold_buy", result, strings.life.results.gold_buy % int(result.get("cost", 0)))

func sell_gold(units: int) -> Dictionary:
	var result: Dictionary = life.sell_gold(units)
	if result.ok and int(result.fee) > 0: stage.show_money("fine", int(result.fee), 0.0, 2)
	return _after("gold_sell", result, strings.life.results.gold_sell % [int(result.get("gross", 0)) - int(result.get("fee", 0)), int(result.get("fee", 0))])

func deposit(amount: int) -> Dictionary:
	var result: Dictionary = life.deposit(amount)
	return _after("deposit", result, strings.life.results.deposit % amount)

func withdraw(amount: int) -> Dictionary:
	var result: Dictionary = life.withdraw(amount)
	return _after("withdraw", result, strings.life.results.withdraw % amount)

func buy_property(id: String) -> Dictionary:
	var result: Dictionary = life.buy_land() if id == "land" else life.buy_house()
	return _after(id + "_buy", result, strings.life.results[id + "_buy"] % int(result.get("cost", 0)))

func sell_property(id: String) -> Dictionary:
	var result: Dictionary = life.sell_land() if id == "land" else life.sell_house()
	if result.ok:
		stage.show_money("fine", int(result.fee), 0.0, 2)
		stage.set_emote("sad")
	return _after(id + "_sell", result, strings.life.results.sell % [int(result.get("gross", 0)) - int(result.get("fee", 0)), int(result.get("fee", 0))])

# ---- leaving -------------------------------------------------------------------------

func go_home() -> void:
	if left: return
	left = true
	finished.emit(false)

func skip() -> void:
	if left: return
	left = true
	finished.emit(true)

func advance(delta: float) -> void:
	if mood_float_time >= 0.0:
		mood_float_time += delta
		var progress := clampf(mood_float_time / MOOD_FLOAT_TIME, 0.0, 1.0)
		mood_float.position.y = 170 - floorf(progress * 10.0)
		mood_float.modulate.a = maxf(1.0 - floorf(progress * 4.0) * 0.25, 0.25)
		if progress >= 1.0:
			mood_float.hide()
			mood_float_time = -1.0

func _process(delta: float) -> void:
	advance(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		stage.skip()
		get_viewport().set_input_as_handled()
		skip()

extends "res://scripts/life/daily_base.gd"
# T-026: a shop interior: shopkeeper sprite, shelves and a menu. Purchases go through the vitals
# module, so the wallet is charged exactly and the bars move at once. A storefront can hold more
# than one counter (the mart has a pharmacy corner, the bookshop a clothing rack), shown as tabs.
const KEEPERS := {"cafe": "linh", "noodle": "bao", "mart": "dat", "pharmacy": "vy", "news": "an", "books": "ngoc", "clothing": "sam", "bank": "rin"}
const WALLS := {"cafe": [43, 44], "noodle": [23, 24], "mart": [56, 33], "pharmacy": [58, 53], "news": [59, 54], "books": [38, 30], "clothing": [59, 54], "bank": [13, 64]}
const ReactionStage = preload("res://scripts/v2/reaction_stage.gd")
const ShopArt = preload("res://scripts/v2/shop_art.gd")
signal closed
signal bought(shop: String, item: String, result: Dictionary)
signal popup(kind: String, amount: int)
var shop_ids: Array = []
var current := ""
var vitals: RefCounted
var title_label: Label
var keeper_label: Label
var message_label: Label
var menu: Control
var tab_row: Control
var rows: Dictionary = {}
var backdrop: Control
var keeper_node: TextureRect
var stage: Control
var message := ""
var done := false
var gains: Array = []

func _ready() -> void:
	_build()

func _build() -> void:
	if built: return
	built = true
	_prepare()
	var floor_fill := _rect(self, 3, Rect2(0, 0, 640, 360))
	floor_fill.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop = Control.new()
	backdrop.size = Vector2(640, 360)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_meta("overlay", true)
	add_child(backdrop)
	stage = ReactionStage.new()
	stage.name = "Stage"
	stage.set_meta("overlay", true)
	stage.position = Vector2(8, 100)
	add_child(stage)
	stage.build()
	for node in stage.get_children():
		if node is ColorRect: node.hide()
	stage.neighbor_node.hide()
	title_label = _text(self, "", Rect2(8, 4, 330, 17), 22, 12)
	var panel := _panel(self, Rect2(232, 28, 400, 250))
	tab_row = Control.new()
	tab_row.position = Vector2(8, 6)
	tab_row.size = Vector2(384, 20)
	panel.add_child(tab_row)
	menu = Control.new()
	menu.position = Vector2(8, 30)
	menu.size = Vector2(384, 212)
	panel.add_child(menu)
	var chat := _panel(self, Rect2(232, 282, 400, 36))
	message_label = _wrapped(chat, "", Rect2(6, 3, 388, 30), 22, 2)
	keeper_label = _wrapped(self, "", Rect2(8, 230, 212, 24), 22, 2)
	var leave := button(self, daily.leave, Rect2(488, 326, 144, 24))
	leave.focus_mode = Control.FOCUS_NONE
	leave.pressed.connect(leave_shop)

func _draw_interior(shop: String) -> void:
	for node in backdrop.get_children():
		backdrop.remove_child(node)
		node.queue_free()
	var art: Dictionary = ShopArt.interior(shop)
	_picture(backdrop, art.back, Vector2(0, 0), 1)
	keeper_node = _picture(backdrop, ShopArt.keeper(shop), Vector2(136, 108), 3)
	_picture(backdrop, art.front, Vector2(0, 0), 1)

func _picture(parent: Node, texture: Texture2D, at: Vector2, scale_factor: int) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.position = at
	node.size = texture.get_size() * scale_factor
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set_meta("overlay", true)
	parent.add_child(node)
	return node

# A 16x16 pixel icon shown at 2x inside a small pastel frame; returns the frame's right edge.
func _icon_tile(parent: Control, id: String, at: Vector2) -> void:
	var tile := Panel.new()
	tile.position = at
	tile.size = Vector2(36, 36)
	tile.add_theme_stylebox_override("panel", WindowTheme2.pastel(101, 82))
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tile)
	var picture := TextureRect.new()
	picture.texture = ShopArt.icon(id)
	picture.position = Vector2(2, 2)
	picture.size = Vector2(32, 32)
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(picture)

func open(life_game: RefCounted, ids: Array, status: Dictionary = {}) -> void:
	_build()
	life = life_game
	vitals = life.vitals
	shop_ids = ids
	done = false
	message = ""
	gains.clear()
	stage.clear()
	stage.neighbor_node.hide()
	stage.set_emote("neutral")
	select_shop(str(ids[0]))

func select_shop(shop: String) -> void:
	current = shop
	_draw_interior(shop)
	title_label.text = daily.shops[shop]
	keeper_label.text = daily.shopkeeper[shop]
	empty(tab_row)
	if shop_ids.size() > 1:
		var x := 0
		for id in shop_ids:
			var tab := button(tab_row, daily.shops[id], Rect2(x, 0, 120, 18))
			tab.focus_mode = Control.FOCUS_NONE
			tab.disabled = id == shop
			tab.pressed.connect(select_shop.bind(id))
			x += 124
	render()

func render() -> void:
	if life == null: return
	empty(menu)
	rows.clear()
	if current == "bank": _render_bank()
	else: _render_items()
	message_label.text = message

func _render_items() -> void:
	var y := 0
	for entry in vitals.shop_items(current):
		var id: String = entry.id
		var price := int(entry.price)
		_icon_tile(menu, id, Vector2(0, y + 2))
		_text(menu, daily.items[id], Rect2(44, y, 190, 12), 22, 8)
		_text(menu, change_text(0, entry) + ("  Skill +%d" % int(entry.skill) if entry.has("skill") else ""), Rect2(44, y + 13, 246, 12), 24)
		var tip_label := _text(menu, daily.item_tip[id], Rect2(44, y + 26, 246, 12), 7)
		tip_label.tooltip_text = daily.item_tip[id]
		_text(menu, "$%d" % price, Rect2(296, y + 4, 34, 12), 52 if life.wallet >= price else 51)
		var node := button(menu, daily.buy, Rect2(334, y, 48, 22))
		node.focus_mode = Control.FOCUS_NONE
		var enough: bool = life.wallet >= price
		node.disabled = not enough
		node.tooltip_text = daily.tip_funds if not enough else daily.item_tip[id]
		node.pressed.connect(buy.bind(id))
		rows[id] = node
		y += 48

func _render_bank() -> void:
	_icon_tile(menu, "pouch", Vector2(0, 0))
	_text(menu, daily.bank_line % life.savings, Rect2(44, 10, 330, 14), 24, 12)
	var y := 50
	for amount in [20, 50]:
		var dep := button(menu, daily.bank_deposit % amount, Rect2(0, y, 180, 22))
		dep.focus_mode = Control.FOCUS_NONE
		dep.disabled = life.wallet < amount
		dep.tooltip_text = daily.tip_funds if life.wallet < amount else ""
		dep.pressed.connect(deposit.bind(amount))
		rows["deposit%d" % amount] = dep
		var out := button(menu, daily.bank_withdraw % amount, Rect2(196, y, 180, 22))
		out.focus_mode = Control.FOCUS_NONE
		out.disabled = life.savings < amount
		out.pressed.connect(withdraw.bind(amount))
		rows["withdraw%d" % amount] = out
		y += 30

# ---- actions ---------------------------------------------------------------------------------

func buy(id: String) -> Dictionary:
	var result: Dictionary = vitals.buy(current, id)
	if result.ok:
		message = daily.bought % [daily.items[id], int(result.cost)] + "  " + change_text(0, result.change)
		if int(result.cost) > 0: stage.show_money("fine", int(result.cost), 0.0, 2)
		stage.set_emote("happy")
		popup.emit("fine", int(result.cost))
		bought.emit(current, id, result)
	else:
		message = daily.no_money
		stage.set_emote("sad")
	render()
	return result

func deposit(amount: int) -> Dictionary:
	var result: Dictionary = life.deposit(amount)
	if result.ok: message = daily.bank_done % amount
	render()
	return result

func withdraw(amount: int) -> Dictionary:
	var result: Dictionary = life.withdraw(amount)
	if result.ok: message = daily.bank_out % amount
	render()
	return result

func leave_shop() -> void:
	if done: return
	done = true
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or done: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		leave_shop()

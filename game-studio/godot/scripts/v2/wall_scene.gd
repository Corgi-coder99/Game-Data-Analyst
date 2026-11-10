extends "res://scripts/life/daily_base.gd"
# T-030: Wall of Fame. Framed plaques for the Employee of the Month winners, the five all-time awards
# and the achievements list. Offline: the only candidate is the local profile. Locked plaques stay empty.
const Awards = preload("res://scripts/meta/awards.gd")
const Clock = preload("res://scripts/meta/clock.gd")
signal back_requested
const WINNERS_PER_PAGE := 4
var meta: RefCounted
var back_button: Button
var prev_button: Button
var next_button: Button
var page := 0
var dynamic: Array = []
var plaque_nodes: Dictionary = {}

func _ready() -> void:
	_prepare_once()

func _prepare_once() -> void:
	if built: return
	built = true
	_prepare()
	_rect(self, 66, Rect2(0, 0, 640, 360))
	_rect(self, 65, Rect2(0, 322, 640, 38))
	_rect(self, 103, Rect2(0, 321, 640, 1))
	back_button = button(self, "Back", Rect2(530, 331, 100, 22))
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(func(): back_requested.emit())
	prev_button = button(self, "<", Rect2(554, 26, 34, 14))
	next_button = button(self, ">", Rect2(594, 26, 34, 14))
	for b in [prev_button, next_button]: b.focus_mode = Control.FOCUS_NONE
	prev_button.pressed.connect(func(): turn_page(1))
	next_button.pressed.connect(func(): turn_page(-1))

func open(meta_ref: RefCounted) -> void:
	_prepare_once()
	meta = meta_ref
	page = 0
	render()

func turn_page(step: int) -> void:
	var count: int = meta.profile.data.winners.size()
	var pages: int = maxi(1, ceili(float(count) / WINNERS_PER_PAGE))
	page = clampi(page + step, 0, pages - 1)
	render()

# A framed plaque: wood frame with a light edge, paper inside. Decorative rectangles are overlays.
func _frame(area: Rect2, earned: bool) -> void:
	_add(_rect(self, 65, Rect2(area.position.x + 2, area.position.y + 2, area.size.x, area.size.y)))
	_add(_rect(self, 69, area))
	_add(_rect(self, 71, Rect2(area.position.x, area.position.y, area.size.x, 1)))
	_add(_rect(self, 71, Rect2(area.position.x, area.position.y, 1, area.size.y)))
	_add(_rect(self, 68, Rect2(area.position.x, area.end.y - 1, area.size.x, 1)))
	_add(_rect(self, 68, Rect2(area.end.x - 1, area.position.y, 1, area.size.y)))
	_add(_rect(self, 72 if earned else 101, Rect2(area.position.x + 3, area.position.y + 3, area.size.x - 6, area.size.y - 6)))

func _add(node: Node) -> Node:
	dynamic.append(node)
	return node

func _label(text: String, area: Rect2, color_index: int, lines: int = 1) -> Label:
	var node: Label = _wrapped(self, text, area, color_index, lines) if lines > 1 else _text(self, text, area, color_index)
	dynamic.append(node)
	return node

func render() -> void:
	if meta == null: return
	for node in dynamic:
		if is_instance_valid(node): node.queue_free()
	dynamic.clear()
	plaque_nodes.clear()
	var data: Dictionary = meta.profile.data
	var cfg: Dictionary = meta.cfg
	_label("WALL OF FAME", Rect2(10, 4, 200, 16), 89).add_theme_font_size_override("font_size", 12)
	_label("%s, %s" % [data.display_name, data.title if str(data.title) != "" else "New hire"], Rect2(230, 8, 390, 12), 7)
	_label("EMPLOYEE OF THE MONTH", Rect2(10, 26, 300, 12), 91)
	# Newest winner first; four plaques per page.
	var winners: Array = data.winners.duplicate()
	winners.reverse()
	var shown: Array = winners.slice(page * WINNERS_PER_PAGE, (page + 1) * WINNERS_PER_PAGE)
	prev_button.visible = winners.size() > WINNERS_PER_PAGE
	next_button.visible = prev_button.visible
	prev_button.disabled = (page + 1) * WINNERS_PER_PAGE >= winners.size()
	next_button.disabled = page == 0
	for i in WINNERS_PER_PAGE:
		var area := Rect2(10 + i * 156, 42, 150, 72)
		if i < shown.size(): _winner_plaque(area, shown[i], i)
		else: _empty_plaque(area, i, winners.is_empty())
	_label("ALL-TIME AWARDS", Rect2(10, 120, 300, 12), 91)
	var awards: Array = Awards.hall(data, cfg)
	for i in awards.size():
		_award_plaque(Rect2(10 + i * 125, 134, 120, 62), awards[i])
	var earned := 0
	for entry in cfg.achievements:
		if data.achievements.has(entry.id): earned += 1
	_label("ACHIEVEMENTS  %d/%d" % [earned, cfg.achievements.size()], Rect2(10, 202, 300, 12), 91)
	for i in cfg.achievements.size():
		var entry: Dictionary = cfg.achievements[i]
		var owned: bool = data.achievements.has(entry.id)
		var x: int = 10 + (i % 2) * 316
		var y: int = 216 + (i / 2) * 26
		var mark := icon(self, "check" if owned else "lock", Vector2(x, y + 2))
		mark.set_meta("overlay", true)
		dynamic.append(mark)
		var name_label := _label(str(entry.name), Rect2(x + 12, y, 296, 12), 89 if owned else 100)
		var desc: String = str(entry.desc) + ("  (" + str(data.achievements[entry.id]) + ")" if owned else "")
		_label(desc, Rect2(x + 12, y + 12, 296, 12), 7 if owned else 99)
		plaque_nodes["ach_" + str(entry.id)] = name_label
	var stats: Dictionary = data.stats
	_label("Reputation %d   Streak %d (best %d)   Days worked %d   Leave freezes %d" % [int(data.reputation), int(data.streak), int(data.best_streak), int(stats.days_total), int(data.freezes)], Rect2(10, 335, 510, 12), 7)

func _avatar(id: String, at: Vector2, locked: bool) -> void:
	var sprite := _sprite(self, id if not locked else "player", 0, at, 2)
	if locked: sprite.modulate = Color(0.25, 0.2, 0.3, 0.55)
	dynamic.append(sprite)

func _winner_plaque(area: Rect2, winner: Dictionary, index: int) -> void:
	_frame(area, true)
	_avatar(str(winner.avatar), Vector2(area.position.x + 8, area.position.y + 14), false)
	var x := area.position.x + 46
	_label(str(winner.name), Rect2(x, area.position.y + 7, 98, 12), 65)
	_label(Clock.month_name(str(winner.month)), Rect2(x, area.position.y + 19, 98, 12), 88)
	_label("%d pts, %d days" % [int(winner.score), int(winner.days)], Rect2(x, area.position.y + 31, 98, 12), 66)
	_label(str(winner.title), Rect2(x, area.position.y + 43, 98, 22), 99, 2)
	plaque_nodes["winner_%d" % index] = true

func _empty_plaque(area: Rect2, index: int, first_ever: bool) -> void:
	_frame(area, false)
	_avatar("player", Vector2(area.position.x + 8, area.position.y + 14), true)
	var x := area.position.x + 46
	_label("Empty plaque", Rect2(x, area.position.y + 7, 98, 12), 99)
	var hint := "Work a full month to claim it." if first_ever and index == 0 else "Waiting for a winner."
	_label(hint, Rect2(x, area.position.y + 19, 98, 34), 100, 3)
	plaque_nodes["empty_%d" % index] = true

func _award_plaque(area: Rect2, award: Dictionary) -> void:
	_frame(area, bool(award.earned))
	var mark := icon(self, "shield" if bool(award.earned) else "lock", Vector2(area.end.x - 14, area.position.y + 6))
	mark.set_meta("overlay", true)
	dynamic.append(mark)
	_label(str(award.name), Rect2(area.position.x + 6, area.position.y + 6, 98, 12), 65 if bool(award.earned) else 99)
	var text: String = str(award.value) if bool(award.earned) else str(award.empty)
	_label(text, Rect2(area.position.x + 6, area.position.y + 20, 108, 36), 88 if bool(award.earned) else 100, 3)
	plaque_nodes["award_" + str(award.id)] = award

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		back_requested.emit()
		get_viewport().set_input_as_handled()

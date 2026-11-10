extends Control
# T-026: compact status strip: Stamina (bolt), Mood (smile), Health (heart), Stress (spiral) and the
# wallet. Icons are drawn in code from palette v3 colors. A second line can show the Focus reason.
const Palette = preload("res://scripts/v2/palette.gd")
const ICONS := {
	"stamina": ["...xx..", "..xx...", ".xxxxx.", "...xx..", "..xx...", ".x.....", "......."],
	"mood": [".xxxxx.", "x.....x", "x.x.x.x", "x.....x", "x.x.x.x", "x..x..x", ".xxxxx."],
	"health": [".xx.xx.", "xxxxxxx", "xxxxxxx", "xxxxxxx", ".xxxxx.", "..xxx..", "...x..."],
	"stress": [".xxxxx.", "x.....x", "x.xxx.x", "x.x.x.x", "x.x...x", "x.xxxxx", ".x....."]}
const COLORS := {"stamina": 28, "mood": 36, "health": 26, "stress": 30}
const ORDER := ["stamina", "mood", "health", "stress"]
const SEGMENT := 50
const STRIP := Rect2(388, 0, 252, 12)
var life: RefCounted
var focus_text := ""
var show_focus := false

func _ready() -> void:
	size = Vector2(640, 26)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func bind(life_game: RefCounted) -> void:
	life = life_game
	size = Vector2(640, 26)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_focus(text: String, visible_line: bool) -> void:
	focus_text = text
	show_focus = visible_line
	queue_redraw()

func values() -> Dictionary:
	if life == null or life.vitals == null: return {}
	var v: RefCounted = life.vitals
	return {"stamina": v.stamina, "mood": life.mood, "health": v.health, "stress": v.stress, "wallet": life.wallet}

func hud_text() -> String:
	var v := values()
	if v.is_empty(): return ""
	return "S%d M%d H%d X%d $%d" % [v.stamina, v.mood, v.health, v.stress, v.wallet]

func _process(_delta: float) -> void:
	if visible and life != null: queue_redraw()

func _draw() -> void:
	var v := values()
	if v.is_empty(): return
	var font := get_theme_default_font()
	draw_rect(STRIP, Palette.color(1))
	draw_rect(Rect2(STRIP.position.x, 11, STRIP.size.x, 1), Palette.color(5))
	draw_rect(Rect2(STRIP.position.x, 0, 1, 12), Palette.color(5))
	var x := STRIP.position.x + 4.0
	for id in ORDER:
		_icon(id, Vector2(x, 2))
		var value: int = v[id]
		draw_rect(Rect2(x + 10, 4, 24, 5), Palette.color(3))
		var fill := roundi(22.0 * float(value) / 100.0)
		var color: int = COLORS[id]
		if id == "stress" and value > 80 or id != "stress" and value < 30: color = 51
		draw_rect(Rect2(x + 11, 5, fill, 3), Palette.color(color))
		draw_string(font, Vector2(x + 36, 9.5), str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.color(22))
		x += SEGMENT - 8
	draw_string(font, Vector2(x + 6, 9.5), "$%d" % v.wallet, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.color(52))
	if show_focus and focus_text != "":
		var width := font.get_string_size(focus_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		draw_rect(Rect2(640 - width - 10, 12, width + 10, 12), Palette.color(1))
		draw_rect(Rect2(640 - width - 10, 23, width + 10, 1), Palette.color(5))
		draw_rect(Rect2(640 - width - 10, 12, 1, 12), Palette.color(5))
		draw_string(font, Vector2(640 - width - 5, 21.5), focus_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.color(48))

func _icon(id: String, at: Vector2) -> void:
	var rows: Array = ICONS[id]
	for y in rows.size():
		var row: String = rows[y]
		for column in row.length():
			if row[column] == "x":
				draw_rect(Rect2(at.x + column, at.y + y, 1, 1), Palette.color(COLORS[id]))

extends RefCounted
# T-039: feedback animations ("juice"). Purely visual: no game logic reads anything from here.
# Switches: `enabled` (tests can turn everything off), `instant` (state changes without motion),
# `reduce_motion` (the Settings toggle), `force` (lets a headless test run real tweens).
# When not active every helper applies its final state at once, so headless runs and Reduce motion
# behave exactly like the game before T-039. Esc (game_flow) calls finish_all(): every running tween
# jumps to its final state and every particle node is removed. Nothing here blocks input.
const Palette = preload("res://scripts/v2/palette.gd")
const CONFETTI_COLORS := [89, 90, 91, 92, 93, 94, 85, 96]
const POP_TIME := 0.12
static var enabled := true
static var instant := false
static var reduce_motion := false
static var force := false
static var _running: Array = []  # [{tween, final: Callable}]
static var _fx: Array = []       # effect nodes (particles, title cards)

static func active() -> bool:
	return enabled and not instant and not reduce_motion and (force or DisplayServer.get_name() != "headless")

static func _usable(node: Node) -> bool:
	return active() and node != null and is_instance_valid(node) and node.is_inside_tree()

static func _track(tween: Tween, final: Callable, owner: Object = null) -> void:
	var record := {"tween": tween, "final": final, "owner": owner, "owned": owner != null}
	_running.append(record)
	tween.finished.connect(func():
		_running.erase(record)
		if final.is_valid(): final.call())

# Running tweens and effect nodes still alive.
static func pending() -> int:
	_running = _running.filter(func(r): return r.tween != null and r.tween.is_valid() and r.tween.is_running())
	_fx = _fx.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	return _running.size() + _fx.size()

# Skip: every animation lands on its final state now; particles and cards disappear.
static func finish_all() -> void:
	var records := _running.duplicate()
	_running.clear()
	for record in records:
		if record.tween != null and record.tween.is_valid(): record.tween.kill()
		if record.final.is_valid() and not (record.get("owned", false) and not is_instance_valid(record.owner)): record.final.call()
	for node in _fx:
		if is_instance_valid(node): node.queue_free()
	_fx.clear()

static func _alive(node: Variant) -> bool:
	return node != null and is_instance_valid(node)

# ---- windows, popups, dialogs ------------------------------------------------------------------

# Scale-and-fade open (0.12 s). The control stays inside its final rectangle the whole time.
static func pop_in(control: Control) -> void:
	if not _usable(control) or control.has_meta("juice_pop"): return
	var pivot := control.pivot_offset
	var extent := control.size
	var alpha := control.modulate.a
	control.set_meta("juice_pop", true)
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.92, 0.92)
	control.modulate.a = 0.0
	var tween := control.create_tween().set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", alpha, POP_TIME)
	_track(tween, func():
		if not _alive(control): return
		control.scale = Vector2.ONE
		control.modulate.a = alpha
		control.pivot_offset = pivot
		control.size = extent
		control.remove_meta("juice_pop"), control)

# Scale-and-fade close; `done` runs at the end (at once when motion is off).
static func pop_out(control: Control, done: Callable) -> void:
	if not _usable(control) or control.has_meta("juice_pop"):
		done.call()
		return
	var pivot := control.pivot_offset
	var extent := control.size
	var alpha := control.modulate.a
	control.set_meta("juice_pop", true)
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween().set_parallel(true)
	tween.tween_property(control, "scale", Vector2(0.92, 0.92), POP_TIME)
	tween.tween_property(control, "modulate:a", 0.0, POP_TIME)
	_track(tween, func():
		if _alive(control):
			control.scale = Vector2.ONE
			control.modulate.a = alpha
			control.pivot_offset = pivot
			control.size = extent
			control.remove_meta("juice_pop")
		done.call(), control)

# ---- small motions ------------------------------------------------------------------------------

# Brief highlight (brighter, back to the stored color). Layout-neutral.
static func pulse(item: CanvasItem, times: int = 2, strength: float = 1.35) -> void:
	if not _usable(item) or item.has_meta("juice_pulse"): return
	var base := item.self_modulate
	item.set_meta("juice_pulse", true)
	var tween := item.create_tween()
	for i in times:
		tween.tween_property(item, "self_modulate", base * Color(strength, strength, strength, 1.0), 0.12)
		tween.tween_property(item, "self_modulate", base, 0.12)
	_track(tween, func():
		if not _alive(item): return
		item.self_modulate = base
		item.remove_meta("juice_pulse"), item)

# Gentle endless pulse (the Send button when the report is ready). on = false restores the color.
static func set_pulse(item: CanvasItem, on: bool) -> void:
	if not _alive(item): return
	var has := item.has_meta("juice_loop")
	if on and (has or not _usable(item)): return
	if not on:
		if has:
			var old: Dictionary = item.get_meta("juice_loop")
			if old.tween != null and old.tween.is_valid(): old.tween.kill()
			_running = _running.filter(func(r): return r.tween != old.tween)
			item.self_modulate = old.base
			item.remove_meta("juice_loop")
		return
	var base := item.self_modulate
	var tween := item.create_tween().set_loops()
	tween.tween_property(item, "self_modulate", base * Color(1.18, 1.18, 1.18, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(item, "self_modulate", base, 0.45).set_trans(Tween.TRANS_SINE)
	item.set_meta("juice_loop", {"tween": tween, "base": base})
	_running.append({"tween": tween, "owner": item, "owned": true, "final": func():
		if _alive(item):
			item.self_modulate = base
			if item.has_meta("juice_loop"): item.remove_meta("juice_loop")})

# Screen or desk shake: whole pixels, back to the start position.
static func shake(item: CanvasItem, pixels: int = 2, duration: float = 0.25) -> void:
	if not _usable(item) or item.has_meta("juice_move"): return
	var origin: Vector2 = item.position
	var extent: Vector2 = item.size if item is Control else Vector2.ZERO
	item.set_meta("juice_move", true)
	var tween := item.create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector2(pixels if i % 2 == 0 else -pixels, (pixels - 1) if i % 3 == 0 else -(pixels - 1))
		tween.tween_property(item, "position", origin + offset, duration / (steps + 1))
	tween.tween_property(item, "position", origin, duration / (steps + 1))
	_track(tween, func():
		if not _alive(item): return
		item.position = origin
		if item is Control: item.size = extent
		item.remove_meta("juice_move"), item)

# Small hop (happy emotes) and the bounce of +$ / -$ popups.
static func hop(item: CanvasItem, pixels: int = 3, duration: float = 0.22) -> void:
	if not _usable(item) or item.has_meta("juice_move"): return
	var origin: Vector2 = item.position
	var extent: Vector2 = item.size if item is Control else Vector2.ZERO
	item.set_meta("juice_move", true)
	var tween := item.create_tween()
	tween.tween_property(item, "position", origin - Vector2(0, pixels), duration * 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "position", origin, duration * 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_track(tween, func():
		if not _alive(item): return
		item.position = origin
		if item is Control: item.size = extent
		item.remove_meta("juice_move"), item)

static func bounce(control: Control) -> void:
	if not _usable(control) or control.has_meta("juice_pop"): return
	var pivot := control.pivot_offset
	var extent := control.size
	control.set_meta("juice_pop", true)
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(1.3, 1.3)
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_track(tween, func():
		if not _alive(control): return
		control.scale = Vector2.ONE
		control.pivot_offset = pivot
		control.size = extent
		control.remove_meta("juice_pop"), control)

# Hover lift for cards and storefront tiles: 1 px up when free-standing, a soft highlight inside a
# Container (which owns the position).
static func hover_lift(control: Control) -> void:
	if not _alive(control) or control.has_meta("juice_hover"): return
	control.set_meta("juice_hover", true)
	control.mouse_entered.connect(func(): _lift(control, true))
	control.mouse_exited.connect(func(): _lift(control, false))

static func _lift(control: Control, up: bool) -> void:
	if not _alive(control): return
	if up and not active(): return
	var lifted: bool = control.get_meta("juice_lifted", false)
	if up == lifted: return
	control.set_meta("juice_lifted", up)
	if control.get_parent() is Container:
		control.self_modulate = control.self_modulate * (Color(1.12, 1.12, 1.12, 1.0) if up else Color(1.0 / 1.12, 1.0 / 1.12, 1.0 / 1.12, 1.0))
	else:
		control.position.y += -1.0 if up else 1.0

# Buttons: 1 px press offset and a brief highlight. Connected by juice_hooks.gd for every Button.
static func press(button: BaseButton, down: bool) -> void:
	if not _alive(button): return
	var pressed: bool = button.get_meta("juice_down", false)
	if down:
		if pressed or not active() or button.disabled or button.get_parent() is Container: return
		button.set_meta("juice_down", true)
		button.position.y += 1.0
	elif pressed:
		button.set_meta("juice_down", false)
		button.position.y -= 1.0
		pulse(button, 1, 1.25)

# ---- numbers --------------------------------------------------------------------------------------

# Counts from one value to another; `setter` receives each whole number and always the final one.
static func count(owner: Node, setter: Callable, from: int, to: int, duration: float = 0.4) -> void:
	if not _usable(owner) or from == to:
		setter.call(to)
		return
	var tween := owner.create_tween()
	tween.tween_method(func(v: float): setter.call(int(round(v))), float(from), float(to), duration)
	_track(tween, func(): if _alive(owner): setter.call(to), owner)

# ---- particles and cards ---------------------------------------------------------------------------

class Burst extends Control:
	var parts: Array = []
	var life := 0.8
	var age := 0.0
	var gravity := 160.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_meta("overlay", true)
	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		for p in parts:
			p.vel.y += gravity * delta
			p.pos += p.vel * delta
		queue_redraw()
	func _draw() -> void:
		var fade := 1.0 if age < life * 0.7 else 0.5
		for p in parts:
			draw_rect(Rect2(floorf(p.pos.x), floorf(p.pos.y), p.size, p.size), Color(p.color, fade))

static func _burst(parent: Node, at: Vector2, amount: int, speed: float, life: float, gravity: float, colors: Array, seed_value: int) -> Node:
	if not _usable(parent): return null
	var node := Burst.new()
	node.life = life
	node.gravity = gravity
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in mini(amount, 59):
		var angle := rng.randf_range(-PI, 0.0) if gravity > 0.0 else rng.randf_range(0.0, TAU)
		node.parts.append({"pos": at, "vel": Vector2(cos(angle), sin(angle)) * rng.randf_range(speed * 0.4, speed), "color": Palette.color(colors[i % colors.size()]), "size": 2 if i % 3 == 0 else 1})
	parent.add_child(node)
	_fx.append(node)
	return node

# Confetti burst: palette v4 pastels, fewer than 60 particles, 0.8 s.
static func confetti(parent: Node, at: Vector2, amount: int = 48) -> Node:
	return _burst(parent, at, amount, 150.0, 0.8, 260.0, CONFETTI_COLORS, 39)

# A few bright pixels on income.
static func sparkle(parent: Node, at: Vector2) -> Node:
	return _burst(parent, at, 7, 28.0, 0.45, 0.0, [89, 96, 102], 7)

class Card extends Control:
	var age := 0.0
	var life := 1.1
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_meta("overlay", true)
	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		var t := age / life
		modulate.a = minf(1.0, t / 0.15) if t < 0.7 else maxf(0.0, 1.0 - (t - 0.7) / 0.3)

# Day title card ("Day 3"): fades in and out by itself, never takes input.
static func title_card(parent: Node, text: String) -> Node:
	if not _usable(parent): return null
	var card := Card.new()
	card.size = Vector2(640, 360)
	var plate := ColorRect.new()
	plate.color = Color(Palette.color(65), 0.86)
	plate.position = Vector2(220, 150)
	plate.size = Vector2(200, 28)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(plate)
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, 5)
	label.size = Vector2(200, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Palette.color(89))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(label)
	card.modulate.a = 0.0
	parent.add_child(card)
	_fx.append(card)
	return card

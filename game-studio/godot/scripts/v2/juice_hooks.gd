extends Node
# T-039: zero-touch juice hooks (same idea as audio_hooks.gd). One instance is added by game_flow.gd.
# - every Button gets the 1 px press offset and a brief highlight;
# - every desktop window (window_base.gd) and the listed popups open with the scale-and-fade.
# Esc lands every running animation on its final state (the event is not consumed).
const Juice = preload("res://scripts/v2/juice.gd")
const WindowBase = preload("res://scripts/v2/windows/window_base.gd")
const POPUPS := ["res://scripts/v2/learn/hint_popup.gd", "res://scripts/v2/windows/analysis_panel.gd"]

func _ready() -> void:
	add_to_group("juice_hooks")
	get_tree().node_added.connect(_hook)
	_scan(get_tree().root)

func _scan(node: Node) -> void:
	_hook(node)
	for child in node.get_children(): _scan(child)

func _hook(node: Node) -> void:
	if node is Button:
		var down := Juice.press.bind(node, true)
		var up := Juice.press.bind(node, false)
		if not node.button_down.is_connected(down): node.button_down.connect(down)
		if not node.button_up.is_connected(up): node.button_up.connect(up)
		return
	if not node is Control: return
	var script: Script = node.get_script()
	if script == null: return
	# Desktop windows only: full-screen scenes also extend window_base.gd but are covered by the fade.
	var is_window: bool = node.get_parent() != null and node.get_parent().has_method("open_window") and _extends(script, WindowBase)
	if is_window or script.resource_path in POPUPS:
		var shown := _shown.bind(node)
		if not node.visibility_changed.is_connected(shown): node.visibility_changed.connect(shown)

func _extends(script: Script, base: Script) -> bool:
	var s := script
	while s != null:
		if s == base: return true
		s = s.get_base_script()
	return false

func _shown(control: Control) -> void:
	if control.is_visible_in_tree(): Juice.pop_in(control)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		Juice.finish_all()

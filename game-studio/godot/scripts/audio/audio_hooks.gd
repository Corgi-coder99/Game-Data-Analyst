extends Node
var manager: Node

func _ready() -> void:
	get_tree().node_added.connect(_connect_button)
	_scan(get_tree().root)

func _scan(node: Node) -> void:
	_connect_button(node)
	for child in node.get_children(): _scan(child)

func _connect_button(node: Node) -> void:
	if not node is Button: return
	var click := _sound.bind(node, "click")
	var hover := _sound.bind(node, "hover")
	if not node.pressed.is_connected(click): node.pressed.connect(click)
	if not node.mouse_entered.is_connected(hover): node.mouse_entered.connect(hover)

func _sound(button: Button, id: String) -> void:
	if not button.disabled and not button.get_meta("no_sound", false): manager.play_sfx(id)

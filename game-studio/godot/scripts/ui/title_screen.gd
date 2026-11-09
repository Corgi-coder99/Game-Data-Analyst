extends PanelContainer

const Loader = preload("res://scripts/data.gd")

func _ready() -> void:
	preload("res://scripts/ui/palette.gd").apply_to(self)
	var strings: Dictionary = Loader.load_json("res://data/strings.json")
	$Menu/Title.text = strings.title
	$Menu/Play.text = strings.play
	$Menu/Quit.text = strings.quit
	$Menu/Play.pressed.connect(start_game)
	$Menu/Quit.pressed.connect(get_tree().quit)
	$Menu/Play.grab_focus()

func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

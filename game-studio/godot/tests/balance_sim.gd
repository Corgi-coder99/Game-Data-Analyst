extends SceneTree
# Chay: Godot_console --headless --path game-studio/godot -s res://tests/balance_sim.gd

func _init() -> void:
	var cfg := Data.load_json("res://data/config.json")
	assert(cfg.has("version"))
	print("balance_sim OK, config version=", cfg["version"])
	quit(0)

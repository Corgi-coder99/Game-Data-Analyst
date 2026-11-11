extends SceneTree
# T-036 measurement tool (hidden access is fine here: this is an offline tool, not a bot).
# Does the day's data inform the day's boss question? Prints the numbers used in the handoff.
# Usage: -s res://tests/relevance_t036.gd -- --seeds=200
const Game = preload("res://scripts/world/world_game.gd")
const Relevance = preload("res://tests/t036_relevance_lib.gd")

func _init() -> void:
	var seeds := 200
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seeds = int(arg.trim_prefix("--seeds="))
	var r: Dictionary = Relevance.measure(104, seeds, 10)
	Relevance.print_report(r)
	quit()

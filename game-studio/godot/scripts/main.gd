extends Node2D

func _ready() -> void:
	print("Main scene ready. Data: ", Data.load_json("res://data/config.json"))

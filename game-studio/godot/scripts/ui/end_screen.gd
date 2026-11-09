extends MarginContainer

signal replay_requested

const Loader = preload("res://scripts/data.gd")
const METRICS := ["cash", "users", "retention", "conversion", "cac", "arpu", "ratio", "integrity"]
var strings: Dictionary
var truth: Dictionary = {}
var observed: Dictionary = {}

func _ready() -> void:
	preload("res://scripts/ui/palette.gd").apply_to(self)
	strings = Loader.load_json("res://data/strings.json")
	$Layout/Buttons/Replay.text = strings.replay
	$Layout/Buttons/Title.text = strings.back_to_title
	$Layout/Buttons/Replay.pressed.connect(func(): replay_requested.emit())
	$Layout/Buttons/Title.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))

func show_result(simulation: RefCounted, last_report: Dictionary) -> void:
	# Only this screen reads true metrics, after the simulation has ended.
	assert(simulation.state.won or simulation.state.lost)
	observed = last_report.duplicate(true)
	for metric in METRICS:
		truth[metric] = simulation.state.ratio(simulation.config) if metric == "ratio" else simulation.state.value(metric, simulation.config)
	observed.ratio = observed.arpu / maxf(float(simulation.config.economy.churn_floor), 1.0 - float(observed.retention)) / maxf(0.001, float(observed.cac))
	$Layout/Result.text = strings.end % [strings.won if simulation.state.won else strings.lost, simulation.score()]
	$Layout/Resolved.text = strings.resolved_events % simulation.state.resolved
	$Layout/Explanation.text = strings.truth_explanation
	for child in $Layout/Table.get_children():
		$Layout/Table.remove_child(child)
		child.queue_free()
	for heading in [strings.truth_metric, strings.truth_actual, strings.truth_seen]:
		add_cell(heading)
	for metric in METRICS:
		add_cell(strings.truth_names[metric])
		var scale := 100.0 if metric in ["retention", "conversion"] else 1.0
		var format_string: String = strings.metric_formats.get(metric, "%.0f")
		add_cell(format_string % (float(truth[metric]) * scale))
		add_cell(format_string % (float(observed[metric]) * scale))
	$Layout/Buttons/Replay.grab_focus()

func add_cell(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	$Layout/Table.add_child(label)

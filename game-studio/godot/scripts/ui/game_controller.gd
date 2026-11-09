extends PanelContainer

const Sim = preload("res://scripts/sim/simulation.gd")
const Loader = preload("res://scripts/data.gd")
var simulation: RefCounted
var strings: Dictionary
var displayed_report: Dictionary
var ended := false

func _ready() -> void:
	preload("res://scripts/ui/palette.gd").apply_to(self)
	strings = Loader.load_json("res://data/strings.json")
	$Layout/Top/FinishWeek.text = strings.finish_week
	$Layout/Top/FinishWeek.pressed.connect(finish_week)
	start_game()

func start_game(seed_value: int = -1) -> void:
	var config: Dictionary = Loader.load_json("res://data/config.json")
	simulation = Sim.new(int(Time.get_ticks_usec()) if seed_value < 0 else seed_value, {}, int(config.weeks.demo))
	ended = false
	$End.hide()
	$Layout.show()
	$Layout/Status.text = ""
	simulation.begin_week()
	refresh()

func play_card(card_id: String) -> bool:
	if ended:
		return false
	var accepted: bool = simulation.play(card_id)
	$Layout/Status.text = "" if accepted else strings.rejected
	if accepted:
		refresh()
	return accepted

func finish_week() -> void:
	if ended:
		return
	simulation.finish_week()
	if simulation.state.lost or simulation.state.won:
		ended = true
		$Layout.hide()
		$End.text = strings.end % [strings.won if simulation.state.won else strings.lost, simulation.score()]
		$End.show()
		return
	simulation.begin_week()
	$Layout/Status.text = ""
	refresh()

func refresh() -> void:
	displayed_report = simulation.report()
	var r := displayed_report
	$Layout/Top/HUD.text = strings.hud % [simulation.state.week, simulation.horizon, r.cash, simulation.state.energy]
	# Derive the ratio only from observed metrics, using the economy's churn floor.
	var ratio: float = r.arpu / maxf(float(simulation.config.economy.churn_floor), 1.0 - float(r.retention)) / maxf(0.001, float(r.cac))
	$Layout/Metrics.text = strings.metrics % [r.users, r.retention * 100.0, r.conversion * 100.0, r.cac, r.arpu, ratio, r.integrity]
	for child in $Layout/Hand.get_children():
		$Layout/Hand.remove_child(child)
		child.queue_free()
	for card in simulation.hand:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = strings.card % [strings.cards[card.id], card.budget, card.energy]
		button.disabled = r.cash < card.budget or simulation.state.energy < card.energy
		button.modulate.a = 0.4 if button.disabled else 1.0
		button.pressed.connect(play_card.bind(str(card.id)))
		$Layout/Hand.add_child(button)

extends PanelContainer

const Sim = preload("res://scripts/sim/simulation.gd")
const Loader = preload("res://scripts/data.gd")
const Palette = preload("res://scripts/ui/palette.gd")
const LOW_INTEGRITY_THRESHOLD := 60.0
const METRICS := ["users", "retention", "conversion", "cac", "arpu", "ratio", "integrity"]
var simulation: RefCounted
var strings: Dictionary
var displayed_report: Dictionary
var history: Array = []
var previous_week: Dictionary = {}
var selected_metric := "users"
var ended := false
@onready var dashboard = $Layout/Body/Dashboard
@onready var details = $Layout/Body/Details

func _ready() -> void:
	Palette.apply_to(self)
	strings = Loader.load_json("res://data/strings.json")
	$Layout/Top/FinishWeek.text = strings.finish_week
	$Layout/Top/FinishWeek.pressed.connect(finish_week)
	details.get_node("EventsTitle").text = strings.events_title
	for metric in METRICS:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(select_metric.bind(metric))
		dashboard.get_node("Metrics").add_child(button)
	start_game()

func start_game(seed_value: int = -1) -> void:
	var config: Dictionary = Loader.load_json("res://data/config.json")
	simulation = Sim.new(int(Time.get_ticks_usec()) if seed_value < 0 else seed_value, {}, int(config.weeks.demo))
	ended = false
	history.clear()
	previous_week.clear()
	selected_metric = "users"
	if has_node("End"):
		var old_end = get_node("End")
		remove_child(old_end)
		old_end.queue_free()
	$Layout.show()
	$Layout/Status.text = ""
	details.get_node("Journal").text = strings.no_journal
	simulation.begin_week()
	refresh()

func _input(event: InputEvent) -> void:
	if ended or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		var index: int = event.keycode - KEY_1
		if index < simulation.hand.size():
			play_card(str(simulation.hand[index].id))
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		finish_week()
		get_viewport().set_input_as_handled()

func play_card(card_id: String) -> bool:
	if ended:
		return false
	var accepted: bool = simulation.play(card_id)
	$Layout/Status.text = "" if accepted else strings.rejected
	if accepted:
		refresh()
		$Layout/Top/HUD.modulate = Palette.SELECTED
		create_tween().tween_property($Layout/Top/HUD, "modulate", Palette.TEXT, 0.2)
	return accepted

func finish_week() -> void:
	if ended:
		return
	# Freeze the last observed report for next week's arrows and journal estimates.
	previous_week = displayed_report.duplicate(true)
	var r := previous_week
	var economy: Dictionary = simulation.config.economy
	var effective_cac: float = r.cac * (1.0 + economy.ad_diminishing * r.ad_spend / economy.ad_unit)
	var acquired: float = r.ad_spend / maxf(0.001, effective_cac)
	var churned: float = r.users * (1.0 - r.retention)
	var users_after: float = maxf(0, r.users - churned + acquired)
	details.get_node("Journal").text = strings.journal % [simulation.state.week, acquired, churned, users_after * r.conversion * r.arpu, r.fixed_cost + economy.cost_per_user * users_after]
	simulation.finish_week()
	if simulation.state.lost or simulation.state.won:
		ended = true
		$Layout.hide()
		var end_screen = load("res://scenes/end.tscn").instantiate()
		add_child(end_screen)
		end_screen.show_result(simulation, displayed_report)
		end_screen.replay_requested.connect(start_game)
		return
	simulation.begin_week()
	$Layout/Status.text = ""
	refresh()

func metric_value(report: Dictionary, metric: String) -> float:
	if metric == "ratio":
		return report.arpu / maxf(float(simulation.config.economy.churn_floor), 1.0 - float(report.retention)) / maxf(0.001, float(report.cac))
	return float(report[metric])

func select_metric(metric: String) -> void:
	selected_metric = metric
	var samples: Array = []
	var weeks: Array = []
	for snapshot in history:
		samples.append(metric_value(snapshot.report, metric))
		weeks.append(snapshot.week)
	dashboard.get_node("Chart").set_values(samples, weeks, strings.chart_week, strings.metric_formats[metric], 100.0 if metric in ["retention", "conversion"] else 1.0)
	var low: float = samples.min() if not samples.is_empty() else 0.0
	var high: float = samples.max() if not samples.is_empty() else 0.0
	dashboard.get_node("ChartTitle").text = strings.chart % [strings.metric_names[metric], low, high]
	for i in METRICS.size():
		dashboard.get_node("Metrics").get_child(i).modulate = Palette.SELECTED if METRICS[i] == metric else Palette.TEXT

func refresh() -> void:
	displayed_report = simulation.report()
	var r := displayed_report
	history.append({"week": simulation.state.week, "report": r.duplicate(true)})
	var energy := ""
	for i in int(simulation.config.energy):
		energy += strings.energy_full if i < simulation.state.energy else strings.energy_empty
	$Layout/Top/HUD.text = strings.dashboard_hud % [simulation.state.week, simulation.horizon, r.cash, energy]
	var uncertain: bool = r.integrity < LOW_INTEGRITY_THRESHOLD
	dashboard.get_node("Warning").text = strings.integrity_warning if uncertain else ""
	for i in METRICS.size():
		var metric: String = METRICS[i]
		var value := metric_value(r, metric)
		var arrow: String = strings.arrow_flat
		if not previous_week.is_empty():
			var delta := value - metric_value(previous_week, metric)
			arrow = strings.arrow_up if delta > 0.001 else (strings.arrow_down if delta < -0.001 else strings.arrow_flat)
		var format_string: String = strings.metric_formats[metric]
		var scaled := value * 100.0 if metric in ["retention", "conversion"] else value
		dashboard.get_node("Metrics").get_child(i).text = strings.metric_tile % [strings.metric_names[metric], format_string % scaled, arrow, strings.uncertain if uncertain else ""]
	select_metric(selected_metric)
	var event_reports: Array = simulation.event_reports()
	var hand_ids := PackedStringArray()
	for card in simulation.hand:
		hand_ids.append(card.id)
	var card_causes := {}
	var event_lines := PackedStringArray()
	for event in event_reports:
		event_lines.append(strings.symptom % event.symptom)
		if event.has("root_cause"):
			event_lines.append(strings.root_cause % event.root_cause)
			var remedies := PackedStringArray()
			for id in event.remedies:
				var card_name: String = strings.cards[id]
				remedies.append(strings.remedy_in_hand % card_name if id in hand_ids else card_name)
				if not card_causes.has(id):
					card_causes[id] = []
				card_causes[id].append(event.root_cause)
			event_lines.append(strings.event_remedies % ", ".join(remedies))
	details.get_node("EventScroll/Events").text = strings.no_events if event_lines.is_empty() else "\n".join(event_lines)
	for child in $Layout/Hand.get_children():
		$Layout/Hand.remove_child(child)
		child.queue_free()
	var index := 0
	for card in simulation.hand:
		index += 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 110)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 1.0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 11)
		button.text = strings.dashboard_card % [index, strings.cards[card.id], strings.categories[card.category], card.budget, card.energy, strings.card_short[card.id]]
		button.tooltip_text = strings.card_detail % [strings.cards[card.id], card.budget, card.energy, strings.card_details[card.id]]
		var causes: Array = card_causes.get(card.id, [])
		button.set_meta("remedy_causes", causes)
		if not causes.is_empty():
			var cause: String = causes[0]
			if causes.size() > 1:
				cause = strings.remedy_more % [cause, causes.size() - 1]
			button.text += "\n" + strings.card_remedy % cause
			button.tooltip_text += "\n" + strings.card_remedy % ", ".join(causes)
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.ACCENT
		style.border_color = Palette.CATEGORIES[card.category]
		style.set_border_width_all(2)
		if not causes.is_empty():
			style.bg_color = Palette.ACCENT.lightened(0.2)
			style.border_color = Palette.SELECTED
			style.set_border_width_all(3)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("disabled", style)
		if not causes.is_empty():
			button.add_theme_stylebox_override("hover", style)
			button.add_theme_stylebox_override("pressed", style)
		button.disabled = r.cash < card.budget or simulation.state.energy < card.energy
		button.modulate.a = 0.4 if button.disabled else 1.0
		button.pressed.connect(play_card.bind(str(card.id)))
		$Layout/Hand.add_child(button)

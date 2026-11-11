extends "res://scripts/v2/windows/window_base.gd"
# Dashboard (formerly Insight BI). T-034: two tabs. "Company" keeps the old metric list; "Dashboard"
# is the 2x2 grid of pinned charts and KPI tiles (only when the data session exists).
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const DashboardView = preload("res://scripts/v2/data/dashboard_view.gd")
const LOW_INTEGRITY_THRESHOLD := 60.0
const REPORTED_CHURN_FLOOR := 0.01
const METRICS := ["cash", "users", "retention", "conversion", "cac", "arpu", "ratio", "integrity"]
var previous: Dictionary = {}
var current: Dictionary = {}
var current_day := -1
var strings: Dictionary
var metrics_box: Control
var dash_view: Control
var tab_buttons: Dictionary = {}
var tab := "metrics"
var session: RefCounted

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.company, Rect2(58, 30, 442, 290))
	metrics_box = Control.new()
	metrics_box.position = Vector2(0, 16)
	metrics_box.size = Vector2(434, 254)
	content.add_child(metrics_box)
	for pair in [["metrics", strings.data_ui.dash.tab_metrics, 0], ["dash", strings.data_ui.dash.tab_dash, 1]]:
		var b := UI.button(content, pair[1], Rect2(pair[2] * 72, 0, 70, 14))
		b.toggle_mode = true
		b.name = "Tab_" + pair[0]
		b.pressed.connect(show_tab.bind(pair[0]))
		tab_buttons[pair[0]] = b
		b.visible = false
	tab_buttons.metrics.button_pressed = true

# Enables the Dashboard tab once the data session exists.
func attach_session(value: RefCounted) -> void:
	session = value
	dash_view = DashboardView.new()
	dash_view.position = Vector2(0, 16)
	content.add_child(dash_view)
	dash_view.build(session, strings.data_ui)
	for id in tab_buttons: tab_buttons[id].visible = true
	show_tab("metrics")

func show_tab(id: String) -> void:
	tab = id
	metrics_box.visible = id == "metrics"
	if dash_view != null: dash_view.visible = id == "dash"
	for key in tab_buttons: tab_buttons[key].button_pressed = key == id

func reset_history() -> void:
	previous.clear()
	current.clear()
	current_day = -1

func display(snapshot: Dictionary, state: Dictionary) -> void:
	if current_day != int(state.day):
		previous = current.duplicate(true)
		current_day = int(state.day)
	current = snapshot.duplicate(true)
	current.ratio = float(current.arpu) / maxf(REPORTED_CHURN_FLOOR, 1.0 - float(current.retention)) / maxf(0.001, float(current.cac))
	empty(metrics_box)
	label(metrics_box, strings.ui.day % [state.day, state.horizon] + " · " + strings.ranks[state.rank], Rect2(0, 0, 232, 13))
	var trust_label := label(metrics_box, strings.ui.trust % state.trust, Rect2(0, 13, 110, 13))
	trust_label.tooltip_text = strings.glossary.trust
	trust_label.mouse_filter = Control.MOUSE_FILTER_PASS
	var trust := ProgressBar.new()
	trust.theme = theme
	trust.show_percentage = false
	trust.custom_minimum_size = Vector2(117, 7)
	trust.position = Vector2(113, 16)
	trust.size = Vector2(117, 7)
	trust.value = clampf(float(state.trust), 0, 100)
	metrics_box.add_child(trust)
	trust.size = Vector2(117, 7)
	for i in METRICS.size():
		var metric: String = METRICS[i]
		var value: float = current[metric]
		var direction := signf(value - float(previous.get(metric, value)))
		var y := 28 + i * 12
		label(metrics_box, strings.metrics[metric], Rect2(0, y, 112, 12), 7)
		var formatted := "%.2f" % value
		if metric in ["retention", "conversion"]: formatted = "%.1f%%" % (value * 100)
		elif metric == "integrity": formatted = "%.1f%%" % value
		elif metric in ["cash", "users"]: formatted = "%.0f" % value
		var amount := label(metrics_box, formatted, Rect2(114, y, 98, 12), 24 if direction > 0 else (26 if direction < 0 else 7))
		if metric == "ratio":
			amount.tooltip_text = strings.ui.ratio_hint
			amount.mouse_filter = Control.MOUSE_FILTER_PASS
		icon(metrics_box, "arrow_up" if direction > 0 else ("arrow_down" if direction < 0 else "arrow_flat"), Vector2(220, y + 2))
	if float(current.integrity) < LOW_INTEGRITY_THRESHOLD:
		label(metrics_box, strings.ui.uncertain, Rect2(0, 126, 230, 14), 28)

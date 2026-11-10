extends "res://scripts/v2/windows/window_base.gd"
const LOW_INTEGRITY_THRESHOLD := 60.0
const REPORTED_CHURN_FLOOR := 0.01
const METRICS := ["cash", "users", "retention", "conversion", "cac", "arpu", "ratio", "integrity"]
var previous: Dictionary = {}
var current: Dictionary = {}
var current_day := -1
var strings: Dictionary

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.company, Rect2(396, 20, 240, 164))

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
	empty(content)
	label(content, strings.ui.day % [state.day, state.horizon] + " · " + strings.ranks[state.rank], Rect2(0, 0, 232, 13))
	label(content, strings.ui.trust % state.trust, Rect2(0, 13, 110, 13))
	var trust := ProgressBar.new()
	trust.theme = theme
	trust.show_percentage = false
	trust.custom_minimum_size = Vector2(117, 7)
	trust.position = Vector2(113, 16)
	trust.size = Vector2(117, 7)
	trust.value = clampf(float(state.trust), 0, 100)
	content.add_child(trust)
	trust.size = Vector2(117, 7)
	for i in METRICS.size():
		var metric: String = METRICS[i]
		var value: float = current[metric]
		var direction := signf(value - float(previous.get(metric, value)))
		var y := 28 + i * 12
		label(content, strings.metrics[metric], Rect2(0, y, 112, 12), 7)
		var formatted := "%.2f" % value
		if metric in ["retention", "conversion"]: formatted = "%.1f%%" % (value * 100)
		elif metric == "integrity": formatted = "%.1f%%" % value
		elif metric in ["cash", "users"]: formatted = "%.0f" % value
		var amount := label(content, formatted, Rect2(114, y, 98, 12), 24 if direction > 0 else (26 if direction < 0 else 7))
		if metric == "ratio":
			amount.tooltip_text = strings.ui.ratio_hint
			amount.mouse_filter = Control.MOUSE_FILTER_PASS
		icon(content, "arrow_up" if direction > 0 else ("arrow_down" if direction < 0 else "arrow_flat"), Vector2(220, y + 2))
	if float(current.integrity) < LOW_INTEGRITY_THRESHOLD:
		label(content, strings.ui.uncertain, Rect2(0, 126, 230, 14), 28)

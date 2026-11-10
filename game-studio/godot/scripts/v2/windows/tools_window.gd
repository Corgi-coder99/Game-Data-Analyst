extends "res://scripts/v2/windows/window_base.gd"
var strings: Dictionary
var buttons: Dictionary = {}
var result_label: Label
signal requested(tool_id: String)

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.tools, Rect2(58, 30, 300, 184))

static func dots(state: Dictionary) -> String:
	var output := ""
	for i in mini(3, int(state.energy_max)):
		output += "●" if i < int(state.energy) else "○"
	return output

func display(available: Array, state: Dictionary, selected: Dictionary, message: String) -> void:
	empty(content)
	buttons.clear()
	var energy_label := label(content, strings.ui.energy + " " + dots(state), Rect2(0, 0, 290, 14), 28)
	energy_label.tooltip_text = strings.glossary.energy
	energy_label.mouse_filter = Control.MOUSE_FILTER_PASS
	var chosen_text: String = strings.ui.select if selected.is_empty() else strings.ui.selected % selected.headline
	var chosen_label := label(content, chosen_text, Rect2(0, 14, 290, 26), 7)
	chosen_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chosen_label.max_lines_visible = 2
	chosen_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chosen_label.tooltip_text = chosen_text
	chosen_label.mouse_filter = Control.MOUSE_FILTER_PASS
	for i in available.size():
		var tool: Dictionary = available[i]
		var y := 42 + i * 24
		label(content, strings.tools[tool.id], Rect2(0, y, 230, 12))
		var cost_text: String = strings.ui.cost_time % [tool.energy, tool.budget, tool.minutes] if tool.has("minutes") else strings.ui.cost % [tool.energy, tool.budget]
		label(content, cost_text, Rect2(0, y + 12, 230, 12), 7)
		var use := button(content, strings.ui.use, Rect2(238, y + 2, 50, 18))
		var cached: bool = tool.id in selected.get("verified_by", [])
		use.disabled = selected.is_empty() or bool(state.finished) or (not cached and (int(state.energy) < int(tool.energy) or float(state.cash_report) < float(tool.budget)))
		use.pressed.connect(func(): requested.emit(tool.id))
		buttons[tool.id] = use
	result_label = label(content, message, Rect2(0, 140, 290, 22), 28)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.tooltip_text = message
	result_label.mouse_filter = Control.MOUSE_FILTER_PASS

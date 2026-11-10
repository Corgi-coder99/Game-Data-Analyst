extends "res://scripts/v2/windows/window_base.gd"
var strings: Dictionary
var buttons: Dictionary = {}
var result_label: Label
signal requested(tool_id: String)

func initialize(texts: Dictionary) -> void:
	strings = texts
	build(strings.windows.tools, Rect2(396, 188, 240, 152))

static func dots(state: Dictionary) -> String:
	var output := ""
	for i in mini(3, int(state.energy_max)):
		output += "●" if i < int(state.energy) else "○"
	return output

func display(available: Array, state: Dictionary, selected: Dictionary, message: String) -> void:
	empty(content)
	buttons.clear()
	label(content, strings.ui.energy + " " + dots(state), Rect2(0, 0, 230, 14), 28)
	for i in available.size():
		var tool: Dictionary = available[i]
		var y := 14 + i * 24
		label(content, strings.tools[tool.id], Rect2(0, y, 180, 12))
		label(content, strings.ui.cost % [tool.energy, tool.budget], Rect2(0, y + 12, 180, 12), 7)
		var use := button(content, strings.ui.use, Rect2(187, y + 2, 43, 18))
		var cached: bool = tool.id in selected.get("verified_by", [])
		use.disabled = selected.is_empty() or bool(state.finished) or (not cached and (int(state.energy) < int(tool.energy) or float(state.cash_report) < float(tool.budget)))
		use.pressed.connect(func(): requested.emit(tool.id))
		buttons[tool.id] = use
	result_label = label(content, message, Rect2(0, 110, 232, 22), 28)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.tooltip_text = message
	result_label.mouse_filter = Control.MOUSE_FILTER_PASS

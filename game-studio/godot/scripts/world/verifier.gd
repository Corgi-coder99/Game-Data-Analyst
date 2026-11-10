extends RefCounted

var _rng := RandomNumberGenerator.new()
var _config: Dictionary

func _init(seed_value: int, config: Dictionary) -> void:
	_rng.seed = seed_value
	_config = config

func verify(item: Dictionary, tool_id: String, sim: RefCounted) -> Dictionary:
	if not _config.tools.has(tool_id): return {"ok":false,"error":"invalid_tool"}
	if item.results.has(tool_id):
		return {"ok":true,"result":item.results[tool_id],"energy_left":sim.state.energy}
	if not sim.use_tool(_config.tools[tool_id], float(_config.tool_budget.get(tool_id, -1))): return {"ok":false,"error":"insufficient_resources"}
	var result := "chua_du_can_cu"
	if tool_id in item.verify_with:
		match item.truth:
			"dung", "mot_phan": result = "xac_nhan"
			"sai": result = "bac_bo"
			"cu": result = "cu"
	# Read integrity through the same public dashboard available to a player.
	var integrity: float = sim.report().integrity
	if result != "chua_du_can_cu" and _rng.randf() < (1.0 - clampf(integrity, 0, 100) / 100.0) * float(_config.noise_factor):
		result = "chua_du_can_cu"
	item.results[tool_id] = result
	item.verified_by.append(tool_id)
	# An inconclusive second tool must not erase an established finding.
	if item.verification in ["chua_kiem_chung", "chua_du_can_cu"] or result != "chua_du_can_cu":
		item.verification = result
	return {"ok":true,"result":result,"energy_left":sim.state.energy}

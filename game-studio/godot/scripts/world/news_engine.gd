extends RefCounted

var _items: Array = []
var _last: Dictionary = {}
var _seen: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _config: Dictionary
var _data: Dictionary

func _init(seed_value: int, config: Dictionary, data: Dictionary) -> void:
	_rng.seed = seed_value
	_config = config
	_data = data

func _eligible(t: Dictionary, day: int, scenario: RefCounted) -> bool:
	if day - int(_last.get(t.id, -100)) < int(_config.repeat_days): return false
	var source: Dictionary = _source(t.source_id)
	var link: String = t.get("link", "") if t.get("link") != null else ""
	if t.kind in ["stale", "noise"]: return true
	if link.begins_with("state:"):
		var variable := link.trim_prefix("state:")
		var value: Dictionary = scenario._days[day - 1][variable]
		var matches: bool = t.state_direction == value.direction
		if t.kind == "trap": return not matches or t.get("exaggerates", false)
		if not matches: return false
		var changed := day
		while changed > 1 and scenario._days[changed - 2][variable].direction == value.direction:
			changed -= 1
		return day - changed >= int(source.delay_days)
	if link.begins_with("event:"):
		for shock in scenario._shocks:
			if shock.id == link.trim_prefix("event:") and day >= shock.day + int(source.delay_days) and (day < shock.end or day - shock.day <= int(_config.event_recent_days)):
				return true
	return false

func _source(id: String) -> Dictionary:
	for source in _data.sources:
		if source.id == id: return source
	return {}

func _generate(day: int, horizon: int, scenario: RefCounted) -> void:
	for slot in int(_config.news_per_day[str(horizon)]):
		var candidates: Array = _data.news.filter(func(t): return _eligible(t, day, scenario))
		if candidates.is_empty(): break
		var desired := ""
		for kind in _config.kind_weights:
			if not _seen.has(kind) and candidates.any(func(t): return t.kind == kind):
				desired = kind
				break
		if desired.is_empty():
			var total := 0.0
			for kind in _config.kind_weights:
				if candidates.any(func(t): return t.kind == kind): total += float(_config.kind_weights[kind])
			var roll := _rng.randf() * total
			for kind in _config.kind_weights:
				if not candidates.any(func(t): return t.kind == kind): continue
				roll -= float(_config.kind_weights[kind])
				if roll <= 0:
					desired = kind
					break
		var pool := candidates.filter(func(t): return t.kind == desired)
		if pool.is_empty(): pool = candidates
		var t: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
		var magnitude := "mid"
		if str(t.get("link", "")).begins_with("state:"):
			magnitude = scenario._days[day - 1][t.link.trim_prefix("state:")].magnitude
		if t.kind == "partial": magnitude = "low" if magnitude == "high" else "high"
		var source := _source(t.source_id)
		_items.append({"uid":"d%d-n%d" % [day, slot],"template_id":t.id,"day":day,"source_id":t.source_id,"source_tier":source.tier,"source_name":source.name,"headline":t.headline.replace("{pct}", str(t.get("magnitude_pct", {}).get(magnitude, 0))),"topic":t.topic,"verification":"chua_kiem_chung","verified_by":[],"truth":t.truth,"kind":t.kind,"link":t.get("link"),"magnitude":magnitude,"verify_with":t.verify_with.duplicate(),"results":{}})
		_last[t.id] = day
		_seen[t.kind] = true

func _find(uid: String) -> Dictionary:
	for item in _items:
		if item.uid == uid: return item
	return {}

func news_today(day: int) -> Array:
	var result: Array = []
	for item in _items:
		if item.day > day or day - item.day >= int(_config.news_lifetime): continue
		var visible := {}
		for key in ["uid","day","source_id","source_tier","source_name","headline","topic","verification","verified_by"]:
			visible[key] = item[key]
		result.append(visible.duplicate(true))
	return result

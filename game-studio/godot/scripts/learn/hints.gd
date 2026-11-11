extends RefCounted
# T-035: turns the engine's structured hint parts into the text of a hint popup.
# Three levels per case: 1 names the problem type, 2 names the method (a Handbook method card), 3 names
# the Sheet operation families. Never the answer, never the reference steps.
const Content = preload("res://scripts/learn/content.gd")

# parts: {level, skill, card_id, families}. texts: strings_v2.learn.
static func compose(parts: Dictionary, texts: Dictionary) -> Dictionary:
	var level := int(parts.get("level", 1))
	var out := {"level": level, "title": texts.hint_level % [level, int(texts.hint_levels)], "text": "", "card_id": ""}
	match level:
		1:
			out.text = str(texts.hint_type.get(parts.get("skill", ""), texts.hint_type.data_cleaning))
		2:
			var card: Dictionary = Content.card_by_id(str(parts.get("card_id", "")))
			out.card_id = str(card.get("id", ""))
			if not card.is_empty():
				out.title = texts.hint_level % [level, int(texts.hint_levels)] + ": " + str(card.title)
				out.text = "%s %s" % [card.what, texts.hint_when % card.when_to_use]
		_:
			var families: Array = parts.get("families", [])
			out.text = texts.hint_families % ", ".join(families) if not families.is_empty() else str(texts.hint_families_none)
	return out

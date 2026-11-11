extends Control
# T-034: the Analysis section of Mail. Pinned charts, tables and KPI tiles can be attached to the report
# (thumbnail, title, Detach). The findings picker lists engine-generated statements as choices; nothing
# is pre-selected and no choice is marked. Everything stays editable until Send.
const UI = preload("res://scripts/v2/data/ui_kit.gd")
const Canvas = preload("res://scripts/v2/data/chart_canvas.gd")
const Palette = preload("res://scripts/v2/palette.gd")
signal closed
signal edited
var session: RefCounted
var texts: Dictionary = {}
var locked := false
var attach_buttons: Dictionary = {}
var finding_pickers: Dictionary = {}
var message_label: Label

func build(p_session: RefCounted, p_texts: Dictionary, p_locked: bool) -> void:
	session = p_session
	texts = p_texts
	locked = p_locked
	size = Vector2(434, 270)
	set_meta("overlay", true)
	UI.panel(self, Rect2(0, 0, 434, 270), 2, 94)
	UI.label(self, texts.mail.title, Rect2(6, 2, 200, 14), 28, 12)
	var done := UI.button(self, texts.mail.done, Rect2(364, 2, 66, 16))
	done.name = "AnalysisDone"
	done.pressed.connect(func(): closed.emit())
	_build_attachments()
	_build_findings()

func _build_attachments() -> void:
	UI.label(self, texts.mail.attachments % [session.attached.size(), session.limit("max_attached", 3)], Rect2(6, 22, 200, 12), 7)
	if session.pins.is_empty():
		UI.wrapped(self, texts.mail.none, Rect2(6, 38, 200, 24), 6, 2)
	for i in session.pins.size():
		var p: Dictionary = session.pins[i]
		var y: int = 36 + i * 40
		UI.panel(self, Rect2(4, y, 206, 36), 3, 4)
		var thumb := Canvas.new()
		thumb.mini = true
		thumb.position = Vector2(8, y + 4)
		thumb.size = Vector2(48, 28)
		add_child(thumb)
		if p.type == "chart": thumb.set_chart(session.pin_series(p.id), p.spec)
		else:
			UI.label(thumb, "KPI" if p.type == "kpi" else "tbl", Rect2(6, 8, 40, 12), 22)
		UI.label(self, p.title, Rect2(60, y + 4, 90, 12), 22)
		UI.label(self, p.type, Rect2(60, y + 18, 90, 12), 7)
		var attached: bool = session.attached.has(p.id)
		var b := UI.button(self, texts.mail.detach if attached else texts.mail.attach, Rect2(152, y + 8, 54, 20), p.title)
		b.name = "Attach_" + str(p.id)
		b.disabled = locked
		b.pressed.connect(func():
			if attached: session.detach(p.id)
			else: session.attach(p.id)
			_rebuild())
		attach_buttons[p.id] = b
	message_label = UI.label(self, session.message, Rect2(6, 198, 204, 24), 26)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _rebuild() -> void:
	UI.clear(self)
	attach_buttons.clear()
	finding_pickers.clear()
	build(session, texts, locked)
	edited.emit()

func _statement(id: String) -> String:
	match id:
		"metric_change": return texts.mail.metric
		"spike_error": return texts.mail.spike
		"biggest_dropoff": return texts.mail.dropoff
		"top_category": return texts.mail.topcat
		"ab_significant": return texts.mail.ab_sig
		"ab_winner": return texts.mail.ab_win
	return id

func _label_of(value: Variant) -> String:
	if value is bool: return texts.mail.yes if value else texts.mail.no
	return str(value)

func _build_findings() -> void:
	UI.label(self, texts.mail.findings, Rect2(218, 22, 214, 12), 7)
	if session.files.is_empty():
		UI.label(self, texts.mail.no_files, Rect2(218, 38, 200, 12), 6)
		return
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(216, 36)
	scroll.size = Vector2(216, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var holder := Control.new()
	scroll.add_child(holder)
	var y := 0
	for f in session.files:
		UI.label(holder, texts.mail.file_head % f.title, Rect2(0, y, 200, 12), 28)
		y += 14
		for option in session.options(f.id):
			var fid: String = f.id
			var oid: String = option.id
			UI.wrapped(holder, _statement(oid), Rect2(0, y, 200, 22), 22, 2)
			y += 22
			if oid == "metric_change":
				var current: Variant = session.finding(fid, oid)
				var dirs: Array = [""] + option.directions
				var dir_labels: Array = [texts.mail.unset] + option.directions.map(func(d): return texts.mail.dir[d])
				var dir_pick := UI.picker(holder, self, Rect2(0, y, 70, 14), dirs, current.direction if current is Dictionary else "", dir_labels)
				dir_pick.name = "Dir_" + fid
				dir_pick.disabled = locked
				var band_pick := UI.picker(holder, self, Rect2(74, y, 120, 14), option.bands, current.band if current is Dictionary else option.bands[4], option.bands.map(func(b): return b + " %"))
				band_pick.name = "Band_" + fid
				band_pick.disabled = locked
				var apply := func(_v):
					if dir_pick.value == "": session.set_finding(fid, oid, null)
					else: session.set_finding(fid, oid, {"direction":dir_pick.value, "band":band_pick.value})
					edited.emit()
				dir_pick.picked.connect(apply)
				band_pick.picked.connect(apply)
				finding_pickers[fid + "|" + oid] = dir_pick
			else:
				var choices: Array = option.choices
				var items: Array = ["__unset"] + choices
				var names: Array = [texts.mail.unset] + choices.map(func(c): return _label_of(c))
				var current_value: Variant = session.finding(fid, oid)
				var pick := UI.picker(holder, self, Rect2(0, y, 194, 14), items, current_value if current_value != null else "__unset", names)
				pick.name = "Pick_" + fid + "_" + oid
				pick.disabled = locked
				pick.picked.connect(func(v):
					session.set_finding(fid, oid, null if str(v) == "__unset" and v is String else v)
					edited.emit())
				finding_pickers[fid + "|" + oid] = pick
			y += 18
		y += 4
	holder.custom_minimum_size = Vector2(200, y)

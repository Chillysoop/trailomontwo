class_name SaveSlots
extends Control
## The save picker on the title screen: 3 save slots and the hardcore slot. Each shows the
## caravan in it (crossing, day, where, team with levels) with Continue / New / Delete.
## New over a used slot and Delete both ask once more before wiping it.
##
##   SaveSlots.open(parent)

signal closed

const SCREEN := Vector2(640, 360)
const PIC := 20.0
const EXPEDITION := "res://scenes/expedition.tscn"
const HARDCORE_COL := "ff8a7a"

var _col: VBoxContainer
## The slot and action ("new" / "delete") waiting for a second press.
var _confirm := ""


static func open(parent: Node) -> SaveSlots:
	var s := SaveSlots.new()
	parent.add_child(s)
	return s


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.78)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.size = SCREEN
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97))
	box.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 5)
	panel.add_child(_col)
	refresh()


func refresh() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	var head := HBoxContainer.new()
	var title := PreviewHud.label("Choose a save", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var back := Ui.button("Back", 9)
	back.pressed.connect(close)
	head.add_child(back)
	_col.add_child(head)
	var first: Button
	for slot in SaveGame.all_slots():
		var b := _row(slot)
		if first == null:
			first = b
	if first != null:
		first.grab_focus.call_deferred()


func close() -> void:
	closed.emit()
	queue_free()


func _row(slot: String) -> Button:
	var hard := SaveGame.is_hardcore(slot)
	var panel := PanelContainer.new()
	var box := PreviewHud.box(Color(0.20, 0.12, 0.14, 0.95) if hard else Color(0.18, 0.14, 0.20, 0.95))
	box.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", box)
	_col.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name := PreviewHud.label("Hardcore" if hard else "Save %s" % slot.trim_prefix("slot"), 11)
	if hard:
		name.add_theme_color_override("font_color", Color(HARDCORE_COL))
	info.add_child(name)

	var s := SaveGame.summary(slot) if SaveGame.exists(slot) else {}
	var used := not s.is_empty() and not s.has("error")
	if used:
		var where := "At %s" % TestRoute.junction_name(s["at"])
		match int(s["state"]):
			Expedition.State.TRAVELLING: where = "On the road from %s" % TestRoute.junction_name(s["at"])
			Expedition.State.ARRIVED: where = "Reached Westwatch"
			Expedition.State.FAILED: where = "Crossing failed"
		info.add_child(PreviewHud.label("Crossing %d   Day %d   %s" % [s["crossing_no"], s["day"], where], 8))
		info.add_child(_team(s["roster"], s["levels"]))
	elif s.has("error"):
		var l := PreviewHud.label(String(s["error"]), 8)
		l.add_theme_color_override("font_color", Color(HARDCORE_COL))
		info.add_child(l)
	else:
		var l := PreviewHud.label("One life. Autosaves, can't be reloaded, and is erased if a crossing fails." if hard else "Empty", 8)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(250, 0)
		l.add_theme_color_override("font_color", Color("c8bca8"))
		info.add_child(l)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 2)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(buttons)
	var main: Button
	if used:
		main = _small("Continue", buttons)
		main.pressed.connect(_continue.bind(slot))
	var exists := SaveGame.exists(slot)
	var new := _small("Overwrite?" if _confirm == slot + ":new" else ("New caravan" if not exists else "New"), buttons)
	new.pressed.connect(_new.bind(slot))
	if main == null:
		main = new
	if exists:
		var del := _small("Erase?" if _confirm == slot + ":delete" else "Delete", buttons)
		del.pressed.connect(_delete.bind(slot))
	return main


func _team(roster: Array, levels: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	for i in roster.size():
		var id := String(roster[i])
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		var pic := TextureRect.new()
		pic.texture = load("res://assets/creatures/%s.png" % id)
		pic.custom_minimum_size = Vector2(PIC, PIC)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.tooltip_text = Species.info(id)["name"]
		cell.add_child(pic)
		var lv := PreviewHud.label("Lv %d" % int(levels[i]) if i < levels.size() else "", 7)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(lv)
		h.add_child(cell)
	return h


func _small(text: String, parent: Node) -> Button:
	var b := Ui.button(text, 8)
	b.custom_minimum_size = Vector2(78, 0)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(b)
	return b


func _continue(slot: String) -> void:
	var r := SaveGame.read(slot)
	if r.has("error"):
		refresh()
		return
	_play(slot, r)


func _new(slot: String) -> void:
	if SaveGame.exists(slot) and _confirm != slot + ":new":
		_confirm = slot + ":new"
		refresh()
		return
	SaveGame.delete(slot)
	_play(slot, {})


func _delete(slot: String) -> void:
	if _confirm != slot + ":delete":
		_confirm = slot + ":delete"
		refresh()
		return
	_confirm = ""
	SaveGame.delete(slot)
	refresh()


func _play(slot: String, loaded: Dictionary) -> void:
	SaveGame.current_slot = slot
	SaveGame.pending = loaded
	if is_inside_tree():
		get_tree().change_scene_to_file(EXPEDITION)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

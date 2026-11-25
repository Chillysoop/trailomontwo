class_name ItemSlots
extends HBoxContainer
## The 3 battle item slots shown before a fight. Click a slot to choose an item (or empty it).
##
##   var s := ItemSlots.new(); s.crossing = e; parent.add_child(s)

signal changed

const SLOT := Vector2(22, 22)

var crossing: Expedition
var _picker: Control


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	refresh()


func refresh() -> void:
	for c in get_children():
		c.queue_free()
	if crossing == null:
		return
	var head := Rich.label("{ik:battle_items}", 8)
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(head)
	for i in BattleItems.SLOTS:
		add_child(_slot(i))
	var owned := 0
	for id in crossing.items:
		owned += crossing.item_count(id)
	var bag := Rich.label("[color=#%s]%d in bag[/color]" % [CreatureCard.MUTED, owned], 7)
	bag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(bag)


func _slot(i: int) -> Control:
	var id: String = crossing.item_slots[i]
	var b := Button.new()
	b.custom_minimum_size = SLOT
	b.focus_mode = Control.FOCUS_NONE
	b.icon = Rich.icon_tex(id if id != "" else "item_slot")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 16)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if id == "":
		b.modulate = Color(1, 1, 1, 0.55)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.17, 0.25, 0.95) if state == "hover" else Color(0.10, 0.08, 0.12, 0.95)
		sb.border_color = Color("e8d6a8") if id != "" else Color("e8d6a8").darkened(0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(_open_picker.bind(i, b))
	Tips.attach(b, func():
		if id == "":
			return "{i:item_slot} [b]Empty item slot[/b]\nClick to choose a battle item for this fight."
		return BattleItems.tip(id, crossing.item_count(id)) + "\n[color=#ffe3a3]Click to change.[/color]")
	return b


## A small list of owned items under the slot. Clicking outside closes it.
func _open_picker(i: int, anchor: Control) -> void:
	_close_picker()
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.size = get_viewport_rect().size
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_picker())
	var panel := PanelContainer.new()
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97))
	box.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", box)
	layer.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	var ids: Array = crossing.items.keys()
	ids.sort()
	for id in ids:
		var free := crossing.item_free(id) + (1 if crossing.item_slots[i] == id else 0)
		var row := Ui.button("%s  x%d" % [BattleItems.item_name(id), free], 8)
		row.icon = Rich.icon_tex(id)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.focus_mode = Control.FOCUS_NONE
		row.disabled = free <= 0
		row.pressed.connect(_choose.bind(i, id))
		Tips.attach(row, func(): return BattleItems.tip(id, crossing.item_count(id)))
		col.add_child(row)
	if ids.is_empty():
		col.add_child(Rich.label("[color=#%s]No battle items yet. Wins sometimes drop them.[/color]" % CreatureCard.MUTED, 8, 160))
	if crossing.item_slots[i] != "":
		var clear := Ui.button("Empty this slot", 8)
		clear.focus_mode = Control.FOCUS_NONE
		clear.pressed.connect(_choose.bind(i, ""))
		col.add_child(clear)
	var host := get_parent()
	while host != null and not (host is CanvasLayer):
		host = host.get_parent()
	(host if host != null else self).add_child(layer)
	_picker = layer
	panel.position = anchor.get_global_rect().position + Vector2(0, SLOT.y + 2)
	panel.reset_size()
	# Keep it on screen.
	var vp := get_viewport_rect().size
	await get_tree().process_frame
	if is_instance_valid(panel):
		panel.position.x = minf(panel.position.x, vp.x - panel.size.x - 4)
		panel.position.y = minf(panel.position.y, vp.y - panel.size.y - 4)


func _choose(i: int, id: String) -> void:
	crossing.set_item_slot(i, id)
	_close_picker()
	Tips.hide_from(null)
	refresh()
	changed.emit()


func _close_picker() -> void:
	if _picker != null and is_instance_valid(_picker):
		_picker.queue_free()
	_picker = null


func _exit_tree() -> void:
	_close_picker()

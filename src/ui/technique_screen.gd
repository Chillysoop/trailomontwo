class_name TechniqueScreen
extends Control
## Techniques: one-use items that teach a move. A technique can be learned by a Trailomon of
## the same habitat as the move's species. Pick a technique, then who learns it, then whether
## it replaces the equipped move or the memory slot.
##
##   TechniqueScreen.open(parent, crossing)

signal closed

const SCREEN := Vector2(640, 360)
const PANEL := Vector2(610, 0)
const LIST_W := 196.0
const TILE := Vector2(180, 70)
const REPLACE_COL := "ff9a4d"
const PIC := 24.0

var crossing: Expedition
var _col: VBoxContainer
var _move := ""
var _learner := ""
var _done := ""
var _sheets: CompanionsScreen


static func open(parent: Node, e: Expedition) -> TechniqueScreen:
	var s := TechniqueScreen.new()
	s.crossing = e
	parent.add_child(s)
	return s


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sheets = CompanionsScreen.new()
	_sheets.crossing = crossing
	_sheets.on_swap = refresh
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.82)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.size = SCREEN
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97))
	box.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 6)
	panel.add_child(_col)
	refresh()


func _exit_tree() -> void:
	if _sheets != null:
		_sheets.free()
		_sheets = null


func refresh() -> void:
	for c in _col.get_children():
		c.queue_free()
	if _move != "" and crossing.technique_count(_move) <= 0:
		_move = ""
		_learner = ""
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_col.add_child(head)
	var title := Rich.label("[font_size=11][b]{i:technique} Techniques[/b][/font_size]", 8)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Ui.button("Close (Esc)", 8)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_screen)
	head.add_child(close)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	_col.add_child(body)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	left.custom_minimum_size = Vector2(LIST_W, 0)
	body.add_child(left)
	left.add_child(_heading("1. Pick a technique"))
	var ids: Array = crossing.techniques.keys()
	ids.sort()
	for mid in ids:
		left.add_child(_technique_button(mid))
	if ids.is_empty():
		left.add_child(Rich.label("[color=#%s]No techniques yet. Wins sometimes drop them, and the guardian always does.[/color]" % CreatureCard.MUTED, 8, LIST_W))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	body.add_child(right)
	if _move != "":
		right.add_child(_heading("2. Who learns it?"))
		right.add_child(_learners())
		if _learner != "":
			var slot: String = CombatData.move(_move)["slot"]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			right.add_child(row)
			var card := _sheets._card(_learner, slot)
			card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(card)
			var tiles := VBoxContainer.new()
			tiles.add_theme_constant_override("separation", 4)
			row.add_child(tiles)
			tiles.add_child(_heading("3. Choose what it replaces"))
			tiles.add_child(_target(slot, "equipped"))
			tiles.add_child(_target(slot, "memory"))
	if _done != "":
		_col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, _done], 8, PANEL.x - 16))


func _heading(text: String) -> Control:
	return Rich.label("[color=#e8d6a8]%s[/color]" % text.to_upper(), 7)


func _technique_button(mid: String) -> Control:
	var owner := MovePool.owner_of(mid)
	var habitat := Glossary.habitat_id(Species.info(owner)["type"])
	var b := Button.new()
	b.custom_minimum_size = Vector2(LIST_W, 30)
	b.focus_mode = Control.FOCUS_NONE
	var chosen := mid == _move
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.17, 0.25, 0.95) if state == "hover" or chosen else Color(0.17, 0.13, 0.19, 0.95)
		sb.border_color = Color("e8d6a8") if chosen else Color("e8d6a8").darkened(0.4)
		sb.set_border_width_all(2 if chosen else 1)
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override(state, sb)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var text := Rich.label("%s  [color=#%s]x%d[/color]\n[color=#%s]{i:%s} %s habitat[/color]" % [
		CreatureCard.move_header(mid, true), CreatureCard.MUTED, crossing.technique_count(mid),
		CreatureCard.MUTED, habitat, Species.info(owner)["type"]], 8)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("line_separation", 0)
	margin.add_child(text)
	b.pressed.connect(func():
		_move = mid
		_learner = ""
		refresh())
	Tips.attach(b, func(): return "%s\n[color=#%s]%s[/color]\n[color=#%s]Teaches this move once, to a %s Trailomon.[/color]" % [
		CreatureCard.move_header(mid, true), CreatureCard.SOFT, CombatData.describe(mid, 30, 20, 400), CreatureCard.MUTED, Species.info(owner)["type"]])
	return b


## Portraits of the team: the ones who can learn it are clickable.
func _learners() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var any := false
	for id in crossing.roster:
		var ok := crossing.can_learn_technique(id, _move)
		any = any or ok
		var b := Button.new()
		b.custom_minimum_size = Vector2(PIC + 8, PIC + 8)
		b.focus_mode = Control.FOCUS_NONE
		b.icon = CompanionsScreen.portrait(id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.disabled = not ok
		if not ok:
			b.modulate = Color(1, 1, 1, 0.3)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb := StyleBoxFlat.new()
			var chosen := id == _learner
			sb.bg_color = Color(0.22, 0.17, 0.25, 0.95) if state == "hover" or chosen else Color(0.12, 0.09, 0.14, 0.95)
			sb.border_color = Color("e8d6a8") if chosen else Color("e8d6a8").darkened(0.45)
			sb.set_border_width_all(2 if chosen else 1)
			sb.set_corner_radius_all(3)
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func():
			_learner = id
			refresh())
		var info := Species.info(id)
		Tips.attach(b, func():
			if ok:
				return "[b]%s[/b] can learn it." % info["name"]
			var slot: String = CombatData.move(_move)["slot"]
			if crossing.kit_move(id, slot) == _move or crossing.memory_move(id, slot) == _move:
				return "[b]%s[/b] already has this move." % info["name"]
			return "[b]%s[/b] can't learn it: only %s Trailomon can." % [info["name"], Species.info(MovePool.owner_of(_move))["type"]])
		row.add_child(b)
	if not any:
		row.add_child(Rich.label("[color=#%s]Nobody on the team can learn this one.[/color]" % CreatureCard.MUTED, 8))
	return row


## Equipped or memory: click to put the technique's move there.
func _target(slot: String, where: String) -> Control:
	var mid := crossing.kit_move(_learner, slot) if where == "equipped" else crossing.memory_move(_learner, slot)
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	var hot_sb := func(hot: bool) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.24, 0.15, 0.14, 0.95) if hot else Color(0.15, 0.11, 0.16, 0.95)
		sb.border_color = Color(REPLACE_COL)
		sb.set_border_width_all(3 if hot else 2)
		sb.set_corner_radius_all(3)
		return sb
	for state in ["normal", "focus"]:
		b.add_theme_stylebox_override(state, hot_sb.call(false))
	for state in ["hover", "pressed"]:
		b.add_theme_stylebox_override(state, hot_sb.call(true))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var label := "EQUIPPED" if where == "equipped" else "{i:memory} MEMORY"
	var text := "[color=#e8d6a8][b]%s[/b][/color]  [color=#%s]click to replace[/color]\n" % [label, REPLACE_COL]
	if mid == "":
		text += "[color=#%s]Empty[/color]" % CreatureCard.MUTED
	else:
		text += CreatureCard.move_header(mid, true) + "\n[i][color=#%s]%s[/color][/i]" % [CreatureCard.MUTED,
			CombatData.describe_short(mid, crossing.stat(_learner, "atk"), crossing.stat(_learner, "def"), crossing.max_hp(_learner))]
	var t := Rich.label(text, 8, TILE.x - 10)
	t.add_theme_font_size_override("italics_font_size", 7)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(t)
	b.pressed.connect(func():
		var line := crossing.use_technique(_learner, _move, where == "memory")
		if line != "":
			crossing.journal.append(line)
			_done = line
		_learner = ""
		Tips.hide_from(null)
		refresh())
	var new_name: String = CombatData.move(_move)["name"]
	Tips.attach(b, func():
		var equipped: String = CombatData.move(crossing.kit_move(_learner, slot))["name"]
		var stored := crossing.memory_move(_learner, slot)
		if where == "memory":
			return "%s goes into {i:memory} memory%s. %s stays equipped." % [new_name,
				"" if stored == "" else ", forgetting " + String(CombatData.move(stored)["name"]), equipped]
		if stored == "":
			return "%s is equipped. %s moves to the empty {i:memory} memory slot." % [new_name, equipped]
		return "%s replaces %s, which is forgotten. Memory keeps %s." % [new_name, equipped, CombatData.move(stored)["name"]])
	return b


func close_screen() -> void:
	if is_queued_for_deletion():
		return
	Tips.hide_from(null)
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_screen()

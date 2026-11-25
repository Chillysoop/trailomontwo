class_name LevelUpScreen
extends Control
## Choose a level-up, laid out as a small character sheet.
##
## Left: the Trailomon's sheet (stats, the three equipped moves and their memory slots), so
## every pick is made with the whole creature in view.
## Right, for a new move: the move equipped now in its own "Current" tile, marked as the one
## your pick replaces, then the two options (one from each archetype). After picking, choose
## to equip it now (the current move goes to memory) or keep the new move in memory.
## Right, for stats: the two rarity-rolled options, each showing current -> after.
##
##   LevelUpScreen.open(parent, crossing)

signal closed

const SCREEN := Vector2(640, 360)
const PANEL := Vector2(600, 0)
const SIDE := 372.0
const OPTION := Vector2(182, 112)
const REPLACE_COL := "ff9a4d"

var crossing: Expedition
var _col: VBoxContainer
var _picked := -1
var _done: Array[String] = []
## Borrowed to build the character sheet (not added to the tree).
var _sheets: CompanionsScreen
var _current_tile: PanelContainer
var _current_tag: RichTextLabel


static func open(parent: Node, e: Expedition) -> LevelUpScreen:
	var s := LevelUpScreen.new()
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
	_current_tile = null
	_current_tag = null
	if crossing.pending_levels.is_empty():
		close_screen()
		return
	var p: Dictionary = crossing.pending_levels[0]
	var id: String = p["id"]
	var info := Species.info(id)
	var is_move: bool = p["options"][0]["kind"] == "move"

	# Header.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_col.add_child(head)
	var title := Rich.label("[font_size=11][b]%s reached Lv %d![/b][/font_size]" % [info["name"], p["level"]], 8)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if crossing.pending_count() > 1:
		head.add_child(Rich.label("[color=#%s]1 of %d[/color]" % [CreatureCard.MUTED, crossing.pending_count()], 8))
	var later := Ui.button("Later (Esc)", 8)
	later.focus_mode = Control.FOCUS_NONE
	later.pressed.connect(close_screen)
	Tips.attach(later, func(): return "Close for now. Waiting level-ups stay on the Companions screen.")
	head.add_child(later)

	# Body: character sheet on the left, choices on the right.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	_col.add_child(body)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	body.add_child(left)
	left.add_child(_heading("Character sheet"))
	var slot := ""
	if is_move:
		slot = CombatData.move(p["options"][0]["move"])["slot"]
	left.add_child(_sheets._card(id, slot))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.custom_minimum_size = Vector2(SIDE, 0)
	body.add_child(right)
	if is_move:
		right.add_child(_heading("Current %s" % Glossary.entry_name(slot).to_lower()))
		right.add_child(_current(id, slot))
		right.add_child(_heading("Pick one to replace it"))
	else:
		right.add_child(_heading("Pick one"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	right.add_child(row)
	for i in p["options"].size():
		row.add_child(_option(id, p["options"][i], i))
	if _picked >= 0:
		right.add_child(_memory_choice(id, p["options"][_picked]))
	if not _done.is_empty():
		_col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, _done[-1]], 8, PANEL.x - 16))
	_show_replaced()


func _heading(text: String) -> Control:
	return Rich.label("[color=#e8d6a8]%s[/color]" % text.to_upper(), 7)


## The move equipped now, in its own tile. It says plainly that the pick replaces it.
func _current(id: String, slot: String) -> Control:
	var mid := crossing.kit_move(id, slot)
	var t := PanelContainer.new()
	t.custom_minimum_size = Vector2(SIDE, 0)
	_current_tile = t
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	t.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	var name := Rich.label(CreatureCard.move_header(mid, true), 8)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	_current_tag = Rich.label("", 7)
	top.add_child(_current_tag)
	col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.SOFT,
		CombatData.describe(mid, crossing.stat(id, "atk"), crossing.stat(id, "def"), crossing.max_hp(id))], 8, SIDE - 12))
	var stored := crossing.memory_move(id, slot)
	var mem := "{i:memory} Memory: " + ("empty" if stored == "" else String(CombatData.move(stored)["name"]))
	col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, mem], 7))
	return t


## Marks the current tile: who replaces it (hovered or picked option), or just a warning.
func _show_replaced(hover := -1) -> void:
	if _current_tile == null:
		return
	var which := hover if hover >= 0 else _picked
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.12, 0.13, 0.95)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(6)
	if which >= 0:
		var mid: String = crossing.pending_levels[0]["options"][which]["move"]
		sb.border_color = Color(REPLACE_COL)
		sb.set_border_width_all(2)
		Rich.set_text(_current_tag, "[color=#%s][b]REPLACED BY %s[/b][/color]" % [REPLACE_COL, String(CombatData.move(mid)["name"]).to_upper()])
	else:
		sb.border_color = Color(REPLACE_COL).darkened(0.35)
		sb.set_border_width_all(1)
		Rich.set_text(_current_tag, "[color=#%s]EQUIPPED NOW[/color]" % REPLACE_COL)
	_current_tile.add_theme_stylebox_override("panel", sb)


func _option(id: String, o: Dictionary, index: int) -> Control:
	var b := Button.new()
	b.custom_minimum_size = OPTION if o["kind"] == "move" else Vector2(OPTION.x, 72)
	b.focus_mode = Control.FOCUS_NONE
	var edge := Color("e8d6a8")
	if o["kind"] == "stat":
		edge = Color(Leveling.RARITY_COLORS[o["rarity"]])
	var chosen := index == _picked
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.17, 0.25, 0.95) if state == "hover" or chosen else Color(0.17, 0.13, 0.19, 0.95)
		sb.border_color = edge
		sb.set_border_width_all(3 if chosen else (2 if state == "hover" else 1))
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override(state, sb)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var text := Rich.label(_option_text(id, o), 8, OPTION.x - 12)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("line_separation", 2)
	margin.add_child(text)
	b.pressed.connect(_pick.bind(index))
	if o["kind"] == "move":
		b.mouse_entered.connect(_show_replaced.bind(index))
		b.mouse_exited.connect(_show_replaced)
	return b


func _option_text(id: String, o: Dictionary) -> String:
	if o["kind"] == "stat":
		var stat: String = o["stat"]
		var col: String = Leveling.RARITY_COLORS[o["rarity"]]
		var before := crossing.max_hp(id) if stat == "hp" else crossing.stat(id, stat)
		var after := before - float(o["amount"]) if stat == "spd" else before + float(o["amount"])
		var fmt := "%.2fs" if stat == "spd" else "%d"
		return "[font_size=10][b][color=#%s]%s[/color][/b][/font_size]\n{i:%s} [font_size=11][b]%s[/b][/font_size]\n[color=#%s]Current %s -> [/color][b]%s[/b]" % [
			col, Leveling.RARITY_NAMES[o["rarity"]].to_upper(), stat, Leveling.boost_text(stat, o["amount"]),
			CreatureCard.MUTED, fmt % before, fmt % after]
	var mid: String = o["move"]
	var slot: String = CombatData.move(mid)["slot"]
	var arc: Dictionary = MovePool.ARCHETYPES[id][MovePool.archetype_of(id, mid)]
	var current: String = CombatData.move(crossing.kit_move(id, slot))["name"]
	var text := "[color=#e8d6a8]%s[/color]  [color=#%s]%s[/color]\n" % [String(arc["name"]).to_upper(), CreatureCard.MUTED, arc["line"]]
	text += CreatureCard.move_header(mid, true) + "\n"
	text += "[color=#%s]%s[/color]\n" % [CreatureCard.SOFT, CombatData.describe(mid, crossing.stat(id, "atk"), crossing.stat(id, "def"), crossing.max_hp(id))]
	text += "[color=#%s]Replaces %s[/color]" % [REPLACE_COL, current]
	return text


func _pick(index: int) -> void:
	var o: Dictionary = crossing.pending_levels[0]["options"][index]
	if o["kind"] == "stat":
		_finish(index, false)
		return
	_picked = index
	refresh()


## After picking a move: equip it now (the current one goes to memory) or keep it in memory.
func _memory_choice(id: String, o: Dictionary) -> Control:
	var mid: String = o["move"]
	var new_name: String = CombatData.move(mid)["name"]
	var slot: String = CombatData.move(mid)["slot"]
	var current: String = CombatData.move(crossing.kit_move(id, slot))["name"]
	var stored := crossing.memory_move(id, slot)
	var lost := "" if stored == "" else "\n[color=#%s]%s is forgotten from memory.[/color]" % [REPLACE_COL, CombatData.move(stored)["name"]]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var now := Ui.button("Equip %s" % new_name, 8)
	now.focus_mode = Control.FOCUS_NONE
	now.pressed.connect(_finish.bind(_picked, false))
	Tips.attach(now, func(): return "%s replaces %s. %s goes into the {i:memory} memory slot, so you can swap it back between battles.%s" % [new_name, current, current, lost])
	row.add_child(now)
	var keep := Ui.button("Put %s in memory" % new_name, 8)
	keep.focus_mode = Control.FOCUS_NONE
	keep.pressed.connect(_finish.bind(_picked, true))
	Tips.attach(keep, func(): return "Keep %s equipped. %s waits in the {i:memory} memory slot; swap it in from the Companions screen.%s" % [current, new_name, lost])
	row.add_child(keep)
	return row


func _finish(index: int, keep_in_memory: bool) -> void:
	var line := crossing.choose_level_up(index, keep_in_memory)
	crossing.journal.append(line)
	_done.append(line)
	_picked = -1
	Tips.hide_from(null)
	refresh()


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

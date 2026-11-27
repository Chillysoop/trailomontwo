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
const OPTION := Vector2(182, 120)
const REPLACE_COL := "ff9a4d"

var crossing: Expedition
var _col: VBoxContainer
var _picked := -1
var _done: Array[String] = []
## Borrowed to build the character sheet (not added to the tree).
var _sheets: CompanionsScreen
## The "equipped" and "memory" tiles and their labels.
var _targets := {}
var _target_tags := {}


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
	# The slot the picked move goes in (options can be for different slots).
	var slot := ""
	if is_move and _picked >= 0:
		slot = CombatData.move(p["options"][_picked]["move"])["slot"]
	left.add_child(_sheets._card(id, slot))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.custom_minimum_size = Vector2(SIDE, 0)
	body.add_child(right)
	right.add_child(_heading("1. Pick a new move" if is_move else "Pick one"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	right.add_child(row)
	for i in p["options"].size():
		row.add_child(_option(id, p["options"][i], i))
	if is_move and _picked >= 0:
		right.add_child(_heading("2. Choose what it replaces"))
		var targets := HBoxContainer.new()
		targets.add_theme_constant_override("separation", 8)
		right.add_child(targets)
		_targets.clear()
		_target_tags.clear()
		for where in ["equipped", "memory"]:
			targets.add_child(_target(id, slot, where))
	if not _done.is_empty():
		_col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, _done[-1]], 8, PANEL.x - 16))
	_style_targets()


func _heading(text: String) -> Control:
	return Rich.label("[color=#e8d6a8]%s[/color]" % text.to_upper(), 7)


## A tile for the equipped move or the memory slot. Once a new move is picked, click a tile
## to put the new move there.
func _target(id: String, slot: String, where: String) -> Control:
	var mid := crossing.kit_move(id, slot) if where == "equipped" else crossing.memory_move(id, slot)
	var b := Button.new()
	b.custom_minimum_size = Vector2(OPTION.x, 74)
	b.focus_mode = Control.FOCUS_NONE
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)
	var tag := Rich.label("", 7)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(tag)
	var text := ""
	if mid == "":
		text = "[color=#%s]Empty[/color]" % CreatureCard.MUTED
	else:
		text = CreatureCard.move_header(mid, true) + "\n[color=#%s]%s[/color]" % [CreatureCard.SOFT,
			CombatData.describe(mid, crossing.stat(id, "atk"), crossing.stat(id, "def"), crossing.max_hp(id))]
	var body := Rich.label(text, 8, OPTION.x - 12)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(body)
	b.pressed.connect(func():
		if _picked >= 0:
			_finish(_picked, where == "memory"))
	b.mouse_entered.connect(_style_targets.bind(where))
	b.mouse_exited.connect(_style_targets)
	Tips.attach(b, func(): return _target_tip(id, slot, where))
	_targets[where] = b
	_target_tags[where] = tag
	return b


func _target_tip(id: String, slot: String, where: String) -> String:
	if _picked < 0:
		return "Pick a new move above first."
	var new_name: String = CombatData.move(crossing.pending_levels[0]["options"][_picked]["move"])["name"]
	var equipped: String = CombatData.move(crossing.kit_move(id, slot))["name"]
	var stored := crossing.memory_move(id, slot)
	if where == "memory":
		if stored == "":
			return "%s goes into the {i:memory} memory slot. %s stays equipped." % [new_name, equipped]
		return "%s replaces %s in {i:memory} memory. %s is forgotten. %s stays equipped." % [new_name, CombatData.move(stored)["name"], CombatData.move(stored)["name"], equipped]
	if stored == "":
		return "%s is equipped. %s moves to the empty {i:memory} memory slot." % [new_name, equipped]
	return "%s replaces %s, which is forgotten. Memory keeps %s." % [new_name, equipped, CombatData.move(stored)["name"]]


## Borders and labels on the two tiles: what each holds, and once a move is picked,
## which one it would replace.
func _style_targets(hover := "") -> void:
	var new_name := ""
	if _picked >= 0:
		new_name = String(CombatData.move(crossing.pending_levels[0]["options"][_picked]["move"])["name"]).to_upper()
	for where in _targets:
		if not is_instance_valid(_targets[where]) or not is_instance_valid(_target_tags.get(where)):
			continue
		var b: Button = _targets[where]
		var hot: bool = _picked >= 0 and where == hover
		var label := "EQUIPPED" if where == "equipped" else "{i:memory} MEMORY"
		var tag := "[color=#e8d6a8][b]%s[/b][/color]" % label
		if hot:
			tag = "[color=#%s][b]%s -> REPLACE WITH %s[/b][/color]" % [REPLACE_COL, label, new_name]
		elif _picked >= 0:
			tag += "  [color=#%s]click to replace[/color]" % REPLACE_COL
		Rich.set_text(_target_tags[where], tag)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.24, 0.15, 0.14, 0.95) if hot else (Color(0.12, 0.09, 0.14, 0.95) if where == "memory" else Color(0.17, 0.13, 0.19, 0.95))
			sb.border_color = Color(REPLACE_COL) if _picked >= 0 else Color("e8d6a8").darkened(0.4)
			sb.set_border_width_all(3 if hot else (2 if _picked >= 0 else 1))
			sb.set_corner_radius_all(3)
			b.add_theme_stylebox_override(state, sb)


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
	var arc: Dictionary = MovePool.archetypes(id)[MovePool.archetype_of(id, mid)]
	var text := "[color=#e8d6a8]%s[/color]  [color=#%s]%s[/color]\n" % [String(arc["name"]).to_upper(), CreatureCard.MUTED, arc["line"]]
	text += CreatureCard.move_header(mid, true) + "\n"
	text += "[color=#%s]%s[/color]" % [CreatureCard.SOFT, CombatData.describe(mid, crossing.stat(id, "atk"), crossing.stat(id, "def"), crossing.max_hp(id))]
	var stored := crossing.memory_move(id, slot)
	text += "\n[color=#%s]Equipped: %s\n{i:memory} Memory: %s[/color]" % [CreatureCard.MUTED, CombatData.move(crossing.kit_move(id, slot))["name"],
		"empty" if stored == "" else String(CombatData.move(stored)["name"])]
	return text


func _pick(index: int) -> void:
	var o: Dictionary = crossing.pending_levels[0]["options"][index]
	if o["kind"] == "stat":
		_finish(index, false)
		return
	_picked = index
	refresh()


func _finish(index: int, keep_in_memory: bool) -> void:
	Sound.sfx("level_up")
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

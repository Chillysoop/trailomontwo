class_name LevelUpScreen
extends Control
## Choose a level-up: pick one of two options for the oldest waiting level-up, then the next.
## Stat options show their rarity; move options show which archetype they come from, then
## ask whether to use the move now (the old one goes to memory) or keep it in memory.
##
##   LevelUpScreen.open(parent, crossing)

signal closed

const SCREEN := Vector2(640, 360)
const PANEL := Vector2(460, 0)
const OPTION := Vector2(218, 112)

var crossing: Expedition
var _col: VBoxContainer
var _picked := -1
var _done: Array[String] = []


static func open(parent: Node, e: Expedition) -> LevelUpScreen:
	var s := LevelUpScreen.new()
	s.crossing = e
	parent.add_child(s)
	return s


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
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


func refresh() -> void:
	for c in _col.get_children():
		c.queue_free()
	if crossing.pending_levels.is_empty():
		close_screen()
		return
	var p: Dictionary = crossing.pending_levels[0]
	var id: String = p["id"]
	var info := Species.info(id)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_col.add_child(head)
	var pic := TextureRect.new()
	pic.texture = CompanionsScreen.portrait(id)
	pic.custom_minimum_size = Vector2(28, 28)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head.add_child(pic)
	var is_move: bool = p["options"][0]["kind"] == "move"
	var title := Rich.label("[font_size=11][b]%s reached Lv %d![/b][/font_size]\n[color=#%s]%s[/color]" % [
		info["name"], p["level"], CreatureCard.MUTED,
		"A new move: one from each path. Pick one." if is_move else "Pick one upgrade."], 8)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if crossing.pending_count() > 1:
		head.add_child(Rich.label("[color=#%s]1 of %d[/color]" % [CreatureCard.MUTED, crossing.pending_count()], 8))
	var later := Ui.button("Later (Esc)", 8)
	later.focus_mode = Control.FOCUS_NONE
	later.pressed.connect(close_screen)
	Tips.attach(later, func(): return "Close for now. Waiting level-ups stay on the Companions screen.")
	head.add_child(later)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_col.add_child(row)
	for i in p["options"].size():
		row.add_child(_option(id, p["options"][i], i))

	if _picked >= 0:
		_col.add_child(_memory_choice(id, p["options"][_picked]))
	if not _done.is_empty():
		_col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, _done[-1]], 8, PANEL.x - 16))


func _option(id: String, o: Dictionary, index: int) -> Control:
	var b := Button.new()
	b.custom_minimum_size = OPTION if o["kind"] == "move" else Vector2(OPTION.x, 92)
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
		margin.add_theme_constant_override("margin_" + side, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var text := Rich.label(_option_text(id, o), 8, OPTION.x - 16)
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
		return "[font_size=10][b][color=#%s]%s[/color][/b][/font_size]\n{i:%s} [font_size=11][b]%s[/b][/font_size]\n[color=#%s]%s %s -> %s[/color]" % [
			col, Leveling.RARITY_NAMES[o["rarity"]].to_upper(), stat, Leveling.boost_text(stat, o["amount"]),
			CreatureCard.MUTED, Leveling.STAT_NAMES[stat], fmt % before, fmt % after]
	var mid: String = o["move"]
	var mv := CombatData.move(mid)
	var slot: String = mv["slot"]
	var arc: Dictionary = MovePool.ARCHETYPES[id][MovePool.archetype_of(id, mid)]
	var current := crossing.kit_move(id, slot)
	var text := "[color=#e8d6a8]%s[/color]  [color=#%s]%s[/color]\n" % [String(arc["name"]).to_upper(), CreatureCard.MUTED, arc["line"]]
	text += CreatureCard.move_header(mid, true) + "\n"
	text += "[color=#%s]%s[/color]\n" % [CreatureCard.SOFT, CombatData.describe(mid, crossing.stat(id, "atk"), crossing.stat(id, "def"), crossing.max_hp(id))]
	text += "[color=#%s]Instead of %s[/color]" % [CreatureCard.MUTED, CombatData.move(current)["name"]]
	return text


func _pick(index: int) -> void:
	var o: Dictionary = crossing.pending_levels[0]["options"][index]
	if o["kind"] == "stat":
		_finish(index, false)
		return
	_picked = index
	refresh()


## After picking a move: use it now or keep it in the slot's memory.
func _memory_choice(id: String, o: Dictionary) -> Control:
	var mid: String = o["move"]
	var slot: String = CombatData.move(mid)["slot"]
	var current: String = CombatData.move(crossing.kit_move(id, slot))["name"]
	var stored := crossing.memory_move(id, slot)
	var lost := "" if stored == "" else " %s is forgotten from memory." % CombatData.move(stored)["name"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var now := Ui.button("Use it now", 9)
	now.focus_mode = Control.FOCUS_NONE
	now.pressed.connect(_finish.bind(_picked, false))
	Tips.attach(now, func(): return "%s goes into the {i:memory} memory slot, so you can swap it back between battles.%s" % [current, lost])
	row.add_child(now)
	var keep := Ui.button("Keep it in memory", 9)
	keep.focus_mode = Control.FOCUS_NONE
	keep.pressed.connect(_finish.bind(_picked, true))
	Tips.attach(keep, func(): return "Keep using %s. The new move waits in the {i:memory} memory slot.%s" % [current, lost])
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

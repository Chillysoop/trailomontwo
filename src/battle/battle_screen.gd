class_name BattleScreen
extends Node2D
## A battle on the trail, in three phases:
## 1. Lineup: the 2x3 grids are shown. Click one of your creatures, then a cell, to move or
##    swap it. Click any creature to inspect it. Habitat synergies update as you arrange.
## 2. Combat: the grids hide and the fight plays out by itself. Pause, speed and retreat.
## 3. Aftermath: what the battle cost or won, then back to the trail.
##
## Practice mode (from the title screen) uses a fresh team at full health, lets you pick
## the foe, and never touches a real crossing.

signal finished(lines: Array)

enum Phase { LINEUP, COMBAT, AFTERMATH }

const SPEEDS := [1.0, 2.0, 4.0]
const GOOD := Color("9fe0a0")
const MID := Color("f0d27a")
const BAD := Color("ff8a7a")
const SHIELD := Color("bfe6ff")
const POISON := Color("a6e36b")

var crossing: Expedition
var ambush := false
var practice := false
var phase := Phase.LINEUP
var battle: Battle
var speed_index := 0
var paused := false

var _practice_pack := 0
var _selected := ""
var _inspect := {}
var _grid: GridView
var _units: Node2D
var _fx: Node2D
## Lineup sprites by cell key, and combat views by fighter uid.
var _views := {}
var _ui: CanvasLayer
var _info: Label
var _info_panel: PanelContainer
var _side_panel: PanelContainer
var _enc_title: Label
var _enc_text: Label
var _syn_mine: Label
var _syn_theirs: Label
var _fight: Button
var _bench_btn: Button
var _foe_btn: Button
var _combat_bar: PanelContainer
var _clock: Label
var _pause_btn: Button
var _speed_btn: Button
var _retreat_btn: Button
var _log: Label
var _log_lines: Array[String] = []
var _after: PanelContainer
var _after_title: Label
var _after_body: Label
var _after_buttons: HBoxContainer
var _result_lines: Array[String] = []


## Call before adding to the tree. For practice, pass a fresh Expedition and practice = true.
func setup(with_crossing: Expedition, was_ambushed := false, is_practice := false) -> void:
	crossing = with_crossing
	ambush = was_ambushed
	practice = is_practice
	if practice:
		crossing.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/backgrounds/battle/trail_forest.png")
	bg.centered = false
	add_child(bg)
	add_child(Stand.sprite(load("res://assets/wagon/wagon.png"), Formation.WAGON_FEET))
	_grid = GridView.new()
	_grid.screen = self
	add_child(_grid)
	_units = Node2D.new()
	_units.y_sort_enabled = true
	add_child(_units)
	_fx = Node2D.new()
	_fx.z_index = 10
	add_child(_fx)
	_build_ui()
	if crossing == null:
		setup(Expedition.new_default(), false, true)
	crossing.tidy_lineup()
	_enter_lineup()


func _pack() -> Dictionary:
	return crossing.pending_encounter.get("pack", CombatData.PACKS[0])


func _is_guardian() -> bool:
	return bool(crossing.pending_encounter.get("guardian", false))


# ---------- lineup ----------

func _enter_lineup() -> void:
	phase = Phase.LINEUP
	_grid.visible = true
	_side_panel.visible = true
	_info_panel.visible = true
	_combat_bar.visible = false
	_after.visible = false
	_log.text = "Ambushed! Your team will be slow to react." if ambush else "Click a creature, then a cell to move it. Click anyone to inspect."
	_refresh_lineup()
	_fight.grab_focus.call_deferred()


func _refresh_lineup() -> void:
	for c in _units.get_children():
		c.queue_free()
	for c in _fx.get_children():
		c.queue_free()
	_views.clear()
	for cell in crossing.lineup:
		var id: String = crossing.lineup[cell]
		var v := _add_unit(id, Formation.slot_feet(Formation.Side.PLAYER, cell.x, cell.y), false)
		if not crossing.conscious(id):
			v["sprite"].modulate = Color(0.45, 0.45, 0.5, 0.6)
		elif id == _selected:
			v["sprite"].modulate = Color(1.25, 1.2, 0.9)
		var bar: HpBar = v["bar"]
		bar.frac = float(crossing.creature_hp.get(id, 0.0)) / crossing.max_hp(id)
		bar.queue_redraw()
	var pack := _pack()
	var scale := float(crossing.pending_encounter.get("scale", 1.0))
	for row in [Formation.Row.FRONT, Formation.Row.BACK]:
		var ids: Array = pack["front" if row == Formation.Row.FRONT else "back"]
		for lane in ids.size():
			if String(ids[lane]) != "":
				_add_unit(ids[lane], Formation.slot_feet(Formation.Side.ENEMY, row, lane), true)
	if String(pack.get("boss", "")) != "":
		_add_unit(pack["boss"], Formation.BOSS_FEET, true)
	_enc_title.text = pack["title"] + ("  (ambush!)" if ambush else "")
	var strength := "weak" if scale < 1.0 else ("tough" if scale > 1.2 else ("strong" if scale > 1.05 else "ordinary"))
	_enc_text.text = "Foes look %s.%s" % [strength, " Boss is safe until its pack falls." if String(pack.get("boss", "")) != "" else ""]
	var mine: Array = []
	for cell in crossing.lineup:
		if crossing.conscious(crossing.lineup[cell]):
			mine.append(crossing.lineup[cell])
	var theirs: Array = []
	for id in pack["front"] + pack["back"]:
		if String(id) != "":
			theirs.append(id)
	if String(pack.get("boss", "")) != "":
		theirs.append(pack["boss"])
	_syn_mine.text = "Your habitat bonuses:\n" + ("\n".join(CombatData.synergy_lines(mine)) if not mine.is_empty() else "nobody can fight")
	var their_lines := CombatData.synergy_lines(theirs).filter(func(l): return not l.begins_with("Close"))
	_syn_theirs.text = "Theirs:\n" + ("\n".join(their_lines) if not their_lines.is_empty() else "none")
	_fight.disabled = mine.is_empty()
	_fight.text = "Fight!" if not mine.is_empty() else "Nobody can fight"
	_foe_btn.visible = practice
	_bench_btn.visible = _selected != "" and crossing.lineup_cell(_selected) != null
	_show_info()
	_grid.queue_redraw()


func _add_unit(id: String, feet: Vector2, enemy: bool) -> Dictionary:
	var holder := Node2D.new()
	holder.position = feet
	_units.add_child(holder)
	var shadow := Shadow.new()
	holder.add_child(shadow)
	var s := Stand.sprite(load("res://assets/creatures/%s.png" % id), Vector2.ZERO, enemy)
	holder.add_child(s)
	Stand.bob(s, 1, 1.0, randf() * 0.6)
	var bar := HpBar.new()
	bar.position = Vector2(-16, 4)
	bar.enemy = enemy
	holder.add_child(bar)
	var v := {"holder": holder, "sprite": s, "bar": bar, "home": feet}
	return v


func _show_info() -> void:
	var id: String = _inspect.get("id", "")
	if id == "":
		_info.text = "Click a creature to see what it does."
		return
	var s := CombatData.stats(id)
	var lines: Array[String] = []
	var scale := float(_inspect.get("scale", 1.0))
	var hp_line := ""
	if _inspect.get("mine", false):
		hp_line = "HP %d/%d" % [roundi(float(crossing.creature_hp.get(id, 0.0))), roundi(crossing.max_hp(id))]
		if crossing.fatigue.get(id, 0.0) > 0.0:
			hp_line += "  tired %d%%" % roundi(float(crossing.fatigue[id]))
	else:
		hp_line = "HP %d" % roundi(float(s["hp"]) * CombatData.HP_SCALE * scale)
	lines.append("%s  ·  %s %s  ·  %s" % [Species.info(id)["name"], CombatData.type_of(id), s["role"], hp_line])
	lines.append("Might %d  Spirit %d  Guard %d  Tempo %d" % [roundi(s["might"] * scale), roundi(s["spirit"] * scale), s["guard"], s["tempo"]])
	var t := CombatData.type_of(id)
	var chart: Array = CombatData.CHART.get(t, ["", ""])
	lines.append("Hits %s hard, weak against %s" % [chart[0], chart[1]])
	for a in s["abilities"]:
		var ab := CombatData.ability(a)
		lines.append("%s (%ds): %s" % [ab["name"], roundi(ab["cooldown"]), ab["desc"]])
	if _inspect.get("mine", false) and not crossing.conscious(id):
		lines.append("Knocked out. Rest a day at a stop to wake it.")
	_info.text = "\n".join(lines)


func _cell_at(p: Vector2, side: int) -> Variant:
	for row in [Formation.Row.FRONT, Formation.Row.BACK]:
		for lane in 3:
			if Formation.cell_rect(side, row, lane).has_point(p):
				return Vector2i(row, lane)
	return null


func _click_lineup(p: Vector2) -> void:
	var cell: Variant = _cell_at(p, Formation.Side.PLAYER)
	if cell != null:
		var there: String = crossing.lineup.get(cell, "")
		if _selected != "" and there != _selected:
			crossing.place_in_lineup(_selected, cell)
			_inspect = {"id": _selected, "mine": true}
			_selected = ""
		elif there != "":
			_selected = "" if there == _selected else there
			_inspect = {"id": there, "mine": true}
		else:
			_selected = ""
		_refresh_lineup()
		return
	var ecell: Variant = _cell_at(p, Formation.Side.ENEMY)
	var pack := _pack()
	var scale := float(crossing.pending_encounter.get("scale", 1.0))
	if ecell != null:
		var id: String = pack["front" if ecell.x == Formation.Row.FRONT else "back"][ecell.y]
		if id != "":
			_inspect = {"id": id, "mine": false, "scale": scale}
	elif String(pack.get("boss", "")) != "" and p.distance_to(Formation.BOSS_FEET + Vector2(0, -30)) < 40:
		_inspect = {"id": pack["boss"], "mine": false, "scale": scale}
	_selected = ""
	_refresh_lineup()


func _bench_selected() -> void:
	if _selected != "":
		crossing.remove_from_lineup(_selected)
		_selected = ""
		_refresh_lineup()


func _auto_arrange() -> void:
	crossing.auto_lineup()
	_selected = ""
	_refresh_lineup()


func _next_foe() -> void:
	var all: Array = CombatData.PACKS.duplicate()
	all.append(CombatData.GUARDIAN)
	_practice_pack = (_practice_pack + 1) % all.size()
	var pack: Dictionary = all[_practice_pack]
	crossing.pending_encounter = {"pack": pack, "scale": CombatData.GUARDIAN_SCALE if pack.has("boss") else 1.0, "guardian": pack.has("boss")}
	_inspect = {}
	_refresh_lineup()


# ---------- combat ----------

func _start_combat() -> void:
	if not crossing.can_fight():
		return
	battle = crossing.make_battle(ambush)
	phase = Phase.COMBAT
	_selected = ""
	_grid.visible = false
	_side_panel.visible = false
	_info_panel.visible = false
	_combat_bar.visible = true
	paused = false
	_retreat_btn.disabled = _is_guardian()
	_retreat_btn.tooltip_text = "There's no way around this one." if _is_guardian() else "Pull back after 3 seconds. Costs food and wagon wear."
	_log_lines.clear()
	_log.text = "The fight begins!"
	for c in _units.get_children():
		c.queue_free()
	_views.clear()
	for f in battle.fighters:
		var feet := Formation.BOSS_FEET if f.is_boss() else Formation.slot_feet(f.side, f.row, f.lane)
		var v := _add_unit(f.species, feet, f.side == Formation.Side.ENEMY)
		_views[f.uid] = v
		_update_bar(f)
	_refresh_combat_bar()


func _process(delta: float) -> void:
	if phase != Phase.COMBAT or battle == null:
		return
	if not paused:
		battle.advance(delta * SPEEDS[speed_index])
	_drain_events()
	_clock.text = "%ds%s" % [int(battle.time), "  tiring!" if battle.time >= Battle.FATIGUE_START else ""]
	if battle.retreating:
		_clock.text += "  retreating %.1fs" % maxf(0.0, battle.retreat_left)
	if battle.outcome != Battle.Outcome.ONGOING:
		_end_combat()


func _drain_events() -> void:
	var evs := battle.events
	battle.events = []
	for e in evs:
		var t: String = e["t"]
		match t:
			"attack":
				_lunge(e["src"], e["dst"])
			"cast":
				var f := battle.fighter(e["src"])
				_float(_view_pos(e["src"]) + Vector2(0, -72), e["label"], MID if e["kind"] in ["damage", "poison", "slow", "weaken"] else GOOD)
				if e["kind"] in ["damage", "slow", "poison", "weaken"]:
					_lunge(e["src"], e["dst"])
				_note("%s used %s" % [f.display_name(), e["label"]])
			"hit":
				var dst := battle.fighter(e["dst"])
				var col := Color.WHITE
				if float(e.get("matchup", 1.0)) > 1.0:
					col = Color("ffd36b")
				elif float(e.get("matchup", 1.0)) < 1.0:
					col = Color("b8b0c8")
				if e.get("label", "") == "Poison":
					col = POISON
				var amount := int(e["amount"])
				var absorbed := int(e.get("absorbed", 0))
				var txt := str(amount - absorbed) if absorbed < amount else "blocked"
				_float(_view_pos(e["dst"]) + Vector2(randf_range(-10, 10), -58), txt, SHIELD if absorbed >= amount else col)
				_flash(e["dst"])
				_update_bar(dst)
			"heal":
				_float(_view_pos(e["dst"]) + Vector2(0, -62), "+%d" % int(e["amount"]), GOOD)
				_update_bar(battle.fighter(e["dst"]))
			"shield":
				_update_bar(battle.fighter(e["dst"]))
			"status":
				if int(e["dst"]) != Battle.WAGON_UID:
					_update_bar(battle.fighter(e["dst"]))
			"ko":
				var f := battle.fighter(e["dst"])
				_knock_out(e["dst"])
				_note("%s%s is knocked out!" % ["Enemy " if f.side == Formation.Side.ENEMY else "Your ", f.display_name()])
			"wagon":
				_bolt(e["dst"])


func _view_pos(uid: int) -> Vector2:
	if uid == Battle.WAGON_UID or not _views.has(uid):
		return Formation.WAGON_FEET + Vector2(60, -110)
	return _views[uid]["home"]


func _lunge(src: int, dst: int) -> void:
	if not _views.has(src):
		return
	var holder: Node2D = _views[src]["holder"]
	var home: Vector2 = _views[src]["home"]
	var dir := signf(_view_pos(dst).x - home.x)
	var t := holder.create_tween()
	t.tween_property(holder, "position", home + Vector2(9 * dir, -1), 0.08 / SPEEDS[speed_index])
	t.tween_property(holder, "position", home, 0.14 / SPEEDS[speed_index])


func _flash(uid: int) -> void:
	if not _views.has(uid):
		return
	var s: Sprite2D = _views[uid]["sprite"]
	var f := battle.fighter(uid)
	if f != null and not f.alive():
		return
	s.modulate = Color(1.8, 0.7, 0.7)
	var t := s.create_tween()
	t.tween_property(s, "modulate", Color.WHITE, 0.15)


func _knock_out(uid: int) -> void:
	if not _views.has(uid):
		return
	var s: Sprite2D = _views[uid]["sprite"]
	var t := s.create_tween()
	t.tween_property(s, "modulate", Color(0.35, 0.35, 0.4, 0.35), 0.3)
	var bar: HpBar = _views[uid]["bar"]
	bar.visible = false


func _update_bar(f: Fighter) -> void:
	if f == null or not _views.has(f.uid):
		return
	var bar: HpBar = _views[f.uid]["bar"]
	bar.frac = f.hp_fraction()
	bar.shield_frac = f.shield / f.max_hp
	bar.poisoned = f.poison_secs > 0.0
	bar.taunting = f.taunt > 0.0
	bar.protected = f.is_boss() and battle != null and _boss_protected()
	bar.queue_redraw()


func _boss_protected() -> bool:
	for f in battle.fighters:
		if f.side == Formation.Side.ENEMY and not f.is_boss() and f.alive():
			return true
	return false


func _float(p: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("2b2030"))
	l.add_theme_constant_override("outline_size", 4)
	l.position = p - Vector2(text.length() * 2.5, 0)
	_fx.add_child(l)
	var t := l.create_tween()
	t.set_parallel()
	t.tween_property(l, "position", l.position + Vector2(0, -14), 0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)


func _bolt(dst: int) -> void:
	var b := ColorRect.new()
	b.color = Color("ffe9a8")
	b.size = Vector2(4, 2)
	var from := Formation.WAGON_FEET + Vector2(70, -120)
	b.position = from
	_fx.add_child(b)
	var t := b.create_tween()
	t.tween_property(b, "position", _view_pos(dst) + Vector2(0, -24), 0.25 / SPEEDS[speed_index])
	t.tween_callback(b.queue_free)


func _note(line: String) -> void:
	_log_lines.append(line)
	if _log_lines.size() > 2:
		_log_lines.pop_front()
	_log.text = "   ".join(_log_lines)


func _toggle_pause() -> void:
	paused = not paused
	_refresh_combat_bar()


func _cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()
	_refresh_combat_bar()


func _retreat() -> void:
	if battle != null and not _is_guardian():
		battle.request_retreat()
		_retreat_btn.disabled = true


func _refresh_combat_bar() -> void:
	_pause_btn.text = "Resume (Space)" if paused else "Pause (Space)"
	_speed_btn.text = "Speed %dx" % int(SPEEDS[speed_index])


func _end_combat() -> void:
	_drain_events()
	phase = Phase.AFTERMATH
	_combat_bar.visible = false
	var o := battle.outcome
	_after_title.text = {Battle.Outcome.VICTORY: "Victory!", Battle.Outcome.DEFEAT: "Defeat",
		Battle.Outcome.WITHDRAW: "Both sides pull back", Battle.Outcome.RETREAT: "You got away"}[o]
	_after_title.add_theme_color_override("font_color", GOOD if o == Battle.Outcome.VICTORY else (BAD if o == Battle.Outcome.DEFEAT else MID))
	if practice:
		var hp := battle.player_hp()
		var lines: Array[String] = ["Practice only: nothing is lost.", "Fight took %d seconds." % int(battle.time)]
		for id in hp:
			lines.append("%s: %d/%d HP" % [Species.info(id)["name"], int(hp[id]), roundi(crossing.max_hp(id))])
		_result_lines = lines
	else:
		_result_lines = crossing.finish_battle(battle)
	_after_body.text = "\n".join(_result_lines)
	for c in _after_buttons.get_children():
		c.queue_free()
	if practice:
		var again := Ui.button("Fight again", 10)
		again.pressed.connect(_practice_again)
		_after_buttons.add_child(again)
		var title := Ui.button("Back to title", 10)
		title.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
		_after_buttons.add_child(title)
		again.grab_focus.call_deferred()
	else:
		var cont := Ui.button("Continue", 10)
		cont.pressed.connect(func(): finished.emit(_result_lines))
		_after_buttons.add_child(cont)
		cont.grab_focus.call_deferred()
	_after.visible = true


func _practice_again() -> void:
	for id in crossing.roster:
		crossing.creature_hp[id] = crossing.max_hp(id)
	battle = null
	_enter_lineup()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if phase == Phase.LINEUP:
			_click_lineup(get_global_mouse_position())
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and phase == Phase.COMBAT and event is InputEventKey:
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and practice:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


# ---------- UI ----------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 6
	add_child(_ui)

	var info_panel := PanelContainer.new()
	_info_panel = info_panel
	info_panel.position = Vector2(6, 6)
	info_panel.custom_minimum_size = Vector2(318, 0)
	info_panel.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.85)))
	_info = PreviewHud.label("", 8)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(306, 0)
	info_panel.add_child(_info)

	_side_panel = PanelContainer.new()
	_side_panel.position = Vector2(332, 6)
	_side_panel.custom_minimum_size = Vector2(302, 0)
	_side_panel.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.85)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	_side_panel.add_child(col)
	_enc_title = PreviewHud.label("", 12)
	col.add_child(_enc_title)
	_enc_text = PreviewHud.label("", 8)
	col.add_child(_enc_text)
	var syn := HBoxContainer.new()
	syn.add_theme_constant_override("separation", 6)
	_syn_mine = PreviewHud.label("", 8)
	_syn_mine.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_syn_mine.custom_minimum_size = Vector2(150, 0)
	syn.add_child(_syn_mine)
	_syn_theirs = PreviewHud.label("", 8)
	_syn_theirs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_syn_theirs.custom_minimum_size = Vector2(134, 0)
	syn.add_child(_syn_theirs)
	col.add_child(syn)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	_fight = Ui.button("Fight!", 10)
	_fight.pressed.connect(_start_combat)
	buttons.add_child(_fight)
	var auto := Ui.button("Auto-arrange", 9)
	auto.pressed.connect(_auto_arrange)
	buttons.add_child(auto)
	_bench_btn = Ui.button("Sit out", 9)
	_bench_btn.tooltip_text = "Take the selected creature out of this battle."
	_bench_btn.pressed.connect(_bench_selected)
	buttons.add_child(_bench_btn)
	_foe_btn = Ui.button("Next foe", 9)
	_foe_btn.pressed.connect(_next_foe)
	buttons.add_child(_foe_btn)
	col.add_child(buttons)
	_ui.add_child(_side_panel)
	_ui.add_child(info_panel)

	_combat_bar = PanelContainer.new()
	_combat_bar.position = Vector2(332, 6)
	_combat_bar.custom_minimum_size = Vector2(302, 0)
	_combat_bar.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.85)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_combat_bar.add_child(row)
	_clock = PreviewHud.label("0s", 9)
	_clock.custom_minimum_size = Vector2(70, 0)
	row.add_child(_clock)
	_pause_btn = Ui.button("Pause (Space)", 9)
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.pressed.connect(_toggle_pause)
	row.add_child(_pause_btn)
	_speed_btn = Ui.button("Speed 1x", 9)
	_speed_btn.focus_mode = Control.FOCUS_NONE
	_speed_btn.pressed.connect(_cycle_speed)
	row.add_child(_speed_btn)
	_retreat_btn = Ui.button("Retreat", 9)
	_retreat_btn.focus_mode = Control.FOCUS_NONE
	_retreat_btn.pressed.connect(_retreat)
	row.add_child(_retreat_btn)
	_ui.add_child(_combat_bar)

	_log = PreviewHud.label("", 9)
	_log.position = Vector2(10, 346)
	_log.add_theme_color_override("font_outline_color", Color("2b2030"))
	_log.add_theme_constant_override("outline_size", 4)
	_ui.add_child(_log)

	_after = PanelContainer.new()
	_after.position = Vector2(150, 96)
	_after.custom_minimum_size = Vector2(340, 0)
	_after.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.94)))
	var acol := VBoxContainer.new()
	acol.add_theme_constant_override("separation", 6)
	_after.add_child(acol)
	_after_title = PreviewHud.label("", 16)
	acol.add_child(_after_title)
	_after_body = PreviewHud.label("", 9)
	_after_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_after_body.custom_minimum_size = Vector2(328, 0)
	acol.add_child(_after_body)
	_after_buttons = HBoxContainer.new()
	_after_buttons.add_theme_constant_override("separation", 6)
	acol.add_child(_after_buttons)
	_after.visible = false
	_ui.add_child(_after)


class GridView:
	extends Node2D
	var screen: BattleScreen

	func _draw() -> void:
		for side in [Formation.Side.PLAYER, Formation.Side.ENEMY]:
			for row in [Formation.Row.FRONT, Formation.Row.BACK]:
				for lane in 3:
					var r := Formation.cell_rect(side, row, lane)
					var picked := false
					if screen != null and screen._selected != "" and side == Formation.Side.PLAYER:
						var c: Variant = screen.crossing.lineup_cell(screen._selected)
						picked = c != null and c == Vector2i(row, lane)
					draw_rect(r, Color(1, 0.9, 0.5, 0.22) if picked else Color(1, 0.97, 0.86, 0.09))
					draw_rect(r, Color(1, 0.9, 0.5, 0.8) if picked else Color(1, 0.97, 0.86, 0.28), false, 1.0)


class HpBar:
	extends Node2D
	var frac := 1.0
	var shield_frac := 0.0
	var poisoned := false
	var taunting := false
	var protected := false
	var enemy := false

	func _draw() -> void:
		var w := 32.0
		draw_rect(Rect2(-1, -1, w + 2, 5), Color(0.1, 0.07, 0.1, 0.85))
		var col := Color("d9645a") if enemy else Color("74c86a")
		if poisoned:
			col = Color("a6e36b")
		draw_rect(Rect2(0, 0, roundf(w * clampf(frac, 0.0, 1.0)), 3), col)
		if shield_frac > 0.0:
			draw_rect(Rect2(0, 0, roundf(w * clampf(shield_frac, 0.0, 1.0)), 1), Color("bfe6ff"))
		if taunting:
			draw_rect(Rect2(-1, -1, w + 2, 5), Color("ffd36b"), false, 1.0)
		if protected:
			draw_rect(Rect2(-1, -1, w + 2, 5), Color("bfe6ff"), false, 1.0)


class Shadow:
	extends Node2D

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * 20, sin(a) * 3))
		draw_colored_polygon(pts, Color(0.16, 0.12, 0.12, 0.28))

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
const ULT := Color("ffe06b")

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
var _hover: HoverZones
var _target_line: TargetLine
var _info: RichTextLabel
var _info_panel: PanelContainer
var _side_panel: PanelContainer
var _enc_title: Label
var _enc_text: RichTextLabel
var _syn_mine: RichTextLabel
var _syn_theirs: RichTextLabel
var _fight: Button
var _bench_btn: Button
var _foe_btn: Button
var _item_slots: ItemSlots
var _items_used: RichTextLabel
var _combat_bar: PanelContainer
var _stats_panel: PanelContainer
var _stats: StatsWindow
var _stats_mode_btn: Button
var _stats_toggle: Button
## Whether the stats window is open (kept between fights).
static var stats_open := true
var _clock: RichTextLabel
var _pause_btn: Button
var _speed_btn: Button
var _retreat_btn: Button
var _log: Label
var _log_lines: Array[String] = []
var _after: PanelContainer
var _after_title: Label
var _after_body: RichTextLabel
var _after_buttons: HBoxContainer
var _result_lines: Array[String] = []
## A hunt, not a fight (set when the lineup opens; the encounter is cleared afterwards).
var _hunting := false


## Call before adding to the tree. For practice, pass a fresh Expedition and practice = true.
func setup(with_crossing: Expedition, was_ambushed := false, is_practice := false) -> void:
	crossing = with_crossing
	ambush = was_ambushed
	practice = is_practice
	if practice:
		crossing.pending_encounter = {"pack": CombatData.PACKS[0], "scale": CombatData.RISK_SCALE[1], "guardian": false}


## The terrain's battle backdrop with the region's landmark between its sky and its ground
## (tools/art/regions.py makes the layers).
func _add_backdrop() -> void:
	var scene := crossing.scenery() if crossing != null else {"terrain": "Forest", "landmark": ""}
	var t := String(scene["terrain"]).to_lower()
	var dir := "res://assets/backgrounds/battle/"
	if not ResourceLoader.exists(dir + t + "_back.png"):
		t = "forest"
	for part in ["back", "landmark", "front"]:
		var bg := Sprite2D.new()
		bg.centered = false
		if part == "landmark":
			var path := "res://assets/props/%s.png" % String(scene["landmark"])
			if String(scene["landmark"]) == "" or not ResourceLoader.exists(path):
				continue
			bg.texture = load(path)
			bg.position = Vector2(540, 142) - Vector2(bg.texture.get_width() * 0.5, bg.texture.get_height())
			bg.modulate = TravelBackdrop.LANDMARK_HAZE
		else:
			bg.texture = load(dir + "%s_%s.png" % [t, part])
		add_child(bg)


func _ready() -> void:
	_add_backdrop()
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
	_target_line = TargetLine.new()
	_target_line.z_index = 11
	_target_line.visible = false
	add_child(_target_line)
	_hover = HoverZones.new()
	add_child(_hover)
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
	_hunting = crossing.is_hunt()
	_grid.visible = true
	_side_panel.visible = true
	_info_panel.visible = true
	_combat_bar.visible = false
	_stats_panel.visible = false
	_after.visible = false
	_log.text = "Ambushed! Your team will be slow to react." if ambush else "Click a creature, then a cell to move it. Hover anything for details."
	_refresh_lineup()
	_fight.grab_focus.call_deferred()


func _refresh_lineup() -> void:
	for c in _units.get_children():
		c.queue_free()
	for c in _fx.get_children():
		c.queue_free()
	_views.clear()
	_hover.clear()
	for cell in crossing.lineup:
		var id: String = crossing.lineup[cell]
		var v := _add_unit(id, Formation.slot_feet(Formation.Side.PLAYER, cell.x, cell.y), false, _mine_card.bind(id))
		if not crossing.conscious(id):
			v["sprite"].modulate = Color(0.45, 0.45, 0.5, 0.6)
		elif id == _selected:
			v["sprite"].modulate = Color(1.25, 1.2, 0.9)
		var bar: HpBar = v["bar"]
		bar.frac = float(crossing.creature_hp.get(id, 0.0)) / crossing.max_hp(id)
		bar.queue_redraw()
	var pack := _pack()
	var scale := crossing.enemy_scale()
	for row in [Formation.Row.FRONT, Formation.Row.BACK]:
		var ids: Array = pack["front" if row == Formation.Row.FRONT else "back"]
		for lane in ids.size():
			if String(ids[lane]) != "":
				_add_unit(ids[lane], Formation.slot_feet(Formation.Side.ENEMY, row, lane), true, _foe_card.bind(ids[lane], scale, false))
	if String(pack.get("boss", "")) != "":
		_add_unit(pack["boss"], Formation.BOSS_FEET, true, _foe_card.bind(pack["boss"], scale, true))
	_enc_title.text = pack["title"] + ("  (ambush!)" if ambush else "")
	_item_slots.visible = not _hunting
	var strength := "weak" if scale < 1.1 else ("tough" if scale >= 1.4 else ("strong" if scale >= 1.25 else "ordinary"))
	var risk_icons: int = {"weak": 0, "ordinary": 1, "strong": 2, "tough": 3}[strength]
	Rich.set_text(_enc_text, "%sFoes look %s.%s%s" % ["{i:risk}".repeat(maxi(1, risk_icons)), strength,
		" {k:role_boss|Boss} is safe until its pack falls." if String(pack.get("boss", "")) != "" else "",
		" You were caught in an {k:ambush}." if ambush else ""])
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
	Rich.set_text(_syn_mine, "Your {k:synergy|habitat bonuses}:\n" + (synergy_markup(mine, true) if not mine.is_empty() else "nobody can fight"))
	var theirs_text := synergy_markup(theirs, false)
	Rich.set_text(_syn_theirs, "Theirs:\n" + (theirs_text if theirs_text != "" else "none"))
	if _hunting:
		Rich.set_text(_enc_text, "{i:food} The herd hasn't seen you. %s stands its ground and fights; the rest {k:hunt|bolt} when spooked. Hit hard and fast: a wounded one runs. %ds before they all scatter." % [
			Species.info(String(pack.get("charger", pack["front"][1])))["name"], int(Battle.HUNT_SECS)])
	_fight.disabled = mine.is_empty()
	_fight.text = ("Start the hunt" if _hunting else "Fight!") if not mine.is_empty() else "Nobody can fight"
	_foe_btn.visible = practice
	if _item_slots.crossing == null:
		_item_slots.crossing = crossing
	_item_slots.refresh()
	_bench_btn.visible = _selected != "" and crossing.lineup_cell(_selected) != null
	_show_info()
	_grid.queue_redraw()


func _add_unit(id: String, feet: Vector2, enemy: bool, tip: Variant = null) -> Dictionary:
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
	if tip != null:
		_hover.add(HoverZones.creature_rect(feet) if feet != Formation.BOSS_FEET else Rect2(feet + Vector2(-32, -72), Vector2(64, 74)), tip, holder)
	return v


## Tooltip for one of your creatures before the fight.
func _mine_card(id: String) -> String:
	return CreatureCard.markup(id, CreatureCard.team_opts(crossing, id))


func _foe_card(id: String, scale: float, boss: bool) -> String:
	var t := CreatureCard.markup(id, {"scale": scale, "enemy": true})
	if _hunting:
		t += "\n" + ("[color=#ff8a7a]The charger: it fights back. Worth double food.[/color]" if id == String(_pack().get("charger", "")) else "Prey: never attacks, bolts when spooked or hurt.")
	if boss:
		t += "\n{k:role_boss|Boss}: can't be hit until its pack is down."
	return t


## Tooltip for a creature during the fight, with live health and statuses.
func _fighter_card(uid: int) -> String:
	if battle == null:
		return ""
	var f := battle.fighter(uid)
	if f == null:
		return ""
	var opts := {"hp": f.hp, "max_hp": f.max_hp, "fighter": f, "enemy": f.side == Formation.Side.ENEMY}
	if f.side == Formation.Side.PLAYER and crossing != null:
		opts["level"] = crossing.level(f.species)
	return CreatureCard.markup(f.species, opts)


## Habitat bonus lines with icons. include_close adds habitats one creature short.
static func synergy_markup(ids: Array, include_close: bool) -> String:
	var counts := CombatData.type_counts(ids)
	var active: Array[String] = []
	var near: Array[String] = []
	for t in CombatData.SYNERGIES:
		var n: int = counts.get(t, 0)
		if n == 0:
			continue
		var tier := CombatData.synergy_tier(t, n)
		var syn: Dictionary = CombatData.SYNERGIES[t]
		var hab := Glossary.habitat_id(t)
		if tier > 0:
			active.append("{i:%s}x%d %s" % [hab, n, syn["desc"] % int(CombatData.synergy_value(t, tier))])
		else:
			near.append("{i:%s}%d/%d" % [hab, n, syn["need"][0]])
	if include_close and not near.is_empty():
		active.append("Close: " + " ".join(near))
	return "\n".join(active)


func _show_info() -> void:
	var id: String = _inspect.get("id", "")
	if id == "":
		Rich.set_text(_info, "Click a creature to move it. Hover any creature, icon or [u]underlined[/u] word for details.")
		return
	var text := _mine_card(id) if _inspect.get("mine", false) else _foe_card(id, float(_inspect.get("scale", 1.0)), id == String(_pack().get("boss", "")))
	if _inspect.get("mine", false) and not crossing.conscious(id):
		text += "\n{k:ko|Knocked out}. Rest a day at a stop to wake it."
	Rich.set_text(_info, text)


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
	var scale := crossing.enemy_scale()
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
	all.append_array(CombatData.GUARDIANS)
	_practice_pack = (_practice_pack + 1) % all.size()
	var pack: Dictionary = all[_practice_pack]
	crossing.pending_encounter = {"pack": pack, "scale": CombatData.GUARDIAN_SCALE if pack.has("boss") else CombatData.RISK_SCALE[1], "guardian": pack.has("boss")}
	_inspect = {}
	_refresh_lineup()


# ---------- combat ----------

func _start_combat() -> void:
	if not crossing.can_fight():
		return
	battle = crossing.make_battle(ambush)
	var used := ""
	for id in battle.items_used:
		used += "{%s:%s}" % ["ik" if battle.items_used.size() == 1 else "i", id]
	Rich.set_text(_items_used, used)
	phase = Phase.COMBAT
	_selected = ""
	_grid.visible = false
	_side_panel.visible = false
	_info_panel.visible = false
	_combat_bar.visible = true
	_stats_panel.visible = true
	_stats.set_battle(battle)
	_refresh_stats_mode()
	paused = false
	_retreat_btn.disabled = _is_guardian()
	_retreat_btn.set_meta("tip", "There's no way around this one." if _is_guardian() else "Pull back after 3 seconds. Costs {i:food} food and {i:wagon} wagon wear.")
	_log_lines.clear()
	_log.text = "The hunt begins! Quietly now..." if _hunting else "The fight begins!"
	if _hunting:
		_retreat_btn.set_meta("tip", "Call off the hunt and keep what you've caught.")
	for c in _units.get_children():
		c.queue_free()
	_views.clear()
	_hover.clear()
	for f in battle.fighters:
		var feet := Formation.BOSS_FEET if f.is_boss() else Formation.slot_feet(f.side, f.row, f.lane)
		var v := _add_unit(f.species, feet, f.side == Formation.Side.ENEMY, _fighter_card.bind(f.uid))
		_views[f.uid] = v
		_update_bar(f)
	_refresh_combat_bar()


func _process(delta: float) -> void:
	if phase != Phase.COMBAT or battle == null:
		return
	if not paused:
		battle.advance(delta * SPEEDS[speed_index])
	_drain_events()
	for f in battle.fighters:
		if f.alive():
			_update_bar(f)
	_stats.queue_redraw()
	_update_target_line()
	var clock := "{i:cooldown}%ds%s" % [int(battle.time), "  {k:tired|tiring!}" if battle.time >= Battle.FATIGUE_START else ""]
	if _hunting:
		clock = "{i:cooldown}%ds left  {i:food}%d caught" % [ceili(maxf(0.0, Battle.HUNT_SECS - battle.time)), battle.hunt_bag().size()]
	if battle.retreating:
		clock += "  retreating %.1fs" % maxf(0.0, battle.retreat_left)
	Rich.set_text(_clock, clock)
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
			"ult":
				var f := battle.fighter(e["src"])
				_float(_view_pos(e["src"]) + Vector2(0, -72), e["label"] + "!", ULT)
				_flash(e["src"], Color(1.6, 1.4, 0.7))
				if e["dst"] != e["src"]:
					_lunge(e["src"], e["dst"])
				_note("%s unleashed %s" % [f.display_name(), e["label"]])
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
			"flee":
				_run_off(e["dst"])
				_note("%s bolts!" % battle.fighter(e["dst"]).display_name())


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


func _flash(uid: int, tint := Color(1.8, 0.7, 0.7)) -> void:
	if not _views.has(uid):
		return
	var s: Sprite2D = _views[uid]["sprite"]
	var f := battle.fighter(uid)
	if f != null and not f.alive():
		return
	s.modulate = tint
	var t := s.create_tween()
	t.tween_property(s, "modulate", Color.WHITE, 0.15 if tint.b < 0.8 else 0.35)


func _knock_out(uid: int) -> void:
	if not _views.has(uid):
		return
	var s: Sprite2D = _views[uid]["sprite"]
	var t := s.create_tween()
	t.tween_property(s, "modulate", Color(0.35, 0.35, 0.4, 0.35), 0.3)
	var bar: HpBar = _views[uid]["bar"]
	bar.visible = false


## A prey animal runs off the right edge and fades.
func _run_off(uid: int) -> void:
	if not _views.has(uid):
		return
	var holder: Node2D = _views[uid]["holder"]
	var bar: HpBar = _views[uid]["bar"]
	bar.visible = false
	var t := holder.create_tween().set_parallel()
	t.tween_property(holder, "position", holder.position + Vector2(140, -6), 0.7 / SPEEDS[speed_index])
	t.tween_property(holder, "modulate", Color(1, 1, 1, 0), 0.7 / SPEEDS[speed_index])


func _update_bar(f: Fighter) -> void:
	if f == null or not _views.has(f.uid):
		return
	var bar: HpBar = _views[f.uid]["bar"]
	bar.frac = f.hp_fraction()
	bar.shield_frac = f.shield / f.max_hp
	bar.poisoned = f.poison_secs > 0.0
	bar.taunting = f.taunt > 0.0
	bar.protected = f.is_boss() and battle != null and _boss_protected()
	var st: Array[String] = []
	if f.shield > 0.5:
		st.append("shield")
	if f.poison_secs > 0.0:
		st.append("poison")
	if f.taunt > 0.0:
		st.append("taunt")
	for m in f.mods:
		st.append(String(m["kind"]))
	bar.set_statuses(st)
	bar.show_bars = f.alive()
	bar.attack_frac = f.attack_bar
	bar.ult_frac = f.ult / CombatData.ULT_MAX
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


func _cycle_stats_mode() -> void:
	_stats.mode = (_stats.mode + 1) % StatsWindow.MODES.size()
	_refresh_stats_mode()


func _toggle_stats() -> void:
	stats_open = not stats_open
	_refresh_stats_mode()


func _refresh_stats_mode() -> void:
	_stats_mode_btn.text = "%s  >" % StatsWindow.MODES[_stats.mode]
	_stats_mode_btn.visible = stats_open
	_stats.visible = stats_open
	_stats_toggle.text = "-" if stats_open else "+ Stats"
	_stats.queue_redraw()
	# Stay pinned to the top-right corner whatever the size.
	_stats_panel.reset_size()
	_stats_panel.position = Vector2(634.0 - _stats_panel.get_combined_minimum_size().x, 6.0)


func _refresh_combat_bar() -> void:
	_pause_btn.text = "Resume (Space)" if paused else "Pause (Space)"
	_speed_btn.text = "Speed %dx" % int(SPEEDS[speed_index])


## While the mouse is over a creature, a red line shows who its next basic attack hits.
func _update_target_line() -> void:
	var node := _hover.hovered_node()
	var f: Fighter = null
	if node != null and battle.outcome == Battle.Outcome.ONGOING:
		for uid in _views:
			if _views[uid]["holder"] == node:
				f = battle.fighter(uid)
				break
	var t := battle.basic_target(f) if f != null else null
	_target_line.visible = t != null
	if t != null:
		_target_line.from = _views[f.uid]["home"] + TargetLine.CHEST
		_target_line.to = _views[t.uid]["home"] + TargetLine.CHEST
		_target_line.queue_redraw()


func _end_combat() -> void:
	_target_line.visible = false
	_drain_events()
	phase = Phase.AFTERMATH
	_combat_bar.visible = false
	_stats.queue_redraw()
	var o := battle.outcome
	_after_title.text = {Battle.Outcome.VICTORY: "Victory!", Battle.Outcome.DEFEAT: "Defeat",
		Battle.Outcome.WITHDRAW: "Both sides pull back", Battle.Outcome.RETREAT: "You got away"}[o]
	if _hunting:
		_after_title.text = "Driven off" if o == Battle.Outcome.DEFEAT else "The hunt is over"
	_after_title.add_theme_color_override("font_color", GOOD if o == Battle.Outcome.VICTORY else (BAD if o == Battle.Outcome.DEFEAT else MID))
	if practice:
		var hp := battle.player_hp()
		var lines: Array[String] = ["Practice only: nothing is lost.", "Fight took %d seconds." % int(battle.time)]
		for id in hp:
			lines.append("%s: %d/%d HP" % [Species.info(id)["name"], int(hp[id]), roundi(crossing.max_hp(id))])
		_result_lines = lines
	else:
		_result_lines = crossing.finish_battle(battle)
	Rich.set_text(_after_body, "\n".join(_result_lines))
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
		if crossing.pending_recruit != "":
			var rid := crossing.pending_recruit
			var take := Ui.button("Take in %s (%s)" % [Species.info(rid)["name"], Species.RARITIES[Species.rarity(rid)]["name"]], 10)
			take.icon = CompanionsScreen.portrait(rid)
			take.expand_icon = false
			take.add_theme_constant_override("icon_max_width", 16)
			take.pressed.connect(func():
				var line := crossing.recruit()
				if line != "":
					_result_lines.append(line)
					Rich.set_text(_after_body, "\n".join(_result_lines))
				take.disabled = true
				take.text = "%s joined" % Species.info(rid)["name"])
			Tips.attach(take, func(): return CreatureCard.markup(rid, {"enemy": false}) + "\n[color=#ffe3a3]It goes to storage. Swap it into your team from the Companions screen.[/color]")
			_after_buttons.add_child(take)
		if crossing.pending_count() > 0:
			var lv := Ui.button("Level ups (%d)" % crossing.pending_count(), 10)
			lv.pressed.connect(func():
				var s := LevelUpScreen.open(_ui, crossing)
				s.closed.connect(func():
					lv.text = "Level ups (%d)" % crossing.pending_count()
					lv.visible = crossing.pending_count() > 0
					cont.grab_focus.call_deferred()))
			Tips.attach(lv, func(): return "Pick upgrades now, or later from the Companions screen.")
			_after_buttons.add_child(lv)
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
	_info = Rich.label("", 8, 306)
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
	_enc_text = Rich.label("", 8, 290)
	col.add_child(_enc_text)
	var syn := HBoxContainer.new()
	syn.add_theme_constant_override("separation", 6)
	_syn_mine = Rich.label("", 8, 150)
	syn.add_child(_syn_mine)
	_syn_theirs = Rich.label("", 8, 134)
	syn.add_child(_syn_theirs)
	col.add_child(syn)
	_item_slots = ItemSlots.new()
	col.add_child(_item_slots)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	_fight = Ui.button("Fight!", 10)
	_fight.pressed.connect(_start_combat)
	Tips.attach(_fight, func(): return "Start the fight. It plays out by itself: your lineup and {k:synergy|habitat bonuses} decide it.")
	buttons.add_child(_fight)
	var auto := Ui.button("Auto-arrange", 9)
	auto.pressed.connect(_auto_arrange)
	Tips.attach(auto, func(): return "Put {i:role_guard} guards and {i:role_bruiser} bruisers in the {k:front_row}, everyone else in the {k:back_row}.")
	buttons.add_child(auto)
	_bench_btn = Ui.button("Sit out", 9)
	Tips.attach(_bench_btn, func(): return "Take the selected creature out of this battle.")
	_bench_btn.pressed.connect(_bench_selected)
	buttons.add_child(_bench_btn)
	var comp := Ui.button("Companions", 9)
	comp.pressed.connect(func(): CompanionsScreen.open(_ui, crossing))
	Tips.attach(comp, func(): return "Your team: stats, moves and memory slots, plus the Trailomon in storage.")
	buttons.add_child(comp)
	_foe_btn = Ui.button("Next foe", 9)
	_foe_btn.pressed.connect(_next_foe)
	buttons.add_child(_foe_btn)
	col.add_child(buttons)
	_ui.add_child(_side_panel)
	_ui.add_child(info_panel)

	_combat_bar = PanelContainer.new()
	_combat_bar.position = Vector2(6, 6)
	_combat_bar.custom_minimum_size = Vector2(302, 0)
	_combat_bar.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.85)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_combat_bar.add_child(row)
	_clock = Rich.label("0s", 9)
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
	Tips.attach(_retreat_btn, func(): return str(_retreat_btn.get_meta("tip", "")))
	row.add_child(_retreat_btn)
	_items_used = Rich.label("", 9)
	_items_used.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_items_used)
	_ui.add_child(_combat_bar)

	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(484, 6)
	var sbox := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.88))
	sbox.set_content_margin_all(3)
	_stats_panel.add_theme_stylebox_override("panel", sbox)
	var scol := VBoxContainer.new()
	scol.add_theme_constant_override("separation", 2)
	_stats_panel.add_child(scol)
	var shead := HBoxContainer.new()
	shead.add_theme_constant_override("separation", 2)
	scol.add_child(shead)
	_stats_mode_btn = Ui.button("", 8)
	_stats_mode_btn.focus_mode = Control.FOCUS_NONE
	_stats_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_mode_btn.pressed.connect(_cycle_stats_mode)
	Tips.attach(_stats_mode_btn, func(): return "Click to switch between damage dealt, {k:shield|shielding} given, healing done and damage taken.")
	shead.add_child(_stats_mode_btn)
	_stats_toggle = Ui.button("-", 8)
	_stats_toggle.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_toggle.focus_mode = Control.FOCUS_NONE
	_stats_toggle.custom_minimum_size = Vector2(12, 0)
	_stats_toggle.pressed.connect(_toggle_stats)
	Tips.attach(_stats_toggle, func(): return "Hide the fight stats." if stats_open else "Show the fight stats.")
	shead.add_child(_stats_toggle)
	_stats = StatsWindow.new()
	scol.add_child(_stats)
	_stats_panel.visible = false
	_ui.add_child(_stats_panel)
	_refresh_stats_mode()

	_log = PreviewHud.label("", 9)
	_log.position = Vector2(10, 346)
	_log.add_theme_color_override("font_outline_color", Color("2b2030"))
	_log.add_theme_constant_override("outline_size", 4)
	_ui.add_child(_log)

	_after = PanelContainer.new()
	_after.position = Vector2(110, 96)
	_after.custom_minimum_size = Vector2(340, 0)
	_after.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.94)))
	var acol := VBoxContainer.new()
	acol.add_theme_constant_override("separation", 6)
	_after.add_child(acol)
	_after_title = PreviewHud.label("", 16)
	acol.add_child(_after_title)
	_after_body = Rich.label("", 9, 328)
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
	## Status icon ids shown under the bar. Set through set_statuses() so the icons are
	## loaded outside _draw (a texture first loaded inside _draw renders as a white box).
	var statuses: Array[String] = []
	var _icons: Array[Texture2D] = []

	func set_statuses(ids: Array[String]) -> void:
		statuses = ids
		_icons.clear()
		for id in ids:
			var tex := Rich.icon_tex(id)
			if tex != null:
				_icons.append(tex)
	## Combat only: attack bar (0..1) and ultimate bar (0..1).
	var show_bars := false
	var attack_frac := 0.0
	var ult_frac := 0.0

	func _draw() -> void:
		var w := 32.0
		var h := 8.0 if show_bars else 5.0
		draw_rect(Rect2(-1, -1, w + 2, h), Color(0.1, 0.07, 0.1, 0.85))
		if show_bars:
			var full := ult_frac >= 1.0
			draw_rect(Rect2(0, 4, roundf(w * clampf(ult_frac, 0.0, 1.0)), 2), Color("ffe06b") if full else Color("d9a43a"))
			draw_rect(Rect2(0, 6, roundf(w * clampf(attack_frac, 0.0, 1.0)), 1), Color("e8e4f0"))
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
		var x := 0.0
		for tex in _icons:
			draw_texture_rect(tex, Rect2(x, h, 8, 8), false)
			x += 8


## Top-right fight totals for your team: one bar per creature, scaled to the leader.
## Damage mode splits each bar into basic attacks, ultimates and passives.
class StatsWindow:
	extends Control
	const MODES := ["Damage", "Shielding", "Healing", "Taken"]
	const LONG := ["Damage dealt", "Shielding given", "Healing done", "Damage taken"]
	const BASIC_COL := Color("e8e4f0")
	const ULT_COL := Color("ffd04a")
	const PASSIVE_COL := Color("8fd06a")
	const WIDTH := 132.0
	const ROW_H := 14.0
	const PIC := 13.0
	const NUM_W := 24.0
	var battle: Battle
	var mode := 0
	## Portraits, loaded outside _draw (a texture first loaded in _draw renders white):
	## species -> [texture, region of the sprite that isn't empty].
	var _pics := {}
	var _wagon: Texture2D
	var _hover_row := -1

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		mouse_exited.connect(func():
			_hover_row = -1
			Tips.hide_from(self))
		tree_exiting.connect(func(): Tips.hide_from(self))

	func set_battle(b: Battle) -> void:
		battle = b
		_wagon = Rich.icon_tex("wagon")
		for f in b.side_fighters(Formation.Side.PLAYER):
			if _pics.has(f.species):
				continue
			var tex: Texture2D = load("res://assets/creatures/%s.png" % f.species)
			var used := Rect2(Vector2.ZERO, tex.get_size())
			var img := tex.get_image()
			if img != null:
				var r := img.get_used_rect()
				if r.size.x > 0:
					# Square crop around the used area, so every portrait is the same shape.
					var side := maxf(r.size.x, r.size.y)
					used = Rect2(Vector2(r.position) + Vector2(r.size) / 2.0 - Vector2(side, side) / 2.0, Vector2(side, side))
			_pics[f.species] = [tex, used]
		queue_redraw()

	func _rows() -> Array:
		var rows: Array = []
		if battle == null:
			return rows
		for f in battle.side_fighters(Formation.Side.PLAYER):
			var segs: Array = []
			match mode:
				0: segs = [[f.dmg_basic, BASIC_COL], [f.dmg_ult, ULT_COL], [f.dmg_passive, PASSIVE_COL]]
				1: segs = [[f.shield_done, Color("bfe6ff")]]
				2: segs = [[f.heal_done, Color("74c86a")]]
				3: segs = [[f.taken, Color("d9645a")]]
			rows.append({"species": f.species, "name": f.display_name(), "segs": segs, "down": not f.alive()})
		if mode == 0:
			rows.append({"species": "", "name": "Wagon", "segs": [[battle.wagon_damage, BASIC_COL]], "down": false})
		rows.sort_custom(func(a, b): return _total(a) > _total(b))
		return rows

	static func _total(r: Dictionary) -> float:
		var t := 0.0
		for sg in r["segs"]:
			t += float(sg[0])
		return t

	func _height() -> float:
		return ROW_H * maxf(1.0, _rows().size()) + (10.0 if mode == 0 else 0.0)

	func _get_minimum_size() -> Vector2:
		return Vector2(WIDTH, _height())

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var i := int(event.position.y / ROW_H)
			var rows := _rows()
			if i < 0 or i >= rows.size():
				_hover_row = -1
				Tips.hide_from(self)
				return
			_hover_row = i
			var r: Dictionary = rows[i]
			var parts: Array[String] = []
			if mode == 0:
				parts = ["Basic %d" % roundi(r["segs"][0][0])]
				if r["segs"].size() > 1:
					parts.append("Ultimate %d" % roundi(r["segs"][1][0]))
					parts.append("Passive %d" % roundi(r["segs"][2][0]))
			Tips.show_text("[b]%s[/b]\n%s: %d%s" % [r["name"], LONG[mode], roundi(_total(r)),
				("\n" + ", ".join(parts)) if not parts.is_empty() else ""], self)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var rows := _rows()
		var top := 0.0
		for r in rows:
			top = maxf(top, _total(r))
		var bar_x := PIC + 3.0
		var bar_w := size.x - bar_x - NUM_W - 2.0
		var y := 0.0
		for r in rows:
			var tint := Color(1, 1, 1, 0.4) if r["down"] else Color.WHITE
			var pic: Rect2 = Rect2(0, y, PIC, PIC)
			draw_rect(pic, Color(0.42, 0.36, 0.44, 0.9 * tint.a))
			if r["species"] != "" and _pics.has(r["species"]):
				draw_texture_rect_region(_pics[r["species"]][0], pic, _pics[r["species"]][1], tint)
			elif r["species"] == "" and _wagon != null:
				draw_texture_rect(_wagon, pic, false, tint)
			draw_rect(Rect2(bar_x, y + 4, bar_w, 6), Color(0.08, 0.06, 0.09, 0.9))
			var x := bar_x
			for sg in r["segs"]:
				var w := roundf(bar_w * float(sg[0]) / top) if top > 0.0 else 0.0
				if w > 0.0:
					draw_rect(Rect2(x, y + 4, w, 6), sg[1])
					x += w
			draw_string(font, Vector2(bar_x + bar_w + 2, y + 10), str(roundi(_total(r))), HORIZONTAL_ALIGNMENT_RIGHT, NUM_W, 8, PreviewHud.INK * tint)
			y += ROW_H
		if mode == 0:
			var lx := 0.0
			for item in [["Basic", BASIC_COL], ["Ult", ULT_COL], ["Passive", PASSIVE_COL]]:
				draw_rect(Rect2(lx, y + 2, 5, 5), item[1])
				draw_string(font, Vector2(lx + 7, y + 8), item[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, PreviewHud.INK)
				lx += 42.0
		if custom_minimum_size.y != _height():
			custom_minimum_size = Vector2(WIDTH, _height())


## A red line with an arrow head from a creature to the one it is attacking.
class TargetLine:
	extends Node2D
	const CHEST := Vector2(0, -18)
	const RED := Color("e0453a")
	var from := Vector2.ZERO
	var to := Vector2.ZERO

	func _draw() -> void:
		var dir := (to - from).normalized()
		if dir == Vector2.ZERO:
			return
		var tip := to - dir * 6.0
		draw_line(from, tip, Color(0, 0, 0, 0.5), 4.0)
		draw_line(from, tip, RED, 2.0)
		var side := dir.orthogonal() * 3.0
		draw_colored_polygon(PackedVector2Array([tip + dir * 4.0, tip - side, tip + side]), RED)
		draw_circle(to, 2.0, RED)


class Shadow:
	extends Node2D

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * 20, sin(a) * 3))
		draw_colored_polygon(pts, Color(0.16, 0.12, 0.12, 0.28))

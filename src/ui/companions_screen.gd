class_name CompanionsScreen
extends Control
## The Companions screen: the six Trailomon in the battle lineup with their stats and moves,
## an empty memory slot beside each move (filled later by level-ups), the Trailomon kept in
## storage, and placeholder dust buttons. Opens over the travel screen and the battle lineup.
##
##   CompanionsScreen.open(parent, crossing)

signal closed

const SCREEN := Vector2(640, 360)
const CARD := Vector2(204, 0)
const PIC := 26.0
const TILE := 24.0
## Space left above and to the left of a portrait for its level badge.
const BADGE_ROOM := Vector2(12, 5)

var crossing: Expedition
var _cards: VBoxContainer
## The six lineup cards, front row first.
var _card_nodes: Array[Control] = []
var _stored: HBoxContainer
var _level_btn: Button
var _seals: RichTextLabel
var _tech_btn: Button
var _dust_btns := {}
## A stored Trailomon picked for a swap ("" if none).
var _swap_pick := ""
var _stored_note: RichTextLabel
## Called after a memory swap instead of refresh(), when the cards are shown somewhere else
## (the level-up screen borrows _card() as its character sheet).
var on_swap: Callable


static func open(parent: Node, e: Expedition) -> CompanionsScreen:
	var s := CompanionsScreen.new()
	s.crossing = e
	parent.add_child(s)
	return s


## A square crop of a creature sprite around the part that isn't empty.
static func portrait(species: String) -> Texture2D:
	var tex: Texture2D = load("res://assets/creatures/%s.png" % species)
	var img := tex.get_image()
	if img == null:
		return tex
	var r := img.get_used_rect()
	if r.size.x <= 0:
		return tex
	var side := maxf(r.size.x, r.size.y)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(Vector2(r.position) + Vector2(r.size) / 2.0 - Vector2(side, side) / 2.0, Vector2(side, side))
	return at


func _ready() -> void:
	position = Vector2.ZERO
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.78)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	panel.custom_minimum_size = SCREEN - Vector2(8, 8)
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.96))
	box.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	col.add_child(head)
	var title := PreviewHud.label("Companions", 11)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	for k in ["light", "dark"]:
		var b := Ui.button("", 8)
		b.icon = Rich.icon_tex(k + "_dust")
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(open_dust.bind(k))
		Tips.attach(b, "g:" + k + "_dust")
		head.add_child(b)
		_dust_btns[k] = b
	_tech_btn = Ui.button("", 8)
	_tech_btn.icon = Rich.icon_tex("technique")
	_tech_btn.focus_mode = Control.FOCUS_NONE
	_tech_btn.pressed.connect(open_techniques)
	Tips.attach(_tech_btn, "g:technique")
	head.add_child(_tech_btn)
	_level_btn = Ui.button("", 8)
	_level_btn.icon = Rich.icon_tex("ultimate")
	_level_btn.focus_mode = Control.FOCUS_NONE
	_level_btn.pressed.connect(open_level_ups)
	Tips.attach(_level_btn, func(): return "Your Trailomon levelled up. Pick their upgrades and new moves.")
	head.add_child(_level_btn)
	_seals = Rich.label("", 8)
	head.add_child(_seals)
	var close := Ui.button("Close (Esc)", 8)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_screen)
	head.add_child(close)

	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 2)
	col.add_child(_cards)

	_stored_note = _heading("Stored", "") as RichTextLabel
	col.add_child(_stored_note)
	_stored = HBoxContainer.new()
	_stored.add_theme_constant_override("separation", 3)
	col.add_child(_stored)
	refresh()


func refresh() -> void:
	for c in _cards.get_children():
		c.queue_free()
	for c in _stored.get_children():
		c.queue_free()
	_card_nodes.clear()
	for row in 2:
		_cards.add_child(_heading("Front row" if row == 0 else "Second row", ""))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		_cards.add_child(line)
		for lane in 3:
			var cid: String = crossing.lineup.get(Vector2i(row, lane), "")
			var card := _card(cid)
			if _swap_pick != "" and cid != "":
				_swap_target(card, cid)
			line.add_child(card)
			_card_nodes.append(card)
	for i in maxi(9, crossing.stored.size() + 1):
		_stored.add_child(_stored_tile(crossing.stored[i] if i < crossing.stored.size() else ""))
	var note := "kept back at camp. Click one, then a team card, to swap them."
	if _swap_pick != "":
		note = "[color=#ffe3a3]Now click a team card to swap with %s (click it again to cancel).[/color]" % Species.info(_swap_pick)["name"]
	Rich.set_text(_stored_note, "[color=#e8d6a8]STORED[/color]   [color=#%s]%s[/color]" % [CreatureCard.MUTED, note])
	var techs := 0
	for mid in crossing.techniques:
		techs += crossing.technique_count(mid)
	_tech_btn.text = "Techniques (%d)" % techs
	for k in _dust_btns:
		(_dust_btns[k] as Button).text = "%s (%d)" % ["Light" if k == "light" else "Dark", crossing.dust_count(k)]
	var seal_icons := ""
	for g in crossing.seals:
		seal_icons += "[hint=%s]{i:seal_%s}[/hint]" % [Expedition.seal_name(g), g]
	Rich.set_text(_seals, seal_icons)
	_level_btn.visible = crossing.pending_count() > 0
	_level_btn.text = "Level ups (%d)" % crossing.pending_count()


func open_level_ups() -> void:
	if crossing.pending_count() == 0:
		return
	var l := LevelUpScreen.open(self, crossing)
	l.closed.connect(refresh)


func open_dust(k: String) -> void:
	var d := DustScreen.open(self, crossing, k)
	d.closed.connect(refresh)


func open_techniques() -> void:
	var t := TechniqueScreen.open(self, crossing)
	t.closed.connect(refresh)


func _evolve(id: String, to: String) -> void:
	var name := crossing.display_name(id)
	if crossing.evolve(id, to) != "":
		Tips.hide_from(null)
		refresh()
		EvolveScreen.open(self, id, to, name)


## A small box to type a name for one of your Trailomon. Enter keeps it, Esc cancels, an
## empty name goes back to the species name.
func _ask_name(id: String) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.6)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.size = SCREEN
	dim.add_child(center)
	var panel := _panel(Color(0.16, 0.12, 0.18, 0.98), Vector2(220, 0))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	col.add_child(Rich.label("{i:rename} [b]Name %s[/b]" % Species.info(id)["name"], 9))
	var field := LineEdit.new()
	field.text = String(crossing.nicknames.get(id, ""))
	field.placeholder_text = String(Species.info(id)["name"])
	field.max_length = Expedition.NICKNAME_MAX
	field.add_theme_font_size_override("font_size", 9)
	col.add_child(field)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	col.add_child(row)
	var done := func(keep: bool):
		if keep:
			crossing.rename(id, field.text)
		dim.queue_free()
		refresh()
	var ok := Ui.button("Keep name", 8)
	ok.pressed.connect(done.bind(true))
	row.add_child(ok)
	var cancel := Ui.button("Cancel", 8)
	cancel.pressed.connect(done.bind(false))
	row.add_child(cancel)
	field.text_submitted.connect(func(_t): done.call(true))
	field.grab_focus.call_deferred()


func close_screen() -> void:
	Tips.hide_from(null)
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_screen()


## A small muted section heading with an optional note after it.
func _heading(title: String, note: String) -> Control:
	var t := "[color=#e8d6a8]%s[/color]" % title.to_upper()
	if note != "":
		t += "   [color=#%s]%s[/color]" % [CreatureCard.MUTED, note]
	return Rich.label(t, 7)


func _panel(bg: Color, min_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	var b := PreviewHud.box(bg)
	b.set_content_margin_all(4)
	# Soft borders, so the cards don't compete with the text.
	b.border_color = Color(0.91, 0.84, 0.66, 0.35 if bg.a > 0.9 else 0.15)
	p.add_theme_stylebox_override("panel", b)
	return p


## One Trailomon's card. `highlight` outlines one move slot (the level-up screen marks the
## slot a new move would replace).
func _card(id: String, highlight := "") -> Control:
	var p := _panel(Color(0.18, 0.14, 0.20, 0.95), CARD)
	if id == "":
		p.add_child(Rich.label("[color=#%s]Empty spot[/color]" % CreatureCard.MUTED, 8))
		return p
	var info := Species.info(id)
	var s := CombatData.stats(id)
	var kit := crossing.kit_moves(id)
	var hp := float(crossing.creature_hp.get(id, 0.0))
	var max_hp := crossing.max_hp(id)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	p.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	col.add_child(top)
	var pic := TextureRect.new()
	pic.texture = portrait(id)
	pic.custom_minimum_size = Vector2(PIC, PIC)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if hp <= 0.0:
		pic.modulate = Color(1, 1, 1, 0.45)
	Tips.attach(pic, func(): return CreatureCard.markup(id, CreatureCard.team_opts(crossing, id)))
	top.add_child(_with_level(pic, crossing.level(id), Vector2(PIC, PIC)))
	var role: String = Glossary.ROLES.get(s["role"], "")
	var atk := crossing.stat(id, "atk")
	var def := crossing.stat(id, "def")
	var spd := crossing.stat(id, "spd")
	var dps := atk * float(CombatData.move(kit[0]).get("pct", 100)) / 100.0 / spd
	var xp_text := "max" if crossing.level(id) >= Leveling.MAX_LEVEL else "%d/%d xp" % [int(crossing.xp.get(id, 0)), Leveling.xp_to_next(crossing.level(id))]
	var shown := Species.name_markup(id)
	if crossing.nicknames.has(id):
		shown = "%s[/b] [font_size=7]%s[/font_size][b]" % [crossing.display_name(id), Species.name_markup(id)]
	var text := "[font_size=10][b]%s[/b][/font_size]  {i:%s} {i:%s}  [font_size=7][color=#%s]%s[/color][/font_size]\n" % [
		shown, Glossary.habitat_id(info["type"]), role, CreatureCard.MUTED, xp_text]
	text += "{i:hp} [color=#%s]%d[/color][color=#%s]/%d[/color]    {i:atk} [color=#%s]%d[/color]    {i:def} [color=#%s]%d[/color]\n" % [
		CreatureCard.HP_COL, roundi(hp), CreatureCard.MUTED, roundi(max_hp), CreatureCard.ATK_COL, roundi(atk), CreatureCard.DEF_COL, roundi(def)]
	text += "{i:spd} [color=#%s]%.2fs[/color]    {i:dps} [color=#%s]%.1f[/color]" % [CreatureCard.SPD_COL, spd, CreatureCard.DPS_COL, dps]
	if hp <= 0.0:
		text += "  {ik:ko}"
	var stats := Rich.label(text, 8)
	stats.add_theme_constant_override("line_separation", 0)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stats)
	var evo := crossing.evolve_options(id)
	var evo_col := VBoxContainer.new()
	evo_col.add_theme_constant_override("separation", 1)
	top.add_child(evo_col)
	var name_btn := Ui.button("", 7)
	name_btn.icon = Rich.icon_tex("rename")
	name_btn.focus_mode = Control.FOCUS_NONE
	name_btn.pressed.connect(_ask_name.bind(id))
	Tips.attach(name_btn, func(): return "Give %s a name." % crossing.display_name(id))
	evo_col.add_child(name_btn)
	if not evo.is_empty():
		for to in evo:
			var eb := Ui.button("Evolve" if evo.size() == 1 else String(Species.info(to)["name"]), 7)
			eb.focus_mode = Control.FOCUS_NONE
			eb.pressed.connect(_evolve.bind(id, to))
			Tips.attach(eb, func(): return "Evolve into %s. It keeps its level, upgrades and learned moves, and takes on the new form's stats and moves.\n\n%s" % [
				Species.name_markup(to), CreatureCard.markup(to, {})])
			evo_col.add_child(eb)

	var rule := ColorRect.new()
	rule.color = Color(0.91, 0.84, 0.66, 0.18)
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)
	for mid in kit:
		var mrow := _move_row(id, mid, atk, def, max_hp)
		if CombatData.move(mid)["slot"] == highlight:
			var hl := PanelContainer.new()
			var hb := StyleBoxFlat.new()
			hb.bg_color = Color(1.0, 0.55, 0.25, 0.10)
			hb.border_color = Color(1.0, 0.6, 0.3, 0.9)
			hb.set_border_width_all(1)
			hb.set_corner_radius_all(2)
			hb.set_content_margin_all(1)
			hl.add_theme_stylebox_override("panel", hb)
			hl.add_child(mrow)
			col.add_child(hl)
		else:
			col.add_child(mrow)
	return p


## One move: slot tag and name, a small italic one-line summary with real numbers under
## it (hover for the full text), then its memory slot.
func _move_row(id: String, mid: String, atk: float, def: float, max_hp: float) -> Control:
	var mv := CombatData.move(mid)
	var slot: String = mv["slot"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	var name := Rich.label(CreatureCard.move_header(mid), 8)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(name)
	# One line at most: no wrapping, and anything too long is clipped.
	var line := Rich.label("[i][color=#%s]%s[/color][/i]" % [Color(CreatureCard.SOFT).darkened(0.15).to_html(false),
		CombatData.describe_short(mid, atk, def, max_hp)], 7)
	line.add_theme_font_size_override("italics_font_size", 7)
	line.fit_content = false
	line.clip_contents = true
	line.custom_minimum_size = Vector2(150, 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(line)
	Tips.attach(text, func(): return "%s\n[color=#%s]%s[/color]" % [CreatureCard.move_header(mid, true), CreatureCard.SOFT, CombatData.describe(mid, atk, def, max_hp)])
	row.add_child(text)
	var slot_box := _memory_slot(id, slot)
	slot_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slot_box)
	return row



func _memory_slot(id: String, slot: String) -> Control:
	var stored := crossing.memory_move(id, slot)
	var col: Color = Color(CreatureCard.SLOT_COL[slot])
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(16, 14)
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.08, 0.06, 0.09, 0.9)
	b.border_color = col if stored != "" else col.darkened(0.45)
	b.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", b)
	var icon := TextureRect.new()
	icon.texture = Rich.icon_tex(slot if stored != "" else "memory")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(12, 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stored == "":
		icon.modulate = Color(1, 1, 1, 0.35)
	p.add_child(icon)
	var slot_name := Glossary.entry_name(slot).to_lower()
	var name: String = Species.info(id)["name"]
	Tips.attach(p, func():
		var now := crossing.memory_move(id, slot)
		if now != "":
			return "{i:memory} [b]Memory slot[/b]\n%s\n[color=#%s]%s[/color]\n[color=#ffe3a3]Click to swap it in.[/color] %s goes into memory." % [
				CreatureCard.move_header(now, true), CreatureCard.SOFT,
				CombatData.describe(now, crossing.stat(id, "atk"), crossing.stat(id, "def"), crossing.max_hp(id)),
				CombatData.move(crossing.kit_move(id, slot))["name"]]
		return "{i:memory} [b]Memory slot (empty)[/b]\nWhen %s learns a new %s, the move it replaces is kept here so you can swap it back between battles." % [name, slot_name])
	if stored != "":
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		p.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				crossing.swap_memory(id, slot)
				Tips.hide_from(null)
				(on_swap if on_swap.is_valid() else refresh).call_deferred())
	return p


## Wraps a portrait so a small level badge sits on its top-left corner.
func _with_level(pic: TextureRect, lv: int, pic_size: Vector2) -> Control:
	# The picture sits down and to the right, so the badge has its own corner.
	var holder := Control.new()
	holder.custom_minimum_size = pic_size + BADGE_ROOM
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	pic.position = BADGE_ROOM
	pic.size = pic_size
	holder.add_child(pic)
	var badge := PanelContainer.new()
	badge.position = Vector2(-2, -2)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.09, 0.07, 0.10, 0.92)
	b.border_color = Color("e8d6a8")
	b.set_border_width_all(1)
	b.set_corner_radius_all(2)
	b.content_margin_left = 2
	b.content_margin_right = 2
	b.content_margin_top = 0
	b.content_margin_bottom = 0
	badge.add_theme_stylebox_override("panel", b)
	var l := PreviewHud.label("Lv %d" % lv, 7)
	l.add_theme_color_override("font_color", Color("ffe3a3"))
	badge.add_child(l)
	holder.add_child(badge)
	return holder


func _stored_tile(id: String) -> Control:
	var p := _panel(Color(0.18, 0.14, 0.20, 0.95) if id != "" else Color(0.10, 0.08, 0.12, 0.8), Vector2(TILE + 38, TILE + 13))
	if id == "":
		return p
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	p.add_child(row)
	var pic := TextureRect.new()
	pic.texture = portrait(id)
	pic.custom_minimum_size = Vector2(TILE, TILE)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_with_level(pic, crossing.level(id), Vector2(TILE, TILE)))
	var hab := TextureRect.new()
	hab.texture = Rich.icon_tex(Glossary.habitat_id(Species.info(id)["type"]))
	hab.custom_minimum_size = Vector2(12, 12)
	hab.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hab.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hab.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(hab)
	Tips.attach(p, func(): return CreatureCard.markup(id, CreatureCard.team_opts(crossing, id)) + "\n[color=#ffe3a3]Click, then click a team card, to swap them.[/color]")
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if id == _swap_pick:
		var hb: StyleBoxFlat = (p.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
		hb.border_color = Color("ffe3a3")
		hb.set_border_width_all(2)
		p.add_theme_stylebox_override("panel", hb)
	p.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_swap_pick = "" if _swap_pick == id else id
			Tips.hide_from(null)
			refresh.call_deferred())
	return p


## While a stored Trailomon is picked, team cards glow and swap on click.
func _swap_target(card: Control, team_id: String) -> void:
	var hb: StyleBoxFlat = (card.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	hb.border_color = Color("ffe3a3")
	hb.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", hb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			crossing.swap_stored(_swap_pick, team_id)
			_swap_pick = ""
			Tips.hide_from(null)
			refresh.call_deferred())

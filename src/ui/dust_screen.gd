class_name DustScreen
extends Control
## Spend Light or Dark dust: pick a Trailomon, then the stat to boost.
##
##   DustScreen.open(parent, crossing, "light")

signal closed

const SCREEN := Vector2(640, 360)
const PANEL := Vector2(600, 0)
const PIC := 24.0
const OPTION := Vector2(178, 44)
const LIGHT_COL := "ffe39a"
const DARK_COL := "c08cff"

var crossing: Expedition
var kind := "light"
var _col: VBoxContainer
var _who := ""
var _done := ""
var _sheets: CompanionsScreen


static func open(parent: Node, e: Expedition, with_kind := "light") -> DustScreen:
	var s := DustScreen.new()
	s.crossing = e
	s.kind = with_kind
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
	if _who == "" and not crossing.roster.is_empty():
		_who = String(crossing.roster[0])
	refresh()


func _exit_tree() -> void:
	if _sheets != null:
		_sheets.free()
		_sheets = null


func refresh() -> void:
	for c in _col.get_children():
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_col.add_child(head)
	var title := Rich.label("[font_size=11][b]Dust[/b][/font_size]", 8)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	for k in ["light", "dark"]:
		var b := Ui.button("%s dust (%d)" % ["Light" if k == "light" else "Dark", crossing.dust_count(k)], 8)
		b.icon = Rich.icon_tex(k + "_dust")
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.button_pressed = k == kind
		b.pressed.connect(func():
			kind = k
			refresh())
		Tips.attach(b, "g:" + k + "_dust")
		head.add_child(b)
	var close := Ui.button("Close (Esc)", 8)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_screen)
	head.add_child(close)

	var col := CreatureCard.MUTED
	var line := "Light dust: a boost to the stat you pick." if kind == "light" else "Dark dust: a big boost to the stat you pick, paid for by its opposite."
	_col.add_child(Rich.label("[color=#%s]%s Each Trailomon can take %d dust in total.[/color]" % [col, line, Dust.CAP], 8, PANEL.x - 16))

	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 4)
	_col.add_child(who)
	for id in crossing.roster:
		who.add_child(_portrait(id))

	if _who != "":
		var body := HBoxContainer.new()
		body.add_theme_constant_override("separation", 8)
		_col.add_child(body)
		var card := _sheets._card(_who)
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		body.add_child(card)
		var right := VBoxContainer.new()
		right.add_theme_constant_override("separation", 4)
		body.add_child(right)
		right.add_child(Rich.label("[color=#e8d6a8]PICK A STAT[/color]   [color=#%s]%d/%d dust taken[/color]" % [
			CreatureCard.MUTED, Dust.CAP - crossing.dust_left(_who), Dust.CAP], 7))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		right.add_child(grid)
		for stat in Leveling.STATS:
			grid.add_child(_option(stat))
		if crossing.dust_count(kind) <= 0:
			right.add_child(Rich.label("[color=#%s]No %s dust left. Win fights to gather more.[/color]" % [CreatureCard.MUTED, kind], 8, 360))
		elif crossing.dust_left(_who) <= 0:
			right.add_child(Rich.label("[color=#%s]%s has taken all the dust it can.[/color]" % [CreatureCard.MUTED, Species.info(_who)["name"]], 8, 360))
	if _done != "":
		_col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, _done], 8, PANEL.x - 16))


func _portrait(id: String) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(PIC + 8, PIC + 8)
	b.focus_mode = Control.FOCUS_NONE
	b.icon = CompanionsScreen.portrait(id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var chosen := id == _who
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.17, 0.25, 0.95) if state == "hover" or chosen else Color(0.12, 0.09, 0.14, 0.95)
		sb.border_color = Color("e8d6a8") if chosen else Color("e8d6a8").darkened(0.45)
		sb.set_border_width_all(2 if chosen else 1)
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(func():
		_who = id
		refresh())
	Tips.attach(b, func(): return "[b]%s[/b]\n%d/%d dust taken" % [Species.info(id)["name"], Dust.CAP - crossing.dust_left(id), Dust.CAP])
	return b


func _option(stat: String) -> Control:
	var o := Dust.offer(kind, stat)
	var ok := crossing.dust_count(kind) > 0 and crossing.dust_left(_who) > 0
	var b := Button.new()
	b.custom_minimum_size = OPTION
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not ok
	var edge := Color(LIGHT_COL if kind == "light" else DARK_COL)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.17, 0.25, 0.95) if state == "hover" else Color(0.17, 0.13, 0.19, 0.95)
		sb.border_color = edge if ok else edge.darkened(0.5)
		sb.set_border_width_all(2 if state == "hover" else 1)
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override(state, sb)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var text := "{i:%s} [b]%s[/b]" % [stat, Leveling.boost_text(stat, o["amount"])]
	if float(o["cost"]) > 0.0:
		var c := Dust.offer_text(o).split(", ")[1]
		text += "\n[color=#ff8a7a]{i:%s} %s[/color]" % [o["cost_stat"], c]
	var t := Rich.label(text, 8, OPTION.x - 10)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ok:
		t.modulate = Color(1, 1, 1, 0.5)
	margin.add_child(t)
	b.pressed.connect(func():
		var line := crossing.use_dust(_who, kind, stat)
		if line != "":
			crossing.journal.append(line)
			_done = line
		Tips.hide_from(null)
		refresh())
	Tips.attach(b, func():
		var before := crossing.max_hp(_who) if stat == "hp" else crossing.stat(_who, stat)
		var fmt := "%.2fs" if stat == "spd" else "%d"
		var after := before - float(o["amount"]) if stat == "spd" else before + float(o["amount"])
		var tip := "%s: %s -> [b]%s[/b]" % [Leveling.STAT_NAMES[stat], fmt % before, fmt % after]
		if float(o["cost"]) > 0.0:
			var cs: String = o["cost_stat"]
			var cb := crossing.max_hp(_who) if cs == "hp" else crossing.stat(_who, cs)
			var cfmt := "%.2fs" if cs == "spd" else "%d"
			var ca := cb + float(o["cost"]) if cs == "spd" else cb - float(o["cost"])
			tip += "\n%s: %s -> [color=#ff8a7a]%s[/color]" % [Leveling.STAT_NAMES[cs], cfmt % cb, cfmt % ca]
		return tip + "\n[color=#%s]Permanent. Uses 1 %s dust.[/color]" % [CreatureCard.MUTED, kind])
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

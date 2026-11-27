class_name FieldGuideScreen
extends Control
## The field guide: every Trailomon, by habitat. Ones you haven't met are dark shapes; met ones
## show their picture, and ones your caravan has had get a little catch mark. Click one for its
## page: rarity, jobs, how it grows and where you've met it.
##
##   FieldGuideScreen.open(parent, crossing)

signal closed

const SCREEN := Vector2(640, 360)
const TILE := 30.0
const COLS := 10
const TABS := ["Forest", "River", "Swamp", "Mountain", "Snow", "Jungle", "Blight", "Glow", "Guardians"]

var crossing: Expedition
var _tab := "Forest"
var _grid: GridContainer
var _page: RichTextLabel
var _pic: TextureRect
var _count: RichTextLabel
var _tab_btns := {}


static func open(parent: Node, e: Expedition) -> FieldGuideScreen:
	var s := FieldGuideScreen.new()
	s.crossing = e
	parent.add_child(s)
	return s


## The species on one tab, each family together in growth order.
static func species_on(tab: String) -> Array[String]:
	var out: Array[String] = []
	for id in Species.DATA:
		var r := Species.rarity(id)
		var b := Species.biome(id)
		var on := false
		if tab == "Guardians":
			on = r == "guardian"
		elif tab == "Blight" or tab == "Glow":
			on = b == tab and r != "guardian"
		else:
			on = b == "" and r != "guardian" and String(Species.info(id)["type"]) == tab
		if on:
			out.append(String(id))
	out.sort_custom(func(a, b):
		var fa := Species.family(a)
		var fb := Species.family(b)
		if fa != fb:
			return fa < fb
		return Species.stage(a) < Species.stage(b))
	return out


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.8)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	panel.custom_minimum_size = SCREEN - Vector2(8, 8)
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97))
	box.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	col.add_child(head)
	var title := Rich.label("{i:field_guide} [b]Field guide[/b]", 11, 160)
	head.add_child(title)
	_count = Rich.label("", 8, 300)
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_count)
	var close := Ui.button("Close (Esc)", 8)
	close.pressed.connect(_close)
	head.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	col.add_child(tabs)
	for t in TABS:
		var b := Ui.button(t, 7)
		var ic := "seal_hollow_stag" if t == "Guardians" else Glossary.icon(Glossary.habitat_id(t))
		b.icon = Rich.icon_tex(ic)
		b.add_theme_constant_override("icon_max_width", 12)
		b.toggle_mode = true
		b.pressed.connect(_show_tab.bind(t))
		tabs.add_child(b)
		_tab_btns[t] = b

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(COLS * (TILE + 2) + 10, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(_grid)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(side)
	_pic = TextureRect.new()
	_pic.custom_minimum_size = Vector2(64, 64)
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	side.add_child(_pic)
	_page = Rich.label("", 8, 280)
	side.add_child(_page)
	_update_count()
	# Open on the first habitat with something met in it.
	for t in TABS:
		if species_on(t).any(func(id): return crossing.has_met(id)):
			_tab = t
			break
	_show_tab(_tab)


func _update_count() -> void:
	var met := 0
	var had := 0
	for id in Species.DATA:
		if crossing.has_met(id):
			met += 1
		if crossing.has_caught(id):
			had += 1
	Rich.set_text(_count, "[right]Met [b]%d[/b] of %d     {i:lure} Caught [b]%d[/b][/right]" % [met, Species.DATA.size(), had])


func _show_tab(tab: String) -> void:
	_tab = tab
	for t in _tab_btns:
		(_tab_btns[t] as Button).button_pressed = t == tab
	for c in _grid.get_children():
		c.queue_free()
	var ids := species_on(tab)
	for id in ids:
		_grid.add_child(_tile(id))
	var first := ""
	for id in ids:
		if crossing.has_met(id):
			first = id
			break
	_show_page(first, tab)


func _tile(id: String) -> Control:
	var met := crossing.has_met(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(TILE, TILE)
	b.focus_mode = Control.FOCUS_NONE
	b.flat = false
	var pic := TextureRect.new()
	pic.texture = CompanionsScreen.portrait(id)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.position = Vector2(2, 2)
	pic.size = Vector2(TILE - 4, TILE - 4)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Unmet: a dark shape only.
	if not met:
		pic.modulate = Color(0.0, 0.0, 0.0, 0.7)
	Glint.apply(pic, crossing.glints.has(id))
	b.add_child(pic)
	if crossing.has_caught(id):
		var mark := TextureRect.new()
		mark.texture = Rich.icon_tex("lure")
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.size = Vector2(8, 8)
		mark.position = Vector2(TILE - 10, 1)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mark)
	b.pressed.connect(_show_page.bind(id if met else "", _tab))
	return b


func _show_page(id: String, tab: String) -> void:
	if id == "":
		_pic.texture = null
		Rich.set_text(_page, "[color=#%s]Nothing met here yet. Unmet Trailomon show as dark shapes: travel %s roads and fight what turns up.[/color]" % [
			CreatureCard.MUTED, "these" if tab == "Guardians" else tab.to_lower()])
		return
	_pic.texture = CompanionsScreen.portrait(id)
	Glint.apply(_pic, crossing.glints.has(id))
	Sound.cry(id)
	var info := Species.info(id)
	var lines: Array[String] = []
	lines.append("[font_size=11][b]%s[/b][/font_size]   %s" % [Species.name_markup(id), Species.rarity_tag(id)])
	var habitat := String(info["type"])
	var biome := Species.biome(id)
	lines.append("{ik:%s} %s%s   size %s" % [Glossary.habitat_id(habitat), habitat, (" ({ik:%s} %s)" % [Glossary.habitat_id(biome), biome]) if biome != "" else "", info["size"]])
	var caps: Dictionary = info.get("capabilities", {})
	if not caps.is_empty():
		var jobs: Array[String] = []
		for cap in caps:
			jobs.append("{i:%s}%s %d" % [Glossary.icon("cap_" + String(cap)), String(cap).capitalize(), int(caps[cap])])
		lines.append("Jobs: " + "  ".join(jobs))
	if int(info.get("hauling", 0)) > 0:
		lines.append("{i:haul} Can haul (%d)" % int(info["hauling"]))
	var prev := Species.previous(id)
	if prev != "":
		lines.append("Grows from %s at Lv %d." % [_name_if_met(prev), Species.evolve_level(prev)])
	var nexts := Species.evolutions(id)
	if not nexts.is_empty():
		var names: Array[String] = []
		for n in nexts:
			names.append(_name_if_met(n))
		lines.append("Grows into %s at Lv %d." % [" or ".join(names), Species.evolve_level(id)])
	var where := crossing.met_where(id)
	if not where.is_empty():
		lines.append("Met in: " + ", ".join(where))
	if crossing.glints.has(id):
		lines.append("{i:glint} Yours glints.")
	lines.append("{i:lure} Your caravan has had one." if crossing.has_caught(id) else "[color=#%s]Not caught yet.[/color]" % CreatureCard.MUTED)
	Rich.set_text(_page, "\n".join(lines))


func _name_if_met(id: String) -> String:
	return Species.name_markup(id) if crossing.has_met(id) else "[color=#%s]???[/color]" % CreatureCard.MUTED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()

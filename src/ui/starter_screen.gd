class_name StarterScreen
extends Control
## Choose your first partner: three Trailomon side by side, each with its portrait, habitat,
## role and a line about how it fights. Hover a portrait for its full card. Picking one starts
## the caravan; every other Trailomon has to be caught on the road.
##
##   var s := StarterScreen.open(parent)
##   s.picked.connect(func(id): ...)

signal picked(id: String)

const SCREEN := Vector2(640, 360)
const CARD := Vector2(176, 210)
const PORTRAIT := 72.0

## One line per starter about its temperament and how it fights (shown under its name).
const BLURBS := {
	"mossmole": "Stubborn and steady. Digs in at the front, shields itself and stings anything that hits it. Grows into a huge mossy bear-mole.",
	"crayhopper": "Restless and quick. Darts in with snapping claws and hits hard, but can't take much. Grows into a giant armored bullfrog-crayfish.",
	"cragkid": "Bold and hardy. Butts heads at the front and helps the haulers pull the wagon. Grows into a winged summit ibex.",
}

var _col: VBoxContainer


static func open(parent: Node) -> StarterScreen:
	var s := StarterScreen.new()
	parent.add_child(s)
	return s


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.86)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.size = SCREEN
	add_child(center)
	var panel := PanelContainer.new()
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97))
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 6)
	panel.add_child(_col)
	_col.add_child(Rich.label("{i:starter} [font_size=12][b]Choose your first partner[/b][/font_size]", 8))
	_col.add_child(Rich.label("[color=#%s]It travels with you from the first day. Every other Trailomon you'll have to catch on the road.[/color]" % CreatureCard.MUTED, 8, 540))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_col.add_child(row)
	for id in Expedition.STARTERS:
		row.add_child(_card(id))


func _card(id: String) -> Control:
	var info := Species.info(id)
	var s := CombatData.stats(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD
	var box := PreviewHud.box(Color(0.20, 0.16, 0.22, 0.95))
	box.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var pic := TextureRect.new()
	pic.texture = CompanionsScreen.portrait(id)
	pic.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.mouse_filter = Control.MOUSE_FILTER_PASS
	Tips.attach(pic, func(): return CreatureCard.markup(id, {"enemy": false}))
	col.add_child(pic)
	var hab := Glossary.habitat_id(String(info["type"]))
	col.add_child(Rich.label("[b]%s[/b]  {i:%s} {k:%s|%s}" % [info["name"], hab, hab, info["type"]], 9))
	var role_line := "[color=#%s]{k:%s|%s}" % [CreatureCard.MUTED, Glossary.ROLES.get(s["role"], "role"), s["role"]]
	if int(info.get("hauling", 0)) > 0:
		role_line += " · helps haul"
	col.add_child(Rich.label(role_line + "[/color]", 8))
	var blurb := Rich.label(String(BLURBS.get(id, "")), 7, CARD.x - 12)
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(blurb)
	var pick := Ui.button("Choose %s" % info["name"], 9)
	pick.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.mouse_entered.connect(Sound.cry.bind(id))
	pick.pressed.connect(func():
		Sound.cry(id)
		picked.emit(id)
		queue_free())
	col.add_child(pick)
	return panel

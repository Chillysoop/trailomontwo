class_name BackgroundScreen
extends Control
## Who leads the caravan: four trail-boss backgrounds side by side, picked once after the first
## partner. Each card shows the boss's icon, a line about them and their three perks.
##
##   var s := BackgroundScreen.open(parent)
##   s.picked.connect(func(id): ...)

signal picked(id: String)

const SCREEN := Vector2(640, 360)
const CARD := Vector2(140, 190)

var _col: VBoxContainer


static func open(parent: Node) -> BackgroundScreen:
	var s := BackgroundScreen.new()
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
	_col.add_child(Rich.label("{i:wagon} [font_size=12][b]Who leads the caravan?[/b][/font_size]", 8))
	_col.add_child(Rich.label("[color=#%s]Your trail boss's past shapes the whole journey. You choose once.[/color]" % CreatureCard.MUTED, 8, 590))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_col.add_child(row)
	for id in Backgrounds.ORDER:
		row.add_child(_card(id))


func _card(id: String) -> Control:
	var b := Backgrounds.info(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD
	var box := PreviewHud.box(Color(0.20, 0.16, 0.22, 0.95))
	box.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	var pic := TextureRect.new()
	pic.texture = Rich.icon_tex(String(b["icon"]))
	pic.custom_minimum_size = Vector2(40, 40)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(pic)
	col.add_child(Rich.label("[b]The %s[/b]" % b["name"], 9))
	col.add_child(Rich.label("[color=#%s]%s[/color]" % [CreatureCard.MUTED, b["line"]], 7, CARD.x - 12))
	var perks := Rich.label("[color=#9fe39a]%s[/color]" % Backgrounds.perk_text(id), 7, CARD.x - 12)
	perks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(perks)
	var pick := Ui.button("Lead as %s" % b["name"], 8)
	pick.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.pressed.connect(func():
		picked.emit(id)
		queue_free())
	col.add_child(pick)
	return panel

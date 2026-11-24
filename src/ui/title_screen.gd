extends Node2D
## Title screen over the scrolling travel scenery.

const SCENES := {
	"Start expedition": "res://scenes/expedition.tscn",
	"Travel preview": "res://scenes/travel_preview.tscn",
	"Practice battle": "res://scenes/battle.tscn",
}


func _ready() -> void:
	var backdrop := TravelBackdrop.new()
	backdrop.speed_scale = 0.5
	add_child(backdrop)
	backdrop.add_foreground(self)

	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	col.position = Vector2(320 - 130, 36)
	col.custom_minimum_size = Vector2(260, 0)
	ui.add_child(col)

	var title := PreviewHud.label("TRAILOMON", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("2b2030"))
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)
	var sub := PreviewHud.label("Trailomon Advanced: early test build", 9)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Color("2b2030"))
	sub.add_theme_constant_override("outline_size", 4)
	col.add_child(sub)

	var first: Button
	for text in SCENES:
		var b := _button(text)
		b.pressed.connect(get_tree().change_scene_to_file.bind(SCENES[text]))
		col.add_child(b)
		if first == null:
			first = b
	var quit := _button("Quit")
	quit.pressed.connect(get_tree().quit)
	col.add_child(quit)
	first.grab_focus.call_deferred()


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_stylebox_override("normal", PreviewHud.box())
	b.add_theme_stylebox_override("hover", PreviewHud.box(Color(0.30, 0.22, 0.30, 0.92)))
	b.add_theme_stylebox_override("focus", PreviewHud.box(Color(0.30, 0.22, 0.30, 0.92)))
	b.add_theme_stylebox_override("pressed", PreviewHud.box(Color(0.45, 0.33, 0.30, 0.95)))
	return b

class_name PreviewHud
extends RefCounted
## Small caption panel used by the preview scenes.

const INK := Color("fbf4e2")
const PANEL := Color(0.13, 0.10, 0.15, 0.82)
const EDGE := Color("e8d6a8")


static func make(title: String, hint: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 5
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.add_theme_stylebox_override("panel", box())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.add_child(label(title, 14))
	var h := label(hint, 9)
	h.name = "Hint"
	col.add_child(h)
	panel.add_child(col)
	layer.add_child(panel)
	return layer


static func label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	return l


static func box(fill := PANEL) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = EDGE
	b.set_border_width_all(1)
	b.set_content_margin_all(6)
	return b

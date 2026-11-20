class_name Ui
extends RefCounted
## Shared button style for in-game panels.


static func button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", PreviewHud.box(Color(0.22, 0.17, 0.24, 0.9)))
	b.add_theme_stylebox_override("hover", PreviewHud.box(Color(0.32, 0.24, 0.32, 0.95)))
	b.add_theme_stylebox_override("focus", PreviewHud.box(Color(0.32, 0.24, 0.32, 0.95)))
	b.add_theme_stylebox_override("pressed", PreviewHud.box(Color(0.45, 0.33, 0.30, 0.95)))
	b.add_theme_stylebox_override("disabled", PreviewHud.box(Color(0.18, 0.14, 0.16, 0.7)))
	# Small buttons get tight padding so lists fit the panel.
	var pad_y := 1 if size <= 8 else 3
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		var sb: StyleBoxFlat = b.get_theme_stylebox(state)
		sb.content_margin_top = pad_y
		sb.content_margin_bottom = pad_y
		sb.content_margin_left = 5
		sb.content_margin_right = 5
	return b

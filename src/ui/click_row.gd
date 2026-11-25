class_name ClickRow
extends PanelContainer
## A button that holds rich text (icons, portraits, hoverable keywords), sized to its content.

signal pressed

var disabled := false:
	set(v):
		disabled = v
		_restyle()
var label: RichTextLabel
var _hover := false


static func make(markup: String, size := 8, width := 0.0) -> ClickRow:
	var r := ClickRow.new()
	r.label = Rich.label(markup, size, width)
	r.label.mouse_filter = Control.MOUSE_FILTER_PASS
	r.add_child(r.label)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.focus_mode = Control.FOCUS_ALL
	r.mouse_entered.connect(func():
		r._hover = true
		r._restyle())
	r.mouse_exited.connect(func():
		r._hover = false
		r._restyle())
	r.focus_entered.connect(r._restyle)
	r.focus_exited.connect(r._restyle)
	r._restyle()
	return r


func set_markup(markup: String) -> void:
	Rich.set_text(label, markup)


func _restyle() -> void:
	var c := Color(0.22, 0.17, 0.24, 0.9)
	if disabled:
		c = Color(0.18, 0.14, 0.16, 0.7)
	elif _hover or has_focus():
		c = Color(0.32, 0.24, 0.32, 0.95)
	var sb := PreviewHud.box(c)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	add_theme_stylebox_override("panel", sb)
	if label != null:
		label.modulate = Color(1, 1, 1, 0.5) if disabled else Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("ui_accept"):
		accept_event()
		pressed.emit()

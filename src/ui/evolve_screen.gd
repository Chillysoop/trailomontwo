class_name EvolveScreen
extends Control
## The evolution reveal: the screen dims, the old form glows white and flickers between its
## outline and the new one, faster and faster, then a burst and the new form steps out with
## its name. Click (or wait) to close.
##
##   EvolveScreen.open(parent, from_id, to_id, shown_name)

signal closed

const SCREEN := Vector2(640, 360)
const SCALE := 3.0
const FLICKERS := 9

var from_id := ""
var to_id := ""
var shown_name := ""
var _old: Sprite2D
var _new: Sprite2D
var _text: RichTextLabel
var _done := false


static func open(parent: Node, from: String, to: String, name := "") -> EvolveScreen:
	var s := EvolveScreen.new()
	s.from_id = from
	s.to_id = to
	s.shown_name = name if name != "" else String(Species.info(from)["name"])
	parent.add_child(s)
	return s


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.92)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var glow := ColorRect.new()
	glow.color = Color(0.55, 0.95, 0.85, 0.0)
	glow.size = SCREEN
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	_old = _sprite(from_id)
	_new = _sprite(to_id)
	_new.visible = false
	_text = Rich.label("[center]What? %s is changing![/center]" % shown_name, 11, 600)
	_text.position = Vector2(20, 300)
	add_child(_text)

	Sound.cry(from_id)
	Sound.sfx("evolve")
	var t := create_tween()
	# The old form fills with light.
	t.tween_property(_old, "modulate", Color(4, 4, 4), 1.2)
	# Flicker between the two outlines, faster each time.
	for i in FLICKERS:
		var wait := lerpf(0.32, 0.06, float(i) / float(FLICKERS - 1))
		t.tween_callback(func(): _old.visible = false; _new.visible = true; _new.modulate = Color(4, 4, 4))
		t.tween_interval(wait)
		t.tween_callback(func(): _new.visible = false; _old.visible = true)
		t.tween_interval(wait)
	# Burst of light, then the new form.
	t.tween_callback(func(): _old.visible = false; _new.visible = true)
	t.tween_property(glow, "color:a", 0.9, 0.15)
	t.tween_property(glow, "color:a", 0.0, 0.6)
	t.parallel().tween_property(_new, "modulate", Color(1, 1, 1), 0.8)
	t.tween_callback(_reveal)


func _sprite(id: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://assets/creatures/%s.png" % id)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(SCALE, SCALE)
	s.position = SCREEN / 2.0 - Vector2(0, 20)
	add_child(s)
	return s


func _reveal() -> void:
	_done = true
	Sound.cry(to_id)
	Rich.set_text(_text, "[center]%s evolved into [b]%s[/b]![/center]\n[center][font_size=8][color=#%s]Click to continue[/color][/font_size][/center]" % [
		shown_name, Species.name_markup(to_id), CreatureCard.MUTED])
	var t := create_tween().set_loops(3)
	t.tween_property(_new, "position:y", _new.position.y - 6, 0.18)
	t.tween_property(_new, "position:y", _new.position.y, 0.18)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		if _done:
			_close()


func _unhandled_input(event: InputEvent) -> void:
	if _done and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()

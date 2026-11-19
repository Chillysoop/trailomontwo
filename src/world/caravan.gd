class_name Caravan
extends Node2D
## The wagon on the trail with its haulers roped in front and a companion walking behind.

const ROAD_FEET_Y := 300.0
const WAGON_FEET := Vector2(220, 302)
const HITCH := Vector2(326, 241)
## Feet positions for up to three haulers, nearest the wagon first.
const HAULER_SLOTS := [Vector2(404, ROAD_FEET_Y + 6), Vector2(486, ROAD_FEET_Y - 2), Vector2(566, ROAD_FEET_Y + 4)]
const COMPANION_FEET := Vector2(78, ROAD_FEET_Y + 10)

var _bobbing: Array[Node2D] = []


## haulers: species ids pulling the wagon (first three are shown). companion: optional species id walking behind.
func setup(haulers: Array, companion := "") -> void:
	for c in get_children():
		c.queue_free()
	_bobbing.clear()
	if companion != "":
		var comp := Stand.sprite(load("res://assets/creatures/%s.png" % companion), COMPANION_FEET)
		add_child(comp)
		_bobbing.append(comp)
	var wagon := Stand.sprite(load("res://assets/wagon/wagon.png"), WAGON_FEET)
	add_child(wagon)
	_bobbing.append(wagon)
	# Draw the far hauler first so the near one overlaps it.
	var shown := haulers.slice(0, HAULER_SLOTS.size())
	for i in range(shown.size() - 1, -1, -1):
		var feet: Vector2 = HAULER_SLOTS[i]
		var from: Vector2 = HITCH + Vector2(0, 4 * (1 - i)) if i < 2 else HAULER_SLOTS[i - 1] + Vector2(10, -28)
		add_child(_rope(from, feet + Vector2(6, -30 + 4 * (1 - i))))
		var h := Stand.sprite(load("res://assets/creatures/%s.png" % shown[i]), feet)
		add_child(h)
		_bobbing.append(h)


## Walking bob while travelling; still while halted.
func set_walking(on: bool) -> void:
	for i in _bobbing.size():
		var n := _bobbing[i]
		if not n.has_meta("rest"):
			n.set_meta("rest", n.position)
		var tw: Tween = n.get_meta("tween") if n.has_meta("tween") else null
		if tw:
			tw.kill()
		n.position = n.get_meta("rest")
		if on:
			n.set_meta("tween", _bob(n, 0.5 + 0.1 * (i % 3), 0.07 * i))


func _bob(node: Node2D, period: float, delay: float) -> Tween:
	var base := node.position
	var t := node.create_tween().set_loops()
	t.tween_interval(delay)
	t.tween_property(node, "position", base + Vector2(0, -1), period / 2.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "position", base, period / 2.0).set_trans(Tween.TRANS_SINE)
	return t


func _rope(from: Vector2, to: Vector2) -> Line2D:
	var line := Line2D.new()
	line.width = 2
	line.default_color = Color("5a3b24")
	for i in 11:
		var t := i / 10.0
		line.add_point(from.lerp(to, t) + Vector2(0, 5.0 * 4.0 * t * (1.0 - t)))
	return line

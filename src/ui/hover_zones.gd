class_name HoverZones
extends Node
## Hover tips for things drawn in the world (creatures, the wagon), not GUI controls.
## Add zones each time the scene is rebuilt; the tip opens while the mouse is inside one,
## unless a GUI control is under the mouse. Callables are re-run while hovered so live
## numbers stay current.

const REFRESH := 0.25

## [{"rect": Rect2, "what": Callable or meta String, "node": Node2D or null}]
var zones: Array = []
var _current := -1
var _timer := 0.0


## The node of the zone under the mouse, or null.
func hovered_node() -> Node2D:
	if _current < 0 or _current >= zones.size():
		return null
	var n: Node2D = zones[_current]["node"]
	return n if is_instance_valid(n) else null


func clear() -> void:
	zones.clear()
	_current = -1
	Tips.hide_from(self)


## rect is in screen space. If node is given, the rect follows the node's position offset.
func add(rect: Rect2, what: Variant, node: Node2D = null) -> void:
	zones.append({"rect": rect, "what": what, "node": node, "origin": node.global_position if node != null else Vector2.ZERO})


## A zone around a creature sprite standing on `feet`.
static func creature_rect(feet: Vector2) -> Rect2:
	return Rect2(feet + Vector2(-20, -50), Vector2(40, 52))


func _process(delta: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var mouse := vp.get_mouse_position()
	var hit := -1
	if vp.gui_get_hovered_control() == null:
		# Last added wins, so things in front take priority.
		for i in range(zones.size() - 1, -1, -1):
			var z: Dictionary = zones[i]
			var r: Rect2 = z["rect"]
			var n: Node2D = z["node"]
			if n != null:
				if not is_instance_valid(n) or not n.is_visible_in_tree():
					continue
				r.position += n.global_position - z["origin"]
			if r.has_point(mouse):
				hit = i
				break
	if hit == -1:
		if _current != -1:
			_current = -1
			Tips.hide_from(self)
		return
	_timer -= delta
	if hit != _current or _timer <= 0.0:
		_current = hit
		_timer = REFRESH
		var what: Variant = zones[hit]["what"]
		if what is Callable:
			var t: String = (what as Callable).call()
			if t == "":
				Tips.hide_from(self)
			else:
				Tips.show_text(t, self)
		else:
			Tips.show_meta(str(what), self)

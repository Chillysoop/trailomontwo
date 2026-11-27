class_name Glint
extends RefCounted
## Glinting Trailomon: now and then a wild one turns up in odd, shimmering colours
## (Expedition.GLINT_CHANCE). Catch it and that Trailomon glints for good. Looks only.

static var _mat: ShaderMaterial


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://assets/shaders/glint.gdshader")
	return _mat


## Make a sprite or picture glint (or stop) .
static func apply(node: CanvasItem, on: bool) -> void:
	if node != null:
		node.material = material() if on else null

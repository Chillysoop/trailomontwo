class_name Stand
extends RefCounted
## Helpers for placing pixel-art sprites by where their feet touch the ground.


## Returns a Sprite2D whose lowest opaque pixel row sits on `feet` and is centered horizontally on it.
static func sprite(texture: Texture2D, feet: Vector2, face_left := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.flip_h = face_left
	var used := texture.get_image().get_used_rect()
	var center_x := used.position.x + used.size.x / 2.0
	if face_left:
		center_x = texture.get_width() - center_x
	s.position = (feet - Vector2(center_x, used.end.y)).round()
	return s


## Gentle idle or walking bob, in whole pixels.
static func bob(node: Node2D, pixels := 1, period := 0.9, delay := 0.0) -> void:
	var base := node.position
	var t := node.create_tween().set_loops()
	t.tween_interval(delay)
	t.tween_property(node, "position", base + Vector2(0, -pixels), period / 2.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "position", base, period / 2.0).set_trans(Tween.TRANS_SINE)

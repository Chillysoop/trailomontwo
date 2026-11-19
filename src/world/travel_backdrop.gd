class_name TravelBackdrop
extends Node2D
## Scrolling parallax scenery for the travel view: sky, sun, mountains, far forest, ground with the trail.
## The foreground layer is separate (see add_foreground) so it can be drawn over the wagon and haulers.

const DIR := "res://assets/backgrounds/travel/"
const LAYER_WIDTH := 1280.0

## Pixels per second for each layer at walking pace; nearer layers move faster.
const LAYERS := [
	["sky.png", 2.0],
	["sun.png", 0.0],
	["mountains.png", 5.0],
	["forest_far.png", 12.0],
	["ground.png", 30.0],
]
const FOREGROUND_SPEED := 46.0

@export var speed_scale := 1.0


func _ready() -> void:
	for entry in LAYERS:
		add_child(_layer(entry[0], entry[1]))


func add_foreground(parent: Node) -> Node2D:
	var fg := _layer("foreground.png", FOREGROUND_SPEED)
	fg.z_index = 10
	parent.add_child(fg)
	return fg


func _layer(file: String, speed: float) -> Node2D:
	var tex: Texture2D = load(DIR + file)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	if speed == 0.0:
		return sprite
	var p := Parallax2D.new()
	p.repeat_size = Vector2(LAYER_WIDTH, 0)
	p.repeat_times = 2
	p.autoscroll = Vector2(-speed * speed_scale, 0)
	p.ignore_camera_scroll = true
	p.add_child(sprite)
	return p

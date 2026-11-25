class_name TravelBackdrop
extends Node2D
## Scrolling parallax scenery for the travel view: sky, sun, mountains, the region's landmark far
## off, the far tree line, and the ground with the trail. Each terrain has its own set of layers
## (assets/backgrounds/travel/<terrain>/, made by tools/art/regions.py), and each region its own
## landmark (assets/props/lm_*.png). The foreground layer is separate (see add_foreground) so it
## can be drawn over the wagon and haulers.

const DIR := "res://assets/backgrounds/travel/"
const LAYER_WIDTH := 1280.0
const TERRAINS := ["Forest", "Hills", "River", "Swamp", "Mountain"]

## File, pixels per second at walking pace (nearer layers move faster). "landmark" is the region's
## landmark, drawn between the mountains and the far tree line.
const LAYERS := [
	["sky.png", 2.0],
	["sun.png", 0.0],
	["mountains.png", 5.0],
	["landmark", 8.0],
	["far.png", 12.0],
	["ground.png", 30.0],
]
const FOREGROUND_SPEED := 46.0
## Where the landmark stands: its feet sit behind the far tree line, hazed toward the sky.
const LANDMARK_FEET := Vector2(780, 214)
const LANDMARK_HAZE := Color(0.82, 0.88, 0.96)

@export var speed_scale := 1.0
@export var moving := true

var terrain := "Forest"
var landmark := ""

var _layers: Array[Parallax2D] = []
var _speeds: Array[float] = []
## File name -> the Sprite2D showing it, so a new terrain can swap textures in place.
var _sprites := {}
var _landmark: Sprite2D
var _sun: Node2D


func _ready() -> void:
	for entry in LAYERS:
		add_child(_layer(entry[0], entry[1]))
	set_moving(moving)


## Start or stop the scenery scrolling (the wagon is travelling or halted).
func set_moving(on: bool) -> void:
	moving = on
	for i in _layers.size():
		_layers[i].autoscroll = Vector2(-_speeds[i] * speed_scale if on else 0.0, 0)


## Show a terrain's scenery and a region's landmark ("" for none).
func set_scene(new_terrain: String, new_landmark := "") -> void:
	terrain = new_terrain if TERRAINS.has(new_terrain) else "Forest"
	landmark = new_landmark
	for file in _sprites:
		(_sprites[file] as Sprite2D).texture = _tex(file)
	if _landmark != null:
		var path := "res://assets/props/%s.png" % landmark
		_landmark.texture = load(path) if landmark != "" and ResourceLoader.exists(path) else null
		if _landmark.texture != null:
			_landmark.position = LANDMARK_FEET - Vector2(_landmark.texture.get_width() / 2.0, _landmark.texture.get_height())
	if _sun != null:
		_sun.visible = terrain != "Swamp"


func add_foreground(parent: Node) -> Node2D:
	var fg := _layer("foreground.png", FOREGROUND_SPEED)
	fg.z_index = 10
	parent.add_child(fg)
	return fg


func _tex(file: String) -> Texture2D:
	var path := DIR + terrain.to_lower() + "/" + file
	if not ResourceLoader.exists(path):
		path = DIR + file
	return load(path)


func _layer(file: String, speed: float) -> Node2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	if file == "landmark":
		_landmark = sprite
		sprite.modulate = LANDMARK_HAZE
	else:
		sprite.texture = _tex(file)
		if file != "sun.png":
			_sprites[file] = sprite
	if speed == 0.0:
		_sun = sprite
		return sprite
	var p := Parallax2D.new()
	p.repeat_size = Vector2(LAYER_WIDTH, 0)
	p.repeat_times = 2
	p.autoscroll = Vector2(-speed * speed_scale, 0)
	p.ignore_camera_scroll = true
	_layers.append(p)
	_speeds.append(speed)
	p.add_child(sprite)
	return p

extends Node2D
## Travel view preview: the haulers pull the wagon down a narrow trail while the scenery scrolls past.

const ROAD_FEET_Y := 300.0
const WAGON_FEET := Vector2(232, 300)
const HITCH := Vector2(308, 262)

var _backdrop: TravelBackdrop


func _ready() -> void:
	_backdrop = TravelBackdrop.new()
	add_child(_backdrop)

	var cast := Node2D.new()
	cast.y_sort_enabled = false
	add_child(cast)

	var companion := Stand.sprite(load("res://assets/creatures/rimehare.png"), Vector2(122, ROAD_FEET_Y + 8))
	cast.add_child(companion)
	Stand.bob(companion, 1, 0.5)

	var wagon := Stand.sprite(load("res://assets/wagon/wagon_travel.png"), WAGON_FEET)
	cast.add_child(wagon)
	Stand.bob(wagon, 1, 1.2)

	var lead := Stand.sprite(load("res://assets/creatures/brambleback.png"), Vector2(472, ROAD_FEET_Y - 2))
	var hauler := Stand.sprite(load("res://assets/creatures/coilhusk.png"), Vector2(392, ROAD_FEET_Y + 6))
	cast.add_child(_rope(HITCH, Vector2(478, ROAD_FEET_Y - 30)))
	cast.add_child(lead)
	cast.add_child(_rope(HITCH + Vector2(0, 4), Vector2(398, ROAD_FEET_Y - 26)))
	cast.add_child(hauler)
	Stand.bob(lead, 1, 0.6, 0.15)
	Stand.bob(hauler, 1, 0.7)

	_backdrop.add_foreground(self)
	add_child(PreviewHud.make("Travel preview", "Esc: back to title"))


func _rope(from: Vector2, to: Vector2) -> Line2D:
	var line := Line2D.new()
	line.width = 2
	line.default_color = Color("5a3b24")
	for i in 11:
		var t := i / 10.0
		line.add_point(from.lerp(to, t) + Vector2(0, 5.0 * 4.0 * t * (1.0 - t)))
	return line


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

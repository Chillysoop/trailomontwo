extends Node2D
## Travel view preview: the haulers pull the wagon down a narrow trail while the scenery scrolls past.


func _ready() -> void:
	var backdrop := TravelBackdrop.new()
	add_child(backdrop)
	var caravan := Caravan.new()
	add_child(caravan)
	caravan.setup(["coilhusk", "brambleback"], "rimehare")
	caravan.set_walking(true)
	backdrop.add_foreground(self)
	add_child(PreviewHud.make("Travel preview", "Esc: back to title"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

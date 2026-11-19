extends Node2D
## Battle layout preview using the approved formation.
## Lineup mode shows the tile grid; starting combat hides it (Space toggles).

const PLAYER_TEAM := {
	Formation.Row.BACK: ["reedwake", "mirelamp", "rimehare"],
	Formation.Row.FRONT: ["brambleback", "gillhorn", "scythelk"],
}
const ENEMY_TEAM := {
	Formation.Row.FRONT: ["thornfang", "thornfang", "thornfang"],
	Formation.Row.BACK: ["inkhoot", "", "frostsnip"],
}
const BOSS := "hollowstag"

var lineup_mode := true
var _grid: Node2D
var _hud: CanvasLayer


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/backgrounds/battle/trail_forest.png")
	bg.centered = false
	add_child(bg)

	add_child(Stand.sprite(load("res://assets/wagon/wagon.png"), Formation.WAGON_FEET))

	_grid = FormationGrid.new()
	add_child(_grid)

	var units := Node2D.new()
	units.y_sort_enabled = true
	add_child(units)
	_place_team(units, Formation.Side.PLAYER, PLAYER_TEAM)
	_place_team(units, Formation.Side.ENEMY, ENEMY_TEAM)
	_place(units, BOSS, Formation.BOSS_FEET, true, 0.4)

	_hud = PreviewHud.make("Battle layout preview", "")
	add_child(_hud)
	_refresh()


func _place_team(parent: Node2D, side: int, team: Dictionary) -> void:
	for row in team:
		var names: Array = team[row]
		for lane in names.size():
			if names[lane] != "":
				var delay := 0.13 * (lane + 3 * int(row))
				_place(parent, names[lane], Formation.slot_feet(side, row, lane), Formation.faces_left(side), delay)


func _place(parent: Node2D, creature: String, feet: Vector2, face_left: bool, delay: float) -> void:
	var holder := Node2D.new()
	holder.position = feet
	parent.add_child(holder)
	var shadow := Shadow.new()
	holder.add_child(shadow)
	var s := Stand.sprite(load("res://assets/creatures/%s.png" % creature), Vector2.ZERO, face_left)
	holder.add_child(s)
	Stand.bob(s, 1, 1.0, delay)


func _refresh() -> void:
	_grid.visible = lineup_mode
	var hint: Label = _hud.find_child("Hint", true, false)
	hint.text = ("Lineup: grid shown.  Space: start combat" if lineup_mode else "Combat: grid hidden.  Space: back to lineup") + "   Esc: title"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		lineup_mode = not lineup_mode
		_refresh()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


class FormationGrid:
	extends Node2D

	func _draw() -> void:
		for side in [Formation.Side.PLAYER, Formation.Side.ENEMY]:
			for row in [Formation.Row.FRONT, Formation.Row.BACK]:
				for lane in 3:
					var r := Formation.cell_rect(side, row, lane)
					draw_rect(r, Color(1, 0.97, 0.86, 0.09))
					draw_rect(r, Color(1, 0.97, 0.86, 0.28), false, 1.0)


class Shadow:
	extends Node2D

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * 20, sin(a) * 3))
		draw_colored_polygon(pts, Color(0.16, 0.12, 0.12, 0.28))

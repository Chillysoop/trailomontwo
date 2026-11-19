extends TestCase


func test_grids_are_centered_on_screen() -> void:
	var b := Formation.grid_bounds()
	check_eq(b.position.x, Formation.SCREEN_WIDTH - b.end.x, "left and right margins should match")


func test_player_and_enemy_slots_mirror_each_other() -> void:
	for lane in 3:
		for row in [Formation.Row.FRONT, Formation.Row.BACK]:
			var p := Formation.slot_feet(Formation.Side.PLAYER, row, lane)
			var e := Formation.slot_feet(Formation.Side.ENEMY, row, lane)
			check_near(p.x + e.x, Formation.SCREEN_WIDTH, 0.001, "lane %d row %d" % [lane, row])
			check_eq(p.y, e.y)


func test_columns_are_straight() -> void:
	for lane in 3:
		var x := Formation.slot_feet(Formation.Side.PLAYER, Formation.Row.FRONT, lane).x
		check_eq(x, Formation.slot_feet(Formation.Side.PLAYER, Formation.Row.FRONT, 0).x)


func test_cells_do_not_overlap() -> void:
	var rects: Array[Rect2] = []
	for side in [Formation.Side.PLAYER, Formation.Side.ENEMY]:
		for row in [Formation.Row.FRONT, Formation.Row.BACK]:
			for lane in 3:
				rects.append(Formation.cell_rect(side, row, lane))
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			check(not rects[i].intersects(rects[j]), "cells %d and %d overlap" % [i, j])


func test_gap_between_teams_is_wider_than_gap_between_rows() -> void:
	var row_gap := Formation.COLUMN_LEFT[1] - (Formation.COLUMN_LEFT[0] + Formation.CELL_WIDTH)
	var team_gap := Formation.COLUMN_LEFT[2] - (Formation.COLUMN_LEFT[1] + Formation.CELL_WIDTH)
	check(team_gap > row_gap, "teams should be further apart than rows")


func test_boss_stands_right_of_enemy_grid_and_facing() -> void:
	check(Formation.BOSS_FEET.x > Formation.grid_bounds().end.x, "boss should stand right of the enemy grid")
	check(Formation.faces_left(Formation.Side.ENEMY), "enemies face left")
	check(not Formation.faces_left(Formation.Side.PLAYER), "player team faces right")

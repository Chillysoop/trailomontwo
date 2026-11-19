class_name Formation
extends RefCounted
## Battle layout on the 640x360 screen (approved mockup: battle-final.png).
##
## Each side stands in a 2 column x 3 lane grid. The two grids together are
## centered on the screen width, with equal open space on the left (wagon)
## and on the right (enemy bosses). Columns are straight, not slanted.

enum Side { PLAYER, ENEMY }
enum Row { FRONT, BACK }

const SCREEN_WIDTH := 640
## Feet line of each lane, top to bottom.
const LANE_FEET_Y: Array[int] = [202, 268, 334]
## Left edge of each grid column, left to right: player back, player front, enemy front, enemy back.
const COLUMN_LEFT: Array[int] = [154, 228, 350, 424]
const CELL_WIDTH := 62
## A cell reaches this far above and below a creature's feet.
const CELL_ABOVE_FEET := 38
const CELL_BELOW_FEET := 10
## Where a boss stands: centered in the open space to the right of the enemy grid.
const BOSS_FEET := Vector2(563, 270)
## The wagon's bottom edge and its horizontal center (partly off the left edge on purpose).
const WAGON_FEET := Vector2(26, 292)


static func column_index(side: int, row: int) -> int:
	if side == Side.PLAYER:
		return 1 if row == Row.FRONT else 0
	return 2 if row == Row.FRONT else 3


static func cell_rect(side: int, row: int, lane: int) -> Rect2:
	var left := COLUMN_LEFT[column_index(side, row)]
	var feet_y := LANE_FEET_Y[lane]
	return Rect2(left, feet_y - CELL_ABOVE_FEET, CELL_WIDTH, CELL_ABOVE_FEET + CELL_BELOW_FEET)


## Where a creature's feet go: horizontally centered in its cell, on the lane's feet line.
static func slot_feet(side: int, row: int, lane: int) -> Vector2:
	var rect := cell_rect(side, row, lane)
	return Vector2(rect.position.x + rect.size.x / 2.0, LANE_FEET_Y[lane])


## Enemies face left, toward the player's team; the player's team faces right.
static func faces_left(side: int) -> bool:
	return side == Side.ENEMY


static func grid_bounds() -> Rect2:
	var top := LANE_FEET_Y[0] - CELL_ABOVE_FEET
	var bottom := LANE_FEET_Y[LANE_FEET_Y.size() - 1] + CELL_BELOW_FEET
	var left := COLUMN_LEFT[0]
	var right := COLUMN_LEFT[COLUMN_LEFT.size() - 1] + CELL_WIDTH
	return Rect2(left, top, right - left, bottom - top)

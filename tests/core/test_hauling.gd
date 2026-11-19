extends TestCase
## Uses the worked example from the design doc.


func test_design_example_can_move() -> void:
	var need := Hauling.demand(80, 140, 1.2)
	check_near(need, 264.0)
	check_eq(Hauling.evaluate(need, Hauling.available([150, 130])), Hauling.Result.NORMAL)


func test_design_example_extra_cargo_is_blocked() -> void:
	var need := Hauling.demand(80, 220, 1.2)
	check_near(need, 360.0)
	check_eq(Hauling.evaluate(need, Hauling.available([150, 130])), Hauling.Result.BLOCKED)


func test_push_zone() -> void:
	check_eq(Hauling.evaluate(300, 280), Hauling.Result.PUSH)
	check_eq(Hauling.evaluate(350, 280), Hauling.Result.PUSH)
	check_eq(Hauling.evaluate(351, 280), Hauling.Result.BLOCKED)

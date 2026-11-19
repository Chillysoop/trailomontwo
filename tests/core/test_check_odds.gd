extends TestCase


func test_design_example_with_specialist() -> void:
	check_eq(CheckOdds.for_advantage(2), {"success": 65, "mixed": 25, "failure": 10})


func test_design_example_without_specialist() -> void:
	check_eq(CheckOdds.for_advantage(-4), {"success": 35, "mixed": 25, "failure": 40})


func test_success_is_capped_at_90() -> void:
	check_eq(CheckOdds.for_advantage(20), {"success": 90, "mixed": 10, "failure": 0})


func test_success_floor_is_10() -> void:
	check_eq(CheckOdds.for_advantage(-20)["success"], 10)


func test_outcomes_always_sum_to_100() -> void:
	for advantage in range(-15, 16):
		var odds := CheckOdds.for_advantage(advantage)
		check_eq(odds["success"] + odds["mixed"] + odds["failure"], 100, "at advantage %d" % advantage)

extends TestCase


## A crossing with random events off, so day and supply counts are exact.
func _fresh() -> Expedition:
	var e := Expedition.new_default(1)
	e.events_enabled = false
	return e


func _seg(from: String, to: String) -> Dictionary:
	for s in TestRoute.exits(from):
		if s["to"] == to:
			return s
	return {}


func test_daily_upkeep_matches_design() -> void:
	var e := _fresh()
	# 1 human + large 2 + large 2 + medium 1 + small 0.5 + small 0.5 + large 2
	check_near(e.daily_provisions(), 9.0)
	check_near(e.daily_water(), 1.0 + 0.5 * 6)


func test_every_junction_can_reach_the_goal() -> void:
	for start in TestRoute.JUNCTIONS:
		var seen := {start: true}
		var frontier: Array = [start]
		while frontier.size() > 0:
			var j: String = frontier.pop_back()
			for s in TestRoute.exits(j):
				if not seen.has(s["to"]):
					seen[s["to"]] = true
					frontier.append(s["to"])
		check(seen.has(TestRoute.GOAL), "%s cannot reach the goal" % start)


func test_travel_spends_days_and_supplies() -> void:
	var e := _fresh()
	var food := e.provisions
	check(e.travel(_seg("eastgate", "mossford")), "forest segment should be travelable")
	check_eq(e.at, "mossford")
	check_eq(e.day, 3)
	check_near(e.provisions, food - 2 * e.daily_provisions())


func test_forest_route_reaches_westwatch_with_default_supplies() -> void:
	var e := _fresh()
	for pair in [["eastgate", "mossford"], ["mossford", "rail_bridge"], ["rail_bridge", "thornmarsh"], ["thornmarsh", "westwatch"]]:
		check(e.travel(_seg(pair[0], pair[1])), "could not travel %s" % [pair])
	check_eq(e.state, Expedition.State.ARRIVED)
	check(e.health > 0, "traveller should survive the main route")


func test_running_out_of_food_and_water_fails_the_crossing() -> void:
	var e := _fresh()
	e.provisions = 0.0
	e.water = 0.0
	for i in 10:
		e.spend_day()
	check_eq(e.state, Expedition.State.FAILED)
	check(e.fail_reason != "", "failure should say why")


func test_overloaded_wagon_is_blocked_on_steep_ground() -> void:
	var e := _fresh()
	e.cargo.append({"name": "Iron rails", "weight": 200.0})
	var f := e.forecast(_seg("cogspire", "westwatch"))
	check_eq(f["hauling"], Hauling.Result.BLOCKED)
	check(not f["can_go"], "blocked segment cannot be travelled")


func test_pushing_takes_longer() -> void:
	var e := _fresh()
	e.cargo.append({"name": "Spare wheels", "weight": 40.0})
	var seg := _seg("eastgate", "ridge_fork")
	var f := e.forecast(seg)
	check_eq(f["hauling"], Hauling.Result.PUSH)
	check_eq(f["days"], 2)

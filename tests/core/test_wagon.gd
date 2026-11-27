extends TestCase


func _seg(from: String, to: String) -> Dictionary:
	for s in TestRoute.exits(from):
		if s["to"] == to:
			return s
	return {}


func test_wear_grows_with_load_terrain_and_pushing() -> void:
	var light := Wagon.wear_per_day(1.0, 0.0, false)
	check(Wagon.wear_per_day(1.0, 200.0, false) > light, "heavier cargo should wear faster")
	check(Wagon.wear_per_day(1.6, 0.0, false) > light, "steeper ground should wear faster")
	check_near(Wagon.wear_per_day(1.0, 0.0, true), light * 2.0)


func test_no_breakdowns_before_the_warning() -> void:
	check_near(Wagon.breakdown_chance(0.0), 0.0)
	check_near(Wagon.breakdown_chance(Wagon.WARN_WEAR), 0.0)
	check(Wagon.breakdown_chance(90.0) > 0.0, "a worn wagon should risk breaking")
	check(Wagon.breakdown_chance(100.0) <= 0.5, "breakdowns are never certain")


func test_one_breakdown_cannot_wreck_a_healthy_wagon() -> void:
	var w := Wagon.new()
	w.break_part(Wagon.Part.RUNNING_GEAR)
	check(w.integrity > 0, "a healthy wagon survives one breakdown")
	check_eq(w.part_name(), "axle")


func test_broken_axle_strands_the_wagon_until_repaired() -> void:
	var e := Expedition.new_default(1)
	e.wagon.break_part(Wagon.Part.RUNNING_GEAR)
	var seg := _seg("eastgate", "mossford")
	check(not e.forecast(seg)["can_go"], "a broken axle should stop travel")
	var spares := e.spare_count("axle")
	e.repair()
	check_eq(e.spare_count("axle"), spares - 1)
	check_eq(e.day, 2)
	check(e.forecast(seg)["can_go"], "repaired wagon should travel again")


func test_repair_without_a_spare_takes_two_days_and_costs_integrity() -> void:
	var e := Expedition.new_default(1)
	e.spares = {}
	e.roster.clear()
	e.wagon.break_part(Wagon.Part.HARNESS)
	var integrity := e.wagon.integrity
	e.repair()
	check_eq(e.day, 3)
	check_eq(e.wagon.broken, Wagon.Part.NONE)
	check(e.wagon.integrity < integrity, "patching without a kit should cost integrity")


func test_broken_harness_cuts_hauling() -> void:
	var e := Expedition.new_default(1)
	var full := e.hauling_available()
	e.wagon.break_part(Wagon.Part.HARNESS)
	check_near(e.hauling_available(), full * Wagon.HARNESS_PENALTY)


func test_fatigue_weakens_haulers_and_rest_restores_them() -> void:
	var e := Expedition.new_default(1)
	var fresh := e.hauling_available()
	e.travel(_seg("eastgate", "mossford"))
	check(e.hauling_available() < fresh, "travel should tire the haulers")
	e.rest()
	e.rest()
	check_near(e.hauling_available(), fresh)


func test_adding_a_hauler_lets_an_overloaded_wagon_through() -> void:
	var e := Expedition.new_default(1)
	e.cargo.append({"name": "Iron ore", "weight": 150.0, "value": 60})
	var seg := _seg("cogspire", "westwatch")
	check(not e.forecast(seg)["can_go"], "too heavy with two haulers")
	e.toggle_hauler("scythelk")
	check_eq(e.forecast(seg)["hauling"], Hauling.Result.PUSH)
	e.toggle_hauler("reedwake")
	check(not e.haulers.has("reedwake"), "non-haulers can't be harnessed")


func test_dropping_cargo_lightens_the_load() -> void:
	var e := Expedition.new_default(1)
	var w := e.cargo_weight()
	var v := e.cargo_value()
	e.drop_cargo(1)
	check_near(e.cargo_weight(), w - 60.0)
	check_eq(e.cargo_value(), v - 150)


func test_overloaded_pushing_eventually_breaks_something() -> void:
	var e := Expedition.new_default(7)
	e.wagon.wear = 95.0
	for i in 40:
		e._wear_day(1.4, true)
		if e.wagon.broken != Wagon.Part.NONE:
			break
	check(e.wagon.broken != Wagon.Part.NONE, "a worn, pushed wagon should break down")

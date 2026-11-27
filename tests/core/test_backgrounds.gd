extends TestCase
## The trail boss's background: picked once, each with its own edge.


func _new(bg: String) -> Expedition:
	var e := Expedition.new_game("mossmole", 2)
	e.set_background(bg)
	return e


func test_background_is_picked_once() -> void:
	var e := _new("tinker")
	e.set_background("merchant")
	check_eq(e.background, "tinker")
	var x := Expedition.new_game("mossmole", 2)
	x.set_background("nonsense")
	check_eq(x.background, "")


func test_merchant_starts_richer_and_is_paid_more() -> void:
	var plain := Expedition.new_game("mossmole", 2)
	var m := _new("merchant")
	check_eq(m.coins, plain.coins + Backgrounds.MERCHANT_COINS)


func test_tinker_kit_and_slower_wear() -> void:
	var plain := Expedition.new_game("mossmole", 2)
	var t := _new("tinker")
	check_eq(t.spare_count("axle"), plain.spare_count("axle") + 1)
	check_near(t.wear_mult(), Backgrounds.TINKER_WEAR)
	t.wagon.break_part(Wagon.Part.CANOPY)
	t.spares.erase("canvas")
	check(t.repair_plan()["skilled"], "a tinker's jury-rig is skilled")


func test_herbalist_knows_plants_and_checks_better() -> void:
	var h := _new("herbalist")
	check_eq(h.known_plants.size(), Camp.PLANTS.size())
	check_eq(h.bg_bonus("forage"), Backgrounds.CHECK_BONUS)
	check_eq(h.bg_bonus("strength"), 0)
	var plain := Expedition.new_game("mossmole", 2)
	check(h._ailment_chance() < plain._ailment_chance(), "fewer ailments")


func test_ranger_sees_further() -> void:
	var r := Expedition.new_default(3)
	r.map = WorldMap.generate(3)
	r.setup_map(1)
	var p := Expedition.new_default(3)
	p.map = WorldMap.generate(3)
	p.setup_map(1)
	r.background = "ranger"
	r.seen.clear()
	p.seen.clear()
	r.reveal(r.at)
	p.reveal(p.at)
	check(r.seen.size() > p.seen.size(), "the ranger sees more")
	check_eq(r.bg_bonus("scout"), Backgrounds.CHECK_BONUS)


func test_background_carries_over() -> void:
	var e := _new("ranger")
	var n := SaveGame.next_crossing(SaveGame.caravan(e), 3, 2)
	check_eq(n.background, "ranger")


# ---------- destinations ----------

func _world() -> Expedition:
	var e := Expedition.new_default(3)
	e.map = WorldMap.generate(3)
	e.setup_map(1)
	e.departed = false
	return e


func test_two_destinations_on_the_far_edge() -> void:
	var e := _world()
	var d := e.destinations()
	check_eq(d.size(), 2)
	check_eq(d[0]["to"], e.main_goal)
	check(d[1]["to"] != d[0]["to"], "a different market")
	check_eq(int(e.map.junctions[d[1]["to"]]["layer"]), int(e.map.junctions[d[0]["to"]]["layer"]))
	check(Expedition.new_default(1).destinations().is_empty(), "none on the test route")


func test_choosing_the_other_market_moves_goal_frost_and_pay() -> void:
	var e := _world()
	var alt: Dictionary = e.destinations()[1]
	check(e.choose_destination("alt"), "chosen")
	check_eq(e.map.goal, alt["to"])
	check_eq(e.destination(), "alt")
	check_near(e.dest_pay, float(alt["pay"]))
	check(float(alt["pay"]) >= Expedition.PAY_MIN and float(alt["pay"]) <= Expedition.PAY_MAX, "pay in range")
	check_eq(e.frost_day, e.day + ceili(e.map.shortest_days(e.map.start, e.map.goal) * Expedition.FROST_SLACK) + Expedition.FROST_EXTRA)
	check(e.choose_destination("main"), "and back")
	check_eq(e.map.goal, e.main_goal)
	e.departed = true
	check(not e.choose_destination("alt"), "not once you've set out")


func test_workshop_never_on_an_edge() -> void:
	for no in [1, 2, 3]:
		var e := _world()
		e.set_crossing(no)
		var l := int(e.map.junctions[e.workshop()]["layer"])
		check(l > 0 and l < WorldMap.LAYERS - 1, "inland")

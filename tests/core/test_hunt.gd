extends TestCase
## Hunting: a different kind of auto-battle. Prey bolt instead of fighting, one charger
## fights back, and every creature knocked out before it gets away is food.


## A caravan stopped at a wild (non-town) stop of a generated world crossing.
func _at_wild_stop() -> Expedition:
	var e := Expedition.new_default(3)
	e.map = WorldMap.generate(3)
	e.setup_map(1)
	for id in e.map.junctions:
		if not Expedition.NO_GAME.has(e.map.kind_of(id)):
			e.at = id
			break
	return e


func _hunt_battle(seed_no: int) -> Battle:
	var e := _at_wild_stop()
	check(e.start_hunt(), "the hunt starts")
	return e.make_battle(false, seed_no)


func test_prey_never_attack_and_bolt_on_their_own() -> void:
	var b := _hunt_battle(7)
	check(b.hunt, "hunt mode")
	var prey := 0
	var chargers := 0
	for f in b.side_fighters(Formation.Side.ENEMY):
		if f.prey:
			prey += 1
		else:
			chargers += 1
	check(prey >= 4, "a herd of prey")
	check_eq(chargers, 1)
	b.run_to_end()
	check(b.time <= Battle.HUNT_SECS + Battle.TICK * 2.0, "the hunt is short")
	for e in b.events:
		if e["t"] == "hit" and int(e["src"]) >= 0:
			var src := b.fighter(int(e["src"]))
			check(not src.prey, "prey never strike")


func test_a_hit_that_does_not_drop_prey_startles_it() -> void:
	var b := _hunt_battle(3)
	var target: Fighter = null
	for f in b.side_fighters(Formation.Side.ENEMY):
		if f.prey:
			target = f
			break
	target.bolt_at = 99.0
	b._deal(null, target, 1.0, "basic", "Test")
	check(target.bolt_at <= b.time + Battle.STARTLE_SECS + 0.001, "it bolts soon")


func test_the_bag_becomes_food_and_costs_a_day() -> void:
	var e := _at_wild_stop()
	var day := e.day
	e.provisions = 20.0
	check(e.start_hunt(), "the hunt starts")
	check_eq(e.day, day + 1)
	var b := e.make_battle(false, 11)
	b.run_to_end()
	var food := e.provisions
	var bag := b.hunt_bag()
	var lines := e.finish_battle(b)
	check(not lines.is_empty(), "the hunt reports")
	if bag.is_empty():
		check_near(e.provisions, food)
	else:
		check(e.provisions > food, "food from the hunt")
	check(e.pending_encounter.is_empty(), "the hunt is over")


func test_one_hunt_per_stop_and_none_in_town() -> void:
	var e := _at_wild_stop()
	check_eq(e.hunt_block(), "")
	e.start_hunt()
	e.finish_battle(e.make_battle(false, 1))
	check_eq(e.hunt_block(), "spooked")
	for id in e.map.junctions:
		if e.map.kind_of(id) == "town":
			e.at = id
	check_eq(e.hunt_block(), "town")


func test_hunts_keep_battle_items() -> void:
	var e := _at_wild_stop()
	var id: String = BattleItems.ITEMS.keys()[0]
	e.items = {id: 1}
	e.item_slots = [id, "", ""] as Array[String]
	e.start_hunt()
	var b := e.make_battle(false, 5)
	check(b.items_used.is_empty(), "no battle items spent on a hunt")


func test_food_left_behind_when_the_wagon_is_full() -> void:
	var e := _at_wild_stop()
	e.start_hunt()
	e.provisions += e.free_space() / Outfitter.weight_of("food") * 10.0
	var b := e.make_battle(false, 2)
	# Knock the whole herd out for the test.
	for f in b.side_fighters(Formation.Side.ENEMY):
		f.hp = 0.0
	b.run_to_end()
	var food := e.provisions
	var lines := e.finish_battle(b)
	check_near(e.provisions, food, 1.0)
	var left := false
	for l in lines:
		if l.contains("left behind"):
			left = true
	check(left, "says what was left behind")


# ---------- delivery jobs ----------

## A world crossing standing at a stop with a job board.
func _at_board() -> Expedition:
	for s in range(1, 40):
		var e := Expedition.new_default(s)
		e.map = WorldMap.generate(s)
		e.setup_map(1)
		for id in e.map.junctions:
			if Expedition.JOB_BOARDS.has(e.map.kind_of(id)) and id != e.map.goal:
				e.at = id
				if not e.delivery_offer().is_empty():
					return e
	return null


func test_a_job_board_offers_a_delivery_further_on() -> void:
	var e := _at_board()
	check(e != null, "some stop has a job")
	var o := e.delivery_offer()
	check(e.map.hops(o["to"], e.map.goal) < e.map.hops(e.at, e.map.goal), "on the way to the goal")
	check(int(o["due"]) > e.day + e.map.shortest_days(e.at, o["to"]), "time to make it")
	check_eq(e.delivery_offer(), o)


func test_taking_a_job_loads_it_and_delivering_pays() -> void:
	var e := _at_board()
	var o := e.delivery_offer()
	var crates := e.cargo.size()
	check(e.take_delivery(), "took it")
	check_eq(e.cargo.size(), crates + 1)
	check(e.delivery_offer().is_empty(), "one job per board")
	var value := e.cargo_value()
	var coins := e.coins
	e.at = o["to"]
	e._hand_over_deliveries()
	check_eq(e.coins, coins + int(o["pay"]))
	check_eq(e.cargo.size(), crates)
	check_eq(e.cargo_value(), value)


func test_late_deliveries_pay_half() -> void:
	var e := _at_board()
	var o := e.delivery_offer()
	e.take_delivery()
	var coins := e.coins
	e.day = int(o["due"]) + 1
	e.at = o["to"]
	e._hand_over_deliveries()
	check_eq(e.coins, coins + int(o["pay"]) / 2)


func test_no_job_without_room() -> void:
	var e := _at_board()
	e.provisions += e.free_space() / Outfitter.weight_of("food") * 10.0
	check(not e.can_take_delivery(), "wagon full")

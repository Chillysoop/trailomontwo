extends TestCase
## Camp life: morale, cooking from the pantry, foraging and unknown plants, the campfire.


func test_morale_bands_change_checks() -> void:
	var e := Expedition.new_default(1)
	var ev := Rivers.make(3, false, false, 1)
	e.morale = 60
	var mid: Array = e.event_choices(ev)
	e.morale = 90
	var high: Array = e.event_choices(ev)
	e.morale = 10
	var low: Array = e.event_choices(ev)
	for i in mid.size():
		if mid[i]["rolled"]:
			check(int(high[i]["odds"]["success"]) >= int(mid[i]["odds"]["success"]), "spirited helps")
			check(int(low[i]["odds"]["success"]) <= int(mid[i]["odds"]["success"]), "grim hurts")
			check_eq(high[i]["morale"], 1)


func test_thin_rations_and_hunger_drag_morale_down() -> void:
	var e := Expedition.new_default(1)
	var m := e.morale
	e.rations = "thin"
	e.spend_day()
	check(e.morale < m, "thin rations hurt")
	m = e.morale
	e.provisions = 0.0
	e.spend_day()
	check(e.morale <= m + Camp.DRIFT["hungry"] + Camp.DRIFT["thin_rations"], "hunger hurts a lot")


func test_change_morale_clamps() -> void:
	var e := Expedition.new_default(1)
	e.change_morale(500)
	check_eq(e.morale, Camp.MAX)
	e.change_morale(-500, "Disaster")
	check_eq(e.morale, 0)
	check_eq(e.morale_band(), "grim")


func test_cooking_uses_the_pantry_once_per_stop() -> void:
	var e := Expedition.new_default(1)
	check_eq(e.cook_block(), "pantry")
	e.pantry = {"fish": 1, "herbs": 1}
	e.morale = 50
	var food := e.provisions
	check(not e.cook().is_empty(), "cooked")
	check_eq(e.pantry, {})
	check_near(e.provisions, food - Camp.MEAL_FOOD)
	check_eq(e.morale, 62)
	e.pantry = {"berries": 1}
	check_eq(e.cook_block(), "cooked")


func test_best_recipe_prefers_the_feast() -> void:
	check_eq(Camp.best_recipe({"fish": 1, "herbs": 1})["id"], "fish_stew")
	check_eq(Camp.best_recipe({"berries": 2})["id"], "berry_cobbler")
	check(Camp.best_recipe({}).is_empty(), "nothing")


func test_forage_fills_the_pantry() -> void:
	var e := Expedition.new_default(1)
	e.at = "mossford"
	check(e.forage(), "can forage")
	check_eq(e.pending_event["id"], "forage")
	check_eq(e.forage_block(), "busy")
	e.resolve_event(0, 0)
	check(e.pantry_count() > 0, "found something")
	check_eq(e.forage_block(), "picked")


func test_no_foraging_in_town() -> void:
	var e := Expedition.new_default(1)
	e.at = "eastgate"
	check_eq(e.forage_block(), "town")


func test_unknown_plants_are_risky_until_learned() -> void:
	var bad := Camp.forage_card("Forest", ["herbs"], "snapwort", false, false)
	var eat: Dictionary = bad["choices"][1]
	check(eat.get("risky", false), "a gamble")
	check(not Expedition.is_safe(eat), "not a safe pick")
	var e := Expedition.new_default(1)
	e.pending_event = bad
	e.resolve_event(1)
	check(e.known_plants.has("snapwort"), "learned")
	check(e.fever_days > 0, "it was bad")
	var known := Camp.forage_card("Forest", ["herbs"], "snapwort", true, false)
	check_eq(known["choices"].size(), 2, "known bad plants aren't offered")
	var good := Camp.forage_card("Forest", ["herbs"], "sun_figs", false, true)
	check(not good["choices"][1].get("risky", true), "the forager knows")


func test_rest_lights_the_campfire_once_per_stop() -> void:
	var e := Expedition.new_default(1)
	e.rest()
	check_eq(e.pending_event.get("id", ""), "campfire")
	e.resolve_event(0)
	e.rest()
	check(e.pending_event.is_empty(), "once per stop")


func test_pantry_and_plants_carry_over_but_morale_resets() -> void:
	var e := Expedition.new_default(1)
	e.pantry = {"berries": 2}
	e.known_plants = {"sun_figs": true}
	e.morale = 20
	var n := SaveGame.next_crossing(SaveGame.caravan(e), 3, 2)
	check_eq(n.pantry, {"berries": 2})
	check(n.known_plants.has("sun_figs"), "remembered")
	check_eq(n.morale, Camp.START)

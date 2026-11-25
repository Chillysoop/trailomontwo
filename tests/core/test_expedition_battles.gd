extends TestCase
## Battles inside a crossing: lineup, encounters, aftermath, knock-outs and recovery.


func _fresh() -> Expedition:
	var e := Expedition.new_default(5)
	e.events_enabled = false
	return e


func _seg(from: String, to: String) -> Dictionary:
	for s in TestRoute.exits(from):
		if s["to"] == to:
			return s
	return {}


func test_default_lineup_fills_six_cells_with_guards_in_front() -> void:
	var e := _fresh()
	check_eq(e.lineup.size(), 6)
	check_eq(e.bench().size(), 0)
	var bramble: Vector2i = e.lineup_cell("brambleback")
	check_eq(bramble.x, 0, "the guard starts in the front row")
	var healer: Vector2i = e.lineup_cell("reedwake")
	check_eq(healer.x, 1, "the healer starts in the second row")


func test_placing_swaps_creatures() -> void:
	var e := _fresh()
	var a: Vector2i = e.lineup_cell("brambleback")
	var b: Vector2i = e.lineup_cell("reedwake")
	e.place_in_lineup("brambleback", b)
	check_eq(e.lineup[b], "brambleback")
	check_eq(e.lineup[a], "reedwake")


func test_sitting_out_keeps_at_least_one() -> void:
	var e := _fresh()
	for id in e.roster:
		e.remove_from_lineup(id)
	check_eq(e.lineup.size(), 1)
	e.tidy_lineup()
	check_eq(e.lineup.size(), 6)


func test_guardian_waits_on_the_last_stretch_to_westwatch() -> void:
	var e := _fresh()
	e.at = "thornmarsh"
	check(e.start_trip(_seg("thornmarsh", "westwatch")), "can set off")
	while e.step_day():
		if not e.pending_encounter.is_empty():
			break
	check(bool(e.pending_encounter.get("guardian", false)), "the guardian should block the way")
	check_eq(e.state, Expedition.State.TRAVELLING, "not arrived yet")
	check(e.encounter_choices().size() == 1, "no way around the guardian")
	e.auto_fight()
	while e.step_day():
		pass
	check_eq(e.state, Expedition.State.ARRIVED)


func test_a_fight_on_the_last_day_does_not_skip_the_guardian() -> void:
	var e := _fresh()
	e.at = "thornmarsh"
	check(e.start_trip(_seg("thornmarsh", "westwatch")), "can set off")
	# A wild pack jumps the wagon on the very last day of the final road.
	e.trip_days_left = 0.0
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.0, "guardian": false}
	e.auto_fight()
	e.step_day()
	check(bool(e.pending_encounter.get("guardian", false)), "the guardian should still block the way")
	check_eq(e.state, Expedition.State.TRAVELLING, "not arrived before the guardian")


func test_guardian_victory_names_this_crossings_guardian_and_goal() -> void:
	var e := _fresh()
	e.set_crossing(2)
	e.pending_encounter = {"pack": e.guardian_pack(), "scale": 0.3, "guardian": true}
	var lines := e.auto_fight()
	check(lines[0].contains(String(e.guardian_pack()["title"])), "names the guardian: " + lines[0])
	check(not lines[0].contains("Hollow Stag"), "not the first crossing's guardian")


func test_victory_brings_supplies() -> void:
	var e := _fresh()
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.0, "guardian": false}
	var food := e.provisions
	var b := e.make_battle(false, 1)
	check_eq(b.run_to_end(), Battle.Outcome.VICTORY)
	e.finish_battle(b)
	check_near(e.provisions, food + Expedition.VICTORY_FOOD)
	check(e.pending_encounter.is_empty(), "encounter cleared")


func test_defeat_breaches_the_wagon() -> void:
	var e := _fresh()
	for id in e.roster:
		e.creature_hp[id] = 0.0
	e.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}
	check(not e.can_fight(), "nobody can fight")
	var food := e.provisions
	e.auto_fight()
	check_eq(e.wagon.integrity, 100 - Expedition.BREACH_INTEGRITY)
	check(e.provisions < food, "they stole food")


func test_knocked_out_creatures_cannot_help_or_haul_until_rest() -> void:
	var e := _fresh()
	e.creature_hp["rimehare"] = 0.0
	e.creature_hp["brambleback"] = 0.0
	e.creature_hp["coilhusk"] = 0.0
	check(e.best_helper("scout") != "rimehare", "a knocked-out scout can't help")
	check_near(e.hauling_available(), 0.0)
	check(not e.forecast(_seg("eastgate", "mossford"))["can_go"], "no conscious haulers, no travel")
	e.rest()
	check(e.conscious("rimehare"), "rest wakes them")
	check(e.forecast(_seg("eastgate", "mossford"))["can_go"], "can travel after resting")


func test_slip_past_and_bribe() -> void:
	var e := _fresh()
	e.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}
	var r := e.resolve_encounter("slip", 0)
	check_eq(r["outcome"], "success")
	check(e.pending_encounter.is_empty(), "slipped past")
	e.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}
	r = e.resolve_encounter("slip", 99)
	check(r["fight"] and r["ambush"], "a failed sneak means an ambush")
	check(not e.pending_encounter.is_empty(), "the fight still waits")
	var food := e.provisions
	e.resolve_encounter("bribe")
	check_near(e.provisions, food - Expedition.BRIBE_FOOD)


func test_random_battles_happen_on_risky_routes() -> void:
	var seen := 0
	for s in 30:
		var e := Expedition.new_default(s)
		e.guardian_enabled = false
		e.travel(_seg("eastgate", "ridge_fork"))
		for line in e.journal:
			if line.begins_with("Victory") or line.begins_with("Defeat") or line.begins_with("Both sides"):
				seen += 1
	check(seen > 0, "some crossings should meet a wild pack")

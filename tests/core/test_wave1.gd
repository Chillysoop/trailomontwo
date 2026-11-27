extends TestCase
## Names, seals, the town healer, type matchups shown in battle and road trainers.


func test_nicknames_show_and_follow_evolution() -> void:
	var e := Expedition.new_game("mossmole", 3)
	check_eq(e.display_name("mossmole"), "Mossmole", "species name by default")
	e.rename("mossmole", "  Clod  ")
	check_eq(e.display_name("mossmole"), "Clod", "trimmed nickname")
	e.rename("mossmole", "A name far too long for a tag")
	check_eq(e.display_name("mossmole").length(), Expedition.NICKNAME_MAX, "cut to fit")
	e.rename("mossmole", "Clod")
	e.carry_nickname("mossmole", "mossbrock")
	check_eq(e.display_name("mossbrock"), "Clod", "the name comes along when it evolves")
	e.rename("mossbrock", "")
	check_eq(e.display_name("mossbrock"), "Mossbrock", "an empty name clears it")


func test_nickname_survives_evolve() -> void:
	var e := Expedition.new_game("mossmole", 3)
	e.rename("mossmole", "Clod")
	while e.level("mossmole") < Species.evolve_level("mossmole"):
		e.gain_xp("mossmole", Leveling.xp_to_next(e.level("mossmole")) - int(e.xp.get("mossmole", 0)))
	check(e.evolve("mossmole", "mossbrock") != "", "evolved")
	check_eq(e.display_name("mossbrock"), "Clod")


func test_beating_a_guardian_earns_its_seal() -> void:
	var e := Expedition.new_default(3)
	e.pending_encounter = {"pack": CombatData.guardian_for(1), "scale": 0.2, "guardian": true}
	var b := e.make_battle(false, 1)
	b.run_to_end()
	check(b.outcome == Battle.Outcome.VICTORY, "won with tiny foes")
	e.finish_battle(b)
	check(e.seals.has("hollow_stag"), "seal earned")
	check_eq(Expedition.seal_name("hollow_stag"), "Seal of the Hollow Stag")
	check(SaveGame.CARRY.has("seals") and SaveGame.CARRY.has("nicknames"), "both carry to the next crossing")


func test_healer_costs_coins_and_heals_once_per_stop() -> void:
	var e := Expedition.new_game("mossmole", 3)
	e.pending_recruit = "thornfang"
	e.recruit()
	e.map.junctions[e.at]["kind"] = "town"
	check_eq(e.heal_cost(), 0, "nobody hurt, nothing to pay")
	e.creature_hp["mossmole"] = 1.0
	e.creature_hp["thornfang"] = 0.0
	check_eq(e.heal_cost(), Expedition.HEAL_COST_HURT + Expedition.HEAL_COST_KO)
	e.coins = 100
	var day := e.day
	check(e.visit_healer() != "", "healed")
	check_eq(e.coins, 100 - Expedition.HEAL_COST_HURT - Expedition.HEAL_COST_KO)
	check_eq(float(e.creature_hp["thornfang"]), e.max_hp("thornfang"), "knocked out one is back")
	check_eq(e.day, day, "no day lost")
	check(not e.has_healer(), "once per stop")


func test_standing_marks_matchups() -> void:
	# River hits Forest hard; Forest hits Swamp hard.
	var st := CombatData.standing("mossmole", ["sporetoad", "minnowisp"])
	check(st["up"].has("Swamp"), "a Forest creature hits Swamp hard")
	check(st["down"].has("River"), "River hits Forest hard")


func test_trainers_have_their_teams() -> void:
	for id in ["trainer_beetles", "trainer_twins", "trainer_climber"]:
		var pack: Dictionary = TrailEvents.PACKS[id]
		for s in pack["front"] + pack["back"]:
			if String(s) != "":
				check(Species.DATA.has(String(s)), "%s exists" % s)
		check(not TrailEvents.by_id(id).is_empty(), "%s can turn up" % id)

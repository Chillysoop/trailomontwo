extends TestCase
## A new caravan sets out with one starter; every other Trailomon is caught after wild wins.


func test_new_game_has_only_the_starter() -> void:
	for id in Expedition.STARTERS:
		check(Species.DATA.has(id), "%s exists" % id)
		check_eq(Species.evolutions(id).size(), 1, "%s evolves" % id)
		var e := Expedition.new_game(id, 3)
		check_eq(e.roster, [id] as Array[String], "only the starter travels")
		check(e.stored.is_empty(), "nothing in storage")
		check_eq(e.lineup.size(), 1, "the starter stands in the lineup")
		check_eq(e.lures, Expedition.START_LURES, "a few lures to start")
		check(e.techniques.is_empty(), "no technique scrolls yet")


func test_unknown_starter_falls_back() -> void:
	var e := Expedition.new_game("hollowstag", 3)
	check_eq(e.roster[0], Expedition.STARTERS[0])


func test_a_lone_starter_can_move_the_wagon() -> void:
	var e := Expedition.new_game("mossmole", 3)
	var demand := Hauling.demand(Wagon.EMPTY_MASS, e.cargo_weight(), 1.0)
	check(Hauling.evaluate(demand, e.hauling_available()) == Hauling.Result.NORMAL, "easy ground at normal speed")
	var steep := Hauling.demand(Wagon.EMPTY_MASS, e.cargo_weight(), WorldMap.TERRAIN_FACTOR["Mountain"])
	check(Hauling.evaluate(steep, e.hauling_available()) != Hauling.Result.BLOCKED, "mountains are a slow push, never a dead end")


func test_catches_join_the_team_until_it_is_full() -> void:
	var e := Expedition.new_game("cragkid", 3)
	var wild := ["thornfang", "lianetail", "mossmole", "crayhopper", "acornet", "pebblotter"]
	for id in wild:
		e.pending_recruit = id
		check(e.recruit() != "", "%s joined" % id)
	check_eq(e.roster.size(), Expedition.TEAM_MAX, "team of 6")
	check(e.stored.has("pebblotter"), "the seventh goes to storage")
	check_eq(e.lineup.size(), Expedition.TEAM_MAX, "everyone on the team has a lineup spot")


func test_catch_odds_and_lures() -> void:
	var e := Expedition.new_game("mossmole", 3)
	e.lures = 0
	check_eq(e.catch_chance("thornfang"), Expedition.CATCH_CHANCE[Species.rarity("thornfang")])
	e.lures = 1
	check(e.catch_chance("thornfang") > Expedition.CATCH_CHANCE[Species.rarity("thornfang")], "a lure helps")
	e.pending_recruit = "thornfang"
	var r := e.try_catch()
	check_eq(e.lures, 0, "the lure is used up")
	check_eq(e.pending_recruit, "", "one try only")
	check_eq(bool(r["caught"]), e.roster.has("thornfang"), "caught means it joined")


func test_every_wild_win_offers_a_catch() -> void:
	for seed in 10:
		var e := Expedition.new_default(seed)
		e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 0.4, "guardian": false}
		var b := e.make_battle(false, 1)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY:
			e.finish_battle(b)
			check(e.pending_recruit != "", "a worn-out wild one to try for")


func test_small_teams_meet_small_packs() -> void:
	check_eq(Encounters.pack_size(1, 1), 1, "a lone starter meets one foe on a safe road")
	check_eq(Encounters.pack_size(1, 3), 2)
	check_eq(Encounters.pack_size(3, 2), 3, "an even fight on a risky road")
	check_eq(Encounters.pack_size(6, 1), 4, "a full team meets the usual pack")
	check_eq(Encounters.pack_size(6, 3), 6)
	var g := CombatData.guardian_for(1)
	var trimmed := Encounters.trim(g, 1)
	var n := 0
	for row in ["front", "back"]:
		for id in trimmed[row]:
			if String(id) != "":
				n += 1
	check_eq(n, 1, "one escort for a team of one")
	check_eq(trimmed.get("boss", ""), g.get("boss", ""), "the guardian itself always comes")
	var e := Expedition.new_game("mossmole", 3)
	check_eq(e.guardian_pack()["front"], trimmed["front"], "the caravan's guardian is trimmed too")


func test_fresh_caravans_get_early_help_that_fades() -> void:
	var e := Expedition.new_game("mossmole", 3)
	var lone := e.small_team_factor()
	check(lone < 1.0, "a lone starter meets weaker foes")
	e.pending_recruit = "thornfang"
	e.recruit()
	check(e.small_team_factor() > lone, "the help shrinks as the team grows")
	e.set_crossing(Expedition.FRESH_FADE_CROSSINGS + 1)
	check_eq(e.small_team_factor(), 1.0, "and is gone after the first crossings")
	check_eq(Expedition.new_default(3).small_team_factor(), 1.0, "a veteran caravan gets no help")

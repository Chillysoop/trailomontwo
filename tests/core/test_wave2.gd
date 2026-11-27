extends TestCase
## Flares, sleeping giants, blocked roads, the deep wilds, legendary lairs and the rumors about them.


func _world(rng_seed := 11, crossing := 1) -> Expedition:
	Expedition.default_map = "world"
	var e := Expedition.new_default(rng_seed)
	Expedition.default_map = "test"
	if crossing != 1:
		e.crossing_no = crossing
		e.setup_map(crossing)
	return e


func _find(e: Expedition, kind: String) -> String:
	var keys := e.obstacles.keys()
	keys.sort()
	for k in keys:
		if e.obstacles[k]["kind"] == kind:
			return k
	return ""


## Put the wagon at one end of a road and start down it.
func _start_on(e: Expedition, k: String) -> Dictionary:
	var ends := k.split("|")
	e.at = ends[0]
	e.state = Expedition.State.AT_JUNCTION
	for seg in e.exits():
		if seg["to"] == ends[1]:
			e.provisions = 200.0
			e.water = 200.0
			e.wagon.wear = 0.0
			e.cargo.clear()
			check(e.start_trip(seg), "set off on %s" % k)
			return seg
	check(false, "road %s found" % k)
	return {}


func test_obstacles_are_placed_on_every_world_crossing() -> void:
	for s in [1, 2, 7, 40]:
		var e := _world(s)
		var giants := 0
		var gates := 0
		var deep := 0
		for k in e.obstacles:
			match String(e.obstacles[k]["kind"]):
				"giant": giants += 1
				"gate": gates += 1
				"deep": deep += 1
		check_eq(giants, 1, "seed %d: one giant on crossing 1" % s)
		check_eq(gates, Obstacles.GATES, "seed %d gates" % s)
		check(deep >= 1, "seed %d has deep wilds" % s)
		check(e.lairs.is_empty(), "no lairs on crossing 1")
		for k in e.obstacles:
			check(not String(k).contains(e.map.start) and not String(k).contains(e.map.goal), "never next to the ends")


func test_same_map_same_obstacles() -> void:
	var a := Obstacles.place(WorldMap.generate(5), 2)
	var b := Obstacles.place(WorldMap.generate(5), 2)
	check_eq(a["roads"].keys().size(), b["roads"].keys().size())
	for k in a["roads"]:
		check(b["roads"].has(k), "same road %s" % k)
	check_eq(a["lairs"].keys(), b["lairs"].keys())
	check(Obstacles.place(WorldMap.test_route(), 3)["roads"].is_empty(), "nothing on the test route")


func test_lairs_from_crossing_two() -> void:
	var e := _world(11, 2)
	check(e.lairs.size() >= 1, "a lair on crossing 2")
	for id in e.lairs:
		check_eq(Species.rarity(String(e.lairs[id]["species"])), "legendary")
		check(["lookout", "ruins"].has(e.map.kind_of(id)), "at a side trip")


func test_flare_scares_off_wild_packs_only() -> void:
	var e := Expedition.new_default(3)
	e.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}
	check(not e.encounter_choices().any(func(v): return v["id"] == "flare"), "no flare, no choice")
	e.apply_fx(Settlements.GOODS["flare"]["fx"])
	check_eq(e.flares, 1)
	check(e.encounter_choices().any(func(v): return v["id"] == "flare"), "flare choice")
	var r := e.resolve_encounter("flare")
	check_eq(r["outcome"], "success")
	check(e.pending_encounter.is_empty(), "they scattered")
	check_eq(e.flares, 0, "used up")
	e.flares = 2
	e.pending_encounter = {"pack": CombatData.guardian_for(1), "scale": 1.0, "guardian": true}
	check(not e.encounter_choices().any(func(v): return v["id"] == "flare"), "never on a guardian")
	check(SaveGame.CARRY.has("flares"), "flares carry over")
	check(Outfitter.STOCK.has("flare"), "outfitter sells them")


func test_giant_blocks_the_road_and_feeding_clears_it() -> void:
	var e := _world(11)
	var k := _find(e, "giant")
	check(k != "", "a giant")
	_start_on(e, k)
	e.step_day()
	check_eq(String(e.pending_event.get("id", "")), "giant", "it's asleep on the road")
	var food := e.provisions
	e.resolve_event(1)
	check(not e.obstacles.has(k), "fed and rolled aside")
	check(e.provisions <= food - Obstacles.GIANT_FOOD + 0.01, "cost the food")
	check_eq(e.safe_choice(Obstacles.giant_event("cairnram", true)), 2, "the safe way is the detour")


func test_beating_a_giant_offers_it_as_the_catch() -> void:
	var e := _world(11)
	var k := _find(e, "giant")
	var sp := String(e.obstacles[k]["species"])
	_start_on(e, k)
	e.step_day()
	e.resolve_event(0)
	check_eq(String(e.pending_encounter["pack"]["front"][1]), sp, "the giant stands front and centre")
	e.pending_encounter["scale"] = 0.05
	var b := e.make_battle(false, 1)
	b.run_to_end()
	check(b.outcome == Battle.Outcome.VICTORY, "beat it")
	e.finish_battle(b)
	check_eq(e.pending_recruit, sp, "the giant is the one to catch")
	check(not e.obstacles.has(k), "road clear")


func test_gate_cleared_by_the_right_job_or_forced() -> void:
	var e := _world(11)
	var k := _find(e, "gate")
	_start_on(e, k)
	e.step_day()
	check_eq(String(e.pending_event.get("id", "")), "gate")
	var day := e.day
	e.resolve_event(1)
	check_eq(e.day, day + Obstacles.FORCE_DAYS, "forcing through takes days")
	check(e.obstacles.has(k), "still blocked for next time")
	var e2 := _world(11)
	_start_on(e2, k)
	e2.step_day()
	e2.resolve_event(0, 0)
	check(not e2.obstacles.has(k), "a lucky clear opens it for good")


func test_deep_wilds_are_longer_and_rarer() -> void:
	var e := _world(11)
	var k := _find(e, "deep")
	var ends := k.split("|")
	e.at = ends[0]
	var plain := 0
	for s in e.map.exits(ends[0]):
		if s["to"] == ends[1]:
			plain = int(s["days"])
	for seg in e.exits():
		if seg["to"] == ends[1]:
			check_eq(int(seg["days"]), plain + Obstacles.DEEP_DAYS, "two more days")
			check(seg.get("deep", false), "marked deep")
	check_eq(Expedition._rarest(["thornfang", "plateflit", "lianetail"] as Array[String]), "plateflit", "the rare one stays behind")


func test_lair_wakes_on_arrival_with_a_better_catch() -> void:
	var e := _world(11, 2)
	var ids := e.lairs.keys()
	ids.sort()
	var id: String = ids[0]
	var sp := String(e.lairs[id]["species"])
	var from: String = e.map.neighbours(id)[0]
	e.obstacles.clear()
	e.at = from
	e.state = Expedition.State.AT_JUNCTION
	e.provisions = 200.0
	e.water = 200.0
	e.cargo.clear()
	for seg in e.exits():
		if seg["to"] == id:
			check(e.start_trip(seg), "set off")
	var guard := 0
	while e.pending_event.get("id", "") != "lair" and guard < 10:
		e.pending_event = {}
		e.pending_encounter = {}
		e.step_day()
		guard += 1
	check_eq(String(e.pending_event.get("id", "")), "lair", "it's at home")
	e.resolve_event(0)
	check_eq(String(e.pending_encounter["pack"]["front"][1]), sp, "the legendary")
	e.pending_encounter["scale"] = 0.05
	var b := e.make_battle(false, 1)
	b.run_to_end()
	e.finish_battle(b)
	check(bool(e.lairs[id]["done"]), "lair cleared")
	check_eq(e.pending_recruit, sp)
	e.lures = 0
	check(e.catch_chance(sp) >= float(Expedition.CATCH_CHANCE["legendary"]) + Obstacles.LAIR_CATCH - 0.001, "much better odds")


func test_rumors_point_at_obstacles() -> void:
	var e := _world(11, 2)
	var tips := 0
	for id in e.map.junctions:
		e.at = id
		var r := e.hear_rumor()
		if r.contains("{i:giant}") or r.contains("{i:lair}") or r.contains("Trailomon could clear it"):
			tips += 1
	check(tips >= 3, "several rumors point at obstacles (%d)" % tips)


func test_field_guide_tracks_met_and_caught() -> void:
	var e := Expedition.new_game("mossmole", 3)
	check(e.has_caught("mossmole"), "the starter counts as caught")
	check(not e.has_met("thornfang"), "not met yet")
	e.meet("thornfang")
	check(e.has_met("thornfang") and not e.has_caught("thornfang"), "met, not caught")
	e.pending_recruit = "thornfang"
	e.recruit()
	check(e.caught.has("thornfang"), "caught")
	check(SaveGame.CARRY.has("caught"), "the guide carries over")
	var total := 0
	for t in FieldGuideScreen.TABS:
		total += FieldGuideScreen.species_on(t).size()
	check_eq(total, Species.DATA.size(), "every species is on exactly one tab")


func test_glinting_catch_glints_for_good() -> void:
	var e := Expedition.new_game("mossmole", 3)
	var pack := {"id": "x", "title": "x", "text": "", "front": ["", "thornfang", ""], "back": ["", "", ""]}
	e.pending_encounter = {"pack": pack, "scale": 0.05, "guardian": false, "glint": "thornfang"}
	e.lineup = {Vector2i(0, 1): "mossmole"}
	var b := e.make_battle(false, 1)
	b.run_to_end()
	e.finish_battle(b)
	check_eq(e.pending_recruit, "thornfang", "the glinting one stays behind")
	check(e.pending_glint, "it glints")
	e.recruit()
	check(e.glints.has("thornfang"), "glints for good")
	check(not e.pending_glint, "flag cleared")
	check(SaveGame.CARRY.has("glints") and SaveGame.CARRY.has("lead"), "carried over")


func test_lead_companion_walks_beside_the_wagon() -> void:
	var e := Expedition.new_game("mossmole", 3)
	e.pending_recruit = "thornfang"
	e.recruit()
	check_eq(e.lead_companion(), "mossmole", "first free one by default")
	e.lead = "thornfang"
	check_eq(e.lead_companion(), "thornfang", "the picked lead")
	e.haulers.append("thornfang")
	check_eq(e.lead_companion(), "mossmole", "not while in harness")


func test_temperaments_lean_stats() -> void:
	var e := Expedition.new_game("mossmole", 3)
	check(Temperaments.KINDS.has(String(e.tempers.get("mossmole", ""))), "the starter has one")
	var hp := CombatData.max_hp("mossmole")
	e.tempers["mossmole"] = "hardy"
	check(e.max_hp("mossmole") > hp, "hardy is tougher")
	e.tempers["mossmole"] = "bold"
	check(e.stat("mossmole", "atk") > float(CombatData.stats("mossmole")["atk"]), "bold hits harder")
	e.lineup = {Vector2i(0, 1): "mossmole"}
	e.creature_hp["mossmole"] = e.max_hp("mossmole")
	e.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}
	var b := e.make_battle(false, 1)
	var f: Fighter = b.side_fighters(Formation.Side.PLAYER)[0]
	check(absf(f.atk - e.stat("mossmole", "atk")) < 0.01, "the battle uses it")
	e.pending_recruit = "thornfang"
	e.recruit()
	check(e.tempers.has("thornfang"), "catches get one")
	check(SaveGame.CARRY.has("tempers"), "carried")


func test_eggs_hatch_after_days() -> void:
	var e := Expedition.new_game("mossmole", 3)
	e.apply_fx({"egg": 1}, "", "Forest")
	check_eq(e.eggs.size(), 1, "an egg")
	var sp := String(e.eggs[0]["species"])
	check_eq(Species.stage(sp), 1, "a first form")
	for i in Expedition.EGG_DAYS:
		e.spend_day()
	check(e.roster.has(sp), "hatched and joined")
	check(e.eggs.is_empty(), "no egg left")
	check(SaveGame.CARRY.has("eggs"), "eggs carry over")
	check(not TrailEvents.by_id("nest").is_empty(), "nests turn up on the road")


func test_rival_picks_the_edge_and_grows() -> void:
	for s in Expedition.STARTERS:
		var r := Rival.starter_for(s)
		check(r != s, "a different starter")
	check_eq(Rival.grown("mossmole", 1), "mossmole")
	check_eq(Rival.grown("mossmole", 4), "mossbrock")
	var small := Rival.pack("mossmole", 1)
	var big := Rival.pack("mossmole", 6)
	var count := func(p): return (p["front"] + p["back"]).filter(func(x): return String(x) != "").size()
	check(count.call(big) > count.call(small), "the team grows")
	check(String(small["id"]).begins_with("trainer_"), "a loss costs only the bet")


func test_rival_turns_up_once_mid_crossing() -> void:
	Expedition.default_map = "world"
	var e := Expedition.new_game("mossmole", 11)
	Expedition.default_map = "test"
	check_eq(e.starter, "mossmole")
	var mid := ""
	var from := ""
	for s in e.map.segments:
		var lb := int(e.map.junctions[s["b"]]["layer"])
		if lb == Rival.LAYERS_FROM and String(s["b"]).begins_with("j"):
			mid = s["b"]
			from = s["a"]
			break
	e.obstacles.clear()
	e.at = from
	e.provisions = 200.0
	e.water = 200.0
	e.cargo.clear()
	for seg in e.exits():
		if seg["to"] == mid:
			check(e.start_trip(seg), "set off")
	e.step_day()
	check_eq(String(e.pending_event.get("id", "")), "rival", "Rook pulls alongside")
	e.coins = 50
	e.resolve_event(0)
	check(bool(e.pending_encounter.get("rival", false)), "a battle with Rook")
	e.pending_encounter["scale"] = 0.05
	var b := e.make_battle(false, 1)
	b.run_to_end()
	e.finish_battle(b)
	check_eq(int(e.rival_record["wins"]), 1, "a win on the record")
	check(e.coins > 50, "took the purse")
	check(e.rival_met, "only once a crossing")


func test_hall_of_fame_keeps_finished_crossings() -> void:
	var keep := HallOfFame.path
	HallOfFame.path = "user://test_hall_of_fame.json"
	if FileAccess.file_exists(HallOfFame.path):
		DirAccess.remove_absolute(HallOfFame.path)
	var e := Expedition.new_game("mossmole", 3)
	e.rename("mossmole", "Clod")
	HallOfFame.record(e, "slot_1")
	HallOfFame.record(e, "slot_1")
	var all := HallOfFame.entries()
	check_eq(all.size(), 2)
	check_eq(String(all[0]["team"][0]["name"]), "Clod", "names go up on the wall")
	DirAccess.remove_absolute(HallOfFame.path)
	HallOfFame.path = keep


func test_personality_quirks_move_morale() -> void:
	var e := Expedition.new_game("mossmole", 3)
	check(Personalities.KINDS.has(String(e.quirks.get("mossmole", ""))), "the starter has a quirk")
	e.pending_recruit = "thornfang"
	e.recruit()
	check(e.quirks.has("thornfang"), "catches get one")
	check(SaveGame.CARRY.has("quirks"), "carried")
	e.quirks = {"mossmole": "glutton", "thornfang": "sunny"}
	e.morale = 50
	check_eq(e.quirk_moment("meal"), 4, "the glutton loves a meal")
	check_eq(e.morale, 54, "morale went up")
	check_eq(e.quirk_moment("rest"), 3, "sunny lifts the camp")
	check(e.journal[e.journal.size() - 1].contains(e.display_name("thornfang")), "the journal names who")
	e.quirks["mossmole"] = "sore_loser"
	check_eq(e.quirk_moment("lose", ["mossmole"]), -3, "only fighters react to a loss")
	check_eq(e.quirk_moment("lose", ["thornfang"]), 0, "a sunny one shrugs it off")
	var card := CreatureCard.team_opts(e, "mossmole")
	check_eq(String(card["quirk"]), "sore_loser", "shown on the card")


func test_field_guide_plants_page() -> void:
	var e := Expedition.new_game("mossmole", 3)
	check(FieldGuideScreen.TABS.has("Plants"), "a plants tab")
	var page := FieldGuideScreen.plants_page(e)
	check(not page.contains("Violet caps"), "untried plants are hidden")
	e.known_plants["violet_caps"] = true
	e.known_plants["snapwort"] = true
	page = FieldGuideScreen.plants_page(e)
	check(page.contains("Violet caps") and page.contains("Snapwort"), "tried plants show")
	check(page.contains("tried 2 of %d" % Camp.PLANTS.size()), "a count")

extends TestCase
## Groundwork for a 300-strong roster: roster data files, evolution, encounter tables and
## the automatic balance checks every new Trailomon has to pass.


# ---------- roster files ----------

func test_roster_files_merge_into_the_tables() -> void:
	for f in Roster.FILES:
		for id in f.SPECIES:
			check(Species.DATA.has(id), "%s is a species" % id)
			check(f.KITS.has(id), "%s has its kit in the same file" % id)
			for mid in CombatData.kit_moves(id):
				check(MovePool.has(mid) or CombatData.MOVES.has(mid), "%s: move %s exists" % [id, mid])
	check(Species.DATA.has("mossmole") and Species.DATA.has("brambleback"), "file and hand-written species both present")
	check(CombatData.KITS.has("titanox") and MovePool.has("earthsplitter"), "kits and moves merged")


func test_species_data_is_sound() -> void:
	for id in Species.DATA:
		var info: Dictionary = Species.DATA[id]
		check(CombatData.HABITATS.has(info["type"]), "%s has a habitat type" % id)
		check(["", "Blight", "Glow"].has(Species.biome(id)), "%s biome" % id)
		check(Species.UPKEEP.has(info["size"]), "%s size" % id)
		for to in Species.evolutions(id):
			check(Species.DATA.has(to), "%s evolves into a real species (%s)" % [id, to])
			check_eq(Species.info(to)["type"], info["type"], "%s keeps its habitat when it evolves" % id)
			check(not Species.is_boss(to), "%s doesn't evolve into a guardian" % id)
		check(Species.stage(id) <= 3, "%s: at most 3 stages" % id)


# ---------- evolution ----------

## Pretend `from` evolves into `to` for one test.
func _with_evolution(from: String, to: String, level := 0) -> Dictionary:
	var old: Dictionary = Species.DATA[from]
	var entry := old.duplicate(true)
	entry["evolves_to"] = to
	if level > 0:
		entry["evolve_level"] = level
	Species.DATA[from] = entry
	return old


func test_species_know_their_line() -> void:
	var old := _with_evolution("mossmole", "burlbear")
	check_eq(Species.evolutions("mossmole"), ["burlbear"] as Array[String])
	check_eq(Species.previous("burlbear"), "mossmole")
	check_eq(Species.stage("burlbear"), 2)
	check_eq(Species.family("burlbear"), "mossmole")
	check_eq(Species.evolve_level("mossmole"), 10, "stage 1 evolves at level 10")
	Species.DATA["mossmole"] = old
	check(Species.evolutions("mossmole").is_empty(), "back to normal")


func test_evolving_keeps_progress() -> void:
	var old := _with_evolution("brambleback", "burlbear")
	var e := Expedition.new_default(5)
	check(not e.can_evolve("brambleback"), "not before level 10")
	while e.level("brambleback") < 10:
		e.gain_xp("brambleback", Leveling.xp_to_next(e.level("brambleback")))
	check(e.journal.any(func(l): return l.contains("ready to evolve")), "the journal says it can evolve")
	e.boosts["brambleback"] = {"atk": 5.0}
	e.creature_hp["brambleback"] = e.max_hp("brambleback") * 0.5
	var cell: Vector2i
	for c in e.lineup:
		if e.lineup[c] == "brambleback":
			cell = c
	check(e.can_evolve("brambleback"), "can evolve at level 10")
	check(e.evolve("brambleback", "burlbear") != "", "evolves")
	check(e.roster.has("burlbear") and not e.roster.has("brambleback"), "the new form is in the team")
	check_eq(e.level("burlbear"), 10, "keeps its level")
	check_eq(float(e.boosts["burlbear"]["atk"]), 5.0, "keeps its boosts")
	check_eq(e.lineup[cell], "burlbear", "keeps its place in the lineup")
	check(absf(float(e.creature_hp["burlbear"]) - e.max_hp("burlbear") * 0.5) < 0.01, "same share of health")
	check(e.encountered.has("burlbear"), "counts as met")
	check_eq(e.kit_moves("burlbear")[0], CombatData.KITS["burlbear"]["basic"], "takes the new form's moves")
	Species.DATA["brambleback"] = old


func test_cant_evolve_into_one_you_own() -> void:
	var old := _with_evolution("brambleback", "coilhusk", 1)
	var e := Expedition.new_default(5)
	check(not e.can_evolve("brambleback"), "you already have a coilhusk")
	check_eq(e.evolve("brambleback", "coilhusk"), "")
	Species.DATA["brambleback"] = old


func test_evolution_survives_a_save() -> void:
	var old := _with_evolution("brambleback", "burlbear", 1)
	var e := Expedition.new_default(5)
	e.evolve("brambleback", "burlbear")
	var c := SaveGame.next_crossing(SaveGame.caravan(e), 5, 2)
	check(c.roster.has("burlbear"), "the evolved form carries to the next crossing")
	Species.DATA["brambleback"] = old


# ---------- encounter tables ----------

func test_tables_follow_the_terrain() -> void:
	var forest := Encounters.pool("Forest", 1)
	check(forest.has("mossmole") and forest.has("thornfang"), "forest locals")
	check(not forest.has("hollowstag") and not forest.has("bogmother"), "no guardians")
	check(not forest.has("emberoak"), "no legendaries on crossing 1")
	check(Encounters.pool("Forest", 2).has("emberoak"), "legendaries from crossing 2")
	var weighted := Encounters.weighted_pool("Forest", 1)
	check(weighted.count("mossmole") > weighted.count("pebblotter"), "home species outnumber strays")
	check(not forest.has("vinegecko"), "no Jungle strays in the Forest")
	check(Encounters.pool("Hills", 1).has("vinegecko"), "Hills mix every habitat")
	check(Encounters.pool("Blight", 3).is_empty(), "no Blight Trailomon yet")


func test_dust_biome_species_stay_in_their_biome() -> void:
	Species.DATA["test_blightling"] = {"rarity": "common", "name": "Blightling", "type": "Forest", "size": "small",
		"hauling": 0, "capabilities": {}, "biome": "Blight"}
	CombatData.KITS["test_blightling"] = CombatData.KITS["mossmole"]
	check(Encounters.pool("Blight", 3).has("test_blightling"), "lives in the Blight")
	check(not Encounters.pool("Forest", 3).has("test_blightling"), "not in the Forest")
	check(not Encounters.pool("Blight", 3).has("mossmole"), "only biome species in the Blight")
	check(not Encounters.pool("Glow", 3).has("test_blightling"), "not in the Glow")
	var packs := CombatData.packs_for({"terrain": "Blight", "risk": 2}, 3)
	check(packs.any(func(p): return p.get("table", false)), "Blight roads use the Blight table")
	var e := Expedition.new_default(3)
	e.set_crossing(3)
	check_eq(e.wild_for("Blight"), ["test_blightling"] as Array[String])
	Species.DATA.erase("test_blightling")
	CombatData.KITS.erase("test_blightling")


func test_evolved_forms_turn_up_later() -> void:
	var old := _with_evolution("mossmole", "burlbear")
	check(not Encounters.can_turn_up("burlbear", 2), "stage 2 not before crossing 3")
	check(Encounters.can_turn_up("burlbear", 3), "stage 2 from crossing 3")
	Species.DATA["mossmole"] = old


func test_built_packs_are_sound() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for terrain in ["Forest", "River", "Swamp", "Mountain", "Hills"]:
		for risk in [1, 2, 3]:
			for i in 20:
				var p := Encounters.build(terrain, 2, risk, rng)
				var ids: Array = (p["front"] + p["back"]).filter(func(id): return id != "")
				check_eq(ids.size(), 3 + risk, "%s risk %d size" % [terrain, risk])
				check(p["front"].any(func(id): return id != ""), "someone stands in front")
				check(ids.filter(func(id): return Species.rarity(id) == "legendary").size() <= 1, "at most one legendary")
				for id in ids:
					check(Encounters.pool(terrain, 2).has(id), "%s lives on %s" % [id, terrain])
	var p := Encounters.build("Forest", 1, 1, rng)
	var b := Battle.create({"slots": {Vector2i(0, 1): "brambleback"}}, {"front": p["front"], "back": p["back"], "scale": 1.0}, {"seed": 1})
	b.run_to_end()
	check(b.outcome != Battle.Outcome.ONGOING, "a built pack fights")


func test_table_packs_come_up_on_the_trail() -> void:
	var packs := CombatData.packs_for({"terrain": "Forest", "risk": 1}, 1)
	var table: Array = packs.filter(func(p): return p.get("table", false))
	check_eq(table.size(), 1, "one table entry per road")
	check(int(table[0]["weight"]) > 3, "weighted by the size of the table")


# ---------- balance checks every species must pass ----------

func test_every_kit_follows_the_keyword_rule() -> void:
	for id in Species.DATA:
		for problem in Balance.keyword_problems(id):
			check(false, problem)


func test_every_species_fits_its_power_budget() -> void:
	for id in Species.DATA:
		if Species.is_boss(id):
			continue
		var band := Balance.power_band(id)
		var p := Balance.power(id)
		check(p >= band[0] and p <= band[1], "%s power %.1f inside %s" % [id, p, band])


func test_every_kit_has_a_steady_rhythm() -> void:
	for id in Species.DATA:
		var spd := float(CombatData.KITS[id]["spd"])
		check(spd >= Balance.SPD_RANGE[0] and spd <= Balance.SPD_RANGE[1], "%s speed %.1f" % [id, spd])
		check_eq(CombatData.kit_moves(id).size(), 3, "%s has three moves" % id)


func test_round_robin_runs() -> void:
	var rates := Balance.round_robin("legendary", 1)
	check_eq(rates.size(), 6)
	for id in rates:
		check(rates[id] >= 0.0 and rates[id] <= 1.0, "%s rate" % id)

extends TestCase
## Levels, level-up offers, learned moves and memory slots.


func test_every_team_species_has_two_archetypes_with_a_move_per_slot() -> void:
	for id in MovePool.ARCHETYPES:
		var arcs: Array = MovePool.ARCHETYPES[id]
		check_eq(arcs.size(), 2, "%s archetypes" % id)
		for arc in arcs:
			var slots: Array = []
			for mid in arc["moves"]:
				check(MovePool.has(mid), "%s exists" % mid)
				slots.append(CombatData.move(mid)["slot"])
			slots.sort()
			check_eq(slots, ["basic", "passive", "ultimate"], "%s %s covers every slot" % [id, arc["name"]])


func test_learned_move_text_resolves() -> void:
	for mid in MovePool.MOVES:
		var full := Rich.bb(CombatData.describe(mid, 30.0, 20.0, 600.0))
		check(full.length() > 10 and not full.contains("{"), "%s text: %s" % [mid, full])
		for m in RegEx.create_from_string("url=g:([a-z0-9_]+)").search_all(full):
			check(Glossary.has(m.get_string(1)), "%s links to unknown %s" % [mid, m.get_string(1)])
		var short := CombatData.describe_short(mid, 30.0, 20.0, 600.0)
		check(short != "" and not short.contains("{"), "%s short: %s" % [mid, short])


func test_every_learned_move_runs_in_a_fight() -> void:
	for species in MovePool.ARCHETYPES:
		for arc in MovePool.ARCHETYPES[species]:
			var kit := {}
			for mid in arc["moves"]:
				kit[CombatData.move(mid)["slot"]] = mid
			var b := Battle.create({"slots": {Vector2i(0, 1): species, Vector2i(0, 0): "brambleback", Vector2i(1, 1): "reedwake"},
				"kits": {species: kit}}, {"front": ["thornfang", "gillhorn", ""], "back": ["", "inkhoot", ""], "scale": 1.0}, {"seed": 5})
			b.run_to_end()
			check(b.outcome != Battle.Outcome.ONGOING, "%s %s fight ends" % [species, arc["name"]])
			for f in b.side_fighters(Formation.Side.PLAYER):
				if f.species == species:
					check_eq(f.basic, kit["basic"])
					# A pure heal ultimate waits until someone is hurt, so it may never fire.
					var heal_only: bool = CombatData.move(kit["ultimate"]).get("target", "") == "none" and CombatData.move(kit["ultimate"]).get("team", {}).has("heal_maxhp")
					check(f.ults_fired > 0 or b.time < 20.0 or heal_only, "%s %s fired its ultimate" % [species, arc["name"]])


func test_levels_queue_choices_with_moves_at_ability_levels() -> void:
	var e := Expedition.new_default(11)
	check_eq(e.level("coilhusk"), 1)
	e.gain_xp("coilhusk", Leveling.xp_to_next(1) + Leveling.xp_to_next(2))
	check_eq(e.level("coilhusk"), 3)
	check_eq(e.pending_count(), 2)
	var lv2: Dictionary = e.pending_levels[0]
	check_eq(lv2["options"].size(), 2)
	check_eq(lv2["options"][0]["kind"], "stat")
	check(lv2["options"][0]["stat"] != lv2["options"][1]["stat"], "two different stats")
	var lv3: Dictionary = e.pending_levels[1]
	check_eq(lv3["options"][0]["kind"], "move")
	check(lv3["options"][0]["archetype"] != lv3["options"][1]["archetype"], "one move from each archetype")


func test_rarer_boosts_are_bigger() -> void:
	for stat in Leveling.BOOSTS:
		var v: Array = Leveling.BOOSTS[stat]
		check_eq(v.size(), Leveling.RARITIES.size())
		for i in range(1, v.size()):
			check(float(v[i]) > float(v[i - 1]), "%s rarity %d bigger" % [stat, i])


func test_stat_choice_applies_to_battle() -> void:
	var e := Expedition.new_default(11)
	e.pending_levels = [{"id": "coilhusk", "level": 2, "options": [
		{"kind": "stat", "stat": "atk", "rarity": 3, "amount": 5}, {"kind": "stat", "stat": "hp", "rarity": 0, "amount": 20}]}]
	e.choose_level_up(0)
	check_eq(e.stat("coilhusk", "atk"), 37.0)
	var b := e.make_battle(false, 1)
	for f in b.fighters:
		if f.species == "coilhusk":
			check_eq(f.atk, 37.0)


func test_learning_a_move_uses_memory() -> void:
	var e := Expedition.new_default(11)
	e.pending_levels = [{"id": "coilhusk", "level": 3, "options": [
		{"kind": "move", "move": "coil_crush", "archetype": "Barkguard"}, {"kind": "move", "move": "spine_jab", "archetype": "Thornwarden"}]}]
	e.choose_level_up(0)
	check_eq(e.kit_move("coilhusk", "basic"), "coil_crush")
	check_eq(e.memory_move("coilhusk", "basic"), "trunk_slam", "the old move waits in memory")
	check(e.swap_memory("coilhusk", "basic"), "swap works")
	check_eq(e.kit_move("coilhusk", "basic"), "trunk_slam")
	check_eq(e.memory_move("coilhusk", "basic"), "coil_crush")
	e.pending_levels = [{"id": "coilhusk", "level": 6, "options": [
		{"kind": "move", "move": "spined_coil", "archetype": "Thornwarden"}, {"kind": "move", "move": "resin_shell", "archetype": "Barkguard"}]}]
	e.choose_level_up(1, true)
	check_eq(e.kit_move("coilhusk", "passive"), "bark_shell", "kept in memory, not used yet")
	check_eq(e.memory_move("coilhusk", "passive"), "resin_shell")


func test_level_up_can_replace_equipped_or_memory() -> void:
	var e := Expedition.new_default(11)
	e.memory["coilhusk"] = {"basic": "spine_jab"}
	e.pending_levels = [{"id": "coilhusk", "level": 3, "options": [
		{"kind": "move", "move": "coil_crush", "archetype": "Barkguard"}, {"kind": "move", "move": "spine_jab", "archetype": "Thornwarden"}]}]
	e.choose_level_up(0)
	check_eq(e.kit_move("coilhusk", "basic"), "coil_crush", "replacing equipped puts the new move in")
	check_eq(e.memory_move("coilhusk", "basic"), "spine_jab", "a full memory slot is left alone")
	e.pending_levels = [{"id": "coilhusk", "level": 6, "options": [
		{"kind": "move", "move": "trunk_slam", "archetype": "Barkguard"}, {"kind": "move", "move": "spine_jab", "archetype": "Thornwarden"}]}]
	e.choose_level_up(0, true)
	check_eq(e.kit_move("coilhusk", "basic"), "coil_crush", "replacing memory leaves the equipped move")
	check_eq(e.memory_move("coilhusk", "basic"), "trunk_slam", "the memory move is replaced")


func test_battles_give_experience() -> void:
	var e := Expedition.new_default(11)
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.0, "guardian": false}
	var b := e.make_battle(false, 3)
	b.run_to_end()
	e.finish_battle(b)
	var gained := 0
	for id in e.lineup.values():
		gained += int(e.xp.get(id, 0)) + e.level(id) - 1
	check(gained > 0, "the lineup earned experience")

extends TestCase
## Auto-battle rules: targeting, damage, synergies, outcomes.

const TEAM := {Vector2i(0, 0): "brambleback", Vector2i(0, 1): "coilhusk", Vector2i(0, 2): "scythelk",
	Vector2i(1, 0): "reedwake", Vector2i(1, 1): "mirelamp", Vector2i(1, 2): "rimehare"}


func _battle(slots: Dictionary, front: Array, back: Array, boss := "", seed := 1) -> Battle:
	return Battle.create({"slots": slots}, {"front": front, "back": back, "boss": boss}, {"seed": seed})


func _enemy(b: Battle, row: int, lane: int) -> Fighter:
	for f in b.fighters:
		if f.side == Formation.Side.ENEMY and f.row == row and f.lane == lane:
			return f
	return null


func test_front_row_protects_second_row() -> void:
	var b := _battle(TEAM, ["", "thornfang", ""], ["inkhoot", "inkhoot", "inkhoot"])
	var t := b.ordinary_target(Formation.Side.PLAYER, 0)
	check_eq(t.row, Formation.Row.FRONT, "the lone front creature must be hit first")
	check_eq(t.lane, 1)


func test_same_lane_then_nearest_lane_then_upper() -> void:
	var b := _battle(TEAM, ["thornfang", "", "thornfang"], [])
	check_eq(b.ordinary_target(Formation.Side.PLAYER, 0).lane, 0)
	check_eq(b.ordinary_target(Formation.Side.PLAYER, 2).lane, 2)
	check_eq(b.ordinary_target(Formation.Side.PLAYER, 1).lane, 0, "a tie goes to the upper lane")


func test_second_row_is_hit_once_front_falls() -> void:
	var b := _battle(TEAM, ["thornfang", "", ""], ["", "", "inkhoot"])
	_enemy(b, Formation.Row.FRONT, 0).hp = 0.0
	var t := b.ordinary_target(Formation.Side.PLAYER, 0)
	check_eq(t.row, Formation.Row.BACK)


func test_taunt_draws_attacks() -> void:
	var b := _battle(TEAM, ["thornfang", "", ""], [])
	var bramble: Fighter
	for f in b.fighters:
		if f.species == "brambleback":
			bramble = f
	var scythe_lane_target := b.ordinary_target(Formation.Side.ENEMY, 2)
	check(scythe_lane_target.species != "brambleback", "without taunt, lane 2 is hit")
	bramble.taunt = 3.0
	check_eq(b.ordinary_target(Formation.Side.ENEMY, 2).species, "brambleback")


func test_boss_is_safe_until_its_grid_falls() -> void:
	var b := _battle(TEAM, ["thornfang", "", ""], [], "hollowstag")
	check(not b.ordinary_target(Formation.Side.PLAYER, 1).is_boss(), "boss protected")
	_enemy(b, Formation.Row.FRONT, 0).hp = 0.0
	check(b.ordinary_target(Formation.Side.PLAYER, 1).is_boss(), "boss exposed once alone")


func test_defense_and_habitat_change_damage() -> void:
	var b := _battle({Vector2i(0, 0): "reedwake", Vector2i(0, 1): "scythelk"}, ["thornfang", "", ""], [])
	var t := _enemy(b, Formation.Row.FRONT, 0)
	check_near(b.damage_for(null, t, 100.0), 100.0 * 100.0 / (100.0 + t.def), 0.01, "defense formula")
	var river: Fighter = b.fighters[0]
	check_near(b.damage_for(river, t, 100.0), 100.0 * 100.0 / (100.0 + t.def) * CombatData.STRONG, 0.01, "River beats Forest")
	check_near(b.damage_for(null, t, 100.0, true), 100.0, 0.01, "pierce ignores defense")


func test_forest_pair_gets_defense_synergy() -> void:
	var b := _battle(TEAM, ["cairnram", "", ""], [])
	for f in b.fighters:
		if f.species == "brambleback":
			check_near(f.def, CombatData.stats("brambleback")["def"] + 12.0, 0.01)
		if f.species == "scythelk":
			check_near(f.def, CombatData.stats("scythelk")["def"], 0.01, "a lone Mountain gets no bonus")


func test_synergy_tiers() -> void:
	check_eq(CombatData.synergy_tier("Forest", 1), 0)
	check_eq(CombatData.synergy_tier("Forest", 2), 1)
	check_eq(CombatData.synergy_tier("Forest", 4), 2)


func test_same_seed_replays_the_same_battle() -> void:
	var a := _battle(TEAM, ["thornfang", "thornfang", "thornfang"], ["", "lianetail", ""], "", 42)
	var b := _battle(TEAM, ["thornfang", "thornfang", "thornfang"], ["", "lianetail", ""], "", 42)
	check_eq(a.run_to_end(), b.run_to_end())
	check_near(a.time, b.time, 0.001)
	check_eq(a.player_hp(), b.player_hp())


func test_healthy_team_beats_a_thornfang_pack_in_reasonable_time() -> void:
	var pack := CombatData.pack_by_id("thornfang_pack")
	var b := _battle(TEAM, pack["front"], pack["back"])
	check_eq(b.run_to_end(), Battle.Outcome.VICTORY)
	check(b.time > 8.0 and b.time < 90.0, "battle took %.1fs" % b.time)


func test_lineup_matters_against_a_swarm() -> void:
	var pack := CombatData.pack_by_id("frost_swarm")
	var bad := {}
	for cell in TEAM:
		bad[Vector2i(1 - cell.x, cell.y)] = TEAM[cell]
	var good_wins := 0
	var bad_wins := 0
	for s in 10:
		var gb := Battle.create({"slots": TEAM}, {"front": pack["front"], "back": pack["back"], "scale": 1.35}, {"seed": s})
		var bb := Battle.create({"slots": bad}, {"front": pack["front"], "back": pack["back"], "scale": 1.35}, {"seed": s})
		good_wins += int(gb.run_to_end() == Battle.Outcome.VICTORY)
		bad_wins += int(bb.run_to_end() == Battle.Outcome.VICTORY)
	check(good_wins > bad_wins + 3, "guards in front should win clearly more (%d vs %d)" % [good_wins, bad_wins])


func test_guardian_is_beatable_at_full_health() -> void:
	var g := CombatData.GUARDIAN
	var wins := 0
	for s in 6:
		var b := Battle.create({"slots": TEAM}, {"front": g["front"], "back": g["back"], "boss": g["boss"], "scale": CombatData.GUARDIAN_SCALE}, {"seed": s})
		wins += int(b.run_to_end() == Battle.Outcome.VICTORY)
	check(wins >= 4, "the guardian should usually fall to a healthy team (%d/6)" % wins)


func test_knocked_out_creatures_sit_out_and_wiped_team_loses() -> void:
	var hp := {}
	for cell in TEAM:
		hp[TEAM[cell]] = 0.0
	hp["rimehare"] = 5.0
	var b := Battle.create({"slots": TEAM, "hp": hp}, {"front": ["cairnram", "cairnram", ""], "back": []}, {"seed": 3})
	check_eq(b.side_fighters(Formation.Side.PLAYER).size(), 1)
	check_eq(b.run_to_end(), Battle.Outcome.DEFEAT)


func test_tired_haulers_hit_softer() -> void:
	var b := Battle.create({"slots": TEAM, "fatigue": {"coilhusk": 100.0}}, {"front": ["cairnram", "", ""], "back": []}, {"seed": 1})
	for f in b.fighters:
		if f.species == "coilhusk":
			check_near(f.atk, CombatData.stats("coilhusk")["atk"] * (1.0 - Battle.FATIGUE_PENALTY), 0.01)


func test_long_battles_end_in_withdrawal() -> void:
	# Two walls of guards with healing can't finish each other quickly; the clock ends it.
	var b := _battle({Vector2i(0, 1): "brambleback"}, ["", "plateflit", ""], [])
	for f in b.fighters:
		f.atk = 0.01
		f.max_hp = 100000.0
		f.hp = f.max_hp
	check_eq(b.run_to_end(), Battle.Outcome.WITHDRAW)
	check(b.time >= Battle.WITHDRAW_AT, "ends at the time limit")


func test_retreat_ends_the_battle_after_the_channel() -> void:
	var b := _battle(TEAM, ["cairnram", "cairnram", "cairnram"], [])
	b.request_retreat()
	for i in int(Battle.RETREAT_SECS / Battle.TICK) + 2:
		b.step()
	check_eq(b.outcome, Battle.Outcome.RETREAT)


func test_every_kit_is_complete() -> void:
	for id in CombatData.KITS:
		var moves := CombatData.kit_moves(id)
		check_eq(moves.size(), 3)
		for i in 3:
			check(CombatData.has_move(moves[i]), "%s: unknown move %s" % [id, moves[i]])
			check_eq(CombatData.move(moves[i])["slot"], ["basic", "passive", "ultimate"][i], "%s slot" % moves[i])


func test_attack_bar_fires_at_speed() -> void:
	var b := _battle({Vector2i(0, 1): "cairnram"}, ["", "plateflit", ""], [])
	var ram: Fighter = b.fighters[0]
	ram.attack_bar = 0.0
	var steps := 0
	while ram.attacks == 0 and steps < 200:
		b.step()
		steps += 1
	check_near(steps * Battle.TICK, ram.spd, 0.11, "first basic attack after spd seconds")


func test_ultimates_fire_and_are_tallied() -> void:
	var pack := CombatData.pack_by_id("thornfang_pack")
	var b := _battle(TEAM, pack["front"], pack["back"])
	b.run_to_end()
	var ults := 0
	var ult_dmg := 0.0
	for f in b.side_fighters(Formation.Side.PLAYER):
		ults += f.ults_fired
		ult_dmg += f.dmg_ult
	check(ults >= 3, "team should fire several ultimates (fired %d)" % ults)
	check(ult_dmg > 0.0, "ultimate damage is tallied")


func test_thorns_count_as_passive_damage() -> void:
	var b := _battle({Vector2i(0, 1): "brambleback"}, ["", "thornfang", ""], [])
	for i in 100:
		b.step()
	var bramble: Fighter = b.fighters[0]
	check(bramble.dmg_passive > 0.0, "thorns hit back")


func test_damage_tallies_match_damage_taken() -> void:
	var b := _battle(TEAM, ["cairnram", "cairnram", ""], [])
	b.run_to_end()
	var dealt := b.wagon_damage
	for f in b.side_fighters(Formation.Side.PLAYER):
		dealt += f.damage_total()
	var taken := 0.0
	for f in b.side_fighters(Formation.Side.ENEMY):
		taken += f.taken
	check_near(dealt, taken, 0.5, "every point dealt is taken by someone")


func test_move_descriptions_fill_in_numbers() -> void:
	var t := CombatData.describe("shell_quake", 40.0, 30.0, 400.0)
	check(t.contains("180% {k:atk|Attack} (72)"), t)
	check(not t.contains("{atk:"), t)
	for id in CombatData.MOVES:
		var d := CombatData.describe(id, 30.0, 30.0, 300.0)
		check(not d.contains("{atk") and not d.contains("{def") and not d.contains("{maxhp"), "%s: %s" % [id, d])
		for k in CombatData.keywords(id):
			check(Glossary.has(k), "%s mentions unknown keyword %s" % [id, k])


func test_basic_attacks_never_skip_a_standing_front_row() -> void:
	# Over a whole fight, no basic attack from a non-reach creature lands on the second row
	# while any front-row enemy is still standing.
	var b := _battle(TEAM, ["thornfang", "", "cairnram"], ["inkhoot", "frostsnip", "inkhoot"], "", 7)
	var steps := 0
	while b.outcome == Battle.Outcome.ONGOING and steps < 4000:
		for f in b.fighters:
			if f.alive() and f.side == Formation.Side.PLAYER and not CombatData.move(f.basic).get("reach", false):
				var t := b.basic_target(f)
				if t != null and not b._row(Formation.Side.ENEMY, Formation.Row.FRONT).is_empty():
					check_eq(t.row, Formation.Row.FRONT, "%s must hit the front row first" % f.species)
					if t.row != Formation.Row.FRONT:
						return
		b.step()
		steps += 1


func test_reach_is_the_only_basic_that_goes_over() -> void:
	var b := _battle({Vector2i(1, 1): "lianetail", Vector2i(0, 1): "brambleback"}, ["thornfang", "", ""], ["", "", "inkhoot"])
	for f in b.fighters:
		if f.species == "lianetail":
			check_eq(b.basic_target(f).row, Formation.Row.BACK, "Vine Whip names the second row")
		elif f.species == "brambleback":
			check_eq(b.basic_target(f).row, Formation.Row.FRONT)


func test_headbutt_staggers_and_wing_bash_dodges() -> void:
	var b := _battle({Vector2i(0, 1): "cairnram"}, ["", "plateflit", ""], [])
	var ram: Fighter
	var flit: Fighter
	for f in b.fighters:
		if f.species == "cairnram":
			ram = f
		elif f.species == "plateflit":
			flit = f
	flit.attack_bar = 0.9
	b._basic_attack(ram)
	check(flit.attack_bar < 0.65, "Headbutt knocks the attack bar back")
	b._basic_attack(flit)
	check(flit.dodge, "Wing Bash readies a dodge")
	var hp := flit.hp
	b._basic_attack(ram)
	check_eq(flit.hp, hp, "the next basic attack misses")
	check(not flit.dodge, "the dodge is used up")


func test_mud_horn_weakens_and_ink_jet_washes_shields() -> void:
	var b := _battle({Vector2i(0, 0): "gillhorn", Vector2i(0, 1): "inkhoot"}, ["brambleback", "", ""], [])
	var bramble := _enemy(b, Formation.Row.FRONT, 0)
	for f in b.fighters:
		if f.species == "gillhorn":
			b._basic_attack(f)
	check(bramble.has_mod("weaken"), "Mud Horn weakens")
	bramble.shield = 30.0
	for f in b.fighters:
		if f.species == "inkhoot":
			b._basic_attack(f)
	check_eq(bramble.shield, 0.0, "Ink Jet washes the shield away first")

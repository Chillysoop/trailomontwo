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


func test_guard_and_habitat_change_damage() -> void:
	var b := _battle(TEAM, ["thornfang", "", ""], [])
	var src: Fighter = b.fighters[0]
	var t := _enemy(b, Formation.Row.FRONT, 0)
	var neutral := b.damage_for(src, t, 10.0, 10.0, "", false)
	check_near(neutral, 10.0 * 100.0 / (100.0 + t.guard), 0.01)
	check_near(b.damage_for(src, t, 10.0, 10.0, "River", false), neutral * CombatData.STRONG, 0.01, "River beats Forest")
	check_near(b.damage_for(src, t, 10.0, 10.0, "Snow", false), neutral, 0.01)
	check_near(b.damage_for(src, t, 10.0, 10.0, "", true), 10.0, 0.01, "pierce ignores guard")


func test_forest_pair_gets_guard_synergy() -> void:
	var b := _battle(TEAM, ["cairnram", "", ""], [])
	for f in b.fighters:
		if f.species == "brambleback":
			check_near(f.guard, CombatData.stats("brambleback")["guard"] + 15.0, 0.01)
		if f.species == "scythelk":
			check_near(f.guard, CombatData.stats("scythelk")["guard"], 0.01, "a lone Mountain gets no bonus")


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


func test_lineup_matters_against_the_guardian() -> void:
	var g := CombatData.GUARDIAN
	var bad := {}
	for cell in TEAM:
		bad[Vector2i(1 - cell.x, cell.y)] = TEAM[cell]
	var good_wins := 0
	var bad_wins := 0
	for s in 10:
		var gb := Battle.create({"slots": TEAM}, {"front": g["front"], "back": g["back"], "boss": g["boss"], "scale": CombatData.GUARDIAN_SCALE}, {"seed": s})
		var bb := Battle.create({"slots": bad}, {"front": g["front"], "back": g["back"], "boss": g["boss"], "scale": CombatData.GUARDIAN_SCALE}, {"seed": s})
		good_wins += int(gb.run_to_end() == Battle.Outcome.VICTORY)
		bad_wins += int(bb.run_to_end() == Battle.Outcome.VICTORY)
	check(good_wins > bad_wins, "guards in front should win more (%d vs %d)" % [good_wins, bad_wins])


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
			check_near(f.might, CombatData.stats("coilhusk")["might"] * (1.0 - Battle.FATIGUE_PENALTY), 0.01)


func test_long_battles_end_in_withdrawal() -> void:
	# Two walls of guards with healing can't finish each other quickly; the clock ends it.
	var b := _battle({Vector2i(0, 1): "brambleback"}, ["", "plateflit", ""], [])
	b.fighters[0].might = 0.1
	b.fighters[1].might = 0.1
	check_eq(b.run_to_end(), Battle.Outcome.WITHDRAW)
	check(b.time >= Battle.WITHDRAW_AT, "ends at the time limit")


func test_retreat_ends_the_battle_after_the_channel() -> void:
	var b := _battle(TEAM, ["cairnram", "cairnram", "cairnram"], [])
	b.request_retreat()
	for i in int(Battle.RETREAT_SECS / Battle.TICK) + 2:
		b.step()
	check_eq(b.outcome, Battle.Outcome.RETREAT)

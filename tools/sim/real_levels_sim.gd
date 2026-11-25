extends SceneTree
## Guardian and wild-pack win rates at the team levels a real campaign reaches (measured by
## tools/playtest/bot.gd, Nov 25 2026). Usage: godot --headless --path . --script res://tools/sim/real_levels_sim.gd
const REAL := {1: 2, 2: 4, 3: 5, 4: 6, 5: 7, 6: 7, 7: 8, 8: 8, 9: 9, 10: 9, 11: 9, 12: 10}

func _team(level: int, s: int) -> Expedition:
	var e := Expedition.new_default(s)
	for id in e.roster:
		while e.level(id) < level:
			e.gain_xp(id, Leveling.xp_to_next(e.level(id)))
			while e.pending_count() > 0:
				e.choose_level_up(0, true)
	for id in e.roster:
		e.creature_hp[id] = e.max_hp(id)
	return e

func _rate(level: int, n: int, terrain: String, guardian: bool) -> int:
	var wins := 0
	for s in 30:
		var e := _team(level, s)
		e.set_crossing(n)
		var rng := RandomNumberGenerator.new(); rng.seed = s
		if guardian:
			e.pending_encounter = {"pack": e.guardian_pack(), "scale": CombatData.GUARDIAN_SCALE, "guardian": true}
		else:
			e.pending_encounter = {"pack": Encounters.build(terrain, n, 2, rng), "scale": float(CombatData.RISK_SCALE[2]), "guardian": false}
		var b := e.make_battle(false, s)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY: wins += 1
	return roundi(wins * 100.0 / 30.0)

func _init():
	Expedition.default_map = "test"
	for n in [1, 3, 5, 7, 9, 12]:
		var lv: int = REAL[n]
		var line := "crossing %2d Lv %2d: guardian %3d%%" % [n, lv, _rate(lv, n, "", true)]
		for t in ["Forest", "River", "Mountain", "Swamp", "Blight", "Glow"]:
			line += "  %s %3d%%" % [t, _rate(lv, n, t, false)]
		print(line)
	quit()

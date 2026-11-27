extends SceneTree
## For each crossing: guardian and wild-pack (risk 2) win rates by team level, starter team,
## auto lineup, no items. Usage: godot --headless --path . --script res://tools/sim/level_need_sim.gd
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

func _rate(level: int, n: int, guardian: bool, runs := 12) -> int:
	var wins := 0
	var terrains := ["Forest", "River", "Mountain", "Swamp", "Blight", "Glow", "Hills", "Snow", "Jungle"]
	for s in runs:
		var e := _team(level, s)
		e.set_crossing(n)
		var rng := RandomNumberGenerator.new(); rng.seed = s
		if guardian:
			e.pending_encounter = {"pack": e.guardian_pack(), "scale": CombatData.GUARDIAN_SCALE, "guardian": true}
		else:
			e.pending_encounter = {"pack": Encounters.build(terrains[s % terrains.size()], n, 2, rng), "scale": float(CombatData.RISK_SCALE[2]), "guardian": false}
		var b := e.make_battle(false, s)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY: wins += 1
	return roundi(wins * 100.0 / runs)

func _init():
	Expedition.default_map = "test"
	var levels := [6, 10, 14, 18, 22, 26]
	var head := "         "
	for l in levels: head += " Lv%-3d" % l
	print(head)
	for n in [4, 5, 6, 8, 10, 12]:
		var g := "c%-2d guard" % n
		var p := "c%-2d pack " % n
		for l in levels:
			g += " %4d%%" % _rate(l, n, true)
			p += " %4d%%" % _rate(l, n, false)
		print(g); print(p)
	quit()

extends SceneTree
## Balance check for later crossings: the starting team, levelled to a given level, against
## each crossing's guardian and its toughest packs.
##   godot --headless --path . --script res://tools/sim/crossing_sim.gd [-- packs | from=N]
## from=N only runs crossings N and later (the full run takes a while).


func _team(level: int, seed_value: int) -> Expedition:
	var e := Expedition.new_default(seed_value)
	for id in e.roster:
		while e.level(id) < level:
			e.gain_xp(id, Leveling.xp_to_next(e.level(id)))
			while e.pending_count() > 0:
				e.choose_level_up(0, true)
	for id in e.roster:
		e.creature_hp[id] = e.max_hp(id)
	return e


func _rate(level: int, crossing_no: int, pack: Dictionary, scale: float) -> int:
	var wins := 0
	for s in 30:
		var e := _team(level, s)
		e.set_crossing(crossing_no)
		e.pending_encounter = {"pack": pack, "scale": scale, "guardian": pack.has("boss")}
		var b := e.make_battle(false, s)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY:
			wins += 1
	return roundi(wins * 100.0 / 30.0)


func _init() -> void:
	Expedition.default_map = "test"
	var args := OS.get_cmdline_user_args()
	if args.has("packs"):
		_packs()
	else:
		var first := 1
		for a in args:
			if a.begins_with("from="):
				first = int(a.substr(5))
		_crossings(first)
	quit()


## Every pack and guardian on its own, crossing 1, at a fresh and a levelled team.
func _packs() -> void:
	var ids := []
	for p in CombatData.PACKS + CombatData.GUARDIANS:
		ids.append(p["id"])
	for pid in ids:
		var p := CombatData.pack_by_id(pid)
		var sc := CombatData.GUARDIAN_SCALE if p.has("boss") else 1.35
		print("%-16s Lv1 %3d%%   Lv5 %3d%%" % [pid, _rate(1, 1, p, sc), _rate(5, 1, p, sc)])


func _crossings(first := 1) -> void:
	for n in range(first, CombatData.GUARDIANS.size() + 1):
		for level in [mini(1 + (n - 1) * 3, Leveling.MAX_LEVEL), mini(1 + (n - 1) * 5, Leveling.MAX_LEVEL)]:
			var g := CombatData.guardian_for(n)
			var line := "crossing %d, team Lv %2d: guardian %s %d%%" % [n, level, g["id"], _rate(level, n, g, CombatData.GUARDIAN_SCALE)]
			for pid in ["emberoak_grove", "auroryx_lights", "tidewyrm_rise", "mirehydra_den", "titanox_pass", "quetzalith_sky"]:
				line += "   %s %d%%" % [pid, _rate(level, n, CombatData.pack_by_id(pid), 1.45)]
			print(line)

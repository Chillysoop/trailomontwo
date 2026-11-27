extends SceneTree
## Early game for a caravan that starts with one Trailomon: win rates for a team of N at the
## level a player has by then, against crossing-1 wild packs (by road risk) and the first
## guardian. Team members past the starter are random crossing-1 commons, as if caught.
## Usage: godot --headless --path . --script res://tools/sim/starter_sim.gd -- [starter=<id>] [x=<foe scale multiplier>]

const RUNS := 16
const CATCHES := ["thornfang", "acornet", "pebblotter", "sporetoad", "minnowisp", "fawnmoth", "lianetail"]
## Team size -> level reached by then (lone starter Lv 2, then about two levels per catch).
const LEVEL := {1: 2, 2: 3, 3: 5, 4: 6, 5: 7}
var x := 1.0


func _team(starter: String, size: int, level: int, s: int) -> Expedition:
	var e := Expedition.new_game(starter, s)
	var rng := RandomNumberGenerator.new()
	rng.seed = s * 31 + size
	var pool := CATCHES.filter(func(id): return id != starter)
	while e.roster.size() < size:
		e.pending_recruit = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(e.pending_recruit)
		e.recruit()
	for id in e.roster:
		while e.level(id) < level:
			e.gain_xp(id, Leveling.xp_to_next(e.level(id)) - int(e.xp.get(id, 0)))
		while e.pending_count() > 0:
			e.choose_level_up(0, true)
	for id in e.roster:
		e.creature_hp[id] = e.max_hp(id)
	return e


func _rate(starter: String, size: int, risk: int, guardian: bool) -> int:
	var wins := 0
	var terrains := ["Forest", "River", "Hills", "Swamp"]
	for s in RUNS:
		var e := _team(starter, size, LEVEL[size], s)
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		if guardian:
			e.pending_encounter = {"pack": e.guardian_pack(), "scale": CombatData.GUARDIAN_SCALE * x, "guardian": true}
		else:
			var pack := Encounters.build(terrains[s % terrains.size()], 1, risk, rng, e.roster.size())
			e.pending_encounter = {"pack": pack, "scale": float(CombatData.RISK_SCALE[risk]) * x, "guardian": false}
		var b := e.make_battle(false, s)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY:
			wins += 1
	return roundi(wins * 100.0 / RUNS)


func _init() -> void:
	Expedition.default_map = "test"
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("starter="):
			only = a.substr(8)
		if a.begins_with("x="):
			x = float(a.substr(2))
	for starter in Expedition.STARTERS:
		if only != "" and starter != only:
			continue
		for size in [1, 2, 3, 4]:
			print("%s x%.2f team %d Lv %d: risk1 %3d%%  risk2 %3d%%  risk3 %3d%%  guardian %3d%%" % [starter, x, size, LEVEL[size],
				_rate(starter, size, 1, false), _rate(starter, size, 2, false), _rate(starter, size, 3, false), _rate(starter, size, 0, true)])
	quit()

extends SceneTree
## Crossing-2 guardian check for a caravan that started with one Trailomon: win rate for a
## team of N at level L, with and without battle items (smart players save them for guardians).
## Usage: godot --headless --path . --script res://tools/sim/c2_sim.gd -- [crossing=2]
const RUNS := 24
const CATCHES := ["thornfang", "acornet", "pebblotter", "sporetoad", "minnowisp", "fawnmoth", "lianetail", "cairnram", "slatebeak", "cragkid"]
var crossing := 2

func _team(size: int, level: int, s: int) -> Expedition:
	var starter: String = Expedition.STARTERS[s % Expedition.STARTERS.size()]
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
	e.set_crossing(crossing)
	return e

func _rate(size: int, level: int, items: bool) -> int:
	var wins := 0
	for s in RUNS:
		var e := _team(size, level, s)
		if items:
			for id in ["rally_horn", "ember_draught", "ironbark_salve"]:
				e.items[id] = 1
			e.item_slots = ["rally_horn", "ember_draught", "ironbark_salve"]
		e.pending_encounter = {"pack": e.guardian_pack(), "scale": CombatData.GUARDIAN_SCALE, "guardian": true}
		var b := e.make_battle(false, s)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY:
			wins += 1
	return roundi(wins * 100.0 / RUNS)

func _init() -> void:
	Expedition.default_map = "test"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("crossing="):
			crossing = int(a.substr(9))
	for size in [3, 4, 5]:
		var line := "c%d team %d:" % [crossing, size]
		for lv in [5, 6, 7, 8]:
			line += "  Lv%d %3d%% /items %3d%%" % [lv, _rate(size, lv, false), _rate(size, lv, true)]
		print(line)
	quit()

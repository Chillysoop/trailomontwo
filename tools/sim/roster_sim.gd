extends SceneTree
## Round robin for the roster: every Trailomon fights every other one of its own rarity,
## three of a kind against three of a kind, from both sides, over a few seeds. Prints each
## one's win rate and flags any outside the healthy band (Balance.WIN_BAND), then a line per
## habitat. Also prints power-budget scores.
##   godot --headless --path . --script res://tools/sim/roster_sim.gd [-- <rarity>]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var rarities := ["common", "rare", "legendary"]
	if not args.is_empty():
		rarities = [args[0]]
	var by_type := {}
	for r in rarities:
		var rates := Balance.round_robin(r, 4)
		var ids := rates.keys()
		ids.sort_custom(func(a, b): return rates[a] > rates[b])
		print("---- %s (%d) ----" % [r, ids.size()])
		for id in ids:
			var flag := "" if Balance.in_band(rates[id]) else "   <-- outside %d-%d%%" % Balance.WIN_BAND
			print("%-12s %-8s %3d%%   power %5.1f%s" % [id, Species.info(id)["type"], roundi(rates[id] * 100.0), Balance.power(id), flag])
			var t: String = Species.info(id)["type"]
			by_type[t] = by_type.get(t, []) + [rates[id]]
	print("---- habitats ----")
	for t in by_type:
		var sum := 0.0
		for v in by_type[t]:
			sum += v
		print("%-9s %3d%%" % [t, roundi(sum / by_type[t].size() * 100.0)])
	quit()

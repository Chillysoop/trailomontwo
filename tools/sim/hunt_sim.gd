extends SceneTree
func _initialize() -> void:
	for cn in [1, 3, 5]:
		var tot := 0; var ch := 0; var food := 0.0; var losses := 0
		for s in 40:
			var e := Expedition.new_default(s)
			e.map = WorldMap.generate(s)
			e.crossing_no = cn
			e.setup_map(cn)
			for id in e.map.junctions:
				if not Expedition.NO_GAME.has(e.map.kind_of(id)):
					e.at = id
					break
			for id in e.roster:
				for i in (cn - 1) * 3:
					e.gain_xp(id, 200)
			e.provisions = 0.0
			if not e.start_hunt():
				continue
			var b := e.make_battle(false, s)
			b.run_to_end()
			tot += b.hunt_bag().size(); ch += 1 if b.charger_down() else 0
			if b.outcome == Battle.Outcome.DEFEAT: losses += 1
			var before := e.provisions
			e.finish_battle(b)
			food += e.provisions - before
		print("crossing %d: avg caught %.1f, charger %d/40, defeats %d, avg food %.1f" % [cn, tot / 40.0, ch, losses, food / 40.0])
	quit(0)

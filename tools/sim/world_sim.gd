extends SceneTree
## Plays many crossings of generated overworld maps: shortest-ish road with a random fork,
## buys food and water when low, safe choice on every event.
## Usage: godot --headless --path . --script res://tools/sim/world_sim.gd


func _init() -> void:
	Expedition.default_map = "world"
	for pace in ["steady", "hard", "easy"]:
		var arrived := 0
		var days := 0
		var stops := 0
		var coins := 0
		var fails := {}
		var rests := 0
		var repairs := 0
		var runs := 120
		for s in runs:
			var e := Expedition.new_default(s)
			e.set_pace(pace)
			var pick := RandomNumberGenerator.new()
			pick.seed = s
			var guard := 0
			while e.state == Expedition.State.AT_JUNCTION and guard < 60:
				guard += 1
				for i in 6:
					if e.provisions < 110 and e.buy("food").is_empty():
						break
				for i in 6:
					if e.water < 45 and e.buy("water").is_empty():
						break
				if e.wagon.wear > 45 and e.repair_kits == 0:
					e.buy("repair_kit")
				if e.wagon.broken != Wagon.Part.NONE or (e.wagon.wear > 60 and e.repair_kits > 0):
					e.repair()
					repairs += 1
				var best: Array = []
				var best_h := 999
				for seg in e.exits():
					var h := e.map.hops(seg["to"], e.map.goal)
					if h < best_h:
						best_h = h
						best = [seg]
					elif h == best_h or (h == best_h + 1 and pick.randf() < 0.3):
						best.append(seg)
				var seg: Dictionary = best[pick.randi_range(0, best.size() - 1)]
				var tries := 0
				while not e.forecast(seg)["can_go"] and tries < 4:
					e.rest()
					tries += 1
					rests += 1
				e.travel(seg)
				stops += 1
			if e.state == Expedition.State.ARRIVED:
				arrived += 1
				days += e.day
				coins += e.coins
			else:
				fails[e.fail_reason] = int(fails.get(e.fail_reason, 0)) + 1
				if OS.get_cmdline_user_args().has("why") and pace == "steady":
					print("  fail seed %d day %d roads %d coins %d food %.0f water %.0f last %s" % [s, e.day, e.visited.size() - 1, e.coins, e.provisions, e.water, e.map.kind_of(e.at)])
		print("%s: arrived %d/%d, avg day %.1f, roads/run %.1f, coins left %.1f, rests %.1f, repairs %.1f, fails %s" % [pace, arrived, runs, float(days) / maxi(1, arrived), float(stops) / runs, float(coins) / maxi(1, arrived), float(rests) / runs, float(repairs) / runs, fails])
	quit(0)

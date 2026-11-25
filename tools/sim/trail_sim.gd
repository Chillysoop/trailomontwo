extends SceneTree
## Plays many crossings with the safe choice on every event and counts outcomes, moments and events.
## Usage: godot --headless --path . --script res://tools/sim/trail_sim.gd


func _init() -> void:
	# The hand-made test route (tools/sim/world_sim.gd plays the generated overworld).
	Expedition.default_map = "test"
	for pace in ["steady", "hard", "easy"]:
		var arrived := 0
		var days := 0
		var moments := 0
		var events := 0
		var fails := {}
		var runs := 200
		for s in runs:
			var e := Expedition.new_default(s)
			e.set_pace(pace)
			if OS.get_cmdline_user_args().has("calm"):
				e.events_enabled = false
			for to in ["mossford", "rail_bridge", "thornmarsh", "westwatch"]:
				var tries := 0
				var seg: Dictionary = {}
				for x in TestRoute.exits(e.at):
					if x["to"] == to:
						seg = x
				while e.state == Expedition.State.AT_JUNCTION and not e.forecast(seg)["can_go"] and tries < 4:
					e.rest()
					tries += 1
				var before := e.journal.size()
				e.travel(seg)
				for l in e.journal.slice(before):
					if l.ends_with("!") and not l.begins_with("Victory"):
						events += 1
			moments += e.moments.size()
			if e.state == Expedition.State.ARRIVED:
				arrived += 1
				days += e.day
			else:
				fails[e.fail_reason] = int(fails.get(e.fail_reason, 0)) + 1
		print("%s: arrived %d/%d, avg day %.1f, moments/run %.1f, events+battles/run %.1f, fails %s" % [pace, arrived, runs, float(days) / maxi(1, arrived), float(moments) / runs, float(events) / runs, fails])
	quit(0)

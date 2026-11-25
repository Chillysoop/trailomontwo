extends SceneTree
## Screenshots of every terrain's scenery with a region landmark, stops, and battle backdrops.
## Usage: godot --path . --script res://tools/shots/region_shots.gd -- <out_dir>

var out_dir := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var exp: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(exp)
	Input.warp_mouse(Vector2(5, 355))
	await _frames(20)
	var crossing: Expedition = exp.get("crossing")
	crossing.events_enabled = false
	crossing.provisions = 9999.0
	crossing.water = 9999.0
	var m := crossing.map
	var picks := {"Forest": "lm_lanternwood", "Hills": "lm_copper_barrows", "River": "lm_the_silverrun",
		"Swamp": "lm_the_murkfens", "Mountain": "lm_the_cogspires", "Blight": "lm_the_ashen_hollow", "Glow": "lm_halo_glade"}
	var stops := {"Forest": "village", "Hills": "lookout", "River": "post", "Swamp": "ruins", "Mountain": "waystation", "Blight": "warden", "Glow": "sanctum"}
	# The overworld on crossing 5, all revealed, with the dust biomes spread over it.
	m.spread_biomes(5)
	for id in m.junctions:
		crossing.seen[id] = true
	exp.call("_toggle_world")
	await _frames(5)
	await _shot("0_overworld_biomes")
	exp.call("_toggle_world")
	exp.call("_set_off")
	crossing.trip_days_left = 50.0
	var bd: TravelBackdrop = exp.get("_backdrop")
	var amb: TrailAmbience = exp.get("_ambience")
	var i := 1
	for t in picks:
		bd.set_scene(t, picks[t])
		amb.set_terrain(t)
		amb.set_weather({"Blight": "ashfall", "Glow": "shimmer"}.get(t, "clear"))
		amb.show_settlement("")
		await _frames(150)
		await _shot("%d_%s_road" % [i, t.to_lower()])
		i += 1
	# Stops in each terrain, scenery halted.
	bd.set_moving(false)
	amb.set_moving(false)
	for t in stops:
		bd.set_scene(t, picks[t])
		amb.set_terrain(t)
		amb.show_settlement(stops[t])
		await _frames(40)
		await _shot("%d_%s_%s" % [i, t.to_lower(), stops[t]])
		i += 1
	amb.show_settlement("town")
	bd.set_scene("Hills", "lm_windmere")
	amb.set_terrain("Hills")
	await _frames(40)
	await _shot("%d_town_gate" % i)
	i += 1
	# Battle backdrops: put the wagon on a road into a region of each terrain.
	root.remove_child(exp)
	for t in picks:
		var to := ""
		for id in m.junctions:
			if m.region_of(id).get("terrain", "") == t:
				to = id
				break
		crossing.state = Expedition.State.TRAVELLING
		crossing.trip = {"from": crossing.at, "to": to if to != "" else crossing.at, "terrain": t, "days": 1}
		var b := BattleScreen.new()
		b.setup(crossing, false, true)
		root.add_child(b)
		await _frames(30)
		await _shot("%d_battle_%s" % [i, t.to_lower()])
		root.remove_child(b)
		b.free()
		i += 1
	quit(0)


func _frames(n: int) -> void:
	for k in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

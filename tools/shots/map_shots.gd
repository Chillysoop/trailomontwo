extends SceneTree
## Screenshots of the overworld map for review (needs a display, e.g. xvfb-run).
## Usage: godot --path . --script res://tools/shots/map_shots.gd -- <out_dir>

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
	await _shot("1_stop_small_map")
	exp.call("_toggle_world")
	await _frames(5)
	await _shot("2_overworld_start")
	exp.call("_toggle_world")
	# A few stops in: more fog lifted, a lookout, a rumor, a couple of wild packs met.
	var crossing: Expedition = exp.get("crossing")
	crossing.events_enabled = false
	for i in 5:
		var best: Dictionary = {}
		var bh := 999
		for seg in crossing.exits():
			var h := crossing.map.hops(seg["to"], crossing.map.goal)
			if h < bh:
				bh = h
				best = seg
		crossing.travel(best)
		crossing.hear_rumor()
		if crossing.state != Expedition.State.AT_JUNCTION:
			break
	crossing.meet_pack({"front": ["frostsnip"], "back": ["plateflit"]})
	exp.call("_reset_view")
	exp.call("_show_junction")
	await _frames(20)
	await _shot("3_stop_five_in")
	exp.call("_toggle_world")
	await _frames(5)
	await _shot("4_overworld_five_in")
	var wm: RouteMapView = exp.get("_world_map")
	wm.zoom = 0.8
	wm.center = crossing.map.pos(crossing.at)
	wm.queue_redraw()
	await _frames(5)
	await _shot("5_overworld_zoomed")
	exp.call("_toggle_world")
	exp.call("_set_off")
	crossing.trip_days_left = 50.0
	await _frames(60)
	await _shot("6_road_minimap")
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

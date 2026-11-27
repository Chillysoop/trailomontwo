extends SceneTree
## Route card, river crossing, frost HUD and job board screenshots for the paths wave.
## Usage: xvfb-run godot --path . --script res://tools/shots/paths_shots.gd -- <out_dir>

var out_dir := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	Expedition.default_map = "world"
	var exp: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(exp)
	await _frames(10)
	exp.call("_begin", Expedition.new_default(11), 1)
	await _frames(10)
	var c: Expedition = exp.get("crossing")
	_close_guide(exp)
	exp.call("_pack_for_me")
	c.departed = true
	exp.call("_show_tab", "route")
	await _frames(5)
	# Hover the first route button so its card shows.
	var exits := c.exits()
	if not exits.is_empty():
		exp.call("_pick", exits[0])
	await _frames(5)
	await _shot("1_route_card")
	# A river in flood, cold weather, ferry nearby.
	c.weather = "cold"
	c.pending_event = Rivers.make(3, true, true, 1)
	exp.call("_halt")
	exp.call("_show_event")
	await _frames(10)
	await _shot("2_river_crossing")
	exp.get("_event").visible = false
	# Late in the season: frost countdown in the HUD.
	c.day = c.frost_day - 3
	exp.call("_refresh_hud")
	await _frames(5)
	await _shot("3_frost_countdown")
	# A job board at a village.
	for id in c.map.junctions:
		if Expedition.JOB_BOARDS.has(c.map.kind_of(id)) and id != c.map.goal:
			c.at = id
			c.job_offer = {}
			if not c.delivery_offer().is_empty():
				break
	c.day = 3
	exp.call("_show_junction")
	exp.call("_show_tab", "trade")
	await _frames(8)
	await _shot("4_job_board")
	quit()


func _close_guide(exp: Node) -> void:
	var g: Node = exp.get("_guide")
	if g != null and is_instance_valid(g):
		g.queue_free()
	exp.set("_guide", null)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

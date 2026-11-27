extends SceneTree
## Outfitter, wagon tab, repair and barter screenshots for the gear wave.
## Usage: xvfb-run godot --path . --script res://tools/shots/gear_shots.gd -- <out_dir>

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
	await _frames(3)
	await _shot("1_outfitter_empty")
	exp.call("_pack_for_me")
	c.buy("reed_pipe")
	exp.call("_refresh_trade")
	exp.call("_refresh_wagon_page")
	await _frames(5)
	await _shot("2_outfitter_packed")
	exp.call("_show_tab", "wagon")
	await _frames(5)
	await _shot("3_wagon_tab")
	# A broken axle with no spare: the jury-rig.
	c.spares.erase("axle")
	c.wagon.break_part(Wagon.Part.RUNNING_GEAR)
	exp.call("_refresh_wagon_page")
	await _frames(5)
	await _shot("4_broken_axle_no_spare")
	# Second crossing, the other shopkeeper.
	var c2 := Expedition.new_default(12)
	c2.set_crossing(2)
	c2.empty_supplies()
	exp.call("_begin", c2, 2)
	await _frames(10)
	_close_guide(exp)
	exp.call("_pack_for_me")
	await _frames(5)
	await _shot("5_outfitter_marrow")
	# A barter on the road.
	c2.departed = true
	exp.call("_set_off")
	await _frames(5)
	c2.provisions = 15.0
	c2.pending_event = c2.make_barter()
	exp.call("_halt")
	exp.call("_show_event")
	await _frames(10)
	await _shot("6_barter")
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

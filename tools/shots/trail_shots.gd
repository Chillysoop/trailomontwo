extends SceneTree
## Screenshots of trail life for review (needs a display, e.g. xvfb-run).
## Usage: godot --path . --script res://tools/shots/trail_shots.gd -- <out_dir>

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
	await _frames(20)
	await _shot("1_stop_route")
	exp.call("_show_tab", "trade")
	await _frames(5)
	await _shot("2_stop_trade")
	exp.call("_show_tab", "route")
	# On the road in the rain, with moments popping up.
	var crossing: Expedition = exp.get("crossing")
	crossing.events_enabled = false
	exp.call("_set_off")
	crossing.trip_days_left = 50.0
	crossing.weather = "rain"
	exp.get("_ambience").call("set_weather", "rain")
	crossing.trip["terrain"] = "Forest"
	crossing.trigger_moment(TrailMoments.by_id("berries"))
	crossing.trigger_moment(TrailMoments.by_id("rain_barrels"))
	crossing.trigger_moment(TrailMoments.by_id("travellers"))
	exp.call("_show_new_moments")
	exp.call("_refresh_hud")
	await _frames(60)
	await _shot("3_road_rain")
	# A trail event card.
	crossing.pending_event = TrailEvents.by_id("swollen_ford")
	crossing.trip["terrain"] = "River"
	exp.get("_ambience").call("set_terrain", "River")
	exp.call("_halt")
	exp.call("_show_event")
	await _frames(10)
	await _shot("4_event_ford")
	exp.call("_choose_event", 0)
	await _frames(10)
	await _shot("5_event_result")
	exp.call("_continue_after_event")
	crossing.pending_event = TrailEvents.by_id("trapped_wild")
	crossing.weather = "fog"
	exp.get("_ambience").call("set_weather", "fog")
	exp.call("_halt")
	exp.call("_show_event")
	await _frames(10)
	await _shot("6_event_snare_fog")
	exp.call("_choose_event", 1)
	await _frames(10)
	await _shot("7_snare_result")
	exp.call("_continue_after_event")
	crossing.weather = "cold"
	exp.get("_ambience").call("set_weather", "cold")
	exp.get("_ambience").call("set_terrain", "Mountain")
	crossing.trip["terrain"] = "Mountain"
	crossing.trigger_moment(TrailMoments.by_id("grave"))
	crossing.trigger_moment(TrailMoments.by_id("warm_huddle"))
	exp.call("_show_new_moments")
	await _frames(90)
	await _shot("8_road_snow_grave")
	exp.get("_ambience").call("set_weather", "fog")
	crossing.weather = "fog"
	exp.call("_refresh_hud")
	await _frames(300)
	await _shot("9_road_fog")
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

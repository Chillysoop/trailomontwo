extends SceneTree
## People on the trail: Pip Gasket's workshop, the locals' advice, the Fernwicks' story cards.
## Usage: xvfb-run godot --path . --script res://tools/shots/people_shots.gd -- <out_dir>

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
	# Close the starter picker, then use a full team for the shots.
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text.begins_with("Choose "):
			(n as Button).pressed.emit()
			break
	await _frames(5)
	var c := Expedition.new_default(11)
	for id in ["brambleback", "coilhusk", "reedwake", "mirelamp", "gillhorn"]:
		if not c.roster.has(id) and c.roster.size() < Expedition.TEAM_MAX:
			c.roster.append(id)
			c.creature_hp[id] = c.max_hp(id)
			c.fatigue[id] = 0.0
	c.tidy_lineup()
	exp.call("_begin", c, 1)
	await _frames(10)
	c = exp.get("crossing")
	_close_guide(exp)
	exp.call("_pack_for_me")
	# A stop with two locals.
	exp.get("_event").visible = false
	c.state = Expedition.State.AT_JUNCTION
	for id in c.map.junctions:
		if id != c.map.start and id != c.workshop() and ["village", "waystation"].has(c.map.kind_of(id)):
			c.at = id
			break
	exp.call("_show_junction")
	exp.call("_show_tab", "trade")
	exp.call("_refresh_trade")
	await _frames(10)
	await _shot("1_folk")
	# Pip's workshop.
	c.at = c.workshop()
	c.coins = 140
	c.upgrades["brass_horn"] = true
	exp.call("_show_junction")
	exp.call("_show_tab", "trade")
	exp.call("_refresh_trade")
	await _frames(10)
	await _shot("2_workshop")
	exp.call("_show_tab", "wagon")
	exp.call("_refresh_wagon_page")
	await _frames(10)
	await _shot("3_wagon_upgrades")
	# The Fernwicks.
	c.departed = true
	exp.call("_set_off")
	await _frames(5)
	exp.call("_halt")
	c.upgrades["float_tanks"] = true
	for stage in [0, 2, 4]:
		c.family_stage = stage
		c.family_trust = 3
		c.pending_event = c.meet_family()
		exp.call("_show_event")
		await _frames(10)
		await _shot("4_family_%d" % stage)
		exp.get("_event").visible = false
	c.pending_event = c.make_river(3)
	exp.call("_show_event")
	await _frames(10)
	await _shot("5_river_float_tanks")
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

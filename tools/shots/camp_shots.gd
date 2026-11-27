extends SceneTree
## Camp life: morale in the HUD, the camp row, a foraging card, the campfire.
## Usage: xvfb-run godot --path . --script res://tools/shots/camp_shots.gd -- <out_dir>

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
	c.state = Expedition.State.AT_JUNCTION
	for id in c.map.junctions:
		if id != c.map.start and String(c.map.region_of(id).get("terrain", "")) == "Forest" and c.map.kind_of(id) != "town":
			c.at = id
			break
	c.morale = 82
	c.pantry = {"mushrooms": 1, "berries": 2, "herbs": 1}
	exp.call("_show_junction")
	exp.call("_show_tab", "wagon")
	exp.call("_refresh_wagon_page")
	await _frames(10)
	await _shot("1_camp_row")
	c.known_plants = {}
	c.forage()
	c.pending_event = Camp.forage_card("Forest", ["mushrooms", "berries"], "violet_caps", false, false)
	exp.call("_show_event")
	await _frames(10)
	await _shot("2_forage")
	exp.get("_event").visible = false
	c.pending_event = {}
	c.morale = 20
	exp.call("_do_rest")
	exp.call("_refresh_hud")
	await _frames(10)
	await _shot("3_campfire_grim")
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

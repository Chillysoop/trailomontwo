extends SceneTree
## Battle screenshots on every terrain, opened from the travel screen like a real trail fight,
## to check nothing from the road scenery covers the teams.
## Usage: xvfb-run godot --path . --script res://tools/shots/battle_fg_shots.gd -- <out_dir>

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
	await _frames(10)
	var c: Expedition = exp.get("crossing")
	c.events_enabled = false
	exp.call("_set_off")
	await _frames(5)
	for t in ["Forest", "Hills", "River", "Swamp", "Mountain", "Snow", "Jungle", "Blight", "Glow"]:
		c.trip["terrain"] = t
		exp.get("_backdrop").call("set_scene", t, "")
		exp.get("_ambience").call("set_terrain", t)
		var pack := CombatData.guardian_for(2)
		c.pending_encounter = {"pack": pack, "scale": 1.0, "guardian": true}
		exp.call("_halt")
		exp.call("_open_battle", false)
		await _frames(20)
		await _shot(t.to_lower() + "_lineup")
		var b: Node = exp.get("_battle")
		b.call("_start_combat")
		await _frames(40)
		await _shot(t.to_lower() + "_combat")
		c.pending_encounter = {}
		b.emit_signal("finished", [])
		await _frames(10)
		c.state = Expedition.State.TRAVELLING
		exp.get("_event").visible = false
		for id in c.roster:
			c.creature_hp[id] = c.max_hp(id)
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

extends SceneTree
## The trail-boss picker after the starter, and the outfitter's choice of destination.
## Usage: xvfb-run godot --path . --script res://tools/shots/boss_shots.gd -- <out_dir>

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
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text.begins_with("Choose "):
			(n as Button).pressed.emit()
			break
	await _frames(10)
	await _shot("1_background_pick")
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text == "Lead as Merchant":
			(n as Button).pressed.emit()
			break
	await _frames(5)
	var g: Node = exp.get("_guide")
	if g != null and is_instance_valid(g):
		g.queue_free()
	exp.set("_guide", null)
	await _frames(5)
	exp.call("_show_tab", "trade")
	exp.call("_refresh_trade")
	await _frames(10)
	await _shot("2_destinations")
	var c: Expedition = exp.get("crossing")
	c.choose_destination("alt")
	exp.call("_refresh_trade")
	await _frames(10)
	await _shot("3_destination_alt")
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

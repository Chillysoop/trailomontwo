extends SceneTree
## Takes screenshots of hover tips for review (needs a display, e.g. xvfb-run).
## Usage: godot --path . --script res://tools/shots/hover_shots.gd -- <out_dir>

var out_dir := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	# Battle: lineup with an enemy hovered.
	var battle: Node = load("res://scenes/battle.tscn").instantiate()
	root.add_child(battle)
	await _frames(10)
	await _hover(Formation.slot_feet(Formation.Side.ENEMY, Formation.Row.FRONT, 1) + Vector2(0, -20))
	await _shot("battle_hover_enemy")
	await _hover(Formation.slot_feet(Formation.Side.PLAYER, Formation.Row.BACK, 1) + Vector2(0, -20))
	await _shot("battle_hover_mine")
	# Hover the first icon of the synergy text.
	var syn: RichTextLabel = battle.get("_syn_mine")
	await _hover(syn.get_global_rect().position + Vector2(5, 18))
	await _shot("battle_hover_synergy")
	var info: RichTextLabel = battle.get("_info")
	battle.set("_inspect", {"id": "mirelamp", "mine": true})
	battle.call("_show_info")
	await _frames(3)
	await _hover(Vector2(0, 0))
	await _shot("battle_info")
	battle.call("_start_combat")
	await _frames(240)
	await _hover(Formation.slot_feet(Formation.Side.PLAYER, Formation.Row.FRONT, 1) + Vector2(0, -20))
	await _shot("battle_combat_hover")
	battle.queue_free()
	await _frames(2)
	# Expedition: HUD and wagon page.
	var exp: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(exp)
	await _frames(10)
	await _hover(Vector2(60, 13))
	await _shot("trail_hud_hover")
	await _hover(Vector2(450, 260))
	await _shot("trail_route_card")
	await _hover(Caravan.HAULER_SLOTS[0] + Vector2(0, -20))
	await _shot("trail_hover_hauler")
	exp.call("_show_tab", true)
	await _frames(5)
	await _hover(Vector2(380, 150))
	await _shot("trail_wagon_page")
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _hover(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	root.warp_mouse(p)
	root.push_input(ev)
	await _frames(4)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)

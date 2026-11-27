extends SceneTree
## Ailment card, landmark card, the guardian road choice, the arrival score and the epitaph.
## Usage: xvfb-run godot --path . --script res://tools/shots/stakes_shots.gd -- <out_dir>

var out_dir := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	Graves.path = "user://shot_graves.json"
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
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text.begins_with("Lead as "):
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
	c.departed = true
	exp.call("_set_off")
	await _frames(5)
	exp.call("_halt")
	# The trail doctor.
	c.light_dust = 2
	c.pending_event = c.catch_ailment("moss_lung", c.roster[0])
	exp.call("_show_event")
	await _frames(10)
	await _shot("1_ailment")
	exp.get("_event").visible = false
	# A landmark card.
	for id in c.map.junctions:
		if Landmarks.has(c.map.landmark(id)) and id != c.map.start:
			c.at = id
			break
	c.pending_event = {}
	c.landmarks_seen = {}
	c._landmark_card()
	exp.call("_show_event")
	await _frames(10)
	await _shot("2_landmark")
	exp.get("_event").visible = false
	# The guardian road.
	c.coins = 120
	c.pending_event = {}
	c.pending_encounter = {"pack": c.guardian_pack(), "scale": CombatData.GUARDIAN_SCALE, "guardian": true}
	exp.call("_show_encounter")
	await _frames(10)
	await _shot("3_guardian_road")
	exp.get("_event").visible = false
	c.pending_encounter = {}
	# Arrival with a scrapbook.
	c.finale = "rapids"
	c.deliveries_on_time = 1
	c.note("river", "Floated the Silverrun in flood.")
	c.note("cargo", "Delivered Lamp oil for Fernhollow on time.")
	c.note("score", "Reached Westwatch on day %d." % c.day)
	c.at = c.map.goal
	c.state = Expedition.State.ARRIVED
	c.score_history.append(c.arrival_score()["total"])
	exp.call("_show_end", true)
	await _frames(10)
	await _shot("4_arrival_score")
	# A failed caravan and its epitaph.
	c.state = Expedition.State.FAILED
	c.fail_reason = "Your traveller ran out of food and water."
	exp.call("_show_end", false)
	(exp.get("_epitaph") as LineEdit).text = "Should have waited for the river to drop."
	await _frames(10)
	await _shot("5_epitaph")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Graves.path))
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

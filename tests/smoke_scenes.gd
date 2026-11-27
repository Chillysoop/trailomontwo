extends SceneTree
## Loads every playable scene, lets it run a few frames, and fails if anything is missing.
## Usage: godot --headless --path . --script res://tests/smoke_scenes.gd

const SCENES := [
	"res://scenes/title_screen.tscn",
	"res://scenes/travel_preview.tscn",
	"res://scenes/battle.tscn",
	"res://scenes/expedition.tscn",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures := 0
	for path in SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			printerr("FAIL could not load ", path)
			failures += 1
			continue
		var node := packed.instantiate()
		root.add_child(node)
		for i in 5:
			await process_frame
		var count := _count(node)
		if count < 5:
			printerr("FAIL %s built only %d nodes" % [path, count])
			failures += 1
		else:
			print("ok %s (%d nodes)" % [path, count])
		node.queue_free()
		await process_frame
	failures += await _battle_scenery_check()
	print("%d scenes, %d failures" % [SCENES.size(), failures])
	quit(1 if failures > 0 else 0)


func _count(n: Node) -> int:
	var total := 1
	for c in n.get_children():
		total += _count(c)
	return total


## A trail battle opens on top of the travel screen. Nothing from the road scenery may still
## draw there, or it covers the teams (the bottom lane sits right above the foreground plants).
func _battle_scenery_check() -> int:
	var exp: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(exp)
	await process_frame
	var c: Expedition = exp.get("crossing")
	c.events_enabled = false
	exp.call("_set_off")
	c.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.0, "guardian": false}
	exp.call("_open_battle", false)
	await process_frame
	var battle: Node = exp.get("_battle")
	var bad: Array[String] = []
	for ch in exp.get_children():
		if ch == battle or not (ch is CanvasItem) or not (ch as CanvasItem).visible:
			continue
		if ch is CanvasLayer:
			continue
		bad.append(str(ch.name))
	for ch in exp.get_children():
		if ch is CanvasLayer and (ch as CanvasLayer).visible:
			bad.append(str(ch.name))
	exp.queue_free()
	await process_frame
	if bad.is_empty():
		print("ok battles hide the travel scenery")
		return 0
	printerr("FAIL travel scenery still shows during a battle: ", bad)
	return 1

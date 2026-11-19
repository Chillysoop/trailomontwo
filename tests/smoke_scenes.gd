extends SceneTree
## Loads every playable scene, lets it run a few frames, and fails if anything is missing.
## Usage: godot --headless --path . --script res://tests/smoke_scenes.gd

const SCENES := [
	"res://scenes/title_screen.tscn",
	"res://scenes/travel_preview.tscn",
	"res://scenes/battle_preview.tscn",
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
	print("%d scenes, %d failures" % [SCENES.size(), failures])
	quit(1 if failures > 0 else 0)


func _count(n: Node) -> int:
	var total := 1
	for c in n.get_children():
		total += _count(c)
	return total

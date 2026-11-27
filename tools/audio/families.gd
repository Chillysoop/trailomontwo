extends SceneTree
## Prints every Trailomon family (first form of each line) as JSON, for gen_audio.py:
##   godot --headless --path . --script res://tools/audio/families.gd


func _init() -> void:
	var out := {}
	for id in Species.DATA:
		var fam := Species.family(id)
		if not out.has(fam):
			out[fam] = {"name": Species.info(fam)["name"], "type": Species.info(fam)["type"], "size": Species.info(fam)["size"],
				"rarity": Species.rarity(fam), "biome": Species.biome(fam)}
	print("FAMILIES " + JSON.stringify(out))
	quit()

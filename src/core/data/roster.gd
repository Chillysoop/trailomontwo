class_name Roster
extends RefCounted
## The roster data files. Each file in src/core/data/roster/ holds one habitat's (or dust
## biome's) Trailomon: SPECIES, KITS and MOVES. They are merged into Species.DATA,
## CombatData.KITS and MovePool.MOVES when those classes load, after the hand-written
## entries that still live in those classes (the first 13 Trailomon and the Hollow Stag).
##
## To add a Trailomon, add it to its habitat's file: species entry, kit and its three moves.
## Dust-biome Trailomon go in blight.gd / glow.gd and carry "biome": "Blight" or "Glow".

const FILES := [
	preload("res://src/core/data/roster/forest.gd"),
	preload("res://src/core/data/roster/river.gd"),
	preload("res://src/core/data/roster/swamp.gd"),
	preload("res://src/core/data/roster/mountain.gd"),
	preload("res://src/core/data/roster/snow.gd"),
	preload("res://src/core/data/roster/jungle.gd"),
	preload("res://src/core/data/roster/blight.gd"),
	preload("res://src/core/data/roster/glow.gd"),
	preload("res://src/core/data/roster/guardians.gd"),
]


## `base` plus the named table ("SPECIES", "KITS" or "MOVES") from every roster file.
## A duplicate id is an error (the later entry is ignored).
static func merged(table: String, base: Dictionary) -> Dictionary:
	var out := base.duplicate()
	for f in FILES:
		var part: Dictionary = f.get(table)
		for id in part:
			if out.has(id):
				push_error("Roster: duplicate %s id '%s'" % [table, id])
				continue
			out[id] = part[id]
	return out

class_name Species
extends RefCounted
## Creature species used by the first playable.
##
## size sets daily upkeep (provisions per day): small 0.5, medium 1, large 2.
## hauling is pulling strength in hauling units (0 = cannot haul).
## Capabilities are ranks 1-3 used by event checks.

const UPKEEP := {"small": 0.5, "medium": 1.0, "large": 2.0}

const DATA := {
	"brambleback": {"name": "Brambleback", "type": "Forest", "size": "large", "hauling": 150,
		"capabilities": {"strength": 3, "guard": 3}},
	"coilhusk": {"name": "Coilhusk", "type": "Forest", "size": "large", "hauling": 130,
		"capabilities": {"strength": 2, "steady": 3}},
	"reedwake": {"name": "Reedwake", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "scout": 1}},
	"mirelamp": {"name": "Mirelamp", "type": "Swamp", "size": "small", "hauling": 0,
		"capabilities": {"light": 3, "heal": 2, "scout": 1}},
	"rimehare": {"name": "Rimehare", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 2}},
	"scythelk": {"name": "Scythelk", "type": "Mountain", "size": "large", "hauling": 90,
		"capabilities": {"clear": 3, "strength": 2}},
	"gillhorn": {"name": "Gillhorn", "type": "Swamp", "size": "medium", "hauling": 60,
		"capabilities": {"float": 2, "strength": 2}},
	"inkhoot": {"name": "Inkhoot", "type": "River", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "float": 1}},
}


static func info(id: String) -> Dictionary:
	return DATA[id]


static func upkeep(id: String) -> float:
	return UPKEEP[DATA[id]["size"]]


static func capability(id: String, cap: String) -> int:
	return int(DATA[id]["capabilities"].get(cap, 0))

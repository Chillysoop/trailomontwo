class_name TestRoute
extends RefCounted
## The first playable's short test route: Eastgate to Westwatch.
## Three macro routes: the forest (long, easy hauling), the river (wet, needs floating),
## and the ridge (short, steep hauling).

const START := "eastgate"
const GOAL := "westwatch"

## pos is the junction's place on the map panel, in pixels of a 360x200 map area.
const JUNCTIONS := {
	"eastgate": {"name": "Eastgate", "pos": Vector2(318, 104)},
	"mossford": {"name": "Mossford", "pos": Vector2(262, 136)},
	"ridge_fork": {"name": "Ridge Fork", "pos": Vector2(262, 52)},
	"lantern_hollow": {"name": "Lantern Hollow", "pos": Vector2(180, 150)},
	"rail_bridge": {"name": "Old Rail Bridge", "pos": Vector2(190, 108)},
	"cogspire": {"name": "Cogspire Ruins", "pos": Vector2(150, 40)},
	"thornmarsh": {"name": "Thornmarsh", "pos": Vector2(96, 138)},
	"westwatch": {"name": "Westwatch", "pos": Vector2(36, 92)},
}

## days: travel days at normal pace. terrain_factor multiplies hauling demand.
## risk 1-3: how dangerous the segment is (used by events).
const SEGMENTS := [
	{"a": "eastgate", "b": "mossford", "terrain": "Forest", "days": 2, "terrain_factor": 1.0, "risk": 1},
	{"a": "eastgate", "b": "ridge_fork", "terrain": "Hills", "days": 1, "terrain_factor": 1.3, "risk": 1},
	{"a": "mossford", "b": "lantern_hollow", "terrain": "Forest", "days": 2, "terrain_factor": 1.0, "risk": 1},
	{"a": "mossford", "b": "rail_bridge", "terrain": "River", "days": 1, "terrain_factor": 1.1, "risk": 2},
	{"a": "ridge_fork", "b": "rail_bridge", "terrain": "Mountain", "days": 2, "terrain_factor": 1.4, "risk": 2},
	{"a": "ridge_fork", "b": "cogspire", "terrain": "Hills", "days": 2, "terrain_factor": 1.2, "risk": 2},
	{"a": "lantern_hollow", "b": "thornmarsh", "terrain": "Swamp", "days": 3, "terrain_factor": 1.2, "risk": 2},
	{"a": "rail_bridge", "b": "thornmarsh", "terrain": "River", "days": 2, "terrain_factor": 1.0, "risk": 2},
	{"a": "rail_bridge", "b": "cogspire", "terrain": "Hills", "days": 1, "terrain_factor": 1.2, "risk": 2},
	{"a": "cogspire", "b": "westwatch", "terrain": "Mountain", "days": 2, "terrain_factor": 1.5, "risk": 3},
	{"a": "thornmarsh", "b": "westwatch", "terrain": "Forest", "days": 2, "terrain_factor": 1.0, "risk": 1},
]


## Segments leaving a junction, each returned with "to" set to the far end.
static func exits(junction: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in SEGMENTS:
		if s["a"] == junction or s["b"] == junction:
			var seg: Dictionary = s.duplicate()
			seg["from"] = junction
			seg["to"] = s["b"] if s["a"] == junction else s["a"]
			out.append(seg)
	return out


static func junction_name(id: String) -> String:
	return JUNCTIONS[id]["name"]

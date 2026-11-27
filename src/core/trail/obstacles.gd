class_name Obstacles
extends RefCounted
## Things in the way, placed fresh on every crossing of a generated map (none on the test route):
##
##   Sleepy giants: a huge wild Trailomon asleep across a road. Wake it and fight (win and you
##     may catch it), feed it and it rolls aside, or take a long detour.
##   Blocked roads: a rockfall, thornwall, fog bog, ice shelf or washout. A Trailomon with the
##     right trail job clears it; anyone can force through, slowly, so no road is ever shut.
##   Deep wilds: long roads far from any stop. Two extra days, every fight is likelier, and
##     rarer Trailomon live there (better catches).
##   Legendary lairs: from crossing 2, a legendary sleeps at the end of a lookout or ruins side
##     trip. Beat it there and the catch is much likelier than anywhere else.
##
## Rumors at stops point at them (Expedition.hear_rumor).

const GIANTS := {1: 1, 2: 2}
const GIANT_MAX := 2
const GATES := 3
const DEEP := 2
const LAIRS := 2
const LAIR_FROM := 2
## How long the deep wilds stretch a road, and the extra daily fight chance there.
const DEEP_DAYS := 2
const DEEP_FIGHT := 0.15
## Catch bonuses: a lair's legendary, and anything met in the deep wilds.
const LAIR_CATCH := 0.3
const DEEP_CATCH := 0.1
## Feeding a giant, and the detour around it.
const GIANT_FOOD := 25
const DETOUR_DAYS := 2
const FORCE_DAYS := 2
const GIANT_SCALE := 1.15

## Blocked-road kinds by terrain: the job that clears it.
const GATE_KINDS := {
	"Forest": {"cap": "clear", "name": "Thornwall", "icon": "job_clear",
		"text": "A wall of thornbrush has grown right over the road."},
	"Jungle": {"cap": "clear", "name": "Vine curtain", "icon": "job_clear",
		"text": "Vines as thick as rope hang across the road like a curtain."},
	"Mountain": {"cap": "strength", "name": "Rockfall", "icon": "job_strength",
		"text": "A rockfall has buried the road under boulders."},
	"Hills": {"cap": "strength", "name": "Landslip", "icon": "job_strength",
		"text": "Half the hillside has slid down onto the road."},
	"Swamp": {"cap": "light", "name": "Fog bog", "icon": "job_light",
		"text": "A thick fog sits on the bog. The road vanishes into it."},
	"Blight": {"cap": "light", "name": "Dust dark", "icon": "job_light",
		"text": "Dark dust hangs so thick that noon looks like midnight."},
	"Glow": {"cap": "light", "name": "Glare maze", "icon": "job_light",
		"text": "Light dust bends the air into a glittering maze."},
	"Snow": {"cap": "cold", "name": "Ice shelf", "icon": "job_cold",
		"text": "A sheet of ice tilts across the road, slick as glass."},
	"River": {"cap": "float", "name": "Washout", "icon": "job_float",
		"text": "Floodwater has torn the road away. Only a channel is left."},
}


static func key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


## Place this crossing's obstacles. Returns {"roads": {key: {...}}, "lairs": {junction: {...}}}.
static func place(map: WorldMap, crossing_no: int) -> Dictionary:
	var out := {"roads": {}, "lairs": {}}
	if map == null or map.is_test:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = map.seed * 7919 + crossing_no * 104729
	var ends := [map.start, map.goal]
	var middle: Array = []
	for s in map.segments:
		var la := int(map.junctions[s["a"]]["layer"])
		var lb := int(map.junctions[s["b"]]["layer"])
		if s.get("rough", false) or ends.has(s["a"]) or ends.has(s["b"]):
			continue
		if String(s["a"]).begins_with("s") or String(s["b"]).begins_with("s"):
			continue
		if mini(la, lb) < 2 or maxi(la, lb) > WorldMap.LAYERS - 3:
			continue
		middle.append(s)
	middle.sort_custom(func(x, y): return key(x["a"], x["b"]) < key(y["a"], y["b"]))
	_shuffle(middle, rng)
	var roads: Dictionary = out["roads"]
	var giants := int(GIANTS.get(crossing_no, GIANT_MAX))
	for s in middle:
		var k := key(s["a"], s["b"])
		var terrain := String(s["terrain"])
		if giants > 0 and terrain != "River":
			var sp := giant_for(terrain, crossing_no, rng)
			if sp != "":
				roads[k] = {"kind": "giant", "species": sp}
				giants -= 1
				continue
		if _count(roads, "gate") < GATES and GATE_KINDS.has(terrain):
			roads[k] = {"kind": "gate", "cap": GATE_KINDS[terrain]["cap"], "name": GATE_KINDS[terrain]["name"]}
			continue
		if _count(roads, "deep") < DEEP and int(s["days"]) >= 2:
			roads[k] = {"kind": "deep"}
			continue
		if giants <= 0 and _count(roads, "gate") >= GATES and _count(roads, "deep") >= DEEP:
			break
	if crossing_no >= LAIR_FROM:
		var dead: Array = []
		for id in map.junctions:
			if String(id).begins_with("s") and ["lookout", "ruins"].has(map.kind_of(id)):
				dead.append(id)
		dead.sort()
		_shuffle(dead, rng)
		for id in dead:
			if out["lairs"].size() >= LAIRS:
				break
			var terrain := String(map.region_of(id).get("terrain", "Forest"))
			var sp := legendary_for(terrain, rng)
			if sp != "":
				out["lairs"][id] = {"species": sp, "done": false}
	return out


## A big, sleepy, fully grown wild Trailomon of this habitat (not legendary).
static func giant_for(terrain: String, crossing_no: int, rng: RandomNumberGenerator) -> String:
	var picks: Array[String] = []
	for id in Encounters.pool(terrain, crossing_no):
		if Species.info(id)["size"] == "large" and Species.rarity(id) != "legendary" and Species.evolutions(id).is_empty() and CombatData.KITS.has(id):
			picks.append(id)
	if picks.is_empty():
		for id in Encounters.pool(terrain, crossing_no):
			if Species.info(id)["size"] == "large" and Species.rarity(id) != "legendary" and CombatData.KITS.has(id):
				picks.append(id)
	picks.sort()
	return picks[rng.randi_range(0, picks.size() - 1)] if not picks.is_empty() else ""


## A legendary of this habitat, first form of its line where it has one.
static func legendary_for(terrain: String, rng: RandomNumberGenerator) -> String:
	var picks: Array[String] = []
	for id in Species.DATA:
		if Species.rarity(id) == "legendary" and String(Species.info(id)["type"]) == terrain and Species.stage(id) == 1 and CombatData.KITS.has(id):
			picks.append(id)
	picks.sort()
	return picks[rng.randi_range(0, picks.size() - 1)] if not picks.is_empty() else ""


## The event card for a sleeping giant on the road.
static func giant_event(sp: String, has_food: bool) -> Dictionary:
	var n := String(Species.info(sp)["name"])
	return {"id": "giant", "kind": "hazard", "title": "A sleeping giant", "species": sp,
		"text": "A huge %s lies asleep right across the road, snoring like a landslide." % n,
		"choices": [
			{"label": "Wake it and fight", "success": {"text": "You bang a pot. One eye opens. Then both.", "battle": "giant"}},
			{"label": "Feed it till it rolls aside", "cost": {"food": -GIANT_FOOD},
				"success": {"text": "It eats, sighs, and rolls off the road in its sleep.", "clear_block": true}},
			{"label": "Take the long way round", "success": {"text": "You leave it snoring and lose two days on goat paths.",
				"days": DETOUR_DAYS, "fatigue": 10}},
		]}


## The event card for a blocked road: clear it with the right job, or force through slowly.
static func gate_event(gate: Dictionary, crossing_no: int) -> Dictionary:
	var kind: Dictionary = {}
	for t in GATE_KINDS:
		if GATE_KINDS[t]["name"] == gate["name"]:
			kind = GATE_KINDS[t]
	var cap := String(gate["cap"])
	return {"id": "gate", "kind": "hazard", "title": String(gate["name"]), "text": String(kind.get("text", "The road is blocked.")),
		"choices": [
			{"label": "Clear the way", "cap": cap, "difficulty": 6 + mini(crossing_no, 6), "assist": {"strength": 2, "scout": 2} if cap != "strength" else {"clear": 2, "scout": 2},
				"success": {"text": "Cleared. The road is open again, for everyone after you too.", "clear_block": true},
				"mixed": {"text": "It takes all day, but you get through.", "clear_block": true, "days": 1},
				"failure": {"text": "No luck. You force a way through, and the wagon pays for it.", "days": FORCE_DAYS, "wear": 8, "fatigue": 10}},
			{"label": "Force a way through", "success": {"text": "Slow, hard work. Two days of it.", "days": FORCE_DAYS, "wear": 6, "fatigue": 8}},
		]}


## The event card at a legendary's lair.
static func lair_event(sp: String) -> Dictionary:
	var n := String(Species.info(sp)["name"])
	return {"id": "lair", "kind": "wonder", "title": "A legendary lair", "species": sp,
		"text": "Bones, old feathers and a warm hollow. %s sleeps here, and it is not small." % n,
		"choices": [
			{"label": "Step into the lair", "success": {"text": "It wakes. The air goes very still.", "battle": "lair"}},
			{"label": "Back away quietly", "success": {"text": "You leave it in peace. Maybe another day."}},
		]}


static func _count(roads: Dictionary, kind: String) -> int:
	var n := 0
	for k in roads:
		if roads[k]["kind"] == kind:
			n += 1
	return n


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

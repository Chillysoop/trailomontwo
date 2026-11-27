class_name Encounters
extends RefCounted
## Encounter tables: which wild Trailomon live on each terrain, by crossing.
##
## Hand-written packs (CombatData.PACKS) are set pieces. Alongside them, every terrain has a
## table built from the roster itself, so each new Trailomon turns up in the wild as soon as
## it is added, with no pack to write:
##   - Forest, River, Swamp, Mountain (and Snow, Jungle) roads: that habitat's Trailomon, plus
##     a few strays from the two habitats next to it on the type chart.
##   - Hills and unknown terrain: every habitat.
##   - Blight and Glow (the dust biomes): only their own biome's Trailomon, which live nowhere else.
## Rarity weights and legendary gating come from Species. Evolved forms turn up wild from
## later crossings (STAGE_FROM). Guardians never turn up.

const BIOMES := ["Blight", "Glow"]
## First crossing each evolution stage can turn up in the wild.
const STAGE_FROM := {1: 1, 2: 3, 3: 5}
## A home species counts this many times more than a stray from a neighbouring habitat.
const HOME_WEIGHT := 4
## Roles that stand in the front row of a generated pack.
const FRONT_ROLES := ["Guard", "Bruiser"]
## Lanes filled in this order (middle first).
const LANES := [1, 0, 2]


## The crossing band (1: crossings 1-2, 2: 3-4, 3: 5-6, 4: 7 and later).
static func band(crossing_no: int) -> int:
	return clampi((maxi(1, crossing_no) + 1) / 2, 1, 4)


static func can_turn_up(id: String, crossing_no: int) -> bool:
	if Species.is_boss(id) or not Species.can_meet(id, crossing_no):
		return false
	return crossing_no >= int(STAGE_FROM.get(Species.stage(id), 99))


## The species that live on this terrain, each listed once (home and strays alike).
static func pool(terrain: String, crossing_no: int) -> Array[String]:
	var out: Array[String] = []
	for id in weighted_pool(terrain, crossing_no):
		if not out.has(id):
			out.append(id)
	return out


## The table as a list for Species.pick_weighted: home species repeat HOME_WEIGHT times.
static func weighted_pool(terrain: String, crossing_no: int) -> Array[String]:
	var out: Array[String] = []
	var habitat: String = TrailLife.TERRAIN_HABITAT.get(terrain, "")
	var near: Array = CombatData.CHART.get(habitat, [])
	for id in Species.DATA:
		if not can_turn_up(id, crossing_no):
			continue
		var b := Species.biome(id)
		if BIOMES.has(terrain):
			if b == terrain:
				out.append(id)
			continue
		if b != "":
			continue
		var type: String = Species.info(id)["type"]
		if habitat == "":
			out.append(id)
		elif type == habitat:
			for i in HOME_WEIGHT:
				out.append(id)
		elif near.has(type):
			out.append(id)
	return out


## How often the table's pack comes up next to the hand-written packs: more often as
## the terrain's own roster grows.
static func table_weight(terrain: String, crossing_no: int) -> int:
	var n := pool(terrain, crossing_no).size()
	return 0 if n == 0 else 3 + n / 4


## A placeholder entry for CombatData.packs_for; Expedition builds the real pack with build().
static func table_entry(terrain: String, crossing_no: int) -> Dictionary:
	var w := table_weight(terrain, crossing_no)
	if w <= 0:
		return {}
	return {"id": "table_" + terrain.to_lower(), "table": true, "terrain": terrain, "weight": w,
		"title": title_for(terrain), "terrains": [terrain], "min_risk": 1, "front": [], "back": []}


static func title_for(terrain: String) -> String:
	match terrain:
		"Blight": return "Blighted Trailomon"
		"Glow": return "Glowing Trailomon"
		"Hills", "": return "Wild Trailomon"
	return "Wild %s Trailomon" % terrain


## Roll a pack from the terrain's table: 4 creatures on risk 1, up to 6 on risk 3. A small team
## meets smaller packs (one fewer than the team on a safe road, as many on risk 2, one more on
## risk 3), so a lone starter faces one wild Trailomon on a safe road. At most one legendary. Guards and bruisers stand in front.
static func build(terrain: String, crossing_no: int, risk: int, rng: RandomNumberGenerator, team_size := 6) -> Dictionary:
	var table := weighted_pool(terrain, crossing_no)
	if table.is_empty():
		return {}
	var plain := table.filter(func(id): return Species.rarity(id) != "legendary")
	var size := pack_size(team_size, risk)
	var picks: Array[String] = []
	var legend := false
	for i in size:
		var id := Species.pick_weighted(table if not legend or plain.is_empty() else plain, rng)
		if Species.rarity(id) == "legendary":
			legend = true
		picks.append(id)
	var front: Array[String] = []
	var back: Array[String] = []
	for id in picks:
		var role := String(CombatData.KITS[id]["role"])
		if FRONT_ROLES.has(role) and front.size() < 3:
			front.append(id)
		elif back.size() < 3:
			back.append(id)
		else:
			front.append(id)
	if front.is_empty() and not back.is_empty():
		front.append(back.pop_front())
	var names: Array[String] = []
	for id in picks:
		var n := String(Species.info(id)["name"])
		if not names.has(n):
			names.append(n)
	var who := names[0] if names.size() == 1 else ", ".join(names.slice(0, names.size() - 1)) + " and " + names[-1]
	var pack := table_entry(terrain, crossing_no)
	pack.erase("table")
	pack["front"] = _lanes(front)
	pack["back"] = _lanes(back)
	pack["text"] = _text(terrain) % who
	return pack


static func _lanes(ids: Array[String]) -> Array:
	var out := ["", "", ""]
	for i in ids.size():
		out[LANES[i]] = ids[i]
	return out


static func _text(terrain: String) -> String:
	match terrain:
		"Blight": return "Dark dust swirls across the road, and things move inside it: %s."
		"Glow": return "The air shimmers with Light dust. Out of the glare step %s."
	return "Wild Trailomon block the road: %s."


## How many foes a wild pack has for a team of `team_size` on a road of this risk.
static func pack_size(team_size: int, risk: int) -> int:
	return clampi(mini(3 + risk, team_size + risk - 2), 1, 6)


## A copy of a pack with at most `keep` creatures (the front row's middle lane first, then
## its sides, then the back row). The boss of a guardian pack is not counted.
static func trim(pack: Dictionary, keep: int) -> Dictionary:
	var out := pack.duplicate(true)
	for row in ["front", "back"]:
		var lanes: Array = out.get(row, ["", "", ""])
		for i in [1, 0, 2]:
			if i >= lanes.size() or String(lanes[i]) == "":
				continue
			if keep > 0:
				keep -= 1
			else:
				lanes[i] = ""
		out[row] = lanes
	# A pack with a back row but no front row moves its middle creature forward.
	var front: Array = out.get("front", [])
	var back: Array = out.get("back", [])
	if not front.is_empty() and front.all(func(x): return String(x) == "") and not back.is_empty():
		for i in [1, 0, 2]:
			if i < back.size() and String(back[i]) != "":
				front[1] = back[i]
				back[i] = ""
				break
	return out


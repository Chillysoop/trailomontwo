class_name WorldMap
extends RefCounted
## The overworld: a big graph of stops joined by roads, split into named regions of one terrain.
## Generated once per caravan from a seed and kept for the whole campaign (saved with it), so
## the fog of war you lift stays lifted. Each crossing runs from one edge to the other: crossing 1
## east to west, crossing 2 back east, and so on, from a different stop each time.
##
## Pure data (no scenes) so it saves as plain values and can be tested headless.
## junctions: id -> {"name", "pos": Vector2 (world units), "region", "kind", "layer", "lookout"?}
## segments: [{"a", "b", "terrain", "days", "terrain_factor", "risk"}]
## regions: id -> {"name", "terrain", "center": Vector2}

const LAYERS := 14
const LAYER_GAP := 180.0
const HEIGHT := 1000.0
const SIZE := Vector2(LAYER_GAP * (LAYERS - 1) + 160.0, HEIGHT)
const TERRAIN_FACTOR := {"Forest": 1.0, "Hills": 1.2, "River": 1.1, "Swamp": 1.2, "Mountain": 1.45}

## Stop kinds by terrain (weights). "lookout" stops reveal more of the map.
const KIND_WEIGHTS := {
	"Forest": {"village": 4, "waystation": 3, "post": 1, "ruins": 1},
	"Hills": {"waystation": 3, "village": 2, "post": 2, "lookout": 2},
	"River": {"post": 3, "village": 3, "waystation": 2},
	"Swamp": {"stilts": 4, "ruins": 2, "waystation": 1},
	"Mountain": {"lookout": 2, "ruins": 1, "waystation": 3, "post": 1},
}

## Stall templates per stop kind: good -> [price, stock].
const STALLS := {
	"town": {"food": [2, 10], "water": [1, 8], "repair_kit": [12, 3], "medicine": [8, 2], "technique": [24, 1], "BATTLE": [10, 2]},
	"village": {"food": [2, 6], "water": [1, 6], "medicine": [8, 1], "BATTLE": [10, 1]},
	"waystation": {"water": [1, 5], "food": [3, 4], "repair_kit": [14, 1]},
	"post": {"food": [3, 6], "water": [1, 5], "repair_kit": [13, 2], "BATTLE": [10, 2], "technique": [24, 1]},
	"ruins": {"dark_dust": [16, 1], "BATTLE": [9, 2]},
	"stilts": {"water": [1, 6], "food": [3, 4], "medicine": [7, 2], "light_dust": [18, 1]},
	"lookout": {"water": [2, 3], "food": [4, 2]},
}

const NAME_PARTS := {
	"Forest": [["Moss", "Fern", "Oak", "Bramble", "Thorn", "Elder", "Lantern", "Hollow", "Briar", "Acorn"], ["ford", "glen", "wood", "hollow", "rest", "dell", "grove", "stead"]],
	"Hills": [["Ridge", "Barrow", "Cairn", "Heather", "Windy", "Copper", "Rook", "Gorse"], ["fork", "down", "rise", "knoll", "gate", "field", "hill", "cross"]],
	"River": [["Reed", "Weir", "Otter", "Silver", "Rush", "Willow", "Kettle", "Mill"], ["ford", "bridge", "bank", "wharf", "falls", "landing", "mouth", "pool"]],
	"Swamp": [["Bog", "Mire", "Fen", "Murk", "Thorn", "Gloam", "Rot", "Peat"], ["marsh", "mire", "stilts", "hollow", "pool", "reach", "wallow", "end"]],
	"Mountain": [["Cog", "Iron", "Slate", "Frost", "Crag", "Anvil", "Spire", "Flint"], ["spire", "peak", "pass", "watch", "crag", "top", "cleft", "hold"]],
}
const REGION_NAMES := {
	"Forest": ["The Mossdeeps", "Lanternwood", "The Green Tangle", "Elderglade"],
	"Hills": ["The Rolling Downs", "Copper Barrows", "Gorse Heights", "Windmere"],
	"River": ["The Silverrun", "Reedwater Vale", "The Kettle Flats", "Otterbend"],
	"Swamp": ["The Murkfens", "Gloamwallow", "The Rotting Reach", "Peatmoor"],
	"Mountain": ["The Cogspires", "Frostcrag Range", "The Anvil Teeth", "Slate Wall"],
}

var seed := 0
var junctions := {}
var segments: Array = []
var regions := {}
var start := ""
var goal := ""
## Stall stock and rumors per stop, made when generated: id -> {"stall": {...}, "rumor_seed": int}.
var stops := {}
## The hand-made test route (tests and the old first playable) instead of a generated world.
var is_test := false


# ---------- building ----------

## The small hand-made route the tests are written against.
static func test_route() -> WorldMap:
	var m := WorldMap.new()
	m.is_test = true
	for id in TestRoute.JUNCTIONS:
		var j: Dictionary = TestRoute.JUNCTIONS[id]
		m.junctions[id] = {"name": j["name"], "pos": Vector2(j["pos"]) * 5.0, "region": "test", "kind": Settlements.stop(id)["kind"], "layer": 0}
	for s in TestRoute.SEGMENTS:
		m.segments.append(s.duplicate())
	m.regions["test"] = {"name": "The Test Route", "terrain": "Forest", "center": Vector2(900, 500)}
	m.start = TestRoute.START
	m.goal = TestRoute.GOAL
	return m


static func generate(rng_seed: int) -> WorldMap:
	var m := WorldMap.new()
	m.seed = rng_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	m._make_regions(rng)
	var layers: Array = []
	var used_names := {}
	for l in LAYERS:
		var count := rng.randi_range(4, 6) if l > 0 and l < LAYERS - 1 else 4
		var ids: Array = []
		for i in count:
			var y := (i + 0.5) / count * (HEIGHT - 120.0) + 60.0 + rng.randf_range(-40, 40)
			var x := SIZE.x - 80.0 - l * LAYER_GAP + rng.randf_range(-45, 45)
			var id := "j%d_%d" % [l, i]
			var pos := Vector2(x, clampf(y, 40.0, HEIGHT - 40.0))
			var region := m._region_at(pos)
			var terrain: String = m.regions[region]["terrain"]
			m.junctions[id] = {"name": m._name(terrain, rng, used_names), "pos": pos, "region": region,
				"kind": _weighted(KIND_WEIGHTS[terrain], rng), "layer": l}
			ids.append(id)
		layers.append(ids)
	# Roads: every stop links to 1-2 nearest stops in the next layer, and every stop has a way in.
	for l in LAYERS - 1:
		var here: Array = layers[l]
		var next: Array = layers[l + 1]
		var reached := {}
		for id in here:
			var by_dist := next.duplicate()
			var p: Vector2 = m.junctions[id]["pos"]
			by_dist.sort_custom(func(a, b): return p.distance_to(m.junctions[a]["pos"]) < p.distance_to(m.junctions[b]["pos"]))
			var links := 1 if rng.randf() < 0.45 else 2
			for k in links:
				m._link(id, by_dist[k], rng)
				reached[by_dist[k]] = true
		for id in next:
			if not reached.has(id):
				var p: Vector2 = m.junctions[id]["pos"]
				var by_dist := here.duplicate()
				by_dist.sort_custom(func(a, b): return p.distance_to(m.junctions[a]["pos"]) < p.distance_to(m.junctions[b]["pos"]))
				m._link(by_dist[0], id, rng)
		# A few side roads within a layer.
		if rng.randf() < 0.5 and here.size() > 1:
			var i := rng.randi_range(0, here.size() - 2)
			m._link(here[i], here[i + 1], rng)
	# Dead-end side trips: lookouts and ruins just off the main roads.
	for k in 10:
		var l := rng.randi_range(1, LAYERS - 2)
		var from: String = layers[l][rng.randi_range(0, layers[l].size() - 1)]
		var p: Vector2 = m.junctions[from]["pos"] + Vector2(rng.randf_range(-60, 60), rng.randf_range(70, 110) * (1 if rng.randf() < 0.5 else -1))
		p.y = clampf(p.y, 30.0, HEIGHT - 30.0)
		var id := "s%d" % k
		var region := m._region_at(p)
		var terrain: String = m.regions[region]["terrain"]
		m.junctions[id] = {"name": m._name(terrain, rng, used_names), "pos": p, "region": region,
			"kind": "lookout" if rng.randf() < 0.5 else "ruins", "layer": l}
		m._link(from, id, rng)
	# Each edge's middle stops become the big towns at both ends.
	for l in [0, LAYERS - 1]:
		for id in layers[l]:
			m.junctions[id]["kind"] = "town"
	m._make_stops(rng)
	m.start = layers[0][1]
	m.goal = layers[LAYERS - 1][2]
	m.junctions[m.start]["name"] = "Eastgate"
	m.junctions[m.goal]["name"] = "Westwatch"
	return m


func _make_regions(rng: RandomNumberGenerator) -> void:
	var terrains := ["Forest", "Hills", "River", "Swamp", "Mountain"]
	var name_used := {}
	var cols := 7
	for c in cols:
		for r in 2:
			var t: String = terrains[rng.randi_range(0, terrains.size() - 1)]
			# Keep the first stretch out of Eastgate gentle.
			if c == cols - 1:
				t = "Forest" if r == 0 else "Hills"
			var names: Array = REGION_NAMES[t]
			var name: String = names[rng.randi_range(0, names.size() - 1)]
			var n := 2
			while name_used.has(name):
				name = "%s %s" % [names[rng.randi_range(0, names.size() - 1)], ["II", "North", "South", "Far"][n % 4]]
				n += 1
			name_used[name] = true
			var center := Vector2((c + 0.5) / cols * SIZE.x + rng.randf_range(-60, 60), (r + 0.5) / 2.0 * HEIGHT + rng.randf_range(-120, 120))
			regions["r%d_%d" % [c, r]] = {"name": name, "terrain": t, "center": center}


func _region_at(p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for id in regions:
		var d := p.distance_squared_to(regions[id]["center"])
		if d < best_d:
			best_d = d
			best = id
	return best


func _name(terrain: String, rng: RandomNumberGenerator, used: Dictionary) -> String:
	var parts: Array = NAME_PARTS[terrain]
	for i in 30:
		var n: String = String(parts[0][rng.randi_range(0, parts[0].size() - 1)]) + String(parts[1][rng.randi_range(0, parts[1].size() - 1)])
		if not used.has(n):
			used[n] = true
			return n
	return "Stop %d" % used.size()


func _link(a: String, b: String, rng: RandomNumberGenerator) -> void:
	if a == b or has_segment(a, b):
		return
	var pa: Vector2 = junctions[a]["pos"]
	var pb: Vector2 = junctions[b]["pos"]
	var terrain: String = regions[junctions[b]["region"]]["terrain"]
	var mid_layer := float(maxi(int(junctions[a]["layer"]), int(junctions[b]["layer"])))
	var middle := 1.0 - absf(mid_layer / (LAYERS - 1) - 0.5) * 2.0
	var risk := clampi(1 + int(round(middle * 1.6 + rng.randf_range(-0.4, 0.4))) + (1 if terrain == "Mountain" else 0), 1, 3)
	segments.append({"a": a, "b": b, "terrain": terrain, "days": clampi(int(round(pa.distance_to(pb) / 175.0)), 1, 3),
		"terrain_factor": TERRAIN_FACTOR[terrain], "risk": risk})


func _make_stops(rng: RandomNumberGenerator) -> void:
	var battle_items: Array = BattleItems.ITEMS.keys()
	for id in junctions:
		var tpl: Dictionary = STALLS.get(junctions[id]["kind"], {})
		var stall := {}
		for good in tpl:
			var g: String = good
			if g == "BATTLE":
				g = battle_items[rng.randi_range(0, battle_items.size() - 1)]
			stall[g] = {"price": int(tpl[good][0]), "stock": int(tpl[good][1])}
		stops[id] = {"stall": stall, "rumor_seed": rng.randi()}


static func _weighted(table: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in table:
		total += int(table[k])
	var r := rng.randi_range(0, total - 1)
	for k in table:
		r -= int(table[k])
		if r < 0:
			return k
	return table.keys()[0]


# ---------- crossings ----------

## Pick crossing `no`'s start and goal: odd crossings go east to west, even ones west to east,
## each from a different stop on the edge.
func setup_crossing(no: int) -> void:
	if is_test:
		start = TestRoute.START
		goal = TestRoute.GOAL
		return
	var east: Array = []
	var west: Array = []
	for id in junctions:
		if int(junctions[id]["layer"]) == 0 and id.begins_with("j"):
			east.append(id)
		elif int(junctions[id]["layer"]) == LAYERS - 1 and id.begins_with("j"):
			west.append(id)
	east.sort()
	west.sort()
	var k := (no - 1) / 2
	var e: String = east[(1 + k) % east.size()]
	var w: String = west[(2 + k) % west.size()]
	if no % 2 == 1:
		start = e
		goal = w
	else:
		start = w
		goal = e


# ---------- queries ----------

func has(id: String) -> bool:
	return junctions.has(id)


func name_of(id: String) -> String:
	return String(junctions[id]["name"]) if junctions.has(id) else id


func pos(id: String) -> Vector2:
	return junctions[id]["pos"]


func kind_of(id: String) -> String:
	return String(junctions.get(id, {}).get("kind", "waystation"))


func region_of(id: String) -> Dictionary:
	return regions.get(junctions.get(id, {}).get("region", ""), {})


func has_segment(a: String, b: String) -> bool:
	for s in segments:
		if (s["a"] == a and s["b"] == b) or (s["a"] == b and s["b"] == a):
			return true
	return false


## Roads leaving a stop, each with "from" and "to" set.
func exits(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in segments:
		if s["a"] == id or s["b"] == id:
			var seg: Dictionary = s.duplicate()
			seg["from"] = id
			seg["to"] = s["b"] if s["a"] == id else s["a"]
			out.append(seg)
	return out


func neighbours(id: String) -> Array[String]:
	var out: Array[String] = []
	for s in exits(id):
		out.append(String(s["to"]))
	return out


## Stops within `depth` roads of a stop (including it).
func around(id: String, depth: int) -> Array[String]:
	var seen := {id: true}
	var frontier: Array[String] = [id]
	for d in depth:
		var next: Array[String] = []
		for j in frontier:
			for n in neighbours(j):
				if not seen.has(n):
					seen[n] = true
					next.append(n)
		frontier = next
	var out: Array[String] = []
	for k in seen:
		out.append(k)
	return out


## Fewest roads from a to b (-1 if unreachable).
func hops(a: String, b: String) -> int:
	var dist := {a: 0}
	var queue: Array[String] = [a]
	while not queue.is_empty():
		var j: String = queue.pop_front()
		if j == b:
			return int(dist[j])
		for n in neighbours(j):
			if not dist.has(n):
				dist[n] = int(dist[j]) + 1
				queue.append(n)
	return -1


## The stop's kind, stall and rumor seed in the shape Settlements.stop() uses.
func stop(id: String) -> Dictionary:
	if is_test:
		return Settlements.stop(id)
	var s: Dictionary = stops.get(id, {"stall": {}, "rumor_seed": 0})
	return {"kind": kind_of(id), "stall": s["stall"], "rumor": "", "rumor_seed": int(s.get("rumor_seed", 0))}


## Species living in a region's habitat (for the map's region card, shown only once met).
func region_species(region_id: String) -> Array[String]:
	var out: Array[String] = []
	var terrain: String = regions.get(region_id, {}).get("terrain", "")
	var habitat: String = TrailLife.TERRAIN_HABITAT.get(terrain, "")
	for id in Species.DATA:
		var info: Dictionary = Species.DATA[id]
		if String(info.get("rarity", "")) == "guardian" or id == "hollowstag":
			continue
		if habitat == "" or info["type"] == habitat:
			out.append(id)
	return out

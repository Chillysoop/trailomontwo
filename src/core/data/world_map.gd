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
## Rough tracks per map, and how much harder they are to haul over.
const ROUGH_TRACKS := 4
const ROUGH_FACTOR := 1.2
const LAYER_GAP := 180.0
const HEIGHT := 1000.0
const SIZE := Vector2(LAYER_GAP * (LAYERS - 1) + 160.0, HEIGHT)
const TERRAIN_FACTOR := {"Forest": 1.0, "Hills": 1.2, "River": 1.1, "Swamp": 1.2, "Mountain": 1.45, "Snow": 1.35, "Jungle": 1.25, "Blight": 1.3, "Glow": 1.0}

## Dust biomes: from crossing 3 Dark dust (the Blight) and Light dust (the Glow) spread over
## regions of the overworld, more of them on later crossings. Their roads are riskier, their
## stops change, and their Trailomon (Species "biome" key) live nowhere else.
const BLIGHT := "Blight"
const GLOW := "Glow"
const BIOMES := [BLIGHT, GLOW]
## Crossing -> regions of each biome (the highest key not above the crossing wins).
const BIOME_SPREAD := {1: 0, 3: 1, 5: 2, 7: 3}

## Stop kinds by terrain (weights). "lookout" stops reveal more of the map.
const KIND_WEIGHTS := {
	"Forest": {"village": 4, "waystation": 3, "post": 1, "ruins": 1},
	"Hills": {"waystation": 3, "village": 2, "post": 2, "lookout": 2},
	"River": {"post": 3, "village": 3, "waystation": 2},
	"Swamp": {"stilts": 4, "ruins": 2, "waystation": 1},
	"Mountain": {"lookout": 2, "ruins": 1, "waystation": 3, "post": 1},
	"Snow": {"village": 3, "waystation": 2, "lookout": 1, "post": 1},
	"Jungle": {"village": 3, "post": 2, "ruins": 2},
	"Blight": {"warden": 3, "ruins": 3, "lookout": 1},
	"Glow": {"sanctum": 3, "village": 1, "lookout": 1},
}

## Stall templates per stop kind: good -> [price, stock].
const STALLS := {
	"town": {"food": [2, 10], "water": [1, 8], "spare_axle": [14, 1], "spare_harness": [8, 1], "spare_canvas": [9, 1], "medicine": [8, 2], "technique": [24, 1], "BATTLE": [10, 2]},
	"village": {"food": [2, 6], "water": [1, 6], "medicine": [8, 1], "BATTLE": [10, 1]},
	"waystation": {"water": [1, 5], "food": [3, 4], "spare_harness": [9, 1]},
	"post": {"food": [3, 6], "water": [1, 5], "spare_axle": [16, 1], "spare_canvas": [10, 1], "BATTLE": [10, 2], "technique": [24, 1]},
	"ruins": {"dark_dust": [16, 1], "BATTLE": [9, 2]},
	"stilts": {"water": [1, 6], "food": [3, 4], "medicine": [7, 2], "light_dust": [18, 1]},
	"lookout": {"water": [2, 3], "food": [4, 2]},
	"warden": {"light_dust": [10, 2], "medicine": [6, 2], "food": [4, 4], "water": [2, 4], "spare_canvas": [10, 1]},
	"sanctum": {"light_dust": [12, 1], "medicine": [5, 2], "food": [3, 4], "water": [1, 6]},
}

const NAME_PARTS := {
	"Forest": [["Moss", "Fern", "Oak", "Bramble", "Thorn", "Elder", "Lantern", "Hollow", "Briar", "Acorn"], ["ford", "glen", "wood", "hollow", "rest", "dell", "grove", "stead"]],
	"Hills": [["Ridge", "Barrow", "Cairn", "Heather", "Windy", "Copper", "Rook", "Gorse"], ["fork", "down", "rise", "knoll", "gate", "field", "hill", "cross"]],
	"River": [["Reed", "Weir", "Otter", "Silver", "Rush", "Willow", "Kettle", "Mill"], ["ford", "bridge", "bank", "wharf", "falls", "landing", "mouth", "pool"]],
	"Swamp": [["Bog", "Mire", "Fen", "Murk", "Thorn", "Gloam", "Rot", "Peat"], ["marsh", "mire", "stilts", "hollow", "pool", "reach", "wallow", "end"]],
	"Mountain": [["Cog", "Iron", "Slate", "Frost", "Crag", "Anvil", "Spire", "Flint"], ["spire", "peak", "pass", "watch", "crag", "top", "cleft", "hold"]],
	"Snow": [["Rime", "Snow", "Hoar", "Ice", "Drift", "Sleet", "White", "Glacier"], ["holt", "fall", "haven", "lodge", "mere", "field", "stead", "hollow"]],
	"Jungle": [["Vine", "Parrot", "Mango", "Liana", "Orchid", "Canopy", "Ember", "Jade"], ["hold", "falls", "grove", "tangle", "court", "bloom", "reach", "landing"]],
}
const REGION_NAMES := {
	"Forest": ["The Mossdeeps", "Lanternwood", "The Green Tangle", "Elderglade"],
	"Hills": ["The Rolling Downs", "Copper Barrows", "Gorse Heights", "Windmere"],
	"River": ["The Silverrun", "Reedwater Vale", "The Kettle Flats", "Otterbend"],
	"Swamp": ["The Murkfens", "Gloamwallow", "The Rotting Reach", "Peatmoor"],
	"Mountain": ["The Cogspires", "Frostcrag Range", "The Anvil Teeth", "Slate Wall"],
	"Snow": ["The White Reach", "Frostfang Pass", "Rimeholt", "The Hoarwood"],
	"Jungle": ["The Emerald Canopy", "Vinehold", "The Sunken Gardens", "Parrotspire"],
	"Blight": ["The Ashen Hollow", "Duskmire Scar", "The Withering"],
	"Glow": ["Lumen Meadows", "The Shining Steppe", "Halo Glade"],
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
	m._add_rough_tracks(layers, rng)
	m.start = layers[0][1]
	m.goal = layers[LAYERS - 1][2]
	m.junctions[m.start]["name"] = "Eastgate"
	m.junctions[m.goal]["name"] = "Westwatch"
	return m


## Rough tracks: a few steep, risky shortcuts that skip a column of stops. Fewer days than the
## roads around, but risk 3 and harder going. Added last, so the rest of the map is unchanged.
func _add_rough_tracks(layers: Array, rng: RandomNumberGenerator) -> void:
	for k in ROUGH_TRACKS:
		var l := rng.randi_range(1, LAYERS - 4)
		var here: Array = layers[l]
		var from: String = here[rng.randi_range(0, here.size() - 1)]
		var p: Vector2 = junctions[from]["pos"]
		var far: Array = layers[l + 2].duplicate()
		far.sort_custom(func(a, b): return p.distance_to(junctions[a]["pos"]) < p.distance_to(junctions[b]["pos"]))
		var to: String = far[0]
		if has_segment(from, to):
			continue
		var terrain: String = regions[junctions[to]["region"]]["terrain"]
		segments.append({"a": from, "b": to, "terrain": terrain, "days": 3, "rough": true,
			"terrain_factor": float(TERRAIN_FACTOR[terrain]) * ROUGH_FACTOR, "risk": 3})


func _make_regions(rng: RandomNumberGenerator) -> void:
	var terrains := ["Forest", "Hills", "River", "Swamp", "Mountain", "Snow", "Jungle"]
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
	spread_biomes(no)


## How many regions of each dust biome there are on crossing `no`.
static func biome_count(no: int) -> int:
	var n := 0
	for k in BIOME_SPREAD:
		if no >= int(k):
			n = int(BIOME_SPREAD[k])
	return n


func is_biome(terrain: String) -> bool:
	return BIOMES.has(terrain)


## Turn regions into Blight and Glow until crossing `no` has its share. Always the same regions
## for a map (in the same order), never the edge columns with the big towns, and never undone.
func spread_biomes(no: int) -> void:
	if is_test:
		return
	var want := biome_count(no)
	var order := _biome_order()
	var i := 0
	for rid in order:
		if i >= want * 2:
			break
		var biome: String = BIOMES[i % 2]
		if String(regions[rid].get("biome", "")) == "":
			_convert(rid, biome, i / 2)
		i += 1


func _biome_order() -> Array:
	var ids: Array = []
	for rid in regions:
		var col := int(String(rid).split("_")[0].substr(1))
		if col >= 1 and col <= 5:
			ids.append(rid)
	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 4243
	for k in range(ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, k)
		var tmp = ids[k]
		ids[k] = ids[j]
		ids[j] = tmp
	return ids


func _convert(rid: String, biome: String, nth: int) -> void:
	var reg: Dictionary = regions[rid]
	reg["base_terrain"] = reg["terrain"]
	reg["base_name"] = reg["name"]
	reg["terrain"] = biome
	reg["biome"] = biome
	var names: Array = REGION_NAMES[biome]
	reg["name"] = names[nth % names.size()] if nth < names.size() else "%s %s" % [names[nth % names.size()], ["II", "Far", "Deep"][(nth / names.size() - 1) % 3]]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + hash(rid)
	var battle_items: Array = BattleItems.ITEMS.keys()
	for id in junctions:
		if junctions[id]["region"] != rid or junctions[id]["kind"] == "town":
			continue
		junctions[id]["kind"] = _weighted(KIND_WEIGHTS[biome], rng)
		var stall := {}
		var tpl: Dictionary = STALLS.get(junctions[id]["kind"], {})
		for good in tpl:
			var g: String = good
			if g == "BATTLE":
				g = battle_items[rng.randi_range(0, battle_items.size() - 1)]
			stall[g] = {"price": int(tpl[good][0]), "stock": int(tpl[good][1])}
		# Dark dust is cheap where it seeps from the ground.
		if biome == BLIGHT:
			stall["dark_dust"] = {"price": 8, "stock": 3}
		stops[id]["stall"] = stall
	for s in segments:
		var ra := String(junctions[s["a"]]["region"])
		var rb := String(junctions[s["b"]]["region"])
		if (ra == rid or rb == rid) and not is_biome(String(s["terrain"])):
			s["base_terrain"] = s["terrain"]
			s["terrain"] = biome
			s["terrain_factor"] = TERRAIN_FACTOR[biome]
			s["risk"] = mini(3, int(s["risk"]) + 1)


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


## Fewest travel days from a to b (roads' "days"), or -1 if there is no way.
func shortest_days(a: String, b: String) -> int:
	var dist := {a: 0}
	var open: Array[String] = [a]
	while not open.is_empty():
		var best := 0
		for i in open.size():
			if int(dist[open[i]]) < int(dist[open[best]]):
				best = i
		var j: String = open.pop_at(best)
		if j == b:
			return int(dist[j])
		for s in exits(j):
			var d := int(dist[j]) + int(s["days"])
			if not dist.has(s["to"]) or d < int(dist[s["to"]]):
				dist[s["to"]] = d
				if not open.has(s["to"]):
					open.append(s["to"])
	return -1


## A river road has a ferry if either end is a place people live by the water.
func has_ferry(seg: Dictionary) -> bool:
	for j in [seg["a"], seg["b"]]:
		if ["town", "post", "village", "stilts"].has(kind_of(j)):
			return true
	return false


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
## The region's landmark prop (assets/props/lm_*.png), seen far off the road. Regions named
## "<name> South" and the like share their base name's landmark. Without a region (the test
## route), the terrain's first landmark.
func landmark(id: String, terrain := "Forest") -> String:
	var reg := region_of(id)
	var t: String = reg.get("terrain", terrain)
	var names: Array = REGION_NAMES.get(t, REGION_NAMES["Forest"])
	var base: String = names[0]
	var rname := String(reg.get("name", ""))
	for n in names:
		if rname.begins_with(String(n)):
			base = n
	return "lm_" + base.to_lower().replace(" ", "_")


func region_species(region_id: String) -> Array[String]:
	var out: Array[String] = []
	var terrain: String = regions.get(region_id, {}).get("terrain", "")
	var habitat: String = TrailLife.TERRAIN_HABITAT.get(terrain, "")
	for id in Species.DATA:
		var info: Dictionary = Species.DATA[id]
		if String(info.get("rarity", "")) == "guardian" or id == "hollowstag":
			continue
		var biome := String(info.get("biome", ""))
		if is_biome(terrain):
			if biome == terrain:
				out.append(id)
		elif biome == "" and (habitat == "" or info["type"] == habitat):
			out.append(id)
	return out

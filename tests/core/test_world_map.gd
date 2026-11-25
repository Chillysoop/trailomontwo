extends TestCase
## The overworld: a big generated map with forks, fog of war and creatures only once met.


func _world(rng_seed := 11) -> Expedition:
	Expedition.default_map = "world"
	var e := Expedition.new_default(rng_seed)
	Expedition.default_map = "test"
	e.events_enabled = false
	return e


func test_generated_map_is_big_and_connected() -> void:
	for s in [1, 2, 3, 40, 999]:
		var m := WorldMap.generate(s)
		m.setup_crossing(1)
		check(m.junctions.size() >= 60, "seed %d has %d stops" % [s, m.junctions.size()])
		check(m.segments.size() >= 70, "seed %d has %d roads" % [s, m.segments.size()])
		var h := m.hops(m.start, m.goal)
		check(h >= WorldMap.LAYERS - 1, "seed %d goal %d roads away" % [s, h])
		for id in m.junctions:
			check(m.hops(m.start, id) >= 0, "seed %d: %s is reachable" % [s, id])


func test_maps_have_real_forks() -> void:
	var m := WorldMap.generate(7)
	var forks := 0
	for id in m.junctions:
		if m.exits(id).size() >= 3:
			forks += 1
	check(forks >= 15, "plenty of forks (%d)" % forks)


func test_same_seed_same_map() -> void:
	var a := WorldMap.generate(5)
	var b := WorldMap.generate(5)
	check_eq(a.junctions.size(), b.junctions.size())
	for id in a.junctions:
		check_eq(a.name_of(id), b.name_of(id))


func test_crossings_alternate_direction() -> void:
	var m := WorldMap.generate(3)
	m.setup_crossing(1)
	var east := m.start
	check_eq(int(m.junctions[m.start]["layer"]), 0, "crossing 1 starts in the east")
	check_eq(int(m.junctions[m.goal]["layer"]), WorldMap.LAYERS - 1, "and ends in the west")
	m.setup_crossing(2)
	check_eq(int(m.junctions[m.start]["layer"]), WorldMap.LAYERS - 1, "crossing 2 starts in the west")
	m.setup_crossing(3)
	check(m.start != east, "crossing 3 sets out from another eastern town")


func test_fog_starts_close_and_lifts_as_you_travel() -> void:
	var e := _world()
	var m := e.map
	check(e.is_seen(m.start), "start is seen")
	check(e.is_seen(m.goal), "the goal is marked from the start")
	for n in m.neighbours(m.start):
		check(e.is_seen(n), "neighbour %s is seen" % n)
	var unseen := 0
	for id in m.junctions:
		if not e.is_seen(id):
			unseen += 1
	check(unseen > m.junctions.size() * 0.8, "most of the map is under fog (%d unseen)" % unseen)
	var seg: Dictionary = e.exits()[0]
	e.travel(seg)
	for n in m.neighbours(seg["to"]):
		check(e.is_seen(n), "arriving reveals %s" % n)


func test_lookout_sees_further() -> void:
	var e := _world()
	var m := e.map
	var look := ""
	for id in m.junctions:
		if m.kind_of(id) == "lookout":
			look = id
			break
	check(look != "", "map has a lookout")
	e.seen.clear()
	e.reveal(look)
	for id in m.around(look, 3):
		check(e.is_seen(id), "lookout reveals %s" % id)


func test_rumor_lifts_fog_on_a_stop_further_on() -> void:
	var e := _world()
	var before := e.seen.size()
	var line := e.hear_rumor()
	check(line != "", "a rumor at the start")
	check_eq(e.seen.size(), before + 1, "the rumor reveals one more stop")
	check_eq(e.hear_rumor(), line, "the same rumor on asking again")


func test_only_met_trailomon_are_encountered() -> void:
	var e := _world()
	for id in e.roster + e.stored:
		check(e.encountered.has(id), "own team %s counts as met" % id)
	var pack := {"front": ["frostsnip"], "back": ["plateflit"], "boss": ""}
	check(not e.encountered.has("frostsnip"), "unmet before the battle")
	e.pending_encounter = {"pack": pack}
	e.make_battle()
	check(e.encountered.has("frostsnip") and e.encountered.has("plateflit"), "met once fought")
	var rid: String = e.map.junctions[e.at]["region"]
	check(e.met_in.get(rid, {}).has("frostsnip"), "shown in the region it was met in")
	for other in e.met_in:
		if other != rid:
			check(not e.met_in[other].has("frostsnip"), "not shown in other regions")


func test_every_stop_has_a_stall_and_towns_sell_food() -> void:
	var m := WorldMap.generate(9)
	for id in m.junctions:
		var st := m.stop(id)
		check(st.has("stall"), "%s has a stall" % id)
		if m.kind_of(id) in ["town", "village"]:
			check(st["stall"].has("food"), "%s sells food" % id)


func test_world_map_survives_a_save_and_next_crossing() -> void:
	var e := _world()
	e.travel(e.exits()[0])
	var data := SaveGame.caravan(e)
	var next := SaveGame.next_crossing(data, 4, 2)
	check_eq(next.map.seed, e.map.seed, "same overworld next crossing")
	check_eq(int(next.map.junctions[next.at]["layer"]), WorldMap.LAYERS - 1, "crossing 2 starts in the west")
	check(next.is_seen(e.visited[1]), "fog lifted last crossing stays lifted")


func test_every_terrain_and_region_has_scenery() -> void:
	for t in TravelBackdrop.TERRAINS:
		var low := String(t).to_lower()
		for f in ["sky", "mountains", "far", "ground", "foreground"]:
			check(ResourceLoader.exists("res://assets/backgrounds/travel/%s/%s.png" % [low, f]), "%s travel %s" % [t, f])
		for part in ["back", "front"]:
			check(ResourceLoader.exists("res://assets/backgrounds/battle/%s_%s.png" % [low, part]), "%s battle %s" % [t, part])
	for t in WorldMap.REGION_NAMES:
		for n in WorldMap.REGION_NAMES[t]:
			var id := "lm_" + String(n).to_lower().replace(" ", "_")
			check(ResourceLoader.exists("res://assets/props/%s.png" % id), "landmark for %s" % n)


func test_scenery_follows_the_road_and_the_region() -> void:
	var e := _world()
	var here := e.scenery()
	check_eq(here["terrain"], e.map.region_of(e.at)["terrain"], "a stop shows its own region")
	check(String(here["landmark"]).begins_with("lm_"), "and its landmark")
	var seg: Dictionary = e.exits()[0]
	e.start_trip(seg)
	var road := e.scenery()
	check_eq(road["terrain"], seg["terrain"], "the road shows its terrain")
	check_eq(road["landmark"], e.map.landmark(seg["to"]), "and the landmark of the region ahead")


func test_region_names_with_a_suffix_share_the_landmark() -> void:
	var m := WorldMap.generate(2)
	for rid in m.regions:
		m.regions[rid]["name"] = "Lanternwood South"
		m.regions[rid]["terrain"] = "Forest"
	var any: String = m.junctions.keys()[0]
	check_eq(m.landmark(any), "lm_lanternwood")

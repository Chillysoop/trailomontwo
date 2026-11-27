extends TestCase
## Paths matter: the season clock, rough tracks, river crossings with helpers, panning.


func _world(seed_value := 3) -> Expedition:
	var e := Expedition.new_default(seed_value)
	e.map = WorldMap.generate(seed_value)
	e.setup_map(1)
	return e


func test_frost_comes_after_the_quickest_crossing() -> void:
	var e := _world()
	var quickest := e.map.shortest_days(e.map.start, e.map.goal)
	check(quickest > 5, "a world crossing takes a while")
	check(e.frost_day > quickest + 1, "there is slack before frost")
	check_eq(e.season(), "open")
	e.day = e.frost_day - 2
	check_eq(e.season(), "late")
	e.day = e.frost_day
	check_eq(e.season(), "frost")


func test_no_season_on_the_test_route() -> void:
	var e := Expedition.new_default(1)
	check_eq(e.frost_day, 0)
	check_eq(e.season(), "open")


func test_frost_hurts_the_crew_every_day() -> void:
	var e := _world()
	e.day = e.frost_day
	var hp := e.health
	e.spend_day()
	check(e.health <= hp - Expedition.FROST_HEALTH, "frost costs health")


func test_late_season_raises_food_prices() -> void:
	var e := _world()
	e.departed = true
	var j := ""
	for id in e.map.junctions:
		if e.map.stop(id)["stall"].has("food"):
			j = id
			break
	e.at = j
	var price := int(e.stall()["food"]["price"])
	e.day = e.frost_day - 1
	check_eq(int(e.stall()["food"]["price"]), price + 1)


func test_rough_tracks_skip_a_column() -> void:
	var m := WorldMap.generate(9)
	var rough := 0
	for s in m.segments:
		if s.get("rough", false):
			rough += 1
			check_eq(absi(int(m.junctions[s["b"]]["layer"]) - int(m.junctions[s["a"]]["layer"])), 2)
			check_eq(int(s["risk"]), 3)
	check(rough >= 1, "some rough tracks")


func test_river_roads_start_with_a_crossing() -> void:
	var e := _world()
	e.events_enabled = true
	var seg := {"a": e.at, "b": "x", "from": e.at, "to": "x", "terrain": "River", "days": 2, "terrain_factor": 1.0, "risk": 2}
	e.provisions = 200.0
	e.water = 100.0
	check(e.start_trip(seg), "set off")
	e.step_day()
	check_eq(String(e.pending_event.get("id", "")), "river")


func test_deeper_rivers_are_harder() -> void:
	var shallow := Rivers.make(1, false, false, 1)
	var flood := Rivers.make(3, false, false, 1)
	check(int(flood["choices"][0]["difficulty"]) > int(shallow["choices"][0]["difficulty"]), "deeper is harder")
	check(Rivers.depth_for(2, "rain") > Rivers.depth_for(2, "clear"), "rain raises the river")


func test_ferry_and_ice_bridge_only_when_possible() -> void:
	var plain := Rivers.make(2, false, false, 1)
	var labels: Array = plain["choices"].map(func(c): return c["label"])
	check(not labels.has("Take the ferry") and not labels.has("Freeze a bridge"), "no ferry, no ice")
	var both := Rivers.make(2, true, true, 1)
	labels = both["choices"].map(func(c): return c["label"])
	check(labels.has("Take the ferry") and labels.has("Freeze a bridge"), "ferry and ice")
	var safe := 0
	for c in both["choices"]:
		if Expedition.is_safe(c):
			safe += 1
	check_eq(safe, 1)


func test_a_scout_helps_ford_the_river() -> void:
	var e := Expedition.new_default(1)
	var ev := Rivers.make(2, false, false, 1)
	var with_help: Dictionary = e.event_choices(ev)[0]
	var keep := e.roster.duplicate()
	var scout := e.best_helper("scout", [with_help["helper"]])
	check(scout != "", "the default team has a scout")
	check(not with_help["assists"].is_empty(), "the scout assists")
	e.roster.erase(scout)
	var without: Dictionary = e.event_choices(ev)[0]
	check(int(with_help["odds"]["success"]) > int(without["odds"]["success"]), "help raises the odds")
	e.roster = keep


func test_waiting_at_the_river_lowers_it_and_asks_again() -> void:
	var e := _world()
	var seg := {"a": e.at, "b": "x", "from": e.at, "to": "x", "terrain": "River", "days": 2, "terrain_factor": 1.0, "risk": 3}
	e.provisions = 200.0
	e.water = 100.0
	e.start_trip(seg)
	e.weather = "clear"
	e.pending_event = e.make_river(3)
	var wait: int = e.pending_event["choices"].size() - 1
	e.weather = "clear"
	e.resolve_event(wait)
	check_eq(String(e.pending_event.get("id", "")), "river")
	check(int(e.pending_event["depth"]) <= 2, "the water dropped")


func test_panning_costs_days() -> void:
	var ev := TrailEvents.by_id("glinting_stream")
	check(not ev.is_empty(), "the stream exists")
	for c in ev["choices"]:
		if c.has("cap"):
			check(int(c["success"]["days"]) >= 1, "panning takes time")

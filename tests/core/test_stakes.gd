extends TestCase
## Stakes and story: ailments and the trail doctor, landmark cards, the finale choice,
## the arrival score and scrapbook, and graves from your own past runs.


func _world() -> Expedition:
	var e := Expedition.new_default(3)
	e.map = WorldMap.generate(3)
	e.setup_map(1)
	return e


func test_rust_itch_halves_a_haulers_pull() -> void:
	var e := Expedition.new_default(1)
	var id: String = e.haulers[0] if not e.haulers.is_empty() else e.roster[0]
	var before := e.hauler_strength(id)
	e.catch_ailment("rust_itch", id)
	check_near(e.hauler_strength(id), before * 0.5)


func test_spore_sneezes_stop_trail_jobs() -> void:
	var e := Expedition.new_default(1)
	var id: String = e.roster[0]
	e.catch_ailment("spore_sneeze", id)
	for cap in ["strength", "scout", "float", "heal"]:
		check_eq(e.job_rank(id, cap), 0)


func test_ailments_run_their_course() -> void:
	var e := Expedition.new_default(1)
	var id: String = e.roster[0]
	e.catch_ailment("bramble_burrs", id)
	var hp := float(e.creature_hp[id])
	for i in Ailments.DAYS:
		e.spend_day()
	check(float(e.creature_hp[id]) < hp, "burrs hurt every day")
	check_eq(e.ailment_of(id), "")


func test_the_doctor_card_cures() -> void:
	var e := Expedition.new_default(1)
	var id: String = e.roster[0]
	e.light_dust = 2
	var card := e.catch_ailment("moss_lung", id)
	e.pending_event = card
	var dust := -1
	for i in card["choices"].size():
		if String(card["choices"][i]["label"]).contains("Light dust"):
			dust = i
	check(dust >= 0, "Light dust is offered when you have some")
	e.resolve_event(dust)
	check_eq(e.ailment_of(id), "")
	check_eq(e.light_dust, 1)


func test_landmark_card_once_per_region() -> void:
	var e := _world()
	var stop := ""
	for id in e.map.junctions:
		if id != e.map.start and Landmarks.has(e.map.landmark(id)):
			stop = id
			break
	e.at = stop
	e._landmark_card()
	check_eq(String(e.pending_event.get("id", "")), "landmark")
	e.resolve_event(0)
	e._landmark_card()
	check(e.pending_event.is_empty(), "only the first visit")
	check(not e.scrapbook.is_empty(), "it goes in the scrapbook")


func test_every_landmark_prop_has_a_card() -> void:
	for t in WorldMap.REGION_NAMES:
		for n in WorldMap.REGION_NAMES[t]:
			var lm := "lm_" + String(n).to_lower().replace(" ", "_")
			check(Landmarks.has(lm), lm)


func _at_guardian() -> Expedition:
	var e := Expedition.new_default(1)
	e.events_enabled = false
	e.at = "thornmarsh"
	e.start_trip(e.exits().filter(func(s): return s["to"] == e.map.goal)[0])
	while e.step_day():
		if not e.pending_encounter.is_empty():
			break
	return e


func test_toll_road_skips_the_guardian_for_coins_and_days() -> void:
	var e := _at_guardian()
	e.coins = 200
	var day := e.day
	var r := e.resolve_encounter("toll")
	check(not r["fight"], "no fight")
	check_eq(e.coins, 200 - e.finale_toll())
	check_eq(e.day, day + Expedition.FINALE_TOLL_DAYS)
	while e.step_day():
		pass
	check_eq(e.state, Expedition.State.ARRIVED)
	check_eq(e.finale, "toll")


func test_toll_needs_the_coins() -> void:
	var e := _at_guardian()
	e.coins = 0
	check(e.resolve_encounter("toll").is_empty(), "can't pay")
	check(not e.pending_encounter.is_empty(), "still blocked")


func test_wrecked_rapids_means_a_fight() -> void:
	var e := _at_guardian()
	# Nobody who can float: a long shot.
	e.roster = ["brambleback"] as Array[String]
	var r := e.resolve_encounter("rapids", 99)
	check(r["fight"], "the guardian has seen you")
	check(not e.pending_encounter.is_empty(), "still blocked")
	var e2 := _at_guardian()
	check(not e2.resolve_encounter("rapids", 0)["fight"], "a clean run gets past")


func test_arrival_score_rewards_good_shape() -> void:
	var e := Expedition.new_default(1)
	var good := e.arrival_score()
	e.health = 20
	e.provisions = 0.0
	e.wagon.integrity = 10
	var bad := e.arrival_score()
	check(int(good["total"]) > int(bad["total"]), "arriving healthy scores more")
	check(String(good["rank"]) != "", "a rank")


func test_arrival_records_the_score() -> void:
	var e := Expedition.new_default(1)
	e.events_enabled = false
	e.guardian_enabled = false
	e.at = "thornmarsh"
	e.travel(e.exits().filter(func(s): return s["to"] == e.map.goal)[0])
	check_eq(e.state, Expedition.State.ARRIVED)
	check_eq(e.score_history.size(), 1)


func test_graves_come_back_on_later_runs() -> void:
	Graves.path = "user://test_graves.json"
	if FileAccess.file_exists(Graves.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Graves.path))
	Graves.lay(2, 17, "Brambleback", "The Murkfens", "Should have waited for the river.")
	check_eq(Graves.for_crossing(2).size(), 1)
	check_eq(Graves.for_crossing(3).size(), 0)
	var stone := Graves.as_stone(Graves.for_crossing(2)[0])
	check(String(stone[1]).contains("river"), "the epitaph you wrote")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Graves.path))
	Graves.path = Graves.PATH

extends TestCase
## Recruiting wild creatures after a win, and swapping stored ones into the team.


func test_candidates_skip_owned_and_bosses() -> void:
	var e := Expedition.new_default(5)
	var pack := {"front": ["thornfang", "brambleback", ""], "back": ["lianetail"], "boss": "hollowstag"}
	var c := e.recruit_candidates(pack)
	check(c.has("thornfang") and c.has("lianetail"), "wild species can join")
	check(not c.has("brambleback"), "not one you already have")
	check(not c.has("hollowstag"), "never the boss")


func test_recruit_goes_to_storage() -> void:
	var e := Expedition.new_default(5)
	e.pending_recruit = "thornfang"
	check(e.recruit() != "", "joined")
	check(e.stored.has("thornfang"), "in storage")
	check_eq(float(e.creature_hp["thornfang"]), e.max_hp("thornfang"), "healthy")
	check_eq(e.pending_recruit, "")
	check_eq(e.recruit(), "", "only once")


func test_wins_sometimes_offer_a_recruit() -> void:
	var offers := 0
	for seed in 20:
		var e := Expedition.new_default(seed)
		e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 0.6, "guardian": false}
		var b := e.make_battle(false, 1)
		b.run_to_end()
		e.finish_battle(b)
		if e.pending_recruit != "":
			offers += 1
	check(offers > 0, "some wins offer a recruit")


func test_swap_stored_into_the_team() -> void:
	var e := Expedition.new_default(5)
	var cell: Variant = e.lineup_cell("brambleback")
	check(e.swap_stored("gillhorn", "brambleback"), "swapped")
	check(e.roster.has("gillhorn") and not e.roster.has("brambleback"), "roster updated")
	check(e.stored.has("brambleback") and not e.stored.has("gillhorn"), "storage updated")
	check_eq(e.lineup[cell], "gillhorn", "takes the same lineup spot")
	check(not e.haulers.has("brambleback"), "stored ones don't haul")
	check(not e.swap_stored("inkhoot", "nobody"), "bad swap is refused")
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.0, "guardian": false}
	var b := e.make_battle(false, 1)
	var species: Array = []
	for f in b.side_fighters(Formation.Side.PLAYER):
		species.append(f.species)
	check(species.has("gillhorn"), "the swapped-in Trailomon fights")


func test_companions_swap_clicks() -> void:
	var s := CompanionsScreen.new()
	s.crossing = Expedition.new_default(5)
	s._ready()
	s._swap_pick = "inkhoot"
	s.refresh()
	check(s.crossing.stored.has("inkhoot"), "nothing swapped until a card is clicked")
	s.free()


func test_recruits_join_near_the_team_level() -> void:
	var e := Expedition.new_default(5)
	for id in e.roster:
		while e.level(id) < 8:
			e.gain_xp(id, Leveling.xp_to_next(e.level(id)))
	var waiting := e.pending_count()
	e.pending_recruit = "thornfang"
	e.recruit()
	check_eq(e.level("thornfang"), 6, "two below the team")
	check_eq(e.pending_count(), waiting + 5, "its level-up choices wait for you")

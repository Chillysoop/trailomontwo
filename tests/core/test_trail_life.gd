extends TestCase
## Weather, pace, rations, fever, trail moments, settlements and the new event effects.


func _fresh() -> Expedition:
	var e := Expedition.new_default(3)
	e.events_enabled = false
	return e


func _seg(from: String, to: String) -> Dictionary:
	for s in TestRoute.exits(from):
		if s["to"] == to:
			return s
	return {}


func test_weather_tables_only_use_known_weather() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for terrain in TrailLife.WEATHER_TABLE:
		for w in TrailLife.WEATHER_TABLE[terrain]:
			check(TrailLife.WEATHER.has(w), "%s has unknown weather %s" % [terrain, w])
		for i in 20:
			check(TrailLife.WEATHER.has(TrailLife.roll_weather(terrain, rng)), "rolled weather is known")


func test_hard_pace_is_faster_and_carries_progress() -> void:
	var e := _fresh()
	e.set_pace("hard")
	var seg := _seg("eastgate", "mossford")  # 2 days
	check_eq(e.forecast(seg)["days"], 2)
	e.travel(seg)
	check_eq(e.day, 3)
	check_near(e.carry, 0.9)  # 3.0 covered of 2.0, capped at 0.9
	# The carried progress makes the next 2-day road a 1-day trip at hard pace.
	check_eq(e.forecast(_seg("mossford", "lantern_hollow"))["days"], 1)


func test_easy_pace_is_slower_but_restful() -> void:
	var e := _fresh()
	e.set_pace("easy")
	var seg := _seg("eastgate", "mossford")
	check_eq(e.forecast(seg)["days"], 3)
	e.travel(seg)
	check(float(e.fatigue["brambleback"]) < Expedition.HAUL_FATIGUE * 2.0, "haulers barely tire at an easy pace")


func test_rations_change_food_and_health() -> void:
	var e := _fresh()
	var normal := e.daily_provisions()
	e.set_rations("thin")
	check_near(e.daily_provisions(), normal * 0.6)
	e.health = 50
	e.spend_day()
	check_eq(e.health, 47)
	e.set_rations("full")
	e.spend_day()
	check_eq(e.health, 50)


func test_fever_drains_health_until_rest() -> void:
	var e := _fresh()
	e.apply_fx({"fever": 3})
	check_eq(e.fever_days, 3)
	e.spend_day()
	check_eq(e.health, 100 - TrailLife.FEVER_DAMAGE)
	e.rest()
	check_eq(e.fever_days, 0)


func test_weather_costs_apply() -> void:
	var e := _fresh()
	e.weather = "rain"
	var water := e.water
	e.spend_day()
	check_near(e.water, water - e.daily_water() + 3.0)
	e.weather = "heat"
	water = e.water
	e.spend_day()
	check_near(e.water, water - e.daily_water() * 1.4)


func test_home_ground_and_weather_raise_job_rank() -> void:
	var e := _fresh()
	check_eq(e.job_rank("reedwake", "float"), 3)
	e.trip = {"terrain": "River"}
	check_eq(e.job_rank("reedwake", "float"), 4)
	e.weather = "rain"
	check_eq(e.job_rank("reedwake", "float"), 5)
	check_eq(e.job_rank("reedwake", "strength"), 0)


func test_moments_apply_and_reward_the_helper() -> void:
	var e := _fresh()
	e.trip = {"terrain": "River"}
	var food := e.provisions
	var rec := e.trigger_moment(TrailMoments.by_id("fish"))
	check_eq(rec["who"], "reedwake")
	check_near(e.provisions, food + 6.0)
	check(int(e.xp.get("reedwake", 0)) > 0, "the fisher earns job xp")
	check_eq(e.moments.size(), 1)
	var g := e.trigger_moment(TrailMoments.by_id("grave"))
	check(g.has("grave"), "graves have a name and a line")


func test_every_moment_and_event_effect_is_known() -> void:
	var known := ["text", "food", "water", "health", "wear", "integrity", "days", "fatigue", "lose_cargo", "coins",
		"spare_axle", "spare_harness", "spare_canvas", "spare", "break", "salvage", "curio", "give_item", "light_dust", "dark_dust", "item", "technique", "xp", "recruit", "fever", "cure", "progress",
		"heal_team", "battle", "bounty"]
	for m in TrailMoments.MOMENTS:
		for k in m["fx"]:
			check(known.has(k), "%s: unknown effect %s" % [m["id"], k])
	for ev in TrailEvents.EVENTS:
		for c in ev["choices"]:
			for o in ["success", "mixed", "failure"]:
				for k in c.get(o, {}):
					check(known.has(k), "%s: unknown effect %s" % [ev["id"], k])


func test_costs_must_be_affordable() -> void:
	var e := _fresh()
	e.pending_event = TrailEvents.by_id("trader")
	e.coins = 5
	var views := e.event_choices(e.pending_event)
	check(not views[0]["affordable"], "can't buy an item with 5 coins")
	check(e.resolve_event(0).is_empty(), "unaffordable choice does nothing")
	e.coins = 20
	var items := e.items.duplicate()
	var r := e.resolve_event(0)
	check_eq(r["outcome"], "success")
	check_eq(e.coins, 10)
	var total := 0
	for k in e.items:
		total += int(e.items[k])
	var before := 0
	for k in items:
		before += int(items[k])
	check_eq(total, before + 1)


func test_helpers_earn_job_xp() -> void:
	var e := _fresh()
	e.pending_event = TrailEvents.by_id("fallen_tree")
	e.resolve_event(0, 0)
	check_eq(int(e.xp.get("scythelk", 0)), TrailEvents.JOB_XP["success"])


func test_freeing_a_wild_trailomon_lets_it_join() -> void:
	var e := _fresh()
	e.trip = {"terrain": "Mountain"}
	e.pending_event = TrailEvents.by_id("trapped_wild")
	var r := e.resolve_event(0, 0)
	check(r["recruit"] != "", "a freed wild Trailomon offers to join")
	check(not e.roster.has(r["recruit"]) and not e.stored.has(r["recruit"]), "only new species")
	e.recruit()
	check(e.stored.has(r["recruit"]), "it goes to storage")


func test_toll_road_fight_pays_a_bounty() -> void:
	var e := Expedition.new_default(2)
	e.events_enabled = false
	e.start_trip(_seg("eastgate", "ridge_fork"))
	e.pending_event = TrailEvents.by_id("toll_road")
	var r := e.resolve_event(2)
	check(r["fight"], "forcing the gate starts a fight")
	check_eq(int(e.pending_encounter["bounty"]), 15)
	var coins := e.coins
	var b := e.make_battle()
	b.run_to_end()
	var won := b.outcome == Battle.Outcome.VICTORY
	e.finish_battle(b)
	if won:
		check_eq(e.coins, coins + Expedition.VICTORY_COINS + 15)


func test_spar_defeat_does_not_breach_the_wagon() -> void:
	var e := _fresh()
	e.state = Expedition.State.TRAVELLING
	e.trip = _seg("eastgate", "mossford")
	e.apply_fx({"battle": "trainer_spar"})
	check(not e.pending_encounter.is_empty(), "the spar is waiting")
	var integrity := e.wagon.integrity
	e.finish_battle(null)
	check_eq(e.wagon.integrity, integrity)


func test_buying_at_a_stall() -> void:
	var e := _fresh()
	var food := e.provisions
	var coins := e.coins
	var price := int(Settlements.stall("eastgate")["food"]["price"])
	check(e.buy("food").size() > 0, "bought food")
	check_near(e.provisions, food + 10.0)
	check_eq(e.coins, coins - price)
	e.coins = 0
	check(not e.can_buy("food"), "no coins, no food")
	e.coins = 999
	for i in 20:
		e.buy("spare_axle")
	check_eq(e.stock_left("spare_axle"), 0)


func test_every_stop_and_good_is_known() -> void:
	for j in TestRoute.JUNCTIONS:
		check(Settlements.STOPS.has(j), "%s has no stop data" % j)
		for good in Settlements.stall(j):
			check(Settlements.GOODS.has(good) or BattleItems.has(good), "%s sells unknown %s" % [j, good])
		for p in Settlements.kind(j)["props"]:
			check(ResourceLoader.exists("res://assets/props/%s.png" % p), "missing prop art %s" % p)

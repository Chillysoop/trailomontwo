extends TestCase
## People on the trail: Pip Gasket's wagon upgrades, the locals' advice at each stop, and the
## Fernwicks, a family met once every crossing.


func _world() -> Expedition:
	var e := Expedition.new_default(3)
	e.map = WorldMap.generate(3)
	e.setup_map(1)
	return e


func _at_workshop(e: Expedition) -> void:
	e.at = e.workshop()
	e.state = Expedition.State.AT_JUNCTION


func test_workshop_is_a_real_stop_and_never_the_ends() -> void:
	for no in [1, 2, 3, 4]:
		var e := _world()
		e.set_crossing(no)
		var w := e.workshop()
		check(e.map.has(w), "a stop on the map")
		check(w != e.map.start and w != e.map.goal, "not the start or goal")
		check(Inventor.KINDS.has(e.map.kind_of(w)), "a kind Pip sets up in")


func test_upgrades_only_at_the_workshop_and_cost_coins() -> void:
	var e := _world()
	e.coins = 200
	check(not e.can_buy_upgrade("brass_horn") or e.at == e.workshop(), "not elsewhere")
	_at_workshop(e)
	var price := e.upgrade_price("brass_horn")
	check(e.buy_upgrade("brass_horn"), "bought")
	check_eq(e.coins, 200 - price)
	check(e.has_upgrade("brass_horn"), "fitted")
	check(not e.buy_upgrade("brass_horn"), "only once")
	e.coins = 0
	check(not e.can_buy_upgrade("still_none"), "unknown id")
	check(not e.can_buy_upgrade("cargo_rack"), "too poor")


func test_cargo_rack_adds_room() -> void:
	var e := Expedition.new_default(1)
	var before := e.free_space()
	e.upgrades["cargo_rack"] = true
	check_near(e.capacity(), Wagon.CAPACITY + Inventor.RACK_ROOM)
	check_near(e.free_space(), before + Inventor.RACK_ROOM)


func test_spring_wheels_slow_wear() -> void:
	var e := Expedition.new_default(1)
	var seg: Dictionary = e.exits()[0]
	var plain := float(e.forecast(seg)["wear"])
	e.upgrades["spring_wheels"] = true
	check_near(float(e.forecast(seg)["wear"]), plain * Inventor.WEAR_MULT, 0.01)


func test_float_tanks_help_float_checks() -> void:
	var e := Expedition.new_default(1)
	var ev := Rivers.make(3, false, false, 1)
	var before: Array = e.event_choices(ev)
	e.upgrades["float_tanks"] = true
	var after: Array = e.event_choices(ev)
	var found := false
	for i in before.size():
		if before[i]["cap"] == "float":
			found = true
			check(int(after[i]["odds"]["success"]) >= int(before[i]["odds"]["success"]), "better odds")
			check_eq(after[i].get("gear", ""), "float_tanks")
	check(found, "rivers have a float choice")


func test_lantern_mast_sees_further() -> void:
	var a := _world()
	var b := _world()
	b.upgrades["lantern_mast"] = true
	a.seen.clear()
	b.seen.clear()
	a.reveal(a.at)
	b.reveal(b.at)
	check(b.seen.size() > a.seen.size(), "more of the map")


func test_upgrades_carry_to_the_next_crossing() -> void:
	var e := _world()
	e.upgrades["dew_still"] = true
	e.family_stage = 2
	e.family_trust = 3
	var n := SaveGame.next_crossing(SaveGame.caravan(e), 3, 2)
	check(n.has_upgrade("dew_still"), "upgrade kept")
	check_eq(n.family_stage, 2)
	check_eq(n.family_trust, 3)
	check(not n.family_met, "a new crossing, a new meeting")


func test_two_locals_with_stable_advice() -> void:
	var e := _world()
	var a := e.hear_folk()
	check_eq(a.size(), 2)
	check(a[0]["name"] != a[1]["name"], "two different people")
	for f in a:
		check(String(f["line"]) != "", "they say something")
	check_eq(e.hear_folk(), a)


func test_guardian_tip_names_its_real_weakness_when_true() -> void:
	var told := 0
	for s in 40:
		var e := Expedition.new_default(s)
		var r := RandomNumberGenerator.new()
		r.seed = s
		var t := Folk._guardian_tip(e, r)
		if t.is_empty():
			continue
		var boss_type := String(Species.info(String(CombatData.guardian_for(e.crossing_no)["boss"]))["type"])
		if t["true"]:
			told += 1
			check_eq(CombatData.matchup(String(t["type"]), boss_type), CombatData.STRONG)
		else:
			check(CombatData.matchup(String(t["type"]), boss_type) != CombatData.STRONG, "a wrong tip is wrong")
	check(told > 20, "mostly true")


func test_folk_point_out_the_workshop() -> void:
	var e := _world()
	var shop := e.workshop()
	var told := false
	for id in e.map.junctions:
		e.at = id
		for f in e.hear_folk():
			if f["topic"] == "inventor":
				told = true
				check_eq(f["to"], shop)
				check(e.is_seen(shop), "shown on the map")
	check(told, "somebody mentions Pip")


func test_family_story_moves_on_and_trust_counts() -> void:
	var e := Expedition.new_default(1)
	e.state = Expedition.State.TRAVELLING
	e.pending_event = e.meet_family()
	check_eq(e.pending_event["id"], "family")
	check_eq(e.family_stage, 1)
	check(e.family_met, "met this crossing")
	e.resolve_event(0, 0)
	check_eq(e.family_trust, 1)
	e.pending_event = e.meet_family()
	check(String(e.pending_event["title"]) != "A wagon in the mud", "the next beat")


func test_every_family_beat_has_a_safe_way_out() -> void:
	for stage in 6:
		var ev := Family.beat(stage, 3, 2)
		var safe := false
		for c in ev["choices"]:
			if Expedition.is_safe(c):
				safe = true
		check(safe, "beat %d can be passed by" % stage)


func test_old_friends_bring_gifts() -> void:
	var e := Expedition.new_default(1)
	e.family_stage = 4
	e.family_trust = 3
	e.state = Expedition.State.TRAVELLING
	var coins := e.coins
	e.pending_event = e.meet_family()
	e.resolve_event(0)
	check_eq(e.coins, coins + 15)

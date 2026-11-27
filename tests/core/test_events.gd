extends TestCase


func _seg(from: String, to: String) -> Dictionary:
	for s in TestRoute.exits(from):
		if s["to"] == to:
			return s
	return {}


func test_twenty_plus_events_each_with_one_safe_choice() -> void:
	check(TrailEvents.EVENTS.size() >= 20, "lots of trail events")
	var kinds := {}
	for e in TrailEvents.EVENTS:
		kinds[e["kind"]] = true
		var safe := 0
		var rolled := 0
		for c in e["choices"]:
			if c.has("cap"):
				rolled += 1
				for k in ["success", "mixed", "failure"]:
					check(c.has(k), "%s: %s missing %s" % [e["id"], c["label"], k])
			if Expedition.is_safe(c):
				safe += 1
		check_eq(safe, 1, e["id"] + " needs exactly one safe choice")
		check(rolled >= 1 or e["id"] in ["trader", "barter"], e["id"] + " needs a rolled choice")
		check(String(e["text"]).length() <= 80, e["id"] + " text should be one short line")
	check_eq(kinds.size(), 5)


func test_every_segment_can_have_an_event() -> void:
	for seg in TestRoute.SEGMENTS:
		check(TrailEvents.for_segment(seg).size() > 0, "%s-%s has no events" % [seg["a"], seg["b"]])


func test_rockslides_only_on_risky_high_ground() -> void:
	var ids: Array = TrailEvents.for_segment({"terrain": "Hills", "risk": 1}).map(func(e): return e["id"])
	check(not ids.has("rockslide"), "low-risk hills shouldn't have rockslides")
	ids = TrailEvents.for_segment({"terrain": "Mountain", "risk": 3}).map(func(e): return e["id"])
	check(ids.has("rockslide"), "risky mountains should")


func test_the_best_creature_helps_and_improves_the_odds() -> void:
	var e := Expedition.new_default(1)
	var ev := TrailEvents.by_id("fallen_tree")
	var views := e.event_choices(ev)
	check_eq(views[0]["helper"], "scythelk")
	# clear rank 3 -> score 9 vs difficulty 6 -> advantage 3 -> 70%
	check_eq(views[0]["odds"]["success"], 70)
	check(views[2]["safe"], "go around is the safe choice")
	e.roster.erase("scythelk")
	views = e.event_choices(ev)
	check_eq(views[0]["helper"], "")
	check(views[0]["odds"]["success"] < 70, "no helper should mean worse odds")


func test_failure_applies_its_costs() -> void:
	var e := Expedition.new_default(1)
	e.pending_event = TrailEvents.by_id("swollen_ford")
	var cargo := e.cargo.size()
	var wear := e.wagon.wear
	var r := e.resolve_event(0, 99)
	check_eq(r["outcome"], "failure")
	check_eq(e.cargo.size(), cargo - 1)
	check_near(e.wagon.wear, wear + 10.0)
	check(e.pending_event.is_empty(), "event should be cleared")


func test_mixed_and_success_rolls() -> void:
	var e := Expedition.new_default(1)
	e.pending_event = TrailEvents.by_id("bitter_night")
	var odds: Dictionary = e.event_choices(e.pending_event)[0]["odds"]
	check_eq(e.resolve_event(0, odds["success"])["outcome"], "mixed")
	e.pending_event = TrailEvents.by_id("bitter_night")
	check_eq(e.resolve_event(0, 0)["outcome"], "success")


func test_safe_choice_costs_a_day() -> void:
	var e := Expedition.new_default(1)
	e.pending_event = TrailEvents.by_id("fallen_tree")
	var day := e.day
	e.resolve_event(e.safe_choice(e.pending_event))
	check_eq(e.day, day + 1)


func test_travel_pauses_for_an_event_until_resolved() -> void:
	# Seeds vary; find one where an event triggers on the first trip.
	for s in 50:
		var e := Expedition.new_default(s)
		e.start_trip(_seg("eastgate", "mossford"))
		e.step_day()
		if e.pending_event.is_empty():
			continue
		var day := e.day
		check(e.step_day(), "still travelling while the event waits")
		check_eq(e.day, day)
		e.resolve_event(e.safe_choice(e.pending_event))
		while e.step_day():
			pass
		check_eq(e.at, "mossford")
		return
	check(false, "no event in 50 seeds")


func test_main_route_still_completes_with_events() -> void:
	for s in 20:
		var e := Expedition.new_default(s)
		# Events are what's tested here; losing to the guardian sends you back (tested elsewhere).
		e.guardian_enabled = false
		for to in ["mossford", "rail_bridge", "thornmarsh", "westwatch"]:
			# Like a player would: rest at a stop until the team can travel again.
			var tries := 0
			while e.state == Expedition.State.AT_JUNCTION and not e.forecast(_seg(e.at, to))["can_go"] and tries < 4:
				e.rest()
				tries += 1
			e.travel(_seg(e.at, to))
		check_eq(e.state, Expedition.State.ARRIVED, "seed %d: %s" % [s, e.fail_reason])

extends TestCase
## More Trailomon, rarity, and harder crossings with a new guardian each time.


func test_every_species_is_complete() -> void:
	for id in Species.DATA:
		check(CombatData.KITS.has(id), "%s has battle stats" % id)
		check(Species.RARITIES.has(Species.rarity(id)), "%s rarity" % id)
		check(ResourceLoader.exists("res://assets/creatures/%s.png" % id), "%s has art" % id)
		if not Species.is_boss(id):
			check_eq(MovePool.archetypes(id).size(), 2, "%s can specialise" % id)
	for id in CombatData.KITS:
		check(Species.DATA.has(id), "%s is a species" % id)


func test_three_rarities_of_trailomon() -> void:
	var count := {}
	for id in Species.DATA:
		var r := Species.rarity(id)
		count[r] = int(count.get(r, 0)) + 1
	check(int(count.get("common", 0)) >= 10, "plenty of commons")
	check(int(count.get("rare", 0)) >= 8, "a good few rares")
	check(int(count.get("legendary", 0)) >= 3, "some legendaries")
	check_eq(int(count.get("guardian", 0)), CombatData.GUARDIANS.size(), "one boss per guardian")


func test_packs_use_known_species() -> void:
	for p in CombatData.PACKS + CombatData.GUARDIANS:
		for id in p["front"] + p["back"]:
			check(id == "" or CombatData.KITS.has(id), "%s: %s" % [p["id"], id])
		if p.has("boss"):
			check(Species.is_boss(p["boss"]), "%s boss" % p["id"])


func test_legendaries_only_from_crossing_two() -> void:
	var seg := {"terrain": "Forest", "risk": 3}
	var ids := func(packs: Array) -> Array:
		var out := []
		for p in packs:
			out.append(p["id"])
		return out
	check(not ids.call(CombatData.packs_for(seg, 1)).has("emberoak_grove"), "no legendary on crossing 1")
	check(ids.call(CombatData.packs_for(seg, 2)).has("emberoak_grove"), "legendary from crossing 2")
	check(not Species.can_meet("auroryx", 1), "can't meet a legendary on crossing 1")
	check(Species.can_meet("auroryx", 2), "can on crossing 2")
	check(not Species.can_meet("bogmother", 9), "guardians never wander")


func test_rarer_trailomon_turn_up_less() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var got := {}
	for i in 1000:
		var id := Species.pick_weighted(["thornfang", "burlbear", "emberoak"], rng)
		got[id] = int(got.get(id, 0)) + 1
	check(got["thornfang"] > got["burlbear"] and got["burlbear"] > got["emberoak"], "common > rare > legendary: %s" % got)


func test_new_guardian_each_crossing() -> void:
	var seen := {}
	for n in range(1, CombatData.GUARDIANS.size() + 1):
		seen[CombatData.guardian_for(n)["id"]] = true
	check_eq(seen.size(), CombatData.GUARDIANS.size(), "every guardian gets a turn")
	check_eq(CombatData.guardian_for(1)["id"], "hollow_stag", "the Hollow Stag guards the first crossing")
	check_eq(CombatData.guardian_for(CombatData.GUARDIANS.size() + 1)["id"], "hollow_stag", "then they come round again")


func test_later_crossings_are_harder() -> void:
	var a := Expedition.new_default(3)
	a.pending_encounter = {"pack": CombatData.PACKS[0], "scale": 1.2, "guardian": false}
	var b := SaveGame.next_crossing(SaveGame.caravan(a), 3, 3)
	b.pending_encounter = a.pending_encounter.duplicate()
	check_eq(b.crossing_no, 3)
	check(b.enemy_scale() > a.enemy_scale() * 1.1, "crossing 3 foes are tougher: %s vs %s" % [b.enemy_scale(), a.enemy_scale()])
	check_eq(b.guardian_pack()["id"], CombatData.guardian_for(3)["id"])


func test_new_kits_fight() -> void:
	var team := {Vector2i(0, 0): "burlbear", Vector2i(0, 1): "quarrytusk", Vector2i(0, 2): "mossmole",
		Vector2i(1, 0): "pebblotter", Vector2i(1, 1): "flurrypup", Vector2i(1, 2): "canopard"}
	for g in CombatData.GUARDIANS:
		var b := Battle.create({"slots": team}, {"front": g["front"], "back": g["back"], "boss": g["boss"], "scale": 1.0}, {"seed": 2})
		b.run_to_end()
		check(b.outcome != Battle.Outcome.ONGOING, "%s fight ends" % g["id"])
	for id in ["vinegecko", "lanternray", "sporetoad", "bogjaw", "slatebeak", "rimewing", "emberoak", "tidewyrm", "auroryx"]:
		var b := Battle.create({"slots": {Vector2i(0, 1): id}}, {"front": ["thornfang", "", ""], "back": ["", "", ""], "scale": 1.0}, {"seed": 1})
		b.run_to_end()
		check(b.events.size() > 3, "%s fights" % id)

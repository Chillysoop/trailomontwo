extends TestCase
## Save files, hardcore protection, and carrying the team into the next crossing.

const TEST_DIR := "user://test_saves/"


func _fresh_dir() -> void:
	SaveGame.dir = TEST_DIR
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	for f in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + f)


func _played() -> Expedition:
	var e := Expedition.new_default(11)
	e.day = 7
	e.provisions = 33.5
	e.levels["coilhusk"] = 4
	e.xp["coilhusk"] = 12
	e.light_dust = 3
	e.dust_used["coilhusk"] = [{"stat": "atk", "amount": 2.0}]
	e.items["ember_draught"] = 2
	e.item_slots[0] = "ember_draught"
	e.wagon.integrity = 61
	e.place_in_lineup("reedwake", Vector2i(0, 0))
	e.rng.randi()
	return e


func test_round_trip_keeps_everything() -> void:
	_fresh_dir()
	var e := _played()
	check(SaveGame.write("slot1", e, 3, SaveGame.caravan(e)), "saved")
	var r := SaveGame.read("slot1")
	check(not r.has("error"), "loads: %s" % r.get("error", ""))
	var l: Expedition = r["expedition"]
	check_eq(r["crossing_no"], 3)
	check_eq(l.day, 7)
	check_near(l.provisions, 33.5)
	check_eq(l.level("coilhusk"), 4)
	check_eq(l.light_dust, 3)
	check_eq(l.item_slots[0], "ember_draught")
	check_near(l.wagon.integrity, 61.0)
	check_eq(l.lineup_cell("reedwake"), Vector2i(0, 0), "lineup cells survive")
	check_eq(l.roster, e.roster)
	check_eq(l.cargo.size(), e.cargo.size())
	check_eq(l.rng.randi(), e.rng.randi(), "random rolls continue the same way")
	check_eq(l.battle_rng.randi(), e.battle_rng.randi())


func test_next_crossing_carries_team_not_supplies() -> void:
	var e := _played()
	e.creature_hp["coilhusk"] = 1.0
	e.fatigue["brambleback"] = 80.0
	var n := SaveGame.next_crossing(SaveGame.caravan(e), 2)
	check_eq(n.level("coilhusk"), 4, "levels carry")
	check_eq(n.light_dust, 3, "dust carries")
	check_eq(int(n.items["ember_draught"]), 2, "items carry")
	check_eq(n.day, 1, "a new crossing")
	check_near(n.provisions, Expedition.new().provisions, 0.01, "fresh supplies")
	check_near(float(n.creature_hp["coilhusk"]), n.max_hp("coilhusk"), 0.01, "healed")
	check_near(float(n.fatigue["brambleback"]), 0.0, 0.01, "rested")
	check_eq(n.lineup_cell("reedwake"), Vector2i(0, 0), "lineup carries")


func test_next_crossing_sets_out_with_a_purse() -> void:
	var keep := Expedition.default_map
	Expedition.default_map = "world"
	var e := _played()
	e.coins = 3
	var n := SaveGame.next_crossing(SaveGame.caravan(e), 2)
	check_eq(n.coins, Expedition.WORLD_START_COINS, "a broke caravan still gets the starting purse")
	e.coins = 200
	n = SaveGame.next_crossing(SaveGame.caravan(e), 2)
	check_eq(n.coins, 200, "savings carry over")
	Expedition.default_map = keep


func test_slots_are_separate_and_deletable() -> void:
	_fresh_dir()
	var a := _played()
	var b := Expedition.new_default(3)
	SaveGame.write("slot1", a, 1, {})
	SaveGame.write("slot2", b, 1, {})
	check_eq(SaveGame.summary("slot1")["day"], 7)
	check_eq(SaveGame.summary("slot2")["day"], 1)
	SaveGame.delete("slot1")
	check(not SaveGame.exists("slot1"), "deleted")
	check(SaveGame.exists("slot2"), "other slot untouched")
	check(SaveGame.read("slot1").has("error"), "nothing to load")


func test_hardcore_refuses_old_copies_and_edits() -> void:
	_fresh_dir()
	var e := _played()
	SaveGame.write("hardcore", e, 1, {})
	var old := FileAccess.get_file_as_string(SaveGame.path("hardcore"))
	e.day = 9
	SaveGame.write("hardcore", e, 1, {})
	check(not SaveGame.read("hardcore").has("error"), "latest save loads")
	var f := FileAccess.open(SaveGame.path("hardcore"), FileAccess.WRITE)
	f.store_string(old)
	f.close()
	check(SaveGame.read("hardcore").has("error"), "an older copy is refused")
	SaveGame.write("hardcore", e, 1, {})
	var text := FileAccess.get_file_as_string(SaveGame.path("hardcore")).replace("\"day\": 9", "\"day\": 2")
	f = FileAccess.open(SaveGame.path("hardcore"), FileAccess.WRITE)
	check(text.contains("\"day\": 2"), "edit applied")
	f.store_string(text)
	f.close()
	check(SaveGame.read("hardcore").has("error"), "an edited save is refused")
	_fresh_dir()


func test_retrying_a_failed_crossing_keeps_the_teams_experience() -> void:
	var e := Expedition.new_default(3)
	var start := SaveGame.caravan(e)
	var id: String = e.roster[0]
	e.gain_xp(id, 500)
	var lv := e.level(id)
	e.provisions = 0.0
	e.items["rally_horn"] = 5
	var again := SaveGame.next_crossing(SaveGame.retry_caravan(start, e), -1, 1)
	check_eq(again.level(id), lv, "levels kept")
	check(again.level(id) > 1, "it did level")
	check_eq(again.item_count("rally_horn"), Expedition.new_default(3).item_count("rally_horn"), "items as the crossing began")

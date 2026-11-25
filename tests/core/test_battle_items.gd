extends TestCase
## Battle items: 3 slots, team-wide boosts for one fight, used up afterwards.


func _crossing() -> Expedition:
	var e := Expedition.new_default(21)
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.0, "guardian": false}
	return e


func test_every_item_has_text_and_an_icon() -> void:
	for id in BattleItems.ITEMS:
		check(BattleItems.desc(id) != "", "%s has a description" % id)
		check(ResourceLoader.exists("res://assets/icons/%s.png" % id), "%s has an icon" % id)
		check(Glossary.has(id), "%s is in the glossary" % id)


func test_slots_respect_counts() -> void:
	var e := _crossing()
	check(e.set_item_slot(0, "ironbark_salve"), "first salve")
	check(e.set_item_slot(1, "ironbark_salve"), "second salve (2 owned)")
	check(not e.set_item_slot(2, "ironbark_salve"), "no third salve")
	check(not e.set_item_slot(2, "bitter_ash"), "can't slot an item you don't own")
	check(not e.set_item_slot(3, "smoke_pouch"), "only 3 slots")
	check(e.set_item_slot(1, ""), "clear a slot")
	check_eq(e.slotted_items(), ["ironbark_salve"] as Array[String])


func test_items_change_the_battle() -> void:
	var e := _crossing()
	var plain := e.make_battle(false, 5)
	e.set_item_slot(0, "ironbark_salve")
	e.set_item_slot(1, "rally_horn")
	e.set_item_slot(2, "smoke_pouch")
	var b := e.make_battle(false, 5)
	check_eq(b.items_used.size(), 3)
	for f in b.side_fighters(Formation.Side.PLAYER):
		check(f.shield >= f.max_hp * 0.15 - 0.01, "%s starts shielded" % f.species)
		check(f.ult >= CombatData.ULT_MAX * 0.5, "%s starts half charged" % f.species)
	for f in b.side_fighters(Formation.Side.ENEMY):
		check(f.has_mod("slow"), "%s is slowed" % f.species)
	for f in plain.side_fighters(Formation.Side.PLAYER):
		check_eq(f.ult, 0.0, "no items, no charge")


func test_stat_items_and_regen() -> void:
	var e := _crossing()
	e.items = {"ember_draught": 1, "stoneskin_tea": 1, "mending_moss": 1}
	var plain := e.make_battle(false, 5)
	for i in 3:
		e.set_item_slot(i, ["ember_draught", "stoneskin_tea", "mending_moss"][i])
	var b := e.make_battle(false, 5)
	var f: Fighter = b.side_fighters(Formation.Side.PLAYER)[0]
	var p: Fighter = plain.side_fighters(Formation.Side.PLAYER)[0]
	check(f.atk > p.atk, "more attack")
	check(f.def > p.def, "more defense")
	f.hp = f.max_hp * 0.5
	var before := f.hp
	for i in int(5.1 / Battle.TICK):
		b._tick_items()
	check(f.hp > before, "mending moss heals over time")


func test_items_are_used_up_after_a_real_battle() -> void:
	var e := _crossing()
	e.set_item_slot(0, "ironbark_salve")
	e.set_item_slot(1, "swiftwind_feather")
	var b := e.make_battle(false, 3)
	b.run_to_end()
	var lines := e.finish_battle(b)
	check_eq(e.item_count("ironbark_salve"), 1, "one salve left")
	check_eq(e.item_count("swiftwind_feather"), 0, "feather used up")
	check_eq(e.item_slots[0], "ironbark_salve", "slot keeps an item while there are more")
	check_eq(e.item_slots[1], "", "empty slot once it runs out")
	check("\n".join(lines).contains("Used up"), "aftermath says what was used")


func test_wins_can_drop_items() -> void:
	var total := 0
	for seed in 12:
		var e := Expedition.new_default(seed)
		e.items = {}
		e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 0.6, "guardian": false}
		var b := e.make_battle(false, 1)
		b.run_to_end()
		if b.outcome == Battle.Outcome.VICTORY:
			e.finish_battle(b)
			for id in e.items:
				total += e.item_count(id)
	check(total > 0, "some wins found items")

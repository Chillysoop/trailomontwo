extends TestCase
## The Companions screen: team cards, memory slots, storage grid and dust placeholders.


func _screen() -> CompanionsScreen:
	var s := CompanionsScreen.new()
	s.crossing = Expedition.new_default(3)
	s._ready()
	return s


func test_shows_six_cards_with_three_moves_and_memory_slots() -> void:
	var s := _screen()
	check_eq(s._card_nodes.size(), 6, "one card per lineup spot")
	var text := ""
	for card in s._card_nodes:
		for l in card.find_children("*", "RichTextLabel", true, false):
			text += (l as RichTextLabel).text + "\n"
	for id in s.crossing.lineup.values():
		check(text.contains(Species.info(id)["name"]), "card for %s" % id)
		for mid in CombatData.kit_moves(id):
			check(text.contains(CombatData.move(mid)["name"]), "move %s" % mid)
	s.free()


func test_storage_grid_lists_stored_trailomon() -> void:
	var s := _screen()
	check(s.crossing.stored.size() > 0, "the default crossing keeps some Trailomon in storage")
	check(s._stored.get_child_count() >= s.crossing.stored.size(), "a tile per stored Trailomon")
	for id in s.crossing.stored:
		check(not s.crossing.roster.has(id), "%s is stored, not travelling" % id)
	s.free()


func test_memory_slots_start_empty() -> void:
	var e := Expedition.new_default(3)
	for id in e.roster:
		for slot in ["basic", "passive", "ultimate"]:
			check_eq(e.memory_move(id, slot), "")


func test_dust_and_memory_have_icons_and_tips() -> void:
	for id in ["light_dust", "dark_dust", "memory"]:
		check(Glossary.has(id), id)
		check(ResourceLoader.exists(Rich.icon_path(Glossary.icon(id))), "icon for " + id)


func test_every_card_and_stored_tile_shows_a_level() -> void:
	var s := _screen()
	var levels := 0
	for n in s.find_children("*", "Label", true, false):
		if (n as Label).text.begins_with("Lv "):
			levels += 1
	check_eq(levels, s.crossing.lineup.size() + s.crossing.stored.size(), "a level badge per Trailomon")
	check_eq(s.crossing.level("coilhusk"), 1, "everyone starts at level 1")
	s.free()


func test_every_move_has_a_one_line_summary_with_numbers() -> void:
	for mid in CombatData.MOVES:
		var t := CombatData.describe_short(mid, 30.0, 20.0, 600.0)
		check(t != "", "%s has a short summary" % mid)
		check(not t.contains("{"), "%s summary resolved: %s" % [mid, t])
		check(t.length() <= 52, "%s summary fits one line: %s" % [mid, t])
	check_eq(CombatData.describe_short("frost_kick", 25.0, 12.0, 560.0), "Hits for 20, slows 20% for 2s")

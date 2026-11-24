extends TestCase
## The Companions screen: team cards, memory slots, storage grid and dust placeholders.


func _screen() -> CompanionsScreen:
	var s := CompanionsScreen.new()
	s.crossing = Expedition.new_default(3)
	s._ready()
	return s


func test_shows_six_cards_with_three_moves_and_memory_slots() -> void:
	var s := _screen()
	check_eq(s._cards.get_child_count(), 6, "one card per lineup spot")
	var text := ""
	for card in s._cards.get_children():
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

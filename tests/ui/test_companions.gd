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


func test_level_up_screen_shows_sheet_and_current_move() -> void:
	var e := Expedition.new_default(3)
	e.gain_xp("coilhusk", 80)
	while e.pending_levels[0]["options"][0]["kind"] != "move":
		e.choose_level_up(0)
	var s := LevelUpScreen.new()
	s.crossing = e
	s._ready()
	var text := ""
	for l in s.find_children("*", "RichTextLabel", true, false):
		text += (l as RichTextLabel).text + "\n"
	check(text.contains("Equipped: "), "options say what is equipped")
	check(text.contains("Memory: empty"), "options say what is in memory")
	check(text.contains("Trunk Slam"), "the character sheet lists the other moves")
	s._pick(0)
	var picked := ""
	for l in s.find_children("*", "RichTextLabel", true, false):
		if not l.is_queued_for_deletion():
			picked += (l as RichTextLabel).text + "\n"
	check(s._targets.has("equipped") and s._targets.has("memory"), "picking shows equipped and memory tiles")
	check(picked.contains("EQUIPPED") and picked.contains("MEMORY"), "tiles are labelled")
	check(picked.contains("click to replace"), "after picking, the tiles ask to be clicked")
	(s._targets["memory"] as Button).pressed.emit()
	check_eq(e.memory_move("coilhusk", "passive") != "", true, "clicking memory puts the move there")
	s._sheets.free()
	s._sheets = null
	s.free()

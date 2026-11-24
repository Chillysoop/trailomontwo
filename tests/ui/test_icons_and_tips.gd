extends TestCase
## Icons, glossary, markup and creature tooltips.


func test_every_glossary_icon_exists() -> void:
	for id in Glossary.ENTRIES:
		var icon := Glossary.icon(id)
		if icon != "":
			check(ResourceLoader.exists(Rich.icon_path(icon)), "missing icon %s for %s" % [icon, id])


func test_every_habitat_and_terrain_has_an_entry() -> void:
	for t in CombatData.CHART:
		check(Glossary.has(Glossary.habitat_id(t)), "no glossary entry for habitat %s" % t)
	for seg in TestRoute.SEGMENTS:
		check(Glossary.has(Glossary.habitat_id(seg["terrain"])), "no glossary entry for terrain %s" % seg["terrain"])


func test_every_role_has_an_entry() -> void:
	for id in CombatData.KITS:
		var role: String = CombatData.stats(id)["role"]
		check(Glossary.ROLES.has(role) and Glossary.has(Glossary.ROLES[role]), "no entry for role %s" % role)


func test_icon_markup_becomes_hoverable_image() -> void:
	var out := Rich.bb("{i:food} left")
	check(out.begins_with("[url=g:food][img=12x12]res://assets/icons/food.png[/img][/url]"), out)
	check(out.ends_with(" left"), out)


func test_keyword_markup_is_underlined_link() -> void:
	var out := Rich.bb("now {k:poison|poisoned}!")
	check(out.contains("[url=g:poison]"), out)
	check(out.contains("[u]poisoned[/u]"), out)
	check(out.ends_with("!"), out)


func test_creature_markup_links_to_card() -> void:
	var out := Rich.bb("{c:reedwake}")
	check(out.contains("[url=c:reedwake]"), out)
	check(out.contains("Reedwake"), out)


func test_every_glossary_text_resolves() -> void:
	for id in Glossary.ENTRIES:
		var bb := Rich.bb(Glossary.text(id))
		check(bb != "", "empty text for %s" % id)
		check(not bb.contains("{k:") and not bb.contains("{i:"), "unresolved markup in %s: %s" % [id, bb])
		for m in RegEx.create_from_string("url=g:([a-z0-9_]+)").search_all(bb):
			check(Glossary.has(m.get_string(1)), "%s links to unknown entry %s" % [id, m.get_string(1)])


func test_tip_content_for_metas() -> void:
	check(Tips.content("g:def").contains("Defense"), "glossary tip")
	check(Tips.content("c:mirelamp").contains("Mirelamp"), "creature tip")
	check_eq(Tips.content("g:nonsense"), "")
	check_eq(Tips.content("c:nonsense"), "")


func test_every_creature_card_builds() -> void:
	for id in CombatData.KITS:
		var bb := Rich.bb(CreatureCard.markup(id))
		check(bb.contains(Species.info(id)["name"]), "card for %s" % id)
		check(not bb.contains("{"), "unresolved markup in %s card" % id)
		for m in RegEx.create_from_string("url=g:([a-z0-9_]+)").search_all(bb):
			check(Glossary.has(m.get_string(1)), "%s card links to unknown entry %s" % [id, m.get_string(1)])


func test_card_shows_live_statuses() -> void:
	var f := Fighter.new()
	f.species = "coilhusk"
	f.max_hp = 400.0
	f.hp = 150.0
	f.shield = 30.0
	f.poison_secs = 2.5
	f.add_mod("slow", 0.3, 4.0)
	var t := CreatureCard.markup("coilhusk", {"hp": f.hp, "max_hp": f.max_hp, "fighter": f})
	check(t.contains("150/400"), t)
	check(t.contains("{i:shield}30"), t)
	check(t.contains("{i:poison}3s"), t)
	check(t.contains("{i:slow}4s"), t)


func test_card_shows_stat_block_and_moves() -> void:
	var t := CreatureCard.markup("brambleback")
	for stat in ["hp", "atk", "def", "spd", "dps"]:
		check(t.contains("{i:%s}" % stat), "stat icon %s: %s" % [stat, t])
	check(t.contains("Thorny Hide") and t.contains("Briar Wall") and t.contains("Bramble Swipe"), t)
	for slot in ["basic", "passive", "ultimate"]:
		check(t.contains("{i:%s}" % slot), "slot tag %s" % slot)
	var parts := t.split(Tips.SIDE)
	check(parts.size() > 1, "keywords open as side popups")
	check(not parts[0].contains("[b]Shield[/b]"), "keyword text is not in the main card")
	check(t.contains(Tips.SIDE + "{i:shield} [b]Shield[/b]"), "Shield side popup: " + t)


func test_stat_icons_are_distinct() -> void:
	var seen := {}
	for stat in ["hp", "atk", "def", "spd", "dps", "basic", "passive", "ultimate"]:
		var icon := Glossary.icon(stat)
		check(icon != "" and ResourceLoader.exists(Rich.icon_path(icon)), "icon for %s" % stat)
		check(not seen.has(icon), "%s shares an icon with %s" % [stat, seen.get(icon, "")])
		seen[icon] = stat

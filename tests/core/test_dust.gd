extends TestCase
## Dust: permanent boosts. Light = modest; Dark = big, paid for by the opposite stat.


func test_light_dust_boosts_a_stat() -> void:
	var e := Expedition.new_default(8)
	var before := e.stat("scythelk", "atk")
	check(e.use_dust("scythelk", "light", "atk") != "", "used")
	check_eq(e.stat("scythelk", "atk"), before + float(Dust.offer("light", "atk", "scythelk")["amount"]))
	check_eq(e.light_dust, 1, "one spent")


func test_dark_dust_trades_the_opposite_stat() -> void:
	var e := Expedition.new_default(8)
	var atk := e.stat("scythelk", "atk")
	var def := e.stat("scythelk", "def")
	e.use_dust("scythelk", "dark", "atk")
	check_eq(e.stat("scythelk", "atk"), atk + float(Dust.offer("dark", "atk", "scythelk")["amount"]))
	check_eq(e.stat("scythelk", "def"), def - float(Dust.offer("dark", "atk", "scythelk")["cost"]))
	check_eq(e.dark_dust, 0)
	check_eq(e.use_dust("scythelk", "dark", "atk"), "", "no dark dust left")


func test_dust_cap_and_hp() -> void:
	var e := Expedition.new_default(8)
	e.light_dust = 10
	var hp := e.max_hp("rimehare")
	for i in Dust.CAP:
		check(e.use_dust("rimehare", "light", "hp") != "", "dust %d" % i)
	check_eq(e.use_dust("rimehare", "light", "hp"), "", "capped")
	check_eq(e.max_hp("rimehare"), hp + Dust.CAP * float(Dust.offer("light", "hp", "rimehare")["amount"]))
	check_eq(float(e.creature_hp["rimehare"]), e.max_hp("rimehare"), "current health grows too")


func test_dust_applies_in_battle_and_wins_gather_it() -> void:
	var e := Expedition.new_default(8)
	e.use_dust("scythelk", "dark", "atk")
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 0.6, "guardian": false}
	var b := e.make_battle(false, 1)
	for f in b.side_fighters(Formation.Side.PLAYER):
		if f.species == "scythelk":
			check_eq(f.atk, e.stat("scythelk", "atk"))
	b.run_to_end()
	var light := e.light_dust
	if b.outcome == Battle.Outcome.VICTORY:
		e.finish_battle(b)
		check(e.light_dust > light, "a win gathers light dust")


func test_dust_screen_builds() -> void:
	var e := Expedition.new_default(8)
	var s := DustScreen.new()
	s.crossing = e
	s.kind = "dark"
	s._ready()
	var text := ""
	for l in s.find_children("*", "RichTextLabel", true, false):
		text += (l as RichTextLabel).text + "\n"
	check(text.contains("Attack"), "stat options shown")
	s._sheets.free()
	s._sheets = null
	s.free()


func test_dust_is_a_share_of_the_species_stats() -> void:
	var tank := Dust.offer("light", "hp", "brambleback")
	var glass := Dust.offer("light", "hp", "inkhoot")
	check(float(tank["amount"]) > float(glass["amount"]), "bigger creatures gain more raw HP")
	var dark := Dust.offer("dark", "atk", "scythelk")
	check(float(dark["amount"]) > float(Dust.offer("light", "atk", "scythelk")["amount"]), "dark gives more")
	check(float(dark["cost"]) > 0.0 and dark["cost_stat"] == "def", "dark costs the opposite stat")


func test_foes_grow_a_little_with_team_level() -> void:
	var e := Expedition.new_default(8)
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.2, "guardian": false}
	check_eq(e.enemy_scale(), 1.2, "level 1 team: route scale only")
	for id in e.roster:
		e.levels[id] = 5
	check(e.enemy_scale() > 1.2 and e.enemy_scale() < 1.4, "a level 5 team meets slightly tougher foes")

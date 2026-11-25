extends TestCase
## Techniques: one-use moves for a Trailomon of the same habitat as the move's species.


func test_owner_and_habitat_rules() -> void:
	var e := Expedition.new_default(4)
	check_eq(MovePool.owner_of("drain_lance"), "reedwake")
	check(e.can_learn_technique("reedwake", "drain_lance"), "own species can learn it")
	check(e.can_learn_technique("inkhoot", "drain_lance"), "another River Trailomon can learn it")
	check(not e.can_learn_technique("brambleback", "drain_lance"), "a Forest Trailomon can't")
	check(e.can_learn_technique("coilhusk", "bark_bash"), "Forest technique for a Forest Trailomon")


func test_using_a_technique_teaches_and_is_used_up() -> void:
	var e := Expedition.new_default(4)
	check_eq(e.technique_count("bark_bash"), 1, "the crossing starts with one")
	var line := e.use_technique("coilhusk", "bark_bash", false)
	check(line != "", "taught")
	check_eq(e.kit_move("coilhusk", "basic"), "bark_bash", "equipped")
	check_eq(e.memory_move("coilhusk", "basic"), "trunk_slam", "the old move went to empty memory")
	check_eq(e.technique_count("bark_bash"), 0, "used up")
	check_eq(e.use_technique("brambleback", "bark_bash", false), "", "none left")


func test_technique_into_memory() -> void:
	var e := Expedition.new_default(4)
	e.use_technique("reedwake", "drain_lance", true)
	check_eq(e.memory_move("reedwake", "basic"), "drain_lance")
	check(not e.can_learn_technique("reedwake", "drain_lance"), "can't learn a move it already has")


func test_learned_technique_works_in_battle() -> void:
	var e := Expedition.new_default(4)
	e.use_technique("coilhusk", "bark_bash", false)
	e.pending_encounter = {"pack": CombatData.pack_by_id("thornfang_pack"), "scale": 1.0, "guardian": false}
	var b := e.make_battle(false, 2)
	for f in b.side_fighters(Formation.Side.PLAYER):
		if f.species == "coilhusk":
			check_eq(f.basic, "bark_bash")
	b.run_to_end()
	check(b.outcome != Battle.Outcome.ONGOING, "the fight ends")


func test_technique_screen_flow() -> void:
	var e := Expedition.new_default(4)
	var s := TechniqueScreen.new()
	s.crossing = e
	s._ready()
	s._move = "bark_bash"
	s._learner = "brambleback"
	s.refresh()
	var text := ""
	for l in s.find_children("*", "RichTextLabel", true, false):
		if not l.is_queued_for_deletion():
			text += (l as RichTextLabel).text + "\n"
	check(text.contains("EQUIPPED") and text.contains("MEMORY"), "replace tiles shown")
	s._sheets.free()
	s._sheets = null
	s.free()

extends TestCase
## Gear matters: spare parts, the wagon's weight limit, the outfitter, roadside barter, cargo pay.


## A caravan in the start town of a generated world crossing, wagon empty, ready to outfit.
func _outfitting() -> Expedition:
	var e := Expedition.new_default(3)
	e.map = WorldMap.generate(3)
	e.setup_map(1)
	e.empty_supplies()
	e.coins = Expedition.WORLD_START_COINS + Outfitter.PURSE
	return e


func test_the_right_spare_fixes_a_part_in_a_day() -> void:
	var e := Expedition.new_default(1)
	e.spares = {"canvas": 1}
	e.wagon.break_part(Wagon.Part.CANOPY)
	check_eq(e.repair_plan()["kind"], "spare")
	e.repair()
	check_eq(e.day, 2)
	check_eq(e.spare_count("canvas"), 0)
	check_eq(e.wagon.broken, Wagon.Part.NONE)


func test_the_wrong_spare_does_not_help() -> void:
	var e := Expedition.new_default(1)
	e.spares = {"canvas": 2}
	e.wagon.break_part(Wagon.Part.RUNNING_GEAR)
	check_eq(e.repair_plan()["kind"], "jury")
	e.repair()
	check_eq(e.spare_count("canvas"), 2)


func test_a_strong_trailomon_jury_rigs_an_axle_in_one_day() -> void:
	var e := Expedition.new_default(1)
	e.spares = {}
	e.wagon.break_part(Wagon.Part.RUNNING_GEAR)
	var plan := e.repair_plan()
	var strong := e.best_helper("strength")
	check(strong != "" and e.job_rank(strong, "strength") >= Wagon.JURY_RANK, "the default team has a strong hauler")
	check(plan["skilled"], "a strength 3+ helper rigs it fast")
	check_eq(int(plan["days"]), 1)
	var before := e.wagon.integrity
	e.repair()
	check_eq(e.wagon.integrity, before - 5)


func test_tune_up_needs_no_parts() -> void:
	var e := Expedition.new_default(1)
	e.spares = {}
	e.wagon.wear = 50.0
	check_eq(e.repair_plan()["kind"], "tune")
	e.repair()
	check_near(e.wagon.wear, 25.0)


func test_lucky_cog_stops_one_breakdown() -> void:
	var e := Expedition.new_default(1)
	e.curios["lucky_cog"] = true
	e.apply_fx({"break": "axle"})
	check_eq(e.wagon.broken, Wagon.Part.NONE)
	check(not e.has_curio("lucky_cog"), "the cog is used up")
	e.apply_fx({"break": "axle"})
	check_eq(e.wagon.broken, Wagon.Part.RUNNING_GEAR)


func test_everything_aboard_counts_toward_the_load() -> void:
	var e := Expedition.new_default(1)
	var before := e.load_weight()
	e.provisions += 20.0
	check_near(e.load_weight(), before + 2.0 * Outfitter.weight_of("food"))
	e.spares["axle"] = e.spare_count("axle") + 1
	check_near(e.load_weight(), before + 2.0 * Outfitter.weight_of("food") + float(Wagon.SPARES["axle"]["weight"]))


func test_a_full_wagon_leaves_food_behind() -> void:
	var e := Expedition.new_default(1)
	e.provisions += e.free_space() / Outfitter.weight_of("food") * 10.0 - 30.0
	var food := e.provisions
	var d := e.apply_fx({"food": 50})
	check_near(e.provisions, food + 30.0)
	var left := false
	for x in d:
		if String(x.get("label", "")).contains("left behind"):
			left = true
	check(left, "the result says what was left behind")


func test_salvage_only_comes_aboard_if_it_fits() -> void:
	var e := Expedition.new_default(1)
	var crates := e.cargo.size()
	e.provisions += e.free_space() / Outfitter.weight_of("food") * 10.0 - 20.0
	e.apply_fx({"salvage": {"name": "Brass fittings", "weight": 30.0, "value": 60}})
	check_eq(e.cargo.size(), crates)
	e.drop_cargo(0)
	e.apply_fx({"salvage": {"name": "Brass fittings", "weight": 30.0, "value": 60}})
	check_eq(e.cargo.size(), crates)


func test_outfitter_only_in_the_start_town_before_leaving() -> void:
	var e := _outfitting()
	check(e.outfitting(), "the start town is the outfitter")
	check(e.stall().has("spare_axle") and e.stall().has("lucky_cog"), "it sells parts and curiosities")
	e.departed = true
	check(not e.outfitting(), "not after setting out")


func test_outfitter_refuses_what_does_not_fit_and_takes_things_back() -> void:
	var e := _outfitting()
	e.coins = 9999
	var guard := 0
	while e.can_buy("water") and guard < 100:
		e.buy("water")
		guard += 1
	check(e.free_space() < Outfitter.weight_of("water"), "bought until the wagon was full")
	check_eq(e.buy_block("water") if e.stock_left("water") > 0 else "room", "room")
	var coins := e.coins
	var water := e.water
	check(not e.sell_back("water").is_empty(), "handed one back")
	check_near(e.water, water - 10.0)
	check_eq(e.coins, coins + int(Outfitter.STOCK["water"][0]))


func test_pack_for_me_fills_a_sensible_kit_for_both_keepers() -> void:
	for no in [1, 2]:
		var e := _outfitting()
		e.crossing_no = no
		check(e.pack_for_me() > 5, "keeper %d packs a kit" % no)
		check(e.provisions >= 60.0, "enough food to start")
		check(e.water >= 40.0, "enough water to start")
		check(e.load_weight() <= Wagon.CAPACITY + 0.01, "within the weight limit")
		check(e.coins > 0, "some coins left for the road")


func test_curiosities_are_one_of_each() -> void:
	var e := _outfitting()
	check(not e.buy("reed_pipe").is_empty(), "bought the pipe")
	check_eq(e.buy_block("reed_pipe"), "have")


func test_barter_wants_what_you_have_and_offers_what_you_lack() -> void:
	var e := Expedition.new_default(5)
	e.spares = {"axle": 1}
	e.items = {}
	e.light_dust = 0
	e.provisions = 10.0
	e.water = 10.0
	var ev := e.make_barter()
	check(not ev.is_empty(), "a deal is offered")
	var trade: Dictionary = ev["choices"][0]
	check_eq(trade["cost"], {"spare_axle": -1})
	check(not trade["success"].has("spare_axle"), "never the same thing back")
	check(e.can_afford(trade["cost"]), "you can pay")


func test_no_barter_when_you_have_nothing_to_trade() -> void:
	var e := Expedition.new_default(5)
	e.spares = {}
	e.items = {}
	e.light_dust = 0
	e.provisions = 10.0
	e.water = 10.0
	check(e.make_barter().is_empty(), "nothing to offer, no deal")


func test_delivered_cargo_pays_coins() -> void:
	var e := Expedition.new_default(1)
	e.events_enabled = false
	e.guardian_enabled = false
	var value := e.cargo_value()
	var coins := e.coins
	e.at = "thornmarsh"
	for seg in e.exits():
		if seg["to"] == e.map.goal:
			e.travel(seg)
	check_eq(e.state, Expedition.State.ARRIVED)
	check_eq(e.cargo_paid, value / Expedition.CARGO_PAY_DIV)
	check(e.coins >= coins + e.cargo_paid - 1, "the pay goes in the purse")

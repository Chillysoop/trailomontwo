class_name Expedition
extends RefCounted
## One crossing in progress: where the wagon is, what day it is, supplies, roster, wagon and cargo.
## Pure rules, no scenes, so it can be tested headless.

enum State { AT_JUNCTION, TRAVELLING, ARRIVED, FAILED }

## Each traveller eats one ration and drinks one water a day; each active creature drinks half a water.
const HUMAN_PROVISIONS := 1.0
const HUMAN_WATER := 1.0
const CREATURE_WATER := 0.5
## A day without enough food or water costs the traveller this much health.
const STARVING_DAMAGE := 20
const THIRST_DAMAGE := 30
## Pushing an overloaded wagon takes this much longer.
const PUSH_SLOWDOWN := 1.5
## Hauler fatigue (0-100) gained per travel day, doubled when pushing. Full fatigue halves strength.
const HAUL_FATIGUE := 8.0
const REST_RECOVERY := 35.0

var day := 1
## Which crossing this is (1 = the first). Later crossings have new maps, tougher foes and
## a different guardian.
var crossing_no := 1
var at := TestRoute.START
## "world" makes a generated overworld; "test" uses the small hand-made TestRoute (tests set this).
static var default_map := "world"
## The overworld (kept across crossings), the fog of war lifted so far, and species met so far.
var map: WorldMap
## Stops you can see on the map: junction id -> true.
var seen := {}
## Species met in battle or on the road: id -> true. Only these show on the map.
var encountered := {}
## Where on the map each species was met: region id -> {species: true}.
var met_in := {}
## Rumors heard: junction id -> markup.
var rumors := {}
var state := State.AT_JUNCTION
var fail_reason := ""
var humans := 1
var health := 100
var provisions := 80.0
var water := 40.0
var roster: Array[String] = []
var haulers: Array[String] = []
var wagon := Wagon.new()
## Spare parts aboard: "axle", "harness", "canvas" -> count (Wagon.SPARES).
var spares := {"axle": 1, "harness": 1, "canvas": 0}
## Outfitter curiosities aboard (Outfitter.CURIOS): id -> true.
var curios := {}
## Delivered cargo pays its value divided by this, in coins, at the end of a crossing.
const CARGO_PAY_DIV := 10
## What the cargo paid on arrival this crossing.
var cargo_paid := 0
## Set once the wagon leaves the start town; until then the start town's stall is the outfitter.
var departed := false
## The stop where the team last hunted: the game there is spooked for the rest of the crossing.
var hunted_at := ""
## Delivery jobs: the offer at the current stop (rebuilt at each new stop), and the stops
## whose job board you've already taken a job from.
var job_offer := {}
var jobs_taken := {}
var fatigue := {}
var cargo: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var visited: Array[String] = []
var journal: Array[String] = []
## Current health of each roster creature (0 = knocked out). Carries between battles.
var creature_hp := {}
## Tamed Trailomon kept in storage, not travelling: no upkeep, can't fight or haul.
var stored: Array[String] = []
## Level of each tamed Trailomon (team and storage), starting at 1. See Leveling.
var levels := {}
## Experience toward the next level.
var xp := {}
## Moves in use when they differ from the species' starting kit: species -> {slot: move id}.
var kits := {}
## Stat boosts from level-ups: species -> {"hp", "atk", "def", "spd"}.
var boosts := {}
## Learnable moves each creature has picked up (MovePool ids).
var known := {}
## Level-ups waiting for the player to choose: [{"id", "level", "options": [...]}], oldest first.
var pending_levels: Array[Dictionary] = []
var level_rng := RandomNumberGenerator.new()
## Memory slots, one per move slot: species -> {"basic": move id, "passive": ..., "ultimate": ...}.
## A stored move can be swapped in between battles. Empty ("") until level-ups teach moves.
var memory := {}
## Battle lineup: Vector2i(row, lane) -> species. Row 0 is the front, 1 the second row.
var lineup := {}
## Separate dice for battles, so adding battles doesn't change which trail events roll.
var battle_rng := RandomNumberGenerator.new()
## Battle items owned (id -> count) and the 3 item slots used in the next battle ("" = empty).
var items := {}
var item_slots: Array[String] = ["", "", ""]
## Techniques owned: move id -> count. Each teaches its move once, to a Trailomon of the same
## habitat as the move's species.
var techniques := {}
## Dust: permanent boosts (see Dust). How much dust each Trailomon has taken so far.
var light_dust := 0
var dark_dust := 0
var dust_used := {}
## A wild creature that offered to join after the last win ("" if none).
var pending_recruit := ""
## Trail life (see TrailLife and docs/trail-life.md): coins, today's weather, pace, rations, fever.
var coins := 30
## Starting coins on a full overworld crossing (the hand-made test route keeps 30).
const WORLD_START_COINS := 70
var weather := "clear"
var pace := "steady"
var rations := "normal"
## Days of trail fever left (crew loses health each day).
var fever_days := 0
## Ailments on single Trailomon: id -> {"kind", "days"} (see Ailments).
var ailments := {}
## Regions whose landmark card you've seen this crossing.
var landmarks_seen := {}
## The crossing's scrapbook: [{"day", "icon", "text"}], shown at the end.
var scrapbook: Array = []
## How the guardian road went: "" (not yet), "fight" (beaten), "toll", "rapids".
var finale := ""
var deliveries_on_time := 0
## Arrival scores of earlier crossings (carried between crossings).
var score_history: Array = []
## Pip Gasket's permanent wagon upgrades: id -> true (see Inventor). Kept between crossings.
var upgrades := {}
## The Fernwicks (see Family): which beat of their story comes next, how much they trust you,
## and whether you've met them on this crossing.
var family_stage := 0
var family_trust := 0
var family_met := false
## What the locals said at each stop (see Folk), so they say the same thing if you come back.
var folk_heard := {}
## Camp life (see Camp): the crew's morale (0-100, fresh each crossing), the pantry of foraged
## ingredients, plants you've learned to tell apart, and where you last cooked/foraged/camped.
var morale := Camp.START
var pantry := {}
var known_plants := {}
var cooked_at := ""
var foraged_at := ""
var camped_at := ""
## Dice for weather and trail moments, so they don't change which events and battles roll.
var life_rng := RandomNumberGenerator.new()
## Every trail moment so far: {"id", "icon", "text", "who", "fx", "deltas", "sight"}. The screen shows new ones.
var moments: Array = []
## Trip progress carried past the last stop by a fast pace (in days, under 1).
var carry := 0.0
## Shop purchases at each stop: junction -> {good: count bought}.
var bought := {}
## Lures carried: each one raises the odds of the next catch, and is used up by it.
var lures := 0
## True for a caravan that set out with one starter (see small_team_factor).
var fresh_start := false
## Names the player gave their Trailomon: species id -> name.
var nicknames := {}
## Crossing seals: the id of every guardian this caravan has beaten, in order.
var seals: Array[String] = []
## Stops where the healer has already patched the team up this crossing.
var healed_at: Array[String] = []
## Every species this caravan has ever had (caught, joined, started with or evolved into).
var caught := {}
## Glinting Trailomon the caravan owns (species id -> true), and the lead who walks beside the wagon.
var glints := {}
var lead := ""
## Each Trailomon's temperament (Temperaments): species id -> kind.
var tempers := {}
## Each Trailomon's personality quirk (Personalities): species id -> kind.
var quirks := {}
## Eggs riding in the wagon: [{"species", "days"}]. Each day on the road or at rest brings one
## closer; a hatchling joins without a catch roll.
var eggs: Array = []
const EGG_DAYS := 5
const EGG_GLINT := 1.0 / 16.0
## Rook, the rival caravan: met once a crossing; wins and losses across the whole journey.
var rival_met := false
var rival_record := {"wins": 0, "losses": 0}
## The starter this caravan set out with (Rook picks against it).
var starter := ""
## Flares: light one to scare off a wild pack and drive on (never works on a guardian).
var flares := 0
## This crossing's obstacles (Obstacles.place): blocked roads by road key, and legendary lairs.
var obstacles := {}
var lairs := {}
## Roads and lairs a rumor has already pointed at.
var rumored := {}
## Extra odds on the pending catch (a lair's legendary, the deep wilds).
var catch_bonus := 0.0
## The pending catch is a glinting one.
var pending_glint := false


static func new_default(rng_seed := -1) -> Expedition:
	var e := Expedition.new()
	if rng_seed >= 0:
		e.rng.seed = rng_seed
		e.battle_rng.seed = rng_seed + 7919
		e.level_rng.seed = rng_seed + 104729
		e.life_rng.seed = rng_seed + 31337
	else:
		e.rng.randomize()
		e.battle_rng.randomize()
		e.level_rng.randomize()
		e.life_rng.randomize()
	e.roster = ["brambleback", "coilhusk", "reedwake", "mirelamp", "rimehare", "scythelk"]
	e.stored = ["gillhorn", "inkhoot"]
	e.items = {"ironbark_salve": 2, "swiftwind_feather": 1, "smoke_pouch": 1, "rally_horn": 1}
	e.techniques = {"bark_bash": 1, "drain_lance": 1}
	e.light_dust = 2
	e.dark_dust = 1
	e.haulers = ["brambleback", "coilhusk"]
	e.cargo = [
		{"name": "Medicine crates", "weight": 40.0, "value": 120},
		{"name": "Tool chests", "weight": 60.0, "value": 150},
		{"name": "Seed stock", "weight": 40.0, "value": 90},
	]
	for id in e.roster + e.stored:
		e.fatigue[id] = 0.0
		e.creature_hp[id] = e.max_hp(id)
	e.tidy_lineup()
	if default_map == "test":
		e.map = WorldMap.test_route()
	else:
		e.map = WorldMap.generate(rng_seed if rng_seed >= 0 else randi())
		# The overworld is long: set out with a purse, and an empty wagon to fill at the outfitter.
		e.coins = WORLD_START_COINS + Outfitter.PURSE
		e.empty_supplies()
	for id in e.roster + e.stored:
		e.encountered[id] = true
	e.setup_map(1)
	return e


## The three Trailomon a new caravan can pick from. Each is the first stage of a three-stage
## line: a sturdy guard, a quick striker and a bruiser who can help pull. The rest of the team
## has to be caught on the road.
const STARTERS := ["mossmole", "crayhopper", "cragkid"]
## What a brand-new caravan carries besides its starter.
const START_ITEMS := {"ironbark_salve": 1, "mending_moss": 1}
const START_LURES := 2
const START_CARGO := [
	{"name": "Medicine crates", "weight": 40.0, "value": 120},
	{"name": "Seed stock", "weight": 40.0, "value": 90},
]


## A brand-new caravan: one starter Trailomon, a light wagon, a couple of lures. Everyone else
## joins by being caught after wild fights (or befriended in trail events).
static func new_game(starter: String, rng_seed := -1) -> Expedition:
	var e := new_default(rng_seed)
	if not STARTERS.has(starter):
		starter = STARTERS[0]
	e.roster = [starter]
	e.stored = []
	e.haulers = []
	e.lineup.clear()
	e.items = START_ITEMS.duplicate()
	e.techniques = {}
	e.light_dust = 0
	e.dark_dust = 0
	e.lures = START_LURES
	e.tempers = {starter: Temperaments.roll(e.life_rng)}
	e.starter = starter
	e.quirks = {starter: Personalities.roll(e.life_rng)}
	e.fresh_start = true
	e.cargo.assign(START_CARGO.duplicate(true))
	e.fatigue = {starter: 0.0}
	e.creature_hp = {starter: e.max_hp(starter)}
	e.encountered = {starter: true}
	e.tidy_lineup()
	return e


## A world crossing starts with nothing aboard but the cargo: everything else comes from the outfitter.
func empty_supplies() -> void:
	provisions = 0.0
	water = 0.0
	spares = {}
	curios = {}
	departed = false


## Which crossing this is: sets the guardian and how tough the foes are (the map hooks in here too).
func set_crossing(no: int) -> void:
	crossing_no = maxi(1, no)
	setup_map(crossing_no)


## The guardian waiting on the last stretch of this crossing.
## A small team meets the guardian with fewer of its brood: at most one escort per team member.
func guardian_pack() -> Dictionary:
	var g: Dictionary = CombatData.guardian_for(crossing_no)
	return g if roster.size() >= TEAM_MAX else Encounters.trim(g, roster.size())


## Foes get tougher every crossing.
const CROSSING_SCALE := 0.04


func crossing_factor() -> float:
	return 1.0 + CROSSING_SCALE * float(crossing_no - 1)


## Start crossing `no` on the map: its start and goal, back at the start, fog lifted around it.
func setup_map(no: int) -> void:
	if map == null:
		map = WorldMap.test_route() if default_map == "test" else WorldMap.generate(randi())
	map.setup_crossing(no)
	var placed := Obstacles.place(map, no)
	obstacles = placed["roads"]
	lairs = placed["lairs"]
	at = map.start
	visited = [at]
	state = State.AT_JUNCTION
	trip = {}
	seen[map.goal] = true
	reveal(at)
	# The season: frost closes in a while after the quickest possible crossing would arrive.
	frost_day = 0 if map.is_test else day + ceili(map.shortest_days(map.start, map.goal) * FROST_SLACK) + FROST_EXTRA


# ---------- the season ----------

## Frost closes the roads on frost_day (0 = no season, as on the test route). LATE_DAYS before it
## the weather turns and stalls charge more; after it every day is cold and the crew suffers.
var frost_day := 0
const FROST_SLACK := 1.6
const FROST_EXTRA := 12
const LATE_DAYS := 6
const FROST_HEALTH := 2
const FROST_FATIGUE := 5.0


## "open", "late" or "frost".
func season() -> String:
	if frost_day <= 0:
		return "open"
	if day >= frost_day:
		return "frost"
	if day >= frost_day - LATE_DAYS:
		return "late"
	return "open"


func frost_left() -> int:
	return frost_day - day if frost_day > 0 else 999


## Today's weather on a terrain, turned colder as the season closes.
func _season_weather(terrain: String) -> String:
	var w := TrailLife.roll_weather(terrain, life_rng)
	if TrailLife.WEATHER_TABLE.has(terrain) and (terrain == "Blight" or terrain == "Glow"):
		return w
	match season():
		"frost":
			return "cold" if life_rng.randf() < 0.7 else "storm"
		"late":
			if life_rng.randf() < 0.35:
				return "cold"
	return w


## Lift the fog around a stop: its neighbours, two roads out with a sharp scout (job rank 4+),
## three from a lookout.
func reveal(id: String) -> void:
	var depth := 1
	var scout := best_helper("scout")
	if scout != "" and job_rank(scout, "scout") >= 4:
		depth = 2
	if has_curio("brass_spyglass"):
		depth += 1
	if has_upgrade("lantern_mast"):
		depth += 1
	if map.kind_of(id) == "lookout":
		depth = 3
	for j in map.around(id, depth):
		seen[j] = true


func is_seen(id: String) -> bool:
	return seen.has(id) or visited.has(id)


## What the scenery shows now: {"terrain", "landmark"}. On the road, the road's terrain and the
## landmark of the region ahead; at a stop, the stop's own region (or the last road's terrain).
func scenery() -> Dictionary:
	var terrain := "Forest"
	var where: String = at
	if not trip.is_empty():
		terrain = String(trip.get("terrain", terrain))
		if state == State.TRAVELLING:
			where = String(trip["to"])
	var reg := map.region_of(where) if map != null else {}
	if state != State.TRAVELLING and reg.has("terrain"):
		terrain = String(reg["terrain"])
	return {"terrain": terrain, "landmark": map.landmark(where, terrain) if map != null else ""}


func stop() -> Dictionary:
	return map.stop(at)


## The rumor at this stop: points at a stop further on and lifts the fog over it.
func hear_rumor() -> String:
	if rumors.has(at):
		return rumors[at]
	var base: Dictionary = stop()
	if String(base.get("rumor", "")) != "":
		rumors[at] = base["rumor"]
		return rumors[at]
	var r := RandomNumberGenerator.new()
	r.seed = int(base.get("rumor_seed", 0))
	var tip := _obstacle_rumor(r)
	if tip != "":
		rumors[at] = tip
		return tip
	var far: Array[String] = []
	for j in map.around(at, 4):
		if not is_seen(j):
			far.append(j)
	far.sort()
	if far.is_empty():
		rumors[at] = ""
		return ""
	var target: String = far[r.randi_range(0, far.size() - 1)]
	seen[target] = true
	var reg := map.region_of(target)
	var kind := map.kind_of(target)
	var lines := {
		"town": "{i:settlement} A big town, %s, lies in %s.",
		"village": "{i:settlement} Friendly folk at %s, in %s.",
		"post": "{i:trade} Traders gather at %s, in %s.",
		"waystation": "{i:camp} A waystation at %s, in %s.",
		"ruins": "{i:ev_find} Old ruins at %s, in %s. Bring {k:cap_light|light}.",
		"stilts": "{i:settlement} Stilt houses at %s, deep in %s.",
		"lookout": "{i:job_scout} From the lookout at %s you can see half of %s.",
	}
	rumors[at] = String(lines.get(kind, "{i:progress} The road reaches %s, in %s.")) % [map.name_of(target), reg.get("name", "the wilds")]
	return rumors[at]


func daily_provisions() -> float:
	var total := HUMAN_PROVISIONS * humans
	for id in roster:
		total += Species.upkeep(id)
	return total * float(TrailLife.ration(rations)["food"])


func daily_water() -> float:
	var w := HUMAN_WATER * humans + CREATURE_WATER * roster.size()
	return w * (Wagon.CANOPY_WATER_PENALTY if wagon.broken == Wagon.Part.CANOPY else 1.0)


func cargo_value() -> int:
	var v := 0
	for c in cargo:
		v += int(c.get("value", 0))
	return v


func can_haul(id: String) -> bool:
	return int(Species.info(id)["hauling"]) > 0


## A hauler's pulling strength after fatigue (full fatigue halves it).
func hauler_strength(id: String) -> float:
	var s := float(Species.info(id)["hauling"]) * (1.0 - float(fatigue.get(id, 0.0)) / 200.0)
	return s * (0.5 if ailment_of(id) == "rust_itch" else 1.0)


func cargo_weight() -> float:
	var w := 0.0
	for c in cargo:
		w += float(c["weight"])
	return w


## Food, water, spare parts and curiosities (Outfitter.WEIGHTS; food and water per lot of 10).
func supplies_weight() -> float:
	var w := provisions / 10.0 * Outfitter.weight_of("food") + water / 10.0 * Outfitter.weight_of("water")
	for k in spares:
		w += float(spares[k]) * float(Wagon.SPARES[k]["weight"])
	for k in curios:
		w += Outfitter.weight_of(k)
	return w


## Everything aboard: cargo plus supplies. The wagon holds Wagon.CAPACITY.
func load_weight() -> float:
	return cargo_weight() + supplies_weight()


## How much the wagon holds (Pip's cargo rack adds room).
func capacity() -> float:
	return Wagon.CAPACITY + (Inventor.RACK_ROOM if has_upgrade("cargo_rack") else 0.0)


func free_space() -> float:
	return maxf(0.0, capacity() - load_weight())


## What the haulers have to pull: the empty wagon plus part of the load.
func pull_demand(terrain_factor: float) -> float:
	return Hauling.demand(Wagon.EMPTY_MASS, load_weight() * Wagon.LOAD_PULL, terrain_factor)


func spare_count(id: String) -> int:
	return int(spares.get(id, 0))


func has_curio(id: String) -> bool:
	return curios.has(id)


# ---------- Pip Gasket's workshop ----------

func has_upgrade(id: String) -> bool:
	return upgrades.has(id)


## Wear multiplier from upgrades (spring wheels).
func wear_mult() -> float:
	return Inventor.WEAR_MULT if has_upgrade("spring_wheels") else 1.0


## The stop where Pip has set up shop this crossing.
func workshop() -> String:
	return Inventor.workshop(map, crossing_no)


func at_workshop() -> bool:
	return state == State.AT_JUNCTION and at == workshop() and at != ""


func upgrade_price(id: String) -> int:
	return Inventor.price(id, crossing_no)


func can_buy_upgrade(id: String) -> bool:
	return at_workshop() and Inventor.is_upgrade(id) and not has_upgrade(id) and coins >= upgrade_price(id)


func buy_upgrade(id: String) -> bool:
	if not can_buy_upgrade(id):
		return false
	coins -= upgrade_price(id)
	upgrades[id] = true
	journal.append("%s bolts a %s onto the wagon." % [Inventor.NAME, String(Inventor.info(id)["name"]).to_lower()])
	note(Inventor.info(id)["icon"], "Fitted the %s." % String(Inventor.info(id)["name"]).to_lower())
	if id == "lantern_mast":
		reveal(at)
	return true


# ---------- folk at the stops ----------

## The two locals at this stop and their advice (see Folk). Anything they point at shows on the map.
func hear_folk() -> Array:
	if state != State.AT_JUNCTION or map == null:
		return []
	var key := "%d:%s" % [crossing_no, at]
	if not folk_heard.has(key):
		folk_heard[key] = Folk.at_stop(self)
		for f in folk_heard[key]:
			if f.has("to"):
				seen[String(f["to"])] = true
	return folk_heard[key]


# ---------- camp life ----------

## Raise or lower the crew's morale. reason goes in the journal for bigger swings.
## The team's quirks react to a moment: their morale shifts add up, with a journal line naming
## who reacted. who: only these Trailomon (e.g. the ones who fought); empty = the whole team.
## Returns the total change.
func quirk_moment(moment: String, who: Array = []) -> int:
	var total := 0
	var names: Array[String] = []
	for id in (who if not who.is_empty() else Array(roster)):
		var n := Personalities.amount(String(quirks.get(id, "")), moment)
		if n != 0:
			total += n
			names.append(display_name(id))
	if total != 0:
		if Personalities.LINES.has(moment):
			journal.append(Personalities.LINES[moment] % " and ".join(names))
		change_morale(total)
	return total


## The daily quirks on a travel day: home roads, the lead, storms, thin rations.
func _quirk_day() -> void:
	var terrain := String(trip.get("terrain", ""))
	var total := 0
	for id in roster:
		var q := String(quirks.get(id, ""))
		if q == "":
			continue
		if terrain != "" and String(Species.info(id)["type"]) == terrain:
			total += Personalities.amount(q, "home_day")
		if lead_companion() == id:
			total += Personalities.amount(q, "lead_day")
		if weather == "rain" or weather == "storm":
			total += Personalities.amount(q, "storm_day")
		if rations == "thin":
			total += Personalities.amount(q, "thin_day")
	change_morale(total)


func change_morale(amount: int, reason := "") -> void:
	if amount == 0:
		return
	var was := morale
	morale = clampi(morale + amount, 0, Camp.MAX)
	if reason != "" and absi(amount) >= 5:
		journal.append("%s (morale %+d)." % [reason, morale - was])
	if Camp.band(was)[1] != Camp.band(morale)[1]:
		journal.append("The crew's spirits are %s." % String(Camp.band(morale)[2]).to_lower())


func morale_band() -> String:
	return String(Camp.band(morale)[1])


## Bonus to every trail-job check from morale.
func morale_bonus() -> int:
	match morale_band():
		"spirited":
			return Camp.SPIRITED_BONUS
		"grim":
			return Camp.GRIM_PENALTY
	return 0


func _morale_day(hungry: bool, travelling := false) -> void:
	var d := Camp.DRIFT["road"] if travelling else 0
	if rations == "thin":
		d += Camp.DRIFT["thin_rations"]
	elif rations == "full":
		d += Camp.DRIFT["full_rations"]
	if pace == "grueling":
		d += Camp.DRIFT["grueling"]
	if season() == "frost":
		d += Camp.DRIFT["frost"]
	if weather == "storm":
		d += Camp.DRIFT["storm"]
	d += Camp.DRIFT["ailing"] * ailments.size()
	if fever_days > 0:
		d += Camp.DRIFT["fever"]
	if hungry:
		d += Camp.DRIFT["hungry"]
	change_morale(d)


func pantry_count() -> int:
	var n := 0
	for k in pantry:
		n += int(pantry[k])
	return n


## Why the crew can't cook a hot meal here ("" = they can).
func cook_block() -> String:
	if state != State.AT_JUNCTION:
		return "busy"
	if cooked_at == at:
		return "cooked"
	if Camp.best_recipe(pantry).is_empty():
		return "pantry"
	if provisions < Camp.MEAL_FOOD:
		return "food"
	return ""


## Cook the best meal the pantry allows. Returns its deltas ([] if nothing was cooked).
func cook() -> Array:
	if cook_block() != "":
		return []
	var r := Camp.best_recipe(pantry)
	for k in r["needs"]:
		pantry[k] = int(pantry[k]) - int(r["needs"][k])
		if int(pantry[k]) <= 0:
			pantry.erase(k)
	cooked_at = at
	provisions -= Camp.MEAL_FOOD
	var fx: Dictionary = (r["fx"] as Dictionary).duplicate()
	var d := [{"icon": "food", "amount": -roundi(Camp.MEAL_FOOD)}]
	d.append_array(apply_fx(fx))
	journal.append("You cook %s. Everyone gathers round." % String(r["name"]).to_lower())
	quirk_moment("meal")
	note("cook", "Cooked %s." % String(r["name"]).to_lower())
	return d


## Why the crew can't forage here ("" = they can).
func forage_block() -> String:
	if state != State.AT_JUNCTION or not pending_event.is_empty():
		return "busy"
	if map.kind_of(at) == "town":
		return "town"
	if foraged_at == at:
		return "picked"
	return ""


## Head out with a basket: sets the foraging card as the pending event.
func forage() -> bool:
	if forage_block() != "":
		return false
	foraged_at = at
	var terrain := String(map.region_of(at).get("terrain", "Forest"))
	var finds: Array = Camp.FORAGE.get(terrain, ["herbs"]).duplicate()
	var r := RandomNumberGenerator.new()
	r.seed = int(stop().get("rumor_seed", 0)) + crossing_no * 97 + day
	var a: String = finds[r.randi_range(0, finds.size() - 1)]
	var b: String = finds[r.randi_range(0, finds.size() - 1)]
	var plant_id := ""
	if r.randf() < Camp.PLANT_CHANCE:
		plant_id = String(Camp.PLANTS[r.randi_range(0, Camp.PLANTS.size() - 1)][0])
	var forager := best_helper("forage")
	var knows := forager != "" and job_rank(forager, "forage") >= Camp.KNOW_RANK
	pending_event = Camp.forage_card(terrain, [a, b], plant_id, known_plants.has(plant_id), knows)
	return true


## After a rest: the campfire (once per stop), with a tale and two Trailomon getting closer.
func _campfire() -> void:
	if camped_at == at or not pending_event.is_empty() or state != State.AT_JUNCTION:
		return
	camped_at = at
	var tale: String = Camp.TALES[life_rng.randi_range(0, Camp.TALES.size() - 1)]
	var bond := ""
	var awake := roster.filter(func(id): return conscious(id))
	if awake.size() >= 2:
		var a: String = awake[life_rng.randi_range(0, awake.size() - 1)]
		var others := awake.filter(func(id): return id != a)
		var b: String = others[life_rng.randi_range(0, others.size() - 1)]
		bond = Camp.BOND_LINES[life_rng.randi_range(0, Camp.BOND_LINES.size() - 1)] % [display_name(a), display_name(b)]
		gain_xp(a, Camp.BOND_XP)
		gain_xp(b, Camp.BOND_XP)
	pending_event = Camp.campfire(tale, bond)


# ---------- the Fernwicks ----------

## Their next story beat as an event (and count this crossing's meeting).
func meet_family() -> Dictionary:
	family_met = true
	var e := Family.beat(family_stage, family_trust, crossing_no)
	family_stage += 1
	journal.append("You meet %s." % Family.NAME)
	note("family", "Met the Fernwicks: %s." % String(e["title"]).to_lower())
	return e


func hauling_available() -> float:
	var strengths: Array = []
	for id in haulers:
		if conscious(id):
			strengths.append(hauler_strength(id))
	# The crew pulls on their own when the Trailomon haulers can't do better.
	var total := maxf(Wagon.BASE_PULL, Hauling.available(strengths))
	return total * (Wagon.HARNESS_PENALTY if wagon.broken == Wagon.Part.HARNESS else 1.0)


## How many days the current food or water lasts.
func days_of(supply: float, per_day: float) -> float:
	return supply / per_day if per_day > 0.0 else INF


## Everything the route card shows for one segment, before committing.
## Rumors point at the crossing's sleeping giants, blocked roads and legendary lairs first.
func _obstacle_rumor(r: RandomNumberGenerator) -> String:
	var near := map.around(at, 4)
	var picks: Array = []
	for id in lairs:
		if not bool(lairs[id]["done"]) and near.has(id) and not rumored.has(id):
			picks.append(id)
	for k in obstacles:
		var ends := String(k).split("|")
		if (near.has(ends[0]) or near.has(ends[1])) and not rumored.has(k) and String(obstacles[k]["kind"]) != "deep":
			picks.append(k)
	picks.sort()
	if picks.is_empty() or r.randf() < 0.25:
		return ""
	var pick: String = picks[r.randi_range(0, picks.size() - 1)]
	rumored[pick] = true
	if lairs.has(pick):
		seen[pick] = true
		var sp := String(lairs[pick]["species"])
		return "{i:lair} Old folk swear %s sleeps at %s. Nobody who woke it came back with a story." % [Species.name_markup(sp), map.name_of(pick)]
	var ends := pick.split("|")
	seen[ends[0]] = true
	seen[ends[1]] = true
	var o: Dictionary = obstacles[pick]
	var road := "the road between %s and %s" % [map.name_of(ends[0]), map.name_of(ends[1])]
	if o["kind"] == "giant":
		return "{i:giant} A giant %s sleeps across %s. Bring food, or a strong team." % [Species.info(String(o["species"]))["name"], road]
	return "{i:%s} %s on %s. A {k:cap_%s|%s} Trailomon could clear it." % [Glossary.icon("cap_" + String(o["cap"])), String(o["name"]), road, String(o["cap"]), String(o["cap"]).capitalize()]


## The obstacle on a road ({} = none): {"kind": "giant"|"gate"|"deep", ...}.
func obstacle_on(seg: Dictionary) -> Dictionary:
	return obstacles.get(Obstacles.key(String(seg.get("from", seg.get("a", ""))), String(seg.get("to", seg.get("b", "")))), {})


func forecast(seg: Dictionary) -> Dictionary:
	var demand := pull_demand(float(seg["terrain_factor"]))
	var available := hauling_available()
	var result := Hauling.evaluate(demand, available)
	var pushing := result == Hauling.Result.PUSH
	var distance := trip_distance(seg, pushing)
	var days := maxi(1, ceili((distance - carry) / float(TrailLife.pace(pace)["speed"]) - 0.0001))
	var wear_added := Wagon.wear_per_day(float(seg["terrain_factor"]), load_weight(), pushing) * float(TrailLife.pace(pace)["wear"]) * days * wear_mult()
	return {
		"wear": wear_added,
		"wear_after": wagon.wear + wear_added,
		"stranded": wagon.broken == Wagon.Part.RUNNING_GEAR,
		"demand": demand,
		"available": available,
		"hauling": result,
		"days": days,
		"provisions": daily_provisions() * days,
		"water": daily_water() * days,
		"enough_food": provisions >= daily_provisions() * days,
		"enough_water": water >= daily_water() * days,
		"can_go": result != Hauling.Result.BLOCKED and state == State.AT_JUNCTION and wagon.broken != Wagon.Part.RUNNING_GEAR and available > 0.0,
	}


## How far a segment is, in normal travel days (pushing makes it longer).
func trip_distance(seg: Dictionary, pushing: bool) -> float:
	return float(seg["days"]) * (PUSH_SLOWDOWN if pushing else 1.0)


func exits() -> Array[Dictionary]:
	var out := map.exits(at)
	for seg in out:
		var o := obstacle_on(seg)
		if o.is_empty():
			continue
		seg["block"] = o.duplicate()
		if o["kind"] == "deep":
			seg["deep"] = true
			seg["days"] = int(seg["days"]) + Obstacles.DEEP_DAYS
			seg["risk"] = 3
	return out


## Travel one day along a segment. Returns a line for the log.
func spend_day(travelling := false) -> String:
	day += 1
	var notes: Array[String] = []
	var food_mult := TrailLife.weather_value(weather, "food_mult", 1.0)
	if has_curio("ember_kettle"):
		food_mult = minf(food_mult, 1.0)
	var need_food := daily_provisions() * food_mult
	var need_water := daily_water() * TrailLife.weather_value(weather, "water_mult", 1.0)
	water += room_for("water", TrailLife.weather_value(weather, "water_gain"))
	health = mini(100, health + int(TrailLife.ration(rations)["health"]) + (int(TrailLife.pace(pace)["health"]) if travelling else 0) \
		+ int(TrailLife.weather_value(weather, "health")))
	if season() == "frost":
		health -= FROST_HEALTH
		for id in fatigue:
			fatigue[id] = clampf(float(fatigue[id]) + FROST_FATIGUE, 0.0, 100.0)
		notes.append("frost")
	if fever_days > 0:
		fever_days -= 1
		health -= TrailLife.FEVER_DAMAGE
		notes.append("fever")
	_ailment_day()
	if provisions >= need_food:
		provisions -= need_food
	else:
		provisions = 0.0
		health -= STARVING_DAMAGE
		notes.append("not enough food")
	if water >= need_water:
		water -= need_water
	else:
		water = 0.0
		health -= THIRST_DAMAGE
		notes.append("not enough water")
	_morale_day(notes.has("not enough food") or notes.has("not enough water"), travelling)
	if travelling:
		_quirk_day()
	if health <= 0:
		health = 0
		state = State.FAILED
		fail_reason = "Your traveller ran out of food and water." if notes.has("not enough food") or notes.has("not enough water") else "Your traveller couldn't go on."
	if state != State.FAILED:
		var hatched := _tend_eggs()
		if hatched != "":
			notes.append(hatched)
	return "Day %d%s" % [day, (": " + ", ".join(notes)) if notes.size() > 0 else ""]


## One more day for every egg; the first one that's ready hatches if there is room.
func _tend_eggs() -> String:
	for egg in eggs:
		egg["days"] = maxi(0, int(egg["days"]) - 1)
	for i in eggs.size():
		if int(eggs[i]["days"]) <= 0 and has_room() and not roster.has(String(eggs[i]["species"])) and not stored.has(String(eggs[i]["species"])):
			var sp := String(eggs[i]["species"])
			eggs.remove_at(i)
			var keep := pending_recruit
			pending_recruit = sp
			pending_glint = life_rng.randf() < EGG_GLINT
			recruit()
			pending_recruit = keep
			note("egg", "An egg hatched: %s." % Species.info(sp)["name"])
			return "the egg hatched into %s!" % Species.info(sp)["name"]
	return ""


## An egg of this habitat: a first-form Trailomon you don't have (not a legendary).
func _find_egg(terrain: String) -> String:
	var picks: Array[String] = []
	for id in wild_for(terrain):
		if Species.stage(id) == 1 and Species.rarity(id) != "legendary" and not eggs.any(func(e): return e["species"] == id):
			picks.append(id)
	return Species.pick_weighted(picks, life_rng) if not picks.is_empty() else ""


var trip := {}
## Trip distance still to cover, in normal travel days. Pace covers more or less each day.
var trip_days_left := 0.0
var _trip_events := 0
## The event waiting for the player's choice (empty when none). Travel pauses until resolve_event().
var pending_event := {}
var _trip_had_event := false
var _trip_had_battle := false
## Tests can switch random events (and random battles) off.
var events_enabled := true
## The battle waiting to be faced (empty when none): {"pack": Dictionary, "scale": float, "guardian": bool}.
var pending_encounter := {}
## The guardian battle on the last stretch to Westwatch. Tests can switch it off.
var guardian_enabled := true
var guardian_faced := false
## Wild battle chance per travel day, plus this much per risk level. At most one per trip.
const BATTLE_CHANCE := 0.10
const BATTLE_RISK_CHANCE := 0.07
## Conscious creatures recover this share of their health each travel day, and this much on a rest day.
const TRAVEL_HEAL := 0.05
const REST_HEAL := 0.4


## Commit to a segment. Returns false if it can't be travelled. Then call step_day() until it returns false.
func start_trip(seg: Dictionary) -> bool:
	var f := forecast(seg)
	if not f["can_go"]:
		return false
	# Camp cards left open at the stop (the campfire, foraging) are dropped when you set off.
	if ["campfire", "forage"].has(String(pending_event.get("id", ""))):
		pending_event = {}
	trip = seg
	departed = true
	trip["pushing"] = f["hauling"] == Hauling.Result.PUSH
	trip_days_left = trip_distance(seg, trip["pushing"]) - carry
	carry = 0.0
	_trip_events = 0
	_trip_had_event = false
	_trip_had_battle = false
	state = State.TRAVELLING
	return true


## Spend one travel day. Returns true while the trip continues.
func step_day() -> bool:
	if state != State.TRAVELLING:
		return false
	if not pending_event.is_empty() or not pending_encounter.is_empty():
		return true
	if trip_days_left <= 0.0:
		# An event or a fight on the last day of the final road must not skip the guardian.
		if _guardian_blocks() or _lair_blocks():
			return true
		return _arrive()
	if events_enabled:
		weather = _season_weather(String(trip["terrain"]))
	journal.append(spend_day(true))
	if state == State.FAILED:
		return false
	_wear_day(float(trip["terrain_factor"]), trip["pushing"])
	if state == State.FAILED:
		return false
	if events_enabled and not trip.get("block_met", false):
		trip["block_met"] = true
		var o := obstacle_on(trip)
		if o.get("kind", "") == "giant":
			pending_event = Obstacles.giant_event(String(o["species"]), provisions >= Obstacles.GIANT_FOOD)
			journal.append("A sleeping giant blocks the road!")
		elif o.get("kind", "") == "gate":
			pending_event = Obstacles.gate_event(o, crossing_no)
			journal.append("%s! The road is blocked." % String(o["name"]))
	if has_upgrade("dew_still"):
		water += minf(Inventor.STILL_WATER, room_for("water", Inventor.STILL_WATER))
	if pending_event.is_empty() and _rival_turns_up():
		rival_met = true
		pending_event = Rival.event(crossing_no, rival_record)
		journal.append("Rook's caravan pulls alongside!")
	if pending_event.is_empty() and events_enabled and String(trip.get("terrain", "")) == "River" and not trip.get("forded", false):
		trip["forded"] = true
		pending_event = make_river(Rivers.depth_for(int(trip["risk"]), weather))
		journal.append("A river blocks the road!")
	if pending_event.is_empty() and events_enabled and life_rng.randf() < _ailment_chance():
		pending_event = catch_ailment()
	if pending_event.is_empty() and events_enabled and _trip_events < TrailEvents.PER_TRIP and rng.randf() < TrailEvents.daily_chance(int(trip["risk"])):
		var options := TrailEvents.for_segment(trip, weather)
		if not options.is_empty():
			pending_event = options[rng.randi_range(0, options.size() - 1)]
			if pending_event["id"] == "barter":
				pending_event = make_barter()
		if not pending_event.is_empty():
			_trip_had_event = true
			_trip_events += 1
			journal.append(pending_event["title"] + "!")
	if pending_event.is_empty() and events_enabled and not map.is_test and not family_met and visited.size() >= 2 and life_rng.randf() < Family.DAILY_CHANCE:
		pending_event = meet_family()
		_trip_had_event = true
	var deep_fight := Obstacles.DEEP_FIGHT if trip.get("deep", false) else 0.0
	if pending_event.is_empty() and events_enabled and not _trip_had_battle and battle_rng.randf() < (BATTLE_CHANCE + BATTLE_RISK_CHANCE * int(trip["risk"]) + TrailLife.weather_value(weather, "ambush") + deep_fight) * (Inventor.HORN_MULT if has_upgrade("brass_horn") else 1.0):
		var packs := CombatData.packs_for(trip, crossing_no)
		if not packs.is_empty():
			var pack: Dictionary = CombatData.pick_pack(packs, battle_rng)
			if pack.get("table", false):
				pack = Encounters.build(String(pack["terrain"]), crossing_no, int(trip["risk"]), battle_rng, roster.size())
			elif roster.size() < TEAM_MAX:
				pack = Encounters.trim(pack, Encounters.pack_size(roster.size(), int(trip["risk"])))
			pending_encounter = {"pack": pack, "scale": float(CombatData.RISK_SCALE.get(int(trip["risk"]), 1.0)), "guardian": false,
				"deep": trip.get("deep", false), "glint": _roll_glint(pack)}
			_trip_had_battle = true
			journal.append(pack["title"] + "!")
	if pending_event.is_empty() and pending_encounter.is_empty() and events_enabled and life_rng.randf() < TrailMoments.DAILY_CHANCE:
		_roll_moment()
	var heal := TRAVEL_HEAL * float(TrailLife.pace(pace)["heal"]) + float(TrailLife.ration(rations)["heal"])
	for id in roster:
		if conscious(id):
			creature_hp[id] = clampf(float(creature_hp[id]) + max_hp(id) * heal, 1.0, max_hp(id))
	trip_days_left -= float(TrailLife.pace(pace)["speed"])
	if state == State.FAILED:
		return false
	if trip_days_left > 0.0 or not pending_event.is_empty() or not pending_encounter.is_empty():
		return true
	if _guardian_blocks() or _lair_blocks():
		return true
	return _arrive()


## Rook shows up on the first road into the middle of the map (a caravan that started with a
## starter; never on the test route).
func _rival_turns_up() -> bool:
	if not events_enabled or rival_met or starter == "" or map == null or map.is_test:
		return false
	var layer := int(map.junctions.get(String(trip.get("to", "")), {}).get("layer", -1))
	return layer >= Rival.LAYERS_FROM and layer <= Rival.LAYERS_TO


## Pulling into a legendary's lair: it's asleep inside (once a trip, until it's beaten).
func _lair_blocks() -> bool:
	var to := String(trip.get("to", ""))
	if not events_enabled or not lairs.has(to) or bool(lairs[to]["done"]) or trip.get("lair_met", false):
		return false
	trip["lair_met"] = true
	pending_event = Obstacles.lair_event(String(lairs[to]["species"]))
	journal.append("Something big is sleeping at %s." % map.name_of(to))
	return true


## On the last stretch to the goal, the crossing's guardian steps out (once per crossing).
func _guardian_blocks() -> bool:
	if trip["to"] != map.goal or not guardian_enabled or guardian_faced:
		return false
	guardian_faced = true
	pending_encounter = {"pack": guardian_pack(), "scale": CombatData.GUARDIAN_SCALE, "guardian": true}
	journal.append(guardian_pack()["title"] + " blocks the way!")
	return true


func _arrive() -> bool:
	carry = clampf(-trip_days_left, 0.0, TrailLife.MAX_CARRY)
	trip_days_left = 0.0
	at = trip["to"]
	visited.append(at)
	journal.append("Reached %s." % map.name_of(at))
	reveal(at)
	state = State.ARRIVED if at == map.goal else State.AT_JUNCTION
	_hand_over_deliveries()
	if state == State.ARRIVED:
		cargo_paid = cargo_value() / CARGO_PAY_DIV
		coins += cargo_paid
		journal.append("The cargo is delivered: +%d coins." % cargo_paid)
		note("score", "Reached %s on day %d." % [map.name_of(at), day])
		score_history.append(arrival_score()["total"])
		# Real games only (a save slot is in play), so tests and tools don't fill the hall.
		if SaveGame.current_slot != "":
			HallOfFame.record(self, SaveGame.current_slot)
	elif events_enabled:
		_landmark_card()
	trip = {}
	return false


## Commit to a segment and resolve the whole trip at once (events take the safe choice).
func travel(seg: Dictionary) -> bool:
	if not start_trip(seg):
		return false
	while step_day():
		if not pending_event.is_empty():
			resolve_event(safe_choice(pending_event))
		if not pending_encounter.is_empty():
			auto_fight()
	if not pending_event.is_empty():
		resolve_event(safe_choice(pending_event))
	return true


## Index of the event's no-roll choice.
func safe_choice(event: Dictionary) -> int:
	var choices: Array = event["choices"]
	for i in choices.size():
		if is_safe(choices[i]):
			return i
	return 0


## A safe choice has no roll, no cost and no fight.
static func is_safe(choice: Dictionary) -> bool:
	return not choice.has("cap") and not choice.has("cost") and not choice.has("deal") and not choice["success"].has("battle") and not choice.get("risky", false)


## Wagon wear, hauler fatigue and a possible breakdown for one travel day.
func _wear_day(terrain_factor: float, pushing: bool) -> void:
	var p := TrailLife.pace(pace)
	for id in haulers:
		fatigue[id] = clampf(float(fatigue.get(id, 0.0)) + HAUL_FATIGUE * (2.0 if pushing else 1.0) * float(p["fatigue"]) + TrailLife.weather_value(weather, "fatigue") + (Camp.GRIM_FATIGUE if morale_band() == "grim" else 0.0), 0.0, 100.0)
	var chance := Wagon.breakdown_chance(wagon.wear)
	wagon.wear = minf(100.0, wagon.wear + Wagon.wear_per_day(terrain_factor, load_weight(), pushing) * float(p["wear"]) * wear_mult() + TrailLife.weather_value(weather, "wear"))
	if wagon.broken == Wagon.Part.NONE and rng.randf() < chance:
		var parts := [Wagon.Part.RUNNING_GEAR, Wagon.Part.HARNESS, Wagon.Part.CANOPY]
		_break(parts[rng.randi_range(0, parts.size() - 1)])
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon fell apart on the trail."


## Something on the wagon breaks (unless the lucky cog takes the hit). Returns true if it broke.
## from_event: the event already took its integrity toll, so the break itself costs none.
func _break(part: Wagon.Part, from_event := false) -> bool:
	if wagon.broken != Wagon.Part.NONE:
		return false
	if has_curio("lucky_cog"):
		curios.erase("lucky_cog")
		journal.append("The %s should have gone. The lucky cog rattles loose instead." % Wagon.PART_NAMES[part])
		return false
	wagon.break_part(part, 0 if from_event else Wagon.BREAKDOWN_DAMAGE)
	change_morale(Camp.ON["breakdown"])
	journal.append("The wagon's %s broke!" % wagon.part_name())
	if wagon.broken == Wagon.Part.RUNNING_GEAR and state == State.TRAVELLING:
		trip_days_left += 1
		journal.append("Limping on a broken axle: one more day to the next stop.")
	return true


# ---------- actions at a junction ----------

## Rest a day: costs a day of food and water, haulers recover.
func rest() -> void:
	if state != State.AT_JUNCTION:
		return
	journal.append(spend_day())
	fever_days = 0
	for id in ailments.keys():
		ailments[id]["days"] = int(ailments[id]["days"]) - 1
		if int(ailments[id]["days"]) <= 0:
			_shake_off(id)
	var pipe := has_curio("reed_pipe")
	for id in fatigue:
		fatigue[id] = maxf(0.0, float(fatigue[id]) - REST_RECOVERY * (1.5 if pipe else 1.0))
	var woke := 0
	for id in roster:
		if not conscious(id):
			woke += 1
		creature_hp[id] = minf(max_hp(id), float(creature_hp.get(id, 0.0)) + max_hp(id) * (REST_HEAL + (0.25 if pipe else 0.0)))
	if state != State.FAILED:
		journal.append("Rested. The haulers recovered and the team licked its wounds%s." % ((", %d back on their feet" % woke) if woke > 0 else ""))
		change_morale(Camp.ON["rest"])
		quirk_moment("rest")
		_campfire()


# ---------- ailments (trail doctor) ----------

func ailment_of(id: String) -> String:
	return String(ailments.get(id, {}).get("kind", ""))


func _ailment_chance() -> float:
	var c := Ailments.DAILY_CHANCE
	if rations == "thin":
		c *= 1.5
	if season() == "frost":
		c *= 1.5
	if ["Swamp", "Jungle"].has(String(trip.get("terrain", ""))):
		c *= 1.3
	return c


## One Trailomon falls ill (it starts at once); returns the doctor's card, or {} if nobody can.
func catch_ailment(kind := "", who := "") -> Dictionary:
	if who == "":
		var well: Array = roster.filter(func(id): return conscious(id) and not ailments.has(id))
		if well.is_empty():
			return {}
		who = well[life_rng.randi_range(0, well.size() - 1)]
	if kind == "":
		var kinds := Ailments.KINDS.keys()
		kind = kinds[life_rng.randi_range(0, kinds.size() - 1)]
	ailments[who] = {"kind": kind, "days": Ailments.DAYS}
	journal.append("%s has %s!" % [Species.info(who)["name"], String(Ailments.info(kind)["name"]).to_lower()])
	note(Ailments.info(kind)["icon"], "%s caught %s." % [Species.info(who)["name"], String(Ailments.info(kind)["name"]).to_lower()])
	return Ailments.make(kind, who, light_dust, display_name(who))


func _ailment_day() -> void:
	for id in ailments.keys():
		match ailment_of(id):
			"moss_lung":
				fatigue[id] = minf(100.0, float(fatigue.get(id, 0.0)) + Ailments.MOSS_FATIGUE)
			"bramble_burrs":
				creature_hp[id] = maxf(1.0, float(creature_hp.get(id, 0.0)) - max_hp(id) * Ailments.BURR_HP)
		ailments[id]["days"] = int(ailments[id]["days"]) - 1
		if int(ailments[id]["days"]) <= 0:
			_shake_off(id)


func _shake_off(id: String) -> void:
	var kind := ailment_of(id)
	ailments.erase(id)
	journal.append("%s shakes off the %s." % [Species.info(id)["name"], String(Ailments.info(kind).get("name", "ailment")).to_lower()])


## Effects from the doctor's card (apply_fx keys ail_cure, ail_days, ail_risk).
func _ailment_fx(fx: Dictionary, d: Array) -> void:
	if fx.has("ail_cure") and ailments.has(String(fx["ail_cure"])):
		var id := String(fx["ail_cure"])
		ailments.erase(id)
		d.append({"icon": "job_heal", "amount": 0, "label": "%s cured" % Species.info(id)["name"]})
	for id in fx.get("ail_days", {}):
		if ailments.has(id):
			ailments[id]["days"] = int(fx["ail_days"][id])
			d.append({"icon": "day", "amount": int(fx["ail_days"][id]), "bad_up": true, "label": "days ill"})
	if fx.has("ail_risk") and ailments.has(String(fx["ail_risk"])):
		var id := String(fx["ail_risk"])
		var kind := ailment_of(id)
		if life_rng.randf() < Ailments.SPREAD_CHANCE:
			var well: Array = roster.filter(func(o): return conscious(o) and not ailments.has(o))
			if not well.is_empty():
				var other: String = well[life_rng.randi_range(0, well.size() - 1)]
				ailments[other] = {"kind": kind, "days": Ailments.DAYS}
				journal.append("It spreads to %s." % Species.info(other)["name"])
				d.append({"icon": Ailments.info(kind)["icon"], "amount": 0, "label": "spread to %s" % Species.info(other)["name"]})
		elif life_rng.randf() < 0.4:
			ailments[id]["days"] = int(ailments[id]["days"]) + Ailments.WORSE_DAYS
			d.append({"icon": Ailments.info(kind)["icon"], "amount": Ailments.WORSE_DAYS, "bad_up": true, "label": "days, getting worse"})


# ---------- landmarks, scrapbook, arrival score ----------

## A first visit to a region with a landmark: its arrival card.
func _landmark_card() -> void:
	if map == null or map.is_test or not pending_event.is_empty():
		return
	var region := String(map.junctions.get(at, {}).get("region", ""))
	if region == "" or landmarks_seen.has(region):
		return
	var lm := map.landmark(at)
	if not Landmarks.has(lm):
		return
	landmarks_seen[region] = true
	pending_event = Landmarks.card(lm, String(map.regions[region]["name"]), day)
	quirk_moment("landmark")
	note("landmark", "Saw %s." % Landmarks.name_of(lm))


## Add a line to the scrapbook.
func note(icon: String, text: String) -> void:
	scrapbook.append({"day": day, "icon": icon, "text": text})


const RANKS := [[0, "Greenhorn"], [300, "Trail hand"], [450, "Wagon master"], [600, "Trail legend"]]


## The arrival reckoning: {"total", "rank", "lines": [[icon, label, points]]}.
func arrival_score() -> Dictionary:
	var lines: Array = []
	var team := 0
	for id in roster:
		team += 40 if conscious(id) else 15
	lines.append(["starter", "Team (%d)" % roster.size(), team])
	lines.append(["health", "Traveller's health", health])
	lines.append(["food", "Food and water left", roundi(provisions / 5.0 + water / 5.0)])
	lines.append(["coins", "Coins", coins / 3])
	lines.append(["wagon", "Wagon", wagon.integrity / 2])
	if frost_day > 0:
		var spare := frost_day - day
		lines.append(["frost", ("%d days before the frost" % spare) if spare >= 0 else ("%d days into the frost" % -spare), spare * 5 if spare >= 0 else spare * 10])
	var guard: int = {"fight": 100, "rapids": 60, "toll": 40}.get(finale, 0)
	if guard > 0:
		lines.append(["ultimate", {"fight": "Beat the guardian", "rapids": "Ran the rapids", "toll": "Paid the toll road"}[finale], guard])
	if deliveries_on_time > 0:
		lines.append(["cargo", "Deliveries on time", 15 * deliveries_on_time])
	var total := 0
	for l in lines:
		total += int(l[2])
	var rank := ""
	for r in RANKS:
		if total >= int(r[0]):
			rank = r[1]
	return {"total": total, "rank": rank, "lines": lines}


# ---------- delivery jobs ----------

## Stops with a job board.
const JOB_BOARDS := ["town", "post", "village", "stilts"]
const JOB_GOODS := ["Mail sacks", "Lamp oil", "Seed sacks", "Bolts of cloth", "Herb bundles", "A crate of tools", "Salt blocks"]
## Days allowed: the quickest way there times this, plus JOB_SPARE_DAYS. Late pays half.
const JOB_SLACK := 1.4
const JOB_SPARE_DAYS := 2


## The job on offer at this stop: {"from", "to", "name", "weight", "pay", "due"}, or {}.
func delivery_offer() -> Dictionary:
	if map == null or map.is_test or state != State.AT_JUNCTION:
		return {}
	if not JOB_BOARDS.has(map.kind_of(at)) or jobs_taken.has(at):
		return {}
	if String(job_offer.get("from", "")) == at:
		return {} if job_offer.has("none") else job_offer
	var r := RandomNumberGenerator.new()
	r.seed = hash(at) + crossing_no * 7919
	var here := map.hops(at, map.goal)
	var options: Array[String] = []
	for j in map.junctions:
		if j == at or j == map.goal:
			continue
		var d := map.shortest_days(at, j)
		if d >= 3 and d <= 12 and map.hops(j, map.goal) < here:
			options.append(j)
	options.sort()
	if options.is_empty():
		job_offer = {"from": at, "none": true}
		return {}
	var to := options[r.randi_range(0, options.size() - 1)]
	var days := map.shortest_days(at, to)
	job_offer = {"from": at, "to": to, "name": "%s for %s" % [JOB_GOODS[r.randi_range(0, JOB_GOODS.size() - 1)], map.name_of(to)],
		"weight": float(5 * r.randi_range(3, 7)), "pay": 8 + 3 * days + 2 * crossing_no,
		"due": day + ceili(days * JOB_SLACK) + JOB_SPARE_DAYS}
	return job_offer


func can_take_delivery() -> bool:
	var o := delivery_offer()
	return not o.is_empty() and free_space() >= float(o["weight"])


func take_delivery() -> bool:
	if not can_take_delivery():
		return false
	var o := delivery_offer()
	cargo.append({"name": o["name"], "weight": o["weight"], "value": 0, "deliver_to": o["to"], "due": o["due"], "pay": o["pay"]})
	jobs_taken[at] = true
	journal.append("Took the job: %s, due by day %d for %d coins." % [o["name"], o["due"], o["pay"]])
	return true


## Hand over any deliveries for this stop. Late ones pay half.
func _hand_over_deliveries() -> void:
	for i in range(cargo.size() - 1, -1, -1):
		var c: Dictionary = cargo[i]
		if String(c.get("deliver_to", "")) != at:
			continue
		var late := day > int(c["due"])
		var pay := int(c["pay"]) / (2 if late else 1)
		if not late:
			deliveries_on_time += 1
			change_morale(Camp.ON["deliver"])
		note("cargo", "Delivered %s%s." % [String(c["name"]), " late" if late else " on time"])
		coins += pay
		cargo.remove_at(i)
		journal.append("Delivered: %s%s. +%d coins." % [String(c["name"]), " (late, half pay)" if late else "", pay])


# ---------- hunting ----------

## Food each creature in the bag brings in, by size. The charger counts double.
const HUNT_FOOD := {"small": 6.0, "medium": 10.0, "large": 16.0}
const HUNT_XP := 25
## Stops too busy for game.
const NO_GAME := ["town", "post"]


## "" when the team can go hunting here, else why not.
func hunt_block() -> String:
	if state != State.AT_JUNCTION or map == null:
		return "busy"
	if NO_GAME.has(map.kind_of(at)):
		return "town"
	if hunted_at == at:
		return "spooked"
	if not can_fight():
		return "ko"
	if Encounters.pool(scenery()["terrain"], crossing_no).is_empty():
		return "town"
	return ""


## A herd grazing near the stop: four to five prey and one charger in front. Prey are the
## terrain's ordinary species; the charger is the biggest of them.
func make_herd(rng_in: RandomNumberGenerator = null) -> Dictionary:
	var r := rng_in if rng_in != null else battle_rng
	var terrain := String(scenery()["terrain"])
	var pool := Encounters.weighted_pool(terrain, crossing_no).filter(func(id): return Species.rarity(id) != "legendary")
	if pool.is_empty():
		return {}
	var picks: Array[String] = []
	for i in 4 + r.randi_range(0, 1):
		picks.append(Species.pick_weighted(pool, r))
	var sizes := {"small": 0, "medium": 1, "large": 2}
	var charger := Species.pick_weighted(pool, r)
	for i in 4:
		var c := Species.pick_weighted(pool, r)
		if int(sizes[Species.info(c)["size"]]) > int(sizes[Species.info(charger)["size"]]):
			charger = c
	var front := [picks[0], charger, picks[1]]
	var back := ["", "", ""]
	for i in range(2, picks.size()):
		back[[1, 0, 2][i - 2]] = picks[i]
	return {"id": "hunt", "title": "A grazing herd", "front": front, "back": back, "charger": charger,
		"text": "A herd grazes near %s, %s at its head. Each one the team knocks out before it bolts drops the forage it was carrying." % [map.name_of(at), Species.info(charger)["name"]]}


## Spend the day hunting. Sets pending_encounter to the herd; the battle screen plays it.
func start_hunt() -> bool:
	if hunt_block() != "":
		return false
	journal.append(spend_day())
	if state == State.FAILED:
		return false
	hunted_at = at
	var herd := make_herd()
	if herd.is_empty():
		return false
	pending_encounter = {"pack": herd, "scale": float(CombatData.RISK_SCALE[1]), "guardian": false, "hunt": true}
	journal.append("The team goes hunting.")
	return true


func is_hunt() -> bool:
	return bool(pending_encounter.get("hunt", false))


func _finish_hunt(battle: Battle) -> Array[String]:
	var lines: Array[String] = []
	pending_encounter = {}
	pending_recruit = ""
	if battle == null:
		lines.append("Nobody is fit to hunt. The day is lost.")
		return lines
	var hp := battle.player_hp()
	for id in hp:
		creature_hp[id] = float(hp[id])
	var bag := battle.hunt_bag()
	if battle.outcome == Battle.Outcome.DEFEAT:
		lines.append("The charger drives the team off. They limp back empty-handed.")
	else:
		var food := 0.0
		var charger_food := 0.0
		for f in battle.side_fighters(Formation.Side.ENEMY):
			if f.hp <= 0.0 and not f.fled:
				var n := float(HUNT_FOOD.get(Species.info(f.species)["size"], 8.0)) * (2.0 if not f.prey else 1.0)
				food += n
				if not f.prey:
					charger_food = n
		var got := room_for("food", food)
		provisions += got
		var fled := 0
		for f in battle.side_fighters(Formation.Side.ENEMY):
			if f.fled:
				fled += 1
		if bag.is_empty():
			lines.append("The whole herd gets away. Nothing for the pot today.")
		else:
			lines.append("The team brings down %d of the herd%s, %d got away." % [bag.size(), " and the charger with them" if charger_food > 0.0 else "", fled])
			lines.append("+%d {i:food} food." % roundi(got))
			change_morale(Camp.ON["hunt"])
			if got + 0.5 < food:
				lines.append("No room in the wagon for the rest: %d food left behind." % roundi(food - got))
	var grew: Array[String] = []
	for f in battle.side_fighters(Formation.Side.PLAYER):
		if gain_xp(f.species, HUNT_XP) > 0:
			grew.append("%s (Lv %d)" % [Species.info(f.species)["name"], level(f.species)])
	lines.append("Everyone who hunted gains %d experience." % HUNT_XP)
	if not grew.is_empty():
		lines.append("Level up! %s. Choose their upgrades from the Companions screen." % ", ".join(grew))
	var down := knocked_out()
	if not down.is_empty():
		var names: Array[String] = []
		for id in down:
			names.append(Species.info(id)["name"])
		lines.append("Knocked out: %s. Rest a day to get them back on their feet." % ", ".join(names))
	for l in lines:
		journal.append(l)
	return lines


## What "Repair" would do right now: {"kind": "spare"|"jury"|"tune"|"none", "days", "spare",
## "helper", "skilled"}. A broken part takes its spare (one day). Without the spare a Trailomon
## with the part's job jury-rigs it (one day if skilled, two if not, and integrity suffers).
## With nothing broken it's a one-day tune-up that takes wear off.
func repair_plan() -> Dictionary:
	if wagon.broken == Wagon.Part.NONE:
		return {"kind": "tune" if wagon.wear >= 1.0 else "none", "days": 1, "spare": "", "helper": "", "skilled": false}
	var spare := wagon.spare_needed()
	if spare_count(spare) > 0:
		return {"kind": "spare", "days": 1, "spare": spare, "helper": "", "skilled": false}
	var job: String = Wagon.SPARES[spare]["job"]
	var helper := best_helper(job)
	var skilled := helper != "" and job_rank(helper, job) >= Wagon.JURY_RANK
	return {"kind": "jury", "days": 1 if skilled else 2, "spare": spare, "helper": helper, "skilled": skilled, "job": job}


## Repair the wagon as repair_plan() says.
func repair() -> void:
	if state != State.AT_JUNCTION:
		return
	var plan := repair_plan()
	if plan["kind"] == "none":
		return
	for i in int(plan["days"]):
		journal.append(spend_day())
		if state == State.FAILED:
			return
	match String(plan["kind"]):
		"tune":
			wagon.tune_up()
			journal.append("A day of grease and tightening. The wagon runs smoother.")
		"spare":
			spares[plan["spare"]] = spare_count(plan["spare"]) - 1
			if spare_count(plan["spare"]) <= 0:
				spares.erase(plan["spare"])
			wagon.repair(true)
			journal.append("Fitted the %s. Good as new." % Wagon.SPARES[plan["spare"]]["name"])
		"jury":
			wagon.repair(false, plan["skilled"])
			if plan["helper"] != "":
				gain_xp(plan["helper"], TrailEvents.JOB_XP["mixed"])
			journal.append("No %s. %s." % [Wagon.SPARES[plan["spare"]]["name"],
				("%s rigs something that holds" % Species.info(plan["helper"])["name"]) if plan["skilled"] else "Patched with rope and hope"])
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon fell apart during repairs."


func drop_cargo(index: int) -> void:
	if index < 0 or index >= cargo.size():
		return
	journal.append("Left the %s behind." % String(cargo[index]["name"]).to_lower())
	cargo.remove_at(index)


## Leave supplies by the road: 10 food, 10 water, or one spare part ("spare_axle"...).
func dump(kind: String) -> void:
	match kind:
		"food":
			if provisions >= 10.0:
				provisions -= 10.0
				journal.append("Left 10 food by the road.")
		"water":
			if water >= 10.0:
				water -= 10.0
				journal.append("Poured out 10 water.")
		_:
			var k := kind.trim_prefix("spare_")
			if spare_count(k) > 0:
				_add_spare(k, -1)
				journal.append("Left the %s by the road." % Wagon.SPARES[k]["name"])


func toggle_hauler(id: String) -> void:
	if not can_haul(id):
		return
	if haulers.has(id):
		haulers.erase(id)
	else:
		haulers.append(id)


# ---------- events ----------

## Home ground and weather bonuses: +1 rank each for a Trailomon on its own habitat's terrain,
## and when today's weather favours its habitat. Only counts if it has the job at all.
func job_bonus(id: String) -> int:
	var t: String = Species.info(id)["type"]
	var bonus := 0
	if not trip.is_empty() and TrailLife.TERRAIN_HABITAT.get(String(trip.get("terrain", "")), "") == t:
		bonus += 1
	if TrailLife.weather(weather)["favours"] == t:
		bonus += 1
	return bonus


## A Trailomon's job rank including bonuses (0 if it doesn't have the job).
func job_rank(id: String, cap: String) -> int:
	if ailment_of(id) == "spore_sneeze":
		return 0
	var r := Species.capability(id, cap)
	return r + job_bonus(id) if r > 0 else 0


## The best creature in the roster for a job, or "" if none has it (skipping any in `busy`).
func best_helper(cap: String, busy: Array = []) -> String:
	var best := ""
	var best_rank := 0
	for id in roster:
		if not conscious(id) or busy.has(id):
			continue
		var r := job_rank(id, cap)
		if r > best_rank:
			best_rank = r
			best = id
	return best


## Can the crew pay this cost right now? (Costs are negative deltas.)
func can_afford(cost: Dictionary) -> bool:
	return coins + int(cost.get("coins", 0)) >= 0 and provisions + float(cost.get("food", 0)) >= 0.0 \
		and water + float(cost.get("water", 0)) >= 0.0 and spare_count("axle") + int(cost.get("spare_axle", 0)) >= 0 \
		and spare_count("harness") + int(cost.get("spare_harness", 0)) >= 0 and spare_count("canvas") + int(cost.get("spare_canvas", 0)) >= 0 \
		and (not cost.has("give_item") or item_free(String(cost["give_item"])) > 0) \
		and light_dust + int(cost.get("light_dust", 0)) >= 0 and dark_dust + int(cost.get("dark_dust", 0)) >= 0


## What each choice of an event looks like: helper, odds (or safe), cost, whether it's affordable.
func event_choices(event: Dictionary) -> Array:
	var out: Array = []
	for c in event["choices"]:
		var cost: Dictionary = c.get("cost", {})
		var view := {"label": c["label"], "safe": is_safe(c), "helper": "", "odds": {}, "cost": cost,
			"affordable": can_afford(cost), "rolled": c.has("cap"), "cap": c.get("cap", ""), "bonus": 0,
			"reward": c["success"], "fight": c["success"].has("battle"), "hidden": c.get("risky", false)}
		if c.has("cap"):
			var helper := best_helper(c["cap"])
			var score := job_rank(helper, c["cap"]) * TrailEvents.RANK_SCORE if helper != "" else 0
			view["helper"] = helper
			view["bonus"] = job_bonus(helper) if helper != "" else 0
			# Other Trailomon can lend a hand: each assisting job adds to the score.
			var assists: Array = []
			var a: Dictionary = c.get("assist", {})
			for cap in a:
				var who := best_helper(cap, [helper])
				if who != "" and job_rank(who, cap) >= Rivers.ASSIST_RANK:
					score += int(a[cap])
					assists.append({"who": who, "cap": cap, "bonus": int(a[cap])})
			view["assists"] = assists
			score += morale_bonus()
			view["morale"] = morale_bonus()
			if c["cap"] == "float" and has_upgrade("float_tanks"):
				score += Inventor.FLOAT_BONUS
				view["gear"] = "float_tanks"
			view["odds"] = CheckOdds.for_scores(score, int(c["difficulty"]))
		out.append(view)
	return out


## Resolve the pending event with a choice. roll is 0-99 (random if negative).
## Returns {"outcome": "success"|"mixed"|"failure", "text", "deltas", "helper", "fight", "recruit"}.
func resolve_event(choice: int, roll := -1) -> Dictionary:
	if pending_event.is_empty():
		return {}
	var c: Dictionary = pending_event["choices"][choice]
	var view: Dictionary = event_choices(pending_event)[choice]
	if not view["affordable"]:
		return {}
	var outcome := "success"
	if c.has("cap"):
		var odds: Dictionary = view["odds"]
		if roll < 0:
			roll = rng.randi_range(0, 99)
		if roll >= odds["success"] + odds["mixed"]:
			outcome = "failure"
		elif roll >= odds["success"]:
			outcome = "mixed"
	var fx: Dictionary = c.get(outcome, c["success"])
	var helper: String = view["helper"]
	var terrain := String(trip.get("terrain", "Forest"))
	var pending_event_was := pending_event
	pending_event = {}
	var text: String = fx["text"]
	journal.append(text)
	var deltas: Array = []
	if c.has("cost"):
		deltas.append_array(apply_fx(c["cost"], "", terrain))
	if helper != "" and int(TrailEvents.JOB_XP[outcome]) > 0:
		deltas.append_array(apply_fx({"job_xp": TrailEvents.JOB_XP[outcome]}, helper, terrain))
		for a in view.get("assists", []):
			gain_xp(String(a["who"]), int(TrailEvents.JOB_XP[outcome]) / 2)
	var river_depth := int(pending_event_was.get("depth", 0)) if pending_event_was.get("id", "") == "river" else 0
	deltas.append_array(apply_fx(fx, helper, terrain))
	# Waiting at a river: the water drops a level, then the choice comes back.
	if fx.get("river_wait", false) and state == State.TRAVELLING:
		pending_event = make_river(maxi(1, river_depth - 1))
	return {"outcome": outcome, "text": text, "deltas": deltas, "helper": helper,
		"fight": not pending_encounter.is_empty(), "recruit": pending_recruit}


## Apply effects in the TrailEffects delta convention. helper earns "job_xp"; "xp" goes to the
## whole team. Returns what changed as [{"icon", "amount", "who"?}] for the screen.
func apply_fx(fx: Dictionary, helper := "", terrain := "Forest") -> Array:
	var d: Array = []
	_ailment_fx(fx, d)
	if fx.has("food"):
		var was := provisions
		var want := float(fx["food"])
		var got := minf(want, room_for("food", want)) if want > 0.0 else want
		provisions = maxf(0.0, provisions + got)
		d.append({"icon": "food", "amount": roundi(provisions - was)})
		if got < want:
			d.append({"icon": "food", "amount": -roundi(want - got), "label": "left behind, no room"})
			journal.append("No room for %d food. Left it behind." % roundi(want - got))
	if fx.has("water"):
		var was := water
		var want := float(fx["water"])
		var got := minf(want, room_for("water", want)) if want > 0.0 else want
		water = maxf(0.0, water + got)
		d.append({"icon": "water", "amount": roundi(water - was)})
		if got < want:
			d.append({"icon": "water", "amount": -roundi(want - got), "label": "left behind, no room"})
	if fx.has("coins"):
		coins = maxi(0, coins + int(fx["coins"]))
		d.append({"icon": "coins", "amount": int(fx["coins"])})
	if fx.has("morale"):
		var was := morale
		change_morale(int(fx["morale"]))
		d.append({"icon": "morale", "amount": morale - was})
	if fx.has("pantry"):
		for k in fx["pantry"]:
			var n := mini(int(fx["pantry"][k]), Camp.PANTRY_MAX - pantry_count())
			if n > 0:
				pantry[k] = int(pantry.get(k, 0)) + n
				d.append({"icon": Camp.ingredient(k)["icon"], "amount": n})
	if fx.has("learn_plant"):
		known_plants[String(fx["learn_plant"])] = true
	if fx.has("trust"):
		family_trust = clampi(family_trust + int(fx["trust"]), 0, Family.MAX_TRUST)
		change_morale(3 * signi(int(fx["trust"])))
		if int(fx["trust"]) != 0:
			d.append({"icon": "family", "amount": int(fx["trust"]), "label": "trust"})
	if fx.has("lures"):
		lures = maxi(0, lures + int(fx["lures"]))
		d.append({"icon": "lure", "amount": int(fx["lures"])})
	if fx.has("egg"):
		var sp := _find_egg(terrain)
		if sp != "":
			eggs.append({"species": sp, "days": EGG_DAYS})
			d.append({"icon": "egg", "amount": 1, "label": "hatches in %d days" % EGG_DAYS})
	if fx.has("flares"):
		flares = maxi(0, flares + int(fx["flares"]))
		d.append({"icon": "flare", "amount": int(fx["flares"])})
	if fx.get("clear_block", false) and not trip.is_empty():
		obstacles.erase(Obstacles.key(String(trip["from"]), String(trip["to"])))
		d.append({"icon": "progress", "amount": 0, "label": "road clear"})
	if fx.has("give_item"):
		var gid := String(fx["give_item"])
		items[gid] = item_count(gid) - 1
		if int(items[gid]) <= 0:
			items.erase(gid)
		d.append({"icon": gid, "amount": -1})
	for k in Wagon.SPARES:
		if fx.has("spare_" + k):
			d.append_array(_add_spare(k, int(fx["spare_" + k])))
	if fx.has("spare"):
		var keys: Array = Wagon.SPARES.keys()
		var k: String = String(fx["spare"]) if Wagon.SPARES.has(String(fx["spare"])) else keys[life_rng.randi_range(0, keys.size() - 1)]
		d.append_array(_add_spare(k, 1))
	if fx.has("curio") and Outfitter.is_curio(String(fx["curio"])):
		curios[String(fx["curio"])] = true
		d.append({"icon": Outfitter.CURIOS[fx["curio"]]["icon"], "amount": 1})
	if fx.has("salvage"):
		var crate: Dictionary = fx["salvage"]
		if float(crate["weight"]) <= free_space():
			cargo.append(crate.duplicate())
			d.append({"icon": "cargo", "amount": 1, "label": String(crate["name"])})
		else:
			d.append({"icon": "cargo", "amount": 0, "label": "no room for the %s" % String(crate["name"]).to_lower()})
			journal.append("No room for the %s." % String(crate["name"]).to_lower())
	if fx.has("break"):
		var part: Wagon.Part = {"axle": Wagon.Part.RUNNING_GEAR, "harness": Wagon.Part.HARNESS, "canopy": Wagon.Part.CANOPY}.get(String(fx["break"]), Wagon.Part.NONE)
		if part != Wagon.Part.NONE and _break(part, true):
			d.append({"icon": "spare_" + Wagon.spare_for(part), "amount": 0, "label": "%s broke" % Wagon.PART_NAMES[part]})
	if fx.has("wear"):
		wagon.wear = clampf(wagon.wear + float(fx["wear"]), 0.0, 100.0)
		d.append({"icon": "wagon", "amount": int(fx["wear"]), "bad_up": true, "label": "wear"})
	if fx.has("integrity"):
		wagon.integrity = clampi(wagon.integrity + int(fx["integrity"]), 0, 100)
		d.append({"icon": "wagon", "amount": int(fx["integrity"]), "suffix": "%"})
	if fx.has("fatigue"):
		for id in haulers:
			fatigue[id] = clampf(float(fatigue.get(id, 0.0)) + float(fx["fatigue"]), 0.0, 100.0)
		d.append({"icon": "tired", "amount": int(fx["fatigue"]), "bad_up": true})
	if fx.has("heal_team"):
		for id in roster:
			creature_hp[id] = minf(max_hp(id), float(creature_hp.get(id, 0.0)) + max_hp(id) * float(fx["heal_team"]))
		d.append({"icon": "hp", "amount": roundi(float(fx["heal_team"]) * 100.0), "suffix": "%"})
	if fx.has("light_dust"):
		light_dust += int(fx["light_dust"])
		d.append({"icon": "light_dust", "amount": int(fx["light_dust"])})
	if fx.has("dark_dust"):
		dark_dust += int(fx["dark_dust"])
		d.append({"icon": "dark_dust", "amount": int(fx["dark_dust"])})
	if fx.has("item"):
		var iid := String(fx["item"])
		if iid == "random" or not BattleItems.has(iid):
			iid = BattleItems.ITEMS.keys()[life_rng.randi_range(0, BattleItems.ITEMS.size() - 1)]
		items[iid] = item_count(iid) + 1
		d.append({"icon": iid, "amount": 1})
	for i in int(fx.get("technique", 0)):
		var all: Array = MovePool.technique_ids()
		var mid: String = all[life_rng.randi_range(0, all.size() - 1)]
		techniques[mid] = technique_count(mid) + 1
		d.append({"icon": "technique", "amount": 1, "label": CombatData.move(mid)["name"]})
	if fx.has("job_xp") and helper != "":
		gain_xp(helper, int(fx["job_xp"]))
		d.append({"icon": "xp", "amount": int(fx["job_xp"]), "who": helper})
	if fx.has("xp"):
		for id in roster:
			if conscious(id):
				gain_xp(id, int(fx["xp"]))
		d.append({"icon": "xp", "amount": int(fx["xp"]), "label": "team"})
	if fx.has("progress") and state == State.TRAVELLING:
		trip_days_left = maxf(0.05, trip_days_left - float(fx["progress"]))
		d.append({"icon": "progress", "amount": roundi(float(fx["progress"]) * 10.0) / 10.0, "label": "day"})
	if int(fx.get("fever", 0)) > 0:
		fever_days = maxi(fever_days, int(fx["fever"]))
		d.append({"icon": "fever", "amount": int(fx["fever"]), "bad_up": true, "label": "days"})
	if fx.has("cure") and fever_days > 0:
		fever_days = 0
		d.append({"icon": "fever", "amount": 0, "label": "cured"})
	for i in int(fx.get("lose_cargo", 0)):
		if cargo.is_empty():
			break
		var lost: Dictionary = cargo.pop_at(rng.randi_range(0, cargo.size() - 1))
		journal.append("Lost the %s." % String(lost["name"]).to_lower())
		d.append({"icon": "cargo", "amount": -1, "label": String(lost["name"])})
	if fx.has("recruit"):
		var wild := wild_for(terrain)
		if not wild.is_empty():
			pending_recruit = Species.pick_weighted(wild, life_rng)


			pending_recruit = wild[life_rng.randi_range(0, wild.size() - 1)]
			meet(pending_recruit)
			d.append({"icon": "ev_wildlife", "amount": 0, "who": pending_recruit, "label": "wants to join"})
	if fx.get("battle", "") == "rival" and state == State.TRAVELLING:
		pending_encounter = {"pack": Rival.pack(starter, crossing_no), "scale": float(CombatData.RISK_SCALE[2]), "guardian": false,
			"bounty": int(fx.get("bounty", 0)), "from_event": true, "rival": true}
		d.append({"icon": "rival", "amount": 0, "label": "battle"})
	elif fx.get("battle", "") in ["giant", "lair"] and state == State.TRAVELLING:
		pending_encounter = _obstacle_fight(String(fx["battle"]))
		d.append({"icon": "risk", "amount": 0, "label": "fight"})
	elif fx.has("battle") and state == State.TRAVELLING:
		var pack: Dictionary = TrailEvents.PACKS.get(String(fx["battle"]), {})
		if pack.is_empty():
			pack = CombatData.pack_by_id(String(fx["battle"]))
		if roster.size() < TEAM_MAX:
			pack = Encounters.trim(pack, Encounters.pack_size(roster.size(), int(trip.get("risk", 1))))
		pending_encounter = {"pack": pack, "scale": float(CombatData.RISK_SCALE.get(int(trip.get("risk", 1)), 1.0)), "guardian": false,
			"bounty": int(fx.get("bounty", 0)), "from_event": true}
		d.append({"icon": "risk", "amount": 0, "label": "fight"})
	if fx.has("health"):
		health = mini(100, health + int(fx["health"]))
		d.append({"icon": "health", "amount": int(fx["health"])})
	if health <= 0:
		health = 0
		state = State.FAILED
		fail_reason = "Your traveller couldn't go on."
		return d
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon fell apart on the trail."
		return d
	if int(fx.get("days", 0)) > 0:
		d.append({"icon": "day", "amount": int(fx["days"]), "bad_up": true})
	for i in int(fx.get("days", 0)):
		journal.append(spend_day())
		if state == State.FAILED:
			return d
	return d


## The fight with a woken giant or a lair's legendary: it stands front and centre, with a few
## wild Trailomon of its habitat around it (fewer for a small team). Beat it and it is the one
## you get a try to catch (much likelier at a lair).
func _obstacle_fight(kind: String) -> Dictionary:
	var lair := kind == "lair"
	var sp := String(lairs[trip["to"]]["species"]) if lair else String(obstacle_on(trip).get("species", ""))
	var terrain := String(trip.get("terrain", "Forest"))
	if lair:
		terrain = String(map.region_of(String(trip["to"])).get("terrain", terrain)) if map != null else terrain
	var risk := 2 if lair else 3
	var pack := Encounters.build(terrain, crossing_no, risk, battle_rng, roster.size())
	if pack.is_empty():
		pack = {"front": ["", "", ""], "back": ["", "", ""]}
	pack = Encounters.trim(pack, maxi(1, Encounters.pack_size(roster.size(), risk) - 1))
	var front: Array = pack["front"]
	var back: Array = pack["back"]
	if String(front[1]) != "":
		for i in [0, 2]:
			if String(front[i]) == "":
				front[i] = front[1]
				break
	front[1] = sp
	for i in 3:
		if String(back[i]) == sp:
			back[i] = ""
	var n := String(Species.info(sp)["name"])
	pack["id"] = ("lair_" if lair else "giant_") + sp
	pack["title"] = ("The legendary %s" if lair else "A woken %s") % n
	pack["text"] = ("%s rises from its hollow." if lair else "The %s heaves itself up, furious and enormous.") % n
	return {"pack": pack, "scale": float(CombatData.RISK_SCALE[3]) * (1.0 if lair else Obstacles.GIANT_SCALE), "guardian": false,
		"prize": sp, "catch_bonus": Obstacles.LAIR_CATCH if lair else 0.0, "lair": String(trip["to"]) if lair else "",
		"giant": not lair}


## Add (or with a negative count, take away) spare parts. Gains only come aboard if they fit.
func _add_spare(k: String, n: int) -> Array:
	if n > 0:
		var fits := int(floorf(free_space() / float(Wagon.SPARES[k]["weight"])))
		if fits < n:
			journal.append("No room for the %s." % Wagon.SPARES[k]["name"])
		n = mini(n, fits)
		if n <= 0:
			return [{"icon": "spare_" + k, "amount": 0, "label": "no room"}]
	spares[k] = maxi(0, spare_count(k) + n)
	if spare_count(k) == 0:
		spares.erase(k)
	return [{"icon": "spare_" + k, "amount": n}]


## How much of a supply fits in the free space (food and water are weighed per lot of 10).
func room_for(supply: String, amount: float) -> float:
	var per_unit: float = Outfitter.weight_of(supply) / 10.0
	if per_unit <= 0.0:
		return amount
	return clampf(free_space() / per_unit, 0.0, amount)


## Wild species that live on this terrain (its encounter table) and aren't owned yet.
func wild_for(terrain: String) -> Array[String]:
	var out: Array[String] = []
	if stored.size() >= STORAGE_MAX:
		return out
	for id in Encounters.pool(terrain, crossing_no):
		if not roster.has(id) and not stored.has(id):
			out.append(id)
	if out.is_empty() and not Encounters.BIOMES.has(terrain):
		for id in Species.DATA:
			if Species.biome(id) == "" and Encounters.can_turn_up(id, crossing_no) and not roster.has(id) and not stored.has(id):
				out.append(id)
	return out


# ---------- trail moments ----------

func _roll_moment() -> void:
	var pool := TrailMoments.for_day(String(trip.get("terrain", "Forest")), weather)
	var weighted: Array = []
	for m in pool:
		if m.has("cap") and best_helper(m["cap"]) == "":
			continue
		if m.has("hauler") and haulers.is_empty():
			continue
		if m.has("need") and not can_afford({"coins": -int(m["need"].get("coins", 0))}):
			continue
		if m["id"] == "fever" and (fever_days > 0 or rations == "full"):
			continue
		for i in int(m["w"]):
			weighted.append(m)
	if weighted.is_empty():
		return
	var m: Dictionary = weighted[life_rng.randi_range(0, weighted.size() - 1)]
	trigger_moment(m)


## Make a moment happen now. Returns the record added to `moments`.
func trigger_moment(m: Dictionary) -> Dictionary:
	var who := ""
	if m.has("cap"):
		who = best_helper(m["cap"])
	elif m.has("hauler") and not haulers.is_empty():
		who = haulers[life_rng.randi_range(0, haulers.size() - 1)]
	var terrain := String(trip.get("terrain", "Forest"))
	var deltas := apply_fx(m["fx"], who, terrain)
	if m.has("cap") and who != "":
		gain_xp(who, TrailMoments.JOB_XP)
		deltas.append({"icon": "xp", "amount": TrailMoments.JOB_XP, "who": who})
	var rec := {"id": m["id"], "icon": m["icon"], "who": who, "deltas": deltas, "sight": m.get("sight", ""),
		"text": String(m["text"]).replace("{who}", "{c:%s}" % who if who != "" else "")}
	if m["id"] == "grave":
		var g: Array = TrailMoments.GRAVES[life_rng.randi_range(0, TrailMoments.GRAVES.size() - 1)]
		# Now and then it's one of yours, from a caravan that fell on this crossing before.
		var own := Graves.for_crossing(crossing_no)
		if not own.is_empty() and life_rng.randf() < Graves.OWN_CHANCE:
			g = Graves.as_stone(own[life_rng.randi_range(0, own.size() - 1)])
			rec["own"] = true
		rec["grave"] = g
	if m["id"] == "wild_watch":
		var met: Array = encountered.keys().filter(func(id): return Species.DATA.has(id) and not roster.has(id) and id != "hollowstag")
		met.sort()
		rec["wild"] = met[life_rng.randi_range(0, met.size() - 1)] if not met.is_empty() else ""
	moments.append(rec)
	journal.append(String(m["text"]).replace("{who}", Species.info(who)["name"] if who != "" else "Someone"))
	return rec


## Mark a species as met, here on the map.
func meet(species: String) -> void:
	encountered[species] = true
	if map == null:
		return
	var where: String = at
	if state == State.TRAVELLING and not trip.is_empty():
		where = String(trip["to"])
	var rid := String(map.junctions.get(where, {}).get("region", ""))
	if rid != "":
		var m: Dictionary = met_in.get(rid, {})
		m[species] = true
		met_in[rid] = m


## Mark every species in a pack as met.
func meet_pack(pack: Dictionary) -> void:
	for id in pack.get("front", []) + pack.get("back", []) + [pack.get("boss", "")]:
		if String(id) != "":
			meet(String(id))


# ---------- pace, rations, settlements ----------

func set_pace(id: String) -> void:
	if TrailLife.PACES.has(id):
		pace = id


func set_rations(id: String) -> void:
	if TrailLife.RATIONS.has(id):
		rations = id


## True while the caravan is still in the start town of a world crossing: the stall there is
## the outfitter (bigger stock, spare parts and curiosities, and you can sell things back).
func outfitting() -> bool:
	return map != null and not map.is_test and not departed and at == map.start and state == State.AT_JUNCTION


## This stop's stall: {good: {"price", "stock"}}.
func stall() -> Dictionary:
	if outfitting():
		var out := {}
		for g in Outfitter.STOCK:
			out[g] = {"price": int(Outfitter.STOCK[g][0]), "stock": int(Outfitter.STOCK[g][1])}
		return out
	var base: Dictionary = stop()["stall"]
	var bump: int = {"late": 1, "frost": 2}.get(season(), 0)
	if bump == 0:
		return base
	# Late in the season food and water cost more.
	var dear := base.duplicate(true)
	for g in ["food", "water"]:
		if dear.has(g):
			dear[g]["price"] = int(dear[g]["price"]) + bump
	return dear


func _stall_key() -> String:
	return "outfitter" if outfitting() else at


## How many of a good are left in this stop's stall.
func stock_left(good: String) -> int:
	var s := stall()
	if not s.has(good):
		return 0
	return int(s[good]["stock"]) - int(bought.get(_stall_key(), {}).get(good, 0))


## Why a good can't be bought right now ("" if it can): "stock", "coins", "room" or "have".
func buy_block(good: String) -> String:
	if Outfitter.is_curio(good) and has_curio(good):
		return "have"
	if state != State.AT_JUNCTION or stock_left(good) <= 0:
		return "stock"
	if coins < int(stall()[good]["price"]):
		return "coins"
	if Outfitter.weight_of(good) > free_space() + 0.001:
		return "room"
	return ""


func can_buy(good: String) -> bool:
	return buy_block(good) == ""


## Buy one lot of a good at this stop. Returns what changed, or [] if it can't.
func buy(good: String) -> Array:
	if not can_buy(good):
		return []
	var lot: Dictionary = stall()[good]
	coins -= int(lot["price"])
	var key := _stall_key()
	var b: Dictionary = bought.get(key, {})
	b[good] = int(b.get(good, 0)) + 1
	bought[key] = b
	var d: Array = [{"icon": "coins", "amount": -int(lot["price"])}]
	d.append_array(apply_fx(Settlements.goods_fx(good)))
	journal.append("Bought %s." % Settlements.good_name(good))
	return d


## How many lots of a good you could hand back to the outfitter (only before setting out).
func sellable(good: String) -> int:
	if not outfitting():
		return 0
	var n := int(bought.get("outfitter", {}).get(good, 0))
	match good:
		"food":
			n = mini(n, floori(provisions / 10.0 + 0.001))
		"water":
			n = mini(n, floori(water / 10.0 + 0.001))
		_:
			if good.begins_with("spare_"):
				n = mini(n, spare_count(good.trim_prefix("spare_")))
			elif Outfitter.is_curio(good):
				n = mini(n, 1 if has_curio(good) else 0)
			elif BattleItems.has(good):
				n = mini(n, item_free(good))
			else:
				n = 0
	return n


## Hand a lot back to the outfitter for a full refund. Returns what changed, or [].
func sell_back(good: String) -> Array:
	if sellable(good) <= 0:
		return []
	var price := int(Outfitter.STOCK[good][0])
	match good:
		"food":
			provisions -= 10.0
		"water":
			water -= 10.0
		_:
			if good.begins_with("spare_"):
				_add_spare(good.trim_prefix("spare_"), -1)
			elif Outfitter.is_curio(good):
				curios.erase(good)
			else:
				items[good] = item_count(good) - 1
				if int(items[good]) <= 0:
					items.erase(good)
	var b: Dictionary = bought["outfitter"]
	b[good] = int(b[good]) - 1
	coins += price
	return [{"icon": "coins", "amount": price}, {"icon": Settlements.good_icon(good), "amount": -1}]


## "Pack it for me": buy the shopkeeper's kit, in their order, while coins and room last.
## Returns how many lots were bought.
func pack_for_me() -> int:
	var n := 0
	for good in Outfitter.keeper(crossing_no)["kit"]:
		if not buy(good).is_empty():
			n += 1
	return n


# ---------- roadside barter ----------

## The river crossing on this road at a given depth.
func make_river(depth: int) -> Dictionary:
	var ferry := map != null and not trip.is_empty() and map.has_ferry(trip)
	var cold := weather == "cold" or season() == "frost"
	return Rivers.make(depth, ferry, cold, crossing_no)


## A traveller wants one thing you carry and offers something you're short of. Built from what
## the caravan has right now, so it is a different deal each time (or empty if nothing fits).
func make_barter() -> Dictionary:
	var wants: Array = []
	for k in Wagon.SPARES:
		if spare_count(k) > 0:
			wants.append({"cost": {"spare_" + k: -1}, "label": Wagon.SPARES[k]["name"]})
	if provisions >= 40.0:
		wants.append({"cost": {"food": -20}, "label": "20 food"})
	if water >= 30.0:
		wants.append({"cost": {"water": -15}, "label": "15 water"})
	for iid in items:
		if item_free(iid) > 0:
			wants.append({"cost": {"give_item": iid}, "label": BattleItems.item_name(iid)})
	if light_dust > 0:
		wants.append({"cost": {"light_dust": -1}, "label": "Light dust"})
	var offers: Array = []
	for k in Wagon.SPARES:
		if spare_count(k) == 0:
			offers.append({"fx": {"spare_" + k: 1}, "label": "a " + String(Wagon.SPARES[k]["name"])})
	if days_of(water, daily_water()) < 4.0:
		offers.append({"fx": {"water": 30}, "label": "30 water"})
	if days_of(provisions, daily_provisions()) < 5.0:
		offers.append({"fx": {"food": 35}, "label": "35 food"})
	if offers.is_empty():
		offers.append({"fx": {"coins": 18}, "label": "18 coins"})
		offers.append({"fx": {"technique": 1}, "label": "a technique scroll"})
	if wants.is_empty():
		return {}
	var w: Dictionary = wants[life_rng.randi_range(0, wants.size() - 1)]
	var o: Dictionary = offers[life_rng.randi_range(0, offers.size() - 1)]
	# Never trade a spare for the same spare, or food for food.
	for tries in 6:
		if not _same_goods(w["cost"], o["fx"]):
			break
		o = offers[life_rng.randi_range(0, offers.size() - 1)]
	if _same_goods(w["cost"], o["fx"]):
		return {}
	var e: Dictionary = TrailEvents.by_id("barter").duplicate(true)
	e["text"] = "A traveller eyes your wagon. They want your %s and offer %s." % [w["label"], o["label"]]
	var fx: Dictionary = o["fx"].duplicate()
	fx["text"] = "A handshake, and the swap is made."
	e["choices"] = [
		{"label": "Trade", "cost": w["cost"], "safe_paid": true, "success": fx},
		{"label": "Ride on", "success": {"text": "You keep what you have."}},
	]
	return e


static func _same_goods(cost: Dictionary, fx: Dictionary) -> bool:
	for k in cost:
		if fx.has(k):
			return true
	return false


# ---------- creatures and battle lineup ----------

func max_hp(id: String) -> float:
	return (CombatData.max_hp(id) + float(boosts.get(id, {}).get("hp", 0.0))) * Temperaments.factor(String(tempers.get(id, "")), "hp")


## A creature's current stat after level-up boosts ("atk", "def", "spd").
func stat(id: String, key: String) -> float:
	var base := float(CombatData.stats(id)[key])
	var b := float(boosts.get(id, {}).get(key, 0.0))
	var t := Temperaments.factor(String(tempers.get(id, "")), key)
	if key == "spd":
		return maxf(0.6, (base - b) * t)
	return maxf(1.0 if key == "atk" else 0.0, (base + b) * t)


## The move in use for "basic", "passive" or "ultimate".
func kit_move(id: String, slot: String) -> String:
	return String(kits.get(id, {}).get(slot, CombatData.stats(id)[slot]))


func kit_moves(id: String) -> Array[String]:
	return [kit_move(id, "basic"), kit_move(id, "passive"), kit_move(id, "ultimate")]


# ---------- levels ----------

## Add experience; every level gained queues a level-up choice. Returns levels gained.
func gain_xp(id: String, amount: int) -> int:
	var gained := 0
	xp[id] = int(xp.get(id, 0)) + amount
	while level(id) < Leveling.MAX_LEVEL and int(xp[id]) >= Leveling.xp_to_next(level(id)):
		xp[id] = int(xp[id]) - Leveling.xp_to_next(level(id))
		levels[id] = level(id) + 1
		gained += 1
		_queue_level_up(id, level(id))
		if level(id) == Species.evolve_level(id) and not Species.evolutions(id).is_empty():
			journal.append("%s is ready to evolve." % Species.info(id)["name"])
	if level(id) >= Leveling.MAX_LEVEL:
		xp[id] = 0
	return gained


func _queue_level_up(id: String, lv: int) -> void:
	var options: Array = []
	if Leveling.is_ability_level(lv):
		options = Leveling.ability_options(id, known.get(id, []), level_rng)
	if options.size() < 2:
		options = Leveling.stat_options(level_rng)
	pending_levels.append({"id": id, "level": lv, "options": options})


## Apply the player's pick for the oldest waiting level-up. For a move, keep_in_memory
## stores it in the slot's memory instead of using it now. Returns a line for the journal.
func choose_level_up(option: int, keep_in_memory := false) -> String:
	if pending_levels.is_empty():
		return ""
	var p: Dictionary = pending_levels.pop_front()
	var id: String = p["id"]
	var o: Dictionary = p["options"][option]
	var name: String = Species.info(id)["name"]
	if o["kind"] == "stat":
		var b: Dictionary = boosts.get(id, {})
		b[o["stat"]] = float(b.get(o["stat"], 0.0)) + float(o["amount"])
		boosts[id] = b
		if o["stat"] == "hp":
			creature_hp[id] = float(creature_hp.get(id, 0.0)) + float(o["amount"])
		return "%s grew: %s (%s)." % [name, Leveling.boost_text(o["stat"], o["amount"]), Leveling.RARITY_NAMES[o["rarity"]]]
	return _learn(id, String(o["move"]), keep_in_memory)


## Learn a move: into its slot (the old move drops into an empty memory slot, else it's
## forgotten) or into memory (replacing what was there).
func _learn(id: String, mid: String, keep_in_memory: bool) -> String:
	var name: String = Species.info(id)["name"]
	var slot: String = CombatData.move(mid)["slot"]
	var k: Array = known.get(id, [])
	if not k.has(mid):
		k.append(mid)
	known[id] = k
	var mem: Dictionary = memory.get(id, {})
	var new_name: String = CombatData.move(mid)["name"]
	if keep_in_memory:
		# Replaces whatever was in memory; the equipped move stays.
		var was := memory_move(id, slot)
		mem[slot] = mid
		memory[id] = mem
		if was != "":
			return "%s learned %s and put it in memory, forgetting %s." % [name, new_name, CombatData.move(was)["name"]]
		return "%s learned %s and put it in memory." % [name, new_name]
	# Replaces the equipped move. It drops into memory only if memory is empty; otherwise it's
	# forgotten and the memory move stays.
	var old := kit_move(id, slot)
	var kit: Dictionary = kits.get(id, {})
	kit[slot] = mid
	kits[id] = kit
	if memory_move(id, slot) == "":
		mem[slot] = old
		memory[id] = mem
		return "%s learned %s. %s moved to memory." % [name, new_name, CombatData.move(old)["name"]]
	return "%s learned %s, forgetting %s." % [name, new_name, CombatData.move(old)["name"]]


## Swap a slot's move with the one in its memory (between battles).
func swap_memory(id: String, slot: String) -> bool:
	var stored := memory_move(id, slot)
	if stored == "":
		return false
	var mem: Dictionary = memory.get(id, {})
	mem[slot] = kit_move(id, slot)
	memory[id] = mem
	var kit: Dictionary = kits.get(id, {})
	kit[slot] = stored
	kits[id] = kit
	return true


func pending_count() -> int:
	return pending_levels.size()


func conscious(id: String) -> bool:
	return float(creature_hp.get(id, 0.0)) > 0.0


func knocked_out() -> Array[String]:
	var out: Array[String] = []
	for id in roster:
		if not conscious(id):
			out.append(id)
	return out


## The move stored in a creature's memory slot for "basic", "passive" or "ultimate" ("" if empty).
func level(id: String) -> int:
	return int(levels.get(id, 1))


# ---------- evolution ----------

## What a tamed Trailomon could evolve into right now: it is at the level, and you don't
## already own that form. Evolving is always the player's choice.
func evolve_options(id: String) -> Array[String]:
	var out: Array[String] = []
	if not (roster.has(id) or stored.has(id)) or level(id) < Species.evolve_level(id):
		return out
	for to in Species.evolutions(id):
		if Species.DATA.has(to) and not roster.has(to) and not stored.has(to):
			out.append(to)
	return out


func can_evolve(id: String) -> bool:
	return not evolve_options(id).is_empty()


## Evolve a Trailomon into `to`. It keeps its level, experience, level-up boosts, learned
## moves, memory, dust and place in the team; it takes the new form's stats and kit (moves
## you swapped in yourself stay). Health keeps the same share of the new Max HP.
## Returns a line for the journal, or "" if it can't evolve.
func evolve(id: String, to: String) -> String:
	if not evolve_options(id).has(to):
		return ""
	var share := 1.0
	if creature_hp.has(id):
		share = clampf(float(creature_hp[id]) / maxf(1.0, max_hp(id)), 0.0, 1.0)
	for list in [roster, haulers, stored]:
		var i: int = list.find(id)
		if i >= 0:
			list[i] = to
	for d in [fatigue, levels, xp, kits, boosts, known, memory, dust_used, nicknames, tempers, quirks, glints]:
		if d.has(id):
			d[to] = d[id]
			d.erase(id)
	for cell in lineup:
		if lineup[cell] == id:
			lineup[cell] = to
	for p in pending_levels:
		if p["id"] == id:
			p["id"] = to
	if creature_hp.has(id):
		creature_hp.erase(id)
		creature_hp[to] = max_hp(to) * share
	if haulers.has(to) and not can_haul(to):
		haulers.erase(to)
	encountered[to] = true
	caught[to] = true
	var line := "%s evolved into %s!" % [Species.info(id)["name"], Species.info(to)["name"]]
	journal.append(line)
	return line


func memory_move(id: String, slot: String) -> String:
	return String(memory.get(id, {}).get(slot, ""))


func lineup_cell(id: String) -> Variant:
	for cell in lineup:
		if lineup[cell] == id:
			return cell
	return null


## Creatures in the roster but not in the lineup.
func bench() -> Array[String]:
	var out: Array[String] = []
	for id in roster:
		if lineup_cell(id) == null:
			out.append(id)
	return out


## Drop creatures that left the roster, and put unplaced ones in free cells
## (guards and bruisers in the front row first, everyone else in the second row first).
func tidy_lineup() -> void:
	for cell in lineup.keys():
		if not roster.has(lineup[cell]):
			lineup.erase(cell)
	for id in bench():
		if lineup.size() >= 6:
			break
		var role: String = CombatData.stats(id)["role"]
		var rows := [0, 1] if role in ["Guard", "Bruiser", "Striker"] else [1, 0]
		var placed := false
		for row in rows:
			for lane in [1, 0, 2]:
				if not placed and not lineup.has(Vector2i(row, lane)):
					lineup[Vector2i(row, lane)] = id
					placed = true


## Put a creature in a cell. Whoever stood there swaps into the creature's old cell
## (or goes to the bench if the creature came from the bench).
func place_in_lineup(id: String, cell: Vector2i) -> void:
	if not roster.has(id):
		return
	var old: Variant = lineup_cell(id)
	var other: String = lineup.get(cell, "")
	if old != null:
		lineup.erase(old)
	lineup[cell] = id
	if other != "" and other != id and old != null:
		lineup[old] = other


func remove_from_lineup(id: String) -> void:
	var cell: Variant = lineup_cell(id)
	if cell != null and lineup.size() > 1:
		lineup.erase(cell)


## Arrange the lineup automatically: guards front centre, healers and supports behind.
func auto_lineup() -> void:
	lineup.clear()
	var order := roster.duplicate()
	var rank := {"Guard": 0, "Bruiser": 1, "Striker": 2, "Support": 3, "Healer": 4}
	order.sort_custom(func(a, b): return rank.get(CombatData.stats(a)["role"], 5) < rank.get(CombatData.stats(b)["role"], 5))
	var cells := [Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 0), Vector2i(1, 1)]
	for i in mini(order.size(), cells.size()):
		lineup[cells[i]] = order[i]


# ---------- encounters ----------

## Choices for the pending encounter, like event choices: Fight, Slip past (scout check),
## and for wild packs a safe option of throwing them food.
const SLIP_DIFFICULTY := 8
const BRIBE_FOOD := 10

func encounter_choices() -> Array:
	if pending_encounter.is_empty():
		return []
	var out: Array = [{"id": "fight", "label": "Fight", "safe": false, "helper": "", "odds": {}}]
	if bool(pending_encounter["guardian"]):
		# The finale: fight, pay the long toll road around, or gamble on the rapids.
		out.append({"id": "toll", "label": "Take the toll road around", "safe": true, "helper": "", "odds": {},
			"cost": finale_toll(), "days": FINALE_TOLL_DAYS, "affordable": coins >= finale_toll()})
		var r := _rapids_check()
		out.append({"id": "rapids", "label": "Run the rapids", "safe": false, "helper": r["helper"], "odds": r["odds"], "assists": r["assists"]})
	else:
		var helper := best_helper("scout")
		var score := Species.capability(helper, "scout") * TrailEvents.RANK_SCORE if helper != "" else 0
		out.append({"id": "slip", "label": "Slip past quietly", "safe": false, "helper": helper,
			"odds": CheckOdds.for_scores(score, SLIP_DIFFICULTY)})
		out.append({"id": "bribe", "label": "Throw them food (%d food)" % BRIBE_FOOD, "safe": true, "helper": "", "odds": {}})
		if flares > 0:
			out.append({"id": "flare", "label": "Light a flare", "safe": true, "helper": "", "odds": {}})
	return out


## Resolve a non-fight choice. Returns {"outcome", "text", "fight": bool, "ambush": bool}.
## "fight" means the battle must still happen (ambush = they struck first).
func resolve_encounter(choice_id: String, roll := -1) -> Dictionary:
	if pending_encounter.is_empty():
		return {}
	match choice_id:
		"toll":
			var toll := finale_toll()
			if coins < toll:
				return {}
			coins -= toll
			pending_encounter = {}
			for i in FINALE_TOLL_DAYS:
				journal.append(spend_day(true))
			finale = "toll"
			var t := "You pay %d coins at the gate and take the long road around. Two slow days, but the guardian never sees you." % toll
			note("toll", "Paid the toll road around the guardian.")
			journal.append(t)
			return {"outcome": "success", "text": t, "fight": false, "ambush": false}
		"rapids":
			var r := _rapids_check()
			if roll < 0:
				roll = battle_rng.randi_range(0, 99)
			if r["helper"] != "":
				gain_xp(String(r["helper"]), int(TrailEvents.JOB_XP["success"]))
			if roll < int(r["odds"]["success"]):
				pending_encounter = {}
				finale = "rapids"
				var t := "The wagon shoots the rapids like a cork, right past the guardian. Whoops from everyone."
				note("rapids", "Ran the rapids past the guardian.")
				journal.append(t)
				return {"outcome": "success", "text": t, "fight": false, "ambush": false}
			if roll < int(r["odds"]["success"]) + int(r["odds"]["mixed"]):
				pending_encounter = {}
				finale = "rapids"
				apply_fx({"lose_cargo": 1, "food": -20, "wear": 10})
				var t := "Through, barely. A crate and a lot of food went over the side."
				note("rapids", "Ran the rapids, and lost a crate doing it.")
				journal.append(t)
				return {"outcome": "mixed", "text": t, "fight": false, "ambush": false}
			apply_fx({"lose_cargo": 1, "food": -25, "integrity": -12, "break": "canopy"})
			var t := "The wagon flips in the white water and washes up at the guardian's feet. It has seen you."
			note("rapids", "Wrecked in the rapids.")
			journal.append(t)
			return {"outcome": "failure", "text": t, "fight": true, "ambush": true}
		"flare":
			if flares <= 0:
				return {}
			flares -= 1
			pending_encounter = {}
			var t := "The flare goes up with a crack and a red glare. They scatter, and you drive on."
			journal.append(t)
			return {"outcome": "success", "text": t, "fight": false, "ambush": false}
		"bribe":
			provisions = maxf(0.0, provisions - BRIBE_FOOD)
			pending_encounter = {}
			var t := "They snatch the food and melt back into the wild."
			journal.append(t)
			return {"outcome": "success", "text": t, "fight": false, "ambush": false}
		"slip":
			var odds: Dictionary = encounter_choices()[1]["odds"]
			if roll < 0:
				roll = battle_rng.randi_range(0, 99)
			if roll < odds["success"]:
				pending_encounter = {}
				var t := "You lead the wagon around them without a sound."
				journal.append(t)
				return {"outcome": "success", "text": t, "fight": false, "ambush": false}
			if roll < odds["success"] + odds["mixed"]:
				pending_encounter = {}
				for id in haulers:
					fatigue[id] = minf(100.0, float(fatigue.get(id, 0.0)) + 15.0)
				var t := "You get past, but only after a long, tiring detour."
				journal.append(t)
				return {"outcome": "mixed", "text": t, "fight": false, "ambush": false}
			var t := "They spot you and charge before your team is ready!"
			journal.append(t)
			return {"outcome": "failure", "text": t, "fight": true, "ambush": true}
	return {"outcome": "success", "text": "", "fight": true, "ambush": false}


const FINALE_TOLL_DAYS := 2
const RAPIDS_DIFFICULTY := 9


## The toll road around the guardian: steep, and steeper each crossing.
func finale_toll() -> int:
	return 30 + 6 * crossing_no


## Running the rapids: a Float check, with Steady and Scout assists, harder each crossing.
func _rapids_check() -> Dictionary:
	var helper := best_helper("float")
	var score := job_rank(helper, "float") * TrailEvents.RANK_SCORE if helper != "" else 0
	var assists: Array = []
	for cap in ["steady", "scout"]:
		var a := best_helper(cap, [helper] + assists.map(func(x): return x["who"]))
		if a != "" and job_rank(a, cap) >= Rivers.ASSIST_RANK:
			assists.append({"who": a, "cap": cap, "bonus": 2})
			score += 2
	if has_upgrade("float_tanks"):
		score += Inventor.FLOAT_BONUS
	return {"helper": helper, "assists": assists, "gear": "float_tanks" if has_upgrade("float_tanks") else "", "odds": CheckOdds.for_scores(score, RAPIDS_DIFFICULTY + crossing_no / 3)}


## Can anyone fight right now?
func can_fight() -> bool:
	for cell in lineup:
		if conscious(lineup[cell]):
			return true
	return false


## Build the battle for the pending encounter from the lineup, health and fatigue.
func make_battle(ambush := false, rng_seed := -1) -> Battle:
	var pack: Dictionary = pending_encounter.get("pack", CombatData.PACKS[0])
	meet_pack(pack)
	var opts := {"ambush": ambush and not is_hunt(), "hunt": is_hunt()}
	opts["seed"] = rng_seed if rng_seed >= 0 else battle_rng.randi()
	# Battle items are kept for real fights.
	opts["items"] = [] if is_hunt() else slotted_items()
	return Battle.create(
		{"slots": lineup.duplicate(), "hp": creature_hp.duplicate(), "fatigue": fatigue.duplicate(),
			"kits": kits.duplicate(true), "boosts": boosts.duplicate(true), "tempers": tempers.duplicate()},
		{"front": pack["front"], "back": pack["back"], "boss": pack.get("boss", ""), "scale": enemy_scale()},
		opts)


## How strong the pending foes are: the route's risk, plus a little for every level your
## lineup has gained, so a levelled team still gets a real fight.
func enemy_scale() -> float:
	var base := float(pending_encounter.get("scale", 1.0))
	var total := 0
	var n := 0
	for cell in lineup:
		total += level(lineup[cell])
		n += 1
	var avg := float(total) / maxf(1.0, float(n))
	return base * crossing_factor() * (1.0 + LEVEL_SCALE * maxf(0.0, avg - 1.0)) * small_team_factor()


## A caravan that set out with a lone starter meets weaker foes while it builds its team: the
## smaller the team, the weaker. The help fades over the first crossings and is gone by
## crossing FRESH_FADE_CROSSINGS + 1, where the full-strength balance takes over.
func small_team_factor() -> float:
	if not fresh_start:
		return 1.0
	var f := float(SMALL_TEAM_SCALE.get(roster.size(), 1.0))
	var fade := clampf(float(crossing_no - 1) / float(FRESH_FADE_CROSSINGS), 0.0, 1.0)
	return lerpf(f, 1.0, fade)


const LEVEL_SCALE := 0.015
## Foe strength by team size (see small_team_factor). Tuned with tools/sim/starter_sim.gd.
const SMALL_TEAM_SCALE := {1: 0.55, 2: 0.58, 3: 0.62, 4: 0.66, 5: 0.7, 6: 0.75}
const FRESH_FADE_CROSSINGS := 4

## What a battle defeat costs (breach): wagon integrity and a share of food and water.
const BREACH_INTEGRITY := 15
const BREACH_SUPPLY_SHARE := 0.1
const RETREAT_FOOD := 5.0
const RETREAT_WEAR := 8.0
const VICTORY_FOOD := 6.0
const VICTORY_WATER := 4.0
const VICTORY_COINS := 5
const ITEM_DROP_CHANCE := 0.5
const TECHNIQUE_DROP_CHANCE := 0.2
const STORAGE_MAX := 9
## Trailomon travelling in the team (the lineup has 6 cells).
const TEAM_MAX := 6
## Odds of catching a worn-out wild Trailomon after a win, by rarity; a lure adds LURE_BONUS.
const CATCH_CHANCE := {"common": 0.65, "rare": 0.4, "legendary": 0.15}
const LURE_BONUS := 0.2
## Odds that a wild pack has one glinting Trailomon in it.
const GLINT_CHANCE := 1.0 / 48.0

## Apply a finished battle (or null when nobody could fight). Returns lines describing the aftermath.
func finish_battle(battle: Battle) -> Array[String]:
	if is_hunt():
		return _finish_hunt(battle)
	var lines: Array[String] = []
	var outcome := Battle.Outcome.DEFEAT if battle == null else battle.outcome
	if battle != null:
		var hp := battle.player_hp()
		for id in hp:
			creature_hp[id] = float(hp[id])
	var guardian := bool(pending_encounter.get("guardian", false))
	var battle_scale := float(pending_encounter.get("scale", 1.0))
	var pack: Dictionary = pending_encounter.get("pack", {})
	var bounty := int(pending_encounter.get("bounty", 0))
	var from_event := bool(pending_encounter.get("from_event", false))
	var spar := String(pack.get("id", "")).begins_with("trainer_")
	var prize := String(pending_encounter.get("prize", ""))
	var lair := String(pending_encounter.get("lair", ""))
	var giant := bool(pending_encounter.get("giant", false))
	var deep := bool(pending_encounter.get("deep", false))
	var glint := String(pending_encounter.get("glint", ""))
	var rival := bool(pending_encounter.get("rival", false))
	if rival:
		rival_record[("wins" if outcome == Battle.Outcome.VICTORY else "losses")] = int(rival_record.get("wins" if outcome == Battle.Outcome.VICTORY else "losses", 0)) + 1
	catch_bonus = float(pending_encounter.get("catch_bonus", 0.0)) + (Obstacles.DEEP_CATCH if deep else 0.0)
	pending_encounter = {}
	pending_recruit = ""
	pending_glint = false
	match outcome:
		Battle.Outcome.VICTORY:
			provisions += VICTORY_FOOD
			water += VICTORY_WATER
			if guardian:
				finale = "fight"
				note("ultimate", "Beat %s." % String(pack.get("title", "the guardian")))
			lines.append("Victory! %s" % (("%s falls back and the road to %s is clear." % [String(pack.get("title", "The guardian")), map.name_of(map.goal)]) if guardian else ("Rook groans and hands over the purse." if rival else "The pack scatters.")))
			var gid := String(pack.get("id", ""))
			if guardian and gid != "" and not seals.has(gid):
				seals.append(gid)
				lines.append("{i:seal_%s} You earn the %s." % [gid, seal_name(gid)])
			lines.append("You gather what they left behind: +%d food, +%d water." % [VICTORY_FOOD, VICTORY_WATER])
			change_morale(Camp.ON["win"] * (2 if guardian else 1))
			if battle != null:
				quirk_moment("win", battle.side_fighters(Formation.Side.PLAYER).map(func(f): return f.species))
			coins += VICTORY_COINS + bounty
			lines.append("+%d {i:coins} coins." % (VICTORY_COINS + bounty))
		Battle.Outcome.RETREAT, Battle.Outcome.WITHDRAW:
			provisions = maxf(0.0, provisions - RETREAT_FOOD)
			wagon.wear = minf(100.0, wagon.wear + RETREAT_WEAR)
			lines.append("Both sides are exhausted and pull back." if outcome == Battle.Outcome.WITHDRAW else "You pull the team back and the wagon rattles away.")
			lines.append("The scramble costs %d food and %d wagon wear." % [RETREAT_FOOD, RETREAT_WEAR])
		_ when rival:
			lines.append("Rook pockets your bet. \"Better luck next crossing!\"")
		_ when spar:
			lines.append("The trainer wins this one, grins, and moves on. No harm done.")
		_:
			var food := roundf(provisions * BREACH_SUPPLY_SHARE)
			var drink := roundf(water * BREACH_SUPPLY_SHARE)
			provisions -= food
			water -= drink
			wagon.integrity = maxi(0, wagon.integrity - BREACH_INTEGRITY)
			lines.append("Defeat. They break through to the wagon.")
			change_morale(Camp.ON["lose"], "A bitter defeat")
			if battle != null:
				quirk_moment("lose", battle.side_fighters(Formation.Side.PLAYER).map(func(f): return f.species))
			lines.append("The wagon takes a beating (-%d%% integrity) and they make off with %d food and %d water." % [BREACH_INTEGRITY, food, drink])
	# Battle items in the slots are used up; loot after a win.
	if battle != null and not battle.items_used.is_empty():
		var used: Array[String] = []
		for id in battle.items_used:
			used.append(BattleItems.item_name(id))
		_spend_items(battle.items_used)
		lines.append("Used up: %s." % ", ".join(used))
	if outcome == Battle.Outcome.VICTORY:
		var found: Array[String] = []
		for i in (2 if guardian else 1):
			if battle_rng.randf() < (1.0 if guardian else ITEM_DROP_CHANCE):
				var id: String = BattleItems.ITEMS.keys()[battle_rng.randi_range(0, BattleItems.ITEMS.size() - 1)]
				items[id] = int(items.get(id, 0)) + 1
				found.append(BattleItems.item_name(id))
		if not found.is_empty():
			lines.append("Found a battle item: %s." % ", ".join(found))
		if giant and not trip.is_empty():
			obstacles.erase(Obstacles.key(String(trip["from"]), String(trip["to"])))
		if lair != "" and lairs.has(lair):
			lairs[lair]["done"] = true
			note("lair", "Beat the legendary %s in its lair." % Species.info(prize)["name"])
		var wild: Array[String] = recruit_candidates(pack)
		if glint != "" and wild.has(glint) and prize == "":
			pending_recruit = glint
			pending_glint = true
			lines.append("The glinting %s stays behind, shimmering. Try to catch it (%d%%)." % [Species.info(glint)["name"], roundi(catch_chance(glint) * 100.0)])
		elif prize != "" and wild.has(prize):
			pending_recruit = prize
			lines.append("The %s is spent and still. Try to catch it (%d%%)." % [Species.info(prize)["name"], roundi(catch_chance(prize) * 100.0)])
		elif not wild.is_empty() and not from_event:
			# The deep wilds: the rarest of the pack is the one that stays behind.
			pending_recruit = _rarest(wild) if deep else Species.pick_weighted(wild, battle_rng)
			lines.append("A worn-out wild %s is still here. Try to catch it (%d%%)." % [Species.info(pending_recruit)["name"], roundi(catch_chance(pending_recruit) * 100.0)])
		var bonus := biome_dust_bonus()
		var light := (Dust.GUARDIAN_LIGHT if guardian else Dust.WIN_LIGHT) + int(bonus["light"])
		var dark := (Dust.GUARDIAN_DARK if guardian else (1 if battle_scale >= Dust.STRONG_SCALE else 0)) + int(bonus["dark"])
		light_dust += light
		dark_dust += dark
		lines.append("Gathered dust: +%d {i:light_dust} Light%s." % [light, "" if dark == 0 else ", +%d {i:dark_dust} Dark" % dark])
		if battle_rng.randf() < (1.0 if guardian else TECHNIQUE_DROP_CHANCE):
			var all: Array = MovePool.technique_ids()
			var mid: String = all[battle_rng.randi_range(0, all.size() - 1)]
			techniques[mid] = int(techniques.get(mid, 0)) + 1
			lines.append("Found a technique: %s." % CombatData.move(mid)["name"])
	# Experience for everyone who stood in the lineup.
	if battle != null:
		var award := Leveling.XP_LOSS
		match outcome:
			Battle.Outcome.VICTORY: award = Leveling.XP_GUARDIAN if guardian else Leveling.XP_WIN
			Battle.Outcome.RETREAT, Battle.Outcome.WITHDRAW: award = Leveling.XP_RETREAT
		var grew: Array[String] = []
		for f in battle.side_fighters(Formation.Side.PLAYER):
			if gain_xp(f.species, award) > 0:
				grew.append("%s (Lv %d)" % [Species.info(f.species)["name"], level(f.species)])
		lines.append("Everyone who fought gains %d experience." % award)
		if not grew.is_empty():
			lines.append("Level up! %s. Choose their upgrades from the Companions screen." % ", ".join(grew))
	var down := knocked_out()
	if not down.is_empty():
		var names: Array[String] = []
		for id in down:
			names.append(Species.info(id)["name"])
		lines.append("Knocked out: %s. Rest a day to get them back on their feet." % ", ".join(names))
	for l in lines:
		journal.append(l)
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon was torn apart in battle."
	elif giant and outcome != Battle.Outcome.VICTORY and state == State.TRAVELLING:
		var t := "You stagger away and take the long way round. It goes back to sleep."
		lines.append(t)
		journal.append(t)
		apply_fx({"days": Obstacles.DETOUR_DAYS})
	elif guardian and outcome != Battle.Outcome.VICTORY and not trip.is_empty():
		lines.append(_turned_back())
		journal.append(lines[-1])
	return lines


## The guardian still holds the road: the wagon falls back to the stop it came from, and the
## guardian waits there for the next try. Rest, regroup and come back stronger.
func _turned_back() -> String:
	var from := String(trip.get("from", at))
	guardian_faced = false
	trip = {}
	trip_days_left = 0.0
	carry = 0.0
	state = State.AT_JUNCTION
	if from != "":
		at = from
	return "%s still holds the road. Your caravan falls back to %s to regroup." % [String(guardian_pack().get("title", "The guardian")), map.name_of(at)]


# ---------- battle items ----------

func item_count(id: String) -> int:
	return int(items.get(id, 0))


## How many of an item are left after the ones already in slots.
func item_free(id: String) -> int:
	return item_count(id) - item_slots.count(id)


## Put an item in a slot ("" clears it). Returns false if none are free.
func set_item_slot(slot: int, id: String) -> bool:
	if slot < 0 or slot >= BattleItems.SLOTS:
		return false
	if id != "" and (not BattleItems.has(id) or (item_slots[slot] != id and item_free(id) <= 0)):
		return false
	item_slots[slot] = id
	return true


func slotted_items() -> Array[String]:
	var out: Array[String] = []
	for id in item_slots:
		if id != "" and item_count(id) > 0:
			out.append(id)
	return out


## Take used items out of the bag. A slot keeps its item while there are more of it.
func _spend_items(used: Array[String]) -> void:
	for id in used:
		items[id] = maxi(0, item_count(id) - 1)
		if items[id] == 0:
			items.erase(id)
	for i in item_slots.size():
		var id := item_slots[i]
		if id != "" and item_slots.slice(0, i + 1).count(id) > item_count(id):
			item_slots[i] = ""


# ---------- techniques ----------

func technique_count(mid: String) -> int:
	return int(techniques.get(mid, 0))


## Can this Trailomon learn the technique? Same habitat as the move's species, and it doesn't
## already have the move equipped or in memory.
func can_learn_technique(id: String, mid: String) -> bool:
	if not MovePool.has(mid) or not Species.DATA.has(id):
		return false
	var owner := MovePool.owner_of(mid)
	if owner != id and Species.info(owner)["type"] != Species.info(id)["type"]:
		return false
	var slot: String = CombatData.move(mid)["slot"]
	return kit_move(id, slot) != mid and memory_move(id, slot) != mid


## Teach a technique (used up). Returns a journal line, or "" if it can't.
func use_technique(id: String, mid: String, to_memory: bool) -> String:
	if technique_count(mid) <= 0 or not can_learn_technique(id, mid):
		return ""
	techniques[mid] = technique_count(mid) - 1
	if techniques[mid] == 0:
		techniques.erase(mid)
	return _learn(id, mid, to_memory)


# ---------- recruiting and storage ----------

## Species from a beaten pack that could join: not the boss, not one you already have.
func recruit_candidates(pack: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if not has_room():
		return out
	for id in pack.get("front", []) + pack.get("back", []):
		var sid := String(id)
		if sid != "" and Species.DATA.has(sid) and not roster.has(sid) and not stored.has(sid) and not out.has(sid):
			out.append(sid)
	return out


## Take in the creature that offered to join. It joins the team while the team has fewer than
## TEAM_MAX, otherwise it goes to storage. Either way it arrives rested and healthy.
func recruit() -> String:
	if pending_recruit == "" or not has_room():
		return ""
	var id := pending_recruit
	pending_recruit = ""
	fatigue[id] = 0.0
	# Newcomers have lived in the wild too: they join a little below your team's level, with
	# their level-up choices waiting for you.
	var join := recruit_level()
	while level(id) < join:
		gain_xp(id, Leveling.xp_to_next(level(id)) - int(xp.get(id, 0)))
	var at_lv := " at Lv %d" % join if join > 1 else ""
	var line := ""
	if roster.size() < TEAM_MAX:
		roster.append(id)
		tidy_lineup()
		if can_haul(id) and haulers.size() < 2:
			haulers.append(id)
		line = "%s joined your team%s." % [Species.info(id)["name"], at_lv]
	else:
		stored.append(id)
		line = "%s joined you%s. It waits in storage until you swap it into the team." % [Species.info(id)["name"], at_lv]
	if not tempers.has(id):
		tempers[id] = Temperaments.roll(life_rng)
	if not quirks.has(id):
		quirks[id] = Personalities.roll(life_rng)
	creature_hp[id] = max_hp(id)
	encountered[id] = true
	caught[id] = true
	if pending_glint:
		glints[id] = true
		line += " It glints!"
	pending_glint = false
	journal.append(line)
	note("starter", "%s joined the caravan." % Species.info(id)["name"])
	return line


## The level a recruit joins at: two below the team's average.
func recruit_level() -> int:
	var total := 0
	for id in roster:
		total += level(id)
	return maxi(1, roundi(float(total) / maxf(1.0, float(roster.size()))) - 2)


## Room for one more Trailomon, in the team or in storage.
func has_room() -> bool:
	return roster.size() < TEAM_MAX or stored.size() < STORAGE_MAX


## The odds of catching a worn-out wild Trailomon, with a lure if you carry one.
func catch_chance(id: String) -> float:
	var base := float(CATCH_CHANCE.get(Species.rarity(id), 0.5))
	return minf(0.95, base + (LURE_BONUS if lures > 0 else 0.0) + catch_bonus)


## Field guide: has this species been met, and has the caravan ever had it?
func has_met(id: String) -> bool:
	return encountered.has(id) or has_caught(id)


func has_caught(id: String) -> bool:
	return caught.has(id) or roster.has(id) or stored.has(id)


## Region names where a species was met, for its field guide page.
func met_where(id: String) -> Array[String]:
	var out: Array[String] = []
	if map == null:
		return out
	for rid in met_in:
		if met_in[rid].has(id) and map.regions.has(rid):
			var n := String(map.regions[rid]["name"])
			if not out.has(n):
				out.append(n)
	out.sort()
	return out


## A wild pack's glinting member, if it has one ("" mostly).
func _roll_glint(pack: Dictionary) -> String:
	if life_rng.randf() >= GLINT_CHANCE:
		return ""
	var ids: Array[String] = []
	for id in pack.get("front", []) + pack.get("back", []):
		if String(id) != "":
			ids.append(String(id))
	return ids[life_rng.randi_range(0, ids.size() - 1)] if not ids.is_empty() else ""


## The Trailomon walking beside the wagon: the one picked as lead if it's in the team and not
## in harness, else the first free one ("" if everyone is hauling).
func lead_companion() -> String:
	if lead != "" and roster.has(lead) and not haulers.has(lead):
		return lead
	for id in roster:
		if not haulers.has(id):
			return id
	return ""


## The rarest of a few species (first one on a tie).
static func _rarest(ids: Array[String]) -> String:
	var best := ids[0]
	for id in ids:
		if int(Species.RARITIES[Species.rarity(id)]["weight"]) < int(Species.RARITIES[Species.rarity(best)]["weight"]):
			best = id
	return best


## Try to catch the pending wild Trailomon: one try, a lure is used up if you carry one.
## Returns {"caught": bool, "line": String}. A miss means it slips away for good.
func try_catch() -> Dictionary:
	if pending_recruit == "" or not has_room():
		return {"caught": false, "line": ""}
	var id := pending_recruit
	var chance := catch_chance(id)
	var lured := lures > 0
	if lured:
		lures -= 1
	if battle_rng.randf() < chance:
		var line := recruit()
		change_morale(Camp.ON["catch"])
		return {"caught": true, "line": ("The lure works. " if lured else "") + "Caught! " + line}
	pending_recruit = ""
	pending_glint = false
	var miss := "%s breaks free and slips into the brush." % Species.info(id)["name"]
	journal.append(miss)
	return {"caught": false, "line": miss}


## Swap a stored creature with one travelling in the team. The stored one takes its place in
## the team and the lineup; the other goes to storage.
func swap_stored(stored_id: String, team_id: String) -> bool:
	var si := stored.find(stored_id)
	var ri := roster.find(team_id)
	if si < 0 or ri < 0:
		return false
	stored[si] = team_id
	roster[ri] = stored_id
	var cell: Variant = lineup_cell(team_id)
	if cell != null:
		lineup[cell] = stored_id
	haulers.erase(team_id)
	if not fatigue.has(stored_id):
		fatigue[stored_id] = 0.0
	if not creature_hp.has(stored_id):
		creature_hp[stored_id] = max_hp(stored_id)
	return true


# ---------- dust ----------

## Extra dust from a win in a dust biome: Dark in the Blight, Light in the Glow.
func biome_dust_bonus() -> Dictionary:
	var t := String(trip.get("terrain", "")) if not trip.is_empty() else ""
	return {"light": 1 if t == WorldMap.GLOW else 0, "dark": 1 if t == WorldMap.BLIGHT else 0}


func dust_left(id: String) -> int:
	return Dust.CAP - int(dust_used.get(id, 0))


func dust_count(kind: String) -> int:
	return dark_dust if kind == "dark" else light_dust


## Use one Light or Dark dust on a stat. Returns a journal line, or "" if it can't.
func use_dust(id: String, kind: String, stat: String) -> String:
	if dust_count(kind) <= 0 or dust_left(id) <= 0 or not Leveling.STATS.has(stat):
		return ""
	var o := Dust.offer(kind, stat, id)
	var b: Dictionary = boosts.get(id, {})
	b[stat] = float(b.get(stat, 0.0)) + float(o["amount"])
	if float(o["cost"]) > 0.0:
		b[o["cost_stat"]] = float(b.get(o["cost_stat"], 0.0)) - float(o["cost"])
	boosts[id] = b
	if stat == "hp":
		creature_hp[id] = float(creature_hp.get(id, 0.0)) + float(o["amount"])
	creature_hp[id] = minf(float(creature_hp.get(id, 0.0)), max_hp(id))
	if kind == "dark":
		dark_dust -= 1
	else:
		light_dust -= 1
	dust_used[id] = int(dust_used.get(id, 0)) + 1
	return "%s took %s dust: %s." % [Species.info(id)["name"], "Dark" if kind == "dark" else "Light", Dust.offer_text(o)]


## Fight the pending encounter instantly (used by travel() and tests).
func auto_fight() -> Array[String]:
	if not can_fight():
		return finish_battle(null)
	var b := make_battle()
	b.run_to_end()
	return finish_battle(b)


# ---------- names, seals and the town healer ----------

const NICKNAME_MAX := 14


## The name to show for one of your Trailomon: its nickname, or its species name.
func display_name(id: String) -> String:
	var n := String(nicknames.get(id, ""))
	return n if n != "" else String(Species.info(id)["name"])


## Give a Trailomon a name (trimmed, at most NICKNAME_MAX letters). An empty name clears it.
func rename(id: String, name: String) -> void:
	var n := name.strip_edges().left(NICKNAME_MAX)
	if n == "" or n == String(Species.info(id)["name"]):
		nicknames.erase(id)
	else:
		nicknames[id] = n


## When a Trailomon evolves its nickname comes along.
func carry_nickname(from_id: String, to_id: String) -> void:
	if nicknames.has(from_id):
		nicknames[to_id] = nicknames[from_id]
		nicknames.erase(from_id)


## The seal a guardian gives: "Seal of the Hollow Stag".
static func seal_name(guardian_id: String) -> String:
	var title := String(CombatData.pack_by_id(guardian_id).get("title", guardian_id.capitalize()))
	if title.begins_with("The "):
		title = "the " + title.substr(4)
	return "Seal of " + title


## Stop kinds with a healer, and what a visit costs.
const HEALER_KINDS := ["town", "village", "stilts", "sanctum"]
const HEAL_COST_HURT := 3
const HEAL_COST_KO := 6


## Whether this stop has a healer who hasn't seen you yet this crossing.
func has_healer() -> bool:
	return state == State.AT_JUNCTION and HEALER_KINDS.has(String(stop().get("kind", ""))) and not healed_at.has(at)


## Coins for a full heal of the team (0 when nobody needs it).
func heal_cost() -> int:
	var cost := 0
	for id in roster:
		var hp := float(creature_hp.get(id, 0.0))
		if hp <= 0.0:
			cost += HEAL_COST_KO
		elif hp < max_hp(id) - 0.5:
			cost += HEAL_COST_HURT
	return cost


## Pay the healer: the whole team back to full health, knocked out ones awake, no day spent.
## Once per stop each crossing.
func visit_healer() -> String:
	var cost := heal_cost()
	if not has_healer() or cost <= 0 or coins < cost:
		return ""
	coins -= cost
	healed_at.append(at)
	for id in roster:
		creature_hp[id] = max_hp(id)
	var line := "The healer looks the team over and sends everyone off fresh (-%d coins)." % cost
	journal.append(line)
	return line


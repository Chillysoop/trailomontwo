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
var at := TestRoute.START
var state := State.AT_JUNCTION
var fail_reason := ""
var humans := 1
var health := 100
var provisions := 80.0
var water := 40.0
var roster: Array[String] = []
var haulers: Array[String] = []
var wagon := Wagon.new()
var repair_kits := 2
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


static func new_default(rng_seed := -1) -> Expedition:
	var e := Expedition.new()
	if rng_seed >= 0:
		e.rng.seed = rng_seed
		e.battle_rng.seed = rng_seed + 7919
		e.level_rng.seed = rng_seed + 104729
	else:
		e.rng.randomize()
		e.battle_rng.randomize()
		e.level_rng.randomize()
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
	for id in e.roster:
		e.fatigue[id] = 0.0
		e.creature_hp[id] = e.max_hp(id)
	e.tidy_lineup()
	e.visited = [TestRoute.START]
	return e


func daily_provisions() -> float:
	var total := HUMAN_PROVISIONS * humans
	for id in roster:
		total += Species.upkeep(id)
	return total


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
	return float(Species.info(id)["hauling"]) * (1.0 - float(fatigue.get(id, 0.0)) / 200.0)


func cargo_weight() -> float:
	var w := 0.0
	for c in cargo:
		w += float(c["weight"])
	return w


func hauling_available() -> float:
	var strengths: Array = []
	for id in haulers:
		if conscious(id):
			strengths.append(hauler_strength(id))
	var total := Hauling.available(strengths)
	return total * (Wagon.HARNESS_PENALTY if wagon.broken == Wagon.Part.HARNESS else 1.0)


## How many days the current food or water lasts.
func days_of(supply: float, per_day: float) -> float:
	return supply / per_day if per_day > 0.0 else INF


## Everything the route card shows for one segment, before committing.
func forecast(seg: Dictionary) -> Dictionary:
	var demand := Hauling.demand(Wagon.EMPTY_MASS, cargo_weight(), float(seg["terrain_factor"]))
	var available := hauling_available()
	var result := Hauling.evaluate(demand, available)
	var days: int = seg["days"]
	var pushing := result == Hauling.Result.PUSH
	if pushing:
		days = ceili(days * PUSH_SLOWDOWN)
	var wear_added := Wagon.wear_per_day(float(seg["terrain_factor"]), cargo_weight(), pushing) * days
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
		"can_go": result != Hauling.Result.BLOCKED and state == State.AT_JUNCTION and wagon.broken != Wagon.Part.RUNNING_GEAR and not haulers.is_empty() and available > 0.0,
	}


func exits() -> Array[Dictionary]:
	return TestRoute.exits(at)


## Travel one day along a segment. Returns a line for the log.
func spend_day() -> String:
	day += 1
	var notes: Array[String] = []
	var need_food := daily_provisions()
	var need_water := daily_water()
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
	if health <= 0:
		health = 0
		state = State.FAILED
		fail_reason = "Your traveller ran out of food and water."
	return "Day %d%s" % [day, (": " + ", ".join(notes)) if notes.size() > 0 else ""]


var trip := {}
var trip_days_left := 0
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
	trip = seg
	trip["pushing"] = f["hauling"] == Hauling.Result.PUSH
	trip_days_left = f["days"]
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
	if trip_days_left <= 0:
		return _arrive()
	journal.append(spend_day())
	if state == State.FAILED:
		return false
	_wear_day(float(trip["terrain_factor"]), trip["pushing"])
	if state == State.FAILED:
		return false
	if events_enabled and not _trip_had_event and rng.randf() < TrailEvents.daily_chance(int(trip["risk"])):
		var options := TrailEvents.for_segment(trip)
		if not options.is_empty():
			pending_event = options[rng.randi_range(0, options.size() - 1)]
			_trip_had_event = true
			journal.append(pending_event["title"] + "!")
	if pending_event.is_empty() and events_enabled and not _trip_had_battle and battle_rng.randf() < BATTLE_CHANCE + BATTLE_RISK_CHANCE * int(trip["risk"]):
		var packs := CombatData.packs_for(trip)
		if not packs.is_empty():
			var pack: Dictionary = packs[battle_rng.randi_range(0, packs.size() - 1)]
			pending_encounter = {"pack": pack, "scale": float(CombatData.RISK_SCALE.get(int(trip["risk"]), 1.0)), "guardian": false}
			_trip_had_battle = true
			journal.append(pack["title"] + "!")
	for id in roster:
		if conscious(id):
			creature_hp[id] = minf(max_hp(id), float(creature_hp[id]) + max_hp(id) * TRAVEL_HEAL)
	trip_days_left -= 1
	if trip_days_left > 0 or not pending_event.is_empty() or not pending_encounter.is_empty():
		return true
	if trip["to"] == TestRoute.GOAL and guardian_enabled and not guardian_faced:
		guardian_faced = true
		pending_encounter = {"pack": CombatData.GUARDIAN, "scale": CombatData.GUARDIAN_SCALE, "guardian": true}
		journal.append(CombatData.GUARDIAN["title"] + " blocks the way!")
		return true
	return _arrive()


func _arrive() -> bool:
	at = trip["to"]
	visited.append(at)
	journal.append("Reached %s." % TestRoute.junction_name(at))
	state = State.ARRIVED if at == TestRoute.GOAL else State.AT_JUNCTION
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
	return true


## Index of the event's no-roll choice.
func safe_choice(event: Dictionary) -> int:
	var choices: Array = event["choices"]
	for i in choices.size():
		if not choices[i].has("cap"):
			return i
	return 0


## Wagon wear, hauler fatigue and a possible breakdown for one travel day.
func _wear_day(terrain_factor: float, pushing: bool) -> void:
	for id in haulers:
		fatigue[id] = minf(100.0, float(fatigue.get(id, 0.0)) + HAUL_FATIGUE * (2.0 if pushing else 1.0))
	var chance := Wagon.breakdown_chance(wagon.wear)
	wagon.wear = minf(100.0, wagon.wear + Wagon.wear_per_day(terrain_factor, cargo_weight(), pushing))
	if wagon.broken == Wagon.Part.NONE and rng.randf() < chance:
		var parts := [Wagon.Part.RUNNING_GEAR, Wagon.Part.HARNESS, Wagon.Part.CANOPY]
		wagon.break_part(parts[rng.randi_range(0, parts.size() - 1)])
		journal.append("The wagon's %s broke!" % wagon.part_name())
		if wagon.broken == Wagon.Part.RUNNING_GEAR:
			trip_days_left += 1
			journal.append("Limping on a broken axle: one more day to the next stop.")
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon fell apart on the trail."


# ---------- actions at a junction ----------

## Rest a day: costs a day of food and water, haulers recover.
func rest() -> void:
	if state != State.AT_JUNCTION:
		return
	journal.append(spend_day())
	for id in fatigue:
		fatigue[id] = maxf(0.0, float(fatigue[id]) - REST_RECOVERY)
	var woke := 0
	for id in roster:
		if not conscious(id):
			woke += 1
		creature_hp[id] = minf(max_hp(id), float(creature_hp.get(id, 0.0)) + max_hp(id) * REST_HEAL)
	if state != State.FAILED:
		journal.append("Rested. The haulers recovered and the team licked its wounds%s." % ((", %d back on their feet" % woke) if woke > 0 else ""))


## Repair the wagon: one day with a repair kit, or two days patching without one (costs integrity).
func repair() -> void:
	if state != State.AT_JUNCTION:
		return
	var kit := repair_kits > 0
	var days := 1 if kit else 2
	for i in days:
		journal.append(spend_day())
		if state == State.FAILED:
			return
	if kit:
		repair_kits -= 1
	wagon.repair(kit)
	journal.append("Repaired the wagon%s." % ("" if kit else " with whatever was at hand"))
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon fell apart during repairs."


func drop_cargo(index: int) -> void:
	if index < 0 or index >= cargo.size():
		return
	journal.append("Left the %s behind." % String(cargo[index]["name"]).to_lower())
	cargo.remove_at(index)


func toggle_hauler(id: String) -> void:
	if not can_haul(id):
		return
	if haulers.has(id):
		haulers.erase(id)
	else:
		haulers.append(id)


# ---------- events ----------

## The best creature in the roster for a capability, or "" if none has it.
func best_helper(cap: String) -> String:
	var best := ""
	var best_rank := 0
	for id in roster:
		if not conscious(id):
			continue
		var r := Species.capability(id, cap)
		if r > best_rank:
			best_rank = r
			best = id
	return best


## What each choice of an event looks like: helper, odds (or safe).
func event_choices(event: Dictionary) -> Array:
	var out: Array = []
	for c in event["choices"]:
		var view := {"label": c["label"], "safe": not c.has("cap"), "helper": "", "odds": {}}
		if c.has("cap"):
			var helper := best_helper(c["cap"])
			var score := Species.capability(helper, c["cap"]) * TrailEvents.RANK_SCORE if helper != "" else 0
			view["helper"] = helper
			view["odds"] = CheckOdds.for_scores(score, int(c["difficulty"]))
		out.append(view)
	return out


## Resolve the pending event with a choice. roll is 0-99 (random if negative).
## Returns {"outcome": "success"|"mixed"|"failure", "text": String}.
func resolve_event(choice: int, roll := -1) -> Dictionary:
	if pending_event.is_empty():
		return {}
	var c: Dictionary = pending_event["choices"][choice]
	var outcome := "success"
	if c.has("cap"):
		var odds: Dictionary = event_choices(pending_event)[choice]["odds"]
		if roll < 0:
			roll = rng.randi_range(0, 99)
		if roll >= odds["success"] + odds["mixed"]:
			outcome = "failure"
		elif roll >= odds["success"]:
			outcome = "mixed"
	var fx: Dictionary = c[outcome]
	pending_event = {}
	var text: String = fx["text"]
	journal.append(text)
	_apply_effects(fx)
	return {"outcome": outcome, "text": text}


func _apply_effects(fx: Dictionary) -> void:
	provisions = maxf(0.0, provisions - float(fx.get("provisions", 0)))
	water = maxf(0.0, water - float(fx.get("water", 0)))
	wagon.wear = minf(100.0, wagon.wear + float(fx.get("wear", 0)))
	wagon.integrity = maxi(0, wagon.integrity - int(fx.get("integrity", 0)))
	for id in haulers:
		fatigue[id] = minf(100.0, float(fatigue.get(id, 0.0)) + float(fx.get("fatigue", 0)))
	for i in int(fx.get("lose_cargo", 0)):
		if cargo.is_empty():
			break
		var lost: Dictionary = cargo.pop_at(rng.randi_range(0, cargo.size() - 1))
		journal.append("Lost the %s." % String(lost["name"]).to_lower())
	health -= int(fx.get("health", 0))
	if health <= 0:
		health = 0
		state = State.FAILED
		fail_reason = "Your traveller couldn't go on."
		return
	if wagon.integrity <= 0:
		state = State.FAILED
		fail_reason = "The wagon fell apart on the trail."
		return
	for i in int(fx.get("days", 0)):
		journal.append(spend_day())
		if state == State.FAILED:
			return


# ---------- creatures and battle lineup ----------

func max_hp(id: String) -> float:
	return CombatData.max_hp(id) + float(boosts.get(id, {}).get("hp", 0.0))


## A creature's current stat after level-up boosts ("atk", "def", "spd").
func stat(id: String, key: String) -> float:
	var base := float(CombatData.stats(id)[key])
	var b := float(boosts.get(id, {}).get(key, 0.0))
	if key == "spd":
		return maxf(0.6, base - b)
	return maxf(1.0 if key == "atk" else 0.0, base + b)


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
	if not bool(pending_encounter["guardian"]):
		var helper := best_helper("scout")
		var score := Species.capability(helper, "scout") * TrailEvents.RANK_SCORE if helper != "" else 0
		out.append({"id": "slip", "label": "Slip past quietly", "safe": false, "helper": helper,
			"odds": CheckOdds.for_scores(score, SLIP_DIFFICULTY)})
		out.append({"id": "bribe", "label": "Throw them food (%d food)" % BRIBE_FOOD, "safe": true, "helper": "", "odds": {}})
	return out


## Resolve a non-fight choice. Returns {"outcome", "text", "fight": bool, "ambush": bool}.
## "fight" means the battle must still happen (ambush = they struck first).
func resolve_encounter(choice_id: String, roll := -1) -> Dictionary:
	if pending_encounter.is_empty():
		return {}
	match choice_id:
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


## Can anyone fight right now?
func can_fight() -> bool:
	for cell in lineup:
		if conscious(lineup[cell]):
			return true
	return false


## Build the battle for the pending encounter from the lineup, health and fatigue.
func make_battle(ambush := false, rng_seed := -1) -> Battle:
	var pack: Dictionary = pending_encounter.get("pack", CombatData.PACKS[0])
	var opts := {"ambush": ambush}
	opts["seed"] = rng_seed if rng_seed >= 0 else battle_rng.randi()
	opts["items"] = slotted_items()
	return Battle.create(
		{"slots": lineup.duplicate(), "hp": creature_hp.duplicate(), "fatigue": fatigue.duplicate(),
			"kits": kits.duplicate(true), "boosts": boosts.duplicate(true)},
		{"front": pack["front"], "back": pack["back"], "boss": pack.get("boss", ""), "scale": float(pending_encounter.get("scale", 1.0))},
		opts)


## What a battle defeat costs (breach): wagon integrity and a share of food and water.
const BREACH_INTEGRITY := 15
const BREACH_SUPPLY_SHARE := 0.1
const RETREAT_FOOD := 5.0
const RETREAT_WEAR := 8.0
const VICTORY_FOOD := 6.0
const VICTORY_WATER := 4.0
const ITEM_DROP_CHANCE := 0.5
const TECHNIQUE_DROP_CHANCE := 0.2

## Apply a finished battle (or null when nobody could fight). Returns lines describing the aftermath.
func finish_battle(battle: Battle) -> Array[String]:
	var lines: Array[String] = []
	var outcome := Battle.Outcome.DEFEAT if battle == null else battle.outcome
	if battle != null:
		var hp := battle.player_hp()
		for id in hp:
			creature_hp[id] = float(hp[id])
	var guardian := bool(pending_encounter.get("guardian", false))
	var battle_scale := float(pending_encounter.get("scale", 1.0))
	pending_encounter = {}
	match outcome:
		Battle.Outcome.VICTORY:
			provisions += VICTORY_FOOD
			water += VICTORY_WATER
			lines.append("Victory! %s" % ("The Hollow Stag's pack scatters and the road to Westwatch is clear." if guardian else "The pack scatters."))
			lines.append("You gather what they left behind: +%d food, +%d water." % [VICTORY_FOOD, VICTORY_WATER])
		Battle.Outcome.RETREAT, Battle.Outcome.WITHDRAW:
			provisions = maxf(0.0, provisions - RETREAT_FOOD)
			wagon.wear = minf(100.0, wagon.wear + RETREAT_WEAR)
			lines.append("Both sides are exhausted and pull back." if outcome == Battle.Outcome.WITHDRAW else "You pull the team back and the wagon rattles away.")
			lines.append("The scramble costs %d food and %d wagon wear." % [RETREAT_FOOD, RETREAT_WEAR])
		_:
			var food := roundf(provisions * BREACH_SUPPLY_SHARE)
			var drink := roundf(water * BREACH_SUPPLY_SHARE)
			provisions -= food
			water -= drink
			wagon.integrity = maxi(0, wagon.integrity - BREACH_INTEGRITY)
			lines.append("Defeat. They break through to the wagon.")
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
		var light := Dust.GUARDIAN_LIGHT if guardian else Dust.WIN_LIGHT
		var dark := Dust.GUARDIAN_DARK if guardian else (1 if battle_scale >= Dust.STRONG_SCALE else 0)
		light_dust += light
		dark_dust += dark
		lines.append("Gathered dust: +%d {i:light_dust} Light%s." % [light, "" if dark == 0 else ", +%d {i:dark_dust} Dark" % dark])
		if battle_rng.randf() < (1.0 if guardian else TECHNIQUE_DROP_CHANCE):
			var all: Array = MovePool.MOVES.keys()
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
	return lines


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


# ---------- dust ----------

func dust_left(id: String) -> int:
	return Dust.CAP - int(dust_used.get(id, 0))


func dust_count(kind: String) -> int:
	return dark_dust if kind == "dark" else light_dust


## Use one Light or Dark dust on a stat. Returns a journal line, or "" if it can't.
func use_dust(id: String, kind: String, stat: String) -> String:
	if dust_count(kind) <= 0 or dust_left(id) <= 0 or not Leveling.STATS.has(stat):
		return ""
	var o := Dust.offer(kind, stat)
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

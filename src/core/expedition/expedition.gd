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


static func new_default(rng_seed := -1) -> Expedition:
	var e := Expedition.new()
	if rng_seed >= 0:
		e.rng.seed = rng_seed
	else:
		e.rng.randomize()
	e.roster = ["brambleback", "coilhusk", "reedwake", "mirelamp", "rimehare", "scythelk"]
	e.haulers = ["brambleback", "coilhusk"]
	e.cargo = [
		{"name": "Medicine crates", "weight": 40.0, "value": 120},
		{"name": "Tool chests", "weight": 60.0, "value": 150},
		{"name": "Seed stock", "weight": 40.0, "value": 90},
	]
	for id in e.roster:
		e.fatigue[id] = 0.0
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
		"can_go": result != Hauling.Result.BLOCKED and state == State.AT_JUNCTION and wagon.broken != Wagon.Part.RUNNING_GEAR and not haulers.is_empty(),
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


## Commit to a segment. Returns false if it can't be travelled. Then call step_day() until it returns false.
func start_trip(seg: Dictionary) -> bool:
	var f := forecast(seg)
	if not f["can_go"]:
		return false
	trip = seg
	trip["pushing"] = f["hauling"] == Hauling.Result.PUSH
	trip_days_left = f["days"]
	state = State.TRAVELLING
	return true


## Spend one travel day. Returns true while the trip continues.
func step_day() -> bool:
	if state != State.TRAVELLING:
		return false
	journal.append(spend_day())
	if state == State.FAILED:
		return false
	_wear_day(float(trip["terrain_factor"]), trip["pushing"])
	if state == State.FAILED:
		return false
	trip_days_left -= 1
	if trip_days_left > 0:
		return true
	at = trip["to"]
	visited.append(at)
	journal.append("Reached %s." % TestRoute.junction_name(at))
	state = State.ARRIVED if at == TestRoute.GOAL else State.AT_JUNCTION
	trip = {}
	return false


## Commit to a segment and resolve the whole trip at once.
func travel(seg: Dictionary) -> bool:
	if not start_trip(seg):
		return false
	while step_day():
		pass
	return true


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
	if state != State.FAILED:
		journal.append("Rested. The haulers recovered.")


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

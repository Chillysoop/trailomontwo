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
var wagon_empty_mass := 80.0
var cargo: Array[Dictionary] = []
var visited: Array[String] = []
var journal: Array[String] = []


static func new_default() -> Expedition:
	var e := Expedition.new()
	e.roster = ["brambleback", "coilhusk", "reedwake", "mirelamp", "rimehare", "scythelk"]
	e.haulers = ["brambleback", "coilhusk"]
	e.cargo = [
		{"name": "Medicine crates", "weight": 40.0},
		{"name": "Tool chests", "weight": 60.0},
		{"name": "Seed stock", "weight": 40.0},
	]
	e.visited = [TestRoute.START]
	return e


func daily_provisions() -> float:
	var total := HUMAN_PROVISIONS * humans
	for id in roster:
		total += Species.upkeep(id)
	return total


func daily_water() -> float:
	return HUMAN_WATER * humans + CREATURE_WATER * roster.size()


func cargo_weight() -> float:
	var w := 0.0
	for c in cargo:
		w += float(c["weight"])
	return w


func hauling_available() -> float:
	var strengths: Array = []
	for id in haulers:
		strengths.append(Species.info(id)["hauling"])
	return Hauling.available(strengths)


## How many days the current food or water lasts.
func days_of(supply: float, per_day: float) -> float:
	return supply / per_day if per_day > 0.0 else INF


## Everything the route card shows for one segment, before committing.
func forecast(seg: Dictionary) -> Dictionary:
	var demand := Hauling.demand(wagon_empty_mass, cargo_weight(), float(seg["terrain_factor"]))
	var available := hauling_available()
	var result := Hauling.evaluate(demand, available)
	var days: int = seg["days"]
	if result == Hauling.Result.PUSH:
		days = ceili(days * PUSH_SLOWDOWN)
	return {
		"demand": demand,
		"available": available,
		"hauling": result,
		"days": days,
		"provisions": daily_provisions() * days,
		"water": daily_water() * days,
		"enough_food": provisions >= daily_provisions() * days,
		"enough_water": water >= daily_water() * days,
		"can_go": result != Hauling.Result.BLOCKED and state == State.AT_JUNCTION,
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

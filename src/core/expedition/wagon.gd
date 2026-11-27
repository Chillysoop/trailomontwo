class_name Wagon
extends RefCounted
## The wagon's condition: integrity, wear and which assembly (if any) is broken.
##
## Wear builds with distance, steep ground, heavy loads and pushing. Past WARN_WEAR the wagon
## shows a breakdown warning, and each travel day has a growing chance of breaking an assembly.
## A breakdown costs integrity, but one routine roll can't wreck a healthy wagon.

enum Part { NONE, RUNNING_GEAR, HARNESS, CANOPY }

const EMPTY_MASS := 40.0
## For hauling, the load counts this much of its weight (supplies ride low and get eaten as you go).
const LOAD_PULL := 0.6
## What the crew and the wagon's old spring motor pull on their own when the Trailomon haulers
## can't do better: enough for a light wagon on easy ground, a slow push in the mountains.
const BASE_PULL := 190.0
## Everything aboard counts toward this: cargo, food, water, spare parts and curiosities.
const CAPACITY := 300.0
const WARN_WEAR := 60.0
const BREAKDOWN_DAMAGE := 20
const HARNESS_PENALTY := 0.75
const CANOPY_WATER_PENALTY := 1.25
const PART_NAMES := {Part.RUNNING_GEAR: "axle", Part.HARNESS: "harness", Part.CANOPY: "canopy"}
## The spare part that fixes each assembly, what it weighs, and the trail job that can jury-rig
## the assembly without one.
const SPARES := {
	"axle": {"part": Part.RUNNING_GEAR, "name": "spare axle", "weight": 20.0, "job": "strength"},
	"harness": {"part": Part.HARNESS, "name": "spare harness", "weight": 8.0, "job": "steady"},
	"canvas": {"part": Part.CANOPY, "name": "canopy canvas", "weight": 10.0, "job": "guard"},
}
## A jury-rig with a helper of at least this job rank takes one day instead of two.
const JURY_RANK := 3

var integrity := 100
var wear := 0.0
var broken := Part.NONE


## Wear added by one travel day.
static func wear_per_day(terrain_factor: float, load_weight: float, pushing: bool) -> float:
	var load_ratio := clampf(load_weight / CAPACITY, 0.0, 1.5)
	return 3.0 * terrain_factor * (0.6 + 0.5 * load_ratio) * (2.0 if pushing else 1.0)


## Chance that today's travel breaks an assembly, from 0 below WARN_WEAR up to 50% at full wear.
static func breakdown_chance(wear_level: float) -> float:
	return clampf((wear_level - WARN_WEAR) / 80.0, 0.0, 0.5)


func warning() -> bool:
	return wear >= WARN_WEAR


func break_part(part: Part, damage := BREAKDOWN_DAMAGE) -> void:
	broken = part
	integrity = maxi(0, integrity - damage)


## Fix the broken assembly: with the right spare it's good as new, a jury-rig costs integrity
## (less with a skilled helper).
func repair(with_spare: bool, skilled := false) -> void:
	broken = Part.NONE
	wear = maxf(0.0, wear - (50.0 if with_spare else 25.0))
	if with_spare:
		integrity = mini(100, integrity + 10)
	else:
		integrity = maxi(0, integrity - (5 if skilled else 10))


## Routine upkeep when nothing is broken: grease and tighten, no parts needed. Shores up a little integrity.
func tune_up() -> void:
	wear = maxf(0.0, wear - 25.0)
	integrity = mini(100, integrity + 5)


## Which spare fixes the broken assembly ("" when nothing is broken).
func spare_needed() -> String:
	return spare_for(broken)


static func spare_for(part: Part) -> String:
	for k in SPARES:
		if SPARES[k]["part"] == part:
			return k
	return ""


func part_name() -> String:
	return PART_NAMES.get(broken, "")

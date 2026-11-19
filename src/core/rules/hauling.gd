class_name Hauling
extends RefCounted
## Hauling demand versus available hauling strength.
##
## demand = (empty wagon mass + cargo weight) * terrain factor
## At or below available strength: normal travel.
## Up to PUSH_LIMIT times available strength: push at reduced speed (extra fatigue and wear).
## Above that: the wagon cannot enter the segment.

enum Result { NORMAL, PUSH, BLOCKED }

const PUSH_LIMIT := 1.25


static func demand(empty_mass: float, cargo_weight: float, terrain_factor: float) -> float:
	return (empty_mass + cargo_weight) * terrain_factor


static func available(hauler_strengths: Array) -> float:
	var total := 0.0
	for strength in hauler_strengths:
		total += float(strength)
	return total


static func evaluate(demand_units: float, available_units: float) -> Result:
	if demand_units <= available_units:
		return Result.NORMAL
	if demand_units <= available_units * PUSH_LIMIT:
		return Result.PUSH
	return Result.BLOCKED

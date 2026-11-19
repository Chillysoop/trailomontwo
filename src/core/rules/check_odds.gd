class_name CheckOdds
extends RefCounted
## Odds for a three-outcome event check (success, mixed, failure).
##
## Design rule: success = clamp(55 + 5 * advantage, 10, 90) percent.
## Mixed = the lesser of 25% or what remains after success.
## Failure = everything left over.

const BASE_SUCCESS := 55
const PER_ADVANTAGE := 5
const MIN_SUCCESS := 10
const MAX_SUCCESS := 90
const MAX_MIXED := 25


## Returns {"success": int, "mixed": int, "failure": int}, in whole percent, summing to 100.
static func for_advantage(advantage: int) -> Dictionary:
	var success: int = clampi(BASE_SUCCESS + PER_ADVANTAGE * advantage, MIN_SUCCESS, MAX_SUCCESS)
	var mixed: int = mini(MAX_MIXED, 100 - success)
	var failure: int = 100 - success - mixed
	return {"success": success, "mixed": mixed, "failure": failure}


## Advantage is effective skill score minus the check's difficulty.
static func for_scores(skill_score: int, difficulty: int) -> Dictionary:
	return for_advantage(skill_score - difficulty)

class_name Dust
extends RefCounted
## Dust: permanent stat boosts for one Trailomon.
## - Light dust: a modest boost to the stat you choose.
## - Dark dust: a big boost to the stat you choose, paid for by its opposite stat
##   (Attack <-> Defense, Max HP <-> Speed).
## Each Trailomon can take CAP dust in total, so dust shapes a creature without running away.

const CAP := 5
## Boost sizes reuse the level-up rarity table: Light = Uncommon, Dark = Epic, its cost = Uncommon.
const LIGHT_RARITY := 1
const DARK_RARITY := 3
const DARK_COST_RARITY := 1
const OPPOSITE := {"atk": "def", "def": "atk", "hp": "spd", "spd": "hp"}

## Dust earned: every win gives Light dust; strong fights and the guardian give Dark dust.
const WIN_LIGHT := 1
const GUARDIAN_LIGHT := 2
const GUARDIAN_DARK := 1
const STRONG_SCALE := 1.25


## What using dust on a stat does: {"stat", "amount", "cost_stat", "cost"} (cost 0 for Light).
static func offer(kind: String, stat: String) -> Dictionary:
	if kind == "dark":
		return {"stat": stat, "amount": Leveling.BOOSTS[stat][DARK_RARITY],
			"cost_stat": OPPOSITE[stat], "cost": Leveling.BOOSTS[OPPOSITE[stat]][DARK_COST_RARITY]}
	return {"stat": stat, "amount": Leveling.BOOSTS[stat][LIGHT_RARITY], "cost_stat": "", "cost": 0}


## "+5 Attack, -3 Defense" style text.
static func offer_text(o: Dictionary) -> String:
	var t := Leveling.boost_text(o["stat"], o["amount"])
	if float(o["cost"]) > 0.0:
		var c := Leveling.boost_text(o["cost_stat"], o["cost"])
		t += ", " + ("+" + c.substr(1) if c.begins_with("-") else "-" + c.substr(1))
	return t

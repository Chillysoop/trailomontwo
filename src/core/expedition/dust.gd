class_name Dust
extends RefCounted
## Dust: permanent stat boosts for one Trailomon.
## - Light dust: a modest boost to the stat you choose.
## - Dark dust: a big boost to the stat you choose, paid for by its opposite stat
##   (Attack <-> Defense, Max HP <-> Speed).
## Each Trailomon can take CAP dust in total, so dust shapes a creature without running away.

const CAP := 5
## Boost sizes are a share of the Trailomon's own base stat, so dust is worth the same to a
## tank and a glass cannon. Speed shares shorten the attack time.
const LIGHT_PCT := 6.0
const DARK_PCT := 12.0
const DARK_COST_PCT := 4.0
const OPPOSITE := {"atk": "def", "def": "atk", "hp": "spd", "spd": "hp"}
## Stats aren't worth the same per percent: Defense has a soft effect, attack time a strong one.
const WEIGHT := {"atk": 1.0, "hp": 1.0, "def": 2.5, "spd": 0.5}

## Dust earned: every win gives Light dust; strong fights and the guardian give Dark dust.
const WIN_LIGHT := 1
const GUARDIAN_LIGHT := 2
const GUARDIAN_DARK := 1
const STRONG_SCALE := 1.25


## What using dust on a stat does for this species: {"stat", "amount", "cost_stat", "cost"}
## (cost 0 for Light).
static func offer(kind: String, stat: String, species: String) -> Dictionary:
	if kind == "dark":
		return {"stat": stat, "amount": _share(species, stat, DARK_PCT),
			"cost_stat": OPPOSITE[stat], "cost": _share(species, OPPOSITE[stat], DARK_COST_PCT)}
	return {"stat": stat, "amount": _share(species, stat, LIGHT_PCT), "cost_stat": "", "cost": 0}


static func _share(species: String, stat: String, pct: float) -> float:
	var base := CombatData.max_hp(species) if stat == "hp" else float(CombatData.stats(species)[stat])
	var v := base * pct * float(WEIGHT[stat]) / 100.0
	if stat == "spd":
		return snappedf(v, 0.01)
	return maxf(1.0, roundf(v))


## "+5 Attack, -3 Defense" style text.
static func offer_text(o: Dictionary) -> String:
	var t := Leveling.boost_text(o["stat"], o["amount"])
	if float(o["cost"]) > 0.0:
		var c := Leveling.boost_text(o["cost_stat"], o["cost"])
		t += ", " + ("+" + c.substr(1) if c.begins_with("-") else "-" + c.substr(1))
	return t

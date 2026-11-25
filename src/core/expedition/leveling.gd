class_name Leveling
extends RefCounted
## Levels, experience and level-up offers.
##
## Every level-up offers the player two options and they pick one:
## - Most levels are stat level-ups: two random stats, each with a random rarity. The rarer
##   the boost, the bigger it is.
## - At ABILITY_LEVELS it's a new move instead: one from each of the species' two
##   archetypes (MovePool), no rarity. The new move can go straight into its slot (the old
##   one moves to the slot's memory) or be kept in memory.

const MAX_LEVEL := 30
const ABILITY_LEVELS := [3, 6, 9, 12, 15, 18]

## Experience for a battle, given to every creature that stood in the lineup.
const XP_WIN := 35
const XP_GUARDIAN := 70
const XP_LOSS := 12
const XP_RETREAT := 8

const RARITIES := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
const RARITY_WEIGHTS := [50, 26, 13, 7, 3, 1]
const RARITY_COLORS := ["c8c4d0", "74d46a", "5aa8ff", "b77dff", "ffb13b", "ff5a8a"]

const STATS := ["hp", "atk", "def", "spd"]
const STAT_NAMES := {"hp": "Max HP", "atk": "Attack", "def": "Defense", "spd": "Speed"}
## Raw boost per rarity, common to mythic. Speed is seconds taken off the attack time.
const BOOSTS := {
	"hp": [40, 70, 110, 160, 230, 320],
	"atk": [1, 2, 3, 5, 7, 10],
	"def": [2, 3, 5, 7, 10, 14],
	"spd": [0.03, 0.05, 0.08, 0.11, 0.15, 0.2],
}


## Experience needed to go from `level` to the next one.
static func xp_to_next(level: int) -> int:
	return 30 + 20 * (level - 1)


static func is_ability_level(level: int) -> bool:
	return ABILITY_LEVELS.has(level)


static func roll_rarity(rng: RandomNumberGenerator) -> int:
	var total := 0
	for w in RARITY_WEIGHTS:
		total += w
	var r := rng.randi_range(1, total)
	for i in RARITY_WEIGHTS.size():
		r -= RARITY_WEIGHTS[i]
		if r <= 0:
			return i
	return 0


## Two stat options with different stats.
static func stat_options(rng: RandomNumberGenerator) -> Array:
	var stats := STATS.duplicate()
	var out: Array = []
	for i in 2:
		var stat: String = stats.pop_at(rng.randi_range(0, stats.size() - 1))
		var rarity := roll_rarity(rng)
		out.append({"kind": "stat", "stat": stat, "rarity": rarity, "amount": BOOSTS[stat][rarity]})
	return out


## One unlearned move from each archetype (empty if an archetype has nothing left).
static func ability_options(species: String, known: Array, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for arc in MovePool.archetypes(species):
		var left: Array = []
		for mid in arc["moves"]:
			if not known.has(mid):
				left.append(mid)
		if not left.is_empty():
			out.append({"kind": "move", "move": left[rng.randi_range(0, left.size() - 1)], "archetype": arc["name"]})
	return out


## How a stat boost reads: "+5 Attack", "-0.08s Speed".
static func boost_text(stat: String, amount: float) -> String:
	if stat == "spd":
		return "-%.2fs attack time" % amount
	return "+%d %s" % [roundi(amount), STAT_NAMES[stat]]

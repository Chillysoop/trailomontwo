extends RefCounted
## Snow Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"flurrypup": {"rarity": "common", "name": "Flurrypup", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"cold": 2, "scout": 2}},
	"rimewing": {"rarity": "rare", "name": "Rimewing", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"cold": 3, "scout": 2}},
	"auroryx": {"rarity": "legendary", "name": "Auroryx", "type": "Snow", "size": "medium", "hauling": 90,
		"capabilities": {"cold": 3, "light": 2, "scout": 2}},
	"sleetmouse": {"rarity": "common", "name": "Sleetmouse", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"scout": 2, "cold": 2}},
	"frostmane": {"rarity": "rare", "name": "Frostmane", "type": "Snow", "size": "large", "hauling": 90,
		"capabilities": {"cold": 3, "guard": 2}},
}

const KITS := {
	"flurrypup": {"role": "Support", "hp": 270, "atk": 24, "def": 12, "spd": 1.5,
		"basic": "snow_nip", "passive": "pack_flurry", "ultimate": "blizzard_howl"},
	"rimewing": {"role": "Striker", "hp": 290, "atk": 32, "def": 16, "spd": 1.6,
		"basic": "frost_wing", "passive": "cold_edge", "ultimate": "rime_dive"},
	"auroryx": {"role": "Striker", "hp": 360, "atk": 34, "def": 22, "spd": 1.5,
		"basic": "aurora_horn", "passive": "aurora_mane", "ultimate": "polar_light"},
	"sleetmouse": {"role": "Striker", "hp": 220, "atk": 27, "def": 10, "spd": 1.3,
		"basic": "sleet_nibble", "passive": "cold_whiskers", "ultimate": "snow_scurry"},
	"frostmane": {"role": "Bruiser", "hp": 450, "atk": 33, "def": 28, "spd": 2.1,
		"basic": "frost_maul", "passive": "ice_pride", "ultimate": "white_roar"},
}

const MOVES := {
	# Flurrypup
	"snow_nip": {"name": "Snow Nip", "slot": "basic", "pct": 75, "slow": [20, 2]},
	"pack_flurry": {"name": "Pack Flurry", "slot": "passive", "kind": "every", "n": 3, "team_haste": [20, 3]},
	"blizzard_howl": {"name": "Blizzard Howl", "slot": "ultimate", "target": "none", "team": {"haste": [30, 5]}},
	# Rimewing
	"frost_wing": {"name": "Frost Wing", "slot": "basic", "pct": 50, "hits": 2, "slow": [15, 2]},
	"cold_edge": {"name": "Cold Edge", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"rime_dive": {"name": "Rime Dive", "slot": "ultimate", "target": "adjacent", "pct": 120, "slow": [40, 4]},
	# Auroryx
	"aurora_horn": {"name": "Aurora Horn", "slot": "basic", "pct": 45, "hits": 2, "slow": [15, 2]},
	"aurora_mane": {"name": "Aurora Mane", "slot": "passive", "kind": "every", "n": 4, "team_haste": [20, 3]},
	"polar_light": {"name": "Polar Light", "slot": "ultimate", "target": "all", "pct": 80, "slow": [30, 3]},
	# Sleetmouse
	"sleet_nibble": {"name": "Sleet Nibble", "slot": "basic", "pct": 45, "hits": 2, "slow": [15, 2]},
	"cold_whiskers": {"name": "Cold Whiskers", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 20},
	"snow_scurry": {"name": "Snow Scurry", "slot": "ultimate", "target": "weakest", "pct": 160, "slow": [30, 3]},
	# Frostmane
	"frost_maul": {"name": "Frost Maul", "slot": "basic", "pct": 95, "slow": [20, 3]},
	"ice_pride": {"name": "Ice Pride", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"white_roar": {"name": "White Roar", "slot": "ultimate", "target": "all", "pct": 90, "slow": [30, 3]},
}

extends RefCounted
## Jungle Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"vinegecko": {"rarity": "common", "name": "Vinegecko", "type": "Jungle", "size": "small", "hauling": 0,
		"capabilities": {"clear": 2, "scout": 2, "forage": 1}},
	"canopard": {"rarity": "rare", "name": "Canopard", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "guard": 1}},
	"vinekeet": {"rarity": "common", "name": "Vinekeet", "type": "Jungle", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "forage": 1}},
	"prowlmander": {"rarity": "rare", "name": "Prowlmander", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 2, "clear": 2}},
	"quetzalith": {"rarity": "legendary", "name": "Quetzalith", "type": "Jungle", "size": "large", "hauling": 0,
		"capabilities": {"scout": 3, "clear": 2, "light": 1}},
}

const KITS := {
	"vinegecko": {"role": "Striker", "hp": 240, "atk": 28, "def": 11, "spd": 1.6,
		"basic": "vine_flick", "passive": "sticky_feet", "ultimate": "canopy_drop"},
	"canopard": {"role": "Striker", "hp": 320, "atk": 35, "def": 18, "spd": 1.7,
		"basic": "leaf_pounce", "passive": "dapple", "ultimate": "canopy_strike"},
	"vinekeet": {"role": "Support", "hp": 240, "atk": 24, "def": 12, "spd": 1.5,
		"basic": "keet_peck", "passive": "chatter", "ultimate": "flock_call"},
	"prowlmander": {"role": "Striker", "hp": 300, "atk": 34, "def": 15, "spd": 1.7,
		"basic": "tongue_lash", "passive": "quick_tongue", "ultimate": "ambush_leap"},
	"quetzalith": {"role": "Striker", "hp": 370, "atk": 36, "def": 20, "spd": 1.6,
		"basic": "plume_strike", "passive": "sun_plumes", "ultimate": "sky_dive"},
}

const MOVES := {
	# Vinegecko
	"vine_flick": {"name": "Vine Flick", "slot": "basic", "pct": 80, "reach": true},
	"sticky_feet": {"name": "Sticky Feet", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"canopy_drop": {"name": "Canopy Drop", "slot": "ultimate", "target": "weakest", "pct": 170},
	# Canopard
	"leaf_pounce": {"name": "Leaf Pounce", "slot": "basic", "pct": 90, "self": {"dodge": true}},
	"dapple": {"name": "Dapple", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 35},
	"canopy_strike": {"name": "Canopy Strike", "slot": "ultimate", "target": "weakest", "pct": 230},
	# Vinekeet
	"keet_peck": {"name": "Keet Peck", "slot": "basic", "pct": 70, "reach": true},
	"chatter": {"name": "Chatter", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 35},
	"flock_call": {"name": "Flock Call", "slot": "ultimate", "target": "row", "pct": 100, "self": {"dodge": true}},
	# Prowlmander
	"tongue_lash": {"name": "Tongue Lash", "slot": "basic", "pct": 85, "reach": true},
	"quick_tongue": {"name": "Quick Tongue", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 30},
	"ambush_leap": {"name": "Ambush Leap", "slot": "ultimate", "target": "weakest", "pct": 220, "self": {"dodge": true}},
	# Quetzalith
	"plume_strike": {"name": "Plume Strike", "slot": "basic", "pct": 80, "reach": true, "self": {"dodge": true}},
	"sun_plumes": {"name": "Sun Plumes", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 60},
	"sky_dive": {"name": "Sky Dive", "slot": "ultimate", "target": "all", "pct": 95},
}

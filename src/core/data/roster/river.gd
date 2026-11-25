extends RefCounted
## River Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"pebblotter": {"rarity": "common", "name": "Pebblotter", "type": "River", "size": "small", "hauling": 0,
		"capabilities": {"float": 2, "heal": 1, "forage": 2}},
	"lanternray": {"rarity": "rare", "name": "Lanternray", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "light": 2}},
	"tidewyrm": {"rarity": "legendary", "name": "Tidewyrm", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "heal": 3}},
	"minnowisp": {"rarity": "common", "name": "Minnowisp", "type": "River", "size": "small", "hauling": 0,
		"capabilities": {"float": 3, "light": 1}},
	"kelpoise": {"rarity": "rare", "name": "Kelpoise", "type": "River", "size": "large", "hauling": 100,
		"capabilities": {"float": 3, "strength": 2}},
}

const KITS := {
	"pebblotter": {"role": "Healer", "hp": 280, "atk": 25, "def": 14, "spd": 1.7,
		"basic": "pebble_toss", "passive": "otter_care", "ultimate": "brook_song"},
	"lanternray": {"role": "Striker", "hp": 300, "atk": 34, "def": 14, "spd": 1.8,
		"basic": "glow_sting", "passive": "deep_glow", "ultimate": "lantern_dive"},
	"tidewyrm": {"role": "Healer", "hp": 400, "atk": 34, "def": 24, "spd": 1.8,
		"basic": "tide_lash", "passive": "tidal_heart", "ultimate": "great_wave"},
	"minnowisp": {"role": "Healer", "hp": 250, "atk": 24, "def": 12, "spd": 1.6,
		"basic": "wisp_splash", "passive": "glimmer", "ultimate": "spring_glow"},
	"kelpoise": {"role": "Guard", "hp": 520, "atk": 24, "def": 38, "spd": 2.3,
		"basic": "kelp_snap", "passive": "kelp_drink", "ultimate": "tide_shelter"},
}

const MOVES := {
	# Pebblotter
	"pebble_toss": {"name": "Pebble Toss", "slot": "basic", "pct": 60, "ally": {"heal_atk": 50}},
	"otter_care": {"name": "Otter Care", "slot": "passive", "kind": "drain", "pct": 20, "to_ally": true},
	"brook_song": {"name": "Brook Song", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12, "cleanse": true}},
	# Lanternray
	"glow_sting": {"name": "Glow Sting", "slot": "basic", "pct": 80, "wash": 50},
	"deep_glow": {"name": "Deep Glow", "slot": "passive", "kind": "drain", "pct": 30},
	"lantern_dive": {"name": "Lantern Dive", "slot": "ultimate", "target": "weakest", "pct": 200, "wash": 100},
	# Tidewyrm
	"tide_lash": {"name": "Tide Lash", "slot": "basic", "pct": 85, "ally": {"heal_atk": 30}},
	"tidal_heart": {"name": "Tidal Heart", "slot": "passive", "kind": "drain", "pct": 12, "to_ally": true},
	"great_wave": {"name": "Great Wave", "slot": "ultimate", "target": "all", "pct": 80, "team": {"heal_maxhp": 5}},
	# Minnowisp
	"wisp_splash": {"name": "Wisp Splash", "slot": "basic", "pct": 55, "ally": {"heal_atk": 55}},
	"glimmer": {"name": "Glimmer", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 60},
	"spring_glow": {"name": "Spring Glow", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 10, "cleanse": true}},
	# Kelpoise
	"kelp_snap": {"name": "Kelp Snap", "slot": "basic", "pct": 75, "self": {"heal_atk": 30}},
	"kelp_drink": {"name": "Kelp Drink", "slot": "passive", "kind": "drain", "pct": 25},
	"tide_shelter": {"name": "Tide Shelter", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 14, "cleanse": true}, "self": {"shield_def": 100}},
}

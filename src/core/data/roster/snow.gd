extends RefCounted
## Snow Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"flurrypup": {"rarity": "common", "name": "Flurrypup", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "blizzfox",
		"capabilities": {"cold": 2, "scout": 2}},
	"rimewing": {"rarity": "rare", "name": "Rimewing", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"cold": 3, "scout": 2}},
	"auroryx": {"rarity": "legendary", "name": "Auroryx", "type": "Snow", "size": "medium", "hauling": 90,
		"capabilities": {"cold": 3, "light": 2, "scout": 2}},
	"sleetmouse": {"rarity": "common", "name": "Sleetmouse", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "sleetstoat",
		"capabilities": {"scout": 2, "cold": 2}},
	"frostmane": {"rarity": "rare", "name": "Frostmane", "type": "Snow", "size": "large", "hauling": 90,
		"capabilities": {"cold": 3, "guard": 2}},
	# ----- Milestone 3 -----
	"blizzfox": {"rarity": "common", "name": "Blizzfox", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "owlvix",
		"capabilities": {"cold": 3, "scout": 2}},
	"owlvix": {"rarity": "rare", "name": "Owlvix", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"cold": 3, "scout": 3}},
	"sleetstoat": {"rarity": "common", "name": "Sleetstoat", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 2}},
	"ptarmhare": {"rarity": "rare", "name": "Ptarmhare", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 2, "forage": 1}},
	"pingtusk": {"rarity": "common", "name": "Pingtusk", "type": "Snow", "size": "medium", "hauling": 50, "evolves_to": "tuskemperor",
		"capabilities": {"cold": 3, "float": 2}},
	"tuskemperor": {"rarity": "rare", "name": "Tuskemperor", "type": "Snow", "size": "large", "hauling": 100,
		"capabilities": {"cold": 3, "float": 3, "strength": 1}},
	"sleetkit": {"rarity": "common", "name": "Sleetkit", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "frostpard",
		"capabilities": {"scout": 2, "cold": 2}},
	"frostpard": {"rarity": "rare", "name": "Frostpard", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 3}},
	"woolcalf": {"rarity": "common", "name": "Woolcalf", "type": "Snow", "size": "medium", "hauling": 80, "evolves_to": "glaciox",
		"capabilities": {"strength": 2, "cold": 2}},
	"glaciox": {"rarity": "rare", "name": "Glaciox", "type": "Snow", "size": "large", "hauling": 150,
		"capabilities": {"strength": 3, "cold": 3}},
	"honkflake": {"rarity": "common", "name": "Honkflake", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "squallswan",
		"capabilities": {"scout": 2, "cold": 2}},
	"squallswan": {"rarity": "rare", "name": "Squallswan", "type": "Snow", "size": "large", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 3}},
	"rimeseal": {"rarity": "common", "name": "Rimeseal", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"float": 2, "cold": 2}},
	"boreowl": {"rarity": "legendary", "name": "Boreowl", "type": "Snow", "size": "large", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 3}},
	"glacimusk": {"rarity": "legendary", "name": "Glacimusk", "type": "Snow", "size": "large", "hauling": 200,
		"capabilities": {"strength": 3, "cold": 3, "steady": 2}},
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
	# ----- Milestone 3 -----
	"blizzfox": {"role": "Support", "hp": 300, "atk": 30, "def": 16, "spd": 1.5,
		"basic": "blizz_nip", "passive": "pack_gust", "ultimate": "white_howl"},
	"owlvix": {"role": "Support", "hp": 390, "atk": 35, "def": 22, "spd": 1.5,
		"basic": "silent_talon", "passive": "night_vigil", "ultimate": "polar_night"},
	"sleetstoat": {"role": "Striker", "hp": 270, "atk": 29, "def": 14, "spd": 1.3,
		"basic": "stoat_flurry", "passive": "ermine_coat", "ultimate": "white_dash"},
	"ptarmhare": {"role": "Support", "hp": 370, "atk": 30, "def": 20, "spd": 1.4,
		"basic": "feather_kick", "passive": "molt_rush", "ultimate": "snowburst_run"},
	"pingtusk": {"role": "Guard", "hp": 390, "atk": 23, "def": 38, "spd": 2.2,
		"basic": "tusk_slide", "passive": "blubber", "ultimate": "ice_floe"},
	"tuskemperor": {"role": "Guard", "hp": 500, "atk": 27, "def": 48, "spd": 2.3,
		"basic": "emperor_slam", "passive": "thick_blubber", "ultimate": "frozen_court"},
	"sleetkit": {"role": "Striker", "hp": 260, "atk": 30, "def": 14, "spd": 1.4,
		"basic": "frost_pounce", "passive": "thick_tail", "ultimate": "ice_claws"},
	"frostpard": {"role": "Striker", "hp": 350, "atk": 36, "def": 20, "spd": 1.4,
		"basic": "frost_maw", "passive": "cold_stalker", "ultimate": "whiteout_leap"},
	"woolcalf": {"role": "Guard", "hp": 430, "atk": 23, "def": 38, "spd": 2.3,
		"basic": "wool_bump", "passive": "frost_fleece", "ultimate": "herd_huddle"},
	"glaciox": {"role": "Guard", "hp": 510, "atk": 27, "def": 48, "spd": 2.3,
		"basic": "glacier_horn", "passive": "ice_fleece", "ultimate": "glacier_wall"},
	"honkflake": {"role": "Support", "hp": 270, "atk": 28, "def": 14, "spd": 1.5,
		"basic": "wing_flurry", "passive": "v_formation", "ultimate": "migration"},
	"squallswan": {"role": "Support", "hp": 380, "atk": 33, "def": 20, "spd": 1.5,
		"basic": "squall_wing", "passive": "swan_grace", "ultimate": "winter_squall"},
	"rimeseal": {"role": "Support", "hp": 320, "atk": 26, "def": 18, "spd": 1.6,
		"basic": "snow_flipper", "passive": "ice_whiskers", "ultimate": "pup_chorus"},
	"boreowl": {"role": "Striker", "hp": 420, "atk": 38, "def": 24, "spd": 1.4,
		"basic": "boreal_talon", "passive": "long_night", "ultimate": "aurora_dive"},
	"glacimusk": {"role": "Guard", "hp": 640, "atk": 30, "def": 52, "spd": 2.2,
		"basic": "mammoth_sweep", "passive": "ice_age", "ultimate": "great_freeze"},
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
	# ----- Milestone 3 -----
	# Blizzfox
	"blizz_nip": {"name": "Blizz Nip", "slot": "basic", "pct": 80, "slow": [20, 2]},
	"pack_gust": {"name": "Pack Gust", "slot": "passive", "kind": "every", "n": 3, "team_haste": [20, 3]},
	"white_howl": {"name": "White Howl", "slot": "ultimate", "target": "none", "team": {"haste": [30, 5]}},
	# Owlvix
	"silent_talon": {"name": "Silent Talon", "slot": "basic", "pct": 80, "slow": [25, 3]},
	"night_vigil": {"name": "Night Vigil", "slot": "passive", "kind": "every", "n": 3, "team_haste": [25, 3]},
	"polar_night": {"name": "Polar Night", "slot": "ultimate", "target": "all", "pct": 60, "slow": [30, 3], "team": {"haste": [25, 4]}},
	# Sleetstoat
	"stoat_flurry": {"name": "Stoat Flurry", "slot": "basic", "pct": 45, "hits": 2, "slow": [15, 2]},
	"ermine_coat": {"name": "Ermine Coat", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"white_dash": {"name": "White Dash", "slot": "ultimate", "target": "weakest", "pct": 170, "slow": [30, 3]},
	# Ptarmhare
	"feather_kick": {"name": "Feather Kick", "slot": "basic", "pct": 85, "slow": [20, 2]},
	"molt_rush": {"name": "Molt Rush", "slot": "passive", "kind": "every", "n": 3, "team_haste": [25, 3]},
	"snowburst_run": {"name": "Snowburst Run", "slot": "ultimate", "target": "row", "pct": 90, "slow": [30, 3], "team": {"haste": [20, 4]}},
	# Pingtusk
	"tusk_slide": {"name": "Tusk Slide", "slot": "basic", "pct": 70, "slow": [20, 2], "self": {"shield_def": 25}},
	"blubber": {"name": "Blubber", "slot": "passive", "kind": "armor_low", "amount": 20},
	"ice_floe": {"name": "Ice Floe", "slot": "ultimate", "target": "row", "pct": 70, "slow": [35, 3], "self": {"shield_def": 100}},
	# Tuskemperor
	"emperor_slam": {"name": "Emperor Slam", "slot": "basic", "pct": 80, "slow": [25, 3], "self": {"shield_def": 30}},
	"thick_blubber": {"name": "Thick Blubber", "slot": "passive", "kind": "armor_low", "amount": 30},
	"frozen_court": {"name": "Frozen Court", "slot": "ultimate", "target": "all", "pct": 60, "slow": [35, 3], "self": {"shield_def": 140}},
	# Sleetkit
	"frost_pounce": {"name": "Frost Pounce", "slot": "basic", "pct": 80, "slow": [15, 2]},
	"thick_tail": {"name": "Thick Tail", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"ice_claws": {"name": "Ice Claws", "slot": "ultimate", "target": "weakest", "pct": 170, "slow": [30, 3]},
	# Frostpard
	"frost_maw": {"name": "Frost Maw", "slot": "basic", "pct": 50, "hits": 2, "slow": [20, 2]},
	"cold_stalker": {"name": "Cold Stalker", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 30},
	"whiteout_leap": {"name": "Whiteout Leap", "slot": "ultimate", "target": "weakest", "pct": 210, "slow": [40, 3]},
	# Woolcalf
	"wool_bump": {"name": "Wool Bump", "slot": "basic", "pct": 70, "slow": [20, 3]},
	"frost_fleece": {"name": "Frost Fleece", "slot": "passive", "kind": "armor_low", "amount": 20},
	"herd_huddle": {"name": "Herd Huddle", "slot": "ultimate", "target": "none", "self": {"shield_def": 150}, "team": {"haste": [20, 4]}},
	# Glaciox
	"glacier_horn": {"name": "Glacier Horn", "slot": "basic", "pct": 80, "slow": [25, 3], "self": {"shield_def": 30}},
	"ice_fleece": {"name": "Ice Fleece", "slot": "passive", "kind": "armor_low", "amount": 30},
	"glacier_wall": {"name": "Glacier Wall", "slot": "ultimate", "target": "row", "pct": 80, "slow": [40, 3], "self": {"shield_def": 160}},
	# Honkflake
	"wing_flurry": {"name": "Wing Flurry", "slot": "basic", "pct": 70, "slow": [15, 2], "splash": 25},
	"v_formation": {"name": "V Formation", "slot": "passive", "kind": "every", "n": 3, "team_haste": [20, 3]},
	"migration": {"name": "Migration", "slot": "ultimate", "target": "none", "team": {"haste": [35, 4]}},
	# Squallswan
	"squall_wing": {"name": "Squall Wing", "slot": "basic", "pct": 80, "slow": [20, 2], "splash": 30},
	"swan_grace": {"name": "Swan Grace", "slot": "passive", "kind": "every", "n": 3, "team_haste": [25, 3]},
	"winter_squall": {"name": "Winter Squall", "slot": "ultimate", "target": "all", "pct": 60, "slow": [30, 3], "team": {"haste": [25, 4]}},
	# Rimeseal
	"snow_flipper": {"name": "Snow Flipper", "slot": "basic", "pct": 75, "slow": [20, 2]},
	"ice_whiskers": {"name": "Ice Whiskers", "slot": "passive", "kind": "every", "n": 3, "team_haste": [15, 3]},
	"pup_chorus": {"name": "Pup Chorus", "slot": "ultimate", "target": "row", "pct": 60, "slow": [30, 3], "team": {"haste": [20, 3]}},
	# Boreowl
	"boreal_talon": {"name": "Boreal Talon", "slot": "basic", "pct": 50, "hits": 2, "slow": [20, 2]},
	"long_night": {"name": "Long Night", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 30},
	"aurora_dive": {"name": "Aurora Dive", "slot": "ultimate", "target": "all", "pct": 85, "slow": [35, 3]},
	# Glacimusk
	"mammoth_sweep": {"name": "Mammoth Sweep", "slot": "basic", "pct": 85, "slow": [25, 3], "splash": 30},
	"ice_age": {"name": "Ice Age", "slot": "passive", "kind": "armor_low", "amount": 30},
	"great_freeze": {"name": "Great Freeze", "slot": "ultimate", "target": "all", "pct": 70, "slow": [40, 4], "self": {"shield_def": 150}},
}

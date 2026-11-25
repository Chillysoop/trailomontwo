extends RefCounted
## Guardians: the bosses at the end of each crossing. They never join.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"bogmother": {"rarity": "guardian", "name": "Bog Mother", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {}},
	"cogmammoth": {"rarity": "guardian", "name": "Cogmammoth", "type": "Mountain", "size": "large", "hauling": 0,
		"capabilities": {}},
	"rimewyrm": {"rarity": "guardian", "name": "Rimewyrm", "type": "Snow", "size": "large", "hauling": 0,
		"capabilities": {}},
	"duskmaw": {"rarity": "guardian", "name": "Duskmaw", "type": "Jungle", "size": "large", "hauling": 0,
		"capabilities": {}},
	"dawnshell": {"rarity": "guardian", "name": "Dawnshell", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {}},
	"briarking": {"rarity": "guardian", "name": "Briarking", "type": "Forest", "size": "large", "hauling": 0,
		"capabilities": {}},
	"sturgebull": {"rarity": "guardian", "name": "Sturgebull", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {}},
	"mirewyrm": {"rarity": "guardian", "name": "Mirewyrm", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {}},
	"condorgon": {"rarity": "guardian", "name": "Condorgon", "type": "Mountain", "size": "large", "hauling": 0,
		"capabilities": {}},
	"tuskursa": {"rarity": "guardian", "name": "Tuskursa", "type": "Snow", "size": "large", "hauling": 0,
		"capabilities": {}},
	"cobrilla": {"rarity": "guardian", "name": "Cobrilla", "type": "Jungle", "size": "large", "hauling": 0,
		"capabilities": {}},
}

const KITS := {
	"bogmother": {"role": "Boss", "hp": 1250, "atk": 39, "def": 30, "spd": 2.2,
		"basic": "brood_spit", "passive": "mother_brood", "ultimate": "fen_flood",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"cogmammoth": {"role": "Boss", "hp": 950, "atk": 33, "def": 38, "spd": 2.4,
		"basic": "gear_tusk", "passive": "iron_hide", "ultimate": "piston_stomp",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"rimewyrm": {"role": "Boss", "hp": 950, "atk": 33, "def": 32, "spd": 2.0,
		"basic": "rime_fang", "passive": "frozen_heart", "ultimate": "glacier_breath",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"duskmaw": {"role": "Boss", "hp": 950, "atk": 33, "def": 28, "spd": 2.0,
		"basic": "dusk_rake", "passive": "shadow_pelt", "ultimate": "nightfall_pounce",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"dawnshell": {"role": "Boss", "hp": 1150, "atk": 35, "def": 36, "spd": 2.2,
		"basic": "sunfan_wave", "passive": "dawn_drink", "ultimate": "radiant_tide",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"briarking": {"role": "Boss", "hp": 1300, "atk": 38, "def": 40, "spd": 2.3,
		"basic": "tusk_thicket", "passive": "crown_of_thorns", "ultimate": "bramble_throne",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"sturgebull": {"role": "Boss", "hp": 1300, "atk": 38, "def": 34, "spd": 2.2,
		"basic": "barbel_ram", "passive": "ancient_gills", "ultimate": "river_stampede",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"mirewyrm": {"role": "Boss", "hp": 1650, "atk": 42, "def": 32, "spd": 2.2,
		"basic": "gill_spew", "passive": "rotting_slime", "ultimate": "drowning_mire",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"condorgon": {"role": "Boss", "hp": 1150, "atk": 32, "def": 32, "spd": 2.3,
		"basic": "tusk_gale", "passive": "high_shadow", "ultimate": "skyfall_stampede",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"tuskursa": {"role": "Boss", "hp": 1300, "atk": 36, "def": 34, "spd": 2.2,
		"basic": "narwhal_lance", "passive": "polar_hunger", "ultimate": "endless_winter",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
	"cobrilla": {"role": "Boss", "hp": 1300, "atk": 38, "def": 30, "spd": 2.1,
		"basic": "hood_slam", "passive": "jungle_king", "ultimate": "canopy_crush",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
}

const MOVES := {
	# Bog Mother
	"brood_spit": {"name": "Brood Spit", "slot": "basic", "pct": 95, "poison": [18, 4], "splash": 40},
	"mother_brood": {"name": "Mother's Brood", "slot": "passive", "kind": "every", "n": 3, "poison_all": [15, 4]},
	"fen_flood": {"name": "Fen Flood", "slot": "ultimate", "target": "all", "pct": 95, "poison": [28, 5]},
	# Cogmammoth
	"gear_tusk": {"name": "Gear Tusk", "slot": "basic", "pct": 100, "stagger": 15, "splash": 25},
	"iron_hide": {"name": "Iron Hide", "slot": "passive", "kind": "armor_low", "amount": 20},
	"piston_stomp": {"name": "Piston Stomp", "slot": "ultimate", "target": "row", "pct": 110, "pierce": true, "stagger": 30},
	# Rimewyrm
	"rime_fang": {"name": "Rime Fang", "slot": "basic", "pct": 50, "hits": 2, "slow": [20, 2]},
	"frozen_heart": {"name": "Frozen Heart", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 20},
	"glacier_breath": {"name": "Glacier Breath", "slot": "ultimate", "target": "all", "pct": 75, "slow": [35, 3]},
	# Duskmaw
	"dusk_rake": {"name": "Dusk Rake", "slot": "basic", "pct": 95, "reach": true, "splash": 30},
	"shadow_pelt": {"name": "Shadow Pelt", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"nightfall_pounce": {"name": "Nightfall Pounce", "slot": "ultimate", "target": "all", "pct": 90, "reach": true, "self": {"dodge": true}},
	# Dawnshell
	"sunfan_wave": {"name": "Sunfan Wave", "slot": "basic", "pct": 85, "wash": 60, "splash": 30},
	"dawn_drink": {"name": "Dawn Drink", "slot": "passive", "kind": "drain", "pct": 25},
	"radiant_tide": {"name": "Radiant Tide", "slot": "ultimate", "target": "all", "pct": 85, "wash": 80, "team": {"heal_maxhp": 8, "cleanse": true}},
	# Briarking
	"tusk_thicket": {"name": "Tusk Thicket", "slot": "basic", "pct": 100, "splash": 30, "self": {"shield_atk": 30}},
	"crown_of_thorns": {"name": "Crown of Thorns", "slot": "passive", "kind": "thorns", "pct": 50},
	"bramble_throne": {"name": "Bramble Throne", "slot": "ultimate", "target": "all", "pct": 90, "self": {"shield_def": 200}, "taunt": 4.0},
	# Sturgebull
	"barbel_ram": {"name": "Barbel Ram", "slot": "basic", "pct": 95, "wash": 60, "splash": 30},
	"ancient_gills": {"name": "Ancient Gills", "slot": "passive", "kind": "drain", "pct": 20},
	"river_stampede": {"name": "River Stampede", "slot": "ultimate", "target": "row", "pct": 130, "wash": 100},
	# Mirewyrm
	"gill_spew": {"name": "Gill Spew", "slot": "basic", "pct": 90, "poison": [18, 4], "splash": 35},
	"rotting_slime": {"name": "Rotting Slime", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 25},
	"drowning_mire": {"name": "Drowning Mire", "slot": "ultimate", "target": "all", "pct": 85, "poison": [24, 5], "weaken": [25, 4]},
	# Condorgon
	"tusk_gale": {"name": "Tusk Gale", "slot": "basic", "pct": 100, "stagger": 20, "splash": 30},
	"high_shadow": {"name": "High Shadow", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"skyfall_stampede": {"name": "Skyfall Stampede", "slot": "ultimate", "target": "row", "pct": 120, "pierce": true, "stagger": 35},
	# Tuskursa
	"narwhal_lance": {"name": "Narwhal Lance", "slot": "basic", "pct": 95, "slow": [20, 3], "splash": 30},
	"polar_hunger": {"name": "Polar Hunger", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"endless_winter": {"name": "Endless Winter", "slot": "ultimate", "target": "all", "pct": 85, "slow": [35, 4], "team": {"haste": [25, 4]}},
	# Cobrilla
	"hood_slam": {"name": "Hood Slam", "slot": "basic", "pct": 95, "reach": true, "splash": 30},
	"jungle_king": {"name": "Jungle King", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"canopy_crush": {"name": "Canopy Crush", "slot": "ultimate", "target": "row", "pct": 140, "reach": true, "self": {"dodge": true}},
}

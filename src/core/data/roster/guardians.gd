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
}

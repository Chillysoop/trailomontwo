extends RefCounted
## Forest Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"mossmole": {"rarity": "common", "name": "Mossmole", "type": "Forest", "size": "small", "hauling": 0,
		"capabilities": {"clear": 2, "forage": 2}},
	"burlbear": {"rarity": "rare", "name": "Burlbear", "type": "Forest", "size": "large", "hauling": 140,
		"capabilities": {"strength": 3, "guard": 2}},
	"emberoak": {"rarity": "legendary", "name": "Emberoak", "type": "Forest", "size": "large", "hauling": 180,
		"capabilities": {"strength": 3, "guard": 3, "light": 2}},
	"acornet": {"rarity": "common", "name": "Acornet", "type": "Forest", "size": "small", "hauling": 0,
		"capabilities": {"forage": 3, "scout": 1}},
	"barkbeetle": {"rarity": "rare", "name": "Barkbeetle", "type": "Forest", "size": "medium", "hauling": 60,
		"capabilities": {"guard": 3, "strength": 1}},
}

const KITS := {
	"mossmole": {"role": "Guard", "hp": 400, "atk": 22, "def": 36, "spd": 2.1,
		"basic": "moss_burrow", "passive": "mossy_hide", "ultimate": "dig_in"},
	"burlbear": {"role": "Bruiser", "hp": 500, "atk": 33, "def": 32, "spd": 2.2,
		"basic": "burl_maul", "passive": "burl_bark", "ultimate": "timber_crash"},
	"emberoak": {"role": "Guard", "hp": 620, "atk": 32, "def": 52, "spd": 2.2,
		"basic": "ember_bough", "passive": "ember_bark", "ultimate": "heartfire"},
	"acornet": {"role": "Striker", "hp": 250, "atk": 27, "def": 14, "spd": 1.6,
		"basic": "acorn_pelt", "passive": "nutshell", "ultimate": "nut_barrage"},
	"barkbeetle": {"role": "Guard", "hp": 420, "atk": 24, "def": 44, "spd": 2.2,
		"basic": "horn_flip", "passive": "hard_shell", "ultimate": "carapace"},
}

const MOVES := {
	# Mossmole
	"moss_burrow": {"name": "Moss Burrow", "slot": "basic", "pct": 70, "self": {"shield_def": 40}},
	"mossy_hide": {"name": "Mossy Hide", "slot": "passive", "kind": "thorns", "pct": 30},
	"dig_in": {"name": "Dig In", "slot": "ultimate", "target": "none", "self": {"shield_def": 220}, "taunt": 3.0},
	# Burlbear
	"burl_maul": {"name": "Burl Maul", "slot": "basic", "pct": 100, "bonus": {"vs": "shielded", "amount": 25}},
	"burl_bark": {"name": "Burl Bark", "slot": "passive", "kind": "every", "n": 3, "shield_def": 90},
	"timber_crash": {"name": "Timber Crash", "slot": "ultimate", "target": "adjacent", "pct": 150, "self": {"shield_def": 60}},
	# Emberoak
	"ember_bough": {"name": "Ember Bough", "slot": "basic", "pct": 80, "def_pct": 40, "self": {"shield_def": 30}},
	"ember_bark": {"name": "Ember Bark", "slot": "passive", "kind": "thorns", "pct": 35},
	"heartfire": {"name": "Heartfire", "slot": "ultimate", "target": "none", "team": {"shield_def": 70, "shield_flat": 40}, "taunt": 4.0},
	# Acornet
	"acorn_pelt": {"name": "Acorn Pelt", "slot": "basic", "pct": 80, "self": {"shield_atk": 20}},
	"nutshell": {"name": "Nutshell", "slot": "passive", "kind": "thorns", "pct": 35, "while_shielded": true},
	"nut_barrage": {"name": "Nut Barrage", "slot": "ultimate", "target": "adjacent", "pct": 110, "self": {"shield_atk": 60}},
	# Barkbeetle
	"horn_flip": {"name": "Horn Flip", "slot": "basic", "pct": 75, "self": {"shield_def": 30}},
	"hard_shell": {"name": "Hard Shell", "slot": "passive", "kind": "start_shield", "def_pct": 200},
	"carapace": {"name": "Carapace", "slot": "ultimate", "target": "none", "self": {"shield_def": 180}, "team": {"shield_def": 30}, "taunt": 4.0},
}

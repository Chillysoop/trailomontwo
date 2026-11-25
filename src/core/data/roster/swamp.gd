extends RefCounted
## Swamp Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"sporetoad": {"rarity": "common", "name": "Sporetoad", "type": "Swamp", "size": "small", "hauling": 0,
		"capabilities": {"heal": 1, "forage": 2, "float": 1}},
	"bogjaw": {"rarity": "rare", "name": "Bogjaw", "type": "Swamp", "size": "large", "hauling": 110,
		"capabilities": {"strength": 2, "float": 2, "guard": 1}},
	"murkmoth": {"rarity": "common", "name": "Murkmoth", "type": "Swamp", "size": "small", "hauling": 0,
		"capabilities": {"scout": 2, "light": 1}},
	"gloomleech": {"rarity": "rare", "name": "Gloomleech", "type": "Swamp", "size": "medium", "hauling": 0,
		"capabilities": {"float": 2, "heal": 1}},
	"mirehydra": {"rarity": "legendary", "name": "Mirehydra", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {"float": 2, "strength": 2, "heal": 1}},
}

const KITS := {
	"sporetoad": {"role": "Support", "hp": 290, "atk": 25, "def": 16, "spd": 1.8,
		"basic": "spore_puff", "passive": "toxic_skin", "ultimate": "spore_storm"},
	"bogjaw": {"role": "Bruiser", "hp": 470, "atk": 33, "def": 30, "spd": 2.2,
		"basic": "bog_bite", "passive": "murk_jaws", "ultimate": "death_roll"},
	"murkmoth": {"role": "Support", "hp": 240, "atk": 25, "def": 11, "spd": 1.7,
		"basic": "dust_wing", "passive": "murk_scales", "ultimate": "moth_swarm"},
	"gloomleech": {"role": "Striker", "hp": 320, "atk": 33, "def": 16, "spd": 1.8,
		"basic": "leech_bite", "passive": "gloom_feed", "ultimate": "bloodrot"},
	"mirehydra": {"role": "Bruiser", "hp": 600, "atk": 36, "def": 32, "spd": 1.9,
		"basic": "triple_bite", "passive": "many_heads", "ultimate": "hydra_rot"},
}

const MOVES := {
	# Sporetoad
	"spore_puff": {"name": "Spore Puff", "slot": "basic", "pct": 60, "poison": [15, 4]},
	"toxic_skin": {"name": "Toxic Skin", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 20},
	"spore_storm": {"name": "Spore Storm", "slot": "ultimate", "target": "all", "poison": [20, 5]},
	# Bogjaw
	"bog_bite": {"name": "Bog Bite", "slot": "basic", "pct": 95, "weaken": [15, 3]},
	"murk_jaws": {"name": "Murk Jaws", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"death_roll": {"name": "Death Roll", "slot": "ultimate", "pct": 200, "poison": [30, 4], "weaken": [25, 4]},
	# Murkmoth
	"dust_wing": {"name": "Dust Wing", "slot": "basic", "pct": 60, "poison": [12, 4], "splash": 25},
	"murk_scales": {"name": "Murk Scales", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 15},
	"moth_swarm": {"name": "Moth Swarm", "slot": "ultimate", "target": "row", "poison": [20, 4], "weaken": [15, 3]},
	# Gloomleech
	"leech_bite": {"name": "Leech Bite", "slot": "basic", "pct": 85, "poison": [15, 3]},
	"gloom_feed": {"name": "Gloom Feed", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 25},
	"bloodrot": {"name": "Bloodrot", "slot": "ultimate", "target": "weakest", "pct": 180, "poison": [30, 4], "weaken": [20, 4]},
	# Mirehydra
	"triple_bite": {"name": "Triple Bite", "slot": "basic", "pct": 45, "hits": 3, "poison": [15, 4], "weaken": [10, 3]},
	"many_heads": {"name": "Many Heads", "slot": "passive", "kind": "every", "n": 3, "poison_all": [12, 4]},
	"hydra_rot": {"name": "Hydra Rot", "slot": "ultimate", "target": "all", "pct": 85, "poison": [22, 5], "weaken": [20, 4]},
}

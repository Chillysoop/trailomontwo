extends RefCounted
## Swamp Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"sporetoad": {"rarity": "common", "name": "Sporetoad", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "mirecroak",
		"capabilities": {"heal": 1, "forage": 2, "float": 1}},
	"bogjaw": {"rarity": "rare", "name": "Bogjaw", "type": "Swamp", "size": "large", "hauling": 110,
		"capabilities": {"strength": 2, "float": 2, "guard": 1}},
	"murkmoth": {"rarity": "common", "name": "Murkmoth", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "murkbat",
		"capabilities": {"scout": 2, "light": 1}},
	"gloomleech": {"rarity": "rare", "name": "Gloomleech", "type": "Swamp", "size": "medium", "hauling": 0,
		"capabilities": {"float": 2, "heal": 1}},
	"mirehydra": {"rarity": "legendary", "name": "Mirehydra", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {"float": 2, "strength": 2, "heal": 1}},
	# ----- Milestone 2 -----
	"mirecroak": {"rarity": "common", "name": "Mirecroak", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "gilatoad",
		"capabilities": {"heal": 1, "forage": 2, "float": 1}},
	"gilatoad": {"rarity": "rare", "name": "Gilatoad", "type": "Swamp", "size": "medium", "hauling": 0,
		"capabilities": {"forage": 2, "heal": 1, "guard": 1}},
	"murkbat": {"rarity": "common", "name": "Murkbat", "type": "Swamp", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "light": 1}},
	"anglenewt": {"rarity": "rare", "name": "Anglenewt", "type": "Swamp", "size": "medium", "hauling": 0,
		"capabilities": {"light": 3, "heal": 1, "float": 2}},
	"sluglet": {"rarity": "common", "name": "Sluglet", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "slimewt",
		"capabilities": {"forage": 2, "heal": 1}},
	"slimewt": {"rarity": "common", "name": "Slimewt", "type": "Swamp", "size": "medium", "hauling": 0, "evolves_to": "axolurk",
		"capabilities": {"forage": 2, "heal": 2}},
	"axolurk": {"rarity": "rare", "name": "Axolurk", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "heal": 2}},
	"skeetbird": {"rarity": "common", "name": "Skeetbird", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "needlehawk",
		"capabilities": {"scout": 3}},
	"needlehawk": {"rarity": "rare", "name": "Needlehawk", "type": "Swamp", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "light": 1}},
	"whiskerhog": {"rarity": "common", "name": "Whiskerhog", "type": "Swamp", "size": "medium", "hauling": 70, "evolves_to": "silthog",
		"capabilities": {"strength": 2, "float": 2}},
	"silthog": {"rarity": "rare", "name": "Silthog", "type": "Swamp", "size": "large", "hauling": 120,
		"capabilities": {"strength": 3, "float": 2}},
	"mudillo": {"rarity": "common", "name": "Mudillo", "type": "Swamp", "size": "medium", "hauling": 50, "evolves_to": "murkadillo",
		"capabilities": {"guard": 2, "steady": 1}},
	"murkadillo": {"rarity": "rare", "name": "Murkadillo", "type": "Swamp", "size": "large", "hauling": 110,
		"capabilities": {"guard": 3, "strength": 1}},
	"carrioncroc": {"rarity": "legendary", "name": "Carrioncroc", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {"strength": 3, "scout": 2}},
	"bogwidow": {"rarity": "legendary", "name": "Bogwidow", "type": "Swamp", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "forage": 2}},
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
	# ----- Milestone 2 -----
	"mirecroak": {"role": "Support", "hp": 320, "atk": 27, "def": 18, "spd": 1.8,
		"basic": "spore_croak", "passive": "fungal_skin", "ultimate": "rot_bloom"},
	"gilatoad": {"role": "Bruiser", "hp": 440, "atk": 33, "def": 28, "spd": 2.0,
		"basic": "venom_bite", "passive": "beaded_hide", "ultimate": "toxic_grip"},
	"murkbat": {"role": "Support", "hp": 280, "atk": 27, "def": 14, "spd": 1.6,
		"basic": "dusk_dust", "passive": "bat_scales", "ultimate": "night_swarm"},
	"anglenewt": {"role": "Support", "hp": 420, "atk": 34, "def": 22, "spd": 1.8,
		"basic": "lure_glow", "passive": "deep_lure", "ultimate": "abyss_light"},
	"sluglet": {"role": "Support", "hp": 320, "atk": 24, "def": 18, "spd": 1.9,
		"basic": "slime_spit", "passive": "slick_trail", "ultimate": "slime_wave"},
	"slimewt": {"role": "Support", "hp": 350, "atk": 28, "def": 22, "spd": 1.9,
		"basic": "acid_spit", "passive": "slime_coat", "ultimate": "acid_wave"},
	"axolurk": {"role": "Bruiser", "hp": 470, "atk": 34, "def": 30, "spd": 2.0,
		"basic": "gill_lash", "passive": "regrowth_rot", "ultimate": "lurk_flood"},
	"skeetbird": {"role": "Striker", "hp": 250, "atk": 29, "def": 12, "spd": 1.4,
		"basic": "needle_sip", "passive": "itch", "ultimate": "swarm_sting"},
	"needlehawk": {"role": "Striker", "hp": 330, "atk": 35, "def": 18, "spd": 1.6,
		"basic": "needle_dive", "passive": "blood_hunter", "ultimate": "fever_strike"},
	"whiskerhog": {"role": "Bruiser", "hp": 400, "atk": 27, "def": 28, "spd": 2.1,
		"basic": "mud_root", "passive": "silt_wallow", "ultimate": "mud_charge"},
	"silthog": {"role": "Bruiser", "hp": 500, "atk": 32, "def": 32, "spd": 2.1,
		"basic": "silt_gore", "passive": "bottom_feeder", "ultimate": "mudslide"},
	"mudillo": {"role": "Guard", "hp": 420, "atk": 22, "def": 40, "spd": 2.3,
		"basic": "mud_roll", "passive": "caked_plates", "ultimate": "bog_curl"},
	"murkadillo": {"role": "Guard", "hp": 520, "atk": 26, "def": 48, "spd": 2.3,
		"basic": "plated_bite", "passive": "mire_armor", "ultimate": "swamp_wall"},
	"carrioncroc": {"role": "Bruiser", "hp": 600, "atk": 36, "def": 34, "spd": 2.0,
		"basic": "carrion_jaw", "passive": "vulture_wings", "ultimate": "death_feast"},
	"bogwidow": {"role": "Striker", "hp": 440, "atk": 38, "def": 26, "spd": 1.6,
		"basic": "widow_fang", "passive": "silk_snare", "ultimate": "black_web"},
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
	# ----- Milestone 2 -----
	# Mirecroak
	"spore_croak": {"name": "Spore Croak", "slot": "basic", "pct": 65, "poison": [15, 4], "splash": 25},
	"fungal_skin": {"name": "Fungal Skin", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 20},
	"rot_bloom": {"name": "Rot Bloom", "slot": "ultimate", "target": "all", "poison": [22, 5], "weaken": [10, 3]},
	# Gilatoad
	"venom_bite": {"name": "Venom Bite", "slot": "basic", "pct": 90, "poison": [20, 4]},
	"beaded_hide": {"name": "Beaded Hide", "slot": "passive", "kind": "every", "n": 3, "poison_all": [12, 4]},
	"toxic_grip": {"name": "Toxic Grip", "slot": "ultimate", "target": "adjacent", "pct": 140, "poison": [25, 4], "weaken": [20, 3]},
	# Murkbat
	"dusk_dust": {"name": "Dusk Dust", "slot": "basic", "pct": 60, "poison": [14, 4], "splash": 30},
	"bat_scales": {"name": "Bat Scales", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 20},
	"night_swarm": {"name": "Night Swarm", "slot": "ultimate", "target": "row", "poison": [22, 4], "weaken": [20, 3]},
	# Anglenewt
	"lure_glow": {"name": "Lure Glow", "slot": "basic", "pct": 80, "weaken": [25, 4], "poison": [12, 3]},
	"deep_lure": {"name": "Deep Lure", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"abyss_light": {"name": "Abyss Light", "slot": "ultimate", "target": "all", "pct": 60, "weaken": [30, 4]},
	# Sluglet
	"slime_spit": {"name": "Slime Spit", "slot": "basic", "pct": 75, "weaken": [15, 3]},
	"slick_trail": {"name": "Slick Trail", "slot": "passive", "kind": "every", "n": 3, "poison_all": [8, 4]},
	"slime_wave": {"name": "Slime Wave", "slot": "ultimate", "target": "row", "pct": 70, "weaken": [25, 4]},
	# Slimewt
	"acid_spit": {"name": "Acid Spit", "slot": "basic", "pct": 70, "weaken": [20, 3], "poison": [10, 3]},
	"slime_coat": {"name": "Slime Coat", "slot": "passive", "kind": "every", "n": 3, "poison_all": [10, 4]},
	"acid_wave": {"name": "Acid Wave", "slot": "ultimate", "target": "row", "pct": 90, "weaken": [30, 4]},
	# Axolurk
	"gill_lash": {"name": "Gill Lash", "slot": "basic", "pct": 90, "weaken": [20, 3], "splash": 25},
	"regrowth_rot": {"name": "Regrowth Rot", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"lurk_flood": {"name": "Lurk Flood", "slot": "ultimate", "target": "all", "pct": 75, "poison": [20, 4], "weaken": [20, 4]},
	# Skeetbird
	"needle_sip": {"name": "Needle Sip", "slot": "basic", "pct": 70, "poison": [12, 3]},
	"itch": {"name": "Itch", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 25},
	"swarm_sting": {"name": "Swarm Sting", "slot": "ultimate", "target": "weakest", "pct": 150, "poison": [25, 4]},
	# Needlehawk
	"needle_dive": {"name": "Needle Dive", "slot": "basic", "pct": 85, "poison": [15, 4]},
	"blood_hunter": {"name": "Blood Hunter", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 30},
	"fever_strike": {"name": "Fever Strike", "slot": "ultimate", "target": "weakest", "pct": 200, "poison": [30, 4], "weaken": [20, 3]},
	# Whiskerhog
	"mud_root": {"name": "Mud Root", "slot": "basic", "pct": 85, "weaken": [15, 3]},
	"silt_wallow": {"name": "Silt Wallow", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 20},
	"mud_charge": {"name": "Mud Charge", "slot": "ultimate", "target": "adjacent", "pct": 130, "weaken": [25, 3]},
	# Silthog
	"silt_gore": {"name": "Silt Gore", "slot": "basic", "pct": 95, "weaken": [20, 3], "poison": [10, 3]},
	"bottom_feeder": {"name": "Bottom Feeder", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"mudslide": {"name": "Mudslide", "slot": "ultimate", "target": "row", "pct": 120, "weaken": [30, 4]},
	# Mudillo
	"mud_roll": {"name": "Mud Roll", "slot": "basic", "pct": 70, "weaken": [15, 3], "self": {"shield_def": 25}},
	"caked_plates": {"name": "Caked Plates", "slot": "passive", "kind": "armor_low", "amount": 20},
	"bog_curl": {"name": "Bog Curl", "slot": "ultimate", "target": "adjacent", "pct": 90, "weaken": [25, 4], "self": {"shield_def": 120}},
	# Murkadillo
	"plated_bite": {"name": "Plated Bite", "slot": "basic", "pct": 80, "weaken": [20, 3], "self": {"shield_def": 30}},
	"mire_armor": {"name": "Mire Armor", "slot": "passive", "kind": "armor_low", "amount": 30},
	"swamp_wall": {"name": "Swamp Wall", "slot": "ultimate", "target": "row", "pct": 80, "weaken": [30, 4], "self": {"shield_def": 150}},
	# Carrioncroc
	"carrion_jaw": {"name": "Carrion Jaw", "slot": "basic", "pct": 95, "poison": [20, 4], "weaken": [15, 3]},
	"vulture_wings": {"name": "Vulture Wings", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 30},
	"death_feast": {"name": "Death Feast", "slot": "ultimate", "target": "all", "pct": 90, "poison": [25, 5], "weaken": [25, 4]},
	# Bogwidow
	"widow_fang": {"name": "Widow Fang", "slot": "basic", "pct": 85, "poison": [22, 4]},
	"silk_snare": {"name": "Silk Snare", "slot": "passive", "kind": "every", "n": 3, "poison_all": [14, 4]},
	"black_web": {"name": "Black Web", "slot": "ultimate", "target": "all", "pct": 70, "poison": [28, 5], "weaken": [20, 4]},
}

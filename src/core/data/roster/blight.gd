extends RefCounted
## Blight Trailomon: the Dark dust biome. Each keeps a habitat type and has "biome": "Blight".
## They live only in Blight terrain (from crossing 3), five per habitat.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	# ----- Forest -----
	"thornrat": {"rarity": "common", "name": "Thornrat", "type": "Forest", "size": "small", "hauling": 0, "evolves_to": "blightquill", "biome": "Blight",
		"capabilities": {"scout": 2, "guard": 1}},
	"blightquill": {"rarity": "rare", "name": "Blightquill", "type": "Forest", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 2, "guard": 2, "strength": 1}},
	"ashbadger": {"rarity": "common", "name": "Ashbadger", "type": "Forest", "size": "medium", "hauling": 60, "biome": "Blight",
		"capabilities": {"strength": 2, "guard": 2}},
	"gloomfawn": {"rarity": "common", "name": "Gloomfawn", "type": "Forest", "size": "small", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 2, "forage": 2}},
	"wraithelk": {"rarity": "legendary", "name": "Wraithelk", "type": "Forest", "size": "large", "hauling": 150, "biome": "Blight",
		"capabilities": {"strength": 3, "guard": 3, "scout": 1}},
	# ----- River -----
	"murkotter": {"rarity": "common", "name": "Murkotter", "type": "River", "size": "small", "hauling": 0, "evolves_to": "lampreotter", "biome": "Blight",
		"capabilities": {"float": 3, "forage": 1}},
	"lampreotter": {"rarity": "rare", "name": "Lampreotter", "type": "River", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"float": 3, "forage": 2}},
	"ashheron": {"rarity": "common", "name": "Ashheron", "type": "River", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"float": 2, "heal": 2}},
	"voidkoi": {"rarity": "rare", "name": "Voidkoi", "type": "River", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"float": 3, "light": 2, "heal": 1}},
	"gloomwhale": {"rarity": "legendary", "name": "Gloomwhale", "type": "River", "size": "large", "hauling": 200, "biome": "Blight",
		"capabilities": {"float": 3, "strength": 3}},
	# ----- Swamp -----
	"rotnewt": {"rarity": "common", "name": "Rotnewt", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "stingmander", "biome": "Blight",
		"capabilities": {"float": 2, "scout": 1}},
	"stingmander": {"rarity": "rare", "name": "Stingmander", "type": "Swamp", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"float": 2, "scout": 2}},
	"leechmole": {"rarity": "common", "name": "Leechmole", "type": "Swamp", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"float": 2, "forage": 2}},
	"carrionstork": {"rarity": "common", "name": "Carrionstork", "type": "Swamp", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"float": 2, "scout": 2}},
	"plaguebat": {"rarity": "rare", "name": "Plaguebat", "type": "Swamp", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 3, "light": 1}},
	# ----- Mountain -----
	"cindergoat": {"rarity": "common", "name": "Cindergoat", "type": "Mountain", "size": "medium", "hauling": 80, "evolves_to": "obsidiram", "biome": "Blight",
		"capabilities": {"strength": 3, "steady": 2}},
	"obsidiram": {"rarity": "rare", "name": "Obsidiram", "type": "Mountain", "size": "large", "hauling": 140, "biome": "Blight",
		"capabilities": {"strength": 3, "steady": 3}},
	"shardhawk": {"rarity": "common", "name": "Shardhawk", "type": "Mountain", "size": "small", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 3}},
	"drillrhino": {"rarity": "rare", "name": "Drillrhino", "type": "Mountain", "size": "large", "hauling": 120, "biome": "Blight",
		"capabilities": {"strength": 3, "clear": 2}},
	"scorbison": {"rarity": "legendary", "name": "Scorbison", "type": "Mountain", "size": "large", "hauling": 180, "biome": "Blight",
		"capabilities": {"strength": 3, "steady": 3, "clear": 1}},
	# ----- Snow -----
	"ashkit": {"rarity": "common", "name": "Ashkit", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "crowvix", "biome": "Blight",
		"capabilities": {"cold": 2, "scout": 2}},
	"crowvix": {"rarity": "rare", "name": "Crowvix", "type": "Snow", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"cold": 3, "scout": 3}},
	"sootseal": {"rarity": "common", "name": "Sootseal", "type": "Snow", "size": "medium", "hauling": 60, "biome": "Blight",
		"capabilities": {"cold": 3, "float": 2}},
	"nightshrew": {"rarity": "common", "name": "Nightshrew", "type": "Snow", "size": "small", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 3, "cold": 1}},
	"lupemoose": {"rarity": "rare", "name": "Lupemoose", "type": "Snow", "size": "large", "hauling": 130, "biome": "Blight",
		"capabilities": {"cold": 3, "strength": 3}},
	# ----- Jungle -----
	"howlbat": {"rarity": "common", "name": "Howlbat", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "vampape", "biome": "Blight",
		"capabilities": {"scout": 3, "clear": 1}},
	"vampape": {"rarity": "rare", "name": "Vampape", "type": "Jungle", "size": "large", "hauling": 100, "biome": "Blight",
		"capabilities": {"strength": 3, "clear": 2}},
	"mantigecko": {"rarity": "common", "name": "Mantigecko", "type": "Jungle", "size": "small", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 2, "clear": 2}},
	"cobrapard": {"rarity": "rare", "name": "Cobrapard", "type": "Jungle", "size": "medium", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 3, "clear": 2}},
	"mandrilion": {"rarity": "legendary", "name": "Mandrilion", "type": "Jungle", "size": "large", "hauling": 0, "biome": "Blight",
		"capabilities": {"scout": 3, "clear": 3}},
}

const KITS := {
	# ----- Forest -----
	"thornrat": {"role": "Striker", "hp": 270, "atk": 30, "def": 16, "spd": 1.3,
		"basic": "ash_quill", "passive": "soot_spines", "ultimate": "quill_burst"},
	"blightquill": {"role": "Bruiser", "hp": 420, "atk": 33, "def": 26, "spd": 1.6,
		"basic": "crystal_gore", "passive": "dark_spines", "ultimate": "shard_stampede"},
	"ashbadger": {"role": "Guard", "hp": 430, "atk": 22, "def": 38, "spd": 2.2,
		"basic": "soot_swipe", "passive": "cinder_hide", "ultimate": "ash_burrow"},
	"gloomfawn": {"role": "Support", "hp": 290, "atk": 24, "def": 18, "spd": 1.5,
		"basic": "hush_kick", "passive": "bat_ears", "ultimate": "night_canopy"},
	"wraithelk": {"role": "Guard", "hp": 620, "atk": 30, "def": 48, "spd": 2.2,
		"basic": "raven_antler", "passive": "black_bramble", "ultimate": "dusk_rut"},
	# ----- River -----
	"murkotter": {"role": "Striker", "hp": 270, "atk": 30, "def": 14, "spd": 1.3,
		"basic": "ink_bite", "passive": "murk_drink", "ultimate": "black_current"},
	"lampreotter": {"role": "Striker", "hp": 350, "atk": 36, "def": 20, "spd": 1.4,
		"basic": "leech_maw", "passive": "blood_drink", "ultimate": "undertow_maw"},
	"ashheron": {"role": "Healer", "hp": 300, "atk": 24, "def": 16, "spd": 1.6,
		"basic": "ash_preen", "passive": "still_water", "ultimate": "grey_rain"},
	"voidkoi": {"role": "Healer", "hp": 370, "atk": 28, "def": 22, "spd": 1.5,
		"basic": "void_lure", "passive": "deep_lantern", "ultimate": "abyss_tide"},
	"gloomwhale": {"role": "Bruiser", "hp": 620, "atk": 36, "def": 30, "spd": 1.9,
		"basic": "abyss_gulp", "passive": "dark_baleen", "ultimate": "deep_dark"},
	# ----- Swamp -----
	"rotnewt": {"role": "Striker", "hp": 260, "atk": 30, "def": 14, "spd": 1.3,
		"basic": "rot_nip", "passive": "tox_skin", "ultimate": "venom_lash"},
	"stingmander": {"role": "Striker", "hp": 350, "atk": 35, "def": 20, "spd": 1.4,
		"basic": "stinger_jab", "passive": "venom_glands", "ultimate": "death_sting"},
	"leechmole": {"role": "Support", "hp": 320, "atk": 24, "def": 20, "spd": 1.6,
		"basic": "sucker_bite", "passive": "slime_rings", "ultimate": "mire_suckle"},
	"carrionstork": {"role": "Bruiser", "hp": 360, "atk": 27, "def": 22, "spd": 1.6,
		"basic": "carrion_peck", "passive": "grave_feeder", "ultimate": "vulture_dive"},
	"plaguebat": {"role": "Support", "hp": 360, "atk": 30, "def": 20, "spd": 1.5,
		"basic": "plague_wing", "passive": "plague_dust", "ultimate": "black_swarm"},
	# ----- Mountain -----
	"cindergoat": {"role": "Guard", "hp": 420, "atk": 23, "def": 40, "spd": 2.2,
		"basic": "cinder_butt", "passive": "obsidian_plates", "ultimate": "rockfall_stand"},
	"obsidiram": {"role": "Guard", "hp": 540, "atk": 27, "def": 50, "spd": 2.3,
		"basic": "glass_horn", "passive": "volcanic_scales", "ultimate": "black_avalanche"},
	"shardhawk": {"role": "Striker", "hp": 250, "atk": 32, "def": 12, "spd": 1.3,
		"basic": "crystal_talon", "passive": "high_sight", "ultimate": "shard_dive"},
	"drillrhino": {"role": "Bruiser", "hp": 450, "atk": 33, "def": 30, "spd": 1.8,
		"basic": "drill_horn", "passive": "tunnel_hide", "ultimate": "quake_charge"},
	"scorbison": {"role": "Bruiser", "hp": 600, "atk": 39, "def": 36, "spd": 2.0,
		"basic": "sting_horn", "passive": "black_carapace", "ultimate": "dark_stampede"},
	# ----- Snow -----
	"ashkit": {"role": "Striker", "hp": 265, "atk": 30, "def": 14, "spd": 1.4,
		"basic": "frost_snap", "passive": "crow_cunning", "ultimate": "cold_ambush"},
	"crowvix": {"role": "Striker", "hp": 345, "atk": 36, "def": 20, "spd": 1.4,
		"basic": "raven_rend", "passive": "murder_call", "ultimate": "black_blizzard"},
	"sootseal": {"role": "Guard", "hp": 420, "atk": 22, "def": 38, "spd": 2.2,
		"basic": "ice_flipper", "passive": "soot_blubber", "ultimate": "dark_floe"},
	"nightshrew": {"role": "Support", "hp": 270, "atk": 26, "def": 14, "spd": 1.4,
		"basic": "echo_nip", "passive": "night_chill", "ultimate": "hoar_shriek"},
	"lupemoose": {"role": "Bruiser", "hp": 460, "atk": 33, "def": 28, "spd": 1.8,
		"basic": "rime_maul", "passive": "winter_hunger", "ultimate": "starving_howl"},
	# ----- Jungle -----
	"howlbat": {"role": "Striker", "hp": 265, "atk": 30, "def": 14, "spd": 1.3,
		"basic": "long_grab", "passive": "night_howl", "ultimate": "swoop_snatch"},
	"vampape": {"role": "Bruiser", "hp": 470, "atk": 34, "def": 26, "spd": 1.7,
		"basic": "knuckle_drop", "passive": "dusk_chest", "ultimate": "canopy_terror"},
	"mantigecko": {"role": "Striker", "hp": 260, "atk": 31, "def": 14, "spd": 1.3,
		"basic": "scythe_flick", "passive": "still_hunter", "ultimate": "twin_scythe"},
	"cobrapard": {"role": "Striker", "hp": 340, "atk": 37, "def": 18, "spd": 1.4,
		"basic": "hood_strike", "passive": "shadow_coil", "ultimate": "panther_venom"},
	"mandrilion": {"role": "Striker", "hp": 470, "atk": 42, "def": 26, "spd": 1.5,
		"basic": "mane_pounce", "passive": "apex_dusk", "ultimate": "eclipse_hunt"},
}

const MOVES := {
	# ----- Forest -----
	# Thornrat
	"ash_quill": {"name": "Ash Quill", "slot": "basic", "pct": 85, "self": {"shield_atk": 15}},
	"soot_spines": {"name": "Soot Spines", "slot": "passive", "kind": "thorns", "pct": 40},
	"quill_burst": {"name": "Quill Burst", "slot": "ultimate", "target": "row", "pct": 110, "self": {"shield_atk": 50}},
	# Blightquill
	"crystal_gore": {"name": "Crystal Gore", "slot": "basic", "pct": 95, "self": {"shield_atk": 20}},
	"dark_spines": {"name": "Dark Spines", "slot": "passive", "kind": "thorns", "pct": 55},
	"shard_stampede": {"name": "Shard Stampede", "slot": "ultimate", "target": "row", "pct": 120, "self": {"shield_def": 90}, "taunt": 3.5},
	# Ashbadger
	"soot_swipe": {"name": "Soot Swipe", "slot": "basic", "pct": 75, "self": {"shield_def": 25}},
	"cinder_hide": {"name": "Cinder Hide", "slot": "passive", "kind": "thorns", "pct": 35},
	"ash_burrow": {"name": "Ash Burrow", "slot": "ultimate", "target": "none", "self": {"shield_def": 200}, "taunt": 3.5},
	# Gloomfawn
	"hush_kick": {"name": "Hush Kick", "slot": "basic", "pct": 65, "ally": {"shield_atk": 45}},
	"bat_ears": {"name": "Bat Ears", "slot": "passive", "kind": "every", "n": 3, "shield_def": 70},
	"night_canopy": {"name": "Night Canopy", "slot": "ultimate", "target": "none", "team": {"shield_def": 45}},
	# Wraithelk
	"raven_antler": {"name": "Raven Antler", "slot": "basic", "pct": 85, "self": {"shield_def": 35}},
	"black_bramble": {"name": "Black Bramble", "slot": "passive", "kind": "thorns", "pct": 60, "while_shielded": true},
	"dusk_rut": {"name": "Dusk Rut", "slot": "ultimate", "target": "all", "pct": 80, "self": {"shield_def": 160}, "taunt": 4.0},
	# ----- River -----
	# Murkotter
	"ink_bite": {"name": "Ink Bite", "slot": "basic", "pct": 85, "wash": 50},
	"murk_drink": {"name": "Murk Drink", "slot": "passive", "kind": "drain", "pct": 20},
	"black_current": {"name": "Black Current", "slot": "ultimate", "target": "weakest", "pct": 190, "wash": 80},
	# Lampreotter
	"leech_maw": {"name": "Leech Maw", "slot": "basic", "pct": 50, "hits": 2, "wash": 30},
	"blood_drink": {"name": "Blood Drink", "slot": "passive", "kind": "drain", "pct": 30},
	"undertow_maw": {"name": "Undertow Maw", "slot": "ultimate", "target": "weakest", "pct": 220, "wash": 120},
	# Ashheron
	"ash_preen": {"name": "Ash Preen", "slot": "basic", "pct": 65, "ally": {"heal_atk": 65}},
	"still_water": {"name": "Still Water", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 60},
	"grey_rain": {"name": "Grey Rain", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12, "cleanse": true}},
	# Voidkoi
	"void_lure": {"name": "Void Lure", "slot": "basic", "pct": 70, "ally": {"heal_atk": 75}},
	"deep_lantern": {"name": "Deep Lantern", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 75},
	"abyss_tide": {"name": "Abyss Tide", "slot": "ultimate", "target": "all", "pct": 60, "team": {"heal_maxhp": 12, "cleanse": true}},
	# Gloomwhale
	"abyss_gulp": {"name": "Abyss Gulp", "slot": "basic", "pct": 90, "wash": 70, "self": {"heal_atk": 20}},
	"dark_baleen": {"name": "Dark Baleen", "slot": "passive", "kind": "drain", "pct": 30},
	"deep_dark": {"name": "Deep Dark", "slot": "ultimate", "target": "row", "pct": 130, "wash": 120, "team": {"heal_maxhp": 6}},
	# ----- Swamp -----
	# Rotnewt
	"rot_nip": {"name": "Rot Nip", "slot": "basic", "pct": 75, "poison": [12, 4]},
	"tox_skin": {"name": "Tox Skin", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 25},
	"venom_lash": {"name": "Venom Lash", "slot": "ultimate", "target": "weakest", "pct": 170, "poison": [25, 4]},
	# Stingmander
	"stinger_jab": {"name": "Stinger Jab", "slot": "basic", "pct": 50, "hits": 2, "poison": [10, 4]},
	"venom_glands": {"name": "Venom Glands", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 30},
	"death_sting": {"name": "Death Sting", "slot": "ultimate", "target": "weakest", "pct": 200, "poison": [30, 4], "weaken": [20, 3]},
	# Leechmole
	"sucker_bite": {"name": "Sucker Bite", "slot": "basic", "pct": 70, "weaken": [20, 3]},
	"slime_rings": {"name": "Slime Rings", "slot": "passive", "kind": "every", "n": 3, "poison_all": [10, 4]},
	"mire_suckle": {"name": "Mire Suckle", "slot": "ultimate", "target": "all", "pct": 55, "weaken": [25, 4]},
	# Carrionstork
	"carrion_peck": {"name": "Carrion Peck", "slot": "basic", "pct": 90, "poison": [14, 4]},
	"grave_feeder": {"name": "Grave Feeder", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"vulture_dive": {"name": "Vulture Dive", "slot": "ultimate", "target": "row", "pct": 100, "poison": [20, 4], "weaken": [20, 3]},
	# Plaguebat
	"plague_wing": {"name": "Plague Wing", "slot": "basic", "pct": 60, "poison": [14, 4], "splash": 30},
	"plague_dust": {"name": "Plague Dust", "slot": "passive", "kind": "every", "n": 3, "poison_all": [14, 4]},
	"black_swarm": {"name": "Black Swarm", "slot": "ultimate", "target": "all", "pct": 70, "poison": [24, 5], "weaken": [20, 4]},
	# ----- Mountain -----
	# Cindergoat
	"cinder_butt": {"name": "Cinder Butt", "slot": "basic", "pct": 75, "stagger": 20, "self": {"shield_def": 25}},
	"obsidian_plates": {"name": "Obsidian Plates", "slot": "passive", "kind": "armor_low", "amount": 20},
	"rockfall_stand": {"name": "Rockfall Stand", "slot": "ultimate", "target": "row", "pct": 80, "stagger": 35, "self": {"shield_def": 120}},
	# Obsidiram
	"glass_horn": {"name": "Glass Horn", "slot": "basic", "pct": 80, "stagger": 25, "self": {"shield_def": 30}},
	"volcanic_scales": {"name": "Volcanic Scales", "slot": "passive", "kind": "armor_low", "amount": 30},
	"black_avalanche": {"name": "Black Avalanche", "slot": "ultimate", "target": "row", "pct": 100, "stagger": 45, "self": {"shield_def": 150}},
	# Shardhawk
	"crystal_talon": {"name": "Crystal Talon", "slot": "basic", "pct": 85, "pierce": true},
	"high_sight": {"name": "High Sight", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"shard_dive": {"name": "Shard Dive", "slot": "ultimate", "target": "weakest", "pct": 180, "pierce": true},
	# Drillrhino
	"drill_horn": {"name": "Drill Horn", "slot": "basic", "pct": 95, "pierce": true},
	"tunnel_hide": {"name": "Tunnel Hide", "slot": "passive", "kind": "armor_low", "amount": 20},
	"quake_charge": {"name": "Quake Charge", "slot": "ultimate", "target": "row", "pct": 130, "pierce": true, "stagger": 35},
	# Scorbison
	"sting_horn": {"name": "Sting Horn", "slot": "basic", "pct": 95, "pierce": true, "stagger": 20},
	"black_carapace": {"name": "Black Carapace", "slot": "passive", "kind": "armor_low", "amount": 30},
	"dark_stampede": {"name": "Dark Stampede", "slot": "ultimate", "target": "all", "pct": 95, "pierce": true, "stagger": 35},
	# ----- Snow -----
	# Ashkit
	"frost_snap": {"name": "Frost Snap", "slot": "basic", "pct": 80, "slow": [15, 2]},
	"crow_cunning": {"name": "Crow Cunning", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"cold_ambush": {"name": "Cold Ambush", "slot": "ultimate", "target": "weakest", "pct": 170, "slow": [30, 3]},
	# Crowvix
	"raven_rend": {"name": "Raven Rend", "slot": "basic", "pct": 50, "hits": 2, "slow": [20, 2]},
	"murder_call": {"name": "Murder Call", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 30},
	"black_blizzard": {"name": "Black Blizzard", "slot": "ultimate", "target": "row", "pct": 120, "slow": [35, 3]},
	# Sootseal
	"ice_flipper": {"name": "Ice Flipper", "slot": "basic", "pct": 70, "slow": [20, 2], "self": {"shield_def": 25}},
	"soot_blubber": {"name": "Soot Blubber", "slot": "passive", "kind": "armor_low", "amount": 20},
	"dark_floe": {"name": "Dark Floe", "slot": "ultimate", "target": "row", "pct": 70, "slow": [35, 3], "self": {"shield_def": 110}},
	# Nightshrew
	"echo_nip": {"name": "Echo Nip", "slot": "basic", "pct": 65, "slow": [15, 2], "splash": 25},
	"night_chill": {"name": "Night Chill", "slot": "passive", "kind": "every", "n": 3, "team_haste": [20, 3]},
	"hoar_shriek": {"name": "Hoar Shriek", "slot": "ultimate", "target": "all", "pct": 50, "slow": [25, 3], "team": {"haste": [20, 4]}},
	# Lupemoose
	"rime_maul": {"name": "Rime Maul", "slot": "basic", "pct": 90, "slow": [20, 3]},
	"winter_hunger": {"name": "Winter Hunger", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"starving_howl": {"name": "Starving Howl", "slot": "ultimate", "target": "row", "pct": 110, "slow": [35, 3], "team": {"haste": [20, 4]}},
	# ----- Jungle -----
	# Howlbat
	"long_grab": {"name": "Long Grab", "slot": "basic", "pct": 80, "reach": true},
	"night_howl": {"name": "Night Howl", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"swoop_snatch": {"name": "Swoop Snatch", "slot": "ultimate", "target": "weakest", "pct": 190, "self": {"dodge": true}},
	# Vampape
	"knuckle_drop": {"name": "Knuckle Drop", "slot": "basic", "pct": 90, "reach": true},
	"dusk_chest": {"name": "Dusk Chest", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 45},
	"canopy_terror": {"name": "Canopy Terror", "slot": "ultimate", "target": "row", "pct": 125, "reach": true, "self": {"dodge": true}},
	# Mantigecko
	"scythe_flick": {"name": "Scythe Flick", "slot": "basic", "pct": 85, "self": {"dodge": true}},
	"still_hunter": {"name": "Still Hunter", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 30},
	"twin_scythe": {"name": "Twin Scythe", "slot": "ultimate", "target": "weakest", "pct": 200, "reach": true},
	# Cobrapard
	"hood_strike": {"name": "Hood Strike", "slot": "basic", "pct": 90, "reach": true},
	"shadow_coil": {"name": "Shadow Coil", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"panther_venom": {"name": "Panther Ambush", "slot": "ultimate", "target": "weakest", "pct": 230, "self": {"dodge": true}},
	# Mandrilion
	"mane_pounce": {"name": "Mane Pounce", "slot": "basic", "pct": 95, "reach": true},
	"apex_dusk": {"name": "Apex Dusk", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 60},
	"eclipse_hunt": {"name": "Eclipse Hunt", "slot": "ultimate", "target": "row", "pct": 140, "reach": true, "self": {"dodge": true}},
}

extends RefCounted
## Glow Trailomon: the Light dust biome. Each keeps a habitat type and has "biome": "Glow".
## They live only in Glow terrain (from crossing 3), five per habitat.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	# ----- Forest -----
	"dawnhare": {"rarity": "common", "name": "Dawnhare", "type": "Forest", "size": "small", "hauling": 0, "evolves_to": "solstag", "biome": "Glow",
		"capabilities": {"scout": 2, "forage": 2}},
	"solstag": {"rarity": "rare", "name": "Solstag", "type": "Forest", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"scout": 2, "forage": 2, "guard": 1}},
	"honeybruin": {"rarity": "common", "name": "Honeybruin", "type": "Forest", "size": "medium", "hauling": 80, "biome": "Glow",
		"capabilities": {"strength": 2, "forage": 2}},
	"glintbeetle": {"rarity": "common", "name": "Glintbeetle", "type": "Forest", "size": "small", "hauling": 0, "biome": "Glow",
		"capabilities": {"guard": 2, "light": 2}},
	"aurelion": {"rarity": "legendary", "name": "Aurelion", "type": "Forest", "size": "large", "hauling": 150, "biome": "Glow",
		"capabilities": {"strength": 3, "guard": 3, "light": 1}},
	# ----- River -----
	"shimmerpup": {"rarity": "common", "name": "Shimmerpup", "type": "River", "size": "small", "hauling": 0, "evolves_to": "seraseal", "biome": "Glow",
		"capabilities": {"float": 3, "heal": 1}},
	"seraseal": {"rarity": "rare", "name": "Seraseal", "type": "River", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"float": 3, "heal": 2}},
	"glimmerray": {"rarity": "common", "name": "Glimmerray", "type": "River", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"float": 3, "light": 2}},
	"pearlotter": {"rarity": "rare", "name": "Pearlotter", "type": "River", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"float": 3, "forage": 2}},
	"lumidolphin": {"rarity": "legendary", "name": "Lumidolphin", "type": "River", "size": "large", "hauling": 200, "biome": "Glow",
		"capabilities": {"float": 3, "heal": 3}},
	# ----- Swamp -----
	"lumifrog": {"rarity": "common", "name": "Lumifrog", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "lanternewt", "biome": "Glow",
		"capabilities": {"float": 2, "light": 2}},
	"lanternewt": {"rarity": "rare", "name": "Lanternewt", "type": "Swamp", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"float": 2, "light": 3}},
	"sunsnapper": {"rarity": "common", "name": "Sunsnapper", "type": "Swamp", "size": "medium", "hauling": 60, "biome": "Glow",
		"capabilities": {"float": 2, "strength": 2}},
	"goldleech": {"rarity": "common", "name": "Goldleech", "type": "Swamp", "size": "small", "hauling": 0, "biome": "Glow",
		"capabilities": {"float": 2, "forage": 1}},
	"hippofly": {"rarity": "rare", "name": "Hippofly", "type": "Swamp", "size": "large", "hauling": 120, "biome": "Glow",
		"capabilities": {"strength": 3, "float": 2}},
	# ----- Mountain -----
	"quartzmot": {"rarity": "common", "name": "Quartzmot", "type": "Mountain", "size": "medium", "hauling": 60, "evolves_to": "halotaur", "biome": "Glow",
		"capabilities": {"strength": 2, "steady": 2}},
	"halotaur": {"rarity": "rare", "name": "Halotaur", "type": "Mountain", "size": "large", "hauling": 140, "biome": "Glow",
		"capabilities": {"strength": 3, "steady": 3}},
	"prismfalcon": {"rarity": "common", "name": "Prismfalcon", "type": "Mountain", "size": "small", "hauling": 0, "biome": "Glow",
		"capabilities": {"scout": 3}},
	"lynxcrest": {"rarity": "rare", "name": "Lynxcrest", "type": "Mountain", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"scout": 3, "steady": 2}},
	"sunmammoth": {"rarity": "legendary", "name": "Sunmammoth", "type": "Mountain", "size": "large", "hauling": 220, "biome": "Glow",
		"capabilities": {"strength": 3, "steady": 3, "clear": 1}},
	# ----- Snow -----
	"lumming": {"rarity": "common", "name": "Lumming", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "aurorlynx", "biome": "Glow",
		"capabilities": {"cold": 2, "scout": 2}},
	"aurorlynx": {"rarity": "rare", "name": "Aurorlynx", "type": "Snow", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"cold": 3, "scout": 3}},
	"candlepine": {"rarity": "common", "name": "Candlepine", "type": "Snow", "size": "medium", "hauling": 60, "biome": "Glow",
		"capabilities": {"cold": 3, "light": 2}},
	"chimecrane": {"rarity": "common", "name": "Chimecrane", "type": "Snow", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"cold": 2, "scout": 2}},
	"caribear": {"rarity": "rare", "name": "Caribear", "type": "Snow", "size": "large", "hauling": 130, "biome": "Glow",
		"capabilities": {"cold": 3, "strength": 3}},
	# ----- Jungle -----
	"sunmarmoset": {"rarity": "common", "name": "Sunmarmoset", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "lionbaboon", "biome": "Glow",
		"capabilities": {"scout": 3, "clear": 1}},
	"lionbaboon": {"rarity": "rare", "name": "Lionbaboon", "type": "Jungle", "size": "large", "hauling": 100, "biome": "Glow",
		"capabilities": {"strength": 3, "clear": 2}},
	"quetzaloth": {"rarity": "common", "name": "Quetzaloth", "type": "Jungle", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"scout": 2, "clear": 2}},
	"butterpard": {"rarity": "rare", "name": "Butterpard", "type": "Jungle", "size": "medium", "hauling": 0, "biome": "Glow",
		"capabilities": {"scout": 3, "clear": 2}},
	"solaconda": {"rarity": "legendary", "name": "Solaconda", "type": "Jungle", "size": "large", "hauling": 0, "biome": "Glow",
		"capabilities": {"scout": 3, "clear": 3, "strength": 1}},
}

const KITS := {
	# ----- Forest -----
	"dawnhare": {"role": "Support", "hp": 290, "atk": 24, "def": 18, "spd": 1.5,
		"basic": "sunpetal_kick", "passive": "morning_coat", "ultimate": "first_light"},
	"solstag": {"role": "Support", "hp": 380, "atk": 28, "def": 24, "spd": 1.5,
		"basic": "halo_antler", "passive": "bright_velvet", "ultimate": "sunrise_grove"},
	"honeybruin": {"role": "Guard", "hp": 430, "atk": 22, "def": 38, "spd": 2.2,
		"basic": "honey_paw", "passive": "comb_coat", "ultimate": "hive_guard"},
	"glintbeetle": {"role": "Striker", "hp": 270, "atk": 30, "def": 18, "spd": 1.3,
		"basic": "glint_horn", "passive": "mirror_shell", "ultimate": "prism_charge"},
	"aurelion": {"role": "Guard", "hp": 620, "atk": 30, "def": 48, "spd": 2.2,
		"basic": "gilded_maul", "passive": "golden_mane", "ultimate": "radiant_roar"},
	# ----- River -----
	"shimmerpup": {"role": "Healer", "hp": 290, "atk": 24, "def": 16, "spd": 1.6,
		"basic": "splash_kiss", "passive": "warm_spring", "ultimate": "sunlit_pool"},
	"seraseal": {"role": "Healer", "hp": 380, "atk": 28, "def": 22, "spd": 1.5,
		"basic": "halo_splash", "passive": "blessed_tide", "ultimate": "swan_hymn"},
	"glimmerray": {"role": "Striker", "hp": 270, "atk": 30, "def": 14, "spd": 1.3,
		"basic": "light_lash", "passive": "sun_sip", "ultimate": "dazzle_dive"},
	"pearlotter": {"role": "Striker", "hp": 350, "atk": 36, "def": 20, "spd": 1.4,
		"basic": "pearl_toss", "passive": "oyster_sip", "ultimate": "pearl_flood"},
	"lumidolphin": {"role": "Healer", "hp": 560, "atk": 32, "def": 30, "spd": 1.7,
		"basic": "tide_chime", "passive": "sun_pod", "ultimate": "dawn_tide"},
	# ----- Swamp -----
	"lumifrog": {"role": "Support", "hp": 300, "atk": 24, "def": 18, "spd": 1.5,
		"basic": "glow_tongue", "passive": "lantern_skin", "ultimate": "dazzle_croak"},
	"lanternewt": {"role": "Support", "hp": 370, "atk": 29, "def": 22, "spd": 1.5,
		"basic": "lure_lick", "passive": "gold_glands", "ultimate": "blinding_bloom"},
	"sunsnapper": {"role": "Bruiser", "hp": 360, "atk": 27, "def": 24, "spd": 1.6,
		"basic": "amber_bite", "passive": "amber_shell", "ultimate": "amber_trap"},
	"goldleech": {"role": "Striker", "hp": 260, "atk": 30, "def": 14, "spd": 1.3,
		"basic": "gilt_bite", "passive": "rich_blood", "ultimate": "gold_fever"},
	"hippofly": {"role": "Bruiser", "hp": 450, "atk": 33, "def": 26, "spd": 1.8,
		"basic": "pollen_chomp", "passive": "moonwing", "ultimate": "pollen_storm"},
	# ----- Mountain -----
	"quartzmot": {"role": "Guard", "hp": 420, "atk": 23, "def": 40, "spd": 2.2,
		"basic": "quartz_butt", "passive": "crystal_fleece", "ultimate": "prism_stand"},
	"halotaur": {"role": "Guard", "hp": 540, "atk": 27, "def": 50, "spd": 2.3,
		"basic": "halo_horn", "passive": "sunstone_hide", "ultimate": "bright_avalanche"},
	"prismfalcon": {"role": "Striker", "hp": 250, "atk": 32, "def": 12, "spd": 1.3,
		"basic": "prism_talon", "passive": "sun_sight", "ultimate": "sunbeam_dive"},
	"lynxcrest": {"role": "Striker", "hp": 340, "atk": 37, "def": 18, "spd": 1.4,
		"basic": "glass_claw", "passive": "high_glare", "ultimate": "noon_pounce"},
	"sunmammoth": {"role": "Bruiser", "hp": 600, "atk": 39, "def": 36, "spd": 2.0,
		"basic": "gold_tusk", "passive": "dawn_wool", "ultimate": "solar_quake"},
	# ----- Snow -----
	"lumming": {"role": "Striker", "hp": 265, "atk": 30, "def": 14, "spd": 1.4,
		"basic": "sparkle_nip", "passive": "starlit_coat", "ultimate": "diamond_dust"},
	"aurorlynx": {"role": "Striker", "hp": 345, "atk": 36, "def": 20, "spd": 1.4,
		"basic": "aurora_claw", "passive": "polar_glow", "ultimate": "northern_lights"},
	"candlepine": {"role": "Guard", "hp": 420, "atk": 22, "def": 38, "spd": 2.2,
		"basic": "wax_flipper", "passive": "warm_blubber", "ultimate": "glow_floe"},
	"chimecrane": {"role": "Support", "hp": 280, "atk": 25, "def": 14, "spd": 1.5,
		"basic": "chime_peck", "passive": "crane_dance", "ultimate": "winter_chorus"},
	"caribear": {"role": "Bruiser", "hp": 460, "atk": 33, "def": 28, "spd": 1.8,
		"basic": "sleet_maul", "passive": "polar_appetite", "ultimate": "sun_on_snow"},
	# ----- Jungle -----
	"sunmarmoset": {"role": "Striker", "hp": 265, "atk": 30, "def": 14, "spd": 1.3,
		"basic": "tuft_flick", "passive": "sun_chatter", "ultimate": "gold_leap"},
	"lionbaboon": {"role": "Bruiser", "hp": 460, "atk": 33, "def": 26, "spd": 1.7,
		"basic": "mane_swing", "passive": "troop_shout", "ultimate": "sunrise_charge"},
	"quetzaloth": {"role": "Support", "hp": 300, "atk": 25, "def": 18, "spd": 1.5,
		"basic": "plume_tap", "passive": "slow_shine", "ultimate": "plume_veil"},
	"butterpard": {"role": "Striker", "hp": 340, "atk": 37, "def": 18, "spd": 1.4,
		"basic": "wing_swipe", "passive": "dazzle_wings", "ultimate": "sunwing_ambush"},
	"solaconda": {"role": "Striker", "hp": 470, "atk": 42, "def": 26, "spd": 1.5,
		"basic": "sun_coil", "passive": "radiant_scales", "ultimate": "noon_strike"},
}

const MOVES := {
	# ----- Forest -----
	# Dawnhare
	"sunpetal_kick": {"name": "Sunpetal Kick", "slot": "basic", "pct": 65, "ally": {"shield_atk": 45}},
	"morning_coat": {"name": "Morning Coat", "slot": "passive", "kind": "every", "n": 3, "shield_def": 70},
	"first_light": {"name": "First Light", "slot": "ultimate", "target": "none", "team": {"shield_def": 45}},
	# Solstag
	"halo_antler": {"name": "Halo Antler", "slot": "basic", "pct": 70, "ally": {"shield_atk": 55}},
	"bright_velvet": {"name": "Bright Velvet", "slot": "passive", "kind": "every", "n": 3, "shield_def": 90},
	"sunrise_grove": {"name": "Sunrise Grove", "slot": "ultimate", "target": "none", "team": {"shield_def": 60}, "taunt": 3.0},
	# Honeybruin
	"honey_paw": {"name": "Honey Paw", "slot": "basic", "pct": 75, "self": {"shield_def": 25}},
	"comb_coat": {"name": "Comb Coat", "slot": "passive", "kind": "thorns", "pct": 35},
	"hive_guard": {"name": "Hive Guard", "slot": "ultimate", "target": "none", "self": {"shield_def": 200}, "taunt": 3.5},
	# Glintbeetle
	"glint_horn": {"name": "Glint Horn", "slot": "basic", "pct": 85, "self": {"shield_atk": 15}},
	"mirror_shell": {"name": "Mirror Shell", "slot": "passive", "kind": "thorns", "pct": 40},
	"prism_charge": {"name": "Prism Charge", "slot": "ultimate", "target": "row", "pct": 110, "self": {"shield_atk": 50}},
	# Aurelion
	"gilded_maul": {"name": "Gilded Maul", "slot": "basic", "pct": 85, "self": {"shield_def": 35}},
	"golden_mane": {"name": "Golden Mane", "slot": "passive", "kind": "thorns", "pct": 60, "while_shielded": true},
	"radiant_roar": {"name": "Radiant Roar", "slot": "ultimate", "target": "all", "pct": 80, "self": {"shield_def": 160}, "taunt": 4.0},
	# ----- River -----
	# Shimmerpup
	"splash_kiss": {"name": "Splash Kiss", "slot": "basic", "pct": 65, "ally": {"heal_atk": 65}},
	"warm_spring": {"name": "Warm Spring", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 60},
	"sunlit_pool": {"name": "Sunlit Pool", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12, "cleanse": true}},
	# Seraseal
	"halo_splash": {"name": "Halo Splash", "slot": "basic", "pct": 70, "ally": {"heal_atk": 75}},
	"blessed_tide": {"name": "Blessed Tide", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 75},
	"swan_hymn": {"name": "Swan Hymn", "slot": "ultimate", "target": "all", "pct": 60, "team": {"heal_maxhp": 12, "cleanse": true}},
	# Glimmerray
	"light_lash": {"name": "Light Lash", "slot": "basic", "pct": 85, "wash": 50},
	"sun_sip": {"name": "Sun Sip", "slot": "passive", "kind": "drain", "pct": 20},
	"dazzle_dive": {"name": "Dazzle Dive", "slot": "ultimate", "target": "weakest", "pct": 190, "wash": 80},
	# Pearlotter
	"pearl_toss": {"name": "Pearl Toss", "slot": "basic", "pct": 50, "hits": 2, "wash": 30},
	"oyster_sip": {"name": "Oyster Sip", "slot": "passive", "kind": "drain", "pct": 30},
	"pearl_flood": {"name": "Pearl Flood", "slot": "ultimate", "target": "weakest", "pct": 220, "wash": 120},
	# Lumidolphin
	"tide_chime": {"name": "Tide Chime", "slot": "basic", "pct": 75, "ally": {"heal_atk": 90}},
	"sun_pod": {"name": "Sun Pod", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 90},
	"dawn_tide": {"name": "Dawn Tide", "slot": "ultimate", "target": "all", "pct": 80, "team": {"heal_maxhp": 16, "cleanse": true}},
	# ----- Swamp -----
	# Lumifrog
	"glow_tongue": {"name": "Glow Tongue", "slot": "basic", "pct": 70, "weaken": [20, 3]},
	"lantern_skin": {"name": "Lantern Skin", "slot": "passive", "kind": "every", "n": 3, "poison_all": [10, 4]},
	"dazzle_croak": {"name": "Dazzle Croak", "slot": "ultimate", "target": "all", "pct": 55, "weaken": [25, 4]},
	# Lanternewt
	"lure_lick": {"name": "Lure Lick", "slot": "basic", "pct": 65, "poison": [14, 4], "splash": 30},
	"gold_glands": {"name": "Gold Glands", "slot": "passive", "kind": "every", "n": 3, "poison_all": [14, 4]},
	"blinding_bloom": {"name": "Blinding Bloom", "slot": "ultimate", "target": "all", "pct": 70, "poison": [22, 5], "weaken": [20, 4]},
	# Sunsnapper
	"amber_bite": {"name": "Amber Bite", "slot": "basic", "pct": 90, "weaken": [15, 3]},
	"amber_shell": {"name": "Amber Shell", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"amber_trap": {"name": "Amber Trap", "slot": "ultimate", "target": "row", "pct": 100, "poison": [20, 4], "weaken": [20, 3]},
	# Goldleech
	"gilt_bite": {"name": "Gilt Bite", "slot": "basic", "pct": 75, "poison": [12, 4]},
	"rich_blood": {"name": "Rich Blood", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 25},
	"gold_fever": {"name": "Gold Fever", "slot": "ultimate", "target": "weakest", "pct": 170, "poison": [25, 4]},
	# Hippofly
	"pollen_chomp": {"name": "Pollen Chomp", "slot": "basic", "pct": 90, "poison": [16, 4]},
	"moonwing": {"name": "Moonwing", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 30},
	"pollen_storm": {"name": "Pollen Storm", "slot": "ultimate", "target": "row", "pct": 110, "poison": [24, 4], "weaken": [25, 4]},
	# ----- Mountain -----
	# Quartzmot
	"quartz_butt": {"name": "Quartz Butt", "slot": "basic", "pct": 75, "stagger": 20, "self": {"shield_def": 25}},
	"crystal_fleece": {"name": "Crystal Fleece", "slot": "passive", "kind": "armor_low", "amount": 20},
	"prism_stand": {"name": "Prism Stand", "slot": "ultimate", "target": "row", "pct": 80, "stagger": 35, "self": {"shield_def": 120}},
	# Halotaur
	"halo_horn": {"name": "Halo Horn", "slot": "basic", "pct": 80, "stagger": 25, "self": {"shield_def": 30}},
	"sunstone_hide": {"name": "Sunstone Hide", "slot": "passive", "kind": "armor_low", "amount": 30},
	"bright_avalanche": {"name": "Bright Avalanche", "slot": "ultimate", "target": "row", "pct": 100, "stagger": 45, "self": {"shield_def": 150}},
	# Prismfalcon
	"prism_talon": {"name": "Prism Talon", "slot": "basic", "pct": 85, "pierce": true},
	"sun_sight": {"name": "Sun Sight", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"sunbeam_dive": {"name": "Sunbeam Dive", "slot": "ultimate", "target": "weakest", "pct": 180, "pierce": true},
	# Lynxcrest
	"glass_claw": {"name": "Glass Claw", "slot": "basic", "pct": 90, "pierce": true},
	"high_glare": {"name": "High Glare", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 30},
	"noon_pounce": {"name": "Noon Pounce", "slot": "ultimate", "target": "weakest", "pct": 210, "pierce": true, "stagger": 30},
	# Sunmammoth
	"gold_tusk": {"name": "Gold Tusk", "slot": "basic", "pct": 95, "stagger": 25},
	"dawn_wool": {"name": "Dawn Wool", "slot": "passive", "kind": "armor_low", "amount": 30},
	"solar_quake": {"name": "Solar Quake", "slot": "ultimate", "target": "all", "pct": 95, "pierce": true, "stagger": 35},
	# ----- Snow -----
	# Lumming
	"sparkle_nip": {"name": "Sparkle Nip", "slot": "basic", "pct": 80, "slow": [15, 2]},
	"starlit_coat": {"name": "Starlit Coat", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"diamond_dust": {"name": "Diamond Dust", "slot": "ultimate", "target": "weakest", "pct": 170, "slow": [30, 3]},
	# Aurorlynx
	"aurora_claw": {"name": "Aurora Claw", "slot": "basic", "pct": 50, "hits": 2, "slow": [20, 2]},
	"polar_glow": {"name": "Polar Glow", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 30},
	"northern_lights": {"name": "Northern Lights", "slot": "ultimate", "target": "row", "pct": 120, "slow": [35, 3]},
	# Candlepine
	"wax_flipper": {"name": "Wax Flipper", "slot": "basic", "pct": 70, "slow": [20, 2], "self": {"shield_def": 25}},
	"warm_blubber": {"name": "Warm Blubber", "slot": "passive", "kind": "armor_low", "amount": 20},
	"glow_floe": {"name": "Glow Floe", "slot": "ultimate", "target": "row", "pct": 70, "slow": [35, 3], "self": {"shield_def": 110}},
	# Chimecrane
	"chime_peck": {"name": "Chime Peck", "slot": "basic", "pct": 65, "slow": [15, 2], "splash": 25},
	"crane_dance": {"name": "Crane Dance", "slot": "passive", "kind": "every", "n": 3, "team_haste": [20, 3]},
	"winter_chorus": {"name": "Winter Chorus", "slot": "ultimate", "target": "all", "pct": 50, "slow": [25, 3], "team": {"haste": [20, 4]}},
	# Caribear
	"sleet_maul": {"name": "Sleet Maul", "slot": "basic", "pct": 90, "slow": [20, 3]},
	"polar_appetite": {"name": "Polar Appetite", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"sun_on_snow": {"name": "Sun on Snow", "slot": "ultimate", "target": "row", "pct": 110, "slow": [35, 3], "team": {"haste": [20, 4]}},
	# ----- Jungle -----
	# Sunmarmoset
	"tuft_flick": {"name": "Tuft Flick", "slot": "basic", "pct": 80, "reach": true},
	"sun_chatter": {"name": "Sun Chatter", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"gold_leap": {"name": "Gold Leap", "slot": "ultimate", "target": "weakest", "pct": 190, "self": {"dodge": true}},
	# Lionbaboon
	"mane_swing": {"name": "Mane Swing", "slot": "basic", "pct": 90, "reach": true},
	"troop_shout": {"name": "Troop Shout", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 45},
	"sunrise_charge": {"name": "Sunrise Charge", "slot": "ultimate", "target": "row", "pct": 125, "reach": true, "self": {"dodge": true}},
	# Quetzaloth
	"plume_tap": {"name": "Plume Tap", "slot": "basic", "pct": 70, "self": {"shield_def": 25, "dodge": true}},
	"slow_shine": {"name": "Slow Shine", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 35},
	"plume_veil": {"name": "Plume Veil", "slot": "ultimate", "target": "row", "pct": 90, "reach": true, "self": {"dodge": true}},
	# Butterpard
	"wing_swipe": {"name": "Wing Swipe", "slot": "basic", "pct": 90, "reach": true},
	"dazzle_wings": {"name": "Dazzle Wings", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"sunwing_ambush": {"name": "Sunwing Ambush", "slot": "ultimate", "target": "weakest", "pct": 230, "self": {"dodge": true}},
	# Solaconda
	"sun_coil": {"name": "Sun Coil", "slot": "basic", "pct": 95, "reach": true},
	"radiant_scales": {"name": "Radiant Scales", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 60},
	"noon_strike": {"name": "Noon Strike", "slot": "ultimate", "target": "row", "pct": 140, "reach": true, "self": {"dodge": true}},
}

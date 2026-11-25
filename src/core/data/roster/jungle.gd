extends RefCounted
## Jungle Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"vinegecko": {"rarity": "common", "name": "Vinegecko", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "chamegecko",
		"capabilities": {"clear": 2, "scout": 2, "forage": 1}},
	"canopard": {"rarity": "rare", "name": "Canopard", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "guard": 1}},
	"vinekeet": {"rarity": "common", "name": "Vinekeet", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "toucaw",
		"capabilities": {"scout": 3, "forage": 1}},
	"prowlmander": {"rarity": "rare", "name": "Prowlmander", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 2, "clear": 2}},
	"quetzalith": {"rarity": "legendary", "name": "Quetzalith", "type": "Jungle", "size": "large", "hauling": 0,
		"capabilities": {"scout": 3, "clear": 2, "light": 1}},
	# ----- Milestone 3 -----
	"chamegecko": {"rarity": "common", "name": "Chamegecko", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "crestlisk",
		"capabilities": {"clear": 2, "scout": 3}},
	"crestlisk": {"rarity": "rare", "name": "Crestlisk", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"clear": 3, "scout": 3}},
	"toucaw": {"rarity": "common", "name": "Toucaw", "type": "Jungle", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "forage": 2}},
	"swingibbon": {"rarity": "rare", "name": "Swingibbon", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "clear": 2}},
	"flitfrog": {"rarity": "common", "name": "Flitfrog", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "sailfrog",
		"capabilities": {"scout": 3, "float": 1}},
	"sailfrog": {"rarity": "rare", "name": "Sailfrog", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "float": 2}},
	"slothant": {"rarity": "common", "name": "Slothant", "type": "Jungle", "size": "medium", "hauling": 40, "evolves_to": "hookclaw",
		"capabilities": {"guard": 2, "clear": 1}},
	"hookclaw": {"rarity": "rare", "name": "Hookclaw", "type": "Jungle", "size": "large", "hauling": 90,
		"capabilities": {"guard": 3, "clear": 2}},
	"mantokapi": {"rarity": "common", "name": "Mantokapi", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 2, "clear": 2}},
	"batemur": {"rarity": "common", "name": "Batemur", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "ayewing",
		"capabilities": {"scout": 3, "light": 1}},
	"ayewing": {"rarity": "rare", "name": "Ayewing", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "light": 2}},
	"tarsifly": {"rarity": "common", "name": "Tarsifly", "type": "Jungle", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "light": 2}},
	"capyscarab": {"rarity": "common", "name": "Capyscarab", "type": "Jungle", "size": "medium", "hauling": 60,
		"capabilities": {"guard": 2, "float": 1, "forage": 1}},
	"harpyjag": {"rarity": "legendary", "name": "Harpyjag", "type": "Jungle", "size": "large", "hauling": 0,
		"capabilities": {"scout": 3, "clear": 2}},
	"silverhide": {"rarity": "legendary", "name": "Silverhide", "type": "Jungle", "size": "large", "hauling": 170,
		"capabilities": {"strength": 3, "guard": 3, "clear": 2}},
}

const KITS := {
	"vinegecko": {"role": "Striker", "hp": 265, "atk": 28, "def": 11, "spd": 1.6,
		"basic": "vine_flick", "passive": "sticky_feet", "ultimate": "canopy_drop"},
	"canopard": {"role": "Striker", "hp": 320, "atk": 35, "def": 18, "spd": 1.7,
		"basic": "leaf_pounce", "passive": "dapple", "ultimate": "canopy_strike"},
	"vinekeet": {"role": "Support", "hp": 265, "atk": 24, "def": 12, "spd": 1.5,
		"basic": "keet_peck", "passive": "chatter", "ultimate": "flock_call"},
	"prowlmander": {"role": "Striker", "hp": 300, "atk": 34, "def": 15, "spd": 1.7,
		"basic": "tongue_lash", "passive": "quick_tongue", "ultimate": "ambush_leap"},
	"quetzalith": {"role": "Striker", "hp": 370, "atk": 36, "def": 20, "spd": 1.6,
		"basic": "plume_strike", "passive": "sun_plumes", "ultimate": "sky_dive"},
	# ----- Milestone 3 -----
	"chamegecko": {"role": "Striker", "hp": 310, "atk": 31, "def": 14, "spd": 1.5,
		"basic": "sticky_lash", "passive": "color_shift", "ultimate": "vanishing_tongue"},
	"crestlisk": {"role": "Striker", "hp": 380, "atk": 36, "def": 18, "spd": 1.5,
		"basic": "crest_whip", "passive": "water_runner", "ultimate": "sun_crest"},
	"toucaw": {"role": "Striker", "hp": 300, "atk": 30, "def": 14, "spd": 1.5,
		"basic": "big_beak", "passive": "loud_call", "ultimate": "rainbow_dive"},
	"swingibbon": {"role": "Striker", "hp": 320, "atk": 35, "def": 18, "spd": 1.5,
		"basic": "vine_swing", "passive": "long_arms", "ultimate": "canopy_crash"},
	"flitfrog": {"role": "Striker", "hp": 280, "atk": 29, "def": 12, "spd": 1.4,
		"basic": "glide_kick", "passive": "tree_cling", "ultimate": "skyleap"},
	"sailfrog": {"role": "Striker", "hp": 330, "atk": 34, "def": 18, "spd": 1.5,
		"basic": "sail_strike", "passive": "canopy_sail", "ultimate": "rain_glide"},
	"slothant": {"role": "Guard", "hp": 430, "atk": 22, "def": 38, "spd": 2.4,
		"basic": "hook_swipe", "passive": "slow_grip", "ultimate": "hang_low"},
	"hookclaw": {"role": "Guard", "hp": 540, "atk": 26, "def": 46, "spd": 2.4,
		"basic": "long_hook", "passive": "moss_fur", "ultimate": "hook_sweep"},
	"mantokapi": {"role": "Striker", "hp": 320, "atk": 32, "def": 16, "spd": 1.6,
		"basic": "mantis_strike", "passive": "striped_legs", "ultimate": "praying_lunge"},
	"batemur": {"role": "Support", "hp": 300, "atk": 26, "def": 14, "spd": 1.5,
		"basic": "night_flit", "passive": "ring_tail", "ultimate": "moon_glide"},
	"ayewing": {"role": "Striker", "hp": 320, "atk": 35, "def": 18, "spd": 1.5,
		"basic": "long_finger", "passive": "night_tapping", "ultimate": "eclipse_glide"},
	"tarsifly": {"role": "Striker", "hp": 270, "atk": 29, "def": 12, "spd": 1.4,
		"basic": "glow_jab", "passive": "big_eyes", "ultimate": "firefly_swarm"},
	"capyscarab": {"role": "Guard", "hp": 440, "atk": 22, "def": 38, "spd": 2.4,
		"basic": "calm_bump", "passive": "jewel_shell", "ultimate": "big_chill"},
	"harpyjag": {"role": "Striker", "hp": 420, "atk": 39, "def": 24, "spd": 1.5,
		"basic": "harpy_talon", "passive": "apex_crest", "ultimate": "canopy_king"},
	"silverhide": {"role": "Guard", "hp": 640, "atk": 31, "def": 52, "spd": 2.2,
		"basic": "knuckle_sweep", "passive": "silver_scales", "ultimate": "jungle_chest"},
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
	# ----- Milestone 3 -----
	# Chamegecko
	"sticky_lash": {"name": "Sticky Lash", "slot": "basic", "pct": 85, "reach": true},
	"color_shift": {"name": "Color Shift", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"vanishing_tongue": {"name": "Vanishing Tongue", "slot": "ultimate", "target": "weakest", "pct": 180, "self": {"dodge": true}},
	# Crestlisk
	"crest_whip": {"name": "Crest Whip", "slot": "basic", "pct": 90, "reach": true},
	"water_runner": {"name": "Water Runner", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 35},
	"sun_crest": {"name": "Sun Crest", "slot": "ultimate", "target": "row", "pct": 120, "reach": true, "self": {"dodge": true}},
	# Toucaw
	"big_beak": {"name": "Big Beak", "slot": "basic", "pct": 85, "reach": true},
	"loud_call": {"name": "Loud Call", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"rainbow_dive": {"name": "Rainbow Dive", "slot": "ultimate", "target": "weakest", "pct": 170, "self": {"dodge": true}},
	# Swingibbon
	"vine_swing": {"name": "Vine Swing", "slot": "basic", "pct": 85, "reach": true, "self": {"dodge": true}},
	"long_arms": {"name": "Long Arms", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"canopy_crash": {"name": "Canopy Crash", "slot": "ultimate", "target": "row", "pct": 125, "reach": true},
	# Flitfrog
	"glide_kick": {"name": "Glide Kick", "slot": "basic", "pct": 80, "reach": true},
	"tree_cling": {"name": "Tree Cling", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"skyleap": {"name": "Skyleap", "slot": "ultimate", "target": "weakest", "pct": 160, "self": {"dodge": true}},
	# Sailfrog
	"sail_strike": {"name": "Sail Strike", "slot": "basic", "pct": 85, "reach": true, "self": {"dodge": true}},
	"canopy_sail": {"name": "Canopy Sail", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 35},
	"rain_glide": {"name": "Rain Glide", "slot": "ultimate", "target": "row", "pct": 115, "reach": true},
	# Slothant
	"hook_swipe": {"name": "Hook Swipe", "slot": "basic", "pct": 70, "reach": true, "self": {"shield_def": 20}},
	"slow_grip": {"name": "Slow Grip", "slot": "passive", "kind": "armor_low", "amount": 20},
	"hang_low": {"name": "Hang Low", "slot": "ultimate", "target": "none", "self": {"shield_def": 180, "dodge": true}},
	# Hookclaw
	"long_hook": {"name": "Long Hook", "slot": "basic", "pct": 80, "reach": true, "self": {"shield_def": 30}},
	"moss_fur": {"name": "Moss Fur", "slot": "passive", "kind": "armor_low", "amount": 30},
	"hook_sweep": {"name": "Hook Sweep", "slot": "ultimate", "target": "row", "pct": 100, "reach": true, "self": {"shield_def": 140}},
	# Mantokapi
	"mantis_strike": {"name": "Mantis Strike", "slot": "basic", "pct": 85, "reach": true},
	"striped_legs": {"name": "Striped Legs", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 30},
	"praying_lunge": {"name": "Praying Lunge", "slot": "ultimate", "target": "weakest", "pct": 180, "self": {"dodge": true}},
	# Batemur
	"night_flit": {"name": "Night Flit", "slot": "basic", "pct": 70, "reach": true, "self": {"dodge": true}},
	"ring_tail": {"name": "Ring Tail", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 35},
	"moon_glide": {"name": "Moon Glide", "slot": "ultimate", "target": "row", "pct": 100, "reach": true},
	# Ayewing
	"long_finger": {"name": "Long Finger", "slot": "basic", "pct": 85, "reach": true, "self": {"dodge": true}},
	"night_tapping": {"name": "Night Tapping", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"eclipse_glide": {"name": "Eclipse Glide", "slot": "ultimate", "target": "row", "pct": 125, "reach": true},
	# Tarsifly
	"glow_jab": {"name": "Glow Jab", "slot": "basic", "pct": 80, "reach": true},
	"big_eyes": {"name": "Big Eyes", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"firefly_swarm": {"name": "Firefly Swarm", "slot": "ultimate", "target": "row", "pct": 95, "self": {"dodge": true}},
	# Capyscarab
	"calm_bump": {"name": "Calm Bump", "slot": "basic", "pct": 70, "self": {"shield_def": 25, "dodge": true}},
	"jewel_shell": {"name": "Jewel Shell", "slot": "passive", "kind": "armor_low", "amount": 20},
	"big_chill": {"name": "Big Chill", "slot": "ultimate", "target": "row", "pct": 70, "reach": true, "self": {"shield_def": 120}},
	# Harpyjag
	"harpy_talon": {"name": "Harpy Talon", "slot": "basic", "pct": 90, "reach": true, "self": {"dodge": true}},
	"apex_crest": {"name": "Apex Crest", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 60},
	"canopy_king": {"name": "Canopy King", "slot": "ultimate", "target": "all", "pct": 90, "reach": true},
	# Silverhide
	"knuckle_sweep": {"name": "Knuckle Sweep", "slot": "basic", "pct": 85, "reach": true, "splash": 25},
	"silver_scales": {"name": "Silver Scales", "slot": "passive", "kind": "armor_low", "amount": 30},
	"jungle_chest": {"name": "Jungle Chest", "slot": "ultimate", "target": "row", "pct": 100, "reach": true, "self": {"shield_def": 180, "dodge": true}},
}

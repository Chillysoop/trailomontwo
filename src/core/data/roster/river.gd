extends RefCounted
## River Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"pebblotter": {"rarity": "common", "name": "Pebblotter", "type": "River", "size": "small", "hauling": 0, "evolves_to": "damotter",
		"capabilities": {"float": 2, "heal": 1, "forage": 2}},
	"lanternray": {"rarity": "rare", "name": "Lanternray", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "light": 2}},
	"tidewyrm": {"rarity": "legendary", "name": "Tidewyrm", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "heal": 3}},
	"minnowisp": {"rarity": "common", "name": "Minnowisp", "type": "River", "size": "small", "hauling": 0, "evolves_to": "shoalwisp",
		"capabilities": {"float": 3, "light": 1}},
	"kelpoise": {"rarity": "rare", "name": "Kelpoise", "type": "River", "size": "large", "hauling": 100,
		"capabilities": {"float": 3, "strength": 2}},
	# ----- Milestone 1 -----
	"damotter": {"rarity": "common", "name": "Damotter", "type": "River", "size": "medium", "hauling": 60,
		"capabilities": {"float": 3, "heal": 2, "strength": 1}},
	"shoalwisp": {"rarity": "common", "name": "Shoalwisp", "type": "River", "size": "small", "hauling": 0, "evolves_to": "glimmerkoi",
		"capabilities": {"float": 3, "light": 2}},
	"glimmerkoi": {"rarity": "rare", "name": "Glimmerkoi", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "light": 3, "heal": 2}},
	"inkstrix": {"rarity": "rare", "name": "Inkstrix", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "float": 2}},
	"crayhopper": {"rarity": "common", "name": "Crayhopper", "type": "River", "size": "small", "hauling": 0, "evolves_to": "pincerfrog",
		"capabilities": {"float": 2, "forage": 2}},
	"pincerfrog": {"rarity": "common", "name": "Pincerfrog", "type": "River", "size": "medium", "hauling": 0, "evolves_to": "bullcray",
		"capabilities": {"float": 3, "forage": 2}},
	"bullcray": {"rarity": "rare", "name": "Bullcray", "type": "River", "size": "large", "hauling": 110,
		"capabilities": {"strength": 2, "float": 3}},
	"stiltseal": {"rarity": "common", "name": "Stiltseal", "type": "River", "size": "medium", "hauling": 0, "evolves_to": "wadeseal",
		"capabilities": {"float": 2, "heal": 2}},
	"wadeseal": {"rarity": "rare", "name": "Wadeseal", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "heal": 3}},
	"salmoram": {"rarity": "common", "name": "Salmoram", "type": "River", "size": "medium", "hauling": 70, "evolves_to": "rapidram",
		"capabilities": {"strength": 2, "float": 2}},
	"rapidram": {"rarity": "rare", "name": "Rapidram", "type": "River", "size": "large", "hauling": 120,
		"capabilities": {"strength": 3, "float": 2}},
	"shelldrake": {"rarity": "common", "name": "Shelldrake", "type": "River", "size": "medium", "hauling": 0, "evolves_to": "moatdrake",
		"capabilities": {"float": 2, "guard": 2}},
	"moatdrake": {"rarity": "rare", "name": "Moatdrake", "type": "River", "size": "large", "hauling": 90,
		"capabilities": {"float": 3, "guard": 2}},
	"tidecrane": {"rarity": "legendary", "name": "Tidecrane", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "heal": 3, "scout": 2}},
	"narwhalcon": {"rarity": "legendary", "name": "Narwhalcon", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "scout": 3}},
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
	# ----- Milestone 1 -----
	"damotter": {"role": "Healer", "hp": 340, "atk": 28, "def": 20, "spd": 1.8,
		"basic": "dam_toss", "passive": "lodge_care", "ultimate": "dam_burst"},
	"shoalwisp": {"role": "Healer", "hp": 300, "atk": 27, "def": 16, "spd": 1.6,
		"basic": "shoal_splash", "passive": "shoal_glimmer", "ultimate": "shoal_spring"},
	"glimmerkoi": {"role": "Healer", "hp": 370, "atk": 32, "def": 22, "spd": 1.7,
		"basic": "koi_shimmer", "passive": "koi_luck", "ultimate": "koi_tide"},
	"inkstrix": {"role": "Striker", "hp": 340, "atk": 36, "def": 16, "spd": 1.6,
		"basic": "ink_lance", "passive": "night_drain", "ultimate": "black_tide"},
	"crayhopper": {"role": "Striker", "hp": 260, "atk": 29, "def": 14, "spd": 1.6,
		"basic": "claw_snip", "passive": "brook_sip", "ultimate": "pinch_leap"},
	"pincerfrog": {"role": "Striker", "hp": 310, "atk": 32, "def": 18, "spd": 1.6,
		"basic": "pincer_lash", "passive": "frog_drink", "ultimate": "pincer_leap"},
	"bullcray": {"role": "Bruiser", "hp": 450, "atk": 32, "def": 30, "spd": 1.9,
		"basic": "bull_clamp", "passive": "deep_croak", "ultimate": "riverquake"},
	"stiltseal": {"role": "Healer", "hp": 300, "atk": 25, "def": 16, "spd": 1.8,
		"basic": "stilt_splash", "passive": "seal_song", "ultimate": "rain_call"},
	"wadeseal": {"role": "Healer", "hp": 420, "atk": 30, "def": 24, "spd": 1.8,
		"basic": "wade_wash", "passive": "seal_warmth", "ultimate": "estuary_song"},
	"salmoram": {"role": "Bruiser", "hp": 380, "atk": 28, "def": 26, "spd": 2.0,
		"basic": "leap_ram", "passive": "upstream", "ultimate": "spawning_charge"},
	"rapidram": {"role": "Bruiser", "hp": 480, "atk": 33, "def": 30, "spd": 2.1,
		"basic": "rapid_ram", "passive": "current_drink", "ultimate": "whitewater_charge"},
	"shelldrake": {"role": "Guard", "hp": 420, "atk": 22, "def": 38, "spd": 2.2,
		"basic": "shell_dabble", "passive": "pond_drink", "ultimate": "moat_shelter"},
	"moatdrake": {"role": "Guard", "hp": 520, "atk": 25, "def": 46, "spd": 2.3,
		"basic": "moat_wing", "passive": "moat_drink", "ultimate": "moat_wall"},
	"tidecrane": {"role": "Healer", "hp": 430, "atk": 34, "def": 26, "spd": 1.8,
		"basic": "crane_rain", "passive": "whale_song", "ultimate": "monsoon"},
	"narwhalcon": {"role": "Striker", "hp": 430, "atk": 38, "def": 26, "spd": 1.6,
		"basic": "tusk_dive", "passive": "sea_hunger", "ultimate": "falling_tusk"},
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
	# ----- Milestone 1 -----
	# Damotter
	"dam_toss": {"name": "Dam Toss", "slot": "basic", "pct": 65, "ally": {"heal_atk": 60}},
	"lodge_care": {"name": "Lodge Care", "slot": "passive", "kind": "drain", "pct": 20, "to_ally": true},
	"dam_burst": {"name": "Dam Burst", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 14, "cleanse": true}},
	# Shoalwisp
	"shoal_splash": {"name": "Shoal Splash", "slot": "basic", "pct": 60, "ally": {"heal_atk": 60}},
	"shoal_glimmer": {"name": "Shoal Glimmer", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 70},
	"shoal_spring": {"name": "Shoal Spring", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12, "cleanse": true}},
	# Glimmerkoi
	"koi_shimmer": {"name": "Koi Shimmer", "slot": "basic", "pct": 70, "ally": {"heal_atk": 75}},
	"koi_luck": {"name": "Koi Luck", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 80},
	"koi_tide": {"name": "Koi Tide", "slot": "ultimate", "target": "all", "pct": 60, "team": {"heal_maxhp": 12, "cleanse": true}},
	# Inkstrix
	"ink_lance": {"name": "Ink Lance", "slot": "basic", "pct": 85, "wash": 60},
	"night_drain": {"name": "Night Drain", "slot": "passive", "kind": "drain", "pct": 30},
	"black_tide": {"name": "Black Tide", "slot": "ultimate", "target": "weakest", "pct": 210, "wash": 100},
	# Crayhopper
	"claw_snip": {"name": "Claw Snip", "slot": "basic", "pct": 80, "wash": 40},
	"brook_sip": {"name": "Brook Sip", "slot": "passive", "kind": "drain", "pct": 20},
	"pinch_leap": {"name": "Pinch Leap", "slot": "ultimate", "target": "weakest", "pct": 170, "wash": 80},
	# Pincerfrog
	"pincer_lash": {"name": "Pincer Lash", "slot": "basic", "pct": 85, "wash": 50},
	"frog_drink": {"name": "Frog Drink", "slot": "passive", "kind": "drain", "pct": 25},
	"pincer_leap": {"name": "Pincer Leap", "slot": "ultimate", "target": "weakest", "pct": 190, "wash": 100},
	# Bullcray
	"bull_clamp": {"name": "Bull Clamp", "slot": "basic", "pct": 95, "wash": 60, "self": {"heal_atk": 20}},
	"deep_croak": {"name": "Deep Croak", "slot": "passive", "kind": "drain", "pct": 30},
	"riverquake": {"name": "Riverquake", "slot": "ultimate", "target": "row", "pct": 120, "wash": 80},
	# Stiltseal
	"stilt_splash": {"name": "Stilt Splash", "slot": "basic", "pct": 55, "ally": {"heal_atk": 55}},
	"seal_song": {"name": "Seal Song", "slot": "passive", "kind": "every", "n": 4, "ally_heal_atk": 80},
	"rain_call": {"name": "Rain Call", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12}},
	# Wadeseal
	"wade_wash": {"name": "Wade Wash", "slot": "basic", "pct": 65, "ally": {"heal_atk": 70}},
	"seal_warmth": {"name": "Seal Warmth", "slot": "passive", "kind": "drain", "pct": 15, "to_ally": true},
	"estuary_song": {"name": "Estuary Song", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 16, "cleanse": true}},
	# Salmoram
	"leap_ram": {"name": "Leap Ram", "slot": "basic", "pct": 85, "self": {"heal_atk": 20}},
	"upstream": {"name": "Upstream", "slot": "passive", "kind": "drain", "pct": 20},
	"spawning_charge": {"name": "Spawning Charge", "slot": "ultimate", "target": "adjacent", "pct": 140, "self": {"heal_atk": 40}},
	# Rapidram
	"rapid_ram": {"name": "Rapid Ram", "slot": "basic", "pct": 95, "self": {"heal_atk": 25}},
	"current_drink": {"name": "Current Drink", "slot": "passive", "kind": "drain", "pct": 25},
	"whitewater_charge": {"name": "Whitewater Charge", "slot": "ultimate", "target": "row", "pct": 125, "wash": 60},
	# Shelldrake
	"shell_dabble": {"name": "Shell Dabble", "slot": "basic", "pct": 70, "self": {"shield_def": 35}},
	"pond_drink": {"name": "Pond Drink", "slot": "passive", "kind": "drain", "pct": 20},
	"moat_shelter": {"name": "Moat Shelter", "slot": "ultimate", "target": "none", "self": {"shield_def": 150}, "team": {"heal_maxhp": 8}},
	# Moatdrake
	"moat_wing": {"name": "Moat Wing", "slot": "basic", "pct": 75, "self": {"shield_def": 40}},
	"moat_drink": {"name": "Moat Drink", "slot": "passive", "kind": "drain", "pct": 25},
	"moat_wall": {"name": "Moat Wall", "slot": "ultimate", "target": "none", "self": {"shield_def": 180}, "team": {"heal_maxhp": 10, "cleanse": true}},
	# Tidecrane
	"crane_rain": {"name": "Crane Rain", "slot": "basic", "pct": 75, "ally": {"heal_atk": 70}},
	"whale_song": {"name": "Whale Song", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 85},
	"monsoon": {"name": "Monsoon", "slot": "ultimate", "target": "all", "pct": 70, "team": {"heal_maxhp": 14, "cleanse": true}},
	# Narwhalcon
	"tusk_dive": {"name": "Tusk Dive", "slot": "basic", "pct": 85, "wash": 60},
	"sea_hunger": {"name": "Sea Hunger", "slot": "passive", "kind": "drain", "pct": 35},
	"falling_tusk": {"name": "Falling Tusk", "slot": "ultimate", "target": "weakest", "pct": 230, "wash": 120},
}

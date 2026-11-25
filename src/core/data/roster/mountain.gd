extends RefCounted
## Mountain Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"slatebeak": {"rarity": "common", "name": "Slatebeak", "type": "Mountain", "size": "medium", "hauling": 0, "evolves_to": "scalecondor",
		"capabilities": {"scout": 3, "steady": 1}},
	"quarrytusk": {"rarity": "rare", "name": "Quarrytusk", "type": "Mountain", "size": "large", "hauling": 160,
		"capabilities": {"strength": 3, "clear": 2}},
	"cragkid": {"rarity": "common", "name": "Cragkid", "type": "Mountain", "size": "medium", "hauling": 70, "evolves_to": "markhorn",
		"capabilities": {"steady": 3, "strength": 1}},
	"basaltortle": {"rarity": "rare", "name": "Basaltortle", "type": "Mountain", "size": "large", "hauling": 130,
		"capabilities": {"strength": 2, "steady": 3}},
	"titanox": {"rarity": "legendary", "name": "Titanox", "type": "Mountain", "size": "large", "hauling": 200,
		"capabilities": {"strength": 3, "steady": 3}},
	# ----- Milestone 2 -----
	"rhinoram": {"rarity": "rare", "name": "Rhinoram", "type": "Mountain", "size": "large", "hauling": 160,
		"capabilities": {"strength": 3, "clear": 2}},
	"scalecondor": {"rarity": "common", "name": "Scalecondor", "type": "Mountain", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "steady": 2}},
	"markhorn": {"rarity": "common", "name": "Markhorn", "type": "Mountain", "size": "medium", "hauling": 90, "evolves_to": "summitibex",
		"capabilities": {"steady": 3, "strength": 2}},
	"summitibex": {"rarity": "rare", "name": "Summitibex", "type": "Mountain", "size": "large", "hauling": 120,
		"capabilities": {"steady": 3, "strength": 3, "scout": 1}},
	"pikadillo": {"rarity": "common", "name": "Pikadillo", "type": "Mountain", "size": "small", "hauling": 0, "evolves_to": "boulderdillo",
		"capabilities": {"scout": 2, "steady": 2}},
	"boulderdillo": {"rarity": "rare", "name": "Boulderdillo", "type": "Mountain", "size": "large", "hauling": 100,
		"capabilities": {"strength": 2, "steady": 3}},
	"drillrat": {"rarity": "common", "name": "Drillrat", "type": "Mountain", "size": "small", "hauling": 0, "evolves_to": "augerhino",
		"capabilities": {"clear": 3, "strength": 1}},
	"augerhino": {"rarity": "rare", "name": "Augerhino", "type": "Mountain", "size": "large", "hauling": 130,
		"capabilities": {"clear": 3, "strength": 2}},
	"cliffkite": {"rarity": "common", "name": "Cliffkite", "type": "Mountain", "size": "small", "hauling": 0, "evolves_to": "talonwalla",
		"capabilities": {"scout": 3}},
	"talonwalla": {"rarity": "rare", "name": "Talonwalla", "type": "Mountain", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "steady": 1}},
	"shaleyak": {"rarity": "common", "name": "Shaleyak", "type": "Mountain", "size": "large", "hauling": 120, "evolves_to": "plateyak",
		"capabilities": {"strength": 3, "steady": 1}},
	"plateyak": {"rarity": "rare", "name": "Plateyak", "type": "Mountain", "size": "large", "hauling": 170,
		"capabilities": {"strength": 3, "steady": 2}},
	"gravelbat": {"rarity": "common", "name": "Gravelbat", "type": "Mountain", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "light": 1}},
	"stormrhino": {"rarity": "legendary", "name": "Stormrhino", "type": "Mountain", "size": "large", "hauling": 180,
		"capabilities": {"strength": 3, "steady": 3, "scout": 1}},
	"obsidiwolf": {"rarity": "legendary", "name": "Obsidiwolf", "type": "Mountain", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "strength": 2}},
}

const KITS := {
	"slatebeak": {"role": "Striker", "hp": 270, "atk": 31, "def": 14, "spd": 1.7,
		"basic": "slate_peck", "passive": "carrion_eye", "ultimate": "rock_dive"},
	"quarrytusk": {"role": "Guard", "hp": 470, "atk": 28, "def": 42, "spd": 2.3,
		"basic": "tusk_shove", "passive": "quarry_hide", "ultimate": "quarry_quake"},
	"cragkid": {"role": "Bruiser", "hp": 360, "atk": 29, "def": 26, "spd": 2.0,
		"basic": "crag_butt", "passive": "sure_footed", "ultimate": "rockfall"},
	"basaltortle": {"role": "Guard", "hp": 520, "atk": 26, "def": 46, "spd": 2.4,
		"basic": "basalt_slam", "passive": "cooled_rock", "ultimate": "magma_crack"},
	"titanox": {"role": "Guard", "hp": 640, "atk": 30, "def": 50, "spd": 2.3,
		"basic": "titan_horn", "passive": "titan_hide", "ultimate": "earthsplitter"},
	# ----- Milestone 2 -----
	"rhinoram": {"role": "Guard", "hp": 520, "atk": 30, "def": 46, "spd": 2.3,
		"basic": "horn_ram", "passive": "rhino_hide", "ultimate": "rockslam"},
	"scalecondor": {"role": "Striker", "hp": 310, "atk": 33, "def": 18, "spd": 1.7,
		"basic": "talon_rake", "passive": "scale_wings", "ultimate": "plummet"},
	"markhorn": {"role": "Bruiser", "hp": 380, "atk": 31, "def": 28, "spd": 2.0,
		"basic": "spiral_butt", "passive": "cliff_footing", "ultimate": "spiral_charge"},
	"summitibex": {"role": "Bruiser", "hp": 450, "atk": 35, "def": 32, "spd": 2.0,
		"basic": "summit_horn", "passive": "eagle_eye", "ultimate": "peak_drop"},
	"pikadillo": {"role": "Striker", "hp": 250, "atk": 29, "def": 16, "spd": 1.5,
		"basic": "pebble_flick", "passive": "tiny_finisher", "ultimate": "rolling_stone"},
	"boulderdillo": {"role": "Guard", "hp": 500, "atk": 27, "def": 46, "spd": 2.3,
		"basic": "boulder_roll", "passive": "boulder_bands", "ultimate": "avalanche_roll"},
	"drillrat": {"role": "Striker", "hp": 260, "atk": 30, "def": 16, "spd": 1.6,
		"basic": "drill_bite", "passive": "tunnel_sense", "ultimate": "cave_in"},
	"augerhino": {"role": "Bruiser", "hp": 470, "atk": 34, "def": 32, "spd": 2.1,
		"basic": "auger_horn", "passive": "bore_through", "ultimate": "deep_drill"},
	"cliffkite": {"role": "Striker", "hp": 250, "atk": 30, "def": 14, "spd": 1.5,
		"basic": "ledge_swoop", "passive": "thin_air", "ultimate": "cliff_drop"},
	"talonwalla": {"role": "Striker", "hp": 360, "atk": 36, "def": 18, "spd": 1.6,
		"basic": "talon_crush", "passive": "killing_eye", "ultimate": "sky_crush"},
	"shaleyak": {"role": "Guard", "hp": 440, "atk": 24, "def": 40, "spd": 2.3,
		"basic": "shale_shove", "passive": "scaled_wool", "ultimate": "rock_wall"},
	"plateyak": {"role": "Guard", "hp": 540, "atk": 27, "def": 50, "spd": 2.4,
		"basic": "plate_charge", "passive": "slate_scales", "ultimate": "rockfall_wall"},
	"gravelbat": {"role": "Striker", "hp": 240, "atk": 30, "def": 12, "spd": 1.4,
		"basic": "gravel_bite", "passive": "echo_hunt", "ultimate": "rock_shriek"},
	"stormrhino": {"role": "Bruiser", "hp": 600, "atk": 37, "def": 40, "spd": 2.1,
		"basic": "thunder_horn", "passive": "storm_hide", "ultimate": "skyfall_charge"},
	"obsidiwolf": {"role": "Striker", "hp": 440, "atk": 39, "def": 28, "spd": 1.6,
		"basic": "obsidian_fang", "passive": "glass_hunger", "ultimate": "shatter_howl"},
}

const MOVES := {
	# Slatebeak
	"slate_peck": {"name": "Slate Peck", "slot": "basic", "pct": 90, "bonus": {"vs": "hurt", "amount": 40}},
	"carrion_eye": {"name": "Carrion Eye", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 20},
	"rock_dive": {"name": "Rock Dive", "slot": "ultimate", "target": "weakest", "pct": 180, "pierce": true},
	# Quarrytusk
	"tusk_shove": {"name": "Tusk Shove", "slot": "basic", "pct": 80, "stagger": 25},
	"quarry_hide": {"name": "Quarry Hide", "slot": "passive", "kind": "armor_low", "amount": 25},
	"quarry_quake": {"name": "Quarry Quake", "slot": "ultimate", "target": "row", "pct": 120, "stagger": 40},
	# Cragkid
	"crag_butt": {"name": "Crag Butt", "slot": "basic", "pct": 90, "stagger": 20},
	"sure_footed": {"name": "Sure-footed", "slot": "passive", "kind": "armor_low", "amount": 15},
	"rockfall": {"name": "Rockfall", "slot": "ultimate", "pct": 190, "pierce": true},
	# Basaltortle
	"basalt_slam": {"name": "Basalt Slam", "slot": "basic", "pct": 80, "stagger": 30},
	"cooled_rock": {"name": "Cooled Rock", "slot": "passive", "kind": "armor_low", "amount": 30},
	"magma_crack": {"name": "Magma Crack", "slot": "ultimate", "target": "row", "pct": 130, "pierce": true},
	# Titanox
	"titan_horn": {"name": "Titan Horn", "slot": "basic", "pct": 85, "stagger": 25, "splash": 30},
	"titan_hide": {"name": "Titan Hide", "slot": "passive", "kind": "armor_low", "amount": 30},
	"earthsplitter": {"name": "Earthsplitter", "slot": "ultimate", "target": "row", "pct": 150, "pierce": true, "stagger": 40},
	# ----- Milestone 2 -----
	# Rhinoram
	"horn_ram": {"name": "Horn Ram", "slot": "basic", "pct": 85, "stagger": 30},
	"rhino_hide": {"name": "Rhino Hide", "slot": "passive", "kind": "armor_low", "amount": 30},
	"rockslam": {"name": "Rockslam", "slot": "ultimate", "target": "row", "pct": 120, "stagger": 40},
	# Scalecondor
	"talon_rake": {"name": "Talon Rake", "slot": "basic", "pct": 90, "bonus": {"vs": "hurt", "amount": 40}},
	"scale_wings": {"name": "Scale Wings", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 20},
	"plummet": {"name": "Plummet", "slot": "ultimate", "target": "weakest", "pct": 190, "pierce": true},
	# Markhorn
	"spiral_butt": {"name": "Spiral Butt", "slot": "basic", "pct": 90, "stagger": 25},
	"cliff_footing": {"name": "Cliff Footing", "slot": "passive", "kind": "armor_low", "amount": 20},
	"spiral_charge": {"name": "Spiral Charge", "slot": "ultimate", "target": "adjacent", "pct": 140, "pierce": true},
	# Summitibex
	"summit_horn": {"name": "Summit Horn", "slot": "basic", "pct": 95, "stagger": 30, "splash": 25},
	"eagle_eye": {"name": "Eagle Eye", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"peak_drop": {"name": "Peak Drop", "slot": "ultimate", "target": "row", "pct": 130, "pierce": true, "stagger": 30},
	# Pikadillo
	"pebble_flick": {"name": "Pebble Flick", "slot": "basic", "pct": 80, "pierce": true},
	"tiny_finisher": {"name": "Tiny Finisher", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"rolling_stone": {"name": "Rolling Stone", "slot": "ultimate", "target": "adjacent", "pct": 130, "stagger": 30},
	# Boulderdillo
	"boulder_roll": {"name": "Boulder Roll", "slot": "basic", "pct": 80, "stagger": 30, "self": {"shield_def": 30}},
	"boulder_bands": {"name": "Boulder Bands", "slot": "passive", "kind": "armor_low", "amount": 30},
	"avalanche_roll": {"name": "Avalanche Roll", "slot": "ultimate", "target": "row", "pct": 110, "stagger": 45},
	# Drillrat
	"drill_bite": {"name": "Drill Bite", "slot": "basic", "pct": 85, "pierce": true},
	"tunnel_sense": {"name": "Tunnel Sense", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 20},
	"cave_in": {"name": "Cave In", "slot": "ultimate", "target": "weakest", "pct": 170, "stagger": 40},
	# Augerhino
	"auger_horn": {"name": "Auger Horn", "slot": "basic", "pct": 95, "pierce": true},
	"bore_through": {"name": "Bore Through", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"deep_drill": {"name": "Deep Drill", "slot": "ultimate", "target": "adjacent", "pct": 150, "pierce": true, "stagger": 30},
	# Cliffkite
	"ledge_swoop": {"name": "Ledge Swoop", "slot": "basic", "pct": 85, "bonus": {"vs": "hurt", "amount": 40}},
	"thin_air": {"name": "Thin Air", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"cliff_drop": {"name": "Cliff Drop", "slot": "ultimate", "target": "weakest", "pct": 170, "pierce": true},
	# Talonwalla
	"talon_crush": {"name": "Talon Crush", "slot": "basic", "pct": 90, "pierce": true},
	"killing_eye": {"name": "Killing Eye", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 30},
	"sky_crush": {"name": "Sky Crush", "slot": "ultimate", "target": "weakest", "pct": 210, "pierce": true},
	# Shaleyak
	"shale_shove": {"name": "Shale Shove", "slot": "basic", "pct": 75, "stagger": 20},
	"scaled_wool": {"name": "Scaled Wool", "slot": "passive", "kind": "armor_low", "amount": 20},
	"rock_wall": {"name": "Rock Wall", "slot": "ultimate", "target": "adjacent", "pct": 90, "stagger": 35, "self": {"shield_def": 120}},
	# Plateyak
	"plate_charge": {"name": "Plate Charge", "slot": "basic", "pct": 80, "stagger": 30},
	"slate_scales": {"name": "Slate Scales", "slot": "passive", "kind": "armor_low", "amount": 30},
	"rockfall_wall": {"name": "Rockfall Wall", "slot": "ultimate", "target": "row", "pct": 100, "stagger": 40, "self": {"shield_def": 140}},
	# Gravelbat
	"gravel_bite": {"name": "Gravel Bite", "slot": "basic", "pct": 75, "pierce": true},
	"echo_hunt": {"name": "Echo Hunt", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 25},
	"rock_shriek": {"name": "Rock Shriek", "slot": "ultimate", "target": "row", "pct": 90, "stagger": 35},
	# Stormrhino
	"thunder_horn": {"name": "Thunder Horn", "slot": "basic", "pct": 95, "stagger": 30, "splash": 30},
	"storm_hide": {"name": "Storm Hide", "slot": "passive", "kind": "armor_low", "amount": 30},
	"skyfall_charge": {"name": "Skyfall Charge", "slot": "ultimate", "target": "row", "pct": 150, "pierce": true, "stagger": 40},
	# Obsidiwolf
	"obsidian_fang": {"name": "Obsidian Fang", "slot": "basic", "pct": 90, "pierce": true},
	"glass_hunger": {"name": "Glass Hunger", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 35},
	"shatter_howl": {"name": "Shatter Howl", "slot": "ultimate", "target": "all", "pct": 90, "pierce": true},
}

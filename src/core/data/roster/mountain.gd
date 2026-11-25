extends RefCounted
## Mountain Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"slatebeak": {"rarity": "common", "name": "Slatebeak", "type": "Mountain", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "steady": 1}},
	"quarrytusk": {"rarity": "rare", "name": "Quarrytusk", "type": "Mountain", "size": "large", "hauling": 160,
		"capabilities": {"strength": 3, "clear": 2}},
	"cragkid": {"rarity": "common", "name": "Cragkid", "type": "Mountain", "size": "medium", "hauling": 70,
		"capabilities": {"steady": 3, "strength": 1}},
	"basaltortle": {"rarity": "rare", "name": "Basaltortle", "type": "Mountain", "size": "large", "hauling": 130,
		"capabilities": {"strength": 2, "steady": 3}},
	"titanox": {"rarity": "legendary", "name": "Titanox", "type": "Mountain", "size": "large", "hauling": 200,
		"capabilities": {"strength": 3, "steady": 3}},
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
}

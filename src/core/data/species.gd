class_name Species
extends RefCounted
## Creature species used by the first playable.
##
## size sets daily upkeep (provisions per day): small 0.5, medium 1, large 2.
## hauling is pulling strength in hauling units (0 = cannot haul).
## Capabilities (trail jobs) are ranks 1-3 used by event checks and trail moments:
## clear, strength, float, light, scout, steady, guard, cold, heal, forage.

const UPKEEP := {"small": 0.5, "medium": 1.0, "large": 2.0}

## Rarity: how often a species turns up in the wild and offers to join, and how strong it is.
## Commons are everywhere, rares turn up less, legendaries are rare finds from crossing 2 on.
## Guardians are the bosses at the end of each crossing and never join.
const RARITIES := {
	"common": {"name": "Common", "color": "c8d6c0", "weight": 6, "from_crossing": 1},
	"rare": {"name": "Rare", "color": "7fc8ff", "weight": 3, "from_crossing": 1},
	"legendary": {"name": "Legendary", "color": "ffc95a", "weight": 1, "from_crossing": 2},
	"guardian": {"name": "Guardian", "color": "ff8a7a", "weight": 0, "from_crossing": 99},
}

const DATA := {
	"brambleback": {"rarity": "rare", "name": "Brambleback", "type": "Forest", "size": "large", "hauling": 150,
		"capabilities": {"strength": 3, "guard": 3}},
	"coilhusk": {"rarity": "rare", "name": "Coilhusk", "type": "Forest", "size": "large", "hauling": 130,
		"capabilities": {"strength": 2, "steady": 3}},
	"reedwake": {"rarity": "common", "name": "Reedwake", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "scout": 1, "forage": 1}},
	"mirelamp": {"rarity": "common", "name": "Mirelamp", "type": "Swamp", "size": "small", "hauling": 0,
		"capabilities": {"light": 3, "heal": 2, "scout": 1, "forage": 2}},
	"rimehare": {"rarity": "common", "name": "Rimehare", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "cold": 2, "forage": 2}},
	"scythelk": {"rarity": "rare", "name": "Scythelk", "type": "Mountain", "size": "large", "hauling": 90,
		"capabilities": {"clear": 3, "strength": 2}},
	"gillhorn": {"rarity": "rare", "name": "Gillhorn", "type": "Swamp", "size": "medium", "hauling": 60,
		"capabilities": {"float": 2, "strength": 2, "forage": 1}},
	"inkhoot": {"rarity": "common", "name": "Inkhoot", "type": "River", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "float": 1}},
	# Wild creatures met in battle (not in the starting roster).
	"thornfang": {"rarity": "common", "name": "Thornfang", "type": "Forest", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 2, "guard": 1, "forage": 2}},
	"cairnram": {"rarity": "common", "name": "Cairnram", "type": "Mountain", "size": "large", "hauling": 120,
		"capabilities": {"clear": 2, "strength": 3}},
	"lianetail": {"rarity": "common", "name": "Lianetail", "type": "Jungle", "size": "small", "hauling": 0,
		"capabilities": {"scout": 3, "clear": 1, "forage": 3}},
	"frostsnip": {"rarity": "common", "name": "Frostsnip", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"cold": 3, "float": 1}},
	"plateflit": {"rarity": "rare", "name": "Plateflit", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"guard": 2, "scout": 1}},
	"hollowstag": {"rarity": "guardian", "name": "Hollowstag", "type": "Forest", "size": "large", "hauling": 0,
		"capabilities": {}},
	# ----- Added with varied crossings -----
	"mossmole": {"rarity": "common", "name": "Mossmole", "type": "Forest", "size": "small", "hauling": 0,
		"capabilities": {"clear": 2, "forage": 2}},
	"burlbear": {"rarity": "rare", "name": "Burlbear", "type": "Forest", "size": "large", "hauling": 140,
		"capabilities": {"strength": 3, "guard": 2}},
	"pebblotter": {"rarity": "common", "name": "Pebblotter", "type": "River", "size": "small", "hauling": 0,
		"capabilities": {"float": 2, "heal": 1, "forage": 2}},
	"lanternray": {"rarity": "rare", "name": "Lanternray", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "light": 2}},
	"sporetoad": {"rarity": "common", "name": "Sporetoad", "type": "Swamp", "size": "small", "hauling": 0,
		"capabilities": {"heal": 1, "forage": 2, "float": 1}},
	"bogjaw": {"rarity": "rare", "name": "Bogjaw", "type": "Swamp", "size": "large", "hauling": 110,
		"capabilities": {"strength": 2, "float": 2, "guard": 1}},
	"slatebeak": {"rarity": "common", "name": "Slatebeak", "type": "Mountain", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "steady": 1}},
	"quarrytusk": {"rarity": "rare", "name": "Quarrytusk", "type": "Mountain", "size": "large", "hauling": 160,
		"capabilities": {"strength": 3, "clear": 2}},
	"flurrypup": {"rarity": "common", "name": "Flurrypup", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"cold": 2, "scout": 2}},
	"rimewing": {"rarity": "rare", "name": "Rimewing", "type": "Snow", "size": "medium", "hauling": 0,
		"capabilities": {"cold": 3, "scout": 2}},
	"vinegecko": {"rarity": "common", "name": "Vinegecko", "type": "Jungle", "size": "small", "hauling": 0,
		"capabilities": {"clear": 2, "scout": 2, "forage": 1}},
	"canopard": {"rarity": "rare", "name": "Canopard", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "guard": 1}},
	"emberoak": {"rarity": "legendary", "name": "Emberoak", "type": "Forest", "size": "large", "hauling": 180,
		"capabilities": {"strength": 3, "guard": 3, "light": 2}},
	"tidewyrm": {"rarity": "legendary", "name": "Tidewyrm", "type": "River", "size": "large", "hauling": 0,
		"capabilities": {"float": 3, "heal": 3}},
	"auroryx": {"rarity": "legendary", "name": "Auroryx", "type": "Snow", "size": "medium", "hauling": 90,
		"capabilities": {"cold": 3, "light": 2, "scout": 2}},
	# Guardians (bosses at the end of later crossings).
	"bogmother": {"rarity": "guardian", "name": "Bog Mother", "type": "Swamp", "size": "large", "hauling": 0,
		"capabilities": {}},
	"cogmammoth": {"rarity": "guardian", "name": "Cogmammoth", "type": "Mountain", "size": "large", "hauling": 0,
		"capabilities": {}},
	"rimewyrm": {"rarity": "guardian", "name": "Rimewyrm", "type": "Snow", "size": "large", "hauling": 0,
		"capabilities": {}},
}


static func info(id: String) -> Dictionary:
	return DATA[id]


static func upkeep(id: String) -> float:
	return UPKEEP[DATA[id]["size"]]


static func capability(id: String, cap: String) -> int:
	return int(DATA[id]["capabilities"].get(cap, 0))


static func rarity(id: String) -> String:
	return String(DATA[id].get("rarity", "common"))


## The species name coloured by rarity (common names stay plain).
static func name_markup(id: String) -> String:
	var r := rarity(id)
	if r == "common":
		return String(DATA[id]["name"])
	return "[color=#%s]%s[/color]" % [RARITIES[r]["color"], DATA[id]["name"]]


## "Rare" / "Legendary" tag in its colour, for cards and tooltips.
static func rarity_tag(id: String) -> String:
	var r: Dictionary = RARITIES[rarity(id)]
	return "[color=#%s]%s[/color]" % [r["color"], r["name"]]


static func is_boss(id: String) -> bool:
	return rarity(id) == "guardian"


## Whether a species can turn up in the wild on this crossing.
static func can_meet(id: String, crossing_no: int) -> bool:
	return crossing_no >= int(RARITIES[rarity(id)]["from_crossing"])


## Pick one species, commons more often than rares, rares more than legendaries.
static func pick_weighted(ids: Array, rng: RandomNumberGenerator) -> String:
	var total := 0
	for id in ids:
		total += int(RARITIES[rarity(id)]["weight"])
	if total <= 0:
		return String(ids[0]) if not ids.is_empty() else ""
	var roll := rng.randi_range(1, total)
	for id in ids:
		roll -= int(RARITIES[rarity(id)]["weight"])
		if roll <= 0:
			return String(id)
	return String(ids[-1])

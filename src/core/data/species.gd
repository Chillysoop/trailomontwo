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

## The hand-written species. Everything else comes from the roster files (see Roster).
const BASE := {
	"brambleback": {"rarity": "rare", "name": "Brambleback", "type": "Forest", "size": "large", "hauling": 150,
		"capabilities": {"strength": 3, "guard": 3}},
	"coilhusk": {"rarity": "rare", "name": "Coilhusk", "type": "Forest", "size": "large", "hauling": 130,
		"capabilities": {"strength": 2, "steady": 3}},
	"reedwake": {"rarity": "common", "name": "Reedwake", "type": "River", "size": "medium", "hauling": 0,
		"capabilities": {"float": 3, "scout": 1, "forage": 1}},
	"mirelamp": {"rarity": "common", "name": "Mirelamp", "type": "Swamp", "size": "small", "hauling": 0, "evolves_to": "anglenewt",
		"capabilities": {"light": 3, "heal": 2, "scout": 1, "forage": 2}},
	"rimehare": {"rarity": "common", "name": "Rimehare", "type": "Snow", "size": "small", "hauling": 0, "evolves_to": "ptarmhare",
		"capabilities": {"scout": 3, "cold": 2, "forage": 2}},
	"scythelk": {"rarity": "rare", "name": "Scythelk", "type": "Mountain", "size": "large", "hauling": 90,
		"capabilities": {"clear": 3, "strength": 2}},
	"gillhorn": {"rarity": "rare", "name": "Gillhorn", "type": "Swamp", "size": "medium", "hauling": 60,
		"capabilities": {"float": 2, "strength": 2, "forage": 1}},
	"inkhoot": {"rarity": "common", "name": "Inkhoot", "type": "River", "size": "small", "hauling": 0, "evolves_to": "inkstrix",
		"capabilities": {"scout": 3, "float": 1}},
	# Wild creatures met in battle (not in the starting roster).
	"thornfang": {"rarity": "common", "name": "Thornfang", "type": "Forest", "size": "medium", "hauling": 0, "evolves_to": "briarwolf",
		"capabilities": {"scout": 2, "guard": 1, "forage": 2}},
	"cairnram": {"rarity": "common", "name": "Cairnram", "type": "Mountain", "size": "large", "hauling": 120, "evolves_to": "rhinoram",
		"capabilities": {"clear": 2, "strength": 3}},
	"lianetail": {"rarity": "common", "name": "Lianetail", "type": "Jungle", "size": "small", "hauling": 0, "evolves_to": "swingibbon",
		"capabilities": {"scout": 3, "clear": 1, "forage": 3}},
	"frostsnip": {"rarity": "common", "name": "Frostsnip", "type": "Snow", "size": "small", "hauling": 0,
		"capabilities": {"cold": 3, "float": 1}},
	"plateflit": {"rarity": "rare", "name": "Plateflit", "type": "Jungle", "size": "medium", "hauling": 0,
		"capabilities": {"guard": 2, "scout": 1}},
	"hollowstag": {"rarity": "guardian", "name": "Hollowstag", "type": "Forest", "size": "large", "hauling": 0,
		"capabilities": {}},
}

## Every species: BASE plus the roster files.
static var DATA: Dictionary = Roster.merged("SPECIES", BASE)


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


# ---------- evolution ----------
## A species can name what it grows into with "evolves_to" (one id, or a list when the line
## branches, one form per archetype) and, optionally, "evolve_level". By default stage 1
## evolves at level 10 and stage 2 at level 20.

const EVOLVE_LEVELS := {1: 10, 2: 20}


## What this species can evolve into ([] if it doesn't evolve).
static func evolutions(id: String) -> Array[String]:
	var out: Array[String] = []
	var to: Variant = DATA.get(id, {}).get("evolves_to", "")
	if to is Array:
		for t in to:
			out.append(String(t))
	elif String(to) != "":
		out.append(String(to))
	return out


## The species this one evolves from ("" for a first stage).
static func previous(id: String) -> String:
	for other in DATA:
		if evolutions(other).has(id):
			return String(other)
	return ""


## 1 for a first stage, 2 for its evolution, 3 for the one after that.
static func stage(id: String) -> int:
	var n := 1
	var p := previous(id)
	while p != "" and n < 5:
		n += 1
		p = previous(p)
	return n


## The first stage of this species' line (its family).
static func family(id: String) -> String:
	var p := id
	while previous(p) != "":
		p = previous(p)
	return p


## The level this species can evolve at.
static func evolve_level(id: String) -> int:
	return int(DATA.get(id, {}).get("evolve_level", EVOLVE_LEVELS.get(stage(id), 20)))


## Dust-biome species: "Blight" or "Glow" ("" for ordinary habitat species).
static func biome(id: String) -> String:
	return String(DATA.get(id, {}).get("biome", ""))

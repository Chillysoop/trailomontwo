class_name CombatData
extends RefCounted
## Battle numbers for every species: stats, abilities, habitat matchups, team synergies
## and the wild packs met on the trail. Pure data, no scene code.
##
## Stats: hp, might (physical power), spirit (healing, shields, resonance), guard (cuts
## incoming damage: x 100 / (100 + guard)) and tempo (basic attack speed: one attack every
## TEMPO_SCALE / tempo seconds).

const TEMPO_SCALE := 100.0

## Advantage and disadvantage multipliers from the design doc.
const STRONG := 1.25
const WEAK := 0.85
## Attacking type -> [strong against, weak against].
const CHART := {
	"River": ["Forest", "Snow"],
	"Forest": ["Swamp", "River"],
	"Swamp": ["Mountain", "Forest"],
	"Mountain": ["Jungle", "Swamp"],
	"Jungle": ["Snow", "Mountain"],
	"Snow": ["River", "Jungle"],
}

## role is shown in the lineup panel and decides auto-arrange (guards go to the front).
const STATS := {
	"brambleback": {"role": "Guard", "hp": 230, "might": 11, "spirit": 12, "guard": 40, "tempo": 55,
		"abilities": ["bristle", "brace"]},
	"coilhusk": {"role": "Bruiser", "hp": 210, "might": 15, "spirit": 9, "guard": 30, "tempo": 55,
		"abilities": ["shell_slam", "coil_up"]},
	"reedwake": {"role": "Healer", "hp": 140, "might": 9, "spirit": 16, "guard": 12, "tempo": 65,
		"abilities": ["mend_current"]},
	"mirelamp": {"role": "Support", "hp": 130, "might": 10, "spirit": 14, "guard": 14, "tempo": 65,
		"abilities": ["bog_spit", "glow_ward"]},
	"rimehare": {"role": "Support", "hp": 120, "might": 11, "spirit": 12, "guard": 10, "tempo": 90,
		"abilities": ["rally_bell"]},
	"scythelk": {"role": "Striker", "hp": 170, "might": 17, "spirit": 8, "guard": 18, "tempo": 70,
		"abilities": ["sweep"]},
	"gillhorn": {"role": "Bruiser", "hp": 180, "might": 14, "spirit": 8, "guard": 25, "tempo": 60,
		"abilities": ["charge"]},
	"inkhoot": {"role": "Striker", "hp": 110, "might": 14, "spirit": 10, "guard": 8, "tempo": 75,
		"abilities": ["dive", "ink_cloud"]},
	"thornfang": {"role": "Striker", "hp": 120, "might": 13, "spirit": 6, "guard": 12, "tempo": 80,
		"abilities": ["rend"]},
	"cairnram": {"role": "Guard", "hp": 200, "might": 13, "spirit": 8, "guard": 35, "tempo": 50,
		"abilities": ["breakstone"]},
	"lianetail": {"role": "Striker", "hp": 100, "might": 13, "spirit": 8, "guard": 8, "tempo": 85,
		"abilities": ["vine_lash"]},
	"frostsnip": {"role": "Striker", "hp": 105, "might": 12, "spirit": 10, "guard": 15, "tempo": 75,
		"abilities": ["frost_sting"]},
	"plateflit": {"role": "Guard", "hp": 150, "might": 11, "spirit": 10, "guard": 35, "tempo": 60,
		"abilities": ["plate_up", "wing_gust"]},
	"hollowstag": {"role": "Boss", "hp": 520, "might": 15, "spirit": 15, "guard": 30, "tempo": 45,
		"abilities": ["antler_storm", "hollow_call"]},
}

## Every creature also has a basic attack of this power using might.
const BASIC_POWER := 10.0
## Every creature's listed hp is multiplied by this, so fights last long enough to read.
const HP_SCALE := 2.0

## kind: damage, heal, shield, taunt, haste, weaken, slow, poison.
## target (damage kinds): front (normal targeting), back (reaches the second row),
##   weakest (lowest health enemy anywhere), row (everyone in the target's row).
## target (helpful kinds): self, adjacent (self and lane neighbours), weakest_ally, team.
## stat: which stat scales power. secs: how long a status lasts.
const ABILITIES := {
	"bristle": {"name": "Bristle", "kind": "taunt", "target": "self", "cooldown": 9.0, "secs": 4.0,
		"desc": "Draws every enemy's normal attacks to itself for 4s."},
	"brace": {"name": "Brace", "kind": "shield", "target": "adjacent", "cooldown": 8.0, "power": 22.0, "stat": "spirit",
		"desc": "Shields itself and the allies beside it."},
	"shell_slam": {"name": "Shell Slam", "kind": "damage", "target": "front", "cooldown": 6.0, "power": 26.0, "stat": "might",
		"desc": "A heavy blow to the enemy in front."},
	"coil_up": {"name": "Coil Up", "kind": "shield", "target": "self", "cooldown": 10.0, "power": 35.0, "stat": "spirit",
		"desc": "Curls into its shell for a big shield."},
	"mend_current": {"name": "Mend Current", "kind": "heal", "target": "weakest_ally", "cooldown": 4.0, "power": 30.0, "stat": "spirit",
		"shield_bonus": 0.3, "desc": "Heals the most hurt ally. Heals 30% more on a shielded ally."},
	"bog_spit": {"name": "Bog Spit", "kind": "poison", "target": "front", "cooldown": 7.0, "power": 4.0, "stat": "spirit", "secs": 5.0,
		"desc": "Poisons the enemy in front for 5s."},
	"glow_ward": {"name": "Glow Ward", "kind": "shield", "target": "weakest_ally", "cooldown": 7.0, "power": 20.0, "stat": "spirit",
		"desc": "Shields the most hurt ally."},
	"rally_bell": {"name": "Rally Bell", "kind": "haste", "target": "team", "cooldown": 12.0, "power": 0.3, "secs": 5.0,
		"desc": "Every ally attacks 30% faster for 5s."},
	"sweep": {"name": "Scythe Sweep", "kind": "damage", "target": "row", "cooldown": 7.0, "power": 16.0, "stat": "might",
		"desc": "Hits every enemy in the target's row."},
	"charge": {"name": "Horn Charge", "kind": "damage", "target": "front", "cooldown": 7.0, "power": 28.0, "stat": "might",
		"desc": "A charging horn strike."},
	"dive": {"name": "Dive", "kind": "damage", "target": "weakest", "cooldown": 6.0, "power": 20.0, "stat": "might",
		"desc": "Dives past the front row to hit the weakest enemy."},
	"ink_cloud": {"name": "Ink Cloud", "kind": "weaken", "target": "front", "cooldown": 10.0, "power": 0.3, "secs": 5.0,
		"desc": "Lowers the target's guard by 30% for 5s."},
	"rend": {"name": "Rend", "kind": "poison", "target": "front", "cooldown": 6.0, "power": 4.0, "stat": "might", "secs": 4.0,
		"desc": "A tearing bite that bleeds for 4s."},
	"breakstone": {"name": "Breakstone", "kind": "damage", "target": "front", "cooldown": 8.0, "power": 30.0, "stat": "might",
		"pierce": true, "desc": "Smashes through guard completely."},
	"vine_lash": {"name": "Vine Lash", "kind": "damage", "target": "back", "cooldown": 6.0, "power": 18.0, "stat": "might",
		"desc": "Lashes over the front row at the second row."},
	"frost_sting": {"name": "Frost Sting", "kind": "slow", "target": "front", "cooldown": 7.0, "power": 0.3, "secs": 4.0,
		"damage": 14.0, "stat": "might", "desc": "A chilling sting that slows the target by 30%."},
	"plate_up": {"name": "Plate Up", "kind": "shield", "target": "self", "cooldown": 9.0, "power": 28.0, "stat": "spirit",
		"desc": "Locks its plates into a shield."},
	"wing_gust": {"name": "Wing Gust", "kind": "damage", "target": "row", "cooldown": 9.0, "power": 12.0, "stat": "might",
		"desc": "A gust that hits a whole row."},
	"antler_storm": {"name": "Antler Storm", "kind": "damage", "target": "row", "cooldown": 7.0, "power": 20.0, "stat": "might",
		"desc": "Hollow antlers rain down on a whole row."},
	"hollow_call": {"name": "Hollow Call", "kind": "heal", "target": "team", "cooldown": 12.0, "power": 14.0, "stat": "spirit",
		"desc": "Heals every creature on its side."},
}

## Habitat synergies (like a team bonus): with `need` or more creatures of a type on your
## side, those creatures gain the bonus. The second tier doubles it.
const SYNERGIES := {
	"Forest": {"name": "Deep Roots", "need": [2, 4], "desc": "Forest allies +%d guard", "values": [15, 30]},
	"River": {"name": "Flowing", "need": [2, 4], "desc": "River heals and shields +%d%%", "values": [25, 50]},
	"Swamp": {"name": "Murk", "need": [2, 4], "desc": "Swamp attacks poison %d/s", "values": [2, 4]},
	"Mountain": {"name": "Bedrock", "need": [2, 4], "desc": "Mountain allies +%d%% might", "values": [15, 30]},
	"Snow": {"name": "Flurry", "need": [2, 4], "desc": "Snow allies attack +%d%% faster", "values": [15, 30]},
	"Jungle": {"name": "Canopy", "need": [2, 4], "desc": "Jungle +%d%% vs second row", "values": [20, 40]},
}

## Wild packs. front/back: three lanes each, top to bottom ("" = empty).
## boss stands behind the enemy grid and can't be hit while the grid has creatures left.
const PACKS := [
	{"id": "thornfang_pack", "title": "A thornfang pack", "terrains": ["Forest", "Hills"], "min_risk": 1,
		"text": "Low growls from the ferns. A thornfang pack is circling the wagon.",
		"front": ["thornfang", "thornfang", "thornfang"], "back": ["", "lianetail", ""]},
	{"id": "river_ambush", "title": "Riverbank ambush", "terrains": ["River"], "min_risk": 1,
		"text": "Gillhorns burst out of the shallows, horns down.",
		"front": ["gillhorn", "", "gillhorn"], "back": ["inkhoot", "", "inkhoot"]},
	{"id": "bog_lurkers", "title": "Bog lurkers", "terrains": ["Swamp"], "min_risk": 1,
		"text": "Something with plated wings rises out of the reeds, and it isn't alone.",
		"front": ["plateflit", "gillhorn", "plateflit"], "back": ["", "", "lianetail"]},
	{"id": "rock_herd", "title": "An angry herd", "terrains": ["Mountain", "Hills"], "min_risk": 2,
		"text": "Cairnrams block the pass, stamping and lowering their horns.",
		"front": ["cairnram", "", "cairnram"], "back": ["frostsnip", "inkhoot", "frostsnip"]},
	{"id": "frost_swarm", "title": "Frostsnip swarm", "terrains": [], "min_risk": 2,
		"text": "A skittering swarm of frostsnips pours across the trail.",
		"front": ["frostsnip", "frostsnip", "frostsnip"], "back": ["", "inkhoot", "frostsnip"]},
	{"id": "canopy_raiders", "title": "Canopy raiders", "terrains": ["Forest", "River"], "min_risk": 2,
		"text": "Lianetails drop from the branches while a thornfang cuts off the road.",
		"front": ["plateflit", "thornfang", ""], "back": ["lianetail", "", "lianetail"]},
]

## The guardian that waits on the last stretch to Westwatch.
const GUARDIAN := {"id": "hollow_stag", "title": "The Hollow Stag", "terrains": [], "min_risk": 1, "boss": "hollowstag",
	"text": "The trail goes silent. A huge stag with hollow, glowing antlers steps out ahead, its pack fanning out around it.",
	"front": ["thornfang", "cairnram", "thornfang"], "back": ["lianetail", "frostsnip", "lianetail"]}

## Enemy strength by segment risk (health and power multiplier).
const RISK_SCALE := {1: 1.0, 2: 1.15, 3: 1.3}
## The guardian pack always fights at this strength.
const GUARDIAN_SCALE := 1.15


static func stats(id: String) -> Dictionary:
	return STATS[id]


static func ability(id: String) -> Dictionary:
	return ABILITIES[id]


static func type_of(id: String) -> String:
	return Species.info(id)["type"]


## Damage multiplier for an attack of `attack_type` against a creature of `target_type`.
static func matchup(attack_type: String, target_type: String) -> float:
	var row: Array = CHART.get(attack_type, ["", ""])
	if row[0] == target_type:
		return STRONG
	if row[1] == target_type:
		return WEAK
	return 1.0


## Active synergy tier (0 none, 1, 2) for a type given how many of it are on a side.
static func synergy_tier(type: String, count: int) -> int:
	if not SYNERGIES.has(type):
		return 0
	var need: Array = SYNERGIES[type]["need"]
	if count >= need[1]:
		return 2
	if count >= need[0]:
		return 1
	return 0


static func synergy_value(type: String, tier: int) -> float:
	if tier <= 0:
		return 0.0
	return float(SYNERGIES[type]["values"][tier - 1])


## Type -> count for a list of species ids.
static func type_counts(ids: Array) -> Dictionary:
	var out := {}
	for id in ids:
		var t := type_of(id)
		out[t] = int(out.get(t, 0)) + 1
	return out


## Readable synergy lines for a team, active ones first.
static func synergy_lines(ids: Array) -> Array[String]:
	var counts := type_counts(ids)
	var active: Array[String] = []
	var near: Array[String] = []
	for t in SYNERGIES:
		var n: int = counts.get(t, 0)
		if n == 0:
			continue
		var tier := synergy_tier(t, n)
		var s: Dictionary = SYNERGIES[t]
		if tier > 0:
			active.append("%s x%d: %s" % [s["name"], n, s["desc"] % int(synergy_value(t, tier))])
		else:
			near.append("%s %d/%d" % [t, n, s["need"][0]])
	if not near.is_empty():
		active.append("Close: " + ", ".join(near))
	return active


static func packs_for(seg: Dictionary) -> Array:
	var out: Array = []
	for p in PACKS:
		var terrains: Array = p["terrains"]
		if int(seg.get("risk", 1)) >= int(p["min_risk"]) and (terrains.is_empty() or terrains.has(seg.get("terrain", ""))):
			out.append(p)
	return out


static func pack_by_id(id: String) -> Dictionary:
	if id == GUARDIAN["id"]:
		return GUARDIAN
	for p in PACKS:
		if p["id"] == id:
			return p
	return {}

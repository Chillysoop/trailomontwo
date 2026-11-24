class_name CombatData
extends RefCounted
## Battle numbers for every species: stats, kits (basic attack, passive, ultimate), habitat
## matchups, team synergies and the wild packs met on the trail. Pure data, no scene code.
##
## Stats (Astronarch-style):
##   hp   health
##   atk  Attack: abilities deal a percentage of it
##   def  Defense: incoming damage x 100 / (100 + def)
##   spd  seconds between basic attacks (lower is faster)
## Every creature has three moves:
##   basic     fires each time its attack bar fills
##   passive   always on, usually tied to its basic attacks
##   ultimate  fires when its ultimate bar fills (from attacking and from being hit)

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

## The ultimate bar fills to this.
const ULT_MAX := 100.0
## Ultimate charge from each basic attack (unless a kit says otherwise) and from each hit taken.
const ULT_PER_ATTACK := 16.0
const ULT_PER_HIT := 4.0
## Listed hp x this, so fights last long enough to read (tuning knob).
const HP_MULT := 2.0

## Habitat themes, used for the kits below:
##   Forest   endurance: thorns, bark and shields
##   River    flow: healing, cleansing, life drain
##   Swamp    rot: poison and weakened defense
##   Mountain weight: heavy blows, pierce, armor
##   Snow     cold and speed: slow, haste
##   Jungle   reach: hitting the second row
const KITS := {
	"brambleback": {"role": "Guard", "hp": 520, "atk": 26, "def": 45, "spd": 2.2,
		"basic": "bramble_swipe", "passive": "thorny_hide", "ultimate": "briar_wall"},
	"coilhusk": {"role": "Bruiser", "hp": 480, "atk": 32, "def": 34, "spd": 2.1,
		"basic": "trunk_slam", "passive": "bark_shell", "ultimate": "shell_quake"},
	"reedwake": {"role": "Healer", "hp": 320, "atk": 26, "def": 15, "spd": 1.8,
		"basic": "mending_spray", "passive": "clear_water", "ultimate": "tidewash"},
	"mirelamp": {"role": "Support", "hp": 300, "atk": 26, "def": 18, "spd": 1.9,
		"basic": "bog_spit", "passive": "rot_light", "ultimate": "miasma"},
	"rimehare": {"role": "Support", "hp": 280, "atk": 25, "def": 12, "spd": 1.4,
		"basic": "frost_kick", "passive": "snow_runner", "ultimate": "rally_bell"},
	"scythelk": {"role": "Striker", "hp": 380, "atk": 38, "def": 22, "spd": 2.0,
		"basic": "scythe_cut", "passive": "rockhorn", "ultimate": "scythe_sweep"},
	"gillhorn": {"role": "Bruiser", "hp": 420, "atk": 30, "def": 28, "spd": 2.1,
		"basic": "mud_horn", "passive": "mudwallow", "ultimate": "bog_charge"},
	"inkhoot": {"role": "Striker", "hp": 260, "atk": 32, "def": 10, "spd": 1.7,
		"basic": "ink_jet", "passive": "undertow", "ultimate": "dive"},
	"thornfang": {"role": "Striker", "hp": 290, "atk": 28, "def": 14, "spd": 1.6,
		"basic": "bite", "passive": "pack_hunter", "ultimate": "rend"},
	"cairnram": {"role": "Guard", "hp": 420, "atk": 27, "def": 40, "spd": 2.3,
		"basic": "headbutt", "passive": "stubborn", "ultimate": "breakstone"},
	"lianetail": {"role": "Striker", "hp": 240, "atk": 28, "def": 10, "spd": 1.6,
		"basic": "vine_whip", "passive": "canopy_stalker", "ultimate": "vine_lash"},
	"frostsnip": {"role": "Striker", "hp": 260, "atk": 27, "def": 18, "spd": 1.7,
		"basic": "frost_sting", "passive": "brittle", "ultimate": "frost_burst"},
	"plateflit": {"role": "Guard", "hp": 360, "atk": 24, "def": 38, "spd": 2.0,
		"basic": "wing_bash", "passive": "glide", "ultimate": "wing_gust"},
	"hollowstag": {"role": "Boss", "hp": 900, "atk": 34, "def": 35, "spd": 2.2,
		"basic": "antler_gore", "passive": "ancient_bark", "ultimate": "antler_storm",
		"ult_per_attack": 10.0, "ult_per_hit": 0.6},
}

## Move text uses Rich markup plus number tokens filled from the creature's stats:
##   {atk:120}   "120% Attack (54)"     {maxhp:15}  "15% Max HP (69)"
##   {def:100}   "100% Defense (45)"
## Behaviour lives in Battle (matched by id); the numbers here are what it reads.
const MOVES := {
	# ----- Forest -----
	"bramble_swipe": {"name": "Bramble Swipe", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"thorny_hide": {"name": "Thorny Hide", "slot": "passive", "pct": 35,
		"desc": "When a basic attack hits you, deal {atk:35} back to the attacker."},
	"briar_wall": {"name": "Briar Wall", "slot": "ultimate", "def_pct": 100, "flat": 60, "secs": 4.0,
		"desc": "You and all {k:adjacent} allies gain {k:shield|Shield} equal to {def:100} plus 60. {k:taunt|Taunt} enemies for 4s."},
	"trunk_slam": {"name": "Trunk Slam", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"bark_shell": {"name": "Bark Shell", "slot": "passive", "every": 3, "def_pct": 120,
		"desc": "Every 3rd basic attack also gives you {k:shield|Shield} equal to {def:120}."},
	"shell_quake": {"name": "Shell Quake", "slot": "ultimate", "pct": 180, "splash": 60,
		"desc": "Deal {atk:180} to your target and {atk:60} to enemies {k:adjacent} to it."},
	"antler_gore": {"name": "Antler Gore", "slot": "basic", "pct": 100, "splash": 40,
		"desc": "Deal {atk:100} to your target and {atk:40} to enemies {k:adjacent} to it."},
	"ancient_bark": {"name": "Ancient Bark", "slot": "passive", "pct": 25,
		"desc": "When a basic attack hits you, deal {atk:25} back to the attacker."},
	"antler_storm": {"name": "Antler Storm", "slot": "ultimate", "pct": 90, "flat": 80,
		"desc": "Deal {atk:90} to every enemy, then {k:shield|Shield} your whole pack for 80."},
	"bite": {"name": "Bite", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"pack_hunter": {"name": "Pack Hunter", "slot": "passive", "pct": 12,
		"desc": "Deal 12% more damage for each other Thornfang still standing."},
	"rend": {"name": "Rend", "slot": "ultimate", "pct": 150, "secs": 6.0, "amount": 50,
		"desc": "Deal {atk:150} to your target and apply {k:ruin} (healing it receives is halved) for 6s."},
	# ----- River -----
	"mending_spray": {"name": "Mending Spray", "slot": "basic", "pct": 70, "heal_pct": 60,
		"desc": "Deal {atk:70} to your target and heal the most hurt ally for {atk:60}."},
	"clear_water": {"name": "Clear Water", "slot": "passive",
		"desc": "Your heals also wash {k:poison} off the ally."},
	"tidewash": {"name": "Tidewash", "slot": "ultimate", "maxhp_pct": 15,
		"desc": "Heal every ally for 15% of their Max HP."},
	"ink_jet": {"name": "Ink Jet", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"undertow": {"name": "Undertow", "slot": "passive", "pct": 25,
		"desc": "Heal yourself for 25% of the damage you deal."},
	"dive": {"name": "Dive", "slot": "ultimate", "pct": 220,
		"desc": "Dive past the {k:front_row} and deal {atk:220} to the weakest enemy anywhere."},
	# ----- Swamp -----
	"bog_spit": {"name": "Bog Spit", "slot": "basic", "pct": 70, "dot": 15, "secs": 4.0,
		"desc": "Deal {atk:70} to your target and {k:poison} it for {atk:15} a second for 4s."},
	"rot_light": {"name": "Rot Light", "slot": "passive", "amount": 20,
		"desc": "Enemies you {k:poison} are also {k:weaken|weakened}: 20% less Defense."},
	"miasma": {"name": "Miasma", "slot": "ultimate", "dot": 25, "secs": 5.0,
		"desc": "{k:poison|Poison} every enemy for {atk:25} a second for 5s."},
	"mud_horn": {"name": "Mud Horn", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"mudwallow": {"name": "Mudwallow", "slot": "passive", "amount": 30,
		"desc": "Deal 30% more damage to {k:poison|poisoned} enemies."},
	"bog_charge": {"name": "Bog Charge", "slot": "ultimate", "pct": 180, "dot": 30, "secs": 4.0,
		"desc": "Deal {atk:180} to your target and {k:poison} it for {atk:30} a second for 4s."},
	# ----- Mountain -----
	"scythe_cut": {"name": "Scythe Cut", "slot": "basic", "pct": 100, "behind": 40,
		"desc": "Deal {atk:100} to your target and {atk:40} to the enemy behind it."},
	"rockhorn": {"name": "Rockhorn", "slot": "passive", "amount": 50,
		"desc": "Your attacks ignore half of the target's Defense."},
	"scythe_sweep": {"name": "Scythe Sweep", "slot": "ultimate", "pct": 140,
		"desc": "Deal {atk:140} to every enemy in your target's row."},
	"headbutt": {"name": "Headbutt", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"stubborn": {"name": "Stubborn", "slot": "passive", "amount": 20,
		"desc": "Below half health, gain 20 Defense."},
	"breakstone": {"name": "Breakstone", "slot": "ultimate", "pct": 190,
		"desc": "Deal {atk:190} to your target. It {k:pierce}."},
	# ----- Snow -----
	"frost_kick": {"name": "Frost Kick", "slot": "basic", "pct": 80, "amount": 20, "secs": 2.0,
		"desc": "Deal {atk:80} to your target and {k:slow} it by 20% for 2s."},
	"snow_runner": {"name": "Snow Runner", "slot": "passive", "amount": 25,
		"desc": "Your attack bar fills 25% faster while any enemy is {k:slow|slowed}."},
	"rally_bell": {"name": "Rally Bell", "slot": "ultimate", "amount": 30, "secs": 5.0,
		"desc": "Every ally gains {k:haste}: attacks 30% faster for 5s."},
	"frost_sting": {"name": "Frost Sting", "slot": "basic", "pct": 90, "amount": 20, "secs": 2.0,
		"desc": "Deal {atk:90} to your target and {k:slow} it by 20% for 2s."},
	"brittle": {"name": "Brittle", "slot": "passive", "amount": 25,
		"desc": "Deal 25% more damage to {k:slow|slowed} enemies."},
	"frost_burst": {"name": "Frost Burst", "slot": "ultimate", "pct": 120, "amount": 40, "secs": 4.0,
		"desc": "Deal {atk:120} to your target and enemies {k:adjacent} to it, and {k:slow} them by 40% for 4s."},
	# ----- Jungle -----
	"vine_whip": {"name": "Vine Whip", "slot": "basic", "pct": 85, "reach": true,
		"desc": "Deal {atk:85} to an enemy in the {k:back_row} if there is one, reaching over the front (unless a {k:taunt|taunt} pulls it)."},
	"canopy_stalker": {"name": "Canopy Stalker", "slot": "passive", "amount": 15,
		"desc": "Deal 15% more damage to enemies in the {k:back_row}."},
	"vine_lash": {"name": "Vine Lash", "slot": "ultimate", "pct": 130, "amount": 30, "secs": 3.0,
		"desc": "Deal {atk:130} to every enemy in the {k:back_row} and {k:slow} them by 30% for 3s."},
	"wing_bash": {"name": "Wing Bash", "slot": "basic", "pct": 100,
		"desc": "Deal {atk:100} to your target."},
	"glide": {"name": "Glide", "slot": "passive", "pct": 50,
		"desc": "Your basic attacks also hit the enemy behind your target for {atk:50}."},
	"wing_gust": {"name": "Wing Gust", "slot": "ultimate", "pct": 100,
		"desc": "Deal {atk:100} to every enemy in the {k:back_row}, or the front row if the back is empty, and {k:shield|Shield} yourself for {def:100}."},
}

## Habitat synergies (like a team bonus): with `need` or more creatures of a type on your
## side, those creatures gain the bonus. The second tier doubles it.
const SYNERGIES := {
	"Forest": {"name": "Deep Roots", "need": [2, 4], "desc": "Forest allies +%d Defense", "values": [12, 24]},
	"River": {"name": "Flowing", "need": [2, 4], "desc": "River heals and shields +%d%%", "values": [25, 50]},
	"Swamp": {"name": "Murk", "need": [2, 4], "desc": "Swamp poisons last +%d%% longer", "values": [50, 100]},
	"Mountain": {"name": "Bedrock", "need": [2, 4], "desc": "Mountain allies +%d%% Attack", "values": [15, 30]},
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
const RISK_SCALE := {1: 1.2, 2: 1.35, 3: 1.45}
## The guardian pack always fights at this strength.
const GUARDIAN_SCALE := 1.25


static func stats(id: String) -> Dictionary:
	return KITS[id]


static func move(id: String) -> Dictionary:
	return MOVES[id]


## [basic, passive, ultimate] move ids for a species.
static func kit_moves(id: String) -> Array[String]:
	var k: Dictionary = KITS[id]
	return [k["basic"], k["passive"], k["ultimate"]]


static func max_hp(id: String, scale := 1.0) -> float:
	return roundf(float(KITS[id]["hp"]) * HP_MULT * scale)


static var _num := RegEx.create_from_string("\\{(atk|def|maxhp):([0-9]+)\\}")

## A move's description in Rich markup, with numbers worked out from these stats.
static func describe(move_id: String, atk: float, def: float, hp_max: float) -> String:
	var d: String = MOVES[move_id]["desc"]
	var out := ""
	var at := 0
	for m in _num.search_all(d):
		out += d.substr(at, m.get_start() - at)
		at = m.get_end()
		var pct := int(m.get_string(2))
		match m.get_string(1):
			"atk":
				out += "%d%% {k:atk|Attack} (%d)" % [pct, roundi(atk * pct / 100.0)]
			"def":
				out += "%d%% {k:def|Defense} (%d)" % [pct, roundi(def * pct / 100.0)]
			"maxhp":
				out += "%d%% {k:hp|Max HP} (%d)" % [pct, roundi(hp_max * pct / 100.0)]
	out += d.substr(at)
	return out


## Glossary keyword ids a move's description mentions (for the keyword boxes).
static func keywords(move_id: String) -> Array[String]:
	var out: Array[String] = []
	var d: String = MOVES[move_id]["desc"]
	for m in RegEx.create_from_string("\\{k:([a-z_]+)").search_all(d):
		var k := m.get_string(1)
		if not out.has(k):
			out.append(k)
	return out


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

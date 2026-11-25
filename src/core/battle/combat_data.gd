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

## Habitat identities (the full guide for designing new creatures is docs/habitats.md).
## Each habitat owns a few keywords; a creature's kit should use at least one of its own
## habitat's and never the signature keyword of another habitat.
const HABITATS := {
	"Forest": {"theme": "Endurance", "owns": ["shield", "taunt", "thorns"],
		"line": "Outlasts: hits back with thorns, grows bark shields and draws attacks."},
	"River": {"theme": "Flow", "owns": ["heal", "cleanse", "drain", "wash"],
		"line": "Keeps things moving: heals, cleanses, drains life and washes away shields."},
	"Swamp": {"theme": "Rot", "owns": ["poison", "weaken"],
		"line": "Wears foes down: poison over time and rotted, weaker Defense."},
	"Mountain": {"theme": "Weight", "owns": ["pierce", "stagger", "execute"],
		"line": "Hits slow and hard: pierces Defense, staggers attacks and finishes the hurt."},
	"Snow": {"theme": "Cold and speed", "owns": ["slow", "haste", "brittle"],
		"line": "Fast and chilling: slows foes, speeds allies, quick double strikes."},
	"Jungle": {"theme": "Reach", "owns": ["reach", "dodge"],
		"line": "Strikes from anywhere: reaches the second row, hits behind and dodges."},
}
## Kits written here; the roster files add the rest (see Roster).
const BASE_KITS := {
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
	"thornfang": {"role": "Striker", "hp": 290, "atk": 28, "def": 16, "spd": 1.7,
		"basic": "thorn_bite", "passive": "thorn_pelt", "ultimate": "bramble_pounce"},
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

## Every kit: BASE_KITS plus the roster files.
static var KITS: Dictionary = Roster.merged("KITS", BASE_KITS)

## Move text uses Rich markup plus number tokens filled from the creature's stats:
##   {atk:120}   "120% Attack (54)"     {maxhp:15}  "15% Max HP (69)"
##   {def:100}   "100% Defense (45)"
## Behaviour lives in Battle (matched by id); the numbers here are what it reads.
const MOVES := {
	# ----- Forest -----
	"bramble_swipe": {"name": "Bramble Swipe", "slot": "basic", "pct": 70, "def_pct": 40,
		"short": "Hits for {atk:70} + {def:40}",
		"desc": "Deal {atk:70} plus {def:40} to your target."},
	"thorny_hide": {"name": "Thorny Hide", "slot": "passive", "pct": 35,
		"short": "Hit by a basic attack: hits back for {atk:35}",
		"desc": "When a basic attack hits you, deal {atk:35} back to the attacker."},
	"briar_wall": {"name": "Briar Wall", "slot": "ultimate", "def_pct": 100, "flat": 60, "secs": 4.0,
		"short": "Shield {def:100}+60 to self and adjacent, taunt 4s",
		"desc": "You and all {k:adjacent} allies gain {k:shield|Shield} equal to {def:100} plus 60. {k:taunt|Taunt} enemies for 4s."},
	"trunk_slam": {"name": "Trunk Slam", "slot": "basic", "pct": 100, "amount": 30,
		"short": "Hits for {atk:100}, +30% while shielded",
		"desc": "Deal {atk:100} to your target, 30% more while you have {k:shield|Shield}."},
	"bark_shell": {"name": "Bark Shell", "slot": "passive", "every": 3, "def_pct": 120,
		"short": "Every 3rd attack: shield self for {def:120}",
		"desc": "Every 3rd basic attack also gives you {k:shield|Shield} equal to {def:120}."},
	"shell_quake": {"name": "Shell Quake", "slot": "ultimate", "pct": 180, "splash": 60,
		"short": "Hits for {atk:180}, {atk:60} to adjacent foes",
		"desc": "Deal {atk:180} to your target and {atk:60} to enemies {k:adjacent} to it."},
	"antler_gore": {"name": "Antler Gore", "slot": "basic", "pct": 100, "splash": 40,
		"short": "Hits for {atk:100}, {atk:40} to adjacent foes",
		"desc": "Deal {atk:100} to your target and {atk:40} to enemies {k:adjacent} to it."},
	"ancient_bark": {"name": "Ancient Bark", "slot": "passive", "every": 3, "def_pct": 50,
		"short": "Every 3rd attack: shield whole pack for {def:50}",
		"desc": "Every 3rd basic attack gives your whole pack {k:shield|Shield} equal to {def:50}."},
	"antler_storm": {"name": "Antler Storm", "slot": "ultimate", "pct": 90, "flat": 80,
		"short": "{atk:90} to every foe, shield pack for 80",
		"desc": "Deal {atk:90} to every enemy, then {k:shield|Shield} your whole pack for 80."},
	"thorn_bite": {"name": "Thorn Bite", "slot": "basic", "pct": 90, "shield_pct": 30,
		"short": "Hits for {atk:90}, shields self for {atk:30}",
		"desc": "Deal {atk:90} to your target and gain {k:shield|Shield} equal to {atk:30}."},
	"thorn_pelt": {"name": "Thorn Pelt", "slot": "passive", "pct": 40,
		"short": "While shielded: hits back for {atk:40}",
		"desc": "While you have {k:shield|Shield}, a basic attack that hits you deals {atk:40} back to the attacker."},
	"bramble_pounce": {"name": "Bramble Pounce", "slot": "ultimate", "pct": 170, "amount": 50,
		"short": "Hits for {atk:170}, shields half the damage",
		"desc": "Deal {atk:170} to your target and gain {k:shield|Shield} equal to half the damage dealt."},
	# ----- River -----
	"mending_spray": {"name": "Mending Spray", "slot": "basic", "pct": 70, "heal_pct": 60,
		"short": "Hits for {atk:70}, heals most hurt ally {atk:60}",
		"desc": "Deal {atk:70} to your target and heal the most hurt ally for {atk:60}."},
	"clear_water": {"name": "Clear Water", "slot": "passive",
		"short": "Heals also wash off poison and weaken",
		"desc": "Your heals also wash {k:poison} off the ally."},
	"tidewash": {"name": "Tidewash", "slot": "ultimate", "maxhp_pct": 15,
		"short": "Heals every ally 15% of max HP",
		"desc": "Heal every ally for 15% of their Max HP."},
	"ink_jet": {"name": "Ink Jet", "slot": "basic", "pct": 90, "wash": 60,
		"short": "Strips {atk:60} shield, then hits for {atk:90}",
		"desc": "{k:wash|Wash away} up to {atk:60} of the target's {k:shield|Shield}, then deal {atk:90}."},
	"undertow": {"name": "Undertow", "slot": "passive", "pct": 25,
		"short": "Heals self for 25% of damage dealt",
		"desc": "Heal yourself for 25% of the damage you deal."},
	"dive": {"name": "Dive", "slot": "ultimate", "pct": 220,
		"short": "{atk:220} to the weakest foe anywhere",
		"desc": "Dive past the {k:front_row} and deal {atk:220} to the weakest enemy anywhere."},
	# ----- Swamp -----
	"bog_spit": {"name": "Bog Spit", "slot": "basic", "pct": 70, "dot": 15, "secs": 4.0,
		"short": "Hits for {atk:70}, poison {atk:15}/s for 4s",
		"desc": "Deal {atk:70} to your target and {k:poison} it for {atk:15} a second for 4s."},
	"rot_light": {"name": "Rot Light", "slot": "passive", "amount": 20,
		"short": "Poisoned foes lose 20% Defense",
		"desc": "Enemies you {k:poison} are also {k:weaken|weakened}: 20% less Defense."},
	"miasma": {"name": "Miasma", "slot": "ultimate", "dot": 25, "secs": 5.0,
		"short": "Poisons every foe for {atk:25}/s for 5s",
		"desc": "{k:poison|Poison} every enemy for {atk:25} a second for 5s."},
	"mud_horn": {"name": "Mud Horn", "slot": "basic", "pct": 100, "amount": 15, "secs": 3.0,
		"short": "Hits for {atk:100}, -15% Defense for 3s",
		"desc": "Deal {atk:100} to your target and {k:weaken} it: 15% less Defense for 3s."},
	"mudwallow": {"name": "Mudwallow", "slot": "passive", "amount": 25,
		"short": "+25% damage vs poisoned or weakened",
		"desc": "Deal 25% more damage to {k:poison|poisoned} or {k:weaken|weakened} enemies."},
	"bog_charge": {"name": "Bog Charge", "slot": "ultimate", "pct": 180, "dot": 30, "secs": 4.0,
		"short": "Hits for {atk:180}, poison {atk:30}/s for 4s",
		"desc": "Deal {atk:180} to your target and {k:poison} it for {atk:30} a second for 4s."},
	# ----- Mountain -----
	"scythe_cut": {"name": "Scythe Cut", "slot": "basic", "pct": 100, "amount": 50,
		"short": "Hits for {atk:100}, +50% below half health",
		"desc": "Deal {atk:100} to your target. {k:execute|Finisher}: 50% more against enemies below half health."},
	"rockhorn": {"name": "Rockhorn", "slot": "passive", "amount": 50,
		"short": "Attacks ignore half of Defense",
		"desc": "Your attacks ignore half of the target's Defense."},
	"scythe_sweep": {"name": "Scythe Sweep", "slot": "ultimate", "pct": 140,
		"short": "{atk:140} to the target's whole row",
		"desc": "Deal {atk:140} to every enemy in your target's row."},
	"headbutt": {"name": "Headbutt", "slot": "basic", "pct": 90, "amount": 30,
		"short": "Hits for {atk:90}, knocks attack bar back 30%",
		"desc": "Deal {atk:90} to your target and {k:stagger} it: its attack bar drops by 30%."},
	"stubborn": {"name": "Stubborn", "slot": "passive", "amount": 20,
		"short": "Below half health: +20 Defense",
		"desc": "Below half health, gain 20 Defense."},
	"breakstone": {"name": "Breakstone", "slot": "ultimate", "pct": 190,
		"short": "{atk:190} that ignores Defense",
		"desc": "Deal {atk:190} to your target. It {k:pierce}."},
	# ----- Snow -----
	"frost_kick": {"name": "Frost Kick", "slot": "basic", "pct": 80, "amount": 20, "secs": 2.0,
		"short": "Hits for {atk:80}, slows 20% for 2s",
		"desc": "Deal {atk:80} to your target and {k:slow} it by 20% for 2s."},
	"snow_runner": {"name": "Snow Runner", "slot": "passive", "amount": 25,
		"short": "+25% attack speed while a foe is slowed",
		"desc": "Your attack bar fills 25% faster while any enemy is {k:slow|slowed}."},
	"rally_bell": {"name": "Rally Bell", "slot": "ultimate", "amount": 30, "secs": 5.0,
		"short": "All allies attack 30% faster for 5s",
		"desc": "Every ally gains {k:haste}: attacks 30% faster for 5s."},
	"frost_sting": {"name": "Frost Sting", "slot": "basic", "pct": 50, "amount": 20, "secs": 2.0,
		"short": "2 hits of {atk:50}, the first slows 20%",
		"desc": "Sting twice for {atk:50} each. The first sting {k:slow|slows} the target by 20% for 2s."},
	"brittle": {"name": "Brittle", "slot": "passive", "amount": 25,
		"short": "+25% damage vs slowed foes",
		"desc": "Deal 25% more damage to {k:slow|slowed} enemies."},
	"frost_burst": {"name": "Frost Burst", "slot": "ultimate", "pct": 120, "amount": 40, "secs": 4.0,
		"short": "{atk:120} and 40% slow to target + adjacent",
		"desc": "Deal {atk:120} to your target and enemies {k:adjacent} to it, and {k:slow} them by 40% for 4s."},
	# ----- Jungle -----
	"vine_whip": {"name": "Vine Whip", "slot": "basic", "pct": 85, "reach": true,
		"short": "Hits the second row for {atk:85}",
		"desc": "Deal {atk:85} to an enemy in the {k:back_row} if there is one, reaching over the front (unless a {k:taunt|taunt} pulls it)."},
	"canopy_stalker": {"name": "Canopy Stalker", "slot": "passive", "amount": 15,
		"short": "+15% damage vs the second row",
		"desc": "Deal 15% more damage to enemies in the {k:back_row}."},
	"vine_lash": {"name": "Vine Lash", "slot": "ultimate", "pct": 145,
		"short": "{atk:145} to every foe in the second row",
		"desc": "Deal {atk:145} to every enemy in the {k:back_row}, reaching over the front."},
	"wing_bash": {"name": "Wing Bash", "slot": "basic", "pct": 90,
		"short": "Hits for {atk:90}, dodges the next basic attack",
		"desc": "Deal {atk:90} to your target, then get ready to {k:dodge} the next basic attack aimed at you."},
	"glide": {"name": "Glide", "slot": "passive", "pct": 50,
		"short": "Also hits behind the target for {atk:50}",
		"desc": "Your basic attacks also hit the enemy behind your target for {atk:50}."},
	"wing_gust": {"name": "Wing Gust", "slot": "ultimate", "pct": 100,
		"short": "{atk:100} to the second row, then dodges",
		"desc": "Deal {atk:100} to every enemy in the {k:back_row}, or the front row if the back is empty, then get ready to {k:dodge} the next basic attack."},
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
	# ----- Packs with the species added with varied crossings. min_crossing: first crossing
	# they can turn up on. weight: how often (default 3). -----
	{"id": "mole_diggers", "title": "Mossmole diggers", "terrains": ["Forest", "Hills"], "min_risk": 1, "min_crossing": 1,
		"text": "The road heaves. Mossmoles pop up all around the wagon.",
		"front": ["mossmole", "mossmole", "thornfang"], "back": ["", "vinegecko", ""]},
	{"id": "otter_raft", "title": "An otter raft", "terrains": ["River"], "min_risk": 1, "min_crossing": 1,
		"text": "Pebblotters float by in a chattering raft, and they don't like wagons.",
		"front": ["gillhorn", "", "gillhorn"], "back": ["pebblotter", "inkhoot", "pebblotter"]},
	{"id": "spore_chorus", "title": "Spore chorus", "terrains": ["Swamp"], "min_risk": 1, "min_crossing": 1,
		"text": "A deep croaking chorus, then a cloud of spores rolls over the reeds.",
		"front": ["plateflit", "sporetoad", "plateflit"], "back": ["sporetoad", "", "sporetoad"]},
	{"id": "slate_flock", "title": "Slatebeak flock", "terrains": ["Mountain", "Hills"], "min_risk": 1, "min_crossing": 1,
		"text": "Stone-grey birds circle low over the wagon, then dive.",
		"front": ["cairnram", "", ""], "back": ["slatebeak", "slatebeak", "slatebeak"]},
	{"id": "pup_pack", "title": "Flurrypup pack", "terrains": ["Mountain", "Hills", "Forest"], "min_risk": 1, "min_crossing": 1,
		"text": "Yips on the wind. A pack of flurrypups races up, tails crackling with frost.",
		"front": ["flurrypup", "frostsnip", "flurrypup"], "back": ["", "flurrypup", ""]},
	{"id": "burl_den", "title": "A burlbear's den", "terrains": ["Forest"], "min_risk": 2, "min_crossing": 1, "weight": 2,
		"text": "The wagon rolls too close to a burlbear den. Mother is home.",
		"front": ["mossmole", "burlbear", "mossmole"], "back": ["", "thornfang", ""]},
	{"id": "lantern_shoal", "title": "Lantern shoal", "terrains": ["River", "Swamp"], "min_risk": 2, "min_crossing": 1, "weight": 2,
		"text": "Lights glide under the water, then rise up glowing and stinging.",
		"front": ["gillhorn", "", "pebblotter"], "back": ["lanternray", "", "lanternray"]},
	{"id": "bogjaw_lair", "title": "Bogjaw lair", "terrains": ["Swamp", "River"], "min_risk": 2, "min_crossing": 2,
		"text": "Two eyes rise from the black water, then two more.",
		"front": ["bogjaw", "", "bogjaw"], "back": ["sporetoad", "mirelamp", ""]},
	{"id": "quarry_herd", "title": "Quarry herd", "terrains": ["Mountain"], "min_risk": 2, "min_crossing": 2,
		"text": "Quarrytusks grind down the slope, drill tusks spinning.",
		"front": ["quarrytusk", "cairnram", "quarrytusk"], "back": ["", "slatebeak", ""]},
	{"id": "rime_flight", "title": "Rimewing flight", "terrains": ["Mountain", "Hills"], "min_risk": 2, "min_crossing": 2,
		"text": "Frost falls from a clear sky. Rimewings are hunting.",
		"front": ["flurrypup", "", "flurrypup"], "back": ["rimewing", "frostsnip", "rimewing"]},
	{"id": "canopy_hunters", "title": "Canopy hunters", "terrains": ["Forest", "River"], "min_risk": 2, "min_crossing": 2,
		"text": "Something spotted moves through the leaves above, keeping pace with the wagon.",
		"front": ["plateflit", "canopard", ""], "back": ["vinegecko", "", "vinegecko"]},
	# ----- Batch 2 packs -----
	{"id": "acorn_raid", "title": "Acorn raid", "terrains": ["Forest", "Hills"], "min_risk": 1, "min_crossing": 1,
		"text": "Acorns rain down on the wagon. Acornets are raiding the food sacks.",
		"front": ["acornet", "mossmole", "acornet"], "back": ["", "acornet", ""]},
	{"id": "wisp_school", "title": "Wisp school", "terrains": ["River"], "min_risk": 1, "min_crossing": 1,
		"text": "Glowing minnows leap from the river and swirl around a snapping kelpoise.",
		"front": ["", "kelpoise", ""], "back": ["minnowisp", "inkhoot", "minnowisp"]},
	{"id": "moth_cloud", "title": "Moth cloud", "terrains": ["Swamp", "Forest"], "min_risk": 1, "min_crossing": 1,
		"text": "A whirling cloud of murkmoths drifts out of the dusk.",
		"front": ["gillhorn", "", ""], "back": ["murkmoth", "murkmoth", "murkmoth"]},
	{"id": "goat_trail", "title": "Goat trail", "terrains": ["Mountain", "Hills"], "min_risk": 1, "min_crossing": 1,
		"text": "Cragkids leap from ledge to ledge, butting anything in their way.",
		"front": ["cragkid", "cragkid", "cragkid"], "back": ["", "slatebeak", ""]},
	{"id": "sleet_scurry", "title": "Sleet scurry", "terrains": ["Mountain", "Hills"], "min_risk": 1, "min_crossing": 1,
		"text": "Tiny frosty mice swarm over the wheels, nibbling everything.",
		"front": ["sleetmouse", "flurrypup", "sleetmouse"], "back": ["sleetmouse", "", ""]},
	{"id": "keet_flock", "title": "Keet flock", "terrains": ["Forest", "River"], "min_risk": 1, "min_crossing": 1,
		"text": "A screeching flock of vinekeets dives at the wagon's canopy.",
		"front": ["vinegecko", "", "vinegecko"], "back": ["vinekeet", "vinekeet", "vinekeet"]},
	{"id": "beetle_bank", "title": "Beetle bank", "terrains": ["Forest"], "min_risk": 2, "min_crossing": 1, "weight": 2,
		"text": "The bank is crawling with barkbeetles, and their horns are down.",
		"front": ["barkbeetle", "", "barkbeetle"], "back": ["acornet", "", "acornet"]},
	{"id": "leech_pool", "title": "Leech pool", "terrains": ["Swamp", "River"], "min_risk": 2, "min_crossing": 1, "weight": 2,
		"text": "The ford is black and still. Then it starts to ripple.",
		"front": ["bogjaw", "", ""], "back": ["gloomleech", "murkmoth", "gloomleech"]},
	{"id": "lava_flats", "title": "Lava flats", "terrains": ["Mountain"], "min_risk": 2, "min_crossing": 2,
		"text": "Basaltortles bask on the warm rock and they don't want to move.",
		"front": ["basaltortle", "cragkid", "basaltortle"], "back": ["", "slatebeak", ""]},
	{"id": "white_pride", "title": "White pride", "terrains": ["Mountain", "Hills"], "min_risk": 2, "min_crossing": 2,
		"text": "A frostmane pride pads out of the snow, steam curling from their jaws.",
		"front": ["frostmane", "", "flurrypup"], "back": ["sleetmouse", "rimewing", ""]},
	{"id": "salamander_ambush", "title": "Salamander ambush", "terrains": ["Forest", "River", "Swamp"], "min_risk": 2, "min_crossing": 2,
		"text": "Bright stripes flash in the undergrowth, then tongues lash out.",
		"front": ["plateflit", "", ""], "back": ["prowlmander", "vinekeet", "prowlmander"]},
	{"id": "mirehydra_den", "title": "Many heads", "terrains": ["Swamp", "River"], "min_risk": 2, "min_crossing": 2, "weight": 1,
		"text": "Three heads rise from the mire on three long necks, all of them hungry: Mirehydra.",
		"front": ["bogjaw", "mirehydra", "sporetoad"], "back": ["murkmoth", "", "gloomleech"]},
	{"id": "titanox_pass", "title": "The titan in the pass", "terrains": ["Mountain", "Hills"], "min_risk": 2, "min_crossing": 2, "weight": 1,
		"text": "The ground shakes. An ox the size of a house blocks the pass, a furnace roaring on its back: Titanox.",
		"front": ["cragkid", "titanox", "cragkid"], "back": ["", "slatebeak", ""]},
	{"id": "quetzalith_sky", "title": "Feathers in the sun", "terrains": ["Forest", "River"], "min_risk": 2, "min_crossing": 2, "weight": 1,
		"text": "A rainbow-plumed serpent coils down from the canopy, crest blazing like the sun: Quetzalith.",
		"front": ["prowlmander", "canopard", ""], "back": ["vinekeet", "quetzalith", "vinekeet"]},
	# Legendaries: rare, from crossing 2 on, and fierce.
	{"id": "emberoak_grove", "title": "A walking grove", "terrains": ["Forest", "Hills"], "min_risk": 2, "min_crossing": 2, "weight": 1,
		"text": "The trees ahead are moving. At their heart walks an ancient oak with a furnace glowing in its chest: Emberoak.",
		"front": ["mossmole", "emberoak", "mossmole"], "back": ["", "thornfang", ""]},
	{"id": "tidewyrm_rise", "title": "The tide rises", "terrains": ["River", "Swamp"], "min_risk": 2, "min_crossing": 2, "weight": 1,
		"text": "The river swells for no reason, and a long shining serpent lifts out of it: Tidewyrm.",
		"front": ["gillhorn", "tidewyrm", "gillhorn"], "back": ["", "lanternray", ""]},
	{"id": "auroryx_lights", "title": "Lights in the sky", "terrains": ["Mountain", "Hills"], "min_risk": 2, "min_crossing": 2, "weight": 1,
		"text": "Green light ripples across the sky. Beneath it, an oryx with an aurora for a mane: Auroryx.",
		"front": ["flurrypup", "auroryx", ""], "back": ["rimewing", "", "frostsnip"]},
]

## The guardian that waits on the last stretch to Westwatch.
const GUARDIAN := {"id": "hollow_stag", "title": "The Hollow Stag", "terrains": [], "min_risk": 1, "boss": "hollowstag",
	"text": "The trail goes silent. A huge stag with hollow, glowing antlers steps out ahead, its pack fanning out around it.",
	"front": ["thornfang", "cairnram", "thornfang"], "back": ["lianetail", "frostsnip", "lianetail"]}

## Each crossing has its own guardian; after the last one they come round again, stronger.
const GUARDIANS := [
	GUARDIAN,
	{"id": "bog_mother", "title": "The Bog Mother", "terrains": [], "min_risk": 1, "boss": "bogmother",
		"text": "The marsh goes still. A toad the size of a cottage heaves out of the mire, her brood swarming around her.",
		"front": ["bogjaw", "sporetoad", "bogjaw"], "back": ["sporetoad", "mirelamp", "lanternray"]},
	{"id": "cogmammoth", "title": "The Cogmammoth", "terrains": [], "min_risk": 1, "boss": "cogmammoth",
		"text": "Gears grind like thunder. A mammoth of moss and brass blocks the pass, its herd lowering their tusks.",
		"front": ["quarrytusk", "", "quarrytusk"], "back": ["slatebeak", "", "slatebeak"]},
	{"id": "rimewyrm", "title": "The Rimewyrm", "terrains": [], "min_risk": 1, "boss": "rimewyrm",
		"text": "Snow begins to fall upward. A great wyrm of ice uncoils across the road, and the cold bites to the bone.",
		"front": ["flurrypup", "rimehare", "flurrypup"], "back": ["", "rimewing", ""]},
]

## Enemy strength by segment risk (health and power multiplier).
const RISK_SCALE := {1: 1.2, 2: 1.35, 3: 1.45}
## The guardian pack always fights at this strength.
const GUARDIAN_SCALE := 1.25


static func stats(id: String) -> Dictionary:
	return KITS[id]


static func move(id: String) -> Dictionary:
	return MOVES[id] if MOVES.has(id) else MovePool.MOVES.get(id, {})


static func has_move(id: String) -> bool:
	return MOVES.has(id) or MovePool.has(id)


## A move's full text (learnable moves write theirs from their data).
static func move_desc(id: String) -> String:
	return MOVES[id]["desc"] if MOVES.has(id) else MovePool.desc(id)


static func move_short(id: String) -> String:
	return MOVES[id].get("short", "") if MOVES.has(id) else MovePool.short(id)


## [basic, passive, ultimate] move ids for a species.
static func kit_moves(id: String) -> Array[String]:
	var k: Dictionary = KITS[id]
	return [k["basic"], k["passive"], k["ultimate"]]


static func max_hp(id: String, scale := 1.0) -> float:
	return roundf(float(KITS[id]["hp"]) * HP_MULT * scale)


static var _num := RegEx.create_from_string("\\{(atk|def|maxhp):([0-9]+)\\}")

## A move's description in Rich markup, with numbers worked out from these stats.
static func describe(move_id: String, atk: float, def: float, hp_max: float) -> String:
	var d := move_desc(move_id)
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


## A move's one-line summary with plain numbers worked out from these stats
## ({atk:70} becomes "18"), for compact lists like the Companions screen.
static func describe_short(move_id: String, atk: float, def: float, hp_max: float) -> String:
	var d := move_short(move_id)
	var out := ""
	var at := 0
	for m in _num.search_all(d):
		out += d.substr(at, m.get_start() - at)
		at = m.get_end()
		var base := atk
		match m.get_string(1):
			"def": base = def
			"maxhp": base = hp_max
		out += str(roundi(base * int(m.get_string(2)) / 100.0))
	out += d.substr(at)
	return out


## Glossary keyword ids a move's description mentions (for the keyword boxes).
static func keywords(move_id: String) -> Array[String]:
	var out: Array[String] = []
	var d := move_desc(move_id)
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


static func packs_for(seg: Dictionary, crossing_no := 1) -> Array:
	var out: Array = []
	for p in PACKS:
		var terrains: Array = p["terrains"]
		if int(seg.get("risk", 1)) >= int(p["min_risk"]) and crossing_no >= int(p.get("min_crossing", 1)) \
				and (terrains.is_empty() or terrains.has(seg.get("terrain", ""))):
			out.append(p)
	var table := Encounters.table_entry(String(seg.get("terrain", "")), crossing_no)
	if not table.is_empty():
		out.append(table)
	return out


## Pick a pack, using each pack's weight (rare and legendary packs turn up less often).
static func pick_pack(packs: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for p in packs:
		total += int(p.get("weight", 3))
	var roll := rng.randi_range(1, maxi(1, total))
	for p in packs:
		roll -= int(p.get("weight", 3))
		if roll <= 0:
			return p
	return packs[-1]


## The guardian for a crossing: the Hollow Stag first, then a new one each crossing.
static func guardian_for(crossing_no: int) -> Dictionary:
	return GUARDIANS[(maxi(1, crossing_no) - 1) % GUARDIANS.size()]


static func pack_by_id(id: String) -> Dictionary:
	for g in GUARDIANS:
		if g["id"] == id:
			return g
	for p in PACKS:
		if p["id"] == id:
			return p
	return {}

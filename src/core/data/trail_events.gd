class_name TrailEvents
extends RefCounted
## Trail events: a decision card on the road. Each has choices; a choice with a "cap" (trail job)
## rolls a three-outcome check (CheckOdds) helped by the best Trailomon with that job, which earns
## job XP unless it fails. Exactly one choice per event has no roll: the safe option, with a
## visible cost. A choice's "cost" is paid up front whatever happens and must be affordable.
##
## kind (icon on the card): wildlife, travelers, hazard, find, shrine.
## Effects use the TrailEffects delta convention (food: -10 means lose 10, coins: +8 means gain 8).
## Keys: food, water, health, wear, integrity, days, fatigue, lose_cargo, coins, repair_kits,
## light_dust, dark_dust, item ("random" or an id), technique (count), xp (helper), recruit
## ("wild" = a wild Trailomon of this road's habitat offers to join), fever (days), cure,
## progress (trip days), heal_team (share of max HP), battle (pack id; the fight comes next),
## bounty (coins on winning that fight).

## A creature's job rank (1-3, +1 on home ground or favoured weather) counts this much toward the check.
const RANK_SCORE := 3
## Chance per travel day that an event happens, plus this much per risk level.
const BASE_CHANCE := 0.16
const RISK_CHANCE := 0.06
## At most this many events per trip.
const PER_TRIP := 2
## Job XP for the helper: success and mixed.
const JOB_XP := {"success": 12, "mixed": 6, "failure": 0}

const KIND_ICON := {"wildlife": "ev_wildlife", "travelers": "ev_travelers", "hazard": "ev_hazard", "find": "ev_find", "shrine": "ev_shrine"}

## Fights that events can start (not wild packs from CombatData).
const PACKS := {
	"toll_beasts": {"id": "toll_beasts", "title": "Toll-road beasts", "terrains": [], "min_risk": 1,
		"text": "The toll keepers whistle. Their trained beasts step onto the road.",
		"front": ["thornfang", "cairnram", "thornfang"], "back": ["", "lianetail", ""]},
	"trainer_spar": {"id": "trainer_spar", "title": "A friendly spar", "terrains": [], "min_risk": 1,
		"text": "The trainer grins and sends out her team.",
		"front": ["plateflit", "", "thornfang"], "back": ["frostsnip", "", "inkhoot"]},
}

const EVENTS := [
	# ----- hazards -----
	{"id": "fallen_tree", "kind": "hazard", "title": "A fallen trunk", "terrains": ["Forest", "Hills"], "min_risk": 1,
		"text": "A huge trunk blocks the trail.",
		"choices": [
			{"label": "Chop through", "cap": "clear", "difficulty": 6,
				"success": {"text": "Cleared in no time."},
				"mixed": {"text": "A branch scrapes the wagon.", "wear": 8},
				"failure": {"text": "It takes all day.", "days": 1, "wear": 12}},
			{"label": "Haul it aside", "cap": "strength", "difficulty": 7,
				"success": {"text": "It rolls into the ferns."},
				"mixed": {"text": "The haulers are worn out.", "fatigue": 15},
				"failure": {"text": "Hours of straining, then a detour.", "days": 1, "fatigue": 25}},
			{"label": "Go around",
				"success": {"text": "A long detour.", "days": 1}},
		]},
	{"id": "swollen_ford", "kind": "hazard", "title": "River crossing", "terrains": ["River"], "min_risk": 1,
		"text": "Last night's rain turned the ford into a fast brown river.",
		"choices": [
			{"label": "Float it across", "cap": "float", "difficulty": 6,
				"success": {"text": "Guided across."},
				"mixed": {"text": "Some food got soaked.", "food": -10},
				"failure": {"text": "The current tips the wagon.", "lose_cargo": 1, "wear": 10}},
			{"label": "Ford it", "cap": "strength", "difficulty": 8,
				"success": {"text": "The haulers plough through."},
				"mixed": {"text": "Across, soaked and tired.", "fatigue": 15, "water": 4},
				"failure": {"text": "Stuck midstream. Cargo washes off.", "lose_cargo": 1, "fatigue": 20}},
			{"label": "Take the ferry", "cost": {"coins": -10}, "safe_paid": true,
				"success": {"text": "The ferryman poles you across."}},
			{"label": "Wait for it to drop",
				"success": {"text": "By morning it's calm.", "days": 1}},
		]},
	{"id": "sinking_bog", "kind": "hazard", "title": "Sinking wheels", "terrains": ["Swamp"], "min_risk": 1,
		"text": "The wheels sink into black mud up to the axles.",
		"choices": [
			{"label": "Pull it free", "cap": "strength", "difficulty": 7,
				"success": {"text": "One great heave."},
				"mixed": {"text": "Free, but spent.", "fatigue": 20},
				"failure": {"text": "Something cracks.", "integrity": -10, "wear": 15}},
			{"label": "Light a firm path", "cap": "light", "difficulty": 6,
				"success": {"text": "Glowing lamps show firm ground."},
				"mixed": {"text": "Mostly firm ground.", "wear": 8},
				"failure": {"text": "The light fades. Lost a day.", "days": 1}},
			{"label": "Unload and reload",
				"success": {"text": "Slow, muddy work.", "days": 1, "fatigue": 10}},
		]},
	{"id": "rockslide", "kind": "hazard", "title": "Loose rocks", "terrains": ["Mountain", "Hills"], "min_risk": 2,
		"text": "Pebbles trickle down. The slope looks ready to go.",
		"choices": [
			{"label": "Scout a safe line", "cap": "scout", "difficulty": 7,
				"success": {"text": "A safe way through."},
				"mixed": {"text": "Stones bounce off the canopy.", "wear": 10},
				"failure": {"text": "Rocks rain down.", "integrity": -15, "health": -15}},
			{"label": "Steady the wagon", "cap": "steady", "difficulty": 6,
				"success": {"text": "Not a wobble."},
				"mixed": {"text": "A wheel scrapes the rocks.", "wear": 10},
				"failure": {"text": "The wagon slams a boulder.", "integrity": -15}},
			{"label": "Wait it out",
				"success": {"text": "The slope lets go overnight.", "days": 1}},
		]},
	{"id": "bitter_night", "kind": "hazard", "title": "A bitter night", "terrains": [], "min_risk": 1,
		"text": "The temperature drops hard. Your traveller is shivering.",
		"choices": [
			{"label": "Huddle up", "cap": "cold", "difficulty": 5,
				"success": {"text": "Warm fur, good sleep."},
				"mixed": {"text": "A long, cold night.", "health": -8},
				"failure": {"text": "A fever sets in.", "health": -10, "fever": 3}},
			{"label": "Herbal brew", "cap": "heal", "difficulty": 5,
				"success": {"text": "Warm and well."},
				"mixed": {"text": "It helps a little.", "health": -8},
				"failure": {"text": "A fever sets in.", "health": -10, "fever": 3}},
			{"label": "Burn supplies",
				"success": {"text": "A roaring fire, at a cost.", "food": -6}},
		]},
	{"id": "storm_shelter", "kind": "hazard", "title": "Storm on the road", "terrains": [], "weather": ["storm"], "min_risk": 1,
		"text": "Thunder rolls in. The canopy strains in the wind.",
		"choices": [
			{"label": "Push through", "cap": "steady", "difficulty": 7,
				"success": {"text": "Through the worst of it."},
				"mixed": {"text": "The canopy tears.", "wear": 12},
				"failure": {"text": "The wagon tips in a gust.", "integrity": -12, "health": -8}},
			{"label": "Make camp", "success": {"text": "You wait it out.", "days": 1, "fatigue": -10}},
		]},
	{"id": "stampede", "kind": "wildlife", "title": "Stampede!", "terrains": ["Hills", "Mountain"], "min_risk": 2,
		"text": "A herd of cairnrams thunders down the slope toward the road.",
		"choices": [
			{"label": "Stand firm", "cap": "guard", "difficulty": 7,
				"success": {"text": "The herd splits around you."},
				"mixed": {"text": "Haulers are rattled.", "fatigue": 15},
				"failure": {"text": "The herd clips the wagon.", "integrity": -10, "wear": 10}},
			{"label": "Outrun them", "cap": "strength", "difficulty": 8,
				"success": {"text": "The haulers bolt clear."},
				"mixed": {"text": "Clear, and exhausted.", "fatigue": 25},
				"failure": {"text": "Cargo bounces off.", "lose_cargo": 1, "fatigue": 20}},
			{"label": "Pull off the road", "success": {"text": "Hours spent hiding.", "days": 1}},
		]},
	{"id": "lost_in_fog", "kind": "hazard", "title": "Thick fog", "terrains": [], "weather": ["fog"], "min_risk": 1,
		"text": "You can't see the haulers' tails. The trail is gone.",
		"choices": [
			{"label": "Scout ahead", "cap": "scout", "difficulty": 6,
				"success": {"text": "Back on the trail.", "progress": 0.3},
				"mixed": {"text": "Found it, eventually.", "progress": -0.3},
				"failure": {"text": "Lost for a day.", "days": 1}},
			{"label": "Light the way", "cap": "light", "difficulty": 6,
				"success": {"text": "Lanterns cut the fog."},
				"mixed": {"text": "Slow going.", "progress": -0.3},
				"failure": {"text": "Lost for a day.", "days": 1}},
			{"label": "Wait for it to lift", "success": {"text": "It burns off by noon.", "progress": -0.5}},
		]},
	{"id": "bad_water", "kind": "hazard", "title": "Bad water", "terrains": ["Swamp", "River"], "min_risk": 1,
		"text": "The water barrels smell wrong.",
		"choices": [
			{"label": "Purify it", "cap": "heal", "difficulty": 6,
				"success": {"text": "Clean and clear."},
				"mixed": {"text": "Half was saved.", "water": -6},
				"failure": {"text": "Your traveller drank it anyway.", "water": -8, "fever": 3}},
			{"label": "Dump it", "success": {"text": "Every drop poured out.", "water": -12}},
		]},
	# ----- wildlife -----
	{"id": "trapped_wild", "kind": "wildlife", "title": "Caught in a snare", "terrains": [], "min_risk": 1,
		"text": "A wild Trailomon is tangled in an old snare, crying out.",
		"choices": [
			{"label": "Cut it free", "cap": "clear", "difficulty": 5,
				"success": {"text": "It sniffs your hand and stays.", "recruit": "wild"},
				"mixed": {"text": "Free, it bolts off.", "health": -5},
				"failure": {"text": "It bites and flees.", "health": -10}},
			{"label": "Tend its leg", "cap": "heal", "difficulty": 6,
				"success": {"text": "It limps after the wagon.", "recruit": "wild"},
				"mixed": {"text": "It thanks you and goes.", "light_dust": 1},
				"failure": {"text": "It panics and runs.", "health": -5}},
			{"label": "Leave it", "success": {"text": "Its cries fade behind you."}},
		]},
	{"id": "orphan", "kind": "wildlife", "title": "A lost little one", "terrains": [], "min_risk": 1,
		"text": "A young wild Trailomon trots after the wagon, all alone.",
		"choices": [
			{"label": "Feed it", "cost": {"food": -5}, "safe_paid": true,
				"success": {"text": "It curls up in the wagon.", "recruit": "wild"}},
			{"label": "Find its family", "cap": "scout", "difficulty": 6,
				"success": {"text": "A happy reunion. They leave a gift.", "light_dust": 1, "food": 4},
				"mixed": {"text": "No luck. It trots away.", "fatigue": 5},
				"failure": {"text": "A day lost searching.", "days": 1}},
			{"label": "Shoo it away", "success": {"text": "It watches you go."}},
		]},
	{"id": "herd_grazing", "kind": "wildlife", "title": "Grazing herd", "terrains": ["Hills", "Forest", "Mountain"], "min_risk": 1,
		"text": "A herd grazes in a meadow beside the road.",
		"choices": [
			{"label": "Forage the meadow", "cap": "forage", "difficulty": 5,
				"success": {"text": "Roots and berries galore.", "food": 12},
				"mixed": {"text": "A modest haul.", "food": 6},
				"failure": {"text": "The herd chases you off.", "health": -6}},
			{"label": "Train on the slope", "cap": "strength", "difficulty": 6,
				"success": {"text": "Your team races the herd.", "xp": 20},
				"mixed": {"text": "Good exercise.", "xp": 8, "fatigue": 10},
				"failure": {"text": "A hauler pulls a muscle.", "fatigue": 25}},
			{"label": "Watch and rest", "success": {"text": "A peaceful hour.", "fatigue": -8}},
		]},
	{"id": "bee_tree", "kind": "find", "title": "Honey tree", "terrains": ["Forest", "Swamp"], "min_risk": 1,
		"text": "A hollow tree hums with bees and drips with honey.",
		"choices": [
			{"label": "Smoke them out", "cap": "light", "difficulty": 6,
				"success": {"text": "Sticky, sweet success.", "food": 10},
				"mixed": {"text": "A little honey, a lot of stings.", "food": 4, "health": -6},
				"failure": {"text": "The swarm wakes up angry.", "health": -12}},
			{"label": "Reach in", "cap": "guard", "difficulty": 7,
				"success": {"text": "Thick fur, full jars.", "food": 10},
				"mixed": {"text": "Some honey, some stings.", "food": 4, "health": -6},
				"failure": {"text": "The swarm chases everyone.", "health": -12, "fatigue": 10}},
			{"label": "Move on", "success": {"text": "The buzzing fades."}},
		]},
	# ----- travellers -----
	{"id": "scavengers", "kind": "travelers", "title": "Scavengers", "terrains": [], "min_risk": 2,
		"text": "Figures shadow the wagon at dusk, eyeing the cargo.",
		"choices": [
			{"label": "Stand guard", "cap": "guard", "difficulty": 6,
				"success": {"text": "They melt away."},
				"mixed": {"text": "They grab a sack of food.", "food": -10},
				"failure": {"text": "They make off with cargo.", "lose_cargo": 1, "health": -10}},
			{"label": "Slip away", "cap": "scout", "difficulty": 7,
				"success": {"text": "They follow the wrong trail."},
				"mixed": {"text": "A sleepless night.", "fatigue": 15},
				"failure": {"text": "They help themselves.", "lose_cargo": 1}},
			{"label": "Pay them off",
				"success": {"text": "They take food and leave.", "food": -15}},
		]},
	{"id": "toll_road", "kind": "travelers", "title": "Toll road", "terrains": ["Hills", "Mountain", "Forest"], "min_risk": 2,
		"text": "A gate across the road. The keepers want coin.",
		"choices": [
			{"label": "Pay the toll", "cost": {"coins": -12}, "safe_paid": true,
				"success": {"text": "The gate swings open."}},
			{"label": "Sneak around", "cap": "scout", "difficulty": 7,
				"success": {"text": "A goat path, free of charge."},
				"mixed": {"text": "A rough path.", "wear": 8, "fatigue": 10},
				"failure": {"text": "Spotted! They set their beasts on you.", "battle": "toll_beasts", "bounty": 15}},
			{"label": "Force the gate", "success": {"text": "You charge the gate.", "battle": "toll_beasts", "bounty": 15}},
			{"label": "Take the long way", "success": {"text": "A full day around.", "days": 1}},
		]},
	{"id": "trader", "kind": "travelers", "title": "Trader's cart", "terrains": [], "min_risk": 1,
		"text": "A trader waves you down, cart rattling with goods.",
		"choices": [
			{"label": "Buy a battle item", "cost": {"coins": -10}, "safe_paid": true,
				"success": {"text": "A fair trade.", "item": "random"}},
			{"label": "Buy a repair kit", "cost": {"coins": -12}, "safe_paid": true,
				"success": {"text": "Good tools.", "repair_kits": 1}},
			{"label": "Trade food for coin", "cost": {"food": -10}, "safe_paid": true,
				"success": {"text": "She pays well for food.", "coins": 9}},
			{"label": "Wave goodbye", "success": {"text": "Safe travels."}},
		]},
	{"id": "stranded_family", "kind": "travelers", "title": "Stranded travellers", "terrains": [], "min_risk": 1,
		"text": "A family sits by a broken wagon with a cracked axle.",
		"choices": [
			{"label": "Give a repair kit", "cost": {"repair_kits": -1}, "safe_paid": true,
				"success": {"text": "They press a gift on you.", "coins": 15, "technique": 1}},
			{"label": "Fix it together", "cap": "steady", "difficulty": 6,
				"success": {"text": "Good as new. They share supplies.", "food": 8, "coins": 8},
				"mixed": {"text": "It holds, barely.", "fatigue": 10, "coins": 4},
				"failure": {"text": "Half a day wasted.", "progress": -0.5}},
			{"label": "Share some food", "cost": {"food": -6}, "safe_paid": true,
				"success": {"text": "They bless your road.", "light_dust": 1}},
			{"label": "Ride on", "success": {"text": "You don't look back."}},
		]},
	{"id": "trainer", "kind": "travelers", "title": "A wandering trainer", "terrains": [], "min_risk": 1,
		"text": "A trainer with a scarred Plateflit blocks the road. \"Spar?\"",
		"choices": [
			{"label": "Accept", "success": {"text": "Lineups ready!", "battle": "trainer_spar", "bounty": 20}},
			{"label": "Swap tips", "cap": "scout", "difficulty": 5,
				"success": {"text": "She shows your team a trick.", "xp": 25},
				"mixed": {"text": "A few pointers.", "xp": 10},
				"failure": {"text": "She sighs and walks on."}},
			{"label": "Decline", "success": {"text": "She shrugs and walks on."}},
		]},
	{"id": "hermit", "kind": "travelers", "title": "The hermit's hut", "terrains": ["Mountain", "Swamp", "Forest"], "min_risk": 1,
		"text": "An old hermit beckons from a mossy hut.",
		"choices": [
			{"label": "Trade food for a scroll", "cost": {"food": -12}, "safe_paid": true,
				"success": {"text": "She hands you a technique.", "technique": 1}},
			{"label": "Learn from her", "cap": "light", "difficulty": 6,
				"success": {"text": "Your team learns fast.", "xp": 30},
				"mixed": {"text": "A little wisdom.", "xp": 12},
				"failure": {"text": "She snores through it."}},
			{"label": "Politely leave", "success": {"text": "She waves you off."}},
		]},
	# ----- finds -----
	{"id": "abandoned_wagon", "kind": "find", "title": "Abandoned wagon", "terrains": [], "min_risk": 1,
		"text": "An overgrown wagon sits off the road. Nobody's been here in years.",
		"choices": [
			{"label": "Search it", "cap": "scout", "difficulty": 5,
				"success": {"text": "Supplies tucked under the seat.", "item": "random", "coins": 8},
				"mixed": {"text": "A few coins.", "coins": 5},
				"failure": {"text": "Something nests inside. It bites.", "health": -10}},
			{"label": "Strip it for parts", "deal": true, "success": {"text": "A day of work.", "days": 1, "repair_kits": 1}},
			{"label": "Leave it be", "success": {"text": "Let it rest."}},
		]},
	{"id": "ruined_cache", "kind": "find", "title": "Old supply cache", "terrains": ["Hills", "Mountain"], "min_risk": 2,
		"text": "A rusted hatch in the hillside, half buried.",
		"choices": [
			{"label": "Pry it open", "cap": "strength", "difficulty": 6,
				"success": {"text": "Dry rations and a scroll!", "food": 10, "technique": 1},
				"mixed": {"text": "Mostly rust. Some food.", "food": 6},
				"failure": {"text": "The hatch gives way. Sprained paw.", "fatigue": 20}},
			{"label": "Leave it", "success": {"text": "Not worth the risk."}},
		]},
	# ----- shrines -----
	{"id": "shrine", "kind": "shrine", "title": "A humming stone", "terrains": [], "min_risk": 1,
		"text": "A mossy standing stone glows by the road.",
		"choices": [
			{"label": "Leave an offering", "cost": {"food": -6}, "safe_paid": true,
				"success": {"text": "Pale dust settles on the wagon.", "light_dust": 1}},
			{"label": "Touch the rune", "cap": "light", "difficulty": 7,
				"success": {"text": "Dark dust swirls into a jar.", "dark_dust": 1},
				"mixed": {"text": "A jolt. Some dust.", "light_dust": 1, "health": -8},
				"failure": {"text": "A dark jolt. Everyone's dizzy.", "health": -12, "fatigue": 15}},
			{"label": "Walk past", "success": {"text": "It hums softly."}},
		]},
	{"id": "hot_spring", "kind": "shrine", "title": "Hot spring", "terrains": ["Mountain", "Hills", "Swamp"], "min_risk": 1,
		"text": "Steam rises from a warm pool among the rocks.",
		"choices": [
			{"label": "Soak a day", "deal": true, "success": {"text": "Everyone feels new.", "days": 1, "heal_team": 0.5, "fatigue": -30, "health": 10, "cure": 1}},
			{"label": "Fill the barrels", "cap": "float", "difficulty": 5,
				"success": {"text": "Clean, warm water.", "water": 12},
				"mixed": {"text": "Some water.", "water": 6},
				"failure": {"text": "Too hot to touch.", "health": -5}},
			{"label": "Keep going", "success": {"text": "Maybe next time."}},
		]},
]


## Events that can happen on a segment, by terrain, risk and today's weather.
static func for_segment(seg: Dictionary, weather := "") -> Array:
	var out: Array = []
	for e in EVENTS:
		var terrains: Array = e["terrains"]
		var weathers: Array = e.get("weather", [])
		if int(seg.get("risk", 1)) < int(e["min_risk"]):
			continue
		if not weathers.is_empty() and not weathers.has(weather):
			continue
		if terrains.is_empty() or terrains.has(seg["terrain"]):
			out.append(e)
	return out


static func by_id(id: String) -> Dictionary:
	for e in EVENTS:
		if e["id"] == id:
			return e
	return {}


static func daily_chance(risk: int) -> float:
	return BASE_CHANCE + RISK_CHANCE * risk


static func kind_icon(event: Dictionary) -> String:
	return KIND_ICON.get(event.get("kind", "hazard"), "ev_hazard")

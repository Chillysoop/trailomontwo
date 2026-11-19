class_name TrailEvents
extends RefCounted
## The first trail events. Each has choices; a choice with a capability rolls a three-outcome
## check (CheckOdds) helped by the best creature with that capability. A choice without one
## is the safe option: a fixed cost, no roll.
##
## Effects keys: provisions, water, health, wear, integrity, days, fatigue, lose_cargo (count).

## A creature's capability rank (1-3) counts this much toward the check score.
const RANK_SCORE := 3
## Chance per travel day that an event happens, plus this much per risk level. At most one per trip.
const BASE_CHANCE := 0.12
const RISK_CHANCE := 0.08

const EVENTS := [
	{"id": "fallen_tree", "title": "A fallen trunk", "terrains": ["Forest", "Hills"], "min_risk": 1,
		"text": "An old trunk lies across the trail, too big to roll over.",
		"choices": [
			{"label": "Clear it", "cap": "clear", "difficulty": 6,
				"success": {"text": "The trunk is cleared in no time."},
				"mixed": {"text": "Cleared, but a branch scrapes the wagon.", "wear": 8},
				"failure": {"text": "It takes all day and the wagon gets knocked about.", "days": 1, "wear": 12}},
			{"label": "Haul it aside", "cap": "strength", "difficulty": 7,
				"success": {"text": "The trunk rolls off into the ferns."},
				"mixed": {"text": "It moves, but the haulers are worn out.", "fatigue": 15},
				"failure": {"text": "The haulers strain for hours and give up.", "days": 1, "fatigue": 25}},
			{"label": "Go around (1 extra day)",
				"success": {"text": "A long detour through the trees.", "days": 1}},
		]},
	{"id": "swollen_ford", "title": "A swollen ford", "terrains": ["River"], "min_risk": 1,
		"text": "Last night's rain has turned the ford into a fast brown river.",
		"choices": [
			{"label": "Float the wagon across", "cap": "float", "difficulty": 6,
				"success": {"text": "The wagon drifts across, guided all the way."},
				"mixed": {"text": "Across, but some food got soaked.", "provisions": 10},
				"failure": {"text": "The current tips the wagon. Cargo is swept away.", "lose_cargo": 1, "wear": 10}},
			{"label": "Wait for the water to drop (1 day)",
				"success": {"text": "By morning the river is calm enough.", "days": 1}},
		]},
	{"id": "sinking_bog", "title": "Sinking wheels", "terrains": ["Swamp"], "min_risk": 1,
		"text": "The wheels sink into black mud up to the axles.",
		"choices": [
			{"label": "Pull it free", "cap": "strength", "difficulty": 7,
				"success": {"text": "One great heave and the wagon is free."},
				"mixed": {"text": "Free, but the haulers are spent.", "fatigue": 20},
				"failure": {"text": "Something cracks under the wagon.", "integrity": 10, "wear": 15}},
			{"label": "Light a firm path", "cap": "light", "difficulty": 6,
				"success": {"text": "Glowing lamps show the solid ground."},
				"mixed": {"text": "Mostly firm ground. Mostly.", "wear": 8},
				"failure": {"text": "The light fades and you wander for a day.", "days": 1}},
			{"label": "Unload, pull, reload (1 day)",
				"success": {"text": "Slow, muddy work, but nothing breaks.", "days": 1, "fatigue": 10}},
		]},
	{"id": "rockslide", "title": "Loose rocks", "terrains": ["Mountain", "Hills"], "min_risk": 2,
		"text": "Pebbles trickle down the slope above. The whole hillside looks ready to go.",
		"choices": [
			{"label": "Scout a safe line", "cap": "scout", "difficulty": 7,
				"success": {"text": "A sharp-eyed scout finds the safe way through."},
				"mixed": {"text": "A few stones bounce off the canopy.", "wear": 10},
				"failure": {"text": "Rocks come down on the wagon and your traveller.", "integrity": 15, "health": 15}},
			{"label": "Steady the wagon", "cap": "steady", "difficulty": 6,
				"success": {"text": "The wagon creeps past without a wobble."},
				"mixed": {"text": "A wheel slips and scrapes the rocks.", "wear": 10},
				"failure": {"text": "The wagon slides and slams into a boulder.", "integrity": 15}},
			{"label": "Wait until it settles (1 day)",
				"success": {"text": "The slope lets go overnight, well ahead of you.", "days": 1}},
		]},
	{"id": "scavengers", "title": "Scavengers", "terrains": [], "min_risk": 2,
		"text": "Figures shadow the wagon at dusk, eyeing the cargo.",
		"choices": [
			{"label": "Stand guard", "cap": "guard", "difficulty": 6,
				"success": {"text": "One look at your guard and they melt away."},
				"mixed": {"text": "They grab a sack of food and run.", "provisions": 10},
				"failure": {"text": "In the scuffle they make off with cargo.", "lose_cargo": 1, "health": 10}},
			{"label": "Slip away in the dark", "cap": "scout", "difficulty": 7,
				"success": {"text": "You leave them guessing on the wrong trail."},
				"mixed": {"text": "You lose them, and a night's sleep.", "fatigue": 15},
				"failure": {"text": "They catch up and help themselves to cargo.", "lose_cargo": 1}},
			{"label": "Pay them off (15 food)",
				"success": {"text": "They take the food and leave you alone.", "provisions": 15}},
		]},
	{"id": "bitter_night", "title": "A bitter night", "terrains": [], "min_risk": 1,
		"text": "The temperature drops hard after sunset. Your traveller is shivering.",
		"choices": [
			{"label": "Huddle with a cold-hardy creature", "cap": "cold", "difficulty": 5,
				"success": {"text": "Warm fur and a good night's sleep."},
				"mixed": {"text": "A long, uncomfortable night.", "health": 8},
				"failure": {"text": "Your traveller wakes up feverish.", "health": 20}},
			{"label": "Tend with herbs", "cap": "heal", "difficulty": 5,
				"success": {"text": "A warm herbal brew does the trick."},
				"mixed": {"text": "It helps a little.", "health": 8},
				"failure": {"text": "The herbs don't help. Fever sets in.", "health": 20}},
			{"label": "Burn spare supplies for heat (6 food)",
				"success": {"text": "A roaring fire, at a cost.", "provisions": 6}},
		]},
]


## Events that can happen on a segment, by terrain and risk.
static func for_segment(seg: Dictionary) -> Array:
	var out: Array = []
	for e in EVENTS:
		var terrains: Array = e["terrains"]
		if int(seg.get("risk", 1)) >= int(e["min_risk"]) and (terrains.is_empty() or terrains.has(seg["terrain"])):
			out.append(e)
	return out


static func by_id(id: String) -> Dictionary:
	for e in EVENTS:
		if e["id"] == id:
			return e
	return {}


static func daily_chance(risk: int) -> float:
	return BASE_CHANCE + RISK_CHANCE * risk

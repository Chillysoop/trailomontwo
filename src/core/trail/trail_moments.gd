class_name TrailMoments
extends RefCounted
## Trail moments: small things that happen on the road with no decision, shown as an icon toast.
## A moment with a "cap" needs a Trailomon with that trail job; it does the work and earns job XP.
## "{who}" in the text becomes that Trailomon (or a hauler for "hauler": true moments).
##
## Effects use the delta convention of TrailEffects (food: +4 means gain 4).

## Chance per travel day of a moment.
const DAILY_CHANCE := 0.9
## Job experience a helper earns for a moment.
const JOB_XP := 4

const MOMENTS := [
	{"id": "berries", "icon": "job_forage", "cap": "forage", "terrains": ["Forest", "Hills"], "w": 4,
		"text": "{who} finds berries", "fx": {"food": 4}},
	{"id": "mushrooms", "icon": "job_forage", "cap": "forage", "terrains": ["Swamp", "Forest"], "w": 3,
		"text": "{who} digs up mushrooms", "fx": {"food": 5}},
	{"id": "spring", "icon": "water", "cap": "scout", "terrains": ["Forest", "Hills", "Mountain"], "w": 3,
		"text": "{who} spots a spring", "fx": {"water": 6}},
	{"id": "fish", "icon": "job_float", "cap": "float", "terrains": ["River", "Swamp"], "w": 4,
		"text": "{who} catches fish", "fx": {"food": 6}},
	{"id": "rain_barrels", "icon": "w_rain", "weather": ["rain", "storm"], "w": 4,
		"text": "Rain fills the barrels", "fx": {"water": 4}},
	{"id": "marsh_herbs", "icon": "job_heal", "cap": "heal", "terrains": ["Swamp", "River", "Forest"], "w": 3,
		"text": "{who} brews trail herbs", "fx": {"health": 6, "cure": 1}},
	{"id": "dust_glint", "icon": "light_dust", "cap": "light", "terrains": [], "w": 1,
		"text": "{who} finds glinting dust", "fx": {"light_dust": 1}},
	{"id": "old_coins", "icon": "coins", "cap": "scout", "terrains": ["Hills", "Mountain", "Forest"], "w": 2,
		"text": "{who} digs up old coins", "fx": {"coins": 6}},
	{"id": "shortcut", "icon": "progress", "cap": "scout", "terrains": [], "w": 2,
		"text": "{who} finds a shortcut", "fx": {"progress": 0.4}},
	{"id": "hauler_song", "icon": "job_strength", "hauler": true, "terrains": ["Forest", "Hills", "River"], "w": 2,
		"text": "{who} hauls with a spring in its step", "fx": {"fatigue": -6}},
	{"id": "warm_huddle", "icon": "job_cold", "cap": "cold", "weather": ["cold", "storm"], "w": 4,
		"text": "{who} keeps the crew warm", "fx": {"health": 4}},
	# Mishaps.
	{"id": "lost_trail", "icon": "w_fog", "weather": ["fog"], "w": 4,
		"text": "Lost the trail in the fog", "fx": {"progress": -0.4}},
	{"id": "loose_spoke", "icon": "wagon", "terrains": ["Hills", "Mountain", "Forest"], "w": 2,
		"text": "A wheel spoke works loose", "fx": {"wear": 4}},
	{"id": "stumble", "icon": "tired", "hauler": true, "terrains": ["Mountain", "Hills", "Swamp"], "w": 2,
		"text": "{who} stumbles on loose stones", "fx": {"fatigue": 8}},
	{"id": "spoiled", "icon": "food", "weather": ["heat", "rain"], "w": 3,
		"text": "Some food spoils", "fx": {"food": -4}},
	{"id": "parched", "icon": "w_heat", "weather": ["heat"], "w": 4,
		"text": "The heat is brutal", "fx": {"water": -3}},
	{"id": "snowdrift", "icon": "w_cold", "weather": ["cold"], "w": 3,
		"text": "Haulers trudge through drifts", "fx": {"fatigue": 6}},
	{"id": "branch", "icon": "w_storm", "weather": ["storm"], "w": 4,
		"text": "A branch slams the canopy", "fx": {"wear": 5}},
	{"id": "fever", "icon": "fever", "weather": ["rain", "cold", "fog"], "w": 1,
		"text": "Your traveller feels feverish", "fx": {"fever": 3}},
	# Sights: the world going on around you.
	{"id": "grave", "icon": "grave", "terrains": [], "w": 3, "sight": "grave",
		"text": "A grave by the road", "fx": {}},
	{"id": "travellers", "icon": "ev_travelers", "terrains": [], "w": 3, "sight": "traveler",
		"text": "Travellers wave hello", "fx": {}},
	{"id": "bread_trader", "icon": "trade", "terrains": [], "w": 2, "sight": "trader", "need": {"coins": 3},
		"text": "A passing trader sells bread", "fx": {"coins": -3, "food": 6}},
	{"id": "wild_watch", "icon": "ev_wildlife", "terrains": [], "w": 3, "sight": "wild",
		"text": "Wild Trailomon watch the wagon", "fx": {}},
	{"id": "fireflies", "icon": "job_light", "terrains": ["Swamp", "Forest"], "w": 2,
		"text": "Fireflies light the road", "fx": {}},
	{"id": "campfire", "icon": "camp", "terrains": [], "w": 2, "sight": "campfire",
		"text": "Smoke from another camp", "fx": {}},
]

## Names and lines on the graves along the road.
const GRAVES := [
	["Wil Hedges", "Pushed the pace."],
	["Marta Quill", "Drank from the bog."],
	["Old Rennick", "Fed his haulers first."],
	["A. Thistle", "Didn't wait for the river to drop."],
	["Bram and Sully", "Best of friends, worst at fording."],
	["Ivo Lark", "Thin rations, thinner luck."],
	["Nell Brask", "She saw Westwatch from the ridge."],
	["Captain Farrow", "Bet his wagon on the fog."],
	["Pell", "A good hauler. A loyal one."],
	["Tobin Reed", "Ate the purple mushrooms."],
]


static func for_day(terrain: String, weather: String) -> Array:
	var out: Array = []
	for m in MOMENTS:
		var terrains: Array = m.get("terrains", [])
		var weathers: Array = m.get("weather", [])
		if not weathers.is_empty():
			if weathers.has(weather):
				out.append(m)
		elif terrains.is_empty() or terrains.has(terrain):
			out.append(m)
	return out


static func by_id(id: String) -> Dictionary:
	for m in MOMENTS:
		if m["id"] == id:
			return m
	return {}

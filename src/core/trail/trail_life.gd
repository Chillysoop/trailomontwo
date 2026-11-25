class_name TrailLife
extends RefCounted
## The rhythm of the road: weather, pace, rations and trail fever. Pure data and rules.
## See docs/trail-life.md.

# ---------- weather ----------

## Weather ids, each with its icon, the habitat it favours (helpers of that habitat get +1 rank)
## and its daily effects. Effects keys:
##   water_gain: water collected per day     water_mult / food_mult: daily use multiplier
##   wear: extra wagon wear per day          fatigue: extra hauler tiredness per day
##   ambush: extra wild battle chance per day
const WEATHER := {
	"clear": {"name": "Clear", "icon": "w_clear", "favours": "Forest"},
	"rain": {"name": "Rain", "icon": "w_rain", "favours": "River", "water_gain": 3.0, "wear": 1.0},
	"fog": {"name": "Fog", "icon": "w_fog", "favours": "Swamp", "ambush": 0.08},
	"storm": {"name": "Storm", "icon": "w_storm", "favours": "Mountain", "wear": 3.0, "fatigue": 4.0},
	"heat": {"name": "Heat", "icon": "w_heat", "favours": "Jungle", "water_mult": 1.4},
	"cold": {"name": "Cold", "icon": "w_cold", "favours": "Snow", "food_mult": 1.25, "fatigue": 3.0},
	# Dust biomes only: Dark dust ash hurts the crew and tires the haulers; Light dust shimmer mends.
	"ashfall": {"name": "Ashfall", "icon": "w_ashfall", "favours": "", "health": -3.0, "fatigue": 3.0, "ambush": 0.06},
	"shimmer": {"name": "Shimmer", "icon": "w_shimmer", "favours": "", "health": 3.0, "fatigue": -3.0},
}

## Weather odds by terrain (weights).
const WEATHER_TABLE := {
	"Forest": {"clear": 45, "rain": 30, "fog": 15, "storm": 10},
	"Hills": {"clear": 45, "rain": 20, "heat": 15, "cold": 10, "storm": 10},
	"River": {"clear": 35, "rain": 35, "fog": 20, "storm": 10},
	"Swamp": {"fog": 35, "heat": 25, "rain": 25, "clear": 15},
	"Mountain": {"cold": 40, "clear": 25, "storm": 20, "fog": 15},
	"Blight": {"ashfall": 50, "fog": 30, "storm": 20},
	"Glow": {"shimmer": 55, "clear": 35, "rain": 10},
}

## The habitat whose Trailomon are on home ground on this terrain ("" for none).
const TERRAIN_HABITAT := {"Forest": "Forest", "River": "River", "Swamp": "Swamp", "Mountain": "Mountain", "Hills": "",
	"Blight": "", "Glow": ""}


static func roll_weather(terrain: String, rng: RandomNumberGenerator) -> String:
	var table: Dictionary = WEATHER_TABLE.get(terrain, WEATHER_TABLE["Forest"])
	var total := 0
	for w in table:
		total += int(table[w])
	var r := rng.randi_range(0, total - 1)
	for w in table:
		r -= int(table[w])
		if r < 0:
			return w
	return "clear"


static func weather(id: String) -> Dictionary:
	return WEATHER.get(id, WEATHER["clear"])


static func weather_value(id: String, key: String, default := 0.0) -> float:
	return float(weather(id).get(key, default))


# ---------- pace ----------

## speed: trip distance covered per day (in normal days). fatigue: hauler tiredness multiplier.
## heal: creature travel healing multiplier. wear: wagon wear multiplier. health: crew health per day.
const PACES := {
	"easy": {"name": "Easy pace", "icon": "pace_easy", "speed": 0.75, "fatigue": 0.4, "heal": 2.0, "wear": 0.8, "health": 0},
	"steady": {"name": "Steady pace", "icon": "pace_steady", "speed": 1.0, "fatigue": 1.0, "heal": 1.0, "wear": 1.0, "health": 0},
	"hard": {"name": "Hard pace", "icon": "pace_hard", "speed": 1.5, "fatigue": 1.8, "heal": 0.5, "wear": 1.3, "health": -1},
}
const PACE_ORDER := ["easy", "steady", "hard"]

# ---------- rations ----------

## food: daily food multiplier. health: crew health per day. heal: extra creature healing per day (share of max HP).
const RATIONS := {
	"full": {"name": "Full rations", "icon": "rations_full", "food": 1.35, "health": 3, "heal": 0.03},
	"normal": {"name": "Normal rations", "icon": "food", "food": 1.0, "health": 0, "heal": 0.0},
	"thin": {"name": "Thin rations", "icon": "rations_thin", "food": 0.6, "health": -3, "heal": -0.03},
}
const RATIONS_ORDER := ["thin", "normal", "full"]

# ---------- trail fever ----------

## Crew health lost per day while feverish.
const FEVER_DAMAGE := 4
const FEVER_DAYS := 3

## Carried-over progress past a stop is capped so a trip always takes at least one day.
const MAX_CARRY := 0.9


static func pace(id: String) -> Dictionary:
	return PACES.get(id, PACES["steady"])


static func ration(id: String) -> Dictionary:
	return RATIONS.get(id, RATIONS["normal"])


static func next_in(order: Array, current: String) -> String:
	return order[(order.find(current) + 1) % order.size()]


## The hover text for the weather icon.
static func weather_tip(id: String) -> String:
	var w := weather(id)
	var fx: Array[String] = []
	if w.has("water_gain"):
		fx.append("+%d {i:water} a day" % int(w["water_gain"]))
	if w.has("water_mult"):
		fx.append("{i:water} use x%.1f" % float(w["water_mult"]))
	if w.has("food_mult"):
		fx.append("{i:food} use x%.2f" % float(w["food_mult"]))
	if w.has("wear"):
		fx.append("+%d {i:wagon} wear" % int(w["wear"]))
	if w.has("fatigue"):
		fx.append("+%d {i:tired}" % int(w["fatigue"]))
	if w.has("ambush"):
		fx.append("more {i:risk} ambushes")
	var fav: String = w["favours"]
	return "{i:%s} [b]%s[/b]\n%s\n{i:%s} %s Trailomon help better (+1 rank)" % [w["icon"], w["name"],
		"  ".join(fx) if not fx.is_empty() else "Fair travelling weather.", Glossary.habitat_id(fav), fav]


static func pace_tip(id: String) -> String:
	var p := pace(id)
	return "{i:%s} [b]%s[/b] (click to change)\n{i:progress} x%.2f speed   {i:tired} x%.1f   {i:hp} heal x%.1f   {i:wagon} wear x%.1f%s" % [
		p["icon"], p["name"], p["speed"], p["fatigue"], p["heal"], p["wear"],
		("   {i:health} %d a day" % int(p["health"])) if int(p["health"]) != 0 else ""]


static func ration_tip(id: String) -> String:
	var r := ration(id)
	var h := int(r["health"])
	return "{i:%s} [b]%s[/b] (click to change)\n{i:food} x%.2f   {i:health} %s a day" % [r["icon"], r["name"], r["food"], ("+%d" % h) if h > 0 else ("%d" % h) if h < 0 else "+0"]

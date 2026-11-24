class_name Glossary
extends RefCounted
## Every hoverable game word: its name, its icon (if it has one) and a short explanation.
## Text may use Rich markup ({i:id}, {k:id}), so explanations can point at other entries.

const ENTRIES := {
	# ----- creature stats -----
	"hp": {"name": "Health", "icon": "hp",
		"text": "How much damage a creature can take before it is knocked out."},
	"atk": {"name": "Attack", "icon": "atk",
		"text": "Attack power. Basic attacks, ultimates and heals are a percentage of it."},
	"def": {"name": "Defense", "icon": "def",
		"text": "Cuts incoming damage: 50 Defense takes a third off every hit."},
	"spd": {"name": "Speed", "icon": "spd",
		"text": "Seconds between basic attacks. Lower is faster."},
	"dps": {"name": "DPS", "icon": "dps",
		"text": "Basic attack damage per second before the target's {k:def}."},
	"basic": {"name": "Basic attack", "icon": "basic",
		"text": "Fires each time the white attack bar under a creature fills."},
	"passive": {"name": "Passive", "icon": "passive",
		"text": "Always on. Often changes what basic attacks do."},
	"ultimate": {"name": "Ultimate", "icon": "ultimate",
		"text": "A creature's big move. Fires when the gold ultimate bar fills, which happens from attacking and from being hit."},
	"cooldown": {"name": "Battle time", "icon": "cooldown",
		"text": "How long the fight has lasted. After 90 seconds both sides tire."},
	"adjacent": {"name": "adjacent",
		"text": "Directly above, below or beside on the same side's grid."},
	"stagger": {"name": "Stagger", "icon": "weight",
		"text": "A heavy blow knocks the target's attack bar back, delaying its next basic attack. {i:mountain}Mountain."},
	"execute": {"name": "Finisher", "icon": "mountain",
		"text": "Hits harder against badly hurt enemies. {i:mountain}Mountain."},
	"wash": {"name": "Wash away", "icon": "river",
		"text": "Strips {k:shield} off the target before the hit lands. {i:river}River."},
	"dodge": {"name": "Dodge", "icon": "jungle",
		"text": "The next basic attack aimed at this creature misses completely. {i:jungle}Jungle."},
	"light_dust": {"name": "Light dust", "icon": "light_dust",
		"text": "Coming soon: a permanent boost you can give one of your Trailomon."},
	"dark_dust": {"name": "Dark dust", "icon": "dark_dust",
		"text": "Coming soon: a permanent boost with a cost, for one of your Trailomon."},
	"memory": {"name": "Memory slot", "icon": "memory",
		"text": "Each move has one memory slot that can hold a move it learned before. Swap them between battles."},
	"ruin": {"name": "Ruin",
		"text": "Healing received is halved while it lasts."},
	# ----- habitats (filled in from the type chart) -----
	"forest": {"name": "Forest", "icon": "forest", "habitat": "Forest"},
	"river": {"name": "River", "icon": "river", "habitat": "River"},
	"swamp": {"name": "Swamp", "icon": "swamp", "habitat": "Swamp"},
	"mountain": {"name": "Mountain", "icon": "mountain", "habitat": "Mountain"},
	"jungle": {"name": "Jungle", "icon": "jungle", "habitat": "Jungle"},
	"snow": {"name": "Snow", "icon": "snow", "habitat": "Snow"},
	"hills": {"name": "Hills", "icon": "hills",
		"text": "Rolling terrain. Harder hauling than flat forest roads."},
	# ----- roles -----
	"role_guard": {"name": "Guard role", "icon": "role_guard",
		"text": "Tough and slow. Belongs in the {k:front_row} to soak hits."},
	"role_bruiser": {"name": "Bruiser", "icon": "role_bruiser",
		"text": "Sturdy hitter. Fine in the {k:front_row}."},
	"role_healer": {"name": "Healer", "icon": "role_healer",
		"text": "Keeps allies alive. Safest in the {k:back_row}."},
	"role_support": {"name": "Support", "icon": "role_support",
		"text": "Helps the team with {k:shield}s, {k:haste} or {k:poison}. Safest in the {k:back_row}."},
	"role_striker": {"name": "Striker", "icon": "role_striker",
		"text": "Fast damage dealer. Fragile, so usually in the {k:back_row}."},
	"role_boss": {"name": "Boss", "icon": "risk",
		"text": "A huge foe behind its pack. It can't be hit until every creature in its pack is down."},
	# ----- statuses -----
	"shield": {"name": "Shield", "icon": "shield",
		"text": "Soaks damage before {k:hp} is lost. Shown as a pale line on the health bar."},
	"poison": {"name": "Poison", "icon": "poison",
		"text": "Deals damage every second for a while. Turns the health bar green."},
	"taunt": {"name": "Taunt", "icon": "taunt",
		"text": "Draws every enemy's basic attacks to this creature."},
	"haste": {"name": "Haste", "icon": "haste",
		"text": "The attack bar fills faster."},
	"weaken": {"name": "Weaken", "icon": "weaken",
		"text": "Lowers {k:def}, so the creature takes more damage."},
	"slow": {"name": "Slow", "icon": "slow",
		"text": "The attack bar fills slower."},
	"ko": {"name": "Knocked out", "icon": "ko",
		"text": "Out of the fight. Can't haul, fight or help until you rest a day."},
	"tired": {"name": "Tired", "icon": "tired",
		"text": "Hauling wears creatures out. Tired haulers pull less. Rest a day to recover."},
	# ----- trail -----
	"day": {"name": "Day", "icon": "day",
		"text": "Every day on the trail costs {k:food} and {k:water}."},
	"food": {"name": "Food", "icon": "food",
		"text": "Provisions for people and creatures. Running out starves the crew."},
	"water": {"name": "Water", "icon": "water",
		"text": "Drunk every day. Running out is deadly fast."},
	"cargo": {"name": "Cargo", "icon": "cargo",
		"text": "Goods you deliver to Westwatch. Heavier cargo needs more {k:haul}."},
	"haul": {"name": "Hauling", "icon": "haul",
		"text": "Pulling strength from your harnessed creatures. If the load needs more, you {k:push} or can't go."},
	"wagon": {"name": "Wagon", "icon": "wagon",
		"text": "Your mobile base. Wear builds up on the trail and can cause a {k:breakdown}."},
	"health": {"name": "Crew health", "icon": "health",
		"text": "How your people are holding up. Hunger, thirst and bad events lower it."},
	"repair_kit": {"name": "Repair kit", "icon": "repair_kit",
		"text": "Fixes the wagon in one day instead of two."},
	"risk": {"name": "Risk", "icon": "risk",
		"text": "How dangerous a stretch of trail is. Riskier roads bring tougher fights."},
	"value": {"name": "Value", "icon": "value",
		"text": "What the cargo is worth when delivered."},
	"weight": {"name": "Weight", "icon": "weight",
		"text": "How heavy it is. Adds to the hauling the wagon needs."},
	# ----- plain keywords (no icon) -----
	"front_row": {"name": "front row",
		"text": "The row nearest the enemy. Normal attacks hit it first."},
	"back_row": {"name": "second row",
		"text": "The row behind. Safe until the front row falls, unless a foe reaches over."},
	"synergy": {"name": "habitat bonus",
		"text": "With 2 or more creatures of one habitat on your side, they all get a bonus. 4 doubles it."},
	"push": {"name": "pushing",
		"text": "The load is a bit too heavy: travel is slower and wears the wagon faster."},
	"breakdown": {"name": "breakdown",
		"text": "Past 60 wear a wagon part can break: the axle (can't leave), harness (weaker hauling) or canopy (water spoils)."},
	"pierce": {"name": "pierces",
		"text": "Ignores {k:def} completely."},
	"ambush": {"name": "ambush",
		"text": "You were caught off guard: your team starts the fight slower."},
	# event capabilities
	"cap_strength": {"name": "strength", "text": "Brute force: shoving, lifting, pulling free."},
	"cap_guard": {"name": "guarding", "text": "Standing watch and protecting the camp."},
	"cap_steady": {"name": "steadiness", "text": "Calm footing on bad ground."},
	"cap_float": {"name": "swimming", "text": "Crossing water and fishing things out."},
	"cap_scout": {"name": "scouting", "text": "Finding paths and spotting danger early."},
	"cap_light": {"name": "light", "text": "Lighting the way in the dark."},
	"cap_heal": {"name": "healing", "text": "Tending wounds and sickness."},
	"cap_cold": {"name": "cold hardiness", "text": "Shrugging off frost and snow."},
	"cap_clear": {"name": "clearing", "text": "Cutting through brush and fallen trees."},
}

## Role name (as in CombatData.KITS) -> entry id.
const ROLES := {"Guard": "role_guard", "Bruiser": "role_bruiser", "Healer": "role_healer",
	"Support": "role_support", "Striker": "role_striker", "Boss": "role_boss"}


static func has(id: String) -> bool:
	return ENTRIES.has(id)


static func entry_name(id: String) -> String:
	return ENTRIES[id]["name"] if ENTRIES.has(id) else id


static func icon(id: String) -> String:
	return ENTRIES[id].get("icon", "") if ENTRIES.has(id) else ""


## Habitat or terrain word ("Forest", "Hills") -> entry id.
static func habitat_id(type: String) -> String:
	return type.to_lower()


## Explanation in Rich markup.
static func text(id: String) -> String:
	if not ENTRIES.has(id):
		return ""
	var e: Dictionary = ENTRIES[id]
	if e.has("habitat"):
		return _habitat_text(e["habitat"])
	return e["text"]


static func _habitat_text(type: String) -> String:
	var chart: Array = CombatData.CHART[type]
	var weak_to := ""
	for t in CombatData.CHART:
		if CombatData.CHART[t][0] == type:
			weak_to = t
	var syn: Dictionary = CombatData.SYNERGIES[type]
	var lines: Array[String] = []
	lines.append("%s: %s" % [CombatData.HABITATS[type]["theme"], CombatData.HABITATS[type]["line"]])
	lines.append("Its attacks hit {i:%s}%s hard and {i:%s}%s softly." % [
		habitat_id(chart[0]), chart[0], habitat_id(chart[1]), chart[1]])
	if weak_to != "":
		lines.append("Takes extra damage from {i:%s}%s." % [habitat_id(weak_to), weak_to])
	lines.append("{k:synergy|Bonus} %s: %s with 2, %s with 4." % [syn["name"],
		syn["desc"] % int(syn["values"][0]), syn["desc"] % int(syn["values"][1])])
	return "\n".join(lines)

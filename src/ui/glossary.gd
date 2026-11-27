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
		"text": "A permanent boost to the stat you choose for one Trailomon. Each Trailomon can take 5 dust in total (Light and Dark). Every win gathers some."},
	"dark_dust": {"name": "Dark dust", "icon": "dark_dust",
		"text": "A big permanent boost to the stat you choose, paid for by its opposite: Attack and Defense trade, Max HP and Speed trade. Counts toward a Trailomon's 5 dust. Strong fights and the guardian drop it."},
	"technique": {"name": "Technique", "icon": "technique",
		"text": "A one-use scroll that teaches a move. Any Trailomon of the same habitat as the move's species can learn it, into its equipped slot or its memory slot. Wins sometimes drop them; the guardian always does."},
	"battle_items": {"name": "Battle items", "icon": "item_slot",
		"text": "Up to 3 consumables you choose before a fight. Each boosts your whole team (or hinders the foes) for that battle and is used up when it ends. Wins sometimes drop more."},
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
	"blight": {"name": "Blight", "icon": "biome_blight",
		"text": "Land soaked in {i:dark_dust} Dark dust, spreading from crossing 3. Riskier roads, {i:w_ashfall} ashfall, Trailomon found nowhere else. Wins give +1 {i:dark_dust}."},
	"glow": {"name": "Glow", "icon": "biome_glow",
		"text": "Land bright with {i:light_dust} Light dust, spreading from crossing 3. {i:w_shimmer} Shimmer mends the crew, but its Trailomon are strong. Wins give +1 {i:light_dust}."},
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
		"text": "Goods you deliver to the far side of the crossing. Each crate pays coins on arrival, but takes room in the wagon."},
	"haul": {"name": "Hauling", "icon": "haul",
		"text": "Pulling strength from your harnessed creatures. If the load needs more, you {k:push} or can't go."},
	"wagon": {"name": "Wagon", "icon": "wagon",
		"text": "Your mobile base. Wear builds up on the trail and can cause a {k:breakdown}."},
	"health": {"name": "Crew health", "icon": "health",
		"text": "How your people are holding up. Hunger, thirst and bad events lower it."},
	"repair_kit": {"name": "Repairs", "icon": "repair_kit",
		"text": "A broken part needs its spare part. Without one, a Trailomon with the right job can jury-rig it."},
	"spare_axle": {"name": "Spare axle", "icon": "spare_axle",
		"text": "Fixes a broken axle in a day. Heavy, but without one you limp. {i:job_strength} Strength Trailomon can jury-rig an axle."},
	"spare_harness": {"name": "Spare harness", "icon": "spare_harness",
		"text": "Fixes a broken harness in a day. {i:job_steady} Steady Trailomon can jury-rig one."},
	"spare_canvas": {"name": "Canopy canvas", "icon": "spare_canvas",
		"text": "Fixes a torn canopy in a day. {i:job_guard} Guard Trailomon can jury-rig one."},
	"lucky_cog": {"name": "Lucky cog", "icon": "lucky_cog", "text": "Stops the first breakdown of the crossing, then rattles loose."},
	"reed_pipe": {"name": "Reed pipe", "icon": "reed_pipe", "text": "A tune at camp: rest days heal the team and haulers much more."},
	"ember_kettle": {"name": "Ember kettle", "icon": "ember_kettle", "text": "Hot meals: cold and snowy days don't eat extra food."},
	"brass_spyglass": {"name": "Brass spyglass", "icon": "brass_spyglass", "text": "See one road further through the fog from every stop."},
	"risk": {"name": "Risk", "icon": "risk",
		"text": "How dangerous a stretch of trail is. Riskier roads bring tougher fights."},
	"value": {"name": "Value", "icon": "value",
		"text": "What the cargo is worth when delivered."},
	"weight": {"name": "Weight", "icon": "weight",
		"text": "How heavy it is. The wagon holds 300: cargo, food, water and parts all count. Heavier loads wear the wagon and tire the haulers."},
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
	# trail jobs (capabilities): who can help in trail events and moments
	"cap_strength": {"name": "Strength", "icon": "job_strength", "text": "Trail job. Brute force: shoving, lifting, pulling free, outrunning."},
	"cap_guard": {"name": "Guard", "icon": "guard", "text": "Trail job. Standing watch and protecting the camp."},
	"cap_steady": {"name": "Steady", "icon": "job_steady", "text": "Trail job. Calm footing on bad ground and in storms."},
	"cap_float": {"name": "Float", "icon": "job_float", "text": "Trail job. Crossing water and catching fish."},
	"cap_scout": {"name": "Scout", "icon": "job_scout", "text": "Trail job. Finding paths, shortcuts and springs, and spotting danger early."},
	"cap_light": {"name": "Light", "icon": "job_light", "text": "Trail job. Lighting the way through fog, bogs and old ruins."},
	"cap_heal": {"name": "Heal", "icon": "job_heal", "text": "Trail job. Tending wounds, brewing herbs, curing {k:fever}."},
	"cap_cold": {"name": "Cold", "icon": "job_cold", "text": "Trail job. Shrugging off frost and keeping the crew warm."},
	"cap_clear": {"name": "Clear", "icon": "job_clear", "text": "Trail job. Cutting through brush, trunks and snares."},
	"cap_forage": {"name": "Forage", "icon": "job_forage", "text": "Trail job. Finding berries, roots and mushrooms along the road."},
	"job": {"name": "trail job", "icon": "xp",
		"text": "Trailomon with the right job help in trail events: rank x3 vs the difficulty. +1 rank on {k:home|home ground}, +1 in weather that favours its habitat. Helpers earn {i:xp} experience."},
	"home": {"name": "home ground", "icon": "progress",
		"text": "A Trailomon on a road of its own habitat (a River Trailomon on a river road) gets +1 rank in trail jobs."},
	# ----- trail life -----
	"weather": {"name": "Weather", "icon": "w_clear",
		"text": "Rolled each travel day from the road's terrain. Rain, fog, storms, heat and cold change what a day costs, and each weather helps one habitat's Trailomon at trail jobs. The route card shows the likeliest weather."},
	"w_clear": {"name": "Clear", "icon": "w_clear", "text": "Fair weather. {i:forest} Forest Trailomon do trail jobs better."},
	"w_rain": {"name": "Rain", "icon": "w_rain", "text": "+3 {i:water} a day from the barrels, +1 wagon wear. {i:river} River Trailomon do trail jobs better."},
	"w_fog": {"name": "Fog", "icon": "w_fog", "text": "More ambushes, and you can lose the trail. {i:swamp} Swamp Trailomon do trail jobs better."},
	"w_storm": {"name": "Storm", "icon": "w_storm", "text": "+3 wagon wear and tired haulers. {i:mountain} Mountain Trailomon do trail jobs better."},
	"w_heat": {"name": "Heat", "icon": "w_heat", "text": "{i:water} Water use x1.4. {i:jungle} Jungle Trailomon do trail jobs better."},
	"w_cold": {"name": "Cold", "icon": "w_cold", "text": "{i:food} Food use x1.25, haulers tire. {i:snow} Snow Trailomon do trail jobs better."},
	"w_ashfall": {"name": "Ashfall", "icon": "w_ashfall", "text": "Dark dust ash: -3 {i:health} a day, haulers tire, more ambushes. Only in the {k:blight|Blight}."},
	"w_shimmer": {"name": "Shimmer", "icon": "w_shimmer", "text": "Light dust in the air: +3 {i:health} a day, haulers rest as they walk. Only in the {k:glow|Glow}."},
	"pace": {"name": "Pace", "icon": "pace_steady",
		"text": "{i:pace_easy} Easy: slower, haulers barely tire, team heals x2. {i:pace_steady} Steady. {i:pace_hard} Hard: x1.5 speed, haulers tire fast, more wear, -1 {i:health} a day."},
	"rations": {"name": "Rations", "icon": "food",
		"text": "{i:rations_thin} Thin: x0.6 food, -3 {i:health} a day. {i:food} Normal. {i:rations_full} Full: x1.35 food, +3 {i:health} a day, team heals faster."},
	"pace_easy": {"name": "Easy pace", "icon": "pace_easy", "text": "x0.75 speed. Haulers barely tire and the team heals twice as fast on the road."},
	"pace_steady": {"name": "Steady pace", "icon": "pace_steady", "text": "Normal speed, normal wear."},
	"pace_hard": {"name": "Hard pace", "icon": "pace_hard", "text": "x1.5 speed. Haulers tire much faster, the wagon wears faster, -1 {i:health} a day."},
	"rations_thin": {"name": "Thin rations", "icon": "rations_thin", "text": "x0.6 food. -3 {i:health} a day and the team heals slower."},
	"rations_full": {"name": "Full rations", "icon": "rations_full", "text": "x1.35 food. +3 {i:health} a day and the team heals faster."},
	"coins": {"name": "Coins", "icon": "coins",
		"text": "Trail money. Spend it at stalls, ferries, tolls and traders. Wins, finds and good deeds earn it."},
	"fever": {"name": "Trail fever", "icon": "fever",
		"text": "Your traveller is sick: -4 {i:health} a day until it passes. Rest a day, medicine or a {k:cap_heal|healer} cures it."},
	"xp": {"name": "Experience", "icon": "xp",
		"text": "Trailomon earn it in battles and by doing {k:job|trail jobs}. Enough of it means a level up."},
	"progress": {"name": "Trail progress", "icon": "progress",
		"text": "How far along the road you are. Shortcuts gain ground, getting lost loses it."},
	"settlement": {"name": "Stop", "icon": "settlement",
		"text": "A place to resupply. Every stop has a stall, a rumor about the road and a safe place to rest."},
	"grave": {"name": "Grave", "icon": "grave", "text": "Not everyone makes it across."},
	"trade": {"name": "Trade", "icon": "trade", "text": "Buy supplies with {i:coins} coins. Stock is limited."},
	"camp": {"name": "Camp", "icon": "camp", "text": "Other travellers share the road."},
	"ev_travelers": {"name": "Travellers", "icon": "ev_travelers", "text": "People on the road: traders, trainers, families, toll keepers."},
	"ev_wildlife": {"name": "Wildlife", "icon": "ev_wildlife", "text": "Wild Trailomon and herds. Some may want to join you."},
	"ev_hazard": {"name": "Hazard", "icon": "ev_hazard", "text": "The road itself fights back: rivers, mud, rocks, storms."},
	"ev_find": {"name": "Find", "icon": "ev_find", "text": "Something worth stopping for."},
	"ev_shrine": {"name": "Shrine", "icon": "ev_shrine", "text": "Old places that hum with dust."},
}

## Role name (as in CombatData.KITS) -> entry id.
const ROLES := {"Guard": "role_guard", "Bruiser": "role_bruiser", "Healer": "role_healer",
	"Support": "role_support", "Striker": "role_striker", "Boss": "role_boss"}


static func has(id: String) -> bool:
	return ENTRIES.has(id) or BattleItems.has(id)


static func entry_name(id: String) -> String:
	if BattleItems.has(id):
		return BattleItems.item_name(id)
	return ENTRIES[id]["name"] if ENTRIES.has(id) else id


static func icon(id: String) -> String:
	if BattleItems.has(id):
		return id
	return ENTRIES[id].get("icon", "") if ENTRIES.has(id) else ""


## Habitat or terrain word ("Forest", "Hills") -> entry id.
static func habitat_id(type: String) -> String:
	return type.to_lower()


## Explanation in Rich markup.
static func text(id: String) -> String:
	if BattleItems.has(id):
		return BattleItems.desc(id) + " Used up when the fight ends."
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

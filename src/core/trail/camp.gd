class_name Camp
extends RefCounted
## Camp life: the crew's morale, cooking a hot meal from what you forage, foraging for
## ingredients (and the odd unknown plant), and the campfire when you rest.

# ---------- morale ----------

const START := 70
const MAX := 100
## Morale bands: [floor, id, name, icon colour]. Spirited crews do trail jobs better; a grim
## crew does them worse and its haulers tire faster.
const BANDS := [[75, "spirited", "Spirited", "9fe39a"], [50, "steady", "Steady", "e8dcc0"], [25, "low", "Low", "f0d27a"], [0, "grim", "Grim", "ff8a7a"]]
const SPIRITED_BONUS := 1
const GRIM_PENALTY := -1
const GRIM_FATIGUE := 4.0
## Daily drift.
const DRIFT := {"road": -1, "thin_rations": -2, "full_rations": 1, "grueling": -2, "frost": -2, "storm": -1, "ailing": -1, "fever": -1, "hungry": -6}
## Gains and losses from things that happen.
const ON := {"win": 4, "catch": 5, "landmark": 3, "rest": 4, "lose": -6, "ko": -3, "breakdown": -4, "lost_cargo": -3, "hunt": 3, "deliver": 3}


static func band(morale: int) -> Array:
	for b in BANDS:
		if morale >= int(b[0]):
			return b
	return BANDS[BANDS.size() - 1]


# ---------- ingredients and cooking ----------

const INGREDIENTS := {
	"herbs": {"name": "wild herbs", "icon": "ing_herbs"},
	"mushrooms": {"name": "mushrooms", "icon": "ing_mushrooms"},
	"berries": {"name": "berries", "icon": "ing_berries"},
	"fish": {"name": "fresh fish", "icon": "ing_fish"},
}
## Ingredients are light (bundles weigh this each) and keep a while.
const PANTRY_MAX := 6
## Recipes, best first: what they need and what a hot meal does. Each costs MEAL_FOOD food too.
const MEAL_FOOD := 5.0
const RECIPES := [
	{"id": "fish_stew", "name": "Riverside fish stew", "needs": {"fish": 1, "herbs": 1}, "fx": {"morale": 12, "heal_team": 0.25, "health": 8}},
	{"id": "mushroom_pie", "name": "Mushroom pie", "needs": {"mushrooms": 1, "berries": 1}, "fx": {"morale": 12, "health": 10, "fatigue": -15}},
	{"id": "grilled_fish", "name": "Grilled fish", "needs": {"fish": 1}, "fx": {"morale": 6, "heal_team": 0.2}},
	{"id": "herb_broth", "name": "Herb broth", "needs": {"herbs": 1}, "fx": {"morale": 5, "health": 6, "cure": true}},
	{"id": "mushroom_soup", "name": "Mushroom soup", "needs": {"mushrooms": 1}, "fx": {"morale": 6, "fatigue": -10}},
	{"id": "berry_cobbler", "name": "Berry cobbler", "needs": {"berries": 1}, "fx": {"morale": 9}},
]


static func ingredient(id: String) -> Dictionary:
	return INGREDIENTS.get(id, {})


## The best recipe the pantry can make ({} if none).
static func best_recipe(pantry: Dictionary) -> Dictionary:
	for r in RECIPES:
		var ok := true
		for k in r["needs"]:
			if int(pantry.get(k, 0)) < int(r["needs"][k]):
				ok = false
		if ok:
			return r
	return {}


# ---------- foraging ----------

## What grows where: terrain -> ingredients you can find.
const FORAGE := {
	"Forest": ["mushrooms", "berries", "herbs"], "Hills": ["herbs", "berries"], "River": ["fish", "herbs"],
	"Swamp": ["mushrooms", "fish"], "Mountain": ["herbs"], "Snow": ["berries", "fish"], "Jungle": ["berries", "mushrooms", "herbs"],
	"Blight": ["mushrooms"], "Glow": ["berries", "herbs"],
}
## Unknown plants: [id, name, good when eaten, the good line, the bad line].
const PLANTS := [
	["violet_caps", "violet caps", true, "Nutty and sweet. Everyone wants more.", ""],
	["brass_puffballs", "brass puffballs", false, "", "They taste like old pennies. Stomach cramps all night."],
	["ember_berries", "ember berries", true, "Warm as a hug. The crew perks right up.", ""],
	["ghost_onions", "ghost onions", false, "", "Clear as glass and twice as hard to digest."],
	["teal_ferns", "teal fiddleheads", true, "Crisp and green. A good find.", ""],
	["snapwort", "snapwort", false, "", "It snaps back. Nobody feels well."],
	["sun_figs", "sun figs", true, "Sticky, golden and delicious.", ""],
	["inkcaps", "inkcaps", false, "", "Everything is purple for a day, including your tongue."],
]
## Forage rank that can tell an unknown plant at a glance.
const KNOW_RANK := 3
const FORAGE_DIFFICULTY := 4
const PLANT_CHANCE := 0.35


static func plant(id: String) -> Array:
	for p in PLANTS:
		if p[0] == id:
			return p
	return []


## The foraging card. finds: the ingredients on offer here.
static func forage_card(terrain: String, finds: Array, plant_id: String, known: bool, forager_knows: bool) -> Dictionary:
	var choices: Array = []
	var a: String = finds[0]
	var b: String = finds[1] if finds.size() > 1 else finds[0]
	choices.append({"label": "Search the undergrowth", "cap": "forage", "difficulty": FORAGE_DIFFICULTY,
		"success": {"text": "Your basket fills up.", "pantry": {a: 1, b: 1}},
		"mixed": {"text": "A small handful.", "pantry": {a: 1}},
		"failure": {"text": "Nothing but thorns and a sore paw."}})
	var e := {"id": "forage", "kind": "find", "icon": "forage", "title": "Foraging", "choices": choices,
		"text": "You walk out from camp with a basket. %s" % _where(terrain)}
	if plant_id != "":
		var p := plant(plant_id)
		var safe: bool = known or forager_knows
		if safe:
			e["text"] += " You spot %s. %s" % [p[1], ("You know these: good eating." if p[2] else "You know these: leave them be.") if known else "Your forager sniffs them and %s." % ("digs right in" if p[2] else "backs away")]
		else:
			e["text"] += " You spot something you don't know: %s." % p[1]
		if not safe or p[2]:
			var good := {"text": String(p[3]), "morale": 6, "food": 6, "learn_plant": plant_id}
			var bad := {"text": String(p[4]), "fever": 2, "morale": -4, "learn_plant": plant_id}
			choices.append({"label": "Eat the %s" % p[1], "success": good if p[2] else bad, "risky": not safe})
	choices.append({"label": "Head back to camp", "success": {"text": "You head back."}})
	return e


static func _where(terrain: String) -> String:
	return {"Forest": "Mushrooms hide under the ferns.", "River": "The shallows flicker with fish.", "Swamp": "Pale caps glow on the logs.",
		"Snow": "Red berries poke through the snow.", "Jungle": "Fruit hangs everywhere.", "Mountain": "Herbs cling to the rocks.",
		"Hills": "Brambles and wild thyme.", "Blight": "Even here, something grows.", "Glow": "Everything shimmers faintly."}.get(terrain, "")


# ---------- the campfire ----------

const TALES := [
	"Old Marrow's tale: the guardians were here before the roads, and they'll be here after.",
	"A ghost story about a wagon that rolls west with no one at the reins. Nobody sleeps much.",
	"Someone swears the Light dust is the stars, ground fine. It's a nice thought.",
	"A song about a brass giant who fell asleep and became a mountain. Everyone joins the chorus.",
	"A tale of a trader who crossed the frost on foot, and what she traded to get through.",
	"The story of the first Trailomon to pull a wagon, and why it chose to.",
	"A riddle with no answer. You argue about it until the fire burns low.",
	"Folklore says if you leave a berry on a stump, the forest remembers you.",
]
const BOND_LINES := [
	"%s and %s curl up together by the fire.",
	"%s shares its supper with %s.",
	"%s keeps watch while %s sleeps.",
	"%s and %s play chase around the wagon until they drop.",
]
const BOND_XP := 10


## The campfire card, after a day's rest.
static func campfire(tale: String, bond: String) -> Dictionary:
	return {"id": "campfire", "kind": "find", "icon": "campfire", "title": "Around the campfire",
		"text": tale + ("\n" + bond if bond != "" else ""),
		"choices": [
			{"label": "Tell another story", "success": {"text": "Late to bed, and smiling.", "morale": 8}},
			{"label": "Sing them to sleep", "success": {"text": "A gentle song. Everyone sleeps deep.", "morale": 5, "fatigue": -10}},
			{"label": "Turn in early", "success": {"text": "A long, quiet night.", "health": 6}},
		]}

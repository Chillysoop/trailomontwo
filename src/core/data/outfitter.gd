class_name Outfitter
extends RefCounted
## The outfitter at the start town of every crossing: you set out with an empty wagon and a
## purse, and buy your whole loadout here under the wagon's weight limit. Each start town has
## its own shopkeeper with opinions (sometimes wrong) and a "pack it for me" kit that shows them.
##
## Curiosities are odd little comforts that each do one specific thing. Most crossings you
## won't miss them; now and then one saves the trip.

## Extra coins for outfitting: every crossing sets out with at least WORLD_START_COINS + PURSE.
const PURSE := 65

## What each lot weighs in the wagon (wagon capacity is Wagon.CAPACITY).
const WEIGHTS := {
	"food": 4.0, "water": 6.0, "spare_axle": 20.0, "spare_harness": 8.0, "spare_canvas": 10.0,
	"lure": 1.0, "lucky_cog": 2.0, "reed_pipe": 2.0, "ember_kettle": 6.0, "brass_spyglass": 3.0,
}
## Battle items and techniques weigh this much a lot.
const SMALL_WEIGHT := 1.0

## Curiosities: one of each at most. What they do is in Expedition (search the id).
const CURIOS := {
	"lucky_cog": {"name": "Lucky cog", "icon": "lucky_cog",
		"text": "Stops the first breakdown of the crossing, then rattles loose and is gone."},
	"reed_pipe": {"name": "Reed pipe", "icon": "reed_pipe",
		"text": "A tune at camp: rest days heal the team and haulers much more."},
	"ember_kettle": {"name": "Ember kettle", "icon": "ember_kettle",
		"text": "Hot meals in the cold: cold and snowy days don't eat extra food."},
	"brass_spyglass": {"name": "Brass spyglass", "icon": "brass_spyglass",
		"text": "See one road further through the fog from every stop."},
}

## The outfitter's stock: good -> [price, stock]. "BATTLE" lines become two battle items.
const STOCK := {
	"food": [2, 30], "water": [1, 20], "spare_axle": [14, 3], "spare_harness": [8, 3], "spare_canvas": [9, 3],
	"lucky_cog": [12, 1], "reed_pipe": [10, 1], "ember_kettle": [11, 1], "brass_spyglass": [13, 1],
	"smoke_pouch": [9, 2], "ironbark_salve": [10, 2], "lure": [6, 4],
}

## The two shopkeepers: odd crossings start in the east (Hob), even ones in the west (Marrow).
## "kit" is what "Pack it for me" buys, in order, while coins and room last.
const KEEPERS := [
	{"id": "hob", "name": "Hob Ferrule", "trade": "wagonwright",
		"hello": "Wheels first, bellies second. Ask anyone who walked home.",
		"bias": "Hob swears by spare parts and packs light on water.",
		"kit": ["spare_axle", "spare_harness", "spare_canvas", "food", "food", "food", "food", "food", "food", "food", "food",
			"water", "water", "water", "water", "lucky_cog", "food", "food"]},
	{"id": "marrow", "name": "Marrow Bell", "trade": "provisioner",
		"hello": "A fed crew fixes its own axles. Mostly.",
		"bias": "Marrow piles on food and water and trusts the team to patch the wagon.",
		"kit": ["food", "food", "food", "food", "food", "food", "food", "food", "food", "food", "food", "food",
			"water", "water", "water", "water", "water", "water", "spare_axle", "reed_pipe"]},
]

## Advice about the road ahead, by the terrain the crossing has the most of.
const ADVICE := {
	"River": "Fords all the way. Wet canvas rots, so carry spare canopy canvas.",
	"Swamp": "Bog mud eats harness straps. A spare harness, or a steady Trailomon.",
	"Mountain": "Steep roads snap axles. A spare axle weighs a lot and is worth it.",
	"Hills": "Toll keepers on the hills. Keep some coins back.",
	"Forest": "Fallen trunks on the forest roads. Bring someone strong.",
	"Snow": "Cold days eat food. Pack extra, or something to cook on.",
	"Jungle": "Heat drinks your water fast. Fill every barrel.",
	"Blight": "Ash on the wind out there. Medicine from the warden camps.",
	"Glow": "The Glow is gentle. Don't let it make you careless.",
}


static func keeper(crossing_no: int) -> Dictionary:
	return KEEPERS[(maxi(1, crossing_no) - 1) % KEEPERS.size()]


static func is_curio(good: String) -> bool:
	return CURIOS.has(good)


static func weight_of(good: String) -> float:
	if WEIGHTS.has(good):
		return float(WEIGHTS[good])
	if good == "technique" or BattleItems.has(good):
		return SMALL_WEIGHT
	return 0.0


## The keeper's tip for this map: the terrain with the most roads.
static func advice(map: WorldMap) -> String:
	if map == null:
		return ""
	var counts := {}
	for seg in map.segments:
		var t := String(seg.get("terrain", ""))
		counts[t] = int(counts.get(t, 0)) + 1
	var best := ""
	for t in counts:
		if ADVICE.has(t) and (best == "" or int(counts[t]) > int(counts[best])):
			best = t
	return ADVICE.get(best, "")

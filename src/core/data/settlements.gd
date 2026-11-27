class_name Settlements
extends RefCounted
## What each stop on the test route is: its kind (buildings around the wagon), its trade stall
## (priced in coins, limited stock per crossing) and one rumor about the road ahead.

## Buildings shown around the wagon at each kind of stop (props in assets/props).
const KINDS := {
	"town": {"name": "Town", "props": ["bld_town_gate", "hut", "trading_post", "well"]},
	"village": {"name": "Village", "props": ["hut", "well", "campfire"]},
	"waystation": {"name": "Waystation", "props": ["bld_inn", "tent_camp", "signpost"]},
	"post": {"name": "Trading post", "props": ["trading_post", "tent_camp", "signpost"]},
	"ruins": {"name": "Ruins", "props": ["bld_ruins", "abandoned_cart", "shrine_stone"]},
	"stilts": {"name": "Stilt village", "props": ["stilt_house", "trading_post", "stilt_house"]},
	"lookout": {"name": "Lookout", "props": ["bld_lookout", "signpost", "campfire"]},
	"warden": {"name": "Warden camp", "props": ["bld_ward_post", "tent_camp", "campfire"]},
	"sanctum": {"name": "Sanctum", "props": ["bld_sanctum", "glow_flowers", "well"]},
}

## One lot of each good: what it gives (TrailEffects deltas).
const GOODS := {
	"food": {"name": "10 food", "icon": "food", "fx": {"food": 10}},
	"water": {"name": "10 water", "icon": "water", "fx": {"water": 10}},
	"spare_axle": {"name": "a spare axle", "icon": "spare_axle", "fx": {"spare_axle": 1}},
	"spare_harness": {"name": "a spare harness", "icon": "spare_harness", "fx": {"spare_harness": 1}},
	"spare_canvas": {"name": "canopy canvas", "icon": "spare_canvas", "fx": {"spare_canvas": 1}},
	"lucky_cog": {"name": "a lucky cog", "icon": "lucky_cog", "fx": {"curio": "lucky_cog"}},
	"reed_pipe": {"name": "a reed pipe", "icon": "reed_pipe", "fx": {"curio": "reed_pipe"}},
	"ember_kettle": {"name": "an ember kettle", "icon": "ember_kettle", "fx": {"curio": "ember_kettle"}},
	"brass_spyglass": {"name": "a brass spyglass", "icon": "brass_spyglass", "fx": {"curio": "brass_spyglass"}},
	"technique": {"name": "a technique scroll", "icon": "technique", "fx": {"technique": 1}},
	"light_dust": {"name": "Light dust", "icon": "light_dust", "fx": {"light_dust": 1}},
	"dark_dust": {"name": "Dark dust", "icon": "dark_dust", "fx": {"dark_dust": 1}},
	"medicine": {"name": "fever medicine", "icon": "job_heal", "fx": {"cure": 1, "health": 10}},
	"lure": {"name": "a catching lure", "icon": "lure", "fx": {"lures": 1}},
}

## Stops: kind, stall {good: {"price", "stock"}} and a rumor (Rich markup, short).
const STOPS := {
	"eastgate": {"kind": "town", "rumor": "{i:river} The ford past Mossford floods after {i:w_rain} rain.",
		"stall": {"food": {"price": 5, "stock": 6}, "water": {"price": 3, "stock": 6}, "spare_axle": {"price": 14, "stock": 1}, "spare_harness": {"price": 8, "stock": 1},
			"ironbark_salve": {"price": 10, "stock": 2}, "ember_draught": {"price": 10, "stock": 2}, "medicine": {"price": 8, "stock": 2}}},
	"mossford": {"kind": "village", "rumor": "{i:ev_travelers} Toll keepers on the {i:hills} hills want 12 {i:coins}.",
		"stall": {"food": {"price": 4, "stock": 5}, "water": {"price": 3, "stock": 5}, "mending_moss": {"price": 9, "stock": 2}}},
	"ridge_fork": {"kind": "waystation", "rumor": "{i:w_cold} The {i:mountain} pass is cold. Bring a {k:snow|Snow} Trailomon.",
		"stall": {"water": {"price": 4, "stock": 4}, "spare_axle": {"price": 15, "stock": 1}, "swiftwind_feather": {"price": 11, "stock": 1}}},
	"lantern_hollow": {"kind": "village", "rumor": "{i:swamp} Marsh lights lead you true. {c:mirelamp} knows the way.",
		"stall": {"food": {"price": 4, "stock": 5}, "light_dust": {"price": 18, "stock": 1}, "smoke_pouch": {"price": 9, "stock": 2}}},
	"rail_bridge": {"kind": "post", "rumor": "{i:ev_shrine} Humming stones give {i:light_dust} dust for a gift of {i:food}.",
		"stall": {"food": {"price": 5, "stock": 5}, "water": {"price": 3, "stock": 5}, "spare_canvas": {"price": 9, "stock": 1}, "spare_harness": {"price": 8, "stock": 1},
			"stoneskin_tea": {"price": 10, "stock": 2}, "technique": {"price": 24, "stock": 1}}},
	"cogspire": {"kind": "ruins", "rumor": "{i:risk} Something huge guards the last stretch to Westwatch.",
		"stall": {"dark_dust": {"price": 16, "stock": 1}, "bitter_ash": {"price": 9, "stock": 2}, "rally_horn": {"price": 12, "stock": 1}}},
	"thornmarsh": {"kind": "stilts", "rumor": "{i:risk} The Hollow Stag's pack waits on the road to Westwatch.",
		"stall": {"water": {"price": 3, "stock": 6}, "food": {"price": 5, "stock": 4}, "medicine": {"price": 7, "stock": 2},
			"mending_moss": {"price": 8, "stock": 2}}},
	"westwatch": {"kind": "town", "rumor": "", "stall": {}},
}


static func stop(junction: String) -> Dictionary:
	return STOPS.get(junction, {"kind": "waystation", "rumor": "", "stall": {}})


static func kind(junction: String) -> Dictionary:
	return KINDS[stop(junction)["kind"]]


static func stall(junction: String) -> Dictionary:
	return stop(junction)["stall"]


## Effects of buying one lot (battle items give one of that item).
static func goods_fx(good: String) -> Dictionary:
	if GOODS.has(good):
		return GOODS[good]["fx"]
	return {"item": good}


static func good_name(good: String) -> String:
	if GOODS.has(good):
		return GOODS[good]["name"]
	return BattleItems.item_name(good) if BattleItems.has(good) else good


static func good_icon(good: String) -> String:
	if GOODS.has(good):
		return GOODS[good]["icon"]
	return good

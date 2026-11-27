class_name Inventor
extends RefCounted
## Pip Gasket, a travelling inventor who sets up shop at one stop each crossing and bolts
## permanent upgrades onto the wagon. Upgrades stay with the caravan from crossing to crossing.

const NAME := "Pip Gasket"
const TRADE := "travelling inventor"
## Stop kinds Pip will set up in (never the start or the goal, nor anywhere on the map's edges).
const KINDS := ["town", "post", "village", "waystation", "stilts"]

const UPGRADES := {
	"spring_wheels": {"name": "Spring wheels", "price": 45, "icon": "up_spring_wheels",
		"text": "Coiled brass springs on every wheel: the wagon wears 20% slower."},
	"cargo_rack": {"name": "Cargo rack", "price": 40, "icon": "up_cargo_rack",
		"text": "A roof rack and side baskets: +40 room in the wagon."},
	"dew_still": {"name": "Dew still", "price": 35, "icon": "up_dew_still",
		"text": "A copper still that drips all night: +2 water every travel day (if there's room)."},
	"float_tanks": {"name": "Float tanks", "price": 50, "icon": "up_float_tanks",
		"text": "Sealed barrels under the floor: +3 on every Float check, rivers and rapids too."},
	"brass_horn": {"name": "Brass horn", "price": 30, "icon": "up_brass_horn",
		"text": "A great honking horn: wild packs jump you 40% less often."},
	"lantern_mast": {"name": "Lantern mast", "price": 35, "icon": "up_lantern_mast",
		"text": "A tall mast with a bright lamp: see one stop further through the fog."},
}
const WEAR_MULT := 0.8
const RACK_ROOM := 40.0
const STILL_WATER := 2.0
const FLOAT_BONUS := 3
const HORN_MULT := 0.6

const HELLOS := [
	"Mind the steam! Everything here is very nearly safe.",
	"Ah, a customer! Or a creditor. Customer? Good.",
	"Your wheels are crying out for springs. I can hear them.",
	"I made a horn so loud it scared off a thunderstorm. Want one?",
	"Back again! The wagon remembers me, you know.",
]


static func info(id: String) -> Dictionary:
	return UPGRADES.get(id, {})


static func is_upgrade(id: String) -> bool:
	return UPGRADES.has(id)


## Prices creep up a little each crossing.
static func price(id: String, crossing_no: int) -> int:
	return int(info(id).get("price", 0)) + 5 * maxi(0, crossing_no - 1)


static func hello(crossing_no: int) -> String:
	return HELLOS[(maxi(1, crossing_no) - 1) % HELLOS.size()]


## Where Pip's workshop is this crossing ("" if nowhere fits).
static func workshop(map: WorldMap, crossing_no: int) -> String:
	if map == null:
		return ""
	var spots: Array = []
	for id in map.junctions:
		var layer := int(map.junctions[id].get("layer", 0))
		var edge := not map.is_test and (layer == 0 or layer == WorldMap.LAYERS - 1)
		if id != map.start and id != map.goal and not edge and KINDS.has(String(map.junctions[id].get("kind", ""))):
			spots.append(id)
	if spots.is_empty():
		return ""
	spots.sort()
	return spots[absi(map.seed + crossing_no * 7919) % spots.size()]

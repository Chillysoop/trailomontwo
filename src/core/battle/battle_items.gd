class_name BattleItems
extends RefCounted
## Battle items: consumables you put in up to 3 slots before a fight. Each gives the whole
## team a boost for that battle (or hinders the foes), and is used up when the fight ends.
##
## Effect keys (all on the player's team unless they start with foe_):
##   shield_maxhp: start with Shield = N% of max HP
##   atk_pct / def_pct: +N% Attack / Defense for the fight
##   haste: [pct, secs]     ult_pct: start with N% ultimate charge
##   regen: [pct, every]    heal N% of max HP every `every` seconds
##   foe_slow / foe_weaken: [pct, secs] on every foe at the start
##   foe_atk_pct: every foe has -N% Attack for the fight

const SLOTS := 3

const ITEMS := {
	"ironbark_salve": {"name": "Ironbark Salve", "shield_maxhp": 15},
	"ember_draught": {"name": "Ember Draught", "atk_pct": 15},
	"stoneskin_tea": {"name": "Stoneskin Tea", "def_pct": 25},
	"swiftwind_feather": {"name": "Swiftwind Feather", "haste": [30, 12]},
	"rally_horn": {"name": "Rally Horn", "ult_pct": 50},
	"mending_moss": {"name": "Mending Moss", "regen": [3, 5]},
	"smoke_pouch": {"name": "Smoke Pouch", "foe_slow": [30, 10]},
	"bitter_ash": {"name": "Bitter Ash", "foe_atk_pct": 12},
}


static func has(id: String) -> bool:
	return ITEMS.has(id)


static func item_name(id: String) -> String:
	return ITEMS[id]["name"]


## What the item does, with keywords for hover popups.
static func desc(id: String) -> String:
	var it: Dictionary = ITEMS[id]
	if it.has("shield_maxhp"):
		return "Your team starts the fight with {k:shield|Shield} equal to %d%% of their max HP." % it["shield_maxhp"]
	if it.has("atk_pct"):
		return "Your team has +%d%% {k:atk|Attack} for the whole fight." % it["atk_pct"]
	if it.has("def_pct"):
		return "Your team has +%d%% {k:def|Defense} for the whole fight." % it["def_pct"]
	if it.has("haste"):
		return "Your team has {k:haste|Haste} %d%% for the first %ds." % it["haste"]
	if it.has("ult_pct"):
		return "Your team starts with %d%% of their {k:ultimate|ultimate} charged." % it["ult_pct"]
	if it.has("regen"):
		return "Every %ds, your team heals %d%% of their max HP." % [it["regen"][1], it["regen"][0]]
	if it.has("foe_slow"):
		return "Every foe is {k:slow|Slowed} %d%% for the first %ds." % it["foe_slow"]
	if it.has("foe_atk_pct"):
		return "Every foe has -%d%% {k:atk|Attack} for the whole fight." % it["foe_atk_pct"]
	if it.has("foe_weaken"):
		return "Every foe is {k:weaken|Weakened} %d%% for the first %ds." % it["foe_weaken"]
	return ""


## Tooltip: icon, name, what it does.
static func tip(id: String, count := -1) -> String:
	var t := "{i:%s} [b]%s[/b]" % [id, item_name(id)]
	if count >= 0:
		t += "  [color=#%s]x%d[/color]" % [CreatureCard.MUTED, count]
	return t + "\n" + desc(id) + "\n[color=#%s]Used up when the fight ends.[/color]" % CreatureCard.MUTED

class_name Backgrounds
extends RefCounted
## Who leads the caravan: picked once, after the first partner, and kept for the whole run.
## Each trail boss has a small edge that changes how the trail plays.

const ALL := {
	"tinker": {"name": "Tinker", "icon": "bg_tinker",
		"line": "Grew up in a wheelwright's shop. Can fix anything with wire and spit.",
		"perks": ["The wagon wears 10% slower", "Every jury-rig counts as skilled", "Starts with a spare axle and harness"]},
	"herbalist": {"name": "Herbalist", "icon": "bg_herbalist",
		"line": "Knows every leaf between here and the frost, and what it does to you.",
		"perks": ["+2 on Forage and Heal checks", "Knows every wild plant", "Ailments strike a third less often"]},
	"ranger": {"name": "Ranger", "icon": "bg_ranger",
		"line": "Has walked the wilds alone. Reads tracks, weather and herds.",
		"perks": ["Hunts bring 40% more food", "+2 on Scout checks", "Sees one stop further through the fog"]},
	"merchant": {"name": "Merchant", "icon": "bg_merchant",
		"line": "Sold lamp oil in every town on the road. Knows what things are worth.",
		"perks": ["+40 coins to start", "Cargo and delivery jobs pay 25% more", "Haggles: every barter throws in 10 coins"]},
}
const ORDER := ["tinker", "herbalist", "ranger", "merchant"]
const TINKER_WEAR := 0.9
const CHECK_BONUS := 2
const HERBALIST_AILMENT := 0.67
const RANGER_HUNT := 1.4
const MERCHANT_COINS := 40
const MERCHANT_PAY := 1.25


static func info(id: String) -> Dictionary:
	return ALL.get(id, {})


static func perk_text(id: String) -> String:
	return "\n".join((info(id).get("perks", []) as Array).map(func(p): return "• " + String(p)))

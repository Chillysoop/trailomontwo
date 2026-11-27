class_name Ailments
extends RefCounted
## Odd naturepunk ailments that strike one Trailomon on the road. Each has one clear effect
## while it lasts, and an event card where you play trail doctor:
##   a Heal Trailomon tends it (Heal check), a herbal remedy (Forage check),
##   a pinch of Light dust (sure cure), rest it a day (sure cure, costs a day),
##   or press on and hope (it runs its course, and might spread to another).

const KINDS := {
	"rust_itch": {"name": "Rust itch", "icon": "rust_itch", "effect": "pulls at half strength",
		"text": "%s scratches at rusty flakes on its hide and can't settle into the harness."},
	"moss_lung": {"name": "Moss lung", "icon": "moss_lung", "effect": "tires fast (+8 tiredness a day)",
		"text": "%s wheezes. Something green is growing in there."},
	"spore_sneeze": {"name": "Spore sneezes", "icon": "spore_sneeze", "effect": "can't help with trail jobs",
		"text": "%s sneezes clouds of orange spores and can't keep its mind on anything."},
	"bramble_burrs": {"name": "Bramble burrs", "icon": "bramble_burrs", "effect": "loses health every day",
		"text": "%s is full of burrs that dig in deeper with every step."},
}
## Untreated, an ailment lasts this many days. Pressing on: this chance it lasts longer and
## this chance it jumps to another Trailomon.
const DAYS := 4
const WORSE_DAYS := 3
const SPREAD_CHANCE := 0.3
## Daily chance on the road (more in bad conditions; see Expedition._ailment_chance).
const DAILY_CHANCE := 0.035
const MOSS_FATIGUE := 8.0
const BURR_HP := 0.06
const HEAL_DIFFICULTY := 4
const FORAGE_DIFFICULTY := 6


static func info(kind: String) -> Dictionary:
	return KINDS.get(kind, {})


## The doctor's card for `who` catching `kind`.
static func make(kind: String, who: String, light_dust: int, shown := "") -> Dictionary:
	var k := info(kind)
	var nm := shown if shown != "" else String(Species.info(who)["name"])
	var choices: Array = [
		{"label": "A healer tends it", "cap": "heal", "difficulty": HEAL_DIFFICULTY,
			"success": {"text": "Gentle hands and a warm poultice. %s is right again." % nm, "ail_cure": who},
			"mixed": {"text": "It helps a little. Two more days of it.", "ail_days": {who: 2}},
			"failure": {"text": "Nothing seems to work.", "ail_days": {who: DAYS}}},
		{"label": "Brew a herbal remedy", "cap": "forage", "difficulty": FORAGE_DIFFICULTY,
			"success": {"text": "The right leaves, the right roots. %s perks up." % nm, "ail_cure": who},
			"mixed": {"text": "Bitter, and only half works.", "ail_days": {who: 2}},
			"failure": {"text": "Wrong leaves. Now its stomach hurts too.", "ail_days": {who: DAYS + 1}}},
	]
	if light_dust > 0:
		choices.append({"label": "A pinch of Light dust", "cost": {"light_dust": -1}, "safe_paid": true,
			"success": {"text": "The dust settles on %s and the ailment fades like mist." % nm, "ail_cure": who}})
	choices.append({"label": "Rest it in the wagon", "success": {"text": "A day off the road, curled up in the wagon. Cured.", "days": 1, "ail_cure": who}})
	choices.append({"label": "Press on and hope", "success": {"text": "You keep moving. It'll pass. Probably.", "ail_days": {who: DAYS}, "ail_risk": who}})
	return {"id": "ailment", "kind": "hazard", "icon": String(k["icon"]), "title": "%s: %s" % [k["name"], nm], "patient": who, "ailment": kind,
		"text": (String(k["text"]) % nm) + " While it lasts, it %s." % k["effect"], "choices": choices}

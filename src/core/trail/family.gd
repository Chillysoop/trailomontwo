class_name Family
extends RefCounted
## The Fernwicks: Bram, Ottilie and their daughter Wren, heading west in a wagon even older
## than yours. You cross paths once every crossing. Each meeting is the next beat of their
## story, and how you treated them before (trust) shapes how it goes.

const NAME := "the Fernwicks"
## Daily chance on the road, once per crossing, from the second road on.
const DAILY_CHANCE := 0.12
const MAX_TRUST := 5


## The card for the next beat of their story.
static func beat(stage: int, trust: int, crossing_no: int) -> Dictionary:
	var again := " You met them on an earlier crossing." if stage > 0 and crossing_no > 1 else ""
	var e: Dictionary
	match mini(stage, 4):
		0:
			e = {"title": "A wagon in the mud",
				"text": "A family's wagon sits axle-deep in mud. Bram Fernwick waves his hat at you; his daughter Wren pushes with all her might.",
				"choices": [
					{"label": "Help pull them out", "cap": "strength", "difficulty": 4,
						"success": {"text": "One heave and they're free. Ottilie presses a jar of honey on you.", "trust": 1, "food": 8},
						"mixed": {"text": "It takes all afternoon, but they're out. They thank you warmly.", "trust": 1, "fatigue": 10},
						"failure": {"text": "Your Trailomon strain and slip. Bram says he'll dig out himself. He's sore about it.", "fatigue": 15}},
					{"label": "Lend them a hand with ropes", "cost": {"food": -5},
						"success": {"text": "Ropes, a plank and a shared lunch. They're out by evening.", "trust": 1}},
					{"label": "Wave and pass", "success": {"text": "You leave them to it. Wren watches you go."}},
				]}
		1:
			e = {"title": "The Fernwicks again",
				"text": "The Fernwicks camp by the road, their water barrel split." + again + " Ottilie asks if you can spare some.",
				"choices": [
					{"label": "Fill their jugs", "cost": {"water": -15}, "safe_paid": true,
						"success": {"text": "Wren gives you a lure she made from reeds and a shiny button.", "trust": 1, "lures": 1}},
					{"label": "Mend their barrel", "cap": "steady", "difficulty": 5,
						"success": {"text": "Good as new. Bram swears you're a wizard with a hammer.", "trust": 1, "coins": 8},
						"mixed": {"text": "It leaks, but slowly. They're grateful.", "trust": 1},
						"failure": {"text": "The hoop snaps. Ottilie sighs and thanks you anyway."}},
					{"label": "You need every drop", "success": {"text": "Ottilie nods. 'We'll manage.' They don't look sure.", "trust": -1}},
				]}
		2:
			e = {"title": "Wren is sick",
				"text": "Bram runs up the road to meet you. Wren has a fever and they've nothing left to treat it." + again,
				"choices": [
					{"label": "A healer looks at her", "cap": "heal", "difficulty": 5,
						"success": {"text": "By morning Wren is sitting up, asking for pancakes.", "trust": 2, "xp": 15},
						"mixed": {"text": "The fever breaks slowly. You stay with them a day.", "trust": 1, "days": 1},
						"failure": {"text": "Nothing helps. They turn back to the last town.", "trust": 0}},
					{"label": "A pinch of Light dust", "cost": {"light_dust": -1}, "safe_paid": true,
						"success": {"text": "The fever melts away. Ottilie cries and hugs everyone, even the Trailomon.", "trust": 2}},
					{"label": "Wish them well", "success": {"text": "You give directions to the nearest town and roll on.", "trust": -1}},
				]}
		3:
			e = {"title": "A fire with friends",
				"text": "The Fernwicks are camped ahead and wave you in." + again + " Wren wants to show your Trailomon her drawings of them.",
				"choices": [
					{"label": "Share their fire", "success": {"text": "Stew, stories and a song. Everyone sleeps well.", "trust": 1, "health": 10, "fatigue": -20}},
					{"label": "Swap supplies", "cost": {"food": -10}, "safe_paid": true,
						"success": {"text": "Bram has a spare part he'll never use. You give him some food for it.", "trust": 1, "spare": "any"}},
				]}
		_:
			var gift := trust >= 3
			e = {"title": "Old friends on the road",
				"text": "The Fernwicks! They've come this way again, and Wren has grown a head taller." + (" They've been saving something for you." if gift else " They wave, a little shy."),
				"choices": [
					{"label": "Catch up over supper", "success": (
						{"text": "Bram gives you a battle charm he won at a fair, and Ottilie a purse of coins.", "item": "random", "coins": 15, "health": 10, "trust": 1}
						if gift else {"text": "A pleasant supper. They seem to warm to you.", "health": 5, "trust": 1})},
				]}
	e["id"] = "family"
	e["kind"] = "travelers"
	e["icon"] = "family"
	e["stage"] = stage
	return e

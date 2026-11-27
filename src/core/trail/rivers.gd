class_name Rivers
extends RefCounted
## Big river crossings: every River road starts with one, the wagon's whole load at stake.
##
## The river has a depth (1 shallow, 2 deep, 3 in flood, 4 a torrent), read from the road's risk
## and the last day's weather. Choices:
##   Ford it: the haulers drag the wagon through. Strength check, harder the deeper it is.
##   Float it: seal the wagon and float it over. Float check.
##   Ice bridge: only on cold days. A Cold Trailomon freezes a path across.
##   Ferry: where people live by the water. Costs coins, always safe.
##   Wait a day: the water drops a level, then decide again. A shallow river
##   can always be waded slowly instead.
## Other Trailomon help ("assist"): a Scout finds a shallower line, a Steady one keeps the wagon
## upright on the float, a strong second hauler leans in on the ford. Each adds to the check.

const NAMES := ["shallow", "deep", "in flood", "a torrent"]
## How much an assisting Trailomon adds to the check score, and the job rank it needs.
const ASSIST_RANK := 2


static func depth_for(risk: int, weather: String) -> int:
	var d := clampi(risk, 1, 3)
	if weather == "rain" or weather == "storm":
		d += 1
	if weather == "cold" or weather == "heat":
		d -= 1
	return clampi(d, 1, 4)


## The crossing as an event card (Expedition.resolve_event plays it like any other event).
static func make(depth: int, ferry: bool, cold: bool, crossing_no: int) -> Dictionary:
	var d := clampi(depth, 1, 4)
	var lose_food := -8 * d
	var choices: Array = [
		{"label": "Ford it", "cap": "strength", "difficulty": 4 + 2 * d, "assist": {"scout": 3, "guard": 2},
			"success": {"text": "The haulers plough straight across."},
			"mixed": {"text": "Across, soaked and spent.", "fatigue": 12, "food": lose_food / 2},
			"failure": {"text": "Swept sideways. Crates bob away downstream.", "lose_cargo": 1, "food": lose_food, "fatigue": 20,
				"break": "canopy" if d >= 3 else ""}},
		{"label": "Float it over", "cap": "float", "difficulty": 3 + 2 * d, "assist": {"scout": 3, "steady": 2},
			"success": {"text": "Sealed tight, the wagon bobs across like a boat."},
			"mixed": {"text": "Water seeps in. Some food is ruined.", "food": lose_food / 2, "wear": 6},
			"failure": {"text": "The wagon rolls. Everything is soaked.", "lose_cargo": 1, "food": lose_food, "water": -10,
				"integrity": -8, "break": "canopy"}},
	]
	if cold:
		choices.append({"label": "Freeze a bridge", "cap": "cold", "difficulty": 3 + d, "assist": {"steady": 2},
			"success": {"text": "Ice spreads from bank to bank. You walk across."},
			"mixed": {"text": "The ice groans but holds.", "wear": 8},
			"failure": {"text": "The ice cracks under the back wheels.", "food": lose_food / 2, "integrity": -10, "break": "axle"}})
	if ferry:
		choices.append({"label": "Take the ferry", "cost": {"coins": -(4 + 3 * d + crossing_no)}, "safe_paid": true,
			"success": {"text": "The ferry hauls you over, dry as a bone."}})
	if d <= 1:
		# Shallow: no need to wait, just wade across slowly.
		choices.append({"label": "Wade across slowly", "success": {"text": "Knee-deep and careful. A few splashes.", "wear": 3}})
	else:
		choices.append({"label": "Wait a day", "success": {"text": "You camp on the bank and watch the water.", "days": 1, "river_wait": true}})
	return {"id": "river", "kind": "hazard", "title": "River crossing", "terrains": ["River"], "min_risk": 1, "depth": d,
		"text": "The river is %s. Everything you own is in the wagon." % NAMES[d - 1], "choices": choices}

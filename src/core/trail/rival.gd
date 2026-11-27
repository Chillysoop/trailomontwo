class_name Rival
extends RefCounted
## Rook Calloway: a rival caravan that set out the same day as you, with the starter that has
## the edge on yours. Rook turns up once a crossing, halfway along, and wants a battle.
## Win and you take the purse; lose and Rook pockets your bet (no harm to the wagon).
## Rook's team grows and evolves crossing by crossing, a step behind or ahead of yours.

const NAME := "Rook Calloway"
## Rook's other Trailomon, in the order they join (first forms; they evolve with the crossings).
const MATES := ["thornfang", "inkhoot", "cairnram", "plateflit", "frostsnip", "gillhorn"]
const PURSE := 12
const PURSE_PER_CROSSING := 4
const BET := 8
## Rook turns up on a road into this band of map columns (the middle of the crossing).
const LAYERS_FROM := 5
const LAYERS_TO := 8

const HELLO := [
	"\"Still crawling along? My team's been waiting all morning.\"",
	"\"You again! Good. I've been practising.\"",
	"\"Look who finally caught up. Ready to lose?\"",
	"\"Westwatch is mine this time. Battle first, though.\"",
]


## The starter Rook picks: the one with the edge on yours.
static func starter_for(mine: String) -> String:
	for s in Expedition.STARTERS:
		if s != mine and not CombatData.standing(s, [mine])["up"].is_empty():
			return s
	for s in Expedition.STARTERS:
		if s != mine:
			return s
	return Expedition.STARTERS[0]


## A first form grown to the stage that fits the crossing.
static func grown(id: String, crossing_no: int) -> String:
	var steps := 0 if crossing_no <= 2 else (1 if crossing_no <= 5 else 2)
	var out := id
	for i in steps:
		var next := Species.evolutions(out)
		if next.is_empty():
			break
		out = next[0]
	return out


## Rook's pack this crossing: the starter in front, mates around it, one more each crossing.
static func pack(mine: String, crossing_no: int) -> Dictionary:
	var ids: Array[String] = [grown(starter_for(mine), crossing_no)]
	for m in MATES.slice(0, clampi(crossing_no, 1, 5)):
		ids.append(grown(String(m), crossing_no))
	var front := ["", ids[0], ""]
	var back := ["", "", ""]
	var order := [[0, 0], [0, 2], [1, 1], [1, 0], [1, 2]]
	for i in range(1, ids.size()):
		var at: Array = order[i - 1]
		if at[0] == 0:
			front[at[1]] = ids[i]
		else:
			back[at[1]] = ids[i]
	return {"id": "trainer_rival", "title": NAME + "'s team", "terrains": [], "min_risk": 1,
		"text": "Rook whistles, and the team falls into line.", "front": front, "back": back}


static func event(crossing_no: int, record: Dictionary) -> Dictionary:
	var hello: String = HELLO[(crossing_no + int(record.get("wins", 0))) % HELLO.size()]
	var purse := PURSE + PURSE_PER_CROSSING * crossing_no
	return {"id": "rival", "kind": "travelers", "title": "Rook's caravan", "terrains": [], "min_risk": 1,
		"text": "A red-wheeled wagon pulls alongside. %s %s" % [NAME, hello],
		"choices": [
			{"label": "Battle Rook (bet %d coins)" % BET, "cost": {"coins": -BET},
				"success": {"text": "\"Winner takes the purse!\"", "battle": "rival", "bounty": purse + BET}},
			{"label": "Race Rook to the next stop", "cap": "scout", "difficulty": 7,
				"success": {"text": "You find a cut-through and leave Rook in the dust.", "progress": 0.5},
				"mixed": {"text": "Neck and neck. Your haulers are spent.", "fatigue": 10},
				"failure": {"text": "Rook's wagon cuts you off. A wheel bangs a rock.", "wear": 8}},
			{"label": "Swap stories and move on", "success": {"text": "\"Next time,\" Rook says. \"Next time for sure.\""}},
		]}

class_name Balance
extends RefCounted
## Balance checks that scale to hundreds of Trailomon (used by tests and tools/sim/roster_sim.gd).
##   power(id)       a rough strength score from stats: sqrt(toughness x damage per second)
##   POWER_BAND      the score range for each rarity, at stage 1 (later stages may sit higher)
##   round_robin()   win rates of every species against its own rarity
##   kit_keywords()  the habitat keywords a data-driven kit uses, read from its move data

## Score bands per rarity. Later evolution stages may reach STAGE_STEP higher per stage.
const POWER_BAND := {"common": [62.0, 88.0], "rare": [75.0, 105.0], "legendary": [92.0, 130.0]}
const STAGE_STEP := 0.15
## A healthy round-robin win rate.
const WIN_BAND := [30, 70]
## Speed (seconds between basic attacks) every kit must sit inside, so its ultimate comes
## round every 9 to 15 seconds or so.
const SPD_RANGE := [1.2, 2.5]

## Keywords that belong to one habitat and must not appear in another habitat's kit.
## Shield and wash are shared (Guards everywhere shield themselves).
const SIGNATURE := {
	"thorns": "Forest", "taunt": "Forest",
	"heal": "River", "cleanse": "River", "drain": "River",
	"poison": "Swamp", "weaken": "Swamp",
	"pierce": "Mountain", "stagger": "Mountain",
	"slow": "Snow", "haste": "Snow",
	"reach": "Jungle", "dodge": "Jungle",
}


static func power(id: String) -> float:
	var k: Dictionary = CombatData.KITS[id]
	var tough := float(k["hp"]) * (1.0 + float(k["def"]) / 100.0)
	var dmg := float(k["atk"]) / float(k["spd"])
	return sqrt(tough * dmg)


static func power_band(id: String) -> Array:
	var band: Array = POWER_BAND.get(Species.rarity(id), [0.0, 9999.0])
	return [band[0], band[1] * (1.0 + STAGE_STEP * (Species.stage(id) - 1))]


static func in_band(rate: float) -> bool:
	return rate * 100.0 >= WIN_BAND[0] and rate * 100.0 <= WIN_BAND[1]


## Keywords a data-driven kit uses (from MovePool move data). Legacy moves give none.
static func kit_keywords(id: String) -> Array[String]:
	var out: Array[String] = []
	for mid in CombatData.kit_moves(id):
		if not MovePool.has(mid):
			continue
		for k in move_keywords(MovePool.MOVES[mid]):
			if not out.has(k):
				out.append(k)
	return out


static func move_keywords(m: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var add := func(k: String) -> void:
		if not out.has(k):
			out.append(k)
	for k in ["poison", "weaken", "slow", "stagger", "wash", "reach", "taunt"]:
		if m.has(k):
			add.call(k)
	if m.get("pierce", false):
		add.call("pierce")
	var me: Dictionary = m.get("self", {})
	var ally: Dictionary = m.get("ally", {})
	var team: Dictionary = m.get("team", {})
	if me.has("shield_atk") or me.has("shield_def") or team.has("shield_def") or team.has("shield_flat") or ally.has("shield_atk"):
		add.call("shield")
	if me.get("dodge", false):
		add.call("dodge")
	if ally.has("heal_atk") or team.has("heal_maxhp"):
		add.call("heal")
	if team.get("cleanse", false):
		add.call("cleanse")
	if team.has("haste"):
		add.call("haste")
	match String(m.get("kind", "")):
		"thorns": add.call("thorns")
		"drain": add.call("drain")
		"start_shield": add.call("shield")
		"every":
			if m.has("shield_def"):
				add.call("shield")
			if m.has("ally_heal_atk"):
				add.call("heal")
			if m.has("poison_all"):
				add.call("poison")
			if m.has("team_haste"):
				add.call("haste")
	return out


## Problems with a kit under the habitat keyword rule ([] = fine).
static func keyword_problems(id: String) -> Array[String]:
	var out: Array[String] = []
	var ks := kit_keywords(id)
	if ks.is_empty():
		return out
	var type: String = Species.info(id)["type"]
	var own: Array = CombatData.HABITATS[type]["owns"]
	if not ks.any(func(k): return own.has(k)):
		out.append("%s uses none of %s's keywords %s" % [id, type, own])
	for k in ks:
		if SIGNATURE.has(k) and SIGNATURE[k] != type:
			out.append("%s (%s) uses %s's keyword '%s'" % [id, type, SIGNATURE[k], k])
	return out


## Win rate of each wild species of a rarity against the others of that rarity: three of
## a kind against three of a kind, from both sides, over `seeds` seeds.
static func round_robin(rarity: String, seeds := 3, ids: Array = []) -> Dictionary:
	if ids.is_empty():
		for id in Species.DATA:
			if Species.rarity(id) == rarity:
				ids.append(id)
	var wins := {}
	var games := {}
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			for s in seeds:
				for flip in 2:
					var a: String = ids[i] if flip == 0 else ids[j]
					var b: String = ids[j] if flip == 0 else ids[i]
					var winner := duel(a, b, s)
					for id in [a, b]:
						games[id] = int(games.get(id, 0)) + 1
					if winner != "":
						wins[winner] = float(wins.get(winner, 0.0)) + 1.0
					else:
						wins[a] = float(wins.get(a, 0.0)) + 0.5
						wins[b] = float(wins.get(b, 0.0)) + 0.5
	var out := {}
	for id in ids:
		out[id] = float(wins.get(id, 0.0)) / maxf(1.0, float(games.get(id, 0)))
	return out


## Three `a` against three `b` in the front row. Returns the winner, or "" for a draw.
static func duel(a: String, b: String, seed_value: int) -> String:
	var cells := {}
	for lane in 3:
		cells[Vector2i(0, lane)] = a
	var bt := Battle.create({"slots": cells}, {"front": [b, b, b], "back": ["", "", ""]}, {"seed": seed_value})
	bt.run_to_end()
	match bt.outcome:
		Battle.Outcome.VICTORY: return a
		Battle.Outcome.DEFEAT: return b
	return ""

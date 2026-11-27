class_name Folk
extends RefCounted
## The people you meet at a stop: two locals with a piece of trail advice each. They talk
## about what's really out there (the guardian, the frost, the roads, rivers, Pip's workshop),
## but folk talk is folk talk: now and then a tip is plain wrong.

const PEOPLE := [
	["Old Marrow", "a retired hauler"], ["Tansy Brook", "a herb seller"], ["Cobb Ashdown", "a wheelwright"],
	["Mother Quill", "a letter writer"], ["Jory Fenn", "a ferry hand"], ["Hessa Vane", "a weather watcher"],
	["Little Tam", "a stable kid"], ["Brother Oakes", "a wandering monk"], ["Dilly Sprocket", "a tinker"],
	["Ruth Ironside", "a trail scout"], ["Silas Crow", "a trapper"], ["Nell Haskett", "an innkeeper"],
	["Garrow Pike", "a river pilot"], ["Ma Thistle", "a cook"], ["Edgar Plumb", "a lost surveyor"],
	["Ivy Gale", "a mail rider"], ["Fergus Lamb", "a shepherd"], ["Opal Rusk", "a fortune teller"],
]
## Chance any one tip is wrong.
const WRONG_CHANCE := 0.25
const FROST_OFF := 6


## Two locals for this stop: [{"name", "trade", "line", "topic", "true"}]. Seeded per stop and
## crossing, so the same folk say the same thing if you come back.
static func at_stop(e: Expedition) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = int(e.stop().get("rumor_seed", 0)) + e.crossing_no * 131 + 17
	var topics := _topics(e, r)
	var people: Array = PEOPLE.duplicate()
	var out: Array = []
	for i in 2:
		if people.is_empty():
			break
		var p: Array = people.pop_at(r.randi_range(0, people.size() - 1))
		var tip: Dictionary = topics.pop_at(r.randi_range(0, topics.size() - 1)) if not topics.is_empty() else _small_talk(r)
		tip["name"] = p[0]
		tip["trade"] = p[1]
		out.append(tip)
	return out


static func _topics(e: Expedition, r: RandomNumberGenerator) -> Array:
	var out: Array = []
	var g := _guardian_tip(e, r)
	if not g.is_empty():
		out.append(g)
	if e.frost_day > 0 and e.season() != "frost":
		var wrong := r.randf() < WRONG_CHANCE
		var d := e.frost_day + (r.randi_range(4, FROST_OFF) * (1 if r.randf() < 0.5 else -1) if wrong else 0)
		out.append({"topic": "frost", "true": not wrong, "icon": "w_cold",
			"line": "My knees say the frost comes by day %d. My knees are never wrong." % maxi(e.day + 1, d)})
	var exits: Array = e.map.exits(e.at)
	if exits.size() >= 2:
		var worst: Dictionary = exits[0]
		var best: Dictionary = exits[0]
		for s in exits:
			if int(s["risk"]) > int(worst["risk"]):
				worst = s
			if int(s["risk"]) < int(best["risk"]):
				best = s
		if int(worst["risk"]) > int(best["risk"]):
			var wrong := r.randf() < WRONG_CHANCE
			var pick: Dictionary = best if wrong else worst
			out.append({"topic": "road", "true": not wrong, "icon": "risk", "to": String(pick["to"]),
				"line": "Stay off the road to %s. Wild packs, and worse." % e.map.name_of(String(pick["to"]))})
	for s in exits:
		if String(s.get("terrain", "")) == "River":
			var wrong := r.randf() < WRONG_CHANCE
			var high := int(s["risk"]) >= 2
			if wrong:
				high = not high
			out.append({"topic": "river", "true": not wrong, "icon": "river",
				"line": ("The river toward %s runs high and fast. Bring a Float Trailomon." if high else "The river toward %s is low. You could wade it.") % e.map.name_of(String(s["to"]))})
			break
	var shop := e.workshop()
	if shop != "" and shop != e.at:
		out.append({"topic": "inventor", "true": true, "icon": "inventor", "to": shop,
			"line": "%s, the inventor, has a workshop at %s this season. Clever hands." % [Inventor.NAME, e.map.name_of(shop)]})
	if e.map.kind_of(e.at) != "town" and e.map.kind_of(e.at) != "post":
		var wrong := r.randf() < WRONG_CHANCE
		var good := e.hunt_block() == ""
		if wrong:
			good = not good
		out.append({"topic": "hunt", "true": not wrong, "icon": "food",
			"line": "Plenty of game around here, if you're quick." if good else "Hunted clean out, round here. Don't waste your time."})
	return out


## The guardian waits on the last stretch, and a Trailomon of the type it fears hits it hardest.
static func _guardian_tip(e: Expedition, r: RandomNumberGenerator) -> Dictionary:
	var g: Dictionary = CombatData.guardian_for(e.crossing_no)
	var boss := String(g.get("boss", ""))
	if not Species.DATA.has(boss):
		return {}
	var t := String(Species.info(boss)["type"])
	var strong := ""
	for a in CombatData.CHART:
		if CombatData.CHART[a][0] == t:
			strong = a
	if strong == "":
		return {}
	var wrong := r.randf() < WRONG_CHANCE
	var said := strong
	if wrong:
		var others: Array = CombatData.CHART.keys().filter(func(x): return x != strong)
		said = others[r.randi_range(0, others.size() - 1)]
	return {"topic": "guardian", "true": not wrong, "icon": said.to_lower(), "type": said,
		"line": "%s fears %s Trailomon. Saw it run from one once." % [String(g["title"]), said]}


static func _small_talk(r: RandomNumberGenerator) -> Dictionary:
	var lines := [
		"Swamp air gives Trailomon moss lung. Keep them dry.",
		"Thin rations make for sick Trailomon. Feed them right.",
		"A tuned-up wagon never breaks when you need it. Mostly.",
		"Rest a day now and then. The road isn't going anywhere.",
	]
	return {"topic": "talk", "true": true, "icon": "ev_travelers", "line": lines[r.randi_range(0, lines.size() - 1)]}

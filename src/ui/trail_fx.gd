class_name TrailFx
extends RefCounted
## Rich markup for trail changes: icon chips like "{food}+6" in green or red, creature portraits,
## and the odds of a trail job check.

const GOOD := "9fe0a0"
const BAD := "ff8a7a"
const MID := "f0d27a"
const PORTRAIT_PX := 14


## A creature portrait that shows its card on hover.
static func portrait(id: String, px := PORTRAIT_PX) -> String:
	return "[url=c:%s][img=%dx%d]res://assets/creatures/%s.png[/img][/url]" % [id, px, px, id]


## One change as a chip. d: {"icon", "amount", "bad_up"?, "who"?, "label"?, "suffix"?}.
static func chip(d: Dictionary) -> String:
	var amount = d.get("amount", 0)
	var good := float(amount) > 0.0
	if d.get("bad_up", false):
		good = not good
	var col := GOOD if good else BAD
	var who := portrait(d["who"]) if d.has("who") else ""
	var num := ""
	if float(amount) != 0.0:
		num = ("+" if float(amount) > 0.0 else "") + (str(amount) if amount is int else "%.1f" % float(amount)) + String(d.get("suffix", ""))
	var label := String(d.get("label", ""))
	if d["icon"] == "ev_wildlife" or d["icon"] == "risk" or label == "cured":
		col = MID
	var core := "{i:%s}%s" % [d["icon"], num]
	if label != "" and label != "wear" and label != "team":
		core += " " + label
	elif label == "team":
		core = "{i:%s}%s team" % [d["icon"], num]
	return "%s[color=#%s]%s[/color]" % [who, col, core]


static func chips(deltas: Array) -> String:
	var parts: Array[String] = []
	for d in deltas:
		parts.append(chip(d))
	return "  ".join(parts)


## The cost of a choice (negative deltas) as red chips.
static func cost(c: Dictionary) -> String:
	var parts: Array[String] = []
	for k in c:
		if k == "give_item":
			parts.append("[color=#%s]{i:%s}-1[/color]" % [BAD, String(c[k])])
			continue
		var icon: String = {"food": "food", "water": "water", "coins": "coins"}.get(k, k)
		parts.append("[color=#%s]{i:%s}%d[/color]" % [BAD, icon, int(c[k])])
	return " ".join(parts)


## What a safe/paid choice gives (its success effects) as small chips, without rolling anything.
static func preview(fx: Dictionary) -> String:
	var parts: Array[String] = []
	var map := {"food": "food", "water": "water", "coins": "coins", "spare_axle": "spare_axle", "spare_harness": "spare_harness",
		"spare_canvas": "spare_canvas", "light_dust": "light_dust",
		"dark_dust": "dark_dust", "technique": "technique", "xp": "xp", "health": "health", "fatigue": "tired", "wear": "wagon"}
	for k in map:
		if fx.has(k):
			var v := int(fx[k])
			var good := v > 0 if not (k in ["fatigue", "wear"]) else v < 0
			parts.append("[color=#%s]{i:%s}%s%d[/color]" % [GOOD if good else BAD, map[k], "+" if v > 0 else "", v])
	if fx.has("days"):
		parts.append("[color=#%s]{i:day}+%d[/color]" % [BAD, int(fx["days"])])
	if fx.has("item"):
		parts.append("[color=#%s]{i:item_slot}+1[/color]" % GOOD)
	if fx.has("recruit"):
		parts.append("[color=#%s]{i:ev_wildlife}?[/color]" % MID)
	if fx.has("battle"):
		parts.append("[color=#%s]{i:risk} fight[/color]" % BAD)
	if fx.has("heal_team"):
		parts.append("[color=#%s]{i:hp}+%d%%[/color]" % [GOOD, roundi(float(fx["heal_team"]) * 100)])
	if fx.has("cure"):
		parts.append("[color=#%s]{i:fever} cured[/color]" % GOOD)
	if fx.has("progress"):
		var p := float(fx["progress"])
		parts.append("[color=#%s]{i:progress}%s%.1f[/color]" % [GOOD if p > 0 else BAD, "+" if p > 0 else "", p])
	return " ".join(parts)


## Odds as three colored numbers: success / mixed / bad.
static func odds(o: Dictionary) -> String:
	return "[color=#%s]%d[/color][color=#8a7f8c]/[/color][color=#%s]%d[/color][color=#8a7f8c]/[/color][color=#%s]%d%%[/color]" % [
		GOOD, o["success"], MID, o["mixed"], BAD, o["failure"]]

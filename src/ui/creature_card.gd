class_name CreatureCard
extends RefCounted
## Tooltip text for a creature: habitat, role, stats, abilities and (when known) its live state.
## Keyword explanations come after Tips.SIDE markers, so they open as their own small
## popups beside the card.

## Stat colors, matching the stat icons (red heart, orange sword, blue shield, green
## chevrons, purple impact).
const HP_COL := "ff7a7a"
const ATK_COL := "ffa04a"
const DEF_COL := "86b8ff"
const SPD_COL := "a6e36b"
const DPS_COL := "e08aff"
## Move-slot colors, matching the slot tags and the stats window (white, green, gold).
const SLOT_COL := {"basic": "e8e4f0", "passive": "8fdc7a", "ultimate": "ffd36b"}


## opts (all optional):
##   hp, max_hp: current health to show instead of the species' base health
##   scale: enemy strength multiplier
##   fatigue: hauling tiredness in percent
##   fighter: a live Fighter (shows its shield and statuses)
##   enemy: true for a foe
static func markup(id: String, opts := {}) -> String:
	var info := Species.info(id)
	var s := CombatData.stats(id)
	var type: String = info["type"]
	var hab := Glossary.habitat_id(type)
	var role: String = Glossary.ROLES.get(s["role"], "")
	var scale := float(opts.get("scale", 1.0))
	var lines: Array[String] = []
	var head := "[b]%s[/b]  {i:%s} {i:%s}" % [info["name"], hab, role] if role != "" else "[b]%s[/b]  {i:%s}" % [info["name"], hab]
	if opts.get("enemy", false):
		head += "  [color=#ff8a7a]foe[/color]"
	lines.append(head)
	lines.append("{k:%s|%s} {k:%s|%s}" % [hab, type, role, s["role"]] if role != "" else "{k:%s|%s}" % [hab, type])
	var f: Fighter = opts.get("fighter", null)
	var max_hp := float(opts.get("max_hp", CombatData.max_hp(id, scale)))
	var hp_text := "%d" % roundi(max_hp)
	if opts.has("hp"):
		hp_text = "%d/%d" % [roundi(float(opts["hp"])), roundi(max_hp)]
	var atk := float(s["atk"]) * scale
	var def := float(s["def"])
	var spd := float(s["spd"])
	if f != null:
		atk = f.atk
		def = f.def_now()
		spd = f.spd
	var dps := atk * float(CombatData.move(s["basic"]).get("pct", 100)) / 100.0 / spd
	lines.append("{i:hp}[color=#%s]%s[/color]  {i:atk}[color=#%s]%d[/color]  {i:def}[color=#%s]%d[/color]" % [
		HP_COL, hp_text, ATK_COL, roundi(atk), DEF_COL, roundi(def)])
	var ult_line := ""
	if f != null:
		ult_line = "  {i:ultimate}[color=#%s]%d%%[/color]" % [SLOT_COL["ultimate"], roundi(f.ult / CombatData.ULT_MAX * 100.0)]
	lines.append("{i:spd}[color=#%s]%.1fs[/color]  {i:dps}[color=#%s]%.1f[/color] DPS%s" % [SPD_COL, spd, DPS_COL, dps, ult_line])
	var keys: Array[String] = []
	for mid in CombatData.kit_moves(id):
		var mv := CombatData.move(mid)
		lines.append(move_header(mid))
		lines.append(CombatData.describe(mid, atk, def, max_hp))
		for k in CombatData.keywords(mid):
			if not keys.has(k) and Glossary.has(k) and not k in ["front_row", "back_row"]:
				keys.append(k)
	var chart: Array = CombatData.CHART[type]
	lines.append("Strong vs {i:%s}  weak vs {i:%s}" % [Glossary.habitat_id(chart[0]), Glossary.habitat_id(chart[1])])
	var states: Array[String] = []
	if f != null:
		if not f.alive():
			states.append("{ik:ko}")
		else:
			if f.shield > 0.5:
				states.append("{i:shield}%d" % roundi(f.shield))
			if f.poison_secs > 0.0:
				states.append("{i:poison}%ds" % ceili(f.poison_secs))
			if f.taunt > 0.0:
				states.append("{i:taunt}%ds" % ceili(f.taunt))
			for m in f.mods:
				states.append("{i:%s}%ds" % [m["kind"], ceili(float(m["secs"]))])
	if opts.has("hp") and float(opts["hp"]) <= 0.0 and f == null:
		states.append("{ik:ko}")
	if float(opts.get("fatigue", 0.0)) > 0.0:
		states.append("{i:tired}%d%%" % roundi(float(opts["fatigue"])))
	if not states.is_empty():
		lines.append("  ".join(states))
	var caps: Dictionary = info["capabilities"]
	if not caps.is_empty() and not opts.get("enemy", false):
		var parts: Array[String] = []
		for c in caps:
			parts.append("{k:cap_%s} %d" % [c, caps[c]])
		lines.append("Trail: " + ", ".join(parts))
	if int(info["hauling"]) > 0 and not opts.get("enemy", false):
		lines[lines.size() - 1] += "  {i:haul}%d" % int(info["hauling"])
	var out := "\n".join(lines)
	for k in keys:
		out += Tips.SIDE + keyword_box(k)
	return out


## "{tag} Move Name  Slot" line, colored by slot. Also used for memory slots later.
static func move_header(move_id: String) -> String:
	var mv := CombatData.move(move_id)
	var slot: String = mv["slot"]
	return "{i:%s} [b][color=#%s]%s[/color][/b]  [color=#8a8298]%s[/color]" % [
		slot, SLOT_COL[slot], mv["name"], Glossary.entry_name(slot)]


## A keyword's popup: icon, name and explanation.
static func keyword_box(k: String) -> String:
	var head := "{i:%s} " % k if Glossary.icon(k) != "" else ""
	return "%s[b]%s[/b]\n%s" % [head, Glossary.entry_name(k), Glossary.text(k)]


static func _is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

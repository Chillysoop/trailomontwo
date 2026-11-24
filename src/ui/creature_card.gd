class_name CreatureCard
extends RefCounted
## Tooltip text for a creature: habitat, role, stats, abilities and (when known) its live state.


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
	lines.append("[color=#9fe0a0]{k:hp|HP}[/color] %s   [color=#ff8a7a]{k:atk|ATK}[/color] %d   [color=#f0d27a]{k:spd|SPD}[/color] %.1fs" % [hp_text, roundi(atk), spd])
	var ult_line := ""
	if f != null:
		ult_line = "   {i:ultimate}%d%%" % roundi(f.ult / CombatData.ULT_MAX * 100.0)
	lines.append("[color=#ffb36b]{k:def|DEF}[/color] %d   [color=#e0a070]{k:dps|DPS}[/color] %.1f%s" % [roundi(def), dps, ult_line])
	var keys: Array[String] = []
	var slot_names := {"basic": "Basic attack", "passive": "Passive", "ultimate": "Ultimate"}
	for mid in CombatData.kit_moves(id):
		var mv := CombatData.move(mid)
		lines.append("[color=#f0d27a]— %s[/color]  [color=#b8b0c8]{k:%s|%s}[/color]" % [mv["name"], mv["slot"], slot_names[mv["slot"]]])
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
	for k in keys:
		lines.append("[color=#b8b0c8][b]%s:[/b] %s[/color]" % [Glossary.entry_name(k), Glossary.text(k)])
	return "\n".join(lines)


static func _is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

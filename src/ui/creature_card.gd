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
	var max_hp := float(opts.get("max_hp", float(s["hp"]) * CombatData.HP_SCALE * scale))
	var hp_text := "%d" % roundi(max_hp)
	if opts.has("hp"):
		hp_text = "%d/%d" % [roundi(float(opts["hp"])), roundi(max_hp)]
	var f: Fighter = opts.get("fighter", null)
	var might := float(s["might"]) * scale
	var spirit := float(s["spirit"]) * scale
	var guard := float(s["guard"])
	var tempo := float(s["tempo"])
	if f != null:
		might = f.might
		spirit = f.spirit
		guard = f.guard_now()
		tempo = f.tempo_now()
	lines.append("{i:hp}%s  {i:might}%d  {i:spirit}%d  {i:guard}%d  {i:tempo}%d" % [
		hp_text, roundi(might), roundi(spirit), roundi(guard), roundi(tempo)])
	var chart: Array = CombatData.CHART[type]
	lines.append("Strong vs {i:%s}  weak vs {i:%s}" % [Glossary.habitat_id(chart[0]), Glossary.habitat_id(chart[1])])
	for a in s["abilities"]:
		var ab := CombatData.ability(a)
		lines.append("[color=#f0d27a]%s[/color] {i:cooldown}%ds: %s" % [ab["name"], roundi(ab["cooldown"]), ability_text(a)])
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
	return "\n".join(lines)


## An ability's description with its key words turned into hoverable keywords.
static func ability_text(id: String) -> String:
	var ab := CombatData.ability(id)
	var d: String = ab["desc"]
	var swaps := [
		["Poisons", "{k:poison|Poisons}"], ["bleeds", "{k:poison|bleeds}"],
		["Shields", "{k:shield|Shields}"], ["shield", "{k:shield|shield}"], ["shielded", "{k:shield|shielded}"],
		["slows", "{k:slow|slows}"], ["guard", "{k:guard|guard}"],
		["attacks 30% faster", "{k:haste|attacks 30% faster}"],
		["second row", "{k:back_row}"], ["front row", "{k:front_row}"],
		["Draws every enemy's normal attacks", "{k:taunt|Draws every enemy's normal attacks}"],
	]
	# Replace whole words only, longest first, without touching text inside earlier swaps.
	var out := ""
	var i := 0
	while i < d.length():
		var hit := false
		for pair in swaps:
			var w: String = pair[0]
			if d.substr(i, w.length()) == w and (i == 0 or not _is_letter(d[i - 1])) \
					and (i + w.length() >= d.length() or not _is_letter(d[i + w.length()])):
				out += pair[1]
				i += w.length()
				hit = true
				break
		if not hit:
			out += d[i]
			i += 1
	if ab.get("pierce", false):
		out = out.replace("Smashes through {k:guard|guard} completely", "Smashes through and {k:pierce}")
	return out


static func _is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

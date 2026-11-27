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
## Softer text for descriptions and side notes, so names and numbers stand out.
const SOFT := "cfc6d8"
const MUTED := "8a8298"
## A half-height blank line between sections.
const GAP := "[font_size=3]\u00a0[/font_size]"


## opts (all optional):
##   hp, max_hp: current health to show instead of the species' base health
##   scale: enemy strength multiplier
##   fatigue: hauling tiredness in percent
##   fighter: a live Fighter (shows its shield and statuses)
##   enemy: true for a foe
##   kit: [basic, passive, ultimate] move ids in use (learned moves), else the species' own
##   atk, def, spd: current stats after level-ups
## Card options for one of your own Trailomon: health, tiredness, level, learned moves
## and boosted stats.
static func team_opts(e: Expedition, id: String) -> Dictionary:
	return {"hp": e.creature_hp.get(id, 0.0), "max_hp": e.max_hp(id), "fatigue": e.fatigue.get(id, 0.0),
		"kit": e.kit_moves(id), "atk": e.stat(id, "atk"), "def": e.stat(id, "def"), "spd": e.stat(id, "spd"),
		"level": e.level(id), "temper": String(e.tempers.get(id, "")), "quirk": String(e.quirks.get(id, ""))}


static func markup(id: String, opts := {}) -> String:
	var info := Species.info(id)
	var s := CombatData.stats(id)
	var type: String = info["type"]
	var hab := Glossary.habitat_id(type)
	var role: String = Glossary.ROLES.get(s["role"], "")
	var scale := float(opts.get("scale", 1.0))
	var lines: Array[String] = []
	var head := "[b]%s[/b]  {i:%s} {i:%s}" % [Species.name_markup(id), hab, role] if role != "" else "[b]%s[/b]  {i:%s}" % [Species.name_markup(id), hab]
	head += "  [font_size=7]%s[/font_size]" % Species.rarity_tag(id)
	if opts.has("level"):
		head += "  [color=#ffe3a3]Lv %d[/color]" % int(opts["level"])
	if opts.get("enemy", false):
		head += "  [color=#ff8a7a]foe[/color]"
	lines.append(head)
	var sub := "{k:%s|%s} · {k:%s|%s}" % [hab, type, role, s["role"]] if role != "" else "{k:%s|%s}" % [hab, type]
	if String(opts.get("temper", "")) != "":
		sub += " · {k:temperament|%s}" % Temperaments.KINDS[opts["temper"]]["name"]
	if Personalities.KINDS.has(String(opts.get("quirk", ""))):
		sub += " · {k:personality|%s}" % Personalities.KINDS[opts["quirk"]]["name"]
	lines.append("[color=#%s]%s[/color]" % [MUTED, sub])
	var f: Fighter = opts.get("fighter", null)
	var max_hp := float(opts.get("max_hp", CombatData.max_hp(id, scale)))
	var hp_text := "%d" % roundi(max_hp)
	if opts.has("hp"):
		hp_text = "%d/%d" % [roundi(float(opts["hp"])), roundi(max_hp)]
	var atk := float(opts.get("atk", float(s["atk"]) * scale))
	var def := float(opts.get("def", s["def"]))
	var spd := float(opts.get("spd", s["spd"]))
	var moves: Array = opts.get("kit", CombatData.kit_moves(id))
	if f != null:
		atk = f.atk
		def = f.def_now()
		spd = f.spd
		if f.basic != "":
			moves = [f.basic, f.passive, f.ultimate]
	var dps := atk * float(CombatData.move(moves[0]).get("pct", 100)) / 100.0 / spd
	lines.append("{i:hp} [color=#%s]%s[/color]    {i:atk} [color=#%s]%d[/color]    {i:def} [color=#%s]%d[/color]" % [
		HP_COL, hp_text, ATK_COL, roundi(atk), DEF_COL, roundi(def)])
	var ult_line := ""
	if f != null:
		ult_line = "  {i:ultimate}[color=#%s]%d%%[/color]" % [SLOT_COL["ultimate"], roundi(f.ult / CombatData.ULT_MAX * 100.0)]
	lines.append("{i:spd} [color=#%s]%.1fs[/color]    {i:dps} [color=#%s]%.1f[/color]%s" % [SPD_COL, spd, DPS_COL, dps, ult_line])
	var keys: Array[String] = []
	for mid in moves:
		lines.append(GAP)
		lines.append(move_header(mid, true))
		lines.append("[color=#%s]%s[/color]" % [SOFT, CombatData.describe(mid, atk, def, max_hp)])
		for k in CombatData.keywords(mid):
			if not keys.has(k) and Glossary.has(k) and not k in ["front_row", "back_row"]:
				keys.append(k)
	lines.append(GAP)
	var chart: Array = CombatData.CHART[type]
	lines.append("[color=#%s]Strong vs[/color] {i:%s}  [color=#%s]weak vs[/color] {i:%s}" % [MUTED, Glossary.habitat_id(chart[0]), MUTED, Glossary.habitat_id(chart[1])])
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
			parts.append("{i:cap_%s}%d" % [c, caps[c]])
		lines.append("[color=#%s]{k:job|Jobs}:[/color] " % MUTED + "  ".join(parts))
	if int(info["hauling"]) > 0 and not opts.get("enemy", false):
		lines[lines.size() - 1] += "  {i:haul}%d" % int(info["hauling"])
	var evo := Species.evolutions(id)
	if not evo.is_empty() and not opts.get("enemy", false):
		var names: Array[String] = []
		for to in evo:
			names.append(Species.name_markup(to))
		lines.append("[color=#%s]Evolves into[/color] %s [color=#%s]at Lv %d[/color]" % [
			MUTED, " or ".join(names), MUTED, Species.evolve_level(id)])
	var out := "\n".join(lines)
	for k in keys:
		out += Tips.SIDE + keyword_box(k)
	return out


## "{tag} Move Name" colored by slot (the tag's hover names the slot). with_slot adds the
## slot's name in small muted text. Also used for memory slots.
static func move_header(move_id: String, with_slot := false) -> String:
	var mv := CombatData.move(move_id)
	var slot: String = mv["slot"]
	var out := "{i:%s} [b][color=#%s]%s[/color][/b]" % [slot, SLOT_COL[slot], mv["name"]]
	if with_slot:
		out += "  [font_size=7][color=#%s]%s[/color][/font_size]" % [MUTED, Glossary.entry_name(slot)]
	return out


## A keyword's popup: icon, name and explanation.
static func keyword_box(k: String) -> String:
	var head := "{i:%s} " % k if Glossary.icon(k) != "" else ""
	return "%s[b]%s[/b]\n[color=#%s]%s[/color]" % [head, Glossary.entry_name(k), SOFT, Glossary.text(k)]


static func _is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

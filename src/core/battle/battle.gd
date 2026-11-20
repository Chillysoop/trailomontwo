class_name Battle
extends RefCounted
## The auto-battle simulation. Pure rules on a fixed time step, so it can be tested headless
## and replays the same way for the same seed. The battle screen only watches `events`.
##
## Rules (design doc, "Automatic combat"):
## - Normal attacks hit the nearest row that still has creatures: same lane first, then the
##   nearest lane. The second row is safe while the front row stands. A boss behind its grid
##   can't be hit until its whole grid is down. Taunt and reach abilities override this.
## - Basic attacks run on their own timer (tempo). Abilities have their own cooldowns plus a
##   shared one-second action lock, and fire automatically in priority order.
## - The wagon throws a small volley while any player creature is still standing.
## - After 90 seconds both sides tire: damage goes up and healing goes down. At 180 seconds an
##   ordinary battle ends in a withdrawal.

enum Outcome { ONGOING, VICTORY, DEFEAT, WITHDRAW, RETREAT }

const TICK := 0.05
const ACTION_LOCK := 1.0
const WAGON_UID := -1
const WAGON_INTERVAL := 4.0
const WAGON_POWER := 9.0
const FATIGUE_START := 90.0
const WITHDRAW_AT := 180.0
const RETREAT_SECS := 3.0
const SHIELD_CAP := 0.5
const MURK_SECS := 3.0
## Hauling fatigue weakens might and tempo by up to this much (at 100 fatigue).
const FATIGUE_PENALTY := 0.25

var fighters: Array[Fighter] = []
var time := 0.0
var outcome := Outcome.ONGOING
## Things that happened since the screen last looked. Each is a Dictionary with "t" (kind):
## attack, cast, hit, heal, shield, ko, status, wagon, outcome.
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var retreating := false
var retreat_left := 0.0
var _acc := 0.0
var _wagon_timer := WAGON_INTERVAL * 0.6
var _next_uid := 0


## player: {"slots": {Vector2i(row, lane): species}, "hp": {species: hp}, "fatigue": {species: 0-100}}
## enemy: {"front": [3 ids], "back": [3 ids], "boss": id or "", "scale": float}
## opts: {"seed": int, "ambush": bool}
static func create(player: Dictionary, enemy: Dictionary, opts := {}) -> Battle:
	var b := Battle.new()
	if opts.has("seed"):
		b.rng.seed = int(opts["seed"])
	else:
		b.rng.randomize()
	var slots: Dictionary = player.get("slots", {})
	var hp: Dictionary = player.get("hp", {})
	var fatigue: Dictionary = player.get("fatigue", {})
	var cells := slots.keys()
	cells.sort()
	for cell in cells:
		var id: String = slots[cell]
		if id == "" or float(hp.get(id, 1.0)) <= 0.0:
			continue
		var f := b._make(id, Formation.Side.PLAYER, cell.x, cell.y, 1.0)
		if hp.has(id):
			f.hp = clampf(float(hp[id]), 0.0, f.max_hp)
		var penalty := FATIGUE_PENALTY * clampf(float(fatigue.get(id, 0.0)), 0.0, 100.0) / 100.0
		f.might *= 1.0 - penalty
		f.tempo *= 1.0 - penalty
	var scale := float(enemy.get("scale", 1.0))
	for row in [Formation.Row.FRONT, Formation.Row.BACK]:
		var ids: Array = enemy.get("front" if row == Formation.Row.FRONT else "back", [])
		for lane in ids.size():
			if String(ids[lane]) != "":
				b._make(ids[lane], Formation.Side.ENEMY, row, lane, scale)
	if String(enemy.get("boss", "")) != "":
		b._make(enemy["boss"], Formation.Side.ENEMY, Fighter.BOSS_ROW, 1, scale)
	b._apply_synergies(Formation.Side.PLAYER)
	b._apply_synergies(Formation.Side.ENEMY)
	var ambush := bool(opts.get("ambush", false))
	for f in b.fighters:
		var caught := ambush and f.side == Formation.Side.PLAYER
		f.basic_timer = f.basic_interval() * (1.2 if caught else b.rng.randf_range(0.25, 0.7))
		for a in f.abilities:
			a["cd"] = float(CombatData.ability(a["id"])["cooldown"]) * (1.0 if caught else 0.5)
	return b


func _make(id: String, side: int, row: int, lane: int, scale: float) -> Fighter:
	var s := CombatData.stats(id)
	var f := Fighter.new()
	f.uid = _next_uid
	_next_uid += 1
	f.species = id
	f.side = side
	f.row = row
	f.lane = lane
	f.type = CombatData.type_of(id)
	f.max_hp = float(s["hp"]) * CombatData.HP_SCALE * scale
	f.hp = f.max_hp
	f.might = float(s["might"]) * scale
	f.spirit = float(s["spirit"]) * scale
	f.guard = float(s["guard"])
	f.tempo = float(s["tempo"])
	for a in s["abilities"]:
		f.abilities.append({"id": a, "cd": 0.0})
	fighters.append(f)
	return f


func _apply_synergies(side: int) -> void:
	var ids: Array = []
	for f in fighters:
		if f.side == side:
			ids.append(f.species)
	var counts := CombatData.type_counts(ids)
	for f in fighters:
		if f.side != side:
			continue
		var v := CombatData.synergy_value(f.type, CombatData.synergy_tier(f.type, int(counts.get(f.type, 0))))
		if v <= 0.0:
			continue
		match f.type:
			"Forest": f.guard += v
			"River": f.heal_bonus = v / 100.0
			"Swamp": f.murk = v
			"Mountain": f.might *= 1.0 + v / 100.0
			"Snow": f.tempo *= 1.0 + v / 100.0
			"Jungle": f.canopy = v / 100.0


# ---------- running ----------

## Advance by real seconds (already multiplied by playback speed). Runs whole ticks only.
func advance(seconds: float) -> void:
	_acc += seconds
	while _acc >= TICK and outcome == Outcome.ONGOING:
		_acc -= TICK
		step()


## Run headless until the battle ends. Returns the outcome.
func run_to_end() -> int:
	var guard_steps := int((WITHDRAW_AT + 5.0) / TICK)
	while outcome == Outcome.ONGOING and guard_steps > 0:
		step()
		guard_steps -= 1
	return outcome


func step() -> void:
	if outcome != Outcome.ONGOING:
		return
	time += TICK
	if retreating:
		retreat_left -= TICK
		if retreat_left <= 0.0:
			_finish(Outcome.RETREAT)
			return
	for f in fighters:
		if f.alive():
			_tick_fighter(f)
		if _check_end():
			return
	if _any_alive(Formation.Side.PLAYER):
		_wagon_timer -= TICK
		if _wagon_timer <= 0.0:
			_wagon_timer = WAGON_INTERVAL
			var t := ordinary_target(Formation.Side.PLAYER, 1)
			if t != null:
				events.append({"t": "wagon", "src": WAGON_UID, "dst": t.uid})
				_hit(null, t, WAGON_POWER, 10.0, "", false, "Wagon volley")
	if _check_end():
		return
	if time >= WITHDRAW_AT:
		_finish(Outcome.WITHDRAW)


## Start the retreat channel. The battle keeps running until it completes.
func request_retreat() -> void:
	if retreating or outcome != Outcome.ONGOING:
		return
	retreating = true
	retreat_left = RETREAT_SECS
	events.append({"t": "status", "src": WAGON_UID, "dst": WAGON_UID, "label": "Retreating..."})


func _tick_fighter(f: Fighter) -> void:
	for i in range(f.mods.size() - 1, -1, -1):
		f.mods[i]["secs"] = float(f.mods[i]["secs"]) - TICK
		if float(f.mods[i]["secs"]) <= 0.0:
			f.mods.remove_at(i)
	f.taunt = maxf(0.0, f.taunt - TICK)
	if f.poison_secs > 0.0:
		f.poison_secs -= TICK
		f.poison_tick -= TICK
		if f.poison_tick <= 0.0:
			f.poison_tick = 1.0
			_apply_damage(_by_uid(f.poison_from), f, f.poison_dps, "Poison")
			if not f.alive():
				return
	f.lock = maxf(0.0, f.lock - TICK)
	for a in f.abilities:
		a["cd"] = maxf(0.0, float(a["cd"]) - TICK)
	if f.lock <= 0.0:
		for a in f.abilities:
			if float(a["cd"]) <= 0.0 and _try_cast(f, a["id"]):
				a["cd"] = float(CombatData.ability(a["id"])["cooldown"])
				f.lock = ACTION_LOCK
				break
	f.basic_timer -= TICK
	if f.basic_timer <= 0.0:
		f.basic_timer = f.basic_interval()
		var t := ordinary_target(f.side, f.lane)
		if t != null:
			events.append({"t": "attack", "src": f.uid, "dst": t.uid})
			_hit(f, t, CombatData.BASIC_POWER, f.might, f.type, false, "")
			if f.murk > 0.0 and t.alive():
				_poison(f, t, f.murk, MURK_SECS)


# ---------- targeting ----------

func _opposite(side: int) -> int:
	return Formation.Side.ENEMY if side == Formation.Side.PLAYER else Formation.Side.PLAYER


func _any_alive(side: int, include_boss := true) -> bool:
	for f in fighters:
		if f.side == side and f.alive() and (include_boss or not f.is_boss()):
			return true
	return false


## The creature a normal attack from `side` in `lane` hits, or null.
func ordinary_target(side: int, lane: int) -> Fighter:
	var opp := _opposite(side)
	var taunters: Array[Fighter] = []
	for f in fighters:
		if f.side == opp and f.alive() and f.taunt > 0.0 and not f.is_boss():
			taunters.append(f)
	if not taunters.is_empty():
		return _nearest_lane(taunters, lane)
	for row in [Formation.Row.FRONT, Formation.Row.BACK, Fighter.BOSS_ROW]:
		var in_row := _row(opp, row)
		if not in_row.is_empty():
			return _nearest_lane(in_row, lane)
	return null


func _row(side: int, row: int) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for f in fighters:
		if f.side == side and f.row == row and f.alive():
			out.append(f)
	return out


## Same lane first, then the nearest lane; ties go to the upper lane.
func _nearest_lane(list: Array[Fighter], lane: int) -> Fighter:
	var best: Fighter = null
	for f in list:
		if best == null:
			best = f
			continue
		var d := absi(f.lane - lane)
		var bd := absi(best.lane - lane)
		if d < bd or (d == bd and f.lane < best.lane):
			best = f
	return best


func _attack_targets(f: Fighter, target_rule: String) -> Array[Fighter]:
	var opp := _opposite(f.side)
	var out: Array[Fighter] = []
	match target_rule:
		"back":
			var back := _row(opp, Formation.Row.BACK)
			var t := _nearest_lane(back, f.lane) if not back.is_empty() else ordinary_target(f.side, f.lane)
			if t != null:
				out.append(t)
		"weakest":
			var best: Fighter = null
			for o in fighters:
				if o.side == opp and o.alive() and not o.is_boss() and (best == null or o.hp_fraction() < best.hp_fraction()):
					best = o
			if best == null:
				best = ordinary_target(f.side, f.lane)
			if best != null:
				out.append(best)
		"row":
			var t := ordinary_target(f.side, f.lane)
			if t != null:
				out.append_array(_row(opp, t.row))
		_:
			var t := ordinary_target(f.side, f.lane)
			if t != null:
				out.append(t)
	return out


func _ally_targets(f: Fighter, target_rule: String) -> Array[Fighter]:
	var out: Array[Fighter] = []
	match target_rule:
		"self":
			out.append(f)
		"adjacent":
			for o in fighters:
				if o.side == f.side and o.alive() and o.row == f.row and absi(o.lane - f.lane) <= 1:
					out.append(o)
		"weakest_ally":
			var best: Fighter = null
			for o in fighters:
				if o.side == f.side and o.alive() and (best == null or o.hp_fraction() < best.hp_fraction()):
					best = o
			out.append(best)
		"team":
			for o in fighters:
				if o.side == f.side and o.alive():
					out.append(o)
	return out


# ---------- abilities ----------

func _try_cast(f: Fighter, id: String) -> bool:
	var a := CombatData.ability(id)
	var kind: String = a["kind"]
	var helpful := kind in ["heal", "shield", "taunt", "haste"]
	var targets := _ally_targets(f, a["target"]) if helpful else _attack_targets(f, a["target"])
	if targets.is_empty():
		return false
	var amount := float(a.get("power", 0.0)) * _stat(f, a) / 10.0
	match kind:
		"heal":
			var hurt := false
			for t in targets:
				hurt = hurt or t.hp_fraction() < (0.8 if a["target"] == "team" else 0.7)
			if not hurt:
				return false
		"shield":
			var shield_amt := amount * (1.0 + f.heal_bonus)
			var needs := false
			for t in targets:
				needs = needs or t.shield < shield_amt * 0.5
			if not needs:
				return false
		"taunt":
			if f.taunt > 0.0:
				return false
	events.append({"t": "cast", "src": f.uid, "dst": targets[0].uid, "label": a["name"], "kind": kind})
	for t in targets:
		match kind:
			"damage":
				_hit(f, t, float(a["power"]), _stat(f, a), f.type, bool(a.get("pierce", false)), a["name"])
			"heal":
				var bonus := 1.0 + f.heal_bonus + (float(a.get("shield_bonus", 0.0)) if t.shield > 0.0 else 0.0)
				_heal(f, t, amount * bonus)
			"shield":
				var amt := amount * (1.0 + f.heal_bonus)
				t.shield = minf(t.max_hp * SHIELD_CAP, t.shield + amt)
				events.append({"t": "shield", "src": f.uid, "dst": t.uid, "amount": amt})
			"taunt":
				t.taunt = float(a["secs"])
				events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Taunting"})
			"haste":
				t.add_mod("haste", float(a["power"]), float(a["secs"]))
				events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Faster"})
			"weaken":
				t.add_mod("weaken", float(a["power"]), float(a["secs"]))
				events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Guard down"})
			"slow":
				_hit(f, t, float(a.get("damage", 0.0)), _stat(f, a), f.type, false, a["name"])
				if t.alive():
					t.add_mod("slow", float(a["power"]), float(a["secs"]))
					events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Slowed"})
			"poison":
				_poison(f, t, amount, float(a["secs"]))
	return true


func _stat(f: Fighter, a: Dictionary) -> float:
	return f.spirit if a.get("stat", "might") == "spirit" else f.might


func _poison(src: Fighter, t: Fighter, dps: float, secs: float) -> void:
	if t.poison_secs <= 0.0:
		t.poison_tick = 1.0
	t.poison_dps = maxf(t.poison_dps if t.poison_secs > 0.0 else 0.0, dps)
	t.poison_secs = maxf(t.poison_secs, secs)
	t.poison_from = src.uid
	events.append({"t": "status", "src": src.uid, "dst": t.uid, "label": "Poisoned"})


## Multiplier once both sides tire (after 90s): +10% damage per 10s.
func fatigue_damage() -> float:
	if time < FATIGUE_START:
		return 1.0
	return 1.0 + 0.1 * floorf((time - FATIGUE_START) / 10.0 + 1.0)


func fatigue_healing() -> float:
	if time < FATIGUE_START:
		return 1.0
	return maxf(0.3, 1.0 - 0.1 * floorf((time - FATIGUE_START) / 10.0 + 1.0))


## Direct damage: power x stat / 10 x 100 / (100 + guard) x habitat matchup x small variance.
func damage_for(src: Fighter, t: Fighter, power: float, stat: float, atk_type: String, pierce: bool) -> float:
	var g := 0.0 if pierce else t.guard_now()
	var dmg := power * stat / 10.0 * 100.0 / (100.0 + g)
	dmg *= CombatData.matchup(atk_type, t.type)
	if src != null and src.canopy > 0.0 and t.row == Formation.Row.BACK:
		dmg *= 1.0 + src.canopy
	return dmg * fatigue_damage()


func _hit(src: Fighter, t: Fighter, power: float, stat: float, atk_type: String, pierce: bool, label: String) -> void:
	var dmg := damage_for(src, t, power, stat, atk_type, pierce) * rng.randf_range(0.9, 1.1)
	var m := CombatData.matchup(atk_type, t.type)
	_apply_damage(src, t, dmg, label, m)


func _apply_damage(src: Fighter, t: Fighter, dmg: float, label: String, matchup := 1.0) -> void:
	var amount := maxf(1.0, roundf(dmg))
	var absorbed := minf(t.shield, amount)
	t.shield -= absorbed
	t.hp = maxf(0.0, t.hp - (amount - absorbed))
	events.append({"t": "hit", "src": src.uid if src != null else WAGON_UID, "dst": t.uid, "amount": amount,
		"absorbed": absorbed, "label": label, "matchup": matchup})
	if t.hp <= 0.0:
		t.shield = 0.0
		t.taunt = 0.0
		t.poison_secs = 0.0
		t.mods.clear()
		events.append({"t": "ko", "src": src.uid if src != null else WAGON_UID, "dst": t.uid})


func _heal(src: Fighter, t: Fighter, amount: float) -> void:
	var before := t.hp
	t.hp = minf(t.max_hp, t.hp + roundf(amount * fatigue_healing()))
	events.append({"t": "heal", "src": src.uid, "dst": t.uid, "amount": t.hp - before})


func _check_end() -> bool:
	if outcome != Outcome.ONGOING:
		return true
	if not _any_alive(Formation.Side.ENEMY):
		_finish(Outcome.VICTORY)
	elif not _any_alive(Formation.Side.PLAYER):
		_finish(Outcome.DEFEAT)
	return outcome != Outcome.ONGOING


func _finish(o: int) -> void:
	outcome = o
	events.append({"t": "outcome", "outcome": o})


func _by_uid(uid: int) -> Fighter:
	for f in fighters:
		if f.uid == uid:
			return f
	return null


func fighter(uid: int) -> Fighter:
	return _by_uid(uid)


## Health left on each player creature, by species.
func player_hp() -> Dictionary:
	var out := {}
	for f in fighters:
		if f.side == Formation.Side.PLAYER:
			out[f.species] = roundf(f.hp)
	return out


func side_fighters(side: int) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for f in fighters:
		if f.side == side:
			out.append(f)
	return out

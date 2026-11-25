class_name Battle
extends RefCounted
## The auto-battle simulation. Pure rules on a fixed time step, so it can be tested headless
## and replays the same way for the same seed. The battle screen only watches `events`.
##
## Rules:
## - Each creature has an attack bar (fills over `spd` seconds) that fires its own basic
##   attack, a passive that is always on, and an ultimate bar that fills from attacking and
##   from being hit and fires its ultimate when full.
## - Normal attacks hit the nearest row that still has creatures: same lane first, then the
##   nearest lane. The second row is safe while the front row stands. A boss behind its grid
##   can't be hit until its whole grid is down. Taunt and reach override this.
## - Damage = amount x 100 / (100 + Defense) x habitat matchup x small variance.
## - The wagon throws a small volley while any player creature is still standing.
## - After 90 seconds both sides tire: damage goes up and healing goes down. At 180 seconds an
##   ordinary battle ends in a withdrawal.

enum Outcome { ONGOING, VICTORY, DEFEAT, WITHDRAW, RETREAT }

const TICK := 0.05
const WAGON_UID := -1
const WAGON_INTERVAL := 4.0
const WAGON_DAMAGE := 18.0
const FATIGUE_START := 90.0
const WITHDRAW_AT := 180.0
const RETREAT_SECS := 3.0
## Hauling fatigue weakens Attack and attack speed by up to this much (at 100 fatigue).
const FATIGUE_PENALTY := 0.25
## A heal ultimate waits until someone is below this share of health.
const HEAL_ULT_BELOW := 0.75

var fighters: Array[Fighter] = []
var time := 0.0
var outcome := Outcome.ONGOING
## Things that happened since the screen last looked. Each is a Dictionary with "t" (kind):
## attack, ult, hit, heal, shield, ko, status, wagon, outcome.
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var retreating := false
var retreat_left := 0.0
var wagon_damage := 0.0
var _acc := 0.0
var _wagon_timer := WAGON_INTERVAL * 0.6
var _next_uid := 0
## Battle items in use: names for the screen, and Mending Moss style heals [pct, every, timer].
var items_used: Array[String] = []
var _regen: Array = []


## player: {"slots": {Vector2i(row, lane): species}, "hp": {species: hp}, "fatigue": {species: 0-100},
##          "kits": {species: {"basic", "passive", "ultimate"}}, "boosts": {species: {"hp", "atk", "def", "spd"}}}
## enemy: {"front": [3 ids], "back": [3 ids], "boss": id or "", "scale": float}
## opts: {"seed": int, "ambush": bool, "items": [battle item ids]}
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
		# Learned moves and level-up boosts.
		var kit: Dictionary = player.get("kits", {}).get(id, {})
		f.basic = kit.get("basic", f.basic)
		f.passive = kit.get("passive", f.passive)
		f.ultimate = kit.get("ultimate", f.ultimate)
		var boost: Dictionary = player.get("boosts", {}).get(id, {})
		f.max_hp += float(boost.get("hp", 0.0))
		f.hp = f.max_hp
		f.atk = maxf(1.0, f.atk + float(boost.get("atk", 0.0)))
		f.def = maxf(0.0, f.def + float(boost.get("def", 0.0)))
		f.spd = maxf(0.6, f.spd - float(boost.get("spd", 0.0)))
		if hp.has(id):
			f.hp = clampf(float(hp[id]), 0.0, f.max_hp)
		var penalty := FATIGUE_PENALTY * clampf(float(fatigue.get(id, 0.0)), 0.0, 100.0) / 100.0
		f.atk *= 1.0 - penalty
		f.spd /= 1.0 - penalty
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
	for f in b.fighters:
		var pm := CombatData.move(f.passive)
		if pm.get("kind", "") == "start_shield":
			f.shield = minf(f.max_hp, f.def * float(pm["def_pct"]) / 100.0)
	var ambush := bool(opts.get("ambush", false))
	for f in b.fighters:
		var caught := ambush and f.side == Formation.Side.PLAYER
		f.attack_bar = 0.0 if caught else b.rng.randf_range(0.2, 0.6)
		f.ult = 0.0 if caught else (30.0 if ambush else 0.0)
	for id in opts.get("items", []):
		b._use_item(String(id))
	return b


## A battle item's effect at the start of the fight.
func _use_item(id: String) -> void:
	if not BattleItems.has(id):
		return
	var it: Dictionary = BattleItems.ITEMS[id]
	items_used.append(id)
	events.append({"t": "status", "src": WAGON_UID, "dst": WAGON_UID, "label": BattleItems.item_name(id) + "!"})
	for f in side_fighters(Formation.Side.PLAYER):
		if it.has("shield_maxhp"):
			f.shield = minf(f.max_hp, f.shield + f.max_hp * float(it["shield_maxhp"]) / 100.0)
		if it.has("atk_pct"):
			f.atk *= 1.0 + float(it["atk_pct"]) / 100.0
		if it.has("def_pct"):
			f.def *= 1.0 + float(it["def_pct"]) / 100.0
		if it.has("haste"):
			f.add_mod("haste", float(it["haste"][0]) / 100.0, float(it["haste"][1]))
		if it.has("ult_pct"):
			f.ult = minf(CombatData.ULT_MAX, f.ult + CombatData.ULT_MAX * float(it["ult_pct"]) / 100.0)
	for f in side_fighters(Formation.Side.ENEMY):
		if it.has("foe_slow"):
			f.add_mod("slow", float(it["foe_slow"][0]) / 100.0, float(it["foe_slow"][1]))
		if it.has("foe_weaken"):
			f.add_mod("weaken", float(it["foe_weaken"][0]) / 100.0, float(it["foe_weaken"][1]))
	if it.has("regen"):
		_regen.append([float(it["regen"][0]), float(it["regen"][1]), float(it["regen"][1])])


func _tick_items() -> void:
	for r in _regen:
		r[2] -= TICK
		if r[2] > 0.0:
			continue
		r[2] = r[1]
		for f in side_fighters(Formation.Side.PLAYER):
			if f.alive():
				var before := f.hp
				f.hp = minf(f.max_hp, f.hp + roundf(f.max_hp * r[0] / 100.0 * fatigue_healing()))
				if f.hp > before:
					events.append({"t": "heal", "src": f.uid, "dst": f.uid, "amount": f.hp - before})


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
	f.max_hp = CombatData.max_hp(id, scale)
	f.hp = f.max_hp
	f.atk = float(s["atk"]) * scale
	f.def = float(s["def"])
	f.spd = float(s["spd"])
	f.basic = s["basic"]
	f.passive = s["passive"]
	f.ultimate = s["ultimate"]
	f.ult_per_attack = float(s.get("ult_per_attack", CombatData.ULT_PER_ATTACK))
	f.ult_per_hit = float(s.get("ult_per_hit", CombatData.ULT_PER_HIT))
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
			"Forest": f.def += v
			"River": f.heal_bonus = v / 100.0
			"Swamp": f.poison_bonus = v / 100.0
			"Mountain": f.atk *= 1.0 + v / 100.0
			"Snow": f.spd /= 1.0 + v / 100.0
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
	_tick_items()
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
				_deal(null, t, WAGON_DAMAGE, "basic", "Wagon volley")
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
			_deal(_by_uid(f.poison_from), f, f.poison_dps, f.poison_tag, "Poison", true, true)
			if not f.alive():
				return
	if f.ult >= CombatData.ULT_MAX and _try_ultimate(f):
		f.ult = 0.0
		f.ults_fired += 1
		if not f.alive():
			return
	var rate := f.attack_rate()
	if f.passive == "snow_runner" and _any_with_mod(_opposite(f.side), "slow"):
		rate *= 1.0 + float(CombatData.move("snow_runner")["amount"]) / 100.0
	f.attack_bar += rate * TICK
	if f.attack_bar >= 1.0:
		f.attack_bar = 0.0
		_basic_attack(f)


# ---------- targeting ----------

func _opposite(side: int) -> int:
	return Formation.Side.ENEMY if side == Formation.Side.PLAYER else Formation.Side.PLAYER


func _any_alive(side: int, include_boss := true) -> bool:
	for f in fighters:
		if f.side == side and f.alive() and (include_boss or not f.is_boss()):
			return true
	return false


func _any_taunting(side: int) -> bool:
	for f in fighters:
		if f.side == side and f.alive() and f.taunt > 0.0:
			return true
	return false


func _any_with_mod(side: int, kind: String) -> bool:
	for f in fighters:
		if f.side == side and f.alive() and f.has_mod(kind):
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


## Creatures next to `f` on its own side: directly above, below and beside it on the grid.
func adjacent(f: Fighter, include_self := false) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for o in fighters:
		if o.side != f.side or not o.alive():
			continue
		if o == f:
			if include_self:
				out.append(o)
			continue
		if f.is_boss() or o.is_boss():
			continue
		var d := absi(o.row - f.row) + absi(o.lane - f.lane)
		if d == 1:
			out.append(o)
	return out


## The enemy standing in the other row of the target's lane (behind a front-row target).
func behind(t: Fighter) -> Fighter:
	if t.row != Formation.Row.FRONT:
		return null
	for o in fighters:
		if o.side == t.side and o.alive() and o.row == Formation.Row.BACK and o.lane == t.lane:
			return o
	return null


## Who `f`'s next basic attack will hit. Ordinary attacks can't touch the second row until
## the whole front row is down; only moves that name a row (reach) go over it, and a taunt
## still pulls those.
func basic_target(f: Fighter) -> Fighter:
	if not f.alive():
		return null
	var reach := bool(CombatData.move(f.basic).get("reach", false)) and not _any_taunting(_opposite(f.side))
	return _back_row_target(f) if reach else ordinary_target(f.side, f.lane)


func _back_row_target(f: Fighter) -> Fighter:
	var back := _row(_opposite(f.side), Formation.Row.BACK)
	return _nearest_lane(back, f.lane) if not back.is_empty() else ordinary_target(f.side, f.lane)


func _weakest_enemy(f: Fighter) -> Fighter:
	var best: Fighter = null
	for o in fighters:
		if o.side != f.side and o.alive() and not o.is_boss() and (best == null or o.hp_fraction() < best.hp_fraction()):
			best = o
	return best if best != null else ordinary_target(f.side, f.lane)


func _weakest_ally(f: Fighter) -> Fighter:
	var best: Fighter = null
	for o in fighters:
		if o.side == f.side and o.alive() and (best == null or o.hp_fraction() < best.hp_fraction()):
			best = o
	return best


func _team(side: int) -> Array[Fighter]:
	var out: Array[Fighter] = []
	for o in fighters:
		if o.side == side and o.alive():
			out.append(o)
	return out


# ---------- moves ----------

func _pct(f: Fighter, move_id: String, key := "pct") -> float:
	return f.atk * float(CombatData.move(move_id).get(key, 100)) / 100.0


func _basic_attack(f: Fighter) -> void:
	var m := CombatData.move(f.basic)
	var t := basic_target(f)
	if t == null:
		return
	f.attacks += 1
	f.ult = minf(CombatData.ULT_MAX, f.ult + f.ult_per_attack)
	events.append({"t": "attack", "src": f.uid, "dst": t.uid, "label": m["name"]})
	# Jungle dodge: the attack misses completely.
	if t.dodge:
		t.dodge = false
		events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Dodged"})
		return
	if MovePool.has(f.basic):
		_learned_basic(f, t, m)
	else:
		_legacy_basic(f, t, m)
	# Passives that ride on basic attacks.
	var pm := CombatData.move(f.passive)
	if pm.get("kind", "") == "every" and f.attacks % int(pm["n"]) == 0:
		_every_nth(f, t, pm)
	match f.passive:
		"bark_shell":
			pm = CombatData.move("bark_shell")
			if f.attacks % int(pm["every"]) == 0:
				_give_shield(f, f, f.def * float(pm["def_pct"]) / 100.0)
		"ancient_bark":
			pm = CombatData.move("ancient_bark")
			if f.attacks % int(pm["every"]) == 0:
				for a in _team(f.side):
					_give_shield(f, a, f.def * float(pm["def_pct"]) / 100.0)
		"glide":
			var b := behind(t)
			if b != null:
				_deal(f, b, _pct(f, "glide"), "passive", "Glide")
	# Thorns on the creature that was hit.
	if t.alive():
		var tm := CombatData.move(t.passive)
		if t.passive == "thorny_hide" or (t.passive == "thorn_pelt" and t.shield > 0.0):
			_deal(t, f, _pct(t, t.passive), "passive", tm["name"])
		elif tm.get("kind", "") == "thorns" and (not tm.get("while_shielded", false) or t.shield > 0.0):
			_deal(t, f, t.atk * float(tm["pct"]) / 100.0, "passive", tm["name"])


## The original kits, matched by move id.
func _legacy_basic(f: Fighter, t: Fighter, m: Dictionary) -> void:
	var amount := _pct(f, f.basic)
	match f.basic:
		"bramble_swipe":
			amount += f.def * float(m["def_pct"]) / 100.0
		"trunk_slam":
			if f.shield > 0.0:
				amount *= 1.0 + float(m["amount"]) / 100.0
		"scythe_cut":
			if t.hp_fraction() < 0.5:
				amount *= 1.0 + float(m["amount"]) / 100.0
		"ink_jet":
			var washed := minf(t.shield, _pct(f, f.basic, "wash"))
			if washed > 0.0:
				t.shield -= washed
				events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Washed"})
	_deal(f, t, amount, "basic", m["name"])
	match f.basic:
		"mending_spray":
			_heal(f, _weakest_ally(f), _pct(f, f.basic, "heal_pct"))
		"bog_spit":
			if t.alive():
				_poison(f, t, _pct(f, f.basic, "dot"), float(m["secs"]))
		"frost_kick":
			if t.alive():
				_slow(f, t, float(m["amount"]) / 100.0, float(m["secs"]))
		"frost_sting":
			if t.alive():
				_slow(f, t, float(m["amount"]) / 100.0, float(m["secs"]))
				_deal(f, t, amount, "basic", m["name"])
		"thorn_bite":
			_give_shield(f, f, _pct(f, f.basic, "shield_pct"))
		"mud_horn":
			if t.alive():
				t.add_mod("weaken", float(m["amount"]) / 100.0, float(m["secs"]))
				events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Weakened"})
		"headbutt":
			if t.alive():
				t.attack_bar = maxf(0.0, t.attack_bar - float(m["amount"]) / 100.0)
				events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Staggered"})
		"wing_bash":
			f.dodge = true
		"antler_gore":
			for a in adjacent(t):
				_deal(f, a, _pct(f, f.basic, "splash"), "basic", m["name"])


# ---------- learned (data-driven) moves, see MovePool ----------

func _learned_basic(f: Fighter, t: Fighter, m: Dictionary) -> void:
	_wash(f, t, m)
	var amount := f.atk * float(m.get("pct", 100)) / 100.0 + f.def * float(m.get("def_pct", 0)) / 100.0
	amount *= _bonus(m.get("bonus", {}), f, t)
	for i in int(m.get("hits", 1)):
		_deal(f, t, amount, "basic", m["name"])
		if not t.alive():
			break
		if i == 0:
			_on_hit(f, t, m, "basic")
	if m.has("splash"):
		for a in adjacent(t):
			_deal(f, a, f.atk * float(m["splash"]) / 100.0, "basic", m["name"])
	_self_and_allies(f, m)


func _learned_ultimate(f: Fighter, t: Fighter, m: Dictionary) -> void:
	var opp := _opposite(f.side)
	var targets: Array[Fighter] = []
	match String(m.get("target", "target")):
		"target": targets = [t]
		"adjacent":
			targets = [t]
			targets.append_array(adjacent(t))
		"row": targets = _row(opp, t.row)
		"all": targets = _team(opp)
		"weakest": targets = [_weakest_enemy(f)]
	for e in targets:
		if e == null or not e.alive():
			continue
		_wash(f, e, m)
		if m.has("pct"):
			_deal(f, e, f.atk * float(m["pct"]) / 100.0 * _bonus(m.get("bonus", {}), f, e), "ult", m["name"], bool(m.get("pierce", false)))
		if e.alive():
			_on_hit(f, e, m, "ult")
	_self_and_allies(f, m, "ult")
	if m.has("taunt"):
		f.taunt = float(m["taunt"])
		events.append({"t": "status", "src": f.uid, "dst": f.uid, "label": "Taunting"})


## Whether a learned ultimate has anything to do yet (a pure heal waits for someone hurt).
func _learned_ult_ready(f: Fighter, t: Fighter, m: Dictionary) -> bool:
	if String(m.get("target", "target")) != "none":
		return t != null
	var team: Dictionary = m.get("team", {})
	if team.has("heal_maxhp") and not team.has("shield_def") and not team.has("haste") and not m.has("taunt") and not m.has("self"):
		var w := _weakest_ally(f)
		return w != null and w.hp_fraction() < HEAL_ULT_BELOW
	return true


func _cond(vs: String, f: Fighter, t: Fighter) -> bool:
	match vs:
		"slowed": return t.has_mod("slow")
		"poisoned": return t.poison_secs > 0.0
		"weakened": return t.has_mod("weaken")
		"hurt": return t.hp_fraction() < 0.5
		"healthy": return t.hp_fraction() > 0.75
		"shielded": return f.shield > 0.0
	return false


func _bonus(b: Dictionary, f: Fighter, t: Fighter) -> float:
	if b.is_empty() or not _cond(String(b["vs"]), f, t):
		return 1.0
	return 1.0 + float(b["amount"]) / 100.0


func _wash(f: Fighter, t: Fighter, m: Dictionary) -> void:
	if not m.has("wash") or t.shield <= 0.0:
		return
	t.shield -= minf(t.shield, f.atk * float(m["wash"]) / 100.0)
	events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Washed"})


## Statuses a learned move puts on an enemy it hit.
func _on_hit(f: Fighter, t: Fighter, m: Dictionary, tag: String) -> void:
	if m.has("poison"):
		_poison(f, t, f.atk * float(m["poison"][0]) / 100.0, float(m["poison"][1]), tag)
	if m.has("slow"):
		_slow(f, t, float(m["slow"][0]) / 100.0, float(m["slow"][1]))
	if m.has("weaken"):
		t.add_mod("weaken", float(m["weaken"][0]) / 100.0, float(m["weaken"][1]))
		events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Weakened"})
	if m.has("stagger"):
		t.attack_bar = maxf(0.0, t.attack_bar - float(m["stagger"]) / 100.0)
		events.append({"t": "status", "src": f.uid, "dst": t.uid, "label": "Staggered"})


func _self_and_allies(f: Fighter, m: Dictionary, tag := "basic") -> void:
	var s: Dictionary = m.get("self", {})
	if s.has("shield_atk"):
		_give_shield(f, f, f.atk * float(s["shield_atk"]) / 100.0)
	if s.has("shield_def"):
		_give_shield(f, f, f.def * float(s["shield_def"]) / 100.0)
	if s.has("heal_atk"):
		_heal(f, f, f.atk * float(s["heal_atk"]) / 100.0, tag)
	if s.get("dodge", false):
		f.dodge = true
	var a: Dictionary = m.get("ally", {})
	if a.has("heal_atk"):
		_heal(f, _weakest_ally(f), f.atk * float(a["heal_atk"]) / 100.0, tag)
	var team: Dictionary = m.get("team", {})
	for ally in _team(f.side) if not team.is_empty() else []:
		if team.has("heal_maxhp"):
			_heal(f, ally, ally.max_hp * float(team["heal_maxhp"]) / 100.0, tag)
		if team.get("cleanse", false):
			_cleanse(ally)
		if team.has("shield_def"):
			_give_shield(f, ally, f.def * float(team["shield_def"]) / 100.0 + float(team.get("shield_flat", 0)))
		if team.has("haste"):
			ally.add_mod("haste", float(team["haste"][0]) / 100.0, float(team["haste"][1]))
			events.append({"t": "status", "src": f.uid, "dst": ally.uid, "label": "Faster"})


func _cleanse(t: Fighter) -> void:
	t.poison_secs = 0.0
	for i in range(t.mods.size() - 1, -1, -1):
		if t.mods[i]["kind"] in ["weaken", "slow"]:
			t.mods.remove_at(i)


## "Every Nth basic attack" passives from MovePool.
func _every_nth(f: Fighter, t: Fighter, pm: Dictionary) -> void:
	if pm.has("shield_def"):
		_give_shield(f, f, f.def * float(pm["shield_def"]) / 100.0)
	elif pm.has("ally_heal_atk"):
		_heal(f, _weakest_ally(f), f.atk * float(pm["ally_heal_atk"]) / 100.0)
	elif pm.has("extra_pct"):
		_deal(f, t, f.atk * float(pm["extra_pct"]) / 100.0, "passive", pm["name"])
	elif pm.has("poison_all"):
		for e in _team(_opposite(f.side)):
			_poison(f, e, f.atk * float(pm["poison_all"][0]) / 100.0, float(pm["poison_all"][1]), "passive")
	elif pm.has("team_haste"):
		for a in _team(f.side):
			a.add_mod("haste", float(pm["team_haste"][0]) / 100.0, float(pm["team_haste"][1]))


## Returns false (and keeps the bar full) when the ultimate has nothing useful to do yet.
func _try_ultimate(f: Fighter) -> bool:
	var m := CombatData.move(f.ultimate)
	var opp := _opposite(f.side)
	var t := ordinary_target(f.side, f.lane)
	if MovePool.has(f.ultimate):
		if not _learned_ult_ready(f, t, m):
			return false
		events.append({"t": "ult", "src": f.uid, "dst": t.uid if t != null else f.uid, "label": m["name"]})
		_learned_ultimate(f, t, m)
		return true
	match f.ultimate:
		"tidewash":
			var w := _weakest_ally(f)
			if w == null or w.hp_fraction() >= HEAL_ULT_BELOW:
				return false
		"rally_bell", "briar_wall":
			pass
		_:
			if t == null:
				return false
	events.append({"t": "ult", "src": f.uid, "dst": t.uid if t != null else f.uid, "label": m["name"]})
	match f.ultimate:
		"briar_wall":
			for a in adjacent(f, true):
				_give_shield(f, a, f.def * float(m["def_pct"]) / 100.0 + float(m["flat"]))
			f.taunt = float(m["secs"])
			events.append({"t": "status", "src": f.uid, "dst": f.uid, "label": "Taunting"})
		"shell_quake":
			var around := adjacent(t)
			_deal(f, t, _pct(f, f.ultimate), "ult", m["name"])
			for a in around:
				_deal(f, a, _pct(f, f.ultimate, "splash"), "ult", m["name"])
		"antler_storm":
			for e in _team(opp):
				_deal(f, e, _pct(f, f.ultimate), "ult", m["name"])
			for a in _team(f.side):
				_give_shield(f, a, float(m["flat"]))
		"bramble_pounce":
			var before := t.hp + t.shield
			_deal(f, t, _pct(f, f.ultimate), "ult", m["name"])
			_give_shield(f, f, (before - t.hp - t.shield) * float(m["amount"]) / 100.0)
		"tidewash":
			for a in _team(f.side):
				_heal(f, a, a.max_hp * float(m["maxhp_pct"]) / 100.0, "ult")
		"dive":
			_deal(f, _weakest_enemy(f), _pct(f, f.ultimate), "ult", m["name"])
		"miasma":
			for e in _team(opp):
				_poison(f, e, _pct(f, f.ultimate, "dot"), float(m["secs"]), "ult")
		"bog_charge":
			_deal(f, t, _pct(f, f.ultimate), "ult", m["name"])
			if t.alive():
				_poison(f, t, _pct(f, f.ultimate, "dot"), float(m["secs"]), "ult")
		"scythe_sweep":
			for e in _row(opp, t.row):
				_deal(f, e, _pct(f, f.ultimate), "ult", m["name"])
		"breakstone":
			_deal(f, t, _pct(f, f.ultimate), "ult", m["name"], true)
		"rally_bell":
			for a in _team(f.side):
				a.add_mod("haste", float(m["amount"]) / 100.0, float(m["secs"]))
				events.append({"t": "status", "src": f.uid, "dst": a.uid, "label": "Faster"})
		"frost_burst":
			var hit: Array[Fighter] = [t]
			hit.append_array(adjacent(t))
			for e in hit:
				_deal(f, e, _pct(f, f.ultimate), "ult", m["name"])
				if e.alive():
					_slow(f, e, float(m["amount"]) / 100.0, float(m["secs"]))
		"vine_lash":
			var back := _row(opp, Formation.Row.BACK)
			if back.is_empty():
				back = [t]
			for e in back:
				_deal(f, e, _pct(f, f.ultimate), "ult", m["name"])
		"wing_gust":
			var row := _row(opp, Formation.Row.BACK)
			if row.is_empty():
				row = _row(opp, t.row)
			for e in row:
				_deal(f, e, _pct(f, f.ultimate), "ult", m["name"])
			f.dodge = true
	return true


# ---------- effects ----------

## tag says which part of the kit gets credit for the poison damage (basic or ult).
func _poison(src: Fighter, t: Fighter, dps: float, secs: float, tag := "basic") -> void:
	secs *= 1.0 + src.poison_bonus
	t.poison_tag = tag
	if t.poison_secs <= 0.0:
		t.poison_tick = 1.0
	t.poison_dps = maxf(t.poison_dps if t.poison_secs > 0.0 else 0.0, dps)
	t.poison_secs = maxf(t.poison_secs, secs)
	t.poison_from = src.uid
	events.append({"t": "status", "src": src.uid, "dst": t.uid, "label": "Poisoned"})
	if src.passive == "rot_light":
		t.add_mod("weaken", float(CombatData.move("rot_light")["amount"]) / 100.0, t.poison_secs)


func _slow(src: Fighter, t: Fighter, amount: float, secs: float) -> void:
	t.add_mod("slow", amount, secs)
	events.append({"t": "status", "src": src.uid, "dst": t.uid, "label": "Slowed"})


func _give_shield(src: Fighter, t: Fighter, amount: float) -> void:
	amount = roundf(amount * (1.0 + src.heal_bonus))
	var before := t.shield
	t.shield = minf(t.max_hp, t.shield + amount)
	src.shield_done += t.shield - before
	events.append({"t": "shield", "src": src.uid, "dst": t.uid, "amount": t.shield - before})


func _heal(src: Fighter, t: Fighter, amount: float, _tag := "basic") -> void:
	if t == null or not t.alive():
		return
	amount *= (1.0 + src.heal_bonus) * fatigue_healing() * (1.0 - t.mod_total("ruin"))
	var before := t.hp
	t.hp = minf(t.max_hp, t.hp + roundf(amount))
	src.heal_done += t.hp - before
	if src.passive == "clear_water" and t.poison_secs > 0.0:
		t.poison_secs = 0.0
		for i in range(t.mods.size() - 1, -1, -1):
			if t.mods[i]["kind"] == "weaken":
				t.mods.remove_at(i)
	if t.hp > before:
		events.append({"t": "heal", "src": src.uid, "dst": t.uid, "amount": t.hp - before})


## Multiplier once both sides tire (after 90s): +10% damage per 10s.
func fatigue_damage() -> float:
	if time < FATIGUE_START:
		return 1.0
	return 1.0 + 0.1 * floorf((time - FATIGUE_START) / 10.0 + 1.0)


func fatigue_healing() -> float:
	if time < FATIGUE_START:
		return 1.0
	return maxf(0.3, 1.0 - 0.1 * floorf((time - FATIGUE_START) / 10.0 + 1.0))


## Damage before variance: amount x 100 / (100 + Defense) x matchup x passives.
func damage_for(src: Fighter, t: Fighter, amount: float, pierce := false) -> float:
	var d := 0.0 if pierce else t.def_now()
	if src != null and src.passive == "rockhorn":
		d *= 1.0 - float(CombatData.move("rockhorn")["amount"]) / 100.0
	var dmg := amount * 100.0 / (100.0 + d)
	if src != null:
		dmg *= CombatData.matchup(src.type, t.type)
		match src.passive:
			"mudwallow":
				if t.poison_secs > 0.0 or t.has_mod("weaken"):
					dmg *= 1.0 + float(CombatData.move("mudwallow")["amount"]) / 100.0
			"brittle":
				if t.has_mod("slow"):
					dmg *= 1.0 + float(CombatData.move("brittle")["amount"]) / 100.0
			"canopy_stalker":
				if t.row == Formation.Row.BACK:
					dmg *= 1.0 + float(CombatData.move("canopy_stalker")["amount"]) / 100.0
		var sp := CombatData.move(src.passive)
		if sp.get("kind", "") == "bonus_vs" and _cond(String(sp["vs"]), src, t):
			dmg *= 1.0 + float(sp["amount"]) / 100.0
		if src.canopy > 0.0 and t.row == Formation.Row.BACK:
			dmg *= 1.0 + src.canopy
	return dmg * fatigue_damage()


## Deal damage and record it. tag is basic, ult or passive (for the stats window).
func _deal(src: Fighter, t: Fighter, amount: float, tag: String, label: String, pierce := false, raw := false) -> void:
	if t == null or not t.alive():
		return
	var dmg := amount if raw else damage_for(src, t, amount, pierce) * rng.randf_range(0.92, 1.08)
	var total := maxf(1.0, roundf(dmg))
	var absorbed := minf(t.shield, total)
	t.shield -= absorbed
	var lost := minf(t.hp, total - absorbed)
	t.hp -= lost
	t.taken += absorbed + lost
	if src != null:
		match tag:
			"ult": src.dmg_ult += absorbed + lost
			"passive": src.dmg_passive += absorbed + lost
			_: src.dmg_basic += absorbed + lost
		if src.passive == "undertow" and src.alive() and tag != "passive":
			_heal(src, src, (absorbed + lost) * float(CombatData.move("undertow")["pct"]) / 100.0)
		elif src.alive() and tag != "passive":
			var dp := CombatData.move(src.passive)
			if dp.get("kind", "") == "drain":
				_heal(src, src, (absorbed + lost) * float(dp["pct"]) / 100.0)
	else:
		wagon_damage += absorbed + lost
	if tag != "passive" and not raw:
		t.ult = minf(CombatData.ULT_MAX, t.ult + t.ult_per_hit)
	var m := CombatData.matchup(src.type, t.type) if src != null else 1.0
	events.append({"t": "hit", "src": src.uid if src != null else WAGON_UID, "dst": t.uid, "amount": total,
		"absorbed": absorbed, "label": label, "matchup": m, "tag": tag})
	if t.hp <= 0.0:
		t.hp = 0.0
		t.shield = 0.0
		t.taunt = 0.0
		t.poison_secs = 0.0
		t.mods.clear()
		events.append({"t": "ko", "src": src.uid if src != null else WAGON_UID, "dst": t.uid})


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

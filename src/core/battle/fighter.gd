class_name Fighter
extends RefCounted
## One creature during a battle: its slot, stats after bonuses, bars, statuses and tallies.

## Row index for a boss standing behind its grid.
const BOSS_ROW := 2

var uid := 0
var species := ""
var side := Formation.Side.PLAYER
var row := Formation.Row.FRONT
var lane := 0
var type := ""
var max_hp := 1.0
var hp := 1.0
var atk := 10.0
var def := 10.0
## Seconds between basic attacks.
var spd := 2.0
var basic := ""
var passive := ""
var ultimate := ""
## 0..1: the basic attack fires when it reaches 1.
var attack_bar := 0.0
## 0..CombatData.ULT_MAX: the ultimate fires when full.
var ult := 0.0
## Ultimate charge per basic attack and per hit taken (kits can override the defaults).
var ult_per_attack := CombatData.ULT_PER_ATTACK
var ult_per_hit := CombatData.ULT_PER_HIT
var shield := 0.0
var taunt := 0.0
## Jungle dodge: the next basic attack aimed at it misses.
var dodge := false
## Active timed modifiers: {"kind": "haste"|"slow"|"weaken"|"ruin", "amount": fraction, "secs": float}
var mods: Array = []
var poison_dps := 0.0
var poison_secs := 0.0
var poison_tick := 1.0
var poison_from := -1
var poison_tag := "basic"
## How many basic attacks it has made (for "every 3rd attack" passives).
var attacks := 0
## Habitat bonuses resolved at the start.
var heal_bonus := 0.0
var poison_bonus := 0.0
var canopy := 0.0

## Fight tallies for the stats window.
var dmg_basic := 0.0
var dmg_ult := 0.0
var dmg_passive := 0.0
var shield_done := 0.0
var heal_done := 0.0
var taken := 0.0
var ults_fired := 0
## Hunts only: prey never attacks and bolts off the field at bolt_at (seconds).
var prey := false
var fled := false
var bolt_at := 0.0


func alive() -> bool:
	return hp > 0.0 and not fled


func is_boss() -> bool:
	return row == BOSS_ROW


func display_name() -> String:
	return Species.info(species)["name"]


func hp_fraction() -> float:
	return hp / max_hp


func damage_total() -> float:
	return dmg_basic + dmg_ult + dmg_passive


func mod_total(kind: String) -> float:
	var t := 0.0
	for m in mods:
		if m["kind"] == kind:
			t = maxf(t, float(m["amount"]))
	return t


func has_mod(kind: String) -> bool:
	return mod_total(kind) > 0.0


## Attack bar fill per second, after haste and slow.
func attack_rate() -> float:
	return maxf(0.1, 1.0 + mod_total("haste") - mod_total("slow")) / spd


## Defense after weaken (and Cairnram's Stubborn).
func def_now() -> float:
	var d := def
	if hp_fraction() < 0.5:
		var pm := CombatData.move(passive)
		if passive == "stubborn" or pm.get("kind", "") == "armor_low":
			d += float(pm["amount"])
	return d * (1.0 - mod_total("weaken"))


## Basic attack damage per second against no Defense, for the stat block.
func dps() -> float:
	return atk * float(CombatData.move(basic).get("pct", 100)) / 100.0 / spd


func add_mod(kind: String, amount: float, secs: float) -> void:
	for m in mods:
		if m["kind"] == kind:
			m["amount"] = maxf(float(m["amount"]), amount)
			m["secs"] = maxf(float(m["secs"]), secs)
			return
	mods.append({"kind": kind, "amount": amount, "secs": secs})

class_name Fighter
extends RefCounted
## One creature during a battle: its slot, stats after bonuses, timers and statuses.

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
var might := 10.0
var spirit := 10.0
var guard := 10.0
var tempo := 60.0
var basic_timer := 0.0
## [{"id": String, "cd": float}] in priority order.
var abilities: Array = []
var lock := 0.0
var shield := 0.0
var taunt := 0.0
## Active timed modifiers: {"kind": "haste"|"slow"|"weaken", "amount": float, "secs": float}
var mods: Array = []
## Damage per second and seconds left.
var poison_dps := 0.0
var poison_secs := 0.0
var poison_tick := 1.0
var poison_from := -1
## Synergy bonuses resolved at the start (heal_bonus fraction, murk dps, canopy fraction).
var heal_bonus := 0.0
var murk := 0.0
var canopy := 0.0


func alive() -> bool:
	return hp > 0.0


func is_boss() -> bool:
	return row == BOSS_ROW


func display_name() -> String:
	return Species.info(species)["name"]


func hp_fraction() -> float:
	return hp / max_hp


func mod_total(kind: String) -> float:
	var t := 0.0
	for m in mods:
		if m["kind"] == kind:
			t = maxf(t, float(m["amount"]))
	return t


func tempo_now() -> float:
	return tempo * (1.0 + mod_total("haste")) * (1.0 - mod_total("slow"))


func guard_now() -> float:
	return guard * (1.0 - mod_total("weaken"))


func basic_interval() -> float:
	return CombatData.TEMPO_SCALE / maxf(1.0, tempo_now())


func add_mod(kind: String, amount: float, secs: float) -> void:
	for m in mods:
		if m["kind"] == kind:
			m["amount"] = maxf(float(m["amount"]), amount)
			m["secs"] = maxf(float(m["secs"]), secs)
			return
	mods.append({"kind": kind, "amount": amount, "secs": secs})

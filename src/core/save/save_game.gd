class_name SaveGame
extends RefCounted
## Save files: 3 normal slots and one hardcore slot.
##
## A save holds the whole crossing in progress (every Expedition variable, so new systems
## are saved without changes here) plus the "caravan": the team progress that carries from
## one crossing to the next (CARRY). It also keeps the caravan as it was when the crossing
## began, so a failed crossing in a normal slot can be tried again from there.
##
## Hardcore: there is one hardcore slot. It autosaves after everything, can't be reloaded to
## an earlier point, and is deleted when the crossing fails. Each save bumps a counter that is
## also kept in a separate key file, so an old copy of the save is refused, and a checksum
## catches edited files. (Copying both files back together is still possible; this stops
## casual reloading, not a determined player.)

const NORMAL_SLOTS := ["slot1", "slot2", "slot3"]
const HARDCORE := "hardcore"
const VERSION := 1
## Where saves live (tests point this elsewhere).
static var dir := "user://saves/"
const SALT := "trailomon-hardcore-v1"

## Team progress that carries into the next crossing. Fields a build doesn't have are skipped.
const CARRY := ["roster", "stored", "levels", "xp", "kits", "boosts", "known", "pending_levels",
	"memory", "lineup", "items", "item_slots", "techniques", "light_dust", "dark_dust", "dust_used", "coins",
	"map", "seen", "encountered", "met_in"]

## The save picked on the title screen for the crossing being played ("" = none, e.g. tests).
static var current_slot := ""
## A loaded save (the result of read()), handed to the expedition screen when it opens.
## Empty means start a brand-new caravan.
static var pending := {}


static func all_slots() -> Array:
	return NORMAL_SLOTS + [HARDCORE]


static func is_hardcore(slot: String) -> bool:
	return slot == HARDCORE


static func path(slot: String) -> String:
	return dir + slot + ".save"


static func exists(slot: String) -> bool:
	return FileAccess.file_exists(path(slot))


# ---------- encoding ----------

## Every script variable of an object, as plain data.
static func encode(obj: Object) -> Dictionary:
	var out := {}
	for p in obj.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		out[p["name"]] = _value(obj.get(p["name"]))
	return out


static func _value(v: Variant) -> Variant:
	if v is RandomNumberGenerator:
		return {"__rng": [v.seed, v.state]}
	if v is Object:
		return {"__obj": encode(v)}
	if v is Array:
		var a := []
		for x in v:
			a.append(_value(x))
		return a
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _value(v[k])
		return d
	return v


## Write saved values back onto an object. Unknown names are ignored, missing ones keep
## their defaults, so older saves still load after new fields are added.
static func decode_into(obj: Object, data: Dictionary) -> void:
	var names := {}
	for p in obj.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names[p["name"]] = true
	for name in data:
		if names.has(name):
			_put(obj, name, data[name])


static func _put(obj: Object, name: String, v: Variant) -> void:
	var cur: Variant = obj.get(name)
	if v is Dictionary and v.has("__rng") and cur is RandomNumberGenerator:
		cur.seed = int(v["__rng"][0])
		cur.state = int(v["__rng"][1])
	elif v is Dictionary and v.has("__obj") and cur is Object:
		decode_into(cur, v["__obj"])
	elif cur is Array and v is Array:
		cur.clear()
		cur.assign(v)
	else:
		obj.set(name, v)


static func caravan(e: Expedition) -> Dictionary:
	var all := encode(e)
	var out := {}
	for k in CARRY:
		if all.has(k):
			out[k] = all[k]
	return out


# ---------- crossings ----------

## A fresh crossing with a caravan carried over: same team and progress, everyone rested and
## healed, new supplies, cargo and wagon.
static func next_crossing(caravan_data: Dictionary, rng_seed := -1, crossing_no := 2) -> Expedition:
	var e := Expedition.new_default(rng_seed)
	decode_into(e, caravan_data)
	e.set_crossing(crossing_no)
	e.fatigue.clear()
	e.creature_hp.clear()
	for id in e.roster + e.stored:
		e.fatigue[id] = 0.0
		e.creature_hp[id] = e.max_hp(id)
	e.haulers.clear()
	for id in e.roster:
		if e.can_haul(id) and e.haulers.size() < 2:
			e.haulers.append(id)
	e.pending_recruit = ""
	e.tidy_lineup()
	# Every crossing sets out with at least the starting purse: coins carry over, but a
	# caravan that spent everything last time would otherwise starve before the first stall.
	if Expedition.default_map != "test":
		e.coins = maxi(e.coins, Expedition.WORLD_START_COINS)
	# Same overworld, the fog you lifted stays lifted, and the next crossing runs the other way.
	e.setup_map(crossing_no)
	return e


# ---------- files ----------

## Save the crossing in a slot. `start` is the caravan as the crossing began; `ui` is what
## the screen was in the middle of (an ambush or battle about to happen).
static func write(slot: String, e: Expedition, crossing_no: int, start: Dictionary, ui := {}) -> bool:
	DirAccess.make_dir_recursive_absolute(dir)
	var counter := _key_counter() + 1 if is_hardcore(slot) else 0
	var body := {"version": VERSION, "slot": slot, "crossing_no": crossing_no, "counter": counter,
		"saved_at": Time.get_datetime_string_from_system(), "expedition": encode(e), "start": start, "ui": ui}
	var text := var_to_str(body)
	var f := FileAccess.open(path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text + "\n#" + _hash(text))
	f.close()
	if is_hardcore(slot):
		_write_key(counter)
	return true


## Read a save: {"slot", "expedition": Expedition, "crossing_no", "start", "ui", "saved_at"},
## or {"error": text}.
static func read(slot: String) -> Dictionary:
	if not exists(slot):
		return {"error": "No save here."}
	var raw := FileAccess.get_file_as_string(path(slot))
	var cut := raw.rfind("\n#")
	if cut < 0:
		return {"error": "This save is damaged."}
	var text := raw.substr(0, cut)
	if is_hardcore(slot) and raw.substr(cut + 2).strip_edges() != _hash(text):
		return {"error": "This hardcore save was changed outside the game."}
	var body: Variant = str_to_var(text)
	if not (body is Dictionary) or not body.has("expedition"):
		return {"error": "This save is damaged."}
	if is_hardcore(slot) and int(body.get("counter", 0)) < _key_counter():
		return {"error": "This is an old copy of the hardcore save, so it can't be loaded."}
	var e := Expedition.new_default()
	decode_into(e, body["expedition"])
	return {"slot": slot, "expedition": e, "crossing_no": int(body.get("crossing_no", 1)),
		"start": body.get("start", {}), "ui": body.get("ui", {}), "saved_at": String(body.get("saved_at", ""))}


## A short summary for the slot picker, without building the whole crossing.
static func summary(slot: String) -> Dictionary:
	var r := read(slot)
	if r.has("error"):
		return r
	var e: Expedition = r["expedition"]
	var levels := []
	for id in e.roster:
		levels.append(e.level(id))
	return {"crossing_no": e.crossing_no, "day": e.day, "at": e.at, "state": e.state,
		"at_name": e.map.name_of(e.at) if e.map != null else e.at,
		"roster": e.roster.duplicate(), "levels": levels, "saved_at": r["saved_at"]}


static func delete(slot: String) -> void:
	if exists(slot):
		DirAccess.remove_absolute(path(slot))


static func _hash(text: String) -> String:
	return (SALT + text).sha256_text()


static func _key_counter() -> int:
	var p := dir + "hardcore.key"
	if not FileAccess.file_exists(p):
		return 0
	return int(FileAccess.get_file_as_string(p).strip_edges())


static func _write_key(counter: int) -> void:
	var f := FileAccess.open(dir + "hardcore.key", FileAccess.WRITE)
	if f != null:
		f.store_string(str(counter))
		f.close()

class_name HallOfFame
extends RefCounted
## The Hall of Fame: every crossing you finish, with the team that got you there. Kept in one
## file for the whole game (all save slots), newest first, up to MAX entries.

const MAX := 60
static var path := "user://hall_of_fame.json"


static func entries() -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Array else []


## The entry for an arrived caravan (no file writing).
static func entry_for(e: Expedition, slot := "") -> Dictionary:
	var team := []
	for id in e.roster:
		team.append({"id": id, "name": e.display_name(id), "level": e.level(id), "glint": e.glints.has(id)})
	var score := e.arrival_score()
	return {"crossing": e.crossing_no, "day": e.day, "score": int(score["total"]), "rank": String(score["rank"]),
		"finale": e.finale, "team": team, "slot": slot, "date": Time.get_date_string_from_system(),
		"seals": e.seals.size()}


static func record(e: Expedition, slot := "") -> void:
	var all := entries()
	all.push_front(entry_for(e, slot))
	if all.size() > MAX:
		all.resize(MAX)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(all))

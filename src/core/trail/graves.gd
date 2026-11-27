class_name Graves
extends RefCounted
## Graves from your own past runs. When a caravan fails you write its epitaph; the stone then
## turns up as a roadside grave on later runs, on the same crossing where it fell.
## Kept in user://graves.json, shared by every save slot (it's your history, not one caravan's).

const PATH := "user://graves.json"
const MAX := 30
## Chance a roadside grave is one of yours (when you have one for this crossing).
const OWN_CHANCE := 0.6
const EPITAPH_MAX := 60

## Tests point this somewhere else.
static var path := PATH


static func all() -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Array else []


## Lay a stone: {"crossing", "day", "lead", "region", "epitaph"}.
static func lay(crossing_no: int, day: int, lead: String, region: String, epitaph: String) -> Dictionary:
	var text := epitaph.strip_edges().left(EPITAPH_MAX)
	if text == "":
		text = "Gone west."
	var g := {"crossing": crossing_no, "day": day, "lead": lead, "region": region, "epitaph": text}
	var list := all()
	list.append(g)
	while list.size() > MAX:
		list.pop_front()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(list))
	return g


## Your graves on this crossing.
static func for_crossing(crossing_no: int) -> Array:
	return all().filter(func(g): return int(g.get("crossing", 0)) == crossing_no)


## As a roadside grave line: [name, epitaph].
static func as_stone(g: Dictionary) -> Array:
	return ["%s's caravan, fell on day %d" % [String(g["lead"]), int(g["day"])], String(g["epitaph"])]

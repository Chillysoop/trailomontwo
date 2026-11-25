class_name RouteMapView
extends Control
## Draws the overworld under the fog of war: what you've seen, where you've been, the roads you
## can take now and the picked one. `full` is the big map (drag to pan, wheel to zoom, region
## names and the Trailomon met there); otherwise it's the small map around the wagon.

signal junction_clicked(id: String)

const FOG := Color(0.07, 0.08, 0.09, 0.96)
const DIM := Color(0.85, 0.80, 0.70, 0.35)
const TRAVELLED := Color("e8c26a")
const EXIT := Color(0.95, 0.92, 0.82, 0.85)
const PICKED := Color("7fe0c8")
const INK := Color("fbf4e2")
const GOAL := Color("f2a35e")
const LAND := {
	"Forest": Color("31533a"), "Hills": Color("5d6a3c"), "River": Color("2f5566"),
	"Swamp": Color("3d4b36"), "Mountain": Color("5b5b66"),
	"Blight": Color("4a2f5c"), "Glow": Color("b8a85a"),
}
const REVEAL := 95.0

var expedition: Expedition
var picked := ""
var full := false
var zoom := 0.33
var center := Vector2.ZERO
var _dragging := false
var _hover := ""
## Creature portraits, loaded before drawing (a texture first loaded inside _draw shows blank).
var _tex := {}


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func fit() -> void:
	if expedition == null:
		return
	if full and _tex.is_empty():
		for sp in Species.DATA:
			var path := "res://assets/creatures/%s.png" % sp
			if ResourceLoader.exists(path):
				_tex[sp] = load(path)
	zoom = minf(size.x / WorldMap.SIZE.x, size.y / WorldMap.SIZE.y) * 0.98 if full else 0.33
	center = WorldMap.SIZE / 2.0 if full else _wagon_pos()


func _process(_delta: float) -> void:
	if expedition != null and not full and is_visible_in_tree():
		center = center.lerp(_wagon_pos(), 0.2)
		queue_redraw()


func _pt(world: Vector2) -> Vector2:
	return (world - center) * zoom + size / 2.0


func _wagon_pos() -> Vector2:
	var m := expedition.map
	if expedition.state == Expedition.State.TRAVELLING and not expedition.trip.is_empty():
		var a: Vector2 = m.pos(expedition.trip["from"])
		var b: Vector2 = m.pos(expedition.trip["to"])
		var dist := expedition.trip_distance(expedition.trip, bool(expedition.trip.get("pushing", false)))
		var t := clampf(1.0 - expedition.trip_days_left / maxf(0.01, dist), 0.0, 1.0)
		return a.lerp(b, t)
	return m.pos(expedition.at)


func _draw() -> void:
	if expedition == null or expedition.map == null:
		return
	var m := expedition.map
	draw_rect(Rect2(Vector2.ZERO, size), FOG)
	# Revealed land, tinted by terrain.
	for id in m.junctions:
		if expedition.is_seen(id):
			var terrain: String = m.region_of(id).get("terrain", "Forest")
			var r := REVEAL * (1.25 if expedition.visited.has(id) else 1.0) * zoom
			draw_circle(_pt(m.pos(id)), r, Color(LAND.get(terrain, LAND["Forest"]), 0.55))
	for id in m.junctions:
		if expedition.is_seen(id):
			var terrain: String = m.region_of(id).get("terrain", "Forest")
			draw_circle(_pt(m.pos(id)), REVEAL * 0.6 * zoom, Color(LAND.get(terrain, LAND["Forest"]).lightened(0.1), 0.5))
	var font := get_theme_default_font()
	# Region names (and the Trailomon met there) once any of their stops are seen.
	if full:
		var shown := {}
		for id in m.junctions:
			var rid: String = m.junctions[id]["region"]
			if expedition.is_seen(id) and not shown.has(rid):
				shown[rid] = true
		for rid in shown:
			var reg: Dictionary = m.regions[rid]
			var p := _pt(reg["center"])
			draw_string(font, p + Vector2(-60, 0), String(reg["name"]), HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(INK, 0.6))
			var met: Array[String] = []
			var unknown := 0
			for sp in m.region_species(rid):
				if expedition.met_in.get(rid, {}).has(sp):
					met.append(sp)
				else:
					unknown += 1
			var x := p.x - (met.size() * 11 + (12 if unknown > 0 else 0)) / 2.0
			for sp in met.slice(0, 6):
				var tex: Texture2D = _tex.get(sp)
				if tex != null:
					draw_texture_rect(tex, Rect2(Vector2(x, p.y + 3), Vector2(11, 11)), false)
				x += 11
			if unknown > 0:
				draw_string(font, Vector2(x + 1, p.y + 12), "?", HORIZONTAL_ALIGNMENT_LEFT, 12, 8, Color(INK, 0.5))
	# Roads.
	var travelled := {}
	for i in range(1, expedition.visited.size()):
		travelled[_key(expedition.visited[i - 1], expedition.visited[i])] = true
	var exits := {}
	if expedition.state == Expedition.State.AT_JUNCTION:
		for s in expedition.exits():
			exits[s["to"]] = true
	for s in m.segments:
		var a: String = s["a"]
		var b: String = s["b"]
		var here := a == expedition.at or b == expedition.at
		var both := expedition.is_seen(a) and expedition.is_seen(b)
		if not both and not here:
			continue
		var col := DIM
		var w := 1.0
		if travelled.has(_key(a, b)):
			col = TRAVELLED
			w = 2.0
		if here and exits.size() > 0:
			var other := b if a == expedition.at else a
			col = PICKED if other == picked else EXIT
			w = 2.0 if other == picked else 1.0
		draw_line(_pt(m.pos(a)), _pt(m.pos(b)), col, w, true)
	# Stops.
	for id in m.junctions:
		var goal: bool = id == m.goal
		if not expedition.is_seen(id) and not goal:
			continue
		var p := _pt(m.pos(id))
		if p.x < -40 or p.y < -20 or p.x > size.x + 40 or p.y > size.y + 20:
			continue
		var here: bool = id == expedition.at
		var col := INK if (expedition.visited.has(id) or exits.has(id)) else Color(INK, 0.6)
		if goal:
			col = GOAL
		var kind := m.kind_of(id)
		var r := 3.5 if kind == "town" else 2.5
		draw_circle(p, r + 1.0, Color(0.1, 0.08, 0.1))
		draw_circle(p, r, col)
		if kind == "lookout":
			draw_arc(p, r + 2.5, 0, TAU, 12, Color(PICKED, 0.6), 1.0)
		if here and expedition.state != Expedition.State.TRAVELLING:
			draw_arc(p, 6.0, 0, TAU, 16, PICKED, 1.0)
		var show_name: bool = here or exits.has(id) or goal or id == _hover or (full and (kind == "town" or expedition.visited.has(id) or zoom >= 0.6))
		if show_name:
			var label: String = m.name_of(id) if (expedition.is_seen(id)) else "%s ?" % m.name_of(id)
			draw_string(font, p + Vector2(-45, -6), label, HORIZONTAL_ALIGNMENT_CENTER, 90, 7, col)
	# The wagon.
	var wp := _pt(_wagon_pos())
	draw_circle(wp, 3.0, PICKED)
	draw_arc(wp, 5.0, 0, TAU, 16, Color(PICKED, 0.6), 1.0)


func _gui_input(event: InputEvent) -> void:
	if expedition == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if full and mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var before := (mb.position - size / 2.0) / zoom + center
			zoom = clampf(zoom * (1.2 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2), 0.2, 1.2)
			center = before - (mb.position - size / 2.0) / zoom
			queue_redraw()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var hit := _junction_at(mb.position)
				if hit != "":
					junction_clicked.emit(hit)
				_dragging = full
			else:
				_dragging = false
			accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging:
			center -= mm.relative / zoom
			queue_redraw()
		var h := _junction_at(mm.position)
		if h != _hover:
			_hover = h
			queue_redraw()


func _junction_at(p: Vector2) -> String:
	var m := expedition.map
	for id in m.junctions:
		if (expedition.is_seen(id) or id == m.goal) and _pt(m.pos(id)).distance_to(p) < 6.0:
			return id
	return ""


func _key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

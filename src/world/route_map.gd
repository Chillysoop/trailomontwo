class_name RouteMapView
extends Control
## Draws the test route's junctions and segments: where you've been, where you can go, and the picked route.

const SCALE := 0.8
const DIM := Color(0.85, 0.80, 0.70, 0.25)
const TRAVELLED := Color("e8c26a")
const EXIT := Color(0.95, 0.92, 0.82, 0.75)
const PICKED := Color("7fe0c8")
const INK := Color("fbf4e2")

var expedition: Expedition
var picked := ""


func _draw() -> void:
	if expedition == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.14, 0.12, 0.55))
	var travelled := {}
	for i in range(1, expedition.visited.size()):
		travelled[_key(expedition.visited[i - 1], expedition.visited[i])] = true
	var exits := {}
	for s in expedition.exits():
		exits[s["to"]] = true
	for s in TestRoute.SEGMENTS:
		var a := _pt(s["a"])
		var b := _pt(s["b"])
		var col := DIM
		var w := 1.0
		var other := ""
		if s["a"] == expedition.at:
			other = s["b"]
		elif s["b"] == expedition.at:
			other = s["a"]
		if travelled.has(_key(s["a"], s["b"])):
			col = TRAVELLED
			w = 2.0
		if other != "" and expedition.state == Expedition.State.AT_JUNCTION:
			col = PICKED if other == picked else EXIT
			w = 2.0 if other == picked else 1.0
		draw_line(a, b, col, w)
	var font := get_theme_default_font()
	for id in TestRoute.JUNCTIONS:
		var p := _pt(id)
		var here: bool = id == expedition.at
		var goal: bool = id == TestRoute.GOAL
		var col := INK if (expedition.visited.has(id) or exits.has(id)) else Color(INK, 0.45)
		if goal:
			col = Color("f2a35e")
		draw_circle(p, 3.5 if here else 2.5, col)
		if here:
			draw_arc(p, 6.0, 0, TAU, 16, PICKED, 1.0)
		var label: String = TestRoute.junction_name(id)
		draw_string(font, p + Vector2(-40, -6), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 7, col)


func _pt(id: String) -> Vector2:
	return TestRoute.JUNCTIONS[id]["pos"] * SCALE + Vector2(4, 6)


func _key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

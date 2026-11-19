extends Node2D
## The playable crossing: pick a route at each junction, watch the caravan travel day by day,
## and manage food, water and hauling until you reach Westwatch or the crossing fails.

const SECONDS_PER_DAY := 1.2
const PANEL_POS := Vector2(338, 30)
const PANEL_SIZE := Vector2(296, 324)

var crossing: Expedition
var _backdrop: TravelBackdrop
var _caravan: Caravan
var _ui: CanvasLayer
var _hud: Label
var _hud_health: Label
var _panel: PanelContainer
var _title: Label
var _map: RouteMapView
var _routes: VBoxContainer
var _card: Label
var _go: Button
var _log: Label
var _end: PanelContainer
var _picked: Dictionary = {}
var _day_timer := 0.0


func _ready() -> void:
	_backdrop = TravelBackdrop.new()
	_backdrop.moving = false
	add_child(_backdrop)
	_caravan = Caravan.new()
	add_child(_caravan)
	_backdrop.add_foreground(self)
	_build_ui()
	start_new()


func start_new() -> void:
	crossing = Expedition.new_default()
	_caravan.setup(crossing.haulers, "rimehare")
	_caravan.set_walking(false)
	_backdrop.set_moving(false)
	_end.visible = false
	_map.expedition = crossing
	_show_junction()


# ---------- junction ----------

func _show_junction() -> void:
	_panel.visible = true
	_title.text = "At %s. Choose the next route." % TestRoute.junction_name(crossing.at)
	for c in _routes.get_children():
		c.queue_free()
	var exits := crossing.exits()
	for seg in exits:
		var b := _button("%s  ·  %s, %d day%s" % [TestRoute.junction_name(seg["to"]), seg["terrain"], seg["days"], "" if seg["days"] == 1 else "s"], 9)
		b.pressed.connect(_pick.bind(seg))
		_routes.add_child(b)
	_pick(exits[0])
	_routes.get_child(0).grab_focus.call_deferred()
	_refresh_hud()


func _pick(seg: Dictionary) -> void:
	_picked = seg
	_map.picked = seg["to"]
	_map.queue_redraw()
	var f := crossing.forecast(seg)
	var lines: Array[String] = []
	lines.append("%s  ·  %s  ·  risk %s" % [TestRoute.junction_name(seg["to"]), seg["terrain"], "●".repeat(seg["risk"]) + "○".repeat(3 - seg["risk"])])
	lines.append("Travel: %d day%s%s" % [f["days"], "" if f["days"] == 1 else "s", "  (pushing, slower)" if f["hauling"] == Hauling.Result.PUSH else ""])
	lines.append("Food: uses %d of %d%s" % [roundi(f["provisions"]), roundi(crossing.provisions), "" if f["enough_food"] else "  NOT ENOUGH"])
	lines.append("Water: uses %d of %d%s" % [roundi(f["water"]), roundi(crossing.water), "" if f["enough_water"] else "  NOT ENOUGH"])
	var haul := "Hauling: needs %d, haulers give %d  " % [roundi(f["demand"]), roundi(f["available"])]
	match f["hauling"]:
		Hauling.Result.NORMAL: haul += "OK"
		Hauling.Result.PUSH: haul += "PUSH (slower)"
		Hauling.Result.BLOCKED: haul += "TOO HEAVY"
	lines.append(haul)
	_card.text = "\n".join(lines)
	_go.disabled = not f["can_go"]
	_go.text = "Set off" if f["can_go"] else "Too heavy to travel this way"


func _set_off() -> void:
	if _picked.is_empty() or not crossing.start_trip(_picked):
		return
	_panel.visible = false
	_backdrop.set_moving(true)
	_caravan.set_walking(true)
	_log.text = "Travelling to %s..." % TestRoute.junction_name(_picked["to"])
	_day_timer = SECONDS_PER_DAY


func _process(delta: float) -> void:
	if crossing == null or crossing.state != Expedition.State.TRAVELLING:
		return
	_day_timer -= delta
	if _day_timer > 0.0:
		return
	_day_timer = SECONDS_PER_DAY
	var more := crossing.step_day()
	_log.text = crossing.journal[crossing.journal.size() - 1]
	_refresh_hud()
	if more:
		return
	_backdrop.set_moving(false)
	_caravan.set_walking(false)
	match crossing.state:
		Expedition.State.AT_JUNCTION: _show_junction()
		Expedition.State.ARRIVED: _show_end(true)
		Expedition.State.FAILED: _show_end(false)


# ---------- HUD and end ----------

func _refresh_hud() -> void:
	_hud.text = "Day %d    Food %d (%.1f days)    Water %d (%.1f days)    Cargo %d    Haulers %d" % [
		crossing.day, roundi(crossing.provisions), crossing.days_of(crossing.provisions, crossing.daily_provisions()),
		roundi(crossing.water), crossing.days_of(crossing.water, crossing.daily_water()), roundi(crossing.cargo_weight()), roundi(crossing.hauling_available())]
	_hud_health.text = "Health %d" % crossing.health
	_hud_health.add_theme_color_override("font_color", Color("ff8a7a") if crossing.health < 50 else PreviewHud.INK)


func _show_end(won: bool) -> void:
	_panel.visible = false
	_end.visible = true
	var title: Label = _end.find_child("EndTitle", true, false)
	var body: Label = _end.find_child("EndBody", true, false)
	if won:
		title.text = "You reached Westwatch"
		body.text = "Day %d. %d food and %d water left.\nThe crossing is complete." % [crossing.day, roundi(crossing.provisions), roundi(crossing.water)]
	else:
		title.text = "The crossing failed"
		body.text = "%s\nDay %d, %d visited stops." % [crossing.fail_reason, crossing.day, crossing.visited.size()]
	(_end.find_child("Again", true, false) as Button).grab_focus.call_deferred()


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 5
	add_child(_ui)

	var bar := PanelContainer.new()
	bar.position = Vector2(6, 4)
	bar.size = Vector2(628, 20)
	bar.add_theme_stylebox_override("panel", PreviewHud.box())
	var row := HBoxContainer.new()
	bar.add_child(row)
	_hud = PreviewHud.label("", 9)
	_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_hud)
	_hud_health = PreviewHud.label("", 9)
	row.add_child(_hud_health)
	_ui.add_child(bar)

	_panel = PanelContainer.new()
	_panel.position = PANEL_POS
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.88)))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_panel.add_child(col)
	_title = PreviewHud.label("", 10)
	col.add_child(_title)
	_map = RouteMapView.new()
	_map.custom_minimum_size = Vector2(296 - 12, 128)
	col.add_child(_map)
	_routes = VBoxContainer.new()
	_routes.add_theme_constant_override("separation", 2)
	col.add_child(_routes)
	_card = PreviewHud.label("", 8)
	col.add_child(_card)
	_go = _button("Set off", 10)
	_go.pressed.connect(_set_off)
	col.add_child(_go)
	_ui.add_child(_panel)

	_log = PreviewHud.label("", 9)
	_log.position = Vector2(10, 340)
	_log.add_theme_color_override("font_outline_color", Color("2b2030"))
	_log.add_theme_constant_override("outline_size", 4)
	_ui.add_child(_log)

	_end = PanelContainer.new()
	_end.position = Vector2(170, 110)
	_end.custom_minimum_size = Vector2(300, 120)
	_end.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.94)))
	var ecol := VBoxContainer.new()
	ecol.add_theme_constant_override("separation", 6)
	_end.add_child(ecol)
	var et := PreviewHud.label("", 16)
	et.name = "EndTitle"
	ecol.add_child(et)
	var eb := PreviewHud.label("", 9)
	eb.name = "EndBody"
	ecol.add_child(eb)
	var again := _button("Try again", 10)
	again.name = "Again"
	again.pressed.connect(start_new)
	ecol.add_child(again)
	var back := _button("Back to title", 10)
	back.pressed.connect(get_tree().change_scene_to_file.bind("res://scenes/title_screen.tscn"))
	ecol.add_child(back)
	_ui.add_child(_end)


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", PreviewHud.box(Color(0.22, 0.17, 0.24, 0.9)))
	b.add_theme_stylebox_override("hover", PreviewHud.box(Color(0.32, 0.24, 0.32, 0.95)))
	b.add_theme_stylebox_override("focus", PreviewHud.box(Color(0.32, 0.24, 0.32, 0.95)))
	b.add_theme_stylebox_override("pressed", PreviewHud.box(Color(0.45, 0.33, 0.30, 0.95)))
	b.add_theme_stylebox_override("disabled", PreviewHud.box(Color(0.18, 0.14, 0.16, 0.7)))
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

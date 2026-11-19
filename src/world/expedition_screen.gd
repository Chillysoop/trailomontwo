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
var _route_page: VBoxContainer
var _wagon_page: VBoxContainer
var _tab_route: Button
var _tab_wagon: Button
var _wagon_status: Label
var _hauler_list: VBoxContainer
var _cargo_list: VBoxContainer
var _rest: Button
var _repair: Button
var _routes: GridContainer
var _card: Label
var _go: Button
var _log: Label
var _end: PanelContainer
var _event: PanelContainer
var _event_title: Label
var _event_text: Label
var _event_choices: VBoxContainer
var _event_result: Label
var _event_continue: Button
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
	_event.visible = false
	_map.expedition = crossing
	_show_junction()


# ---------- junction ----------

func _show_junction() -> void:
	_panel.visible = true
	_title.text = "At %s" % TestRoute.junction_name(crossing.at)
	for c in _routes.get_children():
		c.queue_free()
	var exits := crossing.exits()
	for seg in exits:
		var b := _button("%s\n%s, %d day%s" % [TestRoute.junction_name(seg["to"]), seg["terrain"], seg["days"], "" if seg["days"] == 1 else "s"], 8)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_pick.bind(seg))
		_routes.add_child(b)
	_pick(exits[0])
	_show_tab(false)
	_refresh_wagon_page()
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
	var wear := "Wagon wear: %d -> %d" % [roundi(crossing.wagon.wear), mini(100, roundi(f["wear_after"]))]
	if f["wear_after"] >= Wagon.WARN_WEAR:
		wear += "  BREAKDOWN RISK"
	lines.append(wear)
	_card.text = "\n".join(lines)
	_go.disabled = not f["can_go"]
	if f["can_go"]:
		_go.text = "Set off"
	elif f["stranded"]:
		_go.text = "The axle is broken. Repair the wagon first"
	elif crossing.haulers.is_empty():
		_go.text = "No haulers in harness"
	else:
		_go.text = "Too heavy to travel this way"


func _set_off() -> void:
	if _picked.is_empty() or not crossing.start_trip(_picked):
		return
	_panel.visible = false
	_backdrop.set_moving(true)
	_caravan.set_walking(true)
	_log.text = "Travelling to %s..." % TestRoute.junction_name(_picked["to"])
	_day_timer = SECONDS_PER_DAY


func _process(delta: float) -> void:
	if crossing == null or crossing.state != Expedition.State.TRAVELLING or _event.visible:
		return
	_day_timer -= delta
	if _day_timer > 0.0:
		return
	_day_timer = SECONDS_PER_DAY
	var before := crossing.journal.size()
	var more := crossing.step_day()
	_log.text = "   ".join(crossing.journal.slice(before))
	_refresh_hud()
	if not crossing.pending_event.is_empty():
		_backdrop.set_moving(false)
		_caravan.set_walking(false)
		_show_event()
		return
	if more:
		return
	_after_trip()


func _after_trip() -> void:
	_backdrop.set_moving(false)
	_caravan.set_walking(false)
	match crossing.state:
		Expedition.State.AT_JUNCTION: _show_junction()
		Expedition.State.ARRIVED: _show_end(true)
		Expedition.State.FAILED: _show_end(false)


# ---------- events ----------

func _show_event() -> void:
	var ev := crossing.pending_event
	_event.visible = true
	_event_title.text = ev["title"]
	_event_text.text = ev["text"]
	_event_result.visible = false
	_event_continue.visible = false
	for c in _event_choices.get_children():
		c.queue_free()
	var views := crossing.event_choices(ev)
	for i in views.size():
		var v: Dictionary = views[i]
		var line: String = v["label"]
		if not v["safe"]:
			var odds: Dictionary = v["odds"]
			var who: String = Species.info(v["helper"])["name"] + " helps" if v["helper"] != "" else "nobody can help"
			line += "\n    %s:  %d%% success, %d%% mixed, %d%% bad" % [who, odds["success"], odds["mixed"], odds["failure"]]
		var b := _button(line, 8)
		b.pressed.connect(_choose_event.bind(i))
		_event_choices.add_child(b)
	_event_choices.get_child(0).grab_focus.call_deferred()


func _choose_event(i: int) -> void:
	var r := crossing.resolve_event(i)
	for c in _event_choices.get_children():
		c.queue_free()
	var head: String = {"success": "It went well.", "mixed": "It went partly well.", "failure": "It went badly."}[r["outcome"]]
	_event_result.text = "%s %s" % [head, r["text"]]
	_event_result.add_theme_color_override("font_color", {"success": Color("9fe0a0"), "mixed": Color("f0d27a"), "failure": Color("ff8a7a")}[r["outcome"]])
	_event_result.visible = true
	_event_continue.visible = true
	_event_continue.grab_focus.call_deferred()
	_refresh_hud()


func _continue_after_event() -> void:
	_event.visible = false
	if crossing.state == Expedition.State.TRAVELLING:
		_backdrop.set_moving(true)
		_caravan.set_walking(true)
		_day_timer = SECONDS_PER_DAY
	else:
		_after_trip()


# ---------- wagon & cargo ----------

func _show_tab(wagon: bool) -> void:
	_route_page.visible = not wagon
	_wagon_page.visible = wagon
	_tab_route.disabled = not wagon
	_tab_wagon.disabled = wagon
	if wagon:
		_tab_route.grab_focus.call_deferred()
	elif _routes.get_child_count() > 0:
		_routes.get_child(0).grab_focus.call_deferred()


func _refresh_wagon_page() -> void:
	var w := crossing.wagon
	var status := "Wagon: integrity %d%%, wear %d/100" % [w.integrity, roundi(w.wear)]
	if w.broken != Wagon.Part.NONE:
		status += "\nBROKEN %s: %s" % [w.part_name().to_upper(), {
			Wagon.Part.RUNNING_GEAR: "can't leave until repaired",
			Wagon.Part.HARNESS: "hauling is weaker",
			Wagon.Part.CANOPY: "water spoils faster"}[w.broken]]
	elif w.warning():
		status += "\nWorn: it may break down on the trail"
	status += "\nRepair kits: %d" % crossing.repair_kits
	_wagon_status.text = status
	for c in _hauler_list.get_children():
		c.queue_free()
	for id in crossing.roster:
		if not crossing.can_haul(id):
			continue
		var on := crossing.haulers.has(id)
		var b := _button("%s %s  pulls %d  tired %d%%" % ["[x]" if on else "[  ]", Species.info(id)["name"], roundi(crossing.hauler_strength(id)), roundi(crossing.fatigue.get(id, 0.0))], 8)
		b.pressed.connect(_toggle_hauler.bind(id))
		_hauler_list.add_child(b)
	for c in _cargo_list.get_children():
		c.queue_free()
	for i in crossing.cargo.size():
		var item: Dictionary = crossing.cargo[i]
		var row := HBoxContainer.new()
		var l := PreviewHud.label("%s  ·  %d wt  ·  worth %d" % [item["name"], roundi(item["weight"]), item.get("value", 0)], 8)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var drop := _button("Drop", 8)
		drop.pressed.connect(_drop.bind(i))
		row.add_child(drop)
		_cargo_list.add_child(row)
	if crossing.cargo.is_empty():
		_cargo_list.add_child(PreviewHud.label("Nothing left to deliver.", 8))
	var kit := crossing.repair_kits > 0
	_repair.text = "Repair (1 day, uses a kit)" if kit else "Patch up (2 days, no kit)"
	_repair.disabled = w.broken == Wagon.Part.NONE and w.wear < 1.0


func _after_action() -> void:
	_caravan.setup(crossing.haulers, "rimehare")
	_refresh_hud()
	if crossing.state == Expedition.State.FAILED:
		_show_end(false)
		return
	_log.text = crossing.journal[crossing.journal.size() - 1] if crossing.journal.size() > 0 else ""
	_pick(_picked)
	_refresh_wagon_page()


func _toggle_hauler(id: String) -> void:
	crossing.toggle_hauler(id)
	_after_action()


func _drop(index: int) -> void:
	crossing.drop_cargo(index)
	_after_action()


func _do_rest() -> void:
	crossing.rest()
	_after_action()


func _do_repair() -> void:
	crossing.repair()
	_after_action()


# ---------- HUD and end ----------

func _refresh_hud() -> void:
	_hud.text = "Day %d    Food %d (%.1f days)    Water %d (%.1f days)    Cargo %d    Haul %d    Wagon %d%%" % [
		crossing.day, roundi(crossing.provisions), crossing.days_of(crossing.provisions, crossing.daily_provisions()),
		roundi(crossing.water), crossing.days_of(crossing.water, crossing.daily_water()), roundi(crossing.cargo_weight()), roundi(crossing.hauling_available()), crossing.wagon.integrity]
	_hud_health.text = "Health %d" % crossing.health
	_hud_health.add_theme_color_override("font_color", Color("ff8a7a") if crossing.health < 50 else PreviewHud.INK)


func _show_end(won: bool) -> void:
	_panel.visible = false
	_end.visible = true
	var title: Label = _end.find_child("EndTitle", true, false)
	var body: Label = _end.find_child("EndBody", true, false)
	if won:
		title.text = "You reached Westwatch"
		body.text = "Day %d. %d food and %d water left.\nDelivered %d cargo worth %d. Wagon at %d%%." % [crossing.day, roundi(crossing.provisions), roundi(crossing.water), crossing.cargo.size(), crossing.cargo_value(), crossing.wagon.integrity]
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
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	_title = PreviewHud.label("", 10)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(_title)
	_tab_route = _button("Route", 9)
	_tab_route.pressed.connect(_show_tab.bind(false))
	tabs.add_child(_tab_route)
	_tab_wagon = _button("Wagon & cargo", 9)
	_tab_wagon.pressed.connect(_show_tab.bind(true))
	tabs.add_child(_tab_wagon)
	col.add_child(tabs)

	_route_page = VBoxContainer.new()
	_route_page.add_theme_constant_override("separation", 3)
	col.add_child(_route_page)
	_map = RouteMapView.new()
	_map.custom_minimum_size = Vector2(296 - 12, 128)
	_route_page.add_child(_map)
	_routes = GridContainer.new()
	_routes.columns = 2
	_routes.add_theme_constant_override("h_separation", 3)
	_routes.add_theme_constant_override("v_separation", 3)
	_route_page.add_child(_routes)
	_card = PreviewHud.label("", 8)
	_route_page.add_child(_card)
	_go = _button("Set off", 10)
	_go.pressed.connect(_set_off)
	_route_page.add_child(_go)

	_wagon_page = VBoxContainer.new()
	_wagon_page.add_theme_constant_override("separation", 3)
	_wagon_page.visible = false
	col.add_child(_wagon_page)
	_wagon_status = PreviewHud.label("", 8)
	_wagon_page.add_child(_wagon_status)
	_wagon_page.add_child(PreviewHud.label("Haulers (click to harness or unhitch)", 9))
	_hauler_list = VBoxContainer.new()
	_hauler_list.add_theme_constant_override("separation", 2)
	_wagon_page.add_child(_hauler_list)
	_wagon_page.add_child(PreviewHud.label("Cargo (drop it to lighten the load)", 9))
	_cargo_list = VBoxContainer.new()
	_cargo_list.add_theme_constant_override("separation", 2)
	_wagon_page.add_child(_cargo_list)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 4)
	_rest = _button("Rest a day", 9)
	_rest.pressed.connect(_do_rest)
	acts.add_child(_rest)
	_repair = _button("Repair", 9)
	_repair.pressed.connect(_do_repair)
	acts.add_child(_repair)
	_wagon_page.add_child(acts)
	_ui.add_child(_panel)

	_log = PreviewHud.label("", 9)
	_log.position = Vector2(10, 340)
	_log.add_theme_color_override("font_outline_color", Color("2b2030"))
	_log.add_theme_constant_override("outline_size", 4)
	_ui.add_child(_log)

	_event = PanelContainer.new()
	_event.position = Vector2(150, 64)
	_event.custom_minimum_size = Vector2(340, 0)
	_event.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.94)))
	var vcol := VBoxContainer.new()
	vcol.add_theme_constant_override("separation", 5)
	_event.add_child(vcol)
	_event_title = PreviewHud.label("", 14)
	vcol.add_child(_event_title)
	_event_text = PreviewHud.label("", 9)
	_event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_text.custom_minimum_size = Vector2(328, 0)
	vcol.add_child(_event_text)
	_event_choices = VBoxContainer.new()
	_event_choices.add_theme_constant_override("separation", 3)
	vcol.add_child(_event_choices)
	_event_result = PreviewHud.label("", 9)
	_event_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_result.custom_minimum_size = Vector2(328, 0)
	vcol.add_child(_event_result)
	_event_continue = _button("Continue", 10)
	_event_continue.pressed.connect(_continue_after_event)
	vcol.add_child(_event_continue)
	_event.visible = false
	_ui.add_child(_event)

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
	# Small buttons get tight padding so lists fit the panel.
	var pad_y := 1 if size <= 8 else 3
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		var sb: StyleBoxFlat = b.get_theme_stylebox(state)
		sb.content_margin_top = pad_y
		sb.content_margin_bottom = pad_y
		sb.content_margin_left = 5
		sb.content_margin_right = 5
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

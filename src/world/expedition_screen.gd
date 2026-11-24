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
var _hud: RichTextLabel
var _hud_health: RichTextLabel
var _hover: HoverZones
var _panel: PanelContainer
var _title: Label
var _map: RouteMapView
var _route_page: VBoxContainer
var _wagon_page: VBoxContainer
var _tab_route: Button
var _tab_wagon: Button
var _wagon_status: RichTextLabel
var _hauler_list: VBoxContainer
var _cargo_list: VBoxContainer
var _rest: Button
var _repair: Button
var _routes: GridContainer
var _card: RichTextLabel
var _go: Button
var _log: Label
var _end: PanelContainer
var _event: PanelContainer
var _event_title: Label
var _event_text: Label
var _event_choices: VBoxContainer
var _event_result: Label
var _event_continue: Button
var _team_status: VBoxContainer
var _battle: BattleScreen
## What happens when the event panel's Continue is pressed: "" resumes travel, "battle" or "ambush" opens a fight.
var _continue_to := ""
var _picked: Dictionary = {}
var _day_timer := 0.0


var _companions: CompanionsScreen
var _comp_btn: Button


func _ready() -> void:
	_backdrop = TravelBackdrop.new()
	_backdrop.moving = false
	add_child(_backdrop)
	_caravan = Caravan.new()
	add_child(_caravan)
	_backdrop.add_foreground(self)
	_hover = HoverZones.new()
	add_child(_hover)
	_build_ui()
	start_new()


func start_new() -> void:
	crossing = Expedition.new_default()
	_setup_caravan()
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
		var b := _button("%s\n%d day%s" % [TestRoute.junction_name(seg["to"]), seg["days"], "" if seg["days"] == 1 else "s"], 8)
		b.icon = Rich.icon_tex(Glossary.habitat_id(seg["terrain"]))
		b.add_theme_constant_override("icon_max_width", 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Tips.attach(b, func(): return "{ik:%s} road to %s\n{i:day} %d day%s   %s risk" % [Glossary.habitat_id(seg["terrain"]), TestRoute.junction_name(seg["to"]),
			seg["days"], "" if seg["days"] == 1 else "s", "{i:risk}".repeat(seg["risk"])])
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
	lines.append("[b]%s[/b]  {ik:%s}  {k:risk|Risk} %s" % [TestRoute.junction_name(seg["to"]), Glossary.habitat_id(seg["terrain"]), "{i:risk}".repeat(seg["risk"])])
	lines.append("{i:day} %d day%s%s" % [f["days"], "" if f["days"] == 1 else "s", "  ({k:push|pushing}, slower)" if f["hauling"] == Hauling.Result.PUSH else ""])
	var bad := "[color=#ff8a7a]%s[/color]"
	lines.append("{i:food} uses %d of %d%s     {i:water} uses %d of %d%s" % [
		roundi(f["provisions"]), roundi(crossing.provisions), "" if f["enough_food"] else " " + bad % "NOT ENOUGH",
		roundi(f["water"]), roundi(crossing.water), "" if f["enough_water"] else " " + bad % "NOT ENOUGH"])
	var haul := "{i:haul} needs %d, haulers give %d  " % [roundi(f["demand"]), roundi(f["available"])]
	match f["hauling"]:
		Hauling.Result.NORMAL: haul += "[color=#9fe0a0]OK[/color]"
		Hauling.Result.PUSH: haul += "[color=#f0d27a]{k:push|PUSHING}[/color]"
		Hauling.Result.BLOCKED: haul += bad % "TOO HEAVY"
	lines.append(haul)
	var wear := "{i:wagon} wear %d -> %d" % [roundi(crossing.wagon.wear), mini(100, roundi(f["wear_after"]))]
	if f["wear_after"] >= Wagon.WARN_WEAR:
		wear += "  " + bad % "{k:breakdown|BREAKDOWN} RISK"
	lines.append(wear)
	Rich.set_text(_card, "\n".join(lines))
	_go.disabled = not f["can_go"]
	if f["can_go"]:
		_go.text = "Set off"
	elif f["stranded"]:
		_go.text = "The axle is broken. Repair the wagon first"
	elif crossing.haulers.is_empty():
		_go.text = "No haulers in harness"
	elif f["available"] <= 0.0:
		_go.text = "Haulers are knocked out. Rest first"
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
	if crossing == null or crossing.state != Expedition.State.TRAVELLING or _event.visible or _battle != null or _companions != null:
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
	if not crossing.pending_encounter.is_empty():
		_backdrop.set_moving(false)
		_caravan.set_walking(false)
		_show_encounter()
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
	_event_continue.text = "Continue"
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
		_helper_icon(b, v)
		b.pressed.connect(_choose_event.bind(i))
		_event_choices.add_child(b)
	_event_choices.get_child(0).grab_focus.call_deferred()


## Shows the helping creature's portrait on a choice, with its card on hover.
func _helper_icon(b: Button, v: Dictionary) -> void:
	var helper: String = v.get("helper", "")
	if v.get("safe", true) or helper == "":
		return
	b.icon = load("res://assets/creatures/%s.png" % helper)
	b.add_theme_constant_override("icon_max_width", 16)
	Tips.attach(b, _creature_tip.bind(helper, false))


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
	var next := _continue_to
	_continue_to = ""
	if next != "" and crossing.state == Expedition.State.TRAVELLING:
		_open_battle(next == "ambush")
		return
	if crossing.state == Expedition.State.TRAVELLING:
		_backdrop.set_moving(true)
		_caravan.set_walking(true)
		_day_timer = SECONDS_PER_DAY
	else:
		_after_trip()


# ---------- battles ----------

func _show_encounter() -> void:
	var enc := crossing.pending_encounter
	var pack: Dictionary = enc["pack"]
	_event.visible = true
	_event_title.text = pack["title"]
	_event_text.text = pack["text"]
	_event_result.visible = false
	_event_continue.visible = false
	for c in _event_choices.get_children():
		c.queue_free()
	for v in crossing.encounter_choices():
		var line: String = v["label"]
		if v["id"] == "fight":
			line += "  (set your lineup first)" if crossing.can_fight() else "  (nobody can fight: they'll reach the wagon)"
		elif not v["safe"]:
			var odds: Dictionary = v["odds"]
			var who: String = Species.info(v["helper"])["name"] + " scouts" if v["helper"] != "" else "nobody can scout"
			line += "\n    %s:  %d%% clean, %d%% tiring detour, %d%% ambushed" % [who, odds["success"], odds["mixed"], odds["failure"]]
		var b := _button(line, 8)
		_helper_icon(b, v)
		b.pressed.connect(_choose_encounter.bind(v["id"]))
		_event_choices.add_child(b)
	_event_choices.get_child(0).grab_focus.call_deferred()


func _choose_encounter(id: String) -> void:
	if id == "fight":
		_event.visible = false
		_open_battle(false)
		return
	var r := crossing.resolve_encounter(id)
	for c in _event_choices.get_children():
		c.queue_free()
	_event_result.text = r["text"]
	_event_result.add_theme_color_override("font_color", {"success": Color("9fe0a0"), "mixed": Color("f0d27a"), "failure": Color("ff8a7a")}[r["outcome"]])
	_event_result.visible = true
	_event_continue.visible = true
	_event_continue.text = "To battle!" if r["fight"] else "Continue"
	_continue_to = "ambush" if r["fight"] else ""
	_event_continue.grab_focus.call_deferred()
	_refresh_hud()


func _open_battle(ambushed: bool) -> void:
	if not crossing.can_fight():
		var lines := crossing.finish_battle(null)
		_event.visible = true
		_event_title.text = "The wagon is overrun"
		_event_text.text = ""
		for c in _event_choices.get_children():
			c.queue_free()
		_event_result.text = "\n".join(lines)
		_event_result.add_theme_color_override("font_color", Color("ff8a7a"))
		_event_result.visible = true
		_event_continue.text = "Continue"
		_event_continue.visible = true
		_refresh_hud()
		return
	_ui.visible = false
	_backdrop.visible = false
	_caravan.visible = false
	_battle = BattleScreen.new()
	_battle.setup(crossing, ambushed)
	_battle.finished.connect(_on_battle_finished)
	add_child(_battle)


func _on_battle_finished(lines: Array) -> void:
	_battle.queue_free()
	_battle = null
	_ui.visible = true
	_backdrop.visible = true
	_caravan.visible = true
	_log.text = "   ".join(lines.slice(0, 2))
	_refresh_hud()
	_event_continue.text = "Continue"
	_continue_after_event()


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


func _wagon_summary() -> String:
	var w := crossing.wagon
	var status := "{i:wagon} %d%%  wear %d/100     {i:repair_kit} %d kit%s" % [w.integrity, roundi(w.wear), crossing.repair_kits, "" if crossing.repair_kits == 1 else "s"]
	if w.broken != Wagon.Part.NONE:
		status += "\n[color=#ff8a7a]BROKEN %s[/color]: %s" % [w.part_name().to_upper(), {
			Wagon.Part.RUNNING_GEAR: "can't leave until repaired",
			Wagon.Part.HARNESS: "hauling is weaker",
			Wagon.Part.CANOPY: "water spoils faster"}[w.broken]]
	elif w.warning():
		status += "\n[color=#f0d27a]Worn[/color]: it may have a {k:breakdown} on the trail"
	return status


func _refresh_wagon_page() -> void:
	var w := crossing.wagon
	Rich.set_text(_wagon_status, _wagon_summary())
	# Team: one hoverable portrait per creature with its health.
	for c in _team_status.get_children():
		c.queue_free()
	_team_status.add_child(Rich.label("Team {i:hp} (rest a day to heal):", 8))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 1)
	_team_status.add_child(grid)
	for id in crossing.roster:
		var hp := roundi(float(crossing.creature_hp.get(id, 0.0)))
		var cell := Rich.label("{c:%s} %s" % [id, ("%d" % hp) if hp > 0 else "{i:ko}"], 8)
		cell.custom_minimum_size = Vector2(92, 0)
		grid.add_child(cell)
	for c in _hauler_list.get_children():
		c.queue_free()
	for id in crossing.roster:
		if not crossing.can_haul(id):
			continue
		var on := crossing.haulers.has(id)
		var b := _button("%s %s   pulls %d   tired %d%%" % ["[x]" if on else "[  ]", Species.info(id)["name"], roundi(crossing.hauler_strength(id)), roundi(crossing.fatigue.get(id, 0.0))], 8)
		b.icon = load("res://assets/creatures/%s.png" % id)
		b.add_theme_constant_override("icon_max_width", 16)
		b.pressed.connect(_toggle_hauler.bind(id))
		Tips.attach(b, _creature_tip.bind(id, on))
		_hauler_list.add_child(b)
	for c in _cargo_list.get_children():
		c.queue_free()
	for i in crossing.cargo.size():
		var item: Dictionary = crossing.cargo[i]
		var row := HBoxContainer.new()
		var l := Rich.label("{i:cargo} %s   {i:weight}%d   {i:value}%d" % [item["name"], roundi(item["weight"]), item.get("value", 0)], 8)
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
	_repair.icon = Rich.icon_tex("repair_kit")
	_repair.disabled = w.broken == Wagon.Part.NONE and w.wear < 1.0


func _setup_caravan() -> void:
	_caravan.setup(crossing.haulers, "rimehare")
	_hover.clear()
	_hover.add(Rect2(Caravan.WAGON_FEET + Vector2(-80, -170), Vector2(160, 172)), _wagon_tip)
	var shown := crossing.haulers.slice(0, Caravan.HAULER_SLOTS.size())
	for i in shown.size():
		_hover.add(HoverZones.creature_rect(Caravan.HAULER_SLOTS[i]), _creature_tip.bind(shown[i], true))
	_hover.add(HoverZones.creature_rect(Caravan.COMPANION_FEET), _creature_tip.bind("rimehare", false))


func _creature_tip(id: String, hauling: bool) -> String:
	if crossing == null:
		return ""
	var t := CreatureCard.markup(id, {"hp": crossing.creature_hp.get(id, 0.0), "max_hp": crossing.max_hp(id),
		"fatigue": crossing.fatigue.get(id, 0.0)})
	if hauling:
		t += "\nIn harness: pulls {i:haul}%d" % roundi(crossing.hauler_strength(id))
	return t


func _wagon_tip() -> String:
	if crossing == null:
		return ""
	return "{ik:wagon}\n" + _wagon_summary()


func _after_action() -> void:
	_setup_caravan()
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
	Rich.set_text(_hud, "{i:day}Day %d    {i:food}%d [color=#c8bca8](%.1fd)[/color]    {i:water}%d [color=#c8bca8](%.1fd)[/color]    {i:cargo}%d    {i:haul}%d    {i:wagon}%d%%" % [
		crossing.day, roundi(crossing.provisions), crossing.days_of(crossing.provisions, crossing.daily_provisions()),
		roundi(crossing.water), crossing.days_of(crossing.water, crossing.daily_water()), roundi(crossing.cargo_weight()), roundi(crossing.hauling_available()), crossing.wagon.integrity])
	Rich.set_text(_hud_health, ("{i:health}[color=#ff8a7a]%d[/color]" if crossing.health < 50 else "{i:health}%d") % crossing.health)
	if _comp_btn != null:
		var n := crossing.pending_count()
		_comp_btn.text = "Companions (%d level up%s!)" % [n, "" if n == 1 else "s"] if n > 0 else "Companions"


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
	_hud = Rich.label("", 9)
	_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_hud)
	_hud_health = Rich.label("", 9)
	row.add_child(_hud_health)
	# Always reachable, at a junction or on the road (travel pauses while it's open).
	var comp := _button("Companions", 8)
	comp.focus_mode = Control.FOCUS_NONE
	comp.pressed.connect(_open_companions)
	Tips.attach(comp, func(): return "Your team: stats, moves and memory slots, plus the Trailomon in storage. Travel pauses while it's open.")
	row.add_child(comp)
	_comp_btn = comp
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
	_tab_wagon.icon = Rich.icon_tex("wagon")
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
	_card = Rich.label("", 8, 284)
	_route_page.add_child(_card)
	_go = _button("Set off", 10)
	_go.pressed.connect(_set_off)
	_route_page.add_child(_go)

	_wagon_page = VBoxContainer.new()
	_wagon_page.add_theme_constant_override("separation", 3)
	_wagon_page.visible = false
	col.add_child(_wagon_page)
	_wagon_status = Rich.label("", 8, 284)
	_wagon_page.add_child(_wagon_status)
	_team_status = VBoxContainer.new()
	_team_status.add_theme_constant_override("separation", 1)
	_wagon_page.add_child(_team_status)
	_wagon_page.add_child(Rich.label("{i:haul} Haulers (click to harness or unhitch)", 9))
	_hauler_list = VBoxContainer.new()
	_hauler_list.add_theme_constant_override("separation", 2)
	_wagon_page.add_child(_hauler_list)
	_wagon_page.add_child(Rich.label("{i:cargo} Cargo (drop it to lighten the load)", 9))
	_cargo_list = VBoxContainer.new()
	_cargo_list.add_theme_constant_override("separation", 2)
	_wagon_page.add_child(_cargo_list)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 4)
	_rest = _button("Rest a day", 9)
	_rest.icon = Rich.icon_tex("tired")
	Tips.attach(_rest, func(): return "Spend a {i:day} day. Haulers lose {k:tired|tiredness}, creatures heal, {k:ko|knocked out} ones wake up. Costs {i:food} and {i:water}.")
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


func _open_companions() -> void:
	if _companions != null and is_instance_valid(_companions):
		return
	_companions = CompanionsScreen.open(_ui, crossing)
	_companions.closed.connect(func():
		_companions = null
		_refresh_hud())


func _button(text: String, size: int) -> Button:
	return Ui.button(text, size)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

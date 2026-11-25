extends Node2D
## The playable crossing: pick a route at each junction, watch the caravan travel day by day,
## and manage food, water and hauling until you reach Westwatch or the crossing fails.

const SECONDS_PER_DAY := 2.0
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
var _title: RichTextLabel
var _map: RouteMapView
var _travel_map: RouteMapView
var _world: PanelContainer
var _world_map: RouteMapView
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
var _event_title: RichTextLabel
var _event_text: Label
var _event_choices: VBoxContainer
var _event_result: RichTextLabel
var _ambience: TrailAmbience
var _toasts: VBoxContainer
var _moment_seen := 0
var _pace_btn: Button
var _ration_btn: Button
var _tab_trade: Button
var _trade_page: VBoxContainer
var _trade_list: GridContainer
var _rumor: RichTextLabel
var _coins_label: RichTextLabel
var _event_continue: Button
var _team_status: VBoxContainer
var _battle: BattleScreen
## What happens when the event panel's Continue is pressed: "" resumes travel, "battle" or "ambush" opens a fight.
var _continue_to := ""
var _picked: Dictionary = {}
var _day_timer := 0.0


var _companions: CompanionsScreen
var _comp_btn: Button

## Which crossing this caravan is on (1 for a new caravan), and the save slot it autosaves to
## ("" = no saving, e.g. tests and previews).
var crossing_no := 1
var _slot := ""
## The caravan (team progress) as this crossing began, so a failed crossing can be retried.
var _start := {}
## True while a battle is open, and whether it was an ambush, so a reload lands in the fight.
var _in_battle := false
var _battle_ambush := false


func _ready() -> void:
	_backdrop = TravelBackdrop.new()
	_backdrop.moving = false
	add_child(_backdrop)
	_ambience = TrailAmbience.new()
	add_child(_ambience)
	_caravan = Caravan.new()
	add_child(_caravan)
	_backdrop.add_foreground(self)
	_hover = HoverZones.new()
	add_child(_hover)
	_build_ui()
	start_new()


## Open the save picked on the title screen, or start a brand-new caravan.
func start_new() -> void:
	_slot = SaveGame.current_slot
	var loaded: Dictionary = SaveGame.pending
	SaveGame.pending = {}
	if loaded.is_empty():
		_begin(Expedition.new_default(), 1)
		return
	crossing = loaded["expedition"]
	crossing_no = int(loaded["crossing_no"])
	_start = loaded["start"] if not (loaded["start"] as Dictionary).is_empty() else SaveGame.caravan(crossing)
	_reset_view()
	_resume(loaded["ui"])


## Start a crossing (new, next or retried) and save it.
func _begin(e: Expedition, no: int) -> void:
	crossing = e
	crossing_no = no
	_start = SaveGame.caravan(e)
	_continue_to = ""
	_reset_view()
	_show_junction()


func _reset_view() -> void:
	_setup_caravan()
	_caravan.set_walking(false)
	_backdrop.set_moving(false)
	_end.visible = false
	_event.visible = false
	_moment_seen = 0
	for t in _toasts.get_children():
		t.queue_free()
	_map.expedition = crossing
	_travel_map.expedition = crossing
	_world_map.expedition = crossing
	_map.fit()
	_travel_map.fit()
	_ambience.encountered = crossing.encountered
	_ambience.set_weather(crossing.weather)


## Pick up a loaded crossing where it was left.
func _resume(ui: Dictionary) -> void:
	match crossing.state:
		Expedition.State.ARRIVED:
			_show_end(true)
			return
		Expedition.State.FAILED:
			_show_end(false)
			return
		Expedition.State.AT_JUNCTION:
			_show_junction()
			return
	_panel.visible = false
	_refresh_hud()
	if bool(ui.get("battle", false)) and not crossing.pending_encounter.is_empty():
		if SaveGame.is_hardcore(_slot):
			_auto_battle(bool(ui.get("ambush", false)))
		else:
			_open_battle(bool(ui.get("ambush", false)))
	elif String(ui.get("next", "")) != "" and not crossing.pending_encounter.is_empty():
		_open_battle(String(ui["next"]) == "ambush")
	elif not crossing.pending_event.is_empty():
		_show_event()
	elif not crossing.pending_encounter.is_empty():
		_show_encounter()
	else:
		_ambience.set_terrain(String(crossing.trip.get("terrain", "Forest")))
		_resume_travel()
		_day_timer = SECONDS_PER_DAY


## Hardcore: leaving in the middle of a fight doesn't undo it. The fight plays out with the
## lineup and items you had, and you see how it went.
func _auto_battle(ambush: bool) -> void:
	var b := crossing.make_battle(ambush)
	b.run_to_end()
	var lines := crossing.finish_battle(b)
	_event.visible = true
	Rich.set_text(_event_title, "{i:risk} The fight went on without you")
	_event_text.text = "Hardcore: leaving mid-battle doesn't stop it."
	for c in _event_choices.get_children():
		c.queue_free()
	Rich.set_text(_event_result, "[color=#f0d27a]%s[/color]" % "\n".join(lines))
	_event_result.visible = true
	_event_continue.text = "Continue"
	_event_continue.visible = true
	_continue_to = ""
	_refresh_hud()


## Autosave to the picked slot. A failed hardcore crossing deletes the save instead.
func _save() -> void:
	if _slot == "" or crossing == null:
		return
	if SaveGame.is_hardcore(_slot) and crossing.state == Expedition.State.FAILED:
		SaveGame.delete(_slot)
		return
	SaveGame.write(_slot, crossing, crossing_no, _start,
		{"next": _continue_to, "battle": _in_battle, "ambush": _battle_ambush})


func _to_title() -> void:
	_save()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()


## After reaching Westwatch: the same team sets out on a new crossing.
func _next_crossing() -> void:
	_begin(SaveGame.next_crossing(SaveGame.caravan(crossing), -1, crossing_no + 1), crossing_no + 1)


## After a failed crossing: try it again with the team as it was when the crossing began.
## A failed hardcore caravan is gone, so it starts over from scratch.
func _retry() -> void:
	if SaveGame.is_hardcore(_slot):
		_begin(Expedition.new_default(), 1)
	else:
		_begin(SaveGame.next_crossing(_start, -1, crossing_no), crossing_no)


# ---------- junction ----------

func _show_junction() -> void:
	_panel.visible = true
	var kind: Dictionary = Settlements.KINDS.get(crossing.stop()["kind"], {"name": "Stop"})
	Rich.set_text(_title, "{i:settlement} [b]%s[/b]  [color=#c8bca8]%s[/color]" % [crossing.map.name_of(crossing.at), kind["name"]])
	_ambience.set_moving(false)
	_ambience.encountered = crossing.encountered
	_ambience.show_settlement(crossing.stop()["kind"])
	_refresh_trade()
	for c in _routes.get_children():
		c.queue_free()
	var exits := crossing.exits()
	for seg in exits:
		var b := _button("%s\n%d day%s" % [crossing.map.name_of(seg["to"]), seg["days"], "" if seg["days"] == 1 else "s"], 8)
		b.icon = Rich.icon_tex(Glossary.habitat_id(seg["terrain"]))
		b.add_theme_constant_override("icon_max_width", 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Tips.attach(b, func(): return "{ik:%s} road to %s\n{i:day} %d day%s   %s risk" % [Glossary.habitat_id(seg["terrain"]), crossing.map.name_of(seg["to"]),
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
	lines.append("[b]%s[/b]  {ik:%s}  {k:risk|Risk} %s" % [crossing.map.name_of(seg["to"]), Glossary.habitat_id(seg["terrain"]), "{i:risk}".repeat(seg["risk"])])
	lines.append("{i:day} %d day%s at {i:%s}%s     {k:weather|Weather} %s" % [f["days"], "" if f["days"] == 1 else "s", TrailLife.pace(crossing.pace)["icon"],
		"  ({k:push|pushing})" if f["hauling"] == Hauling.Result.PUSH else "", _forecast_icons(seg["terrain"])])
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


## The three likeliest weathers on a terrain, as icons.
func _forecast_icons(terrain: String) -> String:
	var table: Dictionary = TrailLife.WEATHER_TABLE.get(terrain, {})
	var ids := table.keys()
	ids.sort_custom(func(a, b): return int(table[a]) > int(table[b]))
	var out := ""
	for w in ids.slice(0, 3):
		out += "{i:%s}" % TrailLife.weather(w)["icon"]
	return out


func _set_off() -> void:
	if _picked.is_empty() or not crossing.start_trip(_picked):
		return
	_panel.visible = false
	_backdrop.set_moving(true)
	_caravan.set_walking(true)
	_ambience.set_terrain(_picked["terrain"])
	_ambience.set_moving(true)
	_log.text = "Travelling to %s..." % crossing.map.name_of(_picked["to"])
	_day_timer = SECONDS_PER_DAY


func _process(delta: float) -> void:
	if _travel_map != null:
		_travel_map.visible = crossing != null and crossing.state == Expedition.State.TRAVELLING and _battle == null
	if crossing == null or crossing.state != Expedition.State.TRAVELLING or _event.visible or _battle != null or _companions != null or _world.visible:
		return
	_day_timer -= delta
	if _day_timer > 0.0:
		return
	_day_timer = SECONDS_PER_DAY
	var before := crossing.journal.size()
	var more := crossing.step_day()
	_log.text = crossing.journal[before] if crossing.journal.size() > before else ""
	_ambience.set_weather(crossing.weather)
	_show_new_moments()
	_refresh_hud()
	if not crossing.pending_event.is_empty():
		_halt()
		_show_event()
		return
	if not crossing.pending_encounter.is_empty():
		_halt()
		_show_encounter()
		return
	if more:
		return
	_after_trip()


func _halt() -> void:
	_backdrop.set_moving(false)
	_caravan.set_walking(false)
	_ambience.set_moving(false)


func _resume_travel() -> void:
	_backdrop.set_moving(true)
	_caravan.set_walking(true)
	_ambience.set_moving(true)


## Trail moments since the last look: a toast each, and whatever they mention comes into view.
func _show_new_moments() -> void:
	while _moment_seen < crossing.moments.size():
		var m: Dictionary = crossing.moments[_moment_seen]
		_moment_seen += 1
		_toast(m)
		if String(m.get("sight", "")) != "":
			_ambience.spawn_sight(m["sight"], {"species": m.get("wild", "")})


func _toast(m: Dictionary) -> void:
	var text := "{i:%s} %s" % [m["icon"], m["text"]]
	var who := String(m.get("who", ""))
	if who != "" and not String(m["text"]).contains("{c:"):
		text = TrailFx.portrait(who) + " " + text
	if not m["deltas"].is_empty():
		text += "  " + TrailFx.chips(m["deltas"].filter(func(d): return d["icon"] != "xp")) 
		for d in m["deltas"]:
			if d["icon"] == "xp":
				text += "  [color=#%s]{i:xp}+%d[/color]" % [TrailFx.GOOD, int(d["amount"])]
	if m.has("grave"):
		text += "\n[i][color=#c8bca8]%s. %s[/color][/i]" % [m["grave"][0], m["grave"][1]]
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.82)))
	box.add_child(Rich.label(text, 8))
	box.modulate = Color(1, 1, 1, 0)
	_toasts.add_child(box)
	_toasts.move_child(box, 0)
	while _toasts.get_child_count() > 3:
		var old := _toasts.get_child(_toasts.get_child_count() - 1)
		_toasts.remove_child(old)
		old.queue_free()
	var t := box.create_tween()
	t.tween_property(box, "modulate:a", 1.0, 0.25)
	t.tween_interval(5.0)
	t.tween_property(box, "modulate:a", 0.0, 0.8)
	t.tween_callback(box.queue_free)


func _after_trip() -> void:
	_halt()
	match crossing.state:
		Expedition.State.AT_JUNCTION: _show_junction()
		Expedition.State.ARRIVED: _show_end(true)
		Expedition.State.FAILED: _show_end(false)


# ---------- events ----------

func _show_event() -> void:
	var ev := crossing.pending_event
	_event.visible = true
	Rich.set_text(_event_title, "{i:%s} %s" % [TrailEvents.kind_icon(ev), ev["title"]])
	_event_text.text = ev["text"]
	_event_result.visible = false
	_event_continue.visible = false
	_event_continue.text = "Continue"
	for c in _event_choices.get_children():
		c.queue_free()
	var views := crossing.event_choices(ev)
	for i in views.size():
		var row := ClickRow.make(_choice_markup(views[i]), 8, 316)
		row.disabled = not views[i]["affordable"]
		row.pressed.connect(_choose_event.bind(i))
		_event_choices.add_child(row)
	_event_choices.get_child(0).grab_focus.call_deferred()


## A choice as one line: label, then its cost, then who helps and the odds (or what it gives).
func _choice_markup(v: Dictionary) -> String:
	var parts: Array[String] = ["[b]%s[/b]" % v["label"]]
	if not v["cost"].is_empty():
		parts.append(TrailFx.cost(v["cost"]))
	if v["rolled"]:
		var job := "{i:cap_%s}" % v["cap"]
		if v["helper"] != "":
			var bonus := ("[color=#%s]+%d[/color]" % [TrailFx.GOOD, v["bonus"]]) if int(v["bonus"]) > 0 else ""
			parts.append("%s%s%s %s" % [job, TrailFx.portrait(v["helper"]), bonus, TrailFx.odds(v["odds"])])
		else:
			parts.append("%s[color=#%s]nobody[/color] %s" % [job, TrailFx.BAD, TrailFx.odds(v["odds"])])
		var reward := TrailFx.preview(v["reward"])
		if reward != "":
			parts.append(reward)
	else:
		var gives := TrailFx.preview(v["reward"])
		if gives != "":
			parts.append(gives)
	return "   ".join(parts)


func _choose_event(i: int) -> void:
	var r := crossing.resolve_event(i)
	if r.is_empty():
		return
	for c in _event_choices.get_children():
		c.queue_free()
	_show_result(r["outcome"], r["text"], r["deltas"])
	if r["recruit"] != "":
		_offer_recruit(r["recruit"])
	_continue_to = "battle" if r["fight"] else ""
	_event_continue.text = "To battle!" if r["fight"] else "Continue"
	_refresh_hud()


func _show_result(outcome: String, text: String, deltas: Array) -> void:
	var head: String = {"success": "[color=#9fe0a0]Success.[/color]", "mixed": "[color=#f0d27a]Partly.[/color]", "failure": "[color=#ff8a7a]Bad luck.[/color]"}[outcome]
	var line := "%s %s" % [head, text]
	var shown := deltas.filter(func(d): return not (d["icon"] == "risk" and d.get("label", "") == "fight"))
	if not shown.is_empty():
		line += "\n" + TrailFx.chips(shown)
	Rich.set_text(_event_result, line)
	_event_result.visible = true
	_event_continue.visible = true
	_event_continue.grab_focus.call_deferred()


## A wild Trailomon wants to join: take it in (to storage) or let it go.
func _offer_recruit(id: String) -> void:
	var take := ClickRow.make("%s Take in {c:%s}  {i:ev_wildlife}" % [TrailFx.portrait(id, 16), id], 9, 316)
	take.pressed.connect(func():
		var line := crossing.recruit()
		for c in _event_choices.get_children():
			c.queue_free()
		if line != "":
			_event_result.text += "\n" + Rich.bb("[color=#9fe0a0]{i:ev_wildlife} {c:%s} joined you (in storage).[/color]" % id)
		_refresh_hud())
	_event_choices.add_child(take)


func _continue_after_event() -> void:
	_event.visible = false
	crossing.pending_recruit = ""
	var next := _continue_to
	_continue_to = ""
	if next != "" and crossing.state == Expedition.State.TRAVELLING:
		_open_battle(next == "ambush")
		return
	if crossing.state == Expedition.State.TRAVELLING:
		_resume_travel()
		_day_timer = SECONDS_PER_DAY
	else:
		_after_trip()


# ---------- battles ----------

func _show_encounter() -> void:
	var enc := crossing.pending_encounter
	var pack: Dictionary = enc["pack"]
	_event.visible = true
	Rich.set_text(_event_title, "{i:risk} %s" % pack["title"])
	_event_text.text = pack["text"]
	_event_result.visible = false
	_event_continue.visible = false
	for c in _event_choices.get_children():
		c.queue_free()
	for v in crossing.encounter_choices():
		var line := "[b]%s[/b]" % v["label"]
		if v["id"] == "fight":
			line = "[b]Fight[/b]   " + ("{i:role_guard} set your lineup" if crossing.can_fight() else "[color=#%s]{i:ko} nobody can fight[/color]" % TrailFx.BAD)
		elif v["id"] == "bribe":
			line = "[b]Throw them food[/b]   " + TrailFx.cost({"food": -Expedition.BRIBE_FOOD})
		elif not v["safe"]:
			line = "[b]Slip past[/b]   {i:cap_scout}"
			if v["helper"] != "":
				line += TrailFx.portrait(v["helper"]) + " " + TrailFx.odds(v["odds"])
			else:
				line += "[color=#%s]nobody[/color] %s" % [TrailFx.BAD, TrailFx.odds(v["odds"])]
		var row := ClickRow.make(line, 8, 316)
		row.pressed.connect(_choose_encounter.bind(v["id"]))
		_event_choices.add_child(row)
	_event_choices.get_child(0).grab_focus.call_deferred()


func _choose_encounter(id: String) -> void:
	if id == "fight":
		_event.visible = false
		_open_battle(false)
		return
	var r := crossing.resolve_encounter(id)
	for c in _event_choices.get_children():
		c.queue_free()
	var deltas: Array = []
	if id == "bribe":
		deltas.append({"icon": "food", "amount": -Expedition.BRIBE_FOOD})
	_show_result(r["outcome"], r["text"], deltas)
	_event_continue.text = "To battle!" if r["fight"] else "Continue"
	_continue_to = "ambush" if r["fight"] else ""
	_refresh_hud()


func _open_battle(ambushed: bool) -> void:
	if not crossing.can_fight():
		var lines := crossing.finish_battle(null)
		_event.visible = true
		Rich.set_text(_event_title, "{i:risk} The wagon is overrun")
		_event_text.text = ""
		for c in _event_choices.get_children():
			c.queue_free()
		Rich.set_text(_event_result, "[color=#ff8a7a]%s[/color]" % "\n".join(lines))
		_event_result.visible = true
		_event_continue.text = "Continue"
		_event_continue.visible = true
		_refresh_hud()
		return
	_ui.visible = false
	_backdrop.visible = false
	_caravan.visible = false
	_ambience.set_active(false)
	_battle = BattleScreen.new()
	_in_battle = true
	_battle_ambush = ambushed
	_save()
	_battle.setup(crossing, ambushed)
	_battle.finished.connect(_on_battle_finished)
	add_child(_battle)


func _on_battle_finished(lines: Array) -> void:
	_battle.queue_free()
	_battle = null
	_in_battle = false
	_ui.visible = true
	_backdrop.visible = true
	_caravan.visible = true
	_ambience.set_active(true)
	_log.text = lines[0] if lines.size() > 0 else ""
	_refresh_hud()
	_event_continue.text = "Continue"
	_continue_after_event()


# ---------- wagon & cargo ----------

## page: false/"route", true/"wagon" or "trade".
func _show_tab(page: Variant) -> void:
	var p := "wagon" if page is bool and page else ("route" if page is bool else String(page))
	_route_page.visible = p == "route"
	_wagon_page.visible = p == "wagon"
	_trade_page.visible = p == "trade"
	_tab_route.disabled = p == "route"
	_tab_wagon.disabled = p == "wagon"
	_tab_trade.disabled = p == "trade"
	if p == "route" and _routes.get_child_count() > 0:
		_routes.get_child(0).grab_focus.call_deferred()


# ---------- trade ----------

func _refresh_trade() -> void:
	if _trade_list == null:
		return
	var rumor := crossing.hear_rumor()
	Rich.set_text(_rumor, ("{i:ev_travelers} [color=#e8dcc0]%s[/color]" % rumor) if rumor != "" else "")
	Rich.set_text(_coins_label, "{i:coins} %d   {i:food}%d  {i:water}%d  {i:repair_kit}%d  {i:item_slot}%d  {i:technique}%d  {i:light_dust}%d {i:dark_dust}%d" % [
		crossing.coins, roundi(crossing.provisions), roundi(crossing.water), crossing.repair_kits, _count(crossing.items), _count(crossing.techniques), crossing.light_dust, crossing.dark_dust])
	for c in _trade_list.get_children():
		c.queue_free()
	var stall: Dictionary = crossing.stop()["stall"]
	if stall.is_empty():
		_trade_list.add_child(Rich.label("Nothing for sale here.", 8))
	for good in stall:
		var left := crossing.stock_left(good)
		var row := ClickRow.make("{i:%s} %s   [color=#ffe3a3]{i:coins}%d[/color]   [color=#c8bca8]x%d[/color]" % [
			Settlements.good_icon(good), Settlements.good_name(good), int(stall[good]["price"]), left], 8, 128)
		row.disabled = not crossing.can_buy(good)
		row.pressed.connect(_buy.bind(good))
		Tips.attach(row, "g:" + Settlements.good_icon(good) if Glossary.has(Settlements.good_icon(good)) else "g:trade")
		_trade_list.add_child(row)


static func _count(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


func _buy(good: String) -> void:
	var d := crossing.buy(good)
	if d.is_empty():
		return
	_toast({"icon": "trade", "text": "Bought", "who": "", "deltas": d})
	_refresh_trade()
	_refresh_hud()
	_pick(_picked)


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
	var w := TrailLife.weather(crossing.weather)
	Rich.set_text(_hud, "{i:%s} {i:day}%d   {i:food}%d[color=#c8bca8]/%.0fd[/color]   {i:water}%d[color=#c8bca8]/%.0fd[/color]   {i:coins}%d   {i:cargo}%d   {i:haul}%d   {i:wagon}%d%%" % [
		w["icon"], crossing.day, roundi(crossing.provisions), floorf(crossing.days_of(crossing.provisions, crossing.daily_provisions())),
		roundi(crossing.water), floorf(crossing.days_of(crossing.water, crossing.daily_water())), crossing.coins, roundi(crossing.cargo_weight()), roundi(crossing.hauling_available()), crossing.wagon.integrity])
	var hp := ("{i:health}[color=#ff8a7a]%d[/color]" if crossing.health < 50 else "{i:health}%d") % crossing.health
	if crossing.fever_days > 0:
		hp = "{i:fever}" + hp
	Rich.set_text(_hud_health, hp)
	_pace_btn.icon = Rich.icon_tex(TrailLife.pace(crossing.pace)["icon"])
	_ration_btn.icon = Rich.icon_tex(TrailLife.ration(crossing.rations)["icon"])
	if _comp_btn != null:
		var n := crossing.pending_count()
		_comp_btn.text = "Companions (%d level up%s!)" % [n, "" if n == 1 else "s"] if n > 0 else "Companions"
	_save()


func _show_end(won: bool) -> void:
	_panel.visible = false
	_end.visible = true
	var title: Label = _end.find_child("EndTitle", true, false)
	var body: Label = _end.find_child("EndBody", true, false)
	var again: Button = _end.find_child("Again", true, false)
	if won:
		title.text = "Crossing %d: you reached %s" % [crossing_no, crossing.map.name_of(crossing.map.goal)]
		body.text = "Day %d. %d food and %d water left.\nDelivered %d cargo worth %d. Wagon at %d%%.\nYour team, levels, dust and items come with you." % [crossing.day, roundi(crossing.provisions), roundi(crossing.water), crossing.cargo.size(), crossing.cargo_value(), crossing.wagon.integrity]
		again.text = "Next crossing"
	else:
		title.text = "Crossing %d failed" % crossing_no
		body.text = "%s\nDay %d, %d visited stops." % [crossing.fail_reason, crossing.day, crossing.visited.size()]
		if SaveGame.is_hardcore(_slot):
			body.text += "\nHardcore: this caravan is gone for good."
			again.text = "New hardcore caravan"
		else:
			body.text += "\nTrying again starts this crossing over, with your team as it set out."
			again.text = "Try this crossing again"
	_save()
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
	_pace_btn = _button("", 8)
	_pace_btn.focus_mode = Control.FOCUS_NONE
	_pace_btn.pressed.connect(func():
		crossing.set_pace(TrailLife.next_in(TrailLife.PACE_ORDER, crossing.pace))
		_refresh_hud()
		if _panel.visible and not _picked.is_empty():
			_pick(_picked))
	Tips.attach(_pace_btn, func(): return TrailLife.pace_tip(crossing.pace) + Tips.SIDE + "{ik:pace}\n" + Glossary.text("pace"))
	row.add_child(_pace_btn)
	_ration_btn = _button("", 8)
	_ration_btn.focus_mode = Control.FOCUS_NONE
	_ration_btn.pressed.connect(func():
		crossing.set_rations(TrailLife.next_in(TrailLife.RATIONS_ORDER, crossing.rations))
		_refresh_hud()
		if _panel.visible and not _picked.is_empty():
			_pick(_picked))
	Tips.attach(_ration_btn, func(): return TrailLife.ration_tip(crossing.rations) + Tips.SIDE + "{ik:rations}\n" + Glossary.text("rations"))
	row.add_child(_ration_btn)
	# Always reachable, at a junction or on the road (travel pauses while it's open).
	var comp := _button("Companions", 8)
	comp.focus_mode = Control.FOCUS_NONE
	comp.pressed.connect(_open_companions)
	Tips.attach(comp, func(): return "Your team: stats, moves and memory slots, plus the Trailomon in storage. Travel pauses while it's open.")
	row.add_child(comp)
	_comp_btn = comp
	var map_btn := _button("", 8)
	map_btn.icon = Rich.icon_tex("map")
	map_btn.focus_mode = Control.FOCUS_NONE
	map_btn.pressed.connect(_toggle_world)
	Tips.attach(map_btn, func(): return "{i:map} [b]Overworld map[/b]\nWhere you've been and what you've seen. Travel pauses while it's open.")
	row.add_child(map_btn)
	row.move_child(map_btn, comp.get_index())
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
	_title = Rich.label("", 9)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(_title)
	_tab_route = _button("", 9)
	_tab_route.icon = Rich.icon_tex("progress")
	_tab_route.pressed.connect(_show_tab.bind("route"))
	Tips.attach(_tab_route, func(): return "{i:progress} [b]Route[/b]: pick the next road.")
	tabs.add_child(_tab_route)
	_tab_trade = _button("", 9)
	_tab_trade.icon = Rich.icon_tex("trade")
	_tab_trade.pressed.connect(_show_tab.bind("trade"))
	Tips.attach(_tab_trade, func(): return "{i:trade} [b]Trade[/b]: this stop's stall and the local rumor.")
	tabs.add_child(_tab_trade)
	_tab_wagon = _button("", 9)
	_tab_wagon.icon = Rich.icon_tex("wagon")
	_tab_wagon.pressed.connect(_show_tab.bind("wagon"))
	Tips.attach(_tab_wagon, func(): return "{i:wagon} [b]Wagon & cargo[/b]: haulers, cargo, rest and repairs.")
	tabs.add_child(_tab_wagon)
	col.add_child(tabs)

	_route_page = VBoxContainer.new()
	_route_page.add_theme_constant_override("separation", 3)
	col.add_child(_route_page)
	_map = RouteMapView.new()
	_map.custom_minimum_size = Vector2(296 - 12, 128)
	_map.junction_clicked.connect(_on_map_click)
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

	_trade_page = VBoxContainer.new()
	_trade_page.add_theme_constant_override("separation", 4)
	_trade_page.visible = false
	col.add_child(_trade_page)
	_rumor = Rich.label("", 8, 284)
	_trade_page.add_child(_rumor)
	_coins_label = Rich.label("", 8)
	_trade_page.add_child(_coins_label)
	_trade_list = GridContainer.new()
	_trade_list.columns = 2
	_trade_list.add_theme_constant_override("h_separation", 3)
	_trade_list.add_theme_constant_override("v_separation", 3)
	_trade_page.add_child(_trade_list)

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
	_event_title = Rich.label("", 13)
	vcol.add_child(_event_title)
	_event_text = PreviewHud.label("", 9)
	_event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_text.custom_minimum_size = Vector2(328, 0)
	vcol.add_child(_event_text)
	_event_choices = VBoxContainer.new()
	_event_choices.add_theme_constant_override("separation", 3)
	vcol.add_child(_event_choices)
	_event_result = Rich.label("", 9, 328)
	vcol.add_child(_event_result)
	_event_continue = _button("Continue", 10)
	_event_continue.pressed.connect(_continue_after_event)
	vcol.add_child(_event_continue)
	_event.visible = false
	_ui.add_child(_event)

	_travel_map = RouteMapView.new()
	_travel_map.position = Vector2(500, 286)
	_travel_map.size = Vector2(134, 68)
	_travel_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_travel_map.visible = false
	_ui.add_child(_travel_map)

	_world = PanelContainer.new()
	_world.position = Vector2(8, 28)
	_world.custom_minimum_size = Vector2(624, 326)
	_world.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.10, 0.08, 0.11, 0.97)))
	var wcol := VBoxContainer.new()
	_world.add_child(wcol)
	var whead := HBoxContainer.new()
	var wtitle := Rich.label("{i:map} [b]Overworld[/b]   [color=#c8bca8]drag to look around, wheel to zoom[/color]", 9)
	wtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	whead.add_child(wtitle)
	var wclose := _button("Close", 8)
	wclose.pressed.connect(_toggle_world)
	whead.add_child(wclose)
	wcol.add_child(whead)
	_world_map = RouteMapView.new()
	_world_map.full = true
	_world_map.custom_minimum_size = Vector2(612, 296)
	_world_map.junction_clicked.connect(_on_map_click)
	wcol.add_child(_world_map)
	_world.visible = false
	_ui.add_child(_world)

	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(6, 28)
	_toasts.add_theme_constant_override("separation", 2)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_toasts)

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
	again.pressed.connect(func(): _next_crossing() if crossing.state == Expedition.State.ARRIVED else _retry())
	ecol.add_child(again)
	var back := _button("Back to title", 10)
	back.pressed.connect(_to_title)
	ecol.add_child(back)
	_ui.add_child(_end)


func _toggle_world() -> void:
	_world.visible = not _world.visible
	if _world.visible:
		_world_map.size = _world_map.custom_minimum_size
		_world_map.fit()
		_world_map.picked = _picked.get("to", "")
		_world_map.queue_redraw()


## Clicking a stop you can drive to picks that road.
func _on_map_click(id: String) -> void:
	if crossing.state != Expedition.State.AT_JUNCTION:
		return
	for seg in crossing.exits():
		if seg["to"] == id:
			_pick(seg)
			_world_map.picked = id
			_world_map.queue_redraw()
			return


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
		_to_title()

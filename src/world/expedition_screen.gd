extends Node2D
## The playable crossing: pick a route at each junction, watch the caravan travel day by day,
## and manage food, water and hauling until you reach Westwatch or the crossing fails.

const SECONDS_PER_DAY := 2.0
const PANEL_POS := Vector2(338, 30)
const PANEL_SIZE := Vector2(296, 324)

var crossing: Expedition
var _backdrop: TravelBackdrop
## The travel foreground (plants in front of the road). It sits above everything, so it is
## hidden while a battle is open or it would cover the bottom lane of both teams.
var _foreground: Node2D
var _caravan: Caravan
var _ui: CanvasLayer
## True while the starter picker is open: the caravan behind it is only a stand-in.
var _picking_starter := false
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
var _healer: Button
var _repair: Button
var _hunt: Button
var _forage: Button
var _cook: Button
var _pantry_label: RichTextLabel
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
var _job_box: HBoxContainer
var _shop_box: VBoxContainer
var _end_score: RichTextLabel
var _end_grave: HBoxContainer
var _epitaph: LineEdit
var _coins_label: RichTextLabel
## Outfitter header (keeper, advice, load bar, pack button), shown only in the start town.
var _outfit_box: VBoxContainer
var _event_continue: Button
var _team_status: VBoxContainer
var _battle: BattleScreen
## The how-to-play guide while it's open.
var _guide: GuideScreen
## What happens when the event panel's Continue is pressed: "" resumes travel, "battle" or "ambush" opens a fight.
var _continue_to := ""
var _picked: Dictionary = {}
var _day_timer := 0.0


var _companions: CompanionsScreen
var _comp_btn: Button

## Which crossing this caravan is on (1 for a new caravan), and the save slot it autosaves to
## ("" = no saving, e.g. tests and previews).
var crossing_no: int:
	get: return crossing.crossing_no if crossing != null else 1
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
	_foreground = _backdrop.add_foreground(self)
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
		_choose_starter()
		return
	crossing = loaded["expedition"]
	_start = loaded["start"] if not (loaded["start"] as Dictionary).is_empty() else SaveGame.caravan(crossing)
	_reset_view()
	_resume(loaded["ui"])


## A brand-new caravan: pick the first partner, then set out with it alone.
## Nothing is saved until the pick is made.
func _choose_starter() -> void:
	_picking_starter = true
	_begin(Expedition.new_game(Expedition.STARTERS[0]), 1)
	var s := StarterScreen.open(_ui)
	s.picked.connect(func(id: String):
		_picking_starter = false
		_begin(Expedition.new_game(id), 1)
		_save()
		_open_guide())


## Start a crossing (new, next or retried) and save it.
func _begin(e: Expedition, no: int) -> void:
	crossing = e
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
	_moment_seen = crossing.moments.size()
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
			if crossing.is_hunt():
				# Left in the middle of a hunt: pick it back up (hardcore plays it out).
				if SaveGame.is_hardcore(_slot):
					_auto_battle(false)
				else:
					_open_battle(false)
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
		_set_scenery()
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
	if _slot == "" or crossing == null or _picking_starter:
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


## After a failed crossing: try it again from the start, keeping the team's experience.
## A failed hardcore caravan is gone, so it starts over from scratch.
func _retry() -> void:
	if SaveGame.is_hardcore(_slot):
		_choose_starter()
	else:
		_begin(SaveGame.next_crossing(SaveGame.retry_caravan(_start, crossing), -1, crossing_no), crossing_no)


# ---------- junction ----------

func _show_junction() -> void:
	_panel.visible = true
	var kind: Dictionary = Settlements.KINDS.get(crossing.stop()["kind"], {"name": "Stop"})
	Rich.set_text(_title, "{i:settlement} [b]%s[/b]  [color=#c8bca8]%s[/color]" % [crossing.map.name_of(crossing.at), kind["name"]])
	_ambience.set_moving(false)
	_refresh_music()
	_ambience.encountered = crossing.encountered
	_set_scenery()
	_ambience.show_settlement(crossing.stop()["kind"])
	_refresh_trade()
	for c in _routes.get_children():
		c.queue_free()
	var exits := crossing.exits()
	for seg in exits:
		var marks := " " + "!".repeat(int(seg["risk"]))
		if seg["terrain"] == "River":
			marks += " ford"
		if seg.get("rough", false):
			marks += " rough"
		match String(seg.get("block", {}).get("kind", "")):
			"giant": marks += " giant"
			"gate": marks += " blocked"
			"deep": marks += " deep"
		var b := _button("%s\n%d day%s%s" % [crossing.map.name_of(seg["to"]), seg["days"], "" if seg["days"] == 1 else "s", marks], 8)
		b.icon = Rich.icon_tex(Glossary.habitat_id(seg["terrain"]))
		b.add_theme_constant_override("icon_max_width", 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Tips.attach(b, func(): return "{ik:%s} road to %s\n{i:day} %d day%s   %s risk%s" % [Glossary.habitat_id(seg["terrain"]), crossing.map.name_of(seg["to"]),
			seg["days"], "" if seg["days"] == 1 else "s", "{i:risk}".repeat(seg["risk"]), _road_notes(seg)])
		b.pressed.connect(_pick.bind(seg))
		_routes.add_child(b)
	_pick(exits[0])
	_show_tab("trade" if crossing.outfitting() else false)
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
	var puller := "haulers give" if crossing.hauling_available() > Wagon.BASE_PULL else "your crew pulls"
	var haul := "{i:haul} needs %d, %s %d  " % [roundi(f["demand"]), puller, roundi(f["available"])]
	match f["hauling"]:
		Hauling.Result.NORMAL: haul += "[color=#9fe0a0]OK[/color]"
		Hauling.Result.PUSH: haul += "[color=#f0d27a]{k:push|PUSHING}[/color]"
		Hauling.Result.BLOCKED: haul += bad % "TOO HEAVY"
	lines.append(haul)
	var notes := _road_notes(seg)
	if notes != "":
		lines.append(notes.strip_edges())
	if crossing.frost_day > 0:
		var to_goal := crossing.map.shortest_days(seg["to"], crossing.map.goal)
		var eta := crossing.day + int(f["days"]) + maxi(0, to_goal)
		var left := crossing.frost_day - eta
		lines.append("{i:frost} Westwatch by day %d at the soonest. Frost on day %d%s" % [eta, crossing.frost_day,
			(" [color=#ff8a7a](too late)[/color]" if left < 0 else (" [color=#f0d27a](cutting it close)[/color]" if left < Expedition.LATE_DAYS else ""))])
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
	else:
		_go.text = "Too heavy to travel this way"


## Special things about a road: a river to cross (with or without a ferry), a rough track.
func _road_notes(seg: Dictionary) -> String:
	var t := ""
	if seg["terrain"] == "River":
		t += "\n{i:river} A river to cross%s." % (" (ferry)" if crossing.map.has_ferry(seg) else ", no ferry")
	if seg.get("rough", false):
		t += "\n{i:risk} Rough track: a shortcut, steep and dangerous."
	var o: Dictionary = seg.get("block", {})
	match String(o.get("kind", "")):
		"giant":
			t += "\n{i:giant} A {k:giant|sleeping giant} %s lies across this road." % Species.info(String(o["species"]))["name"]
		"gate":
			var helper := crossing.best_helper(String(o["cap"]))
			t += "\n{i:%s} %s: needs a {k:cap_%s|%s} Trailomon%s." % [Glossary.icon("cap_" + String(o["cap"])), String(o["name"]), String(o["cap"]), String(o["cap"]).capitalize(),
				(", and %s can try" % crossing.display_name(helper)) if helper != "" else ", or two slow days forcing through"]
		"deep":
			t += "\n{i:deep} {k:deep|Deep wilds}: no stops for days. More fights, rarer Trailomon."
	if crossing.lairs.has(String(seg["to"])) and crossing.is_seen(String(seg["to"])) and not bool(crossing.lairs[seg["to"]]["done"]):
		t += "\n{i:lair} A {k:lair|legendary lair}. Something sleeps there."
	for c in crossing.cargo:
		if String(c.get("deliver_to", "")) == String(seg["to"]):
			t += "\n{i:cargo} Deliver the %s here." % String(c["name"]).get_slice(" for ", 0).to_lower()
	return t


## The three likeliest weathers on a terrain, as icons.
func _forecast_icons(terrain: String) -> String:
	var table: Dictionary = TrailLife.WEATHER_TABLE.get(terrain, {})
	var ids := table.keys()
	ids.sort_custom(func(a, b): return int(table[a]) > int(table[b]))
	var out := ""
	for w in ids.slice(0, 3):
		out += "{i:%s}" % TrailLife.weather(w)["icon"]
	return out


## Terrain scenery and the region's landmark, for the road or the stop the wagon is at.
func _set_scenery() -> void:
	var scene := crossing.scenery()
	_backdrop.set_scene(scene["terrain"], scene["landmark"])
	_ambience.set_terrain(scene["terrain"])


func _set_off() -> void:
	if _event.visible or _picked.is_empty() or not crossing.start_trip(_picked):
		return
	_panel.visible = false
	_backdrop.set_moving(true)
	_caravan.set_walking(true)
	_set_scenery()
	_ambience.set_moving(true)
	_refresh_music()
	_log.text = "Travelling to %s..." % crossing.map.name_of(_picked["to"])
	_day_timer = SECONDS_PER_DAY


func _process(delta: float) -> void:
	if _travel_map != null:
		_travel_map.visible = crossing != null and crossing.state == Expedition.State.TRAVELLING and _battle == null
	if crossing == null or crossing.state != Expedition.State.TRAVELLING or _event.visible or _battle != null or _companions != null or _guide != null or _field_guide != null or _world.visible:
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


## Town music at settlements, the trail theme on the road, something eerier in the deep wilds.
func _refresh_music() -> void:
	if crossing == null:
		return
	if crossing.state == Expedition.State.TRAVELLING:
		Sound.music("wild" if crossing.trip.get("deep", false) else "trail")
	elif ["town", "village", "post", "stilts", "sanctum", "warden"].has(String(crossing.stop()["kind"])):
		Sound.music("town")
	else:
		Sound.music("trail")


func _resume_travel() -> void:
	_refresh_music()
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
			var help := ""
			for a in v.get("assists", []):
				help += " [color=#%s]+{i:cap_%s}[/color]%s" % [TrailFx.GOOD, a["cap"], TrailFx.portrait(a["who"])]
			if v.get("gear", "") != "":
				help += " [color=#%s]+{i:%s}[/color]" % [TrailFx.GOOD, Inventor.info(v["gear"])["icon"]]
			if int(v.get("morale", 0)) != 0:
				help += " [color=#%s]{i:morale}%+d[/color]" % [TrailFx.GOOD if int(v["morale"]) > 0 else TrailFx.BAD, int(v["morale"])]
			parts.append("%s%s%s%s %s" % [job, TrailFx.portrait(v["helper"]), bonus, help, TrailFx.odds(v["odds"])])
		else:
			parts.append("%s[color=#%s]nobody[/color] %s" % [job, TrailFx.BAD, TrailFx.odds(v["odds"])])
		var reward := TrailFx.preview(v["reward"])
		if reward != "":
			parts.append(reward)
	elif v.get("hidden", false):
		parts.append("[color=#%s]who knows?[/color]" % TrailFx.MID)
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
			var where := "your team" if crossing.roster.has(id) else "you (in storage)"
			_event_result.text += "\n" + Rich.bb("[color=#9fe0a0]{i:ev_wildlife} {c:%s} joined %s.[/color]" % [id, where])
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
	var loud := String(pack.get("boss", ""))
	if loud == "":
		for lane in [1, 0, 2]:
			if String(pack["front"][lane]) != "":
				loud = String(pack["front"][lane])
				break
	Sound.cry(loud)
	if String(enc.get("glint", "")) != "":
		_event_text.text += "\nOne of them glints in strange colours!"
	if bool(enc.get("guardian", false)):
		_event_text.text += "\nFight it, pay the long toll road around, or gamble on the rapids. Going around beats nothing: no guardian rewards, and a smaller arrival score."
	_event_result.visible = false
	_event_continue.visible = false
	for c in _event_choices.get_children():
		c.queue_free()
	for v in crossing.encounter_choices():
		var line := "[b]%s[/b]" % v["label"]
		if v["id"] == "fight":
			line = "[b]Fight[/b]   " + ("{i:role_guard} set your lineup" if crossing.can_fight() else "[color=#%s]{i:ko} nobody can fight[/color]" % TrailFx.BAD)
		elif v["id"] == "flare":
			line = "{i:flare} [b]Light a flare[/b]   they scatter (%d left)" % crossing.flares
		elif v["id"] == "bribe":
			line = "[b]Throw them food[/b]   " + TrailFx.cost({"food": -Expedition.BRIBE_FOOD})
		elif v["id"] == "toll":
			line = "{i:toll} [b]Toll road around[/b]   " + TrailFx.cost({"coins": -int(v["cost"])}) + " {i:day}+%d" % int(v["days"])
		elif v["id"] == "rapids":
			line = "{i:rapids} [b]Run the rapids[/b]   {i:job_float}"
			line += (TrailFx.portrait(v["helper"]) if v["helper"] != "" else "[color=#%s]nobody[/color]" % TrailFx.BAD)
			for a in v.get("assists", []):
				line += " +{i:%s}%s" % [Glossary.icon("cap_" + String(a["cap"])), TrailFx.portrait(a["who"])]
			if v.get("gear", "") != "":
				line += " +{i:up_float_tanks}"
			line += " " + TrailFx.odds(v["odds"])
		elif not v["safe"]:
			line = "[b]Slip past[/b]   {i:cap_scout}"
			if v["helper"] != "":
				line += TrailFx.portrait(v["helper"]) + " " + TrailFx.odds(v["odds"])
			else:
				line += "[color=#%s]nobody[/color] %s" % [TrailFx.BAD, TrailFx.odds(v["odds"])]
		var row := ClickRow.make(line, 8, 316)
		row.disabled = not bool(v.get("affordable", true))
		row.pressed.connect(_choose_encounter.bind(v["id"]))
		_event_choices.add_child(row)
	_event_choices.get_child(0).grab_focus.call_deferred()


func _choose_encounter(id: String) -> void:
	if id == "fight":
		_event.visible = false
		_open_battle(false)
		return
	if id == "flare":
		Sound.sfx("flare")
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
	_foreground.visible = false
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
	_foreground.visible = true
	_caravan.visible = true
	_ambience.set_active(true)
	_log.text = lines[0] if lines.size() > 0 else ""
	_refresh_music()
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
	var outfit := crossing.outfitting()
	_outfit_box.visible = outfit
	if outfit:
		_refresh_outfitter()
		Rich.set_text(_rumor, "")
	else:
		var rumor := crossing.hear_rumor()
		var talk: Array[String] = []
		if rumor != "":
			talk.append("{i:ev_travelers} [color=#e8dcc0]%s[/color]" % rumor)
		for f in crossing.hear_folk():
			talk.append("{i:folk} [b]%s[/b], %s: [color=#e8dcc0]\"%s\"[/color]" % [f["name"], f["trade"], f["line"]])
		Rich.set_text(_rumor, "\n".join(talk))
	_refresh_workshop()
	Rich.set_text(_coins_label, "{i:coins} %d   {i:food}%d  {i:water}%d  %s {i:item_slot}%d  {i:technique}%d  {i:light_dust}%d {i:dark_dust}%d  {i:lure}%d {i:flare}%d" % [
		crossing.coins, roundi(crossing.provisions), roundi(crossing.water), _spares_text(), _count(crossing.items), _count(crossing.techniques), crossing.light_dust, crossing.dark_dust, crossing.lures, crossing.flares])
	_refresh_job()
	for c in _trade_list.get_children():
		c.queue_free()
	var stall: Dictionary = crossing.stall()
	if stall.is_empty():
		_trade_list.add_child(Rich.label("Nothing for sale here.", 8))
	for good in stall:
		var left := crossing.stock_left(good)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 1)
		var gname := Settlements.good_name(good).trim_prefix("a ").trim_prefix("an ")
		var row := ClickRow.make("{i:%s} %s [color=#ffe3a3]{i:coins}%d[/color] [color=#c8bca8]x%d[/color]" % [
			Settlements.good_icon(good), gname, int(stall[good]["price"]), left], 8, 112 if outfit else 128)
		row.disabled = not crossing.can_buy(good)
		row.pressed.connect(_buy.bind(good))
		Tips.attach(row, _good_tip.bind(good))
		line.add_child(row)
		if outfit:
			var back := _button("-", 8)
			back.disabled = crossing.sellable(good) <= 0
			back.focus_mode = Control.FOCUS_NONE
			back.custom_minimum_size = Vector2(12, 0)
			back.pressed.connect(_sell_back.bind(good))
			Tips.attach(back, func(): return "Hand one back for a full refund. Only before you set out.")
			line.add_child(back)
		_trade_list.add_child(line)


## Pip Gasket's workshop: permanent wagon upgrades, when Pip has set up shop at this stop.
func _refresh_workshop() -> void:
	for c in _shop_box.get_children():
		c.queue_free()
	_shop_box.visible = crossing.at_workshop()
	if not _shop_box.visible:
		return
	_shop_box.add_child(Rich.label("{i:inventor} [b]%s[/b], %s: [color=#e8dcc0]\"%s\"[/color]" % [Inventor.NAME, Inventor.TRADE, Inventor.hello(crossing.crossing_no)], 8, 284))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	for id in Inventor.UPGRADES:
		var u: Dictionary = Inventor.info(id)
		var owned := crossing.has_upgrade(id)
		var row := ClickRow.make("{i:%s} %s %s" % [u["icon"], u["name"], "[color=#9fe39a]fitted[/color]" if owned else "[color=#ffe3a3]{i:coins}%d[/color]" % crossing.upgrade_price(id)], 8, 128)
		row.disabled = not crossing.can_buy_upgrade(id)
		row.pressed.connect(func():
			crossing.buy_upgrade(id)
			_after_action()
			_refresh_trade())
		Tips.attach(row, func(): return "{i:%s} [b]%s[/b]\n%s\nA permanent upgrade: it stays with the wagon on every crossing.%s" % [u["icon"], u["name"], u["text"],
			"" if owned or crossing.coins >= crossing.upgrade_price(id) else "\n[color=#ff8a7a]Not enough coins.[/color]"])
		grid.add_child(row)
	_shop_box.add_child(grid)


## The stop's job board: one delivery to a stop further on, paid on arrival, half if late.
func _refresh_job() -> void:
	for c in _job_box.get_children():
		c.queue_free()
	var o := crossing.delivery_offer()
	_job_box.visible = not o.is_empty()
	if o.is_empty():
		return
	var quick := crossing.map.shortest_days(crossing.at, String(o["to"]))
	var l := Rich.label("{i:cargo} [b]Job:[/b] %s  {i:weight}%d  [color=#ffe3a3]{i:coins}%d[/color]  by {i:day}%d" % [o["name"], roundi(o["weight"]), int(o["pay"]), int(o["due"])], 8, 222)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tips.attach(l, func(): return "Carry this to %s by day %d (the quickest way there takes %d days). Paid when you arrive there, half if you're late. It rides in the wagon like any cargo: heavy, and lost if a river takes it." % [crossing.map.name_of(String(o["to"])), int(o["due"]), quick])
	_job_box.add_child(l)
	var take := _button("Take it", 8)
	take.disabled = not crossing.can_take_delivery()
	take.pressed.connect(func():
		crossing.take_delivery()
		_after_action()
		_refresh_trade())
	Tips.attach(take, func(): return "No room in the wagon." if crossing.free_space() < float(o["weight"]) else "Load it up.")
	_job_box.add_child(take)


func _refresh_outfitter() -> void:
	for c in _outfit_box.get_children():
		c.queue_free()
	var k := Outfitter.keeper(crossing.crossing_no)
	_outfit_box.add_child(Rich.label("{i:trade} [b]%s[/b], %s: [color=#e8dcc0]\"%s\"[/color]" % [k["name"], k["trade"], k["hello"]], 8, 284))
	var tip := Outfitter.advice(crossing.map)
	var shop := crossing.workshop()
	if shop != "":
		crossing.seen[shop] = true
		tip += (" " if tip != "" else "") + "%s the inventor is at %s this season, if you've coins to spare." % [Inventor.NAME, crossing.map.name_of(shop)]
	if tip != "":
		_outfit_box.add_child(Rich.label("[color=#c8bca8]\"%s\"[/color]" % tip, 8, 284))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var used := crossing.load_weight()
	var full := used >= crossing.capacity() - 0.5
	var bar := Rich.label("{i:weight} Load %d/%d%s" % [roundi(used), roundi(crossing.capacity()), "  [color=#ff8a7a]FULL[/color]" if full else ""], 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Tips.attach(bar, func(): return "{i:weight} Everything aboard counts: cargo %d, food and water %d, parts and curiosities %d.\nA heavier wagon wears faster and is harder to pull." % [
		roundi(crossing.cargo_weight()), roundi((crossing.provisions + crossing.water * 2.0) / 2.0), roundi(crossing.supplies_weight() - (crossing.provisions + crossing.water * 2.0) / 2.0)])
	row.add_child(bar)
	var pack := _button("Pack it for me", 8)
	pack.focus_mode = Control.FOCUS_NONE
	pack.pressed.connect(_pack_for_me)
	Tips.attach(pack, func(): return "%s buys their usual kit with what you have left. %s" % [k["name"], k["bias"]])
	row.add_child(pack)
	_outfit_box.add_child(row)


func _good_tip(good: String) -> String:
	var t := Glossary.text(Settlements.good_icon(good)) if Glossary.has(Settlements.good_icon(good)) else ""
	if Outfitter.is_curio(good):
		t = "{ik:%s}\n%s" % [good, Outfitter.CURIOS[good]["text"]]
	elif t == "":
		t = "{ik:trade}\n" + Glossary.text("trade")
	else:
		t = "{ik:%s}\n%s" % [Settlements.good_icon(good), t]
	var w: float = Outfitter.weight_of(good)
	if w > 0.0:
		t += "\n{i:weight} weighs %d" % roundi(w)
	match crossing.buy_block(good):
		"room":
			t += "\n[color=#ff8a7a]No room in the wagon.[/color]"
		"coins":
			t += "\n[color=#ff8a7a]Not enough coins.[/color]"
		"have":
			t += "\n[color=#c8bca8]You have one.[/color]"
	return t


func _spares_text() -> String:
	var t := ""
	for k in Wagon.SPARES:
		t += "{i:spare_%s}%d " % [k, crossing.spare_count(k)]
	return t


func _sell_back(good: String) -> void:
	if crossing.sell_back(good).is_empty():
		return
	_refresh_trade()
	_refresh_hud()
	_refresh_wagon_page()
	_pick(_picked)


func _pack_for_me() -> void:
	var n := crossing.pack_for_me()
	_toast({"icon": "trade", "text": "Packed %d lot%s" % [n, "" if n == 1 else "s"] if n > 0 else "Nothing more fits", "who": "", "deltas": []})
	_refresh_trade()
	_refresh_hud()
	_refresh_wagon_page()
	_pick(_picked)


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
	_refresh_wagon_page()
	_pick(_picked)


func _wagon_summary() -> String:
	var w := crossing.wagon
	var status := "{i:wagon} %d%%  wear %d/100   {i:weight}%d/%d   %s" % [w.integrity, roundi(w.wear), roundi(crossing.load_weight()), roundi(crossing.capacity()), _spares_text()]
	for c in crossing.curios:
		status += "{i:%s}" % c
	for u in crossing.upgrades:
		status += "{i:%s}" % Inventor.info(u).get("icon", "wagon")
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
		var sick := crossing.ailment_of(id)
		var cell := Rich.label("{c:%s} %s%s" % [id, ("%d" % hp) if hp > 0 else "{i:ko}", (" {i:%s}" % Ailments.info(sick)["icon"]) if sick != "" else ""], 8)
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
		if item.has("deliver_to"):
			var late := crossing.day > int(item["due"])
			l = Rich.label("{i:cargo} %s   {i:weight}%d   {i:coins}%d   [color=#%s]by day %d[/color]" % [item["name"], roundi(item["weight"]), int(item["pay"]) / (2 if late else 1), "ff8a7a" if late else "e8dcc0", int(item["due"])], 8)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var drop := _button("Drop", 8)
		drop.pressed.connect(_drop.bind(i))
		row.add_child(drop)
		_cargo_list.add_child(row)
	if crossing.cargo.is_empty():
		_cargo_list.add_child(PreviewHud.label("Nothing left to deliver.", 8))
	# Supplies can be dumped too, to make room for something better.
	var dumps := HBoxContainer.new()
	dumps.add_theme_constant_override("separation", 3)
	dumps.add_child(Rich.label("Dump:", 8))
	for kind in ["food", "water", "spare_axle", "spare_harness", "spare_canvas"]:
		var have := crossing.provisions >= 10.0 if kind == "food" else (crossing.water >= 10.0 if kind == "water" else crossing.spare_count(kind.trim_prefix("spare_")) > 0)
		if not have:
			continue
		var b := _button("", 8)
		b.icon = Rich.icon_tex(kind)
		b.text = "10" if kind == "food" or kind == "water" else "1"
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_dump.bind(kind))
		Tips.attach(b, func(): return "Leave %s by the road to make room. Gone for good." % ("10 " + kind if kind == "food" or kind == "water" else "the " + String(Wagon.SPARES[kind.trim_prefix("spare_")]["name"])))
		dumps.add_child(b)
	if dumps.get_child_count() > 1:
		_cargo_list.add_child(dumps)
	var plan := crossing.repair_plan()
	match String(plan["kind"]):
		"spare":
			_repair.text = "Fit the %s (1 day)" % Wagon.SPARES[plan["spare"]]["name"]
			_repair.icon = Rich.icon_tex("spare_" + String(plan["spare"]))
		"jury":
			_repair.text = "Jury-rig (%d day%s)" % [plan["days"], "" if plan["days"] == 1 else "s"]
			_repair.icon = Rich.icon_tex(Glossary.icon("cap_" + String(plan["job"])))
		_:
			_repair.text = "Tune up (1 day)"
			_repair.icon = Rich.icon_tex("repair_kit")
	_repair.disabled = plan["kind"] == "none"
	_hunt.disabled = crossing.hunt_block() != ""
	_healer.visible = crossing.has_healer()
	_healer.text = "Healer (%d)" % crossing.heal_cost()
	_healer.disabled = crossing.heal_cost() <= 0 or crossing.coins < crossing.heal_cost()
	_forage.disabled = crossing.forage_block() != ""
	_cook.disabled = crossing.cook_block() != ""
	var shelf := ""
	for k in crossing.pantry:
		shelf += "{i:%s}%d " % [Camp.ingredient(k)["icon"], int(crossing.pantry[k])]
	Rich.set_text(_pantry_label, "{i:cook} " + (shelf if shelf != "" else "[color=#8a7f8c]empty[/color]"))


func _repair_tip() -> String:
	var plan := crossing.repair_plan()
	match String(plan["kind"]):
		"spare":
			return "Swap in your %s. Takes a {i:day} day, and the wagon is good as new." % Wagon.SPARES[plan["spare"]]["name"]
		"jury":
			var who := ("{c:%s} has the {k:cap_%s|%s} job and can rig something solid in a day." % [plan["helper"], plan["job"], String(plan["job"]).capitalize()]) if plan["skilled"] \
				else "Nobody on the team is good enough at {k:cap_%s|%s} (rank %d+) to do it fast." % [plan["job"], String(plan["job"]).capitalize(), Wagon.JURY_RANK]
			return "No %s aboard. Patch it with what you have: costs integrity.\n%s" % [Wagon.SPARES[plan["spare"]]["name"], who]
		"tune":
			return "Nothing is broken. A {i:day} day of upkeep takes 25 wear off, so a {k:breakdown} is less likely."
	return "The wagon is in perfect shape."


func _setup_caravan() -> void:
	var buddy := _companion()
	_caravan.setup(crossing.haulers, buddy, crossing.glints)
	_hover.clear()
	_hover.add(Rect2(Caravan.WAGON_FEET + Vector2(-80, -170), Vector2(160, 172)), _wagon_tip)
	var shown := crossing.haulers.slice(0, Caravan.HAULER_SLOTS.size())
	for i in shown.size():
		_hover.add(HoverZones.creature_rect(Caravan.HAULER_SLOTS[i]), _creature_tip.bind(shown[i], true))
	if buddy != "":
		_hover.add(HoverZones.creature_rect(Caravan.COMPANION_FEET), _creature_tip.bind(buddy, false))


## The Trailomon that walks beside the wagon: Rimehare while it travels with you, otherwise
## the first team member who isn't in harness.
func _companion() -> String:
	return crossing.lead_companion()


func _creature_tip(id: String, hauling: bool) -> String:
	if crossing == null:
		return ""
	var t := CreatureCard.markup(id, {"hp": crossing.creature_hp.get(id, 0.0), "max_hp": crossing.max_hp(id),
		"fatigue": crossing.fatigue.get(id, 0.0)})
	if hauling:
		t += "\nIn harness: pulls {i:haul}%d" % roundi(crossing.hauler_strength(id))
	var sick := crossing.ailment_of(id)
	if sick != "":
		var k := Ailments.info(sick)
		t += "\n[color=#ff8a7a]{i:%s} %s: %s, %d more days. Resting helps.[/color]" % [k["icon"], k["name"], k["effect"], int(crossing.ailments[id]["days"])]
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


func _dump(kind: String) -> void:
	crossing.dump(kind)
	_after_action()


func _do_heal() -> void:
	crossing.visit_healer()
	_after_action()


func _do_rest() -> void:
	crossing.rest()
	_after_action()
	if not crossing.pending_event.is_empty() and crossing.state == Expedition.State.AT_JUNCTION:
		_show_event()


func _do_forage() -> void:
	if crossing.forage():
		_show_event()
	_after_action()


func _forage_tip() -> String:
	var why: String = {"town": "Nothing grows in town but weeds.", "picked": "You've already picked this stop clean.", "busy": ""}.get(crossing.forage_block(), "")
	return "{k:forage}\n" + ("[color=#ff8a7a]%s[/color]" % why if why != "" else "Free, once per stop.")


func _do_cook() -> void:
	var d := crossing.cook()
	_after_action()
	if not d.is_empty():
		_log.text = crossing.journal[crossing.journal.size() - 1]


func _cook_tip() -> String:
	var r := Camp.best_recipe(crossing.pantry)
	var why: String = {"cooked": "You've already cooked here.", "pantry": "Nothing in the pantry to cook. Go foraging.", "food": "Not enough food for a meal.", "busy": ""}.get(crossing.cook_block(), "")
	var t := "{k:cook}"
	if not r.is_empty():
		t += "\n[b]%s[/b]: %s %s" % [r["name"], TrailFx.cost({"food": -int(Camp.MEAL_FOOD)}), TrailFx.preview(r["fx"])]
	return t + ("\n[color=#ff8a7a]%s[/color]" % why if why != "" else "")


func _do_hunt() -> void:
	if not crossing.start_hunt():
		_after_action()
		return
	_refresh_hud()
	if crossing.state == Expedition.State.FAILED:
		_show_end(false)
		return
	_open_battle(false)


func _hunt_tip() -> String:
	var why: String = {"town": "No game this close to town.", "spooked": "You already hunted here. The herd won't come back.",
		"ko": "Nobody is fit to hunt.", "busy": ""}.get(crossing.hunt_block(), "")
	return "{k:hunt}\n" + ("[color=#ff8a7a]%s[/color]" % why if why != "" else "Costs a {i:day} day of food and water.")


func _do_repair() -> void:
	crossing.repair()
	_after_action()


# ---------- HUD and end ----------

func _refresh_hud() -> void:
	var w := TrailLife.weather(crossing.weather)
	Rich.set_text(_hud, "{i:%s} {i:day}%d   {i:food}%d[color=#c8bca8]/%.0fd[/color]   {i:water}%d[color=#c8bca8]/%.0fd[/color]   {i:coins}%d   {i:weight}%d   {i:haul}%d   {i:wagon}%d%%" % [
		w["icon"], crossing.day, roundi(crossing.provisions), floorf(crossing.days_of(crossing.provisions, crossing.daily_provisions())),
		roundi(crossing.water), floorf(crossing.days_of(crossing.water, crossing.daily_water())), crossing.coins, roundi(crossing.load_weight()), roundi(crossing.hauling_available()), crossing.wagon.integrity])
	var band := Camp.band(crossing.morale)
	var hp := ("[color=#%s]{i:morale}%d[/color]  " % [band[3], crossing.morale]) + (("{i:health}[color=#ff8a7a]%d[/color]" if crossing.health < 50 else "{i:health}%d") % crossing.health)
	if crossing.fever_days > 0:
		hp = "{i:fever}" + hp
	if crossing.frost_day > 0:
		var left := crossing.frost_left()
		var col := "ff8a7a" if left <= 0 else ("f0d27a" if left <= Expedition.LATE_DAYS else "e8dcc0")
		hp = ("[color=#%s]{i:frost}%s[/color]  " % [col, "FROST" if left <= 0 else "%dd" % left]) + hp
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
	_end_grave.visible = not won
	if won:
		title.text = "Crossing %d: you reached %s" % [crossing_no, crossing.map.name_of(crossing.map.goal)]
		body.text = "Day %d. Delivered %d cargo for %d coins.\nYour team, levels, dust, items and coins come with you." % [crossing.day, crossing.cargo.size(), crossing.cargo_paid]
		Rich.set_text(_end_score, _score_markup() + _scrapbook_markup())
		again.text = "Next crossing"
	else:
		title.text = "Crossing %d failed" % crossing_no
		body.text = "%s\nDay %d, %d visited stops." % [crossing.fail_reason, crossing.day, crossing.visited.size()]
		Rich.set_text(_end_score, _scrapbook_markup())
		_epitaph.editable = true
		if SaveGame.is_hardcore(_slot):
			body.text += "\nHardcore: this caravan is gone for good."
			again.text = "New hardcore caravan"
		else:
			body.text += "\nTrying again starts this crossing over with fresh supplies.\nYour team keeps the experience it earned."
			again.text = "Try this crossing again"
	_save()
	(_end.find_child("Again", true, false) as Button).grab_focus.call_deferred()


## The arrival reckoning, as icon rows and a rank.
func _score_markup() -> String:
	var sc := crossing.arrival_score()
	var t := "[b]Arrival score: %d[/b]  [color=#ffe3a3]%s[/color]" % [int(sc["total"]), sc["rank"]]
	var best := 0
	for v in crossing.score_history.slice(0, crossing.score_history.size() - 1):
		best = maxi(best, int(v))
	if best > 0:
		t += "  [color=#c8bca8](best before: %d)[/color]" % best
	var parts: Array[String] = []
	for l in sc["lines"]:
		parts.append("{i:%s}%s [color=#%s]%+d[/color]" % [l[0], l[1], "9fe0a0" if int(l[2]) >= 0 else "ff8a7a", int(l[2])])
	return t + "\n" + "   ".join(parts)


## The last few scrapbook entries of the crossing.
func _scrapbook_markup() -> String:
	if crossing.scrapbook.is_empty():
		return ""
	var t := "\n[b]Scrapbook[/b]"
	var entries: Array = crossing.scrapbook.slice(maxi(0, crossing.scrapbook.size() - 8))
	for e in entries:
		t += "\n{i:%s} [color=#c8bca8]Day %d[/color]  %s" % [e["icon"], int(e["day"]), e["text"]]
	return t


func _lay_stone() -> void:
	if not _epitaph.editable:
		return
	var lead: String = crossing.display_name(crossing.roster[0]) if not crossing.roster.is_empty() else "Your"
	var region: String = crossing.map.regions.get(crossing.map.junctions.get(crossing.at, {}).get("region", ""), {}).get("name", "")
	var g := Graves.lay(crossing_no, crossing.day, lead, region, _epitaph.text)
	_epitaph.text = "\"%s\"" % g["epitaph"]
	_epitaph.editable = false


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
	Tips.attach(_hud_health, func(): return "{i:morale} [b]Morale %d[/b]: %s\n{k:morale}" % [crossing.morale, Camp.band(crossing.morale)[2]])
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
	var guide := _button("Guide", 8)
	guide.focus_mode = Control.FOCUS_NONE
	guide.pressed.connect(_open_guide)
	Tips.attach(guide, func(): return "How to play: the goal, food and water, roads and growing your team. Travel pauses while it's open.")
	row.add_child(guide)
	var speaker := _button("", 8)
	speaker.icon = Rich.icon_tex("sound_off" if Sound.muted else "sound_on")
	speaker.focus_mode = Control.FOCUS_NONE
	speaker.pressed.connect(func():
		speaker.icon = Rich.icon_tex("sound_off" if Sound.toggle_mute() else "sound_on"))
	Tips.attach(speaker, func(): return "Sound and music on or off.")
	row.add_child(speaker)
	var book := _button("", 8)
	book.icon = Rich.icon_tex("field_guide")
	book.focus_mode = Control.FOCUS_NONE
	book.pressed.connect(_open_field_guide)
	Tips.attach(book, func(): return "{i:field_guide} [b]Field guide[/b]\nEvery Trailomon you've met, where you met it and how it grows. Travel pauses while it's open.")
	row.add_child(book)
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
	_outfit_box = VBoxContainer.new()
	_outfit_box.add_theme_constant_override("separation", 2)
	_outfit_box.visible = false
	_trade_page.add_child(_outfit_box)
	_rumor = Rich.label("", 8, 284)
	_trade_page.add_child(_rumor)
	_shop_box = VBoxContainer.new()
	_shop_box.add_theme_constant_override("separation", 2)
	_shop_box.visible = false
	_trade_page.add_child(_shop_box)
	_job_box = HBoxContainer.new()
	_job_box.add_theme_constant_override("separation", 4)
	_trade_page.add_child(_job_box)
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
	Tips.attach(_repair, _repair_tip)
	acts.add_child(_repair)
	_hunt = _button("Hunt (1 day)", 9)
	_hunt.icon = Rich.icon_tex("food")
	_hunt.pressed.connect(_do_hunt)
	Tips.attach(_hunt, _hunt_tip)
	acts.add_child(_hunt)
	_healer = _button("Healer", 9)
	_healer.icon = Rich.icon_tex("healer")
	_healer.pressed.connect(_do_heal)
	Tips.attach(_healer, func(): return "The stop's healer patches the whole team back to full health and wakes {k:ko|knocked out} ones, without losing a day. %d {i:coins} (%d per hurt Trailomon, %d per knocked out one). Once per stop each crossing." % [
		crossing.heal_cost(), Expedition.HEAL_COST_HURT, Expedition.HEAL_COST_KO])
	_wagon_page.add_child(acts)
	var camp := HBoxContainer.new()
	camp.add_theme_constant_override("separation", 4)
	camp.add_child(_healer)
	_forage = _button("Forage", 9)
	_forage.icon = Rich.icon_tex("forage")
	_forage.pressed.connect(_do_forage)
	Tips.attach(_forage, _forage_tip)
	camp.add_child(_forage)
	_cook = _button("Cook", 9)
	_cook.icon = Rich.icon_tex("cook")
	_cook.pressed.connect(_do_cook)
	Tips.attach(_cook, _cook_tip)
	camp.add_child(_cook)
	_pantry_label = Rich.label("", 8)
	Tips.attach(_pantry_label, func(): return "{k:cook}")
	camp.add_child(_pantry_label)
	_wagon_page.add_child(camp)
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
	_end.position = Vector2(120, 40)
	_end.custom_minimum_size = Vector2(400, 120)
	_end.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.94)))
	var ecol := VBoxContainer.new()
	ecol.add_theme_constant_override("separation", 6)
	_end.add_child(ecol)
	var et := PreviewHud.label("", 16)
	et.name = "EndTitle"
	ecol.add_child(et)
	var eb := PreviewHud.label("", 9)
	eb.name = "EndBody"
	eb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eb.custom_minimum_size = Vector2(388, 0)
	ecol.add_child(eb)
	_end_score = Rich.label("", 8, 388)
	ecol.add_child(_end_score)
	# A failed caravan: write its epitaph. The stone turns up on later runs.
	_end_grave = HBoxContainer.new()
	_end_grave.add_theme_constant_override("separation", 4)
	_epitaph = LineEdit.new()
	_epitaph.placeholder_text = "Write an epitaph..."
	_epitaph.max_length = Graves.EPITAPH_MAX
	_epitaph.add_theme_font_size_override("font_size", 9)
	_epitaph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_grave.add_child(_epitaph)
	var lay := _button("Lay the stone", 9)
	lay.icon = Rich.icon_tex("grave")
	lay.pressed.connect(_lay_stone)
	Tips.attach(lay, func(): return "{i:grave} Your stone will stand by the road on this crossing in later runs.")
	_end_grave.add_child(lay)
	ecol.add_child(_end_grave)
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
		_setup_caravan()
		_refresh_hud())


var _field_guide: FieldGuideScreen


func _open_field_guide() -> void:
	if _field_guide != null and is_instance_valid(_field_guide):
		return
	_field_guide = FieldGuideScreen.open(_ui, crossing)
	_field_guide.closed.connect(func(): _field_guide = null)


## The how-to-play guide (opens by itself when a new caravan sets out).
func _open_guide() -> void:
	if _guide != null and is_instance_valid(_guide):
		return
	_guide = GuideScreen.open(_ui, crossing)
	_guide.closed.connect(func(): _guide = null)


func _button(text: String, size: int) -> Button:
	return Ui.button(text, size)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_to_title()

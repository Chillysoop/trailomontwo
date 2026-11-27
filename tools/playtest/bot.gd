extends SceneTree
## Playtest bot: plays the real game through its screens, from the title screen, like a
## careful new player. Takes screenshots of firsts and keeps a log of everything that happens.
## Needs a display for screenshots (headless runs just log):
##   xvfb-run godot --path . --script res://tools/playtest/bot.gd -- out=<dir> crossings=N seed=S
##   style=smart|careful|reckless
##   smart: plans like a thoughtful player. Takes risky roads for experience while supplies
##     allow, rests up before the guardian road, saves battle items for the guardian, sticks to
##     one style per Trailomon, picks the rarest boosts, swaps in strong recruits.
##   careful: buys supplies and rests, but picks moves at random and burns items on every fight.
##   reckless: never shops or rests, picks at random.

var out_dir := "user://playtest"
var crossings := 3
var seed_value := 1
var style := "careful"
var rng := RandomNumberGenerator.new()
var shots_taken := {}
var log_lines: Array[String] = []
var stats := {"battles": 0, "wins": 0, "losses": 0, "retreats": 0, "events": 0, "guardian": [], "crossing_days": [], "fails": [], "levels": [], "recruits": 0, "evolved": 0, "offscreen": {}}
var exp: Node
var started_ms := 0
var _crossing_seen := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"out": out_dir = kv[1]
			"crossings": crossings = int(kv[1])
			"seed": seed_value = int(kv[1])
			"style": style = kv[1]
	rng.seed = seed_value
	seed(seed_value)
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveGame.dir = "user://playtest_saves_%d/" % seed_value
	DirAccess.make_dir_recursive_absolute(SaveGame.dir)
	for f in DirAccess.get_files_at(SaveGame.dir):
		DirAccess.remove_absolute(SaveGame.dir.path_join(f))
	started_ms = Time.get_ticks_msec()
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/title_screen.tscn")
	await _frames(30)
	await _shot("00_title")
	var start := _find_button(root, "Start expedition")
	start.pressed.emit()
	await _frames(10)
	await _shot("01_save_picker")
	_find_button(root, "New caravan").pressed.emit()
	await _frames(30)
	exp = current_scene
	# The how-to-play guide opens for a new caravan: read it page by page, like a new player.
	var guide: GuideScreen = exp.get("_guide")
	if guide != null:
		for i in GuideScreen.pages(_c()).size():
			await _shot("01_guide_%d" % (i + 1))
			var nb := _find_button(guide, "Next")
			if nb == null:
				nb = _find_button(guide, "Let's go")
			nb.pressed.emit()
			await _frames(4)
	if exp.get("_guide") != null:
		_say("ERROR: guide did not close")
	Engine.time_scale = 40.0 if DisplayServer.get_name() == "headless" else 6.0
	_say("Started crossing 1 at %s" % _c().map.name_of(_c().at))
	var guard := 0
	while guard < 200000:
		guard += 1
		await _frames(2)
		if not is_instance_valid(exp):
			_say("ERROR: expedition screen vanished")
			break
		var done := await _tick()
		if done:
			break
	_report()
	quit(0)


func _c() -> Expedition:
	return exp.get("crossing")


## One look at the screen and one action. Returns true when the playtest is over.
func _tick() -> bool:
	var c := _c()
	var end: Control = exp.get("_end")
	var battle: Node = exp.get("_battle")
	var event: Control = exp.get("_event")
	var panel: Control = exp.get("_panel")
	if battle != null and is_instance_valid(battle):
		await _battle_tick(battle)
		return false
	if end.visible:
		return await _end_tick(c)
	if event.visible:
		await _event_tick(c, event)
		return false
	if panel.visible and c.state == Expedition.State.AT_JUNCTION:
		await _junction_tick(c)
		return false
	if c.state == Expedition.State.TRAVELLING:
		var terr := String(c.scenery()["terrain"])
		if not shots_taken.has("road_" + terr) and exp.get("_companions") == null:
			shots_taken["road_" + terr] = true
			await _frames(40)
			if exp.get("_event").visible == false and exp.get("_battle") == null:
				await _shot("road_%s_c%d" % [terr.to_lower(), c.crossing_no])
	return false


func _junction_tick(c: Expedition) -> void:
	if c.crossing_no != _crossing_seen:
		_crossing_seen = c.crossing_no
		_say("Crossing %d begins: coins %d food %d water %d, guardian %s, haulers %s" % [c.crossing_no, c.coins, c.provisions, c.water, c.guardian_pack()["id"], c.haulers])
		await _frames(10)
		await _shot("c%d_01_first_stop" % c.crossing_no)
		if c.crossing_no == 1:
			exp.call("_show_tab", "trade")
			await _frames(5)
			await _shot("c1_02_trade")
			exp.call("_show_tab", "wagon")
			await _frames(5)
			await _shot("c1_03_wagon")
			exp.call("_show_tab", "route")
			exp.call("_open_companions")
			await _frames(10)
			await _shot("c1_04_companions")
			exp.get("_companions").call("close_screen")
			await _frames(5)
			exp.call("_toggle_world")
			await _frames(10)
			await _shot("c1_05_overworld")
			exp.call("_toggle_world")
		else:
			exp.call("_toggle_world")
			await _frames(10)
			await _shot("c%d_05_overworld" % c.crossing_no)
			exp.call("_toggle_world")
	# Level ups and team upkeep, like a player at a stop.
	await _upkeep(c)
	# Buy supplies when low.
	if style != "reckless":
		for i in 6:
			if c.provisions < 100 and c.buy("food").is_empty():
				break
		for i in 6:
			if c.water < 45 and c.buy("water").is_empty():
				break
		if c.wagon.wear > 45 and c.repair_kits == 0:
			c.buy("repair_kit")
		if c.wagon.broken != Wagon.Part.NONE or (c.wagon.wear > 60 and c.repair_kits > 0):
			exp.call("_do_repair")
		# Rest when half the team is hurt or anyone is knocked out.
		var hurt := 0
		for id in c.roster:
			if float(c.creature_hp.get(id, 0.0)) < c.max_hp(id) * 0.5:
				hurt += 1
		var rests := 0
		var goal_next := false
		for seg in c.exits():
			if seg["to"] == c.map.goal:
				goal_next = true
		# Smart: go into the guardian road rested and healthy.
		if style == "smart" and goal_next and not c.guardian_faced:
			hurt = 0
			for id in c.roster:
				if float(c.creature_hp.get(id, 0.0)) < c.max_hp(id) * 0.85:
					hurt += 1
			hurt = 3 if hurt > 0 else 0
		while (hurt >= 3 or not c.knocked_out().is_empty()) and rests < 2 and c.provisions > 30:
			exp.call("_do_rest")
			rests += 1
			hurt = 0
			for id in c.roster:
				if float(c.creature_hp.get(id, 0.0)) < c.max_hp(id) * 0.5:
					hurt += 1
	elif c.wagon.broken == Wagon.Part.RUNNING_GEAR:
		exp.call("_do_repair")
	if c.state == Expedition.State.FAILED:
		return
	# Pick the road: closest to the goal, sometimes a random fork.
	var best: Array = []
	var best_h := 999
	for seg in c.exits():
		var h := c.map.hops(seg["to"], c.map.goal)
		if h < best_h:
			best_h = h
			best = [seg]
		elif h == best_h or (h == best_h + 1 and rng.randf() < 0.25):
			best.append(seg)
	var seg: Dictionary = best[rng.randi_range(0, best.size() - 1)]
	if style == "smart":
		seg = _smart_road(c, best_h)
	exp.call("_pick", seg)
	var go: Button = exp.get("_go")
	var tries := 0
	while go.disabled and tries < 4:
		if go.text.begins_with("Too heavy"):
			var added := false
			for id in c.roster:
				if c.can_haul(id) and not c.haulers.has(id) and c.conscious(id):
					exp.call("_toggle_hauler", id)
					_say("Harnessed %s (too heavy)" % id)
					added = true
					break
			if not added:
				_say("Can't set off (%s), resting" % go.text)
				exp.call("_do_rest")
		else:
			_say("Can't set off (%s), resting" % go.text)
			exp.call("_do_rest")
		exp.call("_pick", seg)
		tries += 1
	if go.disabled:
		_say("STUCK at %s: %s" % [c.map.name_of(c.at), go.text])
		# Drop cargo to get moving.
		if not c.cargo.is_empty():
			exp.call("_drop", 0)
		return
	go.pressed.emit()


func _upkeep(c: Expedition) -> void:
	if c.pending_count() > 0:
		var first := not shots_taken.has("levelup")
		var s := LevelUpScreen.open(exp.get("_ui"), c)
		await _frames(5)
		if first:
			shots_taken["levelup"] = true
			await _shot("levelup_screen")
		var g := 0
		while c.pending_count() > 0 and g < 50:
			g += 1
			var pick := _best_option(c.pending_levels[0])
			s.call("_pick", pick)
			await _frames(2)
			if c.pending_count() > 0 and int(s.get("_picked")) == pick:
				if not shots_taken.has("levelup_move"):
					shots_taken["levelup_move"] = true
					await _shot("levelup_move_pick")
				s.call("_finish", pick, false)
				await _frames(2)
		if is_instance_valid(s):
			s.call("close_screen")
		await _frames(2)
	if style == "reckless":
		return
	# Evolve when possible.
	for id in c.roster.duplicate():
		var opts := c.evolve_options(id)
		if not opts.is_empty():
			var line := c.evolve(id, opts[0])
			if line != "":
				stats["evolved"] += 1
				_say("EVOLVE " + line)
	# Spend dust on attack (light) and hp (dark)
	for id in c.roster:
		while c.light_dust > 0 and c.dust_left(id) > 0 and (style == "smart" or rng.randf() < 0.5):
			c.use_dust(id, "light", "atk")
		while style == "smart" and c.dark_dust > 0 and c.dust_left(id) > 0:
			if c.use_dust(id, "dark", "hp") == "":
				break
	# Swap in stored creatures that look stronger (higher base hp*atk).
	for sid in c.stored.duplicate():
		var weakest := ""
		var weak_power := INF
		for id in c.roster:
			var p := _power(c, id)
			if p < weak_power:
				weak_power = p
				weakest = id
		if weakest != "" and _power(c, sid) > weak_power * (1.1 if style == "smart" else 1.25) and not c.haulers.has(weakest):
			if c.swap_stored(sid, weakest):
				_say("SWAP in %s for %s" % [sid, weakest])
	# Fill item slots with anything we hold (smart players save them for the guardian).
	if style == "smart":
		return
	for i in 3:
		if c.item_slots[i] == "" or int(c.items.get(c.item_slots[i], 0)) <= 0:
			for id in c.items:
				if int(c.items[id]) > 0 and not c.item_slots.has(id):
					c.item_slots[i] = id
					break


func _power(c: Expedition, id: String) -> float:
	return c.stat(id, "atk") * c.max_hp(id) * (1.0 + 0.1 * c.level(id))


## Smart road choice: risky roads for experience while supplies and health allow, the safest
## road when they run low. Never strays more than one stop from the shortest way.
func _smart_road(c: Expedition, best_h: int) -> Dictionary:
	var hp := 0.0
	var top := 0.0
	for id in c.roster:
		hp += float(c.creature_hp.get(id, 0.0))
		top += c.max_hp(id)
	var flush := c.provisions >= 60 and c.water >= 30 and hp >= top * 0.6
	var pick: Dictionary = {}
	var score := -INF
	for seg in c.exits():
		var h := c.map.hops(seg["to"], c.map.goal)
		if h > best_h + (1 if flush and c.provisions >= 90 else 0):
			continue
		var sc := -float(h) * 2.0 - float(seg["days"]) * 0.3
		sc += float(seg["risk"]) * (1.5 if flush else -1.5)
		if sc > score:
			score = sc
			pick = seg
	return pick


const SMART_ITEMS := ["rally_horn", "ember_draught", "ironbark_salve", "stoneskin_tea", "mending_moss", "bitter_ash", "swiftwind_feather", "smoke_pouch"]

## Smart: battle items only for the guardian (or a wild fight that looks too strong).
func _smart_items(c: Expedition, use: bool) -> void:
	for i in 3:
		c.set_item_slot(i, "")
	if not use:
		return
	var slot := 0
	for id in SMART_ITEMS:
		if slot < 3 and c.item_free(id) > 0:
			c.set_item_slot(slot, id)
			slot += 1


func _best_option(p: Dictionary) -> int:
	# Prefer the rarer stat option; moves: first.
	var opts: Array = p["options"]
	if opts.size() < 2:
		return 0
	if style == "smart":
		if opts[0]["kind"] == "stat" and opts[1]["kind"] == "stat":
			var pref := {"atk": 3, "hp": 2, "spd": 1, "def": 0}
			var a := int(opts[0]["rarity"]) * 10 + int(pref[opts[0]["stat"]])
			var b := int(opts[1]["rarity"]) * 10 + int(pref[opts[1]["stat"]])
			return 1 if b > a else 0
		# Stick to one style (archetype) per Trailomon.
		var id := String(p["id"])
		if not _style_of.has(id):
			_style_of[id] = String(opts[0].get("archetype", ""))
		for i in opts.size():
			if String(opts[i].get("archetype", "")) == _style_of[id]:
				return i
		return 0
	if opts[0]["kind"] == "stat" and opts[1]["kind"] == "stat":
		return 1 if int(opts[1]["rarity"]) > int(opts[0]["rarity"]) else 0
	return rng.randi_range(0, 1)


func _event_tick(c: Expedition, event: Control) -> void:
	var choices: Node = exp.get("_event_choices")
	var cont: Button = exp.get("_event_continue")
	await _frames(3)
	if cont.visible:
		var kids := choices.get_children().filter(func(n): return not n.is_queued_for_deletion())
		if not kids.is_empty():
			# A recruit offer: take it.
			(kids[0] as ClickRow).pressed.emit()
			stats["recruits"] += 1
			await _frames(3)
		if not shots_taken.has("event_result"):
			shots_taken["event_result"] = true
			await _shot("event_result")
		cont.pressed.emit()
		return
	var kids := choices.get_children().filter(func(n): return not n.is_queued_for_deletion())
	if kids.is_empty():
		return
	var title := Rich.bb("") if false else ""
	if not c.pending_encounter.is_empty():
		var first := not shots_taken.has("encounter")
		if first:
			shots_taken["encounter"] = true
			await _shot("encounter_c%d" % c.crossing_no)
		# Always fight (this is a battle playtest), unless nobody can.
		(kids[0] as ClickRow).pressed.emit()
		return
	stats["events"] += 1
	var ev := c.pending_event
	_say("EVENT %s" % ev.get("title", "?"))
	if not shots_taken.has("event_" + String(ev.get("id", ""))) and shots_taken.keys().filter(func(k): return String(k).begins_with("event_")).size() < 6:
		shots_taken["event_" + String(ev.get("id", ""))] = true
		await _shot("event_%s" % ev.get("id", ""))
	var views := c.event_choices(ev)
	var pick := 0
	var ok: Array = []
	for i in views.size():
		if views[i]["affordable"]:
			ok.append(i)
	if style == "careful":
		pick = c.safe_choice(ev)
		if rng.randf() < 0.5 and not ok.is_empty():
			pick = ok[rng.randi_range(0, ok.size() - 1)]
	else:
		pick = ok[rng.randi_range(0, ok.size() - 1)] if not ok.is_empty() else 0
	(kids[pick] as ClickRow).pressed.emit()


var _style_of := {}
var _battle_state := ""
func _battle_tick(b: Node) -> void:
	var c := _c()
	var phase: int = b.get("phase")
	match phase:
		BattleScreen.Phase.LINEUP:
			await _frames(10)
			var guardian := bool(c.pending_encounter.get("guardian", false))
			if guardian:
				await _shot("guardian_lineup_c%d" % c.crossing_no)
			elif not shots_taken.has("lineup"):
				shots_taken["lineup"] = true
				await _shot("battle_lineup")
			_find_button(b, "Auto-arrange").pressed.emit()
			await _frames(2)
			if style == "smart":
				_smart_items(c, guardian or float(c.pending_encounter.get("scale", 1.0)) >= 1.45)
			_battle_state = "guardian" if guardian else "pack"
			stats["battles"] += 1
			var lv: Array = []
			for id in c.roster:
				lv.append(c.level(id))
			b.set_meta("levels", lv)
			b.set_meta("pack", String(c.pending_encounter.get("pack", {}).get("id", "?")))
			b.set_meta("scale", c.enemy_scale())
			_find_button(b, "Fight!").pressed.emit()
			await _frames(2)
			b.call("_cycle_speed")
			b.call("_cycle_speed")
			b.set_meta("t0", Time.get_ticks_msec())
		BattleScreen.Phase.COMBAT:
			if not b.has_meta("shot") and (b.get("battle") as Battle).time > 6.0:
				b.set_meta("shot", true)
				if _battle_state == "guardian":
					await _shot("guardian_combat_c%d" % c.crossing_no)
				elif not shots_taken.has("combat"):
					shots_taken["combat"] = true
					await _shot("battle_combat")
		BattleScreen.Phase.AFTERMATH:
			await _frames(5)
			var battle: Battle = b.get("battle")
			var o := battle.outcome
			var oname: String = {Battle.Outcome.VICTORY: "WIN", Battle.Outcome.DEFEAT: "LOSS", Battle.Outcome.WITHDRAW: "WITHDRAW", Battle.Outcome.RETREAT: "RETREAT"}[o]
			if o == Battle.Outcome.VICTORY: stats["wins"] += 1
			elif o == Battle.Outcome.DEFEAT: stats["losses"] += 1
			else: stats["retreats"] += 1
			var avg := 0.0
			for l in b.get_meta("levels"):
				avg += l
			avg /= maxf(1, (b.get_meta("levels") as Array).size())
			_say("BATTLE c%d %s %s vs %s (scale %.2f, team avg Lv %.1f, %ds)" % [c.crossing_no, _battle_state, oname, b.get_meta("pack"), b.get_meta("scale"), avg, int(battle.time)])
			if _battle_state == "guardian":
				stats["guardian"].append("c%d %s %s Lv%.1f" % [c.crossing_no, b.get_meta("pack"), oname, avg])
				await _shot("guardian_after_c%d" % c.crossing_no)
			elif not shots_taken.has("after"):
				shots_taken["after"] = true
				await _shot("battle_aftermath")
			var take := _find_button(b, "Take in")
			if take != null and not take.disabled:
				take.pressed.emit()
				stats["recruits"] += 1
				await _frames(2)
			_find_button(b, "Continue").pressed.emit()
			await _frames(5)


func _end_tick(c: Expedition) -> bool:
	await _frames(10)
	var won := c.state == Expedition.State.ARRIVED
	await _shot("c%d_end_%s" % [c.crossing_no, "won" if won else "failed"])
	var lv: Array = []
	for id in c.roster:
		lv.append("%s:%d" % [id, c.level(id)])
	_say("END crossing %d %s day %d | %s | team %s" % [c.crossing_no, "ARRIVED" if won else "FAILED (" + c.fail_reason + ")", c.day, "coins %d food %d water %d" % [c.coins, c.provisions, c.water], ", ".join(lv)])
	if won:
		stats["crossing_days"].append(c.day)
		stats["levels"].append(lv)
	else:
		stats["fails"].append("c%d: %s" % [c.crossing_no, c.fail_reason])
		if (stats["fails"] as Array).size() > 6:
			return true
	if won and c.crossing_no >= crossings:
		return true
	(exp.get("_end").find_child("Again", true, false) as Button).pressed.emit()
	await _frames(10)
	_say("Started crossing %d" % _c().crossing_no)
	return false


func _report() -> void:
	_say("---- SUMMARY ----")
	_say(JSON.stringify(stats, "  "))
	_say("real time %ds" % ((Time.get_ticks_msec() - started_ms) / 1000))
	var f := FileAccess.open(out_dir.path_join("log.txt"), FileAccess.WRITE)
	f.store_string("\n".join(log_lines))


func _say(s: String) -> void:
	print(s)
	log_lines.append(s)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.begins_with(text):
		return node
	for ch in node.get_children():
		var r := _find_button(ch, text)
		if r != null:
			return r
	return null


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Flag visible controls that spill off the 640x360 screen.
func _check_bounds(name: String) -> void:
	var bad: Array[String] = []
	_walk_bounds(root, bad)
	if not bad.is_empty():
		stats["offscreen"][name] = bad.slice(0, 4)


func _walk_bounds(n: Node, bad: Array[String]) -> void:
	if n is Control and (n as Control).is_visible_in_tree():
		var r := (n as Control).get_global_rect()
		if r.size.x > 0 and (r.end.x > 642 or r.end.y > 362 or r.position.x < -2 or r.position.y < -2):
			if n is Label or n is RichTextLabel or n is Button or n is PanelContainer:
				bad.append("%s %s" % [n.get_class(), str(r)])
	for ch in n.get_children():
		_walk_bounds(ch, bad)


func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_check_bounds(name)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))

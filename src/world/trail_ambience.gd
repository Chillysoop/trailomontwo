class_name TrailAmbience
extends Node2D
## The world going on around the wagon: wild Trailomon grazing in the distance, birds, other
## travellers and traders on the road, roadside graves and signposts, settlement buildings at
## stops, and weather (rain, snow, fog, storm flashes, heat and terrain tint).
##
## Add it after the backdrop and before the caravan so everything here stands behind the wagon.
## Weather particles live on their own layer above the scene (see `weather_layer`).

const ROAD_SPEED := 30.0
const FAR_SPEED := 20.0
const FAR_FEET_Y := 262.0
const VERGE_FEET_Y := 274.0
const ROAD_FEET_Y := 284.0
const SCREEN := Vector2(640, 360)

## Each terrain has its own painted scenery now, so the tint only nudges the mood.
const TERRAIN_TINT := {
	"Forest": Color(1, 1, 1), "Hills": Color(1, 1, 1), "River": Color(1, 1, 1),
	"Swamp": Color(0.95, 0.98, 0.94), "Mountain": Color(0.97, 0.98, 1.0),
	"Blight": Color(0.88, 0.84, 0.94), "Glow": Color(1.04, 1.02, 0.96),
}
const WEATHER_TINT := {
	"clear": Color(1, 1, 1), "rain": Color(0.8, 0.84, 0.92), "fog": Color(0.9, 0.9, 0.93),
	"storm": Color(0.6, 0.6, 0.74), "heat": Color(1.0, 0.92, 0.8), "cold": Color(0.86, 0.91, 1.0),
	"ashfall": Color(0.78, 0.74, 0.84), "shimmer": Color(1.03, 1.0, 0.92),
}
## Roadside props by terrain (assets/props). Graves and signposts can turn up anywhere.
const ROADSIDE := {
	"Forest": ["signpost", "abandoned_cart", "stump_mushroom", "grave_marker", "fern_cluster"],
	"Hills": ["signpost", "hills_fence", "grave_marker", "hills_rocks", "well", "hills_heather"],
	"River": ["signpost", "river_reeds", "river_rocks", "grave_marker", "wheel_buried"],
	"Swamp": ["swamp_shrooms", "shrine_stone", "grave_marker", "swamp_cattails", "swamp_boiler"],
	"Mountain": ["mtn_boulder", "shrine_stone", "signpost", "grave_marker", "mtn_minecart", "mtn_shrub"],
	"Blight": ["blight_crystal", "blight_wreck", "grave_marker", "blight_brambles", "abandoned_cart"],
	"Glow": ["glow_crystal", "glow_pylon", "glow_flowers", "shrine_stone", "signpost"],
}
## Buildings swapped in at a stop in one terrain (a mountain post is a log mining cabin).
const TERRAIN_BUILDINGS := {
	"Mountain": {"trading_post": "bld_mine_post", "bld_inn": "bld_mine_post"},
	"Swamp": {"hut": "stilt_house"},
	"Blight": {"hut": "bld_ward_post"},
	"Glow": {"hut": "bld_sanctum"},
}

var moving := false
## Species the player has met. Only these graze in the distance (Conner: nothing unmet shows).
var encountered := {}
var terrain := "Forest"
var weather := "clear"
## Draws above the scene: rain, snow, fog, lightning. Created in _ready.
var weather_layer: Node2D

var _rng := RandomNumberGenerator.new()
var _scrollers: Array = []
var _settlement: Array[Node2D] = []
var _tint: CanvasModulate
var _rain: CPUParticles2D
var _snow: CPUParticles2D
var _ash: CPUParticles2D
var _motes: CPUParticles2D
var _fog: Array[TextureRect] = []
var _flash: ColorRect
var _timers := {"wild": 1.0, "birds": 2.0, "traveler": 6.0, "roadside": 2.0, "flash": 5.0}


func _ready() -> void:
	_rng.randomize()
	_tint = CanvasModulate.new()
	add_child(_tint)
	weather_layer = Node2D.new()
	weather_layer.z_index = 20
	add_child(weather_layer)
	_rain = _particles(_streak_tex(), 160, Vector2(-40, 420), 1.0)
	_rain.color = Color(0.82, 0.9, 1.0, 0.8)
	_snow = _particles(_dot_tex(), 90, Vector2(-12, 42), 6.0)
	_snow.color = Color(1, 1, 1, 0.85)
	_ash = _particles(_dot_tex(), 110, Vector2(-18, 30), 6.0)
	_ash.color = Color(0.36, 0.28, 0.46, 0.9)
	_motes = _particles(_dot_tex(), 60, Vector2(-8, -10), 6.0)
	_motes.color = Color(1.0, 0.9, 0.55, 0.85)
	_motes.position = Vector2(340, 250)
	_motes.emission_rect_extents = Vector2(380, 110)
	for i in 3:
		var f := TextureRect.new()
		var g := GradientTexture2D.new()
		g.gradient = Gradient.new()
		g.gradient.set_color(0, Color(0.92, 0.93, 0.96, 0.0))
		g.gradient.set_color(1, Color(0.92, 0.93, 0.96, 0.0))
		g.gradient.add_point(0.5, Color(0.92, 0.93, 0.96, 0.42 + 0.08 * i))
		g.fill_from = Vector2(0, 0)
		g.fill_to = Vector2(0, 1)
		g.width = 8
		g.height = 64
		f.texture = g
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.stretch_mode = TextureRect.STRETCH_SCALE
		f.size = Vector2(900, 70 + 30 * i)
		f.position = Vector2(-120 - 60 * i, 110 + 60 * i)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		weather_layer.add_child(f)
		_fog.append(f)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = SCREEN
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather_layer.add_child(_flash)
	set_weather(weather)
	# A few wild Trailomon and birds from the start, so the world is never empty.
	for i in 2:
		_spawn_wild(_rng.randf_range(60, 600))


func set_moving(on: bool) -> void:
	moving = on


func set_terrain(t: String) -> void:
	terrain = t if TERRAIN_TINT.has(t) else "Forest"
	_update_tint()


func set_weather(w: String) -> void:
	weather = w if WEATHER_TINT.has(w) else "clear"
	if _rain == null:
		return
	_rain.emitting = weather == "rain" or weather == "storm"
	_rain.amount = 260 if weather == "storm" else 180
	_snow.emitting = weather == "cold"
	_ash.emitting = weather == "ashfall"
	_motes.emitting = weather == "shimmer"
	for f in _fog:
		f.visible = weather == "fog"
	_update_tint()


## Turn the tint off while another screen (a battle) is shown.
func set_active(on: bool) -> void:
	visible = on
	_tint.visible = on
	weather_layer.visible = on


func _update_tint() -> void:
	if _tint != null:
		_tint.color = TERRAIN_TINT[terrain] * WEATHER_TINT[weather]


# ---------- settlements ----------

## Buildings around the wagon at a stop (kind from Settlements.KINDS), or none ("").
func show_settlement(kind: String) -> void:
	for n in _settlement:
		if is_instance_valid(n):
			n.queue_free()
	_settlement.clear()
	if kind == "" or not Settlements.KINDS.has(kind):
		return
	var props: Array = Settlements.KINDS[kind]["props"].duplicate()
	var swap: Dictionary = TERRAIN_BUILDINGS.get(terrain, {})
	for i in props.size():
		props[i] = swap.get(props[i], props[i])
	var xs := [44.0, 330.0, 140.0, 470.0]
	for i in props.size():
		var s := _sprite(String(props[i]), Vector2(xs[i % xs.size()], VERGE_FEET_Y - 2 * (i % 2)), 1.0, i % 2 == 1)
		if s == null:
			continue
		s.modulate = Color(0, 0, 0, 0)
		s.create_tween().tween_property(s, "modulate", Color.WHITE, 0.6)
		_add_scroller(s, ROAD_SPEED * 0.9, 0.0)
		_settlement.append(s)


# ---------- sights from trail moments ----------

## Something a trail moment talks about comes into view: "grave", "traveler", "trader", "wild", "campfire".
func spawn_sight(sight: String, data := {}) -> void:
	match sight:
		"grave":
			_spawn_roadside("grave_marker", 560.0)
		"traveler":
			_spawn_traveler(false)
		"trader":
			_spawn_traveler(true)
		"wild":
			_spawn_wild(_rng.randf_range(380, 600), String(data.get("species", "")))
		"campfire":
			_spawn_roadside("tent_camp", 600.0)
			_spawn_roadside("campfire", 650.0)


# ---------- spawning ----------

func _process(delta: float) -> void:
	if not visible:
		return
	for k in _timers:
		_timers[k] -= delta
	if _timers["wild"] <= 0.0:
		_timers["wild"] = _rng.randf_range(5.0, 10.0)
		_spawn_wild(680.0 if moving else _rng.randf_range(80, 600))
	if _timers["birds"] <= 0.0:
		_timers["birds"] = _rng.randf_range(6.0, 13.0)
		_spawn_birds()
	if _timers["traveler"] <= 0.0:
		_timers["traveler"] = _rng.randf_range(14.0, 26.0)
		_spawn_traveler(_rng.randf() < 0.35)
	if _timers["roadside"] <= 0.0:
		_timers["roadside"] = _rng.randf_range(3.5, 7.0)
		if moving:
			var list: Array = ROADSIDE.get(terrain, ROADSIDE["Forest"])
			_spawn_roadside(String(list[_rng.randi_range(0, list.size() - 1)]), 690.0)
	if _timers["flash"] <= 0.0:
		_timers["flash"] = _rng.randf_range(4.0, 9.0)
		if weather == "storm":
			_flash.color.a = 0.55
			var t := _flash.create_tween()
			t.tween_property(_flash, "color:a", 0.0, 0.35)
	for f in _fog:
		if f.visible:
			f.position.x += (6.0 + (12.0 if moving else 0.0)) * delta * (1.0 if f.get_index() % 2 == 0 else 0.6)
			if f.position.x > 0.0:
				f.position.x = -240.0
	for i in range(_scrollers.size() - 1, -1, -1):
		var s: Dictionary = _scrollers[i]
		var obj: Variant = s["node"]
		if not is_instance_valid(obj):
			_scrollers.remove_at(i)
			continue
		var n := obj as Node2D
		n.position.x += (-(float(s["speed"]) if moving else 0.0) + float(s["walk"])) * delta
		if n.position.x < -220.0 or n.position.x > 900.0:
			n.queue_free()
			_scrollers.remove_at(i)


func _spawn_wild(x: float, species := "") -> void:
	if species == "" or not Species.DATA.has(species):
		var pool: Array[String] = []
		var habitat: String = TrailLife.TERRAIN_HABITAT.get(terrain, "")
		for id in Species.DATA:
			if encountered.has(id) and id != "hollowstag" and String(Species.info(id).get("rarity", "")) != "guardian" \
					and (habitat == "" or Species.info(id)["type"] == habitat):
				pool.append(id)
		if pool.is_empty():
			return
		species = pool[_rng.randi_range(0, pool.size() - 1)]
	var face_left := _rng.randf() < 0.5
	var s := Stand.sprite(load("res://assets/creatures/%s.png" % species), Vector2(0, 0), face_left)
	var holder := Node2D.new()
	holder.position = Vector2(x, FAR_FEET_Y + _rng.randf_range(-4, 3))
	holder.scale = Vector2(0.5, 0.5)
	s.modulate = Color(0.82, 0.88, 0.86)
	holder.add_child(s)
	add_child(holder)
	# Grazing hops.
	var t := s.create_tween().set_loops()
	t.tween_interval(_rng.randf_range(0.8, 2.5))
	t.tween_property(s, "position:y", s.position.y - 6, 0.15).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "position:y", s.position.y, 0.15).set_trans(Tween.TRANS_SINE)
	_add_scroller(holder, FAR_SPEED, (-6.0 if face_left else 6.0) * _rng.randf_range(0.0, 1.0))


func _spawn_birds() -> void:
	var count := _rng.randi_range(3, 6)
	var y := _rng.randf_range(36, 110)
	var right := _rng.randf() < 0.4
	var flock := Node2D.new()
	flock.position = Vector2(-30.0 if right else 680.0, y)
	add_child(flock)
	for i in count:
		var b := Line2D.new()
		b.width = 1.0
		b.default_color = Color(0.17, 0.13, 0.19, 0.8)
		b.points = PackedVector2Array([Vector2(-3, -1), Vector2(0, 1), Vector2(3, -1)])
		b.position = Vector2(i * 9 * (-1 if right else 1), (i % 2) * 5 + i * 2)
		flock.add_child(b)
		var t := b.create_tween().set_loops()
		t.tween_property(b, "scale:y", -0.6, 0.18 + 0.02 * i)
		t.tween_property(b, "scale:y", 1.0, 0.18 + 0.02 * i)
	_add_scroller(flock, 4.0, 34.0 if right else -30.0)


func _spawn_traveler(trader: bool) -> void:
	var holder := Node2D.new()
	holder.position = Vector2(700, ROAD_FEET_Y)
	holder.scale = Vector2(0.65, 0.65)
	add_child(holder)
	var parts: Array[Node2D] = []
	if trader:
		var beast := Stand.sprite(load("res://assets/creatures/cairnram.png"), Vector2(-40, 0), true)
		beast.scale = Vector2(0.8, 0.8)
		beast.position *= 0.8
		holder.add_child(beast)
		parts.append(beast)
		var cart := _sprite("trader_cart", Vector2(40, 0), 1.0, false, holder)
		if cart != null:
			parts.append(cart)
	var walker := _sprite("traveler", Vector2(-4 if not trader else 96, 0), 1.0, false, holder)
	if walker != null:
		parts.append(walker)
	if parts.is_empty():
		holder.queue_free()
		return
	for i in parts.size():
		Stand.bob(parts[i], 1, 0.5 + 0.08 * i, 0.07 * i)
	_add_scroller(holder, ROAD_SPEED, -12.0)


func _spawn_roadside(prop: String, x: float) -> void:
	var s := _sprite(prop, Vector2(x, VERGE_FEET_Y + _rng.randf_range(-2, 2)), 0.75 if prop != "grave_marker" else 0.6, _rng.randf() < 0.5)
	if s != null:
		_add_scroller(s, ROAD_SPEED * 0.92, 0.0)


# ---------- helpers ----------

## A prop sprite standing on `feet`, scaled around its feet. null if the art is missing.
func _sprite(prop: String, feet: Vector2, scale_by: float, flip: bool, parent: Node = null) -> Node2D:
	var path := "res://assets/props/%s.png" % prop
	if not ResourceLoader.exists(path):
		return null
	var holder := Node2D.new()
	holder.position = feet
	holder.scale = Vector2(scale_by, scale_by)
	holder.add_child(Stand.sprite(load(path), Vector2.ZERO, flip))
	(parent if parent != null else self).add_child(holder)
	return holder


func _add_scroller(n: Node2D, speed: float, walk: float) -> void:
	_scrollers.append({"node": n, "speed": speed, "walk": walk})


func _particles(tex: Texture2D, amount: int, velocity: Vector2, spread_px: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex
	p.amount = amount
	p.lifetime = 1.2 if velocity.y > 100 else 7.0
	p.preprocess = p.lifetime
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(380, 4)
	p.position = Vector2(340, -10)
	p.direction = velocity.normalized()
	p.spread = spread_px
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = velocity.length() * 0.85
	p.initial_velocity_max = velocity.length() * 1.15
	p.emitting = false
	weather_layer.add_child(p)
	return p


static func _streak_tex() -> Texture2D:
	var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		img.set_pixel(0, y, Color(1, 1, 1, 0.3 + 0.12 * y))
	return ImageTexture.create_from_image(img)


static func _dot_tex() -> Texture2D:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)

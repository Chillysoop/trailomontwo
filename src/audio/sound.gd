class_name Sound
extends RefCounted
## Music, creature cries and a few sound effects (made with tools/audio/gen_audio.py).
##
##   Sound.music("trail")      switch the music loop (fades across; same track keeps playing)
##   Sound.cry("mossbrock")    a Trailomon's cry: evolved forms use their family's, lower
##   Sound.sfx("catch")        a one-shot sound
##   Sound.toggle_mute()       the speaker button
##
## Players hang off the scene tree's root, so the music carries on across scene changes.
## Missing files are skipped quietly (and nothing plays in headless tests).

const DIR := "res://assets/audio/"
const MUSIC_DB := -9.0
const CRY_DB := -4.0
const SFX_DB := -6.0
const FADE := 0.8
## Evolved forms cry lower.
const STAGE_PITCH := {1: 1.0, 2: 0.86, 3: 0.74}

static var muted := false
static var _music: AudioStreamPlayer
static var _music_name := ""
static var _voices: Array[AudioStreamPlayer] = []
static var _next_voice := 0


static func _root() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree and DisplayServer.get_name() != "headless":
		return (loop as SceneTree).root
	return null


static func _load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


static func music(track: String) -> void:
	var root := _root()
	if root == null or track == _music_name:
		return
	_music_name = track
	var stream := _load(DIR + "music/%s.mp3" % track)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	var old := _music
	_music = AudioStreamPlayer.new()
	_music.stream = stream
	_music.volume_db = -40.0
	_music.bus = "Master"
	root.add_child.call_deferred(_music)
	var p := _music
	p.ready.connect(func():
		p.play()
		var t := p.create_tween()
		t.tween_property(p, "volume_db", -80.0 if muted else MUSIC_DB, FADE))
	if old != null and is_instance_valid(old):
		var t2 := old.create_tween()
		t2.tween_property(old, "volume_db", -40.0, FADE)
		t2.tween_callback(old.queue_free)


static func cry(species: String) -> void:
	if not Species.DATA.has(species):
		return
	var fam := Species.family(species)
	var stream := _load(DIR + "cries/%s.mp3" % fam)
	if stream == null:
		return
	_play(stream, CRY_DB, float(STAGE_PITCH.get(Species.stage(species), 0.7)) * randf_range(0.97, 1.03))


static func sfx(name: String) -> void:
	var stream := _load(DIR + "sfx/%s.mp3" % name)
	if stream != null:
		_play(stream, SFX_DB, 1.0)


static func _play(stream: AudioStream, db: float, pitch: float) -> void:
	var root := _root()
	if root == null or muted:
		return
	if _voices.is_empty() or not is_instance_valid(_voices[0]):
		_voices.clear()
		for i in 4:
			var v := AudioStreamPlayer.new()
			root.add_child.call_deferred(v)
			_voices.append(v)
	var v := _voices[_next_voice % _voices.size()]
	_next_voice += 1
	v.stream = stream
	v.volume_db = db
	v.pitch_scale = pitch
	if v.is_inside_tree():
		v.play()
	else:
		v.ready.connect(v.play, CONNECT_ONE_SHOT)


static func toggle_mute() -> bool:
	muted = not muted
	if _music != null and is_instance_valid(_music):
		_music.volume_db = -80.0 if muted else MUSIC_DB
	return muted

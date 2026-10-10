extends Node
## Звуки (спек 2.7). Правило: один play() на игровое событие (сигнал), никогда из _process.
## Пул из шести плееров: одновременные события не перебивают друг друга.

const STREAMS := {
	&"pickup": "res://assets/sfx/pickup.ogg",
	&"eat": "res://assets/sfx/eat.ogg",
	&"hit": "res://assets/sfx/hit.ogg",
	&"meow": "res://assets/sfx/meow.wav",
	&"bark": "res://assets/sfx/bark.wav",
	&"bell": "res://assets/sfx/bell.ogg",
	&"hiss": "res://assets/sfx/hiss.wav",
	&"sprinkle": "res://assets/sfx/sprinkle.wav",
	&"coo": "res://assets/sfx/coo.wav",
	&"splash": "res://assets/sfx/splash.wav",
	&"gull": "res://assets/sfx/gull.wav",
	&"wave": "res://assets/sfx/wave.wav",
	&"horn": "res://assets/sfx/horn.wav",
	&"rustle": "res://assets/sfx/rustle.wav",
}
const POOL := 6
const VOLUME_DB := {&"bark": -4.0, &"bell": -2.0, &"meow": -3.0, &"hiss": -6.0, &"sprinkle": -6.0, &"coo": -4.0, &"splash": -3.0, &"gull": -5.0, &"wave": -6.0, &"horn": -6.0, &"rustle": -4.0}

var enabled := true
var last_played: StringName = &""
var counts := {}
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in STREAMS:
		if ResourceLoader.exists(STREAMS[key]):
			_streams[key] = load(STREAMS[key])
		else:
			push_warning("нет звука %s: %s" % [key, STREAMS[key]])
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.name = "Player%d" % i
		add_child(p)
		_players.append(p)


func has(name: StringName) -> bool:
	return _streams.has(name)


func reset_counters() -> void:
	counts = {}
	last_played = &""


func play(name: StringName, pitch_jitter := 0.06) -> AudioStreamPlayer:
	if not enabled or not _streams.has(name):
		return null
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.volume_db = VOLUME_DB.get(name, 0.0)
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
	last_played = name
	counts[name] = counts.get(name, 0) + 1
	return p


const HEAR_RANGE := 26.0   # дальше звук опасности не слышен (план 21: дождеватели парка булькали на всю карту)
const FULL_RANGE := 6.0


func play_at(name: StringName, pos: Vector3, pitch_jitter := 0.06) -> AudioStreamPlayer:
	## Звук из точки мира: слышен только рядом с котом, тише с расстоянием.
	var cat := get_tree().get_first_node_in_group("cat") as Node3D if is_inside_tree() else null
	var listener := cat.global_position if cat else pos
	var d := listener.distance_to(pos)
	if d > HEAR_RANGE:
		return null
	var p := play(name, pitch_jitter)
	if p:
		var k := clampf((d - FULL_RANGE) / (HEAR_RANGE - FULL_RANGE), 0.0, 1.0)
		p.volume_db += linear_to_db(lerpf(1.0, 0.05, k))
	return p

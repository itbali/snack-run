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
}
const POOL := 6
const VOLUME_DB := {&"bark": -4.0, &"bell": -2.0, &"meow": -3.0, &"hiss": -6.0, &"sprinkle": -6.0, &"coo": -4.0, &"splash": -3.0, &"gull": -5.0, &"wave": -6.0, &"horn": -6.0}

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

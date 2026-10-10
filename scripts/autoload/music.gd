extends Node
## Музыка (план 21): CC0-петли (assets/music/README.md) — днём по очереди дневные, ночью ночная; смена плавным кроссфейдом.
## Громкость — GameSettings.music (0…1, «Музыка» в настройках). На паузе играет.

const DAY := ["res://assets/music/day_happy_clappy.ogg", "res://assets/music/day_head_in_the_sand.ogg"]
const NIGHT := ["res://assets/music/night_feel_good_island.ogg"]
const FADE := 2.0
const BASE_DB := -10.0

var volume := 0.7
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _track := ""
var _day_i := 0
var _fade := 0.0
var active := false   # Main включает: на заставке тихо


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = AudioStreamPlayer.new()
	_b = AudioStreamPlayer.new()
	add_child(_a)
	add_child(_b)
	_a.finished.connect(_next_day)
	_b.finished.connect(_next_day)


func playing() -> bool:
	return active and (_a.playing or _b.playing)


func current_track() -> String:
	return _track


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	_apply_volume()


func start() -> void:
	active = true
	volume = GameSettings.music
	_track = ""


func stop() -> void:
	active = false
	_a.stop()
	_b.stop()
	_track = ""


func _want() -> String:
	if DayNight.is_night(get_tree()):
		return NIGHT[0]
	return DAY[_day_i % DAY.size()]


func _next_day() -> void:
	if not DayNight.is_night(get_tree()):
		_day_i += 1   # дневные петли по очереди, чтобы не приедалась одна
	_switch(_want())


func _switch(path: String) -> void:
	if path == _track or not ResourceLoader.exists(path):
		return
	_track = path
	var s := load(path) as AudioStream
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = false   # по окончании — следующая дневная петля
	var tmp := _a
	_a = _b
	_b = tmp   # _a — новая, _b — затухает
	_a.stream = s
	_a.volume_db = -60.0
	_a.play()
	_fade = 0.0


func _apply_volume() -> void:
	var k := clampf(_fade / FADE, 0.0, 1.0)
	var top := BASE_DB + linear_to_db(maxf(volume, 0.0001))
	if _a:
		_a.volume_db = lerpf(-60.0, top, k) if volume > 0.0 else -80.0
	if _b:
		_b.volume_db = lerpf(top, -60.0, k) if volume > 0.0 else -80.0
		if k >= 1.0 and _b.playing:
			_b.stop()


func _process(delta: float) -> void:
	if not active:
		return
	var want := _want()
	if want != _track and (DayNight.is_night(get_tree()) or _track in NIGHT or _track == ""):
		_switch(want)   # день ↔ ночь — сразу кроссфейдом; днём смена петли — по её окончании
	_fade += delta
	_apply_volume()

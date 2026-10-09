class_name Forklift
extends Node3D
## Погрузчик на причале (спек порта, раздел 3): стоит у штабеля 4–6 с, 1,5 с гудит, едет 3 м/с с ящиком к следующей точке
## маршрута; ночью стоит. Касание — удар, как у велосипедиста.

const SPEED := 3.0
const HORN := 1.5


static func next_state(state: StringName, t_in_state: float, wait: float, night: bool) -> StringName:
	## drive → wait по прибытии решает узел; здесь — переходы по времени и ночь.
	if night:
		return &"wait"
	match state:
		&"wait":
			return &"horn" if t_in_state >= wait else &"wait"
		&"horn":
			return &"drive" if t_in_state >= HORN else &"horn"
	return state

var state: StringName = &"wait"
var path: Array[Vector3] = []
var wait_range := Vector2(4.0, 6.0)
var _i := 0             # текущая точка маршрута (стоит у неё)
var _dir := 1
var _t := 0.0
var _wait := 5.0
var _rng := RandomNumberGenerator.new()

@onready var _hit: Area3D = $HitZone


func configure(hz: Dictionary, _builder: Node3D) -> void:
	path.clear()
	for p in hz.get("path", []):
		path.append(Vector3(float(p[0]), 0.0, float(p[1])))
	var w: Array = hz.get("wait", [4.0, 6.0])
	wait_range = Vector2(float(w[0]), float(w[1]))


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.body_entered.connect(_on_body)
	Toon.apply($Model, Toon.OUTLINE_NONE)
	_wait = _rng.randf_range(wait_range.x, wait_range.y)


func _ground(p: Vector3) -> Vector3:
	return Vector3(p.x, Terrain.surface_height(get_tree(), p.x, p.z, global_position.y), p.z)


func _physics_process(delta: float) -> void:
	if path.size() < 2:
		return
	_t += delta
	var night := DayNight.is_night(get_tree())
	if state == &"drive" and not night:
		for b in _hit.get_overlapping_bodies():   # кот мог стоять у вил ещё до старта — body_entered не повторится
			_on_body(b)
		var target := _ground(path[_i + _dir])
		var to := target - global_position
		to.y = 0.0
		var step := SPEED * delta
		if to.length() <= step:
			global_position = target
			_i += _dir
			if _i == 0 or _i == path.size() - 1:
				_dir = -_dir   # туда-обратно по маршруту
			state = &"wait"
			_t = 0.0
			_wait = _rng.randf_range(wait_range.x, wait_range.y)
		else:
			var d := to.normalized()
			global_position += d * step
			global_position.y = target.y
			rotation.y = atan2(d.x, d.z)   # вилы (+Z модели) — по ходу
		return
	var next := next_state(state, _t, _wait, night)
	if next != state:
		state = next
		_t = 0.0
		if state == &"horn":
			Sfx.play(&"horn")


func _on_body(body: Node3D) -> void:
	if state == &"drive" and body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)

class_name Pedestrian
extends Node3D
## Прохожий двора (план 20): ходит туда-обратно по маршруту, постоит на концах; безопасен (не опасность, без коллизий);
## днём и вечером, ночью дома.

const SPEED := 1.1

var path: Array[Vector3] = []
var _i := 0
var _dir := 1
var _pause := 0.0
var _model: Node3D
var _anim: AnimationPlayer


func setup(model_path: String, points: Array) -> void:
	for p in points:
		path.append(Vector3(float(p[0]), 0.0, float(p[1])))
	_model = (load(model_path) as PackedScene).instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)


func _ready() -> void:
	add_to_group("pedestrians")
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	_anim = _model.find_child("AnimationPlayer", true, false)
	for clip in ["idle", "walk"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if not path.is_empty():
		global_position = _ground(path[0])


func _ground(p: Vector3) -> Vector3:
	return Vector3(p.x, Terrain.surface_height(get_tree(), p.x, p.z, 0.0), p.z)


func _play(clip: String) -> void:
	if _anim and _anim.has_animation(clip) and _anim.current_animation != clip:
		_anim.play(clip, 0.2)


func _physics_process(delta: float) -> void:
	visible = DayNight.current_phase(get_tree()) != &"night"
	if not visible or path.size() < 2:
		return
	if _pause > 0.0:
		_pause -= delta
		_play("idle")
		return
	var target := _ground(path[_i + _dir])
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.1:
		_i += _dir
		if _i == 0 or _i == path.size() - 1:
			_dir = -_dir
			_pause = randf_range(1.5, 4.0)   # постоять, поглядеть по сторонам
		return
	var d := to.normalized()
	global_position += d * SPEED * delta
	global_position.y = target.y
	rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 1.0 - exp(-6.0 * delta))
	_play("walk")

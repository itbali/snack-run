class_name ParkPerson
extends HazardBase
## Общее для людей парка: модель с клипами, маршрут патруля, присутствие по фазе суток.

@export var patrol: Array = []        # точки маршрута [[x, z], ...] из раскладки; пусто — стоит у дома
var _patrol_i := 0
@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	patrol = hz.get("path", [])


func _ready() -> void:
	super()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["idle", "walk", "run", "work"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play(&"idle")


func present() -> bool:
	## Переопределяется: когда человек в парке (по фазе суток).
	return true


func play(clip: StringName) -> void:
	if _anim and _anim.has_animation(String(clip)) and _anim.current_animation != String(clip):
		_anim.play(String(clip), 0.2)


func walk_patrol(delta: float) -> void:
	if patrol.is_empty():
		move_towards_point(home, walk_speed, delta)
		play(&"walk" if global_position.distance_to(home) > 0.2 else &"idle")
		return
	var p: Array = patrol[_patrol_i]
	var target := Vector3(p[0], global_position.y, p[1])
	if move_towards_point(target, walk_speed, delta) < 0.3:
		_patrol_i = (_patrol_i + 1) % patrol.size()
	play(&"walk")


func sync_presence() -> bool:
	## Скрывает и выключает человека вне его фазы суток; возвращает «в парке ли он».
	var here := present()
	visible = here
	hit_zone.monitoring = here
	return here

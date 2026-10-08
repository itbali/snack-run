class_name Dog
extends HazardBase
## Собака: спит, замечает кота в конусе, 1 с настораживается, гонится 1,2× скорости кота,
## теряет след в укрытии (2 с) или устаёт (8 с), возвращается домой (спек 3.2).

const VISION_HALF_ANGLE := 45.0
const VISION_RANGE := 6.0
const HOME_RADIUS := 0.4

var brain := ChaseBrain.new()

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	super()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)
	for clip in ["idle", "walk", "sleep", "alert"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip(&"sleep")


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden"):
		return false
	var forward := -global_transform.basis.z
	return Perception.in_cone(global_position, forward, c.global_position, VISION_HALF_ANGLE, VISION_RANGE)


func _physics_process(delta: float) -> void:
	_ensure_home()
	var c := _find_cat()
	var cat_hidden: bool = c != null and bool(c.get("hidden"))
	var at_home := global_position.distance_to(home) < HOME_RADIUS
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home)
	match s:
		ChaseBrain.State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play_clip(&"sleep")
		ChaseBrain.State.ALERT:
			if c:
				var to := c.global_position - global_position
				rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 10.0 * delta)
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play_clip(&"alert")
		ChaseBrain.State.CHASE:
			if c:
				move_towards_point(c.global_position, run_speed, delta)
			play_clip(&"run")
		ChaseBrain.State.RETURN:
			move_towards_point(home, walk_speed, delta)
			play_clip(&"walk")


func play_clip(name: StringName) -> void:
	if _anim == null:
		return
	var clip := String(name)
	var speed := 1.0
	match name:
		&"run":
			if not _anim.has_animation("run"):
				clip = "walk"
				speed = 1.8
		&"sleep", &"alert":
			if not _anim.has_animation(clip):
				clip = "idle"
	_anim.speed_scale = speed
	if _anim.current_animation != clip:
		_anim.play(clip, 0.2)

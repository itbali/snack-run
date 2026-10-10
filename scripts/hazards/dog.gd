class_name Dog
extends HazardBase
## Собака: спит, замечает кота в конусе, 1 с настораживается, гонится 1,2× скорости кота,
## теряет след в укрытии (2 с) или устаёт (8 с), возвращается домой (спек 3.2).

const VISION_HALF_ANGLE := 45.0
const VISION_RANGE := 6.0
const HOME_RADIUS := 0.4
const RETURN_TIMEOUT := 8.0   # дольше идёт домой — значит упёрлась (стена террасы): переносится домой (ревью плана 11)

var brain := ChaseBrain.new()
var _last_state: int = ChaseBrain.State.IDLE
var _zzz_t := 0.0
var _return_t := 0.0

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	super()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["idle", "walk", "sleep", "alert"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip(&"sleep")


func reset_pursuit() -> void:
	brain.reset()


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone"):
		return false
	if DayNight.is_night(get_tree()):
		return false   # ночью собака двора спит и не просыпается от кота (этап 2)
	var forward := -global_transform.basis.z
	return Perception.in_cone(global_position, forward, c.global_position, VISION_HALF_ANGLE * GameState.stealth_mult, VISION_RANGE)


func _physics_process(delta: float) -> void:
	_ensure_home()
	var c := _find_cat()
	var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))
	var at_home := global_position.distance_to(home) < HOME_RADIUS
	if DayNight.is_night(get_tree()):
		brain.give_up()   # ночь посреди погони — собака уходит спать (ревью плана 7)
	var cat_safe: bool = c != null and bool(c.get("in_safe_zone"))
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home, cat_safe)
	if s == ChaseBrain.State.ALERT and _last_state != ChaseBrain.State.ALERT:
		Sfx.play_at(&"bark", global_position)   # один лай на настороженность
	_last_state = s
	if s != ChaseBrain.State.RETURN:
		_return_t = 0.0
	if c and c.has_method("threaten") and s in [ChaseBrain.State.ALERT, ChaseBrain.State.CHASE] and global_position.distance_to(c.global_position) < VISION_RANGE:
		c.call("threaten")   # испуг, пока собака насторожилась или гонится и она ближе 6 м
	match s:
		ChaseBrain.State.IDLE:
			rotation.y = lerp_angle(rotation.y, home_yaw, 6.0 * delta)   # снова сторожит в исходную сторону
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play_clip(&"sleep")
			_zzz_t += delta
			if _zzz_t >= 1.2:
				_zzz_t = 0.0
				Effects.zzz(get_parent(), global_position + Vector3(0, 0.45, 0))
		ChaseBrain.State.ALERT:
			_zzz_t = 0.0
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
			_return_t += delta
			if _return_t >= RETURN_TIMEOUT:
				global_position = home   # прямой путь домой перекрыт: на большом дворе это за кадром
				velocity = Vector3.ZERO
				Effects.dust(get_parent(), home)
			else:
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

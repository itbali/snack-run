class_name Dog
extends HazardBase
## Собака: днём бродит у дома, ночью спит; замечает кота в конусе (или чует с едой), 0,6 с лает, гонится рывками
## с передышками, теряет след в укрытии (2 с) или устаёт (6 с), возвращается домой (спек 3.2, план 21).

const VISION_HALF_ANGLE := 50.0
const VISION_RANGE := 7.0
const HOME_RADIUS := 0.4
## План 21 (владелец: «враги амёбные»): днём бродит у дома, чует кота с едой, лает коротко, гонится рывками.
const WANDER := 3.5
const SMELL := 4.5
const LUNGE := 0.8          # рывок, с
const PANT := 0.45          # передышка между рывками — шанс увернуться
const LUNGE_SPEED := 5.6    # быстрее бегущего кота (4,0)
const WANDER_TIMEOUT := 4.0 # цель прогулки недостижима (куст, угол дома) — бросить
const RETURN_TIMEOUT := 8.0   # дольше идёт домой — значит упёрлась (стена террасы): переносится домой (ревью плана 11)

var brain := ChaseBrain.new()
var _last_state: int = ChaseBrain.State.IDLE
var _zzz_t := 0.0
var _wander_to := Vector3.INF
var _wander_wait := 0.0
var _lunge_t := 0.0
var _wander_t := 0.0
var _return_t := 0.0

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	super()
	brain.alert_time = 0.6
	brain.chase_max = 6.0
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
	if not GameState.mouth.is_empty() and global_position.distance_to(c.global_position) < SMELL * GameState.stealth_mult:
		return true   # чует еду в зубах — и за спиной
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
	if s == ChaseBrain.State.CHASE and _last_state != ChaseBrain.State.CHASE:
		_lunge_t = 0.0
	if s == ChaseBrain.State.IDLE and _last_state != ChaseBrain.State.IDLE:
		_wander_to = Vector3.INF   # вернулась — сперва постоит дома, глядя в свою сторону
		_wander_wait = randf_range(1.5, 2.5)
	_last_state = s
	if s != ChaseBrain.State.RETURN:
		_return_t = 0.0
	if c and c.has_method("threaten") and s in [ChaseBrain.State.ALERT, ChaseBrain.State.CHASE] and global_position.distance_to(c.global_position) < VISION_RANGE:
		c.call("threaten")   # испуг, пока собака насторожилась или гонится и она ближе 6 м
	match s:
		ChaseBrain.State.IDLE:
			if DayNight.is_night(get_tree()):
				_sleep(delta)
			else:
				_wander(delta)
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
			_lunge_t += delta
			var cycle := fmod(_lunge_t, LUNGE + PANT)
			if c and cycle < LUNGE:
				move_towards_point(c.global_position, LUNGE_SPEED, delta)
				play_clip(&"run")
			else:
				velocity.x = 0.0   # передышка: язык набок, можно увернуться
				velocity.z = 0.0
				_apply_gravity(delta)
				move_and_slide()
				play_clip(&"alert")
		ChaseBrain.State.RETURN:
			_return_t += delta
			if _return_t >= RETURN_TIMEOUT:
				global_position = home   # прямой путь домой перекрыт: на большом дворе это за кадром
				velocity = Vector3.ZERO
				Effects.dust(get_parent(), home)
			else:
				move_towards_point(home, walk_speed, delta)
			play_clip(&"walk")


func _sleep(delta: float) -> void:
	if global_position.distance_to(home) > HOME_RADIUS:
		move_towards_point(home, walk_speed, delta)
		play_clip(&"walk")
		return
	rotation.y = lerp_angle(rotation.y, home_yaw, 6.0 * delta)
	velocity.x = 0.0
	velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()
	play_clip(&"sleep")
	_zzz_t += delta
	if _zzz_t >= 1.2:
		_zzz_t = 0.0
		Effects.zzz(get_parent(), global_position + Vector3(0, 0.45, 0))


func _wander(delta: float) -> void:
	## День: бродит в WANDER от дома, останавливается понюхать.
	_zzz_t = 0.0
	if _wander_to == Vector3.INF or _wander_wait > 0.0:
		_wander_wait -= delta
		if global_position.distance_to(home) <= HOME_RADIUS + 0.2:
			rotation.y = lerp_angle(rotation.y, home_yaw, 6.0 * delta)
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		play_clip(&"idle")
		if _wander_wait <= 0.0:
			_wander_to = home   # нет свободной точки — идёт домой
			for i in 6:
				var a := randf() * TAU
				var p := home + Vector3(cos(a), 0, sin(a)) * randf_range(1.0, WANDER)
				if wander_target_free(p):
					_wander_to = p
					break
			_wander_t = 0.0
		return
	_wander_t += delta
	if move_towards_point(_wander_to, walk_speed * 0.8, delta) < 0.3 or _wander_t >= WANDER_TIMEOUT:
		_wander_to = Vector3.INF
		_wander_wait = randf_range(1.0, 2.5)
	play_clip(&"walk")


func wander_target_free(p: Vector3) -> bool:
	## Точка прогулки не внутри пропса (куст, урна, угол дома): проба на высоте спины собаки.
	if not is_inside_tree():
		return true
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.35
	q.shape = s
	q.transform = Transform3D(Basis(), Vector3(p.x, global_position.y + 0.45, p.z))
	q.collision_mask = Layers.WORLD
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


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

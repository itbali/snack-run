class_name Kid
extends ParkPerson
## Ребёнок, который хочет погладить (спек этапа 2, раздел 3): днём бегает у площадки; заметил кота (конус 50°, 7 м) —
## бежит к нему 1,1× шага кота, в укрытии теряет через 2 с, устаёт через 6 с; поймал — гладит 2 с (без урона).
## Вечером уходит домой, утром возвращается.

const VISION_HALF_ANGLE := 25.0
const VISION_RANGE := 7.0
const PET_TIME := 2.0

var brain := ChaseBrain.new()
var _wander := Vector3.ZERO
var _wander_t := 0.0


func _ready() -> void:
	super()
	walk_speed = 1.0
	run_speed = CatMotion.WALK_SPEED * 1.1
	brain.alert_time = 0.4
	brain.chase_max = 6.0


func present() -> bool:
	var p := DayNight.current_phase(get_tree())
	return p == &"day" or p == &"morning"


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone") or not present():
		return false
	return Perception.in_cone(global_position, -global_transform.basis.z, c.global_position, VISION_HALF_ANGLE, VISION_RANGE)


func _on_hit_body(body: Node3D) -> void:
	if present() and body.is_in_group("cat") and body.has_method("pet"):
		if body.call("pet", PET_TIME):
			brain.give_up()   # погладил — идёт играть дальше


func _physics_process(delta: float) -> void:
	_ensure_home()
	if not sync_presence():
		brain.reset()
		global_position = home
		return
	var c := _find_cat()
	var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))
	var at_home := global_position.distance_to(home) < 0.6
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home, c != null and bool(c.get("in_safe_zone")))
	match s:
		ChaseBrain.State.CHASE:
			if c:
				move_towards_point(c.global_position, run_speed, delta)
				for body in hit_zone.get_overlapping_bodies():   # кот мог стоять в зоне с начала погони
					_on_hit_body(body)
			play(&"run")
		ChaseBrain.State.ALERT:
			if c:
				var to := c.global_position - global_position
				rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 10.0 * delta)
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play(&"idle")
		ChaseBrain.State.RETURN:
			move_towards_point(home, walk_speed, delta)
			play(&"walk")
		_:
			_wander_t -= delta
			if _wander_t <= 0.0:
				var a := randf_range(0.0, TAU)
				_wander = home + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, 3.0)
				_wander_t = randf_range(2.0, 4.0)
			var left := move_towards_point(_wander, walk_speed, delta)
			play(&"walk" if left > 0.2 else &"idle")

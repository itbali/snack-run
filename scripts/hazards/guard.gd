class_name Guard
extends ParkPerson
## Ночной сторож с фонариком (спек этапа 2, раздел 3): только ночью; патрулирует аллеи; видит кота в луче фонарика
## (конус 30°, 8 м) или когда кот стоит в свете фонаря парка; погоня как у собаки; касание — удар.

const BEAM_HALF_ANGLE := 15.0
const BEAM_RANGE := 8.0
const LAMP_RADIUS := 3.0
const LAMP_SEE_RANGE := 14.0

var brain := ChaseBrain.new()
var _torch: SpotLight3D


func _ready() -> void:
	super()
	walk_speed = 1.3
	run_speed = 4.6
	_torch = SpotLight3D.new()
	_torch.name = "Flashlight"
	_torch.position = Vector3(0.2, 1.1, -0.2)
	_torch.rotation_degrees = Vector3(-12, 0, 0)
	_torch.spot_angle = BEAM_HALF_ANGLE
	_torch.spot_range = BEAM_RANGE
	_torch.light_color = Color("#FFF1C2")
	_torch.light_energy = 6.0
	add_child(_torch)


func present() -> bool:
	return DayNight.is_night(get_tree())


func _cat_under_lamp(c: Node3D) -> bool:
	for n in get_tree().get_nodes_in_group("night_lights"):
		var l := n as Node3D
		if l.visible and Vector2(l.global_position.x - c.global_position.x, l.global_position.z - c.global_position.z).length() < LAMP_RADIUS:
			return true
	return false


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone") or not present():
		return false
	if Perception.in_cone(global_position, -global_transform.basis.z, c.global_position, BEAM_HALF_ANGLE, BEAM_RANGE):
		return true
	return _cat_under_lamp(c) and global_position.distance_to(c.global_position) < LAMP_SEE_RANGE


func _physics_process(delta: float) -> void:
	_ensure_home()
	if not sync_presence():
		brain.reset()
		global_position = home
		return
	var c := _find_cat()
	var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))
	var s := brain.update(delta, sees_cat(), cat_hidden, global_position.distance_to(home) < 0.6, c != null and bool(c.get("in_safe_zone")))
	match s:
		ChaseBrain.State.CHASE:
			if c:
				move_towards_point(c.global_position, run_speed, delta)
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
			walk_patrol(delta)

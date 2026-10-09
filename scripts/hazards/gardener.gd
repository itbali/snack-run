class_name Gardener
extends ParkPerson
## Садовник со шлангом (спек этапа 2, раздел 3): ходит по маршруту; каждые 15–25 с останавливается, 1 с шипит
## (предупреждение), 4 с поливает перед собой конусом 3 м / 40° — струя бьёт кота. Ночью спит в сторожке.

const WARN_TIME := 1.0
const SPRAY_TIME := 4.0
const SPRAY_RANGE := 3.0
const SPRAY_HALF_ANGLE := 20.0
const WATER := Color("#9FD3F0")

var mode: StringName = &"walk"   # walk | warn | spray
var mode_left := 0.0
var _next_water := 0.0
var _spray: CPUParticles3D


func _ready() -> void:
	super()
	walk_speed = 1.2
	_next_water = randf_range(15.0, 25.0)
	_spray = Effects.trail(self, WATER, 50)
	_spray.name = "Hose"
	_spray.local_coords = true
	_spray.direction = Vector3(0, 0.35, -1)
	_spray.spread = 12.0
	_spray.initial_velocity_min = 4.0
	_spray.initial_velocity_max = 5.0
	_spray.gravity = Vector3(0, -9.0, 0)
	_spray.lifetime = 0.7
	_spray.position = Vector3(0.25, 0.9, -0.3)
	_spray.emitting = false
	hit_zone.monitoring = false   # садовник бьёт только струёй


func present() -> bool:
	return not DayNight.is_night(get_tree())


func start_watering() -> void:
	if not present():
		return   # ночью садовник спит: ни полива, ни шипения
	mode = &"warn"
	mode_left = WARN_TIME
	velocity = Vector3.ZERO
	Sfx.play(&"hiss", 0.1)


func _on_hit_body(_body: Node3D) -> void:
	pass   # касание садовника не ранит


func _physics_process(delta: float) -> void:
	_ensure_home()
	if not sync_presence():
		mode = &"walk"
		_spray.emitting = false
		global_position = home
		return
	hit_zone.monitoring = false   # садовник бьёт только струёй (sync_presence включает зону остальным людям)
	match mode:
		&"walk":
			walk_patrol(delta)
			_next_water -= delta
			if _next_water <= 0.0:
				start_watering()
		&"warn":
			mode_left -= delta
			play(&"idle")
			_apply_gravity(delta)
			move_and_slide()
			if mode_left <= 0.0:
				mode = &"spray"
				mode_left = SPRAY_TIME
				_spray.emitting = true
		&"spray":
			mode_left -= delta
			play(&"idle")
			_check_spray()
			if mode_left <= 0.0:
				mode = &"walk"
				_spray.emitting = false
				_next_water = randf_range(15.0, 25.0)


func _check_spray() -> void:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone"):
		return
	var forward := -global_transform.basis.z
	if Perception.in_cone(global_position, forward, c.global_position, SPRAY_HALF_ANGLE, SPRAY_RANGE) and c.has_method("take_hit"):
		c.call("take_hit", global_position)

class_name CatMotion
extends RefCounted
## Чистая логика движения кота. Без узлов, без ввода: всё приходит аргументами.

const WALK_SPEED := 2.0
const RUN_SPEED := 4.0
const JUMP_VELOCITY := 4.5
const GRAVITY := 12.0
const ACCEL := 14.0
const SLOPE_WOBBLE := 0.5   # |vy| ниже этого при потере пола не считается прыжком


static func world_direction(input: Vector2, cam_yaw_basis: Basis) -> Vector3:
	if input.is_zero_approx():
		return Vector3.ZERO
	var local := Vector3(input.x, 0.0, input.y)
	var dir := cam_yaw_basis * local
	dir.y = 0.0
	return dir.normalized()


static func step(velocity: Vector3, direction: Vector3, running: bool, on_floor: bool, jump: bool, delta: float) -> Vector3:
	var speed := RUN_SPEED if running else WALK_SPEED
	var target := direction * speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(Vector3(target.x, 0.0, target.z), ACCEL * delta)
	var vy := velocity.y
	if on_floor:
		vy = JUMP_VELOCITY if jump else 0.0
	else:
		vy -= GRAVITY * delta
	return Vector3(horizontal.x, vy, horizontal.z)


static func pick_state(velocity: Vector3, on_floor: bool, running: bool) -> StringName:
	if not on_floor and absf(velocity.y) >= SLOPE_WOBBLE:
		return &"jump"
	var h := Vector2(velocity.x, velocity.z).length()
	if h < 0.1:
		return &"idle"
	if running and h > WALK_SPEED + 0.1:
		return &"run"
	return &"walk"

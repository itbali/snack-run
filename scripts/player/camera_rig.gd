class_name CameraRig
extends Node3D
## Третье лицо: пружина 1,8 м, взгляд с высоты 0,6 м, наклон −14°, сглаживание 8/с (спек 2.3).
## Мышь и правый стик крутят yaw, наклон фиксирован. У стены кот становится прозрачным, не исчезает.

const HEIGHT := 0.6
const DISTANCE := 1.8
const SMOOTH := 8.0
const HIDE_BELOW := 0.9
const YAW_SPEED := 2.2
const PITCH_DEG := -14.0
const PITCH_MIN := -55.0   # сверху вниз — дальше камера «ныряет» за голову
const PITCH_MAX := 8.0     # чуть снизу вверх — ниже пружина упирается в землю
const PITCH_SPEED := 60.0  # град/с с клавиш и стика
const CROUCH_PITCH_MAX := -4.0
const HIDE_PITCH := -12.0   # в укрытии опора низкая: камера не ложится на траву
const SHOP_OFFSET := Vector3(1.4, 0.6, 1.4)   # витрина: камера спереди-сбоку кота
const CROUCH_HEIGHT := 0.3
const MOUSE_SENS := 0.004   # рад на пиксель
const FADE_FULL := 0.3      # при такой длине пружины кот почти прозрачен (0,15)

@export var target: Node3D
var crouch := false
var hide_focus: Node3D   # кот спрятался — камера смотрит на его глаза в укрытии (ревью плана 19)
var shop_view := false
var shop_view_point := Vector3.ZERO   # если use_shop_point, камера едет сюда, иначе target + SHOP_OFFSET
var use_shop_point := false
var _yaw := 0.0
var pitch := PITCH_DEG   # наклон камеры (план 18): мышь, клавиши cam_up/cam_down, правый стик
var shake_left := 0.0
var _shake_amp := 0.05
var _shake_time := 0.2
@onready var _arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	var cam := _arm.get_node("Camera3D") as Camera3D
	cam.add_to_group("game_camera")
	GameSettings.apply_camera(cam)   # размытие вдали (план 18, настройка)
	_arm.spring_length = DISTANCE
	_arm.rotation_degrees.x = PITCH_DEG


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var axis := Input.get_axis("cam_left", "cam_right")
	_yaw -= axis * YAW_SPEED * delta
	rotation.y = _yaw
	if not shop_view:
		pitch = clamp_pitch(pitch + Input.get_axis("cam_down", "cam_up") * PITCH_SPEED * delta)
	_arm.rotation_degrees.x = arm_pitch()
	if shake_left > 0.0:
		shake_left = maxf(shake_left - delta, 0.0)
		var k := _shake_amp * (shake_left / _shake_time)
		_arm.position = Vector3(randf_range(-k, k), randf_range(-k, k), 0.0)
	else:
		_arm.position = Vector3.ZERO
	if shop_view:
		target.visible = true   # витрина: кот виден, даже если пружина до этого прятала его у стены
		_set_target_fade(1.0)
		var want := shop_view_point if use_shop_point else target.global_position + SHOP_OFFSET
		global_position = global_position.lerp(want, 1.0 - exp(-SMOOTH * delta))
		look_at(target.global_position + Vector3(0, 0.15, 0), Vector3.UP)
		_arm.spring_length = 0.0
		return
	_arm.spring_length = DISTANCE
	rotation = Vector3(0, _yaw, 0)
	var goal := target.global_position + Vector3(0, CROUCH_HEIGHT if crouch else HEIGHT, 0)
	if is_instance_valid(hide_focus) and hide_focus.is_visible_in_tree():
		goal = hide_focus.global_position + Vector3(0, 0.3, 0)   # глаза снаружи укрытия: камера не залезает в машину
	global_position = global_position.lerp(goal, 1.0 - exp(-SMOOTH * delta))
	apply_arm_length(_arm.get_hit_length())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_by_pixels((event as InputEventMouseMotion).relative.x)
		tilt_by_pixels((event as InputEventMouseMotion).relative.y)


func shake(amplitude := 0.05, seconds := 0.2) -> void:
	## Тряска камеры при ударе: смещение пружины шумом, затухает за seconds.
	_shake_amp = amplitude
	_shake_time = seconds
	shake_left = seconds


func turn_by_pixels(dx: float) -> void:
	_yaw -= dx * MOUSE_SENS


func arm_pitch() -> float:
	## Наклон рычага: в витрине — прежний ракурс (наклон игрока сохраняется до выхода), в укрытии — не ниже CROUCH_PITCH_MAX.
	if shop_view:
		return PITCH_DEG
	if is_instance_valid(hide_focus):
		return minf(pitch, HIDE_PITCH)   # на глаза — чуть сверху
	return minf(pitch, CROUCH_PITCH_MAX) if crouch else pitch


static func clamp_pitch(p: float) -> float:
	return clampf(p, PITCH_MIN, PITCH_MAX)


func tilt_by_pixels(dy: float) -> void:
	## Мышь вверх (dy < 0) — взгляд выше.
	if shop_view:
		return
	pitch = clamp_pitch(pitch - rad_to_deg(dy * MOUSE_SENS))
	_arm.rotation_degrees.x = arm_pitch()


func apply_arm_length(length: float) -> void:
	# Камера упёрлась в стену: кот не исчезает, а становится прозрачным (замечание ревью плана 1).
	_set_target_fade(clampf((length - FADE_FULL) / (HIDE_BELOW - FADE_FULL), 0.15, 1.0))


func _set_target_fade(alpha: float) -> void:
	if target.has_method("set_fade"):
		target.call("set_fade", alpha)
	else:
		target.visible = alpha > 0.5


func yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)

class_name CameraRig
extends Node3D
## Третье лицо: пружина 3,5 м, взгляд с высоты 0,6 м, сглаживание 8/с (спек 2.3).

const HEIGHT := 0.6
const DISTANCE := 1.8
const SMOOTH := 8.0
const HIDE_BELOW := 0.9
const YAW_SPEED := 2.2
const PITCH_DEG := -14.0

@export var target: Node3D
var _yaw := 0.0
@onready var _arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	_arm.spring_length = DISTANCE
	_arm.rotation_degrees.x = PITCH_DEG


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var axis := Input.get_axis("cam_left", "cam_right")
	_yaw -= axis * YAW_SPEED * delta
	rotation.y = _yaw
	var goal := target.global_position + Vector3(0, HEIGHT, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-SMOOTH * delta))
	apply_arm_length(_arm.get_hit_length())


func apply_arm_length(length: float) -> void:
	# Review Focus 3: камера упёрлась в стену и оказалась внутри кота — прячем модель.
	target.visible = length >= HIDE_BELOW


func yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)

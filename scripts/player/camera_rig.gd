class_name CameraRig
extends Node3D
## Третье лицо: пружина 1,8 м, взгляд с высоты 0,6 м, наклон −14°, сглаживание 8/с (спек 2.3).

const HEIGHT := 0.6
const DISTANCE := 1.8
const SMOOTH := 8.0
const HIDE_BELOW := 0.9
const YAW_SPEED := 2.2
const PITCH_DEG := -14.0
const SHOP_OFFSET := Vector3(1.4, 0.6, 1.4)   # витрина: камера спереди-сбоку кота
const CROUCH_HEIGHT := 0.3

@export var target: Node3D
var crouch := false
var shop_view := false
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
	if shop_view:
		var want := target.global_position + SHOP_OFFSET
		global_position = global_position.lerp(want, 1.0 - exp(-SMOOTH * delta))
		look_at(target.global_position + Vector3(0, 0.15, 0), Vector3.UP)
		_arm.spring_length = 0.0
		return
	_arm.spring_length = DISTANCE
	rotation = Vector3(0, _yaw, 0)
	var goal := target.global_position + Vector3(0, CROUCH_HEIGHT if crouch else HEIGHT, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-SMOOTH * delta))
	apply_arm_length(_arm.get_hit_length())


func apply_arm_length(length: float) -> void:
	# Review Focus 3: камера упёрлась в стену и оказалась внутри кота — прячем модель.
	target.visible = length >= HIDE_BELOW


func yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)

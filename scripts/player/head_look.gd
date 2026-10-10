class_name HeadLook
extends SkeletonModifier3D
## Голова кота смотрит туда же, куда камера (план 18): наклон (pitch) и поворот (yaw) кости головы поверх клипа,
## плавно и в пределах шеи. Цели задаёт Cat по наклону камеры и её направлению.

const MAX_PITCH := 0.45   # рад ≈ 26°
const MAX_YAW := 0.6      # рад ≈ 34°

@export var bone_name: StringName = &"head"
var target_pitch := 0.0
var target_yaw := 0.0
var pitch := 0.0
var yaw := 0.0
var smooth := 6.0   # 0 — мгновенно (тесты)


func _process(delta: float) -> void:
	target_pitch = clampf(target_pitch, -MAX_PITCH, MAX_PITCH)
	target_yaw = clampf(target_yaw, -MAX_YAW, MAX_YAW)
	if smooth <= 0.0:
		pitch = target_pitch
		yaw = target_yaw
	else:
		var k := 1.0 - exp(-smooth * delta)
		pitch = lerpf(pitch, target_pitch, k)
		yaw = lerpf(yaw, target_yaw, k)


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var i := skel.find_bone(bone_name)
	if i < 0:
		return
	# Ось Y скелета кота идёт вдоль тела, верх — +Z скелета (грабли плана 5): наклон — вокруг локальной X кости,
	# поворот — вокруг верха скелета, переведённого в пространство кости.
	var rest := skel.get_bone_pose_rotation(i)
	var parent := skel.get_bone_parent(i)
	var parent_basis := skel.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var up_local := (parent_basis * Basis(rest)).inverse() * Vector3(0, 0, 1)
	var q := rest * Quaternion(Vector3.RIGHT, pitch) * Quaternion(up_local.normalized(), -yaw)
	skel.set_bone_pose_rotation(i, q)

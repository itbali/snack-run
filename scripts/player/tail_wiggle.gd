class_name TailWiggle
extends SkeletonModifier3D
## Хвост покачивается поверх клипа: синус по костям со сдвигом фазы (спек 2.8).

@export var bones: Array[StringName] = [&"Bone.004", &"Bone.005", &"Bone.006", &"Bone.007"]
@export var amplitude := 0.12   # рад (≈7°)
@export var frequency := 2.5    # Гц
@export var phase_step := 0.7
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	for k in bones.size():
		var i := skel.find_bone(bones[k])
		if i < 0:
			continue
		var a := amplitude * sin(TAU * frequency * _t + k * phase_step)
		skel.set_bone_pose_rotation(i, skel.get_bone_pose_rotation(i) * Quaternion(Vector3(0, 0, 1), a))

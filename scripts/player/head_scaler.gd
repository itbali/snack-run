class_name HeadScaler
extends SkeletonModifier3D
## Увеличивает голову поверх любой анимации (чиби-пропорции, спек 2.1).

@export var bone_name: StringName = &"head"
@export var scale_factor := 1.4


# Если в 4.7 этот колбэк не вызывается (голова не масштабируется в тесте),
# переименуйте в `_process_modification_with_delta(_delta: float)`.
func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var idx := skel.find_bone(bone_name)
	if idx < 0:
		return
	skel.set_bone_pose_scale(idx, Vector3.ONE * scale_factor)

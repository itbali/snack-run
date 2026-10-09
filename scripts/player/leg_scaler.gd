class_name LegScaler
extends SkeletonModifier3D
## «Чиби»-лапы поверх любого клипа (спек 2.8): верхние кости лап равномерно в 0,8, корень
## опускается на 20 % высоты ноги, посчитанной из rest-позы, чтобы стопы остались на земле.

@export var upper_bones: Array[StringName] = [&"Bone.014", &"Bone.017", &"Bone.008", &"Bone.011"]
@export var foot_bones: Array[StringName] = [&"Bone.016", &"Bone.019", &"Bone.010", &"Bone.013"]
@export var root_bone: StringName = &"Bone"
@export var leg_scale := 0.8
var drop := 0.0   # единицы скелета


func _ready() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var hip_y := 0.0   # среднее начало верхних костей лап: таз (Bone) выше суставов, его брать нельзя
	var n := 0
	for b in upper_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			hip_y += skel.get_bone_global_rest(i).origin.y
			n += 1
	var foot_y := INF
	for b in foot_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			foot_y = minf(foot_y, skel.get_bone_global_rest(i).origin.y)
	if foot_y < INF and n > 0:
		drop = (hip_y / n - foot_y) * (1.0 - leg_scale)


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	for b in upper_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			skel.set_bone_pose_scale(i, Vector3.ONE * leg_scale)
	var root := skel.find_bone(root_bone)
	if root >= 0:
		skel.set_bone_pose_position(root, skel.get_bone_pose_position(root) - Vector3(0.0, drop, 0.0))

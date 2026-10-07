extends Node3D
## Собирает мир, кота и камеру.

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")


func _ready() -> void:
	Toon.apply($DistrictYard, Toon.OUTLINE_NONE)
	var rig := RigScene.instantiate() as CameraRig
	rig.name = "CameraRig"
	var cat := CatScene.instantiate() as Cat
	cat.name = "Cat"
	cat.camera_rig = rig
	rig.target = cat
	add_child(rig)
	add_child(cat)
	cat.global_position = $DistrictYard/Spawn.global_position
	rig.global_position = cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	(rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()

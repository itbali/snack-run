extends Node3D
## Демо рельефа (план 10): холм, низина, терраса со стенами, лестница и пандус; кот с камерой.
## Запуск кадра: godot --path . res://scenes/dev/terrain_demo.tscn ++ --screenshot=build/x.png

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")


func _ready() -> void:
	Toon.apply($Builder, Toon.OUTLINE_NONE)
	SurfaceTextures.apply($Builder)
	var rig := RigScene.instantiate()
	var cat := CatScene.instantiate()
	cat.camera_rig = rig
	rig.target = cat
	add_child(rig)
	add_child(cat)
	cat.global_position = Vector3(3, 0.1, -3)
	rig.global_position = cat.global_position + Vector3(0, 0.6, 0)
	rig.set("_yaw", deg_to_rad(55))   # на террасу с лестницей и пандусом
	(rig.get_node("SpringArm3D") as SpringArm3D).spring_length = 1.8
	(rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()

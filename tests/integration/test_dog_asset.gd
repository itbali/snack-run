extends GutTest

const DOG_PATH := "res://assets/models/dog.glb"

func test_dog_glb_has_clips_head_and_two_materials() -> void:
	var scene := load(DOG_PATH) as PackedScene
	assert_not_null(scene, "dog.glb должен импортироваться")
	if scene == null:
		return
	var inst := scene.instantiate() as Node3D
	add_child_autofree(inst)
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("idle"))
	assert_true(ap.has_animation("walk"))
	var skel := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	assert_gt(skel.find_bone("head"), -1)
	var names := []
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			names.append((mi as MeshInstance3D).get_active_material(i).resource_name)
	assert_has(names, "sr_cat_orange")
	assert_has(names, "sr_cream")
	var aabb := AABB(skel.global_transform * skel.get_bone_global_rest(0).origin, Vector3.ZERO)
	for i in skel.get_bone_count():
		aabb = aabb.expand(skel.global_transform * skel.get_bone_global_rest(i).origin)
	assert_between(maxf(aabb.size.x, aabb.size.z), 0.35, 0.7, "длина собаки по скелету около 0,5 м")

func test_dog_has_sleep_clip_of_two_seconds() -> void:
	var dog := (load("res://assets/models/dog.glb") as PackedScene).instantiate()
	add_child_autofree(dog)
	var ap := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("sleep"))
	assert_between(ap.get_animation("sleep").length, 1.8, 2.2)

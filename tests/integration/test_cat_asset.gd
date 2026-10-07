extends GutTest

const CAT_PATH := "res://assets/models/cat.glb"

func _instance() -> Node3D:
	var scene := load(CAT_PATH) as PackedScene
	assert_not_null(scene, "cat.glb должен импортироваться как PackedScene")
	var inst := scene.instantiate() as Node3D
	add_child_autofree(inst)
	return inst

func test_cat_has_idle_and_walk() -> void:
	var inst := _instance()
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_not_null(ap)
	assert_true(ap.has_animation("idle"), "нет клипа idle")
	assert_true(ap.has_animation("walk"), "нет клипа walk")

func test_cat_has_head_bone_and_is_kitten_sized() -> void:
	var inst := _instance()
	var skel := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	assert_not_null(skel)
	assert_gt(skel.find_bone("head"), -1, "нет кости head")
	# Скиновый меш в Godot рендерится в пространстве скелета, поэтому размер меряем по костям.
	var aabb := _bones_aabb(skel)
	assert_between(maxf(aabb.size.x, aabb.size.z), 0.2, 0.45, "длина кота по скелету должна быть около 0,3 м")
	assert_lt(aabb.size.y, 0.4, "высота кота не больше 0,4 м")

func test_cat_materials_are_palette() -> void:
	var inst := _instance()
	var names := []
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			names.append((mi as MeshInstance3D).get_active_material(i).resource_name)
	assert_has(names, "sr_cat_orange")
	assert_has(names, "sr_cream")

func _bones_aabb(skel: Skeleton3D) -> AABB:
	var result := AABB(skel.global_transform * skel.get_bone_global_rest(0).origin, Vector3.ZERO)
	for i in skel.get_bone_count():
		result = result.expand(skel.global_transform * skel.get_bone_global_rest(i).origin)
	return result

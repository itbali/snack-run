extends GutTest

const CAT_SCENE := "res://scenes/player/cat.tscn"
const RIG_SCENE := "res://scenes/player/camera_rig.tscn"

func _spawn() -> Node:
	var scene := load(CAT_SCENE) as PackedScene
	assert_not_null(scene, "нет сцены cat.tscn")
	var cat := scene.instantiate()
	add_child_autofree(cat)
	return cat

func test_cat_starts_idle_with_toon_materials() -> void:
	var cat = _spawn()
	assert_eq(cat.state, &"idle")
	var mesh := cat.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_not_null(mesh.material_overlay, "обводка должна быть установлена")
	assert_eq((mesh.get_surface_override_material(0) as StandardMaterial3D).diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)

func test_play_clip_uses_generated_run_and_falls_back_for_unknown() -> void:
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	cat.play_clip(&"run")
	assert_eq(ap.current_animation, "run")
	assert_almost_eq(ap.speed_scale, 1.0, 0.001)
	cat.play_clip(&"somersault")
	assert_eq(ap.current_animation, "idle", "неизвестный клип уходит в idle")
	cat.play_clip(&"idle")
	assert_eq(ap.current_animation, "idle")

var _captured_head_scale := Vector3.ZERO

func test_head_is_scaled() -> void:
	var cat = _spawn()
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	var idx := skel.find_bone("head")
	# Skeleton3D восстанавливает базовую позу после модификаторов, поэтому итог
	# читается только в skeleton_updated (сразу после применения модификаторов).
	skel.skeleton_updated.connect(func() -> void:
		_captured_head_scale = skel.get_bone_global_pose(idx).basis.get_scale())
	await wait_process_frames(3)
	assert_almost_eq(_captured_head_scale.x, 1.4, 0.01)

func test_camera_rig_hides_target_when_too_close() -> void:
	var cat = _spawn()
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	rig.target = cat
	add_child_autofree(rig)
	rig.apply_arm_length(0.5)   # имитация упора в стену
	assert_false(cat.visible)
	rig.apply_arm_length(3.5)
	assert_true(cat.visible)

func test_locomotion_clips_loop() -> void:
	# Ревью: idle/walk/run без зацикливания останавливаются через 1,7 с.
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["idle", "walk", "run", "hide"]:
		assert_eq(ap.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, "клип %s должен зацикливаться" % clip)

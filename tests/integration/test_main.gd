extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

func before_each() -> void:
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()

func _spawn_main() -> Node:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	return main

func test_main_spawns_cat_linked_to_camera() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	var cat = main.find_child("Cat", true, false)
	var rig = main.find_child("CameraRig", true, false)
	assert_not_null(cat, "в главной сцене нет Cat")
	assert_not_null(rig, "в главной сцене нет CameraRig")
	if cat == null or rig == null:
		return
	assert_eq(cat.camera_rig, rig)
	assert_eq(rig.target, cat)
	assert_true((rig.get_node("SpringArm3D/Camera3D") as Camera3D).current)

func test_cat_lands_on_ground() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	assert_not_null(cat, "в главной сцене нет Cat")
	if cat == null:
		return
	await wait_physics_frames(90)
	assert_true(cat.is_on_floor(), "кот должен стоять на земле через 1,5 с")
	# Ревью: нижняя точка коллизии должна совпадать с лапами, кот не тонет в землю.
	assert_between(cat.global_position.y, -0.005, 0.02)

func test_cat_walks_and_jumps_on_input() -> void:
	# Замена ручного прогона: нажимаем действия программно.
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(60)
	var start: Vector3 = cat.global_position
	Input.action_press("move_forward")
	await wait_physics_frames(60)
	assert_eq(cat.state, &"walk", "при зажатом вперёд кот идёт")
	assert_lt(cat.global_position.z, start.z - 0.5, "кот должен сдвинуться вперёд (по -Z)")
	Input.action_press("run")
	await wait_physics_frames(60)
	assert_eq(cat.state, &"run", "с Shift кот бежит")
	Input.action_release("run")
	Input.action_release("move_forward")
	await wait_physics_frames(30)
	Input.action_press("jump")
	await wait_physics_frames(3)
	Input.action_release("jump")
	assert_eq(cat.state, &"jump", "после прыжка состояние jump")
	assert_false(cat.is_on_floor())
	await wait_physics_frames(90)
	assert_true(cat.is_on_floor(), "кот приземлился")

func test_cat_keeps_animating_longer_than_one_clip() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	await wait_physics_frames(60)
	Input.action_press("move_forward")
	await wait_physics_frames(150)   # 2,5 с > длины клипа walk (1,67 с)
	Input.action_release("move_forward")
	assert_true(ap.is_playing(), "анимация должна идти дольше одного клипа")
	assert_eq(ap.current_animation, "walk")

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

func test_eating_spawns_burst_in_rarity_color() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))   # редкая, синяя
	GameState.eat_all()
	var fx := get_tree().get_nodes_in_group("fx")
	assert_eq(fx.size(), 1, "один всплеск на съедание")
	if fx.size() == 1:
		assert_eq((fx[0] as CPUParticles3D).color, Rarity.COLORS[Rarity.Tier.RARE])

func test_hit_spawns_star_burst() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(30)
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	var fx := get_tree().get_nodes_in_group("fx")
	assert_eq(fx.size(), 1)
	if fx.size() == 1:
		assert_eq((fx[0] as CPUParticles3D).color, Effects.HIT_COLOR)

func test_eating_plays_eat_sound() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	Sfx.reset_counters()
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.eat_all()
	assert_eq(Sfx.last_played, &"eat")

func test_vignette_overlay_exists_and_ignores_mouse() -> void:
	var main := _spawn_main()
	var rect := main.get_node_or_null("Vignette/Rect") as ColorRect
	assert_not_null(rect)
	if rect == null:
		return
	assert_true(rect.material is ShaderMaterial)
	assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_lt((main.get_node("Vignette") as CanvasLayer).layer, (main.get_node("Hud") as CanvasLayer).layer + 1, "виньетка под HUD")

func test_fall_below_kill_plane_returns_cat_to_shop_without_penalty() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(5)
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(0, -6, 0)
	await wait_physics_frames(3)
	assert_lt(cat.global_position.distance_to(main.respawn_position()), 0.5, "кот вернулся к будке")
	assert_eq(GameState.hearts, 3, "падение не отнимает сердечко")
	assert_true(GameState.mouth.is_empty(), "еда из зубов потеряна")

func test_kill_plane_ignores_balcony_and_tables() -> void:
	# Review Focus 5
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(5)
	for p in [Vector3(-11.3, 1.2, -9.0), Vector3(0, 0.95, 17)]:
		cat.global_position = p
		await wait_physics_frames(3)
		assert_gt(cat.global_position.y, 0.3, "кот на возвышении остаётся на месте: %s" % p)
		assert_gt(cat.global_position.distance_to(main.respawn_position()), 2.0)

func test_faint_loses_carried_food_instead_of_spilling() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(5)
	GameState.take_hit()
	GameState.take_hit()   # осталось одно сердечко
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.invulnerable_left = 0.0
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	assert_eq(GameState.hearts, 0)
	assert_eq(get_tree().get_nodes_in_group("spilled_food").size(), 0, "при обмороке еда потеряна, не рассыпана (спек 3.2)")

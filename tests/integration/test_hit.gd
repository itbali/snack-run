extends GutTest

const MainScene := preload("res://scenes/main.tscn")

var main
var cat

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(30)
	cat = main.find_child("Cat", true, false)

func after_each() -> void:
	SaveGame.clear()

func test_main_autosaves_on_progress() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	GameState.eat_all()
	await wait_process_frames(1)
	assert_true(FileAccess.file_exists(SaveGame.path), "после съедания прогресс сохранён")

func test_hit_spills_food_knocks_back_and_stuns() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	var start: Vector3 = cat.global_position
	cat.take_hit(start + Vector3(0, 0, 1))
	assert_eq(cat.state, &"hit")
	assert_gt(cat.stunned_left, 0.9)
	assert_eq(GameState.hearts, 2)
	await wait_physics_frames(2)
	var spilled := get_tree().get_nodes_in_group("spilled_food")
	assert_eq(spilled.size(), 2, "две рассыпанные еды")
	await wait_seconds(1.2)
	assert_lt(cat.global_position.z, start.z - 0.8, "отброшен примерно на 1,5 м от источника")
	assert_eq(cat.stunned_left, 0.0)

func test_spilled_food_not_repicked_during_stun() -> void:
	# Review Focus 3
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 0, "еда не подобрана тем же кадром")

func test_second_hit_during_invulnerability_is_ignored() -> void:
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	assert_eq(GameState.hearts, 2)

func test_faint_respawns_at_spawn_unhidden_with_full_hearts() -> void:
	# Review Focus 4: обморок по любой причине (здесь напрямую через GameState) выводит из укрытия.
	main.fade_time = 0.05
	GameState.hearts = 1
	cat.hidden = true
	cat.camera_rig.crouch = true
	cat.global_position = Vector3(5, 0.05, 5)
	GameState.take_hit()
	await wait_for_signal(main.faint_sequence_done, 2.0)
	assert_eq(GameState.hearts, 3)
	assert_false(cat.hidden)
	assert_false(cat.camera_rig.crouch)
	var spawn: Vector3 = main.respawn_position()
	assert_lt(cat.global_position.distance_to(spawn), 0.5)
	assert_true(cat.in_safe_zone or main.find_child("YarnShop", true, false) == null, "возрождение в будке")
	assert_gt(cat.invulnerable_left, 1.5, "после возрождения кот неуязвим ~2 с")
	for h in get_tree().get_nodes_in_group("hazards"):
		if h.has_method("reset_pursuit"):
			assert_eq(h.brain.state, ChaseBrain.State.IDLE, "опасности сброшены после возрождения")

func test_spilled_food_lands_on_surface_below() -> void:
	# Ревью плана 4: еда на pos.y висела в воздухе вокруг стола кафе и балкона (радиус разлёта 1–2 м больше столешницы).
	var spawner: SpillSpawner = main.find_child("SpillSpawner", true, false)
	cat.global_position = Vector3(0, 0.95, 17)   # стол кафе, верх 0,75
	await wait_physics_frames(10)
	assert_almost_eq(cat.global_position.y, 0.75, 0.05, "кот стоит на столе")
	var foods := []
	for i in 6:
		foods.append(FoodCatalog.get_by_id(&"cookie"))
	var out: Array = spawner.spill_around(cat.global_position, foods)
	var on_ground := 0
	for p in out:
		var y: float = (p as Node3D).global_position.y
		assert_true(y < 0.1 or absf(y - 0.75) < 0.05, "еда лежит на земле или на столе, не в воздухе: y=%.2f" % y)
		if y < 0.1:
			on_ground += 1
	assert_gt(on_ground, 0, "в 1–2 м от стола еда падает на землю")

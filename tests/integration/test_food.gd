extends GutTest

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const SpawnScene := preload("res://scenes/food/food_spawn_point.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)

func _cat_at(pos: Vector3) -> Node:
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = pos
	return cat

func _pickup(id: StringName, pos: Vector3) -> Node:
	var p = PickupScene.instantiate()
	p.setup(FoodCatalog.get_by_id(id))
	world.add_child(p)
	p.global_position = pos
	return p

func test_cat_picks_up_food_on_contact() -> void:
	var p = _pickup(&"sausage", Vector3(0, 0.05, 0))
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 1)
	assert_true(not is_instance_valid(p) or p.is_queued_for_deletion(), "еда исчезла")

func test_full_mouth_leaves_food_in_place() -> void:
	# Review Focus 1
	for i in 3:
		GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	var p = _pickup(&"sausage", Vector3(0, 0.05, 0))
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 3)
	assert_true(is_instance_valid(p) and not p.is_queued_for_deletion(), "еда лежит дальше")

func test_spilled_food_has_grace_then_expires() -> void:
	var p = PickupScene.instantiate()
	p.setup(FoodCatalog.get_by_id(&"fish"), true, 0.6)
	world.add_child(p)
	p.global_position = Vector3(0, 0.05, 0)
	_cat_at(Vector3(5, 0.05, 5))
	await wait_physics_frames(3)
	assert_eq(GameState.mouth.size(), 0, "в первые 0,5 с не подбирается")
	await wait_seconds(0.7)
	assert_true(not is_instance_valid(p) or p.is_queued_for_deletion(), "истёк срок жизни")

func test_spilled_food_under_standing_cat_is_picked_after_grace() -> void:
	# Ревью: после паузы подбор должен возобновиться даже если кот не двигался.
	var p = PickupScene.instantiate()
	p.setup(FoodCatalog.get_by_id(&"fish"), true, 3.0)
	world.add_child(p)
	p.global_position = Vector3(0, 0.05, 0)
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(3)
	assert_eq(GameState.mouth.size(), 0, "в первые 0,5 с не подбирается")
	await wait_seconds(0.7)
	assert_eq(GameState.mouth.size(), 1, "через 0,5 с еда под котом подобрана")

func test_pickup_visual_has_ring_in_rarity_color() -> void:
	var p = _pickup(&"donut", Vector3(5, 0, 5))
	await wait_process_frames(1)
	var ring := p.get_node("Ring") as MeshInstance3D
	var mat := ring.get_active_material(0) as StandardMaterial3D
	assert_eq(mat.albedo_color, Rarity.COLORS[Rarity.Tier.LEGENDARY])
	assert_gt(p.get_node("Visual").get_child_count(), 0, "модель загружена")

func test_spawn_point_picks_allowed_and_respawns() -> void:
	var sp = SpawnScene.instantiate()
	sp.allowed = [Rarity.Tier.LEGENDARY]
	sp.respawn_min = 0.1
	sp.respawn_max = 0.1
	world.add_child(sp)
	sp.global_position = Vector3(3, 0, 3)
	await wait_process_frames(1)
	assert_not_null(sp.current)
	assert_eq(sp.current.food.tier, Rarity.Tier.LEGENDARY)
	var first = sp.current
	first.picked.emit(first.food, first)
	first.queue_free()
	await wait_seconds(0.3)
	assert_true(is_instance_valid(sp.current) and sp.current != first, "появилась новая еда")

extends GutTest

const DogScene := preload("res://scenes/hazards/dog.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var cat
var dog

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	cat = CatScene.instantiate()
	world.add_child(cat)
	dog = DogScene.instantiate()
	world.add_child(dog)
	dog.global_position = Vector3(0, 0.05, 0)   # смотрит по -Z

func test_dog_sees_cat_in_front_and_chases() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_physics_frames(3)
	assert_true(dog.sees_cat())
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	var d0: float = dog.global_position.distance_to(cat.global_position)
	await wait_seconds(0.5)
	assert_lt(dog.global_position.distance_to(cat.global_position), d0 - 1.0, "собака сближается")

func test_dog_ignores_cat_behind_or_hidden() -> void:
	cat.global_position = Vector3(0, 0.05, 4)
	await wait_physics_frames(3)
	assert_false(dog.sees_cat(), "за спиной")
	cat.global_position = Vector3(0, 0.05, -4)
	cat.hidden = true
	await wait_physics_frames(3)
	assert_false(dog.sees_cat(), "спрятан")

func test_dog_contact_hits_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -0.2)
	await wait_physics_frames(5)
	assert_eq(GameState.hearts, 2, "касание собаки = удар")

func test_dog_returns_home_after_losing_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	cat.hidden = true
	cat.global_position = Vector3(0, 0.05, -12)
	await wait_seconds(2.3)
	assert_eq(dog.brain.state, ChaseBrain.State.RETURN)
	dog.walk_speed = 8.0   # чтобы не ждать 7 с возврата в тесте
	await wait_seconds(2.5)
	assert_lt(dog.global_position.distance_to(dog.home), 0.6)

func test_dog_faces_home_direction_again_after_chase() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	cat.hidden = true
	cat.global_position = Vector3(0, 0.05, -12)
	dog.walk_speed = 8.0
	await wait_seconds(4.5)
	assert_eq(dog.brain.state, ChaseBrain.State.IDLE, "вернулась и спит")
	cat.hidden = false
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(0.8)
	assert_true(dog.sees_cat(), "после возврата снова смотрит туда же и видит кота")

func test_quiet_upgrade_narrows_dog_cone() -> void:
	cat.global_position = Vector3(3.0, 0.05, -3.4)   # ≈41° от носа собаки: внутри 45°, вне 31,5°
	await wait_physics_frames(3)
	assert_true(dog.sees_cat(), "без улучшения видит на 41°")
	GameState.add_yarn(10)
	GameState.buy(ShopCatalog.get_by_id(&"quiet"))
	dog.rotation.y = 0.0   # за эти кадры собака уже начала поворачиваться к коту
	assert_false(dog.sees_cat(), "с тихими шагами конус 31,5° — не видит")

func test_safe_zone_cancels_chase() -> void:
	# Review Focus 5
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	cat.in_safe_zone = true
	await wait_seconds(2.3)
	assert_eq(dog.brain.state, ChaseBrain.State.RETURN, "в безопасной зоне собака теряет кота через 2 с")

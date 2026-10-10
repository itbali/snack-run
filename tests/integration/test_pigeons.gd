extends GutTest

const FlockScene := preload("res://scenes/hazards/pigeon_flock.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var cat
var flock

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
	cat = CatScene.instantiate()
	cat.position = Vector3(6, 0.05, 0)
	world.add_child(cat)
	flock = FlockScene.instantiate()
	world.add_child(flock)

func test_flock_has_five_pigeons() -> void:
	await wait_physics_frames(2)
	assert_eq(flock.pigeons().size(), 5)

func test_pigeon_steals_last_food_once_then_rests() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 1, "голубь утащил последнюю еду")
	assert_eq(GameState.hearts, 3)
	await wait_physics_frames(10)
	assert_eq(GameState.mouth.size(), 1, "перерыв 10 с: вторую не крадут")

func test_running_cat_scatters_and_keeps_food() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(2.0, 0.05, 0)
	await wait_physics_frames(2)
	Input.action_press("move_forward")
	Input.action_press("run")
	await wait_physics_frames(25)
	Input.action_release("run")
	Input.action_release("move_forward")
	assert_eq(flock.mode, &"scattered", "бегущий кот разогнал стаю")
	assert_eq(GameState.mouth.size(), 1, "еда цела")

func test_pigeons_sleep_at_night() -> void:
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	add_child_autofree(light)
	light.get_node("DayNight").set_time(220.0)
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	await wait_physics_frames(5)
	assert_false(flock.visible, "ночью стаи нет (спят на ветках)")
	assert_eq(GameState.mouth.size(), 1)

func test_hidden_cat_keeps_food_next_to_flock() -> void:
	# Review Focus 1, интеграционно
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	cat.hidden = true
	await wait_physics_frames(6)
	assert_eq(GameState.mouth.size(), 1, "у спрятавшегося не крадут")

func test_flock_steals_again_after_cooldown() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	await wait_physics_frames(4)
	assert_eq(GameState.mouth.size(), 1)
	flock.cooldown_left = 0.0   # перерыв 10 с истёк
	await wait_physics_frames(4)
	assert_eq(GameState.mouth.size(), 0, "после перерыва стая снова крадёт")

func test_flock_creeps_toward_cat_with_food() -> void:
	# План 21: голуби сами подбираются к коту с едой.
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = flock.global_position + Vector3(4, 0.05, 0)
	var d0 := Vector2(cat.global_position.x - flock.global_position.x, cat.global_position.z - flock.global_position.z).length()
	await wait_seconds(1.5)
	var d1 := Vector2(cat.global_position.x - flock.global_position.x, cat.global_position.z - flock.global_position.z).length()
	assert_lt(d1, d0 - 0.5, "стая ближе")

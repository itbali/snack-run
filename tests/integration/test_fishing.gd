extends GutTest
## План 15: рыбалка (спек порта, раздел 4).

const FisherScene := preload("res://scenes/hazards/fisher.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 0.2, 30)
	shape.shape = box
	shape.position.y = -0.1
	body.add_child(shape)
	world.add_child(body)

func _fisher(watch := [0.2, 0.2]) -> Node3D:
	var f := FisherScene.instantiate() as Node3D
	f.call("configure", {"watch": watch, "water": -1.0}, null)
	world.add_child(f)
	return f

func _fish(f: Node3D) -> FoodPickup:
	return f.get("fish") as FoodPickup if is_instance_valid(f.get("fish")) else null

func test_golden_fish_lands_in_bucket_once() -> void:
	var f := _fisher()
	await wait_seconds(3.6)
	var fish := _fish(f)
	assert_not_null(fish, "рыбка в ведре")
	if fish:
		assert_eq(fish.food.id, &"golden_fish")
		var bucket := (f.get_node("Bucket") as Node3D).global_position
		assert_lt(Vector2(fish.global_position.x - bucket.x, fish.global_position.z - bucket.z).length(), 0.3)
	await wait_seconds(3.6)
	assert_eq(world.find_children("*", "FoodPickup", true, false).size(), 1, "в ведре не больше одной рыбки")

func test_cat_steals_fish_while_fisher_watches_water() -> void:
	var f := _fisher([0.2, 0.2])
	await wait_seconds(3.6)    # рыбка в ведре, рыбак повернулся к ведру
	f.set("watch_range", Vector2(20, 20))   # следующий раз смотрит на воду долго
	await wait_seconds(3.0)    # снова смотрит на воду
	assert_eq(f.get("phase"), &"watch")
	var cat = CatScene.instantiate()
	cat.position = (f.get_node("Bucket") as Node3D).global_position + Vector3(0, 0.05, 0.15)
	world.add_child(cat)
	await wait_physics_frames(10)
	assert_true(GameState.mouth.any(func(x): return x.id == &"golden_fish"), "кот стащил золотую рыбку")
	assert_eq(GameState.hearts, 3)

func test_fisher_shoos_cat_at_bucket_when_turning() -> void:
	var f := _fisher([0.5, 0.5])
	var cat = CatScene.instantiate()
	cat.position = (f.get_node("Bucket") as Node3D).global_position + Vector3(0.7, 0.05, 0)
	world.add_child(cat)
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_seconds(4.0)    # клюнуло, вытянул, повернулся — кот у ведра
	assert_eq(GameState.hearts, 2, "рыбак шуганул")

func test_no_fisher_at_night() -> void:
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var f := _fisher()
	await wait_seconds(4.0)
	assert_false(f.visible, "ночью рыбака нет")
	assert_null(_fish(f), "и рыбки нет")

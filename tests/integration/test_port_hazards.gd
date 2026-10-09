extends GutTest
## План 14: опасности порта — чайки, волны, погрузчик, крабы (спек порта, раздел 3).

const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func _floor(y := 0.0, size := 40.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.2, size)
	shape.shape = box
	shape.position.y = y - 0.1
	body.add_child(shape)
	world.add_child(body)

func _cat(pos: Vector3) -> Node:
	var cat = CatScene.instantiate()
	cat.position = pos
	world.add_child(cat)
	return cat

func test_port_sounds_and_models_exist() -> void:
	for s in [&"gull", &"wave", &"horn"]:
		assert_true(Sfx.has(s), "звук %s" % s)
	for m in ["gull", "crab", "forklift", "burrow"]:
		assert_true(ResourceLoader.exists("res://assets/models/%s.glb" % m), "модель %s" % m)

const GullScene := preload("res://scenes/hazards/gull.tscn")

func _gull(pos: Vector3) -> Node3D:
	var g := GullScene.instantiate() as Node3D
	g.position = pos
	world.add_child(g)
	return g

func test_gull_circles_4m_above_its_perch() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	await wait_physics_frames(10)
	assert_almost_eq(g.global_position.y, 4.0, 0.3, "кружит на 4 м")
	var flat := Vector2(g.global_position.x, g.global_position.z).length()
	assert_between(flat, 2.9, 4.1, "радиус 3–4 м")

func test_gull_dives_on_cat_with_food_and_steals_last() -> void:
	# Спек: тень и крик 1 с, бросок; удар и последняя еда унесена, остальное в зубах.
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(5)
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	GameState.pick_up(FoodCatalog.get_by_id(&"fries"))
	await wait_physics_frames(3)
	assert_eq(g.mode, &"warn", "заметила кота с едой")
	assert_true((g.get_node("Shadow") as Node3D).visible, "тень на земле")
	await wait_seconds(1.8)
	assert_eq(GameState.hearts, 2, "удар")
	assert_eq(GameState.mouth.size(), 1, "унесла одну")
	assert_eq(GameState.mouth[0].id, &"shrimp", "последнюю — картошку")
	assert_gt(g.cooldown_left, 6.0, "перерыв 8 с")

func test_gull_ignores_cat_without_food_or_hidden() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(20)
	assert_eq(g.mode, &"circle", "без еды — кружит")
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	cat.hidden = true
	await wait_physics_frames(10)
	assert_eq(g.mode, &"circle", "спрятанного не видит")

func test_gull_sleeps_on_perch_at_night() -> void:
	_floor()
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var g := _gull(Vector3(2, 0, 2))
	var cat = _cat(Vector3(2.5, 0.05, 2.5))
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_physics_frames(15)
	assert_eq(g.mode, &"sleep")
	assert_lt(g.global_position.y, 1.0, "сидит на насесте")
	assert_eq(GameState.hearts, 3)

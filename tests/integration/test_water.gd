extends GutTest
## План 12: вода по правилам этапа 3 (спек порта, раздел 2) — кот тонет и возвращается на ближайший берег.

const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func _floor(y: float, size := 30.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.2, size)
	shape.shape = box
	shape.position.y = y - 0.1
	body.add_child(shape)
	world.add_child(body)

func _water(level: float) -> Water:
	var w := Water.new()
	w.size = Vector3(10, 3, 10)
	w.position = Vector3(0, level, 0)
	world.add_child(w)
	return w

func _shore(pos: Vector3) -> void:
	var m := Marker3D.new()
	m.add_to_group("shore")
	m.position = pos
	world.add_child(m)

func test_cat_sinking_into_water_drowns_and_returns_to_nearest_shore() -> void:
	_floor(-1.5)
	_water(-0.5)
	_shore(Vector3(8, 1.0, 0))
	_shore(Vector3(-14, 1.0, 0))
	var island := StaticBody3D.new()   # суша под маркерами
	island.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 0.2, 4)
	shape.shape = box
	island.add_child(shape)
	island.position = Vector3(8, 0.9, 0)
	world.add_child(island)
	GameState.pick_up(FoodCatalog.get_by_id(&"popcorn"))
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, -1.4, 0)
	world.add_child(cat)
	await wait_physics_frames(5)
	assert_gt(cat.drowning_left, 0.0, "кот тонет")
	await wait_seconds(1.5)
	assert_lt(Vector2(cat.global_position.x - 8, cat.global_position.z).length(), 0.5, "на ближайшем берегу")
	assert_true(GameState.mouth.is_empty(), "еда из зубов потеряна")
	assert_eq(GameState.hearts, 3, "сердечко цело")
	assert_gt(cat.invulnerable_left, 0.0, "неуязвимость после возврата")

func test_cat_on_shore_is_not_drowned() -> void:
	_floor(0.0)
	_water(-0.5)
	var cat = CatScene.instantiate()
	cat.position = Vector3(2, 0.05, 2)
	world.add_child(cat)
	await wait_seconds(1.0)
	assert_eq(cat.drowning_left, 0.0)

func test_water_surface_mesh_is_at_level() -> void:
	var w := _water(-0.5)
	var s := w.get_node("Surface") as MeshInstance3D
	assert_almost_eq(s.global_position.y, -0.5, 0.001)
	assert_true(s.material_override is ShaderMaterial, "поверхность — шейдер воды")

func test_builder_builds_water_zones_and_shore() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"water_zones": [{"pos": [3, -0.5, 4], "size": [6, 2, 6]}], "shore": [{"pos": [10, 0, 4]}]})
	var w := b.find_children("*", "Water", true, false)
	assert_eq(w.size(), 1)
	if w.size() == 1:
		assert_almost_eq((w[0] as Water).level, -0.5, 0.001)
	assert_eq(get_tree().get_nodes_in_group("shore").size(), 1)

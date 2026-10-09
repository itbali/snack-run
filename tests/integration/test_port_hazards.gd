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

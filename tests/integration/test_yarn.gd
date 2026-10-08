extends GutTest

const YarnScene := preload("res://scenes/food/yarn_pickup.tscn")
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

func test_cat_collects_yarn_on_contact() -> void:
	var y = YarnScene.instantiate()
	world.add_child(y)
	y.global_position = Vector3(0, 0.05, 0)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_physics_frames(5)
	assert_eq(GameState.yarn, 1)
	assert_true(not is_instance_valid(y) or y.is_queued_for_deletion())
	assert_eq(get_tree().get_nodes_in_group("yarn").size(), 0, "клубочек не респавнится")

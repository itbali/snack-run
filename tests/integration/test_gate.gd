extends GutTest

const GateScene := preload("res://scenes/world/gate.tscn")
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

func test_gate_blocks_until_satiety_then_opens() -> void:
	var gate = GateScene.instantiate()
	world.add_child(gate)
	gate.global_position = Vector3(0, 0, -2)
	await wait_physics_frames(2)
	assert_false(gate.open)
	assert_eq(gate.collision_layer, Layers.WORLD)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	Input.action_press("move_forward")
	await wait_seconds(2.0)
	Input.action_release("move_forward")
	assert_gt(cat.global_position.z, -1.9, "закрытые ворота не пускают")
	watch_signals(gate)
	GameState.satiety = 10
	GameState.satiety_changed.emit(10)
	await wait_physics_frames(2)
	assert_true(gate.open)
	assert_signal_emitted(gate, "opened")
	assert_eq(gate.collision_layer, 0)
	Input.action_press("move_forward")
	await wait_seconds(1.5)
	Input.action_release("move_forward")
	assert_lt(cat.global_position.z, -2.1, "открытые ворота пропускают")

func test_gate_starts_open_if_satiety_already_enough() -> void:
	GameState.satiety = 12
	var gate = GateScene.instantiate()
	world.add_child(gate)
	await wait_physics_frames(1)
	assert_true(gate.open, "со второго запуска ворота уже открыты")

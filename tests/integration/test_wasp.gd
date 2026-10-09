extends GutTest

const WaspScene := preload("res://scenes/hazards/wasp.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func test_wasp_orbits_anchor_at_radius() -> void:
	var w = WaspScene.instantiate()
	w.radius = 2.0
	world.add_child(w)
	w.global_position = Vector3(5, 0.5, 5)
	await wait_physics_frames(2)
	var anchor: Vector3 = w.anchor
	assert_almost_eq(anchor, Vector3(5, 0.5, 5), Vector3(0.01, 0.01, 0.01))
	var first: Vector3 = w.global_position
	for i in 6:
		await wait_seconds(0.15)
		var flat: Vector3 = w.global_position - anchor
		flat.y = 0.0
		assert_between(flat.length(), 1.8, 2.2, "держит радиус 2 м")
	assert_gt(w.global_position.distance_to(first), 0.5, "движется по кругу")

func test_wasp_stings_on_contact_but_not_hidden_cat() -> void:
	var w = WaspScene.instantiate()
	w.radius = 0.0
	w.height = 0.1
	world.add_child(w)
	w.global_position = Vector3(0, 0.1, 0)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.0, 0)
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 2)
	cat.invulnerable_left = 0.0
	cat.stunned_left = 0.0
	cat.hidden = true
	cat.global_position = Vector3(0.05, 0.0, 0)
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 2, "спрятанный кот не жалится")

func test_wasp_at_default_height_stings_cat_on_floor() -> void:
	var w = WaspScene.instantiate()
	w.radius = 0.0
	world.add_child(w)
	w.global_position = Vector3(0, 0.5, 0)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 0.2, 10)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_seconds(0.6)
	assert_eq(GameState.hearts, 2, "оса на высоте по умолчанию достаёт стоящего кота")

func test_wasp_faces_direction_of_motion() -> void:
	var w = WaspScene.instantiate()
	w.radius = 2.0
	world.add_child(w)
	w.global_position = Vector3(0, 0.5, 0)
	await wait_physics_frames(2)
	var p0: Vector3 = w.global_position
	await wait_physics_frames(6)
	var motion: Vector3 = (w.global_position - p0).normalized()
	var forward: Vector3 = -w.global_transform.basis.z
	assert_gt(motion.dot(forward), 0.9, "оса летит головой вперёд")

func test_wasp_over_table_stings_cat_standing_on_table() -> void:
	# Ревью: оса над десертным столом (h 1,0, r 0,8) должна доставать кота на краю столешницы.
	var table := StaticBody3D.new()
	table.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.06, 0.9)
	shape.shape = box
	shape.position.y = 0.72
	table.add_child(shape)
	world.add_child(table)
	var w = WaspScene.instantiate()
	w.radius = 0.8
	w.height = 1.0
	w.angular_speed = 3.0
	world.add_child(w)
	w.global_position = Vector3(0, 1.0, 0)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0.4, 0.8, 0)
	await wait_seconds(2.5)
	assert_eq(GameState.hearts, 2, "кот на краю стола получает укус за один оборот")

func test_wasp_has_a_trail() -> void:
	var w = WaspScene.instantiate()
	world.add_child(w)
	assert_not_null(w.find_child("Trail", false, false), "за осой серый шлейф")

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

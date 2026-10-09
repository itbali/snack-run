extends GutTest
## План 13: кот стоит на качающейся лодке (спек порта, раздел 2).

const CatScene := preload("res://scenes/player/cat.tscn")
const DECK := [{"size": [1.6, 0.75, 4.2], "offset": [0, 0.075, 0]}]

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func test_cat_rides_bobbing_boat() -> void:
	var b := WorldBuilder.new()
	world.add_child(b)
	b.build({"floaters": [{"model": "boat", "pos": [0, -2.3, 0], "rot": 0, "period": 3.0, "phase": 0.0, "colliders": DECK}]})
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, -1.8, 0.5)
	world.add_child(cat)
	var lo := 99.0
	var hi := -99.0
	for i in 240:
		await wait_physics_frames(1)
		if i > 30:
			lo = minf(lo, cat.global_position.y)
			hi = maxf(hi, cat.global_position.y)
	assert_gt(lo, -2.0, "кот не провалился сквозь лодку")
	assert_gt(hi - lo, 0.1, "кот качается вместе с лодкой")

func test_builder_builds_floaters_with_their_phases() -> void:
	var b := WorldBuilder.new()
	world.add_child(b)
	b.build({"floaters": [{"model": "barrel", "pos": [0, -2.7, 0], "phase": 0.5}, {"model": "barrel", "pos": [2, -2.7, 0], "phase": 2.0}]})
	var f := b.find_children("*", "Floater", true, false)
	assert_eq(f.size(), 2)
	if f.size() == 2:
		assert_ne((f[0] as Floater).phase, (f[1] as Floater).phase)
		assert_not_null((f[0] as Floater).get_node_or_null("Model"), "у опоры есть модель")

extends GutTest

const SprinklerScene := preload("res://scenes/hazards/sprinkler.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var cat
var sp

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
	cat.position = Vector3(1.0, 0.05, 0)
	world.add_child(cat)
	sp = SprinklerScene.instantiate()
	world.add_child(sp)

func test_warning_does_not_wet_but_spray_does() -> void:
	sp.time = 11.2   # предупреждение
	await wait_physics_frames(3)
	assert_eq(sp.phase, &"warn")
	assert_almost_eq(cat.wet_left, 0.0, 0.001, "бульканье — ещё не мокро")
	sp.time = 12.5
	await wait_physics_frames(3)
	assert_eq(sp.phase, &"on")
	assert_gt(cat.wet_left, 3.5, "под струёй кот намок")
	assert_eq(GameState.hearts, 3, "без урона")

func test_wet_cat_is_slower_and_dries() -> void:
	# Review Focus 3
	cat.wet(4.0)
	assert_almost_eq(cat.speed_factor(), 0.6, 0.001, "мокрый ×0,6")
	cat.wet(2.0)
	assert_almost_eq(cat.wet_left, 4.0, 0.05, "повторное намокание продлевает до большего, а не складывается")
	assert_almost_eq(cat.speed_factor(), 0.6, 0.001, "и не умножает замедление")
	await wait_seconds(4.2)
	assert_almost_eq(cat.speed_factor(), 1.0, 0.001, "высох через 4 с")

func test_sprinklers_work_at_night_too() -> void:
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	add_child_autofree(light)
	light.get_node("DayNight").set_time(220.0)
	sp.time = 12.5
	await wait_physics_frames(3)
	assert_gt(cat.wet_left, 0.0, "ночью дождеватели тоже работают")

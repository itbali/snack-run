extends GutTest

const CyclistScene := preload("res://scenes/hazards/cyclist.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var path: Path3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()   # без пола кот проваливается под дорогу раньше, чем проедет велосипед
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	path = Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(Vector3(-6, 0, 0))
	curve.add_point(Vector3(6, 0, 0))
	path.curve = curve
	world.add_child(path)

func _cyclist(interval: float, lead: float) -> Node:
	var c = CyclistScene.instantiate()
	c.interval_min = interval
	c.interval_max = interval
	c.bell_lead = lead
	c.speed = 12.0
	world.add_child(c)
	c.set_path(path)
	return c

func test_bell_then_ride_then_hide() -> void:
	var c = _cyclist(0.2, 0.2)
	watch_signals(c)
	assert_false(c.visible, "до выезда невидим")
	await wait_seconds(0.3)
	assert_signal_emitted(c, "bell")
	assert_false(c.riding, "звонок раньше выезда")
	await wait_seconds(0.3)
	assert_true(c.riding)
	assert_true(c.visible)
	var x0: float = c.global_position.x
	await wait_seconds(0.3)
	assert_gt(c.global_position.x, x0 + 1.0, "едет вдоль дороги")
	await wait_seconds(0.6)   # проезд 12 м при 12 м/с заканчивается на t=1,4 с; следующий выезд на t=1,8 с
	assert_false(c.riding, "доехал и скрылся")
	assert_false(c.visible)

func test_cyclist_hits_cat_on_road() -> void:
	var c = _cyclist(0.1, 0.1)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_seconds(1.2)
	assert_eq(GameState.hearts, 2)

func test_cyclist_model_faces_direction_of_motion() -> void:
	var c = _cyclist(0.1, 0.1)
	await wait_seconds(0.35)
	assert_true(c.riding)
	var p0: Vector3 = c.global_position
	await wait_physics_frames(6)
	var motion: Vector3 = (c.global_position - p0).normalized()
	var model := c.get_node("Model") as Node3D
	var wheel_f := model.find_child("cyclist_wheel_f", true, false) as Node3D
	var wheel_b := model.find_child("cyclist_wheel_b", true, false) as Node3D
	var front_dir: Vector3 = (wheel_f.global_position - wheel_b.global_position).normalized()
	assert_gt(motion.dot(front_dir), 0.9, "переднее колесо впереди по ходу движения")

func test_cyclist_dust_only_while_riding() -> void:
	var c = _cyclist(0.2, 0.2)
	var dust := c.find_child("Dust", false, false) as CPUParticles3D
	assert_not_null(dust, "пыль за колесом")
	if dust == null:
		return
	assert_false(dust.emitting, "до выезда пыли нет")
	await wait_seconds(0.6)
	assert_true(c.riding)
	assert_true(dust.emitting, "в пути пылит")

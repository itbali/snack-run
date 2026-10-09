extends GutTest
## Садовник, ребёнок, сторож (спек этапа 2, раздел 3).

const CatScene := preload("res://scenes/player/cat.tscn")
const LightingScene := preload("res://scenes/world/lighting.tscn")

var world: Node3D
var cat
var dn

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	var light = LightingScene.instantiate()
	world.add_child(light)
	dn = light.get_node("DayNight")
	dn.set_time(50.0)
	dn.time_scale = 0.0
	cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, 10)
	world.add_child(cat)

func _spawn(path: String) -> Node3D:
	var n := (load(path) as PackedScene).instantiate() as Node3D
	n.position = Vector3(0, 0.05, 0)   # смотрит по −Z
	world.add_child(n)
	return n

# --- садовник ---

func test_gardener_spray_hits_only_in_cone_and_not_during_warning() -> void:
	# Review Focus 5
	var g = _spawn("res://scenes/hazards/gardener.tscn")
	await wait_physics_frames(2)
	cat.global_position = Vector3(0, 0.05, -2)
	g.start_watering()
	assert_eq(g.mode, &"warn")
	await wait_physics_frames(5)
	assert_eq(GameState.hearts, 3, "шипение — ещё не удар")
	g.mode_left = 0.0
	await wait_physics_frames(3)
	assert_eq(g.mode, &"spray")
	assert_eq(GameState.hearts, 2, "струя бьёт кота в конусе 3 м")

func test_gardener_spray_misses_cat_outside_cone() -> void:
	var g = _spawn("res://scenes/hazards/gardener.tscn")
	await wait_physics_frames(2)
	cat.global_position = Vector3(2.2, 0.05, -2)   # 48° от направления струи
	g.start_watering()
	g.mode_left = 0.0
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 3)

func test_gardener_sleeps_at_night() -> void:
	# Review Focus 4
	var g = _spawn("res://scenes/hazards/gardener.tscn")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	assert_false(g.visible, "ночью садовник спит в сторожке")
	cat.global_position = Vector3(0, 0.05, -2)
	g.start_watering()
	g.mode_left = 0.0
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 3, "спящий садовник не поливает")

# --- ребёнок ---

func test_kid_catches_and_pets_without_damage() -> void:
	# Review Focus 2
	var k = _spawn("res://scenes/hazards/kid.tscn")
	GameState.pick_up(FoodCatalog.get_by_id(&"popcorn"))
	watch_signals(GameState)
	cat.global_position = Vector3(0, 0.05, -0.3)
	await wait_physics_frames(6)
	assert_signal_emitted(GameState, "cat_petted")
	assert_eq(GameState.hearts, 3, "гладит, а не бьёт")
	assert_true(GameState.mouth.is_empty(), "еда из зубов выпала")
	assert_gt(cat.petted_left, 1.5)
	await wait_seconds(2.2)
	assert_almost_eq(cat.petted_left, 0.0, 0.001, "не дольше 2 с")
	assert_gt(cat.invulnerable_left, 0.0, "после — неуязвимость")

func test_kid_chases_cat_it_sees() -> void:
	var k = _spawn("res://scenes/hazards/kid.tscn")
	cat.global_position = Vector3(0, 0.05, -5)
	await wait_seconds(1.0)
	assert_eq(k.brain.state, ChaseBrain.State.CHASE, "заметил и бежит")
	var d0: float = k.global_position.distance_to(cat.global_position)
	await wait_seconds(0.5)
	assert_lt(k.global_position.distance_to(cat.global_position), d0 - 0.5)

func test_kid_goes_home_in_the_evening() -> void:
	var k = _spawn("res://scenes/hazards/kid.tscn")
	dn.set_time(160.0)
	await wait_physics_frames(2)
	assert_false(k.visible, "вечером ребёнок ушёл домой")
	cat.global_position = Vector3(0, 0.05, -0.3)
	await wait_physics_frames(5)
	assert_almost_eq(cat.petted_left, 0.0, 0.001)

# --- сторож ---

func test_guard_only_at_night() -> void:
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	await wait_physics_frames(2)
	assert_false(gd.visible, "днём сторожа нет")
	cat.global_position = Vector3(0, 0.05, -4)
	assert_false(gd.sees_cat())
	dn.set_time(220.0)
	await wait_physics_frames(2)
	assert_true(gd.visible)
	assert_true(gd.sees_cat(), "ночью видит кота в луче фонарика")

func test_guard_sees_cat_under_lamp_even_outside_flashlight() -> void:
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	cat.global_position = Vector3(5, 0.05, -5)   # 45° — вне луча 15°
	assert_false(gd.sees_cat(), "в темноте сбоку не видит")
	var lamp := SpotLight3D.new()
	lamp.add_to_group("night_lights")
	world.add_child(lamp)
	lamp.global_position = Vector3(5, 2.45, -5)
	lamp.visible = true
	assert_true(gd.sees_cat(), "кот под горящим фонарём заметен")

func test_absent_people_are_not_invisible_walls() -> void:
	# Ревью плана 9 (I1): вне своей фазы тело не должно перекрывать дорогу коту.
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	var k = _spawn("res://scenes/hazards/kid.tscn")
	await wait_physics_frames(2)
	assert_eq(gd.collision_layer, 0, "днём тела сторожа нет")
	assert_eq(k.collision_layer, Layers.HAZARD, "ребёнок днём на месте")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	assert_eq(gd.collision_layer, Layers.HAZARD)
	assert_eq(k.collision_layer, 0, "ночью ребёнка нет")

func test_guard_touch_does_not_hit_by_day() -> void:
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	await wait_physics_frames(2)
	cat.global_position = Vector3(0, 0.05, -0.2)
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 3)

func test_kid_touch_does_not_pet_at_night() -> void:
	var k = _spawn("res://scenes/hazards/kid.tscn")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	cat.global_position = Vector3(0, 0.05, -0.3)
	await wait_physics_frames(6)
	assert_almost_eq(cat.petted_left, 0.0, 0.001)

func test_respawn_dries_and_frees_cat() -> void:
	cat.wet(4.0)
	cat.petted_left = 1.5
	cat.teleport(Vector3(0, 0.05, 5))
	assert_almost_eq(cat.wet_left, 0.0, 0.001)
	assert_almost_eq(cat.petted_left, 0.0, 0.001)

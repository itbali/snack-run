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

const GullScene := preload("res://scenes/hazards/gull.tscn")

func _gull(pos: Vector3) -> Node3D:
	var g := GullScene.instantiate() as Node3D
	g.position = pos
	world.add_child(g)
	return g

func test_gull_circles_4m_above_its_perch() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	await wait_physics_frames(10)
	assert_almost_eq(g.global_position.y, 4.0, 0.3, "кружит на 4 м")
	var flat := Vector2(g.global_position.x, g.global_position.z).length()
	assert_between(flat, 2.9, 4.1, "радиус 3–4 м")

func test_gull_dives_on_cat_with_food_and_steals_last() -> void:
	# Спек: тень и крик 1 с, бросок; удар и последняя еда унесена, остальное в зубах.
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(5)
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	GameState.pick_up(FoodCatalog.get_by_id(&"fries"))
	await wait_physics_frames(3)
	assert_eq(g.mode, &"warn", "заметила кота с едой")
	assert_true((g.get_node("Shadow") as Node3D).visible, "тень на земле")
	await wait_seconds(1.8)
	assert_eq(GameState.hearts, 2, "удар")
	assert_eq(GameState.mouth.size(), 1, "унесла одну")
	assert_eq(GameState.mouth[0].id, &"shrimp", "последнюю — картошку")
	assert_gt(g.cooldown_left, 6.0, "перерыв 8 с")

func test_gull_ignores_cat_without_food_or_hidden() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(20)
	assert_eq(g.mode, &"circle", "без еды — кружит")
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	cat.hidden = true
	await wait_physics_frames(10)
	assert_eq(g.mode, &"circle", "спрятанного не видит")

func test_gull_sleeps_on_perch_at_night() -> void:
	_floor()
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var g := _gull(Vector3(2, 0, 2))
	var cat = _cat(Vector3(2.5, 0.05, 2.5))
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_physics_frames(15)
	assert_eq(g.mode, &"sleep")
	assert_lt(g.global_position.y, 1.0, "сидит на насесте")
	assert_eq(GameState.hearts, 3)

const WaveScene := preload("res://scenes/hazards/wave.tscn")

func _wave() -> Node3D:
	var w := WaveScene.instantiate() as Node3D
	w.set("width", 20.0)
	w.set("inland", -1.0)   # суша — в сторону −Z от линии воды z 0
	world.add_child(w)
	return w

func test_wave_throws_cat_inland_and_wets_once() -> void:
	# Спек: кот отброшен к берегу на 1,5 м и мокрый 4 с; без урона, еда не теряется; один раз за накат.
	_floor()
	var w := _wave()
	var cat = _cat(Vector3(0, 0.05, -2.0))
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_seconds(2.0)
	assert_lt(cat.global_position.z, -3.2, "отброшен вглубь пляжа на 1,5 м")
	assert_gt(cat.wet_left, 0.0, "мокрый")
	assert_eq(GameState.hearts, 3)
	assert_eq(GameState.mouth.size(), 1, "еда в зубах")
	assert_eq(w.get("hits"), 1)
	await wait_seconds(3.0)
	assert_eq(w.get("hits"), 1, "за один накат — один раз")

func test_wave_does_not_reach_cat_far_inland() -> void:
	_floor()
	var w := _wave()
	var cat = _cat(Vector3(0, 0.05, -6.0))
	await wait_seconds(4.0)
	assert_eq(w.get("hits"), 0)
	assert_eq(cat.wet_left, 0.0)

func test_wave_foam_warns_before_roll() -> void:
	_floor()
	var w := _wave()
	w.set("offset", Wave.PERIOD - 1.0)   # за 1 с до наката
	await wait_physics_frames(3)
	assert_true((w.get_node("Foam") as CPUParticles3D).emitting, "пена у кромки")

const ForkliftScene := preload("res://scenes/hazards/forklift.tscn")

func _forklift(path: Array) -> Node3D:
	var f := ForkliftScene.instantiate() as Node3D
	f.position = Vector3(path[0][0], 0, path[0][1])
	f.call("configure", {"path": path, "wait": [0.5, 0.5]}, null)
	world.add_child(f)
	return f

func test_forklift_honks_then_drives_3mps() -> void:
	_floor()
	Sfx.reset_counters()
	var f := _forklift([[0, -10], [0, 10]])
	await wait_seconds(0.7)
	assert_eq(f.get("state"), &"horn", "сначала гудок")
	assert_eq(Sfx.last_played, &"horn")
	var z0: float = f.global_position.z
	await wait_seconds(1.5)
	assert_eq(f.get("state"), &"drive", "через 1,5 с едет")
	var z1: float = f.global_position.z
	await wait_seconds(1.0)
	assert_almost_eq(f.global_position.z - z1, 3.0, 0.4, "3 м/с")
	assert_almost_eq(z0, -10.0, 0.05, "до гудка стоял")

func test_forklift_hits_cat_on_its_lane() -> void:
	_floor()
	var f := _forklift([[0, -6], [0, 6]])
	_cat(Vector3(0, 0.05, 0))
	await wait_seconds(5.0)
	assert_eq(GameState.hearts, 2, "удар погрузчиком")

func test_forklift_stands_at_night() -> void:
	_floor()
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var f := _forklift([[0, -6], [0, 6]])
	await wait_seconds(3.0)
	assert_eq(f.get("state"), &"wait")
	assert_almost_eq(f.global_position.z, -6.0, 0.05, "ночью стоит")

func test_forklift_hits_cat_already_standing_at_its_forks() -> void:
	# Кот стоял у вил, пока погрузчик ждал: при старте удар всё равно проходит.
	_floor()
	var f := _forklift([[0, -6], [0, 6]])
	_cat(Vector3(0, 0.05, -4.9))
	await wait_seconds(3.0)
	assert_eq(GameState.hearts, 2)

const CrabScene := preload("res://scenes/hazards/crab.tscn")

func _crab(pos: Vector3, hz := {}) -> Node3D:
	var c := CrabScene.instantiate() as Node3D
	c.position = pos
	c.call("configure", hz, null)
	world.add_child(c)
	return c

func test_crab_waits_in_burrow_unseen() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	_cat(Vector3(4, 0.05, 0))
	await wait_physics_frames(20)
	assert_eq(c.get("state"), &"burrow")
	assert_false((c.get_node("Model") as Node3D).visible, "в норке не видно")

func test_crab_runs_out_and_pinches_cat_closer_than_3m() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	_cat(Vector3(2.5, 0.05, 0))
	await wait_physics_frames(10)
	assert_true((c.get_node("Model") as Node3D).visible, "вылез из норки")
	await wait_seconds(2.0)
	assert_eq(GameState.hearts, 2, "щипок")

func test_crab_hides_after_5s_chase_and_comes_back_after_6s() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	var cat = _cat(Vector3(2.5, 0.05, 0))
	await wait_physics_frames(3)
	cat.invulnerable_left = 99.0   # не мешаем погоне ударами
	await wait_seconds(5.5)
	assert_eq(c.get("state"), &"hide", "5 с погони — прячется")
	cat.global_position = Vector3(10, 0.05, 0)
	await wait_seconds(7.0)
	assert_eq(c.get("state"), &"burrow", "через 6 с снова сторожит")
	assert_lt(Vector2(c.global_position.x, c.global_position.z).length(), 0.4, "вернулся в норку")

func test_crab_hides_when_cat_jumps_over_it() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	var cat = _cat(Vector3(2.5, 0.05, 0))
	await wait_physics_frames(10)
	assert_eq(c.get("state"), &"chase")
	cat.invulnerable_left = 99.0
	cat.global_position = c.global_position + Vector3(0, 0.7, 0)   # кот над крабом в прыжке
	await wait_physics_frames(2)
	assert_eq(c.get("state"), &"hide")

func test_night_crab_sits_in_burrow_by_day() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0), {"night_only": true})
	_cat(Vector3(1, 0.05, 0))
	await wait_seconds(1.0)
	assert_eq(c.get("state"), &"burrow")
	assert_eq(GameState.hearts, 3)

func test_crab_ignores_hidden_cat_near_burrow() -> void:
	# Ревью плана 14: краб «видел» кота в укрытии у норки и ходил кругами, а при выходе щипал сразу.
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	var cat = _cat(Vector3(1.5, 0.05, 0))
	cat.hidden = true
	await wait_physics_frames(20)
	assert_eq(c.get("state"), &"burrow", "спрятанного не видит")

func test_crab_gives_up_when_cat_hides_mid_chase() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	var cat = _cat(Vector3(2.5, 0.05, 0))
	await wait_physics_frames(10)
	assert_eq(c.get("state"), &"chase")
	cat.hidden = true
	await wait_physics_frames(2)
	assert_eq(c.get("state"), &"hide", "кот спрятался — краб уходит в норку")

func test_crab_hides_after_pinch() -> void:
	# Один краб — одно сердечко за погоню.
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	_cat(Vector3(2.5, 0.05, 0))
	await wait_seconds(2.0)
	assert_eq(GameState.hearts, 2)
	assert_eq(c.get("state"), &"hide")

func test_gull_sleeps_on_its_post() -> void:
	# Ревью плана 14: спек — ночью чайки спят на столбах (тумба, фонарь), а не на земле.
	_floor()
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var g := GullScene.instantiate() as Node3D
	g.call("configure", {"perch_h": 0.55}, null)
	g.position = Vector3(2, 0, 2)
	world.add_child(g)
	await wait_physics_frames(10)
	assert_eq(g.mode, &"sleep")
	assert_almost_eq(g.global_position.y, 0.55, 0.05, "на верхушке тумбы")

func test_gull_does_not_strike_cat_who_lost_food() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(5)
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_physics_frames(3)
	assert_eq(g.mode, &"warn")
	GameState.spill()   # за секунду предупреждения еда пропала (съел, отняли)
	await wait_seconds(1.8)
	assert_eq(GameState.hearts, 3, "красть нечего — не бьёт")

func test_gull_ignores_drowning_cat() -> void:
	# Хвост плана 14: чайка пикировала к тонущему коту.
	assert_false(Gull.decide(3.0, true, false, false, 0.0, false, true), "кот тонет — не пикирует")

func test_forklift_turns_smoothly_at_route_end() -> void:
	_floor()
	var f := _forklift([[0, -2], [0, 2]])
	await wait_seconds(3.6)   # доехал до конца, ждёт
	var r0: float = f.rotation.y
	for i in 300:   # ждём старта обратно
		if f.get("state") == &"drive":
			break
		await wait_physics_frames(1)
	await wait_physics_frames(2)
	assert_lt(absf(wrapf(f.rotation.y - r0, -PI, PI)), 1.0, "в первые кадры разворот только начался")

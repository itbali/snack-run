extends GutTest
## План 10: рельеф (спек «Масштаб и рельеф», раздел 3).

const DEMO := "res://data/terrain/demo.json"

var t: Terrain

func before_each() -> void:
	t = Terrain.new()
	t.data_path = DEMO
	add_child_autofree(t)
	await wait_physics_frames(2)

func _corner_spread(x: float, z: float) -> float:
	var i := int(floor(x - t.x0))
	var j := int(floor(z - t.z0))
	var hs := [t.h(i, j), t.h(i + 1, j), t.h(i, j + 1), t.h(i + 1, j + 1)]
	return hs.max() - hs.min()

func test_height_at_matches_generator_points() -> void:
	assert_almost_eq(t.height_at(8, 8), 3.0, 0.01, "вершина холма")
	assert_almost_eq(t.height_at(-10, 10), -1.0, 0.01, "дно низины")
	assert_almost_eq(t.height_at(-12, -13), 2.0, 0.01, "терраса")
	assert_almost_eq(t.height_at(15, -15), 0.0, 0.01, "ровное место")

func test_ray_hits_terrain_at_height_at() -> void:
	# Review Focus 1: коллизия совпадает с картой высот (кроме самой ячейки обрыва).
	var space := t.get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var checked := 0
	while checked < 40:
		var x := rng.randf_range(-19.5, 19.5)
		var z := rng.randf_range(-19.5, 19.5)
		if _corner_spread(x, z) > 0.6:
			continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 10, z), Vector3(x, -10, z), Layers.WORLD))
		assert_false(hit.is_empty(), "луч в (%.1f, %.1f) попал в рельеф" % [x, z])
		if not hit.is_empty():
			assert_almost_eq((hit["position"] as Vector3).y, t.height_at(x, z), 0.03, "высота в (%.1f, %.1f)" % [x, z])
		checked += 1
	var edge := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-6.3, 10, -12), Vector3(-6.3, -10, -12), Layers.WORLD))
	assert_almost_eq((edge["position"] as Vector3).y, 2.0, 0.03, "у самого края террасы — её высота")

func test_tiles_material_and_group() -> void:
	assert_true(t.is_in_group("terrain"))
	var tiles := t.find_children("Tile*", "MeshInstance3D", false, false)
	assert_eq(tiles.size(), 4, "40×40 м — четыре тайла по 30 м")
	var m := (tiles[0] as MeshInstance3D).material_override as ShaderMaterial
	assert_not_null(m)
	assert_not_null(m.get_shader_parameter("splat"), "карта покрытий в шейдере")
	assert_not_null(m.get_shader_parameter("tex_cliff"), "камень для обрывов")

func test_surface_height_static_helper() -> void:
	assert_almost_eq(Terrain.surface_height(get_tree(), 8, 8), 3.0, 0.01)
	assert_almost_eq(Terrain.surface_height(get_tree(), 500, 500, -7.0), -7.0, 0.001, "вне рельефа — запасная высота")

func _builder() -> WorldBuilder:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.terrain = t
	return b

func test_builder_snaps_everything_to_surface() -> void:
	var b := _builder()
	b.build({"props": [{"model": "bin", "pos": [8, 0, 8]}, {"model": "box", "pos": [15, 1.0, -15], "snap": false}],
		"spawn_points": [{"pos": [-12, 0, -13], "allowed": [0]}],
		"yarn": [{"pos": [8, 0.1, 8]}],
		"hideouts": [{"kind": "box", "pos": [-10, 0.2, 10], "size": [0.6, 0.4, 0.6]}]})
	var props := b.get_node("Props").get_children()
	assert_almost_eq((props[0] as Node3D).global_position.y, 3.0, 0.02, "бак на вершине холма")
	assert_almost_eq((props[1] as Node3D).global_position.y, 1.0, 0.001, "snap: false — абсолютная высота (Review Focus 3)")
	assert_almost_eq((b.get_node("Spawns").get_child(0) as Node3D).global_position.y, 2.0, 0.02, "еда на террасе")
	assert_almost_eq((b.get_node("Yarn").get_child(0) as Node3D).global_position.y, 3.1, 0.02, "клубочек на 10 см над вершиной")
	assert_almost_eq((b.get_node("Hideouts").get_child(0) as Node3D).global_position.y, -0.8, 0.02, "укрытие в низине")

func test_builder_without_terrain_keeps_heights() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "bin", "pos": [8, 0, 8]}]})
	assert_almost_eq((b.get_node("Props").get_child(0) as Node3D).global_position.y, 0.0, 0.001)

func test_collider_rotation() -> void:
	var b := _builder()
	b.build({"props": [{"model": "box", "pos": [15, 0, -15], "colliders": [{"size": [1, 0.1, 2], "offset": [0, 0.5, 0], "rot": [-25, 0, 0]}]}]})
	var shape := b.get_node("Props").get_child(0).find_child("Shape0", true, false) as CollisionShape3D
	assert_almost_eq(shape.rotation_degrees.x, -25.0, 0.01, "наклонный коллайдер для пандусов и лестниц")

# --- кот на рельефе (Review Focus 2) ---

const CatScene := preload("res://scenes/player/cat.tscn")

func _demo_world() -> Node3D:
	var b := _builder()
	b.build(WorldBuilder.load_layout("res://data/layout/terrain_demo.json"))
	return b

func _cat_at(pos: Vector3) -> Node:
	var cat = CatScene.instantiate()
	cat.position = pos
	add_child_autofree(cat)
	return cat

func test_kit_colliders_are_slopes() -> void:
	var c: Array = WorldBuilder.kit_colliders("ramp2")
	assert_eq(c.size(), 1)
	assert_almost_eq(float(c[0]["rot"][0]), 25.0, 0.01, "пандус 25°")
	var s: Array = WorldBuilder.kit_colliders("terrace_stairs2")
	assert_lt(float(s[0]["rot"][0]), 35.0, "ход лестницы не круче 35°")
	assert_eq(WorldBuilder.kit_colliders("bin"), [], "обычные пропсы — без особых коллайдеров")

func test_cat_stands_on_slope_without_sliding() -> void:
	var cat = _cat_at(Vector3(13, t.height_at(13, 8) + 0.1, 8))   # склон холма ≈ 20°
	await wait_physics_frames(30)
	var p0: Vector3 = cat.global_position
	await wait_physics_frames(60)
	assert_lt(Vector2(cat.global_position.x - p0.x, cat.global_position.z - p0.z).length(), 0.05, "кот на склоне не сползает")

func _walk(cat, action: String, frames: int) -> void:
	Input.action_press(action)
	await wait_physics_frames(frames)
	Input.action_release(action)

func test_cat_climbs_ramp_and_stairs_to_terrace() -> void:
	_demo_world()
	await wait_physics_frames(2)
	for start in [Vector3(0.5, 0.1, -10), Vector3(-1.0, 0.1, -15.5)]:
		var cat = _cat_at(start)
		await wait_physics_frames(10)
		await _walk(cat, "move_left", 300)   # без камеры «влево» — это −X; на подъёме горизонтальная скорость ниже
		assert_gt(cat.global_position.y, 1.8, "с %s кот поднялся на террасу" % start)
		cat.queue_free()
		await wait_physics_frames(2)

func test_cat_jumps_down_from_terrace_unhurt() -> void:
	GameState.reset()
	var cat = _cat_at(Vector3(-7, 2.1, -12))
	await wait_physics_frames(10)
	await _walk(cat, "move_right", 60)
	await wait_physics_frames(30)
	assert_lt(cat.global_position.y, 0.3, "спрыгнул вниз")
	assert_eq(GameState.hearts, 3, "без урона")

func test_props_are_in_place_on_the_very_first_physics_frame() -> void:
	# Пропс, добавленный в начале координат и только потом сдвинутый, выталкивал кота сквозь рельеф.
	var b := _builder()
	b.build({"props": [{"model": "box", "pos": [15, 0, -15]}]})
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(0, 0.2, 0)
	q.collision_mask = Layers.WORLD
	var names := space.intersect_point(q, 4).map(func(h): return String(h["collider"].name))
	assert_false(names.any(func(n): return n.begins_with("box")), "в начале координат нет призрака коробки: %s" % [names])

func test_stairs_collider_meets_every_tread_top() -> void:
	# Ревью плана 10: плита шла через внутренние углы ступеней, кот тонул в ступенях до 20 см.
	var b := _builder()
	b.build({"props": [{"model": "terrace_stairs2", "pos": [15, 0, -12]}]})
	await wait_physics_frames(2)
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	for k in 10:
		var d := WorldBuilder.KIT_STEP_TREAD * (k + 0.5)
		var from := Vector3(15, 5, -12 - d)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 10, Layers.WORLD))
		assert_false(hit.is_empty())
		if not hit.is_empty():
			assert_almost_eq((hit["position"] as Vector3).y, WorldBuilder.KIT_STEP_RISE * (k + 1), 0.06, "середина ступени %d" % k)

func test_cat_cannot_walk_up_a_one_metre_terrace() -> void:
	# Спек, раздел 3: floor_max_angle 40°; обрыв террасы 1 м (45° в карте высот) пешком не проходится.
	var cat = _cat_at(Vector3(-10, 0.1, 0))
	await wait_physics_frames(10)
	await _walk(cat, "move_left", 180)
	assert_lt(cat.global_position.y, 0.5, "кот остался внизу у террасы 1 м")
	assert_almost_eq(rad_to_deg(cat.floor_max_angle), 40.0, 0.1)

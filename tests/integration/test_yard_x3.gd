extends GutTest
## План 11: двор ×3 (спек «Масштаб ×3 и рельеф», разделы 1–3).

const LAYOUT := "res://data/layout/yard.json"
var world: Node3D
var b: WorldBuilder
var t: Terrain

func before_all() -> void:
	world = Node3D.new()
	add_child(world)
	t = Terrain.new()
	t.data_path = "res://data/terrain/yard.json"
	world.add_child(t)
	b = WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(LAYOUT))
	await wait_physics_frames(2)

func after_all() -> void:
	world.free()

func _ray_down(x: float, z: float) -> Dictionary:
	var space := world.get_world_3d().direct_space_state
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 20, z), Vector3(x, -10, z), Layers.WORLD))

func test_yard_is_180_by_180_with_counts() -> void:
	assert_almost_eq(t.width, 180.0, 0.01)
	assert_almost_eq(t.depth, 180.0, 0.01)
	var d := WorldBuilder.load_layout(LAYOUT)
	assert_gte(d["spawn_points"].size(), 60)
	assert_gte(d["yarn"].size(), 40)
	assert_gte(d["hideouts"].size(), 25)
	var n := {}
	for h in d["hazards"]:
		n[h["type"]] = n.get(h["type"], 0) + 1
	assert_eq(n, {"dog": 3, "wasp": 4, "cyclist": 2})
	assert_lte(t.triangle_count(), 40000, "рельеф ≤ 40 000 треугольников")

func test_terraces_are_raised() -> void:
	assert_almost_eq(t.height_at(37, -27), 2.0, 0.01, "площадка на террасе")
	assert_almost_eq(t.height_at(0, -95), 2.0, 0.01, "верхний двор")
	assert_almost_eq(t.height_at(-20, 20), 1.0, 0.01, "веранда кафе")

func test_generated_items_stand_on_surface() -> void:
	# Review Focus 3: еда и клубочки стоят на рельефе или на пропсе, не висят и не утоплены.
	for s in b.get_node("Spawns").get_children() + b.get_node("Yarn").get_children():
		var p: Vector3 = s.global_position
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.6, Layers.WORLD))
		assert_false(hit.is_empty(), "%s в %s на опоре" % [s.name, p])
		if not hit.is_empty():
			assert_lt(p.y - (hit["position"] as Vector3).y, 0.35, "%s в %s не висит" % [s.name, p])

func test_garage_chain_steps_by_physics() -> void:
	# Review Focus 5: реальные верхи коллайдеров вдоль цепочки у первого гаража каждого ряда растут ≤ 0,8 м.
	# Первый гараж ряда rot 0 стоит в (−58, −30); цепочка на z −28,2: ящик x −61,58, бак −60,81, бак с ящиком −59,97, крыша −57.
	var tops: Array = []
	for x in [-61.58, -60.81, -59.97, -57.0]:
		var hit := _ray_down(x, -28.2)
		tops.append((hit["position"] as Vector3).y if not hit.is_empty() else -1.0)
	var prev := 0.0
	for top in tops:
		assert_lte(top - prev, 0.8, "шаг цепочки %s" % [tops])
		prev = top
	assert_almost_eq(tops[-1], 2.28, 0.05, "цепочка ведёт на крышу")

func test_district_edge_is_closed() -> void:
	# Review Focus 2: горизонтальный луч наружу на высоте кота упирается в стену по всему периметру, кроме прохода в парк.
	var space := world.get_world_3d().direct_space_state
	var checks := []
	for x in range(-84, 85, 12):
		checks.append([Vector3(x, 0.3, -147), Vector3(x, 0.3, -153)])
		if absf(x) > 18:
			checks.append([Vector3(x, 0.3, 27), Vector3(x, 0.3, 33)])
	for z in range(-144, 25, 12):
		checks.append([Vector3(-87, 0.3, z), Vector3(-93, 0.3, z)])
		checks.append([Vector3(87, 0.3, z), Vector3(93, 0.3, z)])
	for c in checks:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c[0], c[1], Layers.WORLD))
		assert_false(hit.is_empty(), "стена на краю у %s" % [c[0]])

func test_zones_reachable_through_gaps() -> void:
	# Review Focus 1: лестницы и пандусы террас стоят в проходах подпорных стен (луч вдоль подъёма не упирается в стену).
	var space := world.get_world_3d().direct_space_state
	for path in [[Vector3(30, 0.4, -6), Vector3(30, 2.4, -16)], [Vector3(14, 0.4, -27), Vector3(24, 2.4, -27)],
			[Vector3(-12, 0.4, -64), Vector3(-12, 2.4, -74)], [Vector3(-8, 0.4, 20), Vector3(-15, 1.4, 20)]]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(path[0] + Vector3.UP * 0.5, path[1] + Vector3.UP * 0.5, Layers.WORLD))
		assert_true(hit.is_empty() or not String(hit["collider"].name).begins_with("retaining_wall"), "проход %s свободен" % [path[0]])

func test_street_is_closed_except_arch() -> void:
	# План 12: из двора на улицу и в кафе — только через арку с воротами по сытости 10 (спек 3.4).
	var space := world.get_world_3d().direct_space_state
	for x in range(-87, 88, 6):
		if absi(x) < 2:
			continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 0.3, 9.5), Vector3(x, 0.3, 11.5), Layers.WORLD))
		assert_false(hit.is_empty(), "забор вдоль улицы у x %d" % x)

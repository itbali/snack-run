extends GutTest
## План 13: район «Порт» (спек порта, разделы 1, 2, 5, 6; размеры — спек масштаба).

const LAYOUT := "res://data/layout/port.json"
const PORT_FOOD := [&"shrimp", &"fries", &"squid", &"fish_sandwich", &"sushi"]
var world: Node3D
var b: WorldBuilder
var t: Terrain

func before_all() -> void:
	world = Node3D.new()
	add_child(world)
	t = Terrain.new()
	t.data_path = "res://data/terrain/port.json"
	world.add_child(t)
	b = WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(LAYOUT))
	await wait_physics_frames(2)

func after_all() -> void:
	world.free()

func test_port_size_levels_and_counts() -> void:
	assert_almost_eq(t.width, 120.0, 0.01)
	assert_almost_eq(t.depth, 102.0, 0.01)
	assert_almost_eq(t.height_at(0, 136), 0.0, 0.05, "набережная вровень с парком")
	assert_almost_eq(t.height_at(25, 180), -1.0, 0.05, "причал ниже набережной")
	assert_almost_eq(t.height_at(-30, 175), -2.0, 0.05, "пляж")
	assert_lt(t.height_at(0, 210), -3.0, "дно моря")
	var d := WorldBuilder.load_layout(LAYOUT)
	assert_gte(d["spawn_points"].size(), 35)
	assert_gte(d["yarn"].size(), 25)
	assert_gte(d["hideouts"].size(), 14)
	assert_lte(t.triangle_count(), 40000)

func test_water_and_dry_shore() -> void:
	# Review Focus 1: каждый маркер берега на суше, выше воды.
	var w := b.find_children("*", "Water", true, false)
	assert_eq(w.size(), 2, "море и гавань")
	for m in get_tree().get_nodes_in_group("shore"):
		var p: Vector3 = (m as Node3D).global_position
		assert_gt(t.height_at(p.x, p.z), -2.2, "берег %s выше воды" % p)

func test_boats_and_barrels_float_reachably() -> void:
	# Review Focus 2: 3 лодки и 5 бочек; палуба лодки в прыжке от причала (−1), верх бочки на 0,3 над водой.
	var boats := 0
	var barrels := 0
	for f in b.find_children("*", "Floater", true, false):
		var fl := f as Floater
		if String(fl.name).begins_with("boat"):
			boats += 1
			assert_lte(-1.0 - (fl.base.origin.y + 0.45 - fl.amp), 0.8, "с палубы на причал допрыгнуть")
		elif String(fl.name).begins_with("barrel"):
			barrels += 1
			assert_almost_eq(fl.base.origin.y + 0.7, -2.0, 0.01, "верх бочки на 0,3 над водой")
	assert_eq(boats, 3)
	assert_eq(barrels, 5)

func test_only_port_food_and_no_golden_fish_in_spawns() -> void:
	# Review Focus 4.
	for sp in WorldBuilder.load_layout(LAYOUT)["spawn_points"]:
		assert_false(sp.get("foods", []).is_empty(), "у точки %s список еды" % [sp["pos"]])
		for f in sp.get("foods", []):
			assert_true(StringName(f) in PORT_FOOD, "%s — еда порта" % f)

func test_port_land_edges_are_closed() -> void:
	# Review Focus 3: по суше за x ±60 не выйти (набережная и пляж).
	var space := world.get_world_3d().direct_space_state
	for z in range(128, 192, 6):
		var x := -58.0
		var from := Vector3(x, t.height_at(x, z) + 0.3, z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(-4, 0, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "забор на западе у z %d" % z)
	for z in range(128, 146, 6):
		var from := Vector3(58, 0.3, z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(4, 0, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "забор на востоке у z %d" % z)

func test_generated_items_stand_on_surface() -> void:
	for s in b.get_node("Spawns").get_children() + b.get_node("Yarn").get_children():
		var p: Vector3 = s.global_position
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.7, Layers.WORLD))
		assert_false(hit.is_empty(), "%s в %s на опоре" % [s.name, p])
		assert_gt(p.y, -2.3, "%s в %s не под водой" % [s.name, p])

func test_port_north_edge_beyond_park_is_closed() -> void:
	# Ревью плана 13: порт шире парка — на x −60…−45 и 45…60 у z 125 набережная обрывалась в пустоту.
	var space := world.get_world_3d().direct_space_state
	for x in [-58, -52, -47, 47, 52, 58]:
		var from := Vector3(x, 0.3, 127)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, -4), Layers.WORLD))
		assert_false(hit.is_empty(), "забор на юге набережной у x %d" % x)

func test_climb_steps_from_boats_to_pier() -> void:
	# Ревью плана 13: с палубы до настила 0,77–0,85 м — на пределе прыжка; понтоны у проёмов дают ступени ≤ 0,5 м.
	var space := world.get_world_3d().direct_space_state
	for f in b.find_children("boat*", "Floater", true, false):
		var boat := f as Floater
		var deck := boat.base.origin.y + 0.45
		var to_pier := signf(25.0 - boat.base.origin.x)
		var probe := boat.base.origin + Vector3(to_pier * 1.6, 0, 0)   # 0,8 м за бортом к причалу
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 3, probe + Vector3.DOWN * 3, Layers.WORLD))
		assert_false(hit.is_empty(), "у %s ступень к причалу" % boat.name)
		if not hit.is_empty():
			var step := (hit["position"] as Vector3).y
			assert_lte(step - (deck - boat.amp - 0.1), 0.55, "%s: с палубы на ступень" % boat.name)
			assert_lte(-1.0 - step, 0.55, "%s: со ступени на причал" % boat.name)

func test_barrels_are_a_walkable_chain() -> void:
	# Ревью плана 13: бочки через 3 м — зазор 2,3 м; цепочка — центры не дальше 2,0 м.
	var zs: Array = []
	for f in b.find_children("barrel*", "Floater", true, false):
		zs.append((f as Floater).base.origin.z)
	zs.sort()
	for i in zs.size() - 1:
		assert_lte(zs[i + 1] - zs[i], 2.05, "шаг бочек")

func test_cat_jumps_from_boat_back_onto_pier() -> void:
	# Ревью плана 13: реальный ввод — с лодки через понтон на причал.
	GameState.reset()
	var cat = (load("res://scenes/player/cat.tscn") as PackedScene).instantiate()
	cat.position = Vector3(37.3, -1.4, 165)
	world.add_child(cat)
	await wait_physics_frames(20)
	Input.action_press("move_left")   # без камеры «влево» — это −X, к причалу
	for i in 8:
		Input.action_press("jump")
		await wait_physics_frames(2)
		Input.action_release("jump")
		await wait_physics_frames(22)
	Input.action_release("move_left")
	assert_lt(cat.global_position.x, 34.5, "кот на причале, а не в воде")
	assert_gt(cat.global_position.y, -1.1, "на высоте настила")
	cat.free()

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

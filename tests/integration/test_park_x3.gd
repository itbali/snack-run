extends GutTest
## План 12: парк ×3 (спек «Масштаб ×3 и рельеф», раздел 2): поляна, холм с беседкой, пруд, роща, северный луг.

const LAYOUT := "res://data/layout/park.json"
var world: Node3D
var b: WorldBuilder
var t: Terrain

func before_all() -> void:
	world = Node3D.new()
	add_child(world)
	t = Terrain.new()
	t.data_path = "res://data/terrain/park.json"
	world.add_child(t)
	b = WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(LAYOUT))
	await wait_physics_frames(2)

func after_all() -> void:
	world.free()

func test_park_is_90_by_96_with_counts() -> void:
	assert_almost_eq(t.width, 90.0, 0.01)
	assert_almost_eq(t.depth, 96.0, 0.01)
	var d := WorldBuilder.load_layout(LAYOUT)
	assert_gte(d["spawn_points"].size(), 35)
	assert_gte(d["yarn"].size(), 25)
	var n := {}
	for h in d["hazards"]:
		n[h["type"]] = n.get(h["type"], 0) + 1
	assert_eq(n, {"pigeons": 4, "gardener": 2, "sprinkler": 6, "kid": 2, "guard": 2})
	assert_lte(t.triangle_count(), 40000)

func test_hill_with_gazebo_and_pond() -> void:
	assert_almost_eq(t.height_at(0, 92), 3.01, 0.05, "вершина холма")
	assert_lt(t.height_at(-28, 66), -1.2, "дно пруда")
	var w := b.find_children("*", "Water", true, false)
	assert_eq(w.size(), 1, "пруд")
	if w.size() == 1:
		assert_almost_eq((w[0] as Water).level, -0.5, 0.01)
	var g := b.find_children("gazebo*", "", true, false)
	assert_gt(g.size(), 0, "беседка на холме")

func test_shore_markers_are_dry() -> void:
	# Review Focus 1: берег выше воды и вне зоны — вернувшегося кота не затягивает обратно.
	var shores := get_tree().get_nodes_in_group("shore")
	assert_eq(shores.size(), 8)
	for m in shores:
		var p: Vector3 = (m as Node3D).global_position
		assert_gt(t.height_at(p.x, p.z), -0.3, "берег %s на суше" % p)

func test_generated_items_stand_on_surface() -> void:
	for s in b.get_node("Spawns").get_children() + b.get_node("Yarn").get_children():
		var p: Vector3 = s.global_position
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.6, Layers.WORLD))
		assert_false(hit.is_empty(), "%s в %s на опоре" % [s.name, p])
		if not hit.is_empty():
			assert_lt(p.y - (hit["position"] as Vector3).y, 0.35, "%s в %s не висит" % [s.name, p])
		assert_gt(p.y, -0.3, "%s в %s не в пруду" % [s.name, p])

func test_park_edge_is_closed() -> void:
	# Review Focus 2: забор по x ±45 и z 125 (юг закрывают стены двора).
	var space := world.get_world_3d().direct_space_state
	for z in range(33, 124, 6):
		for x in [-45, 45]:
			var from := Vector3(x - signf(x) * 2.0, t.height_at(x - signf(x) * 2.0, z) + 0.3, z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(signf(x) * 4.0, 0, 0), Layers.WORLD))
			assert_false(hit.is_empty(), "забор у x %d, z %d" % [x, z])
	for x in range(-42, 43, 6):
		var from := Vector3(x, t.height_at(x, 123) + 0.3, 123)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, 4), Layers.WORLD))
		assert_false(hit.is_empty(), "забор у x %d на севере" % x)

func test_people_routes_stay_on_dry_land() -> void:
	# Review Focus 3: маршруты садовников и сторожей не заходят в пруд.
	for h in WorldBuilder.load_layout(LAYOUT)["hazards"]:
		for p in h.get("path", []):
			assert_gt(t.height_at(float(p[0]), float(p[1])), -0.3, "%s: точка %s на суше" % [h["type"], p])

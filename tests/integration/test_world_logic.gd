extends GutTest
## План 16: логика мира (просьба владельца 2026-10-10) — нет одиночных стен и «домов из одной стены»,
## дома — объёмы с крышей; районы наполнены украшениями; украшения не в воде.

const DISTRICTS := {"yard": "res://data/layout/yard.json", "park": "res://data/layout/park.json", "port": "res://data/layout/port.json"}
const MIN_DECOR := {"yard": 3000, "park": 2500, "port": 800}
const WATER := {"park": -0.5, "port": -2.3}

func test_no_free_standing_wall_modules() -> void:
	for d in DISTRICTS:
		for p in WorldBuilder.load_layout(DISTRICTS[d])["props"]:
			assert_ne(p["model"], "wall", "%s: одиночная стена в %s — должен быть дом" % [d, p["pos"]])

func test_houses_have_roofs_and_depth() -> void:
	var world := Node3D.new()
	add_child_autofree(world)
	var b := WorldBuilder.new()
	world.add_child(b)
	var houses: Array = (WorldBuilder.load_layout(DISTRICTS["yard"])["props"] as Array).filter(func(p): return String(p["model"]).begins_with("house"))
	assert_gt(houses.size(), 40, "двор окружён домами")
	b.build({"props": houses.slice(0, 6)})
	await wait_physics_frames(2)
	var space := world.get_world_3d().direct_space_state
	for p in houses.slice(0, 6):
		var basis := Basis(Vector3.UP, deg_to_rad(float(p.get("rot", 0))))
		var back := Vector3(p["pos"][0], 0, p["pos"][2]) + basis * Vector3(0, 0, -1.0)   # за фасадом — корпус
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(back + Vector3.UP * 20, back + Vector3.DOWN * 5, Layers.WORLD))
		assert_false(hit.is_empty(), "дом %s имеет глубину" % [p["pos"]])
		if not hit.is_empty():
			assert_gt((hit["position"] as Vector3).y, 3.0, "крыша дома %s" % [p["pos"]])

func test_districts_are_filled_with_decor() -> void:
	for d in DISTRICTS:
		var n: int = (WorldBuilder.load_layout(DISTRICTS[d]).get("decor", []) as Array).size()
		assert_gte(n, MIN_DECOR[d], "%s: украшений %d" % [d, n])

func test_decor_is_not_in_water() -> void:
	for d in WATER:
		var t := Terrain.new()
		t.data_path = "res://data/terrain/%s.json" % d
		add_child_autofree(t)
		for it in WorldBuilder.load_layout(DISTRICTS[d]).get("decor", []):
			var h := t.height_at(float(it["pos"][0]), float(it["pos"][2]))
			if h < WATER[d]:
				assert_true(false, "%s: украшение %s под водой" % [d, it["pos"]])
				break

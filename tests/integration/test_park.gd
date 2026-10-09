extends GutTest
## План 8: район «Парк» (спек этапа 2, разделы 4–5).

const PARK := "res://data/layout/park.json"

func before_each() -> void:
	GameState.reset()

func _park_with_floor() -> Node3D:
	var world := Node3D.new()
	add_child_autofree(world)
	var t := Terrain.new()
	t.data_path = "res://data/terrain/park.json"   # пол парка — рельеф (план 10)
	world.add_child(t)
	var b := WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(PARK))
	return world

func _prop_at(world: Node3D, point: Vector3) -> String:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = point
	q.collision_mask = Layers.WORLD
	for hit in world.get_world_3d().direct_space_state.intersect_point(q, 8):
		var n: String = hit["collider"].name
		if n != "Floor":
			return n
	return ""

func test_park_layout_has_the_spec_content() -> void:
	var d := WorldBuilder.load_layout(PARK)
	var models := {}
	for p in d["props"]:
		models[p["model"]] = models.get(p["model"], 0) + 1
	for m in ["fountain", "slide", "swings", "sandbox", "kiosk", "shed", "lamp", "bench", "fence", "tree", "flowerbed"]:
		assert_gt(models.get(m, 0), 0, "в парке есть %s" % m)
	assert_gte(models.get("lamp", 0), 8, "аллея фонарей")
	assert_between(d["yarn"].size(), 10, 15, "10–15 клубочков")
	var kinds := {}
	for h in d["hideouts"]:
		kinds[h["kind"]] = true
	for k in ["bush", "bench", "slide"]:
		assert_true(kinds.has(k), "укрытие %s" % k)
	assert_eq(int(d["gates"][0]["satiety"]), GameState.PARK_GATE)
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(d)
	assert_eq(b.props_built, d["props"].size(), "все модели парка существуют")

func test_spawns_offer_only_park_food() -> void:
	var foods := {}
	for s in WorldBuilder.load_layout(PARK)["spawn_points"]:
		assert_true(s.has("foods"), "у точки парка задан список еды")
		for f in s.get("foods", []):
			foods[f] = true
			assert_not_null(FoodCatalog.get_by_id(StringName(f)), "еда %s есть в каталоге" % f)
	for f in ["popcorn", "bagel", "sandwich", "corn", "cotton_candy", "cupcake"]:
		assert_true(foods.has(f), "в парке спавнится %s" % f)

func test_spawn_point_respects_food_list() -> void:
	var sp := (load("res://scenes/food/food_spawn_point.tscn") as PackedScene).instantiate() as FoodSpawnPoint
	sp.allowed = [Rarity.Tier.COMMON, Rarity.Tier.RARE]
	sp.foods = [&"popcorn", &"sandwich"]
	add_child_autofree(sp)
	for i in 30:
		assert_true(sp.pick_def().id in [&"popcorn", &"sandwich"])

func test_catalog_has_fourteen_foods_with_models_and_icons() -> void:
	# Review Focus 3
	assert_eq(FoodCatalog.all().size(), 14)
	for f in FoodCatalog.all():
		assert_true(ResourceLoader.exists(f.model_path), "модель %s" % f.id)
		assert_not_null(f.icon(), "иконка %s" % f.id)

func test_invariants_spawns_yarn_hideouts() -> void:
	var world := _park_with_floor()
	await wait_physics_frames(3)
	var space := world.get_world_3d().direct_space_state
	for sp in world.find_children("*", "FoodSpawnPoint", true, false):
		var pos: Vector3 = (sp as Node3D).global_position
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "точка спавна %s внутри пропса" % pos)
	for y in world.find_children("*", "YarnPickup", true, false):
		var pos: Vector3 = (y as Node3D).global_position
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "клубочек %s внутри пропса" % pos)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "под клубочком %s что-то есть" % pos)
		if not hit.is_empty():
			assert_lt(pos.y - (hit["position"] as Vector3).y, 0.3, "клубочек %s не висит" % pos)
	for h in world.find_children("*", "Hideout", true, false):
		var pos: Vector3 = (h as Node3D).global_position
		assert_eq(_prop_at(world, pos), "", "укрытие %s (%s) внутри пропса" % [pos, h.kind])

func test_gate_opens_exactly_at_25() -> void:
	# Review Focus 1
	var world := _park_with_floor()
	var gate := world.find_child("gate_0", true, false) as Gate
	assert_not_null(gate)
	GameState.satiety = 24
	GameState.satiety_changed.emit(24)
	assert_false(gate.open, "при 24 парк закрыт")
	GameState.satiety = 25
	GameState.satiety_changed.emit(25)
	assert_true(gate.open, "при 25 открыт")
	assert_eq(gate.label, "Ворота в парк открыты!")

func test_park_is_fenced_and_floored() -> void:
	# Review Focus 2: по периметру забор, под всем парком пол.
	var world := _park_with_floor()
	await wait_physics_frames(3)
	var space := world.get_world_3d().direct_space_state
	for p in [Vector3(-14.5, 0.5, 45), Vector3(14.5, 0.5, 45), Vector3(0, 0.5, 60.9), Vector3(-5, 0.5, 30)]:
		var from := Vector3(0, 0.5, 45)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from + (p - from).normalized() * 3.0, p + (p - from).normalized() * 1.5, Layers.WORLD))
		assert_false(hit.is_empty(), "к %s не выйти: забор" % p)
	for p in [Vector3(-14, 1, 31), Vector3(14, 1, 59), Vector3(0, 1, 45.5), Vector3(-9, 1, 50)]:
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3(0, -2, 0), Layers.WORLD))
		assert_false(down.is_empty(), "под %s есть пол" % p)

func test_lawn_and_paths_are_textured_in_main() -> void:
	# План 10: пол парка — рельеф; газон и гравий — каналы карты покрытий.
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var t := main.find_child("ParkTerrain", true, false) as Terrain
	assert_not_null(t)
	if t:
		assert_eq(t.channels[2], "grass")
		assert_eq(t.channels[3], "gravel")
		assert_eq((t.material.get_shader_parameter("tex_b") as Texture2D).resource_path, "res://assets/images/textures/grass.png")
		assert_eq((t.material.get_shader_parameter("tex_a") as Texture2D).resource_path, "res://assets/images/textures/gravel.png")
		assert_gt(t.height_at(0, 45) + 1.0, 1.0, "пол парка на месте")
	SaveGame.clear()

func test_perimeter_fence_is_too_high_to_jump_from_any_prop() -> void:
	# Ревью плана 8 (I1): кот запрыгивал на куст (0,78 м) и с него перелетал забор 1,1 м. С любого пропса
	# кот достаёт до ≈ 0,8 + 0,84 м, поэтому коллайдер забора по периметру — не ниже 1,7 м.
	for p in WorldBuilder.load_layout(PARK)["props"]:
		if p["model"] != "fence":
			continue
		assert_true(p.has("colliders"), "у секции забора %s явный коллайдер" % [p["pos"]])
		if p.has("colliders"):
			var top: float = p["colliders"][0]["size"][1] / 2.0 + p["colliders"][0]["offset"][1]
			assert_gte(top, 1.7, "забор %s не перепрыгнуть" % [p["pos"]])

func test_yard_spawns_never_give_park_food() -> void:
	# Ревью плана 8 (I2): карточки парка нельзя собрать во дворе и кафе.
	var park_food := [&"popcorn", &"bagel", &"sandwich", &"corn", &"cotton_candy", &"cupcake"]
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(WorldBuilder.load_layout("res://data/layout/yard.json"))
	for sp in b.find_children("*", "FoodSpawnPoint", true, false):
		for i in 60:
			assert_false(StringName((sp as FoodSpawnPoint).pick_def().id) in park_food, "точка двора %s дала еду парка" % (sp as Node3D).global_position)

func test_park_hazards_are_placed() -> void:
	var types := {}
	for hz in WorldBuilder.load_layout(PARK)["hazards"]:
		types[hz["type"]] = types.get(hz["type"], 0) + 1
	assert_eq(types.get("sprinkler", 0), 3, "три зоны дождевателей")
	for t in ["pigeons", "gardener", "kid", "guard"]:
		assert_gt(types.get(t, 0), 0, "в парке есть %s" % t)
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(WorldBuilder.load_layout(PARK))
	assert_eq(b.hazards_built, WorldBuilder.load_layout(PARK)["hazards"].size(), "все опасности построены")

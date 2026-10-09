extends GutTest

const BuilderScript := preload("res://scripts/world/world_builder.gd")

func _builder() -> Node3D:
	var b: Node3D = BuilderScript.new()
	add_child_autofree(b)
	return b

func test_build_from_dictionary_counts_nodes() -> void:
	var b = _builder()
	b.build({
		"props": [
			{"model": "box", "pos": [1, 0, 1], "rot": 45, "outline": true},
			{"model": "bin", "pos": [3, 0, -4], "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
		],
		"hideouts": [{"kind": "box", "pos": [1, 0.2, 1], "size": [0.6, 0.4, 0.5]}],
		"spawn_points": [{"pos": [2, 0, 2], "allowed": [0, 1]}],
		"hazards": [{"type": "unknown", "pos": [0, 0, 0]}],
		"road": {"points": [[-5, 0, 5], [5, 0, 5]]},
		"yarn": [{"pos": [3, 0, 3]}],
		"gates": [{"pos": [0, 0, 5], "satiety": 10}],
		"shop": {"pos": [4, 0, 4], "rot": 0},
	})
	assert_eq(b.props_built, 2)
	assert_eq(b.yarn_built, 1)
	assert_eq(b.gates_built, 1)
	assert_eq(b.shop_built, 1)
	assert_eq(b.hideouts_built, 1)
	assert_eq(b.spawns_built, 1)
	assert_eq(b.hazards_built, 0, "неизвестный тип пропущен")
	var prop := b.get_node("Props").get_child(0) as StaticBody3D
	assert_eq(prop.collision_layer, Layers.WORLD)
	assert_almost_eq(prop.rotation_degrees.y, 45.0, 0.01)
	assert_true(prop.find_child("Shape*", true, false) != null, "коллайдер по AABB создан")
	var mesh := prop.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_not_null(mesh.material_overlay, "обводка у интерактивного пропса")
	assert_eq((b.get_node("Road") as Path3D).curve.point_count, 2)
	var sp := b.get_node("Spawns").get_child(0)
	assert_eq(sp.allowed, [0, 1])

func test_real_yard_layout_loads() -> void:
	var data := BuilderScript.load_layout("res://data/layout/yard.json")
	assert_gte(data["props"].size(), 24, "во дворе не меньше 24 пропсов")
	var kinds := {}
	for h in data["hideouts"]:
		kinds[h["kind"]] = true
	assert_true(kinds.has("box") and kinds.has("car") and kinds.has("bench"), "три типа укрытий")
	assert_gte(data["spawn_points"].size(), 8)
	var models := {}
	for p in data["props"]:
		models[p["model"]] = true
	for m in ["bench", "lamp", "car", "wall", "fence", "bag", "stairs", "bush", "tree", "puddle", "arch", "door"]:
		assert_true(models.has(m), "в раскладке есть " + m)
	for m in ["cafe_table", "chair", "umbrella", "cafe_sign"]:
		assert_true(models.has(m), "в раскладке есть " + m)
	var tables := 0
	var elevated_spawns := 0
	for p in data["props"]:
		if p["model"] == "cafe_table":
			tables += 1
			assert_true(p.has("colliders"), "у стола явный коллайдер столешницы")
	for sp in data["spawn_points"]:
		if sp["pos"][1] > 0.5:
			elevated_spawns += 1
	assert_gte(tables, 4)
	assert_gte(elevated_spawns, 3, "еда на столах и балконе")
	assert_eq(data["hazards"].size(), 4, "две осы, собака, велосипедист")
	var b = _builder()
	b.build(data)
	assert_eq(b.props_built, data["props"].size(), "все модели существуют")

# --- Инварианты раскладки (после ревью плана 2) ---

func _yard_with_floor() -> Node3D:
	var world := Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.2, 60)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	var b: Node3D = BuilderScript.new()
	world.add_child(b)
	b.build(BuilderScript.load_layout("res://data/layout/yard.json"))
	return world

func _prop_at(world: Node3D, point: Vector3) -> String:
	var space := world.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.position = point
	q.collision_mask = Layers.WORLD
	for hit in space.intersect_point(q, 8):
		var body: Node = hit["collider"]
		if body.name != "Floor":
			return body.name
	return ""

func test_elevated_spawn_points_stand_on_props_not_air() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	var space := world.get_world_3d().direct_space_state
	for sp in world.find_children("*", "FoodSpawnPoint", true, false):
		var pos: Vector3 = (sp as Node3D).global_position
		if pos.y < 0.5:
			continue
		var ray := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD)
		var hit := space.intersect_ray(ray)
		assert_false(hit.is_empty(), "под точкой %s что-то есть" % pos)
		if not hit.is_empty():
			assert_ne(hit["collider"].name, "Floor", "точка %s должна стоять на пропсе, а не висеть над полом" % pos)
			assert_lt(pos.y - hit["position"].y, 0.3, "еда не выше 30 см над опорой")

func test_spawn_points_and_hideouts_are_not_inside_props() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	for sp in world.find_children("*", "FoodSpawnPoint", true, false):
		var pos: Vector3 = (sp as Node3D).global_position + Vector3(0, 0.1, 0)
		assert_eq(_prop_at(world, pos), "", "точка спавна %s внутри пропса" % pos)
	for h in world.find_children("*", "Hideout", true, false):
		var pos: Vector3 = (h as Node3D).global_position
		assert_eq(_prop_at(world, pos), "", "укрытие %s (%s) внутри пропса: кот не сможет туда встать" % [pos, h.kind])

func test_arch_opening_and_tree_sides_are_passable() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	assert_eq(_prop_at(world, Vector3(0, 0.5, 10.5)), "gate_0", "в проёме арки стоят закрытые ворота")
	GameState.satiety = GameState.SATIETY_GATE
	GameState.satiety_changed.emit(GameState.satiety)
	await wait_physics_frames(2)
	assert_eq(_prop_at(world, Vector3(0, 0.5, 10.5)), "", "после открытия проём свободен")
	assert_eq(_prop_at(world, Vector3(9.7, 0.5, -6)), "", "рядом со стволом дерева должно быть проходимо")

func test_yarn_balls_in_layout_stand_on_something() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	var data := BuilderScript.load_layout("res://data/layout/yard.json")
	assert_between(data["yarn"].size(), 10, 15, "10–15 клубочков на район (спек 3.4)")
	var space := world.get_world_3d().direct_space_state
	for y in world.find_children("*", "YarnPickup", true, false):
		var pos: Vector3 = (y as Node3D).global_position
		var ray := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD)
		var hit := space.intersect_ray(ray)
		assert_false(hit.is_empty(), "под клубочком %s пусто" % pos)
		if not hit.is_empty():
			assert_lt(pos.y - hit["position"].y, 0.3, "клубочек %s висит в воздухе" % pos)
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "клубочек %s внутри пропса" % pos)

func test_water_props_get_mirror_material() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "puddle", "pos": [0, 0, 0], "water": true}]})
	assert_eq(b.water_built, 1)
	var mi := b.find_child("Model", true, false).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_lt(m.roughness, 0.1, "лужа зеркальная")
	assert_almost_eq(m.metallic, 0.0, 0.01)

func test_real_yard_puddles_are_water() -> void:
	var data := WorldBuilder.load_layout("res://data/layout/yard.json")
	for p in data["props"]:
		if p["model"] == "puddle":
			assert_true(bool(p.get("water", false)), "лужи в раскладке помечены water")

func test_decals_are_textured_quads_on_ground_and_walls() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"decals": [
		{"texture": "assets/images/world/decal_manhole.png", "pos": [1, 0, 2], "size": [1.0, 1.0]},
		{"texture": "assets/images/world/poster_cafe.png", "pos": [0, 1.5, -13.9], "size": [1.2, 1.2], "rot": 0, "wall": true}]})
	assert_eq(b.decals_built, 2)
	if b.decals_built != 2:
		return
	var ground := b.get_node("Decals").get_child(0) as MeshInstance3D
	assert_true(ground.mesh is QuadMesh)
	assert_almost_eq(ground.global_position.y, 0.01, 0.001, "чуть над асфальтом")
	assert_almost_eq(absf(ground.global_transform.basis.y.y), 0.0, 0.01, "лежит плашмя")
	var wall := b.get_node("Decals").get_child(1) as MeshInstance3D
	assert_almost_eq(wall.global_transform.basis.y.y, 1.0, 0.01, "стоит вертикально")
	assert_not_null((ground.get_surface_override_material(0) as StandardMaterial3D).albedo_texture)

func test_non_solid_props_have_no_collision() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "grass", "pos": [0, 0, 0], "solid": false}, {"model": "ivy", "pos": [0, 1, -13.9], "solid": false}]})
	assert_eq(b.props_built, 2)
	for body in b.get_node("Props").get_children():
		assert_eq(body.find_children("*", "CollisionShape3D", true, false).size(), 0, "%s без коллайдера" % body.name)

func test_real_yard_has_greenery_and_decals() -> void:
	var data := WorldBuilder.load_layout("res://data/layout/yard.json")
	var models := {}
	for p in data["props"]:
		models[p["model"]] = models.get(p["model"], 0) + 1
	assert_gte(models.get("bush", 0), 8, "кусты вдоль стен")
	assert_gte(models.get("grass", 0), 10, "трава пучками")
	assert_gte(models.get("ivy", 0), 3, "плющ на фасаде")
	assert_gte(data.get("decals", []).size(), 6, "декали и плакаты")
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(data)
	assert_eq(b.decals_built, data.get("decals", []).size(), "все текстуры декалей существуют")

func test_wall_decals_and_ivy_hang_on_real_walls() -> void:
	# Ревью плана 5: плакат висел в воздухе за краем северной стены. У каждой настенной декали и плюща должна быть стена сзади.
	var data := WorldBuilder.load_layout("res://data/layout/yard.json")
	var walls := []
	for p in data["props"]:
		if p["model"] == "wall":
			walls.append({"pos": WorldBuilder._v3(p["pos"]), "rot": int(p.get("rot", 0)) % 180})
	var items := []
	for dc in data["decals"]:
		if dc.get("wall", false):
			items.append({"pos": WorldBuilder._v3(dc["pos"]), "rot": int(dc.get("rot", 0)) % 180, "name": dc["texture"]})
	for p in data["props"]:
		if p["model"] == "ivy":
			items.append({"pos": WorldBuilder._v3(p["pos"]), "rot": int(p.get("rot", 0)) % 180, "name": "ivy"})
	for it in items:
		var backed := false
		for w in walls:
			var d: Vector3 = (it["pos"] as Vector3) - (w["pos"] as Vector3)
			var along := absf(d.x) if w["rot"] == 0 else absf(d.z)
			var across := absf(d.z) if w["rot"] == 0 else absf(d.x)
			if along <= 3.0 and across <= 0.5 and w["rot"] == it["rot"]:
				backed = true
		assert_true(backed, "%s в %s висит на стене" % [it["name"], it["pos"]])

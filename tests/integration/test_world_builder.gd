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
	})
	assert_eq(b.props_built, 2)
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
	var b = _builder()
	b.build(data)
	assert_eq(b.props_built, data["props"].size(), "все модели существуют")

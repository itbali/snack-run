extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

func before_each() -> void:
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()

func _meshes_named(root: Node, name: String) -> Array:
	var out := []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.name == name:
			out.append(mi)
	return out

func _mat(mi: MeshInstance3D) -> StandardMaterial3D:
	return mi.get_surface_override_material(0) as StandardMaterial3D

func test_large_surfaces_get_triplanar_textures() -> void:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var expected := {"wall": ["stucco", 4.5]}
	for name in expected:
		var found: Array = _meshes_named(main, name)
		assert_gt(found.size(), 0, "есть меш %s" % name)
		for mi in found:
			var m := _mat(mi)
			assert_not_null(m.albedo_texture, "%s с текстурой" % name)
			if m.albedo_texture:
				assert_eq(m.albedo_texture.resource_path, "res://assets/images/textures/%s.png" % expected[name][0])
			assert_true(m.uv1_triplanar and m.uv1_world_triplanar, "%s: трипланарно по мировым координатам" % name)
			assert_almost_eq(m.uv1_scale.x, 1.0 / expected[name][1], 0.001, "%s: тайл %.0f м" % [name, expected[name][1]])
			assert_eq(m.albedo_color.to_html(false), "ffffff", "цвет несёт текстура")
			assert_eq(m.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON, "тун сохраняется")

func test_yard_floor_is_terrain_with_asphalt_and_paving() -> void:
	# План 10: прежние меши ground/sidewalk заменены рельефом с картой покрытий.
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var t := main.find_child("YardTerrain", true, false) as Terrain
	assert_not_null(t)
	if t == null:
		return
	assert_eq(t.channels.slice(0, 2), ["asphalt", "paving"])
	assert_eq((t.material.get_shader_parameter("tex_r") as Texture2D).resource_path, "res://assets/images/textures/asphalt.png")
	assert_eq((t.material.get_shader_parameter("tex_g") as Texture2D).resource_path, "res://assets/images/textures/paving.png")
	assert_eq(_meshes_named(main, "ground").size(), 0, "старого плоского пола нет")

func test_windows_props_and_puddles_stay_flat() -> void:
	# Review Focus 1–2
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	for name in ["wall_frame0", "wall_glass0", "bin", "puddle", "box"]:
		for mi in _meshes_named(main, name):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
				if m:
					assert_null(m.albedo_texture, "%s остаётся плоским" % name)

func test_missing_texture_file_is_not_an_error() -> void:
	# Review Focus 3
	var root := Node3D.new()
	add_child_autofree(root)
	var mi := MeshInstance3D.new()
	mi.name = "nothing_known"
	mi.mesh = BoxMesh.new()
	root.add_child(mi)
	Toon.apply(root, Toon.OUTLINE_NONE)
	assert_eq(SurfaceTextures.apply(root), 0, "незнакомые меши не трогаются")
	assert_eq(SurfaceTextures.texture_or_null("res://assets/images/textures/none.png"), null)

extends GutTest

func _make_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	box.material = mat
	mi.mesh = box
	add_child_autofree(mi)
	return mi

func test_apply_sets_toon_modes_and_outline() -> void:
	var mi := _make_mesh()
	var n := Toon.apply(mi, 0.02)
	assert_eq(n, 1)
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_not_null(m)
	assert_eq(m.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)
	assert_eq(m.specular_mode, BaseMaterial3D.SPECULAR_TOON)
	assert_eq(m.albedo_color, Color.RED)
	var outline := mi.material_overlay as ShaderMaterial
	assert_not_null(outline, "обводка — шейдерный hull")
	if outline == null:
		return
	assert_eq(outline.shader.resource_path, "res://assets/shaders/outline_fur.gdshader")
	assert_almost_eq(float(outline.get_shader_parameter("width")), 0.02, 0.0001)
	assert_almost_eq(float(outline.get_shader_parameter("jitter")), 0.0, 0.0001, "у пропсов и еды шерсти нет")
	assert_eq((outline.get_shader_parameter("color") as Color).to_html(false), Toon.OUTLINE_COLOR.to_html(false))
	assert_false(m.rim_enabled, "у не-персонажей rim выключен")

func test_apply_without_outline_leaves_overlay_empty() -> void:
	var mi := _make_mesh()
	Toon.apply(mi, 0.0)
	assert_null(mi.material_overlay)

func test_apply_walks_children() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var a := _make_mesh()
	a.reparent(root)
	var b := _make_mesh()
	b.reparent(root)
	assert_eq(Toon.apply(root, 0.01), 2)

func test_outline_width_is_in_meters_under_scaled_parent() -> void:
	# Ревью: grow считается в пространстве модели, у скинового кота масштаб скелета 0,2.
	var parent := Node3D.new()
	parent.scale = Vector3.ONE * 0.2
	add_child_autofree(parent)
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	parent.add_child(mi)
	Toon.apply(mi, 0.02)
	assert_almost_eq(float((mi.material_overlay as ShaderMaterial).get_shader_parameter("width")), 0.1, 0.001)

func test_character_gets_rim_and_fur_jitter() -> void:
	var mi := _make_mesh()
	Toon.apply(mi, 0.006, true)
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_true(m.rim_enabled)
	assert_almost_eq(m.rim, 0.5, 0.01)
	assert_almost_eq(m.rim_tint, 0.6, 0.01)
	assert_almost_eq(float((mi.material_overlay as ShaderMaterial).get_shader_parameter("jitter")), Toon.OUTLINE_JITTER, 0.001)

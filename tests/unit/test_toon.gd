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
	var outline := mi.material_overlay as StandardMaterial3D
	assert_not_null(outline)
	assert_true(outline.grow)
	assert_almost_eq(outline.grow_amount, 0.02, 0.0001)
	assert_eq(outline.cull_mode, BaseMaterial3D.CULL_FRONT)
	assert_eq(outline.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_eq(outline.albedo_color, Toon.OUTLINE_COLOR)

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

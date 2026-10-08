extends GutTest

func test_catalog_has_four_skins() -> void:
	assert_eq(SkinCatalog.all().size(), 4)
	var black := SkinCatalog.get_by_id(&"black")
	assert_not_null(black)
	assert_eq(black.body.to_html(false), "394151")
	assert_eq(black.belly.to_html(false), "fcd3a1")

func test_apply_recolors_named_surfaces() -> void:
	var mi := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var box := BoxMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = mesh
	var body := StandardMaterial3D.new()
	body.resource_name = "sr_cat_orange"
	var other := StandardMaterial3D.new()
	other.resource_name = "sr_ink"
	mi.set_surface_override_material(0, body)
	mi.set_surface_override_material(1, other)
	add_child_autofree(mi)
	var n := CatSkin.apply(mi, SkinCatalog.get_by_id(&"black"))
	assert_eq(n, 1)
	assert_eq((mi.get_surface_override_material(0) as StandardMaterial3D).albedo_color.to_html(false), "394151")
	assert_eq((mi.get_surface_override_material(1) as StandardMaterial3D).albedo_color, Color.WHITE, "чужой материал не тронут")

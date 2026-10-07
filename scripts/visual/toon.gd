class_name Toon
extends RefCounted
## Переводит материалы в тун-режим и добавляет обводку инвертированным hull-ом (спек 2.3).

const OUTLINE_COLOR := Color("#394151")
const OUTLINE_CHARACTER := 0.006   # метры; 0,02 из первой версии спека на 35-см коте рвёт hull
const OUTLINE_FOOD := 0.004
const OUTLINE_NONE := 0.0


## outline_width задаётся в метрах: grow работает в пространстве модели, поэтому
## для вложенных в масштабированный узел мешей (скиновый кот) ширина пересчитывается.
static func apply(root: Node, outline_width: float = OUTLINE_CHARACTER) -> int:
	var count := 0
	if root is MeshInstance3D:
		count += _apply_to_mesh(root as MeshInstance3D, outline_width)
	for child in root.get_children():
		count += apply(child, outline_width)
	return count


static func _apply_to_mesh(mi: MeshInstance3D, outline_width: float) -> int:
	if mi.mesh == null:
		return 0
	var surfaces := mi.mesh.get_surface_count()
	for i in surfaces:
		var src := mi.get_active_material(i)
		var mat: StandardMaterial3D
		if src is StandardMaterial3D:
			mat = (src as StandardMaterial3D).duplicate()
		else:
			mat = StandardMaterial3D.new()
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat.roughness = 0.85
		mi.set_surface_override_material(i, mat)
	if outline_width > 0.0:
		mi.material_overlay = _make_outline(outline_width / _world_scale(mi))
	return surfaces


static func _world_scale(mi: MeshInstance3D) -> float:
	if not mi.is_inside_tree():
		return 1.0
	var s := mi.global_transform.basis.get_scale().x
	return s if s > 0.0001 else 1.0


static func _make_outline(width: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = OUTLINE_COLOR
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = width
	return m

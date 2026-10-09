class_name Toon
extends RefCounted
## Переводит материалы в тун-режим и добавляет обводку шейдерным hull-ом (спек 2.3, 2.8).
## character = true: rim-свет и «шерстяная» обводка с шумом ширины.

const OUTLINE_COLOR := Color("#394151")
const OUTLINE_CHARACTER := 0.006   # метры; 0,02 из первой версии спека на 35-см коте рвёт hull
const OUTLINE_FOOD := 0.004
const OUTLINE_NONE := 0.0
const OUTLINE_JITTER := 0.25
const RIM := 0.5
const RIM_TINT := 0.6
const OutlineShader := preload("res://assets/shaders/outline_fur.gdshader")


## outline_width задаётся в метрах: hull растёт в пространстве модели, поэтому
## для вложенных в масштабированный узел мешей (скиновый кот) ширина пересчитывается.
static func apply(root: Node, outline_width: float = OUTLINE_CHARACTER, character := false) -> int:
	var count := 0
	if root is MeshInstance3D:
		count += _apply_to_mesh(root as MeshInstance3D, outline_width, character)
	for child in root.get_children():
		count += apply(child, outline_width, character)
	return count


static func _apply_to_mesh(mi: MeshInstance3D, outline_width: float, character: bool) -> int:
	if mi.mesh == null:
		return 0
	var surfaces := mi.mesh.get_surface_count()
	for i in surfaces:
		var src := mi.get_active_material(i)
		var mat: StandardMaterial3D
		if src is StandardMaterial3D:
			mat = (src as StandardMaterial3D).duplicate()
			mat.resource_name = src.resource_name   # скины узнают поверхности по имени материала
		else:
			mat = StandardMaterial3D.new()
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat.roughness = 0.85
		mat.rim_enabled = character
		if character:
			mat.rim = RIM
			mat.rim_tint = RIM_TINT
		mi.set_surface_override_material(i, mat)
	if outline_width > 0.0:
		mi.material_overlay = make_outline(outline_width / _world_scale(mi), OUTLINE_JITTER if character else 0.0)
	return surfaces


static func _world_scale(mi: MeshInstance3D) -> float:
	if not mi.is_inside_tree():
		return 1.0
	var s := mi.global_transform.basis.get_scale().x
	return s if s > 0.0001 else 1.0


static func make_outline(width: float, jitter := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = OutlineShader
	m.set_shader_parameter("color", OUTLINE_COLOR)
	m.set_shader_parameter("width", width)
	m.set_shader_parameter("jitter", jitter)
	m.set_shader_parameter("frequency", 40.0)
	m.set_shader_parameter("alpha", 1.0)
	return m

"""Примитивы и проверки для генераторов ассетов."""
import bmesh
import bpy
from mathutils import Vector

import palette


def clear_scene() -> None:
	"""Удаляет все объекты и осиротевшие данные текущего файла."""
	bpy.ops.wm.read_homefile(use_empty=True)
	for block in (bpy.data.meshes, bpy.data.materials, bpy.data.actions, bpy.data.armatures):
		for item in list(block):
			if item.users == 0:
				block.remove(item)


def rounded_box(name, size, bevel=0.02, segments=3, material=None):
	"""Параллелепипед size=(x,y,z) с центром в начале координат и bevel-модификатором."""
	mesh = bpy.data.meshes.new(name)
	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	for v in bm.verts:
		v.co.x *= size[0]
		v.co.y *= size[1]
		v.co.z *= size[2]
	bm.to_mesh(mesh)
	bm.free()
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	if bevel > 0:
		mod = obj.modifiers.new("Bevel", "BEVEL")
		mod.width = bevel
		mod.segments = segments
		mod.limit_method = "ANGLE"
	if material:
		mesh.materials.append(palette.get_material(material))
	bpy.context.view_layer.update()   # иначе dimensions нулевые до первой оценки сцены
	return obj


def world_extent(obj) -> float:
	"""Наибольший габарит в мировых координатах (учитывает масштаб родителя, в отличие от obj.dimensions)."""
	corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
	spans = [max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3)]
	return max(spans)


def tri_count(obj) -> int:
	"""Число треугольников с учётом модификаторов."""
	depsgraph = bpy.context.evaluated_depsgraph_get()
	eval_obj = obj.evaluated_get(depsgraph)
	mesh = eval_obj.to_mesh()
	mesh.calc_loop_triangles()
	n = len(mesh.loop_triangles)
	eval_obj.to_mesh_clear()
	return n


def check_asset(objs, max_tris: int, max_dim: float):
	"""Возвращает список ошибок (пустой список = ассет валиден)."""
	errors = []
	bpy.context.view_layer.update()
	total = sum(tri_count(o) for o in objs if o.type == "MESH")
	if total > max_tris:
		errors.append(f"треугольников {total} > лимита {max_tris}")
	biggest = max((world_extent(o) for o in objs if o.type == "MESH"), default=0.0)
	if biggest > max_dim:
		errors.append(f"габарит {biggest:.2f} м > лимита {max_dim} м")
	for o in objs:
		if o.type != "MESH":
			continue
		for m in o.data.materials:
			if not palette.is_palette_material(m):
				errors.append(f"{o.name}: материал {getattr(m, 'name', None)!r} не из палитры")
	return errors

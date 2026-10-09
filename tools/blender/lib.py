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


def _finish(name, bm, material=None, smooth=False):
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	if smooth:
		for p in mesh.polygons:
			p.use_smooth = True
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	if material:
		mesh.materials.append(palette.get_material(material))
	bpy.context.view_layer.update()
	return obj


def cylinder(name, radius, depth, segments=16, material=None, smooth=True):
	bm = bmesh.new()
	bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
	                      radius1=radius, radius2=radius, depth=depth)
	return _finish(name, bm, material, smooth)


def cone(name, radius, depth, segments=12, material=None, smooth=True):
	bm = bmesh.new()
	bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
	                      radius1=radius, radius2=0.0, depth=depth)
	return _finish(name, bm, material, smooth)


def sphere(name, radius, material=None, segments=12, rings=8, smooth=True):
	bm = bmesh.new()
	bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
	return _finish(name, bm, material, smooth)


def torus(name, major, minor, material=None):
	bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
	                                 major_segments=16, minor_segments=8)
	obj = bpy.context.object
	obj.name = name
	obj.data.name = name
	for p in obj.data.polygons:
		p.use_smooth = True
	if material:
		obj.data.materials.append(palette.get_material(material))
	bpy.context.view_layer.update()
	return obj


def wedge(name, width, length, height, material=None):
	"""Треугольная призма (ломтик пиццы): острый угол в начале координат, основание на +Y."""
	bm = bmesh.new()
	h = height / 2.0
	v = [bm.verts.new(c) for c in (
		(0, 0, -h), (-width / 2, length, -h), (width / 2, length, -h),
		(0, 0, h), (-width / 2, length, h), (width / 2, length, h))]
	bm.faces.new((v[0], v[2], v[1]))
	bm.faces.new((v[3], v[4], v[5]))
	bm.faces.new((v[0], v[1], v[4], v[3]))
	bm.faces.new((v[1], v[2], v[5], v[4]))
	bm.faces.new((v[2], v[0], v[3], v[5]))
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	return _finish(name, bm, material, smooth=False)


def group(parts):
	"""Первый объект становится родителем остальных (мировые позиции сохраняются)."""
	root = parts[0]
	for p in parts[1:]:
		p.parent = root
		p.matrix_parent_inverse = root.matrix_world.inverted()
	return parts


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


def join(name, objs):
	"""Сливает объекты в один меш (мировые координаты, материалы по граням); исходники удаляются.
	Нужно, когда поверхность должна быть одним мешем с одним именем (SurfaceTextures ищет по имени)."""
	import bmesh as _bm
	bpy.context.view_layer.update()
	bm = _bm.new()
	mats = []
	for o in objs:
		depsgraph = bpy.context.evaluated_depsgraph_get()
		tmp = o.evaluated_get(depsgraph).to_mesh().copy()
		tmp.transform(o.matrix_world)
		for poly in tmp.polygons:
			mat = o.data.materials[poly.material_index] if o.data.materials else None
			if mat not in mats:
				mats.append(mat)
			poly.material_index = mats.index(mat)
		bm.from_mesh(tmp)
		bpy.data.meshes.remove(tmp)
		bpy.data.objects.remove(o)
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	for m in mats:
		mesh.materials.append(m)
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	bpy.context.view_layer.update()
	return obj

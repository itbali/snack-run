"""Глаза кота: пять наборов мешей (обычные, испуг, довольный, оглушён, моргание) в глазницах, на кости головы.
В Godot одновременно виден один набор, переключает CatFace (спек 2.4). Координаты считаются
от bbox вершин головы, поэтому глаза всегда на морде, как бы ни был отмасштабирован риг."""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import lib

EYE_SETS = ("normal", "scared", "happy", "dizzy", "blink")
HEAD_GROUP = "head"
SPHERE = {"segments": 8, "rings": 6}   # 80 треугольников на сферу


def group_bbox(mesh, bone):
	"""Мировой bbox вершин, привязанных к кости bone весом > 0,5; при нехватке — порог 0,25,
	а если и так пусто — отрезок head/tail самой кости (у кончика хвоста и шеи вершин может не быть)."""
	bpy.context.view_layer.update()
	gi = mesh.vertex_groups[bone].index
	pts = []
	for threshold in (0.5, 0.25):
		pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices
		       if any(g.group == gi and g.weight > threshold for g in v.groups)]
		if pts:
			break
	if not pts:
		b = mesh.parent.data.bones[bone]
		pts = [mesh.parent.matrix_world @ b.head_local, mesh.parent.matrix_world @ b.tail_local]
	lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
	hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
	return lo, hi


def head_bbox(mesh):
	return group_bbox(mesh, HEAD_GROUP)


def _head_points(mesh):
	bpy.context.view_layer.update()
	gi = mesh.vertex_groups[HEAD_GROUP].index
	return [mesh.matrix_world @ v.co for v in mesh.data.vertices
	        if any(g.group == gi and g.weight > 0.5 for g in v.groups)]


def local_front(mesh, x, z, window=0.012):
	"""Передняя поверхность морды (max y) в XZ-окрестности точки: у глаз морда отступает от кончика носа."""
	pts = [p for p in _head_points(mesh) if abs(p.x - x) < window and abs(p.z - z) < window]
	return max(p.y for p in pts) if pts else max(p.y for p in _head_points(mesh))


def local_halfwidth(mesh, y, z, window=0.012):
	"""Полуширина головы (max |x|) на высоте z в окрестности глубины y."""
	pts = [p for p in _head_points(mesh) if abs(p.y - y) < window and abs(p.z - z) < window]
	return max(abs(p.x) for p in pts) if pts else max(abs(p.x) for p in _head_points(mesh))


WHITE_R = 0.013
SINK = 0.5   # доля радиуса белка внутри головы


def eye_centers(lo, hi, mesh=None):
	"""Центры левого и правого глаза: верхняя треть морды; глубина и ширина — по локальной поверхности
	морды у глаза (ревью плана 5: относительно кончика носа белки выпирали сбоку и вперёд)."""
	z = lo.z + (hi.z - lo.z) * 0.68
	x = (hi.x - lo.x) * 0.22
	y = hi.y - 0.012
	if mesh is not None:
		front = local_front(mesh, x, z)
		half = local_halfwidth(mesh, front - 0.006, z)
		x = max(0.008, half - WHITE_R * 0.95)                       # наружный край белка ≈ на профиле головы
		y = front - WHITE_R * 0.55 * (1.0 - SINK) + 0.0005          # перед белка = front + 0,5 мм; зрачок и блик ещё на 3 мм
	return Vector((-x, y, z)), Vector((x, y, z))


def _line(name, center, angle_deg, length, radius, material):
	"""Штрих в плоскости лица XZ: цилиндр вдоль X, повёрнутый на angle вокруг Y (оси взгляда).
	Положительный угол опускает +X-конец штриха."""
	c = lib.cylinder(name, radius=radius, depth=length, segments=6, material=material)
	c.rotation_euler = (0.0, math.pi / 2 + math.radians(angle_deg), 0.0)
	c.location = center
	return c


def _eyeball(p, c, white_r, iris_r, pupil_r, pop):
	"""Глаз в глазнице: белок-эллипсоид утоплен в голову, радужка/зрачок/блик на его передней поверхности.
	pop — насколько белок выдвинут вперёд (0 = центр на 40 % радиуса внутри головы)."""
	fwd = Vector((0.0, 1.0, 0.0))
	w = lib.sphere(p + "_w", white_r, material="eye_white", **SPHERE)
	w.scale = (1.0, 0.55, 1.0)
	w.location = c - fwd * (white_r * 0.55 * SINK - pop)   # центр белка утоплен в голову на SINK радиуса (по сплюснутой оси)
	front = w.location + fwd * (white_r * 0.55)
	iris = lib.sphere(p + "_i", iris_r, material="eye_green", **SPHERE)
	iris.scale = (1.0, 0.35, 1.0)
	iris.location = front - fwd * (iris_r * 0.35 * 0.6)
	pupil = lib.sphere(p + "_k", pupil_r, material="ink", **SPHERE)
	pupil.scale = (1.0, 0.3, 1.0)
	pupil.location = iris.location + fwd * 0.0015
	glint = lib.sphere(p + "_g", pupil_r * 0.45, material="eye_white", segments=6, rings=4)
	glint.location = pupil.location + fwd * 0.0015 + Vector((-pupil_r * 0.4, 0.0, pupil_r * 0.45))
	return [w, iris, pupil, glint]


def _parts(kind, side, c):
	p = f"eye_{kind}_{side}"
	fwd = Vector((0.0, 1.0, 0.0))
	if kind == "normal":
		return _eyeball(p, c, WHITE_R, 0.008, 0.0042, 0.0)
	if kind == "scared":
		return _eyeball(p, c, WHITE_R + 0.002, 0.0055, 0.0023, 0.003)   # белок выпучен на 3 мм, зрачок точкой
	if kind == "happy":   # «^»: левый штрих поднимается к центру, правый — от центра вниз
		a = _line(p + "_a", c + Vector((-0.006, 0.006, -0.002)), -35, 0.016, 0.0025, "ink")
		b = _line(p + "_b", c + Vector((0.006, 0.006, -0.002)), 35, 0.016, 0.0025, "ink")
		return [a, b]
	if kind == "blink":   # закрытый глаз: одна горизонтальная ресница
		return [_line(p + "_a", c + fwd * 0.006, 0, 0.024, 0.0025, "ink")]
	a = _line(p + "_a", c + fwd * 0.006, 45, 0.026, 0.0025, "ink")    # dizzy: «×»
	b = _line(p + "_b", c + fwd * 0.006, -45, 0.026, 0.0025, "ink")
	return [a, b]


def _join(name, objs):
	"""Сливает объекты в один меш в мировых координатах, сохраняя материалы по граням."""
	bpy.context.view_layer.update()
	bm = bmesh.new()
	mats = []
	for o in objs:
		tmp = o.data.copy()
		tmp.transform(o.matrix_world)
		mat = o.data.materials[0]
		if mat not in mats:
			mats.append(mat)
		for poly in tmp.polygons:
			poly.material_index = mats.index(mat)
		bm.from_mesh(tmp)
		bpy.data.meshes.remove(tmp)
		bpy.data.objects.remove(o)
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	for m in mats:
		mesh.materials.append(m)
	for poly in mesh.polygons:
		poly.use_smooth = True
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	return obj


def _attach(obj, arm, bone=HEAD_GROUP):
	"""Переводит меш в пространство арматуры и скинит его к кости bone весом 1,0."""
	bpy.context.view_layer.update()
	obj.data.transform(arm.matrix_world.inverted() @ obj.matrix_world)
	obj.matrix_world = Matrix.Identity(4)
	obj.parent = arm
	obj.matrix_parent_inverse = Matrix.Identity(4)
	vg = obj.vertex_groups.new(name=bone)
	vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
	mod = obj.modifiers.new("Armature", "ARMATURE")
	mod.object = arm
	bpy.context.view_layer.update()


def build_eyes(arm, mesh):
	"""Четыре объекта eyes_<набор>, дети арматуры. Звать после face_forward и rescale."""
	lo, hi = head_bbox(mesh)
	left, right = eye_centers(lo, hi, mesh)
	out = []
	for kind in EYE_SETS:
		parts = _parts(kind, "l", left) + _parts(kind, "r", right)
		obj = _join(f"eyes_{kind}", parts)
		_attach(obj, arm)
		out.append(obj)
	return out   # веки-козырьки пробовали: при утопленных глазах читаются как брови, убраны (план 5)

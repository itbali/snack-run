"""Машина (план 18): кузов с капотом и багажником, сужающаяся кабина со стёклами и стойками, колёса с дисками, фары,
фонари, бамперы, зеркала. Габарит 1,7×3,6×1,4 м, клиренс 0,3 м (под машиной укрытие), перёд — +Y Blender."""
import math

import bmesh
import bpy

import lib


def cabin(name, w0, l0, w1, l1, h, color):
	"""Кабина-трапеция: низ w0×l0, верх w1×l1 (сдвинут назад), высота h. Крыша — цвет кузова, остальные грани — стекло."""
	import palette
	bm = bmesh.new()
	lo = [(-w0 / 2, -l0 / 2, 0), (w0 / 2, -l0 / 2, 0), (w0 / 2, l0 / 2, 0), (-w0 / 2, l0 / 2, 0)]
	hi = [(-w1 / 2, -l1 / 2 - 0.1, h), (w1 / 2, -l1 / 2 - 0.1, h), (w1 / 2, l1 / 2 - 0.1, h), (-w1 / 2, l1 / 2 - 0.1, h)]
	v = [bm.verts.new(c) for c in lo + hi]
	faces = [((0, 3, 2, 1), 0), ((4, 5, 6, 7), 0), ((0, 1, 5, 4), 1), ((1, 2, 6, 5), 1), ((2, 3, 7, 6), 1), ((3, 0, 4, 7), 1)]
	for idx, mat in faces:
		f = bm.faces.new([v[i] for i in idx])
		f.material_index = mat
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	mesh.materials.append(palette.get_material(color))
	mesh.materials.append(palette.get_material("sky"))
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	# стойки по рёбрам кабины — цвет кузова
	posts = [obj]
	for i in range(4):
		a, b = lo[i], hi[i]
		mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, h / 2)
		d = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
		length = (d[0] ** 2 + d[1] ** 2 + d[2] ** 2) ** 0.5
		post = lib.rounded_box(f"{name}_post{i}", (0.07, 0.07, length), bevel=0.0, segments=1, material=color)
		post.rotation_euler = (math.atan2(-d[1], d[2]), math.atan2(d[0], (d[1] ** 2 + d[2] ** 2) ** 0.5), 0)
		post.location = mid
		posts.append(post)
	return posts


def car(color):
	body = lib.rounded_box("car", (1.7, 3.6, 0.5), bevel=0.12, segments=3, material=color)
	body.location.z = 0.58
	parts = [body]
	for o in cabin("car_cabin", 1.55, 1.9, 1.3, 1.2, 0.5, color):
		o.location = (o.location[0], o.location[1] - 0.15, o.location[2] + 0.82)
		parts.append(o)
	for i, (x, y) in enumerate(((-0.82, 1.15), (0.82, 1.15), (-0.82, -1.15), (0.82, -1.15))):
		tire = lib.cylinder(f"car_wheel{i}", radius=0.32, depth=0.24, segments=14, material="ink")
		tire.rotation_euler = (0, math.pi / 2, 0)
		tire.location = (x, y, 0.32)
		hub = lib.cylinder(f"car_hub{i}", radius=0.15, depth=0.26, segments=10, material="cream")
		hub.rotation_euler = (0, math.pi / 2, 0)
		hub.location = (x, y, 0.32)
		parts += [tire, hub]
	for i, x in enumerate((-0.55, 0.55)):
		hl = lib.sphere(f"car_light{i}", 0.12, material="cream", segments=8, rings=6)
		hl.scale = (1.0, 0.4, 0.7)
		hl.location = (x, 1.79, 0.65)
		tl = lib.rounded_box(f"car_tail{i}", (0.3, 0.05, 0.12), bevel=0.02, segments=1, material="coral")
		tl.location = (x, -1.81, 0.68)
		parts += [hl, tl]
	for i, y in enumerate((1.83, -1.83)):
		b = lib.rounded_box(f"car_bumper{i}", (1.74, 0.12, 0.16), bevel=0.05, segments=2, material="asphalt")
		b.location = (0, y, 0.42)
		parts.append(b)
	for i, x in enumerate((-0.84, 0.84)):
		m = lib.rounded_box(f"car_mirror{i}", (0.14, 0.08, 0.1), bevel=0.02, segments=1, material=color)
		m.location = (x, 0.55, 0.98)
		parts.append(m)
	return lib.group(parts)

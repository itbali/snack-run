"""Листва (план 16): пышный куст из комковатых шапок — общий для bush и bush_flowers."""
import bpy

import lib
import palette

BUSH_LUMPS = ((0.0, 0.0, 0.42, 0.4), (0.38, 0.12, 0.32, 0.3), (-0.34, -0.16, 0.3, 0.3), (0.1, -0.38, 0.3, 0.28),
	(-0.12, 0.36, 0.33, 0.28), (0.18, 0.05, 0.68, 0.24))


def bush(name):
	parts = []
	for i, (x, y, z, r) in enumerate(BUSH_LUMPS):
		c = lib.lumpy(name if i == 0 else f"{name}_{i}", r, material="leaf" if i % 2 == 0 else "olive", seed=31 + i, segments=8, rings=6)
		c.location = (x, y, z)
		parts.append(c)
	return parts


def grass_blades(name, count=11, seed=7, height=0.28):
	"""Пучок травы (план 18): плоские изогнутые травинки, растут из кольца и расходятся наружу — не конусы к центру.
	Двусторонние (материал без отсечения граней), два оттенка."""
	import math
	import random
	import bmesh
	rnd = random.Random(seed)
	bm = bmesh.new()
	mats = []
	for i in range(count):
		a = i * 2 * math.pi / count + rnd.uniform(-0.25, 0.25)
		h = height * rnd.uniform(0.65, 1.15)
		lean = rnd.uniform(0.35, 0.75)       # насколько наклонена наружу
		r0 = rnd.uniform(0.0, 0.05)
		w = rnd.uniform(0.022, 0.032)
		dx, dy = math.cos(a), math.sin(a)
		px, py = -dy, dx                      # поперёк травинки
		ring = []
		segs = 3
		for k in range(segs + 1):
			t = k / segs
			out = r0 + lean * h * t * t       # изгиб: чем выше, тем сильнее наружу
			z = h * t
			half = w * (1.0 - t * 0.85)
			cx, cy = dx * out, dy * out
			ring.append((bm.verts.new((cx - px * half, cy - py * half, z)), bm.verts.new((cx + px * half, cy + py * half, z))))
		for k in range(segs):
			f = bm.faces.new((ring[k][0], ring[k][1], ring[k + 1][1], ring[k + 1][0]))
			f.material_index = i % 2
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	for key in ("leaf", "olive"):
		m = palette.get_material(key)
		m.use_backface_culling = False
		mesh.materials.append(m)
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	return obj

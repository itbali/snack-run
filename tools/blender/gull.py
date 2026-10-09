"""Чайка (план 14): CC0-голубь mujtaba-io с его клипами flap/idle, перекрашенный под чайку и крупнее (длина 0,5 м).
Готовой CC0-чайки с клипами не нашлось (BlendSwap 7419 — риг без клипов), а голубь уже в проекте — правило владельца:
готовые анимации раньше генерации."""
import bpy
from mathutils import Vector

import palette
import pigeon

TARGET_LENGTH = 0.5


def build():
	arm, mesh = pigeon.build()
	m = mesh.matrix_world
	zs = [(m @ v.co).z for v in mesh.data.vertices]
	lo, hi = min(zs), max(zs)
	mesh.data.materials.clear()
	for key in ("cream", "asphalt", "rarity_legendary"):
		mesh.data.materials.append(palette.get_material(key))
	for p in mesh.data.polygons:
		z = (m @ p.center).z
		if z < lo + (hi - lo) * 0.18:
			p.material_index = 2                     # жёлтые лапы
		elif z > lo + (hi - lo) * 0.62:
			p.material_index = 1                     # серая спина и крылья
		else:
			p.material_index = 0                     # белая грудка
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	length = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3))
	k = TARGET_LENGTH / length
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = "GullRig"
	mesh.name = "gull"
	return [arm, mesh]

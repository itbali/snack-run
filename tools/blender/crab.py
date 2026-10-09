"""Краб из CC0 methodical pixel: корпус кирпичный, клешни коралловые; ширина 0,4 м; клипы idle, walk (план 14)."""
import os

import bpy
from mathutils import Vector

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLEND = os.path.join(ROOT, "third_party", "crab_methodicalpixel", "crab.blend")
ACTIONS = ("idle", "walk")
TARGET_WIDTH = 0.4


def build():
	bpy.ops.wm.open_mainfile(filepath=BLEND)
	arm = bpy.data.objects["rig crab"]
	mesh = bpy.data.objects["crab"]
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)
	for a in list(bpy.data.actions):
		if a.name in ACTIONS:
			rig_utils.clean_action(a, arm)
		else:
			bpy.data.actions.remove(a)
	bpy.context.view_layer.update()
	m = mesh.matrix_world
	ys = [(m @ v.co).y for v in mesh.data.vertices]
	front = min(ys) + (max(ys) - min(ys)) * 0.3
	mesh.data.materials.clear()
	for key in ("brick", "coral", "ink"):
		mesh.data.materials.append(palette.get_material(key))
	for p in mesh.data.polygons:
		c = m @ p.center
		p.material_index = 1 if c.y < front else 0   # клешни спереди (−Y) коралловые
	arm.animation_data_create()
	arm.animation_data.action = None
	rig_utils.face_forward(arm, root_bone="body", head_bone="left arm 1.2")   # передом — клешни
	bpy.context.view_layer.update()
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	width = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(2))
	k = TARGET_WIDTH / width
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = "CrabRig"
	mesh.name = "crab"
	return [arm, mesh]

"""Голубь из CC0 mujtaba-io: серый корпус, бирюзовая шея, коралловые лапы; длина 0,3 м; клипы flap, idle."""
import os

import bpy
from mathutils import Vector

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLEND = os.path.join(ROOT, "third_party", "pigeon_mujtaba", "pigeon.blend")
ACTIONS = {"flap-wings-animation": "flap", "idle-animation": "idle"}
TARGET_LENGTH = 0.3


def build():
	bpy.ops.wm.open_mainfile(filepath=BLEND)
	arm = bpy.data.objects["pigeon-armature"]
	mesh = bpy.data.objects["pigeon-model"]
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)
	for a in list(bpy.data.actions):
		if a.name in ACTIONS:
			a.name = ACTIONS[a.name]
			rig_utils.clean_action(a, arm)
		else:
			bpy.data.actions.remove(a)
	bpy.context.view_layer.update()
	m = mesh.matrix_world
	zs = [(m @ v.co).z for v in mesh.data.vertices]
	lo, hi = min(zs), max(zs)
	mesh.data.materials.clear()
	for key in ("asphalt", "sea_light", "coral"):
		mesh.data.materials.append(palette.get_material(key))
	head = arm.matrix_world @ arm.data.bones["neck-bone"].head_local
	for p in mesh.data.polygons:
		c = m @ p.center
		if c.z < lo + (hi - lo) * 0.18:
			p.material_index = 2                     # лапы
		elif (c - head).length < (hi - lo) * 0.22:
			p.material_index = 1                     # шея
		else:
			p.material_index = 0
	arm.animation_data_create()
	arm.animation_data.action = None
	rig_utils.face_forward(arm, root_bone="thorax-bone", head_bone="face-bone")
	bpy.context.view_layer.update()
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	length = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3))
	k = TARGET_LENGTH / length
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = "PigeonRig"
	mesh.name = "pigeon"
	return [arm, mesh]

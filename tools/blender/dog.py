"""Собака из Quaternius Dog.blend: рыжая с белой грудкой, 0,55 м, клипы idle/walk, кость head."""
import os

import bpy
from mathutils import Matrix

import lib
import rig_inspect
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Dog.blend")
TARGET_LENGTH = 0.55
ACTION_MAP = {"Idle": "idle", "Walking": "walk"}


def build():
	bpy.ops.wm.open_mainfile(filepath=SOURCE)
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH")
	if mesh.parent is not arm:
		mesh.parent = arm
	# Запекаем поворот меша и обратную матрицу родителя в вершины: меш оказывается в пространстве
	# арматуры с единичной матрицей (как у кота), иначе экспортёр glTF теряет масштаб арматуры.
	mesh.data.transform(mesh.matrix_parent_inverse @ mesh.matrix_basis)
	mesh.matrix_parent_inverse = Matrix.Identity(4)
	mesh.matrix_basis = Matrix.Identity(4)
	# Арматура в Dog.blend имеет масштаб 1,215 и смещение; сбрасываем её трансформацию в единичную
	# (кости и меш остаются согласованы в пространстве арматуры), как у Cat.blend.
	arm.matrix_world = Matrix.Identity(4)
	bpy.context.view_layer.update()
	head = rig_inspect.find_head_bone(arm, mesh)
	arm.data.bones[head].name = "head"
	for old, new in ACTION_MAP.items():
		act = bpy.data.actions[old]
		act.name = new
		rig_utils.clean_action(act, arm)
	rig_utils.split_material_by_height(mesh, "cat_orange", "cream", 0.35)
	arm.animation_data_create()
	arm.animation_data.action = None
	for pb in arm.pose.bones:
		pb.rotation_mode = "QUATERNION"
	rig_utils.face_forward(arm)
	bpy.context.view_layer.update()
	factor = TARGET_LENGTH / lib.world_extent(mesh)
	arm.scale = (arm.scale.x * factor, arm.scale.y * factor, arm.scale.z * factor)
	arm.name = "DogRig"
	mesh.name = "dog"
	return [arm, mesh]

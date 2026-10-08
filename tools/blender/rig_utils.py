"""Общие операции над ригами Quaternius: каналы action, разворот, раскраска по высоте."""
import math

import bpy

import palette


def action_fcurves(action):
	out = []
	for layer in action.layers:
		for strip in layer.strips:
			for cb in strip.channelbags:
				out.extend((cb, fc) for fc in cb.fcurves)
	return out


def bone_of(fc):
	return fc.data_path.split('"')[1] if 'pose.bones["' in fc.data_path else None


def clean_action(action, arm, rename=None):
	"""Переименовывает кости в каналах и выкидывает каналы несуществующих костей."""
	names = {b.name for b in arm.data.bones}
	for cb, fc in action_fcurves(action):
		bone = bone_of(fc)
		if bone and rename and bone in rename:
			fc.data_path = fc.data_path.replace(f'pose.bones["{bone}"]', f'pose.bones["{rename[bone]}"]')
			bone = rename[bone]
		if bone and bone not in names:
			cb.fcurves.remove(fc)
	action.use_fake_user = True


def face_forward(arm, root_bone="Bone", head_bone="head"):
	"""Поворачивает арматуру так, чтобы вектор таз→голова смотрел по +Y Blender (= -Z Godot)."""
	arm.rotation_mode = "XYZ"
	hips = arm.data.bones[root_bone].head_local
	head = arm.data.bones[head_bone].head_local
	d = arm.matrix_world.to_3x3() @ (head - hips)
	arm.rotation_euler.z += math.pi / 2 - math.atan2(d.y, d.x)
	bpy.context.view_layer.update()
	d2 = arm.matrix_world.to_3x3() @ (head - hips)
	print(f"СМОТРИТ: ({d2.x:.2f}, {d2.y:.2f}, {d2.z:.2f}), ожидается +Y")


def split_material_by_height(mesh, top_key, bottom_key, fraction=0.35):
	"""Грани ниже fraction высоты меша получают bottom_key (белая грудка и лапы), остальные top_key.
	Высота считается в мировых координатах: у Dog.blend меш повёрнут относительно арматуры,
	и локальная ось Z меша — это длина, а не высота."""
	bpy.context.view_layer.update()
	m = mesh.matrix_world
	zs = [(m @ v.co).z for v in mesh.data.vertices]
	threshold = min(zs) + (max(zs) - min(zs)) * fraction
	mesh.data.materials.clear()
	mesh.data.materials.append(palette.get_material(top_key))
	mesh.data.materials.append(palette.get_material(bottom_key))
	for poly in mesh.data.polygons:
		poly.material_index = 1 if (m @ poly.center).z < threshold else 0

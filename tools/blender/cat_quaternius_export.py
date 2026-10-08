"""Промежуточный экспорт кота прямо из Quaternius Cat.blend (без UniMate): масштаб 0,35 м,
палитра, кость head, клипы idle/walk. Нужен один раз как вход для rig_preprocess UniMate
(docs/replay/02-procedure.md, шаг 5.3). Итоговый кот собирается cat.py.
Запуск: blender -b --python-exit-code 1 --python tools/blender/cat_quaternius_export.py -- out.glb"""
import os

import os as _os
import sys as _sys
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))

import bpy  # noqa: E402

import palette  # noqa: E402
import rig_inspect  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Cat.blend")
TARGET_LENGTH = 0.35      # метров, спек 2.1 и карта (25–30 см тело + хвост)
# Исходник смотрит по +X Blender; поворот на +90° вокруг Z даёт +Y Blender = -Z Godot (вперёд).
FACING_FIX_DEG = 90
MATERIAL_MAP = {"Grey": "cat_orange", "White": "cream", "Pink": "coral"}
ACTION_MAP = {"Idle": "idle", "Walking": "walk"}


def load_source():
	bpy.ops.wm.open_mainfile(filepath=SOURCE)
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH")
	return arm, mesh


def recolor(mesh):
	for i, m in enumerate(mesh.data.materials):
		key = MATERIAL_MAP.get(m.name if m else "", "cat_orange")
		mesh.data.materials[i] = palette.get_material(key)


def rename_actions():
	for a in bpy.data.actions:
		if a.name in ACTION_MAP:
			a.name = ACTION_MAP[a.name]
	for a in bpy.data.actions:
		a.use_fake_user = True


def rescale(arm, mesh):
	length = max(mesh.dimensions)
	factor = TARGET_LENGTH / length
	# Масштабируем арматуру (меш её дочерний), не применяя: применение ломает
	# location-каналы анимаций. glTF-экспортёр запишет масштаб узла.
	arm.scale = (factor, factor, factor)
	arm.rotation_euler.z += FACING_FIX_DEG * 3.141592653589793 / 180.0


def name_head(arm, mesh):
	head = rig_inspect.find_head_bone(arm, mesh)
	arm.data.bones[head].name = "head"


def build():
	arm, mesh = load_source()
	if mesh.parent is not arm:
		mesh.parent = arm
	recolor(mesh)
	rename_actions()
	name_head(arm, mesh)
	rescale(arm, mesh)
	arm.name = "CatRig"
	mesh.name = "cat"
	return [arm, mesh]


if __name__ == "__main__":
	import sys

	import export

	out = sys.argv[sys.argv.index("--") + 1]
	objs = build()
	export.export_glb(out, objs, animations=True)
	print("ОК", out)

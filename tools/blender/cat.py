"""Готовит кота: канонический риг UniMate + клипы (idle/walk из Quaternius, остальные из UniMate),
палитра, масштаб 0,35 м, разворот мордой по -Z Godot."""
import math
import os

import bpy

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLIPS_DIR = os.path.join(ROOT, "third_party", "unimate_clips")
CANONICAL = os.path.join(CLIPS_DIR, "cat_canonical.glb")
SOURCE_BLEND = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Cat.blend")
TARGET_LENGTH = 0.35      # метров, спек 2.1
MATERIAL_MAP = {"Grey": "cat_orange", "White": "cream", "Pink": "coral"}
SOURCE_ACTIONS = {"Idle": "idle", "Walking": "walk"}        # из Cat.blend
GENERATED_CLIPS = ["jump", "hide", "hit", "run"]             # из UniMate, файл <имя>.glb
IN_PLACE_CLIPS = {"run"}                                       # убрать перемещение корня: движет CharacterBody3D
ROOT_BONE = "Bone"
HEAD_SOURCE_BONE = "Bone.003"                                 # имя головы в Cat.blend


def _fcurves(action):
	out = []
	for layer in action.layers:
		for strip in layer.strips:
			for cb in strip.channelbags:
				out.extend((cb, fc) for fc in cb.fcurves)
	return out


def _bone_of(fc):
	return fc.data_path.split('"')[1] if 'pose.bones["' in fc.data_path else None


def load_canonical():
	bpy.ops.wm.read_homefile(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=CANONICAL)
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH" and o.parent is arm)
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)   # форма костей (Icosphere) от импортёра
	return arm, mesh


def _clean_action(action, arm, rename=None):
	"""Переименовывает кости в каналах и выкидывает каналы несуществующих костей."""
	names = {b.name for b in arm.data.bones}
	for cb, fc in _fcurves(action):
		bone = _bone_of(fc)
		if bone and rename and bone in rename:
			fc.data_path = fc.data_path.replace(f'pose.bones["{bone}"]', f'pose.bones["{rename[bone]}"]')
			bone = rename[bone]
		if bone and bone not in names:
			cb.fcurves.remove(fc)
	action.use_fake_user = True


def _strip_root_location(action):
	for cb, fc in _fcurves(action):
		if _bone_of(fc) == ROOT_BONE and fc.data_path.endswith("location"):
			cb.fcurves.remove(fc)


def add_source_actions(arm):
	with bpy.data.libraries.load(SOURCE_BLEND, link=False) as (src, dst):
		dst.actions = [a for a in src.actions if a in SOURCE_ACTIONS]
	for old, new in SOURCE_ACTIONS.items():
		act = bpy.data.actions[old]
		act.name = new
		_clean_action(act, arm, rename={HEAD_SOURCE_BONE: "head"})


def add_generated_clips(arm, mesh):
	for name in GENERATED_CLIPS:
		path = os.path.join(CLIPS_DIR, f"{name}.glb")
		if not os.path.exists(path):
			print(f"ПРЕДУПРЕЖДЕНИЕ: нет клипа {path}")
			continue
		before = set(bpy.data.actions)
		keep = set(bpy.data.objects)
		bpy.ops.import_scene.gltf(filepath=path)
		new_actions = [a for a in bpy.data.actions if a not in before]
		for o in list(bpy.data.objects):
			if o not in keep:
				bpy.data.objects.remove(o)
		if not new_actions:
			raise RuntimeError(f"в {path} нет анимации")
		act = new_actions[0]
		act.name = name
		_clean_action(act, arm)
		if name in IN_PLACE_CLIPS:
			_strip_root_location(act)
		for extra in new_actions[1:]:
			bpy.data.actions.remove(extra)


def recolor(mesh):
	for i, m in enumerate(mesh.data.materials):
		raw = (m.name if m else "").replace(palette.MATERIAL_PREFIX, "")
		key = MATERIAL_MAP.get(raw, raw if raw in palette.PALETTE else "cat_orange")
		mesh.data.materials[i] = palette.get_material(key)


def rescale(arm, mesh):
	bpy.context.view_layer.update()
	factor = TARGET_LENGTH / max(mesh.dimensions)
	arm.scale = (arm.scale.x * factor, arm.scale.y * factor, arm.scale.z * factor)


def build():
	arm, mesh = load_canonical()
	add_source_actions(arm)
	add_generated_clips(arm, mesh)
	arm.animation_data_create()
	arm.animation_data.action = None   # активный action экспортёр в режиме ACTIONS теряет
	for pb in arm.pose.bones:
		pb.rotation_mode = "QUATERNION"
	recolor(mesh)
	rig_utils.face_forward(arm)
	rescale(arm, mesh)
	arm.name = "CatRig"
	mesh.name = "cat"
	return [arm, mesh]

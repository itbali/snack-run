"""Люди парка (садовник, ребёнок, сторож) из CC0 Quaternius «Animated Human».
Текстура модели — палитра-полоски: каждая грань получает материал палитры по цвету текстуры под её UV
(кожа, волосы, штаны, рубашка) и по роли персонажа. Клипы: idle, walk, run, work."""
import math
import os

import bpy
from mathutils import Matrix, Vector

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "third_party", "quaternius_animated_human")
BLEND = os.path.join(SRC, "AnimatedHuman.blend")
TEXTURE = os.path.join(SRC, "ClothedLightSkin2.png")
ACTIONS = {"Idle": "idle", "Walk": "walk", "Run": "run", "Working": "work"}
# цвет полосы текстуры -> класс
CLASSES = {(255, 209, 159): "skin", (41, 41, 41): "hair", (200, 148, 89): "pants", (100, 215, 105): "shirt"}
ROLES = {
	"gardener": {"height": 1.7, "skin": "cream", "hair": "brick", "pants": "olive", "shirt": "leaf"},
	"kid": {"height": 1.1, "skin": "cream", "hair": "cat_orange", "pants": "sky", "shirt": "rarity_legendary"},
	"guard": {"height": 1.7, "skin": "cream", "hair": "ink", "pants": "ink", "shirt": "sea_deep"},
	"fisher": {"height": 1.7, "skin": "cream", "hair": "sand", "pants": "sky", "shirt": "cat_orange"},   # панама и жилет (план 15)
}


def _classify(mesh):
	img = bpy.data.images.load(TEXTURE)
	w, h = img.size
	px = list(img.pixels)
	uv = mesh.data.uv_layers.active.data
	out = []
	for p in mesh.data.polygons:
		u = sum(uv[l].uv[0] for l in p.loop_indices) / len(p.loop_indices)
		v = sum(uv[l].uv[1] for l in p.loop_indices) / len(p.loop_indices)
		x = min(w - 1, max(0, int(u * w)))
		y = min(h - 1, max(0, int(v * h)))
		i = (y * w + x) * 4
		c = tuple(round(k * 255) for k in px[i:i + 3])
		best = min(CLASSES, key=lambda ref: sum((a - b) ** 2 for a, b in zip(ref, c)))
		out.append(CLASSES[best])
	return out


def _recolor(mesh, role):
	classes = _classify(mesh)
	keys = ["skin", "hair", "pants", "shirt"]
	mesh.data.materials.clear()
	for k in keys:
		mesh.data.materials.append(palette.get_material(ROLES[role][k]))
	for p, c in zip(mesh.data.polygons, classes):
		p.material_index = keys.index(c)


def forward_vector(arm):
	"""Направление носков в позе клипа walk (кадр 0), мировые координаты. Поза покоя не годится:
	клипы поворачивают таз относительно покоя, и по покою модель в игре смотрела вбок."""
	arm.animation_data_create()
	arm.animation_data.action = bpy.data.actions["walk"]
	bpy.context.scene.frame_set(0)
	bpy.context.view_layer.update()
	d = Vector((0.0, 0.0, 0.0))
	for side in ("Left", "Right"):
		foot = arm.matrix_world @ arm.pose.bones[side + "Foot"].head
		toe = arm.matrix_world @ arm.pose.bones[side + "ToeBase"].head
		d += toe - foot
	arm.animation_data.action = None
	bpy.context.view_layer.update()
	return d


def _face_forward(arm):
	"""Разворачиваем так, чтобы носки (в позе ходьбы) смотрели по +Y Blender (= −Z Godot)."""
	arm.rotation_mode = "XYZ"
	d = forward_vector(arm)
	arm.rotation_euler.z += math.pi / 2 - math.atan2(d.y, d.x)
	bpy.context.view_layer.update()


def build(role):
	bpy.ops.wm.open_mainfile(filepath=BLEND)
	arm = bpy.data.objects["Human Armature"]
	mesh = bpy.data.objects["Human_Mesh"]
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)
	for a in list(bpy.data.actions):
		if a.name in ACTIONS:
			a.name = ACTIONS[a.name]
			rig_utils.clean_action(a, arm)
		else:
			bpy.data.actions.remove(a)
	_recolor(mesh, role)
	arm.animation_data_create()
	arm.animation_data.action = None
	_face_forward(arm)
	bpy.context.view_layer.update()
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	height = max(c.z for c in corners) - min(c.z for c in corners)
	k = ROLES[role]["height"] / height
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = f"{role.capitalize()}Rig"
	mesh.name = role
	return [arm, mesh]

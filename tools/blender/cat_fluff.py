"""Пучки шерсти, усы и ошейник кота (спек 2.8): отдельные меши, скинятся к ближайшей кости весом 1,0.
Координаты считаются от bbox вершин соответствующей кости, как у глаз."""
import math

import bpy
from mathutils import Vector

import cat_eyes
import lib

SPHERE = {"segments": 8, "rings": 6}
CREAM = "cream"


def _oriented(obj, direction):
	"""Поворачивает объект так, чтобы его ось Z (ось цилиндра/конуса) смотрела вдоль direction."""
	obj.rotation_mode = "QUATERNION"
	obj.rotation_quaternion = Vector(direction).normalized().to_track_quat("Z", "Y")


def _cheeks(lo, hi):
	parts = []
	for side in (-1.0, 1.0):
		edge = hi.x if side > 0 else lo.x
		base = Vector((edge * 0.92, hi.y - 0.03, lo.z + 0.35 * (hi.z - lo.z)))
		for i, tilt in enumerate((-0.35, 0.0, 0.35)):
			c = lib.cone(f"cheek_{'r' if side > 0 else 'l'}{i}", radius=0.005, depth=0.014, segments=6, material=CREAM)
			d = Vector((side * 0.8, -1.4, -0.3 + tilt))   # назад и чуть вниз: пух на щеке, а не шип вперёд
			_oriented(c, d)
			c.location = base + d.normalized() * 0.004 + Vector((0.0, -0.004, tilt * 0.012))
			parts.append(c)
	return parts


def _chest(mesh):
	lo, hi = cat_eyes.group_bbox(mesh, "Bone.001")
	s = lib.sphere("chest", 0.028, material=CREAM, **SPHERE)
	s.scale = (1.0, 0.6, 0.8)
	s.location = Vector((0.0, hi.y - 0.012, lo.z + 0.25 * (hi.z - lo.z)))
	return [s]


def _tail_tip(mesh):
	lo, hi = cat_eyes.group_bbox(mesh, "Bone.007")
	s = lib.sphere("tail_tip", 0.018, material=CREAM, **SPHERE)
	s.location = (lo + hi) / 2.0
	return [s]


def _whiskers(lo, hi):
	parts = []
	w = hi.x - lo.x
	for side in (-1.0, 1.0):
		origin = Vector((side * w * 0.3, hi.y - 0.012, lo.z + 0.3 * (hi.z - lo.z)))
		for i, k in enumerate((0.15, 0.0, -0.15)):
			d = Vector((side, 0.3, k)).normalized()
			c = lib.cylinder(f"whisker_{'r' if side > 0 else 'l'}{i}", radius=0.0008, depth=0.035, segments=4, material="eye_white")
			_oriented(c, d)
			c.location = origin + d * 0.0175
			parts.append(c)
	return parts


def _collar(arm, mesh):
	lo, hi = cat_eyes.group_bbox(mesh, "Bone.002")
	pb = arm.pose.bones["Bone.002"]
	bpy.context.view_layer.update()
	head = arm.matrix_world @ pb.head
	tail = arm.matrix_world @ pb.tail
	axis = (tail - head).normalized()
	major = (hi.x - lo.x) / 2.0 * 1.15
	ring = lib.torus("collar_ring", major=major, minor=0.006, material="coral")
	_oriented(ring, axis)
	ring.location = tail - axis * 0.014   # кость шеи начинается у плеч: ошейник — у её конца, под головой
	tag = lib.cylinder("collar_tag", radius=0.012, depth=0.004, segments=10, material="rarity_legendary")
	tag.rotation_euler = (math.pi / 2, 0.0, 0.0)   # плоский диск лицом вперёд
	tag.location = ring.location + Vector((0.0, 0.004, -major))
	return [ring, tag]


def build_fluff(arm, mesh):
	"""Пять объектов, дети арматуры. Звать после face_forward и rescale."""
	lo, hi = cat_eyes.head_bbox(mesh)
	out = []
	for name, parts, bone in (
		("fluff_cheeks", _cheeks(lo, hi), "head"),
		("fluff_chest", _chest(mesh), "Bone.001"),
		("fluff_tail", _tail_tip(mesh), "Bone.007"),
		("whiskers", _whiskers(lo, hi), "head"),
		("collar", _collar(arm, mesh), "Bone.002"),
	):
		obj = cat_eyes._join(name, parts)
		cat_eyes._attach(obj, arm, bone)
		out.append(obj)
	return out

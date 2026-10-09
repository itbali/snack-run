"""Плющ: полоса 2 × 1 м из листьев-квадов в плоскости XZ Blender (= XY Godot, лицом по ±Z).
Висит на стене; в Godot материал двусторонний (solid: false в раскладке)."""
import math
import random

import bmesh
import bpy

import palette

SPEC = {"max_tris": 120, "max_dim": 2.5}


def build():
	rnd = random.Random(3)
	bm = bmesh.new()
	for i in range(26):   # два ряда внахлёст: листва, а не конфетти
		x = -0.95 + (i % 13) * 0.158 + rnd.uniform(-0.03, 0.03)
		z = 0.2 + (i // 13) * 0.42 + (i % 2) * 0.12 + rnd.uniform(-0.05, 0.05)
		s = rnd.uniform(0.17, 0.24)
		rot = rnd.uniform(-0.5, 0.5)
		verts = []
		for dx, dz in ((-s, -s), (s, -s), (s, s), (-s, s)):
			rx = dx * math.cos(rot) - dz * math.sin(rot)
			rz = dx * math.sin(rot) + dz * math.cos(rot)
			verts.append(bm.verts.new((x + rx, 0.0, z + rz)))
		f = bm.faces.new(verts)
		f.material_index = i % 2
	mesh = bpy.data.meshes.new("ivy")
	bm.to_mesh(mesh)
	bm.free()
	mesh.materials.append(palette.get_material("leaf"))
	mesh.materials.append(palette.get_material("olive"))
	obj = bpy.data.objects.new("ivy", mesh)
	bpy.context.scene.collection.objects.link(obj)
	bpy.context.view_layer.update()
	return [obj]

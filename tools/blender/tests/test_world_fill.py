"""План 16: кроны и кусты не шары, дома — замкнутые объёмы, украшения — один меш (для MultiMesh)."""
import importlib
import math
import unittest

import bpy

import lib


def _build(name):
	lib.clear_scene()
	mod = importlib.import_module(f"gen.{name}")
	importlib.reload(mod)
	return mod.build()


class TestFoliage(unittest.TestCase):
	def test_lumpy_is_not_a_sphere(self):
		lib.clear_scene()
		o = lib.lumpy("l", 1.0, seed=3)
		rs = [v.co.length for v in o.data.vertices]
		self.assertGreater(max(rs) - min(rs), 0.2, "радиусы вершин разные — не шар")
		o2 = lib.lumpy("l2", 1.0, seed=3)
		self.assertEqual([round(v.co.length, 5) for v in o.data.vertices], [round(v.co.length, 5) for v in o2.data.vertices], "детерминированно")

	def test_tree_crown_is_many_lumps(self):
		objs = _build("tree")
		crowns = [o for o in objs if o.name.startswith("tree_crown")]
		self.assertGreaterEqual(len(crowns), 5)

	def test_bush_is_many_lumps(self):
		objs = _build("bush")
		self.assertGreaterEqual(len(objs), 5)


class TestHouses(unittest.TestCase):
	def test_house_is_closed_box_behind_facade(self):
		for name, floors, depth in (("house_a", 2, 6.0), ("house_b", 3, 6.0), ("house_shallow", 1, 1.8)):
			objs = _build(name)
			body = next(o for o in objs if o.name == "wall")
			bpy.context.view_layer.update()
			self.assertAlmostEqual(body.dimensions.x, 6.0, 1, name)
			self.assertAlmostEqual(body.dimensions.y, depth, 1, name)
			self.assertAlmostEqual(body.dimensions.z, floors * 3.1, 1, name)
			ys = [(body.matrix_world @ v.co).y for v in body.data.vertices]
			self.assertAlmostEqual(min(ys), -0.2, 1, f"{name}: фасад в плоскости прежней стены")
			self.assertTrue(any(o.name.startswith("wall_glass") for o in objs), f"{name}: окна (ночью светятся)")
			self.assertTrue(any(o.name.startswith("house_roof") or o.name.startswith("house_cap") for o in objs), f"{name}: крыша")


class TestDecor(unittest.TestCase):
	def test_decor_models_are_single_mesh(self):
		for name in ("decor_grass", "decor_flowers", "decor_stones", "decor_leaves", "decor_litter", "decor_shell", "decor_reeds"):
			objs = _build(name)
			self.assertEqual(len(objs), 1, name)
			self.assertEqual(objs[0].type, "MESH")

import unittest

import bpy
from mathutils import Vector

import human
import lib
import pigeon


def _actions():
    return {a.name for a in bpy.data.actions}


def _height(mesh):
    bpy.context.view_layer.update()
    c = [mesh.matrix_world @ Vector(x) for x in mesh.bound_box]
    return max(v.z for v in c) - min(v.z for v in c)


class TestParkPeople(unittest.TestCase):
    def test_roles_have_palette_colors_clips_and_height(self):
        for role, shirt in (("gardener", "sr_leaf"), ("kid", "sr_rarity_legendary"), ("guard", "sr_sea_deep")):
            lib.clear_scene()
            objs = human.build(role)
            mesh = objs[1]
            mats = [m.name for m in mesh.data.materials]
            self.assertIn(shirt, mats, role)
            self.assertIn("sr_cream", mats, f"{role}: кожа")
            used = {mesh.data.materials[p.material_index].name for p in mesh.data.polygons}
            self.assertGreaterEqual(len(used), 3, f"{role}: грани разнесены по ролям текстуры")
            self.assertTrue({"idle", "walk", "run", "work"} <= _actions(), role)
            self.assertAlmostEqual(_height(mesh), human.ROLES[role]["height"], delta=0.05)
            self.assertEqual(lib.check_asset(objs, max_tris=2500, max_dim=2.0), [])

    def test_humans_face_forward(self):
        lib.clear_scene()
        objs = human.build("gardener")
        d = human.forward_vector(objs[0])   # в позе клипа walk: по позе покоя модель смотрела вбок
        self.assertGreater(d.y, abs(d.x) * 3, "носки смотрят по +Y Blender (−Z Godot)")

    def test_pigeon(self):
        lib.clear_scene()
        objs = pigeon.build()
        self.assertTrue({"flap", "idle"} <= _actions())
        mats = {m.name for m in objs[1].data.materials}
        self.assertEqual(mats, {"sr_asphalt", "sr_sea_light", "sr_coral"})
        self.assertEqual(lib.check_asset(objs, max_tris=1500, max_dim=0.35), [])

import unittest

import bpy

import cat
import cat_eyes
import cat_fluff
import lib

EXPECTED_BONES = {"fluff_cheeks": "head", "fluff_chest": "Bone.001", "fluff_tail": "Bone.007", "whiskers": "head", "collar": "Bone.002"}


class TestCatFluff(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        lib.clear_scene()
        cls.objs = cat.build()
        cls.arm, cls.mesh = cls.objs[0], cls.objs[1]
        cls.parts = {o.name: o for o in cls.objs[2:] if o.name in EXPECTED_BONES}

    def _world(self, o):
        bpy.context.view_layer.update()
        return [o.matrix_world @ v.co for v in o.data.vertices]

    def test_body_is_subdivided_and_smooth(self):
        mods = [m for m in self.mesh.modifiers if m.type == "SUBSURF"]
        self.assertEqual(len(mods), 1)
        self.assertEqual(mods[0].levels, 1)
        self.assertTrue(all(p.use_smooth for p in self.mesh.data.polygons))
        self.assertGreater(lib.tri_count(self.mesh), 2500, "после subdivision треугольников больше базовых 807")

    def test_parts_exist_and_are_skinned_to_the_right_bones(self):
        self.assertEqual(set(self.parts), set(EXPECTED_BONES))
        for name, bone in EXPECTED_BONES.items():
            o = self.parts[name]
            self.assertIs(o.parent, self.arm, name)
            self.assertEqual([m.type for m in o.modifiers], ["ARMATURE"], name)
            vg = o.vertex_groups[bone]
            self.assertTrue(all(any(g.group == vg.index and g.weight > 0.99 for g in v.groups) for v in o.data.vertices), name)

    def test_whiskers_stick_out_of_the_muzzle(self):
        lo, hi = cat_eyes.head_bbox(self.mesh)
        xs = [p.x for p in self._world(self.parts["whiskers"])]
        self.assertGreater(max(xs), hi.x + 0.015, "усы торчат вправо дальше щеки")
        self.assertLess(min(xs), lo.x - 0.015, "и влево")

    def test_collar_sits_on_the_neck(self):
        lo, hi = cat_eyes.group_bbox(self.mesh, "Bone.002")
        pts = self._world(self.parts["collar"])
        cz = sum(p.z for p in pts) / len(pts)
        self.assertTrue(lo.z - 0.02 < cz < hi.z + 0.02, f"ошейник на высоте шеи: {cz:.3f} vs {lo.z:.3f}..{hi.z:.3f}")
        mats = {m.name for m in self.parts["collar"].data.materials}
        self.assertEqual(mats, {"sr_coral", "sr_rarity_legendary"}, "коралловый ремешок и золотой жетон")

    def test_budget(self):
        self.assertEqual(lib.check_asset(self.objs, max_tris=8000, max_dim=0.6), [])

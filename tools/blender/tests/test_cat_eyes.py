import unittest

import bpy

import cat
import cat_eyes
import lib


class TestCatEyes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        lib.clear_scene()
        cls.objs = cat.build()
        cls.arm, cls.mesh = cls.objs[0], cls.objs[1]
        cls.eyes = {o.name: o for o in cls.objs[2:] if o.name.startswith("eyes_")}   # пучки и веки — не наборы

    def _world(self, o):
        bpy.context.view_layer.update()
        return [o.matrix_world @ v.co for v in o.data.vertices]

    def test_four_sets_skinned_to_head(self):
        self.assertEqual(set(self.eyes), {"eyes_normal", "eyes_scared", "eyes_happy", "eyes_dizzy", "eyes_blink"})
        for o in self.eyes.values():
            self.assertIs(o.parent, self.arm, o.name)
            self.assertEqual([m.type for m in o.modifiers], ["ARMATURE"], o.name)
            vg = o.vertex_groups["head"]
            self.assertTrue(all(any(g.group == vg.index and g.weight > 0.99 for g in v.groups) for v in o.data.vertices), o.name)
            names = {m.name for m in o.data.materials}
            self.assertFalse(names & {"sr_cat_orange", "sr_cream", "sr_coral"}, f"{o.name}: скин не должен перекрашивать глаза")

    def test_eyes_sit_on_the_front_of_the_head(self):
        lo, hi = cat_eyes.head_bbox(self.mesh)
        for o in self.eyes.values():
            pts = self._world(o)
            cy = sum(p.y for p in pts) / len(pts)
            cz = sum(p.z for p in pts) / len(pts)
            self.assertGreater(cy, hi.y - 0.03, f"{o.name}: у морды (+Y), не на затылке")
            self.assertLess(cy, hi.y + 0.03, f"{o.name}: не висят перед мордой")
            self.assertGreater(cz, lo.z + 0.5 * (hi.z - lo.z), f"{o.name}: верхняя половина головы")
            self.assertLess(cz, hi.z, o.name)
            xs = [p.x for p in pts]
            self.assertLess(min(xs), -0.005, f"{o.name}: есть левый глаз")
            self.assertGreater(max(xs), 0.005, f"{o.name}: есть правый глаз")

    def test_happy_chevrons_point_up(self):
        pts = [p for p in self._world(self.eyes["eyes_happy"]) if p.x > 0]
        cx = sum(p.x for p in pts) / len(pts)
        apex = [p.z for p in pts if abs(p.x - cx) < 0.003]
        ends = [p.z for p in pts if abs(p.x - cx) > 0.009]
        self.assertTrue(apex and ends)
        self.assertGreater(sum(apex) / len(apex), sum(ends) / len(ends), "довольные глаза «^», а не «v»")

    def test_eyes_are_sunk_into_the_head(self):
        lo, hi = cat_eyes.head_bbox(self.mesh)
        ys = [p.y for p in self._world(self.eyes["eyes_normal"])]
        self.assertLess(max(ys), hi.y + 0.004, "белок выступает из морды не больше чем на 4 мм")
        self.assertGreater(max(ys), hi.y - 0.010, "но не утоплен целиком (глаза выше носа, где морда отступает)")

    def test_normal_eyes_have_green_iris_and_no_lids(self):
        mats = {m.name for m in self.eyes["eyes_normal"].data.materials}
        self.assertTrue({"sr_eye_white", "sr_eye_green", "sr_ink"} <= mats, mats)
        self.assertFalse(any(o.name == "eyelids" for o in self.objs), "веки убраны: при утопленных глазах читались как брови")

    def test_blink_set_exists(self):
        self.assertIn("eyes_blink", self.eyes)

    def test_budget(self):
        self.assertEqual(lib.check_asset(self.objs, max_tris=8000, max_dim=0.6), [])

import unittest

import bpy

import dog
import dog_sleep
import lib


class TestDogSleep(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        lib.clear_scene()
        cls.objs = dog.build()
        cls.arm = cls.objs[0]

    def _z(self, name, tail=False):
        bpy.context.view_layer.update()
        pb = self.arm.pose.bones[name]
        return (self.arm.matrix_world @ (pb.tail if tail else pb.head)).z

    def test_sleep_action_exists_and_lasts_two_seconds(self):
        act = bpy.data.actions["sleep"]
        self.assertTrue(act.use_fake_user)
        self.assertGreaterEqual(act.frame_range[1] - act.frame_range[0], 40)
        self.assertIsNone(self.arm.animation_data.action, "активный action экспортёр теряет")

    def test_sleep_pose_lies_on_the_ground(self):
        dog_sleep.reset_pose(self.arm)
        up_root, up_head = self._z("Bone"), self._z("head")
        dog_sleep.apply_pose(self.arm)
        self.assertLess(self._z("Bone"), up_root * 0.5, "корпус опущен к земле")
        self.assertLess(self._z("head"), up_head * 0.65, "голова опущена")
        self.assertLess(self._z("head", tail=True), self._z("head"), "морда ниже затылка")
        for pb in self.arm.pose.bones:
            self.assertGreater((self.arm.matrix_world @ pb.tail).z, -0.02, f"{pb.name} под землёй")
        dog_sleep.reset_pose(self.arm)

    def test_sleep_clip_breathes(self):
        act = bpy.data.actions["sleep"]
        root_curves = [fc for layer in act.layers for strip in layer.strips for cb in strip.channelbags
                       for fc in cb.fcurves if fc.data_path == 'pose.bones["Bone"].location']
        self.assertEqual(len(root_curves), 3, "три канала location корня")
        v1 = sum(fc.evaluate(1) ** 2 for fc in root_curves) ** 0.5
        v24 = sum(fc.evaluate(24) ** 2 for fc in root_curves) ** 0.5
        self.assertGreater(abs(v1 - v24), v1 * 0.05, "на вдохе корпус выше: клип не статичный")

    def test_reset_pose_restores_rest(self):
        dog_sleep.apply_pose(self.arm)
        dog_sleep.reset_pose(self.arm)
        for pb in self.arm.pose.bones:
            self.assertAlmostEqual(pb.location.length, 0.0, places=5)
            self.assertEqual(tuple(round(c, 5) for c in pb.scale), (1.0, 1.0, 1.0))

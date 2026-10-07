import os
import tempfile
import unittest

import bpy

import export
import lib


class TestExport(unittest.TestCase):
    def test_glb_roundtrip_keeps_mesh_and_material(self):
        lib.clear_scene()
        box = lib.rounded_box("crate", (0.4, 0.4, 0.4), material="sand")
        path = os.path.join(tempfile.mkdtemp(), "crate.glb")
        export.export_glb(path, [box])
        self.assertTrue(os.path.exists(path))
        self.assertGreater(os.path.getsize(path), 1000)
        lib.clear_scene()
        bpy.ops.import_scene.gltf(filepath=path)
        meshes = [o for o in bpy.data.objects if o.type == "MESH"]
        self.assertEqual(len(meshes), 1)
        self.assertEqual(meshes[0].name, "crate")
        self.assertAlmostEqual(meshes[0].dimensions.x, 0.4, places=2)
        self.assertTrue(meshes[0].data.materials[0].name.startswith("sr_sand"))

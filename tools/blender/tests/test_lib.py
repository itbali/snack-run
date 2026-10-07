import unittest

import bpy

import lib
import palette


class TestPalette(unittest.TestCase):
    def test_palette_has_17_colors(self):
        self.assertEqual(len(palette.PALETTE), 17)

    def test_material_is_cached_and_colored(self):
        lib.clear_scene()
        m1 = palette.get_material("cat_orange")
        m2 = palette.get_material("cat_orange")
        self.assertIs(m1, m2)
        bsdf = next(n for n in m1.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        rgba = bsdf.inputs["Base Color"].default_value
        # #FAAE45 -> sRGB (0.98, 0.68, 0.27) -> linear около (0.96, 0.42, 0.06)
        self.assertAlmostEqual(rgba[0], 0.955, places=2)
        self.assertAlmostEqual(rgba[1], 0.423, places=2)
        self.assertAlmostEqual(rgba[2], 0.060, places=2)


class TestRoundedBox(unittest.TestCase):
    def test_dimensions_match(self):
        lib.clear_scene()
        o = lib.rounded_box("b", (1.0, 2.0, 3.0))
        self.assertAlmostEqual(o.dimensions.x, 1.0, places=2)
        self.assertAlmostEqual(o.dimensions.y, 2.0, places=2)
        self.assertAlmostEqual(o.dimensions.z, 3.0, places=2)

    def test_bevel_adds_triangles(self):
        lib.clear_scene()
        plain = lib.rounded_box("p", (1, 1, 1), bevel=0.0)
        rounded = lib.rounded_box("r", (1, 1, 1), bevel=0.05, segments=3)
        self.assertEqual(lib.tri_count(plain), 12)
        self.assertGreater(lib.tri_count(rounded), 100)

    def test_check_asset_reports_errors(self):
        lib.clear_scene()
        o = lib.rounded_box("big", (5, 1, 1), bevel=0.05, material="asphalt")
        errors = lib.check_asset([o], max_tris=50, max_dim=2.0)
        self.assertEqual(len(errors), 2)
        self.assertTrue(any("треугольник" in e for e in errors))
        self.assertTrue(any("габарит" in e for e in errors))

    def test_check_asset_uses_world_scale_of_parent(self):
        lib.clear_scene()
        child = lib.rounded_box("child", (5, 1, 1), bevel=0.0)
        parent = bpy.data.objects.new("parent", None)
        bpy.context.scene.collection.objects.link(parent)
        child.parent = parent
        parent.scale = (0.1, 0.1, 0.1)
        bpy.context.view_layer.update()
        self.assertAlmostEqual(lib.world_extent(child), 0.5, places=3)
        self.assertEqual(lib.check_asset([child], max_tris=50, max_dim=1.0), [])

    def test_check_asset_rejects_foreign_material(self):
        lib.clear_scene()
        o = lib.rounded_box("m", (1, 1, 1))
        o.data.materials.append(bpy.data.materials.new("Alien"))
        errors = lib.check_asset([o], max_tris=5000, max_dim=10)
        self.assertEqual(len(errors), 1)
        self.assertIn("палитр", errors[0])

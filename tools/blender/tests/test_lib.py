import unittest

import bpy

import lib
import palette


class TestPalette(unittest.TestCase):
    def test_palette_has_19_colors(self):
        self.assertEqual(len(palette.PALETTE), 19)   # 13 спека + 4 редкости + белок и радужка глаз (планы 4–5)

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


class TestPrimitives(unittest.TestCase):
    def test_cylinder_dims_and_smooth(self):
        lib.clear_scene()
        o = lib.cylinder("c", radius=0.1, depth=0.3, material="coral")
        self.assertAlmostEqual(o.dimensions.x, 0.2, places=2)
        self.assertAlmostEqual(o.dimensions.z, 0.3, places=2)
        self.assertTrue(all(p.use_smooth for p in o.data.polygons))
        self.assertGreater(lib.tri_count(o), 20)

    def test_sphere_and_cone_dims(self):
        lib.clear_scene()
        s = lib.sphere("s", radius=0.05)
        c = lib.cone("k", radius=0.05, depth=0.12)
        self.assertAlmostEqual(s.dimensions.x, 0.1, places=2)
        self.assertAlmostEqual(c.dimensions.z, 0.12, places=2)

    def test_torus_and_wedge_dims(self):
        lib.clear_scene()
        t = lib.torus("t", major=0.08, minor=0.03)
        w = lib.wedge("w", width=0.2, length=0.25, height=0.03)
        self.assertAlmostEqual(t.dimensions.x, 0.22, places=2)
        self.assertAlmostEqual(w.dimensions.y, 0.25, places=2)
        self.assertEqual(lib.tri_count(w), 8)

    def test_group_parents_parts(self):
        lib.clear_scene()
        a = lib.rounded_box("a", (1, 1, 1))
        b = lib.rounded_box("b", (1, 1, 1))
        parts = lib.group([a, b])
        self.assertIs(b.parent, a)
        self.assertEqual(parts, [a, b])

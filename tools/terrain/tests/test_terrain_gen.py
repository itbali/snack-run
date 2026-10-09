import math
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import terrain_gen as tg  # noqa: E402


def desc(**kw):
    d = {"size": [40, 40], "origin": [-20, -20], "cell": 1.0, "base": 0.0, "features": [], "paint": []}
    d.update(kw)
    return d


class TestTerrainGen(unittest.TestCase):
    def test_flat_grid_size_and_base(self):
        g = tg.build(desc(base=0.5))
        self.assertEqual((g.nx, g.nz), (41, 41))
        self.assertAlmostEqual(tg.height_at(g, 3.3, -7.1), 0.5)

    def test_hill_peak_and_gentle_slope(self):
        g = tg.build(desc(features=[{"type": "hill", "center": [0, 0], "radius": 12, "height": 3}]))
        self.assertAlmostEqual(tg.height_at(g, 0, 0), 3.0, places=3)
        self.assertAlmostEqual(tg.height_at(g, 13, 0), 0.0, places=3, msg="за радиусом ровно")
        self.assertLessEqual(tg.max_slope_deg(g), 30.0, "склон холма проходим")

    def test_basin_goes_down(self):
        g = tg.build(desc(features=[{"type": "basin", "center": [5, 5], "radius": 6, "depth": 1.2}]))
        self.assertAlmostEqual(tg.height_at(g, 5, 5), -1.2, places=3)

    def test_terrace_has_sharp_edge(self):
        g = tg.build(desc(features=[{"type": "terrace", "rect": [0, 0, 10, 10], "height": 2}]))
        self.assertAlmostEqual(tg.height_at(g, 5, 5), 2.0)
        self.assertAlmostEqual(tg.height_at(g, -1, 5), 0.0)
        self.assertGreater(tg.max_slope_deg(g), 60.0, "обрыв террасы отвесный")
        self.assertLessEqual(tg.max_slope_deg(g, skip_cliffs_above=0.6), 0.001, "кроме обрыва — ровно")

    def test_paint_rect_and_soft_circle(self):
        g = tg.build(desc(paint=[{"rect": [0, 0, 5, 5], "type": "grass"}, {"circle": [-10, -10, 3], "type": "gravel", "soft": 2}]))
        i, j = 22, 22  # x=2, z=2
        self.assertEqual(g.splat[j][i], [0, 0, 255, 0])
        self.assertEqual(g.splat[10][10][3], 255, "центр круга — гравий")
        edge = g.splat[10][13]  # x=-7: ровно на радиусе 3 → половина
        self.assertTrue(100 < edge[3] < 160, edge)

    def test_json_round_trip(self):
        g = tg.build(desc(features=[{"type": "hill", "center": [0, 0], "radius": 8, "height": 2}]))
        j = tg.to_json(g)
        self.assertEqual(len(j["heights"]), g.nz)
        import base64
        self.assertEqual(len(base64.b64decode(j["splat"])), g.nx * g.nz * 4)


if __name__ == "__main__":
    unittest.main()

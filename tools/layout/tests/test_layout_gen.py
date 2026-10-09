import json, math, random, re, sys, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "layout"))
import layout_gen as lg


class Primitives(unittest.TestCase):
	def test_perimeter_walls_face_inside_and_skip_gaps(self):
		walls = lg.perimeter([0, 0, 24, 12], gaps=[("s", 9.0, 2.0)])
		rots = {(w["pos"][0], w["pos"][2]): w["rot"] for w in walls}
		self.assertEqual(rots[(3.0, 0)], 0, "северная стена лицом на юг (+Z), как ядро при z −14")
		self.assertEqual(rots[(0, 3.0)], 90, "западная — как ядро при x −12")
		self.assertNotIn((9.0, 12), rots, "проход на юге")
		self.assertIn((15.0, 12), rots)

	def test_perimeter_side_not_multiple_of_module_has_no_slits(self):
		# Сторона 75 м: 12 модулей по 6 м встык и последний, прижатый к концу (сдвиг 5 см внутрь от мерцания).
		walls = lg.perimeter([-90, 0, -15, 30], sides="s")
		xs = sorted(w["pos"][0] for w in walls)
		self.assertEqual(len(xs), 13)
		self.assertAlmostEqual(xs[0], -87.0)
		self.assertAlmostEqual(xs[-1], -18.0)
		for a, b in zip(xs, xs[1:]):
			self.assertLessEqual(b - a, 6.0 + 1e-6, "без щелей")
		self.assertAlmostEqual(next(w for w in walls if w["pos"][0] == -18.0)["pos"][2], 29.95)

	def test_footprints_follow_explicit_colliders(self):
		# Балкон ядра: площадка на смещении z 2,55 на высоте 1,0 — пятно по коллайдерам, а не по таблице.
		core = json.loads((ROOT / "data/layout_src/yard_core.json").read_text())
		stairs = next(p for p in core["props"] if p["model"] == "stairs")
		fps = lg.footprints(stairs)
		self.assertEqual(len(fps), len(stairs["colliders"]))
		x, _, z = stairs["pos"]
		self.assertTrue(any(f[0] < x < f[2] and f[1] < z + 2.55 < f[3] and abs(f[4] - 1.0) < 0.01 for f in fps))
		bench = {"model": "bench", "pos": [0, 0, 0], "rot": 90, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}]}
		f = lg.footprints(bench)[0]
		self.assertAlmostEqual(f[3] - f[1], 1.5, 3, "rot 90 меняет оси")
		self.assertEqual(lg.footprints({"model": "grass", "pos": [0, 0, 0], "solid": False}), [])

	def test_perimeter_extra_flags_reach_every_module(self):
		col = [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]
		fences = lg.perimeter([0, 0, 4, 1], "fence", 2.0, "s", extra={"colliders": col})
		self.assertEqual(len(fences), 2)
		self.assertTrue(all(f["colliders"] == col for f in fences))
		d = {"name": "t", "terrain": DESC["terrain"], "zones": [{"name": "z", "ops": [
			{"type": "perimeter", "rect": [0, 0, 4, 1], "model": "fence", "length": 2.0, "sides": "s", "extra": {"colliders": col}}]}]}
		layout, _ = lg.generate(d)
		self.assertTrue(all(p.get("colliders") == col for p in layout["props"]))

	def test_terrace_stairs_land_on_edge_and_walls_cover_cliff(self):
		feature, props, blocked = lg.terrace([10, -20, 30, -10], 2, access=[("s", 20.0, "stairs"), ("w", -15.0, "ramp")])
		self.assertEqual(feature, {"type": "terrace", "rect": [10, -20, 30, -10], "height": 2.0})
		stairs = next(p for p in props if p["model"] == "terrace_stairs2")
		self.assertAlmostEqual(stairs["pos"][2] - lg.kit_run("stairs", 2), -10, 3, "верх лестницы на кромке плато (над ячейкой обрыва)")
		ramp = next(p for p in props if p["model"] == "ramp2")
		self.assertEqual(ramp["rot"], -90)
		walls = [p for p in props if p["model"] == "retaining_wall2"]
		self.assertTrue(all(w["snap"] is False for w in walls))
		self.assertIn([11.5, -9.5], [[w["pos"][0], w["pos"][2]] for w in walls], "стена на ячейке обрыва: кромка + 0,5")
		self.assertFalse(any(abs(w["pos"][0] - 20.0) < 1.5 and w["pos"][2] > -10 for w in walls), "проход под лестницу")
		self.assertTrue(blocked, "полосы обрыва закрыты для россыпи")

	def test_garage_row_chain_reaches_roof(self):
		row = lg.garage_row((0, 0), 3)
		fps = [lg.footprint(p) for p in row["props"]]
		reach = lg.reachable([f for f in fps if f])
		garages = [i for i, p in enumerate(row["props"]) if p["model"] == "garage"]
		self.assertTrue(all(i in reach for i in garages))
		self.assertEqual(len(row["yarn"]), 3)
		self.assertTrue(all(abs(y["pos"][1] - 2.28) < 0.01 for y in row["yarn"]))
		fed = lg.garage_row((0, 0), 2, foods=["donut"])
		self.assertTrue(all(s["foods"] == ["donut"] for s in fed["spawn_points"]), "список еды района доходит до крыш")

	def test_scatter_avoids_props_and_keeps_distance(self):
		blocked = [(4, 4, 6, 6, 1.0)]
		pts = lg.scatter(random.Random(3), [0, 0, 10, 10], 12, blocked, min_dist=1.5)
		self.assertEqual(len(pts), 12)
		for x, z in pts:
			self.assertFalse(3.6 < x < 6.4 and 3.6 < z < 6.4)
		for a in pts:
			for b in pts:
				if a is not b:
					self.assertGreaterEqual(math.dist(a, b), 1.5)

	def test_scatter_avoids_cliff_bands(self):
		_, _, blocked = lg.terrace([10, -20, 30, -10], 2)
		pts = lg.scatter(random.Random(1), [5, -25, 35, -5], 40, blocked, min_dist=1.0)
		for x, z in pts:
			near_edge = (9 <= x <= 11 or 29 <= x <= 31) and -21 <= z <= -9 or (-21 <= z <= -19 or -11 <= z <= -9) and 9 <= x <= 31
			self.assertFalse(near_edge, f"{x},{z} у обрыва")

	def test_scatter_keeps_approach_to_stairs_free(self):
		# Кадр плана 11: дерево из россыпи встало прямо у подножия лестницы верхнего двора.
		_, props, blocked = lg.terrace([10, -20, 30, -10], 2, access=[("s", 20.0, "stairs")])
		start = next(p for p in props if p["model"] == "terrace_stairs2")["pos"]
		pts = lg.scatter(random.Random(2), [10, -10, 30, 0], 60, blocked, min_dist=0.8)
		for x, z in pts:
			self.assertFalse(abs(x - 20.0) < 1.5 and start[2] <= z <= start[2] + 3.0, f"{x},{z} перед лестницей")

	def test_pond_makes_basin_water_and_shore_ring(self):
		feature, water, shore, blocked = lg.pond((-28, 62), 11, 1.5, -0.5)
		self.assertEqual(feature, {"type": "basin", "center": [-28, 62], "radius": 11, "depth": 1.5})
		self.assertEqual(water, {"pos": [-28, -0.5, 62], "size": [22, 2.0, 22]})
		self.assertEqual(len(shore), 8)
		for m in shore:
			self.assertAlmostEqual(math.dist((m["pos"][0], m["pos"][2]), (-28, 62)), 12.5, 2)
		self.assertEqual(blocked, (-40, 50, -16, 74, 0.0))

	def test_scatter_bush_hideout(self):
		d = {"name": "t", "terrain": DESC["terrain"], "zones": [{"name": "z", "ops": [
			{"type": "scatter", "what": "hideout", "kind": "bush", "rect": [-10, -10, 10, 10], "count": 2}]}]}
		layout, _ = lg.generate(d)
		self.assertEqual([p["model"] for p in layout["props"]], ["bush", "bush"])
		self.assertTrue(all(h["kind"] == "bush" and h["pos"][1] == 0.25 and h["size"] == [0.9, 0.5, 0.9] for h in layout["hideouts"]))

	def test_generate_writes_pond_lists(self):
		d = {"name": "t", "terrain": DESC["terrain"], "zones": [{"name": "z", "ops": [
			{"type": "pond", "center": [0, 0], "radius": 6, "depth": 1.5, "level": -0.5}]}]}
		layout, terrain = lg.generate(d)
		self.assertEqual(len(layout["water_zones"]), 1)
		self.assertEqual(len(layout["shore"]), 8)
		self.assertEqual(terrain["features"][0]["type"], "basin")

	def test_kit_constants_match_world_builder(self):
		src = (ROOT / "scripts/world/world_builder.gd").read_text()
		for name, val in (("KIT_STEP_RISE", lg.KIT_RISE), ("KIT_STEP_TREAD", lg.KIT_TREAD), ("KIT_RAMP_DEG", lg.KIT_RAMP_DEG), ("KIT_WIDTH", lg.KIT_WIDTH)):
			m = re.search(rf"const {name} := ([0-9.]+)", src)
			self.assertAlmostEqual(float(m.group(1)), val, 6, name)


DESC = {
	"name": "t", "seed": 5,
	"terrain": {"size": [40, 40], "origin": [-20, -20], "cell": 1.0, "base": 0.0,
		"channels": ["asphalt", "paving", "grass", "gravel"], "default": "asphalt", "features": [], "paint": []},
	"counts": {"spawn_points": 6, "yarn": 3, "hideouts": 2},
	"zones": [{"name": "z", "ops": [
		{"type": "garage_row", "origin": [-10, -10], "count": 2, "rot": 0},
		{"type": "scatter", "what": "spawn", "rect": [-18, 0, 18, 18], "count": 4, "allowed": [0]},
		{"type": "scatter", "what": "hideout", "kind": "box", "rect": [-18, 0, 18, 18], "count": 2},
		{"type": "scatter", "what": "yarn", "rect": [-18, 0, 18, 18], "count": 1},
	]}],
}


class Generate(unittest.TestCase):
	def test_generate_is_deterministic_and_clean(self):
		a, ta = lg.generate(DESC)
		b, tb = lg.generate(DESC)
		self.assertEqual(lg.dump_layout(a), lg.dump_layout(b))
		self.assertEqual(len(a["spawn_points"]), 6)
		self.assertEqual(len(a["hideouts"]), 2)
		self.assertEqual(sum(1 for p in a["props"] if p["model"] == "box"), 2 + 4, "ящик у каждого укрытия + четыре в цепочке ряда")
		self.assertEqual(ta["size"], [40, 40])

	def test_check_reports_floating_and_buried_items(self):
		layout, _ = lg.generate(DESC)
		layout["yarn"].append({"pos": [15.0, 1.5, 15.0]})                # висит в воздухе
		layout["spawn_points"].append({"pos": [-10.0, 0, -10.0], "allowed": [0]})   # внутри гаража
		errs = lg.check(layout, {"yarn": [layout["yarn"][-1]], "spawn_points": [layout["spawn_points"][-1]]})
		self.assertEqual(len(errs), 2, errs)

	def test_scatter_respects_structure_of_later_zones(self):
		# Россыпь ранней зоны не должна вставать перед лестницей террасы из более поздней зоны.
		import copy
		d = copy.deepcopy(DESC)
		d["counts"] = {}
		d["zones"] = [
			{"name": "a", "ops": [{"type": "scatter", "what": "prop", "model": "tree", "rect": [-8, -4, 8, 0], "count": 40, "min_dist": 0.6}]},
			{"name": "b", "ops": [{"type": "terrace", "rect": [-10, -15, 10, -5], "height": 1, "access": [["s", 0, "stairs"]]}]},
		]
		layout, _ = lg.generate(d)
		trees = [p["pos"] for p in layout["props"] if p["model"] == "tree"]
		self.assertTrue(trees)
		self.assertFalse(any(abs(x) < 1.5 and z > -5 for x, _, z in trees), "подход к лестнице свободен")

	def test_counts_are_enforced(self):
		import copy
		d = copy.deepcopy(DESC)
		d["counts"]["yarn"] = 99
		with self.assertRaises(ValueError):
			lg.generate(d)

	def test_core_yarn_keys_preserved(self):
		core = json.loads((ROOT / "data/layout_src/yard_core.json").read_text())
		layout, _ = lg.generate(json.loads((ROOT / "data/layout_src/yard.json").read_text()))
		keys = {tuple(y["pos"]) for y in layout["yarn"]}
		self.assertTrue(all(tuple(y["pos"]) in keys for y in core["yarn"]), "клубочки ядра на прежних местах")

	def test_core_park_yarn_keys_preserved(self):
		core = json.loads((ROOT / "data/layout_src/park_core.json").read_text())
		layout, _ = lg.generate(json.loads((ROOT / "data/layout_src/park.json").read_text()))
		keys = {tuple(y["pos"]) for y in layout["yarn"]}
		self.assertTrue(all(tuple(y["pos"]) in keys for y in core["yarn"]), "клубочки ядра парка на прежних местах")

# План 11. Генератор раскладки и двор ×3 — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Двор становится 180×180 м с четырьмя зонами (старый двор, гаражи с крышами, площадка на террасе, верхний двор на высоте 2 м) и кафе с верандой; раскладка собирается генератором из описания, а не руками.

**Architecture:** Python-генератор `tools/layout/layout_gen.py` читает описание района `data/layout_src/yard.json` (ядро — нынешняя раскладка, зоны из примитивов: стены по периметру, терраса, ряд гаражей, россыпь, ручные места) и пишет `data/layout/yard.json` и `data/terrain_src/yard.json`. Инварианты (ничего внутри пропсов, приподнятое стоит на опоре, крыши достижимы цепочкой прыжков) проверяет сам генератор. В Godot меняются только масштабные вещи: плоские тайлы рельефа в 2 треугольника, оса летает над рельефом, отсечение мелких пропсов и каскады теней 40 м.

**Tech Stack:** Python 3 (stdlib, unittest), Blender 5.2.2 (модель гаража), Godot 4.7.2 + GUT 9.7.1.

**Spec:** `docs/superpowers/specs/2026-10-09-snack-run-scale-terrain-design.md` (разделы 2, 3, 4, 5; план 11 из раздела 7).

## Global Constraints

- Двор 180×180 м: x −90…90, z −150…30 (ядро и улица у южного края, за ним парк, как сейчас).
- Кот, пропсы, скорости, камера не масштабируются.
- Количество двора (ориентир спека): ≥ 60 точек еды, ≥ 40 клубочков, ≥ 25 укрытий; опасности: 3 собаки, 4 осы, 2 велосипедиста.
- Цепочки прыжков ≤ 0,8 м по высоте (прыжок кота 4,5²/(2·12) = 0,84 м).
- Террасы — перепады 1–3 м (целые), подъём лестницами (ступень 0,2 м — решение плана 10) и пандусами 25°; склоны холмов ≤ 30°.
- Рельеф ≤ 40 000 треугольников на район; `visibility_range` мелких пропсов 40 м; каскады теней 40 м; фонари без теней с `distance_fade` 35 м.
- Генератор детерминирован (seed). Ключи клубочков ядра не меняются (старые сохранения).
- Цвета только из `tools/blender/palette.py`; тексты и комментарии по-русски.

## Review Focus

1. Кот доходит от будки пряжи до каждой зоны: проходы в стенах есть, терраса площадки и верхний двор доступны по лестнице и пандусу.
2. Край района закрыт: из 180×180 нельзя выйти, кроме прохода в парк (ворота у x 12, z 30).
3. На террасах ничего не висит в воздухе и не утоплено: точки у края обрыва не ставятся, стены закрывают ячейку обрыва.
4. Старые сохранения: собранные клубочки ядра остаются собранными (ключи по позиции из раскладки).
5. Крыши гаражей достижимы: реальные высоты коллайдеров вдоль цепочки растут шагами ≤ 0,8 м.

Тесты по пунктам: 1 — `test_zones_reachable_through_gaps` (задача 5), 2 — `test_district_edge_is_closed` (задача 5), 3 — `test_scatter_avoids_cliff_bands` (задача 3) и `test_generated_items_stand_on_surface` (задача 5), 4 — `test_core_yarn_keys_preserved` (задача 4), 5 — `test_garage_chain_steps_by_physics` (задача 5).

---

### Task 1: Рельеф в масштабе: плоские тайлы, рельеф без данных, толстая подпорная стена

**Files:**
- Modify: `scripts/world/terrain.gd` (`_build_tiles`, `height_at`)
- Modify: `tools/blender/terrace_kit.py` (`WALL_THICK` 0,4 → 1,0)
- Modify: `data/layout/terrain_demo.json` (центры стен −5,8 → −5,5 и −7,8 → −7,5)
- Test: `tests/integration/test_terrain.gd`

**Interfaces:**
- Produces: `Terrain.triangle_count() -> int`; плоский тайл = 2 треугольника; `height_at` без данных → 0.0. Подпорная стена занимает ровно ячейку обрыва: центр на `край + 0,5` наружу.

- [ ] **Step 1: Падающие тесты**

```gdscript
func test_flat_tiles_are_two_triangles() -> void:
	# Плоский тайл 30×30 — 2 треугольника вместо 1800 (спек: ≤ 40 000 на район).
	var flat := Terrain.new()
	flat.data_path = "res://data/terrain/yard.json"
	add_child_autofree(flat)
	await wait_physics_frames(1)
	var tiles := flat.find_children("Tile*", "MeshInstance3D", false, false)
	assert_eq(flat.triangle_count(), tiles.size() * 2, "плоский двор — по 2 треугольника на тайл")

func test_terrain_without_data_answers_zero() -> void:
	var bad := Terrain.new()
	bad.data_path = "res://data/terrain/none.json"
	add_child_autofree(bad)
	assert_eq(bad.height_at(3, 3), 0.0)
```

- [ ] **Step 2: Запуск** — `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gselect=test_terrain`. Expected: FAIL (`triangle_count` не существует; выход за границы массива в `height_at`).

- [ ] **Step 3: Реализация**

В `height_at` сразу после `ensure_loaded()`:
```gdscript
	if not loaded:
		return 0.0
```
В `ensure_loaded` вместо `push_error` для отсутствующего файла — `push_warning` (GUT не валит тест на предупреждении):
```gdscript
	if not FileAccess.file_exists(data_path):
		push_warning("нет рельефа " + data_path)
		return
```
Плоские тайлы и подсчёт:
```gdscript
var _tris := 0

func triangle_count() -> int:
	return _tris

func _tile_flat(ti: int, tj: int, i1: int, j1: int) -> bool:
	var h0 := h(ti, tj)
	for j in range(tj, j1 + 1):
		for i in range(ti, i1 + 1):
			if absf(h(i, j) - h0) > 0.0001:
				return false
	return true
```
В `_build_tiles` перед циклом по ячейкам:
```gdscript
			if _tile_flat(ti, tj, i1, j1):
				for q in [[ti, tj], [i1, tj], [ti, j1], [i1, tj], [i1, j1], [ti, j1]]:
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(x0 + q[0] * cell, h(q[0], q[1]), z0 + q[1] * cell))
				_tris += 2
			else:
				(прежний цикл по ячейкам; после него) _tris += (i1 - ti) * (j1 - tj) * 2
```
`terrace_kit.py`: `WALL_THICK = 1.0` (стена закрывает всю ячейку обрыва 1 м — минор 1 ревью плана 10). `terrain_demo.json`: стена при x −5,8 → −5,5; стены при z −7,8 → −7,5. `make assets ONLY=retaining_wall1` (и 2, 3), `make import`.

- [ ] **Step 4: Запуск** — тот же `-gselect=test_terrain`. Expected: PASS (16).
- [ ] **Step 5: Коммит** — `git commit -m "Рельеф в масштабе: плоские тайлы в 2 треугольника, рельеф без данных, подпорная стена на всю ячейку обрыва"`.

### Task 2: Модель гаража с плоской крышей

**Files:**
- Create: `tools/blender/gen/garage.py`
- Test: существующие тесты Blender прогоняют все `gen/*.py` через `check_asset` (`make test-blender`); Godot — `tests/integration/test_world_builder.gd`

**Interfaces:**
- Produces: модель `garage` 3,0×5,5 м, высота корпуса 2,2 м, бортик до 2,28 м; ворота смотрят по +Z Godot при rot 0. Пятно для генератора: `(3.1, 5.6, 2.28)`.

- [ ] **Step 1: Падающий тест**

```gdscript
func test_garage_roof_is_walkable_at_2_28() -> void:
	var b = _builder()
	b.build({"props": [{"model": "garage", "pos": [0, 0, 0]}]})
	await wait_physics_frames(1)
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 5, 0), Vector3(0, -1, 0), Layers.WORLD))
	assert_false(hit.is_empty(), "крыша гаража твёрдая")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 2.28, 0.05)
```

- [ ] **Step 2: Запуск** — `-gselect=test_world_builder`. Expected: FAIL (нет `garage.glb`).
- [ ] **Step 3: Реализация**

```python
"""Гараж 3×5,5 м с плоской крышей 2,2 м: короб, ворота, бортик (крыша — площадка для паркура, спек «Масштаб» 3)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 5.7}


def build():
	body = lib.rounded_box("garage", (3.0, 5.5, 2.2), bevel=0.03, material="olive")
	body.location.z = 1.1
	door = lib.rounded_box("garage_door", (2.4, 0.06, 1.8), bevel=0.01, material="sky")
	door.location = (0, -2.76, 0.9)   # −Y Blender = +Z Godot: ворота смотрят «вперёд»
	rim = lib.rounded_box("garage_rim", (3.1, 5.6, 0.08), bevel=0.01, material="cream")
	rim.location.z = 2.24
	return lib.group([body, door, rim])
```
`make assets ONLY=garage && make import`.
- [ ] **Step 4: Запуск** — `make test-blender` и `-gselect=test_world_builder`. Expected: PASS.
- [ ] **Step 5: Коммит** — `"Модель гаража с плоской крышей для паркура"`.

### Task 3: Генератор раскладки: примитивы

**Files:**
- Create: `tools/layout/layout_gen.py`, `tools/layout/tests/test_layout_gen.py`
- Modify: `Makefile` (`test-tools` + `layout`)

**Interfaces:**
- Consumes: `tools/terrain/terrain_gen.py` (`main` не нужен, только формат описания рельефа).
- Produces (Python):
  - `FOOTPRINTS: dict[str, tuple[float, float, float]]` (ширина X, глубина Z, верх) при rot 0;
  - `footprint(p) -> tuple | None` — `(x0, z0, x1, z1, top)` в мире, `top` — над местной землёй;
  - `perimeter(rect, model="wall", length=6.0, sides="nswe", gaps=()) -> list[dict]`;
  - `terrace(rect, height, access=()) -> (feature, props, blocked)`;
  - `garage_row(origin, count, rot=0, step=3.2) -> dict` с ключами `props`, `yarn`, `spawn_points`;
  - `scatter(rng, rect, count, blocked, min_dist=2.0, margin=0.4, taken=None) -> list[(x, z)]`;
  - `model_defaults(props) -> dict[str, dict]`;
  - `KIT_RISE = 0.2`, `KIT_TREAD = 0.3`, `KIT_RAMP_DEG = 25.0`, `KIT_WIDTH = 1.6` — те же, что `WorldBuilder.KIT_*`.

- [ ] **Step 1: Падающие тесты** (`tools/layout/tests/test_layout_gen.py`)

```python
import math, random, re, sys, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "layout"))
import layout_gen as lg


class Primitives(unittest.TestCase):
	def test_perimeter_walls_face_inside_and_skip_gaps(self):
		walls = lg.perimeter([0, 0, 24, 12], gaps=[("s", 9.0, 2.0)])
		rots = {(w["pos"][0], w["pos"][2]): w["rot"] for w in walls}
		self.assertEqual(rots[(3.0, 0)], 0, "северная стена лицом на юг (+Z), как ядро при z −14")
		self.assertEqual(rots[(0, 6.0)], 90, "западная — как ядро при x −12")
		self.assertNotIn((9.0, 12), rots, "проход на юге")
		self.assertIn((15.0, 12), rots)

	def test_terrace_stairs_land_on_edge_and_walls_cover_cliff(self):
		feature, props, blocked = lg.terrace([10, -20, 30, -10], 2, access=[("s", 20.0, "stairs"), ("w", -15.0, "ramp")])
		self.assertEqual(feature, {"type": "terrace", "rect": [10, -20, 30, -10], "height": 2.0})
		stairs = next(p for p in props if p["model"] == "terrace_stairs2")
		self.assertAlmostEqual(stairs["pos"][2] - lg.kit_run("stairs", 2), -10, 3, "верх лестницы на кромке плато (над ячейкой обрыва)")
		ramp = next(p for p in props if p["model"] == "ramp2")
		self.assertEqual(ramp["rot"], -90)
		walls = [p for p in props if p["model"] == "retaining_wall2"]
		self.assertTrue(all(w["snap"] is False for w in walls))
		self.assertIn([11.6, -9.5], [[w["pos"][0], w["pos"][2]] for w in walls], "стена на ячейке обрыва: кромка + 0,5")
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

	def test_kit_constants_match_world_builder(self):
		src = (ROOT / "scripts/world/world_builder.gd").read_text()
		for name, val in (("KIT_STEP_RISE", lg.KIT_RISE), ("KIT_STEP_TREAD", lg.KIT_TREAD), ("KIT_RAMP_DEG", lg.KIT_RAMP_DEG), ("KIT_WIDTH", lg.KIT_WIDTH)):
			m = re.search(rf"const {name} := ([0-9.]+)", src)
			self.assertAlmostEqual(float(m.group(1)), val, 6, name)
```

- [ ] **Step 2: Запуск** — `python3 -m unittest discover -s tools/layout/tests -p "test_*.py"`. Expected: FAIL (`ModuleNotFoundError: layout_gen`).

- [ ] **Step 3: Реализация** (`tools/layout/layout_gen.py`, первая часть)

```python
#!/usr/bin/env python3
"""Генератор раскладки района (спек «Масштаб ×3 и рельеф», раздел 4).

Описание data/layout_src/<район>.json → data/layout/<район>.json (для WorldBuilder)
и data/terrain_src/<район>.json (для tools/terrain/terrain_gen.py). Детерминирован (seed);
перед записью проверяет инварианты (check) и падает с перечнем нарушений.
"""
import json
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

KIT_RISE, KIT_TREAD, KIT_RAMP_DEG, KIT_WIDTH = 0.2, 0.3, 25.0, 1.6   # = WorldBuilder.KIT_* (тест сверяет)
WALL_THICK = 1.0   # подпорная стена закрывает ячейку обрыва 1 м (terrace_kit.WALL_THICK)

# Пятна моделей при rot 0: ширина по X, глубина по Z, высота верха над землёй.
FOOTPRINTS = {
	"wall": (6.0, 0.4, 3.2), "garage": (3.1, 5.6, 2.28), "bin": (0.74, 0.84, 1.12), "box": (0.6, 0.6, 0.6),
	"car": (1.7, 3.6, 1.5), "bench": (1.5, 0.45, 0.5), "fence": (2.0, 0.12, 1.0), "kiosk": (2.4, 2.0, 2.6),
	"shed": (2.0, 2.0, 2.3), "cafe_table": (0.9, 0.9, 0.75), "sandbox": (2.0, 2.0, 0.3), "slide": (1.0, 3.0, 1.6),
	"swings": (2.5, 1.2, 2.2), "tree": (0.3, 0.3, 1.6), "lamp": (0.3, 0.3, 3.0), "fountain": (3.0, 3.0, 1.0),
	"retaining_wall1": (4.0, WALL_THICK, 1.0), "retaining_wall2": (4.0, WALL_THICK, 2.0), "retaining_wall3": (4.0, WALL_THICK, 3.0),
	"stairs": (1.2, 3.2, 1.0), "arch": (3.4, 0.6, 2.6), "chair": (0.5, 0.5, 0.9), "umbrella": (0.2, 0.2, 2.2),
}


def kit_run(kind, h):
	return round(h / KIT_RISE) * KIT_TREAD if kind == "stairs" else h / math.tan(math.radians(KIT_RAMP_DEG))


def footprint(p):
	"""(x0, z0, x1, z1, top) пропса; None — неизвестная или несплошная модель. Повороты не по 90° — описанный квадрат."""
	fp = FOOTPRINTS.get(p["model"])
	if fp is None or p.get("solid", True) is False:
		return None
	sx, sz, top = fp
	rot = float(p.get("rot", 0)) % 180
	if abs(rot - 90) < 1:
		sx, sz = sz, sx
	elif rot > 1:
		sx = sz = max(sx, sz)
	x, y, z = p["pos"]
	base = y if p.get("snap", True) else 0.0   # у стен со snap false y — абсолютная высота подножия
	return (x - sx / 2, z - sz / 2, x + sx / 2, z + sz / 2, base + top)


def _local(origin, rot, dx, dz):
	"""Смещение (dx, dz) в осях объекта с поворотом rot (как Basis(UP, rot) в Godot) → мировые x, z."""
	a = math.radians(rot)
	return (round(origin[0] + dx * math.cos(a) + dz * math.sin(a), 3), round(origin[1] - dx * math.sin(a) + dz * math.cos(a), 3))


SIDES = {"n": 0, "s": 180, "w": 90, "e": -90}   # стена дома лицом внутрь прямоугольника


def perimeter(rect, model="wall", length=6.0, sides="nswe", gaps=()):
	"""Модули стен по сторонам rect; gaps — [(сторона, центр вдоль стороны, ширина)] — проходы без стен."""
	x0, z0, x1, z1 = rect
	out = []
	for side in sides:
		horiz = side in "ns"
		a, b = (x0, x1) if horiz else (z0, z1)
		n = max(1, round((b - a) / length))
		step = (b - a) / n
		for k in range(n):
			c = round(a + step * (k + 0.5), 3)
			if any(g[0] == side and abs(c - g[1]) < (g[2] + step) / 2 for g in gaps):
				continue
			pos = [c, 0, z0 if side == "n" else z1] if horiz else [x0 if side == "w" else x1, 0, c]
			out.append({"model": model, "pos": pos, "rot": SIDES[side]})
	return out


def terrace(rect, height, access=()):
	"""Терраса: элемент рельефа, подпорные стены на ячейке обрыва (снаружи rect), лестницы и пандусы.
	access — [(сторона, центр вдоль стороны, "stairs" | "ramp")]. Возвращает (feature, props, blocked)."""
	h = int(height)
	assert h in (1, 2, 3) and all(float(v).is_integer() for v in rect), "терраса: высота 1–3 м, углы в целых метрах"
	x0, z0, x1, z1 = rect
	feature = {"type": "terrace", "rect": list(rect), "height": float(h)}
	gaps = [(s, c, KIT_WIDTH + 0.8) for s, c, _ in access]
	props = []
	half = WALL_THICK / 2
	for w in perimeter([x0 - half, z0 - half, x1 + half, z1 + half], f"retaining_wall{h}", 4.0, "nswe", gaps):
		w["rot"] = 0 if w["rot"] in (0, 180) else 90   # подпорная стена симметрична
		w["snap"] = False
		props.append(w)
	for side, c, kind in access:
		run = kit_run(kind, h)   # верх подъёма — на кромке плато; ход проходит над ячейкой обрыва в проёме стены
		model = f"terrace_stairs{h}" if kind == "stairs" else f"ramp{h}"
		if side == "s":
			pos, rot = [c, 0, z1 + run], 0
		elif side == "n":
			pos, rot = [c, 0, z0 - run], 180
		elif side == "e":
			pos, rot = [x1 + run, 0, c], 90
		else:
			pos, rot = [x0 - run, 0, c], -90
		props.append({"model": model, "pos": [round(v, 3) for v in pos], "rot": rot})
	b = 1.0   # полоса обрыва ±1 м от края — без россыпи
	blocked = [(x0 - b, z0 - b, x1 + b, z0 + b, h), (x0 - b, z1 - b, x1 + b, z1 + b, h),
		(x0 - b, z0 - b, x0 + b, z1 + b, h), (x1 - b, z0 - b, x1 + b, z1 + b, h)]
	for p in props:
		if p["model"].startswith(("terrace_stairs", "ramp")):
			run = kit_run("stairs" if "stairs" in p["model"] else "ramp", h)
			x, _, z = p["pos"]
			ex, ez = _local((x, z), p["rot"], 0, -run)
			blocked.append((min(x, ex) - 1.2, min(z, ez) - 1.2, max(x, ex) + 1.2, max(z, ez) + 1.2, h))
	return feature, props, blocked


def garage_row(origin, count, rot=0, step=3.2):
	"""Ряд гаражей вдоль локальной X; у первого — цепочка прыжков на крышу:
	ящик 0,6 → бак 1,12 → бак с ящиком 1,72 → крыша 2,28. На каждой крыше клубочек, на крайних — редкая еда."""
	props, yarn, spawns = [], [], []
	for k in range(count):
		gx, gz = _local(origin, rot, k * step, 0)
		props.append({"model": "garage", "pos": [gx, 0, gz], "rot": rot})
		yarn.append({"pos": [gx, 2.28, round(gz, 3)]})
		if k in (0, count - 1):
			sx, sz = _local(origin, rot, k * step, 1.6)
			spawns.append({"pos": [sx, 2.28, sz], "allowed": [2, 3]})
	edge = -1.55 - 0.05
	b2 = edge - 0.37
	b1 = b2 - 0.74 - 0.1
	bx = b1 - 0.37 - 0.3 - 0.1
	for dx, model, y in ((b2, "bin", 0), (b2, "box", 1.12), (b1, "bin", 0), (bx, "box", 0)):
		x, z = _local(origin, rot, dx, 1.8)
		props.append({"model": model, "pos": [x, y, z], "rot": rot})
	return {"props": props, "yarn": yarn, "spawn_points": spawns}


def scatter(rng, rect, count, blocked, min_dist=2.0, margin=0.4, taken=None, tries=6000):
	"""count точек в rect не ближе min_dist друг к другу и к taken, вне blocked (+margin)."""
	pts = []
	taken = list(taken or [])
	x0, z0, x1, z1 = rect
	for _ in range(tries):
		if len(pts) >= count:
			break
		x, z = round(rng.uniform(x0, x1), 1), round(rng.uniform(z0, z1), 1)
		if any(f[0] - margin < x < f[2] + margin and f[1] - margin < z < f[3] + margin for f in blocked):
			continue
		if any((x - a) ** 2 + (z - b) ** 2 < min_dist ** 2 for a, b in taken + pts):
			continue
		pts.append((x, z))
	if len(pts) < count:
		raise ValueError(f"scatter: в {rect} поместилось {len(pts)} из {count}")
	return pts


def reachable(fps, jump=0.8, gap=1.0):
	"""Индексы пятен, на которые кот забирается с земли цепочкой прыжков (вверх ≤ jump, зазор ≤ gap)."""
	def near(a, b):
		dx = max(a[0] - b[2], b[0] - a[2], 0.0)
		dz = max(a[1] - b[3], b[1] - a[3], 0.0)
		return math.hypot(dx, dz) <= gap
	seen = {i for i, f in enumerate(fps) if f[4] <= jump}
	queue = list(seen)
	while queue:
		i = queue.pop()
		for j, f in enumerate(fps):
			if j not in seen and f[4] - fps[i][4] <= jump and near(fps[i], f):
				seen.add(j)
				queue.append(j)
	return seen


def model_defaults(props):
	"""Флаги модели (colliders, solid, outline, water) — из первого пропса ядра с той же моделью."""
	d = {}
	for p in props:
		d.setdefault(p["model"], {k: v for k, v in p.items() if k not in ("model", "pos", "rot")})
	return d
```

Примечание к тесту стены: стены террасы стоят на кромке `rect ± 0,5` (центр ячейки обрыва) — так `retaining_wall` с толщиной 1 м закрывает обрыв целиком.

Makefile:
```make
test-tools:
	set -o pipefail; python3 -m unittest discover -s tools/terrain/tests -p "test_*.py" 2>&1 | tail -3
	set -o pipefail; python3 -m unittest discover -s tools/layout/tests -p "test_*.py" 2>&1 | tail -3

layout:
	for f in data/layout_src/*.json; do case $$f in *_core.json) ;; *) python3 tools/layout/layout_gen.py $$f || exit 1;; esac; done
	$(MAKE) terrain
```
- [ ] **Step 4: Запуск** — `make test-tools`. Expected: PASS (6 + 6).
- [ ] **Step 5: Коммит** — `"Генератор раскладки: стены по периметру, террасы с лестницами, ряды гаражей с цепочкой на крышу, россыпь"`.

### Task 4: Генератор: сборка района и инварианты

**Files:**
- Modify: `tools/layout/layout_gen.py` (`generate`, `check`, `dump_layout`, `main`)
- Create: `data/layout_src/yard_core.json` (копия нынешнего `data/layout/yard.json`, без изменений)
- Test: `tools/layout/tests/test_layout_gen.py`

**Interfaces:**
- Produces: `generate(desc: dict) -> (layout: dict, terrain_src: dict)`; `check(layout, generated: dict) -> list[str]`; `main(argv)`. Формат описания:
  ```
  {"name": "yard", "seed": 11, "core": "data/layout_src/yard_core.json",
   "terrain": {size, origin, cell, base, channels, default, features: [], paint: []},
   "road": {"points": [...]},
   "counts": {"spawn_points": 60, "yarn": 40, "hideouts": 25},
   "zones": [{"name": "...", "ops": [op, ...]}]}
  ```
  Операции `op["type"]`: `perimeter` (rect, sides, gaps, model), `terrace` (rect, height, access), `garage_row` (origin, count, rot), `hill` (center, radius, height → элемент рельефа), `paint` (как в terrain_gen), `place` (готовые списки `props`/`hazards`/`spawn_points`/`yarn`/`hideouts`/`decals`), `scatter` (`what`: `spawn` | `yarn` | `hideout` | `prop`; `rect`, `count`, `min_dist`; для spawn — `allowed`, `foods`; для hideout — `kind` box|bench; для prop — `model`, `rot` число или `"random"`).

- [ ] **Step 1: Падающие тесты**

```python
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
		self.assertEqual(sum(1 for p in a["props"] if p["model"] == "box"), 2 + 2, "ящик у каждого укрытия + два в цепочке")
		self.assertEqual(ta["size"], [40, 40])

	def test_check_reports_floating_and_buried_items(self):
		layout, _ = lg.generate(DESC)
		layout["yarn"].append({"pos": [15.0, 1.5, 15.0]})                # висит в воздухе
		layout["spawn_points"].append({"pos": [-10.0, 0, -10.0], "allowed": [0]})   # внутри гаража
		errs = lg.check(layout, {"yarn": [layout["yarn"][-1]], "spawn_points": [layout["spawn_points"][-1]]})
		self.assertEqual(len(errs), 2, errs)

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
```
(в шапку теста — `import json`). Последний тест краснеет до задачи 5 (нет описания двора) — это ожидаемо, он проверяется там.

- [ ] **Step 2: Запуск** — `make test-tools`. Expected: FAIL (`generate` не существует).

- [ ] **Step 3: Реализация** (`layout_gen.py`, вторая часть)

```python
LISTS = ("props", "hideouts", "spawn_points", "yarn", "hazards", "decals", "gates")


def generate(desc):
	rng = random.Random(desc.get("seed", 1))
	core = json.loads((ROOT / desc["core"]).read_text()) if "core" in desc else {}
	out = {k: [dict(it) for it in core.get(k, [])] for k in LISTS}
	if "shop" in core:
		out["shop"] = core["shop"]
	if desc.get("road") or core.get("road"):
		out["road"] = desc.get("road") or core["road"]
	terrain = json.loads(json.dumps(desc["terrain"]))
	terrain.setdefault("features", [])
	terrain.setdefault("paint", [])
	defaults = model_defaults(core.get("props", []))
	gen = {k: [] for k in LISTS}
	blocked = [f for f in map(footprint, out["props"]) if f]

	def add(kind, items):
		for it in items:
			if kind == "props":
				it = {**defaults.get(it["model"], {}), **it}
				f = footprint(it)
				if f:
					blocked.append(f)
			out[kind].append(it)
			gen[kind].append(it)

	taken = [(s["pos"][0], s["pos"][2]) for k in ("spawn_points", "yarn", "hideouts") for s in out[k]]
	for zone in desc.get("zones", []):
		for op in zone["ops"]:
			t = op["type"]
			if t == "perimeter":
				add("props", perimeter(op["rect"], op.get("model", "wall"), op.get("length", 6.0), op.get("sides", "nswe"), [tuple(g) for g in op.get("gaps", [])]))
			elif t == "terrace":
				feature, props, bl = terrace(op["rect"], op["height"], [tuple(a) for a in op.get("access", [])])
				terrain["features"].append(feature)
				add("props", props)
				blocked.extend(bl)
			elif t == "garage_row":
				row = garage_row(tuple(op["origin"]), op["count"], op.get("rot", 0), op.get("step", 3.2))
				for k, v in row.items():
					add(k, v)
			elif t == "hill":
				terrain["features"].append({"type": "hill", "center": op["center"], "radius": op["radius"], "height": op["height"]})
			elif t == "paint":
				terrain["paint"].append({k: v for k, v in op.items() if k != "type"})
			elif t == "place":
				for k in LISTS:
					add(k, [dict(it) for it in op.get(k, [])])
			elif t == "scatter":
				pts = scatter(rng, op["rect"], op["count"], blocked, op.get("min_dist", 2.0), op.get("margin", 0.4), taken)
				taken.extend(pts)
				for x, z in pts:
					w = op["what"]
					if w == "spawn":
						s = {"pos": [x, 0, z], "allowed": op.get("allowed", [0])}
						if "foods" in op:
							s["foods"] = op["foods"]
						add("spawn_points", [s])
					elif w == "yarn":
						add("yarn", [{"pos": [x, 0, z]}])
					elif w == "hideout" and op.get("kind", "box") == "box":
						add("props", [{"model": "box", "pos": [x, 0, z], "rot": rng.randrange(0, 360, 15), "outline": True}])
						add("hideouts", [{"kind": "box", "pos": [x, 0.2, round(z + 0.65, 2)], "size": [0.6, 0.4, 0.6]}])
					elif w == "hideout":
						r = rng.choice((0, 90, 180, 270))
						add("props", [{"model": "bench", "pos": [x, 0, z], "rot": r}])
						add("hideouts", [{"kind": "bench", "pos": [x, 0.2, z], "rot": r, "size": [1.3, 0.4, 0.4]}])
					elif w == "prop":
						rot = rng.randrange(0, 360, 15) if op.get("rot") == "random" else op.get("rot", 0)
						add("props", [{"model": op["model"], "pos": [x, 0, z], "rot": rot}])
			else:
				raise ValueError(f"неизвестная операция {t}")
	for k, n in desc.get("counts", {}).items():
		if len(out[k]) < n:
			raise ValueError(f"{k}: {len(out[k])} < {n}")
	errs = check(out, gen, terrain)
	if errs:
		raise ValueError("инварианты раскладки:\n" + "\n".join(errs))
	return out, terrain


def check(layout, generated, terrain=None):
	"""Нарушения для созданных генератором точек: еда и клубочки не внутри пропсов, приподнятые — на достижимой опоре."""
	fps = [f for f in map(footprint, layout["props"]) if f]
	reach = reachable(fps)
	errs = []
	for kind in ("spawn_points", "yarn"):
		for it in generated.get(kind, []):
			x, y, z = it["pos"]
			under = [(i, f) for i, f in enumerate(fps) if f[0] < x < f[2] and f[1] < z < f[3]]
			if terrain:
				ox, oz = terrain["origin"]
				sx, sz = terrain["size"]
				if not (ox + 1 <= x <= ox + sx - 1 and oz + 1 <= z <= oz + sz - 1):
					errs.append(f"{kind} {it['pos']}: за краем района")
			if y < 0.3:
				if any(f[4] > y + 0.1 for _, f in under):
					errs.append(f"{kind} {it['pos']}: внутри пропса")
			elif not any(abs(f[4] - y) <= 0.15 and i in reach for i, f in under):
				errs.append(f"{kind} {it['pos']}: нет достижимой опоры на высоте {y}")
	keys = [tuple(y["pos"]) for y in layout["yarn"]]
	if len(keys) != len(set(keys)):
		errs.append("клубочки с одинаковыми позициями (ключи сохранений)")
	return errs


def dump_layout(d):
	"""JSON по элементу в строке: дифф раскладки читается."""
	lines = ["{"]
	keys = list(d)
	for n, k in enumerate(keys):
		comma = "," if n < len(keys) - 1 else ""
		v = d[k]
		if isinstance(v, list):
			lines.append(f'  "{k}": [')
			lines += ["    " + json.dumps(it, ensure_ascii=False) + ("," if i < len(v) - 1 else "") for i, it in enumerate(v)]
			lines.append("  ]" + comma)
		else:
			lines.append(f'  "{k}": ' + json.dumps(v, ensure_ascii=False) + comma)
	lines.append("}")
	return "\n".join(lines) + "\n"


def main(argv):
	src = Path(argv[1])
	desc = json.loads(src.read_text())
	layout, terrain = generate(desc)
	name = desc.get("name", src.stem)
	(ROOT / f"data/layout/{name}.json").write_text(dump_layout(layout))
	(ROOT / f"data/terrain_src/{name}.json").write_text(json.dumps(terrain, ensure_ascii=False, indent=2) + "\n")
	print(f"{name}: пропсов {len(layout['props'])}, еды {len(layout['spawn_points'])}, клубочков {len(layout['yarn'])}, укрытий {len(layout['hideouts'])}")


if __name__ == "__main__":
	main(sys.argv)
```
`cp data/layout/yard.json data/layout_src/yard_core.json`.
- [ ] **Step 4: Запуск** — `make test-tools`. Expected: PASS, кроме `test_core_yarn_keys_preserved` (нет описания двора, задача 5).
- [ ] **Step 5: Коммит** — `"Генератор раскладки: сборка района из ядра и зон, инварианты, запись раскладки и рельефа"`.

### Task 5: Описание двора ×3 и двор в игре

**Files:**
- Create: `data/layout_src/yard.json`
- Generated: `data/layout/yard.json`, `data/terrain_src/yard.json`, `data/terrain/yard.json` (`make layout`)
- Modify: `tests/integration/test_world_builder.gd` (хелпер `_yard_with_floor` → рельеф двора; новые тесты), `tests/integration/test_yarn.gd` (число клубочков из раскладок)
- Test: `tests/integration/test_yard_x3.gd` (новый)

**Interfaces:**
- Consumes: генератор (задачи 3–4), `garage` (задача 2), `Terrain.triangle_count` (задача 1).
- Produces: двор 180×180 с зонами (координаты ниже); описание — единственный источник правды для `data/layout/yard.json`.

Зоны (x0, z0, x1, z1):
- **Ядро** — нынешний двор, улица z 12 и кафе (`yard_core.json`, без изменений).
- **Гаражи** [−62, −42, −22, −6]: два ряда по 8 гаражей спинами друг к другу (`origin` [−58, −30] rot 0 и [−58, −36] rot 180), 2 собаки нет — одна собака у гаражей; россыпь ящиков, баков, еды, клубочков между рядами.
- **Площадка на террасе** [22, −40, 52, −14], высота 2: лестница с юга (x 30), пандус с запада (z −27); песочница, качели, горка, скамейки, фонари, кусты; оса над горкой.
- **Верхний двор** [−40, −118, 40, −72], высота 2: лестницы с юга (x −12 и x 18), пандус с востока (z −95); дома по северной кромке (`perimeter` sides "n" при z −122), три балкона (`stairs` как в ядре) с едой; собака во дворе; оса у клумб.
- **Проходной сквер** [−20, −70, 20, −16]: холм (центр [0, −45], r 12, h 3 — уклон ≤ 25°), трава и деревья, редкая еда.
- **Веранда кафе** — терраса [−27, 15, −13, 26], высота 1, лестница с востока (z 20); столы, зонтики, стулья, десертный стол с осой.
- **Край района**: `perimeter` [−90, −150, 90, 30] стенами домов, на юге проход x −15…15 в парк (`gaps` [["s", 0, 30]]); улица `road` [[−88, 0, 12], [88, 0, 12]]; второй велосипедист; по сторонам улицы машины и баки.
- **Окраины** x −90…−62 и 52…90, z −150…−118: деревья, кусты, редкие точки еды и клубочки, чтобы край не был пустым.
- Покрытия: асфальт по умолчанию; трава в сквере и окраинах; гравий на площадке; плитка в верхнем дворе и на веранде.
- `counts`: spawn_points 60, yarn 40, hideouts 25; опасностей в итоге 3 собаки, 4 осы, 2 велосипедиста (ядро даёт 1 собаку, 2 осы, 1 велосипедиста).

- [ ] **Step 1: Падающие тесты** (`tests/integration/test_yard_x3.gd`)

```gdscript
extends GutTest
## План 11: двор ×3 (спек «Масштаб ×3 и рельеф», разделы 1–3).

const LAYOUT := "res://data/layout/yard.json"
var world: Node3D
var b: WorldBuilder
var t: Terrain

func before_all() -> void:
	world = Node3D.new()
	add_child(world)
	t = Terrain.new()
	t.data_path = "res://data/terrain/yard.json"
	world.add_child(t)
	b = WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(LAYOUT))
	await wait_physics_frames(2)

func after_all() -> void:
	world.free()

func _ray_down(x: float, z: float) -> Dictionary:
	var space := world.get_world_3d().direct_space_state
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 20, z), Vector3(x, -10, z), Layers.WORLD))

func test_yard_is_180_by_180_with_counts() -> void:
	assert_almost_eq(t.width, 180.0, 0.01)
	assert_almost_eq(t.depth, 180.0, 0.01)
	var d := WorldBuilder.load_layout(LAYOUT)
	assert_gte(d["spawn_points"].size(), 60)
	assert_gte(d["yarn"].size(), 40)
	assert_gte(d["hideouts"].size(), 25)
	var n := {}
	for h in d["hazards"]:
		n[h["type"]] = n.get(h["type"], 0) + 1
	assert_eq(n, {"dog": 3, "wasp": 4, "cyclist": 2})
	assert_lte(t.triangle_count(), 40000, "рельеф ≤ 40 000 треугольников")

func test_terraces_are_raised() -> void:
	assert_almost_eq(t.height_at(37, -27), 2.0, 0.01, "площадка на террасе")
	assert_almost_eq(t.height_at(0, -95), 2.0, 0.01, "верхний двор")
	assert_almost_eq(t.height_at(-20, 20), 1.0, 0.01, "веранда кафе")

func test_generated_items_stand_on_surface() -> void:
	# Review Focus 3: еда и клубочки стоят на рельефе или на пропсе, не висят и не утоплены.
	for s in b.get_node("Spawns").get_children() + b.get_node("Yarn").get_children():
		var p: Vector3 = s.global_position
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.6, Layers.WORLD))
		assert_false(hit.is_empty(), "%s в %s на опоре" % [s.name, p])
		if not hit.is_empty():
			assert_lt(p.y - (hit["position"] as Vector3).y, 0.35, "%s в %s не висит" % [s.name, p])

func test_garage_chain_steps_by_physics() -> void:
	# Review Focus 5: реальные верхи коллайдеров вдоль цепочки у первого гаража каждого ряда растут ≤ 0,8 м.
	# Первый гараж ряда rot 0 стоит в (−58, −30); цепочка на z −28,2: ящик x −61,58, бак −60,81, бак с ящиком −59,97, крыша −57.
	var tops: Array = []
	for x in [-61.58, -60.81, -59.97, -57.0]:
		var hit := _ray_down(x, -28.2)
		tops.append((hit["position"] as Vector3).y if not hit.is_empty() else -1.0)
	var prev := 0.0
	for top in tops:
		assert_lte(top - prev, 0.8, "шаг цепочки %s" % [tops])
		prev = top
	assert_almost_eq(tops[-1], 2.28, 0.05, "цепочка ведёт на крышу")

func test_district_edge_is_closed() -> void:
	# Review Focus 2: горизонтальный луч наружу на высоте кота упирается в стену по всему периметру, кроме прохода в парк.
	var space := world.get_world_3d().direct_space_state
	var checks := []
	for x in range(-84, 85, 12):
		checks.append([Vector3(x, 0.3, -147), Vector3(x, 0.3, -153)])
		if absf(x) > 18:
			checks.append([Vector3(x, 0.3, 27), Vector3(x, 0.3, 33)])
	for z in range(-144, 25, 12):
		checks.append([Vector3(-87, 0.3, z), Vector3(-93, 0.3, z)])
		checks.append([Vector3(87, 0.3, z), Vector3(93, 0.3, z)])
	for c in checks:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c[0], c[1], Layers.WORLD))
		assert_false(hit.is_empty(), "стена на краю у %s" % [c[0]])

func test_zones_reachable_through_gaps() -> void:
	# Review Focus 1: лестницы и пандусы террас стоят в проходах подпорных стен (луч вдоль подъёма не упирается в стену).
	var space := world.get_world_3d().direct_space_state
	for path in [[Vector3(30, 0.4, -6), Vector3(30, 2.4, -16)], [Vector3(14, 0.4, -27), Vector3(24, 2.4, -27)],
			[Vector3(-12, 0.4, -64), Vector3(-12, 2.4, -74)], [Vector3(-8, 0.4, 20), Vector3(-15, 1.4, 20)]]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(path[0] + Vector3.UP * 0.5, path[1] + Vector3.UP * 0.5, Layers.WORLD))
		assert_true(hit.is_empty() or not String(hit["collider"].name).begins_with("retaining_wall"), "проход %s свободен" % [path[0]])
```
Точные координаты цепочек и проходов в тестах берутся из описания двора, написанного в шаге 3: при правке описания тесты правятся вместе с ним (одна правка — одна строка в журнале).

`test_world_builder.gd`: `_yard_with_floor` строит `Terrain` с `res://data/terrain/yard.json` вместо коробки 60×60 (как `test_park._park_with_floor`), `assert_eq(data["hazards"].size(), 4, …)` → 9. `test_yarn.gd`: ожидаемое число — сумма `yarn` из `data/layout/yard.json` и `data/layout/park.json`, после сбора на один меньше.

- [ ] **Step 2: Запуск** — `-gselect=test_yard_x3`. Expected: FAIL (двор 60×60, опасностей 4).

- [ ] **Step 3: Реализация** — `data/layout_src/yard.json` по зонам выше (операции `perimeter`, `terrace`, `garage_row`, `hill`, `paint`, `place`, `scatter`). Опасности новых зон — через `place`: собаки `{"type": "dog", "pos": [-40, 0, -24], "rot": 90}` и `{"type": "dog", "pos": [10, 0, -90], "rot": 0}`, осы `{"type": "wasp", "pos": [40, 0.5, -30], "radius": 2.0}` и `{"type": "wasp", "pos": [-20, 0.5, -100], "radius": 2.0}`, велосипедист `{"type": "cyclist", "pos": [-40, 0, 12]}`. Затем `make layout && make import`.
- [ ] **Step 4: Запуск** — `make test`. Expected: всё зелёное, включая `test_core_yarn_keys_preserved`.
- [ ] **Step 5: Коммит** — `"Двор ×3: 180×180, гаражи с крышами, площадка на террасе, верхний двор, веранда кафе, закрытый край"`.

### Task 6: Опасности на рельефе

**Files:**
- Modify: `scripts/hazards/wasp.gd` (высота полёта над рельефом)
- Test: `tests/integration/test_wasp.gd`

**Interfaces:**
- Consumes: `Terrain.surface_height(tree, x, z, fallback)`.
- Produces: оса летает на `рельеф(якорь) + height`; без рельефа — как раньше (`fallback 0`).

- [ ] **Step 1: Падающий тест**

```gdscript
func test_wasp_flies_above_terrace() -> void:
	var t := Terrain.new()
	t.data_path = "res://data/terrain/demo.json"   # терраса 2 м: x −18…−6, z −18…−8
	world.add_child(t)
	var w = WaspScene.instantiate()
	w.radius = 0.0
	w.position = Vector3(-12, 2.5, -13)
	world.add_child(w)
	await wait_physics_frames(4)
	assert_almost_eq(w.global_position.y, 2.5, 0.15, "оса над террасой на высоте 0,5 над землёй")
```
- [ ] **Step 2: Запуск** — `-gselect=test_wasp`. Expected: FAIL (y ≈ 0,5: высота абсолютная).
- [ ] **Step 3: Реализация** — в `wasp.gd` поле `var ground := 0.0`; при взятии якоря: `ground = Terrain.surface_height(get_tree(), anchor.x, anchor.z, 0.0)`; в полёте `height + bob` → `ground + height + bob`.
- [ ] **Step 4: Запуск** — `-gselect=test_wasp`. Expected: PASS (все прежние тоже: без рельефа `ground` = 0).
- [ ] **Step 5: Коммит** — `"Оса летает над рельефом"`.

### Task 7: Производительность большого двора

**Files:**
- Modify: `scripts/world/world_builder.gd` (`SMALL_PROPS`, `visibility_range_end`, свет фонаря), `scenes/world/lighting.tscn` (`directional_shadow_max_distance = 40.0`)
- Test: `tests/integration/test_world_builder.gd`, `tests/integration/test_lighting.gd`

**Interfaces:**
- Produces: `WorldBuilder.SMALL_PROPS := ["grass", "bush", "box", "bag", "chair", "bin", "puddle", "flowerbed", "ivy"]`, `WorldBuilder.SMALL_RANGE := 40.0`.

- [ ] **Step 1: Падающие тесты**

```gdscript
func test_small_props_fade_out_beyond_40m() -> void:
	var b = _builder()
	b.build({"props": [{"model": "bush", "pos": [0, 0, 0]}, {"model": "garage", "pos": [10, 0, 0]}]})
	var bush_mi := b.get_node("Props").get_child(0).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_almost_eq(bush_mi.visibility_range_end, 40.0, 0.01)
	var garage_mi := b.get_node("Props").get_child(1).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_eq(garage_mi.visibility_range_end, 0.0, "крупное видно всегда")

func test_lamp_light_fades_at_35m() -> void:
	var b = _builder()
	b.build({"props": [{"model": "lamp", "pos": [0, 0, 0]}]})
	var l := b.find_child("NightLight", true, false) as SpotLight3D
	assert_true(l.distance_fade_enabled)
	assert_almost_eq(l.distance_fade_begin, 35.0, 0.01)
	assert_false(l.shadow_enabled)
```
`test_lighting.gd`: `assert_almost_eq(sun.directional_shadow_max_distance, 40.0, 0.01)`.
- [ ] **Step 2: Запуск** — `-gselect=test_world_builder`, `-gselect=test_lighting`. Expected: FAIL.
- [ ] **Step 3: Реализация** — в `_build_prop` после `Toon.apply`:
```gdscript
	if String(p["model"]) in SMALL_PROPS:
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = SMALL_RANGE
			(mi as MeshInstance3D).visibility_range_end_margin = 4.0
			(mi as MeshInstance3D).visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
```
В `_night_light()`: `l.distance_fade_enabled = true`, `l.distance_fade_begin = 35.0`, `l.distance_fade_length = 5.0`. В `lighting.tscn` — `directional_shadow_max_distance = 40.0`.
- [ ] **Step 4: Запуск** — те же. Expected: PASS.
- [ ] **Step 5: Коммит** — `"Большой двор: мелкие пропсы гаснут за 40 м, фонари за 35 м, тени солнца на 40 м"`.

### Task 8: Кадры зон и документация

**Files:**
- Modify: `docs/replay/02-procedure.md`, `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`, `CLAUDE.md`, `tools/replay/build_files_md.py` (`tools/layout/**/*.py`, `data/layout_src/*.json`)

- [ ] **Step 1: Кадры** — `make shot SHOT=build/shot_garages.png AT=-50,2.4,-20,200`, `make shot SHOT=build/shot_playground.png AT=30,2.2,-8,180`, `make shot SHOT=build/shot_upper.png AT=-12,2.2,-62,180`, `make shot SHOT=build/shot_veranda.png PHASE=night AT=-8,1.2,20,270`. Посмотреть каждый: ничего не висит, стены закрывают обрывы, крыши читаются.
- [ ] **Step 2: Документы** — раздел плана 11 в `02-procedure.md` (генератор, зоны, грабли), дорожная карта, CLAUDE.md (`make layout`, `tools/layout/`, правка двора — только через `data/layout_src/yard.json`), `make replay`.
- [ ] **Step 3: Полный прогон** — `make test`. Expected: зелёное.
- [ ] **Step 4: Коммит** — `"Документация плана 11: генератор раскладки и двор ×3"`.

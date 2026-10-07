# Snack Run, план 1: Фундамент

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Рыжий кот с анимациями бегает и прыгает по двору-заглушке в Godot с тун-освещением, а все модели собираются из Blender скриптами одной командой.

**Architecture:** Godot-проект (GDScript) с автозагрузками для ввода и dev-инструментов; чистая логика движения кота вынесена в `RefCounted`-класс и покрыта GUT-тестами; Blender-пайплайн — пакет Python-скриптов `tools/blender/` (палитра, примитивы, экспорт, генераторы ассетов) с unittest внутри Blender и валидацией каждого glb. Кот берётся из CC0-пака Quaternius и перекрашивается палитрой.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript, GUT 9.7.1, Blender 5.2.2 LTS (bpy, bmesh, numpy), glTF 2.0 (.glb), GNU make.

**Spec:** `docs/superpowers/specs/2026-10-07-snack-run-design.md`

## Global Constraints

- Godot 4.7.2 stable, GDScript, рендерер Forward+; путь к бинарю `/Applications/Godot.app/Contents/MacOS/Godot`.
- Blender 5.2.2 LTS, запуск только в фоне: `blender -b --python <скрипт> -- <аргументы>`; путь `/Applications/Blender.app/Contents/MacOS/Blender`.
- glTF: 1 единица = 1 м, `+Y` вверх, трансформации применены, имя файла = имя сцены; все модели в `assets/models/`.
- Цвета только из палитры спека 2.2 (13 цветов + 4 редкости), hex копировать точно.
- Полигонаж: пропс 100–800 треугольников, кот до 2500, здание до 3000.
- Тун-материалы: `diffuse_mode = Toon`, `specular_mode = Toon`; обводка через `grow`, `cull_mode = Front`, 0,02 м для кота и опасностей, 0,006 м для еды, цвет `#394151`.
- Камера: третье лицо, `SpringArm3D`, высота взгляда 0,6 м, дистанция 3,5 м, FOV 60°, сглаживание 8/сек.
- Анимации: только бесплатные источники (CC0/CC-BY), платные исключены; порядок: готовые паки → UniMate → генерация `bpy` как последний вариант.
- Все пользовательские тексты, комментарии и сообщения коммитов на русском; идентификаторы кода на английском.
- Коммиты заканчиваются строкой `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

## Review Focus

1. Кот стоит на наклонной или на краю бака: `is_on_floor()` ложно на крутом скосе, кот «скользит» и анимация дёргается между idle и jump. Тест в задаче 6: состояние не меняется на `jump`, если вертикальная скорость мала (|vy| < 0,5) и кот был на полу в прошлом кадре.
2. Одновременное нажатие противоположных клавиш (A и D): направление ноль, кот должен плавно остановиться, а не дрожать. Тест в задаче 6.
3. Камера упирается в стену: `SpringArm3D` сокращает длину и камера оказывается внутри головы кота. Тест в задаче 7: кот скрывается (`visible = false`), если фактическая длина пружины < 0,9 м.
4. Модель кота смотрит не туда (Quaternius экспортирует вперёд по −Y Blender, то есть +Z в Godot, а Godot считает вперёд −Z): кот бежит спиной вперёд. Проверка скриншотом в задаче 4 и параметр `FACING_FIX_DEG` в `cat.py`.
5. `make assets` на чистой машине без `.godot/`: Godot не импортировал glb, тесты, которые загружают `cat.glb`, падают. `make test` зависит от `make import` (задача 1), и это проверяется в задаче 5 запуском после `rm -rf .godot`.

---

## Структура файлов

```
snack_run/
  Makefile                              # assets / import / test / shot / run
  project.godot
  .gutconfig.json
  addons/gut/                           # GUT 9.7.1, вендор
  scenes/
    main.tscn                           # корень: двор + кот + камера
    player/cat.tscn                     # CharacterBody3D + модель + AnimationPlayer
    player/camera_rig.tscn              # Node3D → SpringArm3D → Camera3D
    world/lighting.tscn                 # DirectionalLight3D + WorldEnvironment
    world/district_yard.tscn            # земля + заглушки
  scripts/
    autoload/input_setup.gd             # InputMap в коде
    autoload/dev_tools.gd               # ++ --screenshot=путь
    player/cat_motion.gd                # чистая логика (RefCounted, static)
    player/cat.gd                       # узел кота: ввод, физика, анимации
    player/camera_rig.gd
    player/head_scaler.gd               # SkeletonModifier3D: голова ×1.4
    visual/toon.gd                      # тун-материалы + обводка
  tests/
    unit/test_cat_motion.gd
    unit/test_toon.gd
    integration/test_cat_asset.gd
  tools/blender/
    palette.py        # PALETTE, get_material()
    lib.py            # clear_scene, rounded_box, tri_count, check_asset
    export.py         # export_glb()
    build.py          # запускает gen/*.py, валидирует, экспортирует
    rig_inspect.py    # печать костей, поиск головы
    cat.py            # импорт Quaternius → cat.glb
    cat_anims.py      # jump/hide/hit клипы (последний вариант)
    gen/ground.py  gen/box.py  gen/bin.py
    tests/run.py  tests/test_lib.py  tests/test_export.py  tests/list_glb.py
  third_party/quaternius_animal_pack_v2/   # Cat.blend, Dog.blend, LICENSE.md
  assets/models/                           # результат make assets (в git)
```

---

### Task 1: Проект Godot, GUT, Makefile

**Files:**
- Create: `Makefile`, `project.godot`, `.gutconfig.json`, `scenes/main.tscn`, `tests/unit/test_smoke.gd`
- Create: `addons/gut/` (вендор из релиза GUT v9.7.1)

**Interfaces:**
- Produces: `make import`, `make test`, `make run`; переменные `GODOT`, `BLENDER` в Makefile.

- [ ] **Step 1: Скачать GUT 9.7.1 и положить в addons**

```bash
cd /Users/admin/Projects/neiroslop/snack_run
mkdir -p /tmp/gut_dl && curl -sL -o /tmp/gut_dl/gut.zip https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip
unzip -q -o /tmp/gut_dl/gut.zip -d /tmp/gut_dl
mkdir -p addons && cp -R /tmp/gut_dl/Gut-9.7.1/addons/gut addons/gut
ls addons/gut/gut_cmdln.gd addons/gut/plugin.cfg
```
Ожидается: оба файла найдены.

- [ ] **Step 2: Создать project.godot и главную сцену**

`project.godot`:
```ini
; Engine configuration file.
config_version=5

[application]

config/name="Snack Run"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")

[autoload]

InputSetup="*res://scripts/autoload/input_setup.gd"
DevTools="*res://scripts/autoload/dev_tools.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[rendering]

renderer/rendering_method="forward_plus"
```

`scenes/main.tscn`:
```
[gd_scene format=3]

[node name="Main" type="Node3D"]
```

Заглушки автозагрузок (наполняются в задачах 3 и 6), `scripts/autoload/input_setup.gd`:
```gdscript
extends Node
## Регистрирует действия InputMap в коде, чтобы не держать их в project.godot.

func _ready() -> void:
	pass
```
`scripts/autoload/dev_tools.gd`:
```gdscript
extends Node
## Инструменты разработчика: скриншот из командной строки.

func _ready() -> void:
	pass
```

`.gutconfig.json`:
```json
{
  "dirs": ["res://tests/"],
  "include_subdirs": true,
  "should_exit": true,
  "log_level": 1,
  "prefix": "test_"
}
```

- [ ] **Step 3: Написать smoke-тест**

`tests/unit/test_smoke.gd`:
```gdscript
extends GutTest

func test_godot_version_is_4_7() -> void:
	var v := Engine.get_version_info()
	assert_eq(v.major, 4)
	assert_eq(v.minor, 7)
```

- [ ] **Step 4: Makefile**

```makefile
GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png

.PHONY: import test test-godot test-blender assets shot run

import:
	$(GODOT) --headless --path . --import

test: import test-blender test-godot

test-godot:
	$(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json

test-blender:
	$(BLENDER) -b --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python tools/blender/build.py -- $(ONLY)

shot:
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 ++ --screenshot=$(SHOT)

run:
	$(GODOT) --path .
```
(Отступы в Makefile — табы.)

- [ ] **Step 5: Запустить импорт и тесты Godot**

Run: `make import && make test-godot`
Expected: в конце вывода GUT `1 passed 0 failed`, код выхода 0.

- [ ] **Step 6: Commit**

```bash
git add Makefile project.godot .gutconfig.json scenes scripts tests addons .gitignore
git commit -m "Проект Godot 4.7, GUT 9.7.1, Makefile

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Blender-библиотека: палитра, примитивы, экспорт, тесты

**Files:**
- Create: `tools/blender/palette.py`, `tools/blender/lib.py`, `tools/blender/export.py`, `tools/blender/build.py`, `tools/blender/gen/box.py`, `tools/blender/tests/run.py`, `tools/blender/tests/test_lib.py`, `tools/blender/tests/test_export.py`, `tools/blender/tests/list_glb.py`

**Interfaces:**
- Produces: `palette.PALETTE: dict[str, str]`, `palette.get_material(key: str) -> bpy.types.Material`; `lib.clear_scene()`, `lib.rounded_box(name, size, bevel=0.02, segments=3, material=None) -> Object`, `lib.world_extent(obj) -> float`, `lib.tri_count(obj) -> int`, `lib.check_asset(objs, max_tris, max_dim) -> list[str]` (список ошибок, пустой = ок); `export.export_glb(path, objects, animations=False)`; генератор в `gen/*.py` обязан иметь `SPEC = {"max_tris": int, "max_dim": float}` и `build() -> list[Object]`; `make assets ONLY=box` собирает один ассет.

- [ ] **Step 1: Тестовый раннер и первый падающий тест**

`tools/blender/tests/run.py`:
```python
"""Запуск: blender -b --python tools/blender/tests/run.py"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))  # tools/blender

suite = unittest.defaultTestLoader.discover(HERE, pattern="test_*.py")
result = unittest.TextTestRunner(verbosity=2).run(suite)
sys.exit(0 if result.wasSuccessful() else 1)
```

`tools/blender/tests/test_lib.py`:
```python
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
```

- [ ] **Step 2: Убедиться, что тесты падают**

Run: `make test-blender`
Expected: `ModuleNotFoundError: No module named 'lib'`, код выхода 1.

- [ ] **Step 3: Реализовать palette.py**

```python
"""Палитра Snack Run (спек 2.2). Цвета sRGB hex -> материалы Blender."""
import bpy

PALETTE = {
    "cat_orange": "#FAAE45",
    "cream": "#FCD3A1",
    "sand": "#D3AB87",
    "olive": "#A9B087",
    "leaf": "#458B59",
    "sea_deep": "#1D7FC4",
    "sea_light": "#2F9CCF",
    "sky": "#659ECF",
    "lilac": "#B46DB5",
    "coral": "#F57485",
    "brick": "#BD4045",
    "asphalt": "#5A5C6B",
    "ink": "#394151",
    "rarity_common": "#4D945B",
    "rarity_rare": "#6491E4",
    "rarity_very_rare": "#C473D4",
    "rarity_legendary": "#FABE32",
}

MATERIAL_PREFIX = "sr_"


def hex_to_linear(hex_color: str):
    h = hex_color.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    out = []
    for c in srgb:
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, 1.0)


def get_material(key: str) -> bpy.types.Material:
    """Материал палитры; создаётся один раз и переиспользуется."""
    if key not in PALETTE:
        raise KeyError(f"нет цвета {key!r} в палитре")
    name = MATERIAL_PREFIX + key
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = hex_to_linear(PALETTE[key])
        bsdf.inputs["Roughness"].default_value = 0.85
    return mat


def is_palette_material(mat: bpy.types.Material) -> bool:
    return mat is not None and mat.name.startswith(MATERIAL_PREFIX)
```

- [ ] **Step 4: Реализовать lib.py**

```python
"""Примитивы и проверки для генераторов ассетов."""
import bmesh
import bpy
from mathutils import Vector

import palette


def clear_scene() -> None:
	"""Удаляет все объекты и осиротевшие данные текущего файла."""
	bpy.ops.wm.read_homefile(use_empty=True)
	for block in (bpy.data.meshes, bpy.data.materials, bpy.data.actions, bpy.data.armatures):
		for item in list(block):
			if item.users == 0:
				block.remove(item)


def rounded_box(name, size, bevel=0.02, segments=3, material=None):
	"""Параллелепипед size=(x,y,z) с центром в начале координат и bevel-модификатором."""
	mesh = bpy.data.meshes.new(name)
	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	for v in bm.verts:
		v.co.x *= size[0]
		v.co.y *= size[1]
		v.co.z *= size[2]
	bm.to_mesh(mesh)
	bm.free()
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	if bevel > 0:
		mod = obj.modifiers.new("Bevel", "BEVEL")
		mod.width = bevel
		mod.segments = segments
		mod.limit_method = "ANGLE"
	if material:
		mesh.materials.append(palette.get_material(material))
	bpy.context.view_layer.update()   # иначе dimensions нулевые до первой оценки сцены
	return obj


def world_extent(obj) -> float:
	"""Наибольший габарит в мировых координатах (учитывает масштаб родителя, в отличие от obj.dimensions)."""
	corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
	spans = [max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3)]
	return max(spans)


def tri_count(obj) -> int:
	"""Число треугольников с учётом модификаторов."""
	depsgraph = bpy.context.evaluated_depsgraph_get()
	eval_obj = obj.evaluated_get(depsgraph)
	mesh = eval_obj.to_mesh()
	mesh.calc_loop_triangles()
	n = len(mesh.loop_triangles)
	eval_obj.to_mesh_clear()
	return n


def check_asset(objs, max_tris: int, max_dim: float):
	"""Возвращает список ошибок (пустой список = ассет валиден)."""
	errors = []
	bpy.context.view_layer.update()
	total = sum(tri_count(o) for o in objs if o.type == "MESH")
	if total > max_tris:
		errors.append(f"треугольников {total} > лимита {max_tris}")
	biggest = max((world_extent(o) for o in objs if o.type == "MESH"), default=0.0)
	if biggest > max_dim:
		errors.append(f"габарит {biggest:.2f} м > лимита {max_dim} м")
	for o in objs:
		if o.type != "MESH":
			continue
		for m in o.data.materials:
			if not palette.is_palette_material(m):
				errors.append(f"{o.name}: материал {getattr(m, 'name', None)!r} не из палитры")
	return errors
```

- [ ] **Step 5: Запустить тесты библиотеки**

Run: `make test-blender`
Expected: `Ran 7 tests ... OK`. Если `tri_count` для чистого куба не равен 12, проверьте, что `create_cube` создал 6 четырёхугольников (6×2 = 12).

- [ ] **Step 6: Тест экспорта (падающий)**

`tools/blender/tests/test_export.py`:
```python
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
```

Run: `make test-blender`
Expected: `ModuleNotFoundError: No module named 'export'`.

- [ ] **Step 7: Реализовать export.py**

```python
"""Экспорт glTF (.glb) по конвенциям проекта: 1 ед = 1 м, +Y вверх."""
import os

import bpy


def export_glb(path: str, objects, animations: bool = False) -> None:
	os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objects:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objects[0]
	bpy.ops.export_scene.gltf(
		filepath=path,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_yup=True,
		export_materials="EXPORT",
		export_animations=animations,
		export_animation_mode="ACTIONS",
		export_skins=animations,
		export_morph=False,
	)
```
Если экспортёр ругается на имя параметра, список актуальных имён:
`blender -b --python-expr "import bpy; print(sorted(bpy.ops.export_scene.gltf.get_rna_type().properties.keys()))"`.

- [ ] **Step 8: Запустить тесты**

Run: `make test-blender`
Expected: `Ran 8 tests ... OK`.

- [ ] **Step 9: build.py и первый генератор**

`tools/blender/gen/box.py`:
```python
"""Картонная коробка 0,45×0,35×0,3 м (укрытие и пропс двора)."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.6}


def build():
	body = lib.rounded_box("box", (0.45, 0.35, 0.30), bevel=0.015, segments=2, material="sand")
	body.location.z = 0.15
	return [body]
```

`tools/blender/build.py`:
```python
"""Сборка всех ассетов: blender -b --python tools/blender/build.py -- [имя ...]"""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "assets", "models")

import bpy  # noqa: E402

import export  # noqa: E402
import lib  # noqa: E402


def wanted():
	if "--" in sys.argv:
		names = [a for a in sys.argv[sys.argv.index("--") + 1:] if a]
		if names:
			return names
	gen_dir = os.path.join(HERE, "gen")
	return sorted(f[:-3] for f in os.listdir(gen_dir) if f.endswith(".py") and not f.startswith("_"))


def main():
	failed = []
	for name in wanted():
		lib.clear_scene()
		mod = importlib.import_module(f"gen.{name}")
		objs = mod.build()
		errors = lib.check_asset(objs, **mod.SPEC)
		if errors:
			failed.append(name)
			for e in errors:
				print(f"ОШИБКА {name}: {e}")
			continue
		path = os.path.join(OUT, f"{name}.glb")
		export.export_glb(path, objs, animations=mod.SPEC.get("animations", False))
		print(f"ОК {name} -> {os.path.relpath(path, ROOT)} ({sum(lib.tri_count(o) for o in objs)} tri)")
	if failed:
		print("ПРОВАЛ:", ", ".join(failed))
		sys.exit(1)


if __name__ == "__main__":
	main()
```
Создайте пустой `tools/blender/gen/__init__.py`.

- [ ] **Step 10: Собрать и проверить**

Run: `make assets ONLY=box && ls -la assets/models/box.glb`
Expected: строка `ОК box -> assets/models/box.glb (N tri)`, файл существует.

- [ ] **Step 11: Утилита просмотра glb**

`tools/blender/tests/list_glb.py` (не тест, а инструмент):
```python
"""blender -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb"""
import sys

import bpy

path = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_homefile(use_empty=True)
bpy.ops.import_scene.gltf(filepath=path)
for o in bpy.data.objects:
	print("OBJ", o.type, o.name, tuple(round(d, 3) for d in o.dimensions))
	if o.type == "MESH":
		print("   MATS", [m.name for m in o.data.materials if m])
for a in bpy.data.actions:
	print("ANIM", a.name, "кадры", tuple(a.frame_range))
```

Run: `$BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/box.glb 2>&1 | grep -E "^(OBJ|   MATS|ANIM)"`
Expected: `OBJ MESH box (0.45, 0.3, 0.35)` (после +Y-up ось Z и Y меняются местами) и `MATS ['sr_sand']`.

- [ ] **Step 12: Commit**

```bash
git add tools assets/models/box.glb
git commit -m "Blender-пайплайн: палитра, скруглённые боксы, экспорт glb, сборка

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Тун-материалы, освещение, скриншот из CLI

**Files:**
- Create: `scripts/visual/toon.gd`, `scripts/world/lighting.gd`, `scripts/tools/look_at_target.gd`, `scenes/world/lighting.tscn`, `tests/unit/test_toon.gd`
- Modify: `scripts/autoload/dev_tools.gd`, `scenes/main.tscn`

**Interfaces:**
- Produces: `Toon.apply(root: Node, outline_width: float = 0.02) -> int` (число обработанных поверхностей), `Toon.OUTLINE_COLOR`, константы `Toon.OUTLINE_CHARACTER = 0.02`, `Toon.OUTLINE_FOOD = 0.006`; сцена `lighting.tscn`; `make shot SHOT=путь`.

- [ ] **Step 1: Падающий тест**

`tests/unit/test_toon.gd`:
```gdscript
extends GutTest

func _make_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	box.material = mat
	mi.mesh = box
	add_child_autofree(mi)
	return mi

func test_apply_sets_toon_modes_and_outline() -> void:
	var mi := _make_mesh()
	var n := Toon.apply(mi, 0.02)
	assert_eq(n, 1)
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_not_null(m)
	assert_eq(m.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)
	assert_eq(m.specular_mode, BaseMaterial3D.SPECULAR_TOON)
	assert_eq(m.albedo_color, Color.RED)
	var outline := mi.material_overlay as StandardMaterial3D
	assert_not_null(outline)
	assert_true(outline.grow)
	assert_almost_eq(outline.grow_amount, 0.02, 0.0001)
	assert_eq(outline.cull_mode, BaseMaterial3D.CULL_FRONT)
	assert_eq(outline.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_eq(outline.albedo_color, Toon.OUTLINE_COLOR)

func test_apply_without_outline_leaves_overlay_empty() -> void:
	var mi := _make_mesh()
	Toon.apply(mi, 0.0)
	assert_null(mi.material_overlay)

func test_apply_walks_children() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var a := _make_mesh()
	a.reparent(root)
	var b := _make_mesh()
	b.reparent(root)
	assert_eq(Toon.apply(root, 0.01), 2)
```

Run: `make test-godot`
Expected: ошибка парсинга `Identifier "Toon" not declared`.

- [ ] **Step 2: Реализовать toon.gd**

```gdscript
class_name Toon
extends RefCounted
## Переводит материалы в тун-режим и добавляет обводку инвертированным hull-ом (спек 2.3).

const OUTLINE_COLOR := Color("#394151")
const OUTLINE_CHARACTER := 0.02
const OUTLINE_FOOD := 0.006
const OUTLINE_NONE := 0.0


static func apply(root: Node, outline_width: float = OUTLINE_CHARACTER) -> int:
	var count := 0
	if root is MeshInstance3D:
		count += _apply_to_mesh(root as MeshInstance3D, outline_width)
	for child in root.get_children():
		count += apply(child, outline_width)
	return count


static func _apply_to_mesh(mi: MeshInstance3D, outline_width: float) -> int:
	if mi.mesh == null:
		return 0
	var surfaces := mi.mesh.get_surface_count()
	for i in surfaces:
		var src := mi.get_active_material(i)
		var mat: StandardMaterial3D
		if src is StandardMaterial3D:
			mat = (src as StandardMaterial3D).duplicate()
		else:
			mat = StandardMaterial3D.new()
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat.roughness = 0.85
		mi.set_surface_override_material(i, mat)
	if outline_width > 0.0:
		mi.material_overlay = _make_outline(outline_width)
	return surfaces


static func _make_outline(width: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = OUTLINE_COLOR
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = width
	return m
```

- [ ] **Step 3: Запустить тесты**

Run: `make test-godot`
Expected: `4 passed 0 failed`.

- [ ] **Step 4: Сцена освещения**

`scripts/world/lighting.gd` (поворот солнца задаём кодом, чтобы не писать матрицы в tscn руками):
```gdscript
extends Node3D
## Солнце под 50° к горизонту, с юго-востока (спек 2.3).

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
```

`scripts/tools/look_at_target.gd` (для камер в тестовых сценах):
```gdscript
extends Camera3D
## Смотрит на точку target_point после входа в дерево.

@export var target_point := Vector3(0, 0.15, 0)

func _ready() -> void:
	look_at(target_point, Vector3.UP)
```

`scenes/world/lighting.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world/lighting.gd" id="1"]

[sub_resource type="ProceduralSkyMaterial" id="sky"]
sky_top_color = Color(0.396, 0.620, 0.812, 1)
sky_horizon_color = Color(0.988, 0.827, 0.631, 1)
ground_bottom_color = Color(0.827, 0.671, 0.529, 1)
ground_horizon_color = Color(0.988, 0.827, 0.631, 1)

[sub_resource type="Sky" id="skyres"]
sky_material = SubResource("sky")

[sub_resource type="Environment" id="env"]
background_mode = 2
sky = SubResource("skyres")
ambient_light_source = 2
ambient_light_color = Color(0.624, 0.769, 0.910, 1)
ambient_light_energy = 0.6
tonemap_mode = 2

[node name="Lighting" type="Node3D"]
script = ExtResource("1")

[node name="Sun" type="DirectionalLight3D" parent="."]
light_color = Color(1, 0.945, 0.839, 1)
light_energy = 1.2
shadow_enabled = true

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")
```
(Цвета: небо `#659ECF`, горизонт `#FCD3A1`, земля `#D3AB87`, ambient `#9FC4E8`, солнце `#FFF1D6`, спек 2.3.)

- [ ] **Step 5: Скриншот из CLI**

`scripts/autoload/dev_tools.gd`:
```gdscript
extends Node
## Инструменты разработчика. Запуск: godot --path . ++ --screenshot=build/shot.png

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_and_quit(arg.trim_prefix("--screenshot="))


func _screenshot_and_quit(path: String) -> void:
	# Ждём, пока сцена загрузится и отрисуется несколько кадров.
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err := img.save_png(abs_path)
	print("СКРИНШОТ ", abs_path, " ", error_string(err))
	get_tree().quit(0 if err == OK else 1)
```

`scenes/main.tscn` (временно: свет + коробка, чтобы было что снимать):
```
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://scenes/world/lighting.tscn" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/box.glb" id="2"]
[ext_resource type="Script" path="res://scripts/tools/look_at_target.gd" id="3"]

[sub_resource type="PlaneMesh" id="ground"]
size = Vector2(10, 10)

[node name="Main" type="Node3D"]

[node name="Lighting" parent="." instance=ExtResource("1")]

[node name="Ground" type="MeshInstance3D" parent="."]
mesh = SubResource("ground")

[node name="Box" parent="." instance=ExtResource("2")]

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.5, 1.2, 2.5)
fov = 60.0
script = ExtResource("3")
```

- [ ] **Step 6: Снять скриншот и посмотреть**

Run: `make import && make shot SHOT=build/task3.png && ls -la build/task3.png`
Expected: вывод `СКРИНШОТ ... OK`, файл > 10 КБ. Откройте `build/task3.png` (инструмент Read): видна песочная коробка на серой плоскости, небо градиентом, тень от коробки. Если коробка чёрная, проверьте, что `lighting.tscn` в сцене.

- [ ] **Step 7: Commit**

```bash
git add scripts/visual/toon.gd scripts/world scripts/tools scenes/world/lighting.tscn scenes/main.tscn scripts/autoload/dev_tools.gd tests/unit/test_toon.gd
git commit -m "Тун-материалы с обводкой, освещение, скриншот из CLI

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Кот из CC0-пака Quaternius → cat.glb

**Files:**
- Create: `third_party/quaternius_animal_pack_v2/{Cat.blend,Dog.blend,LICENSE.md}`, `tools/blender/rig_inspect.py`, `tools/blender/cat.py`, `tools/blender/gen/cat.py`
- Test: `tests/integration/test_cat_asset.gd`

**Interfaces:**
- Produces: `assets/models/cat.glb` с анимациями `idle`, `walk`, костью `head`, материалами `sr_cat_orange`, `sr_cream`, `sr_coral`; длина кота 0,35 м; `rig_inspect.find_head_bone(arm, mesh) -> str`.

- [ ] **Step 1: Вендорить пак и лицензию**

Пак уже скачан в scratchpad при подготовке; при чистом старте:
```bash
mkdir -p /tmp/q && cd /tmp/q && curl -sL -o pack.zip "https://opengameart.org/sites/default/files/Animal%20Pack%20Vol.2%20by%20%40Quaternius.zip" && unzip -q -o pack.zip
cd /Users/admin/Projects/neiroslop/snack_run
mkdir -p third_party/quaternius_animal_pack_v2
cp "/tmp/q/Animal Pack Vol.2 by @Quaternius/Blends/Cat.blend" "/tmp/q/Animal Pack Vol.2 by @Quaternius/Blends/Dog.blend" third_party/quaternius_animal_pack_v2/
```
`third_party/quaternius_animal_pack_v2/LICENSE.md`:
```markdown
# Animal Pack Vol.2 by Quaternius

Источник: https://opengameart.org/content/animated-animales-low-poly
Автор: Quaternius (https://quaternius.com)
Лицензия: CC0 1.0 Universal (public domain). Указание авторства не требуется, но мы указываем его в титрах.
Файлы: Cat.blend, Dog.blend (меш, арматура 24 кости, клипы Idle и Walking).
```

- [ ] **Step 2: Инспектор рига**

`tools/blender/rig_inspect.py`:
```python
"""Печать костей и поиск головы. Запуск:
blender -b third_party/quaternius_animal_pack_v2/Cat.blend --python tools/blender/rig_inspect.py"""
import bpy


def vertex_count_for_bone(mesh_obj, bone_name: str) -> int:
	vg = mesh_obj.vertex_groups.get(bone_name)
	if vg is None:
		return 0
	idx = vg.index
	return sum(1 for v in mesh_obj.data.vertices for g in v.groups if g.group == idx and g.weight > 0.3)


def find_head_bone(arm, mesh_obj) -> str:
	"""Голова = листовая не-IK кость с наибольшим числом вершин: у головы уши и морда,
	у лап и кончика хвоста вершин в разы меньше."""
	leaves = [b for b in arm.data.bones if not b.children and not b.name.startswith("IK")]
	return max(leaves, key=lambda b: vertex_count_for_bone(mesh_obj, b.name)).name


def print_table(arm, mesh_obj) -> None:
	for b in arm.data.bones:
		print(f"BONE {b.name:14s} parent={b.parent.name if b.parent else '-':14s} "
		      f"head={tuple(round(c, 2) for c in b.head_local)} verts={vertex_count_for_bone(mesh_obj, b.name)}")


if __name__ == "__main__":
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH")
	print_table(arm, mesh)
	print("HEAD", find_head_bone(arm, mesh))
```

Run: `$BLENDER -b third_party/quaternius_animal_pack_v2/Cat.blend --python tools/blender/rig_inspect.py 2>&1 | grep -E "^(BONE|HEAD)"`
Expected: таблица 24 костей и строка `HEAD Bone.0XX`. Сверьте глазами: у найденной кости `verts` заметно больше, чем у других листовых костей, а её `head` лежит на переднем конце длинной оси и в верхней половине по высоте. Запишите имя в заметки, оно нужно только для проверки, скрипт `cat.py` находит голову сам.

- [ ] **Step 3: Падающий интеграционный тест в Godot**

`tests/integration/test_cat_asset.gd`:
```gdscript
extends GutTest

const CAT_PATH := "res://assets/models/cat.glb"

func _instance() -> Node3D:
	var scene := load(CAT_PATH) as PackedScene
	assert_not_null(scene, "cat.glb должен импортироваться как PackedScene")
	var inst := scene.instantiate() as Node3D
	add_child_autofree(inst)
	return inst

func test_cat_has_idle_and_walk() -> void:
	var inst := _instance()
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_not_null(ap)
	assert_true(ap.has_animation("idle"), "нет клипа idle")
	assert_true(ap.has_animation("walk"), "нет клипа walk")

func test_cat_has_head_bone_and_is_kitten_sized() -> void:
	var inst := _instance()
	var skel := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	assert_not_null(skel)
	assert_gt(skel.find_bone("head"), -1, "нет кости head")
	var aabb := _world_aabb(inst)
	assert_between(maxf(aabb.size.x, aabb.size.z), 0.25, 0.45, "длина кота должна быть около 0,35 м")
	assert_lt(aabb.size.y, 0.4, "высота кота не больше 0,4 м")

func test_cat_materials_are_palette() -> void:
	var inst := _instance()
	var names := []
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			names.append((mi as MeshInstance3D).get_active_material(i).resource_name)
	assert_has(names, "sr_cat_orange")
	assert_has(names, "sr_cream")

func _world_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
```

Run: `make import && make test-godot`
Expected: 3 теста падают с `cat.glb должен импортироваться`.

- [ ] **Step 4: Скрипт подготовки кота**

`tools/blender/cat.py`:
```python
"""Готовит кота из Quaternius Cat.blend: масштаб, палитра, имя головы, имена клипов."""
import os

import bpy

import palette
import rig_inspect

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Cat.blend")
TARGET_LENGTH = 0.35      # метров, спек 2.1 и карта (25–30 см тело + хвост)
FACING_FIX_DEG = 0        # подбирается по скриншоту в шаге 7: 90, -90 или 180
MATERIAL_MAP = {"Grey": "cat_orange", "White": "cream", "Pink": "coral"}
ACTION_MAP = {"Idle": "idle", "Walking": "walk"}


def load_source():
	bpy.ops.wm.open_mainfile(filepath=SOURCE)
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH")
	return arm, mesh


def recolor(mesh):
	for i, m in enumerate(mesh.data.materials):
		key = MATERIAL_MAP.get(m.name if m else "", "cat_orange")
		mesh.data.materials[i] = palette.get_material(key)


def rename_actions():
	for a in bpy.data.actions:
		if a.name in ACTION_MAP:
			a.name = ACTION_MAP[a.name]
	for a in bpy.data.actions:
		a.use_fake_user = True


def rescale(arm, mesh):
	length = max(mesh.dimensions)
	factor = TARGET_LENGTH / length
	# Масштабируем арматуру (меш её дочерний), не применяя: применение ломает
	# location-каналы анимаций. glTF-экспортёр запишет масштаб узла.
	arm.scale = (factor, factor, factor)
	arm.rotation_euler.z += FACING_FIX_DEG * 3.141592653589793 / 180.0


def name_head(arm, mesh):
	head = rig_inspect.find_head_bone(arm, mesh)
	arm.data.bones[head].name = "head"


def build():
	arm, mesh = load_source()
	if mesh.parent is not arm:
		mesh.parent = arm
	recolor(mesh)
	rename_actions()
	name_head(arm, mesh)
	rescale(arm, mesh)
	arm.name = "CatRig"
	mesh.name = "cat"
	return [arm, mesh]
```

`tools/blender/gen/cat.py`:
```python
"""Генератор кота: оборачивает cat.py для build.py."""
import cat

SPEC = {"max_tris": 2500, "max_dim": 0.6, "animations": True}


def build():
	return cat.build()
```

- [ ] **Step 5: Собрать и проверить glb в Blender**

Run: `make assets ONLY=cat && $BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb 2>&1 | grep -E "^(OBJ|   MATS|ANIM)"`
Expected: `OBJ ARMATURE CatRig`, `OBJ MESH cat` с наибольшим габаритом ≈0.35, `MATS ['sr_cat_orange', 'sr_cream', 'sr_coral']`, `ANIM idle`, `ANIM walk`. Если клипов нет, экспортёр не увидел action: убедитесь, что `use_fake_user = True` и `export_animation_mode="ACTIONS"`; запасной вариант: положить оба action в NLA-дорожки арматуры (`arm.animation_data.nla_tracks.new().strips.new(name, 1, action)`) и экспортировать с `export_animation_mode="NLA_TRACKS"`.
Если наибольший габарит в glb не ≈0,35 (экспортёр плохо переносит масштаб арматуры со скином) или меш отвалился от скелета (в `list_glb` у меша нет родителя-ARMATURE), оставьте в `cat.py` `arm.scale = (1, 1, 1)`, а масштаб `0.0618` задайте в `cat.tscn` на узле `Model` (`transform = Transform3D(0.0618, 0, 0, 0, 0.0618, 0, 0, 0, 0.0618, 0, 0, 0)`); тогда проверку размера перенесите из `test_cat_asset.gd` в `test_cat_scene.gd` (задача 7), а `SPEC["max_dim"]` для кота поднимите до 6.0.

- [ ] **Step 6: Запустить Godot-тесты**

Run: `make import && make test-godot`
Expected: все тесты, включая 3 в `test_cat_asset.gd`, зелёные. Если `find_bone("head")` = −1, глб-импортёр Godot сохранил имя, но тест ищет не тот `Skeleton3D`: напечатайте `skel.get_bone_name(i)` для всех `i`.

- [ ] **Step 7: Проверить направление взгляда скриншотом**

Временно добавьте кота в `scenes/main.tscn` вместо коробки:
```
[ext_resource type="PackedScene" path="res://assets/models/cat.glb" id="2"]
...
[node name="Cat" parent="." instance=ExtResource("2")]
```
И поставьте камеру спереди по −Z (она смотрит на начало координат скриптом `look_at_target.gd`):
```
[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.25, -1.2)
script = ExtResource("3")
```
Run: `make shot SHOT=build/task4_front.png`
Expected: на скриншоте морда кота (уши, глаза) смотрит в камеру. Длина исходной модели идёт по оси X Blender, поэтому при `FACING_FIX_DEG = 0` кот, скорее всего, виден боком: тогда поставьте `90` (виден левый бок) или `-90` (правый бок); если виден хвост, `180`. После правки: `make assets ONLY=cat && make import && make shot SHOT=build/task4_front.png`. Повторяйте, пока морда не смотрит в камеру. Это Review Focus 4.

- [ ] **Step 8: Commit**

```bash
git add third_party tools/blender/rig_inspect.py tools/blender/cat.py tools/blender/gen/cat.py assets/models/cat.glb tests/integration/test_cat_asset.gd scenes/main.tscn
git commit -m "Кот из CC0-пака Quaternius: масштаб, палитра, кость head, клипы idle/walk

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Недостающие клипы: jump, hide, hit (и run)

**Files:**
- Create: `tools/blender/cat_anims.py`, `docs/superpowers/notes/2026-10-07-unimate-attempt.md`
- Modify: `tools/blender/cat.py`
- Test: `tests/integration/test_cat_asset.gd`

**Interfaces:**
- Produces: `cat.glb` дополнительно содержит `jump` (18 кадров), `hide` (2 кадра, поза), `hit` (12 кадров); `run` в Blender не создаётся, в Godot это `walk` со `speed_scale = 1.8` (задача 7).

- [ ] **Step 1: Попытка UniMate (лимит 1 час по часам)**

Порядок по спеку 5.3: сначала готовое. UniMate: код https://github.com/Friedrich-M/UniMate (MIT), чекпоинт https://huggingface.co/Linzhan/UniMate.
```bash
mkdir -p /tmp/unimate && cd /tmp/unimate && git clone --depth 1 https://github.com/Friedrich-M/UniMate.git
cat UniMate/README.md | head -120
```
Критерии «получилось»: за час на Apple M4 Pro удалось (а) поставить зависимости, (б) скормить `assets/models/cat.glb` и текст `"a cat jumps in place"`, (в) получить glb/fbx с клипом, который открывается в Blender и не ломает риг (лапы не выворачиваются при просмотре `list_glb.py` + рендере одного кадра). Если выполнены все три, добавьте клип через `bpy.ops.import_scene.gltf` в `cat.py` и переименуйте action в `jump`; повторите для `"a cat crouches and hides"` и `"a cat is hit and flinches"`.
Результат попытки (успех или причина отказа, затраченное время) запишите в `docs/superpowers/notes/2026-10-07-unimate-attempt.md` одним абзацем. Если не получилось, переходите к шагу 2.

- [ ] **Step 2: Падающий тест на новые клипы**

Добавьте в `tests/integration/test_cat_asset.gd`:
```gdscript
func test_cat_has_generated_clips() -> void:
	var inst := _instance()
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["jump", "hide", "hit"]:
		assert_true(ap.has_animation(clip), "нет клипа " + clip)
	assert_between(ap.get_animation("jump").length, 0.6, 0.9, "jump около 0,75 с при 24 fps")
```

Run: `make test-godot`
Expected: падает на `нет клипа jump`.

- [ ] **Step 3: Генерация клипов скриптом (последний вариант по спеку)**

`tools/blender/cat_anims.py`:
```python
"""Процедурные клипы для рига Quaternius: jump, hide, hit. Клипы «на месте»:
вертикальное движение тела делает CharacterBody3D, здесь только поза."""
import math

import bpy
from mathutils import Quaternion

FPS = 24


def _top_level_pose_bones(arm):
	return [pb for pb in arm.pose.bones if pb.parent is None]


def _root(arm):
	return next(pb for pb in _top_level_pose_bones(arm) if not pb.name.startswith("IK"))


def _ik_bones(arm):
	return [pb for pb in _top_level_pose_bones(arm) if pb.name.startswith("IK")]


def _new_action(arm, name, frames):
	action = bpy.data.actions.new(name)
	action.use_fake_user = True
	arm.animation_data_create()
	arm.animation_data.action = action
	bpy.context.scene.frame_start = 0
	bpy.context.scene.frame_end = frames
	for pb in arm.pose.bones:
		pb.location = (0, 0, 0)
		pb.rotation_quaternion = (1, 0, 0, 0)
		pb.scale = (1, 1, 1)
		# Ключ на каждой кости: иначе в Godot кости без дорожки застывают в позе прошлого клипа.
		pb.keyframe_insert("location", frame=0)
		pb.keyframe_insert("rotation_quaternion", frame=0)
		pb.keyframe_insert("scale", frame=0)
	return action


def _key(pb, frame, location=None, scale=None, rot_x_deg=None):
	if location is not None:
		pb.location = location
		pb.keyframe_insert("location", frame=frame)
	if scale is not None:
		pb.scale = scale
		pb.keyframe_insert("scale", frame=frame)
	if rot_x_deg is not None:
		# Режим вращения кости не трогаем: idle/walk записаны кватернионами.
		pb.rotation_quaternion = Quaternion((1.0, 0.0, 0.0), math.radians(rot_x_deg))
		pb.keyframe_insert("rotation_quaternion", frame=frame)


def make_jump(arm, unit):
	"""18 кадров: присед (0–4), выпрямление и подтянутые лапы (5–12), приземление (13–18).
	unit = 1 м в единицах арматуры (до масштабирования)."""
	_new_action(arm, "jump", 18)
	root = _root(arm)
	iks = _ik_bones(arm)
	tuck = 0.08 * unit
	_key(root, 0, scale=(1, 1, 1))
	_key(root, 4, scale=(1.1, 1.1, 0.8))
	_key(root, 9, scale=(0.9, 0.9, 1.15))
	_key(root, 14, scale=(1.05, 1.05, 0.9))
	_key(root, 18, scale=(1, 1, 1))
	for ik in iks:
		_key(ik, 0, location=(0, 0, 0))
		_key(ik, 4, location=(0, 0, 0))
		_key(ik, 9, location=(0, 0, tuck))
		_key(ik, 14, location=(0, 0, 0))
		_key(ik, 18, location=(0, 0, 0))


def make_hide(arm, unit):
	"""2 кадра одинаковой позы: тело прижато к земле."""
	_new_action(arm, "hide", 2)
	root = _root(arm)
	drop = -0.06 * unit
	for f in (0, 2):
		_key(root, f, location=(0, 0, drop), scale=(1.05, 1.05, 0.85))


def make_hit(arm, unit):
	"""12 кадров: отшатнулся назад и сжался, вернулся."""
	_new_action(arm, "hit", 12)
	root = _root(arm)
	_key(root, 0, rot_x_deg=0, scale=(1, 1, 1))
	_key(root, 3, rot_x_deg=-20, scale=(0.9, 0.9, 1.1))
	_key(root, 7, rot_x_deg=8, scale=(1.05, 1.05, 0.9))
	_key(root, 12, rot_x_deg=0, scale=(1, 1, 1))


def add_all(arm, unit):
	make_jump(arm, unit)
	make_hide(arm, unit)
	make_hit(arm, unit)
	arm.animation_data.action = bpy.data.actions["idle"]
```

В `tools/blender/cat.py` добавьте импорт `import cat_anims` и в `build()` перед `rescale(arm, mesh)`:
```python
	unit = max(mesh.dimensions) / TARGET_LENGTH   # единиц арматуры в одном метре
	cat_anims.add_all(arm, unit)
```
Если в выбранном риге ось «вверх» у кости не Z (лапы тянутся вбок на скриншоте), поменяйте в `make_jump` вектор `(0, 0, tuck)` на `(0, tuck, 0)`.

- [ ] **Step 4: Собрать, проверить список клипов, тесты**

Run: `make assets ONLY=cat && $BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb 2>&1 | grep ANIM && make import && make test-godot`
Expected: `ANIM idle`, `walk`, `jump`, `hide`, `hit`; GUT зелёный.

- [ ] **Step 5: Визуальная проверка кадра прыжка**

Временно в `scenes/main.tscn` добавьте к коту скрипт-однострочник через `DevTools`: проще снять кадр через Blender:
```bash
$BLENDER -b --python-expr "
import bpy
bpy.ops.wm.read_homefile(use_empty=True)
bpy.ops.import_scene.gltf(filepath='assets/models/cat.glb')
arm=[o for o in bpy.data.objects if o.type=='ARMATURE'][0]
arm.animation_data.action=bpy.data.actions['jump']
bpy.context.scene.frame_set(9)
cam=bpy.data.objects.new('Cam', bpy.data.cameras.new('Cam')); bpy.context.scene.collection.objects.link(cam)
cam.location=(0.6,-0.8,0.35); cam.rotation_euler=(1.25,0,0.6); bpy.context.scene.camera=cam
light=bpy.data.objects.new('L', bpy.data.lights.new('L','SUN')); bpy.context.scene.collection.objects.link(light); light.rotation_euler=(0.8,0.3,0.5)
bpy.context.scene.render.engine='BLENDER_EEVEE'; bpy.context.scene.render.resolution_x=640; bpy.context.scene.render.resolution_y=480
bpy.context.scene.render.filepath='build/jump_frame9.png'; bpy.ops.render.render(write_still=True)"
```
Откройте `build/jump_frame9.png`: кот вытянут вверх, лапы подтянуты к телу, ничего не вывернуто. Если движок называется иначе в 5.2 (`BLENDER_EEVEE_NEXT`), подставьте имя из `bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys()`.

- [ ] **Step 6: Commit**

```bash
git add tools/blender/cat_anims.py tools/blender/cat.py assets/models/cat.glb tests/integration/test_cat_asset.gd docs/superpowers/notes
git commit -m "Клипы jump/hide/hit для кота (после попытки UniMate)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Логика движения кота (чистая, с тестами) и InputMap

**Files:**
- Create: `scripts/player/cat_motion.gd`, `tests/unit/test_cat_motion.gd`
- Modify: `scripts/autoload/input_setup.gd`

**Interfaces:**
- Produces: `CatMotion.WALK_SPEED = 2.0`, `RUN_SPEED = 4.0`, `JUMP_VELOCITY = 4.5`, `GRAVITY = 12.0`, `ACCEL = 14.0`; `CatMotion.world_direction(input: Vector2, cam_yaw_basis: Basis) -> Vector3`; `CatMotion.step(velocity: Vector3, direction: Vector3, running: bool, on_floor: bool, jump: bool, delta: float) -> Vector3`; `CatMotion.pick_state(velocity: Vector3, on_floor: bool, running: bool) -> StringName` (`&"idle"`, `&"walk"`, `&"run"`, `&"jump"`); действия InputMap: `move_left`, `move_right`, `move_forward`, `move_back`, `run`, `jump`, `hide`, `eat`, `cam_left`, `cam_right`.

- [ ] **Step 1: Падающие тесты**

`tests/unit/test_cat_motion.gd`:
```gdscript
extends GutTest

const D := 1.0 / 60.0

func test_forward_input_maps_to_minus_z() -> void:
	var dir := CatMotion.world_direction(Vector2(0, -1), Basis.IDENTITY)
	assert_almost_eq(dir, Vector3(0, 0, -1), Vector3(0.001, 0.001, 0.001))

func test_direction_rotates_with_camera_yaw() -> void:
	var yaw := Basis(Vector3.UP, PI / 2)   # камера повёрнута на 90° влево
	var dir := CatMotion.world_direction(Vector2(0, -1), yaw)
	assert_almost_eq(dir, Vector3(-1, 0, 0), Vector3(0.001, 0.001, 0.001))

func test_opposite_keys_give_zero_direction() -> void:
	var dir := CatMotion.world_direction(Vector2(0, 0), Basis.IDENTITY)
	assert_eq(dir, Vector3.ZERO)

func test_accelerates_to_walk_speed() -> void:
	var v := Vector3.ZERO
	for i in 120:
		v = CatMotion.step(v, Vector3(0, 0, -1), false, true, false, D)
	assert_almost_eq(v.z, -CatMotion.WALK_SPEED, 0.01)
	assert_almost_eq(v.y, 0.0, 0.001)

func test_run_is_faster() -> void:
	var v := Vector3.ZERO
	for i in 120:
		v = CatMotion.step(v, Vector3(1, 0, 0), true, true, false, D)
	assert_almost_eq(v.x, CatMotion.RUN_SPEED, 0.01)

func test_no_input_decelerates_to_zero_without_overshoot() -> void:
	var v := Vector3(2, 0, 0)
	var prev := v.x
	for i in 60:
		v = CatMotion.step(v, Vector3.ZERO, false, true, false, D)
		assert_true(v.x >= 0.0 and v.x <= prev, "скорость не должна менять знак")
		prev = v.x
	assert_almost_eq(v.x, 0.0, 0.001)

func test_jump_sets_vertical_velocity_only_on_floor() -> void:
	var on_floor := CatMotion.step(Vector3.ZERO, Vector3.ZERO, false, true, true, D)
	assert_almost_eq(on_floor.y, CatMotion.JUMP_VELOCITY, 0.001)
	var in_air := CatMotion.step(Vector3.ZERO, Vector3.ZERO, false, false, true, D)
	assert_lt(in_air.y, 0.0, "в воздухе прыжок не срабатывает, действует гравитация")

func test_gravity_applies_in_air() -> void:
	var v := CatMotion.step(Vector3.ZERO, Vector3.ZERO, false, false, false, 0.5)
	assert_almost_eq(v.y, -CatMotion.GRAVITY * 0.5, 0.001)

func test_pick_state() -> void:
	assert_eq(CatMotion.pick_state(Vector3.ZERO, true, false), &"idle")
	assert_eq(CatMotion.pick_state(Vector3(1.5, 0, 0), true, false), &"walk")
	assert_eq(CatMotion.pick_state(Vector3(3.5, 0, 0), true, true), &"run")
	assert_eq(CatMotion.pick_state(Vector3(0, 3, 0), false, false), &"jump")

func test_small_vertical_wobble_on_slope_is_not_jump() -> void:
	# Review Focus 1: на скосе is_on_floor мигает, но |vy| мал.
	assert_eq(CatMotion.pick_state(Vector3(1.0, -0.3, 0), false, false), &"walk")
	assert_eq(CatMotion.pick_state(Vector3(0, -0.3, 0), false, false), &"idle")
```

Run: `make test-godot`
Expected: `Identifier "CatMotion" not declared`.

- [ ] **Step 2: Реализовать cat_motion.gd**

```gdscript
class_name CatMotion
extends RefCounted
## Чистая логика движения кота. Без узлов, без ввода: всё приходит аргументами.

const WALK_SPEED := 2.0
const RUN_SPEED := 4.0
const JUMP_VELOCITY := 4.5
const GRAVITY := 12.0
const ACCEL := 14.0
const SLOPE_WOBBLE := 0.5   # |vy| ниже этого при потере пола не считается прыжком


static func world_direction(input: Vector2, cam_yaw_basis: Basis) -> Vector3:
	if input.is_zero_approx():
		return Vector3.ZERO
	var local := Vector3(input.x, 0.0, input.y)
	var dir := cam_yaw_basis * local
	dir.y = 0.0
	return dir.normalized()


static func step(velocity: Vector3, direction: Vector3, running: bool, on_floor: bool, jump: bool, delta: float) -> Vector3:
	var speed := RUN_SPEED if running else WALK_SPEED
	var target := direction * speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(Vector3(target.x, 0.0, target.z), ACCEL * delta)
	var vy := velocity.y
	if on_floor:
		vy = JUMP_VELOCITY if jump else 0.0
	else:
		vy -= GRAVITY * delta
	return Vector3(horizontal.x, vy, horizontal.z)


static func pick_state(velocity: Vector3, on_floor: bool, running: bool) -> StringName:
	if not on_floor and absf(velocity.y) >= SLOPE_WOBBLE:
		return &"jump"
	var h := Vector2(velocity.x, velocity.z).length()
	if h < 0.1:
		return &"idle"
	if running and h > WALK_SPEED + 0.1:
		return &"run"
	return &"walk"
```

- [ ] **Step 3: Запустить тесты**

Run: `make test-godot`
Expected: все 10 тестов движения зелёные.

- [ ] **Step 4: InputMap в коде**

`scripts/autoload/input_setup.gd`:
```gdscript
extends Node
## Регистрирует действия InputMap (клавиатура + геймпад), спек 3.1.

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"run": [KEY_SHIFT],
	"jump": [KEY_SPACE],
	"hide": [KEY_CTRL],
	"eat": [KEY_E],
	"cam_left": [KEY_Q],
	"cam_right": [KEY_R],
}
const PAD_BUTTONS := {
	"jump": JOY_BUTTON_A,
	"hide": JOY_BUTTON_B,
	"eat": JOY_BUTTON_X,
}
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	"run": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"cam_left": [JOY_AXIS_RIGHT_X, -1.0],
	"cam_right": [JOY_AXIS_RIGHT_X, 1.0],
}


func _ready() -> void:
	register()


static func register() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for action in PAD_BUTTONS:
		var b := InputEventJoypadButton.new()
		b.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, b)
	for action in PAD_AXES:
		var m := InputEventJoypadMotion.new()
		m.axis = PAD_AXES[action][0]
		m.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, m)
```

Тест в `tests/unit/test_cat_motion.gd` (добавить):
```gdscript
func test_input_actions_registered() -> void:
	var InputSetupScript := load("res://scripts/autoload/input_setup.gd")
	InputSetupScript.register()
	for a in ["move_left", "move_right", "move_forward", "move_back", "run", "jump", "hide", "eat", "cam_left", "cam_right"]:
		assert_true(InputMap.has_action(a), "нет действия " + a)
```

Run: `make test-godot`
Expected: зелёный.

- [ ] **Step 5: Commit**

```bash
git add scripts/player/cat_motion.gd scripts/autoload/input_setup.gd tests/unit/test_cat_motion.gd
git commit -m "Логика движения кота с тестами, InputMap в коде

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Сцена кота, анимации, увеличение головы, камера

**Files:**
- Create: `scripts/player/cat.gd`, `scenes/player/cat.tscn`, `scripts/player/head_scaler.gd`, `scripts/player/camera_rig.gd`, `scenes/player/camera_rig.tscn`
- Test: `tests/integration/test_cat_scene.gd`

**Interfaces:**
- Consumes: `CatMotion.*`, `Toon.apply`, `assets/models/cat.glb` с клипами `idle/walk/jump/hide/hit`.
- Produces: `Cat` (CharacterBody3D, `scenes/player/cat.tscn`) с `var camera_rig: Node3D` (устанавливает `Main`), `func play_clip(name: StringName) -> void` с запасными клипами (`run` → `walk` при `speed_scale` 1.8), сигнал `state_changed(state: StringName)`, свойство `state: StringName`; `CameraRig` (`scenes/player/camera_rig.tscn`) с `@export var target: Node3D`, `func yaw_basis() -> Basis`, константы `HEIGHT = 0.6`, `DISTANCE = 3.5`, `SMOOTH = 8.0`, `HIDE_BELOW = 0.9`; `func apply_arm_length(length: float) -> void`.

- [ ] **Step 1: Падающие тесты сцены**

`tests/integration/test_cat_scene.gd`:
```gdscript
extends GutTest

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

func _spawn():
	var cat := CatScene.instantiate()
	add_child_autofree(cat)
	return cat

func test_cat_starts_idle_with_toon_materials() -> void:
	var cat := _spawn()
	assert_eq(cat.state, &"idle")
	var mesh := cat.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_not_null(mesh.material_overlay, "обводка должна быть установлена")
	assert_eq((mesh.get_surface_override_material(0) as StandardMaterial3D).diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)

func test_play_clip_falls_back_run_to_fast_walk() -> void:
	var cat := _spawn()
	cat.play_clip(&"run")
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_eq(ap.current_animation, "walk")
	assert_almost_eq(ap.speed_scale, 1.8, 0.001)
	cat.play_clip(&"idle")
	assert_eq(ap.current_animation, "idle")
	assert_almost_eq(ap.speed_scale, 1.0, 0.001)

func test_head_is_scaled() -> void:
	var cat := _spawn()
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	await wait_physics_frames(2)
	var idx := skel.find_bone("head")
	assert_almost_eq(skel.get_bone_pose_scale(idx).x, 1.4, 0.01)

func test_camera_rig_hides_target_when_too_close() -> void:
	var cat := _spawn()
	var rig := RigScene.instantiate()
	rig.target = cat
	add_child_autofree(rig)
	rig.apply_arm_length(0.5)   # имитация упора в стену
	assert_false(cat.visible)
	rig.apply_arm_length(3.5)
	assert_true(cat.visible)
```

Run: `make test-godot`
Expected: падает на отсутствии `cat.tscn`.

- [ ] **Step 2: Скрипты кота и головы**

`scripts/player/head_scaler.gd`:
```gdscript
class_name HeadScaler
extends SkeletonModifier3D
## Увеличивает голову поверх любой анимации (чиби-пропорции, спек 2.1).

@export var bone_name: StringName = &"head"
@export var scale_factor := 1.4


# Если в 4.7 этот колбэк не вызывается (голова не масштабируется в тесте),
# переименуйте в `_process_modification_with_delta(_delta: float)`.
func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var idx := skel.find_bone(bone_name)
	if idx < 0:
		return
	skel.set_bone_pose_scale(idx, Vector3.ONE * scale_factor)
```

`scripts/player/cat.gd`:
```gdscript
class_name Cat
extends CharacterBody3D
## Узел кота: читает ввод, двигает тело через CatMotion, переключает клипы.

signal state_changed(state: StringName)

const FALLBACK := {&"run": [&"walk", 1.8], &"jump": [&"idle", 1.0], &"hide": [&"idle", 1.0], &"hit": [&"idle", 1.0]}
const TURN_SPEED := 12.0

var camera_rig: CameraRig
var state: StringName = &"idle":
	set(value):
		if value != state:
			state = value
			play_clip(state)
			state_changed.emit(state)

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)
	var skel := _model.find_child("Skeleton3D", true, false)
	if skel and skel.find_child("HeadScaler", false, false) == null:
		var hs := HeadScaler.new()
		hs.name = "HeadScaler"
		skel.add_child(hs)
	if camera_rig:
		(camera_rig.get_node("SpringArm3D") as SpringArm3D).add_excluded_object(get_rid())
	play_clip(&"idle")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := camera_rig.yaw_basis() if camera_rig else Basis.IDENTITY
	var dir := CatMotion.world_direction(input, yaw)
	var running := Input.is_action_pressed("run")
	var jump := Input.is_action_just_pressed("jump")
	velocity = CatMotion.step(velocity, dir, running, is_on_floor(), jump, delta)
	move_and_slide()
	if dir.length() > 0.0:
		var target_yaw := atan2(-dir.x, -dir.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, TURN_SPEED * delta)
	state = CatMotion.pick_state(velocity, is_on_floor(), running)


func play_clip(name: StringName) -> void:
	if _anim == null:
		return
	var clip := String(name)
	var speed := 1.0
	if not _anim.has_animation(clip) and FALLBACK.has(name):
		clip = String(FALLBACK[name][0])
		speed = FALLBACK[name][1]
	_anim.speed_scale = speed
	if _anim.current_animation != clip:
		_anim.play(clip, 0.15)
```

- [ ] **Step 3: Сцена кота**

`scenes/player/cat.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/player/cat.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/cat.glb" id="2"]
[ext_resource type="Script" path="res://scripts/player/head_scaler.gd" id="3"]

[sub_resource type="CapsuleShape3D" id="shape"]
radius = 0.08
height = 0.3

[node name="Cat" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0.1, 0)
shape = SubResource("shape")

[node name="Model" parent="." instance=ExtResource("2")]
```
`HeadScaler` добавляется к `Skeleton3D` кодом в `_ready()` (см. `cat.gd` выше), потому что узлы внутри импортированного glb нельзя редактировать в tscn без «Make Local».

- [ ] **Step 4: Камера**

`scripts/player/camera_rig.gd`:
```gdscript
class_name CameraRig
extends Node3D
## Третье лицо: пружина 3,5 м, взгляд с высоты 0,6 м, сглаживание 8/с (спек 2.3).

const HEIGHT := 0.6
const DISTANCE := 3.5
const SMOOTH := 8.0
const HIDE_BELOW := 0.9
const YAW_SPEED := 2.2
const PITCH_DEG := -10.0

@export var target: Node3D
var _yaw := 0.0
@onready var _arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	_arm.spring_length = DISTANCE
	_arm.rotation_degrees.x = PITCH_DEG


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var axis := Input.get_axis("cam_left", "cam_right")
	_yaw -= axis * YAW_SPEED * delta
	rotation.y = _yaw
	var goal := target.global_position + Vector3(0, HEIGHT, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-SMOOTH * delta))
	apply_arm_length(_arm.get_hit_length())


func apply_arm_length(length: float) -> void:
	# Review Focus 3: камера упёрлась в стену и оказалась внутри кота — прячем модель.
	target.visible = length >= HIDE_BELOW


func yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)
```

`scenes/player/camera_rig.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/player/camera_rig.gd" id="1"]

[node name="CameraRig" type="Node3D"]
script = ExtResource("1")

[node name="SpringArm3D" type="SpringArm3D" parent="."]
spring_length = 3.5
margin = 0.1

[node name="Camera3D" type="Camera3D" parent="SpringArm3D"]
fov = 60.0
```
Коллизию самого кота `SpringArm3D` исключает в `cat.gd` `_ready()` (см. выше), поэтому в `Main` (задача 8) сначала задаётся `camera_rig`, потом кот добавляется в дерево.

- [ ] **Step 5: Запустить тесты**

Run: `make import && make test-godot`
Expected: 4 теста `test_cat_scene.gd` зелёные. Если `test_head_is_scaled` падает с нулевым масштабом, `SkeletonModifier3D` не активен: проверьте, что `HeadScaler` дочерний именно к `Skeleton3D` и `active = true`.

- [ ] **Step 6: Commit**

```bash
git add scripts/player scenes/player tests/integration/test_cat_scene.gd
git commit -m "Сцена кота с анимациями и чиби-головой, камера от третьего лица

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Двор-заглушка, главная сцена, скриншот результата

**Files:**
- Create: `tools/blender/gen/ground.py`, `tools/blender/gen/bin.py`, `scenes/world/district_yard.tscn`, `scripts/main.gd`
- Modify: `scenes/main.tscn`
- Test: `tests/integration/test_main.gd`

**Interfaces:**
- Consumes: `Cat`, `CameraRig`, `Toon`, `lighting.tscn`.
- Produces: `assets/models/ground.glb` (60×60 м), `assets/models/bin.glb` (мусорный бак 0,7×0,8×1,1 м), `district_yard.tscn` со `StaticBody3D` под землёй и 4 баками, 3 коробками; `Main` создаёт кота в `Marker3D` `Spawn`, связывает с камерой.

- [ ] **Step 1: Генераторы земли и бака**

`tools/blender/gen/ground.py`:
```python
"""Земля двора 60×60 м: асфальт с песочной каймой тротуара."""
import lib

SPEC = {"max_tris": 200, "max_dim": 60.0}


def build():
	asphalt = lib.rounded_box("ground", (60, 60, 0.1), bevel=0.0, material="asphalt")
	asphalt.location.z = -0.05
	walk = lib.rounded_box("sidewalk", (30, 30, 0.12), bevel=0.03, segments=2, material="sand")
	walk.location = (-10, 10, -0.04)
	return [asphalt, walk]
```

`tools/blender/gen/bin.py`:
```python
"""Мусорный бак 0,7×0,8×1,1 м, «надутый» к середине: корпус + крышка + 2 колеса."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.2}


def build():
	body = lib.rounded_box("bin", (0.7, 0.8, 0.95), bevel=0.04, segments=3, material="leaf")
	body.location.z = 0.55
	lid = lib.rounded_box("bin_lid", (0.74, 0.84, 0.12), bevel=0.04, segments=3, material="olive")
	lid.location.z = 1.06
	parts = [body, lid]
	for x in (-0.25, 0.25):
		wheel = lib.rounded_box(f"bin_wheel_{'l' if x < 0 else 'r'}", (0.12, 0.12, 0.12), bevel=0.05, segments=3, material="ink")
		wheel.location = (x, -0.35, 0.06)
		parts.append(wheel)
	for p in parts[1:]:
		p.parent = body
		p.matrix_parent_inverse = body.matrix_world.inverted()
	return parts
```

Run: `make assets && ls assets/models`
Expected: `ОК bin`, `ОК box`, `ОК cat`, `ОК ground`; четыре glb.

- [ ] **Step 2: Падающий тест главной сцены**

`tests/integration/test_main.gd`:
```gdscript
extends GutTest

const MainScene := preload("res://scenes/main.tscn")

func test_main_spawns_cat_linked_to_camera() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(2)
	var cat := main.find_child("Cat", true, false)
	var rig := main.find_child("CameraRig", true, false)
	assert_not_null(cat)
	assert_not_null(rig)
	assert_eq(cat.camera_rig, rig)
	assert_eq(rig.target, cat)
	assert_true((rig.get_node("SpringArm3D/Camera3D") as Camera3D).current)

func test_cat_lands_on_ground() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	var cat := main.find_child("Cat", true, false) as CharacterBody3D
	await wait_physics_frames(90)
	assert_true(cat.is_on_floor(), "кот должен стоять на земле через 1,5 с")
	assert_between(cat.global_position.y, -0.05, 0.1)
```

Run: `make test-godot`
Expected: падает (нет `Cat` в сцене).

- [ ] **Step 3: Сцена двора**

`scenes/world/district_yard.tscn`:
```
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://assets/models/ground.glb" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/bin.glb" id="2"]
[ext_resource type="PackedScene" path="res://assets/models/box.glb" id="3"]

[sub_resource type="BoxShape3D" id="floor"]
size = Vector3(60, 0.2, 60)

[sub_resource type="BoxShape3D" id="binshape"]
size = Vector3(0.74, 1.12, 0.84)

[sub_resource type="BoxShape3D" id="boxshape"]
size = Vector3(0.45, 0.3, 0.35)

[node name="DistrictYard" type="Node3D"]

[node name="Ground" parent="." instance=ExtResource("1")]

[node name="Floor" type="StaticBody3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="Floor"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.1, 0)
shape = SubResource("floor")

[node name="Bin1" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0, -4)
[node name="Model" parent="Bin1" instance=ExtResource("2")]
[node name="Shape" type="CollisionShape3D" parent="Bin1"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.56, 0)
shape = SubResource("binshape")

[node name="Bin2" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4, 0, -4)
[node name="Model" parent="Bin2" instance=ExtResource("2")]
[node name="Shape" type="CollisionShape3D" parent="Bin2"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.56, 0)
shape = SubResource("binshape")

[node name="Bin3" type="StaticBody3D" parent="."]
transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -6, 0, 2)
[node name="Model" parent="Bin3" instance=ExtResource("2")]
[node name="Shape" type="CollisionShape3D" parent="Bin3"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.56, 0)
shape = SubResource("binshape")

[node name="Bin4" type="StaticBody3D" parent="."]
transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -6, 0, 3)
[node name="Model" parent="Bin4" instance=ExtResource("2")]
[node name="Shape" type="CollisionShape3D" parent="Bin4"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.56, 0)
shape = SubResource("binshape")

[node name="Box1" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.5, 0, 1.5)
[node name="Model" parent="Box1" instance=ExtResource("3")]
[node name="Shape" type="CollisionShape3D" parent="Box1"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)
shape = SubResource("boxshape")

[node name="Box2" type="StaticBody3D" parent="."]
transform = Transform3D(0.7071, 0, 0.7071, 0, 1, 0, -0.7071, 0, 0.7071, -2, 0, -1)
[node name="Model" parent="Box2" instance=ExtResource("3")]
[node name="Shape" type="CollisionShape3D" parent="Box2"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)
shape = SubResource("boxshape")

[node name="Box3" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2, 0.3, 1.5)
[node name="Model" parent="Box3" instance=ExtResource("3")]
[node name="Shape" type="CollisionShape3D" parent="Box3"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)
shape = SubResource("boxshape")

[node name="Spawn" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
```

- [ ] **Step 4: Главная сцена и скрипт**

`scripts/main.gd`:
```gdscript
extends Node3D
## Собирает мир, кота и камеру.

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")


func _ready() -> void:
	Toon.apply($DistrictYard, Toon.OUTLINE_NONE)
	var rig := RigScene.instantiate()
	rig.name = "CameraRig"
	var cat := CatScene.instantiate()
	cat.name = "Cat"
	cat.camera_rig = rig
	rig.target = cat
	add_child(rig)
	add_child(cat)
	cat.global_position = $DistrictYard/Spawn.global_position
	rig.global_position = cat.global_position + Vector3(0, rig.HEIGHT, 0)
	(rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()
```

`scenes/main.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/world/lighting.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/world/district_yard.tscn" id="3"]

[node name="Main" type="Node3D"]
script = ExtResource("1")

[node name="Lighting" parent="." instance=ExtResource("2")]

[node name="DistrictYard" parent="." instance=ExtResource("3")]
```

- [ ] **Step 5: Тесты и скриншот**

Run: `make import && make test && make shot SHOT=build/task8.png`
Expected: все тесты зелёные (Blender + GUT). Откройте `build/task8.png`: рыжий кот с обводкой стоит на асфальте, баки и коробки с тун-тенями, небо градиентом. Если кот под землёй, проверьте `Spawn` y=0,3 и что `Floor` создан до кота.

- [ ] **Step 6: Проверка на чистом импорте (Review Focus 5)**

Run: `rm -rf .godot && make test`
Expected: `make import` идёт первым и тесты зелёные.

- [ ] **Step 7: Ручной прогон**

Run: `make run`
Проверить руками: WASD двигает кота относительно камеры, Shift ускоряет и анимация бежит быстрее, Space прыгает на коробку (0,3 м) и на нижний ящик, Q/R вращают камеру, у стен бака камера не залезает внутрь кота. Закрыть окно.

- [ ] **Step 8: Commit**

```bash
git add tools/blender/gen assets/models scenes scripts/main.gd tests/integration/test_main.gd
git commit -m "Двор-заглушка, главная сцена: кот, камера, свет

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## Готово, когда

- `make test` зелёный с нуля (`rm -rf .godot`).
- `make assets` пересобирает 4 glb без ошибок валидации.
- `make shot` даёт скриншот с котом, обводкой и тун-тенями.
- В `make run` кот ходит, бегает, прыгает, камера следует и не входит в модель.
- Следующий шаг: написать план 2 «Игровой цикл» по дорожной карте, опираясь на реальные интерфейсы `Cat`, `CameraRig`, `Toon`, `build.py`.

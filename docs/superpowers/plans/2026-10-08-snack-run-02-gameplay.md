# Snack Run, план 2: Игровой цикл

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Замкнуть цикл «нашёл еду → схватил → спрятался → съел → попал под опасность → потерял» в районе «двор» с собакой, осой и велосипедистом, HUD и раскладкой двора из JSON.

**Architecture:** Чистая логика (`GameState`, `Rarity`, `ChaseBrain`, `Perception`) без узлов и с юнит-тестами; узлы (`FoodPickup`, `FoodSpawnPoint`, `Hideout`, `HazardBase` + `Dog`/`Wasp`/`Cyclist`, `Hud`) общаются сигналами через автозагрузку `GameState`; двор строится `WorldBuilder` из `data/layout/yard.json`; все модели генерируются скриптами Blender (`tools/blender/gen/*.py`), собака берётся из CC0-пака Quaternius.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript, GUT 9.7.1, Blender 5.2.2 (bpy/bmesh), glTF, make. Опционально UniMate (CPU) для клипов собаки.

**Spec:** `docs/superpowers/specs/2026-10-07-snack-run-design.md` (разделы 2.5, 2.6, 3.1–3.6, 4, 5.1). Дорожная карта: `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`. Образец выполненного плана: `docs/superpowers/plans/2026-10-07-snack-run-01-foundation.md`. Памятка с граблями: `CLAUDE.md`.

## Global Constraints

- Godot 4.7.2, GDScript, Forward+; `GODOT=/Applications/Godot.app/Contents/MacOS/Godot`, `BLENDER=/Applications/Blender.app/Contents/MacOS/Blender`.
- Модели только скриптами Blender; glTF 1 ед = 1 м, +Y вверх, `assets/models/<имя>.glb`; цвета только из палитры `tools/blender/palette.py`; полигонаж: пропс 100–800 треугольников, персонаж до 2500.
- Анимации: готовые бесплатные (CC0/CC-BY) → UniMate → генерация скриптом в последнюю очередь. Платные ассеты запрещены.
- Тун-обводка: `Toon.OUTLINE_CHARACTER = 0.006` (кот, опасности), `Toon.OUTLINE_FOOD = 0.004` (еда и интерактивные пропсы), пропсы без обводки.
- Слои коллизий (bit-значения), одинаковые во всех задачах: `Layers.WORLD = 1` (пол, пропсы), `Layers.CAT = 2`, `Layers.HAZARD = 4` (тела опасностей), `Layers.AREA = 8` (еда, укрытия, hit-зоны). Кот: layer 2, mask 1|4. Опасности: layer 4, mask 1. Все Area3D: layer 8, mask 2.
- Удар (спек 3.2): еда из зубов разлетается на 1–2 м и лежит 5 с; −1 сердечко; отброс 1,5 м; оглушение 1 с; неуязвимость 2 с. Ноль сердечек: затемнение, возрождение с полными сердечками, еда в зубах потеряна. Съедание восстанавливает 1 сердечко (за одно действие «съесть»).
- Собака: конус 90°, 6 м; насторожилась 1 с; бег 1,2× скорости кота (4,8 м/с); теряет след через 2 с непрерывного укрытия или 8 с погони; возвращается спать. Оса: кружит радиусом 2–3 м у сладкой еды, жалит касанием, не преследует. Велосипедист: сплайн дороги, интервал 12–20 с, звонок за 2 с.
- Еда: 8 видов и редкости по спеку 3.3; веса спавна 60/25/12/3; сытость 1/3/6/15; зубы вмещают 3; респавн 30–90 с.
- Все тексты на русском, идентификаторы на английском; коммиты с `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Каждый коммит, добавляющий `.glb` или `.gd`, добавляет и соответствующие `*.import` / `*.uid` (они отслеживаются git).
- В интеграционных тестах, трогающих `GameState`, в `before_each()` вызывается `GameState.reset()`.

## Отклонения от спека, принятые заранее (владелец видит их в этом плане)

- Возрождение у маркера `Spawn` двора; магазин пряжи как точка возрождения — план 3.
- Цель сессии: первая «открой 3 карточки», затем +2 к цели каждый раз (спек задаёт только первую).
- Шрифт по умолчанию Godot вместо Nunito, иконки еды — цветные плашки с названием; оформление — план 4.
- Спрятанный кот неуязвим для всех опасностей (спек говорит про собаку; оса и велосипедист в укрытие тоже не достают).
- Спящая собака играет клип idle, если UniMate-клип «лежит» не получится (задача 14).

## Review Focus

1. Подбор еды с полным ртом (3 штуки): еда остаётся лежать, ничего не исчезает, счётчик не растёт. Тест в задаче 4.
2. «Съесть» с пустым ртом: ничего не происходит, сердечко не восстанавливается, сытость не растёт. Тест в задаче 3.
3. Рассыпанная при ударе еда появляется прямо на коте: она не должна подбираться тем же кадром; 0,5 с запрета подбора. Тест в задаче 6.
4. Обморок, пока кот в укрытии (спрятанный кот неуязвим для опасностей, но обморок может прийти из других источников, например из будущих событий): кот должен выйти из укрытия, камера вернуться на обычную высоту, иначе возрождение «в присяде». Тест в задаче 6.
5. Собака теряет след только после 2 с *непрерывного* укрытия: выглянул на 0,5 с — счётчик сбрасывается. Тест в задаче 9.

---

## Структура файлов

```
scripts/core/layers.gd            # константы слоёв
scripts/core/rarity.gd            # Rarity: Tier, веса, сытость, цвета, pick_weighted
scripts/food/food_def.gd          # FoodDef (Resource)
scripts/food/food_catalog.gd      # FoodCatalog: загрузка data/food/*.tres
scripts/food/food_pickup.gd       # FoodPickup (Area3D)
scripts/food/food_spawn_point.gd  # FoodSpawnPoint (Node3D)
scripts/autoload/game_state.gd    # GameState (автозагрузка)
scripts/hideouts/hideout.gd       # Hideout (Area3D)
scripts/hazards/perception.gd     # Perception.in_cone
scripts/hazards/chase_brain.gd    # ChaseBrain FSM
scripts/hazards/hazard_base.gd    # HazardBase (CharacterBody3D)
scripts/hazards/dog.gd  wasp.gd  cyclist.gd
scripts/ui/hud.gd                 # Hud (CanvasLayer)
scripts/world/world_builder.gd    # WorldBuilder: JSON → узлы
scripts/player/cat.gd             # + hide/eat/take_hit/teleport
scripts/player/camera_rig.gd      # + crouch
scripts/main.gd                   # + HUD, разлёт еды, обморок
scenes/food/food_pickup.tscn  food_spawn_point.tscn
scenes/hideouts/hideout.tscn
scenes/hazards/dog.tscn  wasp.tscn  cyclist.tscn
scenes/ui/hud.tscn
scenes/world/district_yard.tscn   # Ground/Floor/Spawn/WorldBuilder, без ручных пропсов
data/food/*.tres (8)              # ресурсы еды
data/layout/yard.json             # раскладка двора
tools/blender/lib.py              # + cylinder/sphere/cone/torus/wedge
tools/blender/rig_utils.py        # face_forward, fcurves, split_material_by_height
tools/blender/dog.py  gen/dog.py  gen/wasp.py  gen/cyclist.py
tools/blender/gen/food_*.py (8)   # модели еды
tools/blender/gen/{bench,lamp,car,wall,fence,bag,stairs,bush,tree,puddle,arch,door}.py
tests/unit/test_rarity.gd  test_game_state.gd  test_perception.gd  test_chase_brain.gd
tests/integration/test_food.gd  test_hideout.gd  test_hit.gd  test_hud.gd  test_world_builder.gd
tests/integration/test_dog.gd  test_wasp.gd  test_cyclist.gd  test_dog_asset.gd
```

Цикл становится играбельным после задачи 10 (еда, укрытия, удар, HUD, двор из JSON, собака). Задачи 11–15 добавляют осу, велосипедиста, пропсы, клипы собаки и документацию.

---

### Task 1: Слои, редкости, ресурс еды, каталог

**Files:**
- Create: `scripts/core/layers.gd`, `scripts/core/rarity.gd`, `scripts/food/food_def.gd`, `scripts/food/food_catalog.gd`, `data/food/{sausage,cookie,pizza,hotdog,croissant,fish,donut,ice_cream}.tres`
- Test: `tests/unit/test_rarity.gd`

**Interfaces:**
- Produces: `Layers.WORLD/CAT/HAZARD/AREA: int`; `Rarity.Tier {COMMON, RARE, VERY_RARE, LEGENDARY}`, `Rarity.WEIGHTS`, `Rarity.SATIETY`, `Rarity.COLORS`, `Rarity.NAMES`, `Rarity.pick_weighted(allowed: Array, rng: RandomNumberGenerator) -> int`; `FoodDef` (Resource) с полями `id: StringName`, `display_name: String`, `tier: int`, `model_path: String`, `sweet: bool`, метод `satiety() -> int`; `FoodCatalog.all() -> Array[FoodDef]`, `FoodCatalog.by_tier(tier: int) -> Array[FoodDef]`, `FoodCatalog.get_by_id(id: StringName) -> FoodDef`.

- [ ] **Step 1: Падающий тест**

`tests/unit/test_rarity.gd`:
```gdscript
extends GutTest

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func test_weights_follow_spec() -> void:
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.COMMON], 60)
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.RARE], 25)
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.VERY_RARE], 12)
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.LEGENDARY], 3)
	assert_eq(Rarity.SATIETY[Rarity.Tier.LEGENDARY], 15)

func test_pick_weighted_proportions() -> void:
	var rng := _rng(7)
	var counts := {0: 0, 1: 0, 2: 0, 3: 0}
	for i in 10000:
		counts[Rarity.pick_weighted([0, 1, 2, 3], rng)] += 1
	assert_between(counts[0] / 10000.0, 0.57, 0.63, "обычная ~60%")
	assert_between(counts[3] / 10000.0, 0.02, 0.045, "легендарная ~3%")

func test_pick_weighted_respects_allowed() -> void:
	var rng := _rng(1)
	for i in 200:
		var t := Rarity.pick_weighted([Rarity.Tier.RARE, Rarity.Tier.LEGENDARY], rng)
		assert_true(t == Rarity.Tier.RARE or t == Rarity.Tier.LEGENDARY)

func test_pick_weighted_empty_gives_common() -> void:
	assert_eq(Rarity.pick_weighted([], _rng(1)), Rarity.Tier.COMMON)

func test_catalog_has_eight_foods_two_per_tier() -> void:
	assert_eq(FoodCatalog.all().size(), 8)
	for t in 4:
		assert_eq(FoodCatalog.by_tier(t).size(), 2, "по две еды в редкости %d" % t)
	var donut := FoodCatalog.get_by_id(&"donut")
	assert_not_null(donut)
	assert_eq(donut.tier, Rarity.Tier.LEGENDARY)
	assert_true(donut.sweet)
	assert_eq(donut.satiety(), 15)
	assert_eq(donut.display_name, "Пончик")
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: `Identifier "Rarity" not declared` (ошибка парсинга), прогон красный.

- [ ] **Step 3: Реализация**

`scripts/core/layers.gd`:
```gdscript
class_name Layers
extends RefCounted
## Bit-значения слоёв коллизий (одни на весь проект).

const WORLD := 1
const CAT := 2
const HAZARD := 4
const AREA := 8
```

`scripts/core/rarity.gd`:
```gdscript
class_name Rarity
extends RefCounted
## Редкости еды: веса спавна, сытость, цвета (спек 2.2, 3.3, 3.4).

enum Tier { COMMON, RARE, VERY_RARE, LEGENDARY }

const WEIGHTS := {Tier.COMMON: 60, Tier.RARE: 25, Tier.VERY_RARE: 12, Tier.LEGENDARY: 3}
const SATIETY := {Tier.COMMON: 1, Tier.RARE: 3, Tier.VERY_RARE: 6, Tier.LEGENDARY: 15}
const COLORS := {
	Tier.COMMON: Color("#4D945B"),
	Tier.RARE: Color("#6491E4"),
	Tier.VERY_RARE: Color("#C473D4"),
	Tier.LEGENDARY: Color("#FABE32"),
}
const NAMES := {Tier.COMMON: "Обычная", Tier.RARE: "Редкая", Tier.VERY_RARE: "Очень редкая", Tier.LEGENDARY: "Легендарная"}


static func pick_weighted(allowed: Array, rng: RandomNumberGenerator) -> int:
	if allowed.is_empty():
		return Tier.COMMON
	var total := 0
	for t in allowed:
		total += WEIGHTS[t]
	var roll := rng.randi_range(1, total)
	for t in allowed:
		roll -= WEIGHTS[t]
		if roll <= 0:
			return t
	return allowed[-1]
```

`scripts/food/food_def.gd`:
```gdscript
class_name FoodDef
extends Resource
## Описание вкусняшки (данные, не код). Файлы в data/food/*.tres.

@export var id: StringName = &""
@export var display_name := ""
@export var tier: Rarity.Tier = Rarity.Tier.COMMON
@export var model_path := ""     # res://assets/models/food_<id>.glb; пусто = сфера-заглушка
@export var sweet := false       # вокруг сладкого кружит оса


func satiety() -> int:
	return Rarity.SATIETY[tier]
```

`scripts/food/food_catalog.gd`:
```gdscript
class_name FoodCatalog
extends RefCounted
## Загружает все FoodDef из data/food.

const DIR := "res://data/food"
static var _cache: Array[FoodDef] = []


static func all() -> Array[FoodDef]:
	if _cache.is_empty():
		var names := DirAccess.get_files_at(DIR)
		for n in names:
			if n.ends_with(".tres"):
				var res := load(DIR + "/" + n)
				if res is FoodDef:
					_cache.append(res)
		_cache.sort_custom(func(a: FoodDef, b: FoodDef) -> bool: return a.id < b.id)
	return _cache


static func by_tier(tier: int) -> Array[FoodDef]:
	var out: Array[FoodDef] = []
	for f in all():
		if f.tier == tier:
			out.append(f)
	return out


static func get_by_id(id: StringName) -> FoodDef:
	for f in all():
		if f.id == id:
			return f
	return null
```

Восемь ресурсов. `data/food/sausage.tres`:
```
[gd_resource type="Resource" script_class="FoodDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/food/food_def.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"sausage"
display_name = "Сосиска"
tier = 0
model_path = "res://assets/models/food_sausage.glb"
sweet = false
```
`data/food/cookie.tres` — то же с `id = &"cookie"`, `display_name = "Печенье"`, `tier = 0`, `model_path = "res://assets/models/food_cookie.glb"`, `sweet = true`.
`data/food/pizza.tres` — `&"pizza"`, `"Пицца"`, `tier = 1`, `food_pizza.glb`, `sweet = false`.
`data/food/hotdog.tres` — `&"hotdog"`, `"Хот-дог"`, `tier = 1`, `food_hotdog.glb`, `sweet = false`.
`data/food/croissant.tres` — `&"croissant"`, `"Круассан"`, `tier = 2`, `food_croissant.glb`, `sweet = false`.
`data/food/fish.tres` — `&"fish"`, `"Рыба"`, `tier = 2`, `food_fish.glb`, `sweet = false`.
`data/food/donut.tres` — `&"donut"`, `"Пончик"`, `tier = 3`, `food_donut.glb`, `sweet = true`.
`data/food/ice_cream.tres` — `&"ice_cream"`, `"Мороженое"`, `tier = 3`, `food_ice_cream.glb`, `sweet = true`.
(Каждый файл — полная копия шаблона с заменёнными пятью строками; блок `[ext_resource]` и `script = ExtResource("1")` одинаковые.)

- [ ] **Step 4: GREEN**

Run: `make test-godot`
Expected: 5 тестов `test_rarity.gd` зелёные, остальные не сломаны (29 + 5).

- [ ] **Step 5: Commit**

```bash
git add scripts/core scripts/food data/food tests/unit/test_rarity.gd
git commit -m "Слои коллизий, редкости, ресурс еды и каталог из 8 вкусняшек

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Примитивы Blender и модели еды

**Files:**
- Modify: `tools/blender/lib.py` (добавить функции), `tools/blender/tests/test_lib.py`
- Create: `tools/blender/gen/food_sausage.py`, `food_cookie.py`, `food_pizza.py`, `food_hotdog.py`, `food_croissant.py`, `food_fish.py`, `food_donut.py`, `food_ice_cream.py`

**Interfaces:**
- Produces: `lib.cylinder(name, radius, depth, segments=16, material=None, smooth=True)`, `lib.sphere(name, radius, material=None, segments=12, rings=8, smooth=True)`, `lib.cone(name, radius, depth, segments=12, material=None, smooth=True)`, `lib.torus(name, major, minor, material=None)`, `lib.wedge(name, width, length, height, material=None)`, `lib.group(parts) -> parts` (делает первый объект родителем остальных). Все примитивы центрированы в начале координат; еда ставится основанием на z=0. Файлы `assets/models/food_<id>.glb`, каждый ≤ 400 треугольников, наибольший габарит ≤ 0,3 м.

- [ ] **Step 1: Падающие тесты примитивов**

Добавить в `tools/blender/tests/test_lib.py` класс:
```python
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
```

- [ ] **Step 2: RED**

Run: `make test-blender`
Expected: `AttributeError: module 'lib' has no attribute 'cylinder'` (4 ошибки).

- [ ] **Step 3: Реализация примитивов**

Добавить в `tools/blender/lib.py` после `rounded_box`:
```python
def _finish(name, bm, material=None, smooth=False):
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	if smooth:
		for p in mesh.polygons:
			p.use_smooth = True
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	if material:
		mesh.materials.append(palette.get_material(material))
	bpy.context.view_layer.update()
	return obj


def cylinder(name, radius, depth, segments=16, material=None, smooth=True):
	bm = bmesh.new()
	bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
	                      radius1=radius, radius2=radius, depth=depth)
	return _finish(name, bm, material, smooth)


def cone(name, radius, depth, segments=12, material=None, smooth=True):
	bm = bmesh.new()
	bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
	                      radius1=radius, radius2=0.0, depth=depth)
	return _finish(name, bm, material, smooth)


def sphere(name, radius, material=None, segments=12, rings=8, smooth=True):
	bm = bmesh.new()
	bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
	return _finish(name, bm, material, smooth)


def torus(name, major, minor, material=None):
	bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
	                                 major_segments=16, minor_segments=8)
	obj = bpy.context.object
	obj.name = name
	obj.data.name = name
	for p in obj.data.polygons:
		p.use_smooth = True
	if material:
		obj.data.materials.append(palette.get_material(material))
	bpy.context.view_layer.update()
	return obj


def wedge(name, width, length, height, material=None):
	"""Треугольная призма (ломтик пиццы): острый угол в начале координат, основание на +Y."""
	bm = bmesh.new()
	h = height / 2.0
	v = [bm.verts.new(c) for c in (
		(0, 0, -h), (-width / 2, length, -h), (width / 2, length, -h),
		(0, 0, h), (-width / 2, length, h), (width / 2, length, h))]
	bm.faces.new((v[0], v[2], v[1]))
	bm.faces.new((v[3], v[4], v[5]))
	bm.faces.new((v[0], v[1], v[4], v[3]))
	bm.faces.new((v[1], v[2], v[5], v[4]))
	bm.faces.new((v[2], v[0], v[3], v[5]))
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	return _finish(name, bm, material, smooth=False)


def group(parts):
	"""Первый объект становится родителем остальных (мировые позиции сохраняются)."""
	root = parts[0]
	for p in parts[1:]:
		p.parent = root
		p.matrix_parent_inverse = root.matrix_world.inverted()
	return parts
```

- [ ] **Step 4: GREEN**

Run: `make test-blender`
Expected: `Ran 12 tests ... OK`. Если `create_cone` ругается на имена аргументов, напечатать `bmesh.ops.create_cone.__doc__`. Если `primitive_torus_add` не работает в фоне, собрать тор через `bmesh.ops.spin` окружности из `create_circle` (360°, 16 шагов).

- [ ] **Step 5: Восемь генераторов еды**

`tools/blender/gen/food_sausage.py`:
```python
"""Сосиска 0,2 м."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	body = lib.cylinder("food_sausage", radius=0.03, depth=0.2, material="brick")
	body.rotation_euler = (1.5708, 0, 0)
	body.location.z = 0.03
	return [body]
```
`tools/blender/gen/food_cookie.py`:
```python
"""Печенье: диск с тремя «шоколадными» точками."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	disc = lib.cylinder("food_cookie", radius=0.07, depth=0.02, material="sand")
	disc.location.z = 0.01
	parts = [disc]
	for i, (x, y) in enumerate(((0.02, 0.02), (-0.03, 0.01), (0.0, -0.03))):
		dot = lib.sphere(f"food_cookie_dot{i}", radius=0.012, material="ink")
		dot.location = (x, y, 0.022)
		parts.append(dot)
	return lib.group(parts)
```
`tools/blender/gen/food_pizza.py`:
```python
"""Ломтик пиццы: тесто-клин, корка, две пепперони."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	base = lib.wedge("food_pizza", width=0.18, length=0.25, height=0.02, material="cat_orange")
	base.location.z = 0.01
	crust = lib.cylinder("food_pizza_crust", radius=0.018, depth=0.18, material="sand")
	crust.rotation_euler = (0, 1.5708, 0)
	crust.location = (0, 0.245, 0.02)
	parts = [base, crust]
	for i, (x, y) in enumerate(((0.03, 0.17), (-0.03, 0.12))):
		p = lib.cylinder(f"food_pizza_pep{i}", radius=0.022, depth=0.006, material="brick", segments=10)
		p.location = (x, y, 0.023)
		parts.append(p)
	return lib.group(parts)
```
`tools/blender/gen/food_hotdog.py`:
```python
"""Хот-дог: булка и сосиска."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	bun = lib.rounded_box("food_hotdog", (0.22, 0.08, 0.06), bevel=0.02, segments=3, material="sand")
	bun.location.z = 0.03
	sausage = lib.cylinder("food_hotdog_sausage", radius=0.022, depth=0.24, material="brick")
	sausage.rotation_euler = (0, 1.5708, 0)
	sausage.location.z = 0.065
	return lib.group([bun, sausage])
```
`tools/blender/gen/food_croissant.py`:
```python
"""Круассан: три сегмента дугой."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	parts = []
	for i, (ang, size) in enumerate(((-0.6, 0.05), (0.0, 0.07), (0.6, 0.05))):
		seg = lib.rounded_box("food_croissant" if i == 1 else f"food_croissant_{i}",
		                      (0.07, size, size), bevel=0.02, segments=3, material="cat_orange")
		seg.location = (math.sin(ang) * 0.07, math.cos(ang) * 0.02 - 0.02, size / 2)
		seg.rotation_euler = (0, 0, -ang)
		parts.append(seg)
	return lib.group([parts[1], parts[0], parts[2]])
```
`tools/blender/gen/food_fish.py`:
```python
"""Рыба: сплющенная сфера и хвост-клин."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	body = lib.sphere("food_fish", radius=0.06, material="sky")
	body.scale = (1.0, 1.8, 0.6)
	body.location.z = 0.036
	tail = lib.wedge("food_fish_tail", width=0.08, length=0.06, height=0.015, material="sea_deep")
	tail.rotation_euler = (0, 0, 3.14159)
	tail.location = (0, -0.1, 0.036)
	return lib.group([body, tail])
```
`tools/blender/gen/food_donut.py`:
```python
"""Пончик с розовой глазурью: тор + тонкий тор сверху."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	ring = lib.torus("food_donut", major=0.07, minor=0.03, material="sand")
	ring.location.z = 0.03
	glaze = lib.torus("food_donut_glaze", major=0.07, minor=0.022, material="coral")
	glaze.location.z = 0.045
	return lib.group([ring, glaze])
```
`tools/blender/gen/food_ice_cream.py`:
```python
"""Мороженое: рожок и шарик."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cone = lib.cone("food_ice_cream", radius=0.04, depth=0.13, material="sand")
	cone.rotation_euler = (3.14159, 0, 0)
	cone.location.z = 0.065
	scoop = lib.sphere("food_ice_cream_scoop", radius=0.045, material="lilac")
	scoop.location.z = 0.15
	return lib.group([cone, scoop])
```

- [ ] **Step 6: Сборка и проверка**

Run: `make assets && ls assets/models | grep food_ | wc -l`
Expected: 8 строк `ОК food_*`, 8 файлов. В `make assets` валидация габаритов и треугольников проходит (`max_dim` 0,3).

Визуальная проверка: собрать все 8 на одной сцене и отрендерить:
```bash
$BLENDER -b --python-exit-code 1 --python-expr "
import bpy, glob, math
bpy.ops.wm.read_homefile(use_empty=True)
for i, f in enumerate(sorted(glob.glob('assets/models/food_*.glb'))):
    before = set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=f)
    for o in bpy.data.objects:
        if o not in before and o.parent is None: o.location.x = i * 0.35
sc = bpy.context.scene
cam = bpy.data.objects.new('Cam', bpy.data.cameras.new('Cam')); sc.collection.objects.link(cam)
cam.location = (1.2, -1.6, 0.9); cam.rotation_euler = (math.radians(62), 0, math.radians(20)); sc.camera = cam
sun = bpy.data.objects.new('Sun', bpy.data.lights.new('Sun', 'SUN')); sc.collection.objects.link(sun); sun.rotation_euler = (0.8, 0.2, 0.5)
sc.render.resolution_x = 1280; sc.render.resolution_y = 480
sc.render.filepath = 'build/food_sheet.png'; bpy.ops.render.render(write_still=True)"
```
Открыть `build/food_sheet.png` (Read): восемь узнаваемых предметов в ряд, ничего не провалилось под z=0.

- [ ] **Step 7: Commit**

```bash
git add tools/blender/lib.py tools/blender/tests/test_lib.py tools/blender/gen/food_*.py assets/models/food_*.glb assets/models/food_*.glb.import
git commit -m "Примитивы Blender (цилиндр, сфера, конус, тор, клин) и 8 моделей еды

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
(`.import` появятся после `make import`; если их ещё нет, выполнить `make import` перед `git add`.)

---

### Task 3: GameState

**Files:**
- Create: `scripts/autoload/game_state.gd`
- Modify: `project.godot` (добавить автозагрузку `GameState="*res://scripts/autoload/game_state.gd"` в секцию `[autoload]` после `DevTools`)
- Test: `tests/unit/test_game_state.gd`

**Interfaces:**
- Produces (автозагрузка `GameState`, без `class_name`): сигналы `hearts_changed(hearts: int, max_hearts: int)`, `mouth_changed(items: Array)`, `satiety_changed(value: int)`, `album_changed(album: Dictionary)`, `food_eaten(items: Array)`, `cat_hit(spilled: Array)`, `cat_fainted()`, `goal_changed(done: int, target: int)`, `goal_completed(target: int)`; константы `MAX_HEARTS = 3`, `MOUTH_CAPACITY = 3`, `GOAL_FIRST = 3`, `GOAL_STEP = 2`, `SATIETY_GATE = 10`; переменные `hearts`, `max_hearts`, `mouth: Array[FoodDef]`, `mouth_capacity`, `satiety: int`, `album: Dictionary`, `goal_target`, `goal_done`; методы `reset() -> void`, `pick_up(food: FoodDef) -> bool`, `eat_all() -> Array[FoodDef]`, `spill() -> Array[FoodDef]`, `take_hit() -> bool` (true = обморок), `revive() -> void`, `album_count() -> int`, `mouth_full() -> bool`.

- [ ] **Step 1: Падающий тест**

`tests/unit/test_game_state.gd`:
```gdscript
extends GutTest

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var gs: Node
var sausage: FoodDef
var donut: FoodDef

func before_each() -> void:
	gs = GameStateScript.new()
	add_child_autofree(gs)
	sausage = FoodCatalog.get_by_id(&"sausage")
	donut = FoodCatalog.get_by_id(&"donut")

func test_initial_state() -> void:
	assert_eq(gs.hearts, 3)
	assert_eq(gs.mouth.size(), 0)
	assert_eq(gs.satiety, 0)
	assert_eq(gs.goal_target, 3)

func test_pick_up_until_full() -> void:
	watch_signals(gs)
	assert_true(gs.pick_up(sausage))
	assert_true(gs.pick_up(sausage))
	assert_true(gs.pick_up(donut))
	assert_true(gs.mouth_full())
	assert_false(gs.pick_up(sausage), "четвёртая не помещается")
	assert_eq(gs.mouth.size(), 3)
	assert_signal_emit_count(gs, "mouth_changed", 3)

func test_eat_all_adds_satiety_album_and_one_heart() -> void:
	gs.hearts = 1
	gs.pick_up(sausage)
	gs.pick_up(donut)
	watch_signals(gs)
	var eaten := gs.eat_all()
	assert_eq(eaten.size(), 2)
	assert_eq(gs.mouth.size(), 0)
	assert_eq(gs.satiety, 1 + 15)
	assert_eq(gs.album[&"sausage"], 1)
	assert_eq(gs.album[&"donut"], 1)
	assert_eq(gs.hearts, 2, "ровно +1 сердечко за съедание")
	assert_signal_emitted(gs, "food_eaten")
	assert_signal_emitted(gs, "satiety_changed")

func test_eat_with_empty_mouth_is_noop() -> void:
	# Review Focus 2
	gs.hearts = 2
	watch_signals(gs)
	assert_eq(gs.eat_all().size(), 0)
	assert_eq(gs.hearts, 2)
	assert_eq(gs.satiety, 0)
	assert_signal_not_emitted(gs, "food_eaten")

func test_eat_does_not_exceed_max_hearts() -> void:
	gs.pick_up(sausage)
	gs.eat_all()
	assert_eq(gs.hearts, 3)

func test_take_hit_spills_and_costs_heart() -> void:
	gs.pick_up(sausage)
	gs.pick_up(donut)
	watch_signals(gs)
	var fainted := gs.take_hit()
	assert_false(fainted)
	assert_eq(gs.hearts, 2)
	assert_eq(gs.mouth.size(), 0)
	var spilled: Array = get_signal_parameters(gs, "cat_hit")[0]
	assert_eq(spilled.size(), 2)

func test_third_hit_faints_and_revive_restores() -> void:
	gs.take_hit()
	gs.take_hit()
	watch_signals(gs)
	assert_true(gs.take_hit())
	assert_signal_emitted(gs, "cat_fainted")
	assert_eq(gs.hearts, 0)
	gs.pick_up(sausage)
	gs.revive()
	assert_eq(gs.hearts, 3)
	assert_eq(gs.mouth.size(), 0, "еда в зубах теряется")

func test_goal_counts_only_new_cards_and_advances() -> void:
	watch_signals(gs)
	for i in 3:
		gs.pick_up(sausage)
		gs.eat_all()
	assert_eq(gs.goal_done, 1, "три сосиски = одна новая карточка")
	gs.pick_up(donut)
	gs.eat_all()
	gs.pick_up(FoodCatalog.get_by_id(&"fish"))
	gs.eat_all()
	assert_signal_emitted(gs, "goal_completed")
	assert_eq(gs.goal_target, 5)
	assert_eq(gs.goal_done, 0)

func test_reset_clears_everything() -> void:
	gs.pick_up(sausage)
	gs.eat_all()
	gs.take_hit()
	gs.reset()
	assert_eq(gs.hearts, 3)
	assert_eq(gs.satiety, 0)
	assert_eq(gs.album.size(), 0)
	assert_eq(gs.goal_target, 3)
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: ошибка загрузки `res://scripts/autoload/game_state.gd` (нет файла), прогон красный.

- [ ] **Step 3: Реализация**

`scripts/autoload/game_state.gd`:
```gdscript
extends Node
## Состояние игрока: сердечки, еда в зубах, сытость, альбом, цель сессии (спек 3.2–3.6).
## Автозагрузка GameState. В тестах создаётся свежий экземпляр этого скрипта.

signal hearts_changed(hearts: int, max_hearts: int)
signal mouth_changed(items: Array)
signal satiety_changed(value: int)
signal album_changed(album: Dictionary)
signal food_eaten(items: Array)
signal cat_hit(spilled: Array)
signal cat_fainted()
signal goal_changed(done: int, target: int)
signal goal_completed(target: int)

const MAX_HEARTS := 3
const MOUTH_CAPACITY := 3
const GOAL_FIRST := 3
const GOAL_STEP := 2
const SATIETY_GATE := 10   # сытость, открывающая арку в кафе (план 3)

var max_hearts := MAX_HEARTS
var hearts := MAX_HEARTS
var mouth_capacity := MOUTH_CAPACITY
var mouth: Array[FoodDef] = []
var satiety := 0
var album := {}          # id -> сколько раз съедено
var goal_target := GOAL_FIRST
var goal_done := 0       # новых карточек с начала текущей цели


func reset() -> void:
	max_hearts = MAX_HEARTS
	hearts = MAX_HEARTS
	mouth_capacity = MOUTH_CAPACITY
	mouth = []
	satiety = 0
	album = {}
	goal_target = GOAL_FIRST
	goal_done = 0
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	goal_changed.emit(goal_done, goal_target)


func mouth_full() -> bool:
	return mouth.size() >= mouth_capacity


func pick_up(food: FoodDef) -> bool:
	if mouth_full():
		return false
	mouth.append(food)
	mouth_changed.emit(mouth)
	return true


func eat_all() -> Array[FoodDef]:
	if mouth.is_empty():
		return []
	var eaten: Array[FoodDef] = mouth.duplicate()
	mouth = []
	for f in eaten:
		satiety += f.satiety()
		if not album.has(f.id):
			album[f.id] = 0
			goal_done += 1
		album[f.id] += 1
	hearts = mini(hearts + 1, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	hearts_changed.emit(hearts, max_hearts)
	food_eaten.emit(eaten)
	if goal_done >= goal_target:
		var finished := goal_target
		goal_target += GOAL_STEP
		goal_done = 0
		goal_completed.emit(finished)
	goal_changed.emit(goal_done, goal_target)
	return eaten


func spill() -> Array[FoodDef]:
	var spilled: Array[FoodDef] = mouth.duplicate()
	mouth = []
	mouth_changed.emit(mouth)
	return spilled


func take_hit() -> bool:
	var spilled := spill()
	hearts = maxi(hearts - 1, 0)
	hearts_changed.emit(hearts, max_hearts)
	cat_hit.emit(spilled)
	if hearts == 0:
		cat_fainted.emit()
		return true
	return false


func revive() -> void:
	hearts = max_hearts
	mouth = []
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)


func album_count() -> int:
	return album.size()
```

В `project.godot`, секция `[autoload]`, добавить строку:
```ini
GameState="*res://scripts/autoload/game_state.gd"
```

- [ ] **Step 4: GREEN**

Run: `make test-godot`
Expected: 9 тестов `test_game_state.gd` зелёные.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_state.gd scripts/autoload/game_state.gd.uid project.godot tests/unit/test_game_state.gd tests/unit/test_game_state.gd.uid
git commit -m "GameState: сердечки, зубы, сытость, альбом, цель сессии

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Подбираемая еда и точки спавна

**Files:**
- Create: `scripts/food/food_pickup.gd`, `scenes/food/food_pickup.tscn`, `scripts/food/food_spawn_point.gd`, `scenes/food/food_spawn_point.tscn`
- Modify: `scripts/player/cat.gd` (слои, группа `cat`)
- Test: `tests/integration/test_food.gd`

**Interfaces:**
- Consumes: `GameState.pick_up/mouth/mouth_full/reset`, `FoodDef`, `FoodCatalog`, `Rarity.COLORS`, `Toon.apply`, `Layers`.
- Produces: `FoodPickup` (Area3D, `scenes/food/food_pickup.tscn`): `food: FoodDef`, `spilled: bool`, `lifetime: float` (0 = вечно), `grace: float`, `signal picked(food: FoodDef, pickup: FoodPickup)`, `func setup(def: FoodDef, is_spilled := false, life := 0.0) -> void`, константа `SPILL_GRACE = 0.5`; `FoodSpawnPoint` (Node3D, `scenes/food/food_spawn_point.tscn`): `allowed: Array` (int-ы редкостей, без типизации, чтобы присваивать из тестов и JSON), `respawn_min: float = 30`, `respawn_max: float = 90`, `rng: RandomNumberGenerator`, `current: FoodPickup`, `func spawn_now() -> FoodPickup`, `func pick_def() -> FoodDef`, сигнал `spawned(pickup: FoodPickup)`. Кот: `collision_layer = Layers.CAT`, `collision_mask = Layers.WORLD | Layers.HAZARD`, в группе `"cat"`.

- [ ] **Step 1: Падающий тест**

`tests/integration/test_food.gd`:
```gdscript
extends GutTest

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const SpawnScene := preload("res://scenes/food/food_spawn_point.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)

func _cat_at(pos: Vector3) -> Node:
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = pos
	return cat

func _pickup(id: StringName, pos: Vector3) -> Node:
	var p = PickupScene.instantiate()
	p.setup(FoodCatalog.get_by_id(id))
	world.add_child(p)
	p.global_position = pos
	return p

func test_cat_picks_up_food_on_contact() -> void:
	var p = _pickup(&"sausage", Vector3(0, 0.05, 0))
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 1)
	assert_true(not is_instance_valid(p) or p.is_queued_for_deletion(), "еда исчезла")

func test_full_mouth_leaves_food_in_place() -> void:
	# Review Focus 1
	for i in 3:
		GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	var p = _pickup(&"sausage", Vector3(0, 0.05, 0))
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 3)
	assert_true(is_instance_valid(p) and not p.is_queued_for_deletion(), "еда лежит дальше")

func test_spilled_food_has_grace_then_expires() -> void:
	var p = PickupScene.instantiate()
	p.setup(FoodCatalog.get_by_id(&"fish"), true, 0.6)
	world.add_child(p)
	p.global_position = Vector3(0, 0.05, 0)
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(3)
	assert_eq(GameState.mouth.size(), 0, "в первые 0,5 с не подбирается")
	await wait_seconds(0.7)
	assert_true(not is_instance_valid(p) or p.is_queued_for_deletion(), "истёк срок жизни")

func test_pickup_visual_has_ring_in_rarity_color() -> void:
	var p = _pickup(&"donut", Vector3(5, 0, 5))
	await wait_process_frames(1)
	var ring := p.get_node("Ring") as MeshInstance3D
	var mat := ring.get_active_material(0) as StandardMaterial3D
	assert_eq(mat.albedo_color, Rarity.COLORS[Rarity.Tier.LEGENDARY])
	assert_gt(p.get_node("Visual").get_child_count(), 0, "модель загружена")

func test_spawn_point_picks_allowed_and_respawns() -> void:
	var sp = SpawnScene.instantiate()
	sp.allowed = [Rarity.Tier.LEGENDARY]
	sp.respawn_min = 0.1
	sp.respawn_max = 0.1
	world.add_child(sp)
	sp.global_position = Vector3(3, 0, 3)
	await wait_process_frames(1)
	assert_not_null(sp.current)
	assert_eq(sp.current.food.tier, Rarity.Tier.LEGENDARY)
	var first = sp.current
	first.picked.emit(first.food, first)
	first.queue_free()
	await wait_seconds(0.3)
	assert_true(is_instance_valid(sp.current) and sp.current != first, "появилась новая еда")
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: ошибки загрузки сцен `food_pickup.tscn` / `food_spawn_point.tscn`, красный прогон.

- [ ] **Step 3: Реализация**

`scripts/food/food_pickup.gd`:
```gdscript
class_name FoodPickup
extends Area3D
## Еда на земле: модель из FoodDef, подложка цвета редкости, покачивание, подбор котом.

signal picked(food: FoodDef, pickup: FoodPickup)

const SPILL_GRACE := 0.5
const BOB_HEIGHT := 0.04
const SPIN_SPEED := 1.2

@export var food: FoodDef
var spilled := false
var lifetime := 0.0
var grace := 0.0
var _t := 0.0
var _built := false

@onready var _visual: Node3D = $Visual
@onready var _ring: MeshInstance3D = $Ring


func setup(def: FoodDef, is_spilled := false, life := 0.0) -> void:
	food = def
	spilled = is_spilled
	lifetime = life
	grace = SPILL_GRACE if is_spilled else 0.0


func _ready() -> void:
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	body_entered.connect(_on_body_entered)
	_build_visual()


func _build_visual() -> void:
	if _built or food == null:
		return
	_built = true
	var model: Node3D = null
	if food.model_path != "" and ResourceLoader.exists(food.model_path):
		model = (load(food.model_path) as PackedScene).instantiate()
	else:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mi.mesh = sphere
		mi.position.y = 0.06
		model = mi
	_visual.add_child(model)
	Toon.apply(_visual, Toon.OUTLINE_FOOD)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Rarity.COLORS[food.tier]
	_ring.set_surface_override_material(0, ring_mat)


func _process(delta: float) -> void:
	_t += delta
	if grace > 0.0:
		grace -= delta
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return
	_visual.position.y = BOB_HEIGHT * (0.5 + 0.5 * sin(_t * 3.0))
	_visual.rotation.y += SPIN_SPEED * delta


func _on_body_entered(body: Node3D) -> void:
	if grace > 0.0 or not body.is_in_group("cat"):
		return
	if GameState.pick_up(food):
		picked.emit(food, self)
		set_deferred("monitoring", false)
		queue_free()
```

`scenes/food/food_pickup.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/food/food_pickup.gd" id="1"]

[sub_resource type="SphereShape3D" id="shape"]
radius = 0.18

[sub_resource type="CylinderMesh" id="ring"]
top_radius = 0.16
bottom_radius = 0.16
height = 0.01

[node name="FoodPickup" type="Area3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
shape = SubResource("shape")

[node name="Visual" type="Node3D" parent="."]

[node name="Ring" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.005, 0)
mesh = SubResource("ring")
```

`scripts/food/food_spawn_point.gd`:
```gdscript
class_name FoodSpawnPoint
extends Node3D
## Точка спавна еды: допустимые редкости, взвешенный выбор, респавн 30–90 с.

signal spawned(pickup: FoodPickup)

const PickupScene := preload("res://scenes/food/food_pickup.tscn")

@export var allowed: Array = [Rarity.Tier.COMMON]
@export var respawn_min := 30.0
@export var respawn_max := 90.0
var rng := RandomNumberGenerator.new()
var current: FoodPickup


func _ready() -> void:
	rng.randomize()
	spawn_now()


func pick_def() -> FoodDef:
	var tier := Rarity.pick_weighted(allowed, rng)
	var pool := FoodCatalog.by_tier(tier)
	if pool.is_empty():
		pool = FoodCatalog.all()
	return pool[rng.randi_range(0, pool.size() - 1)]


func spawn_now() -> FoodPickup:
	var p := PickupScene.instantiate() as FoodPickup
	p.setup(pick_def())
	add_child(p)
	p.picked.connect(_on_picked)
	current = p
	spawned.emit(p)
	return p


func _on_picked(_food: FoodDef, _pickup: FoodPickup) -> void:
	current = null
	var delay := rng.randf_range(respawn_min, respawn_max)
	get_tree().create_timer(delay).timeout.connect(spawn_now)
```

`scenes/food/food_spawn_point.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/food/food_spawn_point.gd" id="1"]

[node name="FoodSpawnPoint" type="Node3D"]
script = ExtResource("1")
```

В `scripts/player/cat.gd`, в начало `_ready()`:
```gdscript
	add_to_group("cat")
	collision_layer = Layers.CAT
	collision_mask = Layers.WORLD | Layers.HAZARD
```

- [ ] **Step 4: GREEN**

Run: `make import && make test-godot`
Expected: 5 тестов `test_food.gd` зелёные, старые не сломаны. Если `test_cat_picks_up_food_on_contact` падает — проверить, что `Area3D.monitoring` включено (по умолчанию) и слои: у кота `collision_layer = 2`, у еды `collision_mask = 2`.

- [ ] **Step 5: Commit**

```bash
git add scripts/food scenes/food scripts/player/cat.gd tests/integration/test_food.gd tests/integration/test_food.gd.uid
git commit -m "Подбираемая еда с подложкой редкости и точки спавна с респавном

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
(плюс `*.uid` новых скриптов.)

---

### Task 5: Укрытия, состояние hide, съедание, низкая камера

**Files:**
- Create: `scripts/hideouts/hideout.gd`, `scenes/hideouts/hideout.tscn`
- Modify: `scripts/player/cat.gd`, `scripts/player/camera_rig.gd`
- Test: `tests/integration/test_hideout.gd`

**Interfaces:**
- Consumes: `GameState.eat_all/mouth`, `Layers`, `Cat.play_clip`, `CatMotion`.
- Produces: `Hideout` (Area3D, `scenes/hideouts/hideout.tscn`): `@export var kind: StringName` (`&"box"`, `&"car"`, `&"bench"`), `@export var size := Vector3(0.6, 0.4, 0.5)` (применяется к BoxShape3D в `_ready`), `cat_inside: bool`. `Cat`: `var current_hideout: Area3D`, `var hidden: bool`, `signal hidden_changed(hidden: bool)`, `signal ate(items: Array)`, `func try_hide() -> bool`, `func unhide() -> void`, `func try_eat() -> bool`; действия `hide` (переключить) и `eat` обрабатываются в `_physics_process`; при `hidden` ввод движения выводит из укрытия. `CameraRig`: `var crouch: bool` (высота `CROUCH_HEIGHT = 0.3` вместо `HEIGHT`).

- [ ] **Step 1: Падающий тест**

`tests/integration/test_hideout.gd`:
```gdscript
extends GutTest

const HideoutScene := preload("res://scenes/hideouts/hideout.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var world: Node3D
var cat
var rig

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	rig = RigScene.instantiate()
	cat = CatScene.instantiate()
	cat.camera_rig = rig
	rig.target = cat
	world.add_child(rig)
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)

func _hideout_at(pos: Vector3) -> Node:
	var h = HideoutScene.instantiate()
	h.kind = &"box"
	world.add_child(h)
	h.global_position = pos
	return h

func test_cannot_hide_outside_hideout() -> void:
	_hideout_at(Vector3(5, 0, 5))
	await wait_physics_frames(3)
	assert_false(cat.try_hide())
	assert_false(cat.hidden)

func test_hide_inside_sets_state_and_lowers_camera() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	assert_true(h.cat_inside)
	assert_true(cat.try_hide())
	assert_true(cat.hidden)
	assert_eq(cat.state, &"hide")
	assert_true(rig.crouch)
	cat.unhide()
	assert_false(cat.hidden)
	assert_false(rig.crouch)

func test_eat_only_when_hidden_with_food() -> void:
	_hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	assert_false(cat.try_eat(), "не спрятан — не ест")
	cat.try_hide()
	watch_signals(cat)
	assert_true(cat.try_eat())
	assert_eq(GameState.mouth.size(), 0)
	assert_eq(GameState.satiety, 1)
	assert_signal_emitted(cat, "ate")
	assert_false(cat.try_eat(), "рот пуст — нечего есть")

func test_movement_input_leaves_hideout() -> void:
	_hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	cat.try_hide()
	Input.action_press("move_forward")
	await wait_physics_frames(3)
	Input.action_release("move_forward")
	assert_false(cat.hidden)
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: нет сцены `hideout.tscn`, красный.

- [ ] **Step 3: Реализация**

`scripts/hideouts/hideout.gd`:
```gdscript
class_name Hideout
extends Area3D
## Объём укрытия (коробка, под машиной, под лавкой). Кот прячется только внутри.

@export var kind: StringName = &"box"
@export var size := Vector3(0.6, 0.4, 0.5)
var cat_inside := false

@onready var _shape: CollisionShape3D = $Collision


func _ready() -> void:
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


# Доступ к полям кота через set/get/call: у типизированного Node3D GDScript не даст
# обратиться к несуществующему у Node3D свойству напрямую.
func _on_enter(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = true
		body.set("current_hideout", self)


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = false
		if body.get("current_hideout") == self:
			body.set("current_hideout", null)
			if body.get("hidden"):
				body.call("unhide")
```

`scenes/hideouts/hideout.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hideouts/hideout.gd" id="1"]

[node name="Hideout" type="Area3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
```

`scripts/player/camera_rig.gd` — добавить константу и свойство, изменить цель:
```gdscript
const CROUCH_HEIGHT := 0.3
var crouch := false
```
и в `_physics_process` строку `var goal := target.global_position + Vector3(0, HEIGHT, 0)` заменить на
```gdscript
	var goal := target.global_position + Vector3(0, CROUCH_HEIGHT if crouch else HEIGHT, 0)
```

`scripts/player/cat.gd` — полная новая версия (заменить файл целиком):
```gdscript
class_name Cat
extends CharacterBody3D
## Узел кота: ввод, физика через CatMotion, клипы, укрытие, еда, удар.

signal state_changed(state: StringName)
signal hidden_changed(hidden: bool)
signal ate(items: Array)
signal hit_taken(from: Vector3)

const FALLBACK := {&"run": [&"walk", 1.8], &"jump": [&"idle", 1.0], &"hide": [&"idle", 1.0], &"hit": [&"idle", 1.0]}
const LOOPING_CLIPS := ["idle", "walk", "run", "hide"]
const TURN_SPEED := 12.0
const KNOCKBACK_SPEED := 6.5      # √(2·ACCEL·1,5 м) — отброс на 1,5 м при торможении 14 м/с²
const KNOCKBACK_UP := 2.0
const STUN_TIME := 1.0
const INVULNERABLE_TIME := 2.0

var camera_rig: CameraRig
var current_hideout: Area3D
var hidden := false
var stunned_left := 0.0
var invulnerable_left := 0.0
var state: StringName = &"idle":
	set(value):
		if value != state:
			state = value
			play_clip(state)
			state_changed.emit(state)

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	add_to_group("cat")
	collision_layer = Layers.CAT
	collision_mask = Layers.WORLD | Layers.HAZARD
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)
	for clip in LOOPING_CLIPS:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var skel := _model.find_child("Skeleton3D", true, false)
	if skel and skel.find_child("HeadScaler", false, false) == null:
		var hs := HeadScaler.new()
		hs.name = "HeadScaler"
		skel.add_child(hs)
	if camera_rig:
		(camera_rig.get_node("SpringArm3D") as SpringArm3D).add_excluded_object(get_rid())
	play_clip(&"idle")


func _physics_process(delta: float) -> void:
	stunned_left = maxf(stunned_left - delta, 0.0)
	invulnerable_left = maxf(invulnerable_left - delta, 0.0)
	if stunned_left > 0.0:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		return
	if Input.is_action_just_pressed("hide"):
		if hidden:
			unhide()
		else:
			try_hide()
	if hidden:
		if Input.is_action_just_pressed("eat"):
			try_eat()
		if Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.3:
			unhide()
		else:
			velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
			move_and_slide()
			return
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


func try_hide() -> bool:
	if hidden or current_hideout == null:
		return false
	hidden = true
	state = &"hide"
	if camera_rig:
		camera_rig.crouch = true
	hidden_changed.emit(true)
	return true


func unhide() -> void:
	if not hidden:
		return
	hidden = false
	if camera_rig:
		camera_rig.crouch = false
	state = &"idle"
	hidden_changed.emit(false)


func try_eat() -> bool:
	if not hidden or GameState.mouth.is_empty():
		return false
	var items := GameState.eat_all()
	ate.emit(items)
	return true


func take_hit(from: Vector3) -> void:
	if invulnerable_left > 0.0 or stunned_left > 0.0 or hidden:
		return
	var away := global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		away = _model.global_transform.basis.z   # назад относительно взгляда
	velocity = away.normalized() * KNOCKBACK_SPEED + Vector3.UP * KNOCKBACK_UP
	stunned_left = STUN_TIME
	invulnerable_left = INVULNERABLE_TIME
	state = &"hit"
	hit_taken.emit(from)
	GameState.take_hit()


func teleport(pos: Vector3) -> void:
	unhide()
	global_position = pos
	velocity = Vector3.ZERO
	stunned_left = 0.0
	state = &"idle"


func play_clip(name: StringName) -> void:
	if _anim == null:
		return
	var clip := String(name)
	var speed := 1.0
	if not _anim.has_animation(clip):
		if FALLBACK.has(name):
			clip = String(FALLBACK[name][0])
			speed = FALLBACK[name][1]
		else:
			clip = "idle"
	_anim.speed_scale = speed
	if _anim.current_animation != clip:
		_anim.play(clip, 0.15)
```

- [ ] **Step 4: GREEN**

Run: `make import && make test-godot`
Expected: 4 теста `test_hideout.gd` зелёные; `test_cat_scene.gd`, `test_main.gd`, `test_food.gd` не сломаны. Примечание: `take_hit` вызывает `GameState.take_hit()` в конце — задача 6 проверит разлёт и обморок.

- [ ] **Step 5: Commit**

```bash
git add scripts/hideouts scenes/hideouts scripts/player tests/integration/test_hideout.gd tests/integration/test_hideout.gd.uid
git commit -m "Укрытия: состояние hide, съедание в укрытии, низкая камера

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Удар, разлёт еды, оглушение, обморок и возрождение

**Files:**
- Modify: `scripts/main.gd`, `scenes/main.tscn` (ничего), `scripts/world/` (нет)
- Create: `scripts/world/spill_spawner.gd`
- Test: `tests/integration/test_hit.gd`

**Interfaces:**
- Consumes: `Cat.take_hit/teleport/hidden/stunned_left/invulnerable_left`, `GameState.cat_hit/cat_fainted/revive`, `FoodPickup.setup`.
- Produces: `SpillSpawner` (Node3D, `scripts/world/spill_spawner.gd`): `func spill_around(pos: Vector3, foods: Array) -> Array` (создаёт `FoodPickup` со `spilled = true`, `lifetime = SPILL_LIFETIME = 5.0`, радиус 1–2 м, возвращает список); `Main`: `func respawn_cat() -> void` (телепорт к `$DistrictYard/Spawn`, `GameState.revive()`), `signal faint_sequence_done`, свойство `fade_time := 0.6`.

- [ ] **Step 1: Падающий тест**

`tests/integration/test_hit.gd`:
```gdscript
extends GutTest

const MainScene := preload("res://scenes/main.tscn")

var main
var cat

func before_each() -> void:
	GameState.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(30)
	cat = main.find_child("Cat", true, false)

func test_hit_spills_food_knocks_back_and_stuns() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	var start: Vector3 = cat.global_position
	cat.take_hit(start + Vector3(0, 0, 1))
	assert_eq(cat.state, &"hit")
	assert_gt(cat.stunned_left, 0.9)
	assert_eq(GameState.hearts, 2)
	await wait_physics_frames(2)
	var spilled := get_tree().get_nodes_in_group("spilled_food")
	assert_eq(spilled.size(), 2, "две рассыпанные еды")
	await wait_seconds(1.2)
	assert_lt(cat.global_position.z, start.z - 0.8, "отброшен примерно на 1,5 м от источника")
	assert_eq(cat.stunned_left, 0.0)

func test_spilled_food_not_repicked_during_stun() -> void:
	# Review Focus 3
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 0, "еда не подобрана тем же кадром")

func test_second_hit_during_invulnerability_is_ignored() -> void:
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	assert_eq(GameState.hearts, 2)

func test_faint_respawns_at_spawn_unhidden_with_full_hearts() -> void:
	# Review Focus 4: обморок по любой причине (здесь напрямую через GameState) выводит из укрытия.
	main.fade_time = 0.05
	GameState.hearts = 1
	cat.hidden = true
	cat.camera_rig.crouch = true
	cat.global_position = Vector3(5, 0.05, 5)
	GameState.take_hit()
	await wait_for_signal(main.faint_sequence_done, 2.0)
	assert_eq(GameState.hearts, 3)
	assert_false(cat.hidden)
	assert_false(cat.camera_rig.crouch)
	var spawn: Vector3 = main.get_node("DistrictYard/Spawn").global_position
	assert_lt(cat.global_position.distance_to(spawn), 0.5)
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: `test_hit_spills_food_knocks_back_and_stuns` падает на `spilled.size()` (0 вместо 2), `test_faint...` — нет сигнала `faint_sequence_done`.

- [ ] **Step 3: Реализация**

`scripts/world/spill_spawner.gd`:
```gdscript
class_name SpillSpawner
extends Node3D
## Раскладывает выбитую из зубов еду вокруг кота (спек 3.2: 1–2 м, 5 с).

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const SPILL_LIFETIME := 5.0
const MIN_R := 1.0
const MAX_R := 2.0

var rng := RandomNumberGenerator.new()


func spill_around(pos: Vector3, foods: Array) -> Array:
	var out := []
	for f in foods:
		var p := PickupScene.instantiate() as FoodPickup
		p.setup(f, true, SPILL_LIFETIME)
		p.add_to_group("spilled_food")
		add_child(p)
		var ang := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(MIN_R, MAX_R)
		p.global_position = Vector3(pos.x + cos(ang) * r, 0.0, pos.z + sin(ang) * r)
		out.append(p)
	return out
```

`scripts/main.gd` — полная новая версия:
```gdscript
extends Node3D
## Собирает мир, кота, камеру и реакции на события GameState.

signal faint_sequence_done

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var fade_time := 0.6
var _cat: Cat
var _rig: CameraRig
var _spill: SpillSpawner
var _fade: ColorRect


func _ready() -> void:
	Toon.apply($DistrictYard, Toon.OUTLINE_NONE)
	_rig = RigScene.instantiate()
	_rig.name = "CameraRig"
	_cat = CatScene.instantiate()
	_cat.name = "Cat"
	_cat.camera_rig = _rig
	_rig.target = _cat
	add_child(_rig)
	add_child(_cat)
	_cat.global_position = $DistrictYard/Spawn.global_position
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	(_rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()
	_spill = SpillSpawner.new()
	_spill.name = "SpillSpawner"
	add_child(_spill)
	_fade = _make_fade()
	GameState.cat_hit.connect(_on_cat_hit)
	GameState.cat_fainted.connect(_on_cat_fainted)


func _make_fade() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 100
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	return rect


func _on_cat_hit(spilled: Array) -> void:
	if spilled.is_empty():
		return
	_spill.spill_around(_cat.global_position, spilled)


func _on_cat_fainted() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, fade_time)
	await tween.finished
	respawn_cat()
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, fade_time)
	await back.finished
	faint_sequence_done.emit()


func respawn_cat() -> void:
	_cat.teleport($DistrictYard/Spawn.global_position)
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	GameState.revive()
```

- [ ] **Step 4: GREEN**

Run: `make test-godot`
Expected: 4 теста `test_hit.gd` зелёные. Если разлетевшаяся еда подбирается сразу, проверить `grace` в `FoodPickup.setup(..., true, ...)`.

- [ ] **Step 5: Commit**

```bash
git add scripts/main.gd scripts/world/spill_spawner.gd scripts/world/spill_spawner.gd.uid tests/integration/test_hit.gd tests/integration/test_hit.gd.uid
git commit -m "Удар: разлёт еды, отброс, оглушение, неуязвимость, обморок и возрождение

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: HUD и цель сессии

**Files:**
- Create: `scripts/ui/hud.gd`, `scenes/ui/hud.tscn`
- Modify: `scenes/main.tscn` (добавить инстанс HUD), `scripts/main.gd` (метод `hud()`)
- Test: `tests/integration/test_hud.gd`

**Interfaces:**
- Consumes: сигналы `GameState`.
- Produces: `Hud` (CanvasLayer, `scenes/ui/hud.tscn`): узлы `Hearts` (HBoxContainer с Label «♥»), `Satiety` (ProgressBar, max = `GameState.SATIETY_GATE`), `Mouth` (HBoxContainer с 3 PanelContainer → Label), `Goal` (Label), `Bell` (Label, скрыт); методы `func flash_bell(text := "🔔 Велосипед!", seconds := 2.0) -> void`, `func hearts_text() -> String` (например `"♥♥♡"`), `func mouth_names() -> Array[String]`. В `Main`: `@onready var hud: Hud = $Hud`.

- [ ] **Step 1: Падающий тест**

`tests/integration/test_hud.gd`:
```gdscript
extends GutTest

const HudScene := preload("res://scenes/ui/hud.tscn")

var hud

func before_each() -> void:
	GameState.reset()
	hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)

func test_hearts_reflect_state() -> void:
	assert_eq(hud.hearts_text(), "♥♥♥")
	GameState.take_hit()
	assert_eq(hud.hearts_text(), "♥♥♡")

func test_mouth_slots_show_names() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))
	assert_eq(hud.mouth_names(), ["Пицца", "", ""])

func test_satiety_and_goal_labels() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	GameState.eat_all()
	assert_eq((hud.get_node("Satiety") as ProgressBar).value, 15.0)
	assert_eq((hud.get_node("Goal") as Label).text, "Открой новых карточек: 1/3")

func test_bell_flash_shows_and_hides() -> void:
	hud.flash_bell("🔔 Велосипед!", 0.1)
	assert_true((hud.get_node("Bell") as Label).visible)
	await wait_seconds(0.25)
	assert_false((hud.get_node("Bell") as Label).visible)
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: нет `hud.tscn`, красный.

- [ ] **Step 3: Реализация**

`scripts/ui/hud.gd`:
```gdscript
class_name Hud
extends CanvasLayer
## HUD: сердечки, сытость, слоты зубов, цель сессии, вспышка звонка (спек 2.6).

const HEART_FULL := "♥"
const HEART_EMPTY := "♡"
const PANEL_COLOR := Color(1, 1, 1, 0.9)
const TEXT_COLOR := Color("#394151")

@onready var _hearts: Label = $Hearts
@onready var _satiety: ProgressBar = $Satiety
@onready var _mouth: HBoxContainer = $Mouth
@onready var _goal: Label = $Goal
@onready var _bell: Label = $Bell


func _ready() -> void:
	_satiety.max_value = GameState.SATIETY_GATE
	_bell.visible = false
	for i in GameState.MOUTH_CAPACITY:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(90, 32)
		var label := Label.new()
		label.name = "Name"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(label)
		_mouth.add_child(panel)
	GameState.hearts_changed.connect(_on_hearts)
	GameState.mouth_changed.connect(_on_mouth)
	GameState.satiety_changed.connect(_on_satiety)
	GameState.goal_changed.connect(_on_goal)
	GameState.goal_completed.connect(_on_goal_completed)
	_on_hearts(GameState.hearts, GameState.max_hearts)
	_on_mouth(GameState.mouth)
	_on_satiety(GameState.satiety)
	_on_goal(GameState.goal_done, GameState.goal_target)


func hearts_text() -> String:
	return _hearts.text


func mouth_names() -> Array[String]:
	var out: Array[String] = []
	for panel in _mouth.get_children():
		out.append((panel.get_node("Name") as Label).text)
	return out


func flash_bell(text := "🔔 Велосипед!", seconds := 2.0) -> void:
	_bell.text = text
	_bell.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _bell.visible = false)


func _on_hearts(hearts: int, max_hearts: int) -> void:
	_hearts.text = HEART_FULL.repeat(hearts) + HEART_EMPTY.repeat(max_hearts - hearts)


func _on_mouth(items: Array) -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		var label := panels[i].get_node("Name") as Label
		label.text = items[i].display_name if i < items.size() else ""


func _on_satiety(value: int) -> void:
	_satiety.value = value


func _on_goal(done: int, target: int) -> void:
	_goal.text = "Открой новых карточек: %d/%d" % [done, target]


func _on_goal_completed(target: int) -> void:
	flash_bell("🎉 Цель выполнена: %d карточек!" % target, 3.0)
```

`scenes/ui/hud.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]

[node name="Hud" type="CanvasLayer"]
script = ExtResource("1")

[node name="Hearts" type="Label" parent="."]
offset_left = 24.0
offset_top = 16.0
offset_right = 200.0
offset_bottom = 56.0
theme_override_colors/font_color = Color(0.961, 0.455, 0.522, 1)
theme_override_font_sizes/font_size = 32
text = "♥♥♥"

[node name="Satiety" type="ProgressBar" parent="."]
offset_left = 24.0
offset_top = 64.0
offset_right = 224.0
offset_bottom = 84.0
max_value = 10.0
show_percentage = false

[node name="Mouth" type="HBoxContainer" parent="."]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -320.0
offset_top = 16.0
offset_right = -24.0
offset_bottom = 56.0
grow_horizontal = 0
alignment = 2

[node name="Goal" type="Label" parent="."]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = -48.0
offset_right = 500.0
offset_bottom = -16.0
grow_vertical = 0
theme_override_font_sizes/font_size = 20
text = "Открой новых карточек: 0/3"

[node name="Bell" type="Label" parent="."]
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -200.0
offset_top = 24.0
offset_right = 200.0
offset_bottom = 64.0
grow_horizontal = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 28
text = "🔔 Велосипед!"
visible = false
```

В `scenes/main.tscn` добавить ресурс и узел:
```
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="4"]
...
[node name="Hud" parent="." instance=ExtResource("4")]
```
В `scripts/main.gd` добавить `@onready var hud: Hud = $Hud`.

- [ ] **Step 4: GREEN**

Run: `make import && make test-godot`
Expected: 4 теста `test_hud.gd` зелёные. `make shot SHOT=build/task7.png`: в углах видны «♥♥♥», полоска, пустые плашки и подпись цели.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui scenes/ui scenes/main.tscn scripts/main.gd tests/integration/test_hud.gd tests/integration/test_hud.gd.uid
git commit -m "HUD: сердечки, сытость, слоты зубов, цель сессии, вспышка звонка

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: WorldBuilder и раскладка двора из JSON

**Files:**
- Create: `scripts/world/world_builder.gd`, `data/layout/yard.json`
- Modify: `scenes/world/district_yard.tscn` (убрать ручные баки/коробки, добавить `WorldBuilder`)
- Test: `tests/integration/test_world_builder.gd`

**Interfaces:**
- Consumes: `FoodSpawnPoint`, `Hideout`, `Toon`, `Layers`; сцены опасностей `res://scenes/hazards/{dog,wasp,cyclist}.tscn` (появятся в задачах 10–12; до них записи `hazards` в JSON просто пропускаются с предупреждением).
- Produces: `WorldBuilder` (Node3D): `@export var layout_path := "res://data/layout/yard.json"`, `static func load_layout(path: String) -> Dictionary`, `func build(data: Dictionary) -> void`, счётчики `props_built`, `hideouts_built`, `spawns_built`, `hazards_built`; дочерние контейнеры `Props`, `Hideouts`, `Spawns`, `Hazards`, `Road` (Path3D). Формат JSON:
```json
{
  "props": [{"model": "bin", "pos": [3, 0, -4], "rot": 0, "outline": false,
             "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]}],
  "hideouts": [{"kind": "box", "pos": [1.5, 0.2, 1.5], "size": [0.6, 0.4, 0.5]}],
  "spawn_points": [{"pos": [2, 0, -3], "allowed": [0]}],
  "hazards": [{"type": "dog", "pos": [7, 0, -7], "rot": 90}, {"type": "wasp", "pos": [-4, 0.5, -6], "radius": 2.5}],
  "road": {"points": [[-20, 0, 12], [20, 0, 12]]}
}
```
`rot` — градусы вокруг Y. Без `colliders` коллайдер один, по AABB модели.

- [ ] **Step 1: Падающий тест**

`tests/integration/test_world_builder.gd`:
```gdscript
extends GutTest

const BuilderScript := preload("res://scripts/world/world_builder.gd")

func _builder() -> Node3D:
	var b: Node3D = BuilderScript.new()
	add_child_autofree(b)
	return b

func test_build_from_dictionary_counts_nodes() -> void:
	var b = _builder()
	b.build({
		"props": [
			{"model": "box", "pos": [1, 0, 1], "rot": 45, "outline": true},
			{"model": "bin", "pos": [3, 0, -4], "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
		],
		"hideouts": [{"kind": "box", "pos": [1, 0.2, 1], "size": [0.6, 0.4, 0.5]}],
		"spawn_points": [{"pos": [2, 0, 2], "allowed": [0, 1]}],
		"hazards": [{"type": "unknown", "pos": [0, 0, 0]}],
		"road": {"points": [[-5, 0, 5], [5, 0, 5]]},
	})
	assert_eq(b.props_built, 2)
	assert_eq(b.hideouts_built, 1)
	assert_eq(b.spawns_built, 1)
	assert_eq(b.hazards_built, 0, "неизвестный тип пропущен")
	var prop := b.get_node("Props").get_child(0) as StaticBody3D
	assert_eq(prop.collision_layer, Layers.WORLD)
	assert_almost_eq(prop.rotation_degrees.y, 45.0, 0.01)
	assert_true(prop.find_child("Shape*", true, false) != null, "коллайдер по AABB создан")
	var mesh := prop.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_not_null(mesh.material_overlay, "обводка у интерактивного пропса")
	assert_eq((b.get_node("Road") as Path3D).curve.point_count, 2)
	var sp := b.get_node("Spawns").get_child(0)
	assert_eq(sp.allowed, [0, 1])

func test_real_yard_layout_loads() -> void:
	var data := BuilderScript.load_layout("res://data/layout/yard.json")
	assert_gt(data["props"].size(), 10, "во дворе больше 10 пропсов")
	assert_gte(data["hideouts"].size(), 3)
	assert_gte(data["spawn_points"].size(), 6)
	var b = _builder()
	b.build(data)
	assert_eq(b.props_built, data["props"].size())
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: нет `world_builder.gd`, красный.

- [ ] **Step 3: Реализация**

`scripts/world/world_builder.gd`:
```gdscript
class_name WorldBuilder
extends Node3D
## Строит район из data/layout/*.json: пропсы с коллизией, укрытия, точки спавна, опасности, дорога.

const MODELS_DIR := "res://assets/models"
const HAZARD_SCENES := {
	"dog": "res://scenes/hazards/dog.tscn",
	"wasp": "res://scenes/hazards/wasp.tscn",
	"cyclist": "res://scenes/hazards/cyclist.tscn",
}
const HideoutScene := preload("res://scenes/hideouts/hideout.tscn")
const SpawnScene := preload("res://scenes/food/food_spawn_point.tscn")

@export var layout_path := ""
var props_built := 0
var hideouts_built := 0
var spawns_built := 0
var hazards_built := 0


func _ready() -> void:
	if layout_path != "":
		build(load_layout(layout_path))


static func load_layout(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "не удалось разобрать " + path)
	return parsed


static func _v3(arr: Array) -> Vector3:
	return Vector3(arr[0], arr[1], arr[2])


func _container(name: String) -> Node3D:
	var n := get_node_or_null(name) as Node3D
	if n == null:
		n = Node3D.new()
		n.name = name
		add_child(n)
	return n


func build(data: Dictionary) -> void:
	for p in data.get("props", []):
		_build_prop(p)
	for h in data.get("hideouts", []):
		_build_hideout(h)
	for s in data.get("spawn_points", []):
		_build_spawn(s)
	_build_road(data.get("road", {}))
	for hz in data.get("hazards", []):
		_build_hazard(hz)


func _build_prop(p: Dictionary) -> void:
	var model_path := "%s/%s.glb" % [MODELS_DIR, p["model"]]
	if not ResourceLoader.exists(model_path):
		push_warning("нет модели " + model_path)
		return
	var body := StaticBody3D.new()
	body.name = "%s_%d" % [p["model"], props_built]
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	body.add_child(model)
	var colliders: Array = p.get("colliders", [])
	if colliders.is_empty():
		var aabb := _model_aabb(model)
		colliders = [{"size": [aabb.size.x, aabb.size.y, aabb.size.z],
			"offset": [aabb.position.x + aabb.size.x / 2, aabb.position.y + aabb.size.y / 2, aabb.position.z + aabb.size.z / 2]}]
	for i in colliders.size():
		var c: Dictionary = colliders[i]
		var shape := CollisionShape3D.new()
		shape.name = "Shape%d" % i
		var box := BoxShape3D.new()
		box.size = _v3(c["size"])
		shape.shape = box
		shape.position = _v3(c.get("offset", [0, 0, 0]))
		body.add_child(shape)
	_container("Props").add_child(body)
	body.global_position = _v3(p["pos"])
	body.rotation_degrees.y = float(p.get("rot", 0))
	Toon.apply(model, Toon.OUTLINE_FOOD if p.get("outline", false) else Toon.OUTLINE_NONE)
	props_built += 1


func _model_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = model.global_transform.affine_inverse() * (mi as Node3D).global_transform if model.is_inside_tree() else _local_xf(mi, model)
		box = xf * box
		result = box if first else result.merge(box)
		first = false
	return result


func _local_xf(node: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n := node
	while n != null and n != root:
		xf = n.transform * xf
		n = n.get_parent() as Node3D
	return xf


func _build_hideout(h: Dictionary) -> void:
	var node := HideoutScene.instantiate() as Hideout
	node.kind = StringName(h.get("kind", "box"))
	node.size = _v3(h.get("size", [0.6, 0.4, 0.5]))
	_container("Hideouts").add_child(node)
	node.global_position = _v3(h["pos"])
	node.rotation_degrees.y = float(h.get("rot", 0))
	hideouts_built += 1


func _build_spawn(s: Dictionary) -> void:
	var node := SpawnScene.instantiate() as FoodSpawnPoint
	var allowed: Array = []
	for t in s.get("allowed", [0]):
		allowed.append(int(t))   # JSON даёт float, ключи словарей Rarity — int
	node.allowed = allowed
	_container("Spawns").add_child(node)
	node.global_position = _v3(s["pos"])
	spawns_built += 1


func _build_road(road: Dictionary) -> void:
	var path := Path3D.new()
	path.name = "Road"
	var curve := Curve3D.new()
	for pt in road.get("points", []):
		curve.add_point(_v3(pt))
	path.curve = curve
	add_child(path)


func _build_hazard(hz: Dictionary) -> void:
	var type_name: String = hz.get("type", "")
	var scene_path: String = HAZARD_SCENES.get(type_name, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("опасность пропущена: " + type_name)
		return
	var node := (load(scene_path) as PackedScene).instantiate() as Node3D
	node.name = "%s_%d" % [type_name, hazards_built]
	if node.has_method("configure"):
		node.call("configure", hz, self)
	_container("Hazards").add_child(node)
	node.global_position = _v3(hz["pos"])
	node.rotation_degrees.y = float(hz.get("rot", 0))
	hazards_built += 1
```

`data/layout/yard.json` (первая версия: только модели, которые уже есть — `bin`, `box`; задача 13 расширит):
```json
{
  "props": [
    {"model": "bin", "pos": [3, 0, -4], "rot": 0, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [4, 0, -4], "rot": 0, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [-6, 0, 2], "rot": 90, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [-6, 0, 3], "rot": 90, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "box", "pos": [1.5, 0, 1.5], "rot": 0, "outline": true},
    {"model": "box", "pos": [-2, 0, -1], "rot": 45, "outline": true},
    {"model": "box", "pos": [1.5, 0.3, 1.5], "rot": 20, "outline": true},
    {"model": "box", "pos": [-3.5, 0, 4], "rot": 0, "outline": true},
    {"model": "box", "pos": [5, 0, 3], "rot": 70, "outline": true},
    {"model": "box", "pos": [-1, 0, -6], "rot": 10, "outline": true},
    {"model": "box", "pos": [6, 0, -1], "rot": 0, "outline": true}
  ],
  "hideouts": [
    {"kind": "box", "pos": [-2, 0.2, -1], "size": [0.7, 0.4, 0.6]},
    {"kind": "box", "pos": [-3.5, 0.2, 4], "size": [0.7, 0.4, 0.6]},
    {"kind": "box", "pos": [6, 0.2, -1], "size": [0.7, 0.4, 0.6]}
  ],
  "spawn_points": [
    {"pos": [3.5, 0, -3], "allowed": [0]},
    {"pos": [-5, 0, 2.5], "allowed": [0]},
    {"pos": [0, 0, -4], "allowed": [0]},
    {"pos": [4, 0, 4], "allowed": [0, 1]},
    {"pos": [-4, 0, -4], "allowed": [0]},
    {"pos": [2, 0, 6], "allowed": [1]},
    {"pos": [7.5, 0, -8], "allowed": [2, 3]}
  ],
  "hazards": [
    {"type": "dog", "pos": [7, 0, -7], "rot": 90},
    {"type": "wasp", "pos": [2, 0.5, 6], "radius": 2.5},
    {"type": "cyclist", "pos": [0, 0, 12]}
  ],
  "road": {"points": [[-25, 0, 12], [25, 0, 12]]}
}
```
Точка `[7.5, 0, -8]` — «легендарная рядом с опасностью» (у собаки), `[2, 0, 6]` — сладкое под осой.

`scenes/world/district_yard.tscn` — полная новая версия:
```
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://assets/models/ground.glb" id="1"]
[ext_resource type="Script" path="res://scripts/world/world_builder.gd" id="2"]

[sub_resource type="BoxShape3D" id="floor"]
size = Vector3(60, 0.2, 60)

[node name="DistrictYard" type="Node3D"]

[node name="Ground" parent="." instance=ExtResource("1")]

[node name="Floor" type="StaticBody3D" parent="."]
collision_layer = 1
collision_mask = 0

[node name="Shape" type="CollisionShape3D" parent="Floor"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.1, 0)
shape = SubResource("floor")

[node name="WorldBuilder" type="Node3D" parent="."]
script = ExtResource("2")
layout_path = "res://data/layout/yard.json"

[node name="Spawn" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0)
```

- [ ] **Step 4: GREEN**

Run: `make import && make test-godot`
Expected: 2 теста `test_world_builder.gd` зелёные; `test_main.gd` зелёный (кот приземляется, ходит по −Z: на линии x=0 от z=0 до z=−3 пропсов нет). В логе предупреждения «опасность пропущена: dog/wasp/cyclist» до задач 10–12 — это ожидаемо.

`make shot SHOT=build/task8.png`: двор как раньше (баки, коробки), Box3 стоит на Box1, у коробок тонкая обводка, на земле видны кольца редкости с едой.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/world_builder.gd scripts/world/world_builder.gd.uid data/layout scenes/world/district_yard.tscn tests/integration/test_world_builder.gd tests/integration/test_world_builder.gd.uid
git commit -m "WorldBuilder: двор из data/layout/yard.json (пропсы, укрытия, спавны, дорога)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Восприятие и мозг погони (чистая логика)

**Files:**
- Create: `scripts/hazards/perception.gd`, `scripts/hazards/chase_brain.gd`
- Test: `tests/unit/test_perception.gd`, `tests/unit/test_chase_brain.gd`

**Interfaces:**
- Produces: `Perception.in_cone(origin: Vector3, forward: Vector3, target: Vector3, half_angle_deg: float, range_m: float) -> bool` (по горизонтали, высота игнорируется); `ChaseBrain` (RefCounted): `enum State { IDLE, ALERT, CHASE, RETURN }`, константы `ALERT_TIME = 1.0`, `CHASE_MAX = 8.0`, `LOST_HIDDEN = 2.0`, `var state`, `func update(delta: float, sees_cat: bool, cat_hidden: bool, at_home: bool) -> int`, `func reset() -> void`.

- [ ] **Step 1: Падающие тесты**

`tests/unit/test_perception.gd`:
```gdscript
extends GutTest

func test_target_in_front_within_range() -> void:
	assert_true(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, -3), 45.0, 6.0))

func test_target_behind_is_not_seen() -> void:
	assert_false(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, 3), 45.0, 6.0))

func test_target_at_edge_of_cone() -> void:
	assert_true(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(2.9, 0, -3), 45.0, 6.0))
	assert_false(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(3.2, 0, -3), 45.0, 6.0))

func test_out_of_range() -> void:
	assert_false(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, -6.5), 45.0, 6.0))

func test_height_is_ignored() -> void:
	assert_true(Perception.in_cone(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 5, -3), 45.0, 6.0))
```

`tests/unit/test_chase_brain.gd`:
```gdscript
extends GutTest

var brain: ChaseBrain

func before_each() -> void:
	brain = ChaseBrain.new()

func _run(seconds: float, sees: bool, hidden: bool, at_home := false) -> int:
	var t := 0.0
	var s := brain.state
	while t < seconds:
		s = brain.update(0.1, sees, hidden, at_home)
		t += 0.1
	return s

func test_idle_until_sees_then_alert_then_chase() -> void:
	assert_eq(_run(1.0, false, false), ChaseBrain.State.IDLE)
	assert_eq(brain.update(0.1, true, false, true), ChaseBrain.State.ALERT)
	assert_eq(_run(0.5, true, false), ChaseBrain.State.ALERT, "насторожилась ещё не секунду")
	assert_eq(_run(0.6, true, false), ChaseBrain.State.CHASE)

func test_chase_times_out_after_8s() -> void:
	brain.update(0.1, true, false, true)
	_run(1.1, true, false)
	assert_eq(brain.state, ChaseBrain.State.CHASE)
	assert_eq(_run(7.0, true, false), ChaseBrain.State.CHASE)
	assert_eq(_run(1.2, true, false), ChaseBrain.State.RETURN)

func test_loses_track_after_2s_continuous_hidden_only() -> void:
	# Review Focus 5
	brain.update(0.1, true, false, true)
	_run(1.1, true, false)
	_run(1.5, false, true)
	_run(0.3, true, false)   # выглянул на 0,3 с — счётчик сбрасывается
	assert_eq(_run(1.5, false, true), ChaseBrain.State.CHASE, "суммарно 3 с, но не подряд")
	assert_eq(_run(0.6, false, true), ChaseBrain.State.RETURN, "2,1 с подряд")

func test_return_becomes_idle_at_home() -> void:
	brain.state = ChaseBrain.State.RETURN
	assert_eq(brain.update(0.1, false, false, false), ChaseBrain.State.RETURN)
	assert_eq(brain.update(0.1, false, false, true), ChaseBrain.State.IDLE)
```

- [ ] **Step 2: RED**

Run: `make test-godot`
Expected: `Identifier "Perception" not declared`, `"ChaseBrain" not declared`.

- [ ] **Step 3: Реализация**

`scripts/hazards/perception.gd`:
```gdscript
class_name Perception
extends RefCounted
## Геометрия восприятия: конус зрения по горизонтали.


static func in_cone(origin: Vector3, forward: Vector3, target: Vector3, half_angle_deg: float, range_m: float) -> bool:
	var to := target - origin
	to.y = 0.0
	var fwd := forward
	fwd.y = 0.0
	if to.length() > range_m or to.length() < 0.001 or fwd.length() < 0.001:
		return false
	var cos_angle := fwd.normalized().dot(to.normalized())
	return cos_angle >= cos(deg_to_rad(half_angle_deg))
```

`scripts/hazards/chase_brain.gd`:
```gdscript
class_name ChaseBrain
extends RefCounted
## Конечный автомат погони (спек 3.2, собака): idle → alert (1 с) → chase → return.

enum State { IDLE, ALERT, CHASE, RETURN }

const ALERT_TIME := 1.0
const CHASE_MAX := 8.0
const LOST_HIDDEN := 2.0

var state: int = State.IDLE
var _t := 0.0
var _hidden_t := 0.0


func reset() -> void:
	state = State.IDLE
	_t = 0.0
	_hidden_t = 0.0


func update(delta: float, sees_cat: bool, cat_hidden: bool, at_home: bool) -> int:
	match state:
		State.IDLE:
			if sees_cat and not cat_hidden:
				state = State.ALERT
				_t = 0.0
		State.ALERT:
			_t += delta
			if _t >= ALERT_TIME:
				state = State.CHASE
				_t = 0.0
				_hidden_t = 0.0
		State.CHASE:
			_t += delta
			_hidden_t = _hidden_t + delta if cat_hidden else 0.0
			if _t >= CHASE_MAX or _hidden_t >= LOST_HIDDEN:
				state = State.RETURN
		State.RETURN:
			if at_home:
				state = State.IDLE
				_t = 0.0
	return state
```

- [ ] **Step 4: GREEN**

Run: `make import && make test-godot`
Expected: 5 + 4 новых теста зелёные.

- [ ] **Step 5: Commit**

```bash
git add scripts/hazards tests/unit/test_perception.gd tests/unit/test_chase_brain.gd tests/unit/*.uid scripts/hazards/*.uid
git commit -m "Восприятие (конус) и мозг погони для опасностей

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Собака: модель из CC0-пака и узел с погоней

**Files:**
- Create: `tools/blender/rig_utils.py`, `tools/blender/dog.py`, `tools/blender/gen/dog.py`, `scripts/hazards/hazard_base.gd`, `scripts/hazards/dog.gd`, `scenes/hazards/dog.tscn`
- Modify: `tools/blender/cat.py` (использовать `rig_utils.face_forward`)
- Test: `tests/integration/test_dog_asset.gd`, `tests/integration/test_dog.gd`

**Interfaces:**
- Consumes: `ChaseBrain`, `Perception`, `Cat.hidden/take_hit`, `Layers`, `Toon`, `WorldBuilder` (вызывает `configure(hz: Dictionary, builder: Node3D)` если есть).
- Produces: `assets/models/dog.glb` (клипы `idle`, `walk`; кость `head`; длина ≈ 0,55 м; материалы `sr_cat_orange` + `sr_cream`); `rig_utils.face_forward(arm, root_bone="Bone", head_bone="head") -> None`, `rig_utils.action_fcurves(action) -> list[(channelbag, fcurve)]`, `rig_utils.clean_action(action, arm, rename=None)`, `rig_utils.split_material_by_height(mesh, top_key, bottom_key, fraction)`; `HazardBase` (CharacterBody3D): `@export var walk_speed := 1.5`, `@export var run_speed := 4.8`, `var home: Vector3` (фиксируется `_ensure_home()` на первом физическом кадре), `var cat: Node3D` (ищется по группе `cat`), `func configure(hz: Dictionary, builder: Node3D) -> void` (пустая по умолчанию), `func _on_hit_body(body)`, `func move_towards_point(target: Vector3, speed: float, delta: float) -> float`; `Dog` (`scenes/hazards/dog.tscn`): `var brain: ChaseBrain`, `const VISION_HALF_ANGLE = 45.0`, `const VISION_RANGE = 6.0`, `func sees_cat() -> bool`, `func play_clip(name: StringName) -> void`.

- [ ] **Step 1: Падающий тест ассета**

`tests/integration/test_dog_asset.gd`:
```gdscript
extends GutTest

const DOG_PATH := "res://assets/models/dog.glb"

func test_dog_glb_has_clips_head_and_two_materials() -> void:
	var scene := load(DOG_PATH) as PackedScene
	assert_not_null(scene, "dog.glb должен импортироваться")
	if scene == null:
		return
	var inst := scene.instantiate() as Node3D
	add_child_autofree(inst)
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("idle"))
	assert_true(ap.has_animation("walk"))
	var skel := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	assert_gt(skel.find_bone("head"), -1)
	var names := []
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			names.append((mi as MeshInstance3D).get_active_material(i).resource_name)
	assert_has(names, "sr_cat_orange")
	assert_has(names, "sr_cream")
	var aabb := AABB(skel.global_transform * skel.get_bone_global_rest(0).origin, Vector3.ZERO)
	for i in skel.get_bone_count():
		aabb = aabb.expand(skel.global_transform * skel.get_bone_global_rest(i).origin)
	assert_between(maxf(aabb.size.x, aabb.size.z), 0.35, 0.7, "длина собаки по скелету около 0,5 м")
```

- [ ] **Step 2: RED**

Run: `make import && make test-godot`
Expected: `dog.glb должен импортироваться` падает.

- [ ] **Step 3: Blender: rig_utils и экспорт собаки**

`tools/blender/rig_utils.py`:
```python
"""Общие операции над ригами Quaternius: каналы action, разворот, раскраска по высоте."""
import math

import bpy

import palette


def action_fcurves(action):
	out = []
	for layer in action.layers:
		for strip in layer.strips:
			for cb in strip.channelbags:
				out.extend((cb, fc) for fc in cb.fcurves)
	return out


def bone_of(fc):
	return fc.data_path.split('"')[1] if 'pose.bones["' in fc.data_path else None


def clean_action(action, arm, rename=None):
	"""Переименовывает кости в каналах и выкидывает каналы несуществующих костей."""
	names = {b.name for b in arm.data.bones}
	for cb, fc in action_fcurves(action):
		bone = bone_of(fc)
		if bone and rename and bone in rename:
			fc.data_path = fc.data_path.replace(f'pose.bones["{bone}"]', f'pose.bones["{rename[bone]}"]')
			bone = rename[bone]
		if bone and bone not in names:
			cb.fcurves.remove(fc)
	action.use_fake_user = True


def face_forward(arm, root_bone="Bone", head_bone="head"):
	"""Поворачивает арматуру так, чтобы вектор таз→голова смотрел по +Y Blender (= -Z Godot)."""
	arm.rotation_mode = "XYZ"
	hips = arm.data.bones[root_bone].head_local
	head = arm.data.bones[head_bone].head_local
	d = arm.matrix_world.to_3x3() @ (head - hips)
	arm.rotation_euler.z += math.pi / 2 - math.atan2(d.y, d.x)
	bpy.context.view_layer.update()
	d2 = arm.matrix_world.to_3x3() @ (head - hips)
	print(f"СМОТРИТ: ({d2.x:.2f}, {d2.y:.2f}, {d2.z:.2f}), ожидается +Y")


def split_material_by_height(mesh, top_key, bottom_key, fraction=0.35):
	"""Грани ниже fraction высоты меша получают bottom_key (белая грудка и лапы), остальные top_key.
	Высота считается в мировых координатах: у Dog.blend меш повёрнут относительно арматуры,
	и локальная ось Z меша — это длина, а не высота."""
	bpy.context.view_layer.update()
	m = mesh.matrix_world
	zs = [(m @ v.co).z for v in mesh.data.vertices]
	threshold = min(zs) + (max(zs) - min(zs)) * fraction
	mesh.data.materials.clear()
	mesh.data.materials.append(palette.get_material(top_key))
	mesh.data.materials.append(palette.get_material(bottom_key))
	for poly in mesh.data.polygons:
		poly.material_index = 1 if (m @ poly.center).z < threshold else 0
```

`tools/blender/dog.py`:
```python
"""Собака из Quaternius Dog.blend: рыжая с белой грудкой, 0,55 м, клипы idle/walk, кость head."""
import os

import bpy

import lib
import rig_inspect
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Dog.blend")
TARGET_LENGTH = 0.55
ACTION_MAP = {"Idle": "idle", "Walking": "walk"}


def build():
	bpy.ops.wm.open_mainfile(filepath=SOURCE)
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH")
	if mesh.parent is not arm:
		mesh.parent = arm
	head = rig_inspect.find_head_bone(arm, mesh)
	arm.data.bones[head].name = "head"
	for old, new in ACTION_MAP.items():
		act = bpy.data.actions[old]
		act.name = new
		rig_utils.clean_action(act, arm)
	rig_utils.split_material_by_height(mesh, "cat_orange", "cream", 0.35)
	arm.animation_data_create()
	arm.animation_data.action = None
	for pb in arm.pose.bones:
		pb.rotation_mode = "QUATERNION"
	rig_utils.face_forward(arm)
	bpy.context.view_layer.update()
	factor = TARGET_LENGTH / lib.world_extent(mesh)
	arm.scale = (arm.scale.x * factor, arm.scale.y * factor, arm.scale.z * factor)
	arm.name = "DogRig"
	mesh.name = "dog"
	return [arm, mesh]
```
Важно: у собаки `mesh.dimensions` = (2,35; 4,33; 7,1) из-за трансформации объекта меша, поэтому длина меряется через `lib.world_extent(mesh)`, а не `dimensions`.

`tools/blender/gen/dog.py`:
```python
"""Генератор собаки: оборачивает dog.py для build.py."""
import dog

SPEC = {"max_tris": 2500, "max_dim": 0.8, "animations": True}


def build():
	return dog.build()
```

В `tools/blender/cat.py` заменить тело `face_forward(arm)` на вызов общей функции: удалить локальную реализацию `face_forward` и в `build()` вместо `face_forward(arm)` написать `rig_utils.face_forward(arm)`; добавить `import rig_utils`. `_fcurves`/`_clean_action` в `cat.py` можно оставить (они работают) — цель задачи не рефакторинг.

Run: `make assets ONLY=dog && make assets ONLY=cat && $BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/dog.glb 2>&1 | grep -E "^(OBJ|   MATS|ANIM)"`
Expected: `СМОТРИТ: (..., 0.99, ...)` в логе, `MATS ['sr_cat_orange', 'sr_cream']`, `ANIM idle`, `ANIM walk`, наибольший габарит ≈0,55. Кот пересобран и `test_cat_asset.gd` остаётся зелёным.

Run: `make import && make test-godot`
Expected: `test_dog_asset.gd` зелёный.

- [ ] **Step 4: Падающий тест узла собаки**

`tests/integration/test_dog.gd`:
```gdscript
extends GutTest

const DogScene := preload("res://scenes/hazards/dog.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var cat
var dog

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	cat = CatScene.instantiate()
	world.add_child(cat)
	dog = DogScene.instantiate()
	world.add_child(dog)
	dog.global_position = Vector3(0, 0.05, 0)   # смотрит по -Z

func test_dog_sees_cat_in_front_and_chases() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_physics_frames(3)
	assert_true(dog.sees_cat())
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	var d0: float = dog.global_position.distance_to(cat.global_position)
	await wait_seconds(0.5)
	assert_lt(dog.global_position.distance_to(cat.global_position), d0 - 1.0, "собака сближается")

func test_dog_ignores_cat_behind_or_hidden() -> void:
	cat.global_position = Vector3(0, 0.05, 4)
	await wait_physics_frames(3)
	assert_false(dog.sees_cat(), "за спиной")
	cat.global_position = Vector3(0, 0.05, -4)
	cat.hidden = true
	await wait_physics_frames(3)
	assert_false(dog.sees_cat(), "спрятан")

func test_dog_contact_hits_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -0.2)
	await wait_physics_frames(5)
	assert_eq(GameState.hearts, 2, "касание собаки = удар")

func test_dog_returns_home_after_losing_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	cat.hidden = true
	cat.global_position = Vector3(0, 0.05, -12)
	await wait_seconds(2.3)
	assert_eq(dog.brain.state, ChaseBrain.State.RETURN)
	dog.walk_speed = 8.0   # чтобы не ждать 7 с возврата в тесте
	await wait_seconds(2.5)
	assert_lt(dog.global_position.distance_to(dog.home), 0.6)
```

- [ ] **Step 5: RED**

Run: `make test-godot`
Expected: нет `dog.tscn`, красный.

- [ ] **Step 6: Реализация узлов**

`scripts/hazards/hazard_base.gd`:
```gdscript
class_name HazardBase
extends CharacterBody3D
## Общее для опасностей: слои, дом, ссылка на кота, hit-зона, гравитация.

const GRAVITY := 12.0

@export var walk_speed := 1.5
@export var run_speed := 4.8
var home: Vector3
var cat: Node3D
var _home_set := false

@onready var hit_zone: Area3D = $HitZone


func _ready() -> void:
	add_to_group("hazards")
	collision_layer = Layers.HAZARD
	collision_mask = Layers.WORLD
	hit_zone.collision_layer = Layers.AREA
	hit_zone.collision_mask = Layers.CAT
	hit_zone.monitorable = false
	hit_zone.body_entered.connect(_on_hit_body)


func _ensure_home() -> void:
	# WorldBuilder ставит global_position после add_child, поэтому дом фиксируется на первом физическом кадре.
	if not _home_set:
		home = global_position
		_home_set = true


func configure(_hz: Dictionary, _builder: Node3D) -> void:
	pass


func _find_cat() -> Node3D:
	if cat == null or not is_instance_valid(cat):
		cat = get_tree().get_first_node_in_group("cat") as Node3D
	return cat


func _on_hit_body(body: Node3D) -> void:
	if body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


func move_towards_point(target: Vector3, speed: float, delta: float) -> float:
	"""Двигает по горизонтали к точке; возвращает оставшееся расстояние."""
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > 0.05:
		var dir := to / dist
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()
	return dist
```

`scripts/hazards/dog.gd`:
```gdscript
class_name Dog
extends HazardBase
## Собака: спит, замечает кота в конусе, 1 с настораживается, гонится 1,2× скорости кота,
## теряет след в укрытии (2 с) или устаёт (8 с), возвращается домой (спек 3.2).

const VISION_HALF_ANGLE := 45.0
const VISION_RANGE := 6.0
const HOME_RADIUS := 0.4

var brain := ChaseBrain.new()
var _was_state := ChaseBrain.State.IDLE

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	super()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)
	for clip in ["idle", "walk"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip(&"sleep")


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden"):
		return false
	var forward := -global_transform.basis.z
	return Perception.in_cone(global_position, forward, c.global_position, VISION_HALF_ANGLE, VISION_RANGE)


func _physics_process(delta: float) -> void:
	_ensure_home()
	var c := _find_cat()
	var cat_hidden: bool = c != null and bool(c.get("hidden"))
	var at_home := global_position.distance_to(home) < HOME_RADIUS
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home)
	match s:
		ChaseBrain.State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play_clip(&"sleep")
		ChaseBrain.State.ALERT:
			if c:
				var to := c.global_position - global_position
				rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 10.0 * delta)
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play_clip(&"alert")
		ChaseBrain.State.CHASE:
			if c:
				move_towards_point(c.global_position, run_speed, delta)
			play_clip(&"run")
		ChaseBrain.State.RETURN:
			move_towards_point(home, walk_speed, delta)
			play_clip(&"walk")
	_was_state = s


func play_clip(name: StringName) -> void:
	if _anim == null:
		return
	var clip := String(name)
	var speed := 1.0
	match name:
		&"run":
			if not _anim.has_animation("run"):
				clip = "walk"
				speed = 1.8
		&"sleep", &"alert":
			if not _anim.has_animation(clip):
				clip = "idle"
	_anim.speed_scale = speed
	if _anim.current_animation != clip:
		_anim.play(clip, 0.2)
```

`scenes/hazards/dog.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/dog.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/dog.glb" id="2"]

[sub_resource type="SphereShape3D" id="body"]
radius = 0.2

[sub_resource type="SphereShape3D" id="hit"]
radius = 0.32

[node name="Dog" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, 0)
shape = SubResource("body")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, 0)
shape = SubResource("hit")
```

- [ ] **Step 7: GREEN**

Run: `make import && make test-godot`
Expected: 4 теста `test_dog.gd` зелёные (неуязвимость спрятанного кота проверяется в `test_wasp.gd`); `test_world_builder.gd` теперь строит собаку (`hazards_built` ≥ 1 в реальном дворе, предупреждение только про wasp/cyclist). Если `test_dog_contact_hits_cat` не бьёт: проверить, что `HitZone.monitoring` включён и кот в группе `cat`.

`make shot SHOT=build/task10.png`: собака у баков справа-сзади; `make run`: подойти к собаке спереди — через секунду она бежит за котом, после 8 с или если спрятаться в коробку на 2 с — уходит домой.

- [ ] **Step 8: Commit**

```bash
git add tools/blender/rig_utils.py tools/blender/dog.py tools/blender/gen/dog.py tools/blender/cat.py assets/models/dog.glb assets/models/dog.glb.import assets/models/cat.glb scripts/hazards scenes/hazards tests/integration/test_dog_asset.gd tests/integration/test_dog.gd tests/integration/*.uid scripts/hazards/*.uid
git commit -m "Собака: модель из CC0-пака, конус зрения, погоня и возврат домой

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

После этой задачи цикл замкнут: еда → укрытие → съесть → собака → удар → разлёт → обморок → возрождение.

---

### Task 11: Оса

**Files:**
- Create: `tools/blender/gen/wasp.py`, `scripts/hazards/wasp.gd`, `scenes/hazards/wasp.tscn`
- Test: `tests/integration/test_wasp.gd`

**Interfaces:**
- Consumes: `Layers`, `Toon`, `Cat.take_hit`, `WorldBuilder.configure(hz, builder)` (ключ `radius`).
- Produces: `assets/models/wasp.glb` (0,3 м, жёлто-чёрная, два крыла `wing_l`/`wing_r`); `Wasp` (Node3D, `scenes/hazards/wasp.tscn`): `@export var radius := 2.5`, `@export var angular_speed := 0.8` (рад/с), `@export var height := 0.5`, `var anchor: Vector3` (центр круга = позиция при `_ready`), `func configure(hz: Dictionary, builder: Node3D)` берёт `radius`.

- [ ] **Step 1: Модель осы**

`tools/blender/gen/wasp.py`:
```python
"""Оса 0,3 м: грудь, полосатое брюшко, два крыла."""
import lib

SPEC = {"max_tris": 900, "max_dim": 0.35}


def build():
	thorax = lib.sphere("wasp", radius=0.045, material="ink")
	thorax.location.z = 0.0
	head = lib.sphere("wasp_head", radius=0.032, material="ink")
	head.location = (0, 0.065, 0.005)
	abdomen = lib.sphere("wasp_abdomen", radius=0.05, material="rarity_legendary")
	abdomen.scale = (1.0, 1.6, 0.9)
	abdomen.location = (0, -0.09, -0.005)
	parts = [thorax, head, abdomen]
	for i, y in enumerate((-0.07, -0.11)):
		ring = lib.cylinder(f"wasp_ring{i}", radius=0.047, depth=0.012, material="ink", segments=12)
		ring.rotation_euler = (1.5708, 0, 0)
		ring.location = (0, y, -0.005)
		parts.append(ring)
	for name, x in (("wasp_wing_l", 0.07), ("wasp_wing_r", -0.07)):
		wing = lib.rounded_box(name, (0.12, 0.05, 0.004), bevel=0.0, material="cream")
		wing.location = (x, 0.0, 0.045)
		wing.rotation_euler = (0, 0.25 if x > 0 else -0.25, 0)
		parts.append(wing)
	return lib.group(parts)
```
Run: `make assets ONLY=wasp` → `ОК wasp`.

- [ ] **Step 2: Падающий тест**

`tests/integration/test_wasp.gd`:
```gdscript
extends GutTest

const WaspScene := preload("res://scenes/hazards/wasp.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func test_wasp_orbits_anchor_at_radius() -> void:
	var w = WaspScene.instantiate()
	w.radius = 2.0
	world.add_child(w)
	w.global_position = Vector3(5, 0.5, 5)
	await wait_physics_frames(2)
	var anchor: Vector3 = w.anchor
	assert_almost_eq(anchor, Vector3(5, 0.5, 5), Vector3(0.01, 0.01, 0.01))
	var first := w.global_position
	for i in 6:
		await wait_seconds(0.15)
		var flat := w.global_position - anchor
		flat.y = 0.0
		assert_between(flat.length(), 1.8, 2.2, "держит радиус 2 м")
	assert_gt(w.global_position.distance_to(first), 0.5, "движется по кругу")

func test_wasp_stings_on_contact_but_not_hidden_cat() -> void:
	var w = WaspScene.instantiate()
	w.radius = 0.0
	w.height = 0.1
	world.add_child(w)
	w.global_position = Vector3(0, 0.1, 0)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.0, 0)
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 2)
	cat.invulnerable_left = 0.0
	cat.stunned_left = 0.0
	cat.hidden = true
	cat.global_position = Vector3(0.05, 0.0, 0)
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 2, "спрятанный кот не жалится")
```

- [ ] **Step 3: RED**

Run: `make import && make test-godot`
Expected: нет `wasp.tscn`.

- [ ] **Step 4: Реализация**

`scripts/hazards/wasp.gd`:
```gdscript
class_name Wasp
extends Node3D
## Оса: кружит вокруг точки (сладкая еда), жалит касанием, не преследует (спек 3.2).

@export var radius := 2.5
@export var angular_speed := 0.8
@export var height := 0.5
var anchor: Vector3
var _anchored := false
var _angle := 0.0
var _t := 0.0

@onready var _hit: Area3D = $HitZone
@onready var _model: Node3D = $Model


func configure(hz: Dictionary, _builder: Node3D) -> void:
	radius = float(hz.get("radius", radius))


func _ready() -> void:
	add_to_group("hazards")
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.body_entered.connect(_on_body)
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)


func _physics_process(delta: float) -> void:
	if not _anchored:
		anchor = global_position   # позиция задаётся после add_child, поэтому якорь берём здесь
		_anchored = true
	_t += delta
	_angle += angular_speed * delta
	_place()
	var wing_l := _model.find_child("wasp_wing_l", true, false) as Node3D
	var wing_r := _model.find_child("wasp_wing_r", true, false) as Node3D
	if wing_l and wing_r:
		var flap := sin(_t * 60.0) * 0.6
		wing_l.rotation.y = 0.25 + flap
		wing_r.rotation.y = -0.25 - flap


func _place() -> void:
	var bob := sin(_t * 4.0) * 0.08
	if radius > 0.0:
		global_position = Vector3(anchor.x + cos(_angle) * radius, height + bob, anchor.z + sin(_angle) * radius)
		rotation.y = -_angle   # мордой по касательной
	else:
		global_position = Vector3(anchor.x, height + bob, anchor.z)


func _on_body(body: Node3D) -> void:
	if body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)
```

`scenes/hazards/wasp.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/wasp.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/wasp.glb" id="2"]

[sub_resource type="SphereShape3D" id="hit"]
radius = 0.2

[node name="Wasp" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
shape = SubResource("hit")
```

- [ ] **Step 5: GREEN**

Run: `make import && make test-godot`
Expected: 2 теста `test_wasp.gd` зелёные. В реальном дворе оса кружит над точкой `[2, 0.5, 6]` (сладкое). `make shot` — видна жёлто-чёрная оса над едой справа.

- [ ] **Step 6: Commit**

```bash
git add tools/blender/gen/wasp.py assets/models/wasp.glb assets/models/wasp.glb.import scripts/hazards/wasp.gd scripts/hazards/wasp.gd.uid scenes/hazards/wasp.tscn tests/integration/test_wasp.gd tests/integration/test_wasp.gd.uid
git commit -m "Оса: модель, кружение у сладкого, укус касанием

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 12: Велосипедист по дороге со звонком

**Files:**
- Create: `tools/blender/gen/cyclist.py`, `scripts/hazards/cyclist.gd`, `scenes/hazards/cyclist.tscn`
- Modify: `scripts/main.gd` (подписка на звонок → `hud.flash_bell()`)
- Test: `tests/integration/test_cyclist.gd`

**Interfaces:**
- Consumes: `WorldBuilder` (`Road` Path3D; `configure(hz, builder)` берёт `builder.get_node("Road")`), `Hud.flash_bell`, `Layers`, `Cat.take_hit`.
- Produces: `assets/models/cyclist.glb` (велосипед с седоком, 1,8 м длиной, смотрит по −Z); `Cyclist` (Node3D, `scenes/hazards/cyclist.tscn`): `signal bell`, `@export var speed := 6.0`, `@export var interval_min := 12.0`, `@export var interval_max := 20.0`, `@export var bell_lead := 2.0`, `var path: Path3D` (назначается `configure` или напрямую), `var riding: bool`, `func start_cycle() -> void`, `func set_path(p: Path3D)`; при отсутствии пути остаётся невидимым.

- [ ] **Step 1: Модель**

`tools/blender/gen/cyclist.py`:
```python
"""Велосипедист: два колеса, рама, седок с шлемом. Длина 1,8 м, едет по -Y Blender (= -Z Godot)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.0}


def build():
	frame = lib.rounded_box("cyclist", (0.08, 0.9, 0.08), bevel=0.02, material="brick")
	frame.location.z = 0.55
	parts = [frame]
	for name, y in (("cyclist_wheel_f", -0.6), ("cyclist_wheel_b", 0.6)):
		wheel = lib.torus(name, major=0.3, minor=0.04, material="ink")
		wheel.rotation_euler = (0, 1.5708, 0)
		wheel.location = (0, y, 0.34)
		parts.append(wheel)
	post = lib.cylinder("cyclist_post", radius=0.03, depth=0.4, material="brick")
	post.location = (0, 0.2, 0.75)
	parts.append(post)
	body = lib.rounded_box("cyclist_body", (0.32, 0.45, 0.5), bevel=0.06, material="sky")
	body.location = (0, 0.05, 1.2)
	body.rotation_euler = (0.5, 0, 0)
	parts.append(body)
	head = lib.sphere("cyclist_head", radius=0.14, material="cream")
	head.location = (0, -0.2, 1.62)
	parts.append(head)
	helmet = lib.sphere("cyclist_helmet", radius=0.155, material="coral")
	helmet.scale = (1, 1, 0.6)
	helmet.location = (0, -0.2, 1.7)
	parts.append(helmet)
	for name, x in (("cyclist_leg_l", 0.12), ("cyclist_leg_r", -0.12)):
		leg = lib.rounded_box(name, (0.1, 0.12, 0.5), bevel=0.03, material="asphalt")
		leg.location = (x, -0.05, 0.75)
		parts.append(leg)
	return lib.group(parts)
```
Run: `make assets ONLY=cyclist` → `ОК cyclist` (габарит ≤ 2,0: длина 1,8 от колеса до колеса).

- [ ] **Step 2: Падающий тест**

`tests/integration/test_cyclist.gd`:
```gdscript
extends GutTest

const CyclistScene := preload("res://scenes/hazards/cyclist.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var path: Path3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	path = Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(Vector3(-6, 0, 0))
	curve.add_point(Vector3(6, 0, 0))
	path.curve = curve
	world.add_child(path)

func _cyclist(interval: float, lead: float) -> Node:
	var c = CyclistScene.instantiate()
	c.interval_min = interval
	c.interval_max = interval
	c.bell_lead = lead
	c.speed = 12.0
	world.add_child(c)
	c.set_path(path)
	return c

func test_bell_then_ride_then_hide() -> void:
	var c = _cyclist(0.2, 0.2)
	watch_signals(c)
	assert_false(c.visible, "до выезда невидим")
	await wait_seconds(0.3)
	assert_signal_emitted(c, "bell")
	assert_false(c.riding, "звонок раньше выезда")
	await wait_seconds(0.3)
	assert_true(c.riding)
	assert_true(c.visible)
	var x0: float = c.global_position.x
	await wait_seconds(0.3)
	assert_gt(c.global_position.x, x0 + 1.0, "едет вдоль дороги")
	await wait_seconds(0.6)   # проезд 12 м при 12 м/с заканчивается на t=1,4 с; следующий выезд на t=1,8 с
	assert_false(c.riding, "доехал и скрылся")
	assert_false(c.visible)

func test_cyclist_hits_cat_on_road() -> void:
	var c = _cyclist(0.1, 0.1)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_seconds(1.2)
	assert_eq(GameState.hearts, 2)
```

- [ ] **Step 3: RED**

Run: `make import && make test-godot`
Expected: нет `cyclist.tscn`.

- [ ] **Step 4: Реализация**

`scripts/hazards/cyclist.gd`:
```gdscript
class_name Cyclist
extends Node3D
## Велосипедист: ждёт 12–20 с, звонит, через 2 с выезжает по дороге (Path3D) и сбивает на ней кота.

signal bell

@export var speed := 6.0
@export var interval_min := 12.0
@export var interval_max := 20.0
@export var bell_lead := 2.0
var path: Path3D
var riding := false
var _progress := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _hit: Area3D = $HitZone
@onready var _model: Node3D = $Model


func configure(_hz: Dictionary, builder: Node3D) -> void:
	var road := builder.get_node_or_null("Road")
	if road is Path3D:
		set_path(road)


func set_path(p: Path3D) -> void:
	path = p
	if is_inside_tree() and not riding:
		start_cycle()


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.monitoring = false
	_hit.body_entered.connect(_on_body)
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)
	visible = false
	if path:
		start_cycle()


func start_cycle() -> void:
	var wait := _rng.randf_range(interval_min, interval_max)
	get_tree().create_timer(wait).timeout.connect(_ring)


func _ring() -> void:
	if not is_inside_tree():
		return
	bell.emit()
	get_tree().create_timer(bell_lead).timeout.connect(_depart)


func _depart() -> void:
	if not is_inside_tree() or path == null:
		return
	riding = true
	_progress = 0.0
	visible = true
	_hit.set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if not riding or path == null:
		return
	var length := path.curve.get_baked_length()
	_progress += speed * delta
	if _progress >= length:
		riding = false
		visible = false
		_hit.set_deferred("monitoring", false)
		start_cycle()
		return
	var pos := path.curve.sample_baked(_progress)
	var ahead := path.curve.sample_baked(minf(_progress + 0.5, length))
	global_position = path.global_transform * pos
	var dir := (path.global_transform * ahead) - global_position
	if dir.length() > 0.01:
		rotation.y = atan2(-dir.x, -dir.z)


func _on_body(body: Node3D) -> void:
	if riding and body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)
```

`scenes/hazards/cyclist.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/cyclist.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/cyclist.glb" id="2"]

[sub_resource type="BoxShape3D" id="hit"]
size = Vector3(0.5, 1.0, 1.9)

[node name="Cyclist" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
shape = SubResource("hit")
```

В `scripts/main.gd` в конец `_ready()`:
```gdscript
	for c in get_tree().get_nodes_in_group("hazards"):
		if c.has_signal("bell"):
			c.bell.connect(func() -> void: hud.flash_bell())
```
(Опасности строятся `WorldBuilder` в `_ready` дочернего узла, то есть раньше `Main._ready`, поэтому группа уже заполнена.)

- [ ] **Step 5: GREEN**

Run: `make import && make test-godot`
Expected: 2 теста `test_cyclist.gd` зелёные; `test_world_builder.gd`: в реальном дворе `hazards_built == 3`, предупреждений нет.

`make run`: через 12–20 с на экране «🔔 Велосипед!», через 2 с по дальней дороге (z = 12) проезжает велосипедист.

- [ ] **Step 6: Commit**

```bash
git add tools/blender/gen/cyclist.py assets/models/cyclist.glb assets/models/cyclist.glb.import scripts/hazards/cyclist.gd scripts/hazards/cyclist.gd.uid scenes/hazards/cyclist.tscn scripts/main.gd tests/integration/test_cyclist.gd tests/integration/test_cyclist.gd.uid
git commit -m "Велосипедист: модель, маршрут по дороге, звонок за 2 секунды

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 13: Пропсы двора и итоговая раскладка

**Files:**
- Create: `tools/blender/gen/{bench,lamp,car,wall,fence,bag,stairs,bush,tree,puddle,arch,door}.py`
- Modify: `data/layout/yard.json`
- Test: `tests/integration/test_world_builder.gd` (ужесточить `test_real_yard_layout_loads`)

**Interfaces:**
- Produces: 12 моделей в `assets/models/`, каждая ≤ 800 треугольников (стена и машина ≤ 1500), основание на z=0; раскладка двора со всеми пропсами, укрытиями «под машиной» (`car`) и «под лавкой» (`bench`), лестницей на балкон (ступени 0,25 м, платформа 1,0 м) и точкой редкой еды на балконе.

- [ ] **Step 1: Ужесточить тест**

В `tests/integration/test_world_builder.gd` заменить `test_real_yard_layout_loads` на:
```gdscript
func test_real_yard_layout_loads() -> void:
	var data := BuilderScript.load_layout("res://data/layout/yard.json")
	assert_gte(data["props"].size(), 24, "во дворе не меньше 24 пропсов")
	var kinds := {}
	for h in data["hideouts"]:
		kinds[h["kind"]] = true
	assert_true(kinds.has("box") and kinds.has("car") and kinds.has("bench"), "три типа укрытий")
	assert_gte(data["spawn_points"].size(), 8)
	var models := {}
	for p in data["props"]:
		models[p["model"]] = true
	for m in ["bench", "lamp", "car", "wall", "fence", "bag", "stairs", "bush", "tree", "puddle", "arch", "door"]:
		assert_true(models.has(m), "в раскладке есть " + m)
	var b = _builder()
	b.build(data)
	assert_eq(b.props_built, data["props"].size(), "все модели существуют")
```

Run: `make test-godot` → падает (нет моделей / мало пропсов).

- [ ] **Step 2: Двенадцать генераторов**

`tools/blender/gen/bench.py`:
```python
"""Лавочка: сиденье 1,5 м на высоте 0,45, спинка, две ножки. Под лавкой — укрытие."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.6}


def build():
	seat = lib.rounded_box("bench", (1.5, 0.45, 0.06), bevel=0.02, material="brick")
	seat.location.z = 0.45
	back = lib.rounded_box("bench_back", (1.5, 0.06, 0.4), bevel=0.02, material="brick")
	back.location = (0, -0.22, 0.72)
	parts = [seat, back]
	for i, x in enumerate((-0.6, 0.6)):
		leg = lib.rounded_box(f"bench_leg{i}", (0.06, 0.4, 0.45), bevel=0.01, material="ink")
		leg.location = (x, 0, 0.225)
		parts.append(leg)
	return lib.group(parts)
```
`tools/blender/gen/lamp.py`:
```python
"""Уличный фонарь 2,6 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.7}


def build():
	post = lib.cylinder("lamp", radius=0.05, depth=2.4, material="ink", segments=10)
	post.location.z = 1.2
	base = lib.cylinder("lamp_base", radius=0.14, depth=0.1, material="ink", segments=10)
	base.location.z = 0.05
	head = lib.rounded_box("lamp_head", (0.3, 0.3, 0.2), bevel=0.04, material="rarity_legendary")
	head.location.z = 2.5
	return lib.group([post, base, head])
```
`tools/blender/gen/car.py`:
```python
"""Припаркованная машина 3,6×1,7×1,4 м, клиренс 0,3 м (под ней укрытие)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 3.7}


def build():
	body = lib.rounded_box("car", (1.7, 3.6, 0.5), bevel=0.08, segments=3, material="brick")
	body.location.z = 0.55
	cabin = lib.rounded_box("car_cabin", (1.5, 1.9, 0.55), bevel=0.12, segments=3, material="brick")
	cabin.location = (0, -0.2, 1.07)
	glass = lib.rounded_box("car_glass", (1.52, 1.5, 0.35), bevel=0.05, material="sky")
	glass.location = (0, -0.2, 1.1)
	parts = [body, cabin, glass]
	for i, (x, y) in enumerate(((-0.8, 1.1), (0.8, 1.1), (-0.8, -1.1), (0.8, -1.1))):
		wheel = lib.cylinder(f"car_wheel{i}", radius=0.32, depth=0.22, material="ink", segments=14)
		wheel.rotation_euler = (0, 1.5708, 0)
		wheel.location = (x, y, 0.32)
		parts.append(wheel)
	return lib.group(parts)
```
`tools/blender/gen/wall.py`:
```python
"""Модуль стены дома 6×3,2 м с тремя окнами (ставить вдоль края двора)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 6.1}


def build():
	wall = lib.rounded_box("wall", (6.0, 0.4, 3.2), bevel=0.03, material="sand")
	wall.location.z = 1.6
	parts = [wall]
	for i, x in enumerate((-1.9, 0.0, 1.9)):
		frame = lib.rounded_box(f"wall_frame{i}", (1.0, 0.1, 1.2), bevel=0.02, material="cream")
		frame.location = (x, -0.22, 1.8)
		glass = lib.rounded_box(f"wall_glass{i}", (0.8, 0.06, 1.0), bevel=0.0, material="sky")
		glass.location = (x, -0.26, 1.8)
		parts += [frame, glass]
	return lib.group(parts)
```
`tools/blender/gen/fence.py`:
```python
"""Забор 2 м: две перекладины и 5 столбиков."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.1}


def build():
	rail = lib.rounded_box("fence", (2.0, 0.05, 0.08), bevel=0.01, material="leaf")
	rail.location.z = 0.9
	rail2 = lib.rounded_box("fence_rail2", (2.0, 0.05, 0.08), bevel=0.01, material="leaf")
	rail2.location.z = 0.45
	parts = [rail, rail2]
	for i in range(5):
		post = lib.rounded_box(f"fence_post{i}", (0.08, 0.08, 1.1), bevel=0.01, material="leaf")
		post.location = (-1.0 + i * 0.5, 0, 0.55)
		parts.append(post)
	return lib.group(parts)
```
`tools/blender/gen/bag.py`:
```python
"""Мешок мусора: сплюснутая сфера с узлом."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.8}


def build():
	bag = lib.sphere("bag", radius=0.3, material="ink")
	bag.scale = (1.0, 1.0, 0.8)
	bag.location.z = 0.24
	knot = lib.sphere("bag_knot", radius=0.08, material="ink")
	knot.location.z = 0.52
	return lib.group([bag, knot])
```
`tools/blender/gen/stairs.py`:
```python
"""Лестница на балкон: 4 ступени по 0,25 м и площадка 1,2×1,2 на высоте 1,0 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.5}


def build():
	parts = []
	for i in range(4):
		step = lib.rounded_box("stairs" if i == 0 else f"stairs_step{i}", (1.2, 0.5, 0.25), bevel=0.02, material="sand")
		step.location = (0, i * 0.5, 0.125 + i * 0.25)
		parts.append(step)
	deck = lib.rounded_box("stairs_deck", (1.2, 1.2, 0.12), bevel=0.02, material="sand")
	deck.location = (0, 2.55, 0.94)
	parts.append(deck)
	rail = lib.rounded_box("stairs_rail", (0.06, 1.2, 0.9), bevel=0.01, material="ink")
	rail.location = (0.6, 2.55, 1.45)
	parts.append(rail)
	return lib.group(parts)
```
`tools/blender/gen/bush.py`:
```python
"""Куст: три сферы."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.2}


def build():
	a = lib.sphere("bush", radius=0.4, material="leaf")
	a.location.z = 0.38
	b = lib.sphere("bush_b", radius=0.3, material="olive")
	b.location = (0.35, 0.1, 0.3)
	c = lib.sphere("bush_c", radius=0.28, material="leaf")
	c.location = (-0.3, -0.15, 0.28)
	return lib.group([a, b, c])
```
`tools/blender/gen/tree.py`:
```python
"""Дерево 3,2 м: ствол и две сферы кроны."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.3}


def build():
	trunk = lib.cylinder("tree", radius=0.15, depth=1.6, material="brick", segments=10)
	trunk.location.z = 0.8
	crown = lib.sphere("tree_crown", radius=0.9, material="leaf")
	crown.location.z = 2.2
	crown2 = lib.sphere("tree_crown2", radius=0.6, material="olive")
	crown2.location = (0.5, 0.3, 2.6)
	return lib.group([trunk, crown, crown2])
```
`tools/blender/gen/puddle.py`:
```python
"""Лужа: плоский диск."""
import lib

SPEC = {"max_tris": 200, "max_dim": 1.6}


def build():
	p = lib.cylinder("puddle", radius=0.75, depth=0.01, material="sea_light", segments=18)
	p.scale = (1.0, 0.7, 1.0)
	p.location.z = 0.005
	return [p]
```
`tools/blender/gen/arch.py`:
```python
"""Арка во двор: два пилона и перекладина, проём 2,4×2,6 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.6}


def build():
	left = lib.rounded_box("arch", (0.5, 0.6, 2.6), bevel=0.04, material="sand")
	left.location = (-1.45, 0, 1.3)
	right = lib.rounded_box("arch_right", (0.5, 0.6, 2.6), bevel=0.04, material="sand")
	right.location = (1.45, 0, 1.3)
	top = lib.rounded_box("arch_top", (3.4, 0.6, 0.6), bevel=0.06, material="brick")
	top.location.z = 2.9
	return lib.group([left, right, top])
```
`tools/blender/gen/door.py`:
```python
"""Дверь подъезда с рамой и ступенькой."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.4}


def build():
	frame = lib.rounded_box("door", (1.3, 0.2, 2.3), bevel=0.03, material="cream")
	frame.location.z = 1.15
	leaf = lib.rounded_box("door_leaf", (1.0, 0.1, 2.1), bevel=0.02, material="sea_deep")
	leaf.location = (0, -0.08, 1.05)
	step = lib.rounded_box("door_step", (1.6, 0.5, 0.15), bevel=0.02, material="sand")
	step.location = (0, -0.35, 0.075)
	return lib.group([frame, leaf, step])
```

Run: `make assets` → все `ОК`, ни одного `ОШИБКА`. Если какой-то пропс превысил треугольники, уменьшить `segments` у сфер/цилиндров.

- [ ] **Step 3: Итоговая раскладка**

Заменить `data/layout/yard.json` целиком:
```json
{
  "props": [
    {"model": "wall", "pos": [0, 0, -14], "rot": 0},
    {"model": "wall", "pos": [6, 0, -14], "rot": 0},
    {"model": "wall", "pos": [-6, 0, -14], "rot": 0},
    {"model": "wall", "pos": [-12, 0, -8], "rot": 90},
    {"model": "wall", "pos": [-12, 0, -2], "rot": 90},
    {"model": "door", "pos": [3, 0, -13.75], "rot": 0},
    {"model": "door", "pos": [-9, 0, -13.75], "rot": 0},
    {"model": "stairs", "pos": [-11.3, 0, -11.5], "rot": 90,
     "colliders": [
       {"size": [1.2, 0.25, 0.5], "offset": [0, 0.125, 0]},
       {"size": [1.2, 0.5, 0.5], "offset": [0, 0.25, 0.5]},
       {"size": [1.2, 0.75, 0.5], "offset": [0, 0.375, 1.0]},
       {"size": [1.2, 1.0, 0.5], "offset": [0, 0.5, 1.5]},
       {"size": [1.2, 0.12, 1.2], "offset": [0, 0.94, 2.55]}
     ]},
    {"model": "bin", "pos": [3, 0, -11], "rot": 0, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [4, 0, -11], "rot": 0, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [-6, 0, 2], "rot": 90, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [-6, 0, 3], "rot": 90, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bag", "pos": [2.2, 0, -11.2], "rot": 30},
    {"model": "bag", "pos": [-6.6, 0, 1.2], "rot": 0},
    {"model": "box", "pos": [1.5, 0, 1.5], "rot": 0, "outline": true},
    {"model": "box", "pos": [1.5, 0.3, 1.5], "rot": 20, "outline": true},
    {"model": "box", "pos": [-2, 0, -1], "rot": 45, "outline": true},
    {"model": "box", "pos": [-3.5, 0, 4], "rot": 0, "outline": true},
    {"model": "box", "pos": [6, 0, -1], "rot": 0, "outline": true},
    {"model": "box", "pos": [2.6, 0, -10.4], "rot": 10, "outline": true},
    {"model": "car", "pos": [8, 0, 4], "rot": 0, "outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}]},
    {"model": "car", "pos": [-8, 0, 7], "rot": 15, "outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}]},
    {"model": "bench", "pos": [0, 0, 7], "rot": 180, "outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}]},
    {"model": "bench", "pos": [-5, 0, -8], "rot": 90, "outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}]},
    {"model": "lamp", "pos": [5, 0, 8], "rot": 0},
    {"model": "lamp", "pos": [-9, 0, -3], "rot": 0},
    {"model": "tree", "pos": [9, 0, -6], "rot": 0},
    {"model": "tree", "pos": [-9, 0, 10], "rot": 0},
    {"model": "bush", "pos": [7, 0, -10], "rot": 0},
    {"model": "bush", "pos": [-3, 0, 10], "rot": 40},
    {"model": "bush", "pos": [10, 0, 0], "rot": 0},
    {"model": "fence", "pos": [10, 0, 7], "rot": 90},
    {"model": "fence", "pos": [10, 0, 9], "rot": 90},
    {"model": "puddle", "pos": [3, 0, 3], "rot": 0},
    {"model": "puddle", "pos": [-5, 0, -5], "rot": 60},
    {"model": "arch", "pos": [0, 0, 10.5], "rot": 0}
  ],
  "hideouts": [
    {"kind": "box", "pos": [-2, 0.2, -1], "size": [0.7, 0.4, 0.6]},
    {"kind": "box", "pos": [-3.5, 0.2, 4], "size": [0.7, 0.4, 0.6]},
    {"kind": "box", "pos": [6, 0.2, -1], "size": [0.7, 0.4, 0.6]},
    {"kind": "box", "pos": [2.6, 0.2, -10.4], "size": [0.7, 0.4, 0.6]},
    {"kind": "car", "pos": [8, 0.15, 4], "size": [1.4, 0.3, 3.2]},
    {"kind": "car", "pos": [-8, 0.15, 7], "rot": 15, "size": [1.4, 0.3, 3.2]},
    {"kind": "bench", "pos": [0, 0.2, 7], "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [-5, 0.2, -8], "rot": 90, "size": [1.3, 0.4, 0.4]}
  ],
  "spawn_points": [
    {"pos": [3.5, 0, -10], "allowed": [0]},
    {"pos": [-5, 0, 2.5], "allowed": [0]},
    {"pos": [0, 0, -4], "allowed": [0]},
    {"pos": [-4, 0, -4], "allowed": [0]},
    {"pos": [1, 0, 6.3], "allowed": [0]},
    {"pos": [-5.8, 0, -7], "allowed": [0, 1]},
    {"pos": [4, 0, 4], "allowed": [0, 1]},
    {"pos": [-11.3, 1.0, -9.0], "allowed": [1]},
    {"pos": [2, 0, 6], "allowed": [1, 3]},
    {"pos": [7.5, 0, -8], "allowed": [2, 3]}
  ],
  "hazards": [
    {"type": "dog", "pos": [7, 0, -7], "rot": 90},
    {"type": "wasp", "pos": [2, 0.5, 6], "radius": 2.5},
    {"type": "cyclist", "pos": [0, 0, 12]}
  ],
  "road": {"points": [[-25, 0, 12], [25, 0, 12]]}
}
```
Балконная точка `[-11.3, 1.0, -9.0]` лежит на площадке лестницы (площадка на высоте 1,0 м, центр `pos + rot90(0, 2.55)`). Кот поднимается по ступеням 0,25 м прыжком (0,84 м) или шагом.

- [ ] **Step 4: GREEN, скриншот, прогон**

Run: `make import && make test-godot`
Expected: `test_world_builder.gd` зелёный (`props_built == 38`), остальные без изменений (линия x=0, z от 0 до −3 по-прежнему пуста).

`make shot SHOT=build/task13.png`: двор с домами на дальнем плане, машины, лавки, деревья, фонари, у коробок/машин/лавок тонкая обводка. `make run`: обойти двор, спрятаться под машиной (Ctrl), подняться по лестнице, собрать редкую еду на балконе.

- [ ] **Step 5: Commit**

```bash
git add tools/blender/gen assets/models data/layout/yard.json tests/integration/test_world_builder.gd
git commit -m "Пропсы двора (12 генераторов) и итоговая раскладка с укрытиями и лестницей

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 14: Клипы собаки «лежит» и «насторожилась» через UniMate (лимит 1,5 часа)

**Files:**
- Create (если получилось): `third_party/unimate_clips/dog_canonical.glb`, `third_party/unimate_clips/dog_sleep.glb`, `third_party/unimate_clips/dog_alert.glb`, `third_party/unimate_clips/dog_annotation.json`
- Modify: `tools/blender/dog.py`, `third_party/unimate_clips/README.md`, `docs/superpowers/notes/2026-10-07-unimate-attempt.md`
- Test: `tests/integration/test_dog_asset.gd`

Порядок по правилу владельца: готовое → UniMate → генерация. У Quaternius только Idle/Walking, спек 2.5 требует видимую позу «спит (лежит)» и «насторожилась (уши вверх)». Пробуем UniMate по процедуре `docs/replay/02-procedure.md`, шаг 5 (окружение `uv` в `/tmp/snack_scratch/unimate`, чекпоинт 1,2 ГБ нужно скачать заново).

- [ ] **Step 1: Предобработка рига собаки**

```bash
cd <проект> && $BLENDER -b --python-exit-code 1 --python-expr "
import sys, os; sys.path.insert(0, 'tools/blender')
import bpy, dog, export
objs = dog.build(); export.export_glb('/tmp/snack_scratch/unimate/UniMate/dog.glb', objs, animations=True); print('ОК')"
cd /tmp/snack_scratch/unimate/UniMate
../venv/bin/python -m data_process.rig_preprocess run --input dog.glb --output_dir outputs/rig/dog --annotate rule
```
Скопировать `third_party/unimate_clips/annotation.json` кота в `outputs/rig/dog/annotation.json` и заменить поле `asset` на `"dog"` (кости и роли у собаки те же: `Bone`, `Bone.001`, …, `head`); затем:
```bash
../venv/bin/python -m data_process.rig_preprocess run --input dog.glb --output_dir outputs/rig/dog --profile general --annotation outputs/rig/dog/annotation.json
```
Проверить `outputs/rig/dog/preview.png`: стрелка вперёд, передние лапы спереди.

- [ ] **Step 2: Генерация и применение**

```bash
../venv/bin/python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 --asset outputs/rig/dog \
  --prompt "An object lies down on its belly and rests." "An object stands still with its head raised, alert." \
  --num_repetitions 2 --output_dir outputs/samples/dog --only_save_motion
PATH=$PWD/../shim:$PWD/../venv/bin:$PATH SKIP_INVALID=1 bash scripts/run_animate_motion.sh outputs/samples/dog
```
Отрендерить листы кадров (скрипт `render_clip.py` из процедуры) и выбрать вариант, где собака опускает корпус к земле (sleep) и стоит с поднятой головой (alert). Критерий: высота корневой кости в sleep ниже 60% от idle.

- [ ] **Step 3: Падающий тест (только если клипы получены)**

В `tests/integration/test_dog_asset.gd` добавить:
```gdscript
func test_dog_has_sleep_and_alert_clips() -> void:
	var inst := (load(DOG_PATH) as PackedScene).instantiate() as Node3D
	add_child_autofree(inst)
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("sleep"))
	assert_true(ap.has_animation("alert"))
```
Run: `make test-godot` → падает.

- [ ] **Step 4: Встроить в dog.py**

Скопировать `outputs/rig/dog/cat.glb`-аналог (`outputs/rig/dog/dog.glb`) в `third_party/unimate_clips/dog_canonical.glb`, выбранные клипы в `dog_sleep.glb`, `dog_alert.glb`, разметку в `dog_annotation.json`. В `tools/blender/dog.py` повторить схему `cat.py`: импортировать канонический glb, скопировать `Idle`/`Walking` из `Dog.blend` (`rig_utils.clean_action` с `rename={"Bone.003": "head"}`), импортировать клипы и переименовать их actions в `sleep`/`alert`, `split_material_by_height`, `rig_utils.face_forward`, масштаб 0,55 м по `lib.world_extent`. В `scripts/hazards/dog.gd` `play_clip` уже предпочитает `sleep`/`alert`, если они есть; клипы зациклить в `_ready` (добавить в список `["idle", "walk", "sleep", "alert"]`).

Run: `make assets ONLY=dog && make import && make test-godot` → зелёный.

- [ ] **Step 5: Если не получилось за 1,5 часа**

Оставить idle как позу сна (отклонение записано в начале плана), дописать абзац в `docs/superpowers/notes/2026-10-07-unimate-attempt.md` с причиной. Тест из шага 3 не добавлять.

- [ ] **Step 6: Commit**

```bash
git add third_party/unimate_clips tools/blender/dog.py assets/models/dog.glb scripts/hazards/dog.gd tests/integration/test_dog_asset.gd docs/superpowers/notes
git commit -m "Клипы собаки sleep/alert через UniMate (или зафиксирован отказ)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 15: Документация воспроизведения и дорожная карта

**Files:**
- Modify: `docs/replay/02-procedure.md`, `docs/replay/03-files.md` (через `make replay`), `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`, `CLAUDE.md`

- [ ] **Step 1: Дописать процедуру**

В `docs/replay/02-procedure.md` перед разделом «Известные грабли» добавить раздел «План 2. Игровой цикл» с подразделами по задачам 1–14 этого плана: какие файлы созданы (ссылка на приложение), команды сборки (`make assets`, `make import && make test-godot`), контрольные точки (число тестов после каждой задачи, что видно на `make shot`), и как выполнялась задача 14 (команды UniMate для собаки, выбранные варианты). Все новые грабли, встреченные при исполнении (из журнала `Ruling:`), добавить в сводку в конце файла.

- [ ] **Step 2: Приложение и дорожная карта**

```bash
make replay
```
В `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md` заголовок плана 2 дополнить «— ВЫПОЛНЕН <дата>, слит в main», список отложенных мелочей обновить (убрать закрытые: Box3, обводка коробок; добавить новые из финального ревью). В `CLAUDE.md` обновить раздел «Статус и что дальше» (следующий шаг — план 3) и карту структуры (новые папки `scripts/food`, `scripts/hazards`, `scripts/ui`, `data/`).

- [ ] **Step 3: Проверка и коммит**

Run: `rm -rf .godot && make test`
Expected: зелёный с нуля.

```bash
git add docs CLAUDE.md
git commit -m "Документация плана 2: процедура воспроизведения, приложение файлов, статус

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## Готово, когда

- `rm -rf .godot && make test` зелёный: 12 Blender-тестов и ≈75 GUT-тестов.
- `make assets` собирает 4 старых + 8 еды + собака + оса + велосипедист + 12 пропсов без ошибок валидации.
- `make run`: еда с цветными кольцами по двору, подбор до 3 штук в HUD, укрытие по Ctrl в коробке/под машиной/под лавкой, съедание по E даёт сытость и карточку, собака замечает и гонится, удар выбивает еду и сердечко, третий удар — затемнение и возрождение, велосипедист звонит и проезжает по дороге, оса кружит над сладким.
- `docs/replay/` дописан, `make replay` выполнен, дорожная карта обновлена.

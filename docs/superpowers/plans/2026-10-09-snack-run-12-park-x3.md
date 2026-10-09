# План 12. Парк ×3, вода и закрытая арка кафе — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Парк становится 90×96 м: прежний парк — центральная поляна с фонтаном, к северу холм с беседкой (+3 м) и аллея по склону, на западе пруд в низине, на востоке роща; появляется вода по правилам этапа 3 (кот тонет и возвращается на ближайший берег); обход арки кафе по улице закрыт забором.

**Architecture:** Парк, как и двор, собирается генератором `tools/layout/layout_gen.py` из описания `data/layout_src/park.json` (ядро — нынешний парк без боковых и северного заборов). Генератор получает операции `pond` (котловина в рельефе, зона воды, маркеры берега) и параметр `extra` у `perimeter` (флаги каждого модуля, например коллайдер забора 1,8 м). В Godot — общий узел `Water` (Area3D + поверхность с шейдером), маркеры `shore`, метод кота `drown()`. Порт (план 13) использует ту же воду для моря.

**Tech Stack:** Python 3 (stdlib), Blender 5.2.2 (беседка), Godot 4.7.2 + GUT 9.7.1.

**Spec:** `docs/superpowers/specs/2026-10-09-snack-run-scale-terrain-design.md` (разделы 2, 3, 7 — план 12); вода — `docs/superpowers/specs/2026-10-09-snack-run-stage3-port-design.md`, раздел 2; арка кафе — основной спек 3.4.

## Global Constraints

- Парк 90×96 м: x −45…45, z 29…125; ядро (прежний парк) остаётся на месте, ворота из двора — (12, 29,9), сытость 25.
- Количество парка (ориентир спека): ≥ 35 точек еды, ≥ 25 клубочков; опасностей ×2 (4 стаи голубей, 2 садовника, 6 дождевателей, 2 ребёнка, 2 сторожа).
- Еда парка — только блюда парка: 0 — popcorn, bagel; 1 — corn, sandwich; 2 — cotton_candy; 3 — cupcake.
- Вода: кот, погрузившийся на 0,15 м ниже поверхности, 1 с тонет (всплеск, звук), затем возвращается на ближайший маркер `shore`; еда из зубов потеряна (не рассыпается), сердечко не снимается, 2 с неуязвимости.
- Холм: склон ≤ 30°, на вершине беседка; пруд: глубина 1,5 м, поверхность −0,5 м.
- Забор парка и двора — коллайдер 1,8 м (через забор не перепрыгнуть: прыжок 0,84 м).

## Review Focus

1. Кот в пруду всегда возвращается на сушу, и на берегу его сразу не затягивает обратно (маркеры берега выше воды и вне зоны).
2. Из двора на улицу и в кафе нельзя пройти мимо арки, пока ворота закрыты; из парка нельзя выйти, кроме ворот.
3. Люди парка (садовник, сторож) по маршрутам на холме не застревают — маршруты не пересекают пруд и стены.
4. Ключи клубочков ядра парка не меняются (сохранения).
5. Еда парка не появляется во дворе и наоборот.

---

### Task 1: Забор вдоль улицы — арка кафе снова единственный проход

**Files:** `tools/layout/layout_gen.py` (`perimeter`: параметр `extra`), `tools/layout/tests/test_layout_gen.py`, `data/layout_src/yard.json`, `tests/integration/test_yard_x3.gd`.

- [ ] RED (Python): `test_perimeter_extra_flags_reach_every_module` — `lg.perimeter([0,0,4,1], "fence", 2.0, "s", extra={"colliders": [...]})` → у каждого модуля ключ `colliders`; в `generate` операция `perimeter` передаёт `op["extra"]`.
- [ ] RED (GUT): `test_street_is_closed_except_arch` — горизонтальные лучи на высоте 0,3 м с z 9,5 на z 11,5 при x от −87 до 87 шагом 6 (кроме |x| < 2) упираются в коллайдер.
- [ ] GREEN: `perimeter(..., extra=None)` добавляет `dict(extra)` в каждый модуль. В `yard.json` зона «улица»: две операции `perimeter` `model: fence`, `length: 2.0`, `sides: "s"`, `rect` [−90, 0, −1.7, 10.5] и [1.7, 0, 90, 10.5], `extra.colliders` [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]. `make layout`.
- [ ] Полный `make test`, коммит «Забор вдоль улицы: в кафе только через арку».

### Task 2: Вода: зона, поверхность, тонущий кот, берег

**Files:** Create `scripts/world/water.gd` (class `Water`), `assets/shaders/water.gdshader`, `tests/integration/test_water.gd`; Modify `scripts/player/cat.gd` (`drown`, `drowning_left`), `scripts/world/world_builder.gd` (`water_zones`, `shore`), `tools/audio/gen_sfx.py` (`splash.wav`), `scripts/autoload/sfx.gd`.

**Interfaces:**
- `Water` (Area3D): `size: Vector3`, `level: float` (мировая высота поверхности = `global_position.y`); зона-коробка от `level − size.y` до `level − 0.15`; `static nearest_shore(tree, pos) -> Vector3` по группе `shore` (без маркеров — позиция `Main.respawn_position()` не нужна: возвращает `pos` с y = level + 1).
- `Cat.drown(shore: Vector3) -> bool` — false, если уже тонет; 1 с `drowning_left`, ввод выключен, `GameState.spill()` без рассыпания, `Sfx.play(&"splash")`, `Effects.burst` голубой; по окончании `teleport(shore)` (даёт 2 с неуязвимости).
- Раскладка: `"water_zones": [{"pos": [x, level, z], "size": [sx, sy, sz]}]` (pos — абсолютный), `"shore": [{"pos": [x, 0, z]}]` (на рельефе, как обычные точки).

- [ ] RED (`test_water.gd`):
  - `test_cat_sinking_into_water_drowns_and_returns_to_nearest_shore` — пол-коробка на −1,5, вода level −0,5, два маркера берега; кот с едой в зубах ставится в (0, −1,4, 0); через 1,5 с кот у ближайшего маркера, рот пуст, сердечек 3, `invulnerable_left > 0`.
  - `test_cat_on_shore_is_not_drowned` — кот на суше рядом с зоной (y 0) не тонет 1 с.
  - `test_water_surface_mesh_is_at_level` — у `Water` дочерний `MeshInstance3D` `Surface` на y = level, материал — шейдер воды.
  - `test_builder_builds_water_zones_and_shore` — `WorldBuilder.build({"water_zones": [...], "shore": [...]})` даёт узел `Water` с level из раскладки и маркеры в группе `shore`.
- [ ] GREEN: реализация по интерфейсам; шейдер — цвет `sea_light` #2F9CCF с прозрачностью 0,85, рябь нормали синусами по `TIME` и мировым xz, `roughness` 0,05 (SSR окружения даёт отражения). `make sfx` (всплеск — шумовой всплеск с затуханием 0,4 с).
- [ ] `make test`, коммит «Вода: пруд и море по правилам этапа 3 — кот тонет и возвращается на берег».

### Task 3: Беседка и операция `pond` генератора

**Files:** Create `tools/blender/gen/gazebo.py`; Modify `tools/layout/layout_gen.py` (`pond`, списки `water_zones`, `shore`, укрытие `bush`), тесты.

- [ ] RED (Python): `test_pond_makes_basin_water_and_shore_ring` — `lg.pond((−28, 62), 11, 1.5, −0.5)` → элемент рельефа `basin` (center, radius, depth), зона воды на level −0,5 размером 2r×2,0×2r, 8 маркеров берега на радиусе r + 1,5, блок-прямоугольник 2(r+1)×2(r+1).
- [ ] RED (Python): `test_scatter_bush_hideout` — `what: hideout, kind: bush` → проп `bush` (флаги из ядра) и укрытие `bush` (y 0,25, size 0,9×0,5×0,9).
- [ ] RED (GUT, `test_world_builder`): `test_gazebo_floor_and_posts_are_solid_but_inside_is_free` — пол беседки на 0,3 м, внутри между столбами проходимо.
- [ ] GREEN: беседка — восьмигранный пол r 2,0 h 0,3 (`sand`), 6 столбов r 0,08 h 2,2 (`cream`), конус крыши r 2,6 (`brick`), `max_tris` 1500; в описании явные коллайдеры (пол 3,4×0,3×3,4 и 6 столбов 0,16×2,2×0,16). `pond` как в тесте; `generate` пишет `water_zones` и `shore`.
- [ ] `make test-tools`, `make test-blender`, коммит «Беседка и пруд в генераторе раскладки».

### Task 4: Описание парка ×3 и парк в игре

**Files:** Create `data/layout_src/park_core.json` (нынешний `park.json` без заборов при x ±15 и z 60,9), `data/layout_src/park.json`; генерируются `data/layout/park.json`, `data/terrain_src/park.json`, `data/terrain/park.json`; Create `tests/integration/test_park_x3.gd`; Modify `tests/integration/test_park.gd` (числа из раскладки), `tools/layout/tests/test_layout_gen.py` (`test_core_park_yarn_keys_preserved`).

Зоны (x0, z0, x1, z1):
- **Поляна** — ядро [−15, 29, 15, 61] без изменений, кроме убранных боковых и северного заборов.
- **Холм с беседкой**: `hill` центр (0, 92), r 18, h 3 (уклон ≤ 15°); беседка на вершине; аллея по склону — фонари вдоль x 0 от z 64 до 82, гравий 3 м шириной; под беседкой 2 клубочка и еда (очень редкая).
- **Пруд**: `pond` центр (−28, 66), r 11, глубина 1,5, level −0,5; камыши — `grass` по берегу; 2 ребёнка у пруда и у площадки.
- **Роща** [18, 36, 43, 88]: плотные деревья и кусты, укрытия-кусты, садовник 2 с маршрутом по краю рощи, стая голубей у скамеек.
- **Северный луг** [−43, 100, 43, 123]: трава, клумбы, дождеватели, сторож 2 по маршруту вокруг холма и пруда.
- **Край**: забор (коллайдер 1,8) по x ±45 и z 125 (на севере — место под ворота порта у x −6 в плане 13, пока сплошной); юг закрыт стенами двора.
- Покрытия: трава по умолчанию; гравий — дорожки ядра (как было) и аллея; песок у пруда не нужен.
- `counts`: spawn_points 35, yarn 25, hideouts 14.

- [ ] RED (`test_park_x3.gd`): размеры 90×96; число точек и опасностей; холм +3 у беседки; вода пруда на −0,5 и маркеры берега на суше; еда на поверхности (как в `test_yard_x3`); край закрыт (лучи наружу на x ±45 и z 125); маршруты садовников и сторожей не заходят в пруд (все точки маршрутов на высоте рельефа > −0,3).
- [ ] GREEN: описание, `make layout`, правка старых тестов парка под числа из раскладки.
- [ ] Кадры: холм с беседкой, пруд, роща, ночь у пруда.
- [ ] `make test`, коммит «Парк ×3: холм с беседкой, пруд, роща, северный луг».

### Task 5: Документация

- [ ] `02-procedure.md` (раздел плана 12, грабли), дорожная карта, CLAUDE.md (вода, `make layout` для парка), `make replay`, коммит.

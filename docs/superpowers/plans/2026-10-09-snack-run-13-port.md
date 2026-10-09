# План 13. Район «Порт» и вода — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** За парком появляется порт 120×102 м: набережная на террасе, причал, песчаный пляж с дюнами, море и гавань с водой из плана 12, три качающиеся лодки и пять бочек, ворота из парка по сытости 50, шесть новых вкусняшек (альбом 14 → 20), укрытия и клубочки.

**Architecture:** Порт — третий район в `district_yard.tscn` (`PortTerrain` + `PortBuilder`), раскладка из описания `data/layout_src/port.json` генератором (ядра нет). Генератор получает `sides`/`gaps` у `terrace` (стена только к пляжу), операции `flat` (ровная высота — пляж и дно моря) и `water` (зона воды и явные маркеры берега). Качающиеся опоры — узел `Floater` (AnimatableBody3D, синус по высоте и крену), раскладка `floaters`. Текстуры песка и досок — генератор картинок по манифесту.

**Tech Stack:** Python 3, Blender 5.2.2, OpenAI `gpt-image-2.5` через `tools/images/gen.py`, Godot 4.7.2 + GUT.

**Spec:** `docs/superpowers/specs/2026-10-09-snack-run-stage3-port-design.md` (разделы 1, 2, 5, 6, 7; план 13 из раздела 9); размеры — `docs/superpowers/specs/2026-10-09-snack-run-scale-terrain-design.md`.

## Global Constraints

- Порт x −60…60, z 125…227; база рельефа −2; набережная — терраса +2 (уровень 0, как парк) z 125…148; причал — терраса +2 x 15…35, z 148…212 (доски); пляж — уровень −2 x −60…10, z 148…195 (песок, дюны ≤ 0,8 м); море — дно −3,5, вода −2,3 (на 0,3 ниже пляжа) z 195…227 и гавань x 10…60, z 148…195.
- Ворота из парка в северном заборе при x −6, порог накопленной сытости 50, надпись «Ворота в порт открыты!».
- Лодки (3): подъём ±0,12 м, крен ±6°, период 3–4 с, разные фазы; бочки (5): верх на 0,3 м выше воды.
- Еда порта: 0 — shrimp «Креветка», fries «Картошка фри»; 1 — squid «Кальмар», fish_sandwich «Рыбный сэндвич»; 2 — sushi «Суши»; 3 — golden_fish «Золотая рыбка» (только из ведра рыбака, план 15; в точках спавна её нет).
- Количество: ≥ 35 точек еды, ≥ 25 клубочков, ≥ 14 укрытий (ящики, перевёрнутая лодка, бочка).
- Набережная: 6 фонарей, киоск, скамейки, урны; пляж: шезлонги, зонты, перевёрнутая лодка.

## Review Focus

1. Кот, упавший с причала, набережной или лодки в воду, возвращается на ближайший берег — на сушу, а не на другой край гавани.
2. Кот стоит на качающейся лодке и не проваливается сквозь неё; прыжок с лодки на лодку и на бочку возможен (верх ≤ 0,8 м разницы).
3. Порт закрыт до сытости 50; из порта нельзя выйти по суше за x ±60.
4. Еда порта не появляется в других районах; золотой рыбки нет в точках спавна.
5. Альбом на 20 карточек читается и не вылезает за экран.

---

### Task 1: Генератор: `terrace` со сторонами, `flat`, `water`
- RED: `test_terrace_walls_only_on_given_sides` (стены только на `sides`, проёмы `gaps`), `test_flat_and_water_ops` (элемент рельефа `flat`; зона воды и маркеры берега в раскладке).
- GREEN: `terrace(rect, height, access=(), sides="nswe", gaps=())`; `flat` → `{"type": "flat", "rect", "height"}`; `water` → `water_zones` + `shore` из `op["shore"]`.

### Task 2: Текстуры песка и досок, каналы рельефа порта
- Манифест: `assets/images/textures/sand.png`, `planks.png` (бесшовные, сверху, палитра: песок #D3AB87/#FCD3A1, доски #D3AB87/#BD4045 тёмные щели #394151). `make images`.
- `Terrain.DEFAULT_TEXTURES`/`DEFAULT_TILES`: `sand` 3 м, `planks` 2 м. RED: `test_port_terrain_channels_use_sand_and_planks`.

### Task 3: Модели порта
- `boat` (корпус 1,6×4,2 м, палуба на 0,45 над водой, борта), `boat_upturned` (перевёрнутая, укрытие), `barrel` (r 0,35, h 0,7), `bollard`, `deckchair`, `buoy`, 6 вкусняшек (`food_shrimp`, `food_fries`, `food_squid`, `food_fish_sandwich`, `food_sushi`, `food_golden_fish`) и иконки в манифесте. `make assets`, `make images`.

### Task 4: Качающиеся опоры `Floater`
- `scripts/world/floater.gd` (AnimatableBody3D, `amp`, `roll_deg`, `period`, `phase`, `sync_to_physics`); статическая `Floater.offset_at(t, amp, roll, period, phase) -> Vector2` (подъём, крен) — юнит-тест.
- RED (GUT): `test_cat_rides_bobbing_boat` — кот на лодке 4 с не падает в воду и поднимается/опускается вместе с ней; `test_floaters_have_different_phases`; `test_builder_builds_floaters`.

### Task 5: Еда порта
- `data/food/{shrimp,fries,squid,fish_sandwich,sushi,golden_fish}.tres`; правка `test_rarity` (20: 6/6/4/4) и `test_menus` (20 карточек). Кадр альбома.

### Task 6: Район «Порт»
- `data/layout_src/port.json` по Global Constraints; ворота парка (x −6, z 125, сытость 50) и проём в северном заборе парка — в `data/layout_src/park.json`; `district_yard.tscn`: `PortTerrain`, `PortBuilder`.
- RED (`test_port.gd`): размеры и уровни; ворота 50 закрыты и открываются; вода и берег на суше (каждый маркер выше воды); 3 лодки и 5 бочек; еда только порта, без золотой рыбки; край по суше закрыт; счётчики. Кадры днём и ночью.

### Task 7: Документация
- `02-procedure.md`, дорожная карта, CLAUDE.md, `make replay`.

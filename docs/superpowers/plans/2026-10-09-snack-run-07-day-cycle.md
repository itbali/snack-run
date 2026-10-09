# Snack Run, план 7: Смена суток

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Цикл 300 с (день 150, вечер 30, ночь 90, утро 30) с плавным светом и небом, фонарями, значком в HUD и правилами:
ночью собака двора не замечает кота, в тёмных точках спавна еда редче-вкуснее.

**Architecture:** Чистый `DayCycle` (RefCounted, static): фаза по времени, ключевые кадры света и их интерполяция, «фонари
включены». Узел `DayNight` (в `lighting.tscn`, группа `day_night`) ведёт время, применяет состояние к солнцу, заполняющему
свету, окружению и небу, переключает группу `night_lights`, шлёт `phase_changed`. Остальные спрашивают
`DayNight.is_night(tree)` (без узла — день). `WorldBuilder` вешает на каждый `lamp` `SpotLight3D` в группе `night_lights`.
`Rarity.NIGHT_WEIGHTS`, `FoodSpawnPoint.pick_def` берёт их ночью. HUD — иконка фазы + полоска до следующей фазы.
`DevTools`: `++ --phase=night` ставит время для скриншота; `make shot PHASE=night`.

**Spec:** `docs/superpowers/specs/2026-10-09-snack-run-stage2-park-design.md`, раздел 2.

## Global Constraints
- Ключевые кадры (t, состояние): (0 день), (150 день), (165 закат), (185 ночь), (270 ночь), (285 рассвет=закат), (300 день).
  День: солнце −65°, `#FFF1D6`, 1,2; заполняющий 0,25; ambient 0,6; небо `#4A9BE0`/`#CFE6F8`; облака белые.
  Закат: −10°, `#FFB36B`, 0,8; заполняющий 0,2; ambient 0,45; небо `#5A6FB0`/`#FFB98A`; облака `#FFD2B0`.
  Ночь: −50°, `#9FB8FF`, 0,25; заполняющий 0,08; ambient 0,25; небо `#0B1633`/`#1E2F5C`; облака `#3A4670`.
- Фазы: день [0,150), вечер [150,180), ночь [180,270), утро [270,300). Фонари горят [165, 285).
- Ночные веса: обычная 40, редкая 30, очень редкая 20, легендарная 10.
- Фонарь: `SpotLight3D` на 2,45 м вниз, угол 50°, дальность 6 м, `#FFD9A0`, энергия 2, без теней.
- Иконки фазы — генератор картинок (`sun.png`, `sunset.png`, `moon.png`).

## Review Focus
1. Пауза останавливает цикл (узел `INHERIT`).
2. Без узла `DayNight` (тесты, отдельные сцены) всё работает как днём.
3. После ночи собака снова замечает кота днём.
4. Переход через 300 → 0 непрерывен (свет не прыгает).

### Task 1: DayCycle и DayNight, фонари, правила, HUD
- [ ] RED: `tests/unit/test_day_cycle.gd` (фазы, ключевые кадры, интерполяция, обёртка 300→0, фонари),
  `tests/integration/test_day_night.gd` (свет днём/ночью, фонари, пауза, собака ночью не видит, днём снова видит, HUD-иконка),
  `tests/unit/test_rarity.gd` (+ночные веса).
- [ ] GREEN: `scripts/world/day_cycle.gd`, `scripts/world/day_night.gd`, `lighting.tscn` (+узел), `world_builder.gd` (фонари),
  `rarity.gd`/`food_spawn_point.gd`, `dog.gd`, `hud.gd`/`hud.tscn`, `dev_tools.gd`, `Makefile`; иконки по манифесту.
- [ ] Кадры днём, на закате и ночью, коммит.

### Task 2: Документация (`02-procedure.md`, `make replay`, дорожная карта, `CLAUDE.md`).

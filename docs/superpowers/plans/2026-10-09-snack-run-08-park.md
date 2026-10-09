# Snack Run, план 8: Район «Парк»

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Парк 30×30 м за кафе (z 30…60): газон и гравийные дорожки с текстурами, фонтан, детская площадка, аллея
скамеек с фонарями, киоск, сторожка, забор; ворота из кафе при сытости 25; 6 новых вкусняшек; укрытия куст / скамейка /
домик горки; 12 клубочков. Опасности — план 9.

**Architecture:** Второй `WorldBuilder` (`ParkBuilder`) в `district_yard.tscn` строит `data/layout/park.json`; пол парка —
модель `park_ground.glb` (меши `lawn`, `path`) и коллайдер `ParkFloor`; `SurfaceTextures` получает `lawn`→`grass.png` (2 м),
`path`→`gravel.png` (0,8 м). Новые пропсы — Blender-скрипты. Ворота — `gates` в `park.json` с `satiety: 25` и `label`.
`GameState.PARK_GATE = 25`; HUD показывает ближайшую цель сытости (кафе 10 → парк 25).

**Spec:** `docs/superpowers/specs/2026-10-09-snack-run-stage2-park-design.md`, разделы 4–5.

## Global Constraints
- Пропс ≤ 800 треугольников (фонтан, горка, сторожка ≤ 1500), палитра `palette.py`, модели только скриптами.
- Еда парка: попкорн, бублик (обычные), сэндвич, кукуруза (редкие), сахарная вата (очень редкая), капкейк (легендарная).
- Укрытие «куст» — куст без коллизии (`solid: false`) + `hideouts` в той же точке.
- Инварианты раскладки как у двора (спавны/клубочки/укрытия не внутри пропсов, приподнятые стоят на чём-то, 10–15 клубочков).

## Review Focus
1. Ворота парка закрыты при сытости 10–24 и открываются ровно на 25; ворота кафе при этом открыты.
2. Кот не выпадает за край парка (забор по периметру, пол под всем парком).
3. Иконки и модели всех 14 вкусняшек существуют (манифест, `FoodDef.model_path`).
4. HUD сытости после 10 показывает цель парка, после 25 — «Парк открыт».

### Task 1: Пол, текстуры, пропсы парка (Blender), раскладка, ворота, еда, укрытия, HUD-цель
- [ ] RED: `tests/integration/test_park.gd` (раскладка грузится, инварианты, ворота 25, пол парка, текстуры газона/гравия,
  забор по периметру); `test_images.gd` уже требует иконки всей еды; `test_hud.gd` (цель сытости 10 → 25).
- [ ] GREEN: `gen/{park_ground,fountain,slide,swings,sandbox,kiosk,shed,flowerbed}.py`, `gen/food_{popcorn,bagel,sandwich,corn,cotton_candy,cupcake}.py`,
  `data/food/*.tres` (6), `data/layout/park.json`, `district_yard.tscn` (+ParkBuilder, ParkFloor), `SurfaceTextures`,
  `GameState.PARK_GATE`, `Gate.label`, `hud.gd`, `main.gd` (сообщение ворот).
- [ ] Кадр парка днём (`make shot` с позицией кота в парке — флаг `--at=x,y,z` в DevTools), коммит.

### Task 2: Документация.

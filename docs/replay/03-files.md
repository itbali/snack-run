# Приложение: содержимое всех файлов проекта

Сгенерировано `make replay` из текущего дерева. Не редактировать руками.
Для каждого файла: путь относительно корня проекта и полное содержимое.
Отступы в GDScript и Makefile — табы; в Python проекта — тоже табы, кроме
`palette.py` и тестов Blender (пробелы). Копировать как есть.

Файлов: 300

## `CLAUDE.md`

````markdown
# Snack Run — памятка для Claude (и для человека) без памяти о прошлых сессиях

3D-игра про котёнка, который собирает вкусняшки и избегает городских опасностей.
Делается для ролика на YouTube-канале «Нейрослоп» (показ вайб-кодинга 3D с Blender и Godot).
Все тексты, комментарии, коммиты — по-русски; идентификаторы кода — по-английски.
Коммиты заканчиваются строкой `Co-Authored-By: <модель, которая работает в сессии> <noreply@anthropic.com>` (планы 1–5 — Claude Fable 5.1, с 2026-10-09 — Claude Opus 5.5).

## Инструкция для воспроизведения с нуля

`docs/replay/` — полная инструкция, по которой другой агент повторяет проект с трёх картинок:
`README.md` → `01-decisions.md` → `02-procedure.md` → `03-files.md` (приложение со всеми файлами,
генерируется `make replay`). **Каждая сессия, меняющая проект, дописывает свои шаги в
`02-procedure.md` и запускает `make replay` перед коммитом.**

## Документы (читать в этом порядке)

1. `docs/superpowers/specs/2026-10-07-snack-run-design.md` — спек: визуальная библия + игровой цикл. **Спек — источник истины**, план лишь аргумент от него.
2. `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md` — дорожная карта из 4 планов и их статус.
3. `docs/superpowers/plans/2026-10-07-snack-run-01-foundation.md` … `2026-10-09-snack-run-05-visual.md` — планы 1–5 (все выполнены). Образец формата для следующих.
4. `docs/superpowers/notes/2026-10-07-unimate-attempt.md` — как заработал UniMate на Mac и все найденные грабли.
5. `reference/*.png` — три концепт-арта (ключевой кадр, карта мира, артборд ассетов).

## Правила владельца проекта

- Движок Godot 4.7.2, 3D-ассеты генерируются Python-скриптами в Blender 5.2.2 (не руками в GUI). 2D-картинки (иконки, арты, декали) — только через `tools/images/gen.py` по манифесту (OpenAI `gpt-image-2.5`, ключ из `OPENAI_API_KEY`), решение владельца №18.
- Анимации **не делать самому**: сначала готовые бесплатные паки (CC0/CC-BY), потом UniMate, и только если ничего нет — генерация скриптом. **Платные ассеты запрещены.**
- Стиль: стилизованный лоуполи + тун-свет + обводка; цвета только из палитры спека 2.2 (`tools/blender/palette.py`).
- Этапность: сначала вертикальный срез района «двор + кафе», остальное потом.

## Процедура разработки (повторять для каждого плана)

Используются навыки superpowers. Порядок, который сработал для плана 1:

1. **Спек уже есть.** Для нового этапа (план 2, 3, 4) сначала `superpowers:writing-plans`: подробный план с кодом каждого шага, задачами по 2–5 минут, тестом-первым. Самопроверка плана: покрытие спека, плейсхолдеры, согласованность имён между задачами, Review Focus. Показать план владельцу, получить «да» и выбор способа исполнения.
2. **Исполнение** `superpowers:executing-plans` (владелец выбирал «сам в этой сессии»): ветка `plan-N-<имя>` от `main`, журнал (ledger) в `.superpowers/sdd/<план>/progress.md`, по каждой задаче: RED-тест → GREEN → коммит → `task-done`. Каждое отклонение от плана — строка `Ruling:` в журнале с причиной и ценой.
3. **Финальное ревью** свежим субагентом (модель `fable`) по шаблону `requesting-code-review/code-reviewer.md` с пакетом `review-package`. Critical/Important чинить одним проходом строго через падающий тест; Minor — в журнал как отложенные.
4. **Завершение** `superpowers:finishing-a-development-branch`: полный `make test`, слияние в `main` (владелец выбирал локальный merge), удаление ветки, удаление workspace плана.
5. В финальном сообщении владельцу: все `Ruling:` с ценой, все отложенные минорные, что проверить руками.

## Команды

```
make test          # test-tools (Python) + Blender-тесты + GUT; делает import сам
make terrain       # data/terrain_src/*.json → data/terrain/*.json (tools/terrain/terrain_gen.py)
make layout        # data/layout_src/*.json → data/layout/*.json + рельеф (tools/layout/layout_gen.py), затем terrain
make test-godot    # только GUT (сначала import); падает и на SCRIPT ERROR
make test-blender  # только Blender
make assets        # пересобрать все glb из tools/blender/gen/*.py в assets/models/
make assets ONLY=cat
make shot SHOT=build/x.png   # скриншот главной сцены из CLI (ждёт 40 кадров)
make run           # запустить игру (WASD, мышь/Q/R камера, Shift бег, Space прыжок, Ctrl прятаться, E есть/магазин, Tab альбом, Esc пауза)
make sfx           # пересинтезировать meow.wav/bark.wav (tools/audio/gen_sfx.py)
make images        # сгенерировать недостающие картинки по tools/images/manifest.json (нужен OPENAI_API_KEY); FORCE=1 — все
make templates     # один раз: шаблоны экспорта 4.7.2 (1,28 ГБ) в ~/Library/Application Support/Godot/export_templates
make export        # build/SnackRun.zip с «Snack Run.app» (macOS universal, ad-hoc подпись) по export_presets.cfg; нужна настройка import_etc2_astc
```
Одиночный прогон GUT: `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gselect=test_theme`.
Пути инструментов: `/Applications/Godot.app/Contents/MacOS/Godot`, `/Applications/Blender.app/Contents/MacOS/Blender`.
Просмотр glb: `blender -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb`.
Инспекция рига: `blender -b <file.blend> --python tools/blender/rig_inspect.py`.

## Структура

- `scenes/main.tscn` + `scripts/main.gd` — собирает свет, двор, кота, камеру.
- `scripts/player/cat_motion.gd` — чистая логика (static, без узлов) → тесты в `tests/unit/`.
- `scripts/player/cat.gd` (CharacterBody3D: idle/walk/run/jump/hide/hit, `take_hit`, `try_hide`, `try_eat`, `teleport`, `set_fade`, `threaten/cheer`, `squash/flash`), `cat_face.gd` (выражения глаз по мешам `eyes_*`, моргание), `camera_rig.gd` (`crouch`, `shop_view`, мышь, прозрачность кота, `shake`), модификаторы скелета `head_scaler.gd`, `leg_scaler.gd`, `tail_wiggle.gd`.
- `scripts/autoload/game_state.gd` — сердечки, зубы (3), сытость, альбом, цель сессии; сигналы `cat_hit`, `cat_fainted` и др. В тестах `GameState.reset()` в `before_each`.
- `scripts/core/` (`Layers`, `Rarity`), `scripts/food/` (`FoodDef`, `FoodCatalog`, `FoodPickup`, `FoodSpawnPoint`), `data/food/*.tres`.
- `scripts/hideouts/hideout.gd`, `scripts/world/world_builder.gd` (двор из `data/layout/yard.json`), `scripts/world/spill_spawner.gd`.
- `scripts/hazards/`: `perception.gd`, `chase_brain.gd` (чистые), `hazard_base.gd`, `dog.gd`, `wasp.gd`, `cyclist.gd`; парк: `sprinkler.gd`, `pigeon_flock.gd`, `park_person.gd` → `gardener.gd`, `kid.gd`, `guard.gd`; порт: `gull.gd`, `wave.gd`, `forklift.gd`, `crab.gd` (`third_party/crab_methodicalpixel/`); модели людей `tools/blender/human.py`, голубя `pigeon.py`.
- `scripts/ui/hud.gd` + `scenes/ui/hud.tscn`; экраны `shop_menu.gd`, `album_menu.gd`, `pause_menu.gd`, `title.gd` (главная сцена `scenes/ui/title.tscn`), `menu_input.gd` (опрос клавиш меню, работает на паузе).
- `scripts/core/shop_item.gd`, `shop_catalog.gd`, `cat_skin.gd`, `skin_catalog.gd`; данные `data/shop/*.tres`, `data/skins/*.tres`.
- `scripts/autoload/save_game.gd` — JSON в `user://save.json`, пишет только по `save_now()` из `Main`; в тестах с `Main` путь переопределяется.
- `scripts/world/gate.gd` (ворота по сытости), `scripts/world/yarn_shop.gd` (будка: безопасная зона, возрождение, витрина), `scripts/food/yarn_pickup.gd`.
- `scripts/visual/toon.gd` — `Toon.apply(root, width_m, character)`; ширина в метрах, пересчитывается под масштаб узла; обводка — `assets/shaders/outline_fur.gdshader`, у персонажей rim и шум. `scripts/visual/effects.gd` — `Effects.burst/dust/hearts/sparkles/trail/zzz/leaves` (частицы; одноразовые удаляются по таймеру).
- `scripts/autoload/sfx.gd` — звуки (`Sfx.play(&"eat")`, один вызов на событие), файлы и лицензии в `assets/sfx/README.md`; `assets/ui/theme.tres` (Nunito, плашки), `assets/shaders/vignette.gdshader`; `scripts/core/mouse.gd` (`Mouse.capture`, в headless no-op).
- `scripts/autoload/input_setup.gd` (InputMap в коде), `dev_tools.gd` (`++ --screenshot=path`).
- `tools/blender/`: `palette.py`, `lib.py` (rounded_box, world_extent, tri_count, check_asset), `export.py`, `build.py`, `cat.py` (сварка + subdivision) + `cat_eyes.py` (глаза) + `cat_fluff.py` (пучки, усы, ошейник), `dog.py` + `dog_sleep.py` (поза «спит»), `gen/*.py` (каждый: `SPEC` + `build()`); `tools/audio/gen_sfx.py`; `tools/images/gen.py` + `manifest.json`; `export_presets.cfg`.
- `scripts/world/terrain.gd` (`Terrain`: меш тайлами, `HeightMapShape3D` «Floor», шейдер `terrain.gdshader` со сплатом, `height_at`); `WorldBuilder.terrain_path` — раскладка привязывается к высоте (`"snap": false` — абсолютно); набор террас `tools/blender/terrace_kit.py`; демо `scenes/dev/terrain_demo.tscn`.
- `scripts/world/floater.gd` (`Floater`: лодки и бочки качаются, раскладка `floaters`); порт — `PortTerrain` + `PortBuilder` в `district_yard.tscn`, `data/layout_src/port.json`.
- `scripts/world/water.gd` (`Water`: зона воды и поверхность-шейдер; кот `drown()` → ближайший маркер группы `shore`).
- `tools/layout/layout_gen.py` — генератор раскладки: описание района `data/layout_src/<район>.json` (ядро `*_core.json` + зоны) → `data/layout/<район>.json` и `data/terrain_src/<район>.json`; двор правится только через описание.
- `scripts/visual/surface_textures.gd` — текстуры крупных поверхностей по имени меша (`wall` и др.; пол — каналы рельефа), трипланар по мировым координатам (спек 2.9).
- `scripts/world/day_cycle.gd` (чистая логика суток) + `day_night.gd` (узел в `lighting.tscn`, группа `day_night`; `DayNight.is_night(tree)`, без узла — день); группы `night_lights`, `night_windows`.
- `scenes/world/lighting.tscn` — солнце, заполняющий свет, окружение (SSAO, SSR, glow, облака `sky_cover`), листья; `WorldBuilder` читает `solid`, `water`, `decals` из `yard.json`.
- `third_party/quaternius_animal_pack_v2/` (CC0 кот и собака), `third_party/quaternius_animated_human/` (CC0 люди парка), `third_party/pigeon_mujtaba/` (CC0 голубь), `third_party/unimate_clips/` (канонический риг + клипы jump/hide/hit/run + README с воспроизведением).
- `tests/unit`, `tests/integration` (GUT 9.7.1 в `addons/gut`, вендор), `tools/blender/tests/`.

## Грабли, на которые уже наступали (не повторять)

**Godot 4.7**
- Новый `class_name` не виден тестам, пока не выполнен `make import` (кэш классов).
- GUT возвращает код 0 при ошибке парсинга скрипта; Makefile грепает `SCRIPT ERROR` в `build/gut.log`.
- `--headless` рендера не даёт; скриншоты — обычный запуск с `++ --screenshot=путь` и `get_viewport().get_texture().get_image()` после кадров.
- `.blend`-файлы в проекте Godot пытается импортировать и требует путь к Blender, при этом glb молча не импортируется → в папках с `.blend` лежит `.gdignore`.
- Импортированные из glb клипы приходят с `loop_mode = 0`; лупы для idle/walk/run/hide ставятся в `cat.gd._ready()`.
- `SkeletonModifier3D`: после модификаторов Skeleton3D восстанавливает базовую позу, итог читается только в сигнале `skeleton_updated` через `get_bone_global_pose`.
- У скинового меша `get_aabb()` уже в метрах; умножать на `global_transform` (масштаб скелета 0,2) нельзя. Размер кота в тестах меряется по костям.
- `material_overlay` + `grow` работает в пространстве модели: для кота под `CatRig` (масштаб 0,2067) ширину делить на масштаб.
- В тестах `var x := func()` без аннотации типа у функции — ошибка парсинга; писать `var x = ...` или `-> Node`.
- `test-godot`, `shot`, `run` зависят от `import`; `*.import` и `*.uid` коммитятся.
- Тонмаппинг Filmic выцветает палитру — используется линейный.

**Blender 5.2**
- `Action.fcurves` нет: каналы в `action.layers[].strips[].channelbags[].fcurves`.
- Импортёр glTF ставит объектам `rotation_mode = QUATERNION`: перед правкой `rotation_euler` ставить `XYZ`.
- Импортёр glTF добавляет объект `Icosphere` (форма костей) — удалять перед экспортом.
- Экспортёр glTF в режиме `ACTIONS` терял активный action арматуры → перед экспортом `animation_data.action = None`, всем actions `use_fake_user = True`.
- `bpy.ops.object.select_all` в фоне не сбрасывал выделение из открытого файла → сброс перебором `view_layer.objects`.
- `obj.dimensions` нулевые до `view_layer.update()`; учитывают только собственный масштаб, не родителя → `lib.world_extent`.
- Blender возвращает код 0 при исключении в скрипте без `--python-exit-code 1` (стоит в Makefile).
- Принципиальный узел искать по `node.type == "BSDF_PRINCIPLED"`, не по имени.
- Масштаб арматуры не применять (`transform_apply` ломает location-каналы анимаций); экспортёр пишет масштаб узла.

**Риг кота (Quaternius Cat.blend)**
- Кости без имён: `Bone` таз, `Bone.001` спина, `Bone.002` шея, `Bone.003` голова (→ `head`), `Bone.004–007` хвост, `Bone.014–016` правая передняя, `Bone.017–019` левая передняя, `Bone.008–010` левая задняя, `Bone.011–013` правая задняя, `IK*` контроллеры (в каноническом риге удалены).
- Модель смотрит по +X Blender; в `cat.py` разворот считается по вектору таз→голова (`face_forward`), результат печатается при сборке.

**План 2:** GUT считает ошибки движка провалом (`failure_error_types` без `engine` в `.gutconfig.json`); поля чужих узлов через `set/get/call`; `home`/`anchor` опасностей на первом физическом кадре; объектные каналы в actions Blender выкидывать (`rig_utils.clean_action`); меш с поворотом относительно арматуры запекать в вершины; в тестах с котом нужен пол.

**План 3:** ожидания GUT стоят на паузе дерева → в тестах паузы `get_tree().create_timer(t, true)`; `Input.action_press` не создаёт событий → меню опрашивать `is_action_just_pressed` из узла с `PROCESS_MODE_ALWAYS`; `Main` оставлять `INHERIT`; `JSON.parse_string` печатает ERROR движка (использовать `JSON.new().parse()`); `Color` из `.tres` сравнивать через `to_html()`.

**План 4:** одиночный прогон GUT — `-gselect=`, не `-gtest=`; пары Area3D фиксируются по позициям в момент `add_child` (в тестах `position` ставить **до** `add_child`, иначе кот в точке собаки ловит удар на первом кадре); скрипт `-s` (SceneTree) без автозагрузок — `cat.tscn` там не компилируется, рендерить `cat.glb`; в `_init()` такого скрипта `global_position`/`look_at` не применяются — задавать `transform`; в Blender при записи клипа позу ставить при снятом action (иначе `view_layer.update()` возвращает уже записанные кадры); `GameState.reset()` рядом с `Main` тут же автосохраняется — файл стирать после сброса или выключать `autosave`; эмоции — меши на кости головы (материалы не из ролей скина, обводку с глаз снимать).

**Этап 2:** не называть статические функции именами встроенных (`wrap`, `clamp`, `lerp`…) — вызов `Класс.wrap()` падает; кадры фаз и мест: `make shot PHASE=night AT=0,0.1,33,180`; парк строит второй `WorldBuilder` (`ParkBuilder`, `data/layout/park.json`).

**Шрифт и окно:** Nunito вариативный — только через `assets/ui/nunito_bold.tres` (`wght 700`), без веса это ExtraLight; в Nunito нет ♥ ♡ ◎ ✓ — в UI иконки или слова; окно развёрнуто, `stretch canvas_items/expand` (Retina, масштаб 2).

**План 5:** **ось Y скелета кота идёт вдоль тела, верх — +Z скелета** (модификаторы берут верх из `skel.global_transform.basis.inverse() * Vector3.UP`, тесты модификаторов меряют мировые координаты); у мешей из Blender-скриптов нет UV — шейдеры берут шум по `VERTEX_ID`; импортированный glb-меш перед subdivision сваривать (`remove_doubles`), иначе мозаика; subdivision на триангулированном меше ×6; `CPUParticles3D`, созданные в физическом шаге, получают `finished` сразу — эмиссию включать после `add_child`, удалять по таймеру; `ambient_light_source`: 1 = DISABLED, 3 = SKY; внешний `velocity.y` у кота гасится шагом на полу (в тестах прыгать через `Input.action_press("jump")`); с нетипизированным `main` в тестах писать `var x: Тип = main.f()`; `yard.json` многострочный — правки скриптом по строкам; служебный рендер `-s` к `cat.glb` добавляет модификаторы скелета вручную; веки над утопленными глазами читаются как брови — не делать.

**UniMate на Mac** (подробно в заметке): venv Python 3.10 через `uv`, requirements без `+cu124`, `sampling.device = cpu` в `config.json` чекпоинта (MPS не умеет float64), ручная `annotation.json` (авторазметка путает спину и хвост), шим `blender` → venv-python с pip-`bpy` для `run_animate_motion.sh`. Окружение жило в scratchpad и не сохранилось; чекпоинт 1,2 ГБ качается с HF заново.

**План 10:** тела раскладки ставить в позицию до `add_child` (`WorldBuilder._add_at`), иначе на первом кадре они в начале координат и выталкивают кота сквозь heightmap; пол районов — `Terrain`, в тестах с парком/двором без `Main` рельеф создавать самому.

**План 11:** ящик 0,3 м (стопки через 0,3); россыпь генератора идёт после структуры всех зон; в описании покрытие — ключ `surface` (ключ `type` у операции); точкам еды всегда давать `foods` района, иначе выпадает еда парка.

**План 12:** у `perimeter` сторона «n» — меньший z, «s» — больший; парк правится только через `data/layout_src/park.json` + `make layout`.

**План 13:** высота террасы в `terrain_gen` абсолютная (в генераторе раскладки — `level`); имена одинаковых узлов давать с номером; кадр альбома — `++ --album`.

**План 14:** отладочные ключи (`--screenshot/--at/--phase/--album`) включают `SaveGame.read_only` — кадры не трогают сохранение; маленькие опасности (краб) без слоя столкновений; у Area3D проверять `get_overlapping_bodies` при старте движения.

## Статус и что дальше

- Планы 10 «Рельеф», 11 «Двор ×3», 12 «Парк ×3, вода», 13 «Порт» и 14 «Опасности порта» выполнены 2026-10-09 (спек `2026-10-09-snack-run-scale-terrain-design.md`). Дальше план 15 (рыбалка); владелец: делать подряд, не ждать его оценки.
- Планы 1–9 выполнены и слиты в `main`: фундамент, игровой цикл, хаб и прогрессия, полировка, визуальная полировка, текстуры крупных поверхностей, этап 2 (сутки, парк, опасности парка). Отложенные мелочи — в дорожной карте.
- Отложено по просьбе владельца: текстуры пропсов («потом вернёмся к текстурам»).
- Открытый вопрос владельцу: лицензия весов UniMate для сгенерированных движений (код MIT, для весов явной лицензии не найдено).
````

## `Makefile`

```makefile
SHELL   := /bin/bash
GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png
PHASE   ?=
AT      ?=
TEMPLATES_DIR := $(HOME)/Library/Application Support/Godot/export_templates/4.7.2.stable

.PHONY: import test test-godot test-blender test-tools terrain layout assets shot run replay sfx templates export images

import:
	$(GODOT) --headless --path . --import

test: test-tools test-blender test-godot

test-tools:
	set -o pipefail; python3 -m unittest discover -s tools/terrain/tests -p "test_*.py" 2>&1 | tail -3
	set -o pipefail; python3 -m unittest discover -s tools/layout/tests -p "test_*.py" 2>&1 | tail -3

layout:
	for f in data/layout_src/*.json; do case $$f in *_core.json) ;; *) python3 tools/layout/layout_gen.py $$f || exit 1;; esac; done
	$(MAKE) terrain

terrain:
	python3 tools/terrain/terrain_gen.py

test-godot: import
	mkdir -p build
	set -o pipefail; $(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee build/gut.log
	@! grep -q "SCRIPT ERROR" build/gut.log || (echo "Ошибки скриптов в тестах, см. build/gut.log"; exit 1)
	@! (grep -E "^ERROR:" build/gut.log | grep -v 'Parameter "material" is null' | grep -q .) || (echo "Ошибки движка в тестах (кроме известного шума dummy-рендерера), см. build/gut.log"; exit 1)

test-blender:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/build.py -- $(ONLY)

shot: import
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 res://scenes/main.tscn ++ $(if $(PHASE),--phase=$(PHASE),) $(if $(AT),--at=$(AT),) --screenshot=$(SHOT)

run: import
	$(GODOT) --path .

replay:
	python3 tools/replay/build_files_md.py

sfx:
	python3 tools/audio/gen_sfx.py

images:
	python3 tools/images/gen.py $(if $(FORCE),--force,)

templates:
	mkdir -p "$(TEMPLATES_DIR)" build
	[ -f build/templates.tpz ] || tools/release/fetch_templates.sh
	unzip -o -j build/templates.tpz 'templates/macos.zip' 'templates/version.txt' -d "$(TEMPLATES_DIR)"
	ls -la "$(TEMPLATES_DIR)"

export: import
	mkdir -p build
	$(GODOT) --headless --path . --export-release "macOS" build/SnackRun.zip
	ls -la build/SnackRun.zip && unzip -l build/SnackRun.zip | head -5
```

## `project.godot`

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Snack Run"
run/main_scene="res://scenes/ui/title.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")

[autoload]

InputSetup="*res://scripts/autoload/input_setup.gd"
DevTools="*res://scripts/autoload/dev_tools.gd"
GameState="*res://scripts/autoload/game_state.gd"
SaveGame="*res://scripts/autoload/save_game.gd"
Sfx="*res://scripts/autoload/sfx.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/size/mode=2
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[gui]

theme/custom="res://assets/ui/theme.tres"

[rendering]

renderer/rendering_method="forward_plus"
textures/vram_compression/import_etc2_astc=true
```

## `.gutconfig.json`

```json
{
  "dirs": [
    "res://tests/"
  ],
  "include_subdirs": true,
  "should_exit": true,
  "log_level": 1,
  "prefix": "test_",
  "failure_error_types": [
    "gut",
    "push_error"
  ]
}
```

## `.gitignore`

```
# Godot
.godot/
# Blender
*.blend1
*.blend2
__pycache__/
# OS
.DS_Store
# build
build/
export/
```

## `scenes/dev/terrain_demo.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/dev/terrain_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/world/lighting.tscn" id="2"]
[ext_resource type="Script" path="res://scripts/world/terrain.gd" id="3"]
[ext_resource type="Script" path="res://scripts/world/world_builder.gd" id="4"]

[node name="TerrainDemo" type="Node3D"]
script = ExtResource("1")

[node name="Lighting" parent="." instance=ExtResource("2")]

[node name="Terrain" type="Node3D" parent="."]
script = ExtResource("3")
data_path = "res://data/terrain/demo.json"

[node name="Builder" type="Node3D" parent="."]
script = ExtResource("4")
layout_path = "res://data/layout/terrain_demo.json"
terrain_path = NodePath("../Terrain")
```

## `scenes/food/food_pickup.tscn`

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

## `scenes/food/food_spawn_point.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/food/food_spawn_point.gd" id="1"]

[node name="FoodSpawnPoint" type="Node3D"]
script = ExtResource("1")
```

## `scenes/food/yarn_pickup.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/food/yarn_pickup.gd" id="1"]

[sub_resource type="SphereShape3D" id="shape"]
radius = 0.25

[node name="YarnPickup" type="Area3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
shape = SubResource("shape")

[node name="Visual" type="Node3D" parent="."]
```

## `scenes/hazards/crab.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/crab.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/crab.glb" id="2"]
[ext_resource type="PackedScene" path="res://assets/models/burrow.glb" id="3"]

[sub_resource type="SphereShape3D" id="body"]
radius = 0.15

[sub_resource type="BoxShape3D" id="hit"]
size = Vector3(0.5, 0.4, 0.5)

[node name="Crab" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)
shape = SubResource("body")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="Burrow" parent="." instance=ExtResource("3")]
top_level = true

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, 0)
shape = SubResource("hit")
```

## `scenes/hazards/cyclist.tscn`

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

## `scenes/hazards/dog.tscn`

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

## `scenes/hazards/forklift.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/forklift.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/forklift.glb" id="2"]

[sub_resource type="BoxShape3D" id="hit"]
size = Vector3(1.3, 1.2, 3.0)

[node name="Forklift" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0.2)
shape = SubResource("hit")
```

## `scenes/hazards/gardener.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/gardener.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/gardener.glb" id="2"]

[sub_resource type="CapsuleShape3D" id="body"]
radius = 0.22
height = 1.7

[sub_resource type="SphereShape3D" id="hit"]
radius = 0.4

[node name="Gardener" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
shape = SubResource("body")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
shape = SubResource("hit")
```

## `scenes/hazards/guard.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/guard.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/guard.glb" id="2"]

[sub_resource type="CapsuleShape3D" id="body"]
radius = 0.22
height = 1.7

[sub_resource type="SphereShape3D" id="hit"]
radius = 0.4

[node name="Guard" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
shape = SubResource("body")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
shape = SubResource("hit")
```

## `scenes/hazards/gull.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/gull.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/gull.glb" id="2"]

[sub_resource type="CylinderMesh" id="shadow"]
top_radius = 0.5
bottom_radius = 0.5
height = 0.02
radial_segments = 16

[sub_resource type="StandardMaterial3D" id="shadow_mat"]
transparency = 1
shading_mode = 0
albedo_color = Color(0.22, 0.25, 0.32, 0.55)

[node name="Gull" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="Shadow" type="MeshInstance3D" parent="."]
top_level = true
visible = false
mesh = SubResource("shadow")
surface_material_override/0 = SubResource("shadow_mat")
```

## `scenes/hazards/kid.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/kid.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/kid.glb" id="2"]

[sub_resource type="CapsuleShape3D" id="body"]
radius = 0.22
height = 1.1

[sub_resource type="SphereShape3D" id="hit"]
radius = 0.4

[node name="Kid" type="CharacterBody3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)
shape = SubResource("body")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)
shape = SubResource("hit")
```

## `scenes/hazards/pigeon_flock.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/pigeon_flock.gd" id="1"]

[node name="PigeonFlock" type="Node3D"]
script = ExtResource("1")
```

## `scenes/hazards/sprinkler.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/sprinkler.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/sprinkler.glb" id="2"]

[sub_resource type="CylinderShape3D" id="zone"]
height = 1.2
radius = 2.0

[node name="Sprinkler" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="Zone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="Zone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)
shape = SubResource("zone")
```

## `scenes/hazards/wasp.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/wasp.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/wasp.glb" id="2"]

[sub_resource type="SphereShape3D" id="hit"]
radius = 0.35

[node name="Wasp" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="HitZone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="HitZone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.25, 0)
shape = SubResource("hit")
```

## `scenes/hazards/wave.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hazards/wave.gd" id="1"]

[node name="Wave" type="Node3D"]
script = ExtResource("1")
```

## `scenes/hideouts/hideout.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/hideouts/hideout.gd" id="1"]

[node name="Hideout" type="Area3D"]
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]
```

## `scenes/main.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/world/lighting.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/world/district_yard.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/shop_menu.tscn" id="5"]
[ext_resource type="PackedScene" path="res://scenes/ui/album_menu.tscn" id="6"]
[ext_resource type="PackedScene" path="res://scenes/ui/pause_menu.tscn" id="7"]
[ext_resource type="Script" path="res://scripts/ui/menu_input.gd" id="8"]
[ext_resource type="Shader" path="res://assets/shaders/vignette.gdshader" id="9"]

[sub_resource type="ShaderMaterial" id="vignette_mat"]
shader = ExtResource("9")

[node name="Main" type="Node3D"]
script = ExtResource("1")

[node name="Lighting" parent="." instance=ExtResource("2")]

[node name="DistrictYard" parent="." instance=ExtResource("3")]

[node name="Hud" parent="." instance=ExtResource("4")]

[node name="ShopMenu" parent="." instance=ExtResource("5")]

[node name="AlbumMenu" parent="." instance=ExtResource("6")]

[node name="PauseMenu" parent="." instance=ExtResource("7")]

[node name="MenuInput" type="Node" parent="."]
script = ExtResource("8")

[node name="Vignette" type="CanvasLayer" parent="."]
layer = 0

[node name="Rect" type="ColorRect" parent="Vignette"]
material = SubResource("vignette_mat")
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(1, 1, 1, 1)
```

## `scenes/player/camera_rig.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/player/camera_rig.gd" id="1"]

[node name="CameraRig" type="Node3D"]
script = ExtResource("1")

[node name="SpringArm3D" type="SpringArm3D" parent="."]
spring_length = 1.8
margin = 0.1

[node name="Camera3D" type="Camera3D" parent="SpringArm3D"]
fov = 60.0
```

## `scenes/player/cat.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/player/cat.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/cat.glb" id="2"]

[sub_resource type="SphereShape3D" id="shape"]
radius = 0.09

[node name="Cat" type="CharacterBody3D"]
script = ExtResource("1")
floor_max_angle = 0.6981317

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.09, 0)
shape = SubResource("shape")

[node name="Model" parent="." instance=ExtResource("2")]
```

## `scenes/ui/album_menu.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/album_menu.gd" id="1"]

[node name="AlbumMenu" type="CanvasLayer"]
layer = 21
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -340.0
offset_top = -230.0
offset_right = 340.0
offset_bottom = 230.0
grow_horizontal = 2
grow_vertical = 2

[node name="Margin" type="MarginContainer" parent="Panel"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="VBox" type="VBoxContainer" parent="Panel/Margin"]
layout_mode = 2

[node name="Title" type="Label" parent="Panel/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 26
text = "Альбом вкусняшек"

[node name="Grid" type="GridContainer" parent="Panel/Margin/VBox"]
layout_mode = 2
columns = 5

[node name="Close" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Закрыть (Tab)"
```

## `scenes/ui/hud.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]

[node name="Hud" type="CanvasLayer"]
script = ExtResource("1")

[node name="Status" type="PanelContainer" parent="."]
offset_left = 20.0
offset_top = 16.0
offset_right = 300.0
offset_bottom = 140.0

[node name="VBox" type="VBoxContainer" parent="Status"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="Hearts" type="HBoxContainer" parent="Status/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_constants/separation = 4

[node name="SatietyRow" type="HBoxContainer" parent="Status/VBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="Satiety" type="ProgressBar" parent="Status/VBox/SatietyRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(110, 16)
layout_mode = 2
size_flags_vertical = 4
max_value = 10.0
show_percentage = false

[node name="SatietyLabel" type="Label" parent="Status/VBox/SatietyRow"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 16
text = "Сытость 0/10"

[node name="YarnRow" type="HBoxContainer" parent="Status/VBox"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="YarnIcon" type="TextureRect" parent="Status/VBox/YarnRow"]
unique_name_in_owner = true
custom_minimum_size = Vector2(30, 30)
layout_mode = 2
expand_mode = 1
stretch_mode = 5

[node name="Yarn" type="Label" parent="Status/VBox/YarnRow"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "0"

[node name="Mouth" type="HBoxContainer" parent="."]
unique_name_in_owner = true
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -560.0
offset_top = 16.0
offset_right = -20.0
offset_bottom = 60.0
grow_horizontal = 0
alignment = 2
theme_override_constants/separation = 8

[node name="GoalPanel" type="PanelContainer" parent="."]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = -64.0
offset_right = 520.0
offset_bottom = -16.0
grow_vertical = 0

[node name="Goal" type="Label" parent="GoalPanel"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Открой новых карточек: 0/3"

[node name="BellPanel" type="PanelContainer" parent="."]
unique_name_in_owner = true
visible = false
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -230.0
offset_top = 24.0
offset_right = 230.0
offset_bottom = 72.0
grow_horizontal = 2

[node name="Bell" type="Label" parent="BellPanel"]
unique_name_in_owner = true
layout_mode = 2
horizontal_alignment = 1
theme_override_font_sizes/font_size = 26
text = "🔔 Велосипед!"

[node name="PhasePanel" type="PanelContainer" parent="."]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -150.0
offset_top = 96.0
offset_right = -20.0
offset_bottom = 156.0
grow_horizontal = 0

[node name="Row" type="HBoxContainer" parent="PhasePanel"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="PhaseIcon" type="TextureRect" parent="PhasePanel/Row"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
expand_mode = 1
stretch_mode = 5

[node name="PhaseBar" type="ProgressBar" parent="PhasePanel/Row"]
unique_name_in_owner = true
custom_minimum_size = Vector2(56, 10)
layout_mode = 2
size_flags_vertical = 4
max_value = 1.0
step = 0.001
show_percentage = false
```

## `scenes/ui/pause_menu.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/pause_menu.gd" id="1"]

[node name="PauseMenu" type="CanvasLayer"]
layer = 22
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -160.0
offset_top = -110.0
offset_right = 160.0
offset_bottom = 110.0
grow_horizontal = 2
grow_vertical = 2

[node name="Margin" type="MarginContainer" parent="Panel"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="VBox" type="VBoxContainer" parent="Panel/Margin"]
layout_mode = 2

[node name="Title" type="Label" parent="Panel/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 26
text = "Пауза"

[node name="Continue" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Продолжить"

[node name="ResetProgress" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Сбросить прогресс"

[node name="Quit" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Выйти"
```

## `scenes/ui/shop_menu.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/shop_menu.gd" id="1"]

[node name="ShopMenu" type="CanvasLayer"]
layer = 20
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 6
anchor_left = 1.0
anchor_top = 0.5
anchor_right = 1.0
anchor_bottom = 0.5
offset_left = -460.0
offset_top = -260.0
offset_right = -24.0
offset_bottom = 260.0
grow_horizontal = 0
grow_vertical = 2

[node name="Margin" type="MarginContainer" parent="Panel"]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="VBox" type="VBoxContainer" parent="Panel/Margin"]
layout_mode = 2

[node name="Title" type="Label" parent="Panel/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 26
text = "Магазин пряжи"

[node name="Yarn" type="Label" parent="Panel/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Клубочков: 0"

[node name="List" type="VBoxContainer" parent="Panel/Margin/VBox"]
layout_mode = 2

[node name="Close" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Закрыть (Esc)"
```

## `scenes/ui/title.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/title.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/images/title/title_bg.png" id="2"]

[node name="Title" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("2")
expand_mode = 1
stretch_mode = 6

[node name="Panel" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.72
anchor_top = 0.5
anchor_right = 0.72
anchor_bottom = 0.5
offset_left = -290.0
offset_top = -175.0
offset_right = 290.0
offset_bottom = 175.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.72
anchor_top = 0.5
anchor_right = 0.72
anchor_bottom = 0.5
offset_left = -270.0
offset_top = -150.0
offset_right = 270.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 16

[node name="Logo" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 64
horizontal_alignment = 1
text = "Snack Run"

[node name="Tagline" type="Label" parent="VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
horizontal_alignment = 1
text = "Маленький кот. Большой мир. Вкусные приключения."

[node name="Continue" type="Button" parent="VBox"]
layout_mode = 2
text = "Продолжить"

[node name="Play" type="Button" parent="VBox"]
layout_mode = 2
text = "Новая игра"

[node name="Quit" type="Button" parent="VBox"]
layout_mode = 2
text = "Выход"
```

## `scenes/world/district_yard.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world/terrain.gd" id="1"]
[ext_resource type="Script" path="res://scripts/world/world_builder.gd" id="2"]

[node name="DistrictYard" type="Node3D"]

[node name="YardTerrain" type="Node3D" parent="."]
script = ExtResource("1")
data_path = "res://data/terrain/yard.json"

[node name="ParkTerrain" type="Node3D" parent="."]
script = ExtResource("1")
data_path = "res://data/terrain/park.json"

[node name="PortTerrain" type="Node3D" parent="."]
script = ExtResource("1")
data_path = "res://data/terrain/port.json"

[node name="WorldBuilder" type="Node3D" parent="."]
script = ExtResource("2")
layout_path = "res://data/layout/yard.json"
terrain_path = NodePath("../YardTerrain")

[node name="ParkBuilder" type="Node3D" parent="."]
script = ExtResource("2")
layout_path = "res://data/layout/park.json"
terrain_path = NodePath("../ParkTerrain")

[node name="PortBuilder" type="Node3D" parent="."]
script = ExtResource("2")
layout_path = "res://data/layout/port.json"
terrain_path = NodePath("../PortTerrain")

[node name="Spawn" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0)
```

## `scenes/world/gate.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world/gate.gd" id="1"]

[node name="Gate" type="StaticBody3D"]
collision_layer = 1
collision_mask = 0
script = ExtResource("1")

[node name="Collision" type="CollisionShape3D" parent="."]

[node name="Bars" type="Node3D" parent="."]
```

## `scenes/world/lighting.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world/lighting.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/images/world/clouds.png" id="2"]
[ext_resource type="Script" path="res://scripts/world/day_night.gd" id="3"]

[sub_resource type="ProceduralSkyMaterial" id="sky"]
sky_top_color = Color(0.29, 0.608, 0.878, 1)
sky_horizon_color = Color(0.812, 0.902, 0.973, 1)
sky_curve = 0.15
ground_bottom_color = Color(0.827, 0.671, 0.529, 1)
ground_horizon_color = Color(0.812, 0.902, 0.973, 1)
sun_angle_max = 20.0
sun_curve = 0.1
sky_cover = ExtResource("2")
sky_cover_modulate = Color(1, 1, 1, 1)

[sub_resource type="Sky" id="skyres"]
sky_material = SubResource("sky")

[sub_resource type="Environment" id="env"]
background_mode = 2
sky = SubResource("skyres")
ambient_light_source = 3
ambient_light_sky_contribution = 1.0
ambient_light_energy = 0.6
tonemap_mode = 0
ssr_enabled = true
ssr_max_steps = 32
ssao_enabled = true
ssao_radius = 0.3
ssao_intensity = 1.5
glow_enabled = true
glow_intensity = 0.4
glow_bloom = 0.05
glow_hdr_threshold = 1.2
adjustment_enabled = true
adjustment_saturation = 1.1

[node name="Lighting" type="Node3D"]
script = ExtResource("1")

[node name="Sun" type="DirectionalLight3D" parent="."]
light_color = Color(1, 0.945, 0.839, 1)
light_energy = 1.2
light_angular_distance = 1.5
shadow_enabled = true
shadow_blur = 1.5
directional_shadow_mode = 2
directional_shadow_max_distance = 40.0

[node name="Fill" type="DirectionalLight3D" parent="."]
light_color = Color(0.624, 0.769, 0.910, 1)
light_energy = 0.25
shadow_enabled = false

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")

[node name="DayNight" type="Node" parent="."]
script = ExtResource("3")
```

## `scenes/world/yarn_shop.tscn`

```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world/yarn_shop.gd" id="1"]
[ext_resource type="PackedScene" path="res://assets/models/yarn_shop.glb" id="2"]

[sub_resource type="BoxShape3D" id="zone"]
size = Vector3(2.0, 2.0, 2.0)

[sub_resource type="BoxShape3D" id="back"]
size = Vector3(2.2, 2.4, 0.12)

[sub_resource type="BoxShape3D" id="side"]
size = Vector3(0.12, 2.4, 2.2)

[sub_resource type="BoxShape3D" id="floor"]
size = Vector3(2.2, 0.03, 2.2)

[node name="YarnShop" type="Node3D"]
script = ExtResource("1")

[node name="Model" parent="." instance=ExtResource("2")]

[node name="Walls" type="StaticBody3D" parent="."]
collision_layer = 1
collision_mask = 0

[node name="Back" type="CollisionShape3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 1.04)
shape = SubResource("back")

[node name="Left" type="CollisionShape3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.04, 1.2, 0)
shape = SubResource("side")

[node name="Right" type="CollisionShape3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.04, 1.2, 0)
shape = SubResource("side")

[node name="Floor" type="CollisionShape3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.015, 0)
shape = SubResource("floor")

[node name="Zone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="Zone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
shape = SubResource("zone")

[node name="Respawn" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0.2)

[node name="ViewPoint" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.8, 0.55, -2.0)

[node name="YarnPlay" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, -0.2)
```

## `scripts/autoload/dev_tools.gd`

```gdscript
extends Node
## Инструменты разработчика. Запуск: godot --path . ++ --screenshot=build/shot.png

const DEV_ARGS := ["--screenshot=", "--at=", "--phase=", "--album"]


static func is_dev_run(args: PackedStringArray) -> bool:
	## Отладочный запуск: кадры и перенос кота не должны собирать клубочки в настоящее сохранение владельца.
	for a in args:
		for d in DEV_ARGS:
			if a.begins_with(d):
				return true
	return false


func _ready() -> void:
	if is_dev_run(OS.get_cmdline_user_args()):
		SaveGame.read_only = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			_set_phase_later(DayCycle.parse_time(arg.trim_prefix("--phase=")))
		if arg.begins_with("--at="):
			var v := arg.trim_prefix("--at=").split_floats(",")
			if v.size() >= 3:
				_teleport_later(Vector3(v[0], v[1], v[2]), deg_to_rad(v[3]) if v.size() > 3 else 0.0)
		if arg == "--album":
			_open_album_later()
		if arg.begins_with("--screenshot="):
			_screenshot_and_quit(arg.trim_prefix("--screenshot="))


func _set_phase_later(t: float) -> void:
	## Для кадров ночью/на закате: ++ --phase=220 ставит время суток после загрузки сцены.
	for i in 3:
		await get_tree().process_frame
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn:
		dn.call("set_time", t)
		dn.set("time_scale", 0.0)


func _teleport_later(pos: Vector3, yaw := 0.0) -> void:
	## Для кадров других районов: ++ --at=x,y,z[,yaw°] ставит кота в точку и поворачивает камеру.
	for i in 4:
		await get_tree().process_frame
	var cat := get_tree().get_first_node_in_group("cat")
	if cat:
		cat.call("teleport", pos)
		var rig := cat.get("camera_rig") as Node3D
		if rig:
			rig.global_position = pos + Vector3(0, 0.6, 0)
			rig.set("_yaw", yaw)


func _open_album_later() -> void:
	## Кадр альбома: ++ --album открывает альбом со всеми карточками (план 13: 20 вкусняшек).
	for i in 6:
		await get_tree().process_frame
	var main := get_tree().get_first_node_in_group("main")
	if main == null:
		main = get_tree().current_scene
	fill_album(main)
	if main and main.has_method("toggle_album"):
		main.call("toggle_album")


func fill_album(main: Node) -> void:
	## Все карточки — только для кадра: автосохранение выключается, настоящий save.json не меняется (ревью плана 13).
	if main and "autosave" in main:
		main.set("autosave", false)
	for f in FoodCatalog.all():
		GameState.album[f.id] = maxi(int(GameState.album.get(f.id, 0)), 1)
	GameState.album_changed.emit(GameState.album)


func _screenshot_and_quit(path: String) -> void:
	# Ждём, пока сцена загрузится, кот приземлится и анимация перейдёт в idle.
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err := img.save_png(abs_path)
	print("СКРИНШОТ ", abs_path, " ", error_string(err))
	get_tree().quit(0 if err == OK else 1)
```

## `scripts/autoload/game_state.gd`

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
signal yarn_changed(count: int)
signal upgrade_bought(id: StringName)
signal skin_changed(id: StringName)
signal food_stolen(food: FoodDef)
signal cat_petted(spilled: Array)

const MAX_HEARTS := 3
const MOUTH_CAPACITY := 3
const GOAL_FIRST := 3
const GOAL_STEP := 2
const SATIETY_GATE := 10   # сытость, открывающая арку в кафе (план 3)
const PARK_GATE := 25      # сытость, открывающая ворота в парк (этап 2)
const YARN_PER_CARD := 3
const SPEED_BONUS := 1.15
const STEALTH_BONUS := 0.7
const DEFAULT_SKIN := &"orange"

var max_hearts := MAX_HEARTS
var hearts := MAX_HEARTS
var mouth_capacity := MOUTH_CAPACITY
var mouth: Array[FoodDef] = []
var satiety := 0
var album := {}          # id -> сколько раз съедено
var goal_target := GOAL_FIRST
var goal_done := 0       # новых карточек с начала текущей цели
var yarn := 0            # клубочки, валюта магазина
var yarn_taken := {}     # ключ позиции собранного клубочка -> true (они не возвращаются после перезапуска)
var upgrades := {}       # id товара -> true
var skin: StringName = DEFAULT_SKIN
var speed_mult := 1.0
var stealth_mult := 1.0


func reset() -> void:
	max_hearts = MAX_HEARTS
	hearts = MAX_HEARTS
	mouth_capacity = MOUTH_CAPACITY
	mouth = []
	satiety = 0
	album = {}
	goal_target = GOAL_FIRST
	goal_done = 0
	yarn = 0
	yarn_taken = {}
	upgrades = {}
	skin = DEFAULT_SKIN
	_apply_upgrades()
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	goal_changed.emit(goal_done, goal_target)
	yarn_changed.emit(yarn)
	skin_changed.emit(skin)


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
			yarn += YARN_PER_CARD
		album[f.id] += 1
	hearts = mini(hearts + 1, max_hearts)
	yarn_changed.emit(yarn)
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


func steal_last() -> FoodDef:
	## Голубь выхватывает последнюю еду из зубов: без урона и без рассыпания (этап 2).
	if mouth.is_empty():
		return null
	var f: FoodDef = mouth.pop_back()
	mouth_changed.emit(mouth)
	food_stolen.emit(f)
	return f


func pet() -> Array[FoodDef]:
	## Ребёнок гладит кота: еда из зубов выпадает рядом, сердечко не снимается (этап 2).
	var spilled := spill()
	cat_petted.emit(spilled)
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


func peck() -> bool:
	## Чайка: сердечко минус одно, последняя еда унесена (food_stolen), остальное в зубах не рассыпается (спек порта).
	steal_last()
	hearts = maxi(hearts - 1, 0)
	hearts_changed.emit(hearts, max_hearts)
	cat_hit.emit([] as Array[FoodDef])
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


func add_yarn(n: int) -> void:
	yarn += n
	yarn_changed.emit(yarn)


func take_yarn(key: String) -> void:
	## Клубочек из раскладки: запоминаем ключ, чтобы он не вернулся после перезапуска.
	if key != "":
		yarn_taken[key] = true
	add_yarn(1)


func is_yarn_taken(key: String) -> bool:
	return yarn_taken.has(key)


func spend_yarn(n: int) -> bool:
	if n > yarn:
		return false
	yarn -= n
	yarn_changed.emit(yarn)
	return true


func owns(id: StringName) -> bool:
	return upgrades.has(id)


func can_buy(item: ShopItem) -> bool:
	if item == null or yarn < item.price:
		return false
	if item.requires != &"" and not owns(item.requires):
		return false
	if item.kind == "refill":
		return hearts < max_hearts
	return not owns(item.id)


func buy(item: ShopItem) -> bool:
	if not can_buy(item):
		return false
	spend_yarn(item.price)
	if item.kind == "refill":
		hearts = max_hearts
		hearts_changed.emit(hearts, max_hearts)
		return true
	upgrades[item.id] = true
	_apply_upgrades()
	if item.kind == "max_heart":
		hearts = max_hearts
		hearts_changed.emit(hearts, max_hearts)
	if item.kind == "skin":
		select_skin(item.skin_id)
	upgrade_bought.emit(item.id)
	return true


func _apply_upgrades() -> void:
	max_hearts = MAX_HEARTS
	mouth_capacity = MOUTH_CAPACITY
	speed_mult = 1.0
	stealth_mult = 1.0
	for it in ShopCatalog.all():
		if not owns(it.id):
			continue
		match it.kind:
			"max_heart":
				max_hearts = maxi(max_hearts, it.value)
			"mouth":
				mouth_capacity = maxi(mouth_capacity, it.value)
			"speed":
				speed_mult = SPEED_BONUS
			"quiet":
				stealth_mult = STEALTH_BONUS
	hearts = mini(hearts, max_hearts)


func owned_skins() -> Array[StringName]:
	var out: Array[StringName] = [DEFAULT_SKIN]
	for it in ShopCatalog.all():
		if it.kind == "skin" and owns(it.id):
			out.append(it.skin_id)
	return out


func select_skin(id: StringName) -> bool:
	if not owned_skins().has(id):
		return false
	skin = id
	skin_changed.emit(skin)
	return true


func to_dict() -> Dictionary:
	var album_out := {}
	for k in album:
		album_out[String(k)] = album[k]
	var upgrades_out := {}
	for k in upgrades:
		upgrades_out[String(k)] = true
	return {
		"version": 1,
		"album": album_out,
		"satiety": satiety,
		"yarn": yarn,
		"yarn_taken": yarn_taken.keys(),
		"upgrades": upgrades_out,
		"skin": String(skin),
		"goal_target": goal_target,
		"goal_done": goal_done,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	if d.get("album") is Dictionary:
		for k in d["album"]:
			if d["album"][k] is float or d["album"][k] is int:
				album[StringName(k)] = int(d["album"][k])
	if d.get("satiety") is float or d.get("satiety") is int:
		satiety = int(d["satiety"])
	if d.get("yarn") is float or d.get("yarn") is int:
		yarn = int(d["yarn"])
	if d.get("yarn_taken") is Array:
		for k in d["yarn_taken"]:
			if k is String:
				yarn_taken[k] = true
	if d.get("upgrades") is Dictionary:
		for k in d["upgrades"]:
			if ShopCatalog.get_by_id(StringName(k)) != null:
				upgrades[StringName(k)] = true
	_apply_upgrades()
	hearts = max_hearts
	if d.get("skin") is String and owned_skins().has(StringName(d["skin"])):
		skin = StringName(d["skin"])
	if d.get("goal_target") is float or d.get("goal_target") is int:
		goal_target = maxi(int(d["goal_target"]), GOAL_FIRST)
	if d.get("goal_done") is float or d.get("goal_done") is int:
		goal_done = maxi(int(d["goal_done"]), 0)
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	yarn_changed.emit(yarn)
	skin_changed.emit(skin)
	goal_changed.emit(goal_done, goal_target)
```

## `scripts/autoload/input_setup.gd`

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
	"album": [KEY_TAB],
	"pause": [KEY_ESCAPE],
}
const PAD_BUTTONS := {
	"jump": JOY_BUTTON_A,
	"hide": JOY_BUTTON_B,
	"eat": JOY_BUTTON_X,
	"album": JOY_BUTTON_Y,
	"pause": JOY_BUTTON_START,
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
		if InputMap.has_action(action):
			continue   # повторная регистрация не должна дублировать события
		InputMap.add_action(action, 0.2)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		if PAD_BUTTONS.has(action):
			var b := InputEventJoypadButton.new()
			b.button_index = PAD_BUTTONS[action]
			InputMap.action_add_event(action, b)
		if PAD_AXES.has(action):
			var m := InputEventJoypadMotion.new()
			m.axis = PAD_AXES[action][0]
			m.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, m)
```

## `scripts/autoload/save_game.gd`

```gdscript
extends Node
## Сохранение прогресса в JSON. Пишет только по явному вызову save_now() (из Main).

const VERSION := 1

var path := "user://save.json"
var read_only := false   # отладочные запуски (кадры, --at) не трогают настоящее сохранение (план 14)


func save_now() -> bool:
	if read_only:
		return false
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("не удалось открыть %s для записи" % path)
		return false
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()
	return true


func load_now() -> bool:
	if not FileAccess.file_exists(path):
		GameState.reset()
		return false
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()   # parse() возвращает код ошибки и не печатает ERROR в консоль, в отличие от parse_string
	var parsed = json.data if json.parse(text) == OK else null
	if not (parsed is Dictionary):
		push_warning("сохранение повреждено, начинаем заново: " + path)
		GameState.reset()
		return false
	GameState.from_dict(parsed)
	return true


func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
```

## `scripts/autoload/sfx.gd`

```gdscript
extends Node
## Звуки (спек 2.7). Правило: один play() на игровое событие (сигнал), никогда из _process.
## Пул из шести плееров: одновременные события не перебивают друг друга.

const STREAMS := {
	&"pickup": "res://assets/sfx/pickup.ogg",
	&"eat": "res://assets/sfx/eat.ogg",
	&"hit": "res://assets/sfx/hit.ogg",
	&"meow": "res://assets/sfx/meow.wav",
	&"bark": "res://assets/sfx/bark.wav",
	&"bell": "res://assets/sfx/bell.ogg",
	&"hiss": "res://assets/sfx/hiss.wav",
	&"sprinkle": "res://assets/sfx/sprinkle.wav",
	&"coo": "res://assets/sfx/coo.wav",
	&"splash": "res://assets/sfx/splash.wav",
	&"gull": "res://assets/sfx/gull.wav",
	&"wave": "res://assets/sfx/wave.wav",
	&"horn": "res://assets/sfx/horn.wav",
}
const POOL := 6
const VOLUME_DB := {&"bark": -4.0, &"bell": -2.0, &"meow": -3.0, &"hiss": -6.0, &"sprinkle": -6.0, &"coo": -4.0, &"splash": -3.0, &"gull": -5.0, &"wave": -6.0, &"horn": -6.0}

var enabled := true
var last_played: StringName = &""
var counts := {}
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in STREAMS:
		if ResourceLoader.exists(STREAMS[key]):
			_streams[key] = load(STREAMS[key])
		else:
			push_warning("нет звука %s: %s" % [key, STREAMS[key]])
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.name = "Player%d" % i
		add_child(p)
		_players.append(p)


func has(name: StringName) -> bool:
	return _streams.has(name)


func reset_counters() -> void:
	counts = {}
	last_played = &""


func play(name: StringName, pitch_jitter := 0.06) -> AudioStreamPlayer:
	if not enabled or not _streams.has(name):
		return null
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.volume_db = VOLUME_DB.get(name, 0.0)
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
	last_played = name
	counts[name] = counts.get(name, 0) + 1
	return p
```

## `scripts/core/cat_skin.gd`

```gdscript
class_name CatSkin
extends Resource
## Скин кота: три цвета для трёх материалов модели (спек 2.4).

const ROLE_BY_MATERIAL := {"sr_cat_orange": "body", "sr_cream": "belly", "sr_coral": "accent"}

@export var id: StringName = &"orange"
@export var display_name := "Рыжий"
@export var body := Color("#FAAE45")
@export var belly := Color("#FCD3A1")
@export var accent := Color("#F57485")


static func apply(model: Node, skin: CatSkin) -> int:
	var count := 0
	var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for mi in meshes:
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var mat := m3.get_surface_override_material(i) as StandardMaterial3D
			if mat == null or not ROLE_BY_MATERIAL.has(mat.resource_name):
				continue
			match ROLE_BY_MATERIAL[mat.resource_name]:
				"body":
					mat.albedo_color = skin.body
				"belly":
					mat.albedo_color = skin.belly
				"accent":
					mat.albedo_color = skin.accent
			count += 1
	return count
```

## `scripts/core/layers.gd`

```gdscript
class_name Layers
extends RefCounted
## Bit-значения слоёв коллизий (одни на весь проект).

const WORLD := 1
const CAT := 2
const HAZARD := 4
const AREA := 8
```

## `scripts/core/mouse.gd`

```gdscript
class_name Mouse
extends RefCounted
## Захват мыши для камеры. В headless (тесты, импорт) ничего не делает: там DisplayServer без мыши.


static func capture(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE
```

## `scripts/core/rarity.gd`

```gdscript
class_name Rarity
extends RefCounted
## Редкости еды: веса спавна, сытость, цвета (спек 2.2, 3.3, 3.4).

enum Tier { COMMON, RARE, VERY_RARE, LEGENDARY }

const WEIGHTS := {Tier.COMMON: 60, Tier.RARE: 25, Tier.VERY_RARE: 12, Tier.LEGENDARY: 3}
const NIGHT_WEIGHTS := {Tier.COMMON: 40, Tier.RARE: 30, Tier.VERY_RARE: 20, Tier.LEGENDARY: 10}   # ночью рискованнее, но вкуснее (этап 2)
const SATIETY := {Tier.COMMON: 1, Tier.RARE: 3, Tier.VERY_RARE: 6, Tier.LEGENDARY: 15}
const COLORS := {
	Tier.COMMON: Color("#4D945B"),
	Tier.RARE: Color("#6491E4"),
	Tier.VERY_RARE: Color("#C473D4"),
	Tier.LEGENDARY: Color("#FABE32"),
}
const NAMES := {Tier.COMMON: "Обычная", Tier.RARE: "Редкая", Tier.VERY_RARE: "Очень редкая", Tier.LEGENDARY: "Легендарная"}


static func pick_weighted(allowed: Array, rng: RandomNumberGenerator, weights: Dictionary = WEIGHTS) -> int:
	if allowed.is_empty():
		return Tier.COMMON
	var total := 0
	for t in allowed:
		total += weights[t]
	var roll := rng.randi_range(1, total)
	for t in allowed:
		roll -= weights[t]
		if roll <= 0:
			return t
	return allowed[-1]
```

## `scripts/core/shop_catalog.gd`

```gdscript
class_name ShopCatalog
extends RefCounted
## Загружает товары из data/shop.

const DIR := "res://data/shop"
static var _cache: Array[ShopItem] = []


static func all() -> Array[ShopItem]:
	if _cache.is_empty():
		for n in DirAccess.get_files_at(DIR):
			if n.ends_with(".tres"):
				var res := load(DIR + "/" + n)
				if res is ShopItem:
					_cache.append(res)
		_cache.sort_custom(func(a: ShopItem, b: ShopItem) -> bool: return a.order < b.order)
	return _cache


static func get_by_id(id: StringName) -> ShopItem:
	for it in all():
		if it.id == id:
			return it
	return null
```

## `scripts/core/shop_item.gd`

```gdscript
class_name ShopItem
extends Resource
## Товар магазина пряжи (спек 3.5). Файлы в data/shop/*.tres.

@export var id: StringName = &""
@export var display_name := ""
@export var price := 0
@export var kind := "refill"          # refill | max_heart | mouth | speed | quiet | skin
@export var value := 0                # новый max_hearts / mouth_capacity
@export var skin_id: StringName = &""
@export var requires: StringName = &""
@export var order := 0
```

## `scripts/core/skin_catalog.gd`

```gdscript
class_name SkinCatalog
extends RefCounted

const DIR := "res://data/skins"
static var _cache: Array[CatSkin] = []


static func all() -> Array[CatSkin]:
	if _cache.is_empty():
		for n in DirAccess.get_files_at(DIR):
			if n.ends_with(".tres"):
				var res := load(DIR + "/" + n)
				if res is CatSkin:
					_cache.append(res)
		_cache.sort_custom(func(a: CatSkin, b: CatSkin) -> bool: return a.id < b.id)
	return _cache


static func get_by_id(id: StringName) -> CatSkin:
	for s in all():
		if s.id == id:
			return s
	return null
```

## `scripts/dev/terrain_demo.gd`

```gdscript
extends Node3D
## Демо рельефа (план 10): холм, низина, терраса со стенами, лестница и пандус; кот с камерой.
## Запуск кадра: godot --path . res://scenes/dev/terrain_demo.tscn ++ --screenshot=build/x.png

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")


func _ready() -> void:
	Toon.apply($Builder, Toon.OUTLINE_NONE)
	SurfaceTextures.apply($Builder)
	var rig := RigScene.instantiate()
	var cat := CatScene.instantiate()
	cat.camera_rig = rig
	rig.target = cat
	add_child(rig)
	add_child(cat)
	cat.global_position = Vector3(3, 0.1, -3)
	rig.global_position = cat.global_position + Vector3(0, 0.6, 0)
	rig.set("_yaw", deg_to_rad(55))   # на террасу с лестницей и пандусом
	(rig.get_node("SpringArm3D") as SpringArm3D).spring_length = 1.8
	(rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()
```

## `scripts/food/food_catalog.gd`

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

## `scripts/food/food_def.gd`

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


func icon_path() -> String:
	return "res://assets/images/ui/food_%s.png" % id


func icon() -> Texture2D:
	## Иконка из сгенерированных картинок; без файла — null (пустой слот, не ошибка).
	var path := icon_path()
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
```

## `scripts/food/food_pickup.gd`

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
	if food.tier >= Rarity.Tier.RARE:
		Effects.sparkles(self, Rarity.COLORS[food.tier])


func _process(delta: float) -> void:
	_t += delta
	if grace > 0.0:
		grace -= delta
		if grace <= 0.0:
			# Пауза кончилась: кот мог всё это время стоять на еде, body_entered уже не придёт.
			for body in get_overlapping_bodies():
				_on_body_entered(body)
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
		Sfx.play(&"pickup")
		picked.emit(food, self)
		set_deferred("monitoring", false)
		queue_free()
```

## `scripts/food/food_spawn_point.gd`

```gdscript
class_name FoodSpawnPoint
extends Node3D
## Точка спавна еды: допустимые редкости, взвешенный выбор, респавн 30–90 с.

signal spawned(pickup: FoodPickup)

const PickupScene := preload("res://scenes/food/food_pickup.tscn")

@export var allowed: Array = [Rarity.Tier.COMMON]
@export var foods: Array = []   # id еды; пусто — любая еда допустимой редкости (парк задаёт свою еду)
@export var respawn_min := 30.0
@export var respawn_max := 90.0
var rng := RandomNumberGenerator.new()
var current: FoodPickup


func _ready() -> void:
	rng.randomize()
	spawn_now()


func pick_def() -> FoodDef:
	var night := is_inside_tree() and DayNight.is_night(get_tree())
	var tier := Rarity.pick_weighted(allowed, rng, Rarity.NIGHT_WEIGHTS if night else Rarity.WEIGHTS)
	var pool := FoodCatalog.by_tier(tier)
	if not foods.is_empty():
		var ids := foods.map(func(x): return StringName(x))   # один раз, не на каждой еде каталога
		var only: Array[FoodDef] = []
		for f in pool:
			if StringName(f.id) in ids:
				only.append(f)
		if only.is_empty():
			push_warning("точка спавна %s: в списке еды нет редкости %d" % [global_position if is_inside_tree() else Vector3.ZERO, tier])
			for f in FoodCatalog.all():
				if StringName(f.id) in ids:
					only.append(f)
		pool = only
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
	get_tree().create_timer(delay, false).timeout.connect(spawn_now)
```

## `scripts/food/yarn_pickup.gd`

```gdscript
class_name YarnPickup
extends Area3D
## Клубочек: валюта магазина. Лежит в труднодоступном месте, не респавнится (спек 3.4).

@onready var _visual: Node3D = $Visual
var key := ""      # ключ позиции из раскладки; пустой у клубочков вне раскладки
var _t := 0.0


func _ready() -> void:
	add_to_group("yarn")
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	body_entered.connect(_on_body)
	var model := (load("res://assets/models/yarn.glb") as PackedScene).instantiate()
	_visual.add_child(model)
	Toon.apply(_visual, Toon.OUTLINE_FOOD)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += 1.5 * delta
	_visual.position.y = 0.03 * (0.5 + 0.5 * sin(_t * 3.0))


func _on_body(body: Node3D) -> void:
	if not body.is_in_group("cat"):
		return
	GameState.take_yarn(key)
	Sfx.play(&"pickup", 0.15)
	if body.has_method("cheer"):
		body.call("cheer")
	Effects.burst(get_parent(), global_position + Vector3(0, 0.1, 0), Effects.YARN_COLOR, 16, 0.04)
	set_deferred("monitoring", false)
	queue_free()
```

## `scripts/hazards/chase_brain.gd`

```gdscript
class_name ChaseBrain
extends RefCounted
## Конечный автомат погони (спек 3.2, собака): idle → alert (1 с) → chase → return.

enum State { IDLE, ALERT, CHASE, RETURN }

const ALERT_TIME := 1.0
const CHASE_MAX := 8.0
const LOST_HIDDEN := 2.0

var state: int = State.IDLE
var alert_time := ALERT_TIME   # ребёнок парка настораживается быстрее и устаёт раньше собаки
var chase_max := CHASE_MAX
var _t := 0.0
var _hidden_t := 0.0


func reset() -> void:
	state = State.IDLE
	_t = 0.0
	_hidden_t = 0.0


func give_up() -> void:
	## Погоня обрывается извне (наступила ночь): собака идёт домой спать.
	if state == State.ALERT or state == State.CHASE:
		state = State.RETURN
		_t = 0.0


func update(delta: float, sees_cat: bool, cat_hidden: bool, at_home: bool, cat_safe := false) -> int:
	match state:
		State.IDLE:
			if sees_cat and not cat_hidden:
				state = State.ALERT
				_t = 0.0
		State.ALERT:
			if cat_safe:
				state = State.IDLE   # кот уже в будке: не стоит и не лает
				_t = 0.0
			else:
				_t += delta
				if _t >= alert_time:
					state = State.CHASE
					_t = 0.0
					_hidden_t = 0.0
		State.CHASE:
			if cat_safe:
				state = State.RETURN   # «в будку собаки не заходят» (спек 3.5): уходит сразу, не через 2 с
			else:
				_t += delta
				_hidden_t = _hidden_t + delta if cat_hidden else 0.0
				if _t >= chase_max or _hidden_t >= LOST_HIDDEN:
					state = State.RETURN
		State.RETURN:
			if at_home:
				state = State.IDLE
				_t = 0.0
	return state
```

## `scripts/hazards/crab.gd`

```gdscript
class_name Crab
extends HazardBase
## Краб (спек порта, раздел 3): сидит в норке; кот ближе 3 м (ночью 4 м) — вылезает и бежит боком 2,4 м/с; прыжок кота над
## ним или 5 с погони — прячется в норку на 6 с. Касание — щипок (удар).

const NOTICE := 3.0
const NOTICE_NIGHT := 4.0
const CHASE_MAX := 5.0
const HIDE_TIME := 6.0


static func decide(state: StringName, dist: float, cat_above: bool, chase_t: float, hide_left: float, night: bool) -> StringName:
	match state:
		&"burrow":
			return &"chase" if dist < (NOTICE_NIGHT if night else NOTICE) else &"burrow"
		&"chase":
			return &"hide" if cat_above or chase_t >= CHASE_MAX else &"chase"
		&"hide":
			return &"hide" if hide_left > 0.0 else &"burrow"
	return state

const SPEED := 2.4
const ABOVE := 0.25

var state: StringName = &"burrow"
var night_only := false
var _chase_t := 0.0
var _hide_left := 0.0

@onready var _model: Node3D = $Model
@onready var _burrow: Node3D = $Burrow
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	night_only = bool(hz.get("night_only", false))


func _ready() -> void:
	super()
	walk_speed = SPEED
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["idle", "walk"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_set_out(false)


func _set_out(out: bool) -> void:
	## В норке краба не видно и он не мешает и не щиплет.
	_model.visible = out
	collision_layer = 0   # маленький краб не твёрдый: иначе он толкает кота телом (щипок — через HitZone)
	hit_zone.monitoring = out


func _physics_process(delta: float) -> void:
	_ensure_home()
	_burrow.global_position = home
	var night := DayNight.is_night(get_tree())
	var c := _find_cat()
	var dist := 99.0
	var above := false
	if c and not bool(c.get("hidden")) and not bool(c.get("in_safe_zone")):
		var d := c.global_position - global_position
		dist = Vector2(d.x, d.z).length()
		above = d.y > ABOVE and dist < 0.5
	if night_only and not night and state == &"burrow":
		return   # ночной краб днём сидит в норке
	var watch := dist   # из норки краб сторожит округу норки, в погоне — меряет до кота
	if state == &"burrow" and c:
		watch = Vector2(c.global_position.x - home.x, c.global_position.z - home.z).length()
	var next := decide(state, watch, above, _chase_t, _hide_left, night)
	if next != state:
		if next == &"chase":
			_chase_t = 0.0
			_set_out(true)
		elif next == &"hide":
			_hide_left = HIDE_TIME
		elif next == &"burrow":
			global_position = home
			_set_out(false)
		state = next
	match state:
		&"burrow":
			velocity = Vector3.ZERO
		&"chase":
			_chase_t += delta
			_run_to(c.global_position, delta)
			for b in hit_zone.get_overlapping_bodies():
				_on_hit_body(b)
		&"hide":
			_hide_left = maxf(_hide_left - delta, 0.0)
			if _run_to(home, delta) < 0.15 and _model.visible:
				_set_out(false)   # забрался в норку; ждёт, пока выйдет время


func _run_to(target: Vector3, delta: float) -> float:
	var left := move_towards_point(target, SPEED, delta)
	_model.rotation.y = PI / 2.0   # бежит боком: клешни смотрят в сторону, ход — вдоль корпуса
	if _anim and _anim.has_animation("walk") and _anim.current_animation != "walk":
		_anim.play("walk", 0.15)
	return left


func _on_hit_body(body: Node3D) -> void:
	if state == &"chase":
		super(body)
```

## `scripts/hazards/cyclist.gd`

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
var _dust: CPUParticles3D

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
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	_dust = Effects.trail(self, Effects.DUST_COLOR, 12)
	_dust.name = "Dust"
	_dust.emitting = false
	_dust.position = Vector3(0, 0.1, 0.4)
	visible = false
	if path:
		start_cycle()


func start_cycle() -> void:
	var wait := _rng.randf_range(interval_min, interval_max)
	get_tree().create_timer(wait, false).timeout.connect(_ring)


func _ring() -> void:
	if not is_inside_tree():
		return
	bell.emit()
	get_tree().create_timer(bell_lead, false).timeout.connect(_depart)


func _depart() -> void:
	if not is_inside_tree() or path == null:
		return
	riding = true
	_progress = 0.0
	visible = true
	_dust.emitting = true
	_hit.set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if not riding or path == null:
		return
	var length := path.curve.get_baked_length()
	_progress += speed * delta
	if _progress >= length:
		riding = false
		visible = false
		_dust.emitting = false
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

## `scripts/hazards/dog.gd`

```gdscript
class_name Dog
extends HazardBase
## Собака: спит, замечает кота в конусе, 1 с настораживается, гонится 1,2× скорости кота,
## теряет след в укрытии (2 с) или устаёт (8 с), возвращается домой (спек 3.2).

const VISION_HALF_ANGLE := 45.0
const VISION_RANGE := 6.0
const HOME_RADIUS := 0.4
const RETURN_TIMEOUT := 8.0   # дольше идёт домой — значит упёрлась (стена террасы): переносится домой (ревью плана 11)

var brain := ChaseBrain.new()
var _last_state: int = ChaseBrain.State.IDLE
var _zzz_t := 0.0
var _return_t := 0.0

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	super()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["idle", "walk", "sleep", "alert"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip(&"sleep")


func reset_pursuit() -> void:
	brain.reset()


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone"):
		return false
	if DayNight.is_night(get_tree()):
		return false   # ночью собака двора спит и не просыпается от кота (этап 2)
	var forward := -global_transform.basis.z
	return Perception.in_cone(global_position, forward, c.global_position, VISION_HALF_ANGLE * GameState.stealth_mult, VISION_RANGE)


func _physics_process(delta: float) -> void:
	_ensure_home()
	var c := _find_cat()
	var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))
	var at_home := global_position.distance_to(home) < HOME_RADIUS
	if DayNight.is_night(get_tree()):
		brain.give_up()   # ночь посреди погони — собака уходит спать (ревью плана 7)
	var cat_safe: bool = c != null and bool(c.get("in_safe_zone"))
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home, cat_safe)
	if s == ChaseBrain.State.ALERT and _last_state != ChaseBrain.State.ALERT:
		Sfx.play(&"bark")   # один лай на настороженность
	_last_state = s
	if s != ChaseBrain.State.RETURN:
		_return_t = 0.0
	if c and c.has_method("threaten") and s in [ChaseBrain.State.ALERT, ChaseBrain.State.CHASE] and global_position.distance_to(c.global_position) < VISION_RANGE:
		c.call("threaten")   # испуг, пока собака насторожилась или гонится и она ближе 6 м
	match s:
		ChaseBrain.State.IDLE:
			rotation.y = lerp_angle(rotation.y, home_yaw, 6.0 * delta)   # снова сторожит в исходную сторону
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play_clip(&"sleep")
			_zzz_t += delta
			if _zzz_t >= 1.2:
				_zzz_t = 0.0
				Effects.zzz(get_parent(), global_position + Vector3(0, 0.45, 0))
		ChaseBrain.State.ALERT:
			_zzz_t = 0.0
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
			_return_t += delta
			if _return_t >= RETURN_TIMEOUT:
				global_position = home   # прямой путь домой перекрыт: на большом дворе это за кадром
				velocity = Vector3.ZERO
				Effects.dust(get_parent(), home)
			else:
				move_towards_point(home, walk_speed, delta)
			play_clip(&"walk")


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

## `scripts/hazards/forklift.gd`

```gdscript
class_name Forklift
extends Node3D
## Погрузчик на причале (спек порта, раздел 3): стоит у штабеля 4–6 с, 1,5 с гудит, едет 3 м/с с ящиком к следующей точке
## маршрута; ночью стоит. Касание — удар, как у велосипедиста.

const SPEED := 3.0
const HORN := 1.5


static func next_state(state: StringName, t_in_state: float, wait: float, night: bool) -> StringName:
	## drive → wait по прибытии решает узел; здесь — переходы по времени и ночь.
	if night:
		return &"wait"
	match state:
		&"wait":
			return &"horn" if t_in_state >= wait else &"wait"
		&"horn":
			return &"drive" if t_in_state >= HORN else &"horn"
	return state

var state: StringName = &"wait"
var path: Array[Vector3] = []
var wait_range := Vector2(4.0, 6.0)
var _i := 0             # текущая точка маршрута (стоит у неё)
var _dir := 1
var _t := 0.0
var _wait := 5.0
var _rng := RandomNumberGenerator.new()

@onready var _hit: Area3D = $HitZone


func configure(hz: Dictionary, _builder: Node3D) -> void:
	path.clear()
	for p in hz.get("path", []):
		path.append(Vector3(float(p[0]), 0.0, float(p[1])))
	var w: Array = hz.get("wait", [4.0, 6.0])
	wait_range = Vector2(float(w[0]), float(w[1]))


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.body_entered.connect(_on_body)
	Toon.apply($Model, Toon.OUTLINE_NONE)
	_wait = _rng.randf_range(wait_range.x, wait_range.y)


func _ground(p: Vector3) -> Vector3:
	return Vector3(p.x, Terrain.surface_height(get_tree(), p.x, p.z, global_position.y), p.z)


func _physics_process(delta: float) -> void:
	if path.size() < 2:
		return
	_t += delta
	var night := DayNight.is_night(get_tree())
	if state == &"drive" and not night:
		for b in _hit.get_overlapping_bodies():   # кот мог стоять у вил ещё до старта — body_entered не повторится
			_on_body(b)
		var target := _ground(path[_i + _dir])
		var to := target - global_position
		to.y = 0.0
		var step := SPEED * delta
		if to.length() <= step:
			global_position = target
			_i += _dir
			if _i == 0 or _i == path.size() - 1:
				_dir = -_dir   # туда-обратно по маршруту
			state = &"wait"
			_t = 0.0
			_wait = _rng.randf_range(wait_range.x, wait_range.y)
		else:
			var d := to.normalized()
			global_position += d * step
			global_position.y = target.y
			rotation.y = atan2(d.x, d.z)   # вилы (+Z модели) — по ходу
		return
	var next := next_state(state, _t, _wait, night)
	if next != state:
		state = next
		_t = 0.0
		if state == &"horn":
			Sfx.play(&"horn")


func _on_body(body: Node3D) -> void:
	if state == &"drive" and body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)
```

## `scripts/hazards/gardener.gd`

```gdscript
class_name Gardener
extends ParkPerson
## Садовник со шлангом (спек этапа 2, раздел 3): ходит по маршруту; каждые 15–25 с останавливается, 1 с шипит
## (предупреждение), 4 с поливает перед собой конусом 3 м / 40° — струя бьёт кота. Ночью спит в сторожке.

const WARN_TIME := 1.0
const SPRAY_TIME := 4.0
const SPRAY_RANGE := 3.0
const SPRAY_HALF_ANGLE := 20.0
const WATER := Color("#9FD3F0")

var mode: StringName = &"walk"   # walk | warn | spray
var mode_left := 0.0
var _next_water := 0.0
var _spray: CPUParticles3D


func _ready() -> void:
	super()
	walk_speed = 1.2
	_next_water = randf_range(15.0, 25.0)
	_spray = Effects.trail(self, WATER, 50)
	_spray.name = "Hose"
	_spray.local_coords = true
	_spray.direction = Vector3(0, 0.35, -1)
	_spray.spread = 12.0
	_spray.initial_velocity_min = 4.0
	_spray.initial_velocity_max = 5.0
	_spray.gravity = Vector3(0, -9.0, 0)
	_spray.lifetime = 0.7
	_spray.position = Vector3(0.25, 0.9, -0.3)
	_spray.emitting = false
	hit_zone.monitoring = false   # садовник бьёт только струёй


func present() -> bool:
	return not DayNight.is_night(get_tree())


func start_watering() -> void:
	if not present():
		return   # ночью садовник спит: ни полива, ни шипения
	mode = &"warn"
	mode_left = WARN_TIME
	velocity = Vector3.ZERO
	Sfx.play(&"hiss", 0.1)


func _on_hit_body(_body: Node3D) -> void:
	pass   # касание садовника не ранит


func _physics_process(delta: float) -> void:
	_ensure_home()
	if not sync_presence():
		mode = &"walk"
		_spray.emitting = false
		global_position = home
		return
	hit_zone.monitoring = false   # садовник бьёт только струёй (sync_presence включает зону остальным людям)
	match mode:
		&"walk":
			walk_patrol(delta)
			_next_water -= delta
			if _next_water <= 0.0:
				start_watering()
		&"warn":
			mode_left -= delta
			play(&"idle")
			_apply_gravity(delta)
			move_and_slide()
			if mode_left <= 0.0:
				mode = &"spray"
				mode_left = SPRAY_TIME
				_spray.emitting = true
		&"spray":
			mode_left -= delta
			play(&"idle")
			_check_spray()
			if mode_left <= 0.0:
				mode = &"walk"
				_spray.emitting = false
				_next_water = randf_range(15.0, 25.0)


func _check_spray() -> void:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone"):
		return
	var forward := -global_transform.basis.z
	if Perception.in_cone(global_position, forward, c.global_position, SPRAY_HALF_ANGLE, SPRAY_RANGE) and c.has_method("take_hit"):
		c.call("take_hit", global_position)
```

## `scripts/hazards/guard.gd`

```gdscript
class_name Guard
extends ParkPerson
## Ночной сторож с фонариком (спек этапа 2, раздел 3): только ночью; патрулирует аллеи; видит кота в луче фонарика
## (конус 30°, 8 м) или когда кот стоит в свете фонаря парка; погоня как у собаки; касание — удар.

const BEAM_HALF_ANGLE := 15.0
const BEAM_RANGE := 8.0
const LAMP_RADIUS := 3.0
const LAMP_SEE_RANGE := 14.0

var brain := ChaseBrain.new()
var _torch: SpotLight3D


func _ready() -> void:
	super()
	walk_speed = 1.3
	run_speed = 4.6
	_torch = SpotLight3D.new()
	_torch.name = "Flashlight"
	_torch.position = Vector3(0.2, 1.1, -0.2)
	_torch.rotation_degrees = Vector3(-12, 0, 0)
	_torch.spot_angle = BEAM_HALF_ANGLE
	_torch.spot_range = BEAM_RANGE
	_torch.light_color = Color("#FFF1C2")
	_torch.light_energy = 6.0
	add_child(_torch)


func present() -> bool:
	return DayNight.is_night(get_tree())


func _cat_under_lamp(c: Node3D) -> bool:
	for n in get_tree().get_nodes_in_group("night_lights"):
		var l := n as Node3D
		if l.visible and Vector2(l.global_position.x - c.global_position.x, l.global_position.z - c.global_position.z).length() < LAMP_RADIUS:
			return true
	return false


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone") or not present():
		return false
	if Perception.in_cone(global_position, -global_transform.basis.z, c.global_position, BEAM_HALF_ANGLE, BEAM_RANGE):
		return true
	return _cat_under_lamp(c) and global_position.distance_to(c.global_position) < LAMP_SEE_RANGE


func _physics_process(delta: float) -> void:
	_ensure_home()
	if not sync_presence():
		brain.reset()
		global_position = home
		return
	var c := _find_cat()
	var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))
	var s := brain.update(delta, sees_cat(), cat_hidden, global_position.distance_to(home) < 0.6, c != null and bool(c.get("in_safe_zone")))
	match s:
		ChaseBrain.State.CHASE:
			if c:
				move_towards_point(c.global_position, run_speed, delta)
			play(&"run")
		ChaseBrain.State.ALERT:
			if c:
				var to := c.global_position - global_position
				rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 10.0 * delta)
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play(&"idle")
		ChaseBrain.State.RETURN:
			move_towards_point(home, walk_speed, delta)
			play(&"walk")
		_:
			walk_patrol(delta)
```

## `scripts/hazards/gull.gd`

```gdscript
class_name Gull
extends Node3D
## Чайка (спек порта, раздел 3): кружит на 4 м радиусом 3–4 м; кот с едой ближе 6 м по горизонтали — 1 с тень и крик,
## затем бросок в точку, где был кот: удар и последняя еда унесена; перерыв 8 с; ночью спит на насесте.

const DIVE_DIST := 6.0
const COOLDOWN := 8.0


static func decide(dist_h: float, has_food: bool, hidden: bool, safe: bool, cooldown: float, night: bool) -> bool:
	return not night and not hidden and not safe and has_food and cooldown <= 0.0 and dist_h < DIVE_DIST

const HEIGHT := 4.0
const RADIUS := 3.5
const ANGULAR := 0.9
const WARN := 1.0
const DIVE := 0.45
const RISE := 1.2
const STRIKE := 0.9

var mode: StringName = &"circle"   # circle | warn | dive | rise | sleep
var cooldown_left := 0.0
var anchor: Vector3
var ground := 0.0
var _anchored := false
var _angle := 0.0
var _t := 0.0
var _target := Vector3.ZERO
var _from := Vector3.ZERO

@onready var _model: Node3D = $Model
@onready var _shadow: MeshInstance3D = $Shadow
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	_angle = float(hz.get("phase", 0.0))


func _ready() -> void:
	add_to_group("hazards")
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["flap", "idle"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_play(&"flap")


func _play(clip: StringName) -> void:
	if _anim and _anim.has_animation(clip) and _anim.current_animation != clip:
		_anim.play(clip, 0.2)


func _cat() -> Node3D:
	return get_tree().get_first_node_in_group("cat") as Node3D


func _physics_process(delta: float) -> void:
	if not _anchored:
		anchor = global_position   # насест: позицию ставит WorldBuilder до add_child, тест — до add_child
		ground = Terrain.surface_height(get_tree(), anchor.x, anchor.z, anchor.y)
		_anchored = true
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	_t += delta
	var night := DayNight.is_night(get_tree())
	var c := _cat()
	match mode:
		&"sleep":
			if not night:
				mode = &"circle"
				_play(&"flap")
			return
		&"circle":
			if night:
				mode = &"sleep"
				global_position = anchor
				_shadow.visible = false
				_play(&"idle")
				return
			_angle += ANGULAR * delta
			var p := Vector3(anchor.x + cos(_angle) * RADIUS, ground + HEIGHT + sin(_t * 2.0) * 0.1, anchor.z + sin(_angle) * RADIUS)
			_face(p - global_position)
			global_position = p
			if c and decide(Vector2(c.global_position.x - p.x, c.global_position.z - p.z).length(), not GameState.mouth.is_empty(),
					bool(c.get("hidden")), bool(c.get("in_safe_zone")), cooldown_left, night):
				mode = &"warn"
				_t = 0.0
				_target = c.global_position
				_shadow.global_position = _target + Vector3(0, 0.03, 0)
				_shadow.scale = Vector3.ONE * 0.2
				_shadow.visible = true
				Sfx.play(&"gull")
		&"warn":
			_shadow.scale = Vector3.ONE * lerpf(0.2, 1.0, clampf(_t / WARN, 0.0, 1.0))   # тень растёт
			if _t >= WARN:
				mode = &"dive"
				_t = 0.0
				_from = global_position
		&"dive":
			var k := clampf(_t / DIVE, 0.0, 1.0)
			var p := _from.lerp(_target + Vector3(0, 0.3, 0), k)
			_face(p - global_position)
			global_position = p
			if k >= 1.0:
				_strike(c)
				mode = &"rise"
				_t = 0.0
				_shadow.visible = false
				cooldown_left = COOLDOWN
		&"rise":
			var back := Vector3(anchor.x + cos(_angle) * RADIUS, ground + HEIGHT, anchor.z + sin(_angle) * RADIUS)
			global_position = global_position.lerp(back, clampf(delta * 3.0, 0.0, 1.0))
			if _t >= RISE:
				mode = &"circle"


func _strike(c: Node3D) -> void:
	## Бросок в точку, где был кот: попал — удар и последняя еда унесена (остальное в зубах).
	if c == null or not c.has_method("take_peck"):
		return
	var d := c.global_position - _target
	if Vector2(d.x, d.z).length() <= STRIKE and absf(d.y) < 1.2:
		c.call("take_peck", global_position)


func _face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.001:
		rotation.y = atan2(-dir.x, -dir.z)
```

## `scripts/hazards/hazard_base.gd`

```gdscript
class_name HazardBase
extends CharacterBody3D
## Общее для опасностей: слои, дом, ссылка на кота, hit-зона, гравитация.

const GRAVITY := 12.0

@export var walk_speed := 1.5
@export var run_speed := 4.8
var home: Vector3
var home_yaw := 0.0
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
		home_yaw = rotation.y
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
	## Двигает по горизонтали к точке; возвращает оставшееся расстояние.
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

## `scripts/hazards/kid.gd`

```gdscript
class_name Kid
extends ParkPerson
## Ребёнок, который хочет погладить (спек этапа 2, раздел 3): днём бегает у площадки; заметил кота (конус 50°, 7 м) —
## бежит к нему 1,1× шага кота, в укрытии теряет через 2 с, устаёт через 6 с; поймал — гладит 2 с (без урона).
## Вечером уходит домой, утром возвращается.

const VISION_HALF_ANGLE := 25.0
const VISION_RANGE := 7.0
const PET_TIME := 2.0

var brain := ChaseBrain.new()
var _wander := Vector3.ZERO
var _wander_t := 0.0


func _ready() -> void:
	super()
	walk_speed = 1.0
	run_speed = CatMotion.WALK_SPEED * 1.1
	brain.alert_time = 0.4
	brain.chase_max = 6.0


func present() -> bool:
	var p := DayNight.current_phase(get_tree())
	return p == &"day" or p == &"morning"


func sees_cat() -> bool:
	var c := _find_cat()
	if c == null or c.get("hidden") or c.get("in_safe_zone") or not present():
		return false
	return Perception.in_cone(global_position, -global_transform.basis.z, c.global_position, VISION_HALF_ANGLE, VISION_RANGE)


func _on_hit_body(body: Node3D) -> void:
	if present() and body.is_in_group("cat") and body.has_method("pet"):
		if body.call("pet", PET_TIME):
			brain.give_up()   # погладил — идёт играть дальше


func _physics_process(delta: float) -> void:
	_ensure_home()
	if not sync_presence():
		brain.reset()
		global_position = home
		return
	var c := _find_cat()
	var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))
	var at_home := global_position.distance_to(home) < 0.6
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home, c != null and bool(c.get("in_safe_zone")))
	match s:
		ChaseBrain.State.CHASE:
			if c:
				move_towards_point(c.global_position, run_speed, delta)
				for body in hit_zone.get_overlapping_bodies():   # кот мог стоять в зоне с начала погони
					_on_hit_body(body)
			play(&"run")
		ChaseBrain.State.ALERT:
			if c:
				var to := c.global_position - global_position
				rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), 10.0 * delta)
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity(delta)
			move_and_slide()
			play(&"idle")
		ChaseBrain.State.RETURN:
			move_towards_point(home, walk_speed, delta)
			play(&"walk")
		_:
			_wander_t -= delta
			if _wander_t <= 0.0:
				var a := randf_range(0.0, TAU)
				_wander = home + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, 3.0)
				_wander_t = randf_range(2.0, 4.0)
			var left := move_towards_point(_wander, walk_speed, delta)
			play(&"walk" if left > 0.2 else &"idle")
```

## `scripts/hazards/park_person.gd`

```gdscript
class_name ParkPerson
extends HazardBase
## Общее для людей парка: модель с клипами, маршрут патруля, присутствие по фазе суток.

@export var patrol: Array = []        # точки маршрута [[x, z], ...] из раскладки; пусто — стоит у дома
var _patrol_i := 0
@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	patrol = hz.get("path", [])


func _ready() -> void:
	super()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["idle", "walk", "run", "work"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play(&"idle")


func present() -> bool:
	## Переопределяется: когда человек в парке (по фазе суток).
	return true


func play(clip: StringName) -> void:
	if _anim and _anim.has_animation(String(clip)) and _anim.current_animation != String(clip):
		_anim.play(String(clip), 0.2)


func walk_patrol(delta: float) -> void:
	if patrol.is_empty():
		move_towards_point(home, walk_speed, delta)
		play(&"walk" if global_position.distance_to(home) > 0.2 else &"idle")
		return
	var p: Array = patrol[_patrol_i]
	var target := Vector3(p[0], global_position.y, p[1])
	if move_towards_point(target, walk_speed, delta) < 0.3:
		_patrol_i = (_patrol_i + 1) % patrol.size()
	play(&"walk")


func sync_presence() -> bool:
	## Скрывает и выключает человека вне его фазы суток; возвращает «в парке ли он».
	var here := present()
	visible = here
	hit_zone.monitoring = here
	collision_layer = Layers.HAZARD if here else 0   # отсутствующий человек — не невидимая стена (ревью плана 9)
	return here
```

## `scripts/hazards/perception.gd`

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

## `scripts/hazards/pigeon_flock.gd`

```gdscript
class_name PigeonFlock
extends Node3D
## Стая голубей (спек этапа 2, раздел 3): бродят и клюют у точки; у кота с едой в зубах, идущего шагом ближе
## 1,5 м, один голубь выхватывает последнюю еду и улетает (перерыв 10 с); бегущий кот разгоняет стаю на 10 с.
## Ночью спят на ветках (стаи нет). Не бьют.

const PigeonModel := preload("res://assets/models/pigeon.glb")
const COUNT := 5
const WANDER := 1.5
const STEAL_DIST := 1.5
const SCATTER_DIST := 2.5
const COOLDOWN := 10.0
const WALK := 0.35

var mode: StringName = &"idle"      # idle | scattered | sleep
var cooldown_left := 0.0
var _rng := RandomNumberGenerator.new()
var _targets: Array[Vector3] = []
var _fly: Array[float] = []          # >0 — голубь в полёте (секунды до возвращения)


static func decide(dist: float, running: bool, mouth: int, hidden: bool, safe: bool, cooldown: float, night: bool) -> StringName:
	if night or hidden or safe:
		return &"none"
	if running and dist < SCATTER_DIST:
		return &"scatter"
	if cooldown <= 0.0 and mouth > 0 and dist < STEAL_DIST:
		return &"steal"
	return &"none"


func configure(_hz: Dictionary, _builder: Node3D) -> void:
	pass


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	for i in COUNT:
		var p := PigeonModel.instantiate() as Node3D
		p.name = "Pigeon%d" % i
		add_child(p)
		p.position = _random_spot()
		p.rotation.y = _rng.randf_range(0.0, TAU)
		Toon.apply(p, Toon.OUTLINE_CHARACTER, true)
		_targets.append(_random_spot())
		_fly.append(0.0)
		_play(p, "idle")


func pigeons() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for c in get_children():
		if String(c.name).begins_with("Pigeon"):
			out.append(c)
	return out


func _random_spot() -> Vector3:
	var a := _rng.randf_range(0.0, TAU)
	var r := _rng.randf_range(0.2, WANDER)
	return Vector3(cos(a) * r, 0.0, sin(a) * r)


func _play(p: Node3D, clip: String) -> void:
	var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(clip):
		ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		if ap.current_animation != clip:
			ap.play(clip)


func _physics_process(delta: float) -> void:
	var night := DayNight.is_night(get_tree())
	visible = not night
	if night:
		mode = &"sleep"
		return
	if mode == &"sleep":
		mode = &"idle"
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	var cat := get_tree().get_first_node_in_group("cat") as Node3D
	if cat:
		var d := Vector2(cat.global_position.x - global_position.x, cat.global_position.z - global_position.z).length()
		var action := decide(d, cat.get("state") == &"run", GameState.mouth.size(), bool(cat.get("hidden")),
			bool(cat.get("in_safe_zone")), cooldown_left, night)
		if action == &"steal":
			_steal()
		elif action == &"scatter" and mode != &"scattered":
			_scatter()
	if mode == &"scattered" and cooldown_left <= 0.0:
		mode = &"idle"
	_move_birds(delta)


func _steal() -> void:
	if GameState.steal_last() == null:
		return
	cooldown_left = COOLDOWN
	Sfx.play(&"coo", 0.15)
	var ps := pigeons()
	if not ps.is_empty():
		_fly[_rng.randi_range(0, ps.size() - 1)] = COOLDOWN


func _scatter() -> void:
	mode = &"scattered"
	cooldown_left = COOLDOWN
	Sfx.play(&"coo", 0.2)
	for i in _fly.size():
		_fly[i] = COOLDOWN


func _move_birds(delta: float) -> void:
	var ps := pigeons()
	for i in ps.size():
		var p := ps[i]
		if _fly[i] > 0.0:
			_fly[i] = maxf(_fly[i] - delta, 0.0)
			_play(p, "flap")
			var up := 3.0 if _fly[i] > COOLDOWN * 0.5 else -3.0   # взлёт, потом возвращение
			p.position += (Vector3(p.position.x, 0, p.position.z).normalized() * 1.5 + Vector3(0, up, 0)) * delta
			p.position.y = clampf(p.position.y, 0.0, 8.0)
			if _fly[i] <= 0.0:
				p.position = _random_spot()
			continue
		_play(p, "idle")
		var to := _targets[i] - p.position
		to.y = 0.0
		if to.length() < 0.05:
			_targets[i] = _random_spot()
		else:
			var step := to.normalized() * minf(WALK * delta, to.length())
			p.position += step
			p.rotation.y = lerp_angle(p.rotation.y, atan2(-to.x, -to.z), 6.0 * delta)
```

## `scripts/hazards/sprinkler.gd`

```gdscript
class_name Sprinkler
extends Node3D
## Дождеватель газона (спек этапа 2, раздел 3): цикл 20 с — 11 с стоит, 1 с булькает (предупреждение),
## 8 с поливает круг радиусом RADIUS. Кот под струёй мокнет (замедление, без урона). Работает и ночью.

const CYCLE := 20.0
const WARN_AT := 11.0
const ON_AT := 12.0
const RADIUS := 2.0
const WET_TIME := 4.0
const WATER := Color("#9FD3F0")

@export var time := 0.0          # сдвиг фазы задаёт раскладка, чтобы зоны не работали синхронно
var phase: StringName = &"off"
var _spray: CPUParticles3D
var _bubbles: CPUParticles3D

@onready var _zone: Area3D = $Zone
@onready var _model: Node3D = $Model


static func phase_at(t: float) -> StringName:
	var w := fposmod(t, CYCLE)
	if w >= ON_AT:
		return &"on"
	if w >= WARN_AT:
		return &"warn"
	return &"off"


func configure(hz: Dictionary, _builder: Node3D) -> void:
	time = float(hz.get("offset", 0.0))


func _ready() -> void:
	add_to_group("hazards")
	_zone.collision_layer = Layers.AREA
	_zone.collision_mask = Layers.CAT
	_zone.monitorable = false
	Toon.apply(_model, Toon.OUTLINE_FOOD)
	_spray = Effects.trail(self, WATER, 60)
	_spray.name = "Spray"
	_spray.local_coords = true
	_spray.direction = Vector3.UP
	_spray.spread = 75.0
	_spray.initial_velocity_min = 3.0
	_spray.initial_velocity_max = 4.2
	_spray.gravity = Vector3(0, -9.0, 0)
	_spray.lifetime = 0.9
	_spray.position = Vector3(0, 0.16, 0)
	_spray.emitting = false
	_bubbles = Effects.trail(self, WATER, 10)
	_bubbles.name = "Bubbles"
	_bubbles.local_coords = true
	_bubbles.direction = Vector3.UP
	_bubbles.spread = 20.0
	_bubbles.initial_velocity_min = 0.3
	_bubbles.initial_velocity_max = 0.6
	_bubbles.position = Vector3(0, 0.16, 0)
	_bubbles.emitting = false


func _physics_process(delta: float) -> void:
	time += delta
	var p := phase_at(time)
	if p != phase:
		phase = p
		_spray.emitting = phase == &"on"
		_bubbles.emitting = phase == &"warn"
		if phase == &"warn":
			Sfx.play(&"sprinkle", 0.1)
	if phase == &"on":
		for body in _zone.get_overlapping_bodies():
			if body.is_in_group("cat") and body.has_method("wet") and not bool(body.get("hidden")):
				body.call("wet", WET_TIME)
```

## `scripts/hazards/wasp.gd`

```gdscript
class_name Wasp
extends Node3D
## Оса: кружит вокруг точки (сладкая еда), жалит касанием, не преследует (спек 3.2).

@export var radius := 2.5
@export var angular_speed := 0.8
@export var height := 0.5
var anchor: Vector3
var ground := 0.0   # высота рельефа под якорем: оса летает на height над землёй (план 11)
var _anchored := false
var _angle := 0.0
var _t := 0.0

@onready var _hit: Area3D = $HitZone
@onready var _model: Node3D = $Model
@onready var _wing_l: Node3D = _model.find_child("wasp_wing_l", true, false)
@onready var _wing_r: Node3D = _model.find_child("wasp_wing_r", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	radius = float(hz.get("radius", radius))
	height = float(hz.get("height", height))


func _ready() -> void:
	add_to_group("hazards")
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.body_entered.connect(_on_body)
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	Effects.trail(self, Color("#5A5C6B"), 8)


func _physics_process(delta: float) -> void:
	if not _anchored:
		anchor = global_position   # позиция задаётся после add_child, поэтому якорь берём здесь
		ground = Terrain.surface_height(get_tree(), anchor.x, anchor.z, 0.0)
		_anchored = true
	_t += delta
	_angle += angular_speed * delta
	_place()
	if _wing_l and _wing_r:
		var flap := sin(_t * 60.0) * 0.6
		_wing_l.rotation.y = 0.25 + flap
		_wing_r.rotation.y = -0.25 - flap


func _place() -> void:
	var bob := sin(_t * 4.0) * 0.08
	if radius > 0.0:
		global_position = Vector3(anchor.x + cos(_angle) * radius, ground + height + bob, anchor.z + sin(_angle) * radius)
		rotation.y = PI - _angle   # головой (−Z модели) по касательной движения
	else:
		global_position = Vector3(anchor.x, ground + height + bob, anchor.z)


func _on_body(body: Node3D) -> void:
	if body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)
```

## `scripts/hazards/wave.gd`

```gdscript
class_name Wave
extends Node3D
## Волна на пляже (спек порта, раздел 3): каждые 14 с накат на 5 м за 3 с и откат за 3 с; за 1,5 с — пена и шум.

const PERIOD := 14.0
const RUN := 3.0
const REACH := 5.0
const FOAM_LEAD := 1.5


static func front_at(t: float) -> float:
	## Насколько вглубь пляжа дошла вода (метры от линии воды).
	var u := fposmod(t, PERIOD)
	if u <= RUN:
		return REACH * u / RUN   # линейно: игроку легко прочитать, докуда дойдёт вода
	if u <= 2.0 * RUN:
		return REACH * (1.0 - (u - RUN) / RUN)
	return 0.0


static func foam(t: float) -> bool:
	return fposmod(t, PERIOD) >= PERIOD - FOAM_LEAD

const THROW := 1.5
const WET := 4.0
const WaterShader := preload("res://assets/shaders/water.gdshader")

@export var width := 20.0          # вдоль линии воды (ось X)
@export var inland := -1.0         # куда суша от линии воды по оси Z: −1 — к −Z
@export var offset := 0.0          # сдвиг фазы, с
var hits := 0
var ground := 0.0
var _t := 0.0
var _hit_this_roll := false
var _foam_sounded := false
var _strip: MeshInstance3D
var _foam: CPUParticles3D


func configure(hz: Dictionary, _builder: Node3D) -> void:
	width = float(hz.get("width", width))
	inland = float(hz.get("inland", inland))
	offset = float(hz.get("offset", offset))


func _ready() -> void:
	add_to_group("hazards")
	_strip = MeshInstance3D.new()
	_strip.name = "Strip"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1, 1)
	_strip.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = WaterShader
	_strip.material_override = mat
	_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_strip)
	_foam = CPUParticles3D.new()
	_foam.name = "Foam"
	_foam.emitting = false
	_foam.amount = 40
	_foam.lifetime = 0.8
	_foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_foam.emission_box_extents = Vector3(width / 2.0, 0.02, 0.3)
	_foam.direction = Vector3.UP
	_foam.spread = 30.0
	_foam.initial_velocity_min = 0.3
	_foam.initial_velocity_max = 0.8
	_foam.gravity = Vector3(0, -2, 0)
	var dot := SphereMesh.new()
	dot.radius = 0.06
	dot.height = 0.12
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#F4F1E8")
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.material = fm
	_foam.mesh = dot
	add_child(_foam)
	ground = global_position.y
	_update_strip(0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	var t := _t + offset
	var u := fposmod(t, PERIOD)
	var front := front_at(t)
	_update_strip(front)
	var foaming := foam(t)
	_foam.emitting = foaming or front > 0.0
	_foam.position = Vector3(0, 0.05, inland * front)
	if foaming and not _foam_sounded:
		Sfx.play(&"wave")
		_foam_sounded = true
	if u < RUN:
		_check_cat(front)
	else:
		_hit_this_roll = false
		if not foaming:
			_foam_sounded = false


func _update_strip(front: float) -> void:
	_strip.visible = front > 0.05
	_strip.scale = Vector3(width, 1.0, maxf(front, 0.01))
	_strip.position = Vector3(0, 0.04, inland * front / 2.0)


func _check_cat(front: float) -> void:
	## Накат: кот на мокрой полосе отброшен вглубь пляжа на 1,5 м и мокрый — один раз за накат (спек порта, раздел 3).
	if _hit_this_roll:
		return
	var c := get_tree().get_first_node_in_group("cat") as Node3D
	if c == null or bool(c.get("hidden")):
		return
	var local := c.global_position - global_position
	var depth := local.z * inland   # насколько кот вглубь суши от линии воды
	if absf(local.x) > width / 2.0 or depth < -0.5 or depth > front or absf(local.y) > 0.8:
		return
	_hit_this_roll = true
	hits += 1
	c.global_position += Vector3(0, 0.1, inland * THROW)
	c.set("velocity", Vector3.ZERO)
	if c.has_method("wet"):
		c.call("wet", WET)
	if c.has_method("squash"):
		c.call("squash", 0.8, 0.15)
```

## `scripts/hideouts/hideout.gd`

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

## `scripts/main.gd`

```gdscript
extends Node3D
## Собирает мир, кота, камеру и реакции на события GameState.

signal faint_sequence_done

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")
const KILL_Y := -5.0   # ниже этого кот считается упавшим за край мира

var fade_time := 0.6
var autosave := true
var _cat: Cat
var _rig: CameraRig
var _spill: SpillSpawner
var _fade: ColorRect
@onready var hud: Hud = $Hud
@onready var shop_menu: ShopMenu = $ShopMenu
@onready var album_menu: AlbumMenu = $AlbumMenu
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	SaveGame.load_now()
	for y in get_tree().get_nodes_in_group("yarn"):
		if GameState.is_yarn_taken(y.key):
			y.queue_free()   # собранные в прошлых сессиях клубочки не возвращаются
	Toon.apply($DistrictYard, Toon.OUTLINE_NONE)
	SurfaceTextures.apply($DistrictYard)   # асфальт, плитка, штукатурка (спек 2.9)
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
	GameState.food_eaten.connect(_on_food_eaten)
	GameState.cat_petted.connect(func(spilled: Array) -> void:
		if not spilled.is_empty():
			_spill.spill_around(_cat.global_position, spilled))
	GameState.cat_fainted.connect(_on_cat_fainted)
	for c in get_tree().get_nodes_in_group("hazards"):
		if c.has_signal("bell"):
			c.bell.connect(func() -> void:
				hud.flash_bell()
				Sfx.play(&"bell"))
	shop_menu.closed.connect(close_shop)
	album_menu.closed.connect(func() -> void: _set_paused(false))
	pause_menu.resumed.connect(func() -> void: _set_paused(false))
	pause_menu.reset_requested.connect(reset_progress)
	for g in get_tree().get_nodes_in_group("gates"):
		g.opened.connect(func() -> void: hud.flash_bell(g.label, 3.0))
	for sig in [GameState.album_changed, GameState.satiety_changed, GameState.yarn_changed, GameState.upgrade_bought, GameState.skin_changed]:
		sig.connect(_on_progress_changed.unbind(1))
	Mouse.capture(true)


func _physics_process(_delta: float) -> void:
	if _cat and _cat.global_position.y < KILL_Y:
		fall_respawn()


func fall_respawn() -> void:
	## Падение за край мира: назад к будке без потери сердечка; еда из зубов теряется.
	GameState.spill()
	_cat.teleport(respawn_position())
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)


func _on_progress_changed() -> void:
	if autosave:
		SaveGame.save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave:
		SaveGame.save_now()


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


func _on_food_eaten(items: Array) -> void:
	Sfx.play(&"eat")
	var top: int = Rarity.Tier.COMMON
	for f in items:
		top = maxi(top, f.tier)
	Effects.burst(self, _cat.global_position + Vector3(0, 0.25, 0), Rarity.COLORS[top])
	Effects.hearts(self, _cat.global_position + Vector3(0, 0.35, 0))


func _on_cat_hit(spilled: Array) -> void:
	Effects.burst(self, _cat.global_position + Vector3(0, 0.3, 0), Effects.HIT_COLOR, 16, 0.06, 1.5)
	if spilled.is_empty() or GameState.hearts == 0:
		return   # при обмороке еда потеряна (спек 3.2), рассыпать нечего
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


func respawn_position() -> Vector3:
	var shop := get_tree().get_first_node_in_group("yarn_shop")
	if shop:
		return shop.respawn_position()
	return $DistrictYard/Spawn.global_position


func respawn_cat() -> void:
	for h in get_tree().get_nodes_in_group("hazards"):
		if h.has_method("reset_pursuit"):
			h.call("reset_pursuit")
	_cat.teleport(respawn_position())
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	GameState.revive()


func on_interact_pressed() -> void:
	if _cat and _cat.in_safe_zone and not _cat.hidden and not shop_menu.is_open and not get_tree().paused:
		open_shop()


func open_shop() -> void:
	Mouse.capture(false)
	_cat.input_enabled = false
	var shop := get_tree().get_first_node_in_group("yarn_shop")
	if shop:
		_rig.shop_view_point = shop.view_position()
		_rig.use_shop_point = true
	_rig.shop_view = true
	hud.visible = false
	shop_menu.open()


func close_shop() -> void:
	if shop_menu.is_open:
		shop_menu.close()
		return
	_cat.input_enabled = true
	_rig.shop_view = false
	hud.visible = true
	Mouse.capture(true)


func on_back_pressed() -> void:
	if shop_menu.is_open:
		close_shop()
	elif album_menu.is_open:
		toggle_album()
	else:
		toggle_pause()


func on_album_pressed() -> void:
	if not shop_menu.is_open and not pause_menu.is_open:
		toggle_album()


func _set_paused(on: bool) -> void:
	get_tree().paused = on
	Mouse.capture(not on)


func toggle_album() -> void:
	if album_menu.is_open:
		album_menu.close()
	else:
		_set_paused(true)
		album_menu.open()


func toggle_pause() -> void:
	if pause_menu.is_open:
		pause_menu.close()
	else:
		_set_paused(true)
		pause_menu.open()


func reset_progress() -> void:
	autosave = false   # reset() шлёт сигналы прогресса, автосохранение тут же записало бы нули
	GameState.reset()
	SaveGame.clear()
	autosave = true
	if pause_menu.is_open:
		pause_menu.close()
	_set_paused(false)
	respawn_cat()
```

## `scripts/player/camera_rig.gd`

```gdscript
class_name CameraRig
extends Node3D
## Третье лицо: пружина 1,8 м, взгляд с высоты 0,6 м, наклон −14°, сглаживание 8/с (спек 2.3).
## Мышь и правый стик крутят yaw, наклон фиксирован. У стены кот становится прозрачным, не исчезает.

const HEIGHT := 0.6
const DISTANCE := 1.8
const SMOOTH := 8.0
const HIDE_BELOW := 0.9
const YAW_SPEED := 2.2
const PITCH_DEG := -14.0
const SHOP_OFFSET := Vector3(1.4, 0.6, 1.4)   # витрина: камера спереди-сбоку кота
const CROUCH_HEIGHT := 0.3
const MOUSE_SENS := 0.004   # рад на пиксель
const FADE_FULL := 0.3      # при такой длине пружины кот почти прозрачен (0,15)

@export var target: Node3D
var crouch := false
var shop_view := false
var shop_view_point := Vector3.ZERO   # если use_shop_point, камера едет сюда, иначе target + SHOP_OFFSET
var use_shop_point := false
var _yaw := 0.0
var shake_left := 0.0
var _shake_amp := 0.05
var _shake_time := 0.2
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
	if shake_left > 0.0:
		shake_left = maxf(shake_left - delta, 0.0)
		var k := _shake_amp * (shake_left / _shake_time)
		_arm.position = Vector3(randf_range(-k, k), randf_range(-k, k), 0.0)
	else:
		_arm.position = Vector3.ZERO
	if shop_view:
		target.visible = true   # витрина: кот виден, даже если пружина до этого прятала его у стены
		_set_target_fade(1.0)
		var want := shop_view_point if use_shop_point else target.global_position + SHOP_OFFSET
		global_position = global_position.lerp(want, 1.0 - exp(-SMOOTH * delta))
		look_at(target.global_position + Vector3(0, 0.15, 0), Vector3.UP)
		_arm.spring_length = 0.0
		return
	_arm.spring_length = DISTANCE
	rotation = Vector3(0, _yaw, 0)
	var goal := target.global_position + Vector3(0, CROUCH_HEIGHT if crouch else HEIGHT, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-SMOOTH * delta))
	apply_arm_length(_arm.get_hit_length())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_by_pixels((event as InputEventMouseMotion).relative.x)


func shake(amplitude := 0.05, seconds := 0.2) -> void:
	## Тряска камеры при ударе: смещение пружины шумом, затухает за seconds.
	_shake_amp = amplitude
	_shake_time = seconds
	shake_left = seconds


func turn_by_pixels(dx: float) -> void:
	_yaw -= dx * MOUSE_SENS


func apply_arm_length(length: float) -> void:
	# Камера упёрлась в стену: кот не исчезает, а становится прозрачным (замечание ревью плана 1).
	_set_target_fade(clampf((length - FADE_FULL) / (HIDE_BELOW - FADE_FULL), 0.15, 1.0))


func _set_target_fade(alpha: float) -> void:
	if target.has_method("set_fade"):
		target.call("set_fade", alpha)
	else:
		target.visible = alpha > 0.5


func yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)
```

## `scripts/player/cat.gd`

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
const RUN_DUST_EVERY := 0.25
const FLASH_COLOR := Color.WHITE
const WET_SLOW := 0.6   # мокрый кот (дождеватель парка)

var camera_rig: CameraRig
var current_hideout: Area3D
var hidden := false
var in_safe_zone := false   # внутри будки пряжи: удары не проходят, собака не видит
var input_enabled := true   # false, пока открыт экран магазина
var stunned_left := 0.0
var invulnerable_left := 0.0
var drowning_left := 0.0   # кот тонет: потом возврат на берег (вода, план 12)
var _shore := Vector3.ZERO
var face := CatFace.new()   # выражения глаз, переключает меши eyes_* модели
var fade := 1.0   # 1 = непрозрачен; значением владеет камера (set_fade), скин его не трогает
var was_on_floor := true
var wet_left := 0.0
var petted_left := 0.0   # ребёнок гладит: кот стоит, не ранен
var _drips: CPUParticles3D
var flashing := false
var _run_dust_t := 0.0
var _squash: Tween
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
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("eyes_") or mi.name == "whiskers" or mi.name == "eyelids":
			(mi as MeshInstance3D).material_overlay = null   # обводка на глазах — рамка, на усах и веках — клякса
	face.bind(_model)
	_apply_skin(GameState.skin)
	GameState.skin_changed.connect(_apply_skin)
	for clip in LOOPING_CLIPS:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var skel := _model.find_child("Skeleton3D", true, false)
	if skel and skel.find_child("HeadScaler", false, false) == null:
		var hs := HeadScaler.new()
		hs.name = "HeadScaler"
		skel.add_child(hs)
		var ls := LegScaler.new()
		ls.name = "LegScaler"
		skel.add_child(ls)
		var tw := TailWiggle.new()
		tw.name = "TailWiggle"
		skel.add_child(tw)
	if camera_rig:
		(camera_rig.get_node("SpringArm3D") as SpringArm3D).add_excluded_object(get_rid())
	play_clip(&"idle")


func _physics_process(delta: float) -> void:
	face.update(delta, stunned_left > 0.0)
	if wet_left > 0.0:
		wet_left = maxf(wet_left - delta, 0.0)
		if _drips:
			_drips.emitting = wet_left > 0.0
	stunned_left = maxf(stunned_left - delta, 0.0)
	invulnerable_left = maxf(invulnerable_left - delta, 0.0)
	petted_left = maxf(petted_left - delta, 0.0)
	if drowning_left > 0.0:
		drowning_left = maxf(drowning_left - delta, 0.0)
		velocity = Vector3(0, -0.4, 0)   # медленно уходит под воду
		global_position += velocity * delta
		if drowning_left == 0.0:
			teleport(_shore)
			if camera_rig:
				camera_rig.global_position = global_position + Vector3(0, CameraRig.HEIGHT, 0)   # камера не летит через воду
		return
	if stunned_left > 0.0 or petted_left > 0.0:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		return
	if not input_enabled:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		state = CatMotion.pick_state(velocity, is_on_floor(), false)
		_after_move(delta)
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
	velocity = CatMotion.step(velocity, dir, running, is_on_floor(), jump, delta, GameState.speed_mult * speed_factor())
	move_and_slide()
	if dir.length() > 0.0:
		var target_yaw := atan2(-dir.x, -dir.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, TURN_SPEED * delta)
	state = CatMotion.pick_state(velocity, is_on_floor(), running, GameState.speed_mult * speed_factor())
	_after_move(delta)


func _after_move(delta: float) -> void:
	## Приземление: сплющить и пыль; прыжок: вытянуться; бег: пыль каждые 0,25 с.
	var on_floor := is_on_floor()
	if on_floor and not was_on_floor:
		squash(0.8, 0.12)
		Effects.dust(get_parent(), global_position)
	elif not on_floor and was_on_floor and velocity.y > 1.0:
		squash(1.15, 0.1)
	was_on_floor = on_floor
	if state == &"run" and on_floor:
		_run_dust_t += delta
		if _run_dust_t >= RUN_DUST_EVERY:
			_run_dust_t = 0.0
			Effects.dust(get_parent(), global_position, 6)
	else:
		_run_dust_t = 0.0


func squash(scale_y: float, duration := 0.12) -> void:
	## Сквош-стретч модели твином, объём сохраняется (спек 2.8).
	if _squash:
		_squash.kill()
	_model.scale = Vector3(1.0 / sqrt(scale_y), scale_y, 1.0 / sqrt(scale_y))
	_squash = create_tween()
	_squash.tween_property(_model, "scale", Vector3.ONE, duration * 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func flash(seconds := 0.1) -> void:
	## Вспышка белым при ударе: только три материала скина; после — цвета надетого скина и текущая прозрачность.
	flashing = true
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m and CatSkin.ROLE_BY_MATERIAL.has(m.resource_name):
				m.albedo_color = Color(FLASH_COLOR, m.albedo_color.a)
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		flashing = false
		_apply_skin(GameState.skin))


func _apply_skin(id: StringName) -> void:
	var skin := SkinCatalog.get_by_id(id)
	if skin == null:
		skin = SkinCatalog.get_by_id(GameState.DEFAULT_SKIN)   # битый сейв: не оставлять кота белым после вспышки
	if skin and not flashing:   # во время вспышки скин перекрасится по её концу
		CatSkin.apply(_model, skin)
		if fade < 1.0:
			_apply_fade()   # перекраска сбрасывает альфу, прозрачность у стены должна остаться


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
	face.cheer()
	ate.emit(items)
	return true


func take_hit(from: Vector3) -> void:
	if drowning_left > 0.0:
		return   # в воде сердечко не снимается (спек порта, раздел 2)
	if not _hit_reaction(from):
		return
	GameState.take_hit()


func take_peck(from: Vector3) -> void:
	## Чайка (спек порта, раздел 3): удар, последняя еда унесена, остальное остаётся в зубах.
	if drowning_left > 0.0:
		return
	if not _hit_reaction(from):
		return
	GameState.peck()


func _hit_reaction(from: Vector3) -> bool:
	## Общая реакция на удар; false — удар не прошёл (неуязвим, оглушён, спрятан, в будке).
	if invulnerable_left > 0.0 or stunned_left > 0.0 or hidden or in_safe_zone:
		return false
	Sfx.play(&"hit")   # один вызов на реальный удар: повторные касания блокирует неуязвимость
	Sfx.play(&"meow", 0.12)
	flash()
	if camera_rig:
		camera_rig.shake()
	var away := global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		away = _model.global_transform.basis.z   # назад относительно взгляда
	velocity = away.normalized() * KNOCKBACK_SPEED + Vector3.UP * KNOCKBACK_UP
	stunned_left = STUN_TIME
	invulnerable_left = INVULNERABLE_TIME
	state = &"hit"
	hit_taken.emit(from)
	return true


func set_fade(alpha: float) -> void:
	if is_equal_approx(alpha, fade):
		return
	fade = alpha
	_apply_fade()


func _apply_fade() -> void:
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			_fade_material(m3.get_surface_override_material(i) as StandardMaterial3D)
		var outline := m3.material_overlay as ShaderMaterial
		if outline:
			outline.set_shader_parameter("alpha", fade)


func _fade_material(mat: StandardMaterial3D) -> void:
	if mat == null:
		return
	mat.albedo_color.a = fade
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if fade >= 0.999 else BaseMaterial3D.TRANSPARENCY_ALPHA
	# Полупрозрачное тело всё равно пишет глубину: иначе дальняя сторона hull-обводки рисуется поверх кота («рентген»).
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY if fade >= 0.999 else BaseMaterial3D.DEPTH_DRAW_ALWAYS


func pet(seconds: float) -> bool:
	if drowning_left > 0.0:
		return false
	## Поймал ребёнок: 2 с стоим довольные, еда выпала, сердечко цело; потом неуязвимость, как после удара.
	if petted_left > 0.0 or invulnerable_left > 0.0 or hidden or in_safe_zone:
		return false
	petted_left = seconds
	invulnerable_left = seconds + INVULNERABLE_TIME
	velocity = Vector3.ZERO
	face.cheer()
	face.happy_left = seconds
	state = &"idle"
	Sfx.play(&"meow", 0.2)
	GameState.pet()
	return true


func wet(seconds: float) -> void:
	## Намок под дождевателем: замедление ×0,6; повторное намокание продлевает до большего срока, не складывается.
	wet_left = maxf(wet_left, seconds)
	if _drips == null:
		_drips = Effects.trail(self, Color("#9FD3F0"), 8)
		_drips.name = "Drips"
		_drips.position = Vector3(0, 0.2, 0)
	_drips.emitting = true


func speed_factor() -> float:
	return WET_SLOW if wet_left > 0.0 else 1.0


func threaten() -> void:
	## Собака насторожилась или гонится рядом: зовётся каждый физический кадр, пока угроза есть.
	face.threaten()


func cheer() -> void:
	face.cheer()


func drown(shore: Vector3) -> bool:
	## Упал в воду (спек порта, раздел 2): 1 с тонет, еда из зубов потеряна, сердечко цело; затем ближайший берег.
	if drowning_left > 0.0:
		return false
	drowning_left = 1.0
	_shore = shore
	unhide()
	GameState.spill()   # не рассыпается — уходит на дно
	Sfx.play(&"splash")
	Effects.burst(get_parent(), global_position + Vector3(0, 0.2, 0), Color("#2F9CCF"), 28, 0.06, 2.5)
	squash(0.6, 0.2)
	state = &"idle"   # не продолжать клип бега под водой
	return true


func teleport(pos: Vector3) -> void:
	unhide()
	global_position = pos
	velocity = Vector3.ZERO
	stunned_left = 0.0
	invulnerable_left = INVULNERABLE_TIME   # после возрождения дать прийти в себя
	wet_left = 0.0
	petted_left = 0.0
	drowning_left = 0.0
	if _drips:
		_drips.emitting = false
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

## `scripts/player/cat_face.gd`

```gdscript
class_name CatFace
extends RefCounted
## Выражения глаз (спек 2.4): оглушён > испуг > довольный > обычные.
## Переключает видимость мешей eyes_* из cat.glb; сам узлов не создаёт.

const SETS: Array[StringName] = [&"normal", &"scared", &"happy", &"dizzy", &"blink"]
const HAPPY_TIME := 1.0
const BLINK_TIME := 0.12
const BLINK_MIN := 3.0
const BLINK_MAX := 5.0
const THREAT_TIME := 0.4   # собака обновляет угрозу каждый физический кадр; без обновлений испуг гаснет

var expression: StringName = &"normal"
var happy_left := 0.0
var threat_left := 0.0
var blink_in := randf_range(BLINK_MIN, BLINK_MAX)   # секунд до следующего моргания
var blink_left := 0.0
var _meshes := {}   # StringName -> MeshInstance3D


func bind(model: Node) -> int:
	_meshes.clear()
	for mi in model.find_children("eyes_*", "MeshInstance3D", true, false):
		_meshes[StringName(String(mi.name).trim_prefix("eyes_"))] = mi
	_show(&"normal")
	return _meshes.size()


func threaten() -> void:
	threat_left = THREAT_TIME


func cheer() -> void:
	happy_left = HAPPY_TIME


func update(delta: float, stunned: bool) -> StringName:
	happy_left = maxf(happy_left - delta, 0.0)
	threat_left = maxf(threat_left - delta, 0.0)
	blink_in -= delta
	if blink_in <= 0.0:
		blink_left = BLINK_TIME
		blink_in = randf_range(BLINK_MIN, BLINK_MAX)
	blink_left = maxf(blink_left - delta, 0.0)
	var want: StringName = &"normal"
	if stunned:
		want = &"dizzy"
	elif threat_left > 0.0:
		want = &"scared"
	elif happy_left > 0.0:
		want = &"happy"
	if want == &"normal" and blink_left > 0.0:
		want = &"blink"   # моргание только поверх обычного выражения
	if want != expression:
		_show(want)
	return expression


func _show(which: StringName) -> void:
	expression = which
	for key in _meshes:
		(_meshes[key] as MeshInstance3D).visible = key == which
```

## `scripts/player/cat_motion.gd`

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


static func step(velocity: Vector3, direction: Vector3, running: bool, on_floor: bool, jump: bool, delta: float, speed_mult := 1.0) -> Vector3:
	var speed := (RUN_SPEED if running else WALK_SPEED) * speed_mult
	var target := direction * speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(Vector3(target.x, 0.0, target.z), ACCEL * delta)
	var vy := velocity.y
	if on_floor:
		vy = JUMP_VELOCITY if jump else 0.0
	else:
		vy -= GRAVITY * delta
	return Vector3(horizontal.x, vy, horizontal.z)


static func pick_state(velocity: Vector3, on_floor: bool, running: bool, speed_mult := 1.0) -> StringName:
	if not on_floor and absf(velocity.y) >= SLOPE_WOBBLE:
		return &"jump"
	var h := Vector2(velocity.x, velocity.z).length()
	if h < 0.1:
		return &"idle"
	if running and h > WALK_SPEED * speed_mult + 0.1:
		return &"run"
	return &"walk"
```

## `scripts/player/head_scaler.gd`

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

## `scripts/player/leg_scaler.gd`

```gdscript
class_name LegScaler
extends SkeletonModifier3D
## «Чиби»-лапы поверх любого клипа (спек 2.8): верхние кости лап равномерно в 0,8, корень
## опускается на 20 % высоты ноги (из rest-позы), чтобы стопы остались на земле.
## Ось «вверх» берётся из трансформа скелета: у кота локальная Y скелета идёт вдоль тела, верх — +Z.

@export var upper_bones: Array[StringName] = [&"Bone.014", &"Bone.017", &"Bone.008", &"Bone.011"]
@export var foot_bones: Array[StringName] = [&"Bone.016", &"Bone.019", &"Bone.010", &"Bone.013"]
@export var root_bone: StringName = &"Bone"
@export var leg_scale := 0.8
var drop := 0.0            # единицы скелета, вдоль up_local
var up_local := Vector3.UP  # мировой верх в локальных осях скелета


func _ready() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	up_local = (skel.global_transform.basis.inverse() * Vector3.UP).normalized()
	var hip := 0.0   # среднее начало верхних костей лап: таз (Bone) выше суставов, его брать нельзя
	var n := 0
	for b in upper_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			hip += skel.get_bone_global_rest(i).origin.dot(up_local)
			n += 1
	var foot := INF
	for b in foot_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			foot = minf(foot, skel.get_bone_global_rest(i).origin.dot(up_local))
	if foot < INF and n > 0:
		drop = (hip / n - foot) * (1.0 - leg_scale)


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	for b in upper_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			skel.set_bone_pose_scale(i, Vector3.ONE * leg_scale)
	var root := skel.find_bone(root_bone)
	if root >= 0:
		skel.set_bone_pose_position(root, skel.get_bone_pose_position(root) - up_local * drop)
```

## `scripts/player/tail_wiggle.gd`

```gdscript
class_name TailWiggle
extends SkeletonModifier3D
## Хвост покачивается поверх клипа: синус по костям со сдвигом фазы (спек 2.8).

@export var bones: Array[StringName] = [&"Bone.004", &"Bone.005", &"Bone.006", &"Bone.007"]
@export var amplitude := 0.12   # рад (≈7°)
@export var frequency := 2.5    # Гц
@export var phase_step := 0.7
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	for k in bones.size():
		var i := skel.find_bone(bones[k])
		if i < 0:
			continue
		var a := amplitude * sin(TAU * frequency * _t + k * phase_step)
		skel.set_bone_pose_rotation(i, skel.get_bone_pose_rotation(i) * Quaternion(Vector3(0, 0, 1), a))
```

## `scripts/tools/look_at_target.gd`

```gdscript
extends Camera3D
## Смотрит на точку target_point после входа в дерево.

@export var target_point := Vector3(0, 0.15, 0)

func _ready() -> void:
	look_at(target_point, Vector3.UP)
```

## `scripts/ui/album_menu.gd`

```gdscript
class_name AlbumMenu
extends CanvasLayer
## Альбом вкусняшек: сетка карточек по редкостям (спек 2.6, 3.4).

signal closed

const LOCKED_ALPHA := 0.4

var is_open := false
var _cards: Array[Control] = []

@onready var _grid: GridContainer = $Panel/Margin/VBox/Grid
@onready var _close: Button = $Panel/Margin/VBox/Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var foods := FoodCatalog.all().duplicate()
	foods.sort_custom(func(a: FoodDef, b: FoodDef) -> bool: return a.tier < b.tier or (a.tier == b.tier and a.id < b.id))
	for f in foods:
		_grid.add_child(_make_card(f))
	_close.pressed.connect(close)


func _make_card(f: FoodDef) -> Control:
	var card := VBoxContainer.new()   # карточка — сам контейнер: Rarity/Name/Count его прямые дети
	card.name = String(f.id)
	card.custom_minimum_size = Vector2(150, 90)
	var strip := ColorRect.new()
	strip.name = "Rarity"
	strip.color = Rarity.COLORS[f.tier]
	strip.custom_minimum_size = Vector2(0, 8)
	card.add_child(strip)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(64, 64)   # 20 карточек (план 13) — 5 колонок по 4 ряда в окне 720
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = f.icon()
	card.add_child(icon)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	card.add_child(name_label)
	var count := Label.new()
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 15)
	card.add_child(count)
	card.set_meta("food", f)
	_cards.append(card)
	return card


func open() -> void:
	is_open = true
	visible = true
	refresh()
	_close.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


func cards() -> Array[Control]:
	return _cards


func refresh() -> void:
	for card in _cards:
		var f: FoodDef = card.get_meta("food")
		var n: int = GameState.album.get(f.id, 0)
		(card.get_node("Name") as Label).text = f.display_name if n > 0 else "???"
		(card.get_node("Count") as Label).text = "×%d" % n
		card.modulate.a = 1.0 if n > 0 else LOCKED_ALPHA
		(card.get_node("Icon") as TextureRect).self_modulate = Color.WHITE if n > 0 else Color(0.2, 0.2, 0.25)   # серый силуэт (спек 2.6)
```

## `scripts/ui/hud.gd`

```gdscript
class_name Hud
extends CanvasLayer
## HUD на белых плашках темы: сердечки, сытость, слоты зубов, клубочки, цель сессии, вспышка звонка (спек 2.6).

const HEART_ICON := "res://assets/images/ui/heart.png"
const YARN_ICON := "res://assets/images/ui/yarn.png"
const HEART_LOST_ALPHA := 0.3
const PHASE_ICONS := {&"day": "res://assets/images/ui/sun.png", &"evening": "res://assets/images/ui/sunset.png", &"night": "res://assets/images/ui/moon.png", &"morning": "res://assets/images/ui/sunset.png"}
const MAX_MOUTH := 5   # максимум после улучшений магазина

@onready var _hearts: HBoxContainer = %Hearts
@onready var _yarn_icon: TextureRect = %YarnIcon
@onready var _satiety: ProgressBar = %Satiety
@onready var _satiety_label: Label = %SatietyLabel
@onready var _yarn: Label = %Yarn
@onready var _mouth: HBoxContainer = %Mouth
@onready var _goal: Label = %Goal
@onready var _bell: Label = %Bell
@onready var _bell_panel: PanelContainer = %BellPanel
@onready var _phase_icon: TextureRect = %PhaseIcon
@onready var _phase_bar: ProgressBar = %PhaseBar
var _day_night: DayNight


func _ready() -> void:
	_satiety.max_value = GameState.SATIETY_GATE
	_yarn_icon.texture = _icon(YARN_ICON)
	_bell_panel.visible = false
	for i in MAX_MOUTH:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 64)
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.name = "Name"
		label.visible = false   # текст остаётся для тестов и подписи, в кадре — иконка еды
		row.add_child(label)
		panel.add_child(row)
		_mouth.add_child(panel)
	GameState.hearts_changed.connect(_on_hearts)
	GameState.mouth_changed.connect(_on_mouth)
	GameState.satiety_changed.connect(_on_satiety)
	GameState.goal_changed.connect(_on_goal)
	GameState.goal_completed.connect(_on_goal_completed)
	GameState.yarn_changed.connect(_on_yarn)
	GameState.upgrade_bought.connect(func(_id: StringName) -> void: _refresh_slots())
	_refresh_slots()
	_on_yarn(GameState.yarn)
	_on_hearts(GameState.hearts, GameState.max_hearts)
	_on_mouth(GameState.mouth)
	_on_satiety(GameState.satiety)
	_on_goal(GameState.goal_done, GameState.goal_target)
	_on_phase(&"day")
	_bind_day_night()


func _bind_day_night() -> void:
	_day_night = get_tree().get_first_node_in_group("day_night") as DayNight
	if _day_night and not _day_night.phase_changed.is_connected(_on_phase):
		_day_night.phase_changed.connect(_on_phase)
		_on_phase(_day_night.phase)
	(_phase_icon.get_parent().get_parent() as Control).visible = _day_night != null


func _process(_delta: float) -> void:
	if _day_night == null or not is_instance_valid(_day_night):
		_bind_day_night()   # ленивая привязка: Lighting мог появиться позже HUD или быть пересоздан
		if _day_night == null:
			return
	_phase_bar.value = DayCycle.phase_progress(_day_night.time)


func _on_phase(phase: StringName) -> void:
	_phase_icon.texture = _icon(PHASE_ICONS.get(phase, PHASE_ICONS[&"day"]))


func hearts_text() -> String:
	## Состояние сердечек для тестов: «осталось/всего» (на экране — иконки).
	var full := 0
	for h in _hearts.get_children():
		if (h as TextureRect).modulate.a > 0.9:
			full += 1
	return "%d/%d" % [full, _hearts.get_child_count()]


static func _icon(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func mouth_names() -> Array[String]:
	var out: Array[String] = []
	for panel in _mouth.get_children():
		if panel.visible:
			out.append((panel.find_child("Name", true, false) as Label).text)
	return out


func _refresh_slots() -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		panels[i].visible = i < GameState.mouth_capacity


func yarn_text() -> String:
	return _yarn.text


func _on_yarn(count: int) -> void:
	_yarn.text = "%d" % count


func flash_bell(text := "🔔 Велосипед!", seconds := 2.0) -> void:
	_bell.text = text
	_bell_panel.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _bell_panel.visible = false)


func _on_hearts(hearts: int, max_hearts: int) -> void:
	while _hearts.get_child_count() < max_hearts:
		var t := TextureRect.new()
		t.custom_minimum_size = Vector2(34, 34)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture = _icon(HEART_ICON)
		_hearts.add_child(t)
	while _hearts.get_child_count() > max_hearts:
		var last := _hearts.get_child(_hearts.get_child_count() - 1)
		_hearts.remove_child(last)
		last.free()
	for i in _hearts.get_child_count():
		(_hearts.get_child(i) as TextureRect).modulate.a = 1.0 if i < hearts else HEART_LOST_ALPHA


func _on_mouth(items: Array) -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		var label := panels[i].find_child("Name", true, false) as Label
		label.text = items[i].display_name if i < items.size() else ""
		(panels[i].find_child("Icon", true, false) as TextureRect).texture = items[i].icon() if i < items.size() else null


func satiety_label_text() -> String:
	return _satiety_label.text


func _on_satiety(value: int) -> void:
	# Ближайшая цель сытости: кафе (10), потом парк (25).
	if value < GameState.SATIETY_GATE:
		_satiety.max_value = GameState.SATIETY_GATE
		_satiety_label.text = "Сытость %d/%d" % [value, GameState.SATIETY_GATE]
	elif value < GameState.PARK_GATE:
		_satiety.max_value = GameState.PARK_GATE
		_satiety_label.text = "До парка %d/%d" % [value, GameState.PARK_GATE]
	else:
		_satiety.max_value = GameState.PARK_GATE
		_satiety_label.text = "Парк открыт"
	_satiety.value = value


func _on_goal(done: int, target: int) -> void:
	_goal.text = "Открой новых карточек: %d/%d" % [done, target]


func _on_goal_completed(target: int) -> void:
	flash_bell("🎉 Цель выполнена: %d карточек!" % target, 3.0)
```

## `scripts/ui/menu_input.gd`

```gdscript
class_name MenuInput
extends Node
## Опрашивает клавиши меню (E в будке, Tab, Esc, B геймпада) и дёргает Main. Работает и на паузе.

@onready var _main: Node = get_parent()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_main.call("on_back_pressed")
	elif Input.is_action_just_pressed("ui_cancel") and _menu_open():
		_main.call("on_back_pressed")   # B на геймпаде закрывает магазин и альбом (Esc ловит ветка выше)
	elif Input.is_action_just_pressed("album"):
		_main.call("on_album_pressed")
	elif Input.is_action_just_pressed("eat"):
		_main.call("on_interact_pressed")


func _menu_open() -> bool:
	return bool(_main.get("shop_menu").is_open) or bool(_main.get("album_menu").is_open)
```

## `scripts/ui/pause_menu.gd`

```gdscript
class_name PauseMenu
extends CanvasLayer
## Пауза: продолжить, сбросить прогресс, выйти.

signal resumed
signal reset_requested

var is_open := false

@onready var _continue: Button = $Panel/Margin/VBox/Continue
@onready var _reset: Button = $Panel/Margin/VBox/ResetProgress
@onready var _quit: Button = $Panel/Margin/VBox/Quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_continue.pressed.connect(close)
	_reset.pressed.connect(func() -> void: reset_requested.emit())
	_quit.pressed.connect(func() -> void: get_tree().quit())


func open() -> void:
	is_open = true
	visible = true
	_continue.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	resumed.emit()
```

## `scripts/ui/shop_menu.gd`

```gdscript
class_name ShopMenu
extends CanvasLayer
## Экран магазина пряжи: список товаров, баланс, покупка (спек 3.5).

signal closed

var is_open := false
var _buttons: Array[Button] = []
var _yarn_icon: Texture2D = load("res://assets/images/ui/yarn.png") if ResourceLoader.exists("res://assets/images/ui/yarn.png") else null

@onready var _list: VBoxContainer = $Panel/Margin/VBox/List
@onready var _yarn: Label = $Panel/Margin/VBox/Yarn
@onready var _close: Button = $Panel/Margin/VBox/Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for item in ShopCatalog.all():
		var b := Button.new()
		b.name = String(item.id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.expand_icon = true
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_on_buy.bind(item))
		_list.add_child(b)
		_buttons.append(b)
	_close.pressed.connect(close)
	GameState.yarn_changed.connect(func(_c: int) -> void: refresh())
	GameState.hearts_changed.connect(func(_h: int, _m: int) -> void: refresh())
	GameState.skin_changed.connect(func(_id: StringName) -> void: refresh())
	refresh()


func open() -> void:
	is_open = true
	visible = true
	refresh()
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


func item_buttons() -> Array[Button]:
	return _buttons


func yarn_text() -> String:
	return _yarn.text


func refresh() -> void:
	_yarn.text = "Клубочков: %d" % GameState.yarn
	var items := ShopCatalog.all()
	for i in _buttons.size():
		var item := items[i]
		var owned := item.kind != "refill" and GameState.owns(item.id)
		if item.kind == "skin" and owned:
			# Купленный скин можно переодевать бесплатно.
			var worn := GameState.skin == item.skin_id
			_buttons[i].text = "%s — %s" % [item.display_name, "надет" if worn else "надеть"]
			_buttons[i].icon = null
			_buttons[i].disabled = worn
			continue
		_buttons[i].text = "%s — куплено" % item.display_name if owned else "%s — %d" % [item.display_name, item.price]
		_buttons[i].icon = null if owned else _yarn_icon   # цена в клубочках: иконка справа от числа
		_buttons[i].disabled = owned or not GameState.can_buy(item)


func _on_buy(item: ShopItem) -> void:
	if item.kind == "skin" and GameState.owns(item.id):
		GameState.select_skin(item.skin_id)
		refresh()
		return
	if GameState.buy(item):
		refresh()
```

## `scripts/ui/title.gd`

```gdscript
extends Control
## Заставка: главная сцена проекта. «Продолжить» видна только при наличии сохранения.

var switch_scenes := true   # тесты выключают, чтобы не подменять сцену дерева GUT

@onready var _continue: Button = $VBox/Continue
@onready var _play: Button = $VBox/Play
@onready var _quit: Button = $VBox/Quit


func _ready() -> void:
	Mouse.capture(false)
	_continue.visible = has_save()
	_continue.pressed.connect(continue_game)
	_play.pressed.connect(new_game)
	_quit.pressed.connect(func() -> void: get_tree().quit())
	(_continue if _continue.visible else _play).grab_focus()


func has_save() -> bool:
	return FileAccess.file_exists(SaveGame.path)


func continue_game() -> void:
	_go()


func new_game() -> void:
	GameState.reset()   # сначала сброс: его сигналы могут вызвать автосохранение, файл стираем после
	SaveGame.clear()
	_go()


func _go() -> void:
	if switch_scenes:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
```

## `scripts/visual/effects.gd`

```gdscript
class_name Effects
extends RefCounted
## Одноразовые всплески частиц: съедание (цвет редкости), удар (золотые звёзды), клубочек (сиреневый).
## CPUParticles3D, а не GPU: работает и под dummy-рендерером тестов, цвет задаётся напрямую.

const YARN_COLOR := Color("#B46DB5")
const HIT_COLOR := Color("#FABE32")


static func burst(parent: Node, pos: Vector3, color: Color, amount := 24, size := 0.05, speed := 2.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Burst"
	p.add_to_group("fx")
	p.add_to_group("burst")   # одноразовые всплески событий: тесты считают их отдельно от постоянных эффектов
	p.one_shot = true
	p.emitting = false   # включается после add_child, иначе из физического шага finished приходит сразу
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -4.0, 0)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color = color
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	_free_later(p)
	return p


## Одноразовые системы удаляются по таймеру, а не по finished: созданные во время физического шага
## CPUParticles3D шлют finished в том же кадре и исчезали бы, не родив ни одной частицы.
static func _free_later(p: CPUParticles3D) -> void:
	p.get_tree().create_timer(p.lifetime * (2.0 - p.explosiveness) + 0.3, false).timeout.connect(p.queue_free)   # последние частицы рождаются к lifetime·(1−explosiveness)


const DUST_COLOR := Color("#D3AB87")
const HEART_PATH := "res://assets/images/ui/heart.png"   # load, не preload: без файла проект должен стартовать


static func _particles(parent: Node, name: String, one_shot: bool) -> CPUParticles3D:
	## Узел создаётся выключенным и без родителя: фабрика настраивает его, затем зовёт _start.
	var p := CPUParticles3D.new()
	p.name = name
	p.add_to_group("fx")
	p.one_shot = one_shot
	p.emitting = false
	p.set_meta("fx_parent", parent)
	return p


static func _start(p: CPUParticles3D, pos := Vector3.INF) -> CPUParticles3D:
	(p.get_meta("fx_parent") as Node).add_child(p)
	if pos != Vector3.INF:
		p.global_position = pos
	p.emitting = true
	if p.one_shot:
		_free_later(p)
	return p


static func _sphere_mesh(radius := 0.5) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	return mesh


static func dust(parent: Node, pos: Vector3, amount := 12) -> CPUParticles3D:
	## Пыль при приземлении и беге: песочные шарики, расходятся в стороны и тают.
	var p := _particles(parent, "Dust", true)
	p.add_to_group("dust")
	p.amount = amount
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 85.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.2
	p.gravity = Vector3(0, -1.0, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.06
	p.color = DUST_COLOR
	p.mesh = _sphere_mesh()
	return _start(p, pos)


static func hearts(parent: Node, pos: Vector3) -> CPUParticles3D:
	## Сердечки при съедании: спрайты сгенерированной иконки, плывут вверх.
	var p := _particles(parent, "Hearts", true)
	p.add_to_group("hearts")
	p.amount = 6
	p.lifetime = 1.0
	p.explosiveness = 0.6
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.2
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = load(HEART_PATH) as Texture2D if ResourceLoader.exists(HEART_PATH) else null
	if mat.albedo_texture == null:
		mat.albedo_color = Color("#F57485")   # без картинки — розовые квадратики
	quad.material = mat
	p.mesh = quad
	return _start(p, pos)


static func sparkles(parent: Node, color: Color) -> CPUParticles3D:
	## Постоянные искры вокруг редкой еды (спек 2.8).
	var p := _particles(parent, "Sparkles", false)
	p.amount = 8
	p.lifetime = 1.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.25
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.015
	p.scale_amount_max = 0.03
	p.color = color
	p.mesh = _sphere_mesh()
	return _start(p)


static func trail(parent: Node, color: Color, amount := 10) -> CPUParticles3D:
	## Шлейф за осой/велосипедом: частицы остаются в мире (local_coords = false).
	var p := _particles(parent, "Trail", false)
	p.amount = amount
	p.lifetime = 0.6
	p.local_coords = false
	p.direction = Vector3.DOWN
	p.spread = 40.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.02
	p.scale_amount_max = 0.04
	p.color = color
	p.mesh = _sphere_mesh()
	return _start(p)


static func zzz(parent: Node, pos: Vector3) -> Label3D:
	## «z» над спящей собакой: всплывает 1,2 с и исчезает.
	var z := Label3D.new()
	z.name = "Zzz"
	z.add_to_group("fx")
	z.text = "z"
	z.font_size = 48
	z.pixel_size = 0.004
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.modulate = Color("#394151")
	parent.add_child(z)
	z.global_position = pos
	var tw := z.create_tween()
	tw.tween_property(z, "global_position", pos + Vector3(0.15, 0.35, 0), 1.2)
	tw.parallel().tween_property(z, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tw.tween_callback(z.queue_free)
	return z


static func leaves(parent: Node, extents := Vector3(15, 1.5, 15)) -> CPUParticles3D:
	## Листья по ветру над двором: медленный дрейф, вращение, 40 штук на 8 с.
	var p := _particles(parent, "Leaves", false)
	p.amount = 40
	p.lifetime = 8.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(1, -0.2, 0.3)
	p.spread = 20.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, -0.15, 0)
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.07
	p.color = Color("#A9B087")
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 0.6)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	p.mesh = quad
	_start(p)
	p.position = Vector3(0, 1.5 + extents.y, 0)   # низ бокса рождения на земле, не под ней
	return p
```

## `scripts/visual/surface_textures.gd`

```gdscript
class_name SurfaceTextures
extends RefCounted
## Текстуры крупных поверхностей (спек 2.9, «гибрид»): асфальт, плитка тротуара, штукатурка стен.
## Трипланарная проекция по мировым координатам — UV у мешей из Blender-скриптов нет, а плитка должна
## идти непрерывно через стыки модулей стены. Пропсы, еда и персонажи остаются плоскоцветными.

const DIR := "res://assets/images/textures/"
## имя меша -> [файл текстуры, размер тайла в метрах]
const TABLE := {
	"ground": ["asphalt.png", 4.0],
	"sidewalk": ["paving.png", 1.2],
	"wall": ["stucco.png", 4.5],
	"lawn": ["grass.png", 2.0],
	"path": ["gravel.png", 0.8],
	"retaining_wall": ["stone.png", 3.0],
}


static func texture_or_null(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func apply(root: Node) -> int:
	## Звать после Toon.apply: правит его пер-инстансные материалы. Возвращает число затекстурированных мешей.
	var count := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or not TABLE.has(String(m3.name)):
			continue
		var entry: Array = TABLE[String(m3.name)]
		var tex := texture_or_null(DIR + entry[0])
		if tex == null:
			continue   # без картинки поверхность остаётся плоского цвета
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m == null:
				continue
			m.albedo_texture = tex
			m.albedo_color = Color.WHITE
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / float(entry[1])
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		count += 1
	return count
```

## `scripts/visual/toon.gd`

```gdscript
class_name Toon
extends RefCounted
## Переводит материалы в тун-режим и добавляет обводку шейдерным hull-ом (спек 2.3, 2.8).
## character = true: rim-свет и «шерстяная» обводка с шумом ширины.

const OUTLINE_COLOR := Color("#394151")
const OUTLINE_CHARACTER := 0.006   # метры; 0,02 из первой версии спека на 35-см коте рвёт hull
const OUTLINE_FOOD := 0.004
const OUTLINE_NONE := 0.0
const OUTLINE_JITTER := 0.25
const RIM := 0.5
const RIM_TINT := 0.6
const OutlineShader := preload("res://assets/shaders/outline_fur.gdshader")


## outline_width задаётся в метрах: hull растёт в пространстве модели, поэтому
## для вложенных в масштабированный узел мешей (скиновый кот) ширина пересчитывается.
static func apply(root: Node, outline_width: float = OUTLINE_CHARACTER, character := false) -> int:
	var count := 0
	if root is MeshInstance3D:
		count += _apply_to_mesh(root as MeshInstance3D, outline_width, character)
	for child in root.get_children():
		count += apply(child, outline_width, character)
	return count


static func _apply_to_mesh(mi: MeshInstance3D, outline_width: float, character: bool) -> int:
	if mi.mesh == null:
		return 0
	var surfaces := mi.mesh.get_surface_count()
	for i in surfaces:
		var src := mi.get_active_material(i)
		var mat: StandardMaterial3D
		if src is StandardMaterial3D:
			mat = (src as StandardMaterial3D).duplicate()
			mat.resource_name = src.resource_name   # скины узнают поверхности по имени материала
		else:
			mat = StandardMaterial3D.new()
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat.roughness = 0.85
		mat.rim_enabled = character
		if character:
			mat.rim = RIM
			mat.rim_tint = RIM_TINT
		mi.set_surface_override_material(i, mat)
	if outline_width > 0.0:
		mi.material_overlay = make_outline(outline_width / _world_scale(mi), OUTLINE_JITTER if character else 0.0)
	return surfaces


static func _world_scale(mi: MeshInstance3D) -> float:
	if not mi.is_inside_tree():
		return 1.0
	var s := mi.global_transform.basis.get_scale().x
	return s if s > 0.0001 else 1.0


static func make_outline(width: float, jitter := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = OutlineShader
	m.set_shader_parameter("color", OUTLINE_COLOR)
	m.set_shader_parameter("width", width)
	m.set_shader_parameter("jitter", jitter)
	m.set_shader_parameter("frequency", 40.0)
	m.set_shader_parameter("alpha", 1.0)
	return m
```

## `scripts/world/day_cycle.gd`

```gdscript
class_name DayCycle
extends RefCounted
## Чистая логика смены суток (спек этапа 2, раздел 2): фазы по времени, ключевые кадры света, фонари.
## Цикл 300 с: день [0,150), вечер [150,180), ночь [180,270), утро [270,300).

const CYCLE := 300.0
const PHASES := [[0.0, &"day"], [150.0, &"evening"], [180.0, &"night"], [270.0, &"morning"]]
const LAMPS_FROM := 165.0
const LAMPS_TO := 285.0

const DAY := {"sun_pitch": -65.0, "sun_color": Color("#FFF1D6"), "sun_energy": 1.2, "fill": 0.25, "ambient": 0.6,
	"sky_top": Color("#4A9BE0"), "sky_horizon": Color("#CFE6F8"), "clouds": Color("#FFFFFF")}
const DUSK := {"sun_pitch": -10.0, "sun_color": Color("#FFB36B"), "sun_energy": 0.8, "fill": 0.2, "ambient": 0.45,
	"sky_top": Color("#5A6FB0"), "sky_horizon": Color("#FFB98A"), "clouds": Color("#FFD2B0")}
const NIGHT := {"sun_pitch": -50.0, "sun_color": Color("#9FB8FF"), "sun_energy": 0.22, "fill": 0.08, "ambient": 0.18,
	"sky_top": Color("#0B1633"), "sky_horizon": Color("#1E2F5C"), "clouds": Color("#3A4670")}
## (время, состояние); рассвет повторяет закат
const KEYS := [[0.0, DAY], [150.0, DAY], [165.0, DUSK], [185.0, NIGHT], [270.0, NIGHT], [285.0, DUSK], [300.0, DAY]]


static func wrap_time(t: float) -> float:
	return fposmod(t, CYCLE)


static func phase_at(t: float) -> StringName:
	var w := wrap_time(t)
	var out: StringName = &"day"
	for p in PHASES:
		if w >= p[0]:
			out = p[1]
	return out


static func phase_progress(t: float) -> float:
	## Доля прошедшей фазы, 0..1 (для полоски «до следующей фазы» в HUD).
	var w := wrap_time(t)
	for i in PHASES.size():
		var start: float = PHASES[i][0]
		var end: float = PHASES[i + 1][0] if i + 1 < PHASES.size() else CYCLE
		if w >= start and w < end:
			return (w - start) / (end - start)
	return 0.0


static func light_at(t: float) -> Dictionary:
	var w := wrap_time(t)
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if w >= a[0] and w <= b[0]:
			var k: float = 0.0 if b[0] == a[0] else (w - a[0]) / (b[0] - a[0])
			k = smoothstep(0.0, 1.0, k)
			var out := {}
			for key in (a[1] as Dictionary):
				var va = a[1][key]
				var vb = b[1][key]
				out[key] = (va as Color).lerp(vb, k) if va is Color else lerpf(va, vb, k)
			return out
	return DAY.duplicate()


static func lamps_on(t: float) -> bool:
	var w := wrap_time(t)
	return w >= LAMPS_FROM and w < LAMPS_TO


static func parse_time(text: String) -> float:
	## «day/evening/night/morning» или число секунд — для ++ --phase= и make shot PHASE=.
	var named := {"day": 75.0, "evening": 165.0, "night": 225.0, "morning": 285.0}
	return named.get(text.to_lower(), text.to_float())
```

## `scripts/world/day_night.gd`

```gdscript
class_name DayNight
extends Node
## Ведёт время суток и применяет свет к узлам Lighting (спек этапа 2, раздел 2).
## Остальные спрашивают DayNight.is_night(tree): без узла (тесты, отдельные сцены) всегда день.
## Пишет в свет/небо только при изменении состояния, фонари и окна — только при переключении.

signal phase_changed(phase: StringName)

const WINDOW_GLOW := Color("#FFD9A0")

@export var time_scale := 1.0
var time := 0.0
var phase: StringName = &"day"
var light_writes := 0          # счётчик применений света (для тестов «не пишет каждый кадр»)
var _last_light: Dictionary = {}
var _lamps := false
var _lamp_count := -1


func _ready() -> void:
	add_to_group("day_night")
	_own_sky()
	set_time(time)


func _own_sky() -> void:
	## Свой экземпляр окружения и неба: подресурсы PackedScene общие для всех инстансов сцены.
	var we := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate(true)


func _process(delta: float) -> void:
	time = DayCycle.wrap_time(time + delta * time_scale)
	_apply()


func set_time(t: float) -> void:
	time = DayCycle.wrap_time(t)
	_apply()


func _apply() -> void:
	var s := DayCycle.light_at(time)
	if s != _last_light:
		_last_light = s
		light_writes += 1
		_write_light(s)
	var lamps := DayCycle.lamps_on(time)
	var count := get_tree().get_node_count_in_group("night_lights") + get_tree().get_node_count_in_group("night_windows") if is_inside_tree() else 0
	if lamps != _lamps or count != _lamp_count:   # новые фонари/окна (построены позже) тоже получают текущее состояние
		_lamps = lamps
		_lamp_count = count
		_write_lamps(lamps)
	var p := DayCycle.phase_at(time)
	if p != phase:
		phase = p
		phase_changed.emit(phase)


func _write_light(s: Dictionary) -> void:
	var lighting := get_parent()
	var sun := lighting.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.rotation_degrees = Vector3(s["sun_pitch"], 30.0, 0.0)
		sun.light_color = s["sun_color"]
		sun.light_energy = s["sun_energy"]
	var fill := lighting.get_node_or_null("Fill") as DirectionalLight3D
	if fill:
		fill.light_energy = s["fill"]
	var we := lighting.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.ambient_light_energy = s["ambient"]
		var sky := we.environment.sky.sky_material as ProceduralSkyMaterial if we.environment.sky else null
		if sky:
			sky.sky_top_color = s["sky_top"]
			sky.sky_horizon_color = s["sky_horizon"]
			sky.ground_horizon_color = s["sky_horizon"]
			sky.sky_cover_modulate = s["clouds"]


func _write_lamps(on: bool) -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("night_lights"):
		(n as Node3D).visible = on
	for n in get_tree().get_nodes_in_group("night_windows"):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as StandardMaterial3D
			if m:
				m.emission_enabled = on
				m.emission = WINDOW_GLOW
				m.emission_energy_multiplier = 0.9


static func current_phase(tree: SceneTree) -> StringName:
	var n := tree.get_first_node_in_group("day_night") as DayNight
	return n.phase if n else &"day"


static func is_night(tree: SceneTree) -> bool:
	return current_phase(tree) == &"night"
```

## `scripts/world/floater.gd`

```gdscript
class_name Floater
extends AnimatableBody3D
## Качающаяся опора в воде — лодка или бочка (спек порта, раздел 2): подъём ±amp, крен ±roll_deg вокруг продольной оси,
## период period, сдвиг фазы phase. Кот стоит на ней: AnimatableBody3D с sync_to_physics переносит его вместе с собой.

@export var amp := 0.12
@export var roll_deg := 6.0
@export var period := 3.5
@export var phase := 0.0
@export var solid := true   # false — декоративная опора (буёк), без коллизии
var base: Transform3D
var _t := 0.0


static func offset_at(t: float, a: float, roll: float, p: float, ph: float) -> Vector2:
	## (подъём в метрах, крен в градусах) в момент t; крен опережает подъём на четверть периода.
	var w := TAU * t / p + ph
	return Vector2(a * sin(w), roll * cos(w))


func _ready() -> void:
	add_to_group("floaters")
	collision_layer = Layers.WORLD if solid else 0
	collision_mask = 0
	sync_to_physics = true
	base = transform


func _physics_process(delta: float) -> void:
	_t += delta
	var o := offset_at(_t, amp, roll_deg, period, phase)
	transform = Transform3D(base.basis * Basis(Vector3.BACK, deg_to_rad(o.y)), base.origin + Vector3(0, o.x, 0))
```

## `scripts/world/gate.gd`

```gdscript
class_name Gate
extends StaticBody3D
## Ворота района: закрыты, пока сытость меньше порога (спек 3.4).

signal opened

const BAR_COLOR := Color("#394151")
const BARS := 5

@export var satiety_required := GameState.SATIETY_GATE
@export var size := Vector3(2.4, 2.6, 0.3)
var open := false
var label := "🎉 Арка в кафе открыта!"   # сообщение при открытии (раскладка задаёт своё)

@onready var _shape: CollisionShape3D = $Collision
@onready var _bars: Node3D = $Bars


func _ready() -> void:
	add_to_group("gates")
	collision_mask = 0
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	_shape.position.y = size.y / 2.0
	_build_bars()
	GameState.satiety_changed.connect(refresh)
	refresh(GameState.satiety)


func _build_bars() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = BAR_COLOR
	for i in BARS:
		var mi := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.06, size.y, 0.06)
		bar.material = mat
		mi.mesh = bar
		mi.position = Vector3(-size.x / 2.0 + size.x * (i + 0.5) / BARS, size.y / 2.0, 0.0)
		_bars.add_child(mi)
	var rail := MeshInstance3D.new()
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(size.x, 0.06, 0.06)
	rail_mesh.material = mat
	rail.mesh = rail_mesh
	rail.position = Vector3(0.0, size.y * 0.5, 0.0)
	_bars.add_child(rail)


func refresh(satiety: int) -> void:
	var now_open := satiety >= satiety_required
	if now_open == open:
		collision_layer = 0 if open else Layers.WORLD
		return
	open = now_open
	collision_layer = 0 if open else Layers.WORLD
	_bars.visible = not open
	if open:
		opened.emit()
```

## `scripts/world/lighting.gd`

```gdscript
extends Node3D
## Свет района: солнце (днём 65° с юго-востока, ведёт DayNight), заполняющий свет неба с обратной стороны, листья.

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-65.0, 30.0, 0.0)
	$Fill.rotation_degrees = Vector3(-65.0, 210.0, 0.0)
	Effects.leaves(self)
```

## `scripts/world/spill_spawner.gd`

```gdscript
class_name SpillSpawner
extends Node3D
## Раскладывает выбитую из зубов еду вокруг кота (спек 3.2: 1–2 м, 5 с). Каждая порция кладётся
## на поверхность под своей точкой (луч вниз по слою WORLD): со стола и балкона падает на землю рядом.

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const SPILL_LIFETIME := 5.0
const MIN_R := 1.0
const MAX_R := 2.0
const RAY_UP := 0.5     # луч стартует чуть выше точки кота: он может стоять на краю стола
const RAY_DOWN := 10.0

var rng := RandomNumberGenerator.new()


func spill_around(pos: Vector3, foods: Array) -> Array:
	var out := []
	var space := get_world_3d().direct_space_state
	for f in foods:
		var p := PickupScene.instantiate() as FoodPickup
		p.setup(f, true, SPILL_LIFETIME)
		p.add_to_group("spilled_food")
		add_child(p)
		var ang := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(MIN_R, MAX_R)
		var x := pos.x + cos(ang) * r
		var z := pos.z + sin(ang) * r
		p.global_position = Vector3(x, surface_y(space, Vector3(x, pos.y + RAY_UP, z)), z)
		out.append(p)
	return out


static func surface_y(space: PhysicsDirectSpaceState3D, from: Vector3) -> float:
	## Высота первой поверхности мира под точкой; без попадания — уровень земли.
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -RAY_DOWN, 0), Layers.WORLD)
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3).y if not hit.is_empty() else 0.0
```

## `scripts/world/terrain.gd`

```gdscript
class_name Terrain
extends Node3D
## Пол района по карте высот (спек «Масштаб и рельеф», раздел 3). Данные — data/terrain/<район>.json (tools/terrain).
## Меш тайлами 30×30 м и коллизия HeightMapShape3D строятся из одной сетки — совпадают точно (Ruling плана 10).
## Узел должен стоять в начале координат (сетка задана в мировых x, z).

const TILE := 30
const TEX_DIR := "res://assets/images/textures/"
const DEFAULT_TEXTURES := {"asphalt": "asphalt.png", "paving": "paving.png", "grass": "grass.png", "gravel": "gravel.png",
	"sand": "sand.png", "stone": "stone.png", "planks": "planks.png"}   # песок и доски — порт (план 13)
const DEFAULT_TILES := {"asphalt": 4.0, "paving": 1.2, "grass": 2.0, "gravel": 0.8, "sand": 3.0, "stone": 3.0, "planks": 2.0}
const TerrainShader := preload("res://assets/shaders/terrain.gdshader")

@export_file("*.json") var data_path := ""
var nx := 0
var nz := 0
var cell := 1.0
var x0 := 0.0
var z0 := 0.0
var width := 0.0
var depth := 0.0
var channels: Array = []
var heights := PackedFloat32Array()
var splat := PackedByteArray()
var loaded := false
var material: ShaderMaterial


func ensure_loaded() -> void:
	if loaded or data_path == "":
		return
	if not FileAccess.file_exists(data_path):
		push_warning("нет рельефа " + data_path)
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(data_path)) != OK:
		push_error("не разобрать рельеф " + data_path)
		return
	var d: Dictionary = json.data
	nx = int(d["nx"])
	nz = int(d["nz"])
	cell = float(d["cell"])
	x0 = float(d["origin"][0])
	z0 = float(d["origin"][1])
	width = float(d["size"][0])
	depth = float(d["size"][1])
	channels = d.get("channels", ["asphalt", "paving", "grass", "gravel"])
	heights.resize(nx * nz)
	for j in nz:
		var row: Array = d["heights"][j]
		for i in nx:
			heights[j * nx + i] = float(row[i])
	splat = Marshalls.base64_to_raw(d["splat"])
	loaded = true


func _ready() -> void:
	add_to_group("terrain")
	ensure_loaded()
	if not loaded:
		return
	assert(is_equal_approx(cell, 1.0), "HeightMapShape3D — шаг 1 м")
	_build_material()
	_build_tiles()
	_build_collision()


func h(i: int, j: int) -> float:
	return heights[clampi(j, 0, nz - 1) * nx + clampi(i, 0, nx - 1)]


func contains(x: float, z: float) -> bool:
	return x >= x0 and x <= x0 + width and z >= z0 and z <= z0 + depth


func height_at(x: float, z: float) -> float:
	## Высота поверхности по треугольникам сетки — так же, как в меше и HeightMapShape3D.
	ensure_loaded()
	if not loaded:
		return 0.0
	var fx := (x - x0) / cell
	var fz := (z - z0) / cell
	var i := clampi(int(floor(fx)), 0, nx - 2)
	var j := clampi(int(floor(fz)), 0, nz - 2)
	var u := clampf(fx - i, 0.0, 1.0)
	var v := clampf(fz - j, 0.0, 1.0)
	var h00 := h(i, j)
	var h10 := h(i + 1, j)
	var h01 := h(i, j + 1)
	var h11 := h(i + 1, j + 1)
	if u + v <= 1.0:   # треугольник (i,j)-(i+1,j)-(i,j+1)
		return h00 + (h10 - h00) * u + (h01 - h00) * v
	return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)


static func surface_height(tree: SceneTree, x: float, z: float, fallback := 0.0) -> float:
	## Высота рельефа в точке по всем узлам группы terrain; вне всех — fallback.
	for n in tree.get_nodes_in_group("terrain"):
		var t := n as Terrain
		if t and t.loaded and t.contains(x, z):
			return t.height_at(x, z)
	return fallback


func _texture(name: String) -> Texture2D:
	var path: String = TEX_DIR + DEFAULT_TEXTURES.get(name, "paving.png")
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _build_material() -> void:
	var img := Image.create_from_data(nx, nz, false, Image.FORMAT_RGBA8, splat)
	material = ShaderMaterial.new()
	material.shader = TerrainShader
	material.set_shader_parameter("splat", ImageTexture.create_from_image(img))
	var keys := ["tex_r", "tex_g", "tex_b", "tex_a"]
	var tiles := Vector4.ONE
	for c in 4:
		var name: String = channels[c] if c < channels.size() else "paving"
		material.set_shader_parameter(keys[c], _texture(name))
		tiles[c] = DEFAULT_TILES.get(name, 2.0)
	material.set_shader_parameter("tile_sizes", tiles)
	material.set_shader_parameter("tex_cliff", _texture("stone"))
	material.set_shader_parameter("origin", Vector2(x0, z0))
	material.set_shader_parameter("size", Vector2(width, depth))
	material.set_shader_parameter("texels", Vector2(nx, nz))


func _normal(i: int, j: int) -> Vector3:
	return Vector3(h(i - 1, j) - h(i + 1, j), 2.0 * cell, h(i, j - 1) - h(i, j + 1)).normalized()


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


func _build_tiles() -> void:
	var t := 0
	for tj in range(0, nz - 1, TILE):
		for ti in range(0, nx - 1, TILE):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var i1 := mini(ti + TILE, nx - 1)
			var j1 := mini(tj + TILE, nz - 1)
			if _tile_flat(ti, tj, i1, j1):   # плоский тайл — один квад (спек: ≤ 40 000 треугольников на район)
				for q in [[ti, tj], [i1, tj], [ti, j1], [i1, tj], [i1, j1], [ti, j1]]:
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(x0 + q[0] * cell, h(q[0], q[1]), z0 + q[1] * cell))
				_tris += 2
			else:
				for j in range(tj, j1):
					for i in range(ti, i1):
						for q in [[i, j], [i + 1, j], [i, j + 1], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
							st.set_normal(_normal(q[0], q[1]))
							st.add_vertex(Vector3(x0 + q[0] * cell, h(q[0], q[1]), z0 + q[1] * cell))
				_tris += (i1 - ti) * (j1 - tj) * 2
			var mi := MeshInstance3D.new()
			mi.name = "Tile%d" % t
			mi.mesh = st.commit()
			mi.material_override = material
			add_child(mi)
			t += 1


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"   # имя пола: инварианты раскладки не считают его пропсом
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	hm.map_width = nx
	hm.map_depth = nz
	hm.map_data = heights
	shape.shape = hm
	shape.position = Vector3(x0 + width / 2.0, 0.0, z0 + depth / 2.0)
	body.add_child(shape)
	add_child(body)
```

## `scripts/world/water.gd`

```gdscript
class_name Water
extends Area3D
## Вода (спек порта, раздел 2): поверхность на уровне узла; кот, погрузившийся на SINK м ниже поверхности, тонет
## и возвращается на ближайший маркер группы shore. Пруд парка и море порта — один узел.

const SINK := 0.15
const WaterShader := preload("res://assets/shaders/water.gdshader")

@export var size := Vector3(10, 3, 10)   # ширина, глубина зоны под поверхностью, длина
var level: float:
	get:
		return global_position.y


func _ready() -> void:
	add_to_group("water")
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, size.z)
	shape.shape = box
	shape.position.y = -SINK - size.y / 2.0
	add_child(shape)
	var surface := MeshInstance3D.new()
	surface.name = "Surface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.z)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	surface.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = WaterShader
	surface.material_override = mat
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	body_entered.connect(_on_body)


func _on_body(body: Node3D) -> void:
	if body.has_method("drown"):
		body.call("drown", nearest_shore(get_tree(), body.global_position, level))


static func nearest_shore(tree: SceneTree, pos: Vector3, water_level := 0.0) -> Vector3:
	## Ближайший маркер берега; без маркеров — та же точка над водой.
	var best := Vector3(pos.x, water_level + 1.0, pos.z)
	var best_d := INF
	for m in tree.get_nodes_in_group("shore"):
		var p: Vector3 = (m as Node3D).global_position
		var d := Vector2(p.x - pos.x, p.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = p
	return best
```

## `scripts/world/world_builder.gd`

```gdscript
class_name WorldBuilder
extends Node3D
## Строит район из data/layout/*.json: пропсы (с коллизией или без — solid), укрытия, точки спавна,
## опасности, дорога, декали (квады с текстурами из сгенерированных картинок).

const MODELS_DIR := "res://assets/models"
const HAZARD_SCENES := {
	"dog": "res://scenes/hazards/dog.tscn",
	"wasp": "res://scenes/hazards/wasp.tscn",
	"cyclist": "res://scenes/hazards/cyclist.tscn",
	"sprinkler": "res://scenes/hazards/sprinkler.tscn",
	"pigeons": "res://scenes/hazards/pigeon_flock.tscn",
	"gardener": "res://scenes/hazards/gardener.tscn",
	"kid": "res://scenes/hazards/kid.tscn",
	"guard": "res://scenes/hazards/guard.tscn",
	"gull": "res://scenes/hazards/gull.tscn",
	"wave": "res://scenes/hazards/wave.tscn",
	"forklift": "res://scenes/hazards/forklift.tscn",
	"crab": "res://scenes/hazards/crab.tscn",
}
const HideoutScene := preload("res://scenes/hideouts/hideout.tscn")
const SpawnScene := preload("res://scenes/food/food_spawn_point.tscn")
const YarnScene := preload("res://scenes/food/yarn_pickup.tscn")
const GateScene := preload("res://scenes/world/gate.tscn")
const YarnShopScene := preload("res://scenes/world/yarn_shop.tscn")

@export var layout_path := ""
@export var terrain_path: NodePath   # пусто — плоский мир, y раскладки абсолютные
var terrain: Terrain
var props_built := 0
var hideouts_built := 0
var spawns_built := 0
var hazards_built := 0
var yarn_built := 0
var gates_built := 0
var shop_built := 0
var water_built := 0
var decals_built := 0


func _ready() -> void:
	if terrain == null and not terrain_path.is_empty():
		terrain = get_node_or_null(terrain_path) as Terrain
	if terrain:
		terrain.ensure_loaded()   # рельеф мог ещё не пройти _ready (порядок соседей)
	if layout_path != "":
		build(load_layout(layout_path))


static func load_layout(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "не удалось разобрать " + path)
	return parsed


## Модули террас (tools/blender/terrace_kit.py): подъём по −Z модели от начала координат.
const KIT_STEP_RISE := 0.2
const KIT_STEP_TREAD := 0.3
const KIT_RAMP_DEG := 25.0
const KIT_WIDTH := 1.6
## Мелкие пропсы гаснут дальше SMALL_RANGE (спек «Масштаб ×3», раздел 5).
const SMALL_PROPS := ["grass", "bush", "box", "bag", "chair", "bin", "puddle", "flowerbed", "ivy"]
const SMALL_RANGE := 40.0


static func kit_colliders(model: String) -> Array:
	## Наклонный коллайдер лестницы террасы или пандуса по имени модели (terrace_stairsN, rampN); иначе [].
	var h := 0.0
	var run := 0.0
	if model.begins_with("terrace_stairs") and model.trim_prefix("terrace_stairs").is_valid_int():
		h = float(model.trim_prefix("terrace_stairs"))
		run = roundf(h / KIT_STEP_RISE) * KIT_STEP_TREAD
	elif model.begins_with("ramp") and model.trim_prefix("ramp").is_valid_int():
		h = float(model.trim_prefix("ramp"))
		run = h / tan(deg_to_rad(KIT_RAMP_DEG))
	else:
		return []
	var ang := rad_to_deg(atan2(h, run))
	var length := sqrt(h * h + run * run)
	# Тонкая плита по линии подъёма; верх плиты — поверхность пандуса, у лестницы — линия через середины
	# проступей (сдвиг на полступени к началу): кот не тонет в ступенях и не висит над ними больше чем на полподступенка.
	var th := 0.1
	var shift := KIT_STEP_TREAD / 2.0 if model.begins_with("terrace_stairs") else 0.0
	var n := Vector3(0, cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
	var center := Vector3(0, h / 2.0, -run / 2.0 + shift) - n * (th / 2.0)
	return [{"size": [KIT_WIDTH, th, length], "offset": [center.x, center.y, center.z], "rot": [ang, 0, 0]}]


func _add_at(parent: Node3D, node: Node3D, pos: Vector3, rot_y_deg: float) -> void:
	## Ставит узел в мировую позицию ДО add_child: тела не появляются на кадр в начале координат.
	node.transform = parent.global_transform.affine_inverse() * Transform3D(Basis(Vector3.UP, deg_to_rad(rot_y_deg)), pos)
	parent.add_child(node)


func _place(item: Dictionary) -> Vector3:
	## Позиция из раскладки: на рельефе y — смещение над поверхностью; "snap": false — абсолютная высота.
	var v := _v3(item["pos"])
	if terrain and bool(item.get("snap", true)):
		v.y += terrain.height_at(v.x, v.z)
	return v


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
	for d in data.get("decals", []):
		_build_decal(d)
	for h in data.get("hideouts", []):
		_build_hideout(h)
	for s in data.get("spawn_points", []):
		_build_spawn(s)
	for y in data.get("yarn", []):
		_build_yarn(y)
	_build_road(data.get("road", {}))
	for g in data.get("gates", []):
		_build_gate(g)
	if data.has("shop"):
		_build_shop(data["shop"])
	for hz in data.get("hazards", []):
		_build_hazard(hz)
	for w in data.get("water_zones", []):
		_build_water(w)
	for m in data.get("shore", []):
		_build_shore(m)
	for f in data.get("floaters", []):
		_build_floater(f)


func _build_floater(f: Dictionary) -> void:
	## Лодка или бочка на воде (план 13): pos — абсолютный (y — опора по ватерлинии), коллайдеры — явные или по модели.
	var model_path := "%s/%s.glb" % [MODELS_DIR, f["model"]]
	if not ResourceLoader.exists(model_path):
		push_warning("нет модели " + model_path)
		return
	var body := Floater.new()
	body.name = "%s%d" % [f["model"], _container("Floaters").get_child_count()]   # уникальное имя: иначе Godot даёт @Floater@N
	body.amp = float(f.get("amp", body.amp))
	body.roll_deg = float(f.get("roll", body.roll_deg))
	body.period = float(f.get("period", body.period))
	body.phase = float(f.get("phase", 0.0))
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	body.add_child(model)
	var colliders: Array = f.get("colliders", [])
	if not bool(f.get("solid", true)):
		body.solid = false   # декоративная опора (буёк): на неё не встать
	elif colliders.is_empty():
		var aabb := _model_aabb(model)
		colliders = [{"size": [aabb.size.x, aabb.size.y, aabb.size.z],
			"offset": [aabb.position.x + aabb.size.x / 2, aabb.position.y + aabb.size.y / 2, aabb.position.z + aabb.size.z / 2]}]
	for i in colliders.size():
		var c: Dictionary = colliders[i]
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = _v3(c["size"])
		shape.shape = box
		shape.position = _v3(c.get("offset", [0, 0, 0]))
		body.add_child(shape)
	_add_at(_container("Floaters"), body, _v3(f["pos"]), float(f.get("rot", 0)))
	Toon.apply(model, Toon.OUTLINE_NONE)


func _build_water(w: Dictionary) -> void:
	## Зона воды (план 12): pos — абсолютный, y — уровень поверхности; size — ширина, глубина зоны, длина.
	var node := Water.new()
	node.size = _v3(w.get("size", [10, 3, 10]))
	_add_at(_container("Water"), node, _v3(w["pos"]), float(w.get("rot", 0)))


func _build_shore(m: Dictionary) -> void:
	## Маркер берега: сюда возвращается утонувший кот (ближайший).
	var node := Marker3D.new()
	node.add_to_group("shore")
	_add_at(_container("Shore"), node, _place(m) + Vector3(0, 0.1, 0), 0.0)


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
	var solid := bool(p.get("solid", true))
	var colliders: Array = p.get("colliders", kit_colliders(String(p["model"]))) if solid else []
	if colliders.is_empty() and solid:
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
		shape.rotation_degrees = _v3(c.get("rot", [0, 0, 0]))   # наклонные коллайдеры лестниц и пандусов
		body.add_child(shape)
	# Позиция до add_child: иначе первый физический кадр тело стоит в начале координат и выталкивает
	# кота, появившегося там, сквозь тонкую карту высот (план 10).
	var props := _container("Props")
	body.transform = props.global_transform.affine_inverse() * Transform3D(Basis(Vector3.UP, deg_to_rad(float(p.get("rot", 0)))), _place(p))
	props.add_child(body)
	Toon.apply(model, Toon.OUTLINE_FOOD if p.get("outline", false) else Toon.OUTLINE_NONE)
	if String(p["model"]) in SMALL_PROPS:
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = SMALL_RANGE
			(mi as MeshInstance3D).visibility_range_end_margin = 4.0
			(mi as MeshInstance3D).visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if p["model"] == "lamp":
		body.add_child(_night_light())
	for mi in model.find_children("wall_glass*", "MeshInstance3D", true, false):
		mi.add_to_group("night_windows")   # ночью окна светятся тёплым (DayNight)
	for mi in model.find_children("lamp_head", "MeshInstance3D", true, false):
		mi.add_to_group("night_windows")   # и плафоны фонарей
	if not solid:
		for mi in model.find_children("*", "MeshInstance3D", true, false):   # листья и трава видны с обеих сторон
			if (mi as MeshInstance3D).mesh == null:
				continue
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
				if m:
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if bool(p.get("water", false)):
		_make_water(model)
		water_built += 1
	props_built += 1


func _night_light() -> SpotLight3D:
	## Свет фонаря: горит с заката до рассвета, переключает DayNight по группе night_lights.
	var l := SpotLight3D.new()
	l.name = "NightLight"
	l.add_to_group("night_lights")
	l.position = Vector3(0, 2.45, 0)
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.spot_angle = 50.0
	l.spot_range = 7.0
	l.light_color = Color("#FFD9A0")
	l.light_energy = 4.0
	l.shadow_enabled = false
	l.distance_fade_enabled = true   # на большом дворе дальние фонари гаснут (спек «Масштаб», раздел 5)
	l.distance_fade_begin = 35.0
	l.distance_fade_length = 5.0
	l.visible = false
	return l


func _make_water(model: Node3D) -> void:
	## Лужа/вода фонтана: зеркальный материал, отражает небо через SSR окружения (спек 2.8).
	## Если у модели есть меши с «water» в имени — зеркальными становятся только они (чаша фонтана остаётся тун).
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var water := meshes.filter(func(m): return String(m.name).contains("water"))
	for mi in (water if not water.is_empty() else meshes):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m == null:
				continue
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
			m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
			m.roughness = 0.05
			m.metallic = 0.0
			m.metallic_specular = 1.0


func _build_decal(d: Dictionary) -> void:
	## Декаль: квад с текстурой из сгенерированной картинки; на асфальте плашмя, на стене вертикально.
	var path := "res://" + String(d["texture"])
	if not ResourceLoader.exists(path):
		push_warning("нет текстуры декали " + path)
		return
	var mi := MeshInstance3D.new()
	mi.name = "decal_%d" % decals_built
	var quad := QuadMesh.new()
	var size: Array = d.get("size", [1.0, 1.0])
	quad.size = Vector2(size[0], size[1])
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(path)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mi.set_surface_override_material(0, mat)
	_container("Decals").add_child(mi)
	var pos := _place(d)
	var wall := bool(d.get("wall", false))
	mi.global_position = pos + (Vector3.ZERO if wall else Vector3(0, 0.01, 0))
	mi.rotation_degrees = Vector3(0.0, float(d.get("rot", 0)), 0.0) if wall else Vector3(-90.0, float(d.get("rot", 0)), 0.0)
	decals_built += 1


func _model_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = _local_xf(mi, model)
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
	_add_at(_container("Hideouts"), node, _place(h), float(h.get("rot", 0)))
	hideouts_built += 1


func _build_spawn(s: Dictionary) -> void:
	var node := SpawnScene.instantiate() as FoodSpawnPoint
	var allowed: Array = []
	for t in s.get("allowed", [0]):
		allowed.append(int(t))   # JSON даёт float, ключи словарей Rarity — int
	node.allowed = allowed
	node.foods = s.get("foods", [])
	_add_at(_container("Spawns"), node, _place(s), 0.0)
	spawns_built += 1


func _build_road(road: Dictionary) -> void:
	var path := Path3D.new()
	path.name = "Road"
	var curve := Curve3D.new()
	for pt in road.get("points", []):
		var v := _v3(pt)
		if terrain:
			v.y += terrain.height_at(v.x, v.z)
		curve.add_point(v)
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
	_add_at(_container("Hazards"), node, _place(hz), float(hz.get("rot", 0)))
	hazards_built += 1


func _build_yarn(y: Dictionary) -> void:
	var node := YarnScene.instantiate() as YarnPickup
	var raw := _v3(y["pos"])   # ключ — по раскладке, а не по высоте рельефа: сохранения не ломаются при правке рельефа
	node.key = "%.1f,%.1f,%.1f" % [raw.x, raw.y, raw.z]
	_add_at(_container("Yarn"), node, _place(y), 0.0)
	yarn_built += 1


func _build_gate(g: Dictionary) -> void:
	var node := GateScene.instantiate() as Gate
	node.name = "gate_%d" % gates_built
	node.satiety_required = int(g.get("satiety", GameState.SATIETY_GATE))
	node.label = String(g.get("label", node.label))
	node.size = _v3(g.get("size", [2.4, 2.6, 0.3]))
	_add_at(_container("Gates"), node, _place(g), float(g.get("rot", 0)))
	gates_built += 1


func _build_shop(s: Dictionary) -> void:
	var node := YarnShopScene.instantiate() as YarnShop
	node.name = "YarnShop"
	_add_at(self, node, _place(s), float(s.get("rot", 0)))
	shop_built += 1
```

## `scripts/world/yarn_shop.gd`

```gdscript
class_name YarnShop
extends Node3D
## Будка пряжи: безопасная зона, точка возрождения, вход в магазин (спек 3.5).

signal cat_entered
signal cat_exited

const BALL_RADIUS := 0.5
const BALL_SPEED := 1.0

var cat_inside := false
var _t := 0.0

@onready var zone: Area3D = $Zone
@onready var _model: Node3D = $Model
@onready var _play: Node3D = $YarnPlay


func _ready() -> void:
	add_to_group("yarn_shop")
	zone.collision_layer = Layers.AREA
	zone.collision_mask = Layers.CAT
	zone.monitorable = false
	zone.body_entered.connect(_on_enter)
	zone.body_exited.connect(_on_exit)
	Toon.apply(_model, Toon.OUTLINE_NONE)
	var ball_scene := load("res://assets/models/yarn.glb") as PackedScene
	for i in 3:
		var ball := ball_scene.instantiate() as Node3D
		_play.add_child(ball)
	Toon.apply(_play, Toon.OUTLINE_FOOD)


func _process(delta: float) -> void:
	_t += delta
	for i in _play.get_child_count():
		var ball := _play.get_child(i) as Node3D
		var a := _t * BALL_SPEED + i * TAU / 3.0
		ball.position = Vector3(cos(a) * BALL_RADIUS, 0.0, sin(a) * BALL_RADIUS * 0.6)
		ball.rotation.x += delta * 4.0


func respawn_position() -> Vector3:
	return ($Respawn as Node3D).global_position


func view_position() -> Vector3:
	## Точка камеры-витрины: снаружи у открытого входа, поворачивается вместе с будкой.
	return ($ViewPoint as Node3D).global_position


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = true
		body.set("in_safe_zone", true)
		cat_entered.emit()


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = false
		body.set("in_safe_zone", false)
		cat_exited.emit()
```

## `tests/integration/test_cat_asset.gd`

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
	# Скиновый меш в Godot рендерится в пространстве скелета, поэтому размер меряем по костям.
	var aabb := _bones_aabb(skel)
	assert_between(maxf(aabb.size.x, aabb.size.z), 0.2, 0.45, "длина кота по скелету должна быть около 0,3 м")
	assert_lt(aabb.size.y, 0.4, "высота кота не больше 0,4 м")

func test_cat_materials_are_palette() -> void:
	var inst := _instance()
	var names := []
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			names.append((mi as MeshInstance3D).get_active_material(i).resource_name)
	assert_has(names, "sr_cat_orange")
	assert_has(names, "sr_cream")

func _bones_aabb(skel: Skeleton3D) -> AABB:
	var result := AABB(skel.global_transform * skel.get_bone_global_rest(0).origin, Vector3.ZERO)
	for i in skel.get_bone_count():
		result = result.expand(skel.global_transform * skel.get_bone_global_rest(i).origin)
	return result

func test_cat_has_generated_clips() -> void:
	var inst := _instance()
	var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["jump", "hide", "hit"]:
		assert_true(ap.has_animation(clip), "нет клипа " + clip)
	assert_between(ap.get_animation("jump").length, 1.5, 2.5, "jump около 2 с: столько генерирует UniMate")
```

## `tests/integration/test_cat_scene.gd`

```gdscript
extends GutTest

const CAT_SCENE := "res://scenes/player/cat.tscn"
const RIG_SCENE := "res://scenes/player/camera_rig.tscn"

func _spawn() -> Node:
	var scene := load(CAT_SCENE) as PackedScene
	assert_not_null(scene, "нет сцены cat.tscn")
	var cat := scene.instantiate()
	add_child_autofree(cat)
	return cat

func test_cat_starts_idle_with_toon_materials() -> void:
	var cat = _spawn()
	assert_eq(cat.state, &"idle")
	var mesh := cat.find_child("cat", true, false) as MeshInstance3D   # первым ребёнком скелета может быть набор глаз без обводки
	assert_not_null(mesh.material_overlay, "обводка должна быть установлена")
	assert_eq((mesh.get_surface_override_material(0) as StandardMaterial3D).diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)

func test_play_clip_uses_generated_run_and_falls_back_for_unknown() -> void:
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	cat.play_clip(&"run")
	assert_eq(ap.current_animation, "run")
	assert_almost_eq(ap.speed_scale, 1.0, 0.001)
	cat.play_clip(&"somersault")
	assert_eq(ap.current_animation, "idle", "неизвестный клип уходит в idle")
	cat.play_clip(&"idle")
	assert_eq(ap.current_animation, "idle")

var _captured_head_scale := Vector3.ZERO

func test_head_is_scaled() -> void:
	var cat = _spawn()
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	var idx := skel.find_bone("head")
	# Skeleton3D восстанавливает базовую позу после модификаторов, поэтому итог
	# читается только в skeleton_updated (сразу после применения модификаторов).
	skel.skeleton_updated.connect(func() -> void:
		_captured_head_scale = skel.get_bone_global_pose(idx).basis.get_scale())
	await wait_process_frames(3)
	assert_almost_eq(_captured_head_scale.x, 1.4, 0.01)

func _body_outline(cat) -> ShaderMaterial:
	return (cat.find_child("cat", true, false) as MeshInstance3D).material_overlay as ShaderMaterial

func _body_material(cat) -> StandardMaterial3D:
	for mi in cat.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
			if m and m.resource_name == "sr_cat_orange":
				return m
	return null

func test_camera_rig_fades_target_instead_of_hiding() -> void:
	# Отложенное замечание ревью плана 1: у стены кот исчезал целиком.
	var cat = _spawn()
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	rig.target = cat
	add_child_autofree(rig)
	rig.apply_arm_length(0.5)   # упор в стену
	assert_true(cat.visible, "кот не исчезает")
	assert_lt(cat.fade, 0.5)
	var body := _body_material(cat)
	assert_eq(body.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_almost_eq(body.albedo_color.a, cat.fade, 0.01)
	assert_eq(body.depth_draw_mode, BaseMaterial3D.DEPTH_DRAW_ALWAYS, "полупрозрачное тело пишет глубину: обводка не просвечивает")
	var outline := _body_outline(cat)
	assert_almost_eq(float(outline.get_shader_parameter("alpha")), cat.fade, 0.01, "обводка тоже полупрозрачна (Review Focus 2)")
	rig.apply_arm_length(3.5)
	assert_almost_eq(cat.fade, 1.0, 0.001, "отошли от стены — непрозрачен")
	assert_eq(_body_material(cat).transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)
	assert_almost_eq(float(_body_outline(cat).get_shader_parameter("alpha")), 1.0, 0.001)

func test_skin_change_keeps_fade() -> void:
	# Review Focus 4
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	cat.set_fade(0.4)
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	assert_almost_eq(_body_material(cat).albedo_color.a, 0.4, 0.01, "скин не возвращает непрозрачность")
	assert_almost_eq(float(_body_outline(cat).get_shader_parameter("alpha")), 0.4, 0.01, "и обводка остаётся полупрозрачной")
	GameState.reset()

func test_mouse_turns_camera() -> void:
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	add_child_autofree(rig)
	var before: Basis = rig.yaw_basis()
	rig.turn_by_pixels(100.0)
	assert_false(rig.yaw_basis().is_equal_approx(before), "100 px мыши поворачивают камеру")

func test_locomotion_clips_loop() -> void:
	# Ревью: idle/walk/run без зацикливания останавливаются через 1,7 с.
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["idle", "walk", "run", "hide"]:
		assert_eq(ap.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, "клип %s должен зацикливаться" % clip)

func test_cat_recolors_on_skin_change() -> void:
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	var found := false
	for mi in cat.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
			if m and m.resource_name == "sr_cat_orange":
				found = true
				assert_eq(m.albedo_color.to_html(false), "394151", "тело перекрашено в чёрный")
	assert_true(found, "у кота есть поверхность тела")
	GameState.reset()

func test_eye_sets_exist_and_only_normal_is_visible() -> void:
	var cat = _spawn()
	var names := []
	for mi in cat.find_children("eyes_*", "MeshInstance3D", true, false):
		names.append(String(mi.name))
		assert_null((mi as MeshInstance3D).material_overlay, "у глаз нет обводки: 6 мм на 3-см глазу — рамка")
	names.sort()
	assert_eq(names, ["eyes_blink", "eyes_dizzy", "eyes_happy", "eyes_normal", "eyes_scared"])
	assert_eq(cat.face.expression, &"normal")
	assert_true(cat.find_child("eyes_normal", true, false).visible)
	assert_false(cat.find_child("eyes_scared", true, false).visible)

func test_expression_priority_and_timers() -> void:
	# Review Focus 2
	GameState.reset()
	var cat = _spawn()
	await wait_physics_frames(2)
	cat.cheer()
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"happy")
	assert_true(cat.find_child("eyes_happy", true, false).visible)
	cat.threaten()
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"scared", "испуг важнее довольного")
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"dizzy", "оглушение важнее всего")
	await wait_seconds(1.3)   # STUN_TIME 1,0; испуг (0,4) и довольство (1,0) к этому времени погасли
	assert_eq(cat.face.expression, &"normal", "все выражения снимаются сами")
	assert_true(cat.find_child("eyes_normal", true, false).visible)

func test_black_skin_keeps_eye_colors() -> void:
	# Review Focus 1
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	var eyes := cat.find_child("eyes_normal", true, false) as MeshInstance3D
	var white := false
	var ink := false
	for i in eyes.mesh.get_surface_count():
		var c := (eyes.get_surface_override_material(i) as StandardMaterial3D).albedo_color
		if c.r > 0.9 and c.g > 0.9 and c.b > 0.85:
			white = true
		if c.r < 0.3 and c.g < 0.3 and c.b < 0.4:
			ink = true
	assert_true(white, "белок остался светлым при чёрном скине")
	assert_true(ink, "зрачок графитовый")
	GameState.reset()

func test_blink_only_over_normal_and_releases() -> void:
	# Review Focus 4
	GameState.reset()
	var cat = _spawn()
	await wait_physics_frames(2)
	cat.face.blink_in = 0.0
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"blink", "пора моргнуть")
	assert_true(cat.find_child("eyes_blink", true, false).visible)
	await wait_seconds(0.3)
	assert_eq(cat.face.expression, &"normal", "глаза открылись через 0,12 с")
	cat.threaten()
	cat.face.blink_in = 0.0
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"scared", "испуг не перебивается морганием")

const FEET := ["Bone.016", "Bone.019", "Bone.010", "Bone.013"]
var _world := {}   # ключ -> {кость: мировая позиция}

func _capture_world(skel: Skeleton3D, key: String) -> void:
	skel.skeleton_updated.connect(func() -> void:
		var d := {}
		for b in FEET + ["Bone"]:
			d[b] = skel.global_transform * skel.get_bone_global_pose(skel.find_bone(b)).origin
		_world[key] = d)

func test_short_legs_keep_feet_on_the_ground() -> void:
	# Review Focus 3 (ревью плана 5): мерить в мировых координатах — ось Y скелета кота идёт вдоль тела, верх — +Z скелета.
	var plain := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	var short := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	add_child_autofree(plain)
	add_child_autofree(short)
	var ls := LegScaler.new()
	short.find_child("Skeleton3D", true, false).add_child(ls)
	_capture_world(plain.find_child("Skeleton3D", true, false), "plain")
	_capture_world(short.find_child("Skeleton3D", true, false), "short")
	var scale: float = (short.find_child("Skeleton3D", true, false) as Skeleton3D).global_transform.basis.get_scale().y
	for clip in ["idle", "walk", "run"]:
		for n in [plain, short]:
			(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).play(clip)
			(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).seek(0.3, true)
		await wait_process_frames(3)
		assert_gt(ls.drop, 0.0, "просадка корня посчитана из rest-позы")
		for b in FEET:
			var dy: float = (_world["short"][b] as Vector3).y - (_world["plain"][b] as Vector3).y
			assert_almost_eq(dy, 0.0, 0.012, "%s: стопа %s на той же высоте (м)" % [clip, b])
		var root_d: Vector3 = (_world["short"]["Bone"] as Vector3) - (_world["plain"]["Bone"] as Vector3)
		assert_almost_eq(root_d.y, -ls.drop * scale, 0.006, "%s: корень опустился вниз на drop в метрах" % clip)
		assert_lt(Vector2(root_d.x, root_d.z).length(), 0.006, "%s: корень не уехал по горизонтали" % clip)

var _tail_basis := {}

func test_tail_wiggle_adds_motion_on_top_of_the_clip() -> void:
	# Два экземпляра на одном кадре idle: с TailWiggle и без; итог модификатора виден только в skeleton_updated.
	var plain := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	var wig := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	add_child_autofree(plain)
	add_child_autofree(wig)
	wig.find_child("Skeleton3D", true, false).add_child(TailWiggle.new())
	var pair := {"plain": plain, "wig": wig}
	for key in pair:
		var n: Node = pair[key]
		(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).play("idle")
		var skel := n.find_child("Skeleton3D", true, false) as Skeleton3D
		var idx := skel.find_bone("Bone.006")
		skel.skeleton_updated.connect(func() -> void: _tail_basis[key] = skel.get_bone_global_pose(idx).basis)
	await wait_seconds(0.15)
	assert_false((_tail_basis["wig"] as Basis).is_equal_approx(_tail_basis["plain"]), "хвост с модификатором отличается от клипа на том же кадре")

func _spawn_on_floor() -> Node:
	var world := Node3D.new()
	add_child_autofree(world)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	body.add_child(shape)
	world.add_child(body)
	var cat = (load(CAT_SCENE) as PackedScene).instantiate()
	cat.position = Vector3(0, 0.05, 0)
	world.add_child(cat)
	return cat

func test_landing_squashes_and_puffs_dust() -> void:
	var cat = _spawn_on_floor()
	await wait_physics_frames(10)
	Input.action_press("jump")   # velocity.y снаружи гасится шагом на полу: прыгаем по-настоящему
	await wait_physics_frames(3)
	Input.action_release("jump")
	assert_false(cat.is_on_floor())
	var before := get_tree().get_nodes_in_group("dust")
	var frames := 0
	while not cat.is_on_floor() and frames < 90:   # ждём сам момент приземления: твин сквоша живёт 0,24 с
		await wait_physics_frames(1)
		frames += 1
	assert_true(cat.is_on_floor(), "приземлился")
	var fresh := get_tree().get_nodes_in_group("dust").filter(func(n): return not before.has(n))
	assert_gt(fresh.size(), 0, "пыль при приземлении (новый узел, не стартовый)")
	var model := cat.get_node("Model") as Node3D
	assert_lt(model.scale.y, 0.95, "сплющен сразу после приземления")
	await wait_seconds(0.4)
	assert_almost_eq(model.scale.y, 1.0, 0.02, "форма вернулась")

func test_flash_turns_white_then_restores_skin() -> void:
	# Review Focus 1
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	cat.flash(0.1)
	assert_true(cat.flashing)
	assert_eq(_body_material(cat).albedo_color.to_html(false), "ffffff", "вспышка белым")
	await wait_seconds(0.25)
	assert_false(cat.flashing)
	assert_eq(_body_material(cat).albedo_color.to_html(false), "394151", "после вспышки — цвет надетого скина, не базовый рыжий")
	GameState.reset()

func test_hit_flashes_and_shakes_camera() -> void:
	var cat = _spawn()
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	rig.target = cat
	cat.camera_rig = rig
	add_child_autofree(rig)
	await wait_physics_frames(2)
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	assert_true(cat.flashing)
	assert_gt(rig.shake_left, 0.0, "камера трясётся")
	await wait_physics_frames(2)
	assert_gt((rig.get_node("SpringArm3D") as SpringArm3D).position.length(), 0.001, "пружина смещена шумом")
```

## `tests/integration/test_cyclist.gd`

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
	var floor_body := StaticBody3D.new()   # без пола кот проваливается под дорогу раньше, чем проедет велосипед
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
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

func test_cyclist_model_faces_direction_of_motion() -> void:
	var c = _cyclist(0.1, 0.1)
	await wait_seconds(0.35)
	assert_true(c.riding)
	var p0: Vector3 = c.global_position
	await wait_physics_frames(6)
	var motion: Vector3 = (c.global_position - p0).normalized()
	var model := c.get_node("Model") as Node3D
	var wheel_f := model.find_child("cyclist_wheel_f", true, false) as Node3D
	var wheel_b := model.find_child("cyclist_wheel_b", true, false) as Node3D
	var front_dir: Vector3 = (wheel_f.global_position - wheel_b.global_position).normalized()
	assert_gt(motion.dot(front_dir), 0.9, "переднее колесо впереди по ходу движения")

func test_cyclist_dust_only_while_riding() -> void:
	var c = _cyclist(0.2, 0.2)
	var dust := c.find_child("Dust", false, false) as CPUParticles3D
	assert_not_null(dust, "пыль за колесом")
	if dust == null:
		return
	assert_false(dust.emitting, "до выезда пыли нет")
	await wait_seconds(0.6)
	assert_true(c.riding)
	assert_true(dust.emitting, "в пути пылит")
```

## `tests/integration/test_day_night.gd`

```gdscript
extends GutTest

const LightingScene := preload("res://scenes/world/lighting.tscn")
const DogScene := preload("res://scenes/hazards/dog.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")

var light
var dn

func before_each() -> void:
	GameState.reset()
	light = LightingScene.instantiate()
	add_child_autofree(light)
	dn = light.get_node("DayNight")
	await wait_process_frames(1)

func after_each() -> void:
	get_tree().paused = false

func test_light_follows_time() -> void:
	dn.set_time(50.0)
	var sun := light.get_node("Sun") as DirectionalLight3D
	assert_almost_eq(sun.light_energy, 1.2, 0.01)
	dn.set_time(220.0)
	assert_almost_eq(sun.light_energy, 0.22, 0.01)
	var env: Environment = (light.get_node("WorldEnvironment") as WorldEnvironment).environment
	assert_almost_eq(env.ambient_light_energy, 0.18, 0.01)
	assert_eq(((env.sky.sky_material as ProceduralSkyMaterial).sky_top_color).to_html(false), "0b1633")
	assert_eq(dn.phase, &"night")
	assert_true(DayNight.is_night(get_tree()))

func test_phase_signal_and_lamps() -> void:
	var lamp := SpotLight3D.new()
	lamp.add_to_group("night_lights")
	add_child_autofree(lamp)
	watch_signals(dn)
	dn.set_time(50.0)
	assert_false(lamp.visible, "днём фонарь выключен")
	dn.set_time(200.0)
	assert_signal_emitted_with_parameters(dn, "phase_changed", [&"night"])
	assert_true(lamp.visible, "ночью фонарь горит")

func test_windows_glow_at_night() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "wall", "pos": [0, 0, 0]}]})
	var glass: MeshInstance3D = null
	for mi in b.find_children("wall_glass*", "MeshInstance3D", true, false):
		glass = mi
	assert_not_null(glass, "у стены есть стёкла")
	if glass == null:
		return
	dn.set_time(50.0)
	assert_false((glass.get_surface_override_material(0) as StandardMaterial3D).emission_enabled, "днём окна не светятся")
	dn.set_time(220.0)
	var m := glass.get_surface_override_material(0) as StandardMaterial3D
	assert_true(m.emission_enabled, "ночью в окнах тёплый свет")
	assert_eq(m.emission.to_html(false), "ffd9a0")

func test_lamp_head_glows_at_night() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "lamp", "pos": [0, 0, 0]}]})
	var head := b.find_child("lamp_head", true, false) as MeshInstance3D
	assert_not_null(head)
	if head == null:
		return
	dn.set_time(220.0)
	await wait_process_frames(1)
	assert_true((head.get_surface_override_material(0) as StandardMaterial3D).emission_enabled, "плафон светится ночью")

func test_time_advances_and_pause_stops_it() -> void:
	# Review Focus 1
	dn.set_time(10.0)
	dn.time_scale = 20.0
	await wait_seconds(0.2)
	assert_gt(dn.time, 12.0, "время идёт")
	get_tree().paused = true
	var t0: float = dn.time
	await get_tree().create_timer(0.2, true).timeout
	assert_almost_eq(dn.time, t0, 0.001, "на паузе цикл стоит")

func test_dog_sleeps_through_the_night_and_wakes_by_day() -> void:
	# Review Focus 3
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, -4)
	add_child_autofree(cat)
	var dog = DogScene.instantiate()
	dog.position = Vector3(0, 0.05, 0)
	add_child_autofree(dog)
	dn.set_time(220.0)
	await wait_physics_frames(3)
	assert_false(dog.sees_cat(), "ночью собака спит и не замечает кота")
	dn.set_time(50.0)
	await wait_physics_frames(3)
	assert_true(dog.sees_cat(), "днём снова видит")

func test_without_day_night_it_is_day() -> void:
	# Review Focus 2
	light.free()
	await wait_process_frames(1)
	assert_false(DayNight.is_night(get_tree()))
	assert_eq(DayNight.current_phase(get_tree()), &"day")

func test_hud_shows_phase_icon() -> void:
	var hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)
	dn.set_time(50.0)
	var icon := hud.get_node("%PhaseIcon") as TextureRect
	assert_eq(icon.texture.resource_path, "res://assets/images/ui/sun.png")
	dn.set_time(200.0)
	assert_eq(icon.texture.resource_path, "res://assets/images/ui/moon.png")

func test_hold_phases_do_not_rewrite_light_every_frame() -> void:
	# Ревью плана 7 (I1): в фазах удержания небо и материалы не перезаписываются каждый кадр.
	dn.set_time(50.0)
	var w0: int = dn.light_writes
	dn.set_time(60.0)
	dn.set_time(70.0)
	assert_eq(dn.light_writes, w0, "днём свет постоянен — записей нет")
	dn.set_time(160.0)
	assert_gt(dn.light_writes, w0, "на закате свет меняется")

func test_lamp_added_at_night_lights_up() -> void:
	dn.set_time(220.0)
	var lamp := SpotLight3D.new()
	lamp.visible = false
	lamp.add_to_group("night_lights")
	add_child_autofree(lamp)
	await wait_process_frames(2)
	assert_true(lamp.visible, "фонарь, построенный ночью, горит")

func test_night_ends_an_ongoing_chase() -> void:
	# Ревью плана 7 (M1): ночь, наступившая посреди погони, укладывает собаку спать.
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, -4)
	add_child_autofree(cat)
	var dog = DogScene.instantiate()
	dog.position = Vector3(0, 0.05, 0)
	add_child_autofree(dog)
	dn.set_time(50.0)
	dn.time_scale = 0.0
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	dn.set_time(220.0)
	await wait_physics_frames(3)
	assert_true(dog.brain.state in [ChaseBrain.State.RETURN, ChaseBrain.State.IDLE], "ночью погоня прекращается")

func test_two_lighting_instances_do_not_share_sky() -> void:
	# Ревью плана 7 (M2)
	var other = LightingScene.instantiate()
	add_child_autofree(other)
	await wait_process_frames(1)
	other.get_node("DayNight").time_scale = 0.0
	dn.set_time(220.0)
	var sky_other := ((other.get_node("WorldEnvironment") as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial)
	assert_ne(sky_other.sky_top_color.to_html(false), "0b1633", "у второй сцены своё небо")

func test_hud_binds_even_if_created_before_lighting() -> void:
	# Ревью плана 7 (M3)
	light.free()
	var hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)
	var l2 = LightingScene.instantiate()
	add_child_autofree(l2)
	l2.get_node("DayNight").set_time(220.0)
	await wait_process_frames(2)
	assert_eq((hud.get_node("%PhaseIcon") as TextureRect).texture.resource_path, "res://assets/images/ui/moon.png")

func test_phase_names_parse() -> void:
	assert_almost_eq(DayCycle.parse_time("night"), 225.0, 0.01)
	assert_almost_eq(DayCycle.parse_time("evening"), 165.0, 0.01)
	assert_almost_eq(DayCycle.parse_time("120"), 120.0, 0.01)
```

## `tests/integration/test_dog.gd`

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
	# Позиции до add_child: пары Area3D берутся по позициям в момент добавления, и кот, созданный
	# в точке собаки, ловил удар на первом кадре, куда бы его потом ни переставили.
	cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, 8)   # за спиной и далеко
	world.add_child(cat)
	dog = DogScene.instantiate()
	dog.position = Vector3(0, 0.05, 0)   # смотрит по -Z
	world.add_child(dog)

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

func test_dog_faces_home_direction_again_after_chase() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	cat.hidden = true
	cat.global_position = Vector3(0, 0.05, -12)
	dog.walk_speed = 8.0
	await wait_seconds(4.5)
	assert_eq(dog.brain.state, ChaseBrain.State.IDLE, "вернулась и спит")
	cat.hidden = false
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(0.8)
	assert_true(dog.sees_cat(), "после возврата снова смотрит туда же и видит кота")

func test_quiet_upgrade_narrows_dog_cone() -> void:
	cat.global_position = Vector3(3.0, 0.05, -3.4)   # ≈41° от носа собаки: внутри 45°, вне 31,5°
	await wait_physics_frames(3)
	assert_true(dog.sees_cat(), "без улучшения видит на 41°")
	GameState.add_yarn(10)
	GameState.buy(ShopCatalog.get_by_id(&"quiet"))
	dog.rotation.y = 0.0   # за эти кадры собака уже начала поворачиваться к коту
	assert_false(dog.sees_cat(), "с тихими шагами конус 31,5° — не видит")

func test_safe_zone_cancels_chase() -> void:
	# Review Focus 5 плана 3, ужесточено планом 4: «в будку собаки не заходят» — уходит сразу.
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	cat.in_safe_zone = true
	await wait_physics_frames(3)
	assert_eq(dog.brain.state, ChaseBrain.State.RETURN, "в безопасной зоне собака разворачивается сразу")

func test_idle_dog_plays_sleep_clip() -> void:
	await wait_physics_frames(3)
	var ap := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("sleep"), "в dog.glb есть клип sleep")
	assert_eq(ap.current_animation, "sleep")
	assert_eq(ap.get_animation("sleep").loop_mode, Animation.LOOP_LINEAR)

func test_chasing_dog_scares_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(0.5)
	assert_eq(dog.brain.state, ChaseBrain.State.ALERT)
	assert_eq(cat.face.expression, &"scared", "насторожившаяся собака пугает кота")
	cat.global_position = Vector3(0, 0.05, 12)   # дальше 6 м: собака ещё гонится, но угрозы рядом нет
	await wait_seconds(0.8)
	assert_eq(cat.face.expression, &"normal", "испуг гаснет без сигналов от собаки")

func test_dog_contact_plays_hit_once_and_barks_on_alert() -> void:
	# Review Focus 3
	Sfx.reset_counters()
	cat.global_position = Vector3(0, 0.05, -0.2)   # перед носом: собака сразу настораживается и бьёт касанием
	await wait_physics_frames(30)   # полсекунды в зоне собаки
	assert_eq(GameState.hearts, 2)
	assert_eq(Sfx.counts.get(&"hit", 0), 1, "один удар — один звук, не по кадрам")
	assert_eq(Sfx.counts.get(&"meow", 0), 1)
	assert_eq(Sfx.counts.get(&"bark", 0), 1, "лай при входе в ALERT, один раз за настороженность")

func test_sleeping_dog_emits_zzz() -> void:
	await wait_seconds(1.5)
	assert_eq(dog.brain.state, ChaseBrain.State.IDLE)
	var zs := 0
	for n in get_tree().get_nodes_in_group("fx"):
		if n is Label3D and n.text == "z":
			zs += 1
	assert_gt(zs, 0, "над спящей собакой всплывает «z»")

func test_dog_returns_home_onto_terrace_even_through_wall() -> void:
	# Ревью плана 11: собака с террасы шла домой по прямой, упиралась в подпорную стену и стояла так до конца игры.
	var t := Terrain.new()
	t.data_path = "res://data/terrain/demo.json"   # терраса 2 м: x −18…−6, z −18…−8, обрыв x −6…−5
	world.add_child(t)
	var b := WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build({"props": [{"model": "retaining_wall2", "pos": [-5.5, 0, -13], "rot": 90, "snap": false}]})
	var d = DogScene.instantiate()
	d.position = Vector3(-12, 2.05, -13)
	world.add_child(d)
	await wait_physics_frames(3)   # дом — на террасе
	d.global_position = Vector3(-2, 0.1, -13)   # погоня увела вниз, за стену
	d.brain.state = ChaseBrain.State.RETURN
	await wait_seconds(10.0)
	assert_lt(d.global_position.distance_to(Vector3(-12, 2.05, -13)), 1.0, "собака вернулась домой на террасу")
	assert_ne(d.brain.state, ChaseBrain.State.RETURN, "возврат закончился")
```

## `tests/integration/test_dog_asset.gd`

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

func test_dog_has_sleep_clip_of_two_seconds() -> void:
	var dog := (load("res://assets/models/dog.glb") as PackedScene).instantiate()
	add_child_autofree(dog)
	var ap := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("sleep"))
	assert_between(ap.get_animation("sleep").length, 1.8, 2.2)
```

## `tests/integration/test_effects.gd`

```gdscript
extends GutTest

func test_burst_creates_one_shot_particles_with_color() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var p := Effects.burst(root, Vector3(1, 2, 3), Color.RED)
	assert_true(p.one_shot)
	assert_true(p.emitting)
	assert_eq(p.color, Color.RED)
	assert_eq(p.global_position, Vector3(1, 2, 3))
	assert_true(p.is_in_group("fx"))
	assert_gt(p.amount, 0)

func test_dust_hearts_sparkles_trail_leaves_zzz_factories() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var d := Effects.dust(root, Vector3.ZERO)
	assert_true(d.one_shot and d.emitting)
	assert_eq(d.color.to_html(false), "d3ab87")
	var h := Effects.hearts(root, Vector3.ZERO)
	assert_true(h.mesh is QuadMesh)
	assert_not_null((h.mesh.material as StandardMaterial3D).albedo_texture, "сердечки — спрайт сгенерированной иконки")
	var s := Effects.sparkles(root, Color.BLUE)
	assert_false(s.one_shot, "искры постоянные")
	assert_eq(s.color, Color.BLUE)
	var t := Effects.trail(root, Color.GRAY)
	assert_false(t.one_shot)
	var z := Effects.zzz(root, Vector3(0, 1, 0))
	assert_eq(z.text, "z")
	var l := Effects.leaves(root)
	assert_eq(l.amount, 40)
	assert_false(l.one_shot)
	assert_gte(l.position.y - l.emission_box_extents.y, 0.0, "листья рождаются над землёй, не под ней")
```

## `tests/integration/test_floater.gd`

```gdscript
extends GutTest
## План 13: кот стоит на качающейся лодке (спек порта, раздел 2).

const CatScene := preload("res://scenes/player/cat.tscn")
const DECK := [{"size": [1.6, 0.75, 4.2], "offset": [0, 0.075, 0]}]

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func test_cat_rides_bobbing_boat() -> void:
	var b := WorldBuilder.new()
	world.add_child(b)
	b.build({"floaters": [{"model": "boat", "pos": [0, -2.3, 0], "rot": 0, "period": 3.0, "phase": 0.0, "colliders": DECK}]})
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, -1.8, 0.5)
	world.add_child(cat)
	var lo := 99.0
	var hi := -99.0
	for i in 240:
		await wait_physics_frames(1)
		if i > 30:
			lo = minf(lo, cat.global_position.y)
			hi = maxf(hi, cat.global_position.y)
	assert_gt(lo, -2.0, "кот не провалился сквозь лодку")
	assert_gt(hi - lo, 0.1, "кот качается вместе с лодкой")

func test_builder_builds_floaters_with_their_phases() -> void:
	var b := WorldBuilder.new()
	world.add_child(b)
	b.build({"floaters": [{"model": "barrel", "pos": [0, -2.7, 0], "phase": 0.5}, {"model": "barrel", "pos": [2, -2.7, 0], "phase": 2.0}]})
	var f := b.find_children("*", "Floater", true, false)
	assert_eq(f.size(), 2)
	if f.size() == 2:
		assert_ne((f[0] as Floater).phase, (f[1] as Floater).phase)
		assert_not_null((f[0] as Floater).get_node_or_null("Model"), "у опоры есть модель")
```

## `tests/integration/test_food.gd`

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
	_cat_at(Vector3(5, 0.05, 5))
	await wait_physics_frames(3)
	assert_eq(GameState.mouth.size(), 0, "в первые 0,5 с не подбирается")
	await wait_seconds(0.7)
	assert_true(not is_instance_valid(p) or p.is_queued_for_deletion(), "истёк срок жизни")

func test_spilled_food_under_standing_cat_is_picked_after_grace() -> void:
	# Ревью: после паузы подбор должен возобновиться даже если кот не двигался.
	var p = PickupScene.instantiate()
	p.setup(FoodCatalog.get_by_id(&"fish"), true, 3.0)
	world.add_child(p)
	p.global_position = Vector3(0, 0.05, 0)
	_cat_at(Vector3(0, 0.05, 0))
	await wait_physics_frames(3)
	assert_eq(GameState.mouth.size(), 0, "в первые 0,5 с не подбирается")
	await wait_seconds(0.7)
	assert_eq(GameState.mouth.size(), 1, "через 0,5 с еда под котом подобрана")

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

func test_rare_food_sparkles_common_does_not() -> void:
	var rare := PickupScene.instantiate() as FoodPickup
	rare.setup(FoodCatalog.get_by_id(&"pizza"))
	add_child_autofree(rare)
	var plain := PickupScene.instantiate() as FoodPickup
	plain.setup(FoodCatalog.get_by_id(&"cookie"))
	add_child_autofree(plain)
	assert_not_null(rare.find_child("Sparkles", false, false), "редкая еда искрится")
	if rare.find_child("Sparkles", false, false):
		assert_eq((rare.find_child("Sparkles", false, false) as CPUParticles3D).color, Rarity.COLORS[Rarity.Tier.RARE])
	assert_null(plain.find_child("Sparkles", false, false), "обычная — нет")
```

## `tests/integration/test_gate.gd`

```gdscript
extends GutTest

const GateScene := preload("res://scenes/world/gate.tscn")
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

func test_gate_blocks_until_satiety_then_opens() -> void:
	var gate = GateScene.instantiate()
	world.add_child(gate)
	gate.global_position = Vector3(0, 0, -2)
	await wait_physics_frames(2)
	assert_false(gate.open)
	assert_eq(gate.collision_layer, Layers.WORLD)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	Input.action_press("move_forward")
	await wait_seconds(2.0)
	Input.action_release("move_forward")
	assert_gt(cat.global_position.z, -1.9, "закрытые ворота не пускают")
	watch_signals(gate)
	GameState.satiety = 10
	GameState.satiety_changed.emit(10)
	await wait_physics_frames(2)
	assert_true(gate.open)
	assert_signal_emitted(gate, "opened")
	assert_eq(gate.collision_layer, 0)
	Input.action_press("move_forward")
	await wait_seconds(1.5)
	Input.action_release("move_forward")
	assert_lt(cat.global_position.z, -2.1, "открытые ворота пропускают")

func test_gate_starts_open_if_satiety_already_enough() -> void:
	GameState.satiety = 12
	var gate = GateScene.instantiate()
	world.add_child(gate)
	await wait_physics_frames(1)
	assert_true(gate.open, "со второго запуска ворота уже открыты")
```

## `tests/integration/test_hideout.gd`

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

## `tests/integration/test_hit.gd`

```gdscript
extends GutTest

const MainScene := preload("res://scenes/main.tscn")

var main
var cat

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(30)
	cat = main.find_child("Cat", true, false)

func after_each() -> void:
	SaveGame.clear()

func test_main_autosaves_on_progress() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	GameState.eat_all()
	await wait_process_frames(1)
	assert_true(FileAccess.file_exists(SaveGame.path), "после съедания прогресс сохранён")

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
	var spawn: Vector3 = main.respawn_position()
	assert_lt(cat.global_position.distance_to(spawn), 0.5)
	assert_true(cat.in_safe_zone or main.find_child("YarnShop", true, false) == null, "возрождение в будке")
	assert_gt(cat.invulnerable_left, 1.5, "после возрождения кот неуязвим ~2 с")
	for h in get_tree().get_nodes_in_group("hazards"):
		if h.has_method("reset_pursuit"):
			assert_eq(h.brain.state, ChaseBrain.State.IDLE, "опасности сброшены после возрождения")

func test_spilled_food_lands_on_surface_below() -> void:
	# Ревью плана 4: еда на pos.y висела в воздухе вокруг стола кафе и балкона (радиус разлёта 1–2 м больше столешницы).
	var spawner: SpillSpawner = main.find_child("SpillSpawner", true, false)
	spawner.rng.seed = 7   # детерминированный разлёт
	cat.global_position = Vector3(0, 0.95, 17)   # стол кафе, верх 0,75
	await wait_physics_frames(10)
	assert_almost_eq(cat.global_position.y, 0.75, 0.05, "кот стоит на столе")
	var foods := []
	for i in 6:
		foods.append(FoodCatalog.get_by_id(&"cookie"))
	var out: Array = spawner.spill_around(cat.global_position, foods)
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var on_ground := 0
	for p in out:
		var pos: Vector3 = (p as Node3D).global_position
		assert_lt(pos.y, 0.76, "не выше стола")
		# Под едой сразу есть поверхность (земля, стол, стул): луч 5 см вниз во что-то упирается.
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.04, 0), pos + Vector3(0, -0.05, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "еда касается поверхности под собой, не висит: y=%.2f" % pos.y)
		if pos.y < 0.1:
			on_ground += 1
	assert_gt(on_ground, 0, "в 1–2 м от стола часть еды падает на землю")
```

## `tests/integration/test_hud.gd`

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
	assert_eq(hud.hearts_text(), "3/3")
	GameState.take_hit()
	assert_eq(hud.hearts_text(), "2/3")

func test_mouth_slots_show_names() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))
	assert_eq(hud.mouth_names(), ["Пицца", "", ""])

func test_satiety_and_goal_labels() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	GameState.eat_all()
	# Полоска показывает прогресс до порога арки (10) и упирается в максимум.
	assert_eq((hud.get_node("%Satiety") as ProgressBar).value, 15.0, "после кафе полоска считает до парка (25)")
	assert_eq((hud.get_node("%Goal") as Label).text, "Открой новых карточек: 1/3")

func test_bell_flash_shows_and_hides() -> void:
	hud.flash_bell("🔔 Велосипед!", 0.1)
	assert_true((hud.get_node("%BellPanel") as PanelContainer).visible)
	await wait_seconds(0.25)
	assert_false((hud.get_node("%BellPanel") as PanelContainer).visible)

func test_mouth_slots_grow_with_capacity_upgrade() -> void:
	assert_eq(hud.mouth_names().size(), 3)
	GameState.add_yarn(20)
	GameState.buy(ShopCatalog.get_by_id(&"mouth_4"))
	GameState.buy(ShopCatalog.get_by_id(&"mouth_5"))
	await wait_process_frames(1)
	assert_eq(hud.mouth_names().size(), 5, "после улучшения видны пять слотов")
	for id in ["sausage", "cookie", "pizza", "hotdog", "fish"]:
		GameState.pick_up(FoodCatalog.get_by_id(StringName(id)))
	assert_eq(hud.mouth_names()[4], "Рыба", "пятая еда видна в HUD")

func test_mouth_slot_shows_food_icon() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))
	var icon := hud.get_node("%Mouth").get_child(0).find_child("Icon", true, false) as TextureRect
	assert_not_null(icon.texture, "в слоте иконка пиццы")
	if icon.texture:
		assert_eq(icon.texture.resource_path, "res://assets/images/ui/food_pizza.png")
	GameState.eat_all()
	assert_null((hud.get_node("%Mouth").get_child(0).find_child("Icon", true, false) as TextureRect).texture, "пустой слот без иконки")

func test_hud_elements_sit_on_white_panels() -> void:
	# Спек 2.6: сердечки, сытость и клубочки на одной плашке; цель и звонок — на своих.
	for path in ["%Hearts", "%Satiety", "%Yarn", "%Goal", "%Bell"]:
		var n := hud.get_node(path) as Control
		var p := n
		while p and not (p is PanelContainer):
			p = p.get_parent() as Control
		assert_not_null(p, "%s лежит на PanelContainer" % path)
	assert_eq((hud.get_node("%Yarn") as Label).get_theme_color("font_color").to_html(false), "394151", "счётчик клубочков графитовый, читается на любом фоне")

func test_hearts_and_yarn_are_icons() -> void:
	var hearts := hud.get_node("%Hearts") as HBoxContainer
	assert_eq(hearts.get_child_count(), GameState.max_hearts, "по иконке на сердечко")
	for h in hearts.get_children():
		assert_not_null((h as TextureRect).texture, "иконка сердечка из сгенерированной картинки")
	GameState.take_hit()
	assert_lt((hearts.get_child(2) as TextureRect).modulate.a, 0.6, "потерянное сердечко блёклое")
	assert_gt((hearts.get_child(0) as TextureRect).modulate.a, 0.9)
	assert_not_null((hud.get_node("%YarnIcon") as TextureRect).texture, "иконка клубочка")
	assert_eq(hud.yarn_text(), "0")

func test_satiety_target_moves_from_cafe_to_park() -> void:
	# Review Focus 4
	GameState.satiety = 12
	GameState.satiety_changed.emit(12)
	assert_eq(hud.satiety_label_text(), "До парка 12/25")
	assert_almost_eq((hud.get_node("%Satiety") as ProgressBar).max_value, 25.0, 0.01)
	GameState.satiety = 25
	GameState.satiety_changed.emit(25)
	assert_eq(hud.satiety_label_text(), "Парк открыт")
	GameState.satiety = 4
	GameState.satiety_changed.emit(4)
	assert_eq(hud.satiety_label_text(), "Сытость 4/10")
```

## `tests/integration/test_lighting.gd`

```gdscript
extends GutTest

var light

func before_each() -> void:
	light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	add_child_autofree(light)
	await wait_process_frames(1)

func test_sun_is_high_warm_and_soft() -> void:
	var sun := light.get_node("Sun") as DirectionalLight3D
	assert_almost_eq(sun.rotation_degrees.x, -65.0, 0.1)
	assert_almost_eq(sun.rotation_degrees.y, 30.0, 0.1)
	assert_almost_eq(sun.light_energy, 1.2, 0.01)
	assert_true(sun.shadow_enabled)
	assert_almost_eq(sun.light_angular_distance, 1.5, 0.01, "мягкая полутень")
	assert_almost_eq(sun.shadow_blur, 1.5, 0.01)
	assert_eq(sun.directional_shadow_mode, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
	assert_almost_eq(sun.directional_shadow_max_distance, 40.0, 0.1, "каскады на 40 м (спек «Масштаб», раздел 5)")

func test_fill_light_from_the_sky_without_shadows() -> void:
	var fill := light.get_node_or_null("Fill") as DirectionalLight3D
	assert_not_null(fill, "заполняющий свет")
	if fill == null:
		return
	assert_false(fill.shadow_enabled)
	assert_almost_eq(fill.light_energy, 0.25, 0.01)
	assert_almost_eq(fill.rotation_degrees.y, 210.0, 0.1)
	assert_eq(fill.light_color.to_html(false), "9fc4e8")

func test_environment_has_ao_ssr_glow_and_clouds() -> void:
	var env: Environment = (light.get_node("WorldEnvironment") as WorldEnvironment).environment
	assert_eq(env.ambient_light_source, Environment.AMBIENT_SOURCE_SKY)
	assert_almost_eq(env.ambient_light_sky_contribution, 1.0, 0.01)
	assert_almost_eq(env.ambient_light_energy, 0.6, 0.01)
	assert_true(env.ssao_enabled)
	assert_almost_eq(env.ssao_radius, 0.3, 0.01)
	assert_true(env.ssr_enabled, "лужи отражают небо")
	assert_true(env.glow_enabled)
	assert_almost_eq(env.glow_hdr_threshold, 1.2, 0.01)
	assert_eq(env.tonemap_mode, Environment.TONE_MAPPER_LINEAR)
	assert_true(env.adjustment_enabled)
	assert_almost_eq(env.adjustment_saturation, 1.1, 0.01)
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	assert_not_null(sky.sky_cover, "слой облаков из сгенерированной картинки")
	if sky.sky_cover:
		assert_eq(sky.sky_cover.resource_path, "res://assets/images/world/clouds.png")

func test_leaves_drift_over_the_yard() -> void:
	assert_not_null(light.get_node_or_null("Leaves"), "листья по ветру")
```

## `tests/integration/test_main.gd`

```gdscript
extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

func before_each() -> void:
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()

func _spawn_main() -> Node:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	return main

func test_main_spawns_cat_linked_to_camera() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	var cat = main.find_child("Cat", true, false)
	var rig = main.find_child("CameraRig", true, false)
	assert_not_null(cat, "в главной сцене нет Cat")
	assert_not_null(rig, "в главной сцене нет CameraRig")
	if cat == null or rig == null:
		return
	assert_eq(cat.camera_rig, rig)
	assert_eq(rig.target, cat)
	assert_true((rig.get_node("SpringArm3D/Camera3D") as Camera3D).current)

func test_cat_lands_on_ground() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	assert_not_null(cat, "в главной сцене нет Cat")
	if cat == null:
		return
	await wait_physics_frames(90)
	assert_true(cat.is_on_floor(), "кот должен стоять на земле через 1,5 с")
	# Ревью: нижняя точка коллизии должна совпадать с лапами, кот не тонет в землю.
	assert_between(cat.global_position.y, -0.005, 0.02)

func test_cat_walks_and_jumps_on_input() -> void:
	# Замена ручного прогона: нажимаем действия программно.
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(60)
	var start: Vector3 = cat.global_position
	Input.action_press("move_forward")
	await wait_physics_frames(60)
	assert_eq(cat.state, &"walk", "при зажатом вперёд кот идёт")
	assert_lt(cat.global_position.z, start.z - 0.5, "кот должен сдвинуться вперёд (по -Z)")
	Input.action_press("run")
	await wait_physics_frames(60)
	assert_eq(cat.state, &"run", "с Shift кот бежит")
	Input.action_release("run")
	Input.action_release("move_forward")
	await wait_physics_frames(30)
	Input.action_press("jump")
	await wait_physics_frames(3)
	Input.action_release("jump")
	assert_eq(cat.state, &"jump", "после прыжка состояние jump")
	assert_false(cat.is_on_floor())
	await wait_physics_frames(90)
	assert_true(cat.is_on_floor(), "кот приземлился")

func test_cat_keeps_animating_longer_than_one_clip() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	await wait_physics_frames(60)
	Input.action_press("move_forward")
	await wait_physics_frames(150)   # 2,5 с > длины клипа walk (1,67 с)
	Input.action_release("move_forward")
	assert_true(ap.is_playing(), "анимация должна идти дольше одного клипа")
	assert_eq(ap.current_animation, "walk")

func test_eating_spawns_burst_in_rarity_color() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))   # редкая, синяя
	GameState.eat_all()
	var bursts := get_tree().get_nodes_in_group("burst")
	assert_eq(bursts.size(), 1, "один всплеск на съедание")
	assert_eq(get_tree().get_nodes_in_group("hearts").size(), 1, "и сердечки")
	if bursts.size() == 1:
		assert_eq((bursts[0] as CPUParticles3D).color, Rarity.COLORS[Rarity.Tier.RARE])

func test_hit_spawns_star_burst() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(30)
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	var fx := get_tree().get_nodes_in_group("burst")
	assert_eq(fx.size(), 1)
	if fx.size() == 1:
		assert_eq((fx[0] as CPUParticles3D).color, Effects.HIT_COLOR)

func test_eating_plays_eat_sound() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	Sfx.reset_counters()
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.eat_all()
	assert_eq(Sfx.last_played, &"eat")

func test_vignette_overlay_exists_and_ignores_mouse() -> void:
	var main := _spawn_main()
	var rect := main.get_node_or_null("Vignette/Rect") as ColorRect
	assert_not_null(rect)
	if rect == null:
		return
	assert_true(rect.material is ShaderMaterial)
	assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_lt((main.get_node("Vignette") as CanvasLayer).layer, (main.get_node("Hud") as CanvasLayer).layer + 1, "виньетка под HUD")

func test_fall_below_kill_plane_returns_cat_to_shop_without_penalty() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(5)
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(0, -6, 0)
	await wait_physics_frames(3)
	assert_lt(cat.global_position.distance_to(main.respawn_position()), 0.5, "кот вернулся к будке")
	assert_eq(GameState.hearts, 3, "падение не отнимает сердечко")
	assert_true(GameState.mouth.is_empty(), "еда из зубов потеряна")

func test_kill_plane_ignores_balcony_and_tables() -> void:
	# Review Focus 5
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(5)
	for p in [Vector3(-11.3, 1.2, -9.0), Vector3(0, 0.95, 17)]:
		cat.global_position = p
		await wait_physics_frames(3)
		assert_gt(cat.global_position.y, 0.3, "кот на возвышении остаётся на месте: %s" % p)
		assert_gt(cat.global_position.distance_to(main.respawn_position()), 2.0)

func test_faint_loses_carried_food_instead_of_spilling() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(5)
	GameState.take_hit()
	GameState.take_hit()   # осталось одно сердечко
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.invulnerable_left = 0.0
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	assert_eq(GameState.hearts, 0)
	assert_eq(get_tree().get_nodes_in_group("spilled_food").size(), 0, "при обмороке еда потеряна, не рассыпана (спек 3.2)")
```

## `tests/integration/test_menus.gd`

```gdscript
extends GutTest

const MainScene := preload("res://scenes/main.tscn")
const CyclistScene := preload("res://scenes/hazards/cyclist.tscn")

var main
var cat

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(20)
	cat = main.find_child("Cat", true, false)

func after_each() -> void:
	get_tree().paused = false
	SaveGame.clear()

func test_album_shows_cards_locked_and_unlocked() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))
	GameState.eat_all()
	main.toggle_album()
	assert_true(main.album_menu.is_open)
	assert_true(get_tree().paused)
	var cards: Array = main.album_menu.cards()
	assert_eq(cards.size(), 20, "8 карточек двора, 6 парка и 6 порта")
	var pizza: Control = null
	var donut: Control = null
	for c in cards:
		if c.name == "pizza":
			pizza = c
		if c.name == "donut":
			donut = c
	assert_eq((pizza.get_node("Name") as Label).text, "Пицца")
	assert_eq((pizza.get_node("Count") as Label).text, "×1")
	assert_eq((donut.get_node("Name") as Label).text, "???")
	assert_almost_eq(donut.modulate.a, 0.4, 0.01)
	assert_eq((donut.get_node("Rarity") as ColorRect).color, Rarity.COLORS[Rarity.Tier.LEGENDARY])
	assert_not_null((pizza.get_node("Icon") as TextureRect).texture, "у карточки иконка")
	assert_lt((donut.get_node("Icon") as TextureRect).self_modulate.r, 0.5, "закрытая карточка — тёмный силуэт")
	main.toggle_album()
	assert_false(main.album_menu.is_open)
	assert_false(get_tree().paused, "после закрытия альбома игра не заморожена")

func test_pause_stops_cyclist_and_resume_unfreezes() -> void:
	# Review Focus 4
	var c = CyclistScene.instantiate()
	c.interval_min = 0.2
	c.interval_max = 0.2
	c.bell_lead = 0.1
	main.add_child(c)
	c.set_path(main.find_child("Road", true, false))
	watch_signals(c)
	main.toggle_pause()
	assert_true(main.pause_menu.is_open)
	assert_true(get_tree().paused)
	# Ожидания GUT сами стоят на паузе, поэтому ждём таймером с process_always = true.
	await get_tree().create_timer(0.6, true).timeout
	assert_signal_not_emitted(c, "bell", "во время паузы велосипедист не звонит")
	var p0: Vector3 = cat.global_position
	Input.action_press("move_forward")
	await get_tree().create_timer(0.3, true).timeout
	Input.action_release("move_forward")
	assert_lt(cat.global_position.distance_to(p0), 0.05, "кот стоит на паузе")
	main.toggle_pause()
	assert_false(get_tree().paused)
	await wait_seconds(0.6)
	assert_signal_emitted(c, "bell", "после паузы цикл продолжился")

func test_reset_progress_clears_save_and_state() -> void:
	GameState.add_yarn(7)
	SaveGame.save_now()
	main.toggle_pause()
	main.reset_progress()
	assert_eq(GameState.yarn, 0)
	assert_false(FileAccess.file_exists(SaveGame.path), "после сброса файла сохранения нет (reset() не должен тут же писать нули)")
	assert_false(get_tree().paused)

func test_title_offers_continue_only_with_save() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/ui/title.tscn")
	var title := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title.switch_scenes = false
	add_child_autofree(title)
	assert_false((title.get_node("VBox/Continue") as Button).visible, "без сохранения «Продолжить» скрыта")
	assert_eq((title.get_node("VBox/Play") as Button).text, "Новая игра")
	assert_not_null((title.get_node("Background") as TextureRect).texture, "фон заставки — арт")
	SaveGame.save_now()
	var title2 := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title2.switch_scenes = false
	add_child_autofree(title2)
	assert_true((title2.get_node("VBox/Continue") as Button).visible, "с сохранением «Продолжить» видна")
	title2.new_game()
	assert_false(FileAccess.file_exists(SaveGame.path), "«Новая игра» стирает сохранение")

func test_ui_cancel_closes_shop_and_album() -> void:
	main.open_shop()
	assert_true(main.shop_menu.is_open)
	Input.action_press("ui_cancel")
	await wait_process_frames(2)
	Input.action_release("ui_cancel")
	assert_false(main.shop_menu.is_open, "B геймпада (ui_cancel) закрывает магазин")
	main.toggle_album()
	assert_true(main.album_menu.is_open)
	Input.action_press("ui_cancel")
	await get_tree().create_timer(0.1, true).timeout
	Input.action_release("ui_cancel")
	assert_false(main.album_menu.is_open, "и альбом")
	assert_false(get_tree().paused)

func test_album_with_twenty_cards_fits_the_window() -> void:
	# План 13: 20 карточек (двор, парк, порт) — панель альбома целиком в окне 1280×720.
	var m := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(m)
	await wait_process_frames(3)
	m.toggle_album()
	await wait_process_frames(3)
	var panel := m.album_menu.get_node("Panel") as Control
	var view := Rect2(Vector2.ZERO, panel.get_viewport_rect().size)
	var need := panel.get_combined_minimum_size()
	# Окно игры 1280×720 (stretch canvas_items): в headless окно другое, поэтому меряем минимальный размер панели.
	assert_lte(need.y, 700.0, "альбом по высоте влезает в 720: %s" % need)
	assert_lte(need.x, 1260.0, "альбом по ширине влезает в 1280: %s" % need)
	m.toggle_album()

func test_dev_album_fill_does_not_touch_the_save() -> void:
	# Ревью плана 13: ++ --album открывал все карточки и сохранял их в настоящий save.json.
	DevTools.fill_album(main)
	assert_false(main.autosave, "кадр альбома не пишет сохранение")
	main.autosave = true
```

## `tests/integration/test_park.gd`

```gdscript
extends GutTest
## План 8: район «Парк» (спек этапа 2, разделы 4–5).

const PARK := "res://data/layout/park.json"

func before_each() -> void:
	GameState.reset()

func _park_with_floor() -> Node3D:
	var world := Node3D.new()
	add_child_autofree(world)
	var t := Terrain.new()
	t.data_path = "res://data/terrain/park.json"   # пол парка — рельеф (план 10)
	world.add_child(t)
	var b := WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(PARK))
	return world

func _prop_at(world: Node3D, point: Vector3) -> String:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = point
	q.collision_mask = Layers.WORLD
	for hit in world.get_world_3d().direct_space_state.intersect_point(q, 8):
		var n: String = hit["collider"].name
		if n != "Floor":
			return n
	return ""

func test_park_layout_has_the_spec_content() -> void:
	var d := WorldBuilder.load_layout(PARK)
	var models := {}
	for p in d["props"]:
		models[p["model"]] = models.get(p["model"], 0) + 1
	for m in ["fountain", "slide", "swings", "sandbox", "kiosk", "shed", "lamp", "bench", "fence", "tree", "flowerbed"]:
		assert_gt(models.get(m, 0), 0, "в парке есть %s" % m)
	assert_gte(models.get("lamp", 0), 8, "аллея фонарей")
	assert_gte(d["yarn"].size(), 25, "парк ×3: не меньше 25 клубочков (спек «Масштаб», раздел 2)")
	var kinds := {}
	for h in d["hideouts"]:
		kinds[h["kind"]] = true
	for k in ["bush", "bench", "slide"]:
		assert_true(kinds.has(k), "укрытие %s" % k)
	assert_eq(int(d["gates"][0]["satiety"]), GameState.PARK_GATE)
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(d)
	assert_eq(b.props_built, d["props"].size(), "все модели парка существуют")

func test_spawns_offer_only_park_food() -> void:
	var foods := {}
	for s in WorldBuilder.load_layout(PARK)["spawn_points"]:
		assert_true(s.has("foods"), "у точки парка задан список еды")
		for f in s.get("foods", []):
			foods[f] = true
			assert_not_null(FoodCatalog.get_by_id(StringName(f)), "еда %s есть в каталоге" % f)
	for f in ["popcorn", "bagel", "sandwich", "corn", "cotton_candy", "cupcake"]:
		assert_true(foods.has(f), "в парке спавнится %s" % f)

func test_spawn_point_respects_food_list() -> void:
	var sp := (load("res://scenes/food/food_spawn_point.tscn") as PackedScene).instantiate() as FoodSpawnPoint
	sp.allowed = [Rarity.Tier.COMMON, Rarity.Tier.RARE]
	sp.foods = [&"popcorn", &"sandwich"]
	add_child_autofree(sp)
	for i in 30:
		assert_true(sp.pick_def().id in [&"popcorn", &"sandwich"])

func test_catalog_foods_have_models_and_icons() -> void:
	# Review Focus 3
	assert_eq(FoodCatalog.all().size(), 20, "двор, парк и порт")
	for f in FoodCatalog.all():
		assert_true(ResourceLoader.exists(f.model_path), "модель %s" % f.id)
		assert_not_null(f.icon(), "иконка %s" % f.id)

func test_invariants_spawns_yarn_hideouts() -> void:
	var world := _park_with_floor()
	await wait_physics_frames(3)
	var space := world.get_world_3d().direct_space_state
	for sp in world.find_children("*", "FoodSpawnPoint", true, false):
		var pos: Vector3 = (sp as Node3D).global_position
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "точка спавна %s внутри пропса" % pos)
	for y in world.find_children("*", "YarnPickup", true, false):
		var pos: Vector3 = (y as Node3D).global_position
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "клубочек %s внутри пропса" % pos)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "под клубочком %s что-то есть" % pos)
		if not hit.is_empty():
			assert_lt(pos.y - (hit["position"] as Vector3).y, 0.3, "клубочек %s не висит" % pos)
	for h in world.find_children("*", "Hideout", true, false):
		var pos: Vector3 = (h as Node3D).global_position
		assert_eq(_prop_at(world, pos), "", "укрытие %s (%s) внутри пропса" % [pos, h.kind])

func test_gate_opens_exactly_at_25() -> void:
	# Review Focus 1
	var world := _park_with_floor()
	var gate := world.find_child("gate_0", true, false) as Gate
	assert_not_null(gate)
	GameState.satiety = 24
	GameState.satiety_changed.emit(24)
	assert_false(gate.open, "при 24 парк закрыт")
	GameState.satiety = 25
	GameState.satiety_changed.emit(25)
	assert_true(gate.open, "при 25 открыт")
	assert_eq(gate.label, "Ворота в парк открыты!")

func test_park_is_fenced_and_floored() -> void:
	# Review Focus 2: по периметру забор, под всем парком пол.
	var world := _park_with_floor()
	await wait_physics_frames(3)
	var space := world.get_world_3d().direct_space_state
	# План 12: края парка ×3 (x ±45, z 125) проверяет test_park_x3; здесь — южный забор ядра у двора.
	for p in [Vector3(-5, 0.5, 30), Vector3(5, 0.5, 30)]:
		var from := Vector3(0, 0.5, 45)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from + (p - from).normalized() * 3.0, p + (p - from).normalized() * 1.5, Layers.WORLD))
		assert_false(hit.is_empty(), "к %s не выйти: забор" % p)
	for p in [Vector3(-14, 1, 31), Vector3(14, 1, 59), Vector3(0, 1, 45.5), Vector3(-9, 1, 50)]:
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3(0, -2, 0), Layers.WORLD))
		assert_false(down.is_empty(), "под %s есть пол" % p)

func test_lawn_and_paths_are_textured_in_main() -> void:
	# План 10: пол парка — рельеф; газон и гравий — каналы карты покрытий.
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var t := main.find_child("ParkTerrain", true, false) as Terrain
	assert_not_null(t)
	if t:
		assert_eq(t.channels[2], "grass")
		assert_eq(t.channels[3], "gravel")
		assert_eq((t.material.get_shader_parameter("tex_b") as Texture2D).resource_path, "res://assets/images/textures/grass.png")
		assert_eq((t.material.get_shader_parameter("tex_a") as Texture2D).resource_path, "res://assets/images/textures/gravel.png")
		assert_gt(t.height_at(0, 45) + 1.0, 1.0, "пол парка на месте")
	SaveGame.clear()

func test_perimeter_fence_is_too_high_to_jump_from_any_prop() -> void:
	# Ревью плана 8 (I1): кот запрыгивал на куст (0,78 м) и с него перелетал забор 1,1 м. С любого пропса
	# кот достаёт до ≈ 0,8 + 0,84 м, поэтому коллайдер забора по периметру — не ниже 1,7 м.
	for p in WorldBuilder.load_layout(PARK)["props"]:
		if p["model"] != "fence":
			continue
		assert_true(p.has("colliders"), "у секции забора %s явный коллайдер" % [p["pos"]])
		if p.has("colliders"):
			var top: float = p["colliders"][0]["size"][1] / 2.0 + p["colliders"][0]["offset"][1]
			assert_gte(top, 1.7, "забор %s не перепрыгнуть" % [p["pos"]])

func test_yard_spawns_never_give_park_food() -> void:
	# Ревью плана 8 (I2): карточки парка нельзя собрать во дворе и кафе.
	var park_food := [&"popcorn", &"bagel", &"sandwich", &"corn", &"cotton_candy", &"cupcake"]
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(WorldBuilder.load_layout("res://data/layout/yard.json"))
	for sp in b.find_children("*", "FoodSpawnPoint", true, false):
		for i in 60:
			assert_false(StringName((sp as FoodSpawnPoint).pick_def().id) in park_food, "точка двора %s дала еду парка" % (sp as Node3D).global_position)

func test_park_hazards_are_placed() -> void:
	var types := {}
	for hz in WorldBuilder.load_layout(PARK)["hazards"]:
		types[hz["type"]] = types.get(hz["type"], 0) + 1
	assert_eq(types.get("sprinkler", 0), 6, "парк ×3: шесть дождевателей")
	for t in ["pigeons", "gardener", "kid", "guard"]:
		assert_gt(types.get(t, 0), 0, "в парке есть %s" % t)
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(WorldBuilder.load_layout(PARK))
	assert_eq(b.hazards_built, WorldBuilder.load_layout(PARK)["hazards"].size(), "все опасности построены")
```

## `tests/integration/test_park_people.gd`

```gdscript
extends GutTest
## Садовник, ребёнок, сторож (спек этапа 2, раздел 3).

const CatScene := preload("res://scenes/player/cat.tscn")
const LightingScene := preload("res://scenes/world/lighting.tscn")

var world: Node3D
var cat
var dn

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
	var light = LightingScene.instantiate()
	world.add_child(light)
	dn = light.get_node("DayNight")
	dn.set_time(50.0)
	dn.time_scale = 0.0
	cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, 10)
	world.add_child(cat)

func _spawn(path: String) -> Node3D:
	var n := (load(path) as PackedScene).instantiate() as Node3D
	n.position = Vector3(0, 0.05, 0)   # смотрит по −Z
	world.add_child(n)
	return n

# --- садовник ---

func test_gardener_spray_hits_only_in_cone_and_not_during_warning() -> void:
	# Review Focus 5
	var g = _spawn("res://scenes/hazards/gardener.tscn")
	await wait_physics_frames(2)
	cat.global_position = Vector3(0, 0.05, -2)
	g.start_watering()
	assert_eq(g.mode, &"warn")
	await wait_physics_frames(5)
	assert_eq(GameState.hearts, 3, "шипение — ещё не удар")
	g.mode_left = 0.0
	await wait_physics_frames(3)
	assert_eq(g.mode, &"spray")
	assert_eq(GameState.hearts, 2, "струя бьёт кота в конусе 3 м")

func test_gardener_spray_misses_cat_outside_cone() -> void:
	var g = _spawn("res://scenes/hazards/gardener.tscn")
	await wait_physics_frames(2)
	cat.global_position = Vector3(2.2, 0.05, -2)   # 48° от направления струи
	g.start_watering()
	g.mode_left = 0.0
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 3)

func test_gardener_sleeps_at_night() -> void:
	# Review Focus 4
	var g = _spawn("res://scenes/hazards/gardener.tscn")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	assert_false(g.visible, "ночью садовник спит в сторожке")
	cat.global_position = Vector3(0, 0.05, -2)
	g.start_watering()
	g.mode_left = 0.0
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 3, "спящий садовник не поливает")

# --- ребёнок ---

func test_kid_catches_and_pets_without_damage() -> void:
	# Review Focus 2
	var k = _spawn("res://scenes/hazards/kid.tscn")
	GameState.pick_up(FoodCatalog.get_by_id(&"popcorn"))
	watch_signals(GameState)
	cat.global_position = Vector3(0, 0.05, -0.3)
	await wait_physics_frames(6)
	assert_signal_emitted(GameState, "cat_petted")
	assert_eq(GameState.hearts, 3, "гладит, а не бьёт")
	assert_true(GameState.mouth.is_empty(), "еда из зубов выпала")
	assert_gt(cat.petted_left, 1.5)
	await wait_seconds(2.2)
	assert_almost_eq(cat.petted_left, 0.0, 0.001, "не дольше 2 с")
	assert_gt(cat.invulnerable_left, 0.0, "после — неуязвимость")

func test_kid_chases_cat_it_sees() -> void:
	var k = _spawn("res://scenes/hazards/kid.tscn")
	cat.global_position = Vector3(0, 0.05, -5)
	await wait_seconds(1.0)
	assert_eq(k.brain.state, ChaseBrain.State.CHASE, "заметил и бежит")
	var d0: float = k.global_position.distance_to(cat.global_position)
	await wait_seconds(0.5)
	assert_lt(k.global_position.distance_to(cat.global_position), d0 - 0.5)

func test_kid_goes_home_in_the_evening() -> void:
	var k = _spawn("res://scenes/hazards/kid.tscn")
	dn.set_time(160.0)
	await wait_physics_frames(2)
	assert_false(k.visible, "вечером ребёнок ушёл домой")
	cat.global_position = Vector3(0, 0.05, -0.3)
	await wait_physics_frames(5)
	assert_almost_eq(cat.petted_left, 0.0, 0.001)

# --- сторож ---

func test_guard_only_at_night() -> void:
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	await wait_physics_frames(2)
	assert_false(gd.visible, "днём сторожа нет")
	cat.global_position = Vector3(0, 0.05, -4)
	assert_false(gd.sees_cat())
	dn.set_time(220.0)
	await wait_physics_frames(2)
	assert_true(gd.visible)
	assert_true(gd.sees_cat(), "ночью видит кота в луче фонарика")

func test_guard_sees_cat_under_lamp_even_outside_flashlight() -> void:
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	cat.global_position = Vector3(5, 0.05, -5)   # 45° — вне луча 15°
	assert_false(gd.sees_cat(), "в темноте сбоку не видит")
	var lamp := SpotLight3D.new()
	lamp.add_to_group("night_lights")
	world.add_child(lamp)
	lamp.global_position = Vector3(5, 2.45, -5)
	lamp.visible = true
	assert_true(gd.sees_cat(), "кот под горящим фонарём заметен")

func test_absent_people_are_not_invisible_walls() -> void:
	# Ревью плана 9 (I1): вне своей фазы тело не должно перекрывать дорогу коту.
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	var k = _spawn("res://scenes/hazards/kid.tscn")
	await wait_physics_frames(2)
	assert_eq(gd.collision_layer, 0, "днём тела сторожа нет")
	assert_eq(k.collision_layer, Layers.HAZARD, "ребёнок днём на месте")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	assert_eq(gd.collision_layer, Layers.HAZARD)
	assert_eq(k.collision_layer, 0, "ночью ребёнка нет")

func test_guard_touch_does_not_hit_by_day() -> void:
	var gd = _spawn("res://scenes/hazards/guard.tscn")
	await wait_physics_frames(2)
	cat.global_position = Vector3(0, 0.05, -0.2)
	await wait_physics_frames(6)
	assert_eq(GameState.hearts, 3)

func test_kid_touch_does_not_pet_at_night() -> void:
	var k = _spawn("res://scenes/hazards/kid.tscn")
	dn.set_time(220.0)
	await wait_physics_frames(2)
	cat.global_position = Vector3(0, 0.05, -0.3)
	await wait_physics_frames(6)
	assert_almost_eq(cat.petted_left, 0.0, 0.001)

func test_respawn_dries_and_frees_cat() -> void:
	cat.wet(4.0)
	cat.petted_left = 1.5
	cat.teleport(Vector3(0, 0.05, 5))
	assert_almost_eq(cat.wet_left, 0.0, 0.001)
	assert_almost_eq(cat.petted_left, 0.0, 0.001)
```

## `tests/integration/test_park_x3.gd`

```gdscript
extends GutTest
## План 12: парк ×3 (спек «Масштаб ×3 и рельеф», раздел 2): поляна, холм с беседкой, пруд, роща, северный луг.

const LAYOUT := "res://data/layout/park.json"
var world: Node3D
var b: WorldBuilder
var t: Terrain

func before_all() -> void:
	world = Node3D.new()
	add_child(world)
	t = Terrain.new()
	t.data_path = "res://data/terrain/park.json"
	world.add_child(t)
	b = WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(LAYOUT))
	await wait_physics_frames(2)

func after_all() -> void:
	world.free()

func test_park_is_90_by_96_with_counts() -> void:
	assert_almost_eq(t.width, 90.0, 0.01)
	assert_almost_eq(t.depth, 96.0, 0.01)
	var d := WorldBuilder.load_layout(LAYOUT)
	assert_gte(d["spawn_points"].size(), 35)
	assert_gte(d["yarn"].size(), 25)
	var n := {}
	for h in d["hazards"]:
		n[h["type"]] = n.get(h["type"], 0) + 1
	assert_eq(n, {"pigeons": 4, "gardener": 2, "sprinkler": 6, "kid": 2, "guard": 2})
	assert_lte(t.triangle_count(), 40000)

func test_hill_with_gazebo_and_pond() -> void:
	assert_almost_eq(t.height_at(0, 92), 3.01, 0.05, "вершина холма")
	assert_lt(t.height_at(-28, 66), -1.2, "дно пруда")
	var w := b.find_children("*", "Water", true, false)
	assert_eq(w.size(), 1, "пруд")
	if w.size() == 1:
		assert_almost_eq((w[0] as Water).level, -0.5, 0.01)
	var g := b.find_children("gazebo*", "", true, false)
	assert_gt(g.size(), 0, "беседка на холме")

func test_shore_markers_are_dry() -> void:
	# Review Focus 1: берег выше воды и вне зоны — вернувшегося кота не затягивает обратно.
	var shores := get_tree().get_nodes_in_group("shore")
	assert_eq(shores.size(), 8)
	for m in shores:
		var p: Vector3 = (m as Node3D).global_position
		assert_gt(t.height_at(p.x, p.z), -0.3, "берег %s на суше" % p)

func test_generated_items_stand_on_surface() -> void:
	for s in b.get_node("Spawns").get_children() + b.get_node("Yarn").get_children():
		var p: Vector3 = s.global_position
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.6, Layers.WORLD))
		assert_false(hit.is_empty(), "%s в %s на опоре" % [s.name, p])
		if not hit.is_empty():
			assert_lt(p.y - (hit["position"] as Vector3).y, 0.35, "%s в %s не висит" % [s.name, p])
		assert_gt(p.y, -0.3, "%s в %s не в пруду" % [s.name, p])

func test_park_edge_is_closed() -> void:
	# Review Focus 2: забор по x ±45 и z 125 (юг закрывают стены двора).
	var space := world.get_world_3d().direct_space_state
	for z in range(33, 124, 6):
		for x in [-45, 45]:
			var from := Vector3(x - signf(x) * 2.0, t.height_at(x - signf(x) * 2.0, z) + 0.3, z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(signf(x) * 4.0, 0, 0), Layers.WORLD))
			assert_false(hit.is_empty(), "забор у x %d, z %d" % [x, z])
	for x in range(-42, 43, 6):
		var from := Vector3(x, t.height_at(x, 123) + 0.3, 123)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, 4), Layers.WORLD))
		assert_false(hit.is_empty(), "забор у x %d на севере" % x)

func test_people_routes_stay_on_dry_land() -> void:
	# Review Focus 3: маршруты садовников и сторожей не заходят в пруд.
	for h in WorldBuilder.load_layout(LAYOUT)["hazards"]:
		for p in h.get("path", []):
			assert_gt(t.height_at(float(p[0]), float(p[1])), -0.3, "%s: точка %s на суше" % [h["type"], p])

func test_port_gate_needs_satiety_50() -> void:
	# План 13: ворота в порт в северном заборе парка при x −6, порог 50.
	var gates := get_tree().get_nodes_in_group("gates").filter(func(g): return absf(g.global_position.x + 6) < 0.1)
	assert_eq(gates.size(), 1)
	if gates.size() == 1:
		assert_eq(gates[0].satiety_required, 50)
		assert_almost_eq(gates[0].global_position.z, 125.0, 0.01)
```

## `tests/integration/test_pigeons.gd`

```gdscript
extends GutTest

const FlockScene := preload("res://scenes/hazards/pigeon_flock.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var cat
var flock

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
	cat = CatScene.instantiate()
	cat.position = Vector3(6, 0.05, 0)
	world.add_child(cat)
	flock = FlockScene.instantiate()
	world.add_child(flock)

func test_flock_has_five_pigeons() -> void:
	await wait_physics_frames(2)
	assert_eq(flock.pigeons().size(), 5)

func test_pigeon_steals_last_food_once_then_rests() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	await wait_physics_frames(5)
	assert_eq(GameState.mouth.size(), 1, "голубь утащил последнюю еду")
	assert_eq(GameState.hearts, 3)
	await wait_physics_frames(10)
	assert_eq(GameState.mouth.size(), 1, "перерыв 10 с: вторую не крадут")

func test_running_cat_scatters_and_keeps_food() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(2.0, 0.05, 0)
	await wait_physics_frames(2)
	Input.action_press("move_forward")
	Input.action_press("run")
	await wait_physics_frames(25)
	Input.action_release("run")
	Input.action_release("move_forward")
	assert_eq(flock.mode, &"scattered", "бегущий кот разогнал стаю")
	assert_eq(GameState.mouth.size(), 1, "еда цела")

func test_pigeons_sleep_at_night() -> void:
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	add_child_autofree(light)
	light.get_node("DayNight").set_time(220.0)
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	await wait_physics_frames(5)
	assert_false(flock.visible, "ночью стаи нет (спят на ветках)")
	assert_eq(GameState.mouth.size(), 1)

func test_hidden_cat_keeps_food_next_to_flock() -> void:
	# Review Focus 1, интеграционно
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	cat.hidden = true
	await wait_physics_frames(6)
	assert_eq(GameState.mouth.size(), 1, "у спрятавшегося не крадут")

func test_flock_steals_again_after_cooldown() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	cat.global_position = Vector3(0.6, 0.05, 0)
	await wait_physics_frames(4)
	assert_eq(GameState.mouth.size(), 1)
	flock.cooldown_left = 0.0   # перерыв 10 с истёк
	await wait_physics_frames(4)
	assert_eq(GameState.mouth.size(), 0, "после перерыва стая снова крадёт")
```

## `tests/integration/test_port.gd`

```gdscript
extends GutTest
## План 13: район «Порт» (спек порта, разделы 1, 2, 5, 6; размеры — спек масштаба).

const LAYOUT := "res://data/layout/port.json"
const PORT_FOOD := [&"shrimp", &"fries", &"squid", &"fish_sandwich", &"sushi"]
var world: Node3D
var b: WorldBuilder
var t: Terrain

func before_all() -> void:
	world = Node3D.new()
	add_child(world)
	t = Terrain.new()
	t.data_path = "res://data/terrain/port.json"
	world.add_child(t)
	b = WorldBuilder.new()
	b.terrain = t
	world.add_child(b)
	b.build(WorldBuilder.load_layout(LAYOUT))
	await wait_physics_frames(2)

func after_all() -> void:
	world.free()

func test_port_size_levels_and_counts() -> void:
	assert_almost_eq(t.width, 120.0, 0.01)
	assert_almost_eq(t.depth, 102.0, 0.01)
	assert_almost_eq(t.height_at(0, 136), 0.0, 0.05, "набережная вровень с парком")
	assert_almost_eq(t.height_at(25, 180), -1.0, 0.05, "причал ниже набережной")
	assert_almost_eq(t.height_at(-30, 175), -2.0, 0.05, "пляж")
	assert_lt(t.height_at(0, 210), -3.0, "дно моря")
	var d := WorldBuilder.load_layout(LAYOUT)
	assert_gte(d["spawn_points"].size(), 35)
	assert_gte(d["yarn"].size(), 25)
	assert_gte(d["hideouts"].size(), 14)
	assert_lte(t.triangle_count(), 40000)

func test_water_and_dry_shore() -> void:
	# Review Focus 1: каждый маркер берега на суше, выше воды.
	var w := b.find_children("*", "Water", true, false)
	assert_eq(w.size(), 2, "море и гавань")
	for m in get_tree().get_nodes_in_group("shore"):
		var p: Vector3 = (m as Node3D).global_position
		assert_gt(t.height_at(p.x, p.z), -2.2, "берег %s выше воды" % p)

func test_boats_and_barrels_float_reachably() -> void:
	# Review Focus 2: 3 лодки и 5 бочек; палуба лодки в прыжке от причала (−1), верх бочки на 0,3 над водой.
	var boats := 0
	var barrels := 0
	for f in b.find_children("*", "Floater", true, false):
		var fl := f as Floater
		if String(fl.name).begins_with("boat"):
			boats += 1
			assert_lte(-1.0 - (fl.base.origin.y + 0.45 - fl.amp), 0.8, "с палубы на причал допрыгнуть")
		elif String(fl.name).begins_with("barrel"):
			barrels += 1
			assert_almost_eq(fl.base.origin.y + 0.7, -2.0, 0.01, "верх бочки на 0,3 над водой")
	assert_eq(boats, 3)
	assert_eq(barrels, 5)

func test_only_port_food_and_no_golden_fish_in_spawns() -> void:
	# Review Focus 4.
	for sp in WorldBuilder.load_layout(LAYOUT)["spawn_points"]:
		assert_false(sp.get("foods", []).is_empty(), "у точки %s список еды" % [sp["pos"]])
		for f in sp.get("foods", []):
			assert_true(StringName(f) in PORT_FOOD, "%s — еда порта" % f)

func test_port_land_edges_are_closed() -> void:
	# Review Focus 3: по суше за x ±60 не выйти (набережная и пляж).
	var space := world.get_world_3d().direct_space_state
	for z in range(128, 192, 6):
		var x := -58.0
		var from := Vector3(x, t.height_at(x, z) + 0.3, z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(-4, 0, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "забор на западе у z %d" % z)
	for z in range(128, 146, 6):
		var from := Vector3(58, 0.3, z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(4, 0, 0), Layers.WORLD))
		assert_false(hit.is_empty(), "забор на востоке у z %d" % z)

func test_generated_items_stand_on_surface() -> void:
	for s in b.get_node("Spawns").get_children() + b.get_node("Yarn").get_children():
		var p: Vector3 = s.global_position
		var hit := world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 0.7, Layers.WORLD))
		assert_false(hit.is_empty(), "%s в %s на опоре" % [s.name, p])
		assert_gt(p.y, -2.3, "%s в %s не под водой" % [s.name, p])

func test_port_north_edge_beyond_park_is_closed() -> void:
	# Ревью плана 13: порт шире парка — на x −60…−45 и 45…60 у z 125 набережная обрывалась в пустоту.
	var space := world.get_world_3d().direct_space_state
	for x in [-58, -52, -47, 47, 52, 58]:
		var from := Vector3(x, 0.3, 127)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, -4), Layers.WORLD))
		assert_false(hit.is_empty(), "забор на юге набережной у x %d" % x)

func test_climb_steps_from_boats_to_pier() -> void:
	# Ревью плана 13: с палубы до настила 0,77–0,85 м — на пределе прыжка; понтоны у проёмов дают ступени ≤ 0,5 м.
	var space := world.get_world_3d().direct_space_state
	for f in b.find_children("boat*", "Floater", true, false):
		var boat := f as Floater
		var deck := boat.base.origin.y + 0.45
		var to_pier := signf(25.0 - boat.base.origin.x)
		var probe := boat.base.origin + Vector3(to_pier * 1.6, 0, 0)   # 0,8 м за бортом к причалу
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 3, probe + Vector3.DOWN * 3, Layers.WORLD))
		assert_false(hit.is_empty(), "у %s ступень к причалу" % boat.name)
		if not hit.is_empty():
			var step := (hit["position"] as Vector3).y
			assert_lte(step - (deck - boat.amp - 0.1), 0.55, "%s: с палубы на ступень" % boat.name)
			assert_lte(-1.0 - step, 0.55, "%s: со ступени на причал" % boat.name)

func test_barrels_are_a_walkable_chain() -> void:
	# Ревью плана 13: бочки через 3 м — зазор 2,3 м; цепочка — центры не дальше 2,0 м.
	var zs: Array = []
	for f in b.find_children("barrel*", "Floater", true, false):
		zs.append((f as Floater).base.origin.z)
	zs.sort()
	for i in zs.size() - 1:
		assert_lte(zs[i + 1] - zs[i], 2.05, "шаг бочек")

func test_cat_jumps_from_boat_back_onto_pier() -> void:
	# Ревью плана 13: реальный ввод — с лодки через понтон на причал.
	GameState.reset()
	var cat = (load("res://scenes/player/cat.tscn") as PackedScene).instantiate()
	cat.position = Vector3(37.3, -1.4, 165)
	world.add_child(cat)
	await wait_physics_frames(20)
	Input.action_press("move_left")   # без камеры «влево» — это −X, к причалу
	for i in 8:
		Input.action_press("jump")
		await wait_physics_frames(2)
		Input.action_release("jump")
		await wait_physics_frames(22)
	Input.action_release("move_left")
	assert_lt(cat.global_position.x, 34.5, "кот на причале, а не в воде")
	assert_gt(cat.global_position.y, -1.1, "на высоте настила")
	cat.free()

func test_port_hazards_are_placed() -> void:
	# План 14: 2 чайки, волна вдоль пляжа, погрузчик на полосе причала, 4 краба днём и ещё 2 ночью.
	var n := {}
	var night_crabs := 0
	for h in WorldBuilder.load_layout(LAYOUT)["hazards"]:
		n[h["type"]] = n.get(h["type"], 0) + 1
		if h["type"] == "crab" and h.get("night_only", false):
			night_crabs += 1
	assert_eq(n, {"forklift": 1, "gull": 2, "wave": 1, "crab": 6})
	assert_eq(night_crabs, 2)

func test_forklift_lane_is_clear() -> void:
	# Review Focus 3 плана 14: по полосе погрузчика нет твёрдых пропсов.
	var space := world.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(25, -0.5, 152), Vector3(25, -0.5, 208.5), Layers.WORLD))
	assert_true(hit.is_empty(), "полоса свободна: %s" % [hit.get("collider")])
```

## `tests/integration/test_port_hazards.gd`

```gdscript
extends GutTest
## План 14: опасности порта — чайки, волны, погрузчик, крабы (спек порта, раздел 3).

const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func _floor(y := 0.0, size := 40.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.2, size)
	shape.shape = box
	shape.position.y = y - 0.1
	body.add_child(shape)
	world.add_child(body)

func _cat(pos: Vector3) -> Node:
	var cat = CatScene.instantiate()
	cat.position = pos
	world.add_child(cat)
	return cat

func test_port_sounds_and_models_exist() -> void:
	for s in [&"gull", &"wave", &"horn"]:
		assert_true(Sfx.has(s), "звук %s" % s)
	for m in ["gull", "crab", "forklift", "burrow"]:
		assert_true(ResourceLoader.exists("res://assets/models/%s.glb" % m), "модель %s" % m)

const GullScene := preload("res://scenes/hazards/gull.tscn")

func _gull(pos: Vector3) -> Node3D:
	var g := GullScene.instantiate() as Node3D
	g.position = pos
	world.add_child(g)
	return g

func test_gull_circles_4m_above_its_perch() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	await wait_physics_frames(10)
	assert_almost_eq(g.global_position.y, 4.0, 0.3, "кружит на 4 м")
	var flat := Vector2(g.global_position.x, g.global_position.z).length()
	assert_between(flat, 2.9, 4.1, "радиус 3–4 м")

func test_gull_dives_on_cat_with_food_and_steals_last() -> void:
	# Спек: тень и крик 1 с, бросок; удар и последняя еда унесена, остальное в зубах.
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(5)
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	GameState.pick_up(FoodCatalog.get_by_id(&"fries"))
	await wait_physics_frames(3)
	assert_eq(g.mode, &"warn", "заметила кота с едой")
	assert_true((g.get_node("Shadow") as Node3D).visible, "тень на земле")
	await wait_seconds(1.8)
	assert_eq(GameState.hearts, 2, "удар")
	assert_eq(GameState.mouth.size(), 1, "унесла одну")
	assert_eq(GameState.mouth[0].id, &"shrimp", "последнюю — картошку")
	assert_gt(g.cooldown_left, 6.0, "перерыв 8 с")

func test_gull_ignores_cat_without_food_or_hidden() -> void:
	_floor()
	var g := _gull(Vector3(0, 0, 0))
	var cat = _cat(Vector3(1, 0.05, 1))
	await wait_physics_frames(20)
	assert_eq(g.mode, &"circle", "без еды — кружит")
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	cat.hidden = true
	await wait_physics_frames(10)
	assert_eq(g.mode, &"circle", "спрятанного не видит")

func test_gull_sleeps_on_perch_at_night() -> void:
	_floor()
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var g := _gull(Vector3(2, 0, 2))
	var cat = _cat(Vector3(2.5, 0.05, 2.5))
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_physics_frames(15)
	assert_eq(g.mode, &"sleep")
	assert_lt(g.global_position.y, 1.0, "сидит на насесте")
	assert_eq(GameState.hearts, 3)

const WaveScene := preload("res://scenes/hazards/wave.tscn")

func _wave() -> Node3D:
	var w := WaveScene.instantiate() as Node3D
	w.set("width", 20.0)
	w.set("inland", -1.0)   # суша — в сторону −Z от линии воды z 0
	world.add_child(w)
	return w

func test_wave_throws_cat_inland_and_wets_once() -> void:
	# Спек: кот отброшен к берегу на 1,5 м и мокрый 4 с; без урона, еда не теряется; один раз за накат.
	_floor()
	var w := _wave()
	var cat = _cat(Vector3(0, 0.05, -2.0))
	GameState.pick_up(FoodCatalog.get_by_id(&"shrimp"))
	await wait_seconds(2.0)
	assert_lt(cat.global_position.z, -3.2, "отброшен вглубь пляжа на 1,5 м")
	assert_gt(cat.wet_left, 0.0, "мокрый")
	assert_eq(GameState.hearts, 3)
	assert_eq(GameState.mouth.size(), 1, "еда в зубах")
	assert_eq(w.get("hits"), 1)
	await wait_seconds(3.0)
	assert_eq(w.get("hits"), 1, "за один накат — один раз")

func test_wave_does_not_reach_cat_far_inland() -> void:
	_floor()
	var w := _wave()
	var cat = _cat(Vector3(0, 0.05, -6.0))
	await wait_seconds(4.0)
	assert_eq(w.get("hits"), 0)
	assert_eq(cat.wet_left, 0.0)

func test_wave_foam_warns_before_roll() -> void:
	_floor()
	var w := _wave()
	w.set("offset", Wave.PERIOD - 1.0)   # за 1 с до наката
	await wait_physics_frames(3)
	assert_true((w.get_node("Foam") as CPUParticles3D).emitting, "пена у кромки")

const ForkliftScene := preload("res://scenes/hazards/forklift.tscn")

func _forklift(path: Array) -> Node3D:
	var f := ForkliftScene.instantiate() as Node3D
	f.position = Vector3(path[0][0], 0, path[0][1])
	f.call("configure", {"path": path, "wait": [0.5, 0.5]}, null)
	world.add_child(f)
	return f

func test_forklift_honks_then_drives_3mps() -> void:
	_floor()
	Sfx.reset_counters()
	var f := _forklift([[0, -10], [0, 10]])
	await wait_seconds(0.7)
	assert_eq(f.get("state"), &"horn", "сначала гудок")
	assert_eq(Sfx.last_played, &"horn")
	var z0: float = f.global_position.z
	await wait_seconds(1.5)
	assert_eq(f.get("state"), &"drive", "через 1,5 с едет")
	var z1: float = f.global_position.z
	await wait_seconds(1.0)
	assert_almost_eq(f.global_position.z - z1, 3.0, 0.4, "3 м/с")
	assert_almost_eq(z0, -10.0, 0.05, "до гудка стоял")

func test_forklift_hits_cat_on_its_lane() -> void:
	_floor()
	var f := _forklift([[0, -6], [0, 6]])
	_cat(Vector3(0, 0.05, 0))
	await wait_seconds(5.0)
	assert_eq(GameState.hearts, 2, "удар погрузчиком")

func test_forklift_stands_at_night() -> void:
	_floor()
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	world.add_child(light)
	light.get_node("DayNight").set_time(220.0)
	light.get_node("DayNight").set("time_scale", 0.0)
	var f := _forklift([[0, -6], [0, 6]])
	await wait_seconds(3.0)
	assert_eq(f.get("state"), &"wait")
	assert_almost_eq(f.global_position.z, -6.0, 0.05, "ночью стоит")

func test_forklift_hits_cat_already_standing_at_its_forks() -> void:
	# Кот стоял у вил, пока погрузчик ждал: при старте удар всё равно проходит.
	_floor()
	var f := _forklift([[0, -6], [0, 6]])
	_cat(Vector3(0, 0.05, -4.9))
	await wait_seconds(3.0)
	assert_eq(GameState.hearts, 2)

const CrabScene := preload("res://scenes/hazards/crab.tscn")

func _crab(pos: Vector3, hz := {}) -> Node3D:
	var c := CrabScene.instantiate() as Node3D
	c.position = pos
	c.call("configure", hz, null)
	world.add_child(c)
	return c

func test_crab_waits_in_burrow_unseen() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	_cat(Vector3(4, 0.05, 0))
	await wait_physics_frames(20)
	assert_eq(c.get("state"), &"burrow")
	assert_false((c.get_node("Model") as Node3D).visible, "в норке не видно")

func test_crab_runs_out_and_pinches_cat_closer_than_3m() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	_cat(Vector3(2.5, 0.05, 0))
	await wait_seconds(2.0)
	assert_eq(GameState.hearts, 2, "щипок")
	assert_true((c.get_node("Model") as Node3D).visible)

func test_crab_hides_after_5s_chase_and_comes_back_after_6s() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	var cat = _cat(Vector3(2.5, 0.05, 0))
	await wait_physics_frames(3)
	cat.invulnerable_left = 99.0   # не мешаем погоне ударами
	await wait_seconds(5.5)
	assert_eq(c.get("state"), &"hide", "5 с погони — прячется")
	cat.global_position = Vector3(10, 0.05, 0)
	await wait_seconds(7.0)
	assert_eq(c.get("state"), &"burrow", "через 6 с снова сторожит")
	assert_lt(Vector2(c.global_position.x, c.global_position.z).length(), 0.4, "вернулся в норку")

func test_crab_hides_when_cat_jumps_over_it() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0))
	var cat = _cat(Vector3(2.5, 0.05, 0))
	await wait_physics_frames(10)
	assert_eq(c.get("state"), &"chase")
	cat.invulnerable_left = 99.0
	cat.global_position = c.global_position + Vector3(0, 0.7, 0)   # кот над крабом в прыжке
	await wait_physics_frames(2)
	assert_eq(c.get("state"), &"hide")

func test_night_crab_sits_in_burrow_by_day() -> void:
	_floor()
	var c := _crab(Vector3(0, 0.05, 0), {"night_only": true})
	_cat(Vector3(1, 0.05, 0))
	await wait_seconds(1.0)
	assert_eq(c.get("state"), &"burrow")
	assert_eq(GameState.hearts, 3)
```

## `tests/integration/test_shop_menu.gd`

```gdscript
extends GutTest

const MainScene := preload("res://scenes/main.tscn")

var main
var cat

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(20)
	cat = main.find_child("Cat", true, false)

func after_each() -> void:
	SaveGame.clear()

func test_open_and_close_toggle_cat_input_and_camera() -> void:
	main.open_shop()
	assert_true(main.shop_menu.is_open)
	assert_false(cat.input_enabled)
	assert_true(cat.camera_rig.shop_view)
	assert_false(main.hud.visible)
	main.close_shop()
	assert_false(main.shop_menu.is_open)
	assert_true(cat.input_enabled)
	assert_false(cat.camera_rig.shop_view)
	assert_true(main.hud.visible)

func test_buttons_reflect_affordability_and_buy_works() -> void:
	GameState.add_yarn(10)
	main.open_shop()
	var buttons: Array = main.shop_menu.item_buttons()
	assert_eq(buttons.size(), 10)
	var speed_btn: Button = buttons[5]
	assert_true(speed_btn.text.begins_with("Бег быстрее"))
	assert_false(speed_btn.disabled)
	var skin_btn: Button = buttons[7]
	assert_true(skin_btn.disabled, "12 клубочков нет")
	speed_btn.pressed.emit()
	assert_true(GameState.owns(&"speed"))
	assert_eq(GameState.yarn, 0)
	assert_eq(main.shop_menu.yarn_text(), "Клубочков: 0")
	assert_true(speed_btn.text.ends_with("куплено"))
	assert_true(speed_btn.disabled, "куплено")
	main.close_shop()

func test_eat_key_in_safe_zone_opens_shop() -> void:
	cat.global_position = main.respawn_position()
	await wait_physics_frames(3)
	assert_true(cat.in_safe_zone)
	Input.action_press("eat")
	await wait_physics_frames(2)
	Input.action_release("eat")
	assert_true(main.shop_menu.is_open)
	main.close_shop()

func test_interact_does_not_open_shop_while_paused() -> void:
	cat.global_position = main.respawn_position()
	await wait_physics_frames(3)
	main.toggle_pause()
	main.on_interact_pressed()
	assert_false(main.shop_menu.is_open, "на паузе магазин не открывается")
	main.toggle_pause()

func test_owned_skins_can_be_reselected() -> void:
	GameState.add_yarn(24)
	main.open_shop()
	var buttons: Array = main.shop_menu.item_buttons()
	var black_btn: Button = buttons[7]
	var grey_btn: Button = buttons[8]
	black_btn.pressed.emit()
	grey_btn.pressed.emit()
	assert_eq(GameState.skin, &"grey")
	assert_false(black_btn.disabled, "купленный скин можно надеть снова")
	assert_true(black_btn.text.ends_with("надеть"))
	black_btn.pressed.emit()
	assert_eq(GameState.skin, &"black")
	assert_eq(GameState.yarn, 0, "повторный выбор бесплатен")
	assert_true(black_btn.text.ends_with("— надет"))
	main.close_shop()
```

## `tests/integration/test_sprinkler.gd`

```gdscript
extends GutTest

const SprinklerScene := preload("res://scenes/hazards/sprinkler.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D
var cat
var sp

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
	cat = CatScene.instantiate()
	cat.position = Vector3(1.0, 0.05, 0)
	world.add_child(cat)
	sp = SprinklerScene.instantiate()
	world.add_child(sp)

func test_warning_does_not_wet_but_spray_does() -> void:
	sp.time = 11.2   # предупреждение
	await wait_physics_frames(3)
	assert_eq(sp.phase, &"warn")
	assert_almost_eq(cat.wet_left, 0.0, 0.001, "бульканье — ещё не мокро")
	sp.time = 12.5
	await wait_physics_frames(3)
	assert_eq(sp.phase, &"on")
	assert_gt(cat.wet_left, 3.5, "под струёй кот намок")
	assert_eq(GameState.hearts, 3, "без урона")

func test_wet_cat_is_slower_and_dries() -> void:
	# Review Focus 3
	cat.wet(4.0)
	assert_almost_eq(cat.speed_factor(), 0.6, 0.001, "мокрый ×0,6")
	cat.wet(2.0)
	assert_almost_eq(cat.wet_left, 4.0, 0.05, "повторное намокание продлевает до большего, а не складывается")
	assert_almost_eq(cat.speed_factor(), 0.6, 0.001, "и не умножает замедление")
	await wait_seconds(4.2)
	assert_almost_eq(cat.speed_factor(), 1.0, 0.001, "высох через 4 с")

func test_sprinklers_work_at_night_too() -> void:
	var light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	add_child_autofree(light)
	light.get_node("DayNight").set_time(220.0)
	sp.time = 12.5
	await wait_physics_frames(3)
	assert_gt(cat.wet_left, 0.0, "ночью дождеватели тоже работают")

func test_rewetting_extends_drying() -> void:
	cat.wet(4.0)
	await wait_seconds(2.0)
	cat.wet(4.0)
	assert_almost_eq(cat.wet_left, 4.0, 0.05, "повторное намокание продлевает срок")
```

## `tests/integration/test_surface_textures.gd`

```gdscript
extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

func before_each() -> void:
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()

func _meshes_named(root: Node, name: String) -> Array:
	var out := []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.name == name:
			out.append(mi)
	return out

func _mat(mi: MeshInstance3D) -> StandardMaterial3D:
	return mi.get_surface_override_material(0) as StandardMaterial3D

func test_large_surfaces_get_triplanar_textures() -> void:
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var expected := {"wall": ["stucco", 4.5]}
	for name in expected:
		var found: Array = _meshes_named(main, name)
		assert_gt(found.size(), 0, "есть меш %s" % name)
		for mi in found:
			var m := _mat(mi)
			assert_not_null(m.albedo_texture, "%s с текстурой" % name)
			if m.albedo_texture:
				assert_eq(m.albedo_texture.resource_path, "res://assets/images/textures/%s.png" % expected[name][0])
			assert_true(m.uv1_triplanar and m.uv1_world_triplanar, "%s: трипланарно по мировым координатам" % name)
			assert_almost_eq(m.uv1_scale.x, 1.0 / expected[name][1], 0.001, "%s: тайл %.0f м" % [name, expected[name][1]])
			assert_eq(m.albedo_color.to_html(false), "ffffff", "цвет несёт текстура")
			assert_eq(m.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON, "тун сохраняется")

func test_yard_floor_is_terrain_with_asphalt_and_paving() -> void:
	# План 10: прежние меши ground/sidewalk заменены рельефом с картой покрытий.
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var t := main.find_child("YardTerrain", true, false) as Terrain
	assert_not_null(t)
	if t == null:
		return
	assert_eq(t.channels.slice(0, 2), ["asphalt", "paving"])
	assert_eq((t.material.get_shader_parameter("tex_r") as Texture2D).resource_path, "res://assets/images/textures/asphalt.png")
	assert_eq((t.material.get_shader_parameter("tex_g") as Texture2D).resource_path, "res://assets/images/textures/paving.png")
	assert_eq(_meshes_named(main, "ground").size(), 0, "старого плоского пола нет")

func test_windows_props_and_puddles_stay_flat() -> void:
	# Review Focus 1–2
	var main := (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	for name in ["wall_frame0", "wall_glass0", "bin", "puddle", "box"]:
		for mi in _meshes_named(main, name):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
				if m:
					assert_null(m.albedo_texture, "%s остаётся плоским" % name)

func test_missing_texture_file_is_not_an_error() -> void:
	# Review Focus 3
	var root := Node3D.new()
	add_child_autofree(root)
	var mi := MeshInstance3D.new()
	mi.name = "nothing_known"
	mi.mesh = BoxMesh.new()
	root.add_child(mi)
	Toon.apply(root, Toon.OUTLINE_NONE)
	assert_eq(SurfaceTextures.apply(root), 0, "незнакомые меши не трогаются")
	assert_eq(SurfaceTextures.texture_or_null("res://assets/images/textures/none.png"), null)
```

## `tests/integration/test_terrain.gd`

```gdscript
extends GutTest
## План 10: рельеф (спек «Масштаб и рельеф», раздел 3).

const DEMO := "res://data/terrain/demo.json"

var t: Terrain

func before_each() -> void:
	t = Terrain.new()
	t.data_path = DEMO
	add_child_autofree(t)
	await wait_physics_frames(2)

func _corner_spread(x: float, z: float) -> float:
	var i := int(floor(x - t.x0))
	var j := int(floor(z - t.z0))
	var hs := [t.h(i, j), t.h(i + 1, j), t.h(i, j + 1), t.h(i + 1, j + 1)]
	return hs.max() - hs.min()

func test_height_at_matches_generator_points() -> void:
	assert_almost_eq(t.height_at(8, 8), 3.0, 0.01, "вершина холма")
	assert_almost_eq(t.height_at(-10, 10), -1.0, 0.01, "дно низины")
	assert_almost_eq(t.height_at(-12, -13), 2.0, 0.01, "терраса")
	assert_almost_eq(t.height_at(15, -15), 0.0, 0.01, "ровное место")

func test_ray_hits_terrain_at_height_at() -> void:
	# Review Focus 1: коллизия совпадает с картой высот (кроме самой ячейки обрыва).
	var space := t.get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var checked := 0
	while checked < 40:
		var x := rng.randf_range(-19.5, 19.5)
		var z := rng.randf_range(-19.5, 19.5)
		if _corner_spread(x, z) > 0.6:
			continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 10, z), Vector3(x, -10, z), Layers.WORLD))
		assert_false(hit.is_empty(), "луч в (%.1f, %.1f) попал в рельеф" % [x, z])
		if not hit.is_empty():
			assert_almost_eq((hit["position"] as Vector3).y, t.height_at(x, z), 0.03, "высота в (%.1f, %.1f)" % [x, z])
		checked += 1
	var edge := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-6.3, 10, -12), Vector3(-6.3, -10, -12), Layers.WORLD))
	assert_almost_eq((edge["position"] as Vector3).y, 2.0, 0.03, "у самого края террасы — её высота")

func test_tiles_material_and_group() -> void:
	assert_true(t.is_in_group("terrain"))
	var tiles := t.find_children("Tile*", "MeshInstance3D", false, false)
	assert_eq(tiles.size(), 4, "40×40 м — четыре тайла по 30 м")
	var m := (tiles[0] as MeshInstance3D).material_override as ShaderMaterial
	assert_not_null(m)
	assert_not_null(m.get_shader_parameter("splat"), "карта покрытий в шейдере")
	assert_not_null(m.get_shader_parameter("tex_cliff"), "камень для обрывов")

func test_surface_height_static_helper() -> void:
	assert_almost_eq(Terrain.surface_height(get_tree(), 8, 8), 3.0, 0.01)
	assert_almost_eq(Terrain.surface_height(get_tree(), 500, 500, -7.0), -7.0, 0.001, "вне рельефа — запасная высота")

func _builder() -> WorldBuilder:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.terrain = t
	return b

func test_builder_snaps_everything_to_surface() -> void:
	var b := _builder()
	b.build({"props": [{"model": "bin", "pos": [8, 0, 8]}, {"model": "box", "pos": [15, 1.0, -15], "snap": false}],
		"spawn_points": [{"pos": [-12, 0, -13], "allowed": [0]}],
		"yarn": [{"pos": [8, 0.1, 8]}],
		"hideouts": [{"kind": "box", "pos": [-10, 0.2, 10], "size": [0.6, 0.4, 0.6]}]})
	var props := b.get_node("Props").get_children()
	assert_almost_eq((props[0] as Node3D).global_position.y, 3.0, 0.02, "бак на вершине холма")
	assert_almost_eq((props[1] as Node3D).global_position.y, 1.0, 0.001, "snap: false — абсолютная высота (Review Focus 3)")
	assert_almost_eq((b.get_node("Spawns").get_child(0) as Node3D).global_position.y, 2.0, 0.02, "еда на террасе")
	assert_almost_eq((b.get_node("Yarn").get_child(0) as Node3D).global_position.y, 3.1, 0.02, "клубочек на 10 см над вершиной")
	assert_almost_eq((b.get_node("Hideouts").get_child(0) as Node3D).global_position.y, -0.8, 0.02, "укрытие в низине")

func test_builder_without_terrain_keeps_heights() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "bin", "pos": [8, 0, 8]}]})
	assert_almost_eq((b.get_node("Props").get_child(0) as Node3D).global_position.y, 0.0, 0.001)

func test_collider_rotation() -> void:
	var b := _builder()
	b.build({"props": [{"model": "box", "pos": [15, 0, -15], "colliders": [{"size": [1, 0.1, 2], "offset": [0, 0.5, 0], "rot": [-25, 0, 0]}]}]})
	var shape := b.get_node("Props").get_child(0).find_child("Shape0", true, false) as CollisionShape3D
	assert_almost_eq(shape.rotation_degrees.x, -25.0, 0.01, "наклонный коллайдер для пандусов и лестниц")

# --- кот на рельефе (Review Focus 2) ---

const CatScene := preload("res://scenes/player/cat.tscn")

func _demo_world() -> Node3D:
	var b := _builder()
	b.build(WorldBuilder.load_layout("res://data/layout/terrain_demo.json"))
	return b

func _cat_at(pos: Vector3) -> Node:
	var cat = CatScene.instantiate()
	cat.position = pos
	add_child_autofree(cat)
	return cat

func test_kit_colliders_are_slopes() -> void:
	var c: Array = WorldBuilder.kit_colliders("ramp2")
	assert_eq(c.size(), 1)
	assert_almost_eq(float(c[0]["rot"][0]), 25.0, 0.01, "пандус 25°")
	var s: Array = WorldBuilder.kit_colliders("terrace_stairs2")
	assert_lt(float(s[0]["rot"][0]), 35.0, "ход лестницы не круче 35°")
	assert_eq(WorldBuilder.kit_colliders("bin"), [], "обычные пропсы — без особых коллайдеров")

func test_cat_stands_on_slope_without_sliding() -> void:
	var cat = _cat_at(Vector3(13, t.height_at(13, 8) + 0.1, 8))   # склон холма ≈ 20°
	await wait_physics_frames(30)
	var p0: Vector3 = cat.global_position
	await wait_physics_frames(60)
	assert_lt(Vector2(cat.global_position.x - p0.x, cat.global_position.z - p0.z).length(), 0.05, "кот на склоне не сползает")

func _walk(cat, action: String, frames: int) -> void:
	Input.action_press(action)
	await wait_physics_frames(frames)
	Input.action_release(action)

func test_cat_climbs_ramp_and_stairs_to_terrace() -> void:
	_demo_world()
	await wait_physics_frames(2)
	for start in [Vector3(0.5, 0.1, -10), Vector3(-1.0, 0.1, -15.5)]:
		var cat = _cat_at(start)
		await wait_physics_frames(10)
		await _walk(cat, "move_left", 300)   # без камеры «влево» — это −X; на подъёме горизонтальная скорость ниже
		assert_gt(cat.global_position.y, 1.8, "с %s кот поднялся на террасу" % start)
		cat.queue_free()
		await wait_physics_frames(2)

func test_cat_jumps_down_from_terrace_unhurt() -> void:
	GameState.reset()
	var cat = _cat_at(Vector3(-7, 2.1, -12))
	await wait_physics_frames(10)
	await _walk(cat, "move_right", 60)
	await wait_physics_frames(30)
	assert_lt(cat.global_position.y, 0.3, "спрыгнул вниз")
	assert_eq(GameState.hearts, 3, "без урона")

func test_props_are_in_place_on_the_very_first_physics_frame() -> void:
	# Пропс, добавленный в начале координат и только потом сдвинутый, выталкивал кота сквозь рельеф.
	var b := _builder()
	b.build({"props": [{"model": "box", "pos": [15, 0, -15]}]})
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(0, 0.2, 0)
	q.collision_mask = Layers.WORLD
	var names := space.intersect_point(q, 4).map(func(h): return String(h["collider"].name))
	assert_false(names.any(func(n): return n.begins_with("box")), "в начале координат нет призрака коробки: %s" % [names])

func test_stairs_collider_meets_every_tread_top() -> void:
	# Ревью плана 10: плита шла через внутренние углы ступеней, кот тонул в ступенях до 20 см.
	var b := _builder()
	b.build({"props": [{"model": "terrace_stairs2", "pos": [15, 0, -12]}]})
	await wait_physics_frames(2)
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	for k in 10:
		var d := WorldBuilder.KIT_STEP_TREAD * (k + 0.5)
		var from := Vector3(15, 5, -12 - d)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 10, Layers.WORLD))
		assert_false(hit.is_empty())
		if not hit.is_empty():
			assert_almost_eq((hit["position"] as Vector3).y, WorldBuilder.KIT_STEP_RISE * (k + 1), 0.06, "середина ступени %d" % k)

func test_cat_cannot_walk_up_a_one_metre_terrace() -> void:
	# Спек, раздел 3: floor_max_angle 40°; обрыв террасы 1 м (45° в карте высот) пешком не проходится.
	var cat = _cat_at(Vector3(-10, 0.1, 0))
	await wait_physics_frames(10)
	await _walk(cat, "move_left", 180)
	assert_lt(cat.global_position.y, 0.5, "кот остался внизу у террасы 1 м")
	assert_almost_eq(rad_to_deg(cat.floor_max_angle), 40.0, 0.1)

func test_flat_tiles_are_two_triangles() -> void:
	# План 11: плоский тайл 30×30 — 2 треугольника вместо 1800 (спек: ≤ 40 000 на район).
	# Плоский рельеф 61×61 пишется прямо в тесте: районы игры теперь холмистые (планы 11–12).
	var n := 61
	var rows := []
	for j in n:
		var row := []
		row.resize(n)
		row.fill(0.0)
		rows.append(row)
	var splat := PackedByteArray()
	splat.resize(n * n * 4)
	var f := FileAccess.open("user://flat_terrain.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"nx": n, "nz": n, "cell": 1.0, "origin": [-30, -30], "size": [60, 60],
		"heights": rows, "splat": Marshalls.raw_to_base64(splat)}))
	f.close()
	var flat := Terrain.new()
	flat.data_path = "user://flat_terrain.json"
	add_child_autofree(flat)
	await wait_physics_frames(1)
	var tiles := flat.find_children("Tile*", "MeshInstance3D", false, false)
	assert_eq(flat.triangle_count(), tiles.size() * 2, "плоский парк — по 2 треугольника на тайл")

func test_terrain_without_data_answers_zero() -> void:
	var bad := Terrain.new()
	bad.data_path = "res://data/terrain/none.json"
	add_child_autofree(bad)
	assert_eq(bad.height_at(3, 3), 0.0)

func test_port_terrain_channels_use_sand_and_planks() -> void:
	# План 13: песок пляжа и доски причала — каналы карты покрытий.
	var n := 3
	var rows := [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
	var splat := PackedByteArray()
	splat.resize(n * n * 4)
	var f := FileAccess.open("user://port_channels.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"nx": n, "nz": n, "cell": 1.0, "origin": [0, 0], "size": [2, 2], "heights": rows,
		"splat": Marshalls.raw_to_base64(splat), "channels": ["paving", "sand", "planks", "grass"]}))
	f.close()
	var pt := Terrain.new()
	pt.data_path = "user://port_channels.json"
	add_child_autofree(pt)
	assert_eq((pt.material.get_shader_parameter("tex_g") as Texture2D).resource_path, "res://assets/images/textures/sand.png")
	assert_eq((pt.material.get_shader_parameter("tex_b") as Texture2D).resource_path, "res://assets/images/textures/planks.png")
```

## `tests/integration/test_wasp.gd`

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
	var first: Vector3 = w.global_position
	for i in 6:
		await wait_seconds(0.15)
		var flat: Vector3 = w.global_position - anchor
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

func test_wasp_at_default_height_stings_cat_on_floor() -> void:
	var w = WaspScene.instantiate()
	w.radius = 0.0
	world.add_child(w)
	w.global_position = Vector3(0, 0.5, 0)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 0.2, 10)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_seconds(0.6)
	assert_eq(GameState.hearts, 2, "оса на высоте по умолчанию достаёт стоящего кота")

func test_wasp_faces_direction_of_motion() -> void:
	var w = WaspScene.instantiate()
	w.radius = 2.0
	world.add_child(w)
	w.global_position = Vector3(0, 0.5, 0)
	await wait_physics_frames(2)
	var p0: Vector3 = w.global_position
	await wait_physics_frames(6)
	var motion: Vector3 = (w.global_position - p0).normalized()
	var forward: Vector3 = -w.global_transform.basis.z
	assert_gt(motion.dot(forward), 0.9, "оса летит головой вперёд")

func test_wasp_over_table_stings_cat_standing_on_table() -> void:
	# Ревью: оса над десертным столом (h 1,0, r 0,8) должна доставать кота на краю столешницы.
	var table := StaticBody3D.new()
	table.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.06, 0.9)
	shape.shape = box
	shape.position.y = 0.72
	table.add_child(shape)
	world.add_child(table)
	var w = WaspScene.instantiate()
	w.radius = 0.8
	w.height = 1.0
	w.angular_speed = 3.0
	world.add_child(w)
	w.global_position = Vector3(0, 1.0, 0)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0.4, 0.8, 0)
	await wait_seconds(2.5)
	assert_eq(GameState.hearts, 2, "кот на краю стола получает укус за один оборот")

func test_wasp_has_a_trail() -> void:
	var w = WaspScene.instantiate()
	world.add_child(w)
	assert_not_null(w.find_child("Trail", false, false), "за осой серый шлейф")

func test_wasp_flies_above_terrace() -> void:
	# План 11: оса над террасой летает на height над землёй, а не над нулём.
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

## `tests/integration/test_water.gd`

```gdscript
extends GutTest
## План 12: вода по правилам этапа 3 (спек порта, раздел 2) — кот тонет и возвращается на ближайший берег.

const CatScene := preload("res://scenes/player/cat.tscn")

var world: Node3D

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)

func _floor(y: float, size := 30.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.2, size)
	shape.shape = box
	shape.position.y = y - 0.1
	body.add_child(shape)
	world.add_child(body)

func _water(level: float) -> Water:
	var w := Water.new()
	w.size = Vector3(10, 3, 10)
	w.position = Vector3(0, level, 0)
	world.add_child(w)
	return w

func _shore(pos: Vector3) -> void:
	var m := Marker3D.new()
	m.add_to_group("shore")
	m.position = pos
	world.add_child(m)

func test_cat_sinking_into_water_drowns_and_returns_to_nearest_shore() -> void:
	_floor(-1.5)
	_water(-0.5)
	_shore(Vector3(8, 1.0, 0))
	_shore(Vector3(-14, 1.0, 0))
	var island := StaticBody3D.new()   # суша под маркерами
	island.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 0.2, 4)
	shape.shape = box
	island.add_child(shape)
	island.position = Vector3(8, 0.9, 0)
	world.add_child(island)
	GameState.pick_up(FoodCatalog.get_by_id(&"popcorn"))
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, -1.4, 0)
	world.add_child(cat)
	await wait_physics_frames(5)
	assert_gt(cat.drowning_left, 0.0, "кот тонет")
	await wait_seconds(1.5)
	assert_lt(Vector2(cat.global_position.x - 8, cat.global_position.z).length(), 0.5, "на ближайшем берегу")
	assert_true(GameState.mouth.is_empty(), "еда из зубов потеряна")
	assert_eq(GameState.hearts, 3, "сердечко цело")
	assert_gt(cat.invulnerable_left, 0.0, "неуязвимость после возврата")

func test_cat_on_shore_is_not_drowned() -> void:
	_floor(0.0)
	_water(-0.5)
	var cat = CatScene.instantiate()
	cat.position = Vector3(2, 0.05, 2)
	world.add_child(cat)
	await wait_seconds(1.0)
	assert_eq(cat.drowning_left, 0.0)

func test_water_surface_mesh_is_at_level() -> void:
	var w := _water(-0.5)
	var s := w.get_node("Surface") as MeshInstance3D
	assert_almost_eq(s.global_position.y, -0.5, 0.001)
	assert_true(s.material_override is ShaderMaterial, "поверхность — шейдер воды")

func test_builder_builds_water_zones_and_shore() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"water_zones": [{"pos": [3, -0.5, 4], "size": [6, 2, 6]}], "shore": [{"pos": [10, 0, 4]}]})
	var w := b.find_children("*", "Water", true, false)
	assert_eq(w.size(), 1)
	if w.size() == 1:
		assert_almost_eq((w[0] as Water).level, -0.5, 0.001)
	assert_eq(get_tree().get_nodes_in_group("shore").size(), 1)

func test_drowning_cat_cannot_be_hit_or_petted() -> void:
	# Ревью плана 12: сторож догонял тонущего кота и снимал сердечко (спек: в воде сердечко не снимается).
	_floor(-1.5)
	_water(-0.5)
	_shore(Vector3(8, 1.0, 0))
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, -1.4, 0)
	world.add_child(cat)
	await wait_physics_frames(5)
	assert_gt(cat.drowning_left, 0.0)
	cat.invulnerable_left = 0.0
	cat.take_hit(Vector3(1, -1.4, 0))
	assert_eq(GameState.hearts, 3, "удар по тонущему не проходит")
	assert_false(cat.pet(2.0), "тонущего не гладят")

func test_water_is_opaque_for_reflections() -> void:
	# Ревью плана 12: с ALPHA вода шла прозрачным проходом, а SSR на прозрачное не действует (спек: зеркальная вода).
	var w := _water(-0.5)
	var mat := (w.get_node("Surface") as MeshInstance3D).material_override as ShaderMaterial
	assert_false(mat.shader.code.contains("ALPHA"), "вода непрозрачная — отражения SSR")

func test_camera_follows_cat_back_to_shore() -> void:
	# Ревью плана 12: после возврата из воды камера плыла через весь пруд (в порту — через море).
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_physics_frames(5)
	var cat = main.find_child("Cat", true, false)
	cat.global_position = Vector3(-28, -1.2, 66)   # дно пруда парка
	await wait_seconds(1.3)
	assert_eq(cat.drowning_left, 0.0, "вернулся на берег")
	var rig: Node3D = main.get("_rig")
	assert_lt(Vector2(rig.global_position.x - cat.global_position.x, rig.global_position.z - cat.global_position.z).length(), 0.5, "камера сразу у кота")
	SaveGame.clear()
```

## `tests/integration/test_world_builder.gd`

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
		"yarn": [{"pos": [3, 0, 3]}],
		"gates": [{"pos": [0, 0, 5], "satiety": 10}],
		"shop": {"pos": [4, 0, 4], "rot": 0},
	})
	assert_eq(b.props_built, 2)
	assert_eq(b.yarn_built, 1)
	assert_eq(b.gates_built, 1)
	assert_eq(b.shop_built, 1)
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
	for m in ["cafe_table", "chair", "umbrella", "cafe_sign"]:
		assert_true(models.has(m), "в раскладке есть " + m)
	var tables := 0
	var elevated_spawns := 0
	for p in data["props"]:
		if p["model"] == "cafe_table":
			tables += 1
			assert_true(p.has("colliders"), "у стола явный коллайдер столешницы")
	for sp in data["spawn_points"]:
		if sp["pos"][1] > 0.5:
			elevated_spawns += 1
	assert_gte(tables, 4)
	assert_gte(elevated_spawns, 3, "еда на столах и балконе")
	assert_eq(data["hazards"].size(), 9, "двор ×3: 3 собаки, 4 осы, 2 велосипедиста")
	var b = _builder()
	b.build(data)
	assert_eq(b.props_built, data["props"].size(), "все модели существуют")

# --- Инварианты раскладки (после ревью плана 2) ---

func _yard_with_floor() -> Node3D:
	var world := Node3D.new()
	add_child_autofree(world)
	var t := Terrain.new()
	t.data_path = "res://data/terrain/yard.json"   # пол двора — рельеф (планы 10–11)
	world.add_child(t)
	var b: Node3D = BuilderScript.new()
	b.terrain = t
	world.add_child(b)
	b.build(BuilderScript.load_layout("res://data/layout/yard.json"))
	return world

func _prop_at(world: Node3D, point: Vector3) -> String:
	var space := world.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.position = point
	q.collision_mask = Layers.WORLD
	for hit in space.intersect_point(q, 8):
		var body: Node = hit["collider"]
		if body.name != "Floor":
			return body.name
	return ""

func test_elevated_spawn_points_stand_on_props_not_air() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	var space := world.get_world_3d().direct_space_state
	var t := world.find_children("*", "Terrain", true, false)[0] as Terrain
	for sp in world.find_children("*", "FoodSpawnPoint", true, false):
		var pos: Vector3 = (sp as Node3D).global_position
		if pos.y - t.height_at(pos.x, pos.z) < 0.5:   # приподнятая — над рельефом, а не над нулём (террасы, холм)
			continue
		var ray := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD)
		var hit := space.intersect_ray(ray)
		assert_false(hit.is_empty(), "под точкой %s что-то есть" % pos)
		if not hit.is_empty():
			assert_ne(hit["collider"].name, "Floor", "точка %s должна стоять на пропсе, а не висеть над полом" % pos)
			assert_lt(pos.y - hit["position"].y, 0.3, "еда не выше 30 см над опорой")

func test_spawn_points_and_hideouts_are_not_inside_props() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	for sp in world.find_children("*", "FoodSpawnPoint", true, false):
		var pos: Vector3 = (sp as Node3D).global_position + Vector3(0, 0.1, 0)
		assert_eq(_prop_at(world, pos), "", "точка спавна %s внутри пропса" % pos)
	for h in world.find_children("*", "Hideout", true, false):
		var pos: Vector3 = (h as Node3D).global_position
		assert_eq(_prop_at(world, pos), "", "укрытие %s (%s) внутри пропса: кот не сможет туда встать" % [pos, h.kind])

func test_arch_opening_and_tree_sides_are_passable() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	assert_eq(_prop_at(world, Vector3(0, 0.5, 10.5)), "gate_0", "в проёме арки стоят закрытые ворота")
	GameState.satiety = GameState.SATIETY_GATE
	GameState.satiety_changed.emit(GameState.satiety)
	await wait_physics_frames(2)
	assert_eq(_prop_at(world, Vector3(0, 0.5, 10.5)), "", "после открытия проём свободен")
	assert_eq(_prop_at(world, Vector3(9.7, 0.5, -6)), "", "рядом со стволом дерева должно быть проходимо")

func test_yarn_balls_in_layout_stand_on_something() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	var data := BuilderScript.load_layout("res://data/layout/yard.json")
	assert_gte(data["yarn"].size(), 40, "двор ×3: не меньше 40 клубочков (спек «Масштаб», раздел 2)")
	var space := world.get_world_3d().direct_space_state
	for y in world.find_children("*", "YarnPickup", true, false):
		var pos: Vector3 = (y as Node3D).global_position
		var ray := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD)
		var hit := space.intersect_ray(ray)
		assert_false(hit.is_empty(), "под клубочком %s пусто" % pos)
		if not hit.is_empty():
			assert_lt(pos.y - hit["position"].y, 0.3, "клубочек %s висит в воздухе" % pos)
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "клубочек %s внутри пропса" % pos)

func test_water_props_get_mirror_material() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "puddle", "pos": [0, 0, 0], "water": true}]})
	assert_eq(b.water_built, 1)
	var mi := b.find_child("Model", true, false).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_lt(m.roughness, 0.1, "лужа зеркальная")
	assert_almost_eq(m.metallic, 0.0, 0.01)

func test_real_yard_puddles_are_water() -> void:
	var data := WorldBuilder.load_layout("res://data/layout/yard.json")
	for p in data["props"]:
		if p["model"] == "puddle":
			assert_true(bool(p.get("water", false)), "лужи в раскладке помечены water")

func test_decals_are_textured_quads_on_ground_and_walls() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"decals": [
		{"texture": "assets/images/world/decal_manhole.png", "pos": [1, 0, 2], "size": [1.0, 1.0]},
		{"texture": "assets/images/world/poster_cafe.png", "pos": [0, 1.5, -13.9], "size": [1.2, 1.2], "rot": 0, "wall": true}]})
	assert_eq(b.decals_built, 2)
	if b.decals_built != 2:
		return
	var ground := b.get_node("Decals").get_child(0) as MeshInstance3D
	assert_true(ground.mesh is QuadMesh)
	assert_almost_eq(ground.global_position.y, 0.01, 0.001, "чуть над асфальтом")
	assert_almost_eq(absf(ground.global_transform.basis.y.y), 0.0, 0.01, "лежит плашмя")
	var wall := b.get_node("Decals").get_child(1) as MeshInstance3D
	assert_almost_eq(wall.global_transform.basis.y.y, 1.0, 0.01, "стоит вертикально")
	assert_not_null((ground.get_surface_override_material(0) as StandardMaterial3D).albedo_texture)

func test_non_solid_props_have_no_collision() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "grass", "pos": [0, 0, 0], "solid": false}, {"model": "ivy", "pos": [0, 1, -13.9], "solid": false}]})
	assert_eq(b.props_built, 2)
	for body in b.get_node("Props").get_children():
		assert_eq(body.find_children("*", "CollisionShape3D", true, false).size(), 0, "%s без коллайдера" % body.name)

func test_real_yard_has_greenery_and_decals() -> void:
	var data := WorldBuilder.load_layout("res://data/layout/yard.json")
	var models := {}
	for p in data["props"]:
		models[p["model"]] = models.get(p["model"], 0) + 1
	assert_gte(models.get("bush", 0), 8, "кусты вдоль стен")
	assert_gte(models.get("grass", 0), 10, "трава пучками")
	assert_gte(models.get("ivy", 0), 3, "плющ на фасаде")
	assert_gte(data.get("decals", []).size(), 6, "декали и плакаты")
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build(data)
	assert_eq(b.decals_built, data.get("decals", []).size(), "все текстуры декалей существуют")

func test_wall_decals_and_ivy_hang_on_real_walls() -> void:
	# Ревью плана 5: плакат висел в воздухе за краем северной стены. У каждой настенной декали и плюща должна быть стена сзади.
	var data := WorldBuilder.load_layout("res://data/layout/yard.json")
	var walls := []
	for p in data["props"]:
		if p["model"] == "wall":
			walls.append({"pos": WorldBuilder._v3(p["pos"]), "rot": int(p.get("rot", 0)) % 180})
	var items := []
	for dc in data["decals"]:
		if dc.get("wall", false):
			items.append({"pos": WorldBuilder._v3(dc["pos"]), "rot": int(dc.get("rot", 0)) % 180, "name": dc["texture"]})
	for p in data["props"]:
		if p["model"] == "ivy":
			items.append({"pos": WorldBuilder._v3(p["pos"]), "rot": int(p.get("rot", 0)) % 180, "name": "ivy"})
	for it in items:
		var backed := false
		for w in walls:
			var d: Vector3 = (it["pos"] as Vector3) - (w["pos"] as Vector3)
			var along := absf(d.x) if w["rot"] == 0 else absf(d.z)
			var across := absf(d.z) if w["rot"] == 0 else absf(d.x)
			if along <= 3.0 and across <= 0.5 and w["rot"] == it["rot"]:
				backed = true
		assert_true(backed, "%s в %s висит на стене" % [it["name"], it["pos"]])

func test_garage_roof_is_walkable_at_2_28() -> void:
	# План 11: крыши гаражей — площадки для паркура.
	var b = _builder()
	b.build({"props": [{"model": "garage", "pos": [0, 0, 0]}]})
	await wait_physics_frames(1)
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 5, 0), Vector3(0, -1, 0), Layers.WORLD))
	assert_false(hit.is_empty(), "крыша гаража твёрдая")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 2.28, 0.05)

func test_small_props_fade_out_beyond_40m() -> void:
	# План 11: на большом дворе мелочь не рисуется дальше 40 м.
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

const GAZEBO_COLLIDERS := [{"size": [3.4, 0.3, 3.4], "offset": [0, 0.15, 0]},
	{"size": [0.16, 2.2, 0.16], "offset": [1.85, 1.4, 0]}, {"size": [0.16, 2.2, 0.16], "offset": [-1.85, 1.4, 0]},
	{"size": [0.16, 2.2, 0.16], "offset": [0.925, 1.4, 1.602]}, {"size": [0.16, 2.2, 0.16], "offset": [-0.925, 1.4, 1.602]},
	{"size": [0.16, 2.2, 0.16], "offset": [0.925, 1.4, -1.602]}, {"size": [0.16, 2.2, 0.16], "offset": [-0.925, 1.4, -1.602]}]

func test_gazebo_floor_and_posts_are_solid_but_inside_is_free() -> void:
	# План 12: беседка на холме парка — пол 0,3 м, внутри проходимо.
	var b = _builder()
	b.build({"props": [{"model": "gazebo", "pos": [0, 0, 0], "colliders": GAZEBO_COLLIDERS}]})
	await wait_physics_frames(1)
	assert_eq(b.props_built, 1, "модель беседки есть")
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0.5, 5, 0.3), Vector3(0.5, -1, 0.3), Layers.WORLD))
	assert_false(hit.is_empty())
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 0.3, 0.02, "пол беседки")
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(0.5, 0.6, 0.3)
	q.collision_mask = Layers.WORLD
	assert_eq(space.intersect_point(q).size(), 0, "внутри беседки свободно")
```

## `tests/integration/test_yard_x3.gd`

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

func test_street_is_closed_except_arch() -> void:
	# План 12: из двора на улицу и в кафе — только через арку с воротами по сытости 10 (спек 3.4).
	var space := world.get_world_3d().direct_space_state
	for x in range(-87, 88, 6):
		if absi(x) < 2:
			continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 0.3, 9.5), Vector3(x, 0.3, 11.5), Layers.WORLD))
		assert_false(hit.is_empty(), "забор вдоль улицы у x %d" % x)
```

## `tests/integration/test_yarn.gd`

```gdscript
extends GutTest

const YarnScene := preload("res://scenes/food/yarn_pickup.tscn")
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

func test_cat_collects_yarn_on_contact() -> void:
	var y = YarnScene.instantiate()
	world.add_child(y)
	y.global_position = Vector3(0, 0.05, 0)
	var cat = CatScene.instantiate()
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_physics_frames(5)
	assert_eq(GameState.yarn, 1)
	assert_true(not is_instance_valid(y) or y.is_queued_for_deletion())
	assert_eq(get_tree().get_nodes_in_group("yarn").size(), 0, "клубочек не респавнится")

func test_collected_yarn_does_not_return_after_relaunch() -> void:
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_physics_frames(5)
	var before := get_tree().get_nodes_in_group("yarn").size()
	var expected := 0
	for path in ["res://data/layout/yard.json", "res://data/layout/park.json", "res://data/layout/port.json"]:
		expected += (WorldBuilder.load_layout(path)["yarn"] as Array).size()
	assert_eq(before, expected, "все клубочки двора, парка и порта")
	var first = get_tree().get_nodes_in_group("yarn")[0]
	var key: String = first.key
	GameState.take_yarn(key)
	SaveGame.save_now()
	main.queue_free()
	await wait_physics_frames(2)
	GameState.reset()
	var main2 := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main2)
	await wait_physics_frames(5)
	assert_eq(get_tree().get_nodes_in_group("yarn").size(), before - 1, "собранный клубочек не вернулся")
	assert_eq(GameState.yarn, 1)
	SaveGame.clear()
```

## `tests/integration/test_yarn_shop.gd`

```gdscript
extends GutTest

const ShopScene := preload("res://scenes/world/yarn_shop.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var world: Node3D
var cat
var rig
var shop

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
	shop = ShopScene.instantiate()
	world.add_child(shop)
	shop.global_position = Vector3(0, 0, -5)
	rig = RigScene.instantiate()
	cat = CatScene.instantiate()
	cat.camera_rig = rig
	rig.target = cat
	world.add_child(rig)
	world.add_child(cat)

func test_zone_flags_cat_and_blocks_hits() -> void:
	cat.global_position = Vector3(0, 0.05, -5)
	await wait_physics_frames(3)
	assert_true(shop.cat_inside)
	assert_true(cat.in_safe_zone)
	cat.take_hit(Vector3(1, 0, -5))
	assert_eq(GameState.hearts, 3, "в будке не бьют")
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_physics_frames(3)
	assert_false(cat.in_safe_zone)

func test_respawn_position_is_inside_zone() -> void:
	var p: Vector3 = shop.respawn_position()
	assert_lt(p.distance_to(Vector3(0, 0, -5)), 1.0)

func test_input_disabled_keeps_cat_still() -> void:
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_physics_frames(3)
	cat.input_enabled = false
	Input.action_press("move_forward")
	await wait_physics_frames(30)
	Input.action_release("move_forward")
	assert_lt(cat.global_position.distance_to(Vector3(0, 0.05, 0)), 0.1)
	assert_eq(cat.state, &"idle")

func test_shop_view_moves_camera_near_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -5)
	rig.global_position = Vector3(0, 0.6, -3)
	rig.shop_view = true
	await wait_seconds(0.8)
	var expected: Vector3 = cat.global_position + CameraRig.SHOP_OFFSET
	assert_lt(rig.global_position.distance_to(expected), 0.3)
	rig.shop_view = false

func test_yarn_play_balls_move() -> void:
	var play := shop.get_node("YarnPlay") as Node3D
	assert_eq(play.get_child_count(), 3)
	var p0: Vector3 = (play.get_child(0) as Node3D).position
	await wait_seconds(0.3)
	assert_gt((play.get_child(0) as Node3D).position.distance_to(p0), 0.05, "клубочки катаются")

func test_shop_view_makes_cat_visible_even_if_camera_was_pinned() -> void:
	cat.global_position = Vector3(0, 0.05, -5)
	cat.visible = false   # камера упиралась в стенку и спрятала кота
	rig.shop_view = true
	await wait_physics_frames(2)
	assert_true(cat.visible, "в витрине кот всегда виден")
	rig.shop_view = false

func test_floor_plate_is_solid() -> void:
	await wait_physics_frames(2)
	var space := world.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0, 1, -5), Vector3(0, -1, -5), Layers.WORLD)
	var hit := space.intersect_ray(q)
	assert_false(hit.is_empty(), "луч вниз в будке во что-то упирается")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 0.03, 0.005, "упирается в плиту будки, а не в землю")
```

## `tests/unit/test_balance.gd`

```gdscript
extends GutTest
## Плейтест баланса по спеку 3.3 числами, не ощущениями: жадный маршрут по точкам спавна двора.
## Шаг 2 м/с (без бега — нижняя оценка), 0,6 с на подбор, после каждых трёх подборов — к ближайшему
## укрытию и 2 с на съедание. Сытость точки — матожидание по весам редкостей.

const WALK := CatMotion.WALK_SPEED
const PICK := 0.6
const EAT := 2.0
const GATE_Z := 10.5   # арка; дальше кафе, до открытия недоступно


static func expected_satiety(allowed: Array) -> float:
	var total := 0.0
	var acc := 0.0
	for t in allowed:
		total += Rarity.WEIGHTS[int(t)]
		acc += Rarity.WEIGHTS[int(t)] * Rarity.SATIETY[int(t)]
	return acc / total if total > 0.0 else 0.0


static func estimate_seconds(layout: Dictionary, target: int) -> float:
	var points := []
	for s in layout["spawn_points"]:
		var p: Vector3 = WorldBuilder._v3(s["pos"])
		if p.z < GATE_Z:
			points.append({"pos": p, "sat": expected_satiety(s.get("allowed", [0]))})
	var hideouts := []
	for h in layout["hideouts"]:
		hideouts.append(WorldBuilder._v3(h["pos"]))
	var pos := Vector3.ZERO   # стартовый маркер Spawn
	var time := 0.0
	var satiety := 0.0
	var carried := 0
	var visited := {}
	while satiety < target and visited.size() < points.size():
		var best := -1
		var best_d := INF
		for i in points.size():
			if visited.has(i):
				continue
			var d: float = pos.distance_to(points[i]["pos"])
			if d < best_d:
				best_d = d
				best = i
		visited[best] = true
		pos = points[best]["pos"]
		time += best_d / WALK + PICK
		carried += 1
		satiety += points[best]["sat"]
		if carried >= GameState.MOUTH_CAPACITY:
			var hd := INF
			var hp := pos
			for h in hideouts:
				if pos.distance_to(h) < hd:
					hd = pos.distance_to(h)
					hp = h
			time += hd / WALK + EAT
			pos = hp
			carried = 0
	if carried > 0:
		time += EAT
	return time if satiety >= target else INF


func test_yard_has_enough_food_for_the_gate() -> void:
	var layout := WorldBuilder.load_layout("res://data/layout/yard.json")
	var total := 0.0
	for s in layout["spawn_points"]:
		if WorldBuilder._v3(s["pos"]).z < GATE_Z:
			total += expected_satiety(s.get("allowed", [0]))
	assert_gte(total, float(GameState.SATIETY_GATE), "за один обход двора (без респавна) сытости хватает на арку")


func test_yard_opens_cafe_within_three_minutes() -> void:
	var layout := WorldBuilder.load_layout("res://data/layout/yard.json")
	var t := estimate_seconds(layout, GameState.SATIETY_GATE)
	gut.p("оценка времени до арки: %.0f с при пороге %d" % [t, GameState.SATIETY_GATE])
	assert_lt(t, 180.0, "спек 3.3: 2–3 минуты до арки; если дольше — порог 6")
```

## `tests/unit/test_cat_motion.gd`

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

func test_input_actions_registered() -> void:
	var InputSetupScript := load("res://scripts/autoload/input_setup.gd")
	InputSetupScript.register()
	for a in ["move_left", "move_right", "move_forward", "move_back", "run", "jump", "hide", "eat", "cam_left", "cam_right", "album", "pause"]:
		assert_true(InputMap.has_action(a), "нет действия " + a)

func test_speed_mult_scales_walk_and_state_threshold() -> void:
	var v := Vector3.ZERO
	for i in 120:
		v = CatMotion.step(v, Vector3(0, 0, -1), false, true, false, D, 1.15)
	assert_almost_eq(v.z, -CatMotion.WALK_SPEED * 1.15, 0.01)
	assert_eq(CatMotion.pick_state(v, true, false, 1.15), &"walk", "ускоренная ходьба — всё ещё walk")
	assert_eq(CatMotion.pick_state(Vector3(0, 0, -4.6), true, true, 1.15), &"run")
```

## `tests/unit/test_chase_brain.gd`

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

func test_safe_zone_ends_chase_immediately() -> void:
	var b := ChaseBrain.new()
	b.update(0.1, true, false, false)
	b.update(1.0, true, false, false)
	assert_eq(b.state, ChaseBrain.State.CHASE)
	assert_eq(b.update(0.1, false, true, false, true), ChaseBrain.State.RETURN, "кот в будке — собака уходит сразу")
	var a := ChaseBrain.new()
	a.update(0.1, true, false, false)
	assert_eq(a.state, ChaseBrain.State.ALERT)
	assert_eq(a.update(0.1, true, true, false, true), ChaseBrain.State.IDLE, "насторожилась, но кот уже в будке")
```

## `tests/unit/test_day_cycle.gd`

```gdscript
extends GutTest

func test_phases_by_time() -> void:
	assert_eq(DayCycle.phase_at(0.0), &"day")
	assert_eq(DayCycle.phase_at(149.9), &"day")
	assert_eq(DayCycle.phase_at(160.0), &"evening")
	assert_eq(DayCycle.phase_at(200.0), &"night")
	assert_eq(DayCycle.phase_at(280.0), &"morning")
	assert_eq(DayCycle.phase_at(300.0), &"day", "цикл замыкается")
	assert_eq(DayCycle.phase_at(-10.0), &"morning", "отрицательное время оборачивается")

func test_phase_progress_counts_to_next_phase() -> void:
	assert_almost_eq(DayCycle.phase_progress(75.0), 0.5, 0.001)
	assert_almost_eq(DayCycle.phase_progress(225.0), 0.5, 0.001)

func test_keyframes_hold_and_blend() -> void:
	var day := DayCycle.light_at(50.0)
	assert_almost_eq(day["sun_pitch"], -65.0, 0.01)
	assert_almost_eq(day["sun_energy"], 1.2, 0.001)
	assert_eq((day["sun_color"] as Color).to_html(false), "fff1d6")
	var night := DayCycle.light_at(220.0)
	assert_almost_eq(night["sun_energy"], 0.22, 0.001)
	assert_almost_eq(night["ambient"], 0.18, 0.001)
	assert_eq((night["sky_top"] as Color).to_html(false), "0b1633")
	var mid := DayCycle.light_at(157.5)   # середина перехода день → закат
	assert_almost_eq(mid["sun_energy"], (1.2 + 0.8) / 2.0, 0.01)

func test_wrap_is_continuous() -> void:
	# Review Focus 4
	var a := DayCycle.light_at(299.99)
	var b := DayCycle.light_at(0.0)
	assert_almost_eq(a["sun_energy"], b["sun_energy"], 0.01)
	assert_almost_eq(a["sun_pitch"], b["sun_pitch"], 0.1)

func test_lamps_on_from_dusk_to_dawn() -> void:
	assert_false(DayCycle.lamps_on(100.0))
	assert_true(DayCycle.lamps_on(170.0))
	assert_true(DayCycle.lamps_on(250.0))
	assert_false(DayCycle.lamps_on(290.0))
```

## `tests/unit/test_floater_math.gd`

```gdscript
extends GutTest
## План 13: качание лодок и бочек — подъём ±amp, крен ±roll, период, фаза (спек порта, раздел 2).

func test_offset_is_periodic_and_bounded() -> void:
	for i in 40:
		var t := i * 0.173
		var o := Floater.offset_at(t, 0.12, 6.0, 3.5, 1.0)
		assert_between(o.x, -0.1201, 0.1201)
		assert_between(o.y, -6.001, 6.001)
		var o2 := Floater.offset_at(t + 3.5, 0.12, 6.0, 3.5, 1.0)
		assert_almost_eq(o2.x, o.x, 0.0001, "период по подъёму")
		assert_almost_eq(o2.y, o.y, 0.0001, "период по крену")

func test_phase_shifts_motion() -> void:
	var a := Floater.offset_at(0.5, 0.12, 6.0, 3.5, 0.0)
	var b := Floater.offset_at(0.5, 0.12, 6.0, 3.5, 2.0)
	assert_gt(absf(a.x - b.x), 0.02, "разные фазы — разное положение")
```

## `tests/unit/test_game_state.gd`

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
	var eaten: Array = gs.eat_all()
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
	var fainted: bool = gs.take_hit()
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

func test_yarn_add_spend_and_card_bonus() -> void:
	watch_signals(gs)
	gs.add_yarn(2)
	assert_eq(gs.yarn, 2)
	assert_false(gs.spend_yarn(5), "нельзя уйти в минус")
	assert_eq(gs.yarn, 2)
	assert_true(gs.spend_yarn(2))
	assert_eq(gs.yarn, 0)
	gs.pick_up(sausage)
	gs.eat_all()
	assert_eq(gs.yarn, 3, "+3 за новую карточку")
	gs.pick_up(sausage)
	gs.eat_all()
	assert_eq(gs.yarn, 3, "повтор карточки клубочков не даёт")
	assert_signal_emitted(gs, "yarn_changed")

func test_steal_last_takes_only_the_last_food_without_damage() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	add_child_autofree(gs)
	gs.reset()
	gs.pick_up(FoodCatalog.get_by_id(&"cookie"))
	gs.pick_up(FoodCatalog.get_by_id(&"pizza"))
	watch_signals(gs)
	var f = gs.steal_last()
	assert_eq(f.id, &"pizza")
	assert_eq(gs.mouth.size(), 1)
	assert_eq(gs.hearts, 3, "кража не ранит")
	assert_signal_emitted(gs, "food_stolen")
	gs.mouth.clear()
	assert_null(gs.steal_last(), "из пустых зубов красть нечего")
```

## `tests/unit/test_images.gd`

```gdscript
extends GutTest
## Review Focus 5: манифест покрывает всю еду, файлы на месте; без ключа игра собирается.

func _manifest() -> Array:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string("res://tools/images/manifest.json")), OK)
	return json.data["images"]

func test_manifest_covers_all_food_and_files_exist() -> void:
	var files := {}
	for e in _manifest():
		files[e["file"]] = true
		assert_true(ResourceLoader.exists("res://" + e["file"]), "нет файла %s (make images)" % e["file"])
	for f in FoodCatalog.all():
		assert_true(files.has("assets/images/ui/food_%s.png" % f.id), "в манифесте нет иконки %s" % f.id)
		assert_not_null(f.icon(), "иконка %s загружается" % f.id)
	for extra in ["assets/images/ui/heart.png", "assets/images/title/title_bg.png", "assets/images/world/clouds.png"]:
		assert_true(files.has(extra), "в манифесте нет %s" % extra)

func test_icon_of_unknown_food_is_null_not_error() -> void:
	var f := FoodDef.new()
	f.id = &"nothing"
	assert_null(f.icon())
```

## `tests/unit/test_perception.gd`

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

## `tests/unit/test_pigeon_rules.gd`

```gdscript
extends GutTest
## Решение стаи голубей (спек этапа 2, раздел 3).

func test_steal_only_from_walking_cat_with_food_near() -> void:
	assert_eq(PigeonFlock.decide(1.2, false, 2, false, false, 0.0, false), &"steal")
	assert_eq(PigeonFlock.decide(2.0, false, 2, false, false, 0.0, false), &"none", "дальше 1,5 м — нет")
	assert_eq(PigeonFlock.decide(1.2, false, 0, false, false, 0.0, false), &"none", "нет еды в зубах")

func test_running_cat_scatters_flock() -> void:
	assert_eq(PigeonFlock.decide(2.2, true, 2, false, false, 0.0, false), &"scatter")
	assert_eq(PigeonFlock.decide(1.0, true, 0, false, false, 0.0, false), &"scatter", "разгоняет и без еды")

func test_no_theft_from_hidden_or_safe_cat_on_cooldown_or_at_night() -> void:
	# Review Focus 1
	assert_eq(PigeonFlock.decide(1.0, false, 2, true, false, 0.0, false), &"none", "спрятался")
	assert_eq(PigeonFlock.decide(1.0, false, 2, false, true, 0.0, false), &"none", "в будке")
	assert_eq(PigeonFlock.decide(1.0, false, 2, false, false, 4.0, false), &"none", "перерыв после кражи")
	assert_eq(PigeonFlock.decide(1.0, false, 2, false, false, 0.0, true), &"none", "ночью спят")
```

## `tests/unit/test_port_hazard_logic.gd`

```gdscript
extends GutTest
## План 14: чистая логика опасностей порта (спек порта, раздел 3).

func test_gull_dives_only_on_cat_with_food_below() -> void:
	assert_true(Gull.decide(4.0, true, false, false, 0.0, false), "кот с едой в 4 м — пикирует")
	assert_false(Gull.decide(7.0, true, false, false, 0.0, false), "дальше 6 м — нет")
	assert_false(Gull.decide(4.0, false, false, false, 0.0, false), "без еды — нет")
	assert_false(Gull.decide(4.0, true, true, false, 0.0, false), "спрятан — нет")
	assert_false(Gull.decide(4.0, true, false, true, 0.0, false), "в безопасной зоне — нет")
	assert_false(Gull.decide(4.0, true, false, false, 3.0, false), "перерыв — нет")
	assert_false(Gull.decide(4.0, true, false, false, 0.0, true), "ночью спит")

func test_wave_cycle_14s() -> void:
	# 0…3 накат, 3…6 откат, 6…12,5 тихо, 12,5…14 пена перед следующим накатом.
	assert_almost_eq(Wave.front_at(0.0), 0.0, 0.01)
	assert_almost_eq(Wave.front_at(3.0), 5.0, 0.01, "дальше всего через 3 с")
	assert_almost_eq(Wave.front_at(1.5), 2.5, 0.6, "накат идёт")
	assert_almost_eq(Wave.front_at(6.0), 0.0, 0.01, "откатилась")
	assert_almost_eq(Wave.front_at(9.0), 0.0, 0.01)
	assert_almost_eq(Wave.front_at(17.0), 5.0, 0.01, "период 14 с")
	assert_true(Wave.foam(13.0), "пена за 1,5 с")
	assert_false(Wave.foam(10.0))

func test_forklift_states() -> void:
	assert_eq(Forklift.next_state(&"wait", 3.0, 5.0, false), &"wait", "стоит у штабеля")
	assert_eq(Forklift.next_state(&"wait", 5.0, 5.0, false), &"horn", "потом гудит")
	assert_eq(Forklift.next_state(&"horn", 1.0, 5.0, false), &"horn")
	assert_eq(Forklift.next_state(&"horn", 1.5, 5.0, false), &"drive", "через 1,5 с едет")
	assert_eq(Forklift.next_state(&"drive", 2.0, 5.0, true), &"wait", "ночью стоит")
	assert_eq(Forklift.next_state(&"wait", 9.0, 5.0, true), &"wait")

func test_crab_burrow_chase_hide() -> void:
	assert_eq(Crab.decide(&"burrow", 2.5, false, 0.0, 0.0, false), &"chase", "кот ближе 3 м — выбегает")
	assert_eq(Crab.decide(&"burrow", 3.5, false, 0.0, 0.0, false), &"burrow")
	assert_eq(Crab.decide(&"burrow", 3.5, false, 0.0, 0.0, true), &"chase", "ночью радиус 4 м")
	assert_eq(Crab.decide(&"chase", 1.0, true, 1.0, 0.0, false), &"hide", "кот прыгнул над крабом")
	assert_eq(Crab.decide(&"chase", 1.0, false, 5.0, 0.0, false), &"hide", "5 с погони")
	assert_eq(Crab.decide(&"chase", 1.0, false, 2.0, 0.0, false), &"chase")
	assert_eq(Crab.decide(&"hide", 1.0, false, 0.0, 3.0, false), &"hide", "6 с в норке")
	assert_eq(Crab.decide(&"hide", 1.0, false, 0.0, 0.0, false), &"burrow", "потом снова сторожит")
```

## `tests/unit/test_rarity.gd`

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

func test_catalog_has_twenty_foods_in_every_tier() -> void:
	# Двор — по две еды в редкости, парк (этап 2) — ещё шесть, порт (этап 3) — ещё шесть: 6/6/4/4.
	assert_eq(FoodCatalog.all().size(), 20)
	var expected := {0: 6, 1: 6, 2: 4, 3: 4}
	for t in 4:
		assert_eq(FoodCatalog.by_tier(t).size(), expected[t], "еды в редкости %d" % t)
	var donut := FoodCatalog.get_by_id(&"donut")
	assert_not_null(donut)
	assert_eq(donut.tier, Rarity.Tier.LEGENDARY)
	assert_true(donut.sweet)
	assert_eq(donut.satiety(), 15)
	assert_eq(donut.display_name, "Пончик")

func test_night_weights_favor_rare_food() -> void:
	assert_eq(Rarity.NIGHT_WEIGHTS[Rarity.Tier.COMMON], 40)
	assert_eq(Rarity.NIGHT_WEIGHTS[Rarity.Tier.LEGENDARY], 10)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var all := [Rarity.Tier.COMMON, Rarity.Tier.RARE, Rarity.Tier.VERY_RARE, Rarity.Tier.LEGENDARY]
	var legend_day := 0
	var legend_night := 0
	for i in 2000:
		if Rarity.pick_weighted(all, rng) == Rarity.Tier.LEGENDARY:
			legend_day += 1
		if Rarity.pick_weighted(all, rng, Rarity.NIGHT_WEIGHTS) == Rarity.Tier.LEGENDARY:
			legend_night += 1
	assert_gt(legend_night, legend_day * 2, "ночью легендарная еда выпадает заметно чаще")

func test_port_foods_follow_spec() -> void:
	# Спек порта, раздел 5.
	var expected := {&"shrimp": [0, "Креветка"], &"fries": [0, "Картошка фри"], &"squid": [1, "Кальмар"],
		&"fish_sandwich": [1, "Рыбный сэндвич"], &"sushi": [2, "Суши"], &"golden_fish": [3, "Золотая рыбка"]}
	for id in expected:
		var f := FoodCatalog.get_by_id(id)
		assert_not_null(f, "есть %s" % id)
		if f:
			assert_eq(f.tier, expected[id][0])
			assert_eq(f.display_name, expected[id][1])
			assert_true(ResourceLoader.exists(f.model_path), "модель %s" % id)
```

## `tests/unit/test_save.gd`

```gdscript
extends GutTest

const TEST_PATH := "user://test_save_unit.json"

func before_each() -> void:
	GameState.reset()
	SaveGame.path = TEST_PATH
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()
	GameState.reset()

func test_round_trip_keeps_progress_but_not_hearts_or_mouth() -> void:
	GameState.add_yarn(30)
	GameState.buy(ShopCatalog.get_by_id(&"speed"))
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	GameState.eat_all()
	GameState.take_hit()
	GameState.pick_up(FoodCatalog.get_by_id(&"fish"))
	assert_true(SaveGame.save_now())
	GameState.reset()
	assert_true(SaveGame.load_now())
	assert_eq(GameState.album[&"donut"], 1)
	assert_eq(GameState.satiety, 15)
	assert_eq(GameState.yarn, 30 - 10 - 12 + 3)
	assert_true(GameState.owns(&"speed"))
	assert_almost_eq(GameState.speed_mult, 1.15, 0.001)
	assert_eq(GameState.skin, &"black")
	assert_eq(GameState.goal_done, 1)
	assert_eq(GameState.hearts, GameState.max_hearts, "сердечки не сохраняются, старт с полными")
	assert_eq(GameState.mouth.size(), 0, "еда в зубах не сохраняется")

func test_load_without_file_returns_false_and_keeps_clean_state() -> void:
	assert_false(SaveGame.load_now())
	assert_eq(GameState.yarn, 0)

func test_corrupted_file_gives_clean_state() -> void:
	# Review Focus 3
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{ это не json")
	f.close()
	assert_false(SaveGame.load_now())
	assert_eq(GameState.yarn, 0)
	assert_eq(GameState.album.size(), 0)
	var g := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	g.store_string("[1, 2, 3]")
	g.close()
	assert_false(SaveGame.load_now())
	var h := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	h.store_string('{"version": 1, "yarn": "много", "album": 5, "upgrades": {"speed": true}}')
	h.close()
	assert_true(SaveGame.load_now(), "частично валидный файл принимается")
	assert_eq(GameState.yarn, 0, "строка вместо числа игнорируется")
	assert_eq(GameState.album.size(), 0, "число вместо словаря игнорируется")
	assert_true(GameState.owns(&"speed"))

func test_clear_removes_file() -> void:
	SaveGame.save_now()
	assert_true(FileAccess.file_exists(TEST_PATH))
	SaveGame.clear()
	assert_false(FileAccess.file_exists(TEST_PATH))

func test_taken_yarn_keys_round_trip() -> void:
	GameState.take_yarn("1.5,0.6,1.5")
	assert_eq(GameState.yarn, 1)
	assert_true(GameState.is_yarn_taken("1.5,0.6,1.5"))
	SaveGame.save_now()
	GameState.reset()
	assert_false(GameState.is_yarn_taken("1.5,0.6,1.5"))
	SaveGame.load_now()
	assert_true(GameState.is_yarn_taken("1.5,0.6,1.5"), "список собранных клубочков сохраняется")

func test_read_only_save_writes_nothing() -> void:
	# План 14: кадры (make shot) собирали клубочки и автосохраняли их в настоящий save.json владельца.
	SaveGame.path = "user://test_save_ro.json"
	SaveGame.clear()
	SaveGame.read_only = true
	assert_false(SaveGame.save_now(), "в режиме только чтения не пишет")
	assert_false(FileAccess.file_exists("user://test_save_ro.json"))
	SaveGame.read_only = false

func test_dev_runs_are_detected() -> void:
	assert_true(DevTools.is_dev_run(PackedStringArray(["--screenshot=build/x.png"])))
	assert_true(DevTools.is_dev_run(PackedStringArray(["--at=1,2,3"])))
	assert_true(DevTools.is_dev_run(PackedStringArray(["--album"])))
	assert_true(DevTools.is_dev_run(PackedStringArray(["--phase=night"])))
	assert_false(DevTools.is_dev_run(PackedStringArray([])), "обычная игра пишет сохранение")
```

## `tests/unit/test_sfx.gd`

```gdscript
extends GutTest

func before_each() -> void:
	Sfx.reset_counters()

func test_all_six_streams_exist() -> void:
	for key in [&"pickup", &"eat", &"hit", &"meow", &"bark", &"bell", &"hiss", &"sprinkle", &"coo"]:
		assert_true(Sfx.has(key), "нет звука %s" % key)

func test_play_assigns_stream_and_counts() -> void:
	var p := Sfx.play(&"eat")
	assert_not_null(p)
	if p:
		assert_eq(p.stream.resource_path, "res://assets/sfx/eat.ogg")
	assert_eq(Sfx.last_played, &"eat")
	assert_eq(Sfx.counts.get(&"eat", 0), 1)
	assert_null(Sfx.play(&"nope"), "неизвестный звук не падает")
```

## `tests/unit/test_shop.gd`

```gdscript
extends GutTest

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var gs: Node

func before_each() -> void:
	gs = GameStateScript.new()
	add_child_autofree(gs)

func _item(id: String) -> ShopItem:
	return ShopCatalog.get_by_id(StringName(id))

func test_catalog_matches_spec_prices() -> void:
	assert_eq(ShopCatalog.all().size(), 10)
	assert_eq(_item("refill_hearts").price, 2)
	assert_eq(_item("max_heart_4").price, 8)
	assert_eq(_item("max_heart_5").price, 15)
	assert_eq(_item("mouth_4").price, 6)
	assert_eq(_item("mouth_5").price, 12)
	assert_eq(_item("speed").price, 10)
	assert_eq(_item("quiet").price, 10)
	assert_eq(_item("skin_black").price, 12)
	assert_eq(_item("max_heart_5").requires, &"max_heart_4")

func test_cannot_buy_without_yarn() -> void:
	# Review Focus 1
	gs.add_yarn(5)
	assert_false(gs.can_buy(_item("speed")))
	assert_false(gs.buy(_item("speed")))
	assert_eq(gs.yarn, 5)
	assert_false(gs.owns(&"speed"))

func test_buy_speed_once_only() -> void:
	# Review Focus 2
	gs.add_yarn(25)
	watch_signals(gs)
	assert_true(gs.buy(_item("speed")))
	assert_eq(gs.yarn, 15)
	assert_almost_eq(gs.speed_mult, 1.15, 0.001)
	assert_signal_emitted(gs, "upgrade_bought")
	assert_false(gs.can_buy(_item("speed")), "повторно не продаётся")
	assert_eq(gs.yarn, 15)

func test_quiet_reduces_dog_cone() -> void:
	gs.add_yarn(10)
	gs.buy(_item("quiet"))
	assert_almost_eq(gs.stealth_mult, 0.7, 0.001)

func test_max_hearts_chain_and_refill() -> void:
	gs.add_yarn(30)
	assert_false(gs.can_buy(_item("max_heart_5")), "сначала четвёртое сердечко")
	assert_true(gs.buy(_item("max_heart_4")))
	assert_eq(gs.max_hearts, 4)
	assert_eq(gs.hearts, 4, "новое сердечко сразу полное")
	assert_true(gs.buy(_item("max_heart_5")))
	assert_eq(gs.max_hearts, 5)
	assert_false(gs.can_buy(_item("refill_hearts")), "сердечки полные — нечего восстанавливать")
	gs.take_hit()
	assert_true(gs.can_buy(_item("refill_hearts")))
	assert_true(gs.buy(_item("refill_hearts")))
	assert_eq(gs.hearts, 5)
	assert_false(gs.can_buy(_item("refill_hearts")))

func test_mouth_capacity_chain() -> void:
	gs.add_yarn(20)
	assert_false(gs.can_buy(_item("mouth_5")))
	gs.buy(_item("mouth_4"))
	assert_eq(gs.mouth_capacity, 4)
	gs.buy(_item("mouth_5"))
	assert_eq(gs.mouth_capacity, 5)

func test_skins_buy_and_select() -> void:
	gs.add_yarn(12)
	watch_signals(gs)
	assert_false(gs.select_skin(&"black"), "не куплен")
	assert_true(gs.buy(_item("skin_black")))
	assert_eq(gs.skin, &"black", "купленный скин сразу надевается")
	assert_signal_emitted(gs, "skin_changed")
	assert_true(gs.select_skin(&"orange"))
	assert_eq(gs.owned_skins(), [&"orange", &"black"])
	assert_false(gs.can_buy(_item("skin_black")), "скин одноразовый")

func test_reset_clears_shop_state() -> void:
	gs.add_yarn(30)
	gs.buy(_item("speed"))
	gs.buy(_item("skin_black"))
	gs.reset()
	assert_eq(gs.yarn, 0)
	assert_eq(gs.upgrades.size(), 0)
	assert_eq(gs.skin, &"orange")
	assert_almost_eq(gs.speed_mult, 1.0, 0.001)
```

## `tests/unit/test_skins.gd`

```gdscript
extends GutTest

func test_catalog_has_four_skins() -> void:
	assert_eq(SkinCatalog.all().size(), 4)
	var black := SkinCatalog.get_by_id(&"black")
	assert_not_null(black)
	assert_eq(black.body.to_html(false), "394151")
	assert_eq(black.belly.to_html(false), "fcd3a1")

func test_apply_recolors_named_surfaces() -> void:
	var mi := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var box := BoxMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = mesh
	var body := StandardMaterial3D.new()
	body.resource_name = "sr_cat_orange"
	var other := StandardMaterial3D.new()
	other.resource_name = "sr_ink"
	mi.set_surface_override_material(0, body)
	mi.set_surface_override_material(1, other)
	add_child_autofree(mi)
	var n := CatSkin.apply(mi, SkinCatalog.get_by_id(&"black"))
	assert_eq(n, 1)
	assert_eq((mi.get_surface_override_material(0) as StandardMaterial3D).albedo_color.to_html(false), "394151")
	assert_eq((mi.get_surface_override_material(1) as StandardMaterial3D).albedo_color, Color.WHITE, "чужой материал не тронут")
```

## `tests/unit/test_smoke.gd`

```gdscript
extends GutTest

func test_godot_version_is_4_7() -> void:
	var v := Engine.get_version_info()
	assert_eq(v.major, 4)
	assert_eq(v.minor, 7)
```

## `tests/unit/test_sprinkler_cycle.gd`

```gdscript
extends GutTest
## Цикл дождевателя (спек этапа 2, раздел 3): 12 с стоит, из них последняя 1 с — предупреждение, 8 с работает.

func test_phases() -> void:
	assert_eq(Sprinkler.phase_at(0.0), &"off")
	assert_eq(Sprinkler.phase_at(10.9), &"off")
	assert_eq(Sprinkler.phase_at(11.5), &"warn")
	assert_eq(Sprinkler.phase_at(12.0), &"on")
	assert_eq(Sprinkler.phase_at(19.9), &"on")
	assert_eq(Sprinkler.phase_at(20.0), &"off", "цикл 20 с")
```

## `tests/unit/test_theme.gd`

```gdscript
extends GutTest

func test_project_theme_uses_nunito_and_rounded_panels() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), "res://assets/ui/theme.tres")
	var theme := load("res://assets/ui/theme.tres") as Theme
	assert_not_null(theme, "нет темы")
	if theme == null:
		return
	assert_not_null(theme.default_font, "шрифт по умолчанию задан")
	# Nunito — вариативный шрифт, без явного веса берётся ExtraLight 200: тонкий и плохо читается.
	var fv := theme.default_font as FontVariation
	assert_not_null(fv, "шрифт темы — FontVariation с заданным весом")
	if fv:
		assert_eq(fv.base_font.resource_path, "res://assets/fonts/Nunito.ttf")
		assert_gte(int(fv.variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght"), 0)), 600, "вес не тоньше SemiBold")
	assert_gte(theme.default_font_size, 22, "базовый кегль читается на видео")
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	assert_not_null(panel, "плашка PanelContainer — StyleBoxFlat")
	if panel == null:
		return
	assert_gt(panel.corner_radius_top_left, 8, "округлые углы")
	assert_gt(panel.shadow_size, 0, "мягкая тень")
	assert_eq(theme.get_color("font_color", "Label").to_html(false), "394151", "графитовый текст")

func test_window_scales_with_screen() -> void:
	# Retina: окно 1280×720 физических пикселей выходило вдвое меньше; интерфейс должен масштабироваться вместе с окном.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/mode")), DisplayServer.WINDOW_MODE_MAXIMIZED)

func test_ui_uses_only_glyphs_the_font_has() -> void:
	# Символов ♥ ♡ ◎ ✓ в Nunito нет: подстановка из системного шрифта выглядит чужой.
	var font := load("res://assets/fonts/Nunito.ttf") as FontFile
	for path in ["res://scripts/ui/hud.gd", "res://scripts/ui/shop_menu.gd", "res://scenes/ui/hud.tscn", "res://scenes/ui/shop_menu.tscn"]:
		var text := FileAccess.get_file_as_string(path)
		for ch in ["♥", "♡", "◎", "✓"]:
			assert_false(text.contains(ch), "%s содержит «%s», которого нет в шрифте" % [path, ch])
	assert_false(font.has_char("♥".unicode_at(0)), "проверка выше осмысленна: ♥ в шрифте действительно нет")
```

## `tests/unit/test_toon.gd`

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
	var outline := mi.material_overlay as ShaderMaterial
	assert_not_null(outline, "обводка — шейдерный hull")
	if outline == null:
		return
	assert_eq(outline.shader.resource_path, "res://assets/shaders/outline_fur.gdshader")
	assert_almost_eq(float(outline.get_shader_parameter("width")), 0.02, 0.0001)
	assert_almost_eq(float(outline.get_shader_parameter("jitter")), 0.0, 0.0001, "у пропсов и еды шерсти нет")
	assert_eq((outline.get_shader_parameter("color") as Color).to_html(false), Toon.OUTLINE_COLOR.to_html(false))
	assert_false(m.rim_enabled, "у не-персонажей rim выключен")

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

func test_outline_width_is_in_meters_under_scaled_parent() -> void:
	# Ревью: grow считается в пространстве модели, у скинового кота масштаб скелета 0,2.
	var parent := Node3D.new()
	parent.scale = Vector3.ONE * 0.2
	add_child_autofree(parent)
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	parent.add_child(mi)
	Toon.apply(mi, 0.02)
	assert_almost_eq(float((mi.material_overlay as ShaderMaterial).get_shader_parameter("width")), 0.1, 0.001)

func test_character_gets_rim_and_fur_jitter() -> void:
	var mi := _make_mesh()
	Toon.apply(mi, 0.006, true)
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_true(m.rim_enabled)
	assert_almost_eq(m.rim, 0.5, 0.01)
	assert_almost_eq(m.rim_tint, 0.6, 0.01)
	assert_almost_eq(float((mi.material_overlay as ShaderMaterial).get_shader_parameter("jitter")), Toon.OUTLINE_JITTER, 0.001)
```

## `tools/blender/build.py`

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
		# Ruling (ledger, pre-flight): в SPEC есть служебный ключ animations, check_asset его не принимает.
		errors = lib.check_asset(objs, max_tris=mod.SPEC["max_tris"], max_dim=mod.SPEC["max_dim"])
		if errors:
			failed.append(name)
			for e in errors:
				print(f"ОШИБКА {name}: {e}")
			continue
		path = os.path.join(OUT, f"{name}.glb")
		export.export_glb(path, objs, animations=mod.SPEC.get("animations", False))
		print(f"ОК {name} -> {os.path.relpath(path, ROOT)} ({sum(lib.tri_count(o) for o in objs if o.type == "MESH")} tri)")
	if failed:
		print("ПРОВАЛ:", ", ".join(failed))
		sys.exit(1)


if __name__ == "__main__":
	main()
```

## `tools/blender/cat.py`

```python
"""Готовит кота: канонический риг UniMate + клипы (idle/walk из Quaternius, остальные из UniMate),
палитра, масштаб 0,35 м, разворот мордой по -Z Godot, плюс наборы глаз (cat_eyes.py), пучки шерсти, усы и ошейник (cat_fluff.py), сглаживание subdivision."""
import math
import os

import bmesh
import bpy

import cat_eyes
import cat_fluff
import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLIPS_DIR = os.path.join(ROOT, "third_party", "unimate_clips")
CANONICAL = os.path.join(CLIPS_DIR, "cat_canonical.glb")
SOURCE_BLEND = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Cat.blend")
TARGET_LENGTH = 0.35      # метров, спек 2.1
MATERIAL_MAP = {"Grey": "cat_orange", "White": "cream", "Pink": "coral"}
SOURCE_ACTIONS = {"Idle": "idle", "Walking": "walk"}        # из Cat.blend
GENERATED_CLIPS = ["jump", "hide", "hit", "run"]             # из UniMate, файл <имя>.glb
IN_PLACE_CLIPS = {"run"}                                       # убрать перемещение корня: движет CharacterBody3D
ROOT_BONE = "Bone"
HEAD_SOURCE_BONE = "Bone.003"                                 # имя головы в Cat.blend


def _fcurves(action):
	out = []
	for layer in action.layers:
		for strip in layer.strips:
			for cb in strip.channelbags:
				out.extend((cb, fc) for fc in cb.fcurves)
	return out


def _bone_of(fc):
	return fc.data_path.split('"')[1] if 'pose.bones["' in fc.data_path else None


def load_canonical():
	bpy.ops.wm.read_homefile(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=CANONICAL)
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH" and o.parent is arm)
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)   # форма костей (Icosphere) от импортёра
	return arm, mesh


def _clean_action(action, arm, rename=None):
	"""Переименовывает кости в каналах и выкидывает каналы несуществующих костей."""
	names = {b.name for b in arm.data.bones}
	for cb, fc in _fcurves(action):
		bone = _bone_of(fc)
		if bone and rename and bone in rename:
			fc.data_path = fc.data_path.replace(f'pose.bones["{bone}"]', f'pose.bones["{rename[bone]}"]')
			bone = rename[bone]
		if bone and bone not in names:
			cb.fcurves.remove(fc)
	action.use_fake_user = True


def _strip_root_location(action):
	for cb, fc in _fcurves(action):
		if _bone_of(fc) == ROOT_BONE and fc.data_path.endswith("location"):
			cb.fcurves.remove(fc)


def add_source_actions(arm):
	with bpy.data.libraries.load(SOURCE_BLEND, link=False) as (src, dst):
		dst.actions = [a for a in src.actions if a in SOURCE_ACTIONS]
	for old, new in SOURCE_ACTIONS.items():
		act = bpy.data.actions[old]
		act.name = new
		_clean_action(act, arm, rename={HEAD_SOURCE_BONE: "head"})


def add_generated_clips(arm, mesh):
	for name in GENERATED_CLIPS:
		path = os.path.join(CLIPS_DIR, f"{name}.glb")
		if not os.path.exists(path):
			print(f"ПРЕДУПРЕЖДЕНИЕ: нет клипа {path}")
			continue
		before = set(bpy.data.actions)
		keep = set(bpy.data.objects)
		bpy.ops.import_scene.gltf(filepath=path)
		new_actions = [a for a in bpy.data.actions if a not in before]
		for o in list(bpy.data.objects):
			if o not in keep:
				bpy.data.objects.remove(o)
		if not new_actions:
			raise RuntimeError(f"в {path} нет анимации")
		act = new_actions[0]
		act.name = name
		_clean_action(act, arm)
		if name in IN_PLACE_CLIPS:
			_strip_root_location(act)
		for extra in new_actions[1:]:
			bpy.data.actions.remove(extra)


def recolor(mesh):
	for i, m in enumerate(mesh.data.materials):
		raw = (m.name if m else "").replace(palette.MATERIAL_PREFIX, "")
		key = MATERIAL_MAP.get(raw, raw if raw in palette.PALETTE else "cat_orange")
		mesh.data.materials[i] = palette.get_material(key)


def rescale(arm, mesh):
	bpy.context.view_layer.update()
	factor = TARGET_LENGTH / max(mesh.dimensions)
	arm.scale = (arm.scale.x * factor, arm.scale.y * factor, arm.scale.z * factor)


def smooth_body(mesh):
	"""Сваривает вершины (импортёр glTF режет меш по нормалям и UV, и subdivision разводил бы
	треугольники в мозаику), затем один уровень subdivision при экспорте (export_apply применяет
	модификаторы, кроме арматуры) и smooth-шейдинг."""
	bm = bmesh.new()
	bm.from_mesh(mesh.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)   # группы вершин (deform-слой) сохраняются
	bm.to_mesh(mesh.data)
	bm.free()
	mod = mesh.modifiers.new("Subdivision", "SUBSURF")
	mod.levels = 1
	mod.render_levels = 1
	mesh.modifiers.move(mesh.modifiers.find(mod.name), 0)   # до Armature
	for p in mesh.data.polygons:
		p.use_smooth = True


def build():
	arm, mesh = load_canonical()
	add_source_actions(arm)
	add_generated_clips(arm, mesh)
	arm.animation_data_create()
	arm.animation_data.action = None   # активный action экспортёр в режиме ACTIONS теряет
	for pb in arm.pose.bones:
		pb.rotation_mode = "QUATERNION"
	recolor(mesh)
	smooth_body(mesh)
	rig_utils.face_forward(arm)
	rescale(arm, mesh)
	eyes = cat_eyes.build_eyes(arm, mesh)
	fluff = cat_fluff.build_fluff(arm, mesh)
	arm.name = "CatRig"
	mesh.name = "cat"
	return [arm, mesh] + eyes + fluff
```

## `tools/blender/cat_eyes.py`

```python
"""Глаза кота: пять наборов мешей (обычные, испуг, довольный, оглушён, моргание) в глазницах, на кости головы.
В Godot одновременно виден один набор, переключает CatFace (спек 2.4). Координаты считаются
от bbox вершин головы, поэтому глаза всегда на морде, как бы ни был отмасштабирован риг."""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import lib

EYE_SETS = ("normal", "scared", "happy", "dizzy", "blink")
HEAD_GROUP = "head"
SPHERE = {"segments": 8, "rings": 6}   # 80 треугольников на сферу


def group_bbox(mesh, bone):
	"""Мировой bbox вершин, привязанных к кости bone весом > 0,5; при нехватке — порог 0,25,
	а если и так пусто — отрезок head/tail самой кости (у кончика хвоста и шеи вершин может не быть)."""
	bpy.context.view_layer.update()
	gi = mesh.vertex_groups[bone].index
	pts = []
	for threshold in (0.5, 0.25):
		pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices
		       if any(g.group == gi and g.weight > threshold for g in v.groups)]
		if pts:
			break
	if not pts:
		b = mesh.parent.data.bones[bone]
		pts = [mesh.parent.matrix_world @ b.head_local, mesh.parent.matrix_world @ b.tail_local]
	lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
	hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
	return lo, hi


def head_bbox(mesh):
	return group_bbox(mesh, HEAD_GROUP)


def _head_points(mesh):
	bpy.context.view_layer.update()
	gi = mesh.vertex_groups[HEAD_GROUP].index
	return [mesh.matrix_world @ v.co for v in mesh.data.vertices
	        if any(g.group == gi and g.weight > 0.5 for g in v.groups)]


def local_front(mesh, x, z, window=0.012):
	"""Передняя поверхность морды (max y) в XZ-окрестности точки: у глаз морда отступает от кончика носа."""
	pts = [p for p in _head_points(mesh) if abs(p.x - x) < window and abs(p.z - z) < window]
	return max(p.y for p in pts) if pts else max(p.y for p in _head_points(mesh))


def local_halfwidth(mesh, y, z, window=0.012):
	"""Полуширина головы (max |x|) на высоте z в окрестности глубины y."""
	pts = [p for p in _head_points(mesh) if abs(p.y - y) < window and abs(p.z - z) < window]
	return max(abs(p.x) for p in pts) if pts else max(abs(p.x) for p in _head_points(mesh))


WHITE_R = 0.013
SINK = 0.5   # доля радиуса белка внутри головы


def eye_centers(lo, hi, mesh=None):
	"""Центры левого и правого глаза: верхняя треть морды; глубина и ширина — по локальной поверхности
	морды у глаза (ревью плана 5: относительно кончика носа белки выпирали сбоку и вперёд)."""
	z = lo.z + (hi.z - lo.z) * 0.68
	x = (hi.x - lo.x) * 0.22
	y = hi.y - 0.012
	if mesh is not None:
		front = local_front(mesh, x, z)
		half = local_halfwidth(mesh, front - 0.006, z)
		x = max(0.008, half - WHITE_R * 0.95)                       # наружный край белка ≈ на профиле головы
		y = front - WHITE_R * 0.55 * (1.0 - SINK) + 0.0005          # перед белка = front + 0,5 мм; зрачок и блик ещё на 3 мм
	return Vector((-x, y, z)), Vector((x, y, z))


def _line(name, center, angle_deg, length, radius, material):
	"""Штрих в плоскости лица XZ: цилиндр вдоль X, повёрнутый на angle вокруг Y (оси взгляда).
	Положительный угол опускает +X-конец штриха."""
	c = lib.cylinder(name, radius=radius, depth=length, segments=6, material=material)
	c.rotation_euler = (0.0, math.pi / 2 + math.radians(angle_deg), 0.0)
	c.location = center
	return c


def _eyeball(p, c, white_r, iris_r, pupil_r, pop):
	"""Глаз в глазнице: белок-эллипсоид утоплен в голову, радужка/зрачок/блик на его передней поверхности.
	pop — насколько белок выдвинут вперёд (0 = центр на 40 % радиуса внутри головы)."""
	fwd = Vector((0.0, 1.0, 0.0))
	w = lib.sphere(p + "_w", white_r, material="eye_white", **SPHERE)
	w.scale = (1.0, 0.55, 1.0)
	w.location = c - fwd * (white_r * 0.55 * SINK - pop)   # центр белка утоплен в голову на SINK радиуса (по сплюснутой оси)
	front = w.location + fwd * (white_r * 0.55)
	iris = lib.sphere(p + "_i", iris_r, material="eye_green", **SPHERE)
	iris.scale = (1.0, 0.35, 1.0)
	iris.location = front - fwd * (iris_r * 0.35 * 0.6)
	pupil = lib.sphere(p + "_k", pupil_r, material="ink", **SPHERE)
	pupil.scale = (1.0, 0.3, 1.0)
	pupil.location = iris.location + fwd * 0.0015
	glint = lib.sphere(p + "_g", pupil_r * 0.45, material="eye_white", segments=6, rings=4)
	glint.location = pupil.location + fwd * 0.0015 + Vector((-pupil_r * 0.4, 0.0, pupil_r * 0.45))
	return [w, iris, pupil, glint]


def _parts(kind, side, c):
	p = f"eye_{kind}_{side}"
	fwd = Vector((0.0, 1.0, 0.0))
	if kind == "normal":
		return _eyeball(p, c, WHITE_R, 0.008, 0.0042, 0.0)
	if kind == "scared":
		return _eyeball(p, c, WHITE_R + 0.002, 0.0055, 0.0023, 0.003)   # белок выпучен на 3 мм, зрачок точкой
	if kind == "happy":   # «^»: левый штрих поднимается к центру, правый — от центра вниз
		a = _line(p + "_a", c + Vector((-0.006, 0.0045, -0.002)), -35, 0.016, 0.0025, "ink")
		b = _line(p + "_b", c + Vector((0.006, 0.0045, -0.002)), 35, 0.016, 0.0025, "ink")
		return [a, b]
	if kind == "blink":   # закрытый глаз: одна горизонтальная ресница
		return [_line(p + "_a", c + fwd * 0.0045, 0, 0.024, 0.0025, "ink")]   # у поверхности глаза, не перед мордой
	a = _line(p + "_a", c + fwd * 0.0045, 45, 0.026, 0.0025, "ink")    # dizzy: «×»
	b = _line(p + "_b", c + fwd * 0.0045, -45, 0.026, 0.0025, "ink")
	return [a, b]


def _join(name, objs):
	"""Сливает объекты в один меш в мировых координатах, сохраняя материалы по граням."""
	bpy.context.view_layer.update()
	bm = bmesh.new()
	mats = []
	for o in objs:
		tmp = o.data.copy()
		tmp.transform(o.matrix_world)
		mat = o.data.materials[0]
		if mat not in mats:
			mats.append(mat)
		for poly in tmp.polygons:
			poly.material_index = mats.index(mat)
		bm.from_mesh(tmp)
		bpy.data.meshes.remove(tmp)
		bpy.data.objects.remove(o)
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	for m in mats:
		mesh.materials.append(m)
	for poly in mesh.polygons:
		poly.use_smooth = True
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	return obj


def _attach(obj, arm, bone=HEAD_GROUP):
	"""Переводит меш в пространство арматуры и скинит его к кости bone весом 1,0."""
	bpy.context.view_layer.update()
	obj.data.transform(arm.matrix_world.inverted() @ obj.matrix_world)
	obj.matrix_world = Matrix.Identity(4)
	obj.parent = arm
	obj.matrix_parent_inverse = Matrix.Identity(4)
	vg = obj.vertex_groups.new(name=bone)
	vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
	mod = obj.modifiers.new("Armature", "ARMATURE")
	mod.object = arm
	bpy.context.view_layer.update()


def build_eyes(arm, mesh):
	"""Четыре объекта eyes_<набор>, дети арматуры. Звать после face_forward и rescale."""
	lo, hi = head_bbox(mesh)
	left, right = eye_centers(lo, hi, mesh)
	out = []
	for kind in EYE_SETS:
		parts = _parts(kind, "l", left) + _parts(kind, "r", right)
		obj = _join(f"eyes_{kind}", parts)
		_attach(obj, arm)
		out.append(obj)
	return out   # веки-козырьки пробовали: при утопленных глазах читаются как брови, убраны (план 5)
```

## `tools/blender/cat_fluff.py`

```python
"""Пучки шерсти, усы и ошейник кота (спек 2.8): отдельные меши, скинятся к ближайшей кости весом 1,0.
Координаты считаются от bbox вершин соответствующей кости, как у глаз."""
import math

import bpy
from mathutils import Vector

import cat_eyes
import lib

SPHERE = {"segments": 8, "rings": 6}
CREAM = "cream"


def _oriented(obj, direction):
	"""Поворачивает объект так, чтобы его ось Z (ось цилиндра/конуса) смотрела вдоль direction."""
	obj.rotation_mode = "QUATERNION"
	obj.rotation_quaternion = Vector(direction).normalized().to_track_quat("Z", "Y")


def _cheeks(lo, hi):
	parts = []
	for side in (-1.0, 1.0):
		edge = hi.x if side > 0 else lo.x
		base = Vector((edge * 0.92, hi.y - 0.03, lo.z + 0.35 * (hi.z - lo.z)))
		for i, tilt in enumerate((-0.35, 0.0, 0.35)):
			c = lib.cone(f"cheek_{'r' if side > 0 else 'l'}{i}", radius=0.005, depth=0.014, segments=6, material=CREAM)
			d = Vector((side * 0.8, -1.4, -0.3 + tilt))   # назад и чуть вниз: пух на щеке, а не шип вперёд
			_oriented(c, d)
			c.location = base + d.normalized() * 0.004 + Vector((0.0, -0.004, tilt * 0.012))
			parts.append(c)
	return parts


def _chest(mesh):
	lo, hi = cat_eyes.group_bbox(mesh, "Bone.001")
	s = lib.sphere("chest", 0.028, material=CREAM, **SPHERE)
	s.scale = (1.0, 0.6, 0.8)
	s.location = Vector((0.0, hi.y - 0.012, lo.z + 0.25 * (hi.z - lo.z)))
	return [s]


def _tail_tip(mesh):
	lo, hi = cat_eyes.group_bbox(mesh, "Bone.007")
	s = lib.sphere("tail_tip", 0.018, material=CREAM, **SPHERE)
	s.location = (lo + hi) / 2.0
	return [s]


def _whiskers(lo, hi):
	parts = []
	w = hi.x - lo.x
	for side in (-1.0, 1.0):
		origin = Vector((side * w * 0.3, hi.y - 0.012, lo.z + 0.3 * (hi.z - lo.z)))
		for i, k in enumerate((0.15, 0.0, -0.15)):
			d = Vector((side, 0.3, k)).normalized()
			c = lib.cylinder(f"whisker_{'r' if side > 0 else 'l'}{i}", radius=0.0008, depth=0.035, segments=4, material="eye_white")
			_oriented(c, d)
			c.location = origin + d * 0.0175
			parts.append(c)
	return parts


def _collar(arm, mesh):
	lo, hi = cat_eyes.group_bbox(mesh, "Bone.002")
	pb = arm.pose.bones["Bone.002"]
	bpy.context.view_layer.update()
	head = arm.matrix_world @ pb.head
	tail = arm.matrix_world @ pb.tail
	axis = (tail - head).normalized()
	major = (hi.x - lo.x) / 2.0 * 1.15
	ring = lib.torus("collar_ring", major=major, minor=0.006, material="coral")
	_oriented(ring, axis)
	ring.location = tail - axis * 0.014   # кость шеи начинается у плеч: ошейник — у её конца, под головой
	tag = lib.cylinder("collar_tag", radius=0.012, depth=0.004, segments=10, material="rarity_legendary")
	tag.rotation_euler = (math.pi / 2, 0.0, 0.0)   # плоский диск лицом вперёд
	tag.location = ring.location + Vector((0.0, 0.004, -major))
	return [ring, tag]


def build_fluff(arm, mesh):
	"""Пять объектов, дети арматуры. Звать после face_forward и rescale."""
	lo, hi = cat_eyes.head_bbox(mesh)
	out = []
	for name, parts, bone in (
		("fluff_cheeks", _cheeks(lo, hi), "head"),
		("fluff_chest", _chest(mesh), "Bone.001"),
		("fluff_tail", _tail_tip(mesh), "Bone.007"),
		("whiskers", _whiskers(lo, hi), "head"),
		("collar", _collar(arm, mesh), "Bone.002"),
	):
		obj = cat_eyes._join(name, parts)
		cat_eyes._attach(obj, arm, bone)
		out.append(obj)
	return out
```

## `tools/blender/cat_quaternius_export.py`

```python
"""Промежуточный экспорт кота прямо из Quaternius Cat.blend (без UniMate): масштаб 0,35 м,
палитра, кость head, клипы idle/walk. Нужен один раз как вход для rig_preprocess UniMate
(docs/replay/02-procedure.md, шаг 5.3). Итоговый кот собирается cat.py.
Запуск: blender -b --python-exit-code 1 --python tools/blender/cat_quaternius_export.py -- out.glb"""
import os

import os as _os
import sys as _sys
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))

import bpy  # noqa: E402

import palette  # noqa: E402
import rig_inspect  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "third_party", "quaternius_animal_pack_v2", "Cat.blend")
TARGET_LENGTH = 0.35      # метров, спек 2.1 и карта (25–30 см тело + хвост)
# Исходник смотрит по +X Blender; поворот на +90° вокруг Z даёт +Y Blender = -Z Godot (вперёд).
FACING_FIX_DEG = 90
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


if __name__ == "__main__":
	import sys

	import export

	out = sys.argv[sys.argv.index("--") + 1]
	objs = build()
	export.export_glb(out, objs, animations=True)
	print("ОК", out)
```

## `tools/blender/crab.py`

```python
"""Краб из CC0 methodical pixel: корпус кирпичный, клешни коралловые; ширина 0,4 м; клипы idle, walk (план 14)."""
import os

import bpy
from mathutils import Vector

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLEND = os.path.join(ROOT, "third_party", "crab_methodicalpixel", "crab.blend")
ACTIONS = ("idle", "walk")
TARGET_WIDTH = 0.4


def build():
	bpy.ops.wm.open_mainfile(filepath=BLEND)
	arm = bpy.data.objects["rig crab"]
	mesh = bpy.data.objects["crab"]
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)
	for a in list(bpy.data.actions):
		if a.name in ACTIONS:
			rig_utils.clean_action(a, arm)
		else:
			bpy.data.actions.remove(a)
	bpy.context.view_layer.update()
	m = mesh.matrix_world
	ys = [(m @ v.co).y for v in mesh.data.vertices]
	front = min(ys) + (max(ys) - min(ys)) * 0.3
	mesh.data.materials.clear()
	for key in ("brick", "coral", "ink"):
		mesh.data.materials.append(palette.get_material(key))
	for p in mesh.data.polygons:
		c = m @ p.center
		p.material_index = 1 if c.y < front else 0   # клешни спереди (−Y) коралловые
	arm.animation_data_create()
	arm.animation_data.action = None
	rig_utils.face_forward(arm, root_bone="body", head_bone="left arm 1.2")   # передом — клешни
	bpy.context.view_layer.update()
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	width = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(2))
	k = TARGET_WIDTH / width
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = "CrabRig"
	mesh.name = "crab"
	return [arm, mesh]
```

## `tools/blender/dog.py`

```python
"""Собака из Quaternius Dog.blend: рыжая с белой грудкой, 0,55 м, клипы idle/walk и процедурный sleep, кость head."""
import os

import bpy
from mathutils import Matrix

import dog_sleep
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
	# Запекаем поворот меша и обратную матрицу родителя в вершины: меш оказывается в пространстве
	# арматуры с единичной матрицей (как у кота), иначе экспортёр glTF теряет масштаб арматуры.
	mesh.data.transform(mesh.matrix_parent_inverse @ mesh.matrix_basis)
	mesh.matrix_parent_inverse = Matrix.Identity(4)
	mesh.matrix_basis = Matrix.Identity(4)
	# Арматура в Dog.blend имеет масштаб 1,215 и смещение; сбрасываем её трансформацию в единичную
	# (кости и меш остаются согласованы в пространстве арматуры), как у Cat.blend.
	arm.matrix_world = Matrix.Identity(4)
	bpy.context.view_layer.update()
	head = rig_inspect.find_head_bone(arm, mesh)
	arm.data.bones[head].name = "head"
	for old, new in ACTION_MAP.items():
		act = bpy.data.actions[old]
		act.name = new
		rig_utils.clean_action(act, arm)
	dog_sleep.make_sleep_action(arm)
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

## `tools/blender/dog_sleep.py`

```python
"""Поза «спит» для собаки: процедурный клип. UniMate не дал позу лёжа
(docs/superpowers/notes/2026-10-07-unimate-attempt.md), поэтому поза задана числами:
корпус опущен на землю, лапы укорочены и их цели IK подняты, голова опущена к лапам;
дыхание — лёгкий подъём корпуса в середине клипа. Всё считается в пространстве арматуры (Z вверх)."""
import bpy
from mathutils import Quaternion, Vector

ROOT_BONE = "Bone"
HEAD_BONE = "head"
LEG_CHAINS = (("Bone.014", "Bone.015", "Bone.016"), ("Bone.017", "Bone.018", "Bone.019"),
              ("Bone.008", "Bone.009", "Bone.010"), ("Bone.011", "Bone.012", "Bone.013"))
IK_TARGETS = ("IKFrontRight", "IKFrontLeft", "IKBackLeft", "IKBackRight")
FRAMES = 48            # 2 с при 24 к/с
DROP_FRACTION = 0.62   # какую долю высоты корпуса над лапами убрать
LEG_SCALE = 0.45       # лапы вдоль своей оси
HEAD_TILT = 0.75       # рад, голова к лапам
BREATH = 0.10          # доля drop, на которую корпус приподнимается на вдохе


def reset_pose(arm):
	for pb in arm.pose.bones:
		pb.location = (0.0, 0.0, 0.0)
		pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
		pb.scale = (1.0, 1.0, 1.0)
	bpy.context.view_layer.update()


def _local_offset(pb, armature_vec):
	"""Вектор из пространства арматуры в локальные оси кости (location позы задаётся в них)."""
	return pb.bone.matrix_local.to_3x3().inverted() @ armature_vec


def apply_pose(arm, breath=0.0):
	"""Ставит позу «лежит». breath 0..1 — доля вдоха (корпус чуть выше)."""
	reset_pose(arm)
	root = arm.pose.bones[ROOT_BONE]
	feet_z = min(arm.pose.bones[chain[-1]].head.z for chain in LEG_CHAINS)
	drop = (root.head.z - feet_z) * DROP_FRACTION * (1.0 - BREATH * breath)
	root.location = _local_offset(root, Vector((0.0, 0.0, -drop)))
	for chain in LEG_CHAINS:
		for name in chain:
			arm.pose.bones[name].scale = (1.0, LEG_SCALE, 1.0)
	for name in IK_TARGETS:
		if name in arm.pose.bones:
			pb = arm.pose.bones[name]
			pb.location = _local_offset(pb, Vector((0.0, 0.0, drop * 0.25)))   # иначе IK тянет укороченную лапу к земле
	head = arm.pose.bones[HEAD_BONE]
	head.rotation_mode = "QUATERNION"
	best = None
	for sign in (1.0, -1.0):   # знак выбираем по результату: морда должна уйти вниз
		head.rotation_quaternion = Quaternion((1.0, 0.0, 0.0), sign * HEAD_TILT)
		bpy.context.view_layer.update()
		if best is None or head.tail.z < best[0]:
			best = (head.tail.z, sign)
	head.rotation_quaternion = Quaternion((1.0, 0.0, 0.0), best[1] * HEAD_TILT)
	bpy.context.view_layer.update()


def make_sleep_action(arm, name="sleep"):
	"""Клип sleep: кадры 1 и FRAMES — поза лёжа, середина — вдох. После записи поза сбрасывается,
	иначе незаписанные в idle/walk каналы унесут эту позу в другие клипы при экспорте."""
	action = bpy.data.actions.new(name)
	action.use_fake_user = True
	arm.animation_data_create()
	keyed = [ROOT_BONE, HEAD_BONE] + [b for chain in LEG_CHAINS for b in chain] + [t for t in IK_TARGETS if t in arm.pose.bones]
	for frame, breath in ((1, 0.0), (FRAMES // 2, 1.0), (FRAMES, 0.0)):
		# Поза ставится при снятом action: иначе каждый view_layer.update() внутри apply_pose
		# перезаписывает кости значениями уже записанных кадров, и клип выходит статичным.
		arm.animation_data.action = None
		apply_pose(arm, breath)
		arm.animation_data.action = action
		for bname in keyed:   # между назначением action и вставкой ключей — никаких update()
			pb = arm.pose.bones[bname]
			pb.keyframe_insert("location", frame=frame)
			pb.keyframe_insert("rotation_quaternion", frame=frame)
			pb.keyframe_insert("scale", frame=frame)
	arm.animation_data.action = None
	reset_pose(arm)
	return action
```

## `tools/blender/export.py`

```python
"""Экспорт glTF (.glb) по конвенциям проекта: 1 ед = 1 м, +Y вверх."""
import os

import bpy


def export_glb(path: str, objects, animations: bool = False) -> None:
	os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
	# Сбрасываем выделение напрямую: в открытом .blend могут быть выделены посторонние объекты.
	for o in bpy.context.view_layer.objects:
		o.select_set(False)
	for o in objects:
		o.hide_set(False)
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

## `tools/blender/gen/__init__.py`

```python

```

## `tools/blender/gen/arch.py`

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

## `tools/blender/gen/bag.py`

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

## `tools/blender/gen/barrel.py`

```python
"""Бочка (порт): r 0,35, высота 0,7, обручи. На набережной — укрытие, в воде — качающаяся опора (Floater)."""
import lib

SPEC = {"max_tris": 900, "max_dim": 0.8}


def build():
	body = lib.cylinder("barrel", radius=0.35, depth=0.7, segments=12, material="brick")
	body.location.z = 0.35
	parts = [body]
	for i, z in enumerate((0.12, 0.58)):
		h = lib.cylinder(f"barrel_hoop{i}", radius=0.365, depth=0.05, segments=12, material="ink")
		h.location.z = z
		parts.append(h)
	lid = lib.cylinder("barrel_lid", radius=0.3, depth=0.02, segments=12, material="sand")
	lid.location.z = 0.71
	parts.append(lid)
	return lib.group(parts)
```

## `tools/blender/gen/bench.py`

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

## `tools/blender/gen/bin.py`

```python
"""Мусорный бак 0,7×0,8×1,1 м: корпус + крышка + 2 колеса."""
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

## `tools/blender/gen/boat.py`

```python
"""Лодка у причала (порт): корпус 1,6×4,2 м, палуба на 0,45 м над ватерлинией (origin), нос-клин, банка. Качается (Floater)."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 5.2}


def build():
	hull = lib.rounded_box("boat", (1.6, 4.2, 0.75), bevel=0.06, material="brick")
	hull.location.z = 0.075
	deck = lib.rounded_box("boat_deck", (1.4, 4.0, 0.06), bevel=0.01, segments=1, material="sand")
	deck.location.z = 0.45
	bow = lib.wedge("boat_bow", width=1.6, length=0.8, height=0.75, material="brick")
	bow.location = (0, 2.1, -0.3)
	seat = lib.rounded_box("boat_seat", (1.4, 0.3, 0.08), bevel=0.01, segments=1, material="cream")
	seat.location = (0, -0.8, 0.62)
	rim = lib.rounded_box("boat_rim", (1.7, 4.3, 0.06), bevel=0.01, segments=1, material="cream")
	rim.location.z = 0.48
	return lib.group([hull, deck, bow, seat, rim])
```

## `tools/blender/gen/boat_upturned.py`

```python
"""Перевёрнутая лодка на пляже (укрытие «под лодкой»): днище сверху, борта до песка, концы открыты."""
import lib

SPEC = {"max_tris": 1200, "max_dim": 4.4}


def build():
	top = lib.rounded_box("boat_upturned", (1.6, 4.2, 0.12), bevel=0.04, material="brick")
	top.location.z = 0.6
	keel = lib.rounded_box("boat_upturned_keel", (0.12, 4.0, 0.1), bevel=0.01, segments=1, material="cream")
	keel.location.z = 0.7
	parts = [top, keel]
	for side, x in (("l", -0.74), ("r", 0.74)):
		s = lib.rounded_box(f"boat_upturned_side_{side}", (0.12, 4.2, 0.6), bevel=0.02, segments=1, material="brick")
		s.location = (x, 0, 0.3)
		parts.append(s)
	return lib.group(parts)
```

## `tools/blender/gen/bollard.py`

```python
"""Швартовая тумба причала."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.5}


def build():
	post = lib.cylinder("bollard", radius=0.15, depth=0.45, segments=10, material="ink")
	post.location.z = 0.225
	cap = lib.cylinder("bollard_cap", radius=0.2, depth=0.08, segments=10, material="ink")
	cap.location.z = 0.47
	return lib.group([post, cap])
```

## `tools/blender/gen/box.py`

```python
"""Картонная коробка 0,45×0,35×0,3 м (укрытие и пропс двора)."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.6}


def build():
	body = lib.rounded_box("box", (0.45, 0.35, 0.30), bevel=0.015, segments=2, material="sand")
	body.location.z = 0.15
	return [body]
```

## `tools/blender/gen/buoy.py`

```python
"""Буёк в море: шар с полосой."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.7}


def build():
	ball = lib.sphere("buoy", radius=0.3, material="coral")
	ball.location.z = 0.1
	band = lib.cylinder("buoy_band", radius=0.31, depth=0.1, segments=12, material="cream")
	band.location.z = 0.1
	return lib.group([ball, band])
```

## `tools/blender/gen/burrow.py`

```python
"""Норка краба (план 14): песчаное кольцо с тёмной серединой."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.6}


def build():
	ring = lib.torus("burrow", major=0.22, minor=0.06, material="sand")
	ring.location.z = 0.02
	hole = lib.cylinder("burrow_hole", radius=0.18, depth=0.02, segments=10, material="ink")
	hole.location.z = 0.005
	return lib.group([ring, hole])
```

## `tools/blender/gen/bush.py`

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

## `tools/blender/gen/cafe_sign.py`

```python
"""Вывеска кафе: две стойки и коралловая доска с кремовой рамкой."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.0}


def build():
	board = lib.rounded_box("cafe_sign", (2.6, 0.12, 0.8), bevel=0.03, segments=1, material="coral")
	board.location.z = 2.2
	frame = lib.rounded_box("cafe_sign_frame", (2.8, 0.08, 1.0), bevel=0.03, segments=1, material="cream")
	frame.location = (0, 0.04, 2.2)
	parts = [board, frame]
	for i, x in enumerate((-1.2, 1.2)):
		post = lib.cylinder(f"cafe_sign_post{i}", radius=0.05, depth=1.8, material="ink", segments=8)
		post.location = (x, 0, 0.9)
		parts.append(post)
	return lib.group(parts)
```

## `tools/blender/gen/cafe_table.py`

```python
"""Круглый стол кафе: столешница r 0,45 на высоте 0,75, ножка, основание."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.0}


def build():
	top = lib.cylinder("cafe_table", radius=0.45, depth=0.04, material="cream", segments=18)
	top.location.z = 0.73
	pole = lib.cylinder("cafe_table_pole", radius=0.04, depth=0.7, material="ink", segments=8)
	pole.location.z = 0.36
	base = lib.cylinder("cafe_table_base", radius=0.25, depth=0.03, material="ink", segments=12)
	base.location.z = 0.015
	return lib.group([top, pole, base])
```

## `tools/blender/gen/car.py`

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

## `tools/blender/gen/cat.py`

```python
"""Генератор кота: оборачивает cat.py для build.py."""
import cat

SPEC = {"max_tris": 8000, "max_dim": 0.6, "animations": True}   # subdivision ×6 на триангулированном меше, спек 2.8 с отклонением


def build():
	return cat.build()
```

## `tools/blender/gen/chair.py`

```python
"""Стул кафе: сиденье 0,45 м, спинка, четыре ножки."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.9}


def build():
	seat = lib.rounded_box("chair", (0.42, 0.42, 0.04), bevel=0.01, segments=1, material="sky")
	seat.location.z = 0.45
	back = lib.rounded_box("chair_back", (0.42, 0.04, 0.4), bevel=0.01, segments=1, material="sky")
	back.location = (0, -0.19, 0.67)
	parts = [seat, back]
	for i, (x, y) in enumerate(((-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18), (0.18, 0.18))):
		leg = lib.cylinder(f"chair_leg{i}", radius=0.02, depth=0.45, material="ink", segments=6)
		leg.location = (x, y, 0.225)
		parts.append(leg)
	return lib.group(parts)
```

## `tools/blender/gen/crab.py`

```python
"""Генератор краба (CC0 methodical pixel — crab.py)."""
import crab

SPEC = {"max_tris": 1500, "max_dim": 0.45, "animations": True}


def build():
	return crab.build()
```

## `tools/blender/gen/cyclist.py`

```python
"""Велосипедист: два колеса, рама, седок с шлемом. Длина 1,8 м, перёд по +Y Blender (= -Z Godot, вперёд в игре)."""
import lib

SPEC = {"max_tris": 1800, "max_dim": 2.0}   # два тора колёс по 256 + две сферы


def build():
	frame = lib.rounded_box("cyclist", (0.08, 0.9, 0.08), bevel=0.02, material="brick")
	frame.location.z = 0.55
	parts = [frame]
	for name, y in (("cyclist_wheel_f", 0.6), ("cyclist_wheel_b", -0.6)):
		wheel = lib.torus(name, major=0.3, minor=0.04, material="ink")
		wheel.rotation_euler = (0, 1.5708, 0)
		wheel.location = (0, y, 0.34)
		parts.append(wheel)
	post = lib.cylinder("cyclist_post", radius=0.03, depth=0.4, material="brick")
	post.location = (0, -0.2, 0.75)
	parts.append(post)
	body = lib.rounded_box("cyclist_body", (0.32, 0.45, 0.5), bevel=0.06, material="sky")
	body.location = (0, -0.05, 1.2)
	body.rotation_euler = (-0.5, 0, 0)
	parts.append(body)
	head = lib.sphere("cyclist_head", radius=0.14, material="cream")
	head.location = (0, 0.2, 1.62)
	parts.append(head)
	helmet = lib.sphere("cyclist_helmet", radius=0.155, material="coral")
	helmet.scale = (1, 1, 0.6)
	helmet.location = (0, 0.2, 1.7)
	parts.append(helmet)
	for name, x in (("cyclist_leg_l", 0.12), ("cyclist_leg_r", -0.12)):
		leg = lib.rounded_box(name, (0.1, 0.12, 0.5), bevel=0.03, material="asphalt")
		leg.location = (x, 0.05, 0.75)
		parts.append(leg)
	return lib.group(parts)
```

## `tools/blender/gen/deckchair.py`

```python
"""Шезлонг на пляже: рама и полосатая ткань под наклоном."""
import math

import lib

SPEC = {"max_tris": 600, "max_dim": 1.7}


def build():
	seat = lib.rounded_box("deckchair", (0.6, 1.0, 0.05), bevel=0.01, segments=1, material="sea_light")
	seat.location = (0, -0.3, 0.3)
	back = lib.rounded_box("deckchair_back", (0.6, 0.8, 0.05), bevel=0.01, segments=1, material="cream")
	back.rotation_euler = (math.radians(-55), 0, 0)
	back.location = (0, 0.45, 0.55)
	parts = [seat, back]
	for i, (x, y) in enumerate(((-0.28, -0.75), (0.28, -0.75), (-0.28, 0.15), (0.28, 0.15))):
		leg = lib.rounded_box(f"deckchair_leg{i}", (0.04, 0.04, 0.3), bevel=0.0, segments=1, material="sand")
		leg.location = (x, y, 0.15)
		parts.append(leg)
	return lib.group(parts)
```

## `tools/blender/gen/dog.py`

```python
"""Генератор собаки: оборачивает dog.py для build.py."""
import dog

SPEC = {"max_tris": 2500, "max_dim": 0.8, "animations": True}


def build():
	return dog.build()
```

## `tools/blender/gen/door.py`

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

## `tools/blender/gen/fence.py`

```python
"""Забор 2 м: две перекладины и 5 столбиков."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.1}


def build():
	rail = lib.rounded_box("fence", (2.0, 0.05, 0.08), bevel=0.01, segments=1, material="leaf")
	rail.location.z = 0.9
	rail2 = lib.rounded_box("fence_rail2", (2.0, 0.05, 0.08), bevel=0.01, segments=1, material="leaf")
	rail2.location.z = 0.45
	parts = [rail, rail2]
	for i in range(5):
		post = lib.rounded_box(f"fence_post{i}", (0.08, 0.08, 1.1), bevel=0.0, material="leaf")
		post.location = (-1.0 + i * 0.5, 0, 0.55)
		parts.append(post)
	return lib.group(parts)
```

## `tools/blender/gen/flowerbed.py`

```python
"""Клумба: круглый бортик 1,4 м с землёй и цветами (шарики коралловые и золотые на стеблях)."""
import math

import lib

SPEC = {"max_tris": 800, "max_dim": 1.5}


def build():
	rim = lib.cylinder("flowerbed", radius=0.7, depth=0.25, segments=16, material="sand")
	rim.location.z = 0.125
	soil = lib.cylinder("flowerbed_soil", radius=0.62, depth=0.04, segments=16, material="brick")
	soil.location.z = 0.25
	parts = [rim, soil]
	for i in range(8):
		a = i * 2 * math.pi / 8
		r = 0.38 if i % 2 else 0.2
		head = lib.sphere(f"flowerbed_f{i}", 0.07, material="coral" if i % 2 else "rarity_legendary", segments=6, rings=4)
		head.location = (math.cos(a) * r, math.sin(a) * r, 0.42)
		parts.append(head)
	leafy = lib.sphere("flowerbed_leaves", 0.5, material="leaf", segments=8, rings=5)
	leafy.scale = (1, 1, 0.35)
	leafy.location.z = 0.3
	parts.append(leafy)
	return lib.group(parts)
```

## `tools/blender/gen/food_bagel.py`

```python
"""Бублик: тор."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	b = lib.torus("food_bagel", major=0.07, minor=0.035, material="cat_orange")
	b.location.z = 0.035
	return [b]
```

## `tools/blender/gen/food_cookie.py`

```python
"""Печенье: диск с тремя «шоколадными» точками."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	disc = lib.cylinder("food_cookie", radius=0.07, depth=0.02, material="sand")
	disc.location.z = 0.01
	parts = [disc]
	for i, (x, y) in enumerate(((0.02, 0.02), (-0.03, 0.01), (0.0, -0.03))):
		dot = lib.sphere(f"food_cookie_dot{i}", radius=0.012, material="ink", segments=6, rings=4)
		dot.location = (x, y, 0.022)
		parts.append(dot)
	return lib.group(parts)
```

## `tools/blender/gen/food_corn.py`

```python
"""Кукуруза: золотой початок и два листа."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cob = lib.cylinder("food_corn", radius=0.04, depth=0.2, segments=10, material="rarity_legendary")
	cob.rotation_euler = (0, math.pi / 2, 0)
	cob.location.z = 0.04
	parts = [cob]
	for i, s in enumerate((-1, 1)):
		leaf = lib.cone(f"food_corn_leaf{i}", radius=0.03, depth=0.16, segments=5, material="leaf")
		leaf.rotation_euler = (0, math.pi / 2 + 0.3 * s, 0.4 * s)
		leaf.location = (-0.11, 0.02 * s, 0.05)
		parts.append(leaf)
	return lib.group(parts)
```

## `tools/blender/gen/food_cotton_candy.py`

```python
"""Сахарная вата: розово-сиреневое облачко на палочке."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	stick = lib.cylinder("food_cotton_candy", radius=0.008, depth=0.12, segments=6, material="cream")
	stick.location.z = 0.06
	parts = [stick]
	for i, (x, y, z, r, m) in enumerate(((0, 0, 0.17, 0.065, "coral"), (0.04, 0.02, 0.2, 0.045, "lilac"), (-0.035, -0.015, 0.19, 0.05, "lilac"))):
		s = lib.sphere(f"food_cotton_candy_c{i}", r, material=m, segments=8, rings=6)
		s.location = (x, y, z)
		parts.append(s)
	return lib.group(parts)
```

## `tools/blender/gen/food_croissant.py`

```python
"""Круассан: три сегмента дугой."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	parts = []
	for i, (ang, size) in enumerate(((-0.6, 0.05), (0.0, 0.07), (0.6, 0.05))):
		seg = lib.rounded_box("food_croissant" if i == 1 else f"food_croissant_{i}",
		                      (0.07, size, size), bevel=0.02, segments=2, material="cat_orange")
		seg.location = (math.sin(ang) * 0.07, math.cos(ang) * 0.02 - 0.02, size / 2)
		seg.rotation_euler = (0, 0, -ang)
		parts.append(seg)
	return lib.group([parts[1], parts[0], parts[2]])
```

## `tools/blender/gen/food_cupcake.py`

```python
"""Капкейк: голубая формочка, розовый крем и вишенка."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cup = lib.cylinder("food_cupcake", radius=0.06, depth=0.07, segments=10, material="sky")
	cup.location.z = 0.035
	cream = lib.sphere("food_cupcake_cream", 0.065, material="coral", segments=10, rings=6)
	cream.scale = (1, 1, 0.75)
	cream.location.z = 0.095
	cherry = lib.sphere("food_cupcake_cherry", 0.018, material="brick", segments=6, rings=4)
	cherry.location.z = 0.15
	return lib.group([cup, cream, cherry])
```

## `tools/blender/gen/food_donut.py`

```python
"""Пончик с розовой глазурью: тор + тонкий тор сверху."""
import lib

SPEC = {"max_tris": 600, "max_dim": 0.3}   # два тора по 256 треугольников


def build():
	ring = lib.torus("food_donut", major=0.07, minor=0.03, material="sand")
	ring.location.z = 0.03
	glaze = lib.torus("food_donut_glaze", major=0.07, minor=0.022, material="coral")
	glaze.location.z = 0.045
	return lib.group([ring, glaze])
```

## `tools/blender/gen/food_fish.py`

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

## `tools/blender/gen/food_fish_sandwich.py`

```python
"""Рыбный сэндвич: булка, золотистое филе, лист салата."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	bottom = lib.cylinder("food_fish_sandwich", radius=0.08, depth=0.03, segments=10, material="sand")
	bottom.location.z = 0.015
	lettuce = lib.cylinder("food_fish_sandwich_leaf", radius=0.085, depth=0.012, segments=10, material="leaf")
	lettuce.location.z = 0.036
	fish = lib.rounded_box("food_fish_sandwich_fish", (0.17, 0.09, 0.025), bevel=0.01, segments=1, material="cat_orange")
	fish.location.z = 0.055
	top = lib.sphere("food_fish_sandwich_top", 0.08, material="sand", segments=10, rings=6)
	top.scale = (1, 1, 0.45)
	top.location.z = 0.07
	return lib.group([bottom, lettuce, fish, top])
```

## `tools/blender/gen/food_fries.py`

```python
"""Картошка фри: красный стаканчик и палочки."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	cup = lib.rounded_box("food_fries", (0.11, 0.07, 0.11), bevel=0.01, segments=1, material="brick")
	cup.location.z = 0.055
	parts = [cup]
	for i, (x, y, h) in enumerate(((-0.03, 0, 0.17), (0, 0.01, 0.19), (0.03, -0.01, 0.16), (-0.015, -0.015, 0.18), (0.02, 0.02, 0.175))):
		f = lib.rounded_box(f"food_fries_f{i}", (0.016, 0.016, h - 0.06), bevel=0.0, segments=1, material="rarity_legendary")
		f.location = (x, y, 0.06 + (h - 0.06) / 2)
		parts.append(f)
	return lib.group(parts)
```

## `tools/blender/gen/food_golden_fish.py`

```python
"""Золотая рыбка (легендарная, только из ведра рыбака): золотое тельце, хвост, плавник."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	body = lib.sphere("food_golden_fish", radius=0.06, material="rarity_legendary")
	body.scale = (1.0, 1.8, 0.6)
	body.location.z = 0.036
	tail = lib.wedge("food_golden_fish_tail", width=0.09, length=0.06, height=0.015, material="cat_orange")
	tail.rotation_euler = (0, 0, 3.14159)
	tail.location = (0, -0.1, 0.036)
	fin = lib.wedge("food_golden_fish_fin", width=0.015, length=0.05, height=0.03, material="cat_orange")
	fin.location = (0, 0, 0.06)
	return lib.group([body, tail, fin])
```

## `tools/blender/gen/food_hotdog.py`

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

## `tools/blender/gen/food_ice_cream.py`

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

## `tools/blender/gen/food_pizza.py`

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

## `tools/blender/gen/food_popcorn.py`

```python
"""Попкорн: полосатый стакан и горка зёрен."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cup = lib.cylinder("food_popcorn", radius=0.07, depth=0.14, segments=8, material="brick")
	cup.location.z = 0.07
	parts = [cup]
	for i, (x, y, z) in enumerate(((0, 0, 0.16), (0.04, 0.02, 0.15), (-0.04, 0.01, 0.15), (0.01, -0.04, 0.15), (0, 0.04, 0.19))):
		k = lib.sphere(f"food_popcorn_k{i}", 0.035, material="cream", segments=6, rings=4)
		k.location = (x, y, z)
		parts.append(k)
	return lib.group(parts)
```

## `tools/blender/gen/food_sandwich.py`

```python
"""Сэндвич: два треугольных ломтика хлеба, салат и сыр между ними."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	bottom = lib.wedge("food_sandwich", width=0.2, length=0.18, height=0.03, material="cream")
	bottom.location.z = 0.015
	leaf = lib.wedge("food_sandwich_leaf", width=0.21, length=0.19, height=0.012, material="leaf")
	leaf.location.z = 0.036
	cheese = lib.wedge("food_sandwich_cheese", width=0.19, length=0.17, height=0.012, material="rarity_legendary")
	cheese.location.z = 0.048
	top = lib.wedge("food_sandwich_top", width=0.2, length=0.18, height=0.03, material="cream")
	top.location.z = 0.069
	return lib.group([bottom, leaf, cheese, top])
```

## `tools/blender/gen/food_sausage.py`

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

## `tools/blender/gen/food_shrimp.py`

```python
"""Креветка: изогнутое тельце из сегментов и хвостик."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	parts = []
	for i in range(5):
		a = math.radians(-40 + i * 45)
		s = lib.sphere(f"food_shrimp" if i == 0 else f"food_shrimp_s{i}", 0.035 - i * 0.004, material="coral", segments=8, rings=5)
		s.location = (0.06 * math.cos(a), 0.06 * math.sin(a), 0.035)
		parts.append(s)
	tail = lib.wedge("food_shrimp_tail", width=0.05, length=0.04, height=0.01, material="cream")
	tail.location = (-0.05, 0.05, 0.03)
	parts.append(tail)
	return lib.group(parts)
```

## `tools/blender/gen/food_squid.py`

```python
"""Кальмар: сиреневая мантия-конус и щупальца."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	body = lib.cone("food_squid", radius=0.05, depth=0.14, segments=8, material="lilac")
	body.location.z = 0.13
	parts = [body]
	for i, (x, y) in enumerate(((-0.03, 0), (0.03, 0), (0, 0.03), (0, -0.03))):
		t = lib.cylinder(f"food_squid_t{i}", radius=0.01, depth=0.06, segments=6, material="cream")
		t.location = (x, y, 0.03)
		parts.append(t)
	return lib.group(parts)
```

## `tools/blender/gen/food_sushi.py`

```python
"""Суши: два нигири — рис, лосось, полоска нори."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	parts = []
	for i, x in enumerate((-0.045, 0.045)):
		rice = lib.rounded_box("food_sushi" if i == 0 else f"food_sushi_r{i}", (0.07, 0.12, 0.04), bevel=0.012, segments=2, material="eye_white")
		rice.location = (x, 0, 0.02)
		fish = lib.rounded_box(f"food_sushi_f{i}", (0.075, 0.13, 0.02), bevel=0.008, segments=2, material="coral")
		fish.location = (x, 0, 0.05)
		nori = lib.rounded_box(f"food_sushi_n{i}", (0.08, 0.025, 0.065), bevel=0.0, segments=1, material="ink")
		nori.location = (x, 0, 0.032)
		parts += [rice, fish, nori]
	return lib.group(parts)
```

## `tools/blender/gen/forklift.py`

```python
"""Погрузчик причала (план 14): корпус, кабина-рама, мачта, вилы спереди (−Y Blender = +Z Godot — «вперёд» по ходу), ящик."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.8}


def build():
	body = lib.rounded_box("forklift", (1.1, 1.8, 0.7), bevel=0.05, material="rarity_legendary")
	body.location = (0, 0.2, 0.55)
	seat = lib.rounded_box("forklift_seat", (0.6, 0.5, 0.3), bevel=0.03, segments=1, material="ink")
	seat.location = (0, 0.4, 1.05)
	parts = [body, seat]
	for i, (x, y) in enumerate(((-0.5, -0.4), (0.5, -0.4), (-0.5, 0.8), (0.5, 0.8))):
		post = lib.rounded_box(f"forklift_post{i}", (0.06, 0.06, 1.1), bevel=0.0, segments=1, material="ink")
		post.location = (x, y, 1.45)
		parts.append(post)
	roof = lib.rounded_box("forklift_roof", (1.1, 1.3, 0.06), bevel=0.01, segments=1, material="ink")
	roof.location = (0, 0.2, 2.0)
	parts.append(roof)
	for i, x in enumerate((-0.35, 0.35)):
		mast = lib.rounded_box(f"forklift_mast{i}", (0.08, 0.08, 1.8), bevel=0.0, segments=1, material="asphalt")
		mast.location = (x, -0.75, 0.9)
		fork = lib.rounded_box(f"forklift_fork{i}", (0.1, 0.9, 0.05), bevel=0.0, segments=1, material="asphalt")
		fork.location = (x, -1.2, 0.25)
		parts += [mast, fork]
	crate = lib.rounded_box("forklift_crate", (0.9, 0.8, 0.6), bevel=0.03, segments=1, material="sand")
	crate.location = (0, -1.2, 0.58)
	parts.append(crate)
	for i, (x, y) in enumerate(((-0.58, -0.3), (0.58, -0.3), (-0.58, 0.75), (0.58, 0.75))):
		w = lib.cylinder(f"forklift_wheel{i}", radius=0.22, depth=0.16, segments=10, material="ink")
		w.rotation_euler = (0, 1.5708, 0)
		w.location = (x, y, 0.22)
		parts.append(w)
	return lib.group(parts)
```

## `tools/blender/gen/fountain.py`

```python
"""Фонтан: круглая чаша 3,2 м (бортик 0,45), вода (меш fountain_water — зеркальный), колонна и верхняя чаша."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 3.3}


def build():
	basin = lib.cylinder("fountain", radius=1.6, depth=0.45, segments=24, material="cream")
	basin.location.z = 0.225
	water = lib.cylinder("fountain_water", radius=1.42, depth=0.02, segments=24, material="sea_light")
	water.location.z = 0.4
	column = lib.cylinder("fountain_column", radius=0.22, depth=1.1, segments=12, material="sand")
	column.location.z = 0.95
	bowl = lib.cylinder("fountain_bowl", radius=0.6, depth=0.14, segments=16, material="cream")
	bowl.location.z = 1.45
	top_water = lib.cylinder("fountain_water_top", radius=0.5, depth=0.02, segments=16, material="sea_light")
	top_water.location.z = 1.53
	knob = lib.sphere("fountain_knob", 0.12, material="sky")
	knob.location.z = 1.62
	return lib.group([basin, water, column, bowl, top_water, knob])
```

## `tools/blender/gen/garage.py`

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

## `tools/blender/gen/gardener.py`

```python
"""Генератор: gardener (CC0 Quaternius Animated Human, перекраска по роли — human.py)."""
import human

SPEC = {"max_tris": 2500, "max_dim": 2.0, "animations": True}


def build():
	return human.build("gardener")
```

## `tools/blender/gen/gazebo.py`

```python
"""Беседка на вершине холма парка (план 12): восьмигранный пол 0,3 м, 6 столбов, конусная крыша."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 5.3}


def build():
	floor = lib.cylinder("gazebo", radius=2.0, depth=0.3, segments=8, material="sand", smooth=False)
	floor.location.z = 0.15
	parts = [floor]
	for k in range(6):
		a = k * math.pi / 3
		post = lib.cylinder(f"gazebo_post{k}", radius=0.08, depth=2.2, segments=8, material="cream")
		post.location = (1.85 * math.cos(a), 1.85 * math.sin(a), 0.3 + 1.1)
		parts.append(post)
	roof = lib.cone("gazebo_roof", radius=2.6, depth=1.1, segments=8, material="brick", smooth=False)
	roof.location.z = 2.5 + 0.55
	parts.append(roof)
	return lib.group(parts)
```

## `tools/blender/gen/grass.py`

```python
"""Пучок травы: пять узких конусов, чуть наклонённых в стороны. Без коллизии (solid: false в раскладке)."""
import math

import lib

SPEC = {"max_tris": 120, "max_dim": 0.3}


def build():
	parts = []
	for i in range(5):
		a = i * 2 * math.pi / 5
		c = lib.cone("grass" if i == 0 else f"grass_{i}", radius=0.02, depth=0.22, segments=5, material="leaf" if i % 2 else "olive")
		c.location = (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.11)
		c.rotation_euler = (math.sin(a) * 0.35, -math.cos(a) * 0.35, 0.0)
		parts.append(c)
	return lib.group(parts)
```

## `tools/blender/gen/ground.py`

```python
"""Земля двора 60×60 м: асфальт с песочной площадкой тротуара."""
import lib

SPEC = {"max_tris": 200, "max_dim": 60.0}


def build():
	asphalt = lib.rounded_box("ground", (60, 60, 0.1), bevel=0.0, material="asphalt")
	asphalt.location.z = -0.05
	walk = lib.rounded_box("sidewalk", (30, 30, 0.12), bevel=0.03, segments=2, material="sand")
	walk.location = (-10, 10, -0.055)   # верх на +5 мм: без z-fighting с асфальтом, кот стоит на коллизии пола y=0
	return [asphalt, walk]
```

## `tools/blender/gen/guard.py`

```python
"""Генератор: guard (CC0 Quaternius Animated Human, перекраска по роли — human.py)."""
import human

SPEC = {"max_tris": 2500, "max_dim": 2.0, "animations": True}


def build():
	return human.build("guard")
```

## `tools/blender/gen/gull.py`

```python
"""Генератор чайки (CC0-голубь, перекраска — gull.py)."""
import gull

SPEC = {"max_tris": 1500, "max_dim": 0.6, "animations": True}


def build():
	return gull.build()
```

## `tools/blender/gen/ivy.py`

```python
"""Плющ: полоса 2 × 1 м из листьев-квадов в плоскости XZ Blender (= XY Godot, лицом по ±Z).
Висит на стене; в Godot материал двусторонний (solid: false в раскладке)."""
import math
import random

import bmesh
import bpy

import palette

SPEC = {"max_tris": 120, "max_dim": 2.5}


def build():
	rnd = random.Random(3)
	bm = bmesh.new()
	for i in range(26):   # два ряда внахлёст: листва, а не конфетти
		x = -0.95 + (i % 13) * 0.158 + rnd.uniform(-0.03, 0.03)
		z = 0.2 + (i // 13) * 0.42 + (i % 2) * 0.12 + rnd.uniform(-0.05, 0.05)
		s = rnd.uniform(0.17, 0.24)
		rot = rnd.uniform(-0.5, 0.5)
		verts = []
		for dx, dz in ((-s, -s), (s, -s), (s, s), (-s, s)):
			rx = dx * math.cos(rot) - dz * math.sin(rot)
			rz = dx * math.sin(rot) + dz * math.cos(rot)
			verts.append(bm.verts.new((x + rx, 0.0, z + rz)))
		f = bm.faces.new(verts)
		f.material_index = i % 2
	mesh = bpy.data.meshes.new("ivy")
	bm.to_mesh(mesh)
	bm.free()
	mesh.materials.append(palette.get_material("leaf"))
	mesh.materials.append(palette.get_material("olive"))
	obj = bpy.data.objects.new("ivy", mesh)
	bpy.context.scene.collection.objects.link(obj)
	bpy.context.view_layer.update()
	return [obj]
```

## `tools/blender/gen/kid.py`

```python
"""Генератор: kid (CC0 Quaternius Animated Human, перекраска по роли — human.py)."""
import human

SPEC = {"max_tris": 2500, "max_dim": 2.0, "animations": True}


def build():
	return human.build("kid")
```

## `tools/blender/gen/kiosk.py`

```python
"""Киоск мороженого 1,6×1,2×2,2 м: корпус, окошко, полосатый навес, рожок-вывеска сверху."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.8}


def build():
	body = lib.rounded_box("kiosk", (1.6, 1.2, 2.0), bevel=0.04, material="cream")
	body.location.z = 1.0
	window = lib.rounded_box("kiosk_window", (1.1, 0.06, 0.6), bevel=0.01, material="sky")
	window.location = (0, 0.6, 1.3)
	counter = lib.rounded_box("kiosk_counter", (1.3, 0.3, 0.06), bevel=0.01, material="sand")
	counter.location = (0, 0.72, 0.95)
	parts = [body, window, counter]
	for i in range(4):
		stripe = lib.rounded_box(f"kiosk_awning{i}", (0.42, 0.5, 0.05), bevel=0.0, material="coral" if i % 2 == 0 else "cream")
		stripe.location = (-0.63 + i * 0.42, 0.8, 1.75)
		stripe.rotation_euler = (0.35, 0, 0)
		parts.append(stripe)
	cone = lib.cone("kiosk_cone", radius=0.18, depth=0.4, segments=10, material="sand")
	cone.rotation_euler = (3.14159, 0, 0)
	cone.location.z = 2.25
	scoop = lib.sphere("kiosk_scoop", 0.2, material="coral")
	scoop.location.z = 2.5
	parts += [cone, scoop]
	return lib.group(parts)
```

## `tools/blender/gen/lamp.py`

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

## `tools/blender/gen/park_ground.py`

```python
"""Пол парка 30×32 м: газон (меш lawn) и гравийные дорожки (меш path). Текстуры — SurfaceTextures по именам.
Центр модели — центр парка; в раскладке ставится в (0, 0, 45). +Y Blender = −Z Godot (к кафе)."""
import lib

SPEC = {"max_tris": 400, "max_dim": 32.5}


def build():
	lawn = lib.rounded_box("lawn", (30, 32, 0.1), bevel=0.0, material="leaf")
	lawn.location.z = -0.044   # верх на +6 мм: над асфальтом двора там, где они перекрываются
	# Дорожки: крест через фонтан и отвод к воротам (x 12, южный край). Верх на +12 мм.
	pieces = []
	for name, size, loc in (
		("p_ns", (2.2, 32, 0.1), (0, 0)),
		("p_ew", (30, 2.2, 0.1), (0, 0)),
		("p_gate", (2.2, 9, 0.1), (12, 11.5)),      # от ворот (Godot z 30) на север до z 39
		("p_gate2", (12, 2.2, 0.1), (6, 7)),       # к центральной дорожке (Godot z 38)
		("p_play", (8, 2.2, 0.1), (-8, 3)),        # к площадке (Godot z 42)
	):
		b = lib.rounded_box(name, size, bevel=0.0, material="sand")
		b.location = (loc[0], loc[1], -0.038)
		pieces.append(b)
	path = lib.join("path", pieces)
	return [lawn, path]
```

## `tools/blender/gen/pigeon.py`

```python
"""Генератор голубя (CC0 mujtaba-io — pigeon.py)."""
import pigeon

SPEC = {"max_tris": 1500, "max_dim": 0.35, "animations": True}


def build():
	return pigeon.build()
```

## `tools/blender/gen/pontoon.py`

```python
"""Понтон-ступень у проёма причала (ревью плана 13): дощатая площадка 1,4×1,6 м высотой 0,3 — с лодки на причал в два шага."""
import lib

SPEC = {"max_tris": 600, "max_dim": 1.7}


def build():
	parts = []
	for i in range(4):
		p = lib.rounded_box("pontoon" if i == 0 else f"pontoon_plank{i}", (1.4, 0.36, 0.08), bevel=0.01, segments=1, material="sand" if i % 2 else "brick")
		p.location = (0, -0.6 + i * 0.4, 0.26)
		parts.append(p)
	for i, (x, y) in enumerate(((-0.6, -0.7), (0.6, -0.7), (-0.6, 0.7), (0.6, 0.7))):
		post = lib.cylinder(f"pontoon_post{i}", radius=0.07, depth=0.6, segments=8, material="ink")
		post.location = (x, y, 0.0)
		parts.append(post)
	return lib.group(parts)
```

## `tools/blender/gen/puddle.py`

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

## `tools/blender/gen/ramp1.py`

```python
"""Модуль террасы: ramp высотой 1 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.ramp(1)
```

## `tools/blender/gen/ramp2.py`

```python
"""Модуль террасы: ramp высотой 2 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.ramp(2)
```

## `tools/blender/gen/ramp3.py`

```python
"""Модуль террасы: ramp высотой 3 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.ramp(3)
```

## `tools/blender/gen/retaining_wall1.py`

```python
"""Модуль террасы: wall высотой 1 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.wall(1)
```

## `tools/blender/gen/retaining_wall2.py`

```python
"""Модуль террасы: wall высотой 2 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.wall(2)
```

## `tools/blender/gen/retaining_wall3.py`

```python
"""Модуль террасы: wall высотой 3 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.wall(3)
```

## `tools/blender/gen/sandbox.py`

```python
"""Песочница 2×2 м: четыре доски бортика 0,2 м и песок внутри, ведёрко."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.1}


def build():
	sand = lib.rounded_box("sandbox", (1.84, 1.84, 0.12), bevel=0.02, material="cream")
	sand.location.z = 0.06
	parts = [sand]
	for i, (x, y, sx, sy) in enumerate(((0, 0.96, 2.0, 0.12), (0, -0.96, 2.0, 0.12), (0.96, 0, 0.12, 1.8), (-0.96, 0, 0.12, 1.8))):
		b = lib.rounded_box(f"sandbox_board{i}", (sx, sy, 0.2), bevel=0.02, segments=1, material="brick")
		b.location = (x, y, 0.1)
		parts.append(b)
	bucket = lib.cylinder("sandbox_bucket", radius=0.08, depth=0.12, segments=10, material="sky")
	bucket.location = (0.4, 0.3, 0.18)
	parts.append(bucket)
	return lib.group(parts)
```

## `tools/blender/gen/shed.py`

```python
"""Сторожка садовника 2×2 м: стены, двускатная крыша (клин), дверь, лейка у входа."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 2.6}


def build():
	walls = lib.rounded_box("shed", (2.0, 2.0, 1.9), bevel=0.03, material="olive")
	walls.location.z = 0.95
	roof = lib.wedge("shed_roof", width=2.4, length=1.2, height=2.3, material="brick")
	roof.rotation_euler = (0, math.pi / 2, math.pi / 2)
	roof.location = (0, 1.15, 1.9)
	door = lib.rounded_box("shed_door", (0.7, 0.06, 1.4), bevel=0.01, material="sand")
	door.location = (0, 1.01, 0.7)
	can = lib.cylinder("shed_can", radius=0.12, depth=0.25, segments=10, material="sky")
	can.location = (0.7, 1.25, 0.125)
	return lib.group([walls, roof, door, can])
```

## `tools/blender/gen/slide.py`

```python
"""Детская горка с домиком: домик 1,2×1,2 м (стенки 0,7, открыт спереди — укрытие), крыша-площадка, скат и лесенка."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 3.2}


def build():
	roof = lib.rounded_box("slide", (1.3, 1.3, 0.06), bevel=0.02, material="coral")
	roof.location.z = 0.72
	back = lib.rounded_box("slide_back", (1.2, 0.08, 0.7), bevel=0.01, material="sky")
	back.location = (0, -0.56, 0.35)
	parts = [roof, back]
	for i, x in enumerate((-0.56, 0.56)):
		side = lib.rounded_box(f"slide_side{i}", (0.08, 1.2, 0.7), bevel=0.01, material="sky")
		side.location = (x, 0, 0.35)
		parts.append(side)
	ramp = lib.rounded_box("slide_ramp", (0.5, 1.6, 0.05), bevel=0.01, material="rarity_legendary")
	ramp.location = (-1.25, 0, 0.38)
	ramp.rotation_euler = (0.0, math.radians(-27.0), math.radians(90.0))
	parts.append(ramp)
	for i in range(4):
		rung = lib.rounded_box(f"slide_rung{i}", (0.06, 0.5, 0.04), bevel=0.0, material="cream")
		rung.location = (0.75, 0, 0.15 + i * 0.17)
		parts.append(rung)
	return lib.group(parts)
```

## `tools/blender/gen/sprinkler.py`

```python
"""Дождеватель газона: низкая головка на стойке (вода — частицы в Godot)."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.3}


def build():
	base = lib.cylinder("sprinkler", radius=0.06, depth=0.08, segments=10, material="ink")
	base.location.z = 0.04
	head = lib.cylinder("sprinkler_head", radius=0.035, depth=0.08, segments=8, material="sky")
	head.location.z = 0.12
	return lib.group([base, head])
```

## `tools/blender/gen/stairs.py`

```python
"""Лестница на балкон: 4 ступени по 0,25 м и площадка 1,2×1,2 на высоте 1,0 м.
Ступени идут по -Y Blender (= +Z Godot), как коллайдеры в data/layout/yard.json."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.5}


def build():
	parts = []
	for i in range(4):
		step = lib.rounded_box("stairs" if i == 0 else f"stairs_step{i}", (1.2, 0.5, 0.25), bevel=0.02, segments=1, material="sand")
		step.location = (0, -i * 0.5, 0.125 + i * 0.25)
		parts.append(step)
	deck = lib.rounded_box("stairs_deck", (1.2, 1.2, 0.12), bevel=0.02, segments=1, material="sand")
	deck.location = (0, -2.55, 0.94)
	parts.append(deck)
	rail = lib.rounded_box("stairs_rail", (0.06, 1.2, 0.9), bevel=0.0, material="ink")
	rail.location = (0.6, -2.55, 1.45)
	parts.append(rail)
	return lib.group(parts)
```

## `tools/blender/gen/swings.py`

```python
"""Качели: А-образные стойки, перекладина 2,4 м, два сиденья на тросах."""
import math

import lib

SPEC = {"max_tris": 800, "max_dim": 2.6}


def build():
	bar = lib.cylinder("swings", radius=0.05, depth=2.4, segments=8, material="coral")
	bar.rotation_euler = (0, math.pi / 2, 0)
	bar.location.z = 1.8
	parts = [bar]
	for i, x in enumerate((-1.15, 1.15)):
		for j, s in enumerate((-1, 1)):
			leg = lib.cylinder(f"swings_leg{i}{j}", radius=0.04, depth=1.95, segments=8, material="coral")
			leg.rotation_euler = (math.radians(18 * s), 0, 0)
			leg.location = (x, 0.3 * s, 0.9)
			parts.append(leg)
	for i, x in enumerate((-0.5, 0.5)):
		seat = lib.rounded_box(f"swings_seat{i}", (0.4, 0.2, 0.04), bevel=0.01, material="rarity_legendary")
		seat.location = (x, 0, 0.45)
		parts.append(seat)
		for k, dx in enumerate((-0.17, 0.17)):
			rope = lib.cylinder(f"swings_rope{i}{k}", radius=0.01, depth=1.33, segments=4, material="ink")
			rope.location = (x + dx, 0, 1.12)
			parts.append(rope)
	return lib.group(parts)
```

## `tools/blender/gen/terrace_stairs1.py`

```python
"""Модуль террасы: stairs высотой 1 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.stairs(1)
```

## `tools/blender/gen/terrace_stairs2.py`

```python
"""Модуль террасы: stairs высотой 2 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.stairs(2)
```

## `tools/blender/gen/terrace_stairs3.py`

```python
"""Модуль террасы: stairs высотой 3 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.stairs(3)
```

## `tools/blender/gen/tree.py`

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

## `tools/blender/gen/umbrella.py`

```python
"""Зонт кафе: стойка и конус купола r 1,2 на высоте 2,2 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.6}


def build():
	pole = lib.cylinder("umbrella", radius=0.03, depth=2.2, material="ink", segments=8)
	pole.location.z = 1.1
	canopy = lib.cone("umbrella_canopy", radius=1.2, depth=0.45, material="coral", segments=12)
	canopy.location.z = 2.35
	return lib.group([pole, canopy])
```

## `tools/blender/gen/wall.py`

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

## `tools/blender/gen/wasp.py`

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

## `tools/blender/gen/yarn.py`

```python
"""Клубочек пряжи 0,16 м: сфера с двумя лентами-торами."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.25}


def build():
	ball = lib.sphere("yarn", radius=0.08, material="lilac")
	ball.location.z = 0.08
	band = lib.torus("yarn_band", major=0.075, minor=0.012, material="coral")
	band.location.z = 0.08
	band.rotation_euler = (0.6, 0.3, 0)
	band2 = lib.torus("yarn_band2", major=0.075, minor=0.012, material="coral")
	band2.location.z = 0.08
	band2.rotation_euler = (-0.5, 0.9, 0)
	return lib.group([ball, band, band2])
```

## `tools/blender/gen/yarn_shop.py`

```python
"""Будка «Пряжа»: пол, задняя и две боковые стенки, навес, полка с клубочками.
Открытый перёд по +Y Blender (= -Z Godot), задняя стенка на -Y Blender (= +Z Godot)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.6}


def build():
	floor = lib.rounded_box("yarn_shop", (2.2, 2.2, 0.03), bevel=0.01, segments=1, material="sand")
	floor.location.z = 0.015   # плита; коллайдер в yarn_shop.tscn (Walls/Floor), кот стоит на ней
	back = lib.rounded_box("yarn_shop_back", (2.2, 0.12, 2.2), bevel=0.02, segments=1, material="lilac")
	back.location = (0, -1.04, 1.18)
	parts = [floor, back]
	for name, x in (("yarn_shop_side_l", -1.04), ("yarn_shop_side_r", 1.04)):
		side = lib.rounded_box(name, (0.12, 2.2, 2.2), bevel=0.02, segments=1, material="lilac")
		side.location = (x, 0, 1.18)
		parts.append(side)
	roof = lib.rounded_box("yarn_shop_roof", (2.6, 2.6, 0.12), bevel=0.03, segments=1, material="coral")
	roof.location.z = 2.34
	parts.append(roof)
	shelf = lib.rounded_box("yarn_shop_shelf", (1.9, 0.3, 0.06), bevel=0.01, segments=1, material="cream")
	shelf.location = (0, -0.85, 1.3)
	parts.append(shelf)
	for i, (x, mat) in enumerate(((-0.6, "coral"), (-0.2, "sky"), (0.2, "rarity_legendary"), (0.6, "leaf"))):
		ball = lib.sphere(f"yarn_shop_ball{i}", radius=0.1, material=mat, segments=10, rings=6)
		ball.location = (x, -0.85, 1.43)
		parts.append(ball)
	return lib.group(parts)
```

## `tools/blender/gull.py`

```python
"""Чайка (план 14): CC0-голубь mujtaba-io с его клипами flap/idle, перекрашенный под чайку и крупнее (длина 0,5 м).
Готовой CC0-чайки с клипами не нашлось (BlendSwap 7419 — риг без клипов), а голубь уже в проекте — правило владельца:
готовые анимации раньше генерации."""
import bpy
from mathutils import Vector

import palette
import pigeon

TARGET_LENGTH = 0.5


def build():
	arm, mesh = pigeon.build()
	m = mesh.matrix_world
	zs = [(m @ v.co).z for v in mesh.data.vertices]
	lo, hi = min(zs), max(zs)
	mesh.data.materials.clear()
	for key in ("cream", "asphalt", "rarity_legendary"):
		mesh.data.materials.append(palette.get_material(key))
	for p in mesh.data.polygons:
		z = (m @ p.center).z
		if z < lo + (hi - lo) * 0.18:
			p.material_index = 2                     # жёлтые лапы
		elif z > lo + (hi - lo) * 0.62:
			p.material_index = 1                     # серая спина и крылья
		else:
			p.material_index = 0                     # белая грудка
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	length = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3))
	k = TARGET_LENGTH / length
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = "GullRig"
	mesh.name = "gull"
	return [arm, mesh]
```

## `tools/blender/human.py`

```python
"""Люди парка (садовник, ребёнок, сторож) из CC0 Quaternius «Animated Human».
Текстура модели — палитра-полоски: каждая грань получает материал палитры по цвету текстуры под её UV
(кожа, волосы, штаны, рубашка) и по роли персонажа. Клипы: idle, walk, run, work."""
import math
import os

import bpy
from mathutils import Matrix, Vector

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "third_party", "quaternius_animated_human")
BLEND = os.path.join(SRC, "AnimatedHuman.blend")
TEXTURE = os.path.join(SRC, "ClothedLightSkin2.png")
ACTIONS = {"Idle": "idle", "Walk": "walk", "Run": "run", "Working": "work"}
# цвет полосы текстуры -> класс
CLASSES = {(255, 209, 159): "skin", (41, 41, 41): "hair", (200, 148, 89): "pants", (100, 215, 105): "shirt"}
ROLES = {
	"gardener": {"height": 1.7, "skin": "cream", "hair": "brick", "pants": "olive", "shirt": "leaf"},
	"kid": {"height": 1.1, "skin": "cream", "hair": "cat_orange", "pants": "sky", "shirt": "rarity_legendary"},
	"guard": {"height": 1.7, "skin": "cream", "hair": "ink", "pants": "ink", "shirt": "sea_deep"},
}


def _classify(mesh):
	img = bpy.data.images.load(TEXTURE)
	w, h = img.size
	px = list(img.pixels)
	uv = mesh.data.uv_layers.active.data
	out = []
	for p in mesh.data.polygons:
		u = sum(uv[l].uv[0] for l in p.loop_indices) / len(p.loop_indices)
		v = sum(uv[l].uv[1] for l in p.loop_indices) / len(p.loop_indices)
		x = min(w - 1, max(0, int(u * w)))
		y = min(h - 1, max(0, int(v * h)))
		i = (y * w + x) * 4
		c = tuple(round(k * 255) for k in px[i:i + 3])
		best = min(CLASSES, key=lambda ref: sum((a - b) ** 2 for a, b in zip(ref, c)))
		out.append(CLASSES[best])
	return out


def _recolor(mesh, role):
	classes = _classify(mesh)
	keys = ["skin", "hair", "pants", "shirt"]
	mesh.data.materials.clear()
	for k in keys:
		mesh.data.materials.append(palette.get_material(ROLES[role][k]))
	for p, c in zip(mesh.data.polygons, classes):
		p.material_index = keys.index(c)


def forward_vector(arm):
	"""Направление носков в позе клипа walk (кадр 0), мировые координаты. Поза покоя не годится:
	клипы поворачивают таз относительно покоя, и по покою модель в игре смотрела вбок."""
	arm.animation_data_create()
	arm.animation_data.action = bpy.data.actions["walk"]
	bpy.context.scene.frame_set(0)
	bpy.context.view_layer.update()
	d = Vector((0.0, 0.0, 0.0))
	for side in ("Left", "Right"):
		foot = arm.matrix_world @ arm.pose.bones[side + "Foot"].head
		toe = arm.matrix_world @ arm.pose.bones[side + "ToeBase"].head
		d += toe - foot
	arm.animation_data.action = None
	bpy.context.view_layer.update()
	return d


def _face_forward(arm):
	"""Разворачиваем так, чтобы носки (в позе ходьбы) смотрели по +Y Blender (= −Z Godot)."""
	arm.rotation_mode = "XYZ"
	d = forward_vector(arm)
	arm.rotation_euler.z += math.pi / 2 - math.atan2(d.y, d.x)
	bpy.context.view_layer.update()


def build(role):
	bpy.ops.wm.open_mainfile(filepath=BLEND)
	arm = bpy.data.objects["Human Armature"]
	mesh = bpy.data.objects["Human_Mesh"]
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)
	for a in list(bpy.data.actions):
		if a.name in ACTIONS:
			a.name = ACTIONS[a.name]
			rig_utils.clean_action(a, arm)
		else:
			bpy.data.actions.remove(a)
	_recolor(mesh, role)
	arm.animation_data_create()
	arm.animation_data.action = None
	_face_forward(arm)
	bpy.context.view_layer.update()
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	height = max(c.z for c in corners) - min(c.z for c in corners)
	k = ROLES[role]["height"] / height
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = f"{role.capitalize()}Rig"
	mesh.name = role
	return [arm, mesh]
```

## `tools/blender/lib.py`

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


def join(name, objs):
	"""Сливает объекты в один меш (мировые координаты, материалы по граням); исходники удаляются.
	Нужно, когда поверхность должна быть одним мешем с одним именем (SurfaceTextures ищет по имени)."""
	import bmesh as _bm
	bpy.context.view_layer.update()
	bm = _bm.new()
	mats = []
	for o in objs:
		depsgraph = bpy.context.evaluated_depsgraph_get()
		ev = o.evaluated_get(depsgraph)
		tmp = ev.to_mesh().copy()
		ev.to_mesh_clear()
		tmp.transform(o.matrix_world)
		for poly in tmp.polygons:
			mat = o.data.materials[poly.material_index] if o.data.materials else None
			if mat not in mats:
				mats.append(mat)
			poly.material_index = mats.index(mat)
		bm.from_mesh(tmp)
		bpy.data.meshes.remove(tmp)
		src = o.data
		bpy.data.objects.remove(o)
		if src.users == 0:
			bpy.data.meshes.remove(src)   # без сирот в долгих сессиях
	mesh = bpy.data.meshes.new(name)
	bm.to_mesh(mesh)
	bm.free()
	for m in mats:
		mesh.materials.append(m)
	obj = bpy.data.objects.new(name, mesh)
	bpy.context.scene.collection.objects.link(obj)
	bpy.context.view_layer.update()
	return obj
```

## `tools/blender/palette.py`

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
    "eye_white": "#F4F1E8",   # белок глаз; не из спека, чтобы скины (sr_cream) не красили глаза
    "eye_green": "#6FA04A",   # радужка (спек 2.8)
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

## `tools/blender/pigeon.py`

```python
"""Голубь из CC0 mujtaba-io: серый корпус, бирюзовая шея, коралловые лапы; длина 0,3 м; клипы flap, idle."""
import os

import bpy
from mathutils import Vector

import palette
import rig_utils

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLEND = os.path.join(ROOT, "third_party", "pigeon_mujtaba", "pigeon.blend")
ACTIONS = {"flap-wings-animation": "flap", "idle-animation": "idle"}
TARGET_LENGTH = 0.3


def build():
	bpy.ops.wm.open_mainfile(filepath=BLEND)
	arm = bpy.data.objects["pigeon-armature"]
	mesh = bpy.data.objects["pigeon-model"]
	for o in list(bpy.data.objects):
		if o not in (arm, mesh):
			bpy.data.objects.remove(o)
	for a in list(bpy.data.actions):
		if a.name in ACTIONS:
			a.name = ACTIONS[a.name]
			rig_utils.clean_action(a, arm)
		else:
			bpy.data.actions.remove(a)
	bpy.context.view_layer.update()
	m = mesh.matrix_world
	zs = [(m @ v.co).z for v in mesh.data.vertices]
	lo, hi = min(zs), max(zs)
	mesh.data.materials.clear()
	for key in ("asphalt", "sea_light", "coral"):
		mesh.data.materials.append(palette.get_material(key))
	head = arm.matrix_world @ arm.data.bones["neck-bone"].head_local
	for p in mesh.data.polygons:
		c = m @ p.center
		if c.z < lo + (hi - lo) * 0.18:
			p.material_index = 2                     # лапы
		elif (c - head).length < (hi - lo) * 0.22:
			p.material_index = 1                     # шея
		else:
			p.material_index = 0
	arm.animation_data_create()
	arm.animation_data.action = None
	rig_utils.face_forward(arm, root_bone="thorax-bone", head_bone="face-bone")
	bpy.context.view_layer.update()
	corners = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
	length = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3))
	k = TARGET_LENGTH / length
	arm.scale = (arm.scale.x * k, arm.scale.y * k, arm.scale.z * k)
	bpy.context.view_layer.update()
	arm.name = "PigeonRig"
	mesh.name = "pigeon"
	return [arm, mesh]
```

## `tools/blender/rig_inspect.py`

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

## `tools/blender/rig_utils.py`

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
		if bone is None:
			# Каналы самого объекта (location/rotation/scale арматуры): в Dog.blend Idle хранит
			# масштаб 1,215, и Godot применял его к узлу рига — собака становилась гигантской.
			cb.fcurves.remove(fc)
			continue
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

## `tools/blender/terrace_kit.py`

```python
"""Модули террас (спек «Масштаб и рельеф», раздел 3): подпорная стена, лестница, пандус высотой 1/2/3 м.
Подъём идёт по +Y Blender (= −Z Godot) от начала координат: низ у origin, верх на расстоянии run(h).
Коллайдеры лестниц и пандусов — наклонный параллелепипед (WorldBuilder.kit_colliders)."""
import math

import lib

STEP_RISE = 0.2
STEP_TREAD = 0.3
RAMP_DEG = 25.0
WIDTH = 1.6
WALL_LEN = 4.0
WALL_THICK = 1.0   # стена закрывает всю ячейку обрыва 1 м (ревью плана 10)


def stairs_run(h):
	return round(h / STEP_RISE) * STEP_TREAD


def ramp_run(h):
	return h / math.tan(math.radians(RAMP_DEG))


def wall(h):
	w = lib.rounded_box("retaining_wall", (WALL_LEN, WALL_THICK, h), bevel=0.03, segments=1, material="sand")
	w.location.z = h / 2.0
	cap = lib.rounded_box("retaining_wall_cap", (WALL_LEN + 0.06, WALL_THICK + 0.08, 0.08), bevel=0.02, segments=1, material="cream")
	cap.location.z = h + 0.04
	return lib.group([w, cap])


def stairs(h):
	n = round(h / STEP_RISE)
	parts = []
	for k in range(n):
		top = (k + 1) * STEP_RISE
		s = lib.rounded_box("terrace_stairs" if k == 0 else f"terrace_stairs_s{k}", (WIDTH, STEP_TREAD, top), bevel=0.015, segments=1, material="sand")
		s.location = (0, k * STEP_TREAD + STEP_TREAD / 2.0, top / 2.0)
		parts.append(s)
	for side, x in (("l", -WIDTH / 2 - 0.05), ("r", WIDTH / 2 + 0.05)):
		rail = lib.rounded_box(f"terrace_stairs_side_{side}", (0.1, n * STEP_TREAD, 0.12), bevel=0.0, material="ink")
		rail.location = (x, n * STEP_TREAD / 2.0, h / 2.0 + 0.3)
		rail.rotation_euler = (math.atan2(h, n * STEP_TREAD), 0, 0)
		parts.append(rail)
	return lib.group(parts)


def ramp(h):
	L = ramp_run(h)
	slab = lib.rounded_box("ramp", (WIDTH, math.hypot(L, h), 0.1), bevel=0.0, material="asphalt")
	slab.rotation_euler = (math.atan2(h, L), 0, 0)
	slab.location = (0, L / 2.0, h / 2.0)
	curb_parts = [slab]
	for side, x in (("l", -WIDTH / 2 - 0.05), ("r", WIDTH / 2 + 0.05)):
		c = lib.rounded_box(f"ramp_curb_{side}", (0.1, math.hypot(L, h), 0.18), bevel=0.0, material="cream")
		c.rotation_euler = (math.atan2(h, L), 0, 0)
		c.location = (x, L / 2.0, h / 2.0 + 0.06)
		curb_parts.append(c)
	return lib.group(curb_parts)
```

## `tools/blender/tests/list_glb.py`

```python
"""blender -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb"""
import sys

import bpy

path = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_homefile(use_empty=True)
bpy.ops.import_scene.gltf(filepath=path)
for o in bpy.data.objects:
	print("OBJ", o.type, o.name, tuple(round(d, 3) for d in o.dimensions), "parent", o.parent.name if o.parent else "-")
	if o.type == "MESH":
		print("   MATS", [m.name for m in o.data.materials if m])
for a in bpy.data.actions:
	print("ANIM", a.name, "кадры", tuple(a.frame_range))
```

## `tools/blender/tests/run.py`

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

## `tools/blender/tests/test_cat_eyes.py`

```python
import unittest

import bpy

import cat
import cat_eyes
import lib


class TestCatEyes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        lib.clear_scene()
        cls.objs = cat.build()
        cls.arm, cls.mesh = cls.objs[0], cls.objs[1]
        cls.eyes = {o.name: o for o in cls.objs[2:] if o.name.startswith("eyes_")}   # пучки и веки — не наборы

    def _world(self, o):
        bpy.context.view_layer.update()
        return [o.matrix_world @ v.co for v in o.data.vertices]

    def test_four_sets_skinned_to_head(self):
        self.assertEqual(set(self.eyes), {"eyes_normal", "eyes_scared", "eyes_happy", "eyes_dizzy", "eyes_blink"})
        for o in self.eyes.values():
            self.assertIs(o.parent, self.arm, o.name)
            self.assertEqual([m.type for m in o.modifiers], ["ARMATURE"], o.name)
            vg = o.vertex_groups["head"]
            self.assertTrue(all(any(g.group == vg.index and g.weight > 0.99 for g in v.groups) for v in o.data.vertices), o.name)
            names = {m.name for m in o.data.materials}
            self.assertFalse(names & {"sr_cat_orange", "sr_cream", "sr_coral"}, f"{o.name}: скин не должен перекрашивать глаза")

    def test_eyes_sit_on_the_front_of_the_head(self):
        lo, hi = cat_eyes.head_bbox(self.mesh)
        for o in self.eyes.values():
            pts = self._world(o)
            cy = sum(p.y for p in pts) / len(pts)
            cz = sum(p.z for p in pts) / len(pts)
            self.assertGreater(cy, hi.y - 0.03, f"{o.name}: у морды (+Y), не на затылке")
            self.assertLess(cy, hi.y + 0.03, f"{o.name}: не висят перед мордой")
            self.assertGreater(cz, lo.z + 0.5 * (hi.z - lo.z), f"{o.name}: верхняя половина головы")
            self.assertLess(cz, hi.z, o.name)
            xs = [p.x for p in pts]
            self.assertLess(min(xs), -0.005, f"{o.name}: есть левый глаз")
            self.assertGreater(max(xs), 0.005, f"{o.name}: есть правый глаз")

    def test_happy_chevrons_point_up(self):
        pts = [p for p in self._world(self.eyes["eyes_happy"]) if p.x > 0]
        cx = sum(p.x for p in pts) / len(pts)
        apex = [p.z for p in pts if abs(p.x - cx) < 0.003]
        ends = [p.z for p in pts if abs(p.x - cx) > 0.009]
        self.assertTrue(apex and ends)
        self.assertGreater(sum(apex) / len(apex), sum(ends) / len(ends), "довольные глаза «^», а не «v»")

    def test_eyes_are_sunk_into_the_head(self):
        # Ревью плана 5: опора — локальная поверхность морды у глаза, а не кончик носа; боковой выступ тоже ограничен.
        pts = self._world(self.eyes["eyes_normal"])
        for side in (-1, 1):
            eye = [p for p in pts if p.x * side > 0]
            cx = sum(p.x for p in eye) / len(eye)
            cz = sum(p.z for p in eye) / len(eye)
            front = cat_eyes.local_front(self.mesh, cx, cz)
            self.assertLess(max(p.y for p in eye), front + 0.004, "белок, зрачок и блик выступают из морды не больше чем на 4 мм")
            self.assertGreater(max(p.y for p in eye), front - 0.006, "но глаз виден, а не утоплен целиком")
            half = cat_eyes.local_halfwidth(self.mesh, front - 0.006, cz)
            self.assertLess(max(abs(p.x) for p in eye), half + 0.003, "сбоку белок не торчит из профиля головы")

    def test_normal_eyes_have_green_iris_and_no_lids(self):
        mats = {m.name for m in self.eyes["eyes_normal"].data.materials}
        self.assertTrue({"sr_eye_white", "sr_eye_green", "sr_ink"} <= mats, mats)
        self.assertFalse(any(o.name == "eyelids" for o in self.objs), "веки убраны: при утопленных глазах читались как брови")

    def test_blink_set_exists(self):
        self.assertIn("eyes_blink", self.eyes)

    def test_budget(self):
        self.assertEqual(lib.check_asset(self.objs, max_tris=8000, max_dim=0.6), [])
```

## `tools/blender/tests/test_cat_fluff.py`

```python
import unittest

import bpy

import cat
import cat_eyes
import cat_fluff
import lib

EXPECTED_BONES = {"fluff_cheeks": "head", "fluff_chest": "Bone.001", "fluff_tail": "Bone.007", "whiskers": "head", "collar": "Bone.002"}


class TestCatFluff(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        lib.clear_scene()
        cls.objs = cat.build()
        cls.arm, cls.mesh = cls.objs[0], cls.objs[1]
        cls.parts = {o.name: o for o in cls.objs[2:] if o.name in EXPECTED_BONES}

    def _world(self, o):
        bpy.context.view_layer.update()
        return [o.matrix_world @ v.co for v in o.data.vertices]

    def test_body_is_subdivided_and_smooth(self):
        mods = [m for m in self.mesh.modifiers if m.type == "SUBSURF"]
        self.assertEqual(len(mods), 1)
        self.assertEqual(mods[0].levels, 1)
        self.assertTrue(all(p.use_smooth for p in self.mesh.data.polygons))
        self.assertGreater(lib.tri_count(self.mesh), 2500, "после subdivision треугольников больше базовых 807")

    def test_parts_exist_and_are_skinned_to_the_right_bones(self):
        self.assertEqual(set(self.parts), set(EXPECTED_BONES))
        for name, bone in EXPECTED_BONES.items():
            o = self.parts[name]
            self.assertIs(o.parent, self.arm, name)
            self.assertEqual([m.type for m in o.modifiers], ["ARMATURE"], name)
            vg = o.vertex_groups[bone]
            self.assertTrue(all(any(g.group == vg.index and g.weight > 0.99 for g in v.groups) for v in o.data.vertices), name)

    def test_whiskers_stick_out_of_the_muzzle(self):
        lo, hi = cat_eyes.head_bbox(self.mesh)
        xs = [p.x for p in self._world(self.parts["whiskers"])]
        self.assertGreater(max(xs), hi.x + 0.015, "усы торчат вправо дальше щеки")
        self.assertLess(min(xs), lo.x - 0.015, "и влево")

    def test_collar_sits_on_the_neck(self):
        lo, hi = cat_eyes.group_bbox(self.mesh, "Bone.002")
        pts = self._world(self.parts["collar"])
        cz = sum(p.z for p in pts) / len(pts)
        self.assertTrue(lo.z - 0.02 < cz < hi.z + 0.02, f"ошейник на высоте шеи: {cz:.3f} vs {lo.z:.3f}..{hi.z:.3f}")
        mats = {m.name for m in self.parts["collar"].data.materials}
        self.assertEqual(mats, {"sr_coral", "sr_rarity_legendary"}, "коралловый ремешок и золотой жетон")

    def test_budget(self):
        self.assertEqual(lib.check_asset(self.objs, max_tris=8000, max_dim=0.6), [])
```

## `tools/blender/tests/test_dog_sleep.py`

```python
import unittest

import bpy

import dog
import dog_sleep
import lib


class TestDogSleep(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        lib.clear_scene()
        cls.objs = dog.build()
        cls.arm = cls.objs[0]

    def _z(self, name, tail=False):
        bpy.context.view_layer.update()
        pb = self.arm.pose.bones[name]
        return (self.arm.matrix_world @ (pb.tail if tail else pb.head)).z

    def test_sleep_action_exists_and_lasts_two_seconds(self):
        act = bpy.data.actions["sleep"]
        self.assertTrue(act.use_fake_user)
        self.assertGreaterEqual(act.frame_range[1] - act.frame_range[0], 40)
        self.assertIsNone(self.arm.animation_data.action, "активный action экспортёр теряет")

    def test_sleep_pose_lies_on_the_ground(self):
        dog_sleep.reset_pose(self.arm)
        up_root, up_head = self._z("Bone"), self._z("head")
        dog_sleep.apply_pose(self.arm)
        self.assertLess(self._z("Bone"), up_root * 0.5, "корпус опущен к земле")
        self.assertLess(self._z("head"), up_head * 0.65, "голова опущена")
        self.assertLess(self._z("head", tail=True), self._z("head"), "морда ниже затылка")
        for pb in self.arm.pose.bones:
            self.assertGreater((self.arm.matrix_world @ pb.tail).z, -0.02, f"{pb.name} под землёй")
        dog_sleep.reset_pose(self.arm)

    def test_sleep_clip_breathes(self):
        act = bpy.data.actions["sleep"]
        root_curves = [fc for layer in act.layers for strip in layer.strips for cb in strip.channelbags
                       for fc in cb.fcurves if fc.data_path == 'pose.bones["Bone"].location']
        self.assertEqual(len(root_curves), 3, "три канала location корня")
        v1 = sum(fc.evaluate(1) ** 2 for fc in root_curves) ** 0.5
        v24 = sum(fc.evaluate(24) ** 2 for fc in root_curves) ** 0.5
        self.assertGreater(abs(v1 - v24), v1 * 0.05, "на вдохе корпус выше: клип не статичный")

    def test_reset_pose_restores_rest(self):
        dog_sleep.apply_pose(self.arm)
        dog_sleep.reset_pose(self.arm)
        for pb in self.arm.pose.bones:
            self.assertAlmostEqual(pb.location.length, 0.0, places=5)
            self.assertEqual(tuple(round(c, 5) for c in pb.scale), (1.0, 1.0, 1.0))
```

## `tools/blender/tests/test_export.py`

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

## `tools/blender/tests/test_lib.py`

```python
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
```

## `tools/blender/tests/test_park_people.py`

```python
import unittest

import bpy
from mathutils import Vector

import human
import lib
import pigeon


def _actions():
    return {a.name for a in bpy.data.actions}


def _height(mesh):
    bpy.context.view_layer.update()
    c = [mesh.matrix_world @ Vector(x) for x in mesh.bound_box]
    return max(v.z for v in c) - min(v.z for v in c)


class TestParkPeople(unittest.TestCase):
    def test_roles_have_palette_colors_clips_and_height(self):
        for role, shirt in (("gardener", "sr_leaf"), ("kid", "sr_rarity_legendary"), ("guard", "sr_sea_deep")):
            lib.clear_scene()
            objs = human.build(role)
            mesh = objs[1]
            mats = [m.name for m in mesh.data.materials]
            self.assertIn(shirt, mats, role)
            self.assertIn("sr_cream", mats, f"{role}: кожа")
            used = {mesh.data.materials[p.material_index].name for p in mesh.data.polygons}
            self.assertGreaterEqual(len(used), 3, f"{role}: грани разнесены по ролям текстуры")
            self.assertTrue({"idle", "walk", "run", "work"} <= _actions(), role)
            self.assertAlmostEqual(_height(mesh), human.ROLES[role]["height"], delta=0.05)
            self.assertEqual(lib.check_asset(objs, max_tris=2500, max_dim=2.0), [])

    def test_humans_face_forward(self):
        lib.clear_scene()
        objs = human.build("gardener")
        d = human.forward_vector(objs[0])   # в позе клипа walk: по позе покоя модель смотрела вбок
        self.assertGreater(d.y, abs(d.x) * 3, "носки смотрят по +Y Blender (−Z Godot)")

    def test_pigeon(self):
        lib.clear_scene()
        objs = pigeon.build()
        self.assertTrue({"flap", "idle"} <= _actions())
        mats = {m.name for m in objs[1].data.materials}
        self.assertEqual(mats, {"sr_asphalt", "sr_sea_light", "sr_coral"})
        self.assertEqual(lib.check_asset(objs, max_tris=1500, max_dim=0.35), [])
```

## `tools/replay/build_files_md.py`

````python
#!/usr/bin/env python3
"""Собирает docs/replay/03-files.md: полное содержимое всех исходников проекта.
Запуск: make replay (или python3 tools/replay/build_files_md.py)."""
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "replay" / "03-files.md"

INCLUDE = [
    "CLAUDE.md", "Makefile", "project.godot", ".gutconfig.json", ".gitignore",
    "scenes/**/*.tscn", "scripts/**/*.gd", "tests/**/*.gd",
    "tools/blender/**/*.py", "tools/replay/*.py",
    "third_party/.gdignore", "third_party/*/README.md", "third_party/*/LICENSE.md",
    "third_party/unimate_clips/annotation.json",
    "docs/superpowers/specs/*.md", "docs/superpowers/plans/*roadmap.md",
    "docs/superpowers/notes/*.md",
    "export_presets.cfg", "tools/audio/*.py", "tools/release/*.sh", "tools/images/*.py", "tools/images/manifest.json", "assets/ui/*.tres", "assets/shaders/*.gdshader",
    "assets/sfx/README.md", "assets/fonts/OFL.txt",
    "tools/terrain/**/*.py", "data/terrain_src/*.json", "data/layout/*.json",
    "tools/layout/**/*.py", "data/layout_src/*.json",
]
EXCLUDE_DIRS = {"addons", "build", ".godot", ".superpowers"}
# Двоичные файлы (.ttf/.ogg/.wav/.glb/.png) в приложение не входят: откуда их взять (или как сгенерировать), описано в процедуре.
LANG = {".py": "python", ".gd": "gdscript", ".tscn": "", ".json": "json", ".md": "markdown",
        ".godot": "ini", "Makefile": "makefile", ".gitignore": "", ".gdignore": "",
        ".cfg": "ini", ".tres": "", ".gdshader": "glsl", ".txt": "", ".sh": "bash"}


def lang_for(p: pathlib.Path) -> str:
    if p.name == "Makefile":
        return "makefile"
    return LANG.get(p.suffix, "")


def main() -> None:
    files = []
    for pattern in INCLUDE:
        for p in sorted(ROOT.glob(pattern)):
            if p.is_file() and not (set(p.relative_to(ROOT).parts) & EXCLUDE_DIRS):
                files.append(p)
    seen, ordered = set(), []
    for p in files:
        if p not in seen:
            seen.add(p)
            ordered.append(p)
    lines = ["# Приложение: содержимое всех файлов проекта", "",
             "Сгенерировано `make replay` из текущего дерева. Не редактировать руками.",
             "Для каждого файла: путь относительно корня проекта и полное содержимое.",
             "Отступы в GDScript и Makefile — табы; в Python проекта — тоже табы, кроме",
             "`palette.py` и тестов Blender (пробелы). Копировать как есть.", "",
             f"Файлов: {len(ordered)}", ""]
    for p in ordered:
        rel = p.relative_to(ROOT).as_posix()
        text = p.read_text(encoding="utf-8")
        fence = "````" if "```" in text else "```"
        lines += [f"## `{rel}`", "", f"{fence}{lang_for(p)}", text.rstrip("\n"), fence, ""]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: {len(ordered)} файлов, {OUT.stat().st_size // 1024} КБ")


if __name__ == "__main__":
    sys.exit(main())
````

## `third_party/.gdignore`

```

```

## `third_party/crab_methodicalpixel/README.md`

```markdown
# Краб (CC0)

- Источник: [crab low poly animated 3d model](https://opengameart.org/content/crab-low-poly-animated-3d-model), автор methodical pixel.
- Лицензия: CC0 1.0 (http://creativecommons.org/publicdomain/zero/1.0/).
- Архив: https://opengameart.org/sites/default/files/crab_0.zip → `crab/crab.blend` (текстура и превью не нужны: краска — палитра проекта).
- Клипы: `idle` (48 кадров), `walk` (24 кадра); ноги на IK-костях, экспорт glTF запекает позы.
- Используется в `tools/blender/crab.py` (план 14: крабы на пляже порта).
```

## `third_party/pigeon_mujtaba/README.md`

```markdown
# Low poly 3D Pigeon (rigged + animated), автор mujtaba-io, CC0

Источник: https://opengameart.org/node/167919 — файл
`https://opengameart.org/sites/default/files/genuinely-my-pigeon-extended-furthur.blend` (здесь `pigeon.blend`, Blender 2.79).
Лицензия: CC0 («Copyright/Attribution Notice: CC0. You own it.»). Клипы: flap-wings-animation, idle-animation.
Используется в `tools/blender/pigeon.py`.
```

## `third_party/quaternius_animated_human/README.md`

```markdown
# Animated Human Low Poly (Quaternius), CC0

Источник: https://opengameart.org/content/animated-human-low-poly — архив
`https://opengameart.org/sites/default/files/Animated%20Human%20by%20%40Quaternius_0.zip`, файл `Blend/Animated Human.blend`
(здесь `AnimatedHuman.blend`) и его текстура-палитра `Blend/Textures/ClothedLightSkin2.png`. Лицензия CC0 (`LICENSE.txt`).
Клипы: Idle, Walk, Run, Working, Jump, Punch, Death. Используется в `tools/blender/human.py` (садовник, ребёнок, сторож).
```

## `third_party/unimate_clips/README.md`

````markdown
# Клипы кота, сгенерированные UniMate

UniMate (SIGGRAPH Asia 2026, код MIT: https://github.com/Friedrich-M/UniMate,
чекпоинт `unimate_uniml3d_f60_v3`, шаг 150000, https://huggingface.co/Linzhan/UniMate).
Исходный риг: CC0-кот Quaternius (`third_party/quaternius_animal_pack_v2/Cat.blend`),
экспортированный нашим `tools/blender/cat.py` первой версии.

- `cat_canonical.glb` — риг и меш после `rig_preprocess` (канонический кадр, 20 костей, IK удалены).
- `annotation.json` — ручная разметка суставов (автоматическая перепутала хвост и спину).
- `jump.glb`, `hide.glb`, `hit.glb`, `run.glb` — сгенерированные движения, применённые к каноническому ригу.

Воспроизведение (Mac, CPU, Python 3.10 через uv):
```
python -m data_process.rig_preprocess run --input cat.glb --output_dir outputs/rig/cat --profile general --annotation annotation.json
python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 --asset outputs/rig/cat \
    --prompt "An object jumps in place." --num_repetitions 2 --output_dir outputs/samples/cat --only_save_motion
bash scripts/run_animate_motion.sh outputs/samples/cat      # blender в PATH = venv python с pip-модулем bpy
```
В `config.json` чекпоинта `sampling.device` заменён на `cpu` (MPS не поддерживает float64 в torchdiffeq).
Сгенерированные движения — результат нашей работы над CC0-ассетом; код UniMate под MIT.
````

## `third_party/quaternius_animal_pack_v2/LICENSE.md`

```markdown
# Animal Pack Vol.2 by Quaternius

Источник: https://opengameart.org/content/animated-animales-low-poly
Автор: Quaternius (https://quaternius.com)
Лицензия: CC0 1.0 Universal (public domain). Указание авторства не требуется, но мы указываем его в титрах.
Файлы: Cat.blend, Dog.blend (меш, арматура 24 кости, клипы Idle и Walking).
```

## `third_party/unimate_clips/annotation.json`

```json
{
 "format": "rig_preprocess-annotation/1",
 "asset": "cat",
 "notes": [
  "joint 'Bone.011' translates by 5.3% of the skeleton in 'cat-walk'; the model keeps rotations and the root path only"
 ],
 "face_pair": {
  "right": "Bone.011",
  "left": "Bone.008",
  "body_axis": false,
  "source": "thigh",
  "check": false
 },
 "face_pair_alternatives": [
  [
   "Bone.017",
   "Bone.014",
   "Thigh"
  ],
  [
   "Bone.018",
   "Bone.015",
   "Shin"
  ],
  [
   "Bone.019",
   "Bone.016",
   "Foot"
  ]
 ],
 "n_flagged": 0,
 "joints": [
  {
   "index": 0,
   "raw": "Bone",
   "parent": null,
   "label": "Hips",
   "source": "rule",
   "check": false
  },
  {
   "index": 1,
   "raw": "Bone.001",
   "parent": "Bone",
   "label": "Spine",
   "source": "rule",
   "check": false
  },
  {
   "index": 2,
   "raw": "Bone.002",
   "parent": "Bone.001",
   "label": "Neck",
   "source": "rule",
   "check": false
  },
  {
   "index": 3,
   "raw": "head",
   "parent": "Bone.002",
   "label": "Head",
   "source": "names",
   "check": false
  },
  {
   "index": 4,
   "raw": "Bone.014",
   "parent": "Bone.001",
   "label": "Right Front Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 5,
   "raw": "Bone.015",
   "parent": "Bone.014",
   "label": "Right Front Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 6,
   "raw": "Bone.016",
   "parent": "Bone.015",
   "label": "Right Front Paw",
   "source": "rule",
   "check": false
  },
  {
   "index": 7,
   "raw": "Bone.017",
   "parent": "Bone.001",
   "label": "Left Front Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 8,
   "raw": "Bone.018",
   "parent": "Bone.017",
   "label": "Left Front Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 9,
   "raw": "Bone.019",
   "parent": "Bone.018",
   "label": "Left Front Paw",
   "source": "rule",
   "check": false
  },
  {
   "index": 10,
   "raw": "Bone.004",
   "parent": "Bone",
   "label": "Tail",
   "source": "rule",
   "check": false
  },
  {
   "index": 11,
   "raw": "Bone.005",
   "parent": "Bone.004",
   "label": "Tail",
   "source": "rule",
   "check": false
  },
  {
   "index": 12,
   "raw": "Bone.006",
   "parent": "Bone.005",
   "label": "Tail",
   "source": "rule",
   "check": false
  },
  {
   "index": 13,
   "raw": "Bone.007",
   "parent": "Bone.006",
   "label": "Tail End",
   "source": "rule",
   "check": false
  },
  {
   "index": 14,
   "raw": "Bone.008",
   "parent": "Bone",
   "label": "Left Hind Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 15,
   "raw": "Bone.009",
   "parent": "Bone.008",
   "label": "Left Hind Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 16,
   "raw": "Bone.010",
   "parent": "Bone.009",
   "label": "Left Back Paw",
   "source": "rule",
   "check": false
  },
  {
   "index": 17,
   "raw": "Bone.011",
   "parent": "Bone",
   "label": "Right Hind Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 18,
   "raw": "Bone.012",
   "parent": "Bone.011",
   "label": "Right Hind Leg",
   "source": "rule",
   "check": false
  },
  {
   "index": 19,
   "raw": "Bone.013",
   "parent": "Bone.012",
   "label": "Right Back Paw",
   "source": "rule",
   "check": false
  }
 ],
 "vocabulary": {
  "format": "[Left |Right ][Qualifier ]Part[ End], e.g. 'Left Front Leg', 'Right Index Finger End'. Qualifier: Front, Back, Middle, Rear, Hind, Inner, Outer, Upper, Lower. No numbers: every joint of a chain takes the same label (Spine, Spine, Spine; Tail, Tail), its last joint 'End' ('Tail End'). 'Bone' only for a joint that is no body part.",
  "parts": [
   "Abdomen",
   "Anal Fin",
   "Ankle",
   "Antenna",
   "Appendage",
   "Arm",
   "Back Claw",
   "Back Hip",
   "Back Paw",
   "Bag",
   "Barbel",
   "Base",
   "Belly",
   "Belt",
   "Body",
   "Bone",
   "Branch",
   "Cannon",
   "Cape",
   "Caudal Fin",
   "Center",
   "Chain",
   "Cheek",
   "Chest",
   "Chin",
   "Claw",
   "Cloth",
   "Collar",
   "Crest",
   "Door",
   "Dorsal Fin",
   "Dorsal Plate",
   "Ear",
   "Elbow",
   "Elbow Back",
   "End",
   "Eye",
   "Eyeball",
   "Eyebrow",
   "Eyelid",
   "Fang",
   "Feather",
   "Fetlock",
   "Fin",
   "Finger",
   "Foot",
   "Forearm",
   "Forearm Twist",
   "Front Hoof",
   "Front Leg",
   "Front Leg End",
   "Front Paw",
   "Front Shoulder",
   "Fur",
   "Gill",
   "Hair",
   "Halter",
   "Hand",
   "Hand Claw",
   "Handle",
   "Hat",
   "Head",
   "Head End",
   "Heel",
   "Hind Leg",
   "Hind Leg End",
   "Hip",
   "Hips",
   "Hoof",
   "Horn",
   "IK Chain",
   "Index Finger",
   "Inner Claw",
   "Inner Finger",
   "Inner Hand Claw",
   "Inner Toe",
   "Jaw",
   "Jiggle",
   "Knee",
   "Large Mandible",
   "Leaf",
   "Leg",
   "Lever",
   "Lid",
   "Lip",
   "Lower Body",
   "Lower Eyelid",
   "Lower Front Lip",
   "Lower Jaw",
   "Lower Left Lip",
   "Lower Lip",
   "Lower Mandible",
   "Lower Right Lip",
   "Mandible",
   "Mane",
   "Metacarpus",
   "Middle Claw",
   "Middle Finger",
   "Middle Hand Claw",
   "Middle Leg",
   "Middle Leg End",
   "Middle Toe",
   "Mouth",
   "Muzzle",
   "Neck",
   "Neck Muscle",
   "Nose",
   "Outer Claw",
   "Outer Finger",
   "Outer Hand Claw",
   "Outer Toe",
   "Palm",
   "Pastern",
   "Paw",
   "Pectoral Fin",
   "Pelvic Fin",
   "Pelvis",
   "Petal",
   "Phalanges",
   "Pincer",
   "Pinky Finger",
   "Prop",
   "Propeller",
   "Rear Hoof",
   "Reins",
   "Ribcage",
   "Ring Finger",
   "Root",
   "Rope",
   "Scapula",
   "Scarf",
   "Shell",
   "Shield",
   "Shin",
   "Shin Twist",
   "Shoulder",
   "Skirt",
   "Skull",
   "Skull Base",
   "Spine",
   "Stem",
   "Stinger",
   "Strap",
   "Tail",
   "Tail Twist",
   "Tentacle",
   "Thigh",
   "Thigh Muscle",
   "Thigh Twist",
   "Thumb Finger",
   "Toe",
   "Toe End",
   "Tongue",
   "Twist",
   "Upper Arm",
   "Upper Arm Twist",
   "Upper Body",
   "Upper Eyelid",
   "Upper Jaw",
   "Upper Left Lip",
   "Upper Lip",
   "Upper Right Lip",
   "Waist",
   "Weapon",
   "Wheel",
   "Whisker",
   "Wing",
   "Wrist",
   "Wrist Back"
  ]
 }
}
```

## `docs/superpowers/specs/2026-10-07-snack-run-design.md`

````markdown
# Snack Run — дизайн-спек (визуальная библия + игровой цикл)

Дата: 2026-10-07. Статус: на ревью.
Референсы: `reference/keyart_pizza_chase.png`, `reference/map_world.png`, `reference/artboard_assets.png`.

## 0. Зачем и что считается успехом

Игра делается для ролика на YouTube-канале «Нейрослоп»: показать вайб-кодинг 3D-игры с
Blender и Godot. Успех этапа 1 — играбельный вертикальный срез, который
целиком показывает игровой цикл, выглядит цельно и красиво в кадре и собирается
воспроизводимо (ассеты и сцена генерируются скриптами, а не руками).

Вне этапа 1 (сознательно отложено): смена суток, районы кроме первого, случайные
события, озвучка и музыка кроме 6 базовых звуков, мобильные платформы, сохранения в облако.

## 1. Концепт

**Snack Run.** Маленький котёнок, большой приморский город, вкусные приключения.
Открытый мир из районов, вид от третьего лица, кот собирает вкусняшки и избегает
городских опасностей.

Три столпа дизайна (любое решение сверяется с ними):

1. **Жадность против страха.** Еда не считается собранной, пока её не съели в
   укрытии. Чем больше несёшь в зубах, тем больше теряешь при ударе.
2. **Город глазами кота.** Камера низко, бордюры и столы огромные, укрытия везде:
   под машиной, в коробке, под лавкой.
3. **Уют.** Никто не умирает. Удар, писк, еда разлетелась, кот отлетел. Формы
   круглые, цвета тёплые.

## 2. Визуальная библия

### 2.1 Стиль

Стилизованный лоуполи с мягкими скруглёнными формами. Цвет задаётся
материалами из палитры (без рисованных текстур). Освещение тун: 2–3 ступени тона
плюс тонкая тёмная обводка. Референс ощущения: `keyart_pizza_chase.png`.
Референс техники: Untitled Goose Game, A Short Hike.

Правила формы:

- Все углы со скосом (bevel) 2–3 сегмента, ничего острого.
- Еда крупнее реалистичной в 1,5 раза, чтобы читалась на видео.
- Пропорции кота «чиби»: голова ≈ 40% длины тела, короткие лапы, большие глаза.
- Пропсы слегка «надутые»: бочки и баки шире к середине, коробки чуть выпуклые.
- Полигонаж: пропс 100–800 треугольников, кот до 2500, здание до 3000.

### 2.2 Палитра

Сняты скриптом с цветовой полосы `artboard_assets.png` (строка y=975).

| Роль                      | Hex       |
|---------------------------|-----------|
| Оранжевый кота            | `#FAAE45` |
| Сливочный (грудка, лапы)  | `#FCD3A1` |
| Песочный (тротуар, стены) | `#D3AB87` |
| Оливковый (кусты, тень)   | `#A9B087` |
| Зелёный (листва)          | `#458B59` |
| Глубокий синий (море)     | `#1D7FC4` |
| Бирюза (вода у берега)    | `#2F9CCF` |
| Небесный (небо, UI-акцент)| `#659ECF` |
| Сиреневый (вывески, цветы)| `#B46DB5` |
| Коралловый (ошейник, тенты)| `#F57485` |
| Кирпичный (крыши, машины) | `#BD4045` |
| Графит (асфальт)          | `#5A5C6B` |
| Тёмный графит (обводка, тени) | `#394151` |

Редкости (по артборду, стандартная игровая конвенция; версия с карты отвергнута):

| Редкость     | Hex       | Доля спавна |
|--------------|-----------|-------------|
| Обычная      | `#4D945B` | 60%         |
| Редкая       | `#6491E4` | 25%         |
| Очень редкая | `#C473D4` | 12%         |
| Легендарная  | `#FABE32` | 3%          |

Цвет редкости используется для свечения-подложки под едой, рамки в альбоме и
частиц при съедании.

### 2.3 Свет, камера, пост-обработка

- Базовое время: солнечный полдень. Один `DirectionalLight3D` (тёплый
  `#FFF1D6`, энергия 1,0, угол 50°), `WorldEnvironment` с голубым ambient
  `#9FC4E8` энергии 0,45 и мягким небом градиентом небесный → сливочный у
  горизонта. Тонмаппинг линейный: Filmic выцветает палитру.
- Тени включены, мягкие (PCF), только от ключевого света.
- Тун-шейдинг: `StandardMaterial3D` с `diffuse_mode = Toon`,
  `specular_mode = Toon`, обводка через инвертированный hull (параметр `grow` у второго
  `StandardMaterial3D` с `cull_mode = Front`; толщина в метрах: 0,006 м для
  кота и опасностей, 0,004 м для еды; 0,02 м на 35-сантиметровом коте рвёт
  hull на рёбрах лоуполи, проверено на реализации);
  на пропсах обводки нет, чтобы не шуметь.
- Камера: третье лицо, `SpringArm3D`, высота взгляда 0,6 м, дистанция 1,8 м,
  наклон −14°, FOV 60°, сглаживание следования 8/сек. В укрытии камера
  опускается до 0,3 м. (Исходные 3,5 м давали кота в 4% кадра, поправлено по
  скриншотам реализации.)
- Пост-обработка: лёгкая виньетка, без bloom.

### 2.4 Персонаж

Рыжий котёнок (`#FAAE45`), белая грудка и лапы (`#FCD3A1`), розовые уши и нос,
красный ошейник (`#F57485`) с золотым жетоном. Глаза большие, зелёные.

Эмоции: 4 выражения глаз на одной плоскости лица через смену материала:
обычные, испуг (в режиме преследования), довольный (при съедании, 1 с),
оглушён (спирали, 1 с после удара).

Скины (магазин): рыжий (по умолчанию), чёрный с белой грудкой, серый полосатый,
сиамский. Скин = набор из 3 цветов материалов, меш один.

### 2.5 Опасности (этап 1)

- **Собака** (корги по `keyart`): рыжая с белым, 600–900 треугольников.
  Состояния видны по позе: спит (лежит), насторожилась (уши вверх), бежит.
- **Оса**: жёлто-чёрная, крупная (30 см), крылья плоскостями с мерцанием
  прозрачности. Кружит по кругу радиусом 2–3 м.
- **Велосипедист**: человек-капсула с шлемом на велосипеде, едет по сплайну
  дороги, звонит в звонок за 2 с до появления.

### 2.6 UI

Округлые белые плашки с мягкой тенью и тёмным графитовым текстом (как подписи
на карте). Шрифт: Nunito (SIL OFL). Элементы в игре: сердечки (3 слева вверху),
полоска сытости под ними, слот «в зубах» (до 3 иконок еды) справа вверху, счётчик
клубочков. Альбом: сетка карточек по редкостям, неоткрытые серые силуэты.

### 2.7 Звук (минимум этапа 1)

6 эффектов: подбор еды, съедание, удар, писк кота, лай, звонок велосипеда.
Источники: CC0 (Kenney Audio, freesound CC0). Музыки в этапе 1 нет.

### 2.8 Визуальная полировка (план 5, решения владельца 2026-10-09)

Цель: кадр как на `keyart_pizza_chase.png` — круглый пушистый котёнок с большими
зелёными глазами в глазницах, яркий солнечный день, живой двор. Стиль остаётся
плоскоцветным лоуполи с туном; «шерсть» — силуэтом и пучками, не прядями.

**Кот (облагораживаем модель Quaternius, клипы не трогаем).**
- Сглаживание: один уровень subdivision при экспорте, smooth-шейдинг; бюджет
  кота поднимается до 6000 треугольников (вместо 2500).
- Глаза: белок — эллипсоид радиуса 14 мм, сплюснутый по оси взгляда до 0,55 и
  утопленный в голову на 40% (снаружи линзовидный выступ ≤ 3 мм); радужка
  зелёная `#6FA04A` (новый цвет палитры `eye_green`), зрачок `#394151`, блик
  `#F4F1E8`; веко — козырёк цвета тела над глазом. Наборы: обычные, испуг,
  довольный, оглушён, моргание; моргание каждые 3–5 с на 0,12 с поверх
  обычного выражения. Глаза без обводки.
- Пучки шерсти (кремовые, smooth): щёчные кисточки по 3 конуса с каждой
  стороны, грудка-манишка, кончик хвоста; усы — по 3 белых цилиндра
  (радиус 0,8 мм, длина 35 мм) с каждой стороны морды; ошейник — коралловый
  тор на шее с золотым жетоном (`rarity_legendary`). Всё скинится к ближайшей
  кости весом 1,0.
- «Чиби»-лапы: модификатор скелета укорачивает четыре верхние кости лап
  равномерно в 0,8 раза и опускает корень на 20% высоты ноги; клипы прежние.
- Силуэт: обводка персонажей — шейдер инвертированного hull с шумом ширины
  ±25% (частота 40 на единицу UV), ширина 0,006 м; rim-свет в тун-материале
  (`rim 0,5`, `rim_tint 0,6`) у кота, собаки, осы, велосипедиста. У еды и
  пропсов обводка без шума, без rim.
- Хвост покачивается процедурно поверх клипа (синус ±7°, 2,5 Гц, по костям
  со сдвигом фазы).

**Свет, небо, пост (яркий день по референсу).**
- Солнце: 65° к горизонту, азимут 30°, цвет `#FFF1D6`, энергия 1,2; мягкие
  тени: `light_angular_distance 1,5°`, `shadow_blur 1,5`, 4 каскада на 30 м.
- Заполняющий свет: второй `DirectionalLight3D` с противоположной стороны
  (−65°, 210°), цвет неба `#9FC4E8`, энергия 0,25, без теней.
- Ambient от неба, энергия 0,6; SSAO (радиус 0,3, интенсивность 1,5); SSR
  для луж; glow слабый (интенсивность 0,4, порог HDR 1,2) — ограниченное
  отклонение от «без bloom»; насыщенность +10% через adjustments; тонмаппинг
  линейный.
- Небо: `ProceduralSkyMaterial` (верх `#4A9BE0`, горизонт `#CFE6F8`) и слой
  облаков `sky_cover` из сгенерированной картинки.
- Лужи: `roughness 0,05`, `metallic 0`, отражают небо через SSR.

**VFX и «жизнь».**
- Кот: сквош-стретч модели (прыжок 0,85×1,15, приземление 1,2×0,8 на 0,12 с),
  пыль при приземлении и каждые 0,25 с бега (песочная, 12 частиц); вспышка
  белым на 0,1 с и тряска камеры (0,05 м, 0,2 с) при ударе; сердечки при
  съедании (спрайты сгенерированной иконки).
- Еда редкости ≥ редкая: постоянные искры цвета редкости. Оса: серый шлейф.
  Велосипедист: пыль за колесом. Собака в IDLE: всплывающие «z».
- Двор: листья, плывущие по ветру (40 частиц на 30×30 м).

**Мир.**
- Зелень: кусты вдоль стен, трава пучками (`grass.py`), плющ на фасаде
  (`ivy.py`). Декали на асфальт (люк, трещины, листья) и плакаты на стены —
  квады с текстурами из сгенерированных картинок, список `decals` в раскладке.

**Картинки (исключение из правила «только скрипты Blender», решение владельца).**
- Генератор: OpenAI Images API, модель `gpt-image-2.5` (`sunburst` для крупных
  артов, `flare` для иконок), ключ только из `OPENAI_API_KEY`. Скрипт
  `tools/images/gen.py` и манифест `tools/images/manifest.json` (файл → промпт →
  размер); `make images` генерирует только отсутствующие файлы. PNG коммитятся
  в `assets/images/`; при воспроизведении результат похож, но не идентичен.
- Набор: 8 иконок еды (альбом и слоты «в зубах»), сердечко (частицы), фон
  заставки 1536×1024, 3 плаката, облака (прозрачные), 3 декали. В 3D-ассеты
  картинки не идут, кроме неба и декалей.

### 2.9 Текстуры крупных поверхностей (решение владельца 2026-10-09, «гибрид»)

Отступление от 2.1 «без рисованных текстур» для крупных плоскостей, которые без текстуры читаются как
цветные кубики. Пол двора (асфальт), тротуар (плитка) и стены домов (штукатурка с проглядывающим
кирпичом) получают бесшовные мультяшные текстуры из сгенерированных картинок (манифест
`tools/images/manifest.json`, папка `assets/images/textures/`) в цветах палитры. Мелкие пропсы, еда и
персонажи остаются плоскоцветными с тун-светом, как в Untitled Goose Game.

- Наложение — трипланарная проекция по мировым координатам (`uv1_triplanar`, `uv1_world_triplanar`):
  UV-развёртка мешей не нужна, плитка непрерывна через стыки модулей стены.
- Размер тайла в метрах: асфальт 4 м, плитка тротуара 1,2 м (16 плиток по 0,3 м — соразмерно котёнку), штукатурка 4,5 м (кирпич проглядывает реже).
- Тун-диффуз сохраняется, `albedo_color` белый (цвет несёт текстура), мипмапы и сжатие VRAM включены.
- Таблица «меш → текстура» живёт в коде (`SurfaceTextures`), применяется к району в `Main._ready`.

## 3. Игровой цикл

### 3.1 Момент-к-моменту (10–30 с)

Заметил еду → оценил окружение (собака спит? оса кружит? дорога?) → подкрался
или пробежал → схватил (еда «в зубах», максимум 3, в магазине до 5) → добежал
до укрытия → съел. Только съеденная еда даёт прогресс.

Управление: WASD/стик — движение, Shift/RT — бег, Space/A — прыжок (на бак,
лавку, стол), Ctrl/B — присесть и войти в укрытие, E/X — съесть в укрытии.
Еда подбирается касанием.

### 3.2 Опасности и их поведение

Каждая опасность работает по своей схеме, чтобы цикл не повторялся:

| Опасность    | Схема           | Поведение                                                                 |
|--------------|-----------------|---------------------------------------------------------------------------|
| Собака       | Преследование   | Спит у точки. Конус зрения 90°, 6 м. Заметила → 1 с «насторожилась» → бег 1,2× скорости кота. Теряет след, если кот в укрытии 2 с, или через 8 с погони (устаёт). Возвращается спать. Убежать нельзя, только спрятаться. |
| Оса          | Зона            | Кружит вокруг «сладкой» еды (пончик, мороженое). Касание = удар. Не преследует. |
| Велосипедист | Маршрут         | Едет по сплайну дороги с интервалом 12–20 с, звонок за 2 с. Сбивает на дороге. |

Удар: еда из зубов разлетается на 1–2 м (лежит 5 с, можно подобрать снова),
минус 1 сердечко, кот отлетает на 1,5 м и оглушён 1 с (неуязвим 2 с).
Ноль сердечек: затемнение, кот просыпается в магазине пряжи с полными
сердечками; еда в зубах потеряна. Съедание восстанавливает 1 сердечко.

### 3.3 Еда и редкости

Точки спавна привязаны к местам: обычная еда у баков и лавок, редкая у кафе
и на балконе двора (одна точка, чтобы в закрытом дворе была не только обычная
еда), очень редкая на столах кафе, легендарная рядом с опасностью (у спящей
собаки, под осой). Респавн 30–90 с, в точке спавна случайная еда по весам
редкости.

Допущение по балансу (проверить на плейтесте): до открытия арки игроку нужно
≈ 10 сытости, то есть 7–10 подборов во дворе, что должно занимать 2–3 минуты.
Если дольше, снижаем порог арки до 6.

Этап 1, 8 видов: сосиска, печенье (обычные); пицца, хот-дог (редкие);
круассан, рыба (очень редкие); пончик, мороженое (легендарные).

### 3.4 Прогрессия

- **Альбом вкусняшек**: главная ось. Первая съеденная еда каждого вида открывает
  карточку. 100% района = медаль района.
- **Сытость**: накопительная шкала от съеденного (обычная 1, редкая 3, очень
  редкая 6, легендарная 15). Открывает ворота районов. Этап 1: арка в кафе
  открывается при сытости 10.
- **Клубочки**: валюта. Лежат в труднодоступных местах (крыша бака, балкон,
  под лестницей), 10–15 на район, респавна нет. Плюс 3 клубочка за каждую новую
  карточку альбома.

### 3.5 Безопасная зона: магазин пряжи

Хаб-интерьер у входа в район, опасности туда не заходят. Пока открыт экран
магазина, на фоне сам котёнок игрока в idle-режиме играет с клубочками: катает
их лапой, прыгает за ними (отдельных NPC нет). Это экран магазина и
одновременно точка возрождения.

Ассортимент за клубочки:

| Категория | Товар                                   | Цена |
|-----------|-----------------------------------------|------|
| Сердечки  | Восстановить все                        | 2    |
|           | +1 максимум (до 5)                      | 8, 15 |
| Улучшения | Вместимость зубов 3 → 4 → 5             | 6, 12 |
|           | Бег быстрее на 15%                      | 10   |
|           | Тише шаги: конус собаки −30%            | 10   |
| Скины     | Чёрный, серый полосатый, сиамский       | 12 каждый |

Купленное сохраняется между сессиями (локальное сохранение JSON).

### 3.6 Сессия (3–5 мин) и цель

На старте показана цель: «Открой N новых карточек» (N = 3 для первого захода).
Выполнил → салют и новая цель. Сессия не ограничена временем.

## 4. Этап 1: содержание вертикального среза

- **Локация** ≈ 60×60 м: жилой двор (баки, подъезды, припаркованные машины,
  лавки, лестница на балкон) → арка → уличное кафе (столы, зонты, вывеска,
  дорога с велосипедистом вдоль кафе). Магазин пряжи в углу двора.
- **Еда**: 8 видов из 3.3. **Опасности**: собака, оса, велосипедист.
- **Укрытия**: картонная коробка, под припаркованной машиной, под лавочкой.
- **Пропсы** (≈22): бак, урна, коробка, мешок мусора, ящик, лавка, фонарь,
  машина (2 цвета), стол кафе, стул, зонт, клумба, лестница, лужа, дерево, куст,
  стена с окнами (модуль), арка, забор, дверь подъезда, вывеска кафе, витрина
  магазина пряжи.
- **Экраны**: заставка, игра (HUD), альбом, магазин, пауза.

## 5. Архитектура

### 5.1 Godot 4.7.2 (GDScript)

```
snack_run/
  project.godot
  scenes/
    main.tscn            # загрузчик: меню → мир
    world/district_yard.tscn
    player/cat.tscn
    hazards/{dog,wasp,cyclist}.tscn
    food/food_pickup.tscn  # один сценарий, вид задаётся ресурсом
    hideouts/hideout.tscn
    shop/yarn_shop.tscn
    ui/{hud,album,shop,pause}.tscn
  scripts/
    autoload/game_state.gd   # сердечки, сытость, альбом, в зубах, клубочки
    autoload/save.gd         # JSON в user://
    player/cat_controller.gd # состояния idle/walk/run/jump/hide/stunned
    hazards/hazard_base.gd   # FSM idle/alert/chase/return
    food/food_resource.gd    # Resource: id, редкость, сытость, модель
  data/
    food/*.tres  hazards/*.tres  shop/*.tres  skins/*.tres
  assets/models/*.glb  assets/audio/*.ogg  assets/fonts/
  tools/blender/           # генераторы ассетов
  tests/                   # GUT
```

Принципы: данные еды, товаров и скинов в `.tres`, не в коде. Опасности
наследуют `hazard_base.gd` и переопределяют только восприятие и движение.
Сигналы вместо прямых ссылок: `food_eaten`, `cat_hit`, `hearts_changed`.

### 5.2 Пайплайн Blender 5.2.2

Всё генерируется Python-скриптами (`bpy`), запуск `blender -b --python`.

- `tools/blender/palette.py` — палитра из 2.2 как материалы.
- `tools/blender/lib.py` — примитивы: скруглённый бокс, цилиндр, «надутая» форма,
  bevel, назначение материала, проверка полигонажа.
- `tools/blender/props/*.py` — по скрипту на пропс или группу.
- `tools/blender/food.py`, `hazards.py`, `cat.py`, `world_yard.py`.
- `tools/blender/export.py` — glTF: 1 ед. = 1 м, +Y вверх, применить
  трансформации, имя файла = имя сцены, в `assets/models/`.
- `make assets` пересобирает всё; каждый ассет проверяется (полигонаж в
  лимите, размер по габаритам, материалы только из палитры).

### 5.3 Кот и анимации

Правило: сначала готовое из интернета, генерируем только то, чего нет.

- **База**: Quaternius «Animal Pack Vol.2» (CC0, OpenGameArt). Проверено:
  кот (402 грани, 24 кости, клипы Idle и Walking по 40 кадров) и собака (302
  грани, 24 кости, Idle и Walking) открываются в Blender 5.2.2.
- Скриптом кот перепропорционируется в котёнка (масштаб костей головы/лап,
  палитра материалов, ошейник), рига не меняется, Idle/Walk сохраняются.
- **Недостающие клипы** Run, Jump, Hide, Hit, в порядке «сначала готовое»:
  1. UniMate (SIGGRAPH Asia 2026, код MIT, чекпоинт на Hugging Face;
     исследовательский релиз, авторы предупреждают о сбоях). Лимит 1 час.
  2. Другие бесплатные источники с подходящей лицензией (CC0/CC-BY):
     OpenGameArt, poly.pizza, itch.io «name your price» за 0 $ (например,
     `lowpoly-cat-running` с клипом Run, FBX). Ретаргет на риг Quaternius не
     проверен, лимит 2 часа. Платные паки исключены решением владельца.
  3. Последний вариант: генерируем `bpy`-скриптом (Run = Walk с удвоенной
     частотой и увеличенной амплитудой, Jump и Hit = траектория корневой кости
     + сквош позвоночника, Hide = поза Idle с опущенным корнем).
- Собака: Quaternius Idle/Walking, Run = ускоренный Walk.

### 5.4 Тестирование

- GUT: `GameState` (подбор, потеря еды при ударе, сердечки, сытость, покупка),
  веса редкостей, сохранение/загрузка.
- Скриншоты сцены: запуск Godot из CLI с обычным рендерером и аргументом
  `--screenshot <путь>`, который обрабатывает наш скрипт (`get_viewport()
  .get_texture().get_image().save_png()` через 2 кадра после загрузки, затем
  выход). `--headless` не подходит: он использует пустой рендерер и кадров не
  даёт.
- Проверка ассетов в `make assets` (см. 5.2).
- Ручной прогон цикла: собрать 3 еды, довести до укрытия, съесть, попасть под
  собаку, потерять еду, купить сердечко.

## 6. Дальнейшие этапы (не в этом спеке)

Этап 2: парк и смена суток. Этап 3: порт, пляж, чайка и вода. Этап 4:
случайные события и дворовые коты. Каждый этап — отдельный спек и план.
````

## `docs/superpowers/specs/2026-10-09-snack-run-scale-terrain-design.md`

```markdown
# Snack Run: масштаб ×3 и рельеф (спек)

Решения владельца 2026-10-09: «все районы плоские и мелкие» — увеличить **втрое по стороне** и сделать рельефными:
**террасы и лестницы, плавные холмы, крыши и вертикаль** (все три); **сначала двор и парк, потом порт** (этап 3 строится
сразу по этим правилам). Основной спек и спеки этапов 2–3 остаются в силе, кроме размеров и пола.

## 1. Размеры

| Район | Было | Станет | Бегом насквозь (4 м/с) |
|---|---|---|---|
| Двор с кафе | 60×60 м | 180×180 м | ~45 с |
| Парк | 30×32 м | 90×96 м | ~24 с |
| Порт (этап 3) | 40×34 м | 120×102 м | ~30 с |

Кот, люди, пропсы, скорости и камера не масштабируются: мир становится больше, а не крупнее.

## 2. Плотность и зоны

Чтобы площадь ×9 не стала пустой, район делится на **зоны** 25–40 м со своим характером, связанные дорожками,
лестницами и проходами. Контент ×4–5 (не ×9): между зонами — «проходные» участки с редкой едой и укрытиями.

- **Двор (180×180)**: 4 зоны — старый двор (нынешний, ядро), гаражи с крышами (паркур), детская площадка на террасе,
  верхний двор у домов на холме (2–3 м выше) с балконами; дальше улица с велосипедистом и кафе (кафе ×1,5, летняя
  веранда на террасе). Дома — модули стен по периметру зон, проходы-арки между ними.
- **Парк (90×96)**: холмистый: центральная поляна с фонтаном, холм с беседкой (+3 м), пруд в низине (вода — правила
  этапа 3), площадка у подножия, аллея по склону, лесок.
- Количество (ориентир): двор — 60 точек еды, 40 клубочков, 25 укрытий, опасностей ×3 (3 собаки, 4 осы, 2 велосипедиста);
  парк — 35 точек еды, 25 клубочков, опасностей ×2.

## 3. Рельеф

- **Карта высот** района — сетка 1 м, генерируется скриптом из описания (холмы — гауссовы купола, террасы — плато с
  обрывом, низины). Из неё: меш пола (Blender-скрипт, ≤ 40 000 треугольников на район, тайлы 30×30 м для отсечения)
  и коллизия `HeightMapShape3D` той же сетки (точное совпадение).
- **Террасы**: перепады 1–3 м; обрыв закрыт подпорной стенкой (модуль, текстура камня), подъём — лестницы (модуль,
  ступень 0,15 м — кот поднимается) и пандусы ≤ 25°. С края террасы можно спрыгнуть (кот не получает урона).
- **Холмы**: склоны ≤ 30° (кот ходит, `floor_max_angle` 40°), на вершинах — достопримечательности.
- **Крыши и вертикаль**: гаражи, навесы, сараи, киоски, автобусные остановки — с плоскими крышами, на которые можно
  запрыгнуть по ящикам/бакам/заборам (цепочки прыжков ≤ 0,8 м по высоте). На крышах — клубочки и редкая еда.
- **Пропсы встают на поверхность**: `WorldBuilder` берёт высоту из карты (`y` в раскладке — смещение над землёй;
  `"snap": false` — абсолютная высота). Опасности и точки спавна — так же.
- Текстуры пола по уклону и высоте (спек 2.9): трава на склонах, плитка/асфальт на плоском, камень на обрывах — смешение
  в шейдере по нормали.

## 4. Раскладка

- Ручная расстановка 300+ пропсов неприемлема. **Генератор раскладки** (`tools/layout/`, Python): описание района
  (зоны, достопримечательности, дорожки, правила плотности) → `data/layout/*.json` и `heightmap`. Детерминирован
  (seed), инварианты из тестов раскладки проверяются и самим генератором.
- Ключевые места (будка пряжи, ворота, кафе, старт) — фиксированы в описании.

## 5. Технические рамки

- Производительность mac-билда: ≥ 60 к/с на M4 в развёрнутом окне. Отсечение по видимости (тайлы пола, `visibility_range`
  у мелких пропсов 40 м), фонари — `SpotLight3D` без теней с `distance_fade` 35 м.
- Тени солнца — каскады на 40 м (было 30).
- Камера не меняется; пружина упирается в рельеф (уже работает).

## 6. Тестирование

- Карта высот: юнит-тесты генератора (высота в точке, совпадение меша и коллизии, уклоны ≤ 30° вне обрывов).
- Инварианты раскладки на больших районах (спавны/клубочки/укрытия на поверхности и не в пропсах, крыши достижимы
  цепочкой прыжков — проверка графом высот).
- Кот на склоне не скользит, по лестнице поднимается, с террасы спрыгивает (интеграционные).
- Кадры зон днём и ночью.

## 7. Разбивка на планы

- **План 10. Рельеф**: карта высот, меш и коллизия, привязка пропсов к поверхности, подпорные стены, лестницы, пандусы,
  шейдер пола по уклону.
- **План 11. Генератор раскладки и двор ×3**: зоны двора, гаражи и крыши, терраса с площадкой, верхний двор, кафе с верандой.
- **План 12. Парк ×3**: холмы, пруд, беседка, лесок, аллея по склону; опасности парка по зонам.
- Затем этап 3 (порт 120×102) планами 13–15.
```

## `docs/superpowers/specs/2026-10-09-snack-run-stage2-park-design.md`

```markdown
# Snack Run, этап 2: парк и смена суток (спек)

Продолжение `2026-10-07-snack-run-design.md` (основной спек остаётся источником истины по стилю,
управлению, прогрессии и архитектуре). Решения владельца 2026-10-09: опасности парка — голуби-воришки,
садовник со шлангом, дождеватели газона, ребёнок, который хочет погладить; цикл суток ≈ 5 мин меняет
правила; парк открывается воротами из кафе при сытости 25.

## 1. Что добавляется

- **Район «Парк»** ≈ 30×30 м севернее кафе (за улицей с велосипедистом, z ≈ 26…56), вход — вторые
  ворота из кафе, порог накопленной сытости 25.
- **Смена суток** во всех районах: день → вечер → ночь → утро, цикл 300 с.
- **4 опасности парка + ночной сторож**, 6 новых вкусняшек (альбом 8 → 14), 12 клубочков.
- Стиль прежний (спек 2.1–2.9): лоуполи, тун, обводка; крупные поверхности — текстуры (газон,
  гравийные дорожки), пропсы плоскоцветные.

## 2. Смена суток

| Фаза | Длительность | Свет |
|---|---|---|
| День | 150 с | как сейчас (спек 2.8): солнце 65°, тёплое |
| Вечер | 30 с | солнце опускается до 10°, оранжевое `#FFB36B`, небо в персиковый |
| Ночь | 90 с | солнце выключено, «луна» — холодный `#9FB8FF` 0,25 под 50°, ambient 0,25, небо тёмно-синее; включаются фонари |
| Утро | 30 с | обратный переход к дню |

- Переходы плавные (интерполяция цвета, энергии, угла, неба). Игра стартует днём; фаза не сохраняется.
- Значок в HUD: солнце / закат / луна (сгенерированные иконки), рядом полоска до следующей фазы.
- Правила по фазам: собака двора и садовник ночью спят (не просыпаются от кота); ребёнок уходит
  домой вечером и возвращается утром; голуби ночью спят на ветках (не воруют); дождеватели работают
  и ночью; ночью в парке патрулирует **сторож с фонариком** (единственная ночная опасность-преследователь).
- Ночная еда: в тёмных точках спавна веса редкостей сдвигаются вверх (обычная 40, редкая 30,
  очень редкая 20, легендарная 10) — ночью рискованнее, но вкуснее.
- Фонари парка и двора (`lamp`) ночью — `SpotLight3D` вниз, конус 50°, тёплый `#FFD9A0`.

## 3. Опасности парка

| Опасность | Поведение | Попадание |
|---|---|---|
| **Голуби** (стая 5, у фонтана и скамеек) | Бродят и клюют. Если кот с едой в зубах ближе 1,5 м и идёт шагом — один голубь выхватывает последнюю еду и улетает. Бегом (Shift) на стаю — разлетаются на 10 с. Ночью спят. | Еда потеряна, сердечко не снимается |
| **Садовник со шлангом** (дорожки) | Ходит по маршруту; каждые 15–25 с останавливается и поливает газон перед собой 4 с: струя — конус 3 м / 40°. За 1 с до полива — шипение и капли. Ночью спит в сторожке. | Удар (как собака) |
| **Дождеватели** (3 зоны газона) | Цикл 8 с работают / 12 с стоят; за 1 с — бульканье и капли. Работают и ночью. | Кот мокрый: скорость ×0,6 на 4 с, капли с шерсти; без урона |
| **Ребёнок** (детская площадка) | Днём бегает по площадке. Заметил кота (конус 50°, 7 м) — бежит к нему 1,1× скорости кота шага; в укрытии теряет через 2 с; устаёт через 6 с. Вечером уходит. | «Гладит» 2 с: кот обездвижен, еда из зубов падает рядом; сердечко не снимается |
| **Сторож** (только ночью) | Патруль по аллеям с фонариком. Видит кота в луче фонарика (конус 30°, 8 м) или когда кот стоит в свете фонаря парка. Погоня как у собаки (1 с насторожился, 8 с гонится, 2 с до потери в укрытии). | Удар |

Новые укрытия: куст (кот внутри куста), под скамейкой парка, домик детской горки.

## 4. Еда парка (альбом +6)

| Вкусняшка | Редкость | Где |
|---|---|---|
| Попкорн | обычная | у киоска, скамейки |
| Бублик | обычная | скамейки, урны |
| Сэндвич | редкая | у сторожки садовника, столики |
| Кукуруза | редкая | у фонтана (голуби!) |
| Сахарная вата | очень редкая | детская площадка (ребёнок!) |
| Капкейк | легендарная | на бортике фонтана ночью / под присмотром сторожа |

Сытость и бонусы по редкостям — как в основном спеке 3.3–3.4. Иконки — генератор картинок.

## 5. Район «Парк»

- Газон (текстура травы), гравийные дорожки (текстура гравия), фонтан в центре (вода — зеркальный
  материал, как лужи), детская площадка (горка с домиком, качели, песочница), аллея со скамейками
  и фонарями (8), киоск мороженого, сторожка садовника, деревья, кусты, клумбы, забор по периметру.
- Раскладка — `data/layout/park.json` тем же `WorldBuilder`; ворота из кафе — `gates` с `satiety: 25`.
- Пол двора расширяется (или отдельный пол парка) так, чтобы kill-plane и коллизия покрывали парк.

## 6. Ассеты и анимации (правило владельца: сначала бесплатные готовые)

- Люди (садовник, ребёнок, сторож): ищем CC0-паки с анимированными гуманоидами (например, Quaternius
  Ultimate Animated Character / Universal Animation Library) с клипами idle/walk/run; одежда и цвета
  перекрашиваются скриптом в палитру. Только если не найдено — UniMate, затем скрипт.
- Голуби: ищем CC0-птицу с клипами (Quaternius animals); иначе процедурное махание крыльями, как у осы.
- Шланг, струя, дождеватели — частицы `CPUParticles3D` (не меши).
- Пропсы парка — скрипты Blender (фонтан, горка, качели, песочница, киоск, сторожка, скамейка
  парка, клумба, фонарь — уже есть).

## 7. Тестирование

Как в основном спеке 5.4: чистая логика (фазы суток, мозг ребёнка/сторожа, голуби) — юнит-тесты;
поведение опасностей и смена правил по фазе — интеграционные GUT с ускорением времени цикла;
раскладка парка — инварианты как у двора (спавны и клубочки не в пропсах, на чём-то стоят);
кадры днём и ночью — `make shot` с параметром фазы.

## 8. Разбивка на планы

- **План 7. Смена суток**: `DayCycle` (фазы, интерполяция света и неба, фонари, HUD-значок, правила
  сна собаки), ночные веса еды.
- **План 8. Район «Парк»**: пропсы, текстуры газона и гравия, раскладка, ворота 25, еда парка, укрытия,
  клубочки, иконки.
- **План 9. Опасности парка**: голуби, садовник, дождеватели, ребёнок, сторож; поиск анимаций людей и птиц.

## 9. Вне этапа 2

Порт, пляж, чайки (этап 3); случайные события и дворовые коты (этап 4); сохранение фазы суток.
```

## `docs/superpowers/specs/2026-10-09-snack-run-stage3-port-design.md`

```markdown
# Snack Run, этап 3: порт, пляж, чайки и вода (спек)

Продолжение `2026-10-07-snack-run-design.md` и `2026-10-09-snack-run-stage2-park-design.md` (стиль, управление,
прогрессия, сутки — оттуда). Решения владельца 2026-10-09: опасности — чайки с пикированием, волны и прилив, погрузчик
с ящиками, крабы на песке; механика — рыбалка у причала, вода и качающиеся лодки, новый район; вход — ворота из парка
при сытости 50. Рельеф и размеры — по спеку масштаба: набережная на террасе над пляжем, причал ниже,
дюны на пляже, крыши складов для паркура.

## 1. Что добавляется

- **Район «Порт»** 120×102 м (масштаб ×3 по спеку `2026-10-09-snack-run-scale-terrain-design.md`) севернее парка: набережная (мощёная, z 63…70) с лестницей от ворот парка,
  на востоке причал с ящиками и швартовкой лодок, на западе песчаный пляж, вдоль севера вода (море). Ворота в северном
  заборе парка (x −6), порог накопленной сытости 50.
- **4 опасности**, **рыбалка**, **вода и лодки**, 6 новых вкусняшек (альбом 14 → 20), 12 клубочков, новые укрытия.
- Смена суток действует и здесь (правила по фазам — раздел 3).

## 2. Вода и лодки

- Море — плоскость воды на уровне −0,3 м (зеркальный материал с лёгкой рябью шейдером). Кот, упавший в воду, «тонет»:
  1 с всплеск и бульканье, затем возвращается на ближайшую точку берега (маркеры `shore` в раскладке), еда из зубов
  потеряна, сердечко не снимается, 2 с неуязвимости. Это не kill-plane двора: возврат к ближайшему берегу, а не в будку.
- **Лодки** (3, у причала): плавающие платформы — качаются по синусу (подъём ±0,12 м, крен ±6°, период 3–4 с, разные
  фазы), кот на них стоит и прыгает; на лодках еда и клубочки. **Бочки** (5, в воде между лодками) — маленькие
  качающиеся опоры для прыжков (верх выше воды на 0,3 м).
- Тон воды и отражения следуют суткам (ночью тёмная вода, отражения фонарей набережной).

## 3. Опасности

| Опасность | Поведение | Попадание |
|---|---|---|
| **Чайки** (2, над причалом и пляжем) | Кружат на высоте 4 м радиусом 3–4 м. Если кот с едой в зубах в 6 м под чайкой — пикирует: за 1 с на земле растёт тень и крик, затем бросок в точку, где был кот. Перерыв 8 с. Ночью сидят на столбах и спят. | Удар, и чайка уносит последнюю еду (не рассыпается) |
| **Волны и прилив** (пляж) | Каждые 14 с волна накатывает от линии воды на 5 м вглубь пляжа и откатывается (3 с туда, 3 с обратно); за 1,5 с — пена у кромки и шум. | Кот отброшен к берегу на 1,5 м и мокрый (×0,6 на 4 с); без урона. Еда не теряется |
| **Погрузчик** (причал) | Ездит по маршруту на причале 3 м/с с ящиком на вилах, перед движением 1,5 с гудок; стоит у штабеля 4–6 с. Ночью стоит. | Удар (как велосипедист) |
| **Крабы** (4, пляж) | Сидят в норках; кот ближе 3 м — вылезают и бегут боком к коту 2,4 м/с; прыжок кота над крабом или 5 с погони — прячутся в норку на 6 с. Ночью их 6 и они смелее (радиус 4 м). | Щипок — удар |

Новые укрытия: штабель ящиков (за ящиками), перевёрнутая лодка на пляже (под ней), бочка на набережной.

## 4. Рыбалка

- 2 рыбака на краю причала (люди из CC0-пака Quaternius, новая роль: жилет, панама), с удочкой и ведром позади.
- Цикл рыбака: смотрит на воду 10–20 с → клюёт (поплавок дёргается, всплеск) → 2 с вытягивает → рыба падает в ведро
  (появляется вкусняшка «Золотая рыбка», легендарная, только так) → 3 с смотрит в ведро (повернувшись к берегу) → снова к воде.
- Пока рыбак смотрит на воду, кот может стащить рыбу из ведра. Если кот у ведра (ближе 1 м), когда рыбак поворачивается, —
  рыбак шугает: удар, еда из зубов рассыпается.
- Днём и вечером; ночью рыбаков нет.

## 5. Еда порта (альбом +6)

| Вкусняшка | Редкость | Где |
|---|---|---|
| Креветка | обычная | набережная, ящики |
| Картошка фри | обычная | киоск на набережной, урны |
| Кальмар | редкая | причал, лодки |
| Рыбный сэндвич | редкая | у киоска, на бочках |
| Суши | очень редкая | на дальней лодке |
| Золотая рыбка | легендарная | только из ведра рыбака |

## 6. Район «Порт»

- Набережная — мощёная (текстура камня), парапет с проёмами к пляжу, фонари (6), киоск, скамейки, урны.
- Причал — деревянный настил (текстура досок), сваи, швартовые тумбы, штабели ящиков, погрузчик, рыбаки.
- Пляж — песок (текстура песка), шезлонги, зонты, перевёрнутая лодка, ракушки, норки крабов.
- Море — плоскость воды шейдером, качающиеся лодки и бочки, буйки.
- Пол порта, забор/парапет по краям, kill-plane не нужен (вода возвращает на берег).

## 7. Ассеты и анимации (правило владельца: сначала бесплатные готовые)

- Чайка и краб — ищем CC0 с клипами (Quaternius, OpenGameArt, Kenney); иначе процедурное движение (махание крыльями
  синусом, как у осы; боковой бег краба — покачивание корпуса).
- Рыбаки — модель людей этапа 2 с новой ролью, удочка и ведро — Blender-скрипты.
- Погрузчик, лодки, бочки, ящики, причал, сваи, шезлонги, зонты — Blender-скрипты.
- Вода — шейдер; волна и пена — меш-полоса со смещением и частицы.
- Текстуры (камень набережной, доски причала, песок) — генератор картинок, трипланарно (спек 2.9).

## 8. Тестирование

Как в этапе 2: чистая логика (волна по времени, цикл рыбака, решение чайки/краба, качание лодки) — юнит-тесты;
поведение — интеграционные GUT; вода и возврат на берег; инварианты раскладки; кадры днём и ночью.

## 9. Разбивка на планы

Номера планов сдвинуты этапом «Масштаб и рельеф» (планы 10–12): порт — планы 13–15.

- **План 13. Район «Порт» и вода**: пол, текстуры, набережная, причал, пляж, море-шейдер, тонущий кот и возврат на берег,
  лодки и бочки, ворота 50, еда, укрытия, клубочки.
- **План 14. Опасности порта**: чайки, волны, погрузчик, крабы; поиск анимаций чайки и краба.
- **План 15. Рыбалка**: рыбаки, удочки, ведра, цикл, кража, золотая рыбка.

## 9а. Фактические числа после масштаба ×3 (план 13)

Порт x −60…60, z 125…227, база рельефа −2. Набережная — уровень 0, z 125…148, парапет 0,7 м к пляжу. Причал — уровень −1,
x 15…35, z 148…212, понтоны-ступени (верх −1,45) у проёмов к лодкам. Пляж — −2. Море и гавань: дно −3,5, вода −2,3
(на 0,3 ниже пляжа, как в разделе 2). Лодки: палуба −1,65 ±0,12; бочки — шаг 2 м, верх −2,0. Ворота в парке — x −6, z 125.

## 10. Вне этапа 3

Случайные события и дворовые коты (этап 4); плавание как навык; сохранение фазы суток.
```

## `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`

```markdown
# Snack Run — технический план (дорожная карта)

Спек: `docs/superpowers/specs/2026-10-07-snack-run-design.md`.
Спек описывает несколько подсистем, поэтому реализация разбита на четыре плана.
Каждый план заканчивается работающей, проверяемой версией игры. Детальный план
пишется перед началом своего этапа, когда интерфейсы предыдущего этапа уже
реальны, а не предполагаемы.

## Инструменты (установлены 2026-10-07)

| Инструмент | Версия | Путь |
|---|---|---|
| Godot | 4.7.2 stable | `/Applications/Godot.app/Contents/MacOS/Godot` |
| Blender | 5.2.2 LTS, Python 3.13, numpy | `/Applications/Blender.app/Contents/MacOS/Blender` |
| GUT | 9.7.1 (релиз 2026-07-10, под Godot 4.7) | ставится в `addons/gut` планом 1 |
| Node | 24.15 | для вспомогательных скриптов, в игре не используется |
| Unity Hub, three.js | поставлены по просьбе владельца | в проекте не используются |

## План 1. Фундамент (`2026-10-07-snack-run-01-foundation.md`) — ВЫПОЛНЕН 2026-10-08, слит в main

Результат: по двору-заглушке бегает и прыгает рыжий кот с анимациями, камера
от третьего лица, тун-освещение и обводка, `make assets` собирает модели из
Blender скриптами, `make test` гоняет GUT и Blender-тесты, `make shot` делает
скриншот сцены из CLI.

Задачи: проект Godot + GUT + Makefile → Blender-библиотека (палитра,
скруглённые примитивы, экспорт glTF, валидация) → тун-материалы, свет,
скриншоты → импорт CC0-кота Quaternius (масштаб, палитра, имя головы) →
недостающие клипы (UniMate, затем bpy) → логика движения кота с тестами →
сцена кота и камера → двор-заглушка.

## План 2. Игровой цикл (`2026-10-08-snack-run-02-gameplay.md`) — ВЫПОЛНЕН 2026-10-08

Результат: цикл «найди → схвати → спрячься → съешь → попал под собаку → потерял».

- `GameState` (сердечки, «в зубах», сытость, альбом) с GUT-тестами.
- Ресурсы еды `.tres` (8 видов), модели еды скриптами, пикап с подложкой цвета
  редкости, точки спавна с весами редкостей и респавном.
- Укрытия 3 типов, состояние `hide`, съедание в укрытии.
- Опасности на общем `hazard_base.gd`: собака (конус, погоня, усталость 8 с),
  оса (зона), велосипедист (сплайн, звонок). Модели собаки (Quaternius) и осы,
  велосипедиста (скриптами).
- Удар: разлёт еды, сердечко, оглушение, неуязвимость, возрождение.
- HUD: сердечки, сытость, слот зубов. Цель сессии «открой N карточек».
- Раскладка двора из `data/layout/yard.json`, пропсы двора (≈12) скриптами.

## План 3. Хаб и прогрессия (`2026-10-08-snack-run-03-hub.md`) — ВЫПОЛНЕН 2026-10-08

Результат: магазин пряжи, альбом, клубочки, ворота в кафе, сохранение.

- Клубочки в мире и бонус за карточки; арка в кафе по сытости 10.
- Магазин: экран, товары из `.tres` (сердечки, вместимость, скорость, тихие
  шаги, 3 скина), котёнок играет с клубочками на фоне, точка возрождения.
- Альбом: сетка карточек по редкостям. Меню, пауза. Сохранение JSON в `user://`.
- Кафе: пропсы (столы, зонты, вывеска, дорога), спавны редкой еды.

## План 4. Полировка под ролик (`2026-10-08-snack-run-04-polish.md`) — ВЫПОЛНЕН 2026-10-08

Результат: игра выглядит как в спеке и собирается в mac-билд.

- UI: тема Nunito, белые округлые плашки с тенью, графитовый текст; заставка
  «Продолжить / Новая игра».
- Кот: четыре набора глаз на кости головы (обычные, испуг, довольный, оглушён),
  переключает `CatFace` по событиям; частицы при съедании (цвет редкости),
  ударе и клубочке; шесть звуков (4 Kenney CC0 + синтез писка и лая).
- Камера мышью/правым стиком, у стены кот прозрачный, а не скрытый; виньетка.
- Собака: процедурный клип «спит» (UniMate позу лёжа не дал), лай при
  настороженности, из будки уходит сразу; плита будки с коллайдером.
- Дыры мира: kill-plane, еда при обмороке теряется, рассыпанная еда на высоте
  кота, сброс прогресса без записи нулей, B геймпада закрывает меню.
- Баланс: оценка времени до арки тестом — 32 с при пороге 10, порог не менялся.
- `make templates` / `make export` → `build/SnackRun.zip` (universal, ad-hoc подпись).
- Отложено из ревью плана 4: `reset_progress` ставит `autosave = true` безусловно; `addons/*` не
  исключён из экспорта; `build/` без `.gdignore`; B геймпада не закрывает паузу; оценка
  баланса 32 с — нижняя граница, порог арки проверить живым плейтестом; у полупрозрачного
  кота возможен «рентген» (depth draw).
- Сознательно не сделано: «чиби»-пропорции лап (сломали бы клипы UniMate).
- Этапы 2+ (парк, сутки, порт) — отдельные спеки.

## План 5. Визуальная полировка (`2026-10-09-snack-run-05-visual.md`, спек 2.8) — ВЫПОЛНЕН 2026-10-09

Результат: кадр приближен к референсу по решению владельца («выглядит сыро»).

- Картинки через OpenAI `gpt-image-2.5` по манифесту (`make images`): иконки еды в
  HUD и альбоме, арт заставки, облака, плакаты, декали.
- Кот: сваренный и сглаженный меш, глаза в глазницах с зелёной радужкой и бликом,
  моргание, щёчные кисточки, грудка, кончик хвоста, усы, ошейник с жетоном,
  короткие «чиби»-лапы и покачивание хвоста модификаторами скелета.
- Тун v2: rim-свет персонажей, шейдерная обводка с «шерстяным» шумом.
- Свет: яркий день, мягкие тени, заполняющий свет, SSAO, SSR-лужи, glow, облака.
- VFX: сквош-стретч и пыль, вспышка и тряска при ударе, сердечки, искры редкой
  еды, шлейфы осы и велосипеда, листья по ветру, «z» у спящей собаки.
- Мир: кусты, плющ, трава, декали и плакаты.
- Сознательно не сделано: веки (читались как брови), hit-stop, настоящая шерсть.
- Закрыто после плана 5 (ветка polish-minors, 2026-10-09): облака мельче (перегенерированы),
  плакаты не за кустами, плакат с лапками перенесён на западную стену (висел в воздухе), плющ
  гуще (26 листьев в два ряда), линии моргания у глаз, плашка заставки правее, листья
  рождаются над землёй, таймер одноразовых частиц учитывает `explosiveness`, полупрозрачный
  кот пишет глубину, `mesh == null` защищён, `gen.py` ловит сетевые ошибки, `heart.png` через
  `load` с фолбэком, скин-фолбэк после вспышки; тест «настенные декали и плющ висят на стене».
- Закрыто: PNG мира и сердечко импортируются со сжатием VRAM и мипмапами; mac-билд пересобран
  (71 МБ, запуск — код 0).
- Закрыто: окно развёрнуто и масштабирует интерфейс (Retina), шрифт Nunito Bold, сердечки и
  клубочек в HUD — иконки, в магазине нет символов вне шрифта.
- Отложено: щёчные кисточки спорны по вкусу;
  `clouds.png` и `title_bg.png` — жёсткие зависимости сцен; сквош держит объём (1,118/0,93 вместо 1,2/0,85 спека); жетон ошейника не виден
  спереди.

## Отложено сознательно

Пропорции лап и выражения глаз котёнка (спек 2.1, 2.4) перенесены в план 4,
чтобы план 1 дал играбельного кота раньше. Голова увеличивается уже в плане 1.

## Отложенные мелочи из ревью плана 1 (взять в план 2 или 4)

- 9× «Parameter material is null» в `build/gut.log` при `free_all` под dummy-рендерером; причина не выяснена.
- `test_input_actions_registered` тавтологичен (автозагрузка уже зарегистрировала действия).
- Клип jump 1,96 с при физическом прыжке 0,75 с; нет состояния fall при спуске с объектов.
- `cat.py` при отсутствии клипа только печатает предупреждение; `make assets` успешен без клипа.
- Переименовать `tools/blender/cat.py` → `cat_asset.py` (двусмысленность с `gen/cat.py`).
- Имена костей `Bone`/`head` в `cat.py` вынести в константы с комментарием.
- Баки 1,12 м недостижимы прыжком 0,84 м (спек 3.1 «прыжок на бак»): лестница на балкон есть, на баки по-прежнему не запрыгнуть.
- ✓ план 4: спящая собака — процедурный клип `sleep` (`tools/blender/dog_sleep.py`).
- Еда респавнится 30–90 с: за 3–5-минутную сессию двор может опустеть; проверить на плейтесте.
- Оса кружит у точки спавна независимо от сладости еды (`FoodDef.sweet` не используется); орбита проходит сквозь спинку лавки.
- ✓ план 4: счётчик клубочков графитовый на белой плашке.
- Сытость сохраняется: со второго запуска ворота открыты сразу (принятое отклонение плана 3).
- Скины — наборы из трёх цветов, «полосатого» и «сиамского» в полном смысле нет.
- ✓ план 4 (частично): `reset_progress()` больше не пишет нули; покупка по-прежнему пишет файл 2–3 раза (безвредно).
- ✓ план 4: при коте в будке собака уходит сразу.
- ✓ план 4: плита с коллайдером.
- ✓ план 4 (частично): B закрывает магазин и альбом; Space покупает товар в фокусе — стандартное `ui_accept`, оставлено.
- ✓ план 4: kill-plane на −5 м, возврат к будке без штрафа.
- ✓ план 4: «Продолжить» (при сохранении) и «Новая игра».
- ✓ план 4 (частично): под лавкой кот теперь полупрозрачный, не скрытый; сквозь днище машины может торчать по-прежнему.
- `main.gd` повторно применяет Toon ко всему двору (дублирование материалов).
- ✓ план 4: рассыпанная еда на высоте кота.
- ✓ план 4: при обмороке еда теряется.
- Укрытие «коробка» — присед за коробкой, а не внутри (модель сплошная).
- Собака не обходит препятствия (бежит в коробку/машину).
- ✓ план 4: прозрачность вместо скрытия.
- ✓ план 4: мышь крутит камеру (правый стик был с плана 1).
- Лицензия весов UniMate для сгенерированных движений — уточнить владельцу.

## План 6. Текстуры крупных поверхностей (`2026-10-09-snack-run-06-textures.md`, спек 2.9) — ВЫПОЛНЕН 2026-10-09

Гибрид по решению владельца: асфальт, плитка тротуара и штукатурка стен с проглядывающим кирпичом —
бесшовные текстуры OpenAI с трипланарной проекцией; пропсы, еда и персонажи остаются плоскоцветными.
Дальше можно: текстура дерева для лавки/забора, картон для коробок, черепица навеса будки.

## Этап 2: парк и смена суток (спек `2026-10-09-snack-run-stage2-park-design.md`)

- План 7. Смена суток (`2026-10-09-snack-run-07-day-cycle.md`) — ВЫПОЛНЕН 2026-10-09: цикл 300 с, свет и небо,
  фонари и окна ночью, значок фазы, собака спит ночью, ночные веса еды.
- План 8. Район «Парк» (`2026-10-09-snack-run-08-park.md`) — ВЫПОЛНЕН 2026-10-09: газон и гравий, фонтан,
  площадка, аллея фонарей, киоск, сторожка, забор, ворота 25, 6 вкусняшек, укрытия, 12 клубочков.
- План 9. Опасности парка (`2026-10-09-snack-run-09-park-hazards.md`) — ВЫПОЛНЕН 2026-10-09: голуби-воришки,
  садовник со шлангом, дождеватели, ребёнок «погладить», ночной сторож; люди и голубь из CC0-паков (Quaternius, mujtaba-io).
- Отложено из ревью плана 9: окклюзия луча сторожа и струи садовника (через забор), капли перед поливом,
  возврат голубей к стае, расписание садовника в статической функции.
- Этап 2 закрыт. Дальше по спеку: этап 3 (порт, пляж, чайки, вода), этап 4 (случайные события, дворовые коты).

## Масштаб ×3 и рельеф (спек `2026-10-09-snack-run-scale-terrain-design.md`)

- План 10. Рельеф (`2026-10-09-snack-run-10-terrain.md`) — ВЫПОЛНЕН 2026-10-09: генератор карт высот, узел `Terrain`
  (меш, коллизия, шейдер со сплатом), привязка раскладки к высоте, набор террас (стены, лестницы, пандусы), двор и парк на рельефе.
- Отложено из ревью плана 10 (взять в план 11): ячейка обрыва торчит «откосом» перед подпорной стеной 0,4 м; визуальная плита
  пандуса на 5 см выше коллайдера; Python `height_at` билинейный, а не по треугольникам; `max_slope_deg` не видит диагональный
  уклон; тест луча пропускает ячейки обрыва; битый `data_path` рельефа даёт каскад ошибок; нет проверки, что `Terrain` в начале
  координат; мёртвые `ground`/`park_ground` (glb, генераторы, записи текстур); `Toon.apply` создаёт лишние материалы на тайлах;
  меш рельефа неиндексированный и для 180×180 даст 64 800 треугольников (спек ≤ 40 000) — индексы или прореживание;
  2 неосвобождённых узла в `test_terrain`; константы набора террас дублируются в Blender и `WorldBuilder`; абсолютные высоты у
  ос, голубей, маркера возрождения и декалей; дорога (Path3D) не повторяет рельеф.
- План 11. Генератор раскладки и двор ×3 (`2026-10-09-snack-run-11-yard-x3.md`) — ВЫПОЛНЕН 2026-10-09: `tools/layout/`,
  двор 180×180 с гаражами и крышами, площадкой и верхним двором на террасах, сквером с холмом, верандой; плоские тайлы рельефа,
  оса над рельефом, отсечение мелочи 40 м.
- Отложено из ревью плана 11: выемки 0,5×0,5 м на внешних углах подпорных стен; проёмы под лестницы шире нужного (убираются
  модули по 4 м — виден склон обрыва); перекрытие последнего модуля стены — возможное мерцание верхних граней; `check()` генератора
  не проверяет укрытия и сравнивает позиции, а не ключи `%.1f`; дома верхнего двора на z −116 вместо −122 из плана (−122 вне террасы),
  в сквере еда только [0, 1], нет десертного стола с осой на веранде (иначе ос 5 при итоге 4); тесты проходов и цепочки слабее
  формулировок (лучи, один ряд гаражей) — вынести проверку достижимости по карте поверхности в тест; замер fps на M4 не делался;
  деревья россыпи сразу за верхней площадкой лестниц; местами пустые поля травы — смотреть на плейтесте; арку кафе (ворота 10)
  обходят по улице — решение владельца.
- План 12. Парк ×3, вода и арка кафе (`2026-10-09-snack-run-12-park-x3.md`) — ВЫПОЛНЕН 2026-10-09: парк 90×96 с холмом
  и беседкой, прудом (вода: кот тонет и возвращается на берег), рощей и лугом; забор вдоль улицы — в кафе только через арку.
- Отложено из ревью плана 12: без маркеров берега кот тонет повторно (запасная точка над той же водой); кот под водой
  движется сквозь склон котловины; тест «на берегу не тонет» слабый, маршруты проверяются по вершинам, лучи края шагом 6 м;
  стая голубей на склоне холма (птицы в земле или в воздухе); пол беседки на 0,15 м шире коллайдера; люди в погоне ходят по
  дну пруда; линейный поиск маркера берега; маршруты ядра парка через фонтан и качели (с плана 9).
- План 13. Район «Порт» и вода (`2026-10-09-snack-run-13-port.md`) — ВЫПОЛНЕН 2026-10-09: набережная, причал, пляж, море,
  качающиеся лодки и бочки, ворота 50, шесть вкусняшек, альбом 20.
- План 14. Опасности порта (`2026-10-09-snack-run-14-port-hazards.md`) — ВЫПОЛНЕН 2026-10-09: чайки (CC0-голубь), волны,
  погрузчик, крабы (CC0 methodical pixel).
- Отложено из ревью плана 13: проёмы стен в описании «1.0» при фактических 4 м; лодки и бочки без тун-обводки.
- Планы 13–15. Этап 3: порт 120×102 (район и вода, опасности, рыбалка) по спеку `2026-10-09-snack-run-stage3-port-design.md`.
```

## `docs/superpowers/notes/2026-10-07-unimate-attempt.md`

```markdown
# Попытка UniMate для клипов кота (2026-10-07)

**Итог: успех, клипы jump/hide/hit/run взяты из UniMate.** Время: 23:17–23:55 (38 минут до первого
проверенного прыжка, ещё ~20 минут на остальные клипы и интеграцию).

Что потребовалось на Mac (M4 Pro, без CUDA):
- Окружение через `uv venv --python 3.10`, `requirements.txt` без суффиксов `+cu124`; torch 2.5.1, pip-модуль `bpy` 4.0.
- `sampling.device` в `config.json` чекпоинта → `cpu` (на `mps` падает torchdiffeq: float64 не поддерживается).
  Генерация ≈ 1–1,5 мин на клип на CPU.
- `rig_preprocess` с ручной `annotation.json`: автоматическая разметка приняла спину за хвост и перепутала стороны лап.
- Скрипт `run_animate_motion.sh` ждёт `blender` в PATH и conda; подставлен шим, который запускает скрипт
  в venv через pip-`bpy` (у системного Blender нет зависимостей проекта).
- Исходные idle/walk не прошли через пайплайн (idle отфильтрован как статичный, формат экспортного npz не
  совпал с аниматором), поэтому они копируются из `Cat.blend` на канонический риг напрямую: имена костей
  совпадают, каналы IK-костей выкидываются, голова `Bone.003` → `head`. Проверено рендером.
- Клип `run` содержит перемещение корня, в `cat.py` его каналы положения удаляются (бег на месте).
- В Blender 5 `Action.fcurves` нет: каналы живут в `action.layers[].strips[].channelbags[].fcurves`.
- Экспортёр glTF в режиме ACTIONS терял активный action арматуры; перед экспортом `animation_data.action = None`.
- Импортёр glTF ставит объектам `rotation_mode = QUATERNION`; перед правкой `rotation_euler` нужен `XYZ`.

Качество: jump (вариант rep_1) — присед и подскок с отрывом лап; hide — низкий присед; hit — отшатывание,
во второй половине клипа кот валится на бок (в игре играет только первая секунда); run — галоп.
Файлы и команды воспроизведения: `third_party/unimate_clips/README.md`.

## Попытка 2: клипы собаки «лежит» и «насторожилась» (2026-10-08, 13:38–13:53)

**Итог: отказ, собака спит в клипе idle.** Риг собаки (тот же каркас костей, что у кота) прошёл
`rig_preprocess` с разметкой, скопированной из `annotation.json` кота. Четыре формулировки
по два варианта: «lies down on its belly and rests», «lies flat on the ground and sleeps»,
«stands still with its head raised, alert», «sits down on its hind legs». Высота корневой кости
(стоя 0,65–0,71 в канонических единицах): лучший «лежащий» вариант опускается только до 0,51
(72%), при этом лапы уходят под пол (−0,39); «сидит» — до 0,57; «alert» — статичная стойка,
неотличимая от idle. Критерий плана (корень ниже 60% от стойки) не выполнен ни разу.
Вывод: чекпоинт `unimate_uniml3d_f60_v3` плохо воспроизводит позы лёжа/сидя для четвероногих
с таким ригом; для анимаций «на месте» (прыжок, бег, присед кота) он работал.
Команды и файлы в `/tmp`-папке не сохранены; процедура та же, что в шаге 5 `docs/replay/02-procedure.md`.
```

## `export_presets.cfg`

```ini
[preset.0]

name="macOS"
platform="macOS"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="third_party/*, tools/*, docs/*, reference/*, tests/*, build/*, .superpowers/*"
export_path="build/SnackRun.zip"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

export/distribution_type=1
binary_format/architecture="universal"
application/bundle_identifier="ru.neiroslop.snackrun"
application/app_category="Games"
application/short_version="0.4.0"
application/version="0.4.0"
application/copyright="Нейрослоп, 2026"
display/high_res=true
codesign/codesign=1
codesign/identity=""
notarization/notarization=0
```

## `tools/audio/gen_sfx.py`

```python
#!/usr/bin/env python3
"""Два звука, которых нет в CC0-паках Kenney: писк кота и лай. Только стандартная библиотека.
Запуск: make sfx (пишет assets/sfx/meow.wav и bark.wav, 22 050 Гц, моно, 16 бит)."""
import math
import pathlib
import random
import struct
import wave

RATE = 22050
OUT = pathlib.Path(__file__).resolve().parents[2] / "assets" / "sfx"


def write(name, samples):
	OUT.mkdir(parents=True, exist_ok=True)
	with wave.open(str(OUT / name), "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(RATE)
		w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def meow(duration=0.45):
	"""Писк: тон 900→520 Гц с вибрато 6 Гц/25 Гц, вторая гармоника 0,35, атака 30 мс, спад к концу."""
	out = []
	phase = 0.0
	n = int(RATE * duration)
	for i in range(n):
		t = i / RATE
		u = t / duration
		f = 900 - 380 * u + 25 * math.sin(2 * math.pi * 6 * t)
		phase += 2 * math.pi * f / RATE
		env = min(1.0, t / 0.03) * (1.0 - u) ** 1.5
		out.append(env * 0.6 * (math.sin(phase) + 0.35 * math.sin(2 * phase)))
	return out


def bark(duration=0.16, gap=0.07):
	"""Лай «гав-гав»: два импульса, тон 190→120 Гц с пятью гармониками плюс шум 0,25, атака 10 мс."""
	rnd = random.Random(7)

	def pulse():
		out = []
		phase = 0.0
		n = int(RATE * duration)
		for i in range(n):
			t = i / RATE
			u = t / duration
			phase += 2 * math.pi * (190 - 70 * u) / RATE
			env = min(1.0, t / 0.01) * (1.0 - u) ** 2
			tone = sum(math.sin(k * phase) / k for k in (1, 2, 3, 4, 5))
			out.append(env * (0.45 * tone + 0.25 * rnd.uniform(-1.0, 1.0)))
		return out

	return pulse() + [0.0] * int(RATE * gap) + pulse()


def hiss(duration=0.9):
	"""Шипение шланга: шум с плавной атакой 150 мс и затуханием, без тона."""
	rnd = random.Random(11)
	out = []
	n = int(RATE * duration)
	prev = 0.0
	for i in range(n):
		t = i / RATE
		env = min(1.0, t / 0.15) * (1.0 - t / duration) ** 0.5
		prev = prev * 0.55 + rnd.uniform(-1.0, 1.0) * 0.45   # мягкий фильтр: шипение, а не треск
		out.append(env * 0.5 * prev)
	return out


def splash(duration=0.45):
	"""Всплеск: удар низкого тона 180→60 Гц и шумовой хвост с быстрым затуханием (кот упал в воду)."""
	rnd = random.Random(17)
	out = []
	n = int(RATE * duration)
	prev = 0.0
	phase = 0.0
	for i in range(n):
		t = i / RATE
		u = t / duration
		phase += 2 * math.pi * (180 - 120 * u) / RATE
		prev = prev * 0.35 + rnd.uniform(-1.0, 1.0) * 0.65
		env = min(1.0, t / 0.008) * (1.0 - u) ** 2.2
		out.append(env * (0.45 * math.sin(phase) * (1.0 - u) + 0.45 * prev))
	return out


def gull(duration=0.7):
	"""Крик чайки: два «кья» — тон 1400→900 Гц с хрипотцой (шум 0,2), между ними пауза."""
	rnd = random.Random(23)
	out = []
	for part in (0.3, 0.32):
		phase = 0.0
		n = int(RATE * part)
		for i in range(n):
			t = i / RATE
			u = t / part
			phase += 2 * math.pi * (1400 - 500 * u) / RATE
			env = min(1.0, t / 0.02) * (1.0 - u) ** 1.2
			out.append(env * 0.45 * (math.sin(phase) + 0.35 * math.sin(2 * phase) + 0.2 * rnd.uniform(-1, 1)))
		out += [0.0] * int(RATE * 0.06)
	return out


def wave_sound(duration=1.6):
	"""Шум наката: мягкий шум с плавным нарастанием и спадом."""
	rnd = random.Random(29)
	out = []
	n = int(RATE * duration)
	prev = 0.0
	for i in range(n):
		u = i / n
		prev = prev * 0.8 + rnd.uniform(-1.0, 1.0) * 0.2
		env = math.sin(math.pi * u) ** 1.5
		out.append(env * 0.9 * prev)
	return out


def horn(duration=0.8):
	"""Гудок погрузчика: два коротких тона 420 Гц с квадратной окраской."""
	out = []
	for part in (0.3, 0.3):
		n = int(RATE * part)
		for i in range(n):
			t = i / RATE
			s = math.sin(2 * math.pi * 420 * t)
			env = min(1.0, t / 0.01) * min(1.0, (part - t) / 0.02)
			out.append(env * 0.35 * (s + 0.3 * math.copysign(1.0, s)))
		out += [0.0] * int(RATE * 0.1)
	return out


def sprinkle(count=6, gap=0.11):
	"""Бульканье дождевателя: короткие «бульки» — тон 300→700 Гц по 60 мс."""
	out = []
	for k in range(count):
		n = int(RATE * 0.06)
		phase = 0.0
		for i in range(n):
			u = i / n
			phase += 2 * math.pi * (300 + 400 * u + 40 * k) / RATE
			out.append(math.sin(phase) * 0.45 * (1 - u) ** 2)
		out += [0.0] * int(RATE * gap)
	return out


def coo(duration=0.5):
	"""Воркование голубя: два низких «гу-у» 320→260 Гц с вибрато 9 Гц."""
	out = []
	for part in (0.22, 0.28):
		n = int(RATE * part)
		phase = 0.0
		for i in range(n):
			t = i / RATE
			u = t / part
			phase += 2 * math.pi * (320 - 60 * u + 12 * math.sin(2 * math.pi * 9 * t)) / RATE
			env = min(1.0, t / 0.03) * (1.0 - u) ** 1.2
			out.append(env * 0.55 * (math.sin(phase) + 0.25 * math.sin(2 * phase)))
		out += [0.0] * int(RATE * 0.05)
	return out


if __name__ == "__main__":
	write("meow.wav", meow())
	write("bark.wav", bark())
	write("hiss.wav", hiss())
	write("sprinkle.wav", sprinkle())
	write("splash.wav", splash())
	write("gull.wav", gull())
	write("wave.wav", wave_sound())
	write("horn.wav", horn())
	write("coo.wav", coo())
	print("ОК assets/sfx/meow.wav, bark.wav, hiss.wav, sprinkle.wav, coo.wav, splash.wav, gull.wav, wave.wav, horn.wav")
```

## `tools/release/fetch_templates.sh`

```bash
#!/bin/bash
# Скачивает шаблоны экспорта Godot 4.7.2 (1,28 ГБ) восемью параллельными диапазонами:
# один поток с GitHub шёл 150 КБ/с, восемь — около 1 МБ/с. Результат: build/templates.tpz.
set -e
cd "$(dirname "$0")/../.."
URL=https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
mkdir -p build/tpz_parts
SIZE=$(curl -sIL "$URL" | grep -i '^content-length' | tail -1 | tr -dc '0-9')
[ -n "$SIZE" ] || { echo "не удалось узнать размер $URL"; exit 1; }
N=8; CHUNK=$(( (SIZE + N - 1) / N ))
for i in $(seq 0 $((N-1))); do
  S=$((i*CHUNK)); E=$(( (i+1)*CHUNK - 1 )); [ $E -ge $SIZE ] && E=$((SIZE-1))
  curl -sL -r $S-$E -o build/tpz_parts/part_$i "$URL" &
done
wait
cat $(for i in $(seq 0 $((N-1))); do echo build/tpz_parts/part_$i; done) > build/templates.tpz
[ "$(stat -f %z build/templates.tpz)" = "$SIZE" ] || { echo "размер не совпал"; exit 1; }
rm -rf build/tpz_parts
echo "ОК build/templates.tpz ($SIZE байт)"
```

## `tools/images/gen.py`

```python
#!/usr/bin/env python3
"""Генерация 2D-картинок (иконки, заставка, плакаты, облака, декали) через OpenAI Images API.
Ключ берётся только из переменной окружения OPENAI_API_KEY и никуда не пишется.
Запуск: make images (только отсутствующие файлы), make images FORCE=1 (все заново)."""
import base64
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = pathlib.Path(__file__).with_name("manifest.json")
API = "https://api.openai.com/v1/images/generations"
STYLE = ("Style: flat cartoon game art, thick dark graphite (#394151) outline, soft pastel colors, "
         "simple rounded shapes, clean edges, no text unless the prompt asks for it.")


def generate(entry, key):
	body = {
		"model": entry.get("model", "gpt-image-2.5-flare"),
		"prompt": entry["prompt"] + " " + STYLE,
		"size": entry.get("size", "1024x1024"),
		"quality": entry.get("quality", "medium"),
		"output_format": "png",
		"n": 1,
	}
	if entry.get("background") == "transparent":
		body["background"] = "transparent"
	req = urllib.request.Request(API, data=json.dumps(body).encode(), method="POST",
	                             headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
	for attempt in range(3):
		try:
			with urllib.request.urlopen(req, timeout=180) as resp:
				data = json.load(resp)
			return base64.b64decode(data["data"][0]["b64_json"]), data.get("usage", {}).get("total_tokens")
		except urllib.error.HTTPError as e:
			text = e.read().decode(errors="replace")[:300]
			if e.code in (429, 500, 502, 503) and attempt < 2:
				time.sleep(5 * (attempt + 1))
				continue
			raise RuntimeError(f"{entry['file']}: HTTP {e.code} {text}") from None
		except (urllib.error.URLError, TimeoutError, OSError) as e:   # сеть/таймаут: ключ в сообщение не попадает
			if attempt < 2:
				time.sleep(5 * (attempt + 1))
				continue
			raise RuntimeError(f"{entry['file']}: сеть недоступна ({e.__class__.__name__})") from None
		except (KeyError, IndexError, ValueError) as e:
			raise RuntimeError(f"{entry['file']}: неожиданный ответ API ({e.__class__.__name__})") from None


def main(argv):
	force = "--force" in argv
	only = [a for a in argv if not a.startswith("--")]
	key = os.environ.get("OPENAI_API_KEY", "")
	entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["images"]
	todo = [e for e in entries if (force or not (ROOT / e["file"]).exists()) and (not only or e["file"] in only)]
	if not todo:
		print("все картинки на месте")
		return 0
	if not key:
		print(f"нет OPENAI_API_KEY, а нужно сгенерировать {len(todo)} файл(ов):", ", ".join(e["file"] for e in todo))
		return 1
	for e in todo:
		png, tokens = generate(e, key)
		out = ROOT / e["file"]
		out.parent.mkdir(parents=True, exist_ok=True)
		out.write_bytes(png)
		print(f"ОК {e['file']} ({len(png) // 1024} КБ, {tokens} токенов)")
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
```

## `tools/images/manifest.json`

```json
{
  "style_note": "Все промпты дополняются STYLE из gen.py: плоский мультяшный стиль, графитовая обводка, пастель. Перегенерация одного файла: python3 tools/images/gen.py --force <путь>.",
  "images": [
    {
      "file": "assets/images/ui/food_sausage.png",
      "note": "иконка сосиски",
      "background": "transparent",
      "prompt": "Game icon of a single plump sausage with a small bite mark, warm red-brown (#BD4045) with lighter highlights, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_cookie.png",
      "note": "иконка печенья",
      "background": "transparent",
      "prompt": "Game icon of a round chocolate chip cookie, sandy (#D3AB87) with dark chips, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_pizza.png",
      "note": "иконка пиццы",
      "background": "transparent",
      "prompt": "Game icon of a pizza slice with pepperoni, crust #D3AB87, cheese #FABE32, pepperoni #BD4045, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_hotdog.png",
      "note": "иконка хот-дога",
      "background": "transparent",
      "prompt": "Game icon of a hot dog in a bun with a mustard zigzag, bun #D3AB87, sausage #BD4045, mustard #FABE32, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_croissant.png",
      "note": "иконка круассана",
      "background": "transparent",
      "prompt": "Game icon of a golden croissant, #FAAE45 with #D3AB87 shading, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_fish.png",
      "note": "иконка рыбы",
      "background": "transparent",
      "prompt": "Game icon of a whole cartoon fish, silver-blue (#2F9CCF) with a cute eye, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_donut.png",
      "note": "иконка пончика",
      "background": "transparent",
      "prompt": "Game icon of a ring donut with pink (#F57485) glaze and colorful sprinkles, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_ice_cream.png",
      "note": "иконка мороженого",
      "background": "transparent",
      "prompt": "Game icon of a soft-serve ice cream cone, cream (#FCD3A1) swirl and sandy (#D3AB87) waffle cone, centered, transparent background"
    },
    {
      "file": "assets/images/ui/heart.png",
      "note": "сердечко для частиц",
      "background": "transparent",
      "prompt": "Game icon of a simple glossy heart, coral pink (#F57485) with a white highlight, centered, transparent background"
    },
    {
      "file": "assets/images/ui/yarn.png",
      "note": "клубочек для HUD и магазина",
      "background": "transparent",
      "prompt": "Game icon of a round ball of yarn with a loose thread, lilac (#B46DB5) with lighter highlights, centered, transparent background"
    },
    {
      "file": "assets/images/title/title_bg.png",
      "note": "фон заставки",
      "size": "1536x1024",
      "model": "gpt-image-2.5-sunburst",
      "quality": "high",
      "prompt": "Wide illustration for a cozy game title screen: a fluffy orange kitten with big green eyes and a white chest crouches on a sunny city sidewalk next to a pizza slice, green bins and a bench behind, blue sky with cumulus clouds, warm midday light, soft shadows, lots of greenery. Leave the center-bottom area calm and uncluttered for menu buttons. No text."
    },
    {
      "file": "assets/images/world/clouds.png",
      "note": "слой облаков для неба (sky_cover)",
      "size": "1536x1024",
      "background": "transparent",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Seamless wide panoramic layer of many small scattered fluffy white cumulus clouds (at least 40 clouds, each small, none larger than a tenth of the image width), cartoon style with soft shading, clouds only, lots of empty space between them, transparent background, suitable for tiling across a sky dome"
    },
    {
      "file": "assets/images/world/poster_cafe.png",
      "note": "плакат кафе",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Square chalkboard poster for a street cafe with the text 'Good Food Better Days' in friendly hand lettering, a small paw print and a croissant doodle, dark board with chalk colors"
    },
    {
      "file": "assets/images/world/poster_cat.png",
      "note": "плакат с котом",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Square street poster of a cute cartoon cat face silhouette in white on a dark green (#458B59) background, slightly weathered paper look, no text"
    },
    {
      "file": "assets/images/world/poster_paws.png",
      "note": "плакат с лапками",
      "prompt": "Square playful poster with a trail of cat paw prints in coral pink (#F57485) on cream (#FCD3A1) paper, no text"
    },
    {
      "file": "assets/images/world/decal_manhole.png",
      "note": "люк на асфальт",
      "background": "transparent",
      "prompt": "Top-down round cast iron manhole cover with a simple grid pattern, dark grey (#5A5C6B) with lighter rim, centered, transparent background"
    },
    {
      "file": "assets/images/world/decal_cracks.png",
      "note": "трещины на асфальте",
      "background": "transparent",
      "prompt": "Top-down subtle asphalt cracks and a faint dark stain, thin graphite lines, mostly empty, transparent background"
    },
    {
      "file": "assets/images/world/decal_leaves.png",
      "note": "опавшие листья",
      "background": "transparent",
      "prompt": "Top-down scatter of a few small fallen leaves in olive (#A9B087), leaf green (#458B59) and sand (#D3AB87), transparent background"
    },
    {
      "file": "assets/images/textures/asphalt.png",
      "note": "бесшовный асфальт (дорога и двор)",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Seamless tileable texture of stylized cartoon asphalt seen straight from above, flat even lighting with no shadows and no perspective, base color #5A5C6B with small lighter and darker speckles and a couple of subtle hairline cracks, painterly hand-painted game texture, edges must wrap seamlessly on all four sides, no text, no objects"
    },
    {
      "file": "assets/images/textures/paving.png",
      "note": "бесшовная плитка тротуара",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Seamless tileable texture of stylized cartoon square paving stones seen straight from above, exactly 4 by 4 rounded square tiles filling the whole image edge to edge, warm sand color #D3AB87 with slightly darker grout lines and soft color variation per tile, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly, no text"
    },
    {
      "file": "assets/images/textures/stucco.png",
      "note": "бесшовная штукатурка с кирпичом (стены домов)",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Seamless tileable texture of a stylized cartoon plastered building wall seen straight on, warm sand stucco #D3AB87 with soft painterly variation and a few small patches where orange-red bricks (#BD4045) peek through the plaster, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly on all sides, no windows, no text"
    },
    {
      "file": "assets/images/ui/sun.png",
      "note": "иконка фазы суток: sun",
      "background": "transparent",
      "prompt": "Game icon of a smiling cartoon sun with rounded rays, warm yellow (#FABE32), centered, transparent background"
    },
    {
      "file": "assets/images/ui/sunset.png",
      "note": "иконка фазы суток: sunset",
      "background": "transparent",
      "prompt": "Game icon of a cartoon sun half below a horizon line with soft orange (#FFB36B) and coral (#F57485) glow, centered, transparent background"
    },
    {
      "file": "assets/images/ui/moon.png",
      "note": "иконка фазы суток: moon",
      "background": "transparent",
      "prompt": "Game icon of a cute crescent moon with two small stars, pale blue (#9FB8FF), centered, transparent background"
    },
    {
      "file": "assets/images/textures/grass.png",
      "note": "бесшовный газон парка",
      "prompt": "Seamless tileable texture of a stylized cartoon lawn seen straight from above, short grass in leaf green (#458B59) and olive (#A9B087) with tiny painted blades and a few small white clover flowers, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly on all four sides, no objects, no text",
      "model": "gpt-image-2.5-sunburst"
    },
    {
      "file": "assets/images/textures/gravel.png",
      "note": "бесшовный гравий дорожек",
      "prompt": "Seamless tileable texture of a stylized cartoon fine gravel path seen straight from above, small rounded pebbles in sand (#D3AB87), cream (#FCD3A1) and light grey tones, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly on all four sides, no text",
      "model": "gpt-image-2.5-sunburst"
    },
    {
      "file": "assets/images/ui/food_popcorn.png",
      "note": "иконка попкорна",
      "prompt": "Game icon of a striped red and white popcorn box overflowing with fluffy popcorn, red #BD4045, cream popcorn #FCD3A1, centered, transparent background",
      "background": "transparent"
    },
    {
      "file": "assets/images/ui/food_bagel.png",
      "note": "иконка бублика",
      "prompt": "Game icon of a round golden bagel with sesame seeds, #FAAE45 with #D3AB87 shading, centered, transparent background",
      "background": "transparent"
    },
    {
      "file": "assets/images/ui/food_sandwich.png",
      "note": "иконка сэндвича",
      "prompt": "Game icon of a triangle sandwich with lettuce, tomato and cheese, bread #FCD3A1, centered, transparent background",
      "background": "transparent"
    },
    {
      "file": "assets/images/ui/food_corn.png",
      "note": "иконка кукурузы",
      "prompt": "Game icon of a grilled corn cob with green husk leaves, kernels #FABE32, husk #458B59, centered, transparent background",
      "background": "transparent"
    },
    {
      "file": "assets/images/ui/food_cotton_candy.png",
      "note": "иконка сахарной ваты",
      "prompt": "Game icon of fluffy pink cotton candy on a paper cone stick, pink #F57485 and lilac #B46DB5 swirl, centered, transparent background",
      "background": "transparent"
    },
    {
      "file": "assets/images/ui/food_cupcake.png",
      "note": "иконка капкейка",
      "prompt": "Game icon of a cupcake with swirled pink frosting, sprinkles and a cherry on top, paper cup in sky blue #659ECF, centered, transparent background",
      "background": "transparent"
    },
    {
      "file": "assets/images/textures/stone.png",
      "note": "бесшовный камень (обрывы, подпорные стены)",
      "model": "gpt-image-2.5-sunburst",
      "prompt": "Seamless tileable texture of a stylized cartoon stone retaining wall seen straight on, irregular rounded stones in sand (#D3AB87), cream (#FCD3A1) and soft grey tones with darker mortar lines, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly on all four sides, no text"
    },
    {
      "file": "assets/images/textures/sand.png",
      "note": "бесшовный песок пляжа порта",
      "prompt": "Seamless tileable texture of stylized cartoon beach sand seen straight from above, warm sand (#D3AB87) and cream (#FCD3A1) with tiny painted grains, a few small shells and soft ripples, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly on all four sides, no objects, no text",
      "model": "gpt-image-2.5-sunburst"
    },
    {
      "file": "assets/images/textures/planks.png",
      "note": "бесшовные доски причала",
      "prompt": "Seamless tileable texture of stylized cartoon wooden pier planks seen straight from above, parallel boards in sand (#D3AB87) with warm brick-brown (#BD4045) tint and dark graphite (#394151) gaps and nail dots, flat even lighting, no shadows, no perspective, hand-painted game texture, edges wrap seamlessly on all four sides, no text",
      "model": "gpt-image-2.5-sunburst"
    },
    {
      "file": "assets/images/ui/food_shrimp.png",
      "note": "иконка shrimp",
      "background": "transparent",
      "prompt": "Game icon of a curled pink shrimp, coral (#F57485) with cream (#FCD3A1) segments, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_fries.png",
      "note": "иконка fries",
      "background": "transparent",
      "prompt": "Game icon of a red paper cup (#BD4045) of golden french fries (#FABE32), centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_squid.png",
      "note": "иконка squid",
      "background": "transparent",
      "prompt": "Game icon of a cute small squid, lilac (#B46DB5) with cream suckers, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_fish_sandwich.png",
      "note": "иконка fish_sandwich",
      "background": "transparent",
      "prompt": "Game icon of a fish sandwich: bun #D3AB87, golden fried fish fillet #FAAE45, green lettuce #458B59, centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_sushi.png",
      "note": "иконка sushi",
      "background": "transparent",
      "prompt": "Game icon of two pieces of nigiri sushi with salmon (#F57485) on white rice and a nori band (#394151), centered, transparent background"
    },
    {
      "file": "assets/images/ui/food_golden_fish.png",
      "note": "иконка golden_fish",
      "background": "transparent",
      "prompt": "Game icon of a shiny golden cartoon fish (#FABE32) with sparkles and a cute eye, centered, transparent background"
    }
  ]
}
```

## `assets/ui/nunito_bold.tres`

```
[gd_resource type="FontVariation" load_steps=2 format=3]

[ext_resource type="FontFile" path="res://assets/fonts/Nunito.ttf" id="1"]

[resource]
base_font = ExtResource("1")
variation_opentype = {2003265652: 700}
```

## `assets/ui/theme.tres`

```
[gd_resource type="Theme" load_steps=8 format=3]

[ext_resource type="FontVariation" path="res://assets/ui/nunito_bold.tres" id="1"]

[sub_resource type="StyleBoxFlat" id="panel"]
content_margin_left = 14.0
content_margin_top = 8.0
content_margin_right = 14.0
content_margin_bottom = 8.0
bg_color = Color(1, 1, 1, 0.92)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14
shadow_color = Color(0.224, 0.255, 0.318, 0.18)
shadow_size = 6
shadow_offset = Vector2(0, 3)

[sub_resource type="StyleBoxFlat" id="button"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.98, 0.682, 0.271, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[sub_resource type="StyleBoxFlat" id="button_hover"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.961, 0.455, 0.522, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[sub_resource type="StyleBoxFlat" id="button_disabled"]
content_margin_left = 16.0
content_margin_top = 8.0
content_margin_right = 16.0
content_margin_bottom = 8.0
bg_color = Color(0.85, 0.85, 0.85, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[sub_resource type="StyleBoxFlat" id="bar_bg"]
bg_color = Color(0.88, 0.88, 0.88, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[sub_resource type="StyleBoxFlat" id="bar_fill"]
bg_color = Color(0.271, 0.545, 0.349, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[resource]
default_font = ExtResource("1")
default_font_size = 24
Button/colors/font_color = Color(0.224, 0.255, 0.318, 1)
Button/colors/font_disabled_color = Color(0.5, 0.5, 0.5, 1)
Button/colors/font_focus_color = Color(1, 1, 1, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/colors/font_pressed_color = Color(1, 1, 1, 1)
Button/styles/disabled = SubResource("button_disabled")
Button/styles/focus = SubResource("button_hover")
Button/styles/hover = SubResource("button_hover")
Button/styles/normal = SubResource("button")
Button/styles/pressed = SubResource("button_hover")
Label/colors/font_color = Color(0.224, 0.255, 0.318, 1)
PanelContainer/styles/panel = SubResource("panel")
ProgressBar/styles/background = SubResource("bar_bg")
ProgressBar/styles/fill = SubResource("bar_fill")
```

## `assets/shaders/outline_fur.gdshader`

```glsl
shader_type spatial;
render_mode cull_front, unshaded, blend_mix, depth_draw_always;
// Инвертированный hull с «рваной» шириной: силуэт персонажа читается как пушистый (спек 2.8).
uniform vec4 color : source_color = vec4(0.224, 0.255, 0.318, 1.0);
uniform float width = 0.006;      // в единицах модели (Toon пересчитывает метры под масштаб узла)
uniform float jitter = 0.0;       // доля width: 0 — ровная обводка, 0.25 — шерсть
uniform float frequency = 40.0;   // не используется с хэшем по вершинам; оставлен для совместимости параметров
uniform float alpha = 1.0;

float hash1(float x) {
	return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

void vertex() {
	// Хэш по номеру вершины: стабилен в движении и не требует UV (у мешей из Blender-скриптов их нет).
	// При jitter = 0 шум не применяется, ширина ровно width.
	float n = jitter > 0.0 ? hash1(float(VERTEX_ID)) * 2.0 - 1.0 : 0.0;
	VERTEX += NORMAL * width * (1.0 + jitter * n);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = alpha * color.a;
}
```

## `assets/shaders/terrain.gdshader`

```glsl
shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Пол района (спек «Масштаб и рельеф», раздел 3): 4 покрытия по карте весов (RGBA), камень на крутых гранях.
// Покрытия — проекция сверху по мировым xz, камень — трипланарно по бокам.
uniform sampler2D splat : filter_linear, repeat_disable;
uniform sampler2D tex_r : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_g : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_cliff : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tile_sizes = vec4(4.0, 1.2, 2.0, 0.8);   // метров на один повтор текстуры R, G, B, A
uniform float cliff_tile = 3.0;
uniform vec2 origin = vec2(0.0);
uniform vec2 size = vec2(40.0);
uniform vec2 texels = vec2(41.0);

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 suv = ((wpos.xz - origin) / size) * ((texels - 1.0) / texels) + 0.5 / texels;   // центры текселей = вершины сетки
	vec4 w = texture(splat, suv);
	w /= max(w.r + w.g + w.b + w.a, 0.001);
	vec3 ground = texture(tex_r, wpos.xz / tile_sizes.x).rgb * w.r
		+ texture(tex_g, wpos.xz / tile_sizes.y).rgb * w.g
		+ texture(tex_b, wpos.xz / tile_sizes.z).rgb * w.b
		+ texture(tex_a, wpos.xz / tile_sizes.w).rgb * w.a;
	vec3 an = abs(wnorm);
	vec3 cliff = (texture(tex_cliff, wpos.zy / cliff_tile).rgb * an.x + texture(tex_cliff, wpos.xy / cliff_tile).rgb * an.z) / max(an.x + an.z, 0.001);
	float steep = smoothstep(0.80, 0.62, wnorm.y);
	ALBEDO = mix(ground, cliff, steep);
	ROUGHNESS = 0.9;
}
```

## `assets/shaders/vignette.gdshader`

```glsl
shader_type canvas_item;
// Мягкое затемнение краёв кадра (план 4). strength — плотность, radius — где начинается.
uniform float strength : hint_range(0.0, 1.0) = 0.35;
uniform float radius : hint_range(0.0, 1.5) = 0.72;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.4142;
	float v = smoothstep(radius, 1.25, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength);
}
```

## `assets/shaders/water.gdshader`

```glsl
shader_type spatial;
// Вода пруда и моря (спек порта, раздел 2): цвет палитры sea_light, рябь нормалью; непрозрачная — так её отражает SSR окружения
// (прозрачный проход Godot SSR не получает, ревью плана 12).
render_mode diffuse_toon, specular_toon, cull_disabled;

uniform vec4 tint : source_color = vec4(0.184, 0.612, 0.812, 1.0);
uniform vec4 deep : source_color = vec4(0.114, 0.498, 0.769, 1.0);
uniform float ripple = 0.08;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float a = sin(wpos.x * 1.7 + TIME * 1.3) + sin(wpos.z * 2.3 - TIME * 1.1);
	float b = cos(wpos.x * 2.1 - TIME * 0.9) + cos(wpos.z * 1.5 + TIME * 1.4);
	vec3 n = normalize(vec3(a * ripple, 1.0, b * ripple));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float f = 0.5 + 0.25 * (a + b) * 0.25;
	ALBEDO = mix(deep.rgb, tint.rgb, clamp(f, 0.0, 1.0));
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
```

## `assets/sfx/README.md`

```markdown
# Звуки (спек 2.7)

| Файл | Событие | Источник | Лицензия |
|---|---|---|---|
| pickup.ogg | подбор еды, клубочка | Kenney «Interface Sounds», pluck_001 | CC0 (LICENSE_kenney.txt) |
| eat.ogg | съедание | Kenney «Interface Sounds», drop_002 | CC0 |
| hit.ogg | удар | Kenney «Impact Sounds», impactPunch_medium_000 | CC0 |
| bell.ogg | звонок велосипеда | Kenney «Impact Sounds», impactBell_heavy_000 | CC0 |
| meow.wav | писк кота | синтез `tools/audio/gen_sfx.py` (`make sfx`) | проект |
| bark.wav | лай | синтез `tools/audio/gen_sfx.py` (`make sfx`) | проект |
| hiss.wav | шланг садовника | синтез `make sfx` | проект |
| sprinkle.wav | дождеватель | синтез `make sfx` | проект |
| coo.wav | голуби | синтез `make sfx` | проект |
| splash.wav | кот упал в воду | синтез `make sfx` | проект |
| gull.wav | крик чайки | синтез `make sfx` | проект |
| wave.wav | шум наката | синтез `make sfx` | проект |
| horn.wav | гудок погрузчика | синтез `make sfx` | проект |

Паки: https://kenney.nl/assets/interface-sounds, https://kenney.nl/assets/impact-sounds.
Правило: один `Sfx.play()` на игровое событие (сигнал), никогда из `_process`.
```

## `assets/fonts/OFL.txt`

```
Copyright 2014 The Nunito Project Authors (https://github.com/googlefonts/nunito)

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL


-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded, 
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components as
distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to a
new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name as
presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
```

## `tools/terrain/terrain_gen.py`

```python
#!/usr/bin/env python3
"""Генератор карт высот районов (спек «Масштаб и рельеф», раздел 3). Только стандартная библиотека.

Вход  data/terrain_src/<район>.json:
  size [W, D] метров, origin [x0, z0] — угол с наименьшими x, z в координатах Godot, cell 1.0, base — высота по умолчанию,
  channels — имена 4 покрытий (R, G, B, A), default — покрытие по умолчанию,
  features — по порядку: hill {center, radius, height}, basin {center, radius, depth},
             terrace {rect [x0, z0, x1, z1], height} (плато с отвесным краем, max с текущей высотой),
             flat {rect, height} (ровно заданная высота).
  paint — по порядку: {rect | circle [x, z, r], type, soft? метры размытия края}.
Выход data/terrain/<район>.json: size, origin, cell, nx, nz, heights (nz строк по nx, см), splat (base64 RGBA, nx*nz*4).
Запуск: make terrain  (все файлы из data/terrain_src)."""
import base64
import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


class Grid:
	def __init__(self, desc):
		self.w, self.d = desc["size"]
		self.x0, self.z0 = desc["origin"]
		self.cell = float(desc.get("cell", 1.0))
		self.nx = int(round(self.w / self.cell)) + 1
		self.nz = int(round(self.d / self.cell)) + 1
		self.h = [[float(desc.get("base", 0.0))] * self.nx for _ in range(self.nz)]
		self.channels = desc.get("channels", ["asphalt", "paving", "grass", "gravel"])
		default = self.channels.index(desc.get("default", self.channels[0]))
		self.splat = [[[255 if c == default else 0 for c in range(4)] for _ in range(self.nx)] for _ in range(self.nz)]

	def pos(self, i, j):
		return self.x0 + i * self.cell, self.z0 + j * self.cell

	def cells(self):
		for j in range(self.nz):
			for i in range(self.nx):
				yield i, j, *self.pos(i, j)


def _in_rect(x, z, r):
	return r[0] <= x <= r[2] and r[1] <= z <= r[3]


def apply_feature(g, f):
	t = f["type"]
	for i, j, x, z in g.cells():
		if t == "hill" or t == "basin":
			cx, cz = f["center"]
			d = math.hypot(x - cx, z - cz) / f["radius"]
			if d < 1.0:
				bump = math.cos(d * math.pi / 2.0) ** 2   # гладкий купол, нулевой наклон на вершине и у подножия
				g.h[j][i] += bump * (f["height"] if t == "hill" else -f["depth"])
		elif t == "terrace":
			if _in_rect(x, z, f["rect"]):
				g.h[j][i] = max(g.h[j][i], f["height"])
		elif t == "flat":
			if _in_rect(x, z, f["rect"]):
				g.h[j][i] = f["height"]
		else:
			raise ValueError(f"неизвестный рельеф: {t}")


def apply_paint(g, p):
	c = g.channels.index(p["type"])
	soft = float(p.get("soft", 0.0))
	for i, j, x, z in g.cells():
		if "rect" in p:
			r = p["rect"]
			dist = max(r[0] - x, x - r[2], r[1] - z, z - r[3])   # <0 внутри
		else:
			cx, cz, rad = p["circle"]
			dist = math.hypot(x - cx, z - cz) - rad
		if soft > 0.0:
			k = min(1.0, max(0.0, 0.5 - dist / soft))
		else:
			k = 1.0 if dist <= 0.0 else 0.0
		if k <= 0.0:
			continue
		px = g.splat[j][i]
		for ch in range(4):
			target = 255 if ch == c else 0
			px[ch] = int(round(px[ch] * (1.0 - k) + target * k))


def build(desc):
	g = Grid(desc)
	for f in desc.get("features", []):
		apply_feature(g, f)
	for p in desc.get("paint", []):
		apply_paint(g, p)
	return g


def height_at(g, x, z):
	"""Билинейная высота (та же, что Terrain.height_at в Godot)."""
	fx = (x - g.x0) / g.cell
	fz = (z - g.z0) / g.cell
	i = max(0, min(g.nx - 2, int(math.floor(fx))))
	j = max(0, min(g.nz - 2, int(math.floor(fz))))
	u = min(1.0, max(0.0, fx - i))
	v = min(1.0, max(0.0, fz - j))
	h00, h10, h01, h11 = g.h[j][i], g.h[j][i + 1], g.h[j + 1][i], g.h[j + 1][i + 1]
	return (h00 * (1 - u) + h10 * u) * (1 - v) + (h01 * (1 - u) + h11 * u) * v


def max_slope_deg(g, skip_cliffs_above=None):
	"""Наибольший уклон между соседними вершинами, градусы; перепады больше skip_cliffs_above м (обрывы террас) пропускаются."""
	worst = 0.0
	for j in range(g.nz):
		for i in range(g.nx):
			for di, dj in ((1, 0), (0, 1)):
				if i + di < g.nx and j + dj < g.nz:
					dh = abs(g.h[j + dj][i + di] - g.h[j][i])
					if skip_cliffs_above is not None and dh > skip_cliffs_above:
						continue
					worst = max(worst, math.degrees(math.atan2(dh, g.cell)))
	return worst


def to_json(g):
	raw = bytearray()
	for j in range(g.nz):
		for i in range(g.nx):
			raw.extend(g.splat[j][i])
	return {
		"size": [g.w, g.d], "origin": [g.x0, g.z0], "cell": g.cell, "nx": g.nx, "nz": g.nz,
		"channels": g.channels,
		"heights": [[round(v, 3) for v in row] for row in g.h],
		"splat": base64.b64encode(bytes(raw)).decode(),
	}


def main(argv):
	srcs = [pathlib.Path(a) for a in argv] or sorted((ROOT / "data" / "terrain_src").glob("*.json"))
	for src in srcs:
		g = build(json.loads(src.read_text(encoding="utf-8")))
		out = ROOT / "data" / "terrain" / src.name
		out.write_text(json.dumps(to_json(g), separators=(",", ":")), encoding="utf-8")
		print(f"ОК {out.relative_to(ROOT)}: {g.nx}×{g.nz}, уклон ≤ {max_slope_deg(g, 0.6):.1f}° (без обрывов)")
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
```

## `tools/terrain/tests/test_terrain_gen.py`

```python
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
```

## `data/terrain_src/demo.json`

```json
{
  "note": "Демо-рельеф для тестов и кадров: холм, низина, терраса 2 м, гравийная дорожка, газон на холме.",
  "size": [
    40,
    40
  ],
  "origin": [
    -20,
    -20
  ],
  "cell": 1.0,
  "base": 0.0,
  "channels": [
    "asphalt",
    "paving",
    "grass",
    "gravel"
  ],
  "default": "paving",
  "features": [
    {
      "type": "hill",
      "center": [
        8,
        8
      ],
      "radius": 10,
      "height": 3
    },
    {
      "type": "basin",
      "center": [
        -10,
        10
      ],
      "radius": 6,
      "depth": 1
    },
    {
      "type": "terrace",
      "rect": [
        -18,
        -18,
        -6,
        -8
      ],
      "height": 2
    },
    {
      "type": "terrace",
      "rect": [
        -19,
        -3,
        -13,
        3
      ],
      "height": 1
    }
  ],
  "paint": [
    {
      "circle": [
        8,
        8,
        9
      ],
      "type": "grass",
      "soft": 3
    },
    {
      "circle": [
        -10,
        10,
        6
      ],
      "type": "grass",
      "soft": 2
    },
    {
      "rect": [
        -20,
        -2,
        20,
        0
      ],
      "type": "gravel",
      "soft": 1
    },
    {
      "rect": [
        -18,
        -18,
        -6,
        -8
      ],
      "type": "asphalt"
    }
  ]
}
```

## `data/terrain_src/park.json`

```json
{
  "size": [
    90,
    96
  ],
  "origin": [
    -45,
    29
  ],
  "cell": 1.0,
  "base": 0.01,
  "channels": [
    "asphalt",
    "paving",
    "grass",
    "gravel"
  ],
  "default": "grass",
  "features": [
    {
      "type": "hill",
      "center": [
        0,
        92
      ],
      "radius": 18,
      "height": 3
    },
    {
      "type": "basin",
      "center": [
        -28,
        66
      ],
      "radius": 11,
      "depth": 1.5
    }
  ],
  "paint": [
    {
      "rect": [
        -1.1,
        29,
        1.1,
        61
      ],
      "type": "gravel"
    },
    {
      "rect": [
        -15,
        43.9,
        15,
        46.1
      ],
      "type": "gravel"
    },
    {
      "rect": [
        10.9,
        29,
        13.1,
        38
      ],
      "type": "gravel"
    },
    {
      "rect": [
        0,
        36.9,
        12,
        39.1
      ],
      "type": "gravel"
    },
    {
      "rect": [
        -12,
        40.9,
        -4,
        43.1
      ],
      "type": "gravel"
    },
    {
      "rect": [
        -1.5,
        61,
        1.5,
        90
      ],
      "type": "gravel"
    }
  ]
}
```

## `data/terrain_src/port.json`

```json
{
  "size": [
    120,
    102
  ],
  "origin": [
    -60,
    125
  ],
  "cell": 1.0,
  "base": -2.0,
  "channels": [
    "stone",
    "sand",
    "planks",
    "grass"
  ],
  "default": "sand",
  "features": [
    {
      "type": "flat",
      "rect": [
        -60,
        195,
        60,
        227
      ],
      "height": -3.5
    },
    {
      "type": "flat",
      "rect": [
        10,
        148,
        60,
        195
      ],
      "height": -3.5
    },
    {
      "type": "terrace",
      "rect": [
        15,
        148,
        35,
        212
      ],
      "height": -1.0
    },
    {
      "type": "terrace",
      "rect": [
        -60,
        125,
        60,
        148
      ],
      "height": 0.0
    },
    {
      "type": "hill",
      "center": [
        -45,
        160
      ],
      "radius": 5,
      "height": 0.8
    },
    {
      "type": "hill",
      "center": [
        -20,
        158
      ],
      "radius": 4,
      "height": 0.6
    },
    {
      "type": "hill",
      "center": [
        -52,
        182
      ],
      "radius": 5,
      "height": 0.7
    }
  ],
  "paint": [
    {
      "rect": [
        15,
        148,
        35,
        212
      ],
      "type": "planks"
    },
    {
      "rect": [
        -60,
        125,
        60,
        148.5
      ],
      "type": "stone"
    }
  ]
}
```

## `data/terrain_src/yard.json`

```json
{
  "size": [
    180,
    180
  ],
  "origin": [
    -90,
    -150
  ],
  "cell": 1.0,
  "base": 0.0,
  "channels": [
    "asphalt",
    "paving",
    "grass",
    "gravel"
  ],
  "default": "grass",
  "features": [
    {
      "type": "terrace",
      "rect": [
        22,
        -40,
        52,
        -14
      ],
      "height": 2.0
    },
    {
      "type": "hill",
      "center": [
        0,
        -45
      ],
      "radius": 12,
      "height": 3
    },
    {
      "type": "terrace",
      "rect": [
        -40,
        -118,
        40,
        -72
      ],
      "height": 2.0
    },
    {
      "type": "terrace",
      "rect": [
        -27,
        15,
        -13,
        26
      ],
      "height": 1.0
    }
  ],
  "paint": [
    {
      "rect": [
        -30,
        -16,
        30,
        30
      ],
      "type": "asphalt",
      "soft": 2
    },
    {
      "rect": [
        -90,
        7,
        90,
        17
      ],
      "type": "asphalt"
    },
    {
      "rect": [
        -64,
        -44,
        -20,
        -4
      ],
      "type": "asphalt",
      "soft": 2
    },
    {
      "rect": [
        -25,
        -25,
        5,
        5
      ],
      "type": "paving"
    },
    {
      "rect": [
        22,
        -40,
        52,
        -14
      ],
      "type": "gravel"
    },
    {
      "circle": [
        0,
        -45,
        16
      ],
      "soft": 3,
      "type": "grass"
    },
    {
      "rect": [
        -40,
        -118,
        40,
        -72
      ],
      "type": "paving"
    },
    {
      "rect": [
        -27,
        15,
        -13,
        26
      ],
      "type": "paving"
    },
    {
      "rect": [
        -88,
        -146,
        -66,
        -46
      ],
      "soft": 2,
      "type": "grass"
    },
    {
      "rect": [
        56,
        -146,
        88,
        -46
      ],
      "soft": 2,
      "type": "grass"
    },
    {
      "rect": [
        -60,
        -146,
        52,
        -124
      ],
      "soft": 2,
      "type": "grass"
    },
    {
      "rect": [
        56,
        -40,
        88,
        4
      ],
      "soft": 2,
      "type": "grass"
    }
  ]
}
```

## `data/layout/park.json`

```json
{
  "props": [
    {"model": "fence", "pos": [-14, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-12, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-10, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-8, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-6, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-4, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-2, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [0, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [2, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [4, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [6, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [8, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [10, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [14, 0, 29.9], "rot": 0, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fountain", "pos": [0, 0, 45], "rot": 0, "water": true, "colliders": [{"size": [3.2, 0.45, 3.2], "offset": [0, 0.225, 0]}, {"size": [0.5, 1.4, 0.5], "offset": [0, 0.7, 0]}]},
    {"model": "slide", "pos": [-9, 0, 38], "rot": 0, "colliders": [{"size": [1.3, 0.06, 1.3], "offset": [0, 0.72, 0]}, {"size": [1.2, 0.7, 0.08], "offset": [0, 0.35, 0.56]}, {"size": [0.08, 0.7, 1.2], "offset": [-0.56, 0.35, 0]}, {"size": [0.08, 0.7, 1.2], "offset": [0.56, 0.35, 0]}]},
    {"model": "swings", "pos": [-9, 0, 45], "rot": 90, "colliders": [{"size": [0.2, 1.9, 0.8], "offset": [-1.15, 0.95, 0]}, {"size": [0.2, 1.9, 0.8], "offset": [1.15, 0.95, 0]}]},
    {"model": "sandbox", "pos": [-5, 0, 37.5], "rot": 0, "colliders": [{"size": [2.0, 0.2, 2.0], "offset": [0, 0.1, 0]}]},
    {"model": "kiosk", "pos": [9, 0, 41.5], "rot": 180},
    {"model": "shed", "pos": [11, 0, 56], "rot": 180},
    {"model": "tree", "pos": [-12, 0, 32.5], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "tree", "pos": [12, 0, 51], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "tree", "pos": [-12, 0, 58], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "tree", "pos": [-6, 0, 57], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "tree", "pos": [7, 0, 48], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "bench", "pos": [4, 0, 34], "rot": -90, "colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}]},
    {"model": "bench", "pos": [4, 0, 52], "rot": -90, "colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}]},
    {"model": "bench", "pos": [-4, 0, 52], "rot": 90, "colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}]},
    {"model": "bench", "pos": [-4, 0, 34], "rot": 90, "colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}]},
    {"model": "lamp", "pos": [2, 0, 33], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [2, 0, 41], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [2, 0, 49], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [2, 0, 57], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [-2, 0, 37], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [-2, 0, 53], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [-12, 0, 47.5], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "lamp", "pos": [12, 0, 43], "rot": 0, "colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}]},
    {"model": "flowerbed", "pos": [-5, 0, 49], "rot": 0},
    {"model": "flowerbed", "pos": [5, 0, 41], "rot": 0},
    {"model": "bush", "pos": [-13, 0, 50], "rot": 0, "solid": false},
    {"model": "bush", "pos": [13, 0, 36], "rot": 0, "solid": false},
    {"model": "bush", "pos": [6, 0, 58.5], "rot": 0, "solid": false},
    {"model": "bush", "pos": [-13.5, 0, 40], "rot": 30},
    {"model": "bush", "pos": [9, 0, 59], "rot": 30},
    {"model": "bush", "pos": [-8, 0, 59], "rot": 30},
    {"model": "bush", "pos": [13.5, 0, 47], "rot": 30},
    {"model": "grass", "pos": [-14, 0, 31], "rot": 143, "solid": false},
    {"model": "grass", "pos": [14, 0, 31], "rot": 291, "solid": false},
    {"model": "grass", "pos": [-7, 0, 31.5], "rot": 3, "solid": false},
    {"model": "grass", "pos": [6, 0, 31.5], "rot": 46, "solid": false},
    {"model": "grass", "pos": [-14, 0, 59.5], "rot": 342, "solid": false},
    {"model": "grass", "pos": [3, 0, 59.5], "rot": 149, "solid": false},
    {"model": "grass", "pos": [-10, 0, 53], "rot": 61, "solid": false},
    {"model": "grass", "pos": [10, 0, 34], "rot": 188, "solid": false},
    {"model": "grass", "pos": [-3, 0, 41], "rot": 194, "solid": false},
    {"model": "grass", "pos": [3, 0, 49.5], "rot": 79, "solid": false},
    {"model": "grass", "pos": [8, 0, 53], "rot": 259, "solid": false},
    {"model": "grass", "pos": [-11, 0, 41], "rot": 306, "solid": false},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-44.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-42.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-40.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-38.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-36.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-34.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-32.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-30.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-28.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-26.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-24.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-22.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-20.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-18.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-16.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-14.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-12.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-10.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-8.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-4.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-2.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [0.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [2.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [4.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [6.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [8.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [10.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [12.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [14.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [16.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [18.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [20.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [22.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [24.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [26.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [28.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [30.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [32.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [34.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [36.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [38.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [40.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [42.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [44.0, 0, 125.0], "rot": 180},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 30.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 32.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 34.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 36.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 38.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 40.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 42.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 44.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 46.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 48.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 50.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 52.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 54.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 56.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 58.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 60.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 62.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 64.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 66.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 68.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 70.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 72.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 74.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 76.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 78.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 80.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 82.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 84.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 86.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 88.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 90.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 92.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 94.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 96.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 98.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 100.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 102.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 104.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 106.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 108.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 110.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 112.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 114.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 116.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 118.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 120.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 122.9], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-44.95, 0, 124.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 30.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 32.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 34.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 36.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 38.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 40.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 42.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 44.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 46.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 48.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 50.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 52.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 54.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 56.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 58.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 60.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 62.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 64.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 66.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 68.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 70.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 72.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 74.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 76.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 78.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 80.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 82.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 84.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 86.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 88.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 90.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 92.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 94.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 96.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 98.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 100.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 102.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 104.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 106.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 108.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 110.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 112.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 114.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 116.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 118.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 120.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 122.9], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [44.95, 0, 124.0], "rot": -90},
    {"model": "gazebo", "pos": [0, 0, 92], "rot": 0, "colliders": [{"size": [3.4, 0.3, 3.4], "offset": [0, 0.15, 0]}, {"size": [0.16, 2.2, 0.16], "offset": [1.85, 1.4, 0.0]}, {"size": [0.16, 2.2, 0.16], "offset": [0.925, 1.4, 1.602]}, {"size": [0.16, 2.2, 0.16], "offset": [-0.925, 1.4, 1.602]}, {"size": [0.16, 2.2, 0.16], "offset": [-1.85, 1.4, 0.0]}, {"size": [0.16, 2.2, 0.16], "offset": [-0.925, 1.4, -1.602]}, {"size": [0.16, 2.2, 0.16], "offset": [0.925, 1.4, -1.602]}]},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [2.5, 0, 64], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [2.5, 0, 68], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [2.5, 0, 72], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [2.5, 0, 76], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [2.5, 0, 80], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [2.5, 0, 84], "rot": 0},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-3, 0, 78], "rot": 90},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [5, 0, 98], "rot": 0},
    {"solid": false, "model": "grass", "pos": [-16.4, 0, 69.08], "rot": 14},
    {"solid": false, "model": "grass", "pos": [-19.5, 0, 74.47], "rot": 44},
    {"solid": false, "model": "grass", "pos": [-24.87, 0, 77.59], "rot": 74},
    {"solid": false, "model": "grass", "pos": [-31.08, 0, 77.6], "rot": 104},
    {"solid": false, "model": "grass", "pos": [-36.47, 0, 74.5], "rot": 134},
    {"solid": false, "model": "grass", "pos": [-39.59, 0, 69.13], "rot": 164},
    {"solid": false, "model": "grass", "pos": [-39.6, 0, 62.92], "rot": 193},
    {"solid": false, "model": "grass", "pos": [-36.5, 0, 57.53], "rot": 223},
    {"solid": false, "model": "grass", "pos": [-31.13, 0, 54.41], "rot": 253},
    {"solid": false, "model": "grass", "pos": [-24.92, 0, 54.4], "rot": 283},
    {"solid": false, "model": "grass", "pos": [-19.53, 0, 57.5], "rot": 313},
    {"solid": false, "model": "grass", "pos": [-16.41, 0, 62.87], "rot": 343},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [21, 0, 94], "rot": 0},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [24, 0, 94], "rot": 0},
    {"model": "flowerbed", "pos": [-30, 0, 116], "rot": 0},
    {"model": "flowerbed", "pos": [-10, 0, 116], "rot": 0},
    {"model": "flowerbed", "pos": [10, 0, 116], "rot": 0},
    {"model": "flowerbed", "pos": [30, 0, 116], "rot": 0},
    {"solid": false, "model": "bush", "pos": [-0.7, 0, 94.9], "rot": 75},
    {"solid": false, "model": "bush", "pos": [4.7, 0, 72.3], "rot": 150},
    {"solid": false, "model": "bush", "pos": [-13.7, 0, 82.5], "rot": 90},
    {"solid": false, "model": "bush", "pos": [-6.3, 0, 101.7], "rot": 15},
    {"solid": false, "model": "bush", "pos": [5.3, 0, 92.5], "rot": 270},
    {"solid": false, "model": "bush", "pos": [-9.9, 0, 85.4], "rot": 90},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [5.5, 0, 66.4], "rot": 90},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [30.7, 0, 40.3], "rot": 210},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [33.2, 0, 70.7], "rot": 255},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [29.7, 0, 67.7], "rot": 165},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [20.1, 0, 46.0], "rot": 75},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [37.7, 0, 49.6], "rot": 90},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [41.5, 0, 81.0], "rot": 345},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [27.6, 0, 52.1], "rot": 105},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [24.3, 0, 53.4], "rot": 285},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [37.1, 0, 45.3], "rot": 0},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [27.5, 0, 80.7], "rot": 120},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [18.8, 0, 37.3], "rot": 150},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [34.9, 0, 38.3], "rot": 75},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [23.1, 0, 67.6], "rot": 105},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [19.9, 0, 50.2], "rot": 0},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [28.8, 0, 61.9], "rot": 240},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [30.9, 0, 55.2], "rot": 15},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [35.4, 0, 80.5], "rot": 105},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [24.0, 0, 87.4], "rot": 285},
    {"solid": false, "model": "bush", "pos": [20.9, 0, 54.8], "rot": 120},
    {"solid": false, "model": "bush", "pos": [31.7, 0, 44.0], "rot": 195},
    {"solid": false, "model": "bush", "pos": [34.7, 0, 50.5], "rot": 60},
    {"solid": false, "model": "bush", "pos": [21.0, 0, 76.8], "rot": 105},
    {"solid": false, "model": "bush", "pos": [26.8, 0, 71.6], "rot": 90},
    {"solid": false, "model": "bush", "pos": [29.1, 0, 74.4], "rot": 195},
    {"solid": false, "model": "bush", "pos": [39.6, 0, 69.3], "rot": 225},
    {"solid": false, "model": "bush", "pos": [29.1, 0, 77.2], "rot": 15},
    {"solid": false, "model": "bush", "pos": [36.4, 0, 63.1], "rot": 255},
    {"solid": false, "model": "bush", "pos": [18.7, 0, 65.0], "rot": 270},
    {"solid": false, "model": "bush", "pos": [30.2, 0, 59.1], "rot": 15},
    {"solid": false, "model": "bush", "pos": [22.5, 0, 70.7], "rot": 195},
    {"solid": false, "model": "bush", "pos": [25.0, 0, 46.5], "rot": 165},
    {"solid": false, "model": "bush", "pos": [31.6, 0, 49.1], "rot": 135},
    {"solid": false, "model": "bush", "pos": [-7.9, 0, 114.4], "rot": 75},
    {"solid": false, "model": "bush", "pos": [-18.7, 0, 118.7], "rot": 75},
    {"solid": false, "model": "bush", "pos": [24.9, 0, 114.0], "rot": 90},
    {"solid": false, "model": "bush", "pos": [-30.3, 0, 106.0], "rot": 120},
    {"solid": false, "model": "bush", "pos": [-40.2, 0, 115.1], "rot": 45},
    {"solid": false, "model": "bush", "pos": [25.5, 0, 108.7], "rot": 120},
    {"solid": false, "model": "bush", "pos": [-13.8, 0, 117.7], "rot": 240},
    {"solid": false, "model": "bush", "pos": [-0.6, 0, 121.6], "rot": 15},
    {"solid": false, "model": "grass", "pos": [31.7, 0, 115.0], "rot": 0},
    {"solid": false, "model": "grass", "pos": [20.8, 0, 116.5], "rot": 300},
    {"solid": false, "model": "grass", "pos": [41.3, 0, 121.0], "rot": 60},
    {"solid": false, "model": "grass", "pos": [23.3, 0, 119.8], "rot": 180},
    {"solid": false, "model": "grass", "pos": [-16.3, 0, 120.1], "rot": 240},
    {"solid": false, "model": "grass", "pos": [4.8, 0, 101.0], "rot": 225},
    {"solid": false, "model": "grass", "pos": [26.7, 0, 104.5], "rot": 300},
    {"solid": false, "model": "grass", "pos": [-26.1, 0, 118.6], "rot": 135},
    {"solid": false, "model": "grass", "pos": [36.7, 0, 122.6], "rot": 210},
    {"solid": false, "model": "grass", "pos": [-41.1, 0, 120.9], "rot": 165},
    {"solid": false, "model": "grass", "pos": [-11.6, 0, 111.5], "rot": 300},
    {"solid": false, "model": "grass", "pos": [-25.8, 0, 102.3], "rot": 180},
    {"solid": false, "model": "bush", "pos": [-37.9, 0, 118.3], "rot": 225},
    {"solid": false, "model": "bush", "pos": [16.0, 0, 122.7], "rot": 285},
    {"solid": false, "model": "bush", "pos": [-30.8, 0, 102.8], "rot": 60},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [14.5, 0, 100.3], "rot": 90},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-39.8, 0, 40.6], "rot": 285},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-34.2, 0, 39.9], "rot": 300},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-34.7, 0, 44.1], "rot": 255},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-23.1, 0, 50.4], "rot": 285},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-21.9, 0, 38.5], "rot": 165},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-41.3, 0, 86.1], "rot": 45},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-36.1, 0, 90.2], "rot": 345},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-21.2, 0, 92.0], "rot": 270},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-31.6, 0, 85.0], "rot": 300},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-34.1, 0, 97.8], "rot": 225},
    {"solid": false, "model": "bush", "pos": [-31.6, 0, 49.9], "rot": 90},
    {"solid": false, "model": "bush", "pos": [-21.1, 0, 46.6], "rot": 120}
  ],
  "hideouts": [
    {"kind": "bush", "pos": [-13, 0.25, 50], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [13, 0.25, 36], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [6, 0.25, 58.5], "size": [0.9, 0.5, 0.9]},
    {"kind": "bench", "pos": [4, 0.2, 52], "rot": -90, "size": [1.2, 0.4, 0.35]},
    {"kind": "bench", "pos": [-4, 0.2, 34], "rot": 90, "size": [1.2, 0.4, 0.35]},
    {"kind": "slide", "pos": [-9, 0.3, 38], "size": [0.9, 0.5, 0.9]},
    {"kind": "bench", "pos": [5.5, 0.2, 66.4], "rot": 90, "size": [1.3, 0.4, 0.4]},
    {"kind": "bush", "pos": [30.2, 0.25, 59.1], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [22.5, 0.25, 70.7], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [25.0, 0.25, 46.5], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [31.6, 0.25, 49.1], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [-37.9, 0.25, 118.3], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [16.0, 0.25, 122.7], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [-30.8, 0.25, 102.8], "size": [0.9, 0.5, 0.9]},
    {"kind": "bench", "pos": [14.5, 0.2, 100.3], "rot": 90, "size": [1.3, 0.4, 0.4]},
    {"kind": "bush", "pos": [-31.6, 0.25, 49.9], "size": [0.9, 0.5, 0.9]},
    {"kind": "bush", "pos": [-21.1, 0.25, 46.6], "size": [0.9, 0.5, 0.9]}
  ],
  "spawn_points": [
    {"pos": [8, 0, 39.3], "allowed": [0], "foods": ["popcorn", "bagel"]},
    {"pos": [3, 0, 35.5], "allowed": [0], "foods": ["popcorn", "bagel"]},
    {"pos": [3, 0, 53.5], "allowed": [0], "foods": ["bagel"]},
    {"pos": [-3, 0, 50.5], "allowed": [0], "foods": ["popcorn"]},
    {"pos": [-11, 0, 49], "allowed": [0], "foods": ["bagel"]},
    {"pos": [-1, 0, 31.5], "allowed": [0], "foods": ["popcorn", "bagel"]},
    {"pos": [9.5, 0, 53.8], "allowed": [1], "foods": ["sandwich"]},
    {"pos": [2.3, 0, 42.6], "allowed": [1], "foods": ["corn"]},
    {"pos": [-2.3, 0, 47.4], "allowed": [1], "foods": ["corn"]},
    {"pos": [-7, 0, 40.2], "allowed": [2], "foods": ["cotton_candy"]},
    {"pos": [-6.3, 0, 35.2], "allowed": [2], "foods": ["cotton_candy"]},
    {"pos": [1.45, 0.45, 45], "allowed": [3], "foods": ["cupcake"]},
    {"pos": [0, 0.3, 92], "allowed": [2], "foods": ["cotton_candy"]},
    {"pos": [-11.9, 0, 95.6], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [-4.6, 0, 82.6], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [9.6, 0, 64.9], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [-12.3, 0, 106.1], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [0.2, 0, 68.2], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [33.6, 0, 83.8], "allowed": [0, 1, 3], "foods": ["popcorn", "bagel", "corn", "sandwich", "cupcake"]},
    {"pos": [42.0, 0, 75.5], "allowed": [0, 1, 3], "foods": ["popcorn", "bagel", "corn", "sandwich", "cupcake"]},
    {"pos": [32.1, 0, 36.9], "allowed": [0, 1, 3], "foods": ["popcorn", "bagel", "corn", "sandwich", "cupcake"]},
    {"pos": [37.9, 0, 82.7], "allowed": [0, 1, 3], "foods": ["popcorn", "bagel", "corn", "sandwich", "cupcake"]},
    {"pos": [40.8, 0, 63.8], "allowed": [0, 1, 3], "foods": ["popcorn", "bagel", "corn", "sandwich", "cupcake"]},
    {"pos": [37.7, 0, 55.7], "allowed": [0, 1, 3], "foods": ["popcorn", "bagel", "corn", "sandwich", "cupcake"]},
    {"pos": [30.3, 0, 120.5], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [-41.2, 0, 103.6], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [22.1, 0, 108.4], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [-34.1, 0, 119.4], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [39.8, 0, 108.6], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [-36.8, 0, 121.1], "allowed": [0, 1, 2], "foods": ["popcorn", "bagel", "corn", "sandwich", "cotton_candy"]},
    {"pos": [-27.5, 0, 43.7], "allowed": [0, 1], "foods": ["popcorn", "bagel", "corn", "sandwich"]},
    {"pos": [-33.8, 0, 52.9], "allowed": [0, 1], "foods": ["popcorn", "bagel", "corn", "sandwich"]},
    {"pos": [-31.0, 0, 34.8], "allowed": [0, 1], "foods": ["popcorn", "bagel", "corn", "sandwich"]},
    {"pos": [-34.6, 0, 86.6], "allowed": [1, 2], "foods": ["corn", "sandwich", "cotton_candy"]},
    {"pos": [-25.9, 0, 87.2], "allowed": [1, 2], "foods": ["corn", "sandwich", "cotton_candy"]}
  ],
  "yarn": [
    {"pos": [-1.45, 0.45, 45]},
    {"pos": [0, 0.45, 46.45]},
    {"pos": [-9, 0.75, 38]},
    {"pos": [-5, 0.2, 36.6]},
    {"pos": [12.5, 0, 57.8]},
    {"pos": [-12.6, 0, 33.2]},
    {"pos": [-14, 0, 60]},
    {"pos": [14, 0, 30.6]},
    {"pos": [-14, 0, 30.6]},
    {"pos": [13.7, 0, 52.5]},
    {"pos": [-5.5, 0, 58.5]},
    {"pos": [7.6, 0, 47.3]},
    {"pos": [0.8, 0.3, 92.6]},
    {"pos": [-0.8, 0.3, 91.4]},
    {"pos": [13.6, 0, 107.5]},
    {"pos": [-10.2, 0, 78.4]},
    {"pos": [25.8, 0, 84.6]},
    {"pos": [27.9, 0, 48.8]},
    {"pos": [35.4, 0, 75.5]},
    {"pos": [27.1, 0, 37.5]},
    {"pos": [-6.6, 0, 118.5]},
    {"pos": [5.6, 0, 121.2]},
    {"pos": [8.0, 0, 113.5]},
    {"pos": [-3.4, 0, 107.7]},
    {"pos": [12.9, 0, 119.1]},
    {"pos": [-41.1, 0, 45.8]},
    {"pos": [-40.4, 0, 36.5]},
    {"pos": [-21.9, 0, 97.8]}
  ],
  "hazards": [
    {"type": "pigeons", "pos": [3.2, 0, 47.5]},
    {"type": "pigeons", "pos": [-3.5, 0, 33.2]},
    {"type": "gardener", "pos": [11, 0, 54.3], "rot": 180, "path": [[11, 50], [12, 39], [6, 38.5], [1, 38.5], [1, 52], [10, 53]]},
    {"type": "sprinkler", "pos": [-7, 0, 52], "offset": 0},
    {"type": "sprinkler", "pos": [7, 0, 33.5], "offset": 7},
    {"type": "sprinkler", "pos": [9, 0, 46], "offset": 14},
    {"type": "kid", "pos": [-7.5, 0, 41], "rot": 90},
    {"type": "guard", "pos": [0, 0, 31], "rot": 180, "path": [[0, 31], [0, 58], [-13, 58], [-13, 45], [0, 45], [13, 45], [13, 31]]},
    {"type": "pigeons", "pos": [-4, 0, 80]},
    {"type": "kid", "pos": [-22, 0, 82], "rot": 180},
    {"type": "gardener", "pos": [16.5, 0, 40], "rot": 0, "path": [[16.5, 40], [16.5, 86], [30, 90], [16.5, 86]]},
    {"type": "pigeons", "pos": [20, 0, 92]},
    {"type": "sprinkler", "pos": [-20, 0, 110], "offset": 3},
    {"type": "sprinkler", "pos": [20, 0, 112], "offset": 10},
    {"type": "sprinkler", "pos": [-30, 0, 40], "offset": 17},
    {"type": "guard", "pos": [-10, 0, 70], "rot": 0, "path": [[-10, 70], [-12, 104], [12, 104], [14, 70]]}
  ],
  "decals": [
  ],
  "gates": [
    {"pos": [12, 0, 29.9], "rot": 0, "size": [2.2, 2.6, 0.3], "satiety": 25, "label": "Ворота в парк открыты!"},
    {"pos": [-6, 0, 125], "rot": 0, "size": [2.2, 2.6, 0.3], "satiety": 50, "label": "Ворота в порт открыты!"}
  ],
  "water_zones": [
    {"pos": [-28, -0.5, 66], "size": [22, 2.0, 22]}
  ],
  "shore": [
    {"pos": [-15.5, 0, 66.0]},
    {"pos": [-19.16, 0, 74.84]},
    {"pos": [-28.0, 0, 78.5]},
    {"pos": [-36.84, 0, 74.84]},
    {"pos": [-40.5, 0, 66.0]},
    {"pos": [-36.84, 0, 57.16]},
    {"pos": [-28.0, 0, 53.5]},
    {"pos": [-19.16, 0, 57.16]}
  ],
  "floaters": [
  ]
}
```

## `data/layout/port.json`

```json
{
  "props": [
    {"model": "retaining_wall2", "pos": [16.5, -2.3, 212.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [20.5, -2.3, 212.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [24.5, -2.3, 212.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [28.5, -2.3, 212.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [32.5, -2.3, 212.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [33.5, -2.3, 212.45], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 149.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 153.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 157.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 161.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 165.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 169.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 173.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 181.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 185.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 189.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 193.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 197.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 201.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 205.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.5, -2.3, 209.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [14.55, -2.3, 210.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 149.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 153.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 157.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 161.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 169.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 173.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 177.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 185.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 189.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 193.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 197.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 201.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 205.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, -2.3, 209.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [35.45, -2.3, 210.5], "rot": 90, "snap": false},
    {"model": "terrace_stairs1", "pos": [25, 0, 149.5], "rot": 0},
    {"model": "bollard", "pos": [16, 0, 160], "rot": 0},
    {"model": "bollard", "pos": [16, 0, 180], "rot": 0},
    {"model": "bollard", "pos": [16, 0, 200], "rot": 0},
    {"model": "bollard", "pos": [34, 0, 160], "rot": 0},
    {"model": "bollard", "pos": [34, 0, 180], "rot": 0},
    {"model": "bollard", "pos": [34, 0, 200], "rot": 0},
    {"model": "pontoon", "pos": [35.7, -1.75, 165], "rot": 0, "snap": false, "colliders": [{"size": [1.4, 0.3, 1.6], "offset": [0, 0.15, 0]}]},
    {"model": "pontoon", "pos": [35.7, -1.75, 181], "rot": 0, "snap": false, "colliders": [{"size": [1.4, 0.3, 1.6], "offset": [0, 0.15, 0]}]},
    {"model": "pontoon", "pos": [14.3, -1.75, 176], "rot": 0, "snap": false, "colliders": [{"size": [1.4, 0.3, 1.6], "offset": [0, 0.15, 0]}]},
    {"outline": true, "model": "box", "pos": [24.6, 0, 209.8], "rot": 0},
    {"outline": true, "model": "box", "pos": [25.4, 0, 209.8], "rot": 0},
    {"outline": true, "model": "box", "pos": [25.0, 0.3, 209.8], "rot": 15},
    {"model": "retaining_wall3", "pos": [-58.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-54.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-50.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-46.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-34.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-30.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-26.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-22.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-18.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-10.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-6.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [-2.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [5.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [9.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [13.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [17.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [21.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [29.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [33.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [37.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [41.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [45.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [49.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [53.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [57.5, -2.3, 148.5], "rot": 0, "snap": false},
    {"model": "retaining_wall3", "pos": [58.5, -2.3, 148.45], "rot": 0, "snap": false},
    {"model": "terrace_stairs2", "pos": [-40, 0, 151.0], "rot": 0},
    {"model": "terrace_stairs2", "pos": [-15, 0, 151.0], "rot": 0},
    {"model": "ramp2", "pos": [2, 0, 152.289], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 126.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 128.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 130.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 132.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 134.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 136.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 138.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 140.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 142.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 144.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 146.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-59.95, 0, 147.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 126.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 128.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 130.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 132.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 134.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 136.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 138.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 140.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 142.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 144.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [60.0, 0, 146.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [59.95, 0, 147.0], "rot": -90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-59.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-57.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-55.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-53.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-51.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-49.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-47.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-45.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [45.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [47.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [49.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [51.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [53.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [55.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [57.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [59.0, 0, 125.1], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [-50, 0, 146], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [-30, 0, 146], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [-10, 0, 146], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [10, 0, 146], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [30, 0, 146], "rot": 0},
    {"colliders": [{"size": [0.2, 2.6, 0.2], "offset": [0, 1.3, 0]}], "model": "lamp", "pos": [50, 0, 146], "rot": 0},
    {"model": "kiosk", "pos": [-30, 0, 131], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-27, 0, 131], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [12, 0, 131], "rot": 0},
    {"model": "barrel", "pos": [44, 0, 132], "rot": 0, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"model": "barrel", "pos": [-48, 0, 140], "rot": 0, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 149.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 151.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 153.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 155.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 157.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 159.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 161.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 163.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 165.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 167.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 169.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 171.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 173.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 175.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 177.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 179.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 181.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 183.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 185.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 187.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 189.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 191.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-60.0, 0, 193.0], "rot": 90},
    {"colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}], "model": "fence", "pos": [-59.95, 0, 194.0], "rot": 90},
    {"model": "boat_upturned", "pos": [-8, 0, 170], "rot": 30, "colliders": [{"size": [1.6, 0.12, 4.2], "offset": [0, 0.6, 0]}, {"size": [0.12, 0.6, 4.2], "offset": [-0.74, 0.3, 0]}, {"size": [0.12, 0.6, 4.2], "offset": [0.74, 0.3, 0]}]},
    {"outline": true, "model": "box", "pos": [20.7, 0, 191.1], "rot": 255},
    {"outline": true, "model": "box", "pos": [28.3, 0, 201.0], "rot": 90},
    {"outline": true, "model": "box", "pos": [19.3, 0, 163.8], "rot": 345},
    {"outline": true, "model": "box", "pos": [29.2, 0, 157.8], "rot": 135},
    {"outline": true, "model": "box", "pos": [32.2, 0, 192.2], "rot": 300},
    {"outline": true, "model": "box", "pos": [31.5, 0, 152.6], "rot": 30},
    {"outline": true, "model": "box", "pos": [32.2, 0, 160.0], "rot": 240},
    {"outline": true, "model": "box", "pos": [33.5, 0, 199.5], "rot": 0},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-43.3, 0, 132.6], "rot": 0},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-10.7, 0, 143.3], "rot": 0},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [7.5, 0, 139.6], "rot": 0},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [50.9, 0, 136.4], "rot": 0},
    {"outline": true, "model": "box", "pos": [-51.9, 0, 133.6], "rot": 270},
    {"outline": true, "model": "box", "pos": [-17.7, 0, 128.8], "rot": 195},
    {"outline": true, "model": "box", "pos": [-1.1, 0, 137.5], "rot": 15},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-17.3, 0, 132.3], "rot": 90},
    {"colliders": [{"size": [1.5, 0.08, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-38.7, 0, 143.0], "rot": 0},
    {"model": "deckchair", "pos": [1.0, 0, 188.6], "rot": 90},
    {"model": "deckchair", "pos": [-13.0, 0, 156.5], "rot": 270},
    {"model": "deckchair", "pos": [-40.6, 0, 185.0], "rot": 180},
    {"model": "deckchair", "pos": [-54.9, 0, 162.3], "rot": 285},
    {"model": "deckchair", "pos": [-3.4, 0, 162.3], "rot": 15},
    {"model": "deckchair", "pos": [-6.1, 0, 182.8], "rot": 255},
    {"colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}], "model": "umbrella", "pos": [1.2, 0, 157.5], "rot": 135},
    {"colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}], "model": "umbrella", "pos": [-48.9, 0, 173.8], "rot": 120},
    {"colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}], "model": "umbrella", "pos": [-4.4, 0, 173.8], "rot": 30},
    {"colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}], "model": "umbrella", "pos": [-38.2, 0, 190.5], "rot": 165},
    {"outline": true, "model": "box", "pos": [-2.6, 0, 159.0], "rot": 120},
    {"outline": true, "model": "box", "pos": [-54.5, 0, 172.5], "rot": 105}
  ],
  "hideouts": [
    {"kind": "barrel", "pos": [44, 0.2, 132.75], "size": [0.6, 0.4, 0.6]},
    {"kind": "barrel", "pos": [-48, 0.2, 140.75], "size": [0.6, 0.4, 0.6]},
    {"kind": "boat", "pos": [-8, 0.2, 170], "rot": 30, "size": [1.2, 0.4, 3.6]},
    {"kind": "box", "pos": [32.2, 0.2, 192.85], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [31.5, 0.2, 153.25], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [32.2, 0.2, 160.65], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [33.5, 0.2, 200.15], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-51.9, 0.2, 134.25], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-17.7, 0.2, 129.45], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-1.1, 0.2, 138.15], "size": [0.6, 0.4, 0.6]},
    {"kind": "bench", "pos": [-17.3, 0.2, 132.3], "rot": 90, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [-38.7, 0.2, 143.0], "rot": 0, "size": [1.3, 0.4, 0.4]},
    {"kind": "box", "pos": [-2.6, 0.2, 159.65], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-54.5, 0.2, 173.15], "size": [0.6, 0.4, 0.6]}
  ],
  "spawn_points": [
    {"pos": [37.3, -1.55, 164], "allowed": [1], "foods": ["squid"], "snap": false},
    {"pos": [12.7, -1.55, 177], "allowed": [1], "foods": ["squid", "fish_sandwich"], "snap": false},
    {"pos": [37.3, -1.55, 182], "allowed": [2], "foods": ["sushi"], "snap": false},
    {"pos": [-30, 0, 133.6], "allowed": [0], "foods": ["fries"]},
    {"pos": [16.5, 0, 157.6], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [28.3, 0, 209.9], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [17.5, 0, 197.6], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [32.0, 0, 165.7], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [18.5, 0, 202.6], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [32.2, 0, 183.0], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [32.0, 0, 188.3], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [20.7, 0, 176.9], "allowed": [0, 1, 2], "foods": ["shrimp", "fries", "squid", "fish_sandwich", "sushi"]},
    {"pos": [40.8, 0, 127.6], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-20.9, 0, 129.8], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [6.9, 0, 136.6], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [37.6, 0, 131.0], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-34.0, 0, 141.4], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-14.4, 0, 139.9], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-39.8, 0, 129.6], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-33.0, 0, 134.6], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-30.7, 0, 140.9], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [10.7, 0, 134.7], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [16.3, 0, 134.7], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-54.6, 0, 154.2], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-10.0, 0, 157.2], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-10.7, 0, 186.8], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [8.0, 0, 184.6], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-30.0, 0, 177.3], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-3.0, 0, 180.9], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-50.8, 0, 165.0], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [7.7, 0, 171.4], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-28.3, 0, 153.1], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-1.7, 0, 169.2], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-26.1, 0, 163.2], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]},
    {"pos": [-27.6, 0, 188.2], "allowed": [0, 1], "foods": ["shrimp", "fries", "squid", "fish_sandwich"]}
  ],
  "yarn": [
    {"pos": [37.3, -1.55, 166.5], "snap": false},
    {"pos": [12.7, -1.55, 174.5], "snap": false},
    {"pos": [19.2, 0, 171.4]},
    {"pos": [24.3, 0, 150.1]},
    {"pos": [20.0, 0, 179.9]},
    {"pos": [28.6, 0, 176.7]},
    {"pos": [29.7, 0, 171.0]},
    {"pos": [28.7, 0, 187.8]},
    {"pos": [-21.2, 0, 135.3]},
    {"pos": [-50.0, 0, 127.8]},
    {"pos": [48.9, 0, 138.8]},
    {"pos": [57.0, 0, 134.0]},
    {"pos": [-50.9, 0, 136.5]},
    {"pos": [52.4, 0, 129.7]},
    {"pos": [-22.6, 0, 160.6]},
    {"pos": [-33.2, 0, 171.6]},
    {"pos": [-45.4, 0, 175.3]},
    {"pos": [-55.7, 0, 185.0]},
    {"pos": [-46.2, 0, 157.0]},
    {"pos": [-19.1, 0, 165.0]},
    {"pos": [0.4, 0, 172.4]},
    {"pos": [-23.6, 0, 185.5]},
    {"pos": [-43.9, 0, 182.1]},
    {"pos": [-15.2, 0, 169.7]},
    {"pos": [5.3, 0, 153.9]}
  ],
  "hazards": [
    {"type": "forklift", "pos": [25, 0, 153], "rot": 0, "path": [[25, 153], [25, 207]]},
    {"type": "gull", "pos": [30, 0, 192], "phase": 0.0},
    {"type": "gull", "pos": [-30, 0, 170], "phase": 2.0},
    {"type": "wave", "pos": [-25, -2.0, 194.2], "snap": false, "width": 68, "inland": -1},
    {"type": "crab", "pos": [-50, 0, 175]},
    {"type": "crab", "pos": [-35, 0, 186]},
    {"type": "crab", "pos": [-15, 0, 179]},
    {"type": "crab", "pos": [-4, 0, 160]},
    {"type": "crab", "pos": [-42, 0, 164], "night_only": true},
    {"type": "crab", "pos": [-24, 0, 190], "night_only": true}
  ],
  "decals": [
  ],
  "gates": [
  ],
  "water_zones": [
    {"pos": [0.0, -2.3, 210.5], "size": [120, 2.0, 33]},
    {"pos": [34.5, -2.3, 171.5], "size": [51, 2.0, 47]}
  ],
  "shore": [
    {"pos": [-55, 0, 192]},
    {"pos": [-45, 0, 192]},
    {"pos": [-35, 0, 192]},
    {"pos": [-25, 0, 192]},
    {"pos": [-15, 0, 192]},
    {"pos": [-5, 0, 192]},
    {"pos": [5, 0, 192]},
    {"pos": [25, 0, 155]},
    {"pos": [25, 0, 165]},
    {"pos": [25, 0, 175]},
    {"pos": [25, 0, 185]},
    {"pos": [25, 0, 195]},
    {"pos": [25, 0, 205]},
    {"pos": [40, 0, 145]},
    {"pos": [50, 0, 145]},
    {"pos": [57, 0, 145]},
    {"pos": [8, 0, 155]},
    {"pos": [8, 0, 165]},
    {"pos": [8, 0, 175]},
    {"pos": [8, 0, 185]}
  ],
  "floaters": [
    {"model": "boat", "pos": [37.3, -2.1, 165], "rot": 0, "period": 3.4, "phase": 0.0, "colliders": [{"size": [1.6, 0.75, 4.2], "offset": [0, 0.075, 0]}]},
    {"model": "boat", "pos": [37.3, -2.1, 181], "rot": 0, "period": 3.8, "phase": 1.7, "colliders": [{"size": [1.6, 0.75, 4.2], "offset": [0, 0.075, 0]}]},
    {"model": "boat", "pos": [12.7, -2.1, 176], "rot": 0, "period": 3.1, "phase": 3.1, "colliders": [{"size": [1.6, 0.75, 4.2], "offset": [0, 0.075, 0]}]},
    {"model": "barrel", "pos": [37.6, -2.6999999999999997, 169], "rot": 0, "amp": 0.06, "roll": 4.0, "period": 2.6, "phase": 0.0, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"model": "barrel", "pos": [37.6, -2.6999999999999997, 171], "rot": 0, "amp": 0.06, "roll": 4.0, "period": 2.8000000000000003, "phase": 1.1, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"model": "barrel", "pos": [37.6, -2.6999999999999997, 173], "rot": 0, "amp": 0.06, "roll": 4.0, "period": 3.0, "phase": 2.2, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"model": "barrel", "pos": [37.6, -2.6999999999999997, 175], "rot": 0, "amp": 0.06, "roll": 4.0, "period": 3.2, "phase": 3.3000000000000003, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"model": "barrel", "pos": [37.6, -2.6999999999999997, 177], "rot": 0, "amp": 0.06, "roll": 4.0, "period": 3.4000000000000004, "phase": 4.4, "colliders": [{"size": [0.7, 0.7, 0.7], "offset": [0, 0.35, 0]}]},
    {"model": "buoy", "pos": [-40, -2.3, 215], "rot": 0, "amp": 0.08, "period": 2.9, "phase": -4.0, "solid": false},
    {"model": "buoy", "pos": [-10, -2.3, 215], "rot": 0, "amp": 0.08, "period": 2.9, "phase": -1.0, "solid": false},
    {"model": "buoy", "pos": [20, -2.3, 215], "rot": 0, "amp": 0.08, "period": 2.9, "phase": 2.0, "solid": false},
    {"model": "buoy", "pos": [50, -2.3, 215], "rot": 0, "amp": 0.08, "period": 2.9, "phase": 5.0, "solid": false}
  ]
}
```

## `data/layout/terrain_demo.json`

```json
{
  "note": "Демо террасы на data/terrain/demo.json: терраса x −18…−6, z −18…−8, высота 2 м.",
  "props": [
    {
      "model": "ramp2",
      "pos": [
        -1.711,
        0,
        -10
      ],
      "rot": 90
    },
    {
      "model": "terrace_stairs2",
      "pos": [
        -3.0,
        0,
        -15.5
      ],
      "rot": 90
    },
    {
      "model": "retaining_wall2",
      "pos": [
        -5.5,
        0,
        -17.6
      ],
      "rot": 90,
      "snap": false
    },
    {
      "model": "retaining_wall2",
      "pos": [
        -12,
        0,
        -7.5
      ],
      "rot": 0,
      "snap": false
    },
    {
      "model": "retaining_wall2",
      "pos": [
        -16,
        0,
        -7.5
      ],
      "rot": 0,
      "snap": false
    },
    {
      "model": "bin",
      "pos": [
        8,
        0,
        8
      ]
    },
    {
      "model": "bench",
      "pos": [
        -12,
        0,
        -12
      ]
    }
  ]
}
```

## `data/layout/yard.json`

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
    {"model": "stairs", "pos": [-11.3, 0, -11.5], "rot": 0, "colliders": [{"size": [1.2, 0.25, 0.5], "offset": [0, 0.125, 0]}, {"size": [1.2, 0.5, 0.5], "offset": [0, 0.25, 0.5]}, {"size": [1.2, 0.75, 0.5], "offset": [0, 0.375, 1.0]}, {"size": [1.2, 1.0, 0.5], "offset": [0, 0.5, 1.5]}, {"size": [1.2, 0.12, 1.2], "offset": [0, 0.94, 2.55]}]},
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
    {"model": "tree", "pos": [9, 0, -6], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "tree", "pos": [-9, 0, 10], "rot": 0, "colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}]},
    {"model": "bush", "pos": [7, 0, -10], "rot": 0},
    {"model": "bush", "pos": [-3, 0, 10], "rot": 40},
    {"model": "bush", "pos": [10, 0, 0], "rot": 0},
    {"model": "fence", "pos": [10, 0, 7], "rot": 90},
    {"model": "fence", "pos": [10, 0, 9], "rot": 90},
    {"model": "puddle", "water": true, "pos": [3, 0, 3], "rot": 0},
    {"model": "puddle", "water": true, "pos": [-5, 0, -5], "rot": 60},
    {"model": "arch", "pos": [0, 0, 10.5], "rot": 0, "colliders": [{"size": [0.5, 2.6, 0.6], "offset": [-1.45, 1.3, 0]}, {"size": [0.5, 2.6, 0.6], "offset": [1.45, 1.3, 0]}]},
    {"model": "wall", "pos": [0, 0, 28], "rot": 180},
    {"model": "wall", "pos": [6, 0, 28], "rot": 180},
    {"model": "wall", "pos": [-6, 0, 28], "rot": 180},
    {"model": "cafe_sign", "pos": [0, 0, 26.5], "rot": 180},
    {"model": "cafe_table", "pos": [-4, 0, 17], "colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}]},
    {"model": "cafe_table", "pos": [0, 0, 17], "colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}]},
    {"model": "cafe_table", "pos": [4, 0, 17], "colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}]},
    {"model": "cafe_table", "pos": [-2, 0, 21], "colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}]},
    {"model": "cafe_table", "pos": [2, 0, 21], "colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}]},
    {"model": "chair", "pos": [-4, 0, 16.2], "rot": 180, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [-4, 0, 17.8], "rot": 0, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [0, 0, 16.2], "rot": 180, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [0, 0, 17.8], "rot": 0, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [4, 0, 16.2], "rot": 180, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [4, 0, 17.8], "rot": 0, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [-2, 0, 21.8], "rot": 0, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "chair", "pos": [2, 0, 21.8], "rot": 0, "outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}]},
    {"model": "umbrella", "pos": [-3.3, 0, 17.7], "colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}]},
    {"model": "umbrella", "pos": [4.7, 0, 17.7], "colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}]},
    {"model": "umbrella", "pos": [2.7, 0, 21.7], "colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}]},
    {"model": "bin", "pos": [8, 0, 24], "rot": 0, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bin", "pos": [9, 0, 24], "rot": 0, "colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}]},
    {"model": "bush", "pos": [-8, 0, 24], "rot": 0},
    {"model": "bush", "pos": [8, 0, 14.5], "rot": 20},
    {"model": "puddle", "water": true, "pos": [-6, 0, 19], "rot": 30},
    {"model": "bush", "pos": [-7.5, 0, -13.0], "rot": 294},
    {"model": "bush", "pos": [-2.5, 0, -13.0], "rot": 193},
    {"model": "bush", "pos": [0.0, 0, -13.0], "rot": 0},
    {"model": "bush", "pos": [8.8, 0, -13.0], "rot": 277},
    {"model": "bush", "pos": [4.6, 0, -13.0], "rot": 28},
    {"model": "bush", "pos": [-11.0, 0, -5.0], "rot": 90},
    {"model": "bush", "pos": [-11.0, 0, 0.5], "rot": 90},
    {"model": "grass", "pos": [-12.5, 0, -12.5], "rot": 205, "solid": false},
    {"model": "grass", "pos": [12.5, 0, -12.5], "rot": 90, "solid": false},
    {"model": "grass", "pos": [-12.5, 0, 9], "rot": 210, "solid": false},
    {"model": "grass", "pos": [12.5, 0, 9], "rot": 95, "solid": false},
    {"model": "grass", "pos": [-6, 0, -12.8], "rot": 184, "solid": false},
    {"model": "grass", "pos": [6, 0, -12.8], "rot": 100, "solid": false},
    {"model": "grass", "pos": [-12.8, 0, -3], "rot": 350, "solid": false},
    {"model": "grass", "pos": [12.8, 0, -3], "rot": 267, "solid": false},
    {"model": "grass", "pos": [3.5, 0, 4.2], "rot": 256, "solid": false},
    {"model": "grass", "pos": [-3, 0, 1.5], "rot": 226, "solid": false},
    {"model": "grass", "pos": [8.5, 0, -5], "rot": 5, "solid": false},
    {"model": "grass", "pos": [-8.5, 0, 9.5], "rot": 71, "solid": false},
    {"model": "ivy", "pos": [-6.0, 2.2, -13.78], "rot": 0, "solid": false},
    {"model": "ivy", "pos": [0.0, 2.2, -13.78], "rot": 0, "solid": false},
    {"model": "ivy", "pos": [8.0, 2.2, -13.78], "rot": 0, "solid": false},
    {"model": "wall", "pos": [-87.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-81.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-75.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-69.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-63.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-57.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-51.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-45.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-39.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-33.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-27.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-21.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-15.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-9.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-3.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [3.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [9.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [15.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [21.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [27.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [33.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [39.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [45.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [51.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [57.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [63.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [69.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [75.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [81.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [87.0, 0, -150.0], "rot": 0},
    {"model": "wall", "pos": [-90.0, 0, -147.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -141.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -135.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -129.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -123.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -117.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -111.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -105.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -99.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -93.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -87.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -81.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -75.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -69.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -63.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -57.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -51.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -45.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -39.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -33.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -27.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -21.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -15.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -9.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, -3.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, 3.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, 9.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, 15.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, 21.0], "rot": 90},
    {"model": "wall", "pos": [-90.0, 0, 27.0], "rot": 90},
    {"model": "wall", "pos": [90.0, 0, -147.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -141.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -135.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -129.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -123.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -117.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -111.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -105.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -99.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -93.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -87.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -81.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -75.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -69.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -63.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -57.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -51.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -45.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -39.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -33.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -27.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -21.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -15.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -9.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, -3.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, 3.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, 9.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, 15.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, 21.0], "rot": -90},
    {"model": "wall", "pos": [90.0, 0, 27.0], "rot": -90},
    {"model": "wall", "pos": [-87.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-81.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-75.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-69.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-63.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-57.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-51.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-45.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-39.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-33.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-27.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-21.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [-18.0, 0, 29.95], "rot": 180},
    {"model": "wall", "pos": [18.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [24.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [30.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [36.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [42.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [48.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [54.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [60.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [66.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [72.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [78.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [84.0, 0, 30.0], "rot": 180},
    {"model": "wall", "pos": [87.0, 0, 29.95], "rot": 180},
    {"model": "fence", "pos": [-89.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-87.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-85.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-83.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-81.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-79.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-77.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-75.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-73.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-71.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-69.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-67.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-65.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-63.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-61.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-59.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-57.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-55.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-53.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-51.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-49.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-47.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-45.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-43.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-41.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-39.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-37.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-35.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-33.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-31.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-29.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-27.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-25.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-23.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-21.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-19.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-17.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-15.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-13.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-11.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-9.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-7.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-5.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-3.0, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [-2.7, 0, 10.85], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [2.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [4.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [6.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [8.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [10.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [12.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [14.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [16.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [18.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [20.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [22.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [24.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [26.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [28.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [30.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [32.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [34.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [36.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [38.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [40.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [42.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [44.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [46.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [48.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [50.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [52.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [54.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [56.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [58.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [60.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [62.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [64.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [66.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [68.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [70.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [72.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [74.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [76.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [78.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [80.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [82.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [84.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [86.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [88.7, 0, 10.9], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"model": "fence", "pos": [89.0, 0, 10.85], "rot": 180, "colliders": [{"size": [2.0, 1.8, 0.12], "offset": [0, 0.9, 0]}]},
    {"outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}], "model": "car", "pos": [-30, 0, 8.5], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}], "model": "car", "pos": [-48, 0, 8.5], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}], "model": "car", "pos": [32, 0, 8.5], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}], "model": "car", "pos": [56, 0, 15.5], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}], "model": "car", "pos": [-66, 0, 15.5], "rot": 90},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-36, 0, 8], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-35, 0, 8], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [44, 0, 8], "rot": 0},
    {"model": "lamp", "pos": [-40, 0, 9], "rot": 0},
    {"model": "lamp", "pos": [40, 0, 9], "rot": 0},
    {"model": "lamp", "pos": [70, 0, 15], "rot": 0},
    {"model": "lamp", "pos": [-75, 0, 15], "rot": 0},
    {"model": "garage", "pos": [-58.0, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-54.8, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-51.6, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-48.4, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-45.2, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-42.0, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-38.8, 0, -30.0], "rot": 0},
    {"model": "garage", "pos": [-35.6, 0, -30.0], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-59.97, 0, -28.2], "rot": 0},
    {"outline": true, "model": "box", "pos": [-59.97, 1.12, -28.2], "rot": 0},
    {"outline": true, "model": "box", "pos": [-59.97, 1.42, -28.2], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-60.81, 0, -28.2], "rot": 0},
    {"outline": true, "model": "box", "pos": [-61.58, 0, -28.2], "rot": 0},
    {"outline": true, "model": "box", "pos": [-61.58, 0.3, -28.2], "rot": 0},
    {"model": "garage", "pos": [-35.6, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-38.8, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-42.0, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-45.2, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-48.4, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-51.6, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-54.8, 0, -36.0], "rot": 180},
    {"model": "garage", "pos": [-58.0, 0, -36.0], "rot": 180},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-33.63, 0, -37.8], "rot": 180},
    {"outline": true, "model": "box", "pos": [-33.63, 1.12, -37.8], "rot": 180},
    {"outline": true, "model": "box", "pos": [-33.63, 1.42, -37.8], "rot": 180},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-32.79, 0, -37.8], "rot": 180},
    {"outline": true, "model": "box", "pos": [-32.02, 0, -37.8], "rot": 180},
    {"outline": true, "model": "box", "pos": [-32.02, 0.3, -37.8], "rot": 180},
    {"model": "lamp", "pos": [-46, 0, -24], "rot": 0},
    {"model": "retaining_wall2", "pos": [23.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [27.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [31.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [39.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [43.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [47.5, 0.0, -40.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [50.5, 0.0, -40.45], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [23.5, 0.0, -13.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [35.5, 0.0, -13.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [39.5, 0.0, -13.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [43.5, 0.0, -13.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [47.5, 0.0, -13.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [50.5, 0.0, -13.55], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -38.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -34.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -30.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -22.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -18.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [21.55, 0.0, -15.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.5, 0.0, -38.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.5, 0.0, -34.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.5, 0.0, -30.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.5, 0.0, -26.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.5, 0.0, -22.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.5, 0.0, -18.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [52.45, 0.0, -15.5], "rot": 90, "snap": false},
    {"model": "terrace_stairs2", "pos": [30, 0, -11.0], "rot": 0},
    {"model": "ramp2", "pos": [17.711, 0, -27], "rot": -90},
    {"model": "sandbox", "pos": [32, 0, -31], "rot": 0},
    {"model": "swings", "pos": [42, 0, -22], "rot": 0},
    {"model": "slide", "pos": [45, 0, -33], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [27, 0, -22], "rot": 90},
    {"model": "lamp", "pos": [36, 0, -17], "rot": 0},
    {"model": "lamp", "pos": [49, 0, -37], "rot": 0},
    {"model": "retaining_wall2", "pos": [-38.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-34.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-30.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-26.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-22.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-18.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-14.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-10.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-6.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-2.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [1.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [5.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [9.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [13.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [17.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [25.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [29.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [33.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [37.5, 0.0, -118.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [38.5, 0.0, -118.45], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-38.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-34.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-30.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-26.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-22.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-18.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-6.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-2.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [1.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [5.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [9.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [13.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [21.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [25.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [29.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [33.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [37.5, 0.0, -71.5], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [38.5, 0.0, -71.55], "rot": 0, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -116.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -112.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -108.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -104.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -100.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -96.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -92.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -88.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -84.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -80.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.5, 0.0, -76.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [-40.45, 0.0, -73.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -116.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -112.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -108.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -104.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -100.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -88.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -84.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -80.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.5, 0.0, -76.5], "rot": 90, "snap": false},
    {"model": "retaining_wall2", "pos": [40.45, 0.0, -73.5], "rot": 90, "snap": false},
    {"model": "terrace_stairs2", "pos": [-12, 0, -69.0], "rot": 0},
    {"model": "terrace_stairs2", "pos": [18, 0, -69.0], "rot": 0},
    {"model": "ramp2", "pos": [44.289, 0, -95], "rot": 90},
    {"model": "wall", "pos": [-35.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [-29.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [-23.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [-17.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [-11.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [-5.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [1.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [7.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [13.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [19.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [25.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [31.0, 0, -116.0], "rot": 0},
    {"model": "wall", "pos": [35.0, 0, -115.95], "rot": 0},
    {"colliders": [{"size": [1.2, 0.25, 0.5], "offset": [0, 0.125, 0]}, {"size": [1.2, 0.5, 0.5], "offset": [0, 0.25, 0.5]}, {"size": [1.2, 0.75, 0.5], "offset": [0, 0.375, 1.0]}, {"size": [1.2, 1.0, 0.5], "offset": [0, 0.5, 1.5]}, {"size": [1.2, 0.12, 1.2], "offset": [0, 0.94, 2.55]}], "model": "stairs", "pos": [-25, 0, -113.5], "rot": 0},
    {"colliders": [{"size": [1.2, 0.25, 0.5], "offset": [0, 0.125, 0]}, {"size": [1.2, 0.5, 0.5], "offset": [0, 0.25, 0.5]}, {"size": [1.2, 0.75, 0.5], "offset": [0, 0.375, 1.0]}, {"size": [1.2, 1.0, 0.5], "offset": [0, 0.5, 1.5]}, {"size": [1.2, 0.12, 1.2], "offset": [0, 0.94, 2.55]}], "model": "stairs", "pos": [0, 0, -113.5], "rot": 0},
    {"colliders": [{"size": [1.2, 0.25, 0.5], "offset": [0, 0.125, 0]}, {"size": [1.2, 0.5, 0.5], "offset": [0, 0.25, 0.5]}, {"size": [1.2, 0.75, 0.5], "offset": [0, 0.375, 1.0]}, {"size": [1.2, 1.0, 0.5], "offset": [0, 0.5, 1.5]}, {"size": [1.2, 0.12, 1.2], "offset": [0, 0.94, 2.55]}], "model": "stairs", "pos": [25, 0, -113.5], "rot": 0},
    {"model": "flowerbed", "pos": [-22, 0, -100], "rot": 0},
    {"model": "flowerbed", "pos": [-18, 0, -100], "rot": 0},
    {"model": "lamp", "pos": [-10, 0, -85], "rot": 0},
    {"model": "lamp", "pos": [20, 0, -85], "rot": 0},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [5, 0, -100], "rot": 0},
    {"model": "retaining_wall1", "pos": [-25.5, 0.0, 14.5], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-21.5, 0.0, 14.5], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-17.5, 0.0, 14.5], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-14.5, 0.0, 14.55], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-25.5, 0.0, 26.5], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-21.5, 0.0, 26.5], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-17.5, 0.0, 26.5], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-14.5, 0.0, 26.45], "rot": 0, "snap": false},
    {"model": "retaining_wall1", "pos": [-27.5, 0.0, 16.5], "rot": 90, "snap": false},
    {"model": "retaining_wall1", "pos": [-27.5, 0.0, 20.5], "rot": 90, "snap": false},
    {"model": "retaining_wall1", "pos": [-27.5, 0.0, 24.5], "rot": 90, "snap": false},
    {"model": "retaining_wall1", "pos": [-12.5, 0.0, 16.5], "rot": 90, "snap": false},
    {"model": "retaining_wall1", "pos": [-12.5, 0.0, 24.5], "rot": 90, "snap": false},
    {"model": "terrace_stairs1", "pos": [-11.5, 0, 20], "rot": 90},
    {"colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}], "model": "cafe_table", "pos": [-23, 0, 18]},
    {"colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}], "model": "cafe_table", "pos": [-19, 0, 22]},
    {"colliders": [{"size": [0.9, 0.06, 0.9], "offset": [0, 0.72, 0]}, {"size": [0.5, 0.72, 0.5], "offset": [0, 0.36, 0]}], "model": "cafe_table", "pos": [-23, 0, 23]},
    {"colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}], "model": "umbrella", "pos": [-22.3, 0, 18.7]},
    {"colliders": [{"size": [0.1, 2.2, 0.1], "offset": [0, 1.1, 0]}], "model": "umbrella", "pos": [-18.3, 0, 22.7]},
    {"outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}], "model": "chair", "pos": [-23, 0, 17.2], "rot": 180},
    {"outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}], "model": "chair", "pos": [-19, 0, 21.2], "rot": 180},
    {"outline": true, "colliders": [{"size": [0.42, 0.45, 0.42], "offset": [0, 0.24, 0]}], "model": "chair", "pos": [-23, 0, 22.2], "rot": 180},
    {"model": "lamp", "pos": [-26, 0, 25], "rot": 0},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-50.7, 0, 24.5], "rot": 0},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [60.2, 0, 25.7], "rot": 0},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-38.2, 0, -18.9], "rot": 240},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-43.9, 0, -12.7], "rot": 30},
    {"colliders": [{"size": [0.74, 1.12, 0.84], "offset": [0, 0.56, 0]}], "model": "bin", "pos": [-36.0, 0, -14.8], "rot": 15},
    {"outline": true, "model": "box", "pos": [-60.6, 0, -10.2], "rot": 90},
    {"outline": true, "model": "box", "pos": [-38.0, 0, -12.0], "rot": 240},
    {"outline": true, "model": "box", "pos": [-48.9, 0, -15.4], "rot": 105},
    {"outline": true, "model": "box", "pos": [-51.2, 0, -24.4], "rot": 210},
    {"outline": true, "model": "box", "pos": [-31.7, 0, -23.9], "rot": 240},
    {"outline": true, "model": "box", "pos": [-54.9, 0, -15.9], "rot": 90},
    {"model": "bush", "pos": [49.6, 0, -21.1], "rot": 270},
    {"model": "bush", "pos": [34.9, 0, -29.6], "rot": 135},
    {"model": "bush", "pos": [34.3, 0, -16.2], "rot": 0},
    {"model": "bush", "pos": [24.0, 0, -19.0], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [37.3, 0, -32.4], "rot": 270},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [43.2, 0, -29.4], "rot": 270},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-8.3, 0, -60.9], "rot": 15},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [8.8, 0, -66.4], "rot": 15},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-10.9, 0, -40.9], "rot": 75},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [14.1, 0, -38.1], "rot": 135},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-8.8, 0, -22.3], "rot": 165},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-9.2, 0, -46.8], "rot": 240},
    {"model": "bush", "pos": [2.9, 0, -63.2], "rot": 330},
    {"model": "bush", "pos": [-5.5, 0, -23.7], "rot": 135},
    {"model": "bush", "pos": [19.2, 0, -35.8], "rot": 15},
    {"model": "bush", "pos": [7.6, 0, -39.6], "rot": 0},
    {"model": "bush", "pos": [-14.4, 0, -68.2], "rot": 285},
    {"model": "bush", "pos": [-19.3, 0, -22.7], "rot": 300},
    {"solid": false, "model": "grass", "pos": [-17.0, 0, -66.5], "rot": 0},
    {"solid": false, "model": "grass", "pos": [-7.6, 0, -62.9], "rot": 285},
    {"solid": false, "model": "grass", "pos": [-17.1, 0, -46.4], "rot": 315},
    {"solid": false, "model": "grass", "pos": [-5.3, 0, -67.7], "rot": 180},
    {"solid": false, "model": "grass", "pos": [17.4, 0, -31.7], "rot": 180},
    {"solid": false, "model": "grass", "pos": [-14.8, 0, -19.9], "rot": 270},
    {"solid": false, "model": "grass", "pos": [-6.3, 0, -65.6], "rot": 0},
    {"solid": false, "model": "grass", "pos": [-1.1, 0, -66.0], "rot": 285},
    {"solid": false, "model": "grass", "pos": [14.3, 0, -20.9], "rot": 30},
    {"solid": false, "model": "grass", "pos": [-18.8, 0, -44.0], "rot": 30},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-11.4, 0, -58.6], "rot": 90},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [16.8, 0, -59.1], "rot": 270},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-10.7, 0, -79.5], "rot": 90},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-33.1, 0, -107.8], "rot": 195},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [34.6, 0, -82.1], "rot": 180},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-27.9, 0, -94.0], "rot": 300},
    {"model": "bush", "pos": [1.4, 0, -87.1], "rot": 300},
    {"model": "bush", "pos": [15.6, 0, -81.4], "rot": 270},
    {"model": "bush", "pos": [9.0, 0, -99.1], "rot": 0},
    {"model": "bush", "pos": [23.7, 0, -100.5], "rot": 300},
    {"model": "bush", "pos": [7.7, 0, -86.9], "rot": 60},
    {"model": "bush", "pos": [-15.8, 0, -98.0], "rot": 180},
    {"outline": true, "model": "box", "pos": [32.0, 0, -94.2], "rot": 150},
    {"outline": true, "model": "box", "pos": [-20.6, 0, -79.4], "rot": 120},
    {"outline": true, "model": "box", "pos": [34.6, 0, -76.8], "rot": 330},
    {"outline": true, "model": "box", "pos": [2.7, 0, -83.1], "rot": 0},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-10.9, 0, -107.2], "rot": 180},
    {"outline": true, "colliders": [{"size": [1.5, 0.1, 0.45], "offset": [0, 0.45, 0]}, {"size": [1.5, 0.4, 0.06], "offset": [0, 0.72, 0.22]}], "model": "bench", "pos": [-4.3, 0, -91.3], "rot": 270},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-67.8, 0, -124.2], "rot": 345},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-68.9, 0, -103.1], "rot": 240},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-87.2, 0, -92.7], "rot": 315},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-72.9, 0, -54.4], "rot": 330},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-77.6, 0, -46.0], "rot": 210},
    {"model": "bush", "pos": [-67.2, 0, -96.7], "rot": 135},
    {"model": "bush", "pos": [-67.1, 0, -137.4], "rot": 315},
    {"model": "bush", "pos": [-83.1, 0, -93.3], "rot": 180},
    {"model": "bush", "pos": [-81.6, 0, -73.1], "rot": 285},
    {"model": "bush", "pos": [-73.9, 0, -93.7], "rot": 90},
    {"model": "bush", "pos": [-69.4, 0, -90.0], "rot": 135},
    {"solid": false, "model": "grass", "pos": [-69.3, 0, -49.2], "rot": 225},
    {"solid": false, "model": "grass", "pos": [-76.5, 0, -88.7], "rot": 225},
    {"solid": false, "model": "grass", "pos": [-76.9, 0, -85.5], "rot": 60},
    {"solid": false, "model": "grass", "pos": [-87.4, 0, -49.1], "rot": 150},
    {"solid": false, "model": "grass", "pos": [-76.6, 0, -105.9], "rot": 195},
    {"solid": false, "model": "grass", "pos": [-77.2, 0, -76.9], "rot": 225},
    {"solid": false, "model": "grass", "pos": [-78.9, 0, -50.3], "rot": 240},
    {"solid": false, "model": "grass", "pos": [-67.7, 0, -119.1], "rot": 150},
    {"outline": true, "model": "box", "pos": [-87.2, 0, -130.4], "rot": 0},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [78.0, 0, -113.8], "rot": 240},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [67.4, 0, -84.0], "rot": 195},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [59.4, 0, -72.9], "rot": 0},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [59.9, 0, -95.0], "rot": 180},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [64.0, 0, -126.2], "rot": 300},
    {"model": "bush", "pos": [69.2, 0, -93.1], "rot": 90},
    {"model": "bush", "pos": [76.2, 0, -82.2], "rot": 90},
    {"model": "bush", "pos": [72.9, 0, -60.9], "rot": 90},
    {"model": "bush", "pos": [63.4, 0, -71.9], "rot": 45},
    {"model": "bush", "pos": [81.9, 0, -55.7], "rot": 60},
    {"model": "bush", "pos": [66.1, 0, -114.5], "rot": 105},
    {"solid": false, "model": "grass", "pos": [60.2, 0, -137.2], "rot": 300},
    {"solid": false, "model": "grass", "pos": [68.4, 0, -102.5], "rot": 150},
    {"solid": false, "model": "grass", "pos": [86.1, 0, -91.7], "rot": 240},
    {"solid": false, "model": "grass", "pos": [78.6, 0, -125.9], "rot": 315},
    {"solid": false, "model": "grass", "pos": [76.1, 0, -66.1], "rot": 90},
    {"solid": false, "model": "grass", "pos": [59.1, 0, -89.0], "rot": 30},
    {"solid": false, "model": "grass", "pos": [67.4, 0, -63.9], "rot": 225},
    {"solid": false, "model": "grass", "pos": [67.6, 0, -75.5], "rot": 45},
    {"outline": true, "model": "box", "pos": [61.1, 0, -117.7], "rot": 315},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-49.3, 0, -144.6], "rot": 90},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [46.6, 0, -135.8], "rot": 75},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [25.6, 0, -138.8], "rot": 195},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-7.7, 0, -134.7], "rot": 210},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [-58.5, 0, -130.6], "rot": 165},
    {"model": "bush", "pos": [22.8, 0, -137.1], "rot": 285},
    {"model": "bush", "pos": [-38.1, 0, -142.4], "rot": 90},
    {"model": "bush", "pos": [-2.6, 0, -145.7], "rot": 240},
    {"model": "bush", "pos": [40.0, 0, -128.4], "rot": 270},
    {"model": "bush", "pos": [18.9, 0, -127.1], "rot": 150},
    {"model": "bush", "pos": [10.5, 0, -137.1], "rot": 120},
    {"solid": false, "model": "grass", "pos": [-28.7, 0, -143.4], "rot": 285},
    {"solid": false, "model": "grass", "pos": [23.2, 0, -142.5], "rot": 15},
    {"solid": false, "model": "grass", "pos": [44.6, 0, -143.1], "rot": 105},
    {"solid": false, "model": "grass", "pos": [-23.1, 0, -134.1], "rot": 120},
    {"solid": false, "model": "grass", "pos": [-18.6, 0, -136.5], "rot": 315},
    {"solid": false, "model": "grass", "pos": [-39.3, 0, -128.5], "rot": 135},
    {"solid": false, "model": "grass", "pos": [-26.2, 0, -143.8], "rot": 150},
    {"solid": false, "model": "grass", "pos": [39.5, 0, -124.2], "rot": 90},
    {"outline": true, "model": "box", "pos": [8.9, 0, -129.7], "rot": 120},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [70.2, 0, -17.8], "rot": 45},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [80.4, 0, -11.5], "rot": 300},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [56.3, 0, -28.6], "rot": 210},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [64.8, 0, -25.0], "rot": 300},
    {"colliders": [{"size": [0.3, 1.6, 0.3], "offset": [0, 0.8, 0]}], "model": "tree", "pos": [72.7, 0, -2.8], "rot": 30},
    {"model": "bush", "pos": [73.6, 0, -10.6], "rot": 135},
    {"model": "bush", "pos": [86.6, 0, -23.0], "rot": 315},
    {"model": "bush", "pos": [87.0, 0, -2.4], "rot": 330},
    {"model": "bush", "pos": [73.3, 0, -13.8], "rot": 345},
    {"model": "bush", "pos": [66.0, 0, -16.7], "rot": 135},
    {"model": "bush", "pos": [71.5, 0, -28.1], "rot": 0},
    {"solid": false, "model": "grass", "pos": [57.4, 0, -33.1], "rot": 345},
    {"solid": false, "model": "grass", "pos": [80.1, 0, -22.8], "rot": 210},
    {"solid": false, "model": "grass", "pos": [84.7, 0, -7.1], "rot": 60},
    {"solid": false, "model": "grass", "pos": [57.6, 0, 3.5], "rot": 105},
    {"solid": false, "model": "grass", "pos": [86.2, 0, -36.8], "rot": 285},
    {"solid": false, "model": "grass", "pos": [85.0, 0, -21.1], "rot": 330},
    {"solid": false, "model": "grass", "pos": [71.3, 0, 2.8], "rot": 45},
    {"solid": false, "model": "grass", "pos": [63.8, 0, -17.0], "rot": 15},
    {"outline": true, "model": "box", "pos": [70.2, 0, -10.6], "rot": 210}
  ],
  "hideouts": [
    {"kind": "box", "pos": [-2, 0.2, -0.35], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-3.5, 0.2, 4.65], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [6, 0.2, -0.35], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [2.6, 0.2, -9.75], "size": [0.6, 0.4, 0.6]},
    {"kind": "car", "pos": [8, 0.15, 4], "size": [1.4, 0.3, 3.2]},
    {"kind": "car", "pos": [-8, 0.15, 7], "rot": 15, "size": [1.4, 0.3, 3.2]},
    {"kind": "bench", "pos": [0, 0.2, 7], "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [-5, 0.2, -8], "rot": 90, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [-50.7, 0.2, 24.5], "rot": 0, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [60.2, 0.2, 25.7], "rot": 0, "size": [1.3, 0.4, 0.4]},
    {"kind": "box", "pos": [-51.2, 0.2, -23.75], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-31.7, 0.2, -23.25], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-54.9, 0.2, -15.25], "size": [0.6, 0.4, 0.6]},
    {"kind": "bench", "pos": [37.3, 0.2, -32.4], "rot": 270, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [43.2, 0.2, -29.4], "rot": 270, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [-11.4, 0.2, -58.6], "rot": 90, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [16.8, 0.2, -59.1], "rot": 270, "size": [1.3, 0.4, 0.4]},
    {"kind": "box", "pos": [32.0, 0.2, -93.55], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [-20.6, 0.2, -78.75], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [34.6, 0.2, -76.15], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [2.7, 0.2, -82.45], "size": [0.6, 0.4, 0.6]},
    {"kind": "bench", "pos": [-10.9, 0.2, -107.2], "rot": 180, "size": [1.3, 0.4, 0.4]},
    {"kind": "bench", "pos": [-4.3, 0.2, -91.3], "rot": 270, "size": [1.3, 0.4, 0.4]},
    {"kind": "box", "pos": [-87.2, 0.2, -129.75], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [61.1, 0.2, -117.05], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [8.9, 0.2, -129.05], "size": [0.6, 0.4, 0.6]},
    {"kind": "box", "pos": [70.2, 0.2, -9.95], "size": [0.6, 0.4, 0.6]}
  ],
  "spawn_points": [
    {"pos": [3.5, 0, -10], "allowed": [0], "foods": ["sausage", "cookie"]},
    {"pos": [-5, 0, 2.5], "allowed": [0], "foods": ["sausage", "cookie"]},
    {"pos": [0, 0, -4], "allowed": [0], "foods": ["sausage", "cookie"]},
    {"pos": [-4, 0, -4], "allowed": [0], "foods": ["sausage", "cookie"]},
    {"pos": [1, 0, 6.3], "allowed": [0], "foods": ["sausage", "cookie"]},
    {"pos": [-5.8, 0, -7], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [4, 0, 4], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-11.3, 1.0, -9.0], "allowed": [1], "foods": ["pizza", "hotdog"]},
    {"pos": [2, 0, 6], "allowed": [1, 3], "foods": ["pizza", "hotdog", "donut", "ice_cream"]},
    {"pos": [7.5, 0, -8], "allowed": [2, 3], "foods": ["croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-4, 0, 15.3], "allowed": [1], "foods": ["pizza", "hotdog"]},
    {"pos": [4, 0, 15.3], "allowed": [1], "foods": ["pizza", "hotdog"]},
    {"pos": [0, 0.75, 17], "allowed": [2], "foods": ["croissant", "fish"]},
    {"pos": [-2, 0.75, 21], "allowed": [2], "foods": ["croissant", "fish"]},
    {"pos": [2, 0.75, 21], "allowed": [3], "foods": ["donut", "ice_cream"]},
    {"pos": [7, 0, 20], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-58.0, 2.28, -28.4], "allowed": [2, 3], "foods": ["croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-35.6, 2.28, -28.4], "allowed": [2, 3], "foods": ["croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-35.6, 2.28, -37.6], "allowed": [2, 3], "foods": ["croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-58.0, 2.28, -37.6], "allowed": [2, 3], "foods": ["croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-25, 1.0, -110.95], "allowed": [1, 2], "foods": ["pizza", "hotdog", "croissant", "fish"]},
    {"pos": [0, 1.0, -110.95], "allowed": [1, 2], "foods": ["pizza", "hotdog", "croissant", "fish"]},
    {"pos": [25, 1.0, -110.95], "allowed": [1, 2], "foods": ["pizza", "hotdog", "croissant", "fish"]},
    {"pos": [-23, 0.75, 18], "allowed": [2], "foods": ["croissant", "fish"]},
    {"pos": [-19, 0.75, 22], "allowed": [3], "foods": ["donut", "ice_cream"]},
    {"pos": [-23, 0.75, 23], "allowed": [1], "foods": ["pizza", "hotdog"]},
    {"pos": [-54.3, 0, 6.8], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-21.3, 0, 6.3], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [51.5, 0, 6.9], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [28.9, 0, 6.6], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-50.9, 0, -8.0], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-22.2, 0, -10.9], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-33.7, 0, -20.3], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-52.8, 0, -20.8], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-46.5, 0, -8.8], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-28.1, 0, -26.0], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [28.9, 0, -16.1], "allowed": [0, 1, 2], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish"]},
    {"pos": [39.7, 0, -25.3], "allowed": [0, 1, 2], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish"]},
    {"pos": [25.1, 0, -34.8], "allowed": [0, 1, 2], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish"]},
    {"pos": [35.5, 0, -37.8], "allowed": [0, 1, 2], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish"]},
    {"pos": [39.9, 0, -19.7], "allowed": [0, 1, 2], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish"]},
    {"pos": [29.4, 0, -24.0], "allowed": [0, 1, 2], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish"]},
    {"pos": [7.8, 0, -46.2], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-1.5, 0, -41.9], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-15.5, 0, -29.4], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [15.9, 0, -50.9], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-14.3, 0, -38.2], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [0.7, 0, -30.8], "allowed": [0, 1], "foods": ["sausage", "cookie", "pizza", "hotdog"]},
    {"pos": [-3.3, 0, -109.2], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-25.9, 0, -108.4], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [9.3, 0, -94.8], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [22.1, 0, -77.4], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [13.3, 0, -103.2], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-1.8, 0, -103.9], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-35.2, 0, -93.9], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [14.2, 0, -92.3], "allowed": [0, 1, 2, 3], "foods": ["sausage", "cookie", "pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-85.6, 0, -104.0], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-87.4, 0, -120.0], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [75.6, 0, -55.5], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [71.4, 0, -127.0], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [-0.3, 0, -137.4], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [52.0, 0, -131.9], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [76.0, 0, -19.9], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]},
    {"pos": [62.5, 0, -37.7], "allowed": [1, 2, 3], "foods": ["pizza", "hotdog", "croissant", "fish", "donut", "ice_cream"]}
  ],
  "yarn": [
    {"pos": [-11.3, 1.0, -9.3]},
    {"pos": [-10.9, 0.5, -11.0]},
    {"pos": [1.5, 0.6, 1.5]},
    {"pos": [0.4, 0.5, 7.0]},
    {"pos": [8.0, 0.0, 5.3]},
    {"pos": [-8.3, 0.0, 8.3]},
    {"pos": [-11.2, 0.0, -13.2]},
    {"pos": [11.5, 0.0, -13.0]},
    {"pos": [1.9, 0.0, 10.5]},
    {"pos": [-5.6, 0.0, -9.0]},
    {"pos": [-4, 0.75, 17]},
    {"pos": [4, 0.75, 17]},
    {"pos": [-58.0, 2.28, -30.0]},
    {"pos": [-54.8, 2.28, -30.0]},
    {"pos": [-51.6, 2.28, -30.0]},
    {"pos": [-48.4, 2.28, -30.0]},
    {"pos": [-45.2, 2.28, -30.0]},
    {"pos": [-42.0, 2.28, -30.0]},
    {"pos": [-38.8, 2.28, -30.0]},
    {"pos": [-35.6, 2.28, -30.0]},
    {"pos": [-35.6, 2.28, -36.0]},
    {"pos": [-38.8, 2.28, -36.0]},
    {"pos": [-42.0, 2.28, -36.0]},
    {"pos": [-45.2, 2.28, -36.0]},
    {"pos": [-48.4, 2.28, -36.0]},
    {"pos": [-51.6, 2.28, -36.0]},
    {"pos": [-54.8, 2.28, -36.0]},
    {"pos": [-58.0, 2.28, -36.0]},
    {"pos": [-24.6, 0.5, -113.0]},
    {"pos": [0.4, 0.5, -113.0]},
    {"pos": [25.4, 0.5, -113.0]},
    {"pos": [-53.6, 0, -9.6]},
    {"pos": [-43.2, 0, -8.4]},
    {"pos": [-46.1, 0, -24.7]},
    {"pos": [24.4, 0, -29.9]},
    {"pos": [40.2, 0, -35.2]},
    {"pos": [27.5, 0, -29.5]},
    {"pos": [40.3, 0, -31.2]},
    {"pos": [-0.1, 0, -57.4]},
    {"pos": [-3.8, 0, -57.0]},
    {"pos": [5.4, 0, -28.2]},
    {"pos": [10.2, 0, -59.6]},
    {"pos": [-7.7, 0, -83.1]},
    {"pos": [29.2, 0, -107.0]},
    {"pos": [31.1, 0, -85.4]},
    {"pos": [9.0, 0, -79.1]},
    {"pos": [-8.9, 0, -90.7]},
    {"pos": [27.3, 0, -82.9]},
    {"pos": [-72.6, 0, -48.3]},
    {"pos": [59.7, 0, -128.8]},
    {"pos": [49.8, 0, -145.5]},
    {"pos": [72.9, 0, -34.5]}
  ],
  "hazards": [
    {"type": "dog", "pos": [7, 0, -7], "rot": 90},
    {"type": "wasp", "pos": [2, 0.5, 6], "radius": 2.5},
    {"type": "cyclist", "pos": [0, 0, 12]},
    {"type": "wasp", "pos": [2, 1.1, 21], "radius": 0.8, "height": 1.0},
    {"type": "cyclist", "pos": [-40, 0, 12]},
    {"type": "dog", "pos": [-40, 0, -22], "rot": 90},
    {"type": "wasp", "pos": [45, 0.5, -33], "radius": 2.0},
    {"type": "dog", "pos": [10, 0, -90], "rot": 0},
    {"type": "wasp", "pos": [-20, 0.5, -100], "radius": 2.0}
  ],
  "decals": [
    {"texture": "assets/images/world/decal_manhole.png", "pos": [3, 0, -2], "size": [1.0, 1.0]},
    {"texture": "assets/images/world/decal_cracks.png", "pos": [-6, 0, 4], "size": [2.0, 2.0], "rot": 20},
    {"texture": "assets/images/world/decal_cracks.png", "pos": [8, 0, -9], "size": [1.5, 1.5], "rot": 110},
    {"texture": "assets/images/world/decal_leaves.png", "pos": [-2, 0, -6], "size": [2.0, 2.0]},
    {"texture": "assets/images/world/decal_leaves.png", "pos": [6, 0, 6], "size": [2.0, 2.0], "rot": 70},
    {"texture": "assets/images/world/poster_cafe.png", "pos": [-5.0, 0.8, -13.78], "size": [0.9, 0.9], "wall": true},
    {"texture": "assets/images/world/poster_cat.png", "pos": [6.5, 0.8, -13.78], "size": [0.8, 0.8], "wall": true},
    {"texture": "assets/images/world/poster_paws.png", "pos": [-11.78, 0.8, -6.5], "size": [0.7, 0.7], "wall": true, "rot": 90}
  ],
  "gates": [
    {"pos": [0, 0, 10.5], "rot": 0, "size": [2.4, 2.6, 0.3], "satiety": 10}
  ],
  "water_zones": [
  ],
  "shore": [
  ],
  "floaters": [
  ],
  "shop": {"pos": [-4.5, 0, -1.5], "rot": 180},
  "road": {"points": [[-88, 0, 12], [88, 0, 12]]}
}
```

## `tools/layout/layout_gen.py`

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
	"wall": (6.0, 0.4, 3.2), "garage": (3.1, 5.6, 2.28), "bin": (0.74, 0.84, 1.12), "box": (0.6, 0.6, 0.3),
	"car": (1.7, 3.6, 1.5), "bench": (1.5, 0.45, 0.5), "fence": (2.0, 0.12, 1.0), "kiosk": (2.4, 2.0, 2.6),
	"shed": (2.0, 2.0, 2.3), "cafe_table": (0.9, 0.9, 0.75), "sandbox": (2.0, 2.0, 0.3), "slide": (1.0, 3.0, 1.6),
	"swings": (2.5, 1.2, 2.2), "tree": (0.3, 0.3, 1.6), "lamp": (0.3, 0.3, 3.0), "fountain": (3.0, 3.0, 1.0),
	"retaining_wall1": (4.0, WALL_THICK, 1.0), "retaining_wall2": (4.0, WALL_THICK, 2.0), "retaining_wall3": (4.0, WALL_THICK, 3.0),
	"stairs": (1.2, 3.2, 1.0), "arch": (3.4, 0.6, 2.6), "chair": (0.5, 0.5, 0.9), "umbrella": (0.2, 0.2, 2.2),
	"bush": (1.0, 1.0, 0.8), "flowerbed": (2.0, 1.0, 0.4), "door": (1.0, 0.2, 2.0),
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


def footprints(p):
	"""Пятна пропса: по явным коллайдерам (как их строит WorldBuilder), иначе по таблице; несплошной — []."""
	if p.get("solid", True) is False:
		return []
	if "colliders" not in p:
		f = footprint(p)
		return [f] if f else []
	x, y, z = p["pos"]
	base = y if p.get("snap", True) else 0.0
	rot = float(p.get("rot", 0)) % 360
	out = []
	for c in p["colliders"]:
		sx, sy, sz = c["size"]
		ox, oy, oz = c.get("offset", [0, 0, 0])
		cx, cz = _local((x, z), rot, ox, oz)
		if abs(rot % 180 - 90) < 1:
			sx, sz = sz, sx
		elif rot % 180 > 1:
			sx = sz = max(sx, sz)
		out.append((cx - sx / 2, cz - sz / 2, cx + sx / 2, cz + sz / 2, base + oy + sy / 2))
	return out


def _local(origin, rot, dx, dz):
	"""Смещение (dx, dz) в осях объекта с поворотом rot (как Basis(UP, rot) в Godot) → мировые x, z."""
	a = math.radians(rot)
	return (round(origin[0] + dx * math.cos(a) + dz * math.sin(a), 3), round(origin[1] - dx * math.sin(a) + dz * math.cos(a), 3))


SIDES = {"n": 0, "s": 180, "w": 90, "e": -90}   # стена дома лицом внутрь прямоугольника


def perimeter(rect, model="wall", length=6.0, sides="nswe", gaps=(), extra=None):
	"""Модули стен по сторонам rect; gaps — [(сторона, центр вдоль стороны, ширина)] — проходы без стен."""
	x0, z0, x1, z1 = rect
	out = []
	for side in sides:
		horiz = side in "ns"
		a, b = (x0, x1) if horiz else (z0, z1)
		span = b - a
		whole = abs(span / length - round(span / length)) < 1e-6
		n = max(1, round(span / length)) if whole else math.ceil(span / length)
		step = length if not whole else span / n
		inward = {"n": 1, "s": -1, "w": 1, "e": -1}[side] * 0.05
		for k in range(n):
			c = round(a + step * (k + 0.5), 3)
			shift = 0.0
			if not whole and k == n - 1:   # сторона не кратна модулю: последний прижат к концу, чуть внутрь (без мерцания)
				c, shift = round(b - length / 2, 3), inward
			if any(g[0] == side and abs(c - g[1]) < (g[2] + step) / 2 for g in gaps):
				continue
			line = (z0 if side == "n" else z1) if horiz else (x0 if side == "w" else x1)
			line = round(line + shift, 3)
			pos = [c, 0, line] if horiz else [line, 0, c]
			out.append({"model": model, "pos": pos, "rot": SIDES[side], **(extra or {})})
	return out


def terrace(rect, height, access=(), sides="nswe", gaps=(), ground=0.0, wall_h=None, level=None):
	"""Терраса: элемент рельефа, подпорные стены на ячейке обрыва (снаружи rect), лестницы и пандусы.
	access — [(сторона, центр вдоль стороны, "stairs" | "ramp")]. Возвращает (feature, props, blocked)."""
	h = int(height)
	assert h in (1, 2, 3) and all(float(v).is_integer() for v in rect), "терраса: высота 1–3 м, углы в целых метрах"
	x0, z0, x1, z1 = rect
	# height — подъём над окружением (стены, лестницы); level — абсолютная высота плато в terrain_gen (по умолчанию = height).
	feature = {"type": "terrace", "rect": list(rect), "height": float(h if level is None else level)}
	gaps = [(s, c, KIT_WIDTH + 0.8) for s, c, _ in access] + [tuple(g) for g in gaps]
	props = []
	half = WALL_THICK / 2
	for w in perimeter([x0 - half, z0 - half, x1 + half, z1 + half], f"retaining_wall{int(wall_h or h)}", 4.0, sides, gaps):
		w["pos"][1] = ground   # подножие стены — абсолютная высота (у порта база рельефа −2)
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
			ax, az = _local((x, z), p["rot"], 0, 3.0)   # свободный подход 3 м к подножию
			blocked.append((min(ax, ex) - 1.2, min(az, ez) - 1.2, max(ax, ex) + 1.2, max(az, ez) + 1.2, h))
	return feature, props, blocked


def garage_row(origin, count, rot=0, step=3.2, foods=None):
	"""Ряд гаражей вдоль локальной X; у первого — цепочка прыжков на крышу:
	стопка ящиков 0,6 → бак 1,12 → бак с двумя ящиками 1,72 → крыша 2,28. На каждой крыше клубочек, на крайних — редкая еда."""
	props, yarn, spawns = [], [], []
	for k in range(count):
		gx, gz = _local(origin, rot, k * step, 0)
		props.append({"model": "garage", "pos": [gx, 0, gz], "rot": rot})
		yarn.append({"pos": [gx, 2.28, round(gz, 3)]})
		if k in (0, count - 1):
			sx, sz = _local(origin, rot, k * step, 1.6)
			sp = {"pos": [sx, 2.28, sz], "allowed": [2, 3]}
			if foods:
				sp["foods"] = foods   # без списка точка берёт еду любого района (парк во дворе)
			spawns.append(sp)
	edge = -1.55 - 0.05
	b2 = edge - 0.37
	b1 = b2 - 0.74 - 0.1
	bx = b1 - 0.37 - 0.3 - 0.1
	# ящик 0,3 м: стопка из двух — 0,6; бак 1,12; бак с двумя ящиками — 1,72; крыша 2,28 (шаги ≤ 0,6 м)
	for dx, model, y in ((b2, "bin", 0), (b2, "box", 1.12), (b2, "box", 1.42), (b1, "bin", 0), (bx, "box", 0), (bx, "box", 0.3)):
		x, z = _local(origin, rot, dx, 1.8)
		props.append({"model": model, "pos": [x, y, z], "rot": rot})
	return {"props": props, "yarn": yarn, "spawn_points": spawns}


def pond(center, radius, depth, level):
	"""Пруд: котловина рельефа, зона воды (поверхность level, абсолютная), 8 маркеров берега на radius + 1,5,
	прямоугольник, закрытый для россыпи. Возвращает (feature, water, shore, blocked)."""
	cx, cz = center
	feature = {"type": "basin", "center": [cx, cz], "radius": radius, "depth": depth}
	water = {"pos": [cx, level, cz], "size": [2 * radius, 2.0, 2 * radius]}
	shore = []
	for k in range(8):
		a = k * math.pi / 4
		shore.append({"pos": [round(cx + (radius + 1.5) * math.cos(a), 2), 0, round(cz + (radius + 1.5) * math.sin(a), 2)]})
	blocked = (cx - radius - 1, cz - radius - 1, cx + radius + 1, cz + radius + 1, 0.0)
	return feature, water, shore, blocked


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


LISTS = ("props", "hideouts", "spawn_points", "yarn", "hazards", "decals", "gates", "water_zones", "shore", "floaters")


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
	sample = list(core.get("props", []))
	for path in desc.get("defaults", []):   # районы без ядра берут флаги моделей из ядер других районов
		sample += json.loads((ROOT / path).read_text()).get("props", [])
	defaults = model_defaults(sample)
	gen = {k: [] for k in LISTS}
	blocked = [f for p in out["props"] for f in footprints(p)]

	def add(kind, items):
		for it in items:
			if kind == "props":
				it = {**defaults.get(it["model"], {}), **it}
				blocked.extend(footprints(it))
			out[kind].append(it)
			gen[kind].append(it)

	taken = [(s["pos"][0], s["pos"][2]) for k in ("spawn_points", "yarn", "hideouts") for s in out[k]]
	# Два прохода: сначала структура всех зон (стены, террасы, гаражи, ручные места), потом россыпь —
	# иначе россыпь ранней зоны не знает о лестницах и стенах поздней.
	ops = [op for z in desc.get("zones", []) for op in z["ops"]]
	for op in [o for o in ops if o["type"] != "scatter"] + [o for o in ops if o["type"] == "scatter"]:
		t = op["type"]
		if t == "perimeter":
			add("props", perimeter(op["rect"], op.get("model", "wall"), op.get("length", 6.0), op.get("sides", "nswe"), [tuple(g) for g in op.get("gaps", [])], op.get("extra")))
		elif t == "terrace":
			feature, props, bl = terrace(op["rect"], op["height"], [tuple(a) for a in op.get("access", [])],
				op.get("sides", "nswe"), [tuple(g) for g in op.get("gaps", [])], op.get("ground", 0.0), op.get("wall_h"), op.get("level"))
			terrain["features"].append(feature)
			add("props", props)
			blocked.extend(bl)
		elif t == "garage_row":
			row = garage_row(tuple(op["origin"]), op["count"], op.get("rot", 0), op.get("step", 3.2), op.get("foods"))
			for k, v in row.items():
				add(k, v)
		elif t == "pond":
			feature, water, shore, bl = pond(tuple(op["center"]), op["radius"], op["depth"], op["level"])
			terrain["features"].append(feature)
			add("water_zones", [water])
			add("shore", shore)
			blocked.append(bl)
		elif t == "block":
			blocked.append(tuple(op["rect"]) + (0.0,))   # полоса без россыпи (маршрут погрузчика)
		elif t == "flat":
			terrain["features"].append({"type": "flat", "rect": op["rect"], "height": op["height"]})
		elif t == "water":
			x0, z0, x1, z1 = op["rect"]
			add("water_zones", [{"pos": [(x0 + x1) / 2, op["level"], (z0 + z1) / 2], "size": [x1 - x0, op.get("depth", 2.0), z1 - z0]}])
			add("shore", [dict(m) if isinstance(m, dict) else {"pos": list(m)} for m in op.get("shore", [])])   # словарь — с флагами (snap)
			# Прямоугольник воды не закрывается для россыпи: над ним бывает суша (причал); россыпи задаются по суше.
		elif t == "hill":
			terrain["features"].append({"type": "hill", "center": op["center"], "radius": op["radius"], "height": op["height"]})
		elif t == "paint":
			pt = {k: v for k, v in op.items() if k not in ("type", "surface")}
			pt["type"] = op["surface"]   # ключ type занят самой операцией
			terrain["paint"].append(pt)
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
				elif w == "hideout" and op.get("kind") == "bush":
					add("props", [{"model": "bush", "pos": [x, 0, z], "rot": rng.randrange(0, 360, 15)}])
					add("hideouts", [{"kind": "bush", "pos": [x, 0.25, z], "size": [0.9, 0.5, 0.9]}])
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
	fps = [f for p in layout["props"] for f in footprints(p)]
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

## `tools/layout/tests/test_layout_gen.py`

```python
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

	def test_terrace_walls_only_on_given_sides(self):
		# План 13: набережная — стена только к пляжу (сторона «s»), проём под причал.
		_, props, _ = lg.terrace([0, 0, 40, 20], 2, sides="s", gaps=[("s", 30, 10)])
		walls = [p for p in props if p["model"] == "retaining_wall2"]
		self.assertTrue(walls)
		self.assertTrue(all(abs(w["pos"][2] - 20.5) < 0.1 for w in walls), "только сторона s")
		self.assertFalse(any(25 < w["pos"][0] < 35 for w in walls), "проём под причал")

	def test_flat_and_water_ops(self):
		d = {"name": "t", "terrain": DESC["terrain"], "zones": [{"name": "z", "ops": [
			{"type": "flat", "rect": [-10, 0, 10, 20], "height": -3.5},
			{"type": "water", "rect": [-10, 0, 10, 20], "level": -2.3, "shore": [[0, 0, -2], [5, 0, -2]]}]}]}
		layout, terrain = lg.generate(d)
		self.assertEqual(terrain["features"][0], {"type": "flat", "rect": [-10, 0, 10, 20], "height": -3.5})
		self.assertEqual(layout["water_zones"], [{"pos": [0.0, -2.3, 10.0], "size": [20, 2.0, 20]}])
		self.assertEqual([m["pos"] for m in layout["shore"]], [[0, 0, -2], [5, 0, -2]])

	def test_terrace_wall_ground_and_height(self):
		# Порт: база рельефа −2, набережная +2 — стены от −2,3 высотой 3 дают парапет 0,7 над набережной.
		_, props, _ = lg.terrace([0, 0, 8, 8], 2, sides="s", ground=-2.3, wall_h=3)
		walls = [p for p in props if p["model"].startswith("retaining_wall")]
		self.assertTrue(walls)
		self.assertTrue(all(w["model"] == "retaining_wall3" and w["pos"][1] == -2.3 for w in walls))
		feature, _, _ = lg.terrace([0, 0, 8, 8], 2, sides="s", ground=-2.3, wall_h=3, level=0.0)
		self.assertEqual(feature["height"], 0.0, "плато на абсолютной высоте 0 при базе −2")

	def test_defaults_from_other_cores(self):
		# У порта нет ядра — флаги моделей (коллайдеры скамьи, бака, зонта) берутся из ядер двора и парка.
		d = {"name": "t", "terrain": DESC["terrain"], "defaults": ["data/layout_src/park_core.json", "data/layout_src/yard_core.json"],
			"zones": [{"name": "z", "ops": [{"type": "place", "props": [{"model": "bin", "pos": [0, 0, 0]}, {"model": "umbrella", "pos": [5, 0, 5]}]}]}]}
		layout, _ = lg.generate(d)
		self.assertTrue(all("colliders" in p for p in layout["props"]))

	def test_block_keeps_lane_free(self):
		# План 14: полоса погрузчика на причале свободна от россыпи.
		d = {"name": "t", "terrain": DESC["terrain"], "zones": [{"name": "z", "ops": [
			{"type": "scatter", "what": "prop", "model": "box", "rect": [-10, -10, 10, 10], "count": 30, "min_dist": 1.0},
			{"type": "block", "rect": [-2, -10, 2, 10]}]}]}
		layout, _ = lg.generate(d)
		self.assertFalse(any(-2.4 < p["pos"][0] < 2.4 for p in layout["props"]), "в полосе пусто")

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
```

## `data/layout_src/park.json`

```json
{
 "name": "park",
 "seed": 12,
 "core": "data/layout_src/park_core.json",
 "note": "Парк ×3 (спек «Масштаб ×3 и рельеф»): ядро — прежний парк (поляна с фонтаном); холм с беседкой, пруд, роща, северный луг.",
 "terrain": {
  "size": [
   90,
   96
  ],
  "origin": [
   -45,
   29
  ],
  "cell": 1.0,
  "base": 0.01,
  "channels": [
   "asphalt",
   "paving",
   "grass",
   "gravel"
  ],
  "default": "grass",
  "features": [],
  "paint": [
   {
    "rect": [
     -1.1,
     29,
     1.1,
     61
    ],
    "type": "gravel"
   },
   {
    "rect": [
     -15,
     43.9,
     15,
     46.1
    ],
    "type": "gravel"
   },
   {
    "rect": [
     10.9,
     29,
     13.1,
     38
    ],
    "type": "gravel"
   },
   {
    "rect": [
     0,
     36.9,
     12,
     39.1
    ],
    "type": "gravel"
   },
   {
    "rect": [
     -12,
     40.9,
     -4,
     43.1
    ],
    "type": "gravel"
   }
  ]
 },
 "counts": {
  "spawn_points": 35,
  "yarn": 25,
  "hideouts": 14
 },
 "zones": [
  {
   "name": "край парка",
   "ops": [
    {
     "type": "perimeter",
     "rect": [
      -45,
      29.9,
      45,
      125
     ],
     "model": "fence",
     "length": 2.0,
     "sides": "swe",
     "extra": {
      "colliders": [
       {
        "size": [
         2.0,
         1.8,
         0.12
        ],
        "offset": [
         0,
         0.9,
         0
        ]
       }
      ]
     },
     "gaps": [
      [
       "s",
       -6,
       1.0
      ]
     ]
    },
    {
     "type": "place",
     "gates": [
      {
       "pos": [
        -6,
        0,
        125
       ],
       "rot": 0,
       "size": [
        2.2,
        2.6,
        0.3
       ],
       "satiety": 50,
       "label": "Ворота в порт открыты!"
      }
     ]
    }
   ]
  },
  {
   "name": "холм с беседкой",
   "ops": [
    {
     "type": "hill",
     "center": [
      0,
      92
     ],
     "radius": 18,
     "height": 3
    },
    {
     "type": "paint",
     "rect": [
      -1.5,
      61,
      1.5,
      90
     ],
     "surface": "gravel"
    },
    {
     "type": "place",
     "props": [
      {
       "model": "gazebo",
       "pos": [
        0,
        0,
        92
       ],
       "rot": 0,
       "colliders": [
        {
         "size": [
          3.4,
          0.3,
          3.4
         ],
         "offset": [
          0,
          0.15,
          0
         ]
        },
        {
         "size": [
          0.16,
          2.2,
          0.16
         ],
         "offset": [
          1.85,
          1.4,
          0.0
         ]
        },
        {
         "size": [
          0.16,
          2.2,
          0.16
         ],
         "offset": [
          0.925,
          1.4,
          1.602
         ]
        },
        {
         "size": [
          0.16,
          2.2,
          0.16
         ],
         "offset": [
          -0.925,
          1.4,
          1.602
         ]
        },
        {
         "size": [
          0.16,
          2.2,
          0.16
         ],
         "offset": [
          -1.85,
          1.4,
          0.0
         ]
        },
        {
         "size": [
          0.16,
          2.2,
          0.16
         ],
         "offset": [
          -0.925,
          1.4,
          -1.602
         ]
        },
        {
         "size": [
          0.16,
          2.2,
          0.16
         ],
         "offset": [
          0.925,
          1.4,
          -1.602
         ]
        }
       ]
      },
      {
       "model": "lamp",
       "pos": [
        2.5,
        0,
        64
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        2.5,
        0,
        68
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        2.5,
        0,
        72
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        2.5,
        0,
        76
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        2.5,
        0,
        80
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        2.5,
        0,
        84
       ],
       "rot": 0
      },
      {
       "model": "bench",
       "pos": [
        -3,
        0,
        78
       ],
       "rot": 90
      },
      {
       "model": "bench",
       "pos": [
        5,
        0,
        98
       ],
       "rot": 0
      }
     ],
     "spawn_points": [
      {
       "pos": [
        0,
        0.3,
        92
       ],
       "allowed": [
        2
       ],
       "foods": [
        "cotton_candy"
       ]
      }
     ],
     "yarn": [
      {
       "pos": [
        0.8,
        0.3,
        92.6
       ]
      },
      {
       "pos": [
        -0.8,
        0.3,
        91.4
       ]
      }
     ],
     "hazards": [
      {
       "type": "pigeons",
       "pos": [
        -4,
        0,
        80
       ]
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      -14,
      66,
      14,
      110
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -14,
      64,
      14,
      110
     ],
     "count": 5,
     "allowed": [
      0,
      1,
      2
     ],
     "foods": [
      "popcorn",
      "bagel",
      "corn",
      "sandwich",
      "cotton_candy"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -14,
      64,
      14,
      110
     ],
     "count": 2,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      -14,
      64,
      14,
      110
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "пруд",
   "ops": [
    {
     "type": "pond",
     "center": [
      -28,
      66
     ],
     "radius": 11,
     "depth": 1.5,
     "level": -0.5
    },
    {
     "type": "place",
     "props": [
      {
       "model": "grass",
       "pos": [
        -16.4,
        0,
        69.08
       ],
       "rot": 14,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -19.5,
        0,
        74.47
       ],
       "rot": 44,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -24.87,
        0,
        77.59
       ],
       "rot": 74,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -31.08,
        0,
        77.6
       ],
       "rot": 104,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -36.47,
        0,
        74.5
       ],
       "rot": 134,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -39.59,
        0,
        69.13
       ],
       "rot": 164,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -39.6,
        0,
        62.92
       ],
       "rot": 193,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -36.5,
        0,
        57.53
       ],
       "rot": 223,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -31.13,
        0,
        54.41
       ],
       "rot": 253,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -24.92,
        0,
        54.4
       ],
       "rot": 283,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -19.53,
        0,
        57.5
       ],
       "rot": 313,
       "solid": false
      },
      {
       "model": "grass",
       "pos": [
        -16.41,
        0,
        62.87
       ],
       "rot": 343,
       "solid": false
      }
     ],
     "hazards": [
      {
       "type": "kid",
       "pos": [
        -22,
        0,
        82
       ],
       "rot": 180
      }
     ]
    }
   ]
  },
  {
   "name": "роща",
   "ops": [
    {
     "type": "place",
     "hazards": [
      {
       "type": "gardener",
       "pos": [
        16.5,
        0,
        40
       ],
       "rot": 0,
       "path": [
        [
         16.5,
         40
        ],
        [
         16.5,
         86
        ],
        [
         30,
         90
        ],
        [
         16.5,
         86
        ]
       ]
      },
      {
       "type": "pigeons",
       "pos": [
        20,
        0,
        92
       ]
      }
     ],
     "props": [
      {
       "model": "bench",
       "pos": [
        21,
        0,
        94
       ],
       "rot": 0
      },
      {
       "model": "bench",
       "pos": [
        24,
        0,
        94
       ],
       "rot": 0
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      18,
      36,
      43,
      88
     ],
     "count": 18,
     "rot": "random",
     "min_dist": 3.5
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      18,
      36,
      43,
      88
     ],
     "count": 10,
     "rot": "random",
     "min_dist": 2.5
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      18,
      36,
      43,
      88
     ],
     "count": 6,
     "allowed": [
      0,
      1,
      3
     ],
     "foods": [
      "popcorn",
      "bagel",
      "corn",
      "sandwich",
      "cupcake"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      18,
      36,
      43,
      88
     ],
     "count": 4,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bush",
     "rect": [
      18,
      36,
      43,
      88
     ],
     "count": 4,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "северный луг",
   "ops": [
    {
     "type": "place",
     "props": [
      {
       "model": "flowerbed",
       "pos": [
        -30,
        0,
        116
       ],
       "rot": 0
      },
      {
       "model": "flowerbed",
       "pos": [
        -10,
        0,
        116
       ],
       "rot": 0
      },
      {
       "model": "flowerbed",
       "pos": [
        10,
        0,
        116
       ],
       "rot": 0
      },
      {
       "model": "flowerbed",
       "pos": [
        30,
        0,
        116
       ],
       "rot": 0
      }
     ],
     "hazards": [
      {
       "type": "sprinkler",
       "pos": [
        -20,
        0,
        110
       ],
       "offset": 3
      },
      {
       "type": "sprinkler",
       "pos": [
        20,
        0,
        112
       ],
       "offset": 10
      },
      {
       "type": "sprinkler",
       "pos": [
        -30,
        0,
        40
       ],
       "offset": 17
      },
      {
       "type": "guard",
       "pos": [
        -10,
        0,
        70
       ],
       "rot": 0,
       "path": [
        [
         -10,
         70
        ],
        [
         -12,
         104
        ],
        [
         12,
         104
        ],
        [
         14,
         70
        ]
       ]
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      -43,
      100,
      43,
      123
     ],
     "count": 8,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "grass",
     "rect": [
      -43,
      100,
      43,
      123
     ],
     "count": 12,
     "rot": "random",
     "min_dist": 2.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -43,
      100,
      43,
      123
     ],
     "count": 6,
     "allowed": [
      0,
      1,
      2
     ],
     "foods": [
      "popcorn",
      "bagel",
      "corn",
      "sandwich",
      "cotton_candy"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -43,
      100,
      43,
      123
     ],
     "count": 5,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bush",
     "rect": [
      -43,
      100,
      43,
      123
     ],
     "count": 3,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      -43,
      100,
      43,
      123
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "западные поляны",
   "ops": [
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      -43,
      31,
      -17,
      53
     ],
     "count": 5,
     "rot": "random",
     "min_dist": 4.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      -43,
      80,
      -17,
      98
     ],
     "count": 5,
     "rot": "random",
     "min_dist": 4.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -43,
      31,
      -17,
      53
     ],
     "count": 3,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "popcorn",
      "bagel",
      "corn",
      "sandwich"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -43,
      80,
      -17,
      98
     ],
     "count": 2,
     "allowed": [
      1,
      2
     ],
     "foods": [
      "corn",
      "sandwich",
      "cotton_candy"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -43,
      31,
      -17,
      53
     ],
     "count": 2,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -43,
      80,
      -17,
      98
     ],
     "count": 1,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bush",
     "rect": [
      -43,
      31,
      -17,
      98
     ],
     "count": 2,
     "min_dist": 3.0
    }
   ]
  }
 ]
}
```

## `data/layout_src/park_core.json`

```json
{
 "props": [
  {
   "model": "fence",
   "pos": [
    -14,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    -12,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    -10,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    -8,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    -6,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    -4,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    -2,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    0,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    2,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    4,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    6,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    8,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    10,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fence",
   "pos": [
    14,
    0,
    29.9
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      1.8,
      0.12
     ],
     "offset": [
      0,
      0.9,
      0
     ]
    }
   ]
  },
  {
   "model": "fountain",
   "pos": [
    0,
    0,
    45
   ],
   "rot": 0,
   "water": true,
   "colliders": [
    {
     "size": [
      3.2,
      0.45,
      3.2
     ],
     "offset": [
      0,
      0.225,
      0
     ]
    },
    {
     "size": [
      0.5,
      1.4,
      0.5
     ],
     "offset": [
      0,
      0.7,
      0
     ]
    }
   ]
  },
  {
   "model": "slide",
   "pos": [
    -9,
    0,
    38
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      1.3,
      0.06,
      1.3
     ],
     "offset": [
      0,
      0.72,
      0
     ]
    },
    {
     "size": [
      1.2,
      0.7,
      0.08
     ],
     "offset": [
      0,
      0.35,
      0.56
     ]
    },
    {
     "size": [
      0.08,
      0.7,
      1.2
     ],
     "offset": [
      -0.56,
      0.35,
      0
     ]
    },
    {
     "size": [
      0.08,
      0.7,
      1.2
     ],
     "offset": [
      0.56,
      0.35,
      0
     ]
    }
   ]
  },
  {
   "model": "swings",
   "pos": [
    -9,
    0,
    45
   ],
   "rot": 90,
   "colliders": [
    {
     "size": [
      0.2,
      1.9,
      0.8
     ],
     "offset": [
      -1.15,
      0.95,
      0
     ]
    },
    {
     "size": [
      0.2,
      1.9,
      0.8
     ],
     "offset": [
      1.15,
      0.95,
      0
     ]
    }
   ]
  },
  {
   "model": "sandbox",
   "pos": [
    -5,
    0,
    37.5
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      2.0,
      0.2,
      2.0
     ],
     "offset": [
      0,
      0.1,
      0
     ]
    }
   ]
  },
  {
   "model": "kiosk",
   "pos": [
    9,
    0,
    41.5
   ],
   "rot": 180
  },
  {
   "model": "shed",
   "pos": [
    11,
    0,
    56
   ],
   "rot": 180
  },
  {
   "model": "tree",
   "pos": [
    -12,
    0,
    32.5
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.3,
      1.6,
      0.3
     ],
     "offset": [
      0,
      0.8,
      0
     ]
    }
   ]
  },
  {
   "model": "tree",
   "pos": [
    12,
    0,
    51
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.3,
      1.6,
      0.3
     ],
     "offset": [
      0,
      0.8,
      0
     ]
    }
   ]
  },
  {
   "model": "tree",
   "pos": [
    -12,
    0,
    58
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.3,
      1.6,
      0.3
     ],
     "offset": [
      0,
      0.8,
      0
     ]
    }
   ]
  },
  {
   "model": "tree",
   "pos": [
    -6,
    0,
    57
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.3,
      1.6,
      0.3
     ],
     "offset": [
      0,
      0.8,
      0
     ]
    }
   ]
  },
  {
   "model": "tree",
   "pos": [
    7,
    0,
    48
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.3,
      1.6,
      0.3
     ],
     "offset": [
      0,
      0.8,
      0
     ]
    }
   ]
  },
  {
   "model": "bench",
   "pos": [
    4,
    0,
    34
   ],
   "rot": -90,
   "colliders": [
    {
     "size": [
      1.5,
      0.08,
      0.45
     ],
     "offset": [
      0,
      0.45,
      0
     ]
    },
    {
     "size": [
      1.5,
      0.4,
      0.06
     ],
     "offset": [
      0,
      0.72,
      0.22
     ]
    }
   ]
  },
  {
   "model": "bench",
   "pos": [
    4,
    0,
    52
   ],
   "rot": -90,
   "colliders": [
    {
     "size": [
      1.5,
      0.08,
      0.45
     ],
     "offset": [
      0,
      0.45,
      0
     ]
    },
    {
     "size": [
      1.5,
      0.4,
      0.06
     ],
     "offset": [
      0,
      0.72,
      0.22
     ]
    }
   ]
  },
  {
   "model": "bench",
   "pos": [
    -4,
    0,
    52
   ],
   "rot": 90,
   "colliders": [
    {
     "size": [
      1.5,
      0.08,
      0.45
     ],
     "offset": [
      0,
      0.45,
      0
     ]
    },
    {
     "size": [
      1.5,
      0.4,
      0.06
     ],
     "offset": [
      0,
      0.72,
      0.22
     ]
    }
   ]
  },
  {
   "model": "bench",
   "pos": [
    -4,
    0,
    34
   ],
   "rot": 90,
   "colliders": [
    {
     "size": [
      1.5,
      0.08,
      0.45
     ],
     "offset": [
      0,
      0.45,
      0
     ]
    },
    {
     "size": [
      1.5,
      0.4,
      0.06
     ],
     "offset": [
      0,
      0.72,
      0.22
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    2,
    0,
    33
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    2,
    0,
    41
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    2,
    0,
    49
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    2,
    0,
    57
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    -2,
    0,
    37
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    -2,
    0,
    53
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    -12,
    0,
    47.5
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "lamp",
   "pos": [
    12,
    0,
    43
   ],
   "rot": 0,
   "colliders": [
    {
     "size": [
      0.2,
      2.6,
      0.2
     ],
     "offset": [
      0,
      1.3,
      0
     ]
    }
   ]
  },
  {
   "model": "flowerbed",
   "pos": [
    -5,
    0,
    49
   ],
   "rot": 0
  },
  {
   "model": "flowerbed",
   "pos": [
    5,
    0,
    41
   ],
   "rot": 0
  },
  {
   "model": "bush",
   "pos": [
    -13,
    0,
    50
   ],
   "rot": 0,
   "solid": false
  },
  {
   "model": "bush",
   "pos": [
    13,
    0,
    36
   ],
   "rot": 0,
   "solid": false
  },
  {
   "model": "bush",
   "pos": [
    6,
    0,
    58.5
   ],
   "rot": 0,
   "solid": false
  },
  {
   "model": "bush",
   "pos": [
    -13.5,
    0,
    40
   ],
   "rot": 30
  },
  {
   "model": "bush",
   "pos": [
    9,
    0,
    59
   ],
   "rot": 30
  },
  {
   "model": "bush",
   "pos": [
    -8,
    0,
    59
   ],
   "rot": 30
  },
  {
   "model": "bush",
   "pos": [
    13.5,
    0,
    47
   ],
   "rot": 30
  },
  {
   "model": "grass",
   "pos": [
    -14,
    0,
    31
   ],
   "rot": 143,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    14,
    0,
    31
   ],
   "rot": 291,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    -7,
    0,
    31.5
   ],
   "rot": 3,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    6,
    0,
    31.5
   ],
   "rot": 46,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    -14,
    0,
    59.5
   ],
   "rot": 342,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    3,
    0,
    59.5
   ],
   "rot": 149,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    -10,
    0,
    53
   ],
   "rot": 61,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    10,
    0,
    34
   ],
   "rot": 188,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    -3,
    0,
    41
   ],
   "rot": 194,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    3,
    0,
    49.5
   ],
   "rot": 79,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    8,
    0,
    53
   ],
   "rot": 259,
   "solid": false
  },
  {
   "model": "grass",
   "pos": [
    -11,
    0,
    41
   ],
   "rot": 306,
   "solid": false
  }
 ],
 "hideouts": [
  {
   "kind": "bush",
   "pos": [
    -13,
    0.25,
    50
   ],
   "size": [
    0.9,
    0.5,
    0.9
   ]
  },
  {
   "kind": "bush",
   "pos": [
    13,
    0.25,
    36
   ],
   "size": [
    0.9,
    0.5,
    0.9
   ]
  },
  {
   "kind": "bush",
   "pos": [
    6,
    0.25,
    58.5
   ],
   "size": [
    0.9,
    0.5,
    0.9
   ]
  },
  {
   "kind": "bench",
   "pos": [
    4,
    0.2,
    52
   ],
   "rot": -90,
   "size": [
    1.2,
    0.4,
    0.35
   ]
  },
  {
   "kind": "bench",
   "pos": [
    -4,
    0.2,
    34
   ],
   "rot": 90,
   "size": [
    1.2,
    0.4,
    0.35
   ]
  },
  {
   "kind": "slide",
   "pos": [
    -9,
    0.3,
    38
   ],
   "size": [
    0.9,
    0.5,
    0.9
   ]
  }
 ],
 "spawn_points": [
  {
   "pos": [
    8,
    0,
    39.3
   ],
   "allowed": [
    0
   ],
   "foods": [
    "popcorn",
    "bagel"
   ]
  },
  {
   "pos": [
    3,
    0,
    35.5
   ],
   "allowed": [
    0
   ],
   "foods": [
    "popcorn",
    "bagel"
   ]
  },
  {
   "pos": [
    3,
    0,
    53.5
   ],
   "allowed": [
    0
   ],
   "foods": [
    "bagel"
   ]
  },
  {
   "pos": [
    -3,
    0,
    50.5
   ],
   "allowed": [
    0
   ],
   "foods": [
    "popcorn"
   ]
  },
  {
   "pos": [
    -11,
    0,
    49
   ],
   "allowed": [
    0
   ],
   "foods": [
    "bagel"
   ]
  },
  {
   "pos": [
    -1,
    0,
    31.5
   ],
   "allowed": [
    0
   ],
   "foods": [
    "popcorn",
    "bagel"
   ]
  },
  {
   "pos": [
    9.5,
    0,
    53.8
   ],
   "allowed": [
    1
   ],
   "foods": [
    "sandwich"
   ]
  },
  {
   "pos": [
    2.3,
    0,
    42.6
   ],
   "allowed": [
    1
   ],
   "foods": [
    "corn"
   ]
  },
  {
   "pos": [
    -2.3,
    0,
    47.4
   ],
   "allowed": [
    1
   ],
   "foods": [
    "corn"
   ]
  },
  {
   "pos": [
    -7,
    0,
    40.2
   ],
   "allowed": [
    2
   ],
   "foods": [
    "cotton_candy"
   ]
  },
  {
   "pos": [
    -6.3,
    0,
    35.2
   ],
   "allowed": [
    2
   ],
   "foods": [
    "cotton_candy"
   ]
  },
  {
   "pos": [
    1.45,
    0.45,
    45
   ],
   "allowed": [
    3
   ],
   "foods": [
    "cupcake"
   ]
  }
 ],
 "yarn": [
  {
   "pos": [
    -1.45,
    0.45,
    45
   ]
  },
  {
   "pos": [
    0,
    0.45,
    46.45
   ]
  },
  {
   "pos": [
    -9,
    0.75,
    38
   ]
  },
  {
   "pos": [
    -5,
    0.2,
    36.6
   ]
  },
  {
   "pos": [
    12.5,
    0,
    57.8
   ]
  },
  {
   "pos": [
    -12.6,
    0,
    33.2
   ]
  },
  {
   "pos": [
    -14,
    0,
    60
   ]
  },
  {
   "pos": [
    14,
    0,
    30.6
   ]
  },
  {
   "pos": [
    -14,
    0,
    30.6
   ]
  },
  {
   "pos": [
    13.7,
    0,
    52.5
   ]
  },
  {
   "pos": [
    -5.5,
    0,
    58.5
   ]
  },
  {
   "pos": [
    7.6,
    0,
    47.3
   ]
  }
 ],
 "gates": [
  {
   "pos": [
    12,
    0,
    29.9
   ],
   "rot": 0,
   "size": [
    2.2,
    2.6,
    0.3
   ],
   "satiety": 25,
   "label": "Ворота в парк открыты!"
  }
 ],
 "hazards": [
  {
   "type": "pigeons",
   "pos": [
    3.2,
    0,
    47.5
   ]
  },
  {
   "type": "pigeons",
   "pos": [
    -3.5,
    0,
    33.2
   ]
  },
  {
   "type": "gardener",
   "pos": [
    11,
    0,
    54.3
   ],
   "rot": 180,
   "path": [
    [
     11,
     50
    ],
    [
     12,
     39
    ],
    [
     6,
     38.5
    ],
    [
     1,
     38.5
    ],
    [
     1,
     52
    ],
    [
     10,
     53
    ]
   ]
  },
  {
   "type": "sprinkler",
   "pos": [
    -7,
    0,
    52
   ],
   "offset": 0
  },
  {
   "type": "sprinkler",
   "pos": [
    7,
    0,
    33.5
   ],
   "offset": 7
  },
  {
   "type": "sprinkler",
   "pos": [
    9,
    0,
    46
   ],
   "offset": 14
  },
  {
   "type": "kid",
   "pos": [
    -7.5,
    0,
    41
   ],
   "rot": 90
  },
  {
   "type": "guard",
   "pos": [
    0,
    0,
    31
   ],
   "rot": 180,
   "path": [
    [
     0,
     31
    ],
    [
     0,
     58
    ],
    [
     -13,
     58
    ],
    [
     -13,
     45
    ],
    [
     0,
     45
    ],
    [
     13,
     45
    ],
    [
     13,
     31
    ]
   ]
  }
 ],
 "note": "Ядро парка ×3: прежний парк 30×32 без боковых и северного заборов (план 12)."
}
```

## `data/layout_src/port.json`

```json
{
 "name": "port",
 "seed": 13,
 "defaults": [
  "data/layout_src/park_core.json",
  "data/layout_src/yard_core.json"
 ],
 "note": "Порт (этап 3, спек порта и масштаба): набережная на террасе, причал ниже, пляж с дюнами, море и гавань, лодки и бочки.",
 "terrain": {
  "size": [
   120,
   102
  ],
  "origin": [
   -60,
   125
  ],
  "cell": 1.0,
  "base": -2.0,
  "channels": [
   "stone",
   "sand",
   "planks",
   "grass"
  ],
  "default": "sand",
  "features": [],
  "paint": []
 },
 "counts": {
  "spawn_points": 35,
  "yarn": 25,
  "hideouts": 14
 },
 "zones": [
  {
   "name": "море и гавань",
   "ops": [
    {
     "type": "flat",
     "rect": [
      -60,
      195,
      60,
      227
     ],
     "height": -3.5
    },
    {
     "type": "flat",
     "rect": [
      10,
      148,
      60,
      195
     ],
     "height": -3.5
    },
    {
     "type": "water",
     "rect": [
      -60,
      194,
      60,
      227
     ],
     "level": -2.3,
     "shore": [
      [
       -55,
       0,
       192
      ],
      [
       -45,
       0,
       192
      ],
      [
       -35,
       0,
       192
      ],
      [
       -25,
       0,
       192
      ],
      [
       -15,
       0,
       192
      ],
      [
       -5,
       0,
       192
      ],
      [
       5,
       0,
       192
      ]
     ]
    },
    {
     "type": "water",
     "rect": [
      9,
      148,
      60,
      195
     ],
     "level": -2.3,
     "shore": [
      [
       25,
       0,
       155
      ],
      [
       25,
       0,
       165
      ],
      [
       25,
       0,
       175
      ],
      [
       25,
       0,
       185
      ],
      [
       25,
       0,
       195
      ],
      [
       25,
       0,
       205
      ],
      [
       40,
       0,
       145
      ],
      [
       50,
       0,
       145
      ],
      [
       57,
       0,
       145
      ],
      [
       8,
       0,
       155
      ],
      [
       8,
       0,
       165
      ],
      [
       8,
       0,
       175
      ],
      [
       8,
       0,
       185
      ]
     ]
    },
    {
     "type": "place",
     "floaters": [
      {
       "model": "boat",
       "pos": [
        37.3,
        -2.1,
        165
       ],
       "rot": 0,
       "period": 3.4,
       "phase": 0.0,
       "colliders": [
        {
         "size": [
          1.6,
          0.75,
          4.2
         ],
         "offset": [
          0,
          0.075,
          0
         ]
        }
       ]
      },
      {
       "model": "boat",
       "pos": [
        37.3,
        -2.1,
        181
       ],
       "rot": 0,
       "period": 3.8,
       "phase": 1.7,
       "colliders": [
        {
         "size": [
          1.6,
          0.75,
          4.2
         ],
         "offset": [
          0,
          0.075,
          0
         ]
        }
       ]
      },
      {
       "model": "boat",
       "pos": [
        12.7,
        -2.1,
        176
       ],
       "rot": 0,
       "period": 3.1,
       "phase": 3.1,
       "colliders": [
        {
         "size": [
          1.6,
          0.75,
          4.2
         ],
         "offset": [
          0,
          0.075,
          0
         ]
        }
       ]
      },
      {
       "model": "barrel",
       "pos": [
        37.6,
        -2.6999999999999997,
        169
       ],
       "rot": 0,
       "amp": 0.06,
       "roll": 4.0,
       "period": 2.6,
       "phase": 0.0,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      },
      {
       "model": "barrel",
       "pos": [
        37.6,
        -2.6999999999999997,
        171
       ],
       "rot": 0,
       "amp": 0.06,
       "roll": 4.0,
       "period": 2.8000000000000003,
       "phase": 1.1,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      },
      {
       "model": "barrel",
       "pos": [
        37.6,
        -2.6999999999999997,
        173
       ],
       "rot": 0,
       "amp": 0.06,
       "roll": 4.0,
       "period": 3.0,
       "phase": 2.2,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      },
      {
       "model": "barrel",
       "pos": [
        37.6,
        -2.6999999999999997,
        175
       ],
       "rot": 0,
       "amp": 0.06,
       "roll": 4.0,
       "period": 3.2,
       "phase": 3.3000000000000003,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      },
      {
       "model": "barrel",
       "pos": [
        37.6,
        -2.6999999999999997,
        177
       ],
       "rot": 0,
       "amp": 0.06,
       "roll": 4.0,
       "period": 3.4000000000000004,
       "phase": 4.4,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      },
      {
       "model": "buoy",
       "pos": [
        -40,
        -2.3,
        215
       ],
       "rot": 0,
       "amp": 0.08,
       "period": 2.9,
       "phase": -4.0,
       "solid": false
      },
      {
       "model": "buoy",
       "pos": [
        -10,
        -2.3,
        215
       ],
       "rot": 0,
       "amp": 0.08,
       "period": 2.9,
       "phase": -1.0,
       "solid": false
      },
      {
       "model": "buoy",
       "pos": [
        20,
        -2.3,
        215
       ],
       "rot": 0,
       "amp": 0.08,
       "period": 2.9,
       "phase": 2.0,
       "solid": false
      },
      {
       "model": "buoy",
       "pos": [
        50,
        -2.3,
        215
       ],
       "rot": 0,
       "amp": 0.08,
       "period": 2.9,
       "phase": 5.0,
       "solid": false
      }
     ],
     "spawn_points": [
      {
       "pos": [
        37.3,
        -1.55,
        164
       ],
       "allowed": [
        1
       ],
       "foods": [
        "squid"
       ],
       "snap": false
      },
      {
       "pos": [
        12.7,
        -1.55,
        177
       ],
       "allowed": [
        1
       ],
       "foods": [
        "squid",
        "fish_sandwich"
       ],
       "snap": false
      },
      {
       "pos": [
        37.3,
        -1.55,
        182
       ],
       "allowed": [
        2
       ],
       "foods": [
        "sushi"
       ],
       "snap": false
      }
     ],
     "yarn": [
      {
       "pos": [
        37.3,
        -1.55,
        166.5
       ],
       "snap": false
      },
      {
       "pos": [
        12.7,
        -1.55,
        174.5
       ],
       "snap": false
      }
     ]
    }
   ]
  },
  {
   "name": "причал",
   "ops": [
    {
     "type": "terrace",
     "rect": [
      15,
      148,
      35,
      212
     ],
     "height": 1,
     "sides": "swe",
     "ground": -2.3,
     "wall_h": 2,
     "gaps": [
      [
       "e",
       165,
       1.0
      ],
      [
       "e",
       181,
       1.0
      ],
      [
       "w",
       176,
       1.0
      ]
     ],
     "level": -1.0
    },
    {
     "type": "block",
     "rect": [
      22.5,
      151,
      27.5,
      211
     ]
    },
    {
     "type": "paint",
     "rect": [
      15,
      148,
      35,
      212
     ],
     "surface": "planks"
    },
    {
     "type": "place",
     "props": [
      {
       "model": "terrace_stairs1",
       "pos": [
        25,
        0,
        149.5
       ],
       "rot": 0
      },
      {
       "model": "bollard",
       "pos": [
        16,
        0,
        160
       ],
       "rot": 0
      },
      {
       "model": "bollard",
       "pos": [
        16,
        0,
        180
       ],
       "rot": 0
      },
      {
       "model": "bollard",
       "pos": [
        16,
        0,
        200
       ],
       "rot": 0
      },
      {
       "model": "bollard",
       "pos": [
        34,
        0,
        160
       ],
       "rot": 0
      },
      {
       "model": "bollard",
       "pos": [
        34,
        0,
        180
       ],
       "rot": 0
      },
      {
       "model": "bollard",
       "pos": [
        34,
        0,
        200
       ],
       "rot": 0
      },
      {
       "model": "pontoon",
       "pos": [
        35.7,
        -1.75,
        165
       ],
       "rot": 0,
       "snap": false,
       "colliders": [
        {
         "size": [
          1.4,
          0.3,
          1.6
         ],
         "offset": [
          0,
          0.15,
          0
         ]
        }
       ]
      },
      {
       "model": "pontoon",
       "pos": [
        35.7,
        -1.75,
        181
       ],
       "rot": 0,
       "snap": false,
       "colliders": [
        {
         "size": [
          1.4,
          0.3,
          1.6
         ],
         "offset": [
          0,
          0.15,
          0
         ]
        }
       ]
      },
      {
       "model": "pontoon",
       "pos": [
        14.3,
        -1.75,
        176
       ],
       "rot": 0,
       "snap": false,
       "colliders": [
        {
         "size": [
          1.4,
          0.3,
          1.6
         ],
         "offset": [
          0,
          0.15,
          0
         ]
        }
       ]
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "box",
     "rect": [
      16,
      150,
      34,
      210
     ],
     "count": 4,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      16,
      150,
      34,
      210
     ],
     "count": 8,
     "allowed": [
      0,
      1,
      2
     ],
     "foods": [
      "shrimp",
      "fries",
      "squid",
      "fish_sandwich",
      "sushi"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      16,
      150,
      34,
      210
     ],
     "count": 6,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      16,
      150,
      34,
      210
     ],
     "count": 4,
     "min_dist": 3.0
    },
    {
     "type": "place",
     "props": [
      {
       "model": "box",
       "pos": [
        24.6,
        0,
        209.8
       ],
       "rot": 0,
       "outline": true
      },
      {
       "model": "box",
       "pos": [
        25.4,
        0,
        209.8
       ],
       "rot": 0,
       "outline": true
      },
      {
       "model": "box",
       "pos": [
        25.0,
        0.3,
        209.8
       ],
       "rot": 15,
       "outline": true
      }
     ],
     "hazards": [
      {
       "type": "forklift",
       "pos": [
        25,
        0,
        153
       ],
       "rot": 0,
       "path": [
        [
         25,
         153
        ],
        [
         25,
         207
        ]
       ]
      },
      {
       "type": "gull",
       "pos": [
        30,
        0,
        192
       ],
       "phase": 0.0
      }
     ]
    }
   ]
  },
  {
   "name": "набережная",
   "ops": [
    {
     "type": "terrace",
     "rect": [
      -60,
      125,
      60,
      148
     ],
     "height": 2,
     "sides": "s",
     "ground": -2.3,
     "wall_h": 3,
     "gaps": [
      [
       "s",
       25,
       1.0
      ]
     ],
     "access": [
      [
       "s",
       -40,
       "stairs"
      ],
      [
       "s",
       -15,
       "stairs"
      ],
      [
       "s",
       2,
       "ramp"
      ]
     ],
     "level": 0.0
    },
    {
     "type": "paint",
     "rect": [
      -60,
      125,
      60,
      148.5
     ],
     "surface": "stone"
    },
    {
     "type": "perimeter",
     "rect": [
      -60,
      125,
      60,
      148
     ],
     "model": "fence",
     "length": 2.0,
     "sides": "we",
     "extra": {
      "colliders": [
       {
        "size": [
         2.0,
         1.8,
         0.12
        ],
        "offset": [
         0,
         0.9,
         0
        ]
       }
      ]
     }
    },
    {
     "type": "perimeter",
     "rect": [
      -60,
      125.1,
      60,
      148
     ],
     "model": "fence",
     "length": 2.0,
     "sides": "n",
     "gaps": [
      [
       "n",
       0,
       88
      ]
     ],
     "extra": {
      "colliders": [
       {
        "size": [
         2.0,
         1.8,
         0.12
        ],
        "offset": [
         0,
         0.9,
         0
        ]
       }
      ]
     }
    },
    {
     "type": "place",
     "props": [
      {
       "model": "lamp",
       "pos": [
        -50,
        0,
        146
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        -30,
        0,
        146
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        -10,
        0,
        146
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        10,
        0,
        146
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        30,
        0,
        146
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        50,
        0,
        146
       ],
       "rot": 0
      },
      {
       "model": "kiosk",
       "pos": [
        -30,
        0,
        131
       ],
       "rot": 0
      },
      {
       "model": "bin",
       "pos": [
        -27,
        0,
        131
       ],
       "rot": 0
      },
      {
       "model": "bin",
       "pos": [
        12,
        0,
        131
       ],
       "rot": 0
      },
      {
       "model": "barrel",
       "pos": [
        44,
        0,
        132
       ],
       "rot": 0,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      },
      {
       "model": "barrel",
       "pos": [
        -48,
        0,
        140
       ],
       "rot": 0,
       "colliders": [
        {
         "size": [
          0.7,
          0.7,
          0.7
         ],
         "offset": [
          0,
          0.35,
          0
         ]
        }
       ]
      }
     ],
     "hideouts": [
      {
       "kind": "barrel",
       "pos": [
        44,
        0.2,
        132.75
       ],
       "size": [
        0.6,
        0.4,
        0.6
       ]
      },
      {
       "kind": "barrel",
       "pos": [
        -48,
        0.2,
        140.75
       ],
       "size": [
        0.6,
        0.4,
        0.6
       ]
      }
     ],
     "spawn_points": [
      {
       "pos": [
        -30,
        0,
        133.6
       ],
       "allowed": [
        0
       ],
       "foods": [
        "fries"
       ]
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bench",
     "rect": [
      -58,
      127,
      58,
      145
     ],
     "count": 4,
     "rot": 0,
     "min_dist": 6.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -58,
      127,
      58,
      145
     ],
     "count": 11,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "shrimp",
      "fries",
      "squid",
      "fish_sandwich"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -58,
      127,
      58,
      145
     ],
     "count": 6,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      -58,
      127,
      58,
      145
     ],
     "count": 3,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      -58,
      127,
      58,
      145
     ],
     "count": 2,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "пляж",
   "ops": [
    {
     "type": "hill",
     "center": [
      -45,
      160
     ],
     "radius": 5,
     "height": 0.8
    },
    {
     "type": "hill",
     "center": [
      -20,
      158
     ],
     "radius": 4,
     "height": 0.6
    },
    {
     "type": "hill",
     "center": [
      -52,
      182
     ],
     "radius": 5,
     "height": 0.7
    },
    {
     "type": "perimeter",
     "rect": [
      -60,
      148,
      60,
      195
     ],
     "model": "fence",
     "length": 2.0,
     "sides": "w",
     "extra": {
      "colliders": [
       {
        "size": [
         2.0,
         1.8,
         0.12
        ],
        "offset": [
         0,
         0.9,
         0
        ]
       }
      ]
     }
    },
    {
     "type": "place",
     "props": [
      {
       "model": "boat_upturned",
       "pos": [
        -8,
        0,
        170
       ],
       "rot": 30,
       "colliders": [
        {
         "size": [
          1.6,
          0.12,
          4.2
         ],
         "offset": [
          0,
          0.6,
          0
         ]
        },
        {
         "size": [
          0.12,
          0.6,
          4.2
         ],
         "offset": [
          -0.74,
          0.3,
          0
         ]
        },
        {
         "size": [
          0.12,
          0.6,
          4.2
         ],
         "offset": [
          0.74,
          0.3,
          0
         ]
        }
       ]
      }
     ],
     "hideouts": [
      {
       "kind": "boat",
       "pos": [
        -8,
        0.2,
        170
       ],
       "rot": 30,
       "size": [
        1.2,
        0.4,
        3.6
       ]
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "deckchair",
     "rect": [
      -58,
      153,
      8,
      192
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 4.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "umbrella",
     "rect": [
      -58,
      153,
      8,
      192
     ],
     "count": 4,
     "rot": "random",
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -58,
      153,
      8,
      192
     ],
     "count": 12,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "shrimp",
      "fries",
      "squid",
      "fish_sandwich"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -58,
      153,
      8,
      192
     ],
     "count": 11,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      -58,
      153,
      8,
      192
     ],
     "count": 2,
     "min_dist": 3.0
    },
    {
     "type": "place",
     "hazards": [
      {
       "type": "gull",
       "pos": [
        -30,
        0,
        170
       ],
       "phase": 2.0
      },
      {
       "type": "wave",
       "pos": [
        -25,
        -2.0,
        194.2
       ],
       "snap": false,
       "width": 68,
       "inland": -1
      },
      {
       "type": "crab",
       "pos": [
        -50,
        0,
        175
       ]
      },
      {
       "type": "crab",
       "pos": [
        -35,
        0,
        186
       ]
      },
      {
       "type": "crab",
       "pos": [
        -15,
        0,
        179
       ]
      },
      {
       "type": "crab",
       "pos": [
        -4,
        0,
        160
       ]
      },
      {
       "type": "crab",
       "pos": [
        -42,
        0,
        164
       ],
       "night_only": true
      },
      {
       "type": "crab",
       "pos": [
        -24,
        0,
        190
       ],
       "night_only": true
      }
     ]
    }
   ]
  }
 ]
}
```

## `data/layout_src/yard.json`

```json
{
 "name": "yard",
 "seed": 11,
 "core": "data/layout_src/yard_core.json",
 "note": "Двор ×3 (спек «Масштаб ×3 и рельеф»): ядро — прежний двор с улицей и кафе; зоны — гаражи, площадка на террасе, сквер с холмом, верхний двор, веранда, окраины.",
 "terrain": {
  "size": [
   180,
   180
  ],
  "origin": [
   -90,
   -150
  ],
  "cell": 1.0,
  "base": 0.0,
  "channels": [
   "asphalt",
   "paving",
   "grass",
   "gravel"
  ],
  "default": "grass",
  "features": [],
  "paint": [
   {
    "rect": [
     -30,
     -16,
     30,
     30
    ],
    "type": "asphalt",
    "soft": 2
   },
   {
    "rect": [
     -90,
     7,
     90,
     17
    ],
    "type": "asphalt"
   },
   {
    "rect": [
     -64,
     -44,
     -20,
     -4
    ],
    "type": "asphalt",
    "soft": 2
   },
   {
    "rect": [
     -25,
     -25,
     5,
     5
    ],
    "type": "paving"
   }
  ]
 },
 "road": {
  "points": [
   [
    -88,
    0,
    12
   ],
   [
    88,
    0,
    12
   ]
  ]
 },
 "counts": {
  "spawn_points": 60,
  "yarn": 40,
  "hideouts": 25
 },
 "zones": [
  {
   "name": "край района",
   "ops": [
    {
     "type": "perimeter",
     "rect": [
      -90,
      -150,
      90,
      30
     ],
     "sides": "nwe"
    },
    {
     "type": "perimeter",
     "rect": [
      -90,
      0,
      -15,
      30
     ],
     "sides": "s"
    },
    {
     "type": "perimeter",
     "rect": [
      15,
      0,
      90,
      30
     ],
     "sides": "s"
    }
   ]
  },
  {
   "name": "улица",
   "ops": [
    {
     "type": "perimeter",
     "rect": [
      -90,
      0,
      -1.7,
      10.9
     ],
     "model": "fence",
     "length": 2.0,
     "sides": "s",
     "extra": {
      "colliders": [
       {
        "size": [
         2.0,
         1.8,
         0.12
        ],
        "offset": [
         0,
         0.9,
         0
        ]
       }
      ]
     }
    },
    {
     "type": "perimeter",
     "rect": [
      1.7,
      0,
      90,
      10.9
     ],
     "model": "fence",
     "length": 2.0,
     "sides": "s",
     "extra": {
      "colliders": [
       {
        "size": [
         2.0,
         1.8,
         0.12
        ],
        "offset": [
         0,
         0.9,
         0
        ]
       }
      ]
     }
    },
    {
     "type": "place",
     "props": [
      {
       "model": "car",
       "pos": [
        -30,
        0,
        8.5
       ],
       "rot": 90
      },
      {
       "model": "car",
       "pos": [
        -48,
        0,
        8.5
       ],
       "rot": 90
      },
      {
       "model": "car",
       "pos": [
        32,
        0,
        8.5
       ],
       "rot": 90
      },
      {
       "model": "car",
       "pos": [
        56,
        0,
        15.5
       ],
       "rot": 90
      },
      {
       "model": "car",
       "pos": [
        -66,
        0,
        15.5
       ],
       "rot": 90
      },
      {
       "model": "bin",
       "pos": [
        -36,
        0,
        8
       ],
       "rot": 0
      },
      {
       "model": "bin",
       "pos": [
        -35,
        0,
        8
       ],
       "rot": 0
      },
      {
       "model": "bin",
       "pos": [
        44,
        0,
        8
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        -40,
        0,
        9
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        40,
        0,
        9
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        70,
        0,
        15
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        -75,
        0,
        15
       ],
       "rot": 0
      }
     ],
     "hazards": [
      {
       "type": "cyclist",
       "pos": [
        -40,
        0,
        12
       ]
      }
     ]
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -86,
      4,
      -16,
      9
     ],
     "count": 2,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "sausage",
      "cookie",
      "pizza",
      "hotdog"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      16,
      4,
      86,
      9
     ],
     "count": 2,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "sausage",
      "cookie",
      "pizza",
      "hotdog"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      -86,
      15,
      -30,
      27
     ],
     "count": 1,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      30,
      15,
      86,
      27
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "гаражи",
   "ops": [
    {
     "type": "garage_row",
     "origin": [
      -58,
      -30
     ],
     "count": 8,
     "rot": 0,
     "foods": [
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ]
    },
    {
     "type": "garage_row",
     "origin": [
      -35.6,
      -36
     ],
     "count": 8,
     "rot": 180,
     "foods": [
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ]
    },
    {
     "type": "place",
     "hazards": [
      {
       "type": "dog",
       "pos": [
        -40,
        0,
        -22
       ],
       "rot": 90
      }
     ],
     "props": [
      {
       "model": "lamp",
       "pos": [
        -46,
        0,
        -24
       ],
       "rot": 0
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bin",
     "rect": [
      -62,
      -26,
      -22,
      -8
     ],
     "count": 3,
     "rot": "random",
     "min_dist": 2.5
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "box",
     "rect": [
      -62,
      -26,
      -22,
      -8
     ],
     "count": 3,
     "rot": "random",
     "min_dist": 2.5
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -62,
      -26,
      -22,
      -8
     ],
     "count": 6,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "sausage",
      "cookie",
      "pizza",
      "hotdog"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -62,
      -26,
      -22,
      -8
     ],
     "count": 3,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      -62,
      -26,
      -22,
      -8
     ],
     "count": 3,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "площадка",
   "ops": [
    {
     "type": "terrace",
     "rect": [
      22,
      -40,
      52,
      -14
     ],
     "height": 2,
     "access": [
      [
       "s",
       30,
       "stairs"
      ],
      [
       "w",
       -27,
       "ramp"
      ]
     ]
    },
    {
     "type": "paint",
     "rect": [
      22,
      -40,
      52,
      -14
     ],
     "surface": "gravel"
    },
    {
     "type": "place",
     "props": [
      {
       "model": "sandbox",
       "pos": [
        32,
        0,
        -31
       ],
       "rot": 0
      },
      {
       "model": "swings",
       "pos": [
        42,
        0,
        -22
       ],
       "rot": 0
      },
      {
       "model": "slide",
       "pos": [
        45,
        0,
        -33
       ],
       "rot": 90
      },
      {
       "model": "bench",
       "pos": [
        27,
        0,
        -22
       ],
       "rot": 90
      },
      {
       "model": "lamp",
       "pos": [
        36,
        0,
        -17
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        49,
        0,
        -37
       ],
       "rot": 0
      }
     ],
     "hazards": [
      {
       "type": "wasp",
       "pos": [
        45,
        0.5,
        -33
       ],
       "radius": 2.0
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      24,
      -38,
      50,
      -16
     ],
     "count": 4,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      24,
      -38,
      50,
      -16
     ],
     "count": 6,
     "allowed": [
      0,
      1,
      2
     ],
     "foods": [
      "sausage",
      "cookie",
      "pizza",
      "hotdog",
      "croissant",
      "fish"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      24,
      -38,
      50,
      -16
     ],
     "count": 4,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      24,
      -38,
      50,
      -16
     ],
     "count": 2,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "сквер",
   "ops": [
    {
     "type": "hill",
     "center": [
      0,
      -45
     ],
     "radius": 12,
     "height": 3
    },
    {
     "type": "paint",
     "circle": [
      0,
      -45,
      16
     ],
     "surface": "grass",
     "soft": 3
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      -20,
      -70,
      20,
      -18
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 4.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      -20,
      -70,
      20,
      -18
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "grass",
     "rect": [
      -20,
      -70,
      20,
      -18
     ],
     "count": 10,
     "rot": "random",
     "min_dist": 2.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -20,
      -70,
      20,
      -18
     ],
     "count": 6,
     "allowed": [
      0,
      1
     ],
     "foods": [
      "sausage",
      "cookie",
      "pizza",
      "hotdog"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -20,
      -70,
      20,
      -18
     ],
     "count": 4,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      -20,
      -70,
      20,
      -18
     ],
     "count": 2,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "верхний двор",
   "ops": [
    {
     "type": "terrace",
     "rect": [
      -40,
      -118,
      40,
      -72
     ],
     "height": 2,
     "access": [
      [
       "s",
       -12,
       "stairs"
      ],
      [
       "s",
       18,
       "stairs"
      ],
      [
       "e",
       -95,
       "ramp"
      ]
     ]
    },
    {
     "type": "paint",
     "rect": [
      -40,
      -118,
      40,
      -72
     ],
     "surface": "paving"
    },
    {
     "type": "perimeter",
     "rect": [
      -38,
      -116,
      38,
      -72
     ],
     "sides": "n"
    },
    {
     "type": "place",
     "props": [
      {
       "model": "stairs",
       "pos": [
        -25,
        0,
        -113.5
       ],
       "rot": 0
      },
      {
       "model": "stairs",
       "pos": [
        0,
        0,
        -113.5
       ],
       "rot": 0
      },
      {
       "model": "stairs",
       "pos": [
        25,
        0,
        -113.5
       ],
       "rot": 0
      },
      {
       "model": "flowerbed",
       "pos": [
        -22,
        0,
        -100
       ],
       "rot": 0
      },
      {
       "model": "flowerbed",
       "pos": [
        -18,
        0,
        -100
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        -10,
        0,
        -85
       ],
       "rot": 0
      },
      {
       "model": "lamp",
       "pos": [
        20,
        0,
        -85
       ],
       "rot": 0
      },
      {
       "model": "bench",
       "pos": [
        5,
        0,
        -100
       ],
       "rot": 0
      }
     ],
     "spawn_points": [
      {
       "pos": [
        -25,
        1.0,
        -110.95
       ],
       "allowed": [
        1,
        2
       ],
       "foods": [
        "pizza",
        "hotdog",
        "croissant",
        "fish"
       ]
      },
      {
       "pos": [
        0,
        1.0,
        -110.95
       ],
       "allowed": [
        1,
        2
       ],
       "foods": [
        "pizza",
        "hotdog",
        "croissant",
        "fish"
       ]
      },
      {
       "pos": [
        25,
        1.0,
        -110.95
       ],
       "allowed": [
        1,
        2
       ],
       "foods": [
        "pizza",
        "hotdog",
        "croissant",
        "fish"
       ]
      }
     ],
     "yarn": [
      {
       "pos": [
        -24.6,
        0.5,
        -113.0
       ]
      },
      {
       "pos": [
        0.4,
        0.5,
        -113.0
       ]
      },
      {
       "pos": [
        25.4,
        0.5,
        -113.0
       ]
      }
     ],
     "hazards": [
      {
       "type": "dog",
       "pos": [
        10,
        0,
        -90
       ],
       "rot": 0
      },
      {
       "type": "wasp",
       "pos": [
        -20,
        0.5,
        -100
       ],
       "radius": 2.0
      }
     ]
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      -36,
      -110,
      36,
      -76
     ],
     "count": 4,
     "rot": "random",
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      -36,
      -110,
      36,
      -76
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -36,
      -110,
      36,
      -76
     ],
     "count": 8,
     "allowed": [
      0,
      1,
      2,
      3
     ],
     "foods": [
      "sausage",
      "cookie",
      "pizza",
      "hotdog",
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ],
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -36,
      -110,
      36,
      -76
     ],
     "count": 6,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      -36,
      -110,
      36,
      -76
     ],
     "count": 4,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "bench",
     "rect": [
      -36,
      -110,
      36,
      -76
     ],
     "count": 2,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "веранда кафе",
   "ops": [
    {
     "type": "terrace",
     "rect": [
      -27,
      15,
      -13,
      26
     ],
     "height": 1,
     "access": [
      [
       "e",
       20,
       "stairs"
      ]
     ]
    },
    {
     "type": "paint",
     "rect": [
      -27,
      15,
      -13,
      26
     ],
     "surface": "paving"
    },
    {
     "type": "place",
     "props": [
      {
       "model": "cafe_table",
       "pos": [
        -23,
        0,
        18
       ]
      },
      {
       "model": "cafe_table",
       "pos": [
        -19,
        0,
        22
       ]
      },
      {
       "model": "cafe_table",
       "pos": [
        -23,
        0,
        23
       ]
      },
      {
       "model": "umbrella",
       "pos": [
        -22.3,
        0,
        18.7
       ]
      },
      {
       "model": "umbrella",
       "pos": [
        -18.3,
        0,
        22.7
       ]
      },
      {
       "model": "chair",
       "pos": [
        -23,
        0,
        17.2
       ],
       "rot": 180
      },
      {
       "model": "chair",
       "pos": [
        -19,
        0,
        21.2
       ],
       "rot": 180
      },
      {
       "model": "chair",
       "pos": [
        -23,
        0,
        22.2
       ],
       "rot": 180
      },
      {
       "model": "lamp",
       "pos": [
        -26,
        0,
        25
       ],
       "rot": 0
      }
     ],
     "spawn_points": [
      {
       "pos": [
        -23,
        0.75,
        18
       ],
       "allowed": [
        2
       ],
       "foods": [
        "croissant",
        "fish"
       ]
      },
      {
       "pos": [
        -19,
        0.75,
        22
       ],
       "allowed": [
        3
       ],
       "foods": [
        "donut",
        "ice_cream"
       ]
      },
      {
       "pos": [
        -23,
        0.75,
        23
       ],
       "allowed": [
        1
       ],
       "foods": [
        "pizza",
        "hotdog"
       ]
      }
     ]
    }
   ]
  },
  {
   "name": "окраина запад",
   "ops": [
    {
     "type": "paint",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "surface": "grass",
     "soft": 2
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "count": 5,
     "rot": "random",
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "grass",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "count": 8,
     "rot": "random",
     "min_dist": 2.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "count": 2,
     "allowed": [
      1,
      2,
      3
     ],
     "foods": [
      "pizza",
      "hotdog",
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ],
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "count": 1,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      -88,
      -146,
      -66,
      -46
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "окраина восток",
   "ops": [
    {
     "type": "paint",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "surface": "grass",
     "soft": 2
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "count": 5,
     "rot": "random",
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "grass",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "count": 8,
     "rot": "random",
     "min_dist": 2.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "count": 2,
     "allowed": [
      1,
      2,
      3
     ],
     "foods": [
      "pizza",
      "hotdog",
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ],
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "count": 1,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      56,
      -146,
      88,
      -46
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "окраина север",
   "ops": [
    {
     "type": "paint",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "surface": "grass",
     "soft": 2
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "count": 5,
     "rot": "random",
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "grass",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "count": 8,
     "rot": "random",
     "min_dist": 2.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "count": 2,
     "allowed": [
      1,
      2,
      3
     ],
     "foods": [
      "pizza",
      "hotdog",
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ],
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "count": 1,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      -60,
      -146,
      52,
      -124
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  },
  {
   "name": "окраина юго-восток",
   "ops": [
    {
     "type": "paint",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "surface": "grass",
     "soft": 2
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "tree",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "count": 5,
     "rot": "random",
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "bush",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "count": 6,
     "rot": "random",
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "prop",
     "model": "grass",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "count": 8,
     "rot": "random",
     "min_dist": 2.0
    },
    {
     "type": "scatter",
     "what": "spawn",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "count": 2,
     "allowed": [
      1,
      2,
      3
     ],
     "foods": [
      "pizza",
      "hotdog",
      "croissant",
      "fish",
      "donut",
      "ice_cream"
     ],
     "min_dist": 5.0
    },
    {
     "type": "scatter",
     "what": "yarn",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "count": 1,
     "min_dist": 3.0
    },
    {
     "type": "scatter",
     "what": "hideout",
     "kind": "box",
     "rect": [
      56,
      -40,
      88,
      4
     ],
     "count": 1,
     "min_dist": 3.0
    }
   ]
  }
 ]
}
```

## `data/layout_src/yard_core.json`

```json
{
  "props": [
    {
      "model": "wall",
      "pos": [
        0,
        0,
        -14
      ],
      "rot": 0
    },
    {
      "model": "wall",
      "pos": [
        6,
        0,
        -14
      ],
      "rot": 0
    },
    {
      "model": "wall",
      "pos": [
        -6,
        0,
        -14
      ],
      "rot": 0
    },
    {
      "model": "wall",
      "pos": [
        -12,
        0,
        -8
      ],
      "rot": 90
    },
    {
      "model": "wall",
      "pos": [
        -12,
        0,
        -2
      ],
      "rot": 90
    },
    {
      "model": "door",
      "pos": [
        3,
        0,
        -13.75
      ],
      "rot": 0
    },
    {
      "model": "door",
      "pos": [
        -9,
        0,
        -13.75
      ],
      "rot": 0
    },
    {
      "model": "stairs",
      "pos": [
        -11.3,
        0,
        -11.5
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            1.2,
            0.25,
            0.5
          ],
          "offset": [
            0,
            0.125,
            0
          ]
        },
        {
          "size": [
            1.2,
            0.5,
            0.5
          ],
          "offset": [
            0,
            0.25,
            0.5
          ]
        },
        {
          "size": [
            1.2,
            0.75,
            0.5
          ],
          "offset": [
            0,
            0.375,
            1.0
          ]
        },
        {
          "size": [
            1.2,
            1.0,
            0.5
          ],
          "offset": [
            0,
            0.5,
            1.5
          ]
        },
        {
          "size": [
            1.2,
            0.12,
            1.2
          ],
          "offset": [
            0,
            0.94,
            2.55
          ]
        }
      ]
    },
    {
      "model": "bin",
      "pos": [
        3,
        0,
        -11
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.74,
            1.12,
            0.84
          ],
          "offset": [
            0,
            0.56,
            0
          ]
        }
      ]
    },
    {
      "model": "bin",
      "pos": [
        4,
        0,
        -11
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.74,
            1.12,
            0.84
          ],
          "offset": [
            0,
            0.56,
            0
          ]
        }
      ]
    },
    {
      "model": "bin",
      "pos": [
        -6,
        0,
        2
      ],
      "rot": 90,
      "colliders": [
        {
          "size": [
            0.74,
            1.12,
            0.84
          ],
          "offset": [
            0,
            0.56,
            0
          ]
        }
      ]
    },
    {
      "model": "bin",
      "pos": [
        -6,
        0,
        3
      ],
      "rot": 90,
      "colliders": [
        {
          "size": [
            0.74,
            1.12,
            0.84
          ],
          "offset": [
            0,
            0.56,
            0
          ]
        }
      ]
    },
    {
      "model": "bag",
      "pos": [
        2.2,
        0,
        -11.2
      ],
      "rot": 30
    },
    {
      "model": "bag",
      "pos": [
        -6.6,
        0,
        1.2
      ],
      "rot": 0
    },
    {
      "model": "box",
      "pos": [
        1.5,
        0,
        1.5
      ],
      "rot": 0,
      "outline": true
    },
    {
      "model": "box",
      "pos": [
        1.5,
        0.3,
        1.5
      ],
      "rot": 20,
      "outline": true
    },
    {
      "model": "box",
      "pos": [
        -2,
        0,
        -1
      ],
      "rot": 45,
      "outline": true
    },
    {
      "model": "box",
      "pos": [
        -3.5,
        0,
        4
      ],
      "rot": 0,
      "outline": true
    },
    {
      "model": "box",
      "pos": [
        6,
        0,
        -1
      ],
      "rot": 0,
      "outline": true
    },
    {
      "model": "box",
      "pos": [
        2.6,
        0,
        -10.4
      ],
      "rot": 10,
      "outline": true
    },
    {
      "model": "car",
      "pos": [
        8,
        0,
        4
      ],
      "rot": 0,
      "outline": true,
      "colliders": [
        {
          "size": [
            1.7,
            1.2,
            3.6
          ],
          "offset": [
            0,
            0.9,
            0
          ]
        }
      ]
    },
    {
      "model": "car",
      "pos": [
        -8,
        0,
        7
      ],
      "rot": 15,
      "outline": true,
      "colliders": [
        {
          "size": [
            1.7,
            1.2,
            3.6
          ],
          "offset": [
            0,
            0.9,
            0
          ]
        }
      ]
    },
    {
      "model": "bench",
      "pos": [
        0,
        0,
        7
      ],
      "rot": 180,
      "outline": true,
      "colliders": [
        {
          "size": [
            1.5,
            0.1,
            0.45
          ],
          "offset": [
            0,
            0.45,
            0
          ]
        },
        {
          "size": [
            1.5,
            0.4,
            0.06
          ],
          "offset": [
            0,
            0.72,
            0.22
          ]
        }
      ]
    },
    {
      "model": "bench",
      "pos": [
        -5,
        0,
        -8
      ],
      "rot": 90,
      "outline": true,
      "colliders": [
        {
          "size": [
            1.5,
            0.1,
            0.45
          ],
          "offset": [
            0,
            0.45,
            0
          ]
        },
        {
          "size": [
            1.5,
            0.4,
            0.06
          ],
          "offset": [
            0,
            0.72,
            0.22
          ]
        }
      ]
    },
    {
      "model": "lamp",
      "pos": [
        5,
        0,
        8
      ],
      "rot": 0
    },
    {
      "model": "lamp",
      "pos": [
        -9,
        0,
        -3
      ],
      "rot": 0
    },
    {
      "model": "tree",
      "pos": [
        9,
        0,
        -6
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.3,
            1.6,
            0.3
          ],
          "offset": [
            0,
            0.8,
            0
          ]
        }
      ]
    },
    {
      "model": "tree",
      "pos": [
        -9,
        0,
        10
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.3,
            1.6,
            0.3
          ],
          "offset": [
            0,
            0.8,
            0
          ]
        }
      ]
    },
    {
      "model": "bush",
      "pos": [
        7,
        0,
        -10
      ],
      "rot": 0
    },
    {
      "model": "bush",
      "pos": [
        -3,
        0,
        10
      ],
      "rot": 40
    },
    {
      "model": "bush",
      "pos": [
        10,
        0,
        0
      ],
      "rot": 0
    },
    {
      "model": "fence",
      "pos": [
        10,
        0,
        7
      ],
      "rot": 90
    },
    {
      "model": "fence",
      "pos": [
        10,
        0,
        9
      ],
      "rot": 90
    },
    {
      "model": "puddle",
      "water": true,
      "pos": [
        3,
        0,
        3
      ],
      "rot": 0
    },
    {
      "model": "puddle",
      "water": true,
      "pos": [
        -5,
        0,
        -5
      ],
      "rot": 60
    },
    {
      "model": "arch",
      "pos": [
        0,
        0,
        10.5
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.5,
            2.6,
            0.6
          ],
          "offset": [
            -1.45,
            1.3,
            0
          ]
        },
        {
          "size": [
            0.5,
            2.6,
            0.6
          ],
          "offset": [
            1.45,
            1.3,
            0
          ]
        }
      ]
    },
    {
      "model": "wall",
      "pos": [
        0,
        0,
        28
      ],
      "rot": 180
    },
    {
      "model": "wall",
      "pos": [
        6,
        0,
        28
      ],
      "rot": 180
    },
    {
      "model": "wall",
      "pos": [
        -6,
        0,
        28
      ],
      "rot": 180
    },
    {
      "model": "cafe_sign",
      "pos": [
        0,
        0,
        26.5
      ],
      "rot": 180
    },
    {
      "model": "cafe_table",
      "pos": [
        -4,
        0,
        17
      ],
      "colliders": [
        {
          "size": [
            0.9,
            0.06,
            0.9
          ],
          "offset": [
            0,
            0.72,
            0
          ]
        },
        {
          "size": [
            0.5,
            0.72,
            0.5
          ],
          "offset": [
            0,
            0.36,
            0
          ]
        }
      ]
    },
    {
      "model": "cafe_table",
      "pos": [
        0,
        0,
        17
      ],
      "colliders": [
        {
          "size": [
            0.9,
            0.06,
            0.9
          ],
          "offset": [
            0,
            0.72,
            0
          ]
        },
        {
          "size": [
            0.5,
            0.72,
            0.5
          ],
          "offset": [
            0,
            0.36,
            0
          ]
        }
      ]
    },
    {
      "model": "cafe_table",
      "pos": [
        4,
        0,
        17
      ],
      "colliders": [
        {
          "size": [
            0.9,
            0.06,
            0.9
          ],
          "offset": [
            0,
            0.72,
            0
          ]
        },
        {
          "size": [
            0.5,
            0.72,
            0.5
          ],
          "offset": [
            0,
            0.36,
            0
          ]
        }
      ]
    },
    {
      "model": "cafe_table",
      "pos": [
        -2,
        0,
        21
      ],
      "colliders": [
        {
          "size": [
            0.9,
            0.06,
            0.9
          ],
          "offset": [
            0,
            0.72,
            0
          ]
        },
        {
          "size": [
            0.5,
            0.72,
            0.5
          ],
          "offset": [
            0,
            0.36,
            0
          ]
        }
      ]
    },
    {
      "model": "cafe_table",
      "pos": [
        2,
        0,
        21
      ],
      "colliders": [
        {
          "size": [
            0.9,
            0.06,
            0.9
          ],
          "offset": [
            0,
            0.72,
            0
          ]
        },
        {
          "size": [
            0.5,
            0.72,
            0.5
          ],
          "offset": [
            0,
            0.36,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        -4,
        0,
        16.2
      ],
      "rot": 180,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        -4,
        0,
        17.8
      ],
      "rot": 0,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        0,
        0,
        16.2
      ],
      "rot": 180,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        0,
        0,
        17.8
      ],
      "rot": 0,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        4,
        0,
        16.2
      ],
      "rot": 180,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        4,
        0,
        17.8
      ],
      "rot": 0,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        -2,
        0,
        21.8
      ],
      "rot": 0,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "chair",
      "pos": [
        2,
        0,
        21.8
      ],
      "rot": 0,
      "outline": true,
      "colliders": [
        {
          "size": [
            0.42,
            0.45,
            0.42
          ],
          "offset": [
            0,
            0.24,
            0
          ]
        }
      ]
    },
    {
      "model": "umbrella",
      "pos": [
        -3.3,
        0,
        17.7
      ],
      "colliders": [
        {
          "size": [
            0.1,
            2.2,
            0.1
          ],
          "offset": [
            0,
            1.1,
            0
          ]
        }
      ]
    },
    {
      "model": "umbrella",
      "pos": [
        4.7,
        0,
        17.7
      ],
      "colliders": [
        {
          "size": [
            0.1,
            2.2,
            0.1
          ],
          "offset": [
            0,
            1.1,
            0
          ]
        }
      ]
    },
    {
      "model": "umbrella",
      "pos": [
        2.7,
        0,
        21.7
      ],
      "colliders": [
        {
          "size": [
            0.1,
            2.2,
            0.1
          ],
          "offset": [
            0,
            1.1,
            0
          ]
        }
      ]
    },
    {
      "model": "bin",
      "pos": [
        8,
        0,
        24
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.74,
            1.12,
            0.84
          ],
          "offset": [
            0,
            0.56,
            0
          ]
        }
      ]
    },
    {
      "model": "bin",
      "pos": [
        9,
        0,
        24
      ],
      "rot": 0,
      "colliders": [
        {
          "size": [
            0.74,
            1.12,
            0.84
          ],
          "offset": [
            0,
            0.56,
            0
          ]
        }
      ]
    },
    {
      "model": "bush",
      "pos": [
        -8,
        0,
        24
      ],
      "rot": 0
    },
    {
      "model": "bush",
      "pos": [
        8,
        0,
        14.5
      ],
      "rot": 20
    },
    {
      "model": "puddle",
      "water": true,
      "pos": [
        -6,
        0,
        19
      ],
      "rot": 30
    },
    {
      "model": "bush",
      "pos": [
        -7.5,
        0,
        -13.0
      ],
      "rot": 294
    },
    {
      "model": "bush",
      "pos": [
        -2.5,
        0,
        -13.0
      ],
      "rot": 193
    },
    {
      "model": "bush",
      "pos": [
        0.0,
        0,
        -13.0
      ],
      "rot": 0
    },
    {
      "model": "bush",
      "pos": [
        8.8,
        0,
        -13.0
      ],
      "rot": 277
    },
    {
      "model": "bush",
      "pos": [
        4.6,
        0,
        -13.0
      ],
      "rot": 28
    },
    {
      "model": "bush",
      "pos": [
        -11.0,
        0,
        -5.0
      ],
      "rot": 90
    },
    {
      "model": "bush",
      "pos": [
        -11.0,
        0,
        0.5
      ],
      "rot": 90
    },
    {
      "model": "grass",
      "pos": [
        -12.5,
        0,
        -12.5
      ],
      "rot": 205,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        12.5,
        0,
        -12.5
      ],
      "rot": 90,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        -12.5,
        0,
        9
      ],
      "rot": 210,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        12.5,
        0,
        9
      ],
      "rot": 95,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        -6,
        0,
        -12.8
      ],
      "rot": 184,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        6,
        0,
        -12.8
      ],
      "rot": 100,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        -12.8,
        0,
        -3
      ],
      "rot": 350,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        12.8,
        0,
        -3
      ],
      "rot": 267,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        3.5,
        0,
        4.2
      ],
      "rot": 256,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        -3,
        0,
        1.5
      ],
      "rot": 226,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        8.5,
        0,
        -5
      ],
      "rot": 5,
      "solid": false
    },
    {
      "model": "grass",
      "pos": [
        -8.5,
        0,
        9.5
      ],
      "rot": 71,
      "solid": false
    },
    {
      "model": "ivy",
      "pos": [
        -6.0,
        2.2,
        -13.78
      ],
      "rot": 0,
      "solid": false
    },
    {
      "model": "ivy",
      "pos": [
        0.0,
        2.2,
        -13.78
      ],
      "rot": 0,
      "solid": false
    },
    {
      "model": "ivy",
      "pos": [
        8.0,
        2.2,
        -13.78
      ],
      "rot": 0,
      "solid": false
    }
  ],
  "hideouts": [
    {
      "kind": "box",
      "pos": [
        -2,
        0.2,
        -0.35
      ],
      "size": [
        0.6,
        0.4,
        0.6
      ]
    },
    {
      "kind": "box",
      "pos": [
        -3.5,
        0.2,
        4.65
      ],
      "size": [
        0.6,
        0.4,
        0.6
      ]
    },
    {
      "kind": "box",
      "pos": [
        6,
        0.2,
        -0.35
      ],
      "size": [
        0.6,
        0.4,
        0.6
      ]
    },
    {
      "kind": "box",
      "pos": [
        2.6,
        0.2,
        -9.75
      ],
      "size": [
        0.6,
        0.4,
        0.6
      ]
    },
    {
      "kind": "car",
      "pos": [
        8,
        0.15,
        4
      ],
      "size": [
        1.4,
        0.3,
        3.2
      ]
    },
    {
      "kind": "car",
      "pos": [
        -8,
        0.15,
        7
      ],
      "rot": 15,
      "size": [
        1.4,
        0.3,
        3.2
      ]
    },
    {
      "kind": "bench",
      "pos": [
        0,
        0.2,
        7
      ],
      "size": [
        1.3,
        0.4,
        0.4
      ]
    },
    {
      "kind": "bench",
      "pos": [
        -5,
        0.2,
        -8
      ],
      "rot": 90,
      "size": [
        1.3,
        0.4,
        0.4
      ]
    }
  ],
  "spawn_points": [
    {
      "pos": [
        3.5,
        0,
        -10
      ],
      "allowed": [
        0
      ],
      "foods": [
        "sausage",
        "cookie"
      ]
    },
    {
      "pos": [
        -5,
        0,
        2.5
      ],
      "allowed": [
        0
      ],
      "foods": [
        "sausage",
        "cookie"
      ]
    },
    {
      "pos": [
        0,
        0,
        -4
      ],
      "allowed": [
        0
      ],
      "foods": [
        "sausage",
        "cookie"
      ]
    },
    {
      "pos": [
        -4,
        0,
        -4
      ],
      "allowed": [
        0
      ],
      "foods": [
        "sausage",
        "cookie"
      ]
    },
    {
      "pos": [
        1,
        0,
        6.3
      ],
      "allowed": [
        0
      ],
      "foods": [
        "sausage",
        "cookie"
      ]
    },
    {
      "pos": [
        -5.8,
        0,
        -7
      ],
      "allowed": [
        0,
        1
      ],
      "foods": [
        "sausage",
        "cookie",
        "pizza",
        "hotdog"
      ]
    },
    {
      "pos": [
        4,
        0,
        4
      ],
      "allowed": [
        0,
        1
      ],
      "foods": [
        "sausage",
        "cookie",
        "pizza",
        "hotdog"
      ]
    },
    {
      "pos": [
        -11.3,
        1.0,
        -9.0
      ],
      "allowed": [
        1
      ],
      "foods": [
        "pizza",
        "hotdog"
      ]
    },
    {
      "pos": [
        2,
        0,
        6
      ],
      "allowed": [
        1,
        3
      ],
      "foods": [
        "pizza",
        "hotdog",
        "donut",
        "ice_cream"
      ]
    },
    {
      "pos": [
        7.5,
        0,
        -8
      ],
      "allowed": [
        2,
        3
      ],
      "foods": [
        "croissant",
        "fish",
        "donut",
        "ice_cream"
      ]
    },
    {
      "pos": [
        -4,
        0,
        15.3
      ],
      "allowed": [
        1
      ],
      "foods": [
        "pizza",
        "hotdog"
      ]
    },
    {
      "pos": [
        4,
        0,
        15.3
      ],
      "allowed": [
        1
      ],
      "foods": [
        "pizza",
        "hotdog"
      ]
    },
    {
      "pos": [
        0,
        0.75,
        17
      ],
      "allowed": [
        2
      ],
      "foods": [
        "croissant",
        "fish"
      ]
    },
    {
      "pos": [
        -2,
        0.75,
        21
      ],
      "allowed": [
        2
      ],
      "foods": [
        "croissant",
        "fish"
      ]
    },
    {
      "pos": [
        2,
        0.75,
        21
      ],
      "allowed": [
        3
      ],
      "foods": [
        "donut",
        "ice_cream"
      ]
    },
    {
      "pos": [
        7,
        0,
        20
      ],
      "allowed": [
        0,
        1
      ],
      "foods": [
        "sausage",
        "cookie",
        "pizza",
        "hotdog"
      ]
    }
  ],
  "hazards": [
    {
      "type": "dog",
      "pos": [
        7,
        0,
        -7
      ],
      "rot": 90
    },
    {
      "type": "wasp",
      "pos": [
        2,
        0.5,
        6
      ],
      "radius": 2.5
    },
    {
      "type": "cyclist",
      "pos": [
        0,
        0,
        12
      ]
    },
    {
      "type": "wasp",
      "pos": [
        2,
        1.1,
        21
      ],
      "radius": 0.8,
      "height": 1.0
    }
  ],
  "road": {
    "points": [
      [
        -25,
        0,
        12
      ],
      [
        25,
        0,
        12
      ]
    ]
  },
  "yarn": [
    {
      "pos": [
        -11.3,
        1.0,
        -9.3
      ]
    },
    {
      "pos": [
        -10.9,
        0.5,
        -11.0
      ]
    },
    {
      "pos": [
        1.5,
        0.6,
        1.5
      ]
    },
    {
      "pos": [
        0.4,
        0.5,
        7.0
      ]
    },
    {
      "pos": [
        8.0,
        0.0,
        5.3
      ]
    },
    {
      "pos": [
        -8.3,
        0.0,
        8.3
      ]
    },
    {
      "pos": [
        -11.2,
        0.0,
        -13.2
      ]
    },
    {
      "pos": [
        11.5,
        0.0,
        -13.0
      ]
    },
    {
      "pos": [
        1.9,
        0.0,
        10.5
      ]
    },
    {
      "pos": [
        -5.6,
        0.0,
        -9.0
      ]
    },
    {
      "pos": [
        -4,
        0.75,
        17
      ]
    },
    {
      "pos": [
        4,
        0.75,
        17
      ]
    }
  ],
  "gates": [
    {
      "pos": [
        0,
        0,
        10.5
      ],
      "rot": 0,
      "size": [
        2.4,
        2.6,
        0.3
      ],
      "satiety": 10
    }
  ],
  "shop": {
    "pos": [
      -4.5,
      0,
      -1.5
    ],
    "rot": 180
  },
  "decals": [
    {
      "texture": "assets/images/world/decal_manhole.png",
      "pos": [
        3,
        0,
        -2
      ],
      "size": [
        1.0,
        1.0
      ]
    },
    {
      "texture": "assets/images/world/decal_cracks.png",
      "pos": [
        -6,
        0,
        4
      ],
      "size": [
        2.0,
        2.0
      ],
      "rot": 20
    },
    {
      "texture": "assets/images/world/decal_cracks.png",
      "pos": [
        8,
        0,
        -9
      ],
      "size": [
        1.5,
        1.5
      ],
      "rot": 110
    },
    {
      "texture": "assets/images/world/decal_leaves.png",
      "pos": [
        -2,
        0,
        -6
      ],
      "size": [
        2.0,
        2.0
      ]
    },
    {
      "texture": "assets/images/world/decal_leaves.png",
      "pos": [
        6,
        0,
        6
      ],
      "size": [
        2.0,
        2.0
      ],
      "rot": 70
    },
    {
      "texture": "assets/images/world/poster_cafe.png",
      "pos": [
        -5.0,
        0.8,
        -13.78
      ],
      "size": [
        0.9,
        0.9
      ],
      "wall": true
    },
    {
      "texture": "assets/images/world/poster_cat.png",
      "pos": [
        6.5,
        0.8,
        -13.78
      ],
      "size": [
        0.8,
        0.8
      ],
      "wall": true
    },
    {
      "texture": "assets/images/world/poster_paws.png",
      "pos": [
        -11.78,
        0.8,
        -6.5
      ],
      "size": [
        0.7,
        0.7
      ],
      "wall": true,
      "rot": 90
    }
  ]
}
```


# Snack Run — памятка для Claude (и для человека) без памяти о прошлых сессиях

3D-игра про котёнка, который собирает вкусняшки и избегает городских опасностей.
Делается для ролика на YouTube-канале «Нейрослоп» (показ вайб-кодинга 3D с Blender и Godot).
Все тексты, комментарии, коммиты — по-русски; идентификаторы кода — по-английски.
Коммиты заканчиваются строкой `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

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
make test          # Blender-тесты (unittest внутри Blender) + GUT; делает import сам
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
- `scripts/hazards/`: `perception.gd`, `chase_brain.gd` (чистые), `hazard_base.gd`, `dog.gd`, `wasp.gd`, `cyclist.gd`.
- `scripts/ui/hud.gd` + `scenes/ui/hud.tscn`; экраны `shop_menu.gd`, `album_menu.gd`, `pause_menu.gd`, `title.gd` (главная сцена `scenes/ui/title.tscn`), `menu_input.gd` (опрос клавиш меню, работает на паузе).
- `scripts/core/shop_item.gd`, `shop_catalog.gd`, `cat_skin.gd`, `skin_catalog.gd`; данные `data/shop/*.tres`, `data/skins/*.tres`.
- `scripts/autoload/save_game.gd` — JSON в `user://save.json`, пишет только по `save_now()` из `Main`; в тестах с `Main` путь переопределяется.
- `scripts/world/gate.gd` (ворота по сытости), `scripts/world/yarn_shop.gd` (будка: безопасная зона, возрождение, витрина), `scripts/food/yarn_pickup.gd`.
- `scripts/visual/toon.gd` — `Toon.apply(root, width_m, character)`; ширина в метрах, пересчитывается под масштаб узла; обводка — `assets/shaders/outline_fur.gdshader`, у персонажей rim и шум. `scripts/visual/effects.gd` — `Effects.burst/dust/hearts/sparkles/trail/zzz/leaves` (частицы; одноразовые удаляются по таймеру).
- `scripts/autoload/sfx.gd` — звуки (`Sfx.play(&"eat")`, один вызов на событие), файлы и лицензии в `assets/sfx/README.md`; `assets/ui/theme.tres` (Nunito, плашки), `assets/shaders/vignette.gdshader`; `scripts/core/mouse.gd` (`Mouse.capture`, в headless no-op).
- `scripts/autoload/input_setup.gd` (InputMap в коде), `dev_tools.gd` (`++ --screenshot=path`).
- `tools/blender/`: `palette.py`, `lib.py` (rounded_box, world_extent, tri_count, check_asset), `export.py`, `build.py`, `cat.py` (сварка + subdivision) + `cat_eyes.py` (глаза) + `cat_fluff.py` (пучки, усы, ошейник), `dog.py` + `dog_sleep.py` (поза «спит»), `gen/*.py` (каждый: `SPEC` + `build()`); `tools/audio/gen_sfx.py`; `tools/images/gen.py` + `manifest.json`; `export_presets.cfg`.
- `scenes/world/lighting.tscn` — солнце, заполняющий свет, окружение (SSAO, SSR, glow, облака `sky_cover`), листья; `WorldBuilder` читает `solid`, `water`, `decals` из `yard.json`.
- `third_party/quaternius_animal_pack_v2/` (CC0 кот и собака), `third_party/unimate_clips/` (канонический риг + клипы jump/hide/hit/run + README с воспроизведением).
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

**План 5:** импортированный glb-меш перед subdivision сваривать (`remove_doubles`), иначе мозаика; subdivision на триангулированном меше ×6; `CPUParticles3D`, созданные в физическом шаге, получают `finished` сразу — эмиссию включать после `add_child`, удалять по таймеру; `ambient_light_source`: 1 = DISABLED, 3 = SKY; внешний `velocity.y` у кота гасится шагом на полу (в тестах прыгать через `Input.action_press("jump")`); с нетипизированным `main` в тестах писать `var x: Тип = main.f()`; `yard.json` многострочный — правки скриптом по строкам; служебный рендер `-s` к `cat.glb` добавляет модификаторы скелета вручную; веки над утопленными глазами читаются как брови — не делать.

**UniMate на Mac** (подробно в заметке): venv Python 3.10 через `uv`, requirements без `+cu124`, `sampling.device = cpu` в `config.json` чекпоинта (MPS не умеет float64), ручная `annotation.json` (авторазметка путает спину и хвост), шим `blender` → venv-python с pip-`bpy` для `run_animate_motion.sh`. Окружение жило в scratchpad и не сохранилось; чекпоинт 1,2 ГБ качается с HF заново.

## Статус и что дальше

- Планы 1–5 выполнены и слиты в `main` (2026-10-09): фундамент, игровой цикл, хаб и прогрессия, полировка под ролик, визуальная полировка (картинки OpenAI, гладкий кот с глазами в глазницах и пучками, короткие лапы, тун v2, яркий день, VFX, зелень и декали). Отложенные мелочи — в конце дорожной карты.
- Следующий шаг: живой плейтест владельца с правками по его замечаниям, затем этапы 2+ (парк, сутки, порт) отдельными спеками через brainstorming.
- Открытый вопрос владельцу: лицензия весов UniMate для сгенерированных движений (код MIT, для весов явной лицензии не найдено).

# Процедура воспроизведения, шаг за шагом (как было сделано на самом деле)

Условные обозначения:
- `GODOT` = `/Applications/Godot.app/Contents/MacOS/Godot`, `BLENDER` = `/Applications/Blender.app/Contents/MacOS/Blender`.
- «Создать файл X» = взять содержимое из `03-files.md` (раздел с таким путём) и записать как есть.
- «Контрольная точка» = обязательная проверка; дальше не идти, пока не совпало.
- Временные файлы (загрузки, окружение UniMate, пробные рендеры) держать вне проекта, в отдельной scratch-папке, например `/tmp/snack_scratch`.

Порядок задач повторяет план 1. Каждая задача: сначала тест (он должен упасть), потом код,
тест зелёный, коммит.

---

## Шаг 0. Репозиторий и референсы

```bash
cd <папка с тремя PNG>
git init
mkdir -p docs/superpowers/specs docs/superpowers/plans docs/superpowers/notes reference
mv "Артборд ассетов для игры про котика.png" reference/artboard_assets.png
mv "Карта приключений кота Snack Run.png" reference/map_world.png
mv "Котёнок в погоне за пиццей.png" reference/keyart_pizza_chase.png
```
Создать `.gitignore` (из приложения). Коммит «Initial commit: концепт-арты Snack Run».

Создать спек `docs/superpowers/specs/2026-10-07-snack-run-design.md` и дорожную карту
`docs/superpowers/plans/2026-10-07-snack-run-roadmap.md` (оба из приложения, целиком). Коммит.

Палитра в спеке (13 цветов + 4 редкости) снята скриптом с цветовой полосы артборда
(строка пикселей y=975, кружки слева направо) и с квадратиков редкостей (x≈947, y=72/122/170/220).
Переснимать не нужно: hex уже в спеке и в `tools/blender/palette.py`.

Ветка для работы: `git checkout -b plan-1-foundation`.

## Шаг 1. Проект Godot, GUT, Makefile

1. Скачать GUT 9.7.1 и положить в `addons/gut`:
```bash
mkdir -p /tmp/snack_scratch/gut && cd /tmp/snack_scratch/gut
curl -sL -o gut.zip https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip && unzip -q -o gut.zip
cd <проект> && mkdir -p addons && cp -R /tmp/snack_scratch/gut/Gut-9.7.1/addons/gut addons/gut
ls addons/gut/gut_cmdln.gd addons/gut/plugin.cfg
```
2. Создать `project.godot`, `.gutconfig.json`, `Makefile`, `scenes/main.tscn` (на этом шаге —
   минимальный `[node name="Main" type="Node3D"]`), заглушки `scripts/autoload/input_setup.gd`
   и `scripts/autoload/dev_tools.gd` (с пустым `_ready`), тест `tests/unit/test_smoke.gd`.
   Итоговые версии Makefile и автозагрузок в приложении уже полные (они появятся к шагу 6);
   на шаге 1 можно сразу взять полные, это ничего не ломает.
3. Контрольная точка: `make import && make test-godot` → `1 passed`, код 0.
4. Коммит «Проект Godot 4.7, GUT 9.7.1, Makefile».

Известные грабли: GUT возвращает код 0 при ошибке парсинга теста, поэтому в Makefile стоит
grep по `SCRIPT ERROR`; `*.import` и `*.uid` коммитятся (не игнорировать).

## Шаг 2. Blender-библиотека

Создать: `tools/blender/tests/run.py`, `tools/blender/tests/test_lib.py` → `make test-blender`
должен упасть с `ModuleNotFoundError: No module named 'lib'`. Затем `tools/blender/palette.py`,
`tools/blender/lib.py` → `Ran 7 tests ... OK`. Затем `tools/blender/tests/test_export.py` (падает
на `export`), `tools/blender/export.py` → `Ran 8 tests ... OK`. Затем `tools/blender/build.py`,
`tools/blender/gen/__init__.py` (пустой), `tools/blender/gen/box.py`, `tools/blender/tests/list_glb.py`.

Контрольная точка:
```bash
make assets ONLY=box      # ОК box -> assets/models/box.glb (108 tri)
$BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/box.glb 2>&1 | grep -E "^(OBJ|   MATS)"
# OBJ MESH box (0.45, 0.35, 0.3) parent -   /   MATS ['sr_sand']
```
Коммит «Blender-пайплайн: палитра, скруглённые боксы, экспорт glb, сборка».

Грабли: `Action.fcurves` в Blender 5 нет; `obj.dimensions` нулевые до `view_layer.update()` и
не учитывают масштаб родителя (поэтому `lib.world_extent`); узел Principled искать по
`node.type == "BSDF_PRINCIPLED"`; Blender без `--python-exit-code 1` возвращает 0 при исключении.

## Шаг 3. Тун-материалы, свет, скриншот из CLI

Создать `tests/unit/test_toon.gd` → `make test-godot` падает (`Identifier "Toon" not declared`).
Создать `scripts/visual/toon.gd`, `scripts/world/lighting.gd`, `scripts/tools/look_at_target.gd`,
`scenes/world/lighting.tscn`, полный `scripts/autoload/dev_tools.gd`.
`make import && make test-godot` → 4 теста Toon зелёные (новый `class_name` виден только после `make import`).

Временно положить в `scenes/main.tscn` свет + коробку + камеру (как в плане 1, задача 3, шаг 5)
и снять `make shot SHOT=build/task3.png`. Контрольная точка: коробка на плоскости, небо
градиентом, тень. Коммит.

Грабли: в `lighting.tscn` `ambient_light_source = 2` (Color), `tonemap_mode = 0` (линейный, Filmic
выцветает палитру); матрицы поворота в tscn не писать руками, поворот солнца задаёт `lighting.gd`.

## Шаг 4. Кот из CC0-пака Quaternius

1. Скачать пак и вендорить:
```bash
mkdir -p /tmp/snack_scratch/q && cd /tmp/snack_scratch/q
curl -sL -o pack.zip "https://opengameart.org/sites/default/files/Animal%20Pack%20Vol.2%20by%20%40Quaternius.zip" && unzip -q -o pack.zip
cd <проект> && mkdir -p third_party/quaternius_animal_pack_v2
cp "/tmp/snack_scratch/q/Animal Pack Vol.2 by @Quaternius/Blends/Cat.blend" "/tmp/snack_scratch/q/Animal Pack Vol.2 by @Quaternius/Blends/Dog.blend" third_party/quaternius_animal_pack_v2/
printf '' > third_party/.gdignore      # иначе Godot пытается импортировать .blend и молча не импортирует glb
```
Создать `third_party/quaternius_animal_pack_v2/LICENSE.md`.
2. Создать `tools/blender/rig_inspect.py` и запустить:
```bash
$BLENDER -b third_party/quaternius_animal_pack_v2/Cat.blend --python tools/blender/rig_inspect.py 2>&1 | grep -E "^(BONE|HEAD)"
```
Ожидается `HEAD Bone.003` (106 вершин, голова впереди по +X). Роли костей: `Bone` таз,
`Bone.001` спина, `Bone.002` шея, `Bone.003` голова, `Bone.004–007` хвост, `Bone.014–016`
правая передняя лапа, `Bone.017–019` левая передняя, `Bone.008–010` левая задняя,
`Bone.011–013` правая задняя, `IK*` контроллеры.
3. Создать `tests/integration/test_cat_asset.gd` (из приложения; он уже включает тест на
   сгенерированные клипы, который до шага 5 будет падать — это нормально).
4. **Важно:** итоговый `tools/blender/cat.py` (в приложении) собирает кота из канонического рига
   UniMate (`third_party/unimate_clips/cat_canonical.glb`), которого на шаге 4 ещё нет. Поэтому
   выполнить шаг 5 (UniMate) сразу после пункта 2 этого шага, а затем вернуться к сборке.
   Промежуточный glb для UniMate делает `tools/blender/cat_quaternius_export.py` (см. 5.3).
5. Создать `tools/blender/gen/cat.py`. `make assets ONLY=cat`. Контрольная точка:
```bash
$BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb 2>&1 | grep -E "^(OBJ|   MATS|ANIM)"
# OBJ MESH cat (~0.11, ~0.26, ~0.35) parent CatRig; MATS ['sr_cat_orange','sr_cream','sr_coral']
# ANIM hide/hit/idle/jump/run/walk (после шага 5); Icosphere в списке — артефакт импортёра, в glb его нет
```
   В логе сборки строка `КОТ СМОТРИТ: (0.00, 0.99, 0.14), ожидается +Y`.
6. `make import && make test-godot` → тесты `test_cat_asset.gd` зелёные.
7. Скриншот спереди: временно в `scenes/main.tscn` вместо коробки кот и камера в точке
   `(0, 0.25, -1.2)` со скриптом `look_at_target.gd`; `make shot SHOT=build/front.png`.
   Контрольная точка: морда (уши, глаза) смотрит в камеру, хвост сзади.
8. Коммит.

Грабли: размер кота в тесте меряется по костям скелета (`get_bone_global_rest`), не по AABB
меша × `global_transform` (даёт 0,02 м); импортёр glTF ставит объектам `rotation_mode =
QUATERNION`, перед правкой `rotation_euler` нужен `XYZ`; экспортёр в режиме ACTIONS терял
активный action — перед экспортом `animation_data.action = None`.

## Шаг 5. Клипы jump/hide/hit/run через UniMate (на Mac, CPU)

Это самый длинный шаг (~1 час). Порядок по правилу владельца: UniMate раньше любой генерации.

### 5.1 Окружение
```bash
mkdir -p /tmp/snack_scratch/unimate && cd /tmp/snack_scratch/unimate
git clone --depth 1 https://github.com/Friedrich-M/UniMate.git
sed -e 's/+cu124//' -e '/^--extra-index-url https:\/\/download.pytorch.org/d' UniMate/requirements.txt > req_mac.txt
uv venv --python 3.10 venv
VIRTUAL_ENV=$PWD/venv uv pip install "setuptools<81"
VIRTUAL_ENV=$PWD/venv uv pip install --no-build-isolation -r req_mac.txt     # ~10 минут
venv/bin/python -c "import torch, bpy; print(torch.__version__, bpy.app.version_string)"   # 2.5.1 4.0.0
```

### 5.2 Чекпоинт (1,2 ГБ; curl иногда обрывается, проверять размер и докачивать `-C -`)
```bash
cd UniMate && mkdir -p outputs/unimate_uniml3d_f60_v3/checkpoints
B=https://huggingface.co/Linzhan/UniMate/resolve/main/unimate_uniml3d_f60_v3
curl -sL -o outputs/unimate_uniml3d_f60_v3/config.json "$B/config.json"
curl -sL -o outputs/unimate_uniml3d_f60_v3/dataset_stats.npy "$B/dataset_stats.npy"
curl -L -C - --retry 5 -o outputs/unimate_uniml3d_f60_v3/checkpoints/checkpoint_step_150000.pt "$B/checkpoints/checkpoint_step_150000.pt"
ls -la outputs/unimate_uniml3d_f60_v3/checkpoints   # должно быть 1185836040 байт
python3 - <<'EOF'
import json; p='outputs/unimate_uniml3d_f60_v3/config.json'; c=json.load(open(p)); c['sampling']['device']='cpu'; json.dump(c, open(p,'w'), indent=1)
EOF
```
`mps` не подходит: torchdiffeq требует float64.

### 5.3 Предобработка рига
Нужен glb кота с ригом Quaternius. Его делает `tools/blender/cat_quaternius_export.py`
(масштаб 0,35 м, палитра, кость `head`, клипы idle/walk):
```bash
cd <проект> && $BLENDER -b --python-exit-code 1 --python tools/blender/cat_quaternius_export.py -- /tmp/snack_scratch/unimate/UniMate/cat.glb
cd /tmp/snack_scratch/unimate/UniMate
```
```bash
../venv/bin/python -m data_process.rig_preprocess run --input cat.glb --output_dir outputs/rig/cat --annotate rule
```
Автоматическая разметка **неверна** (спину называет хвостом, стороны лап путает). Заменить
метки и пару лицевых суставов скриптом:
```bash
python3 - <<'EOF'
import json
p='outputs/rig/cat/annotation.json'; a=json.load(open(p))
labels={'Bone':'Hips','Bone.001':'Spine','Bone.002':'Neck','head':'Head',
 'Bone.014':'Right Front Leg','Bone.015':'Right Front Leg','Bone.016':'Right Front Paw',
 'Bone.017':'Left Front Leg','Bone.018':'Left Front Leg','Bone.019':'Left Front Paw',
 'Bone.004':'Tail','Bone.005':'Tail','Bone.006':'Tail','Bone.007':'Tail End',
 'Bone.008':'Left Hind Leg','Bone.009':'Left Hind Leg','Bone.010':'Left Back Paw',
 'Bone.011':'Right Hind Leg','Bone.012':'Right Hind Leg','Bone.013':'Right Back Paw'}
for j in a['joints']: j['label']=labels[j['raw']]
a['face_pair']['right']='Bone.011'; a['face_pair']['left']='Bone.008'; a['face_pair']['body_axis']=False
json.dump(a, open(p,'w'), indent=1, ensure_ascii=False)
EOF
../venv/bin/python -m data_process.rig_preprocess run --input cat.glb --output_dir outputs/rig/cat --profile general --annotation outputs/rig/cat/annotation.json
```
Готовая `annotation.json` лежит в приложении (`third_party/unimate_clips/annotation.json`).
Контрольная точка: `outputs/rig/cat/preview.png` — передние лапы спереди, хвост сзади, серая
стрелка вперёд; файлы `cond.npy` и `cat.glb` (канонический риг, 20 костей, без IK).

### 5.4 Генерация движений (~1–1,5 мин на клип)
```bash
../venv/bin/python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 --asset outputs/rig/cat \
  --prompt "An object jumps in place." --num_repetitions 2 --output_dir outputs/samples/cat --only_save_motion
../venv/bin/python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 --asset outputs/rig/cat \
  --prompt "An object crouches down low and stays still." "An object flinches backward as if hit." "An object runs forward." \
  --num_repetitions 1 --output_dir outputs/samples/cat2 --only_save_motion
```

### 5.5 Применение движений к мешу
Скрипт `scripts/run_animate_motion.sh` ждёт `blender` в PATH и conda. Системный Blender не
подходит (нет зависимостей проекта). Шим, запускающий скрипт в venv через pip-`bpy`:
```bash
mkdir -p ../shim && cat > ../shim/blender <<'EOF'
#!/bin/sh
script=""
while [ $# -gt 0 ]; do
  case "$1" in
    -b) shift ;;
    --python-exit-code) shift 2 ;;
    -P) script="$2"; shift 2 ;;
    --) shift; break ;;
    *) shift ;;
  esac
done
exec "$(dirname "$0")/../venv/bin/python" "$script" -- "$@"
EOF
chmod +x ../shim/blender
PATH=$PWD/../shim:$PWD/../venv/bin:$PATH SKIP_INVALID=1 bash scripts/run_animate_motion.sh outputs/samples/cat
PATH=$PWD/../shim:$PWD/../venv/bin:$PATH SKIP_INVALID=1 bash scripts/run_animate_motion.sh outputs/samples/cat2
```
Результат: `outputs/samples/cat/animated/*.glb` и `outputs/samples/cat2/animated/*.glb`.

### 5.6 Оценка и выбор
Отрендерить 4 кадра каждого клипа (камера сбоку-спереди, EEVEE) и посмотреть на листы кадров;
для прыжка дополнительно посчитать высоту корневой кости по кадрам (`arm.matrix_world @
pose.bones["Bone"].head`). В оригинальном прогоне выбран `rep_1` прыжка: присед (0,46) → подъём
до 0,74 с отрывом лап; `rep_0` почти без отрыва. hide — низкий присед; hit — отшатывание, во
второй половине кот валится на бок (в игре играет первая секунда); run — галоп с перемещением
корня (в `cat.py` каналы положения корня у `run` удаляются).

### 5.7 Вендоринг в проект
```bash
mkdir -p third_party/unimate_clips
cp UniMate/outputs/rig/cat/cat.glb third_party/unimate_clips/cat_canonical.glb
cp UniMate/outputs/rig/cat/annotation.json third_party/unimate_clips/annotation.json
cp "UniMate/outputs/samples/cat/animated/cat-an_object_jumps_in_place-rep_1-0.glb" third_party/unimate_clips/jump.glb
cp "UniMate/outputs/samples/cat2/animated/cat-an_object_crouches_down_low_and_stays_still-rep_0-0.glb" third_party/unimate_clips/hide.glb
cp "UniMate/outputs/samples/cat2/animated/cat-an_object_flinches_backward_as_if_hit-rep_0-1.glb" third_party/unimate_clips/hit.glb
cp "UniMate/outputs/samples/cat2/animated/cat-an_object_runs_forward-rep_0-2.glb" third_party/unimate_clips/run.glb
```
Создать `third_party/unimate_clips/README.md`, заметку `docs/superpowers/notes/2026-10-07-unimate-attempt.md`.

### 5.8 Сборка кота с клипами
Итоговый `tools/blender/cat.py` (приложение): импортирует канонический glb, копирует actions
`Idle`/`Walking` из `Cat.blend` по именам костей (переименовывая `Bone.003` → `head`, выбрасывая
каналы IK-костей), импортирует каждый клип UniMate и забирает его action, у `run` удаляет
каналы положения корня, перекрашивает палитрой, разворачивает мордой по −Z Godot, масштабирует
до 0,35 м, экспортирует 6 клипов. Исходные idle/walk через пайплайн UniMate не прогоняются
(idle отфильтровывается как статичный, формат экспортного npz не совпадает с аниматором).

`make assets ONLY=cat && make import && make test-godot` → все тесты `test_cat_asset.gd` зелёные.
Коммит.

Если UniMate по какой-то причине не заработал: запасной путь из плана 1, задача 5
(`tools/blender/cat_anims.py`, процедурные клипы), но при воспроизведении он не понадобился.

## Шаг 6. Логика движения кота и InputMap

Создать `tests/unit/test_cat_motion.gd` → падает. Создать `scripts/player/cat_motion.gd`,
полный `scripts/autoload/input_setup.gd`. `make import && make test-godot` → зелёный.
Коммит «Логика движения кота с тестами, InputMap в коде».

## Шаг 7. Сцена кота, голова, камера

Создать `tests/integration/test_cat_scene.gd` → падает (`нет сцены cat.tscn`). Создать
`scripts/player/head_scaler.gd`, `scripts/player/camera_rig.gd`, `scripts/player/cat.gd`,
`scenes/player/cat.tscn`, `scenes/player/camera_rig.tscn`. `make import && make test-godot`.

Грабли: масштаб головы читается только внутри сигнала `skeleton_updated` через
`get_bone_global_pose` (Skeleton3D восстанавливает базовую позу после модификаторов); клипы из
glb приходят без зацикливания, лупы ставит `cat.gd._ready()`; обводка `grow` считается в
пространстве модели, поэтому `Toon.apply` делит ширину на масштаб узла.

Коммит «Сцена кота с анимациями и чиби-головой, камера от третьего лица».

## Шаг 8. Двор-заглушка и главная сцена

Создать `tools/blender/gen/ground.py`, `tools/blender/gen/bin.py`, `make assets` (4 glb).
Создать `tests/integration/test_main.gd` → падает. Создать `scenes/world/district_yard.tscn`,
`scripts/main.gd`, итоговый `scenes/main.tscn`.

Контрольные точки:
```bash
make import && make test-godot        # 29 passed
make shot SHOT=build/task8.png        # кот стоит на тротуаре в idle, баки и коробки, тени
rm -rf .godot && make test            # зелёный с нуля: Ran 8 tests OK + Passing Tests 29
rm -rf .godot && make shot            # импорт выполняется сам (цель shot зависит от import)
```
Коммит «Двор-заглушка, главная сцена: кот, камера, свет».

## Шаг 9. Независимое ревью и исправления

Ревью всей ветки свежим агентом (шаблон `code-reviewer.md` из superpowers). Находки, которые
были исправлены (в приложении код уже исправленный):
1. Критично: клипы не зациклены, кот застывал через 1,7 с (`LOOPING_CLIPS` в `cat.gd`, тесты
   `test_locomotion_clips_loop`, `test_cat_keeps_animating_longer_than_one_clip`).
2. Обводка в единицах модели (`Toon._world_scale`, тест `test_outline_width_is_in_meters_under_scaled_parent`).
3. Капсула коллизии тонула и не вращалась → сфера r=0,09 на y=0,09; тротуар заподлицо; спавн y=0,05.
4. `make run`/`make shot` без импорта → цели зависят от `import`; `SHELL := /bin/bash`; `*.import`/`*.uid` в git.
5. Скриншот ловил кота в падении → `dev_tools` ждёт 40 кадров.
Спек поправлен: камера 1,8 м/−14°, свет 1,0/0,45, обводка 0,006 м.

Отложенные мелочи перечислены в конце дорожной карты.

## Шаг 10. Завершение

`make test` зелёный → `git checkout main && git merge --ff-only plan-1-foundation` → `make test`
на main → `git branch -d plan-1-foundation`. Создать `CLAUDE.md` (приложение) и эту папку
`docs/replay/` (`make replay`). Коммит.

---

# План 2. Игровой цикл (выполнен 2026-10-08)

План: `docs/superpowers/plans/2026-10-08-snack-run-02-gameplay.md` (15 задач, код каждого шага внутри).
Ветка `plan-2-gameplay` от `main`, тот же порядок: RED-тест → код → GREEN → коммит → `task-done`.
Все файлы — в приложении `03-files.md`. Ниже только то, что отличалось от плана, и контрольные точки.

## Задачи 1–3: данные и состояние

- `scripts/core/layers.gd`, `scripts/core/rarity.gd`, `scripts/food/food_def.gd`, `scripts/food/food_catalog.gd`,
  8 ресурсов `data/food/*.tres` (сгенерированы одним Python-циклом из таблицы id/название/редкость/сладкое).
- `make import && make test-godot` → 34 теста. В тестах на экземпляре `GameState` (тип `Node`) писать
  `var eaten: Array = gs.eat_all()`: вывод типа из динамического вызова невозможен.
- `scripts/autoload/game_state.gd` + строка `GameState="*res://scripts/autoload/game_state.gd"` в
  `[autoload]` `project.godot` → 43 теста.

## Задача 2: примитивы и еда

- В `tools/blender/lib.py` добавлены `_finish`, `cylinder`, `cone`, `sphere`, `torus`, `wedge`, `group`;
  тесты `TestPrimitives` → `Ran 12 tests OK`.
- 8 генераторов `tools/blender/gen/food_*.py`. Лимиты: печенье — точки-сферы `segments=6, rings=4`,
  круассан — скосы `segments=2`, пончик — `max_tris` 600 (два тора по 256). `make assets` → 8 `ОК food_*`.
- Контрольная точка: лист кадров всех восьми (Blender, камера `(1.22, -1.9, 1.3)`, lens 24).

## Задача 4: еда на земле

- `scripts/food/food_pickup.gd` + `scenes/food/food_pickup.tscn`, `scripts/food/food_spawn_point.gd` + `.tscn`;
  в `cat.gd` `_ready` добавлены группа `cat` и слои. → 48 тестов.
- Грабли: GUT 9.7 считает ошибки движка провалом теста; dummy-рендерер пишет «Parameter material is null»,
  когда узлы с материалами освобождаются внутри физического кадра (после `wait_physics_frames`). Решение:
  в `.gutconfig.json` `"failure_error_types": ["gut", "push_error"]` (без `engine`). Ошибки скриптов
  по-прежнему валят прогон через grep `SCRIPT ERROR` в Makefile.

## Задачи 5–7: укрытия, удар, HUD

- `scripts/hideouts/hideout.gd` (+`.tscn`), полная новая версия `scripts/player/cat.gd`, `camera_rig.gd` с
  `crouch`. Доступ к полям кота из `Hideout`/опасностей только через `set/get/call` — у типизированного
  `Node3D` GDScript не даёт обратиться к несуществующему свойству. → 52 теста.
- `scripts/world/spill_spawner.gd`, новая версия `scripts/main.gd` (затемнение, возрождение) → 56.
- `scripts/ui/hud.gd` + `scenes/ui/hud.tscn`, инстанс `Hud` в `main.tscn`, `@onready var hud` в `main.gd`.
  Полоска сытости клампится на `SATIETY_GATE` (10), тест ждёт 10, а не 15. → 60.

## Задача 8: двор из JSON

- `scripts/world/world_builder.gd`, `data/layout/yard.json`, новая версия `scenes/world/district_yard.tscn`
  (только Ground/Floor/WorldBuilder/Spawn). → 62 теста. Предупреждения «опасность пропущена: dog/wasp/cyclist»
  до задач 10–12 нормальны.
- Тротуар поднят на +5 мм (`gen/ground.py`, `z=-0.055`): заподлицо с асфальтом был z-fighting.

## Задачи 9–10: мозг и собака

- `scripts/hazards/perception.gd`, `chase_brain.gd` → 71 тест.
- `tools/blender/rig_utils.py`, `tools/blender/dog.py`, `gen/dog.py`; `cat.py` теперь зовёт
  `rig_utils.face_forward`. `make assets ONLY=dog && make assets ONLY=cat`.
- **Две грабли Dog.blend:** (1) меш повёрнут относительно арматуры и имеет `matrix_parent_inverse`,
  а арматура — масштаб 1,215 и смещение: без запекания трансформации меша в вершины и сброса
  `arm.matrix_world` в единичную экспортёр терял масштаб; (2) action `Idle` содержит каналы самого
  объекта (location/rotation/scale=1,215), Godot применял их к узлу `DogRig` и собака становилась в
  13 раз больше. `rig_utils.clean_action` теперь выкидывает все не-костные каналы.
  Проверка: скриншот отдельной сцены с `dog.tscn` у начала координат, камера в 1,6 м.
- `scripts/hazards/hazard_base.gd` (`_ensure_home` на первом физическом кадре: WorldBuilder ставит
  позицию после `add_child`), `dog.gd`, `scenes/hazards/dog.tscn` → 76 тестов.

## Задачи 11–13: оса, велосипедист, пропсы

- `gen/wasp.py`, `scripts/hazards/wasp.gd` (якорь берётся на первом физическом кадре), `wasp.tscn` → 78.
  В тестах `var first: Vector3 = w.global_position` (тот же вывод типа).
- `gen/cyclist.py` (лимит 1800: два тора колёс), `cyclist.gd`, `cyclist.tscn`, в `main.gd` подписка
  сигнала `bell` всех опасностей на `hud.flash_bell()`. В тесте велосипедиста нужен пол, иначе кот
  проваливается под дорогу раньше проезда. → 80.
- 12 генераторов пропсов; забор и лестница — скосы `segments=1`, столбики без скоса (иначе > 800).
  Итоговый `data/layout/yard.json` (38 пропсов, 8 укрытий, 10 точек спавна, 3 опасности, дорога).
  Контрольные точки: `make shot` (дома, лавка, лужа, лестница, собака нормального размера) и общий план
  сверху (камера `(2, 14, 22)` → `(0, 0, -3)`).

## Задача 14: UniMate для собаки — отказ

Процедура как в шаге 5 плана 1 (окружение `uv`, чекпоинт, `rig_preprocess` с разметкой кота, где
`asset` → `dog`). Четыре промпта × 2 варианта не дали позы «лежит» (корень ≥72% от стойки, лапы под
полом), `alert` = стойка. Собака спит в idle. Подробности в
`docs/superpowers/notes/2026-10-07-unimate-attempt.md`.

## Задача 15: эта документация, `make replay`, дорожная карта, `CLAUDE.md`.

Итог плана 2 до ревью: 12 Blender-тестов и 80 GUT-тестов; после правок ревью — 88.

## Ревью плана 2 и исправления

Независимый ревьюер нашёл 2 критичных и 6 важных дефектов, все закрыты через падающие тесты
(коммит «Правки по ревью плана 2»): лестница строилась зеркально своим коллайдерам (ступени в
`gen/stairs.py` теперь идут по −Y Blender = +Z Godot, `rot: 0` в раскладке), hit-зона осы висела
выше стоящего кота (сфера r 0,35 на y −0,25), собака после погони не возвращала направление
взгляда (`home_yaw` в `HazardBase`), велосипедист и оса двигались задом (перёд модели = +Y Blender,
`rotation.y = PI - _angle` у осы), дерево и арка получали сплошной коллайдер по AABB (явные
`colliders` в `yard.json`), укрытия-коробки стояли внутри коллайдера коробки (сдвинуты на 0,65 м
«за коробку»), рассыпанная еда под стоящим котом не подбиралась после паузы (проверка
`get_overlapping_bodies` по её концу), после возрождения кот был уязвим (2 с неуязвимости, сброс
`brain` опасностей). В `test_world_builder.gd` добавлены инварианты раскладки: точка спавна с
y > 0,5 стоит на пропсе, точки спавна и укрытия не внутри коллайдеров, проём арки и бока дерева
проходимы; в тестах осы и велосипедиста — проверка «перёд модели совпадает с направлением движения».
Makefile дополнительно валит прогон на любой `^ERROR:` движка, кроме известной строки
dummy-рендерера. Итог: 12 Blender + 88 GUT тестов.

---

# План 3. Хаб и прогрессия (выполнен 2026-10-08)

План: `docs/superpowers/plans/2026-10-08-snack-run-03-hub.md` (10 задач). Ветка `plan-3-hub`.
Файлы — в приложении `03-files.md`. Ниже контрольные точки и то, что отличалось от плана.

## Задачи 1–3: клубочки, товары, улучшения

- `GameState`: `yarn`, `add_yarn/spend_yarn`, +3 за новую карточку; `YarnPickup` + `gen/yarn.py`
  (`max_dim` 0,25: тор с наклоном даёт ровно 0,2); `WorldBuilder` читает `"yarn"`; HUD «◎ N». → 91 тест.
- `ShopItem`/`ShopCatalog`, 10 `.tres` в `data/shop` (сгенерированы циклом), `GameState.can_buy/buy/owns/
  select_skin/owned_skins`, `_apply_upgrades` пересчитывает max_hearts/mouth/speed/stealth из купленного. → 99.
- `CatMotion.step/pick_state` с `speed_mult`; `CatSkin` + `SkinCatalog` + 4 `.tres` в `data/skins`;
  `Toon._apply_to_mesh` копирует `resource_name` в дубликат материала (скины узнают поверхности по имени);
  `Dog.sees_cat` умножает конус на `GameState.stealth_mult`. Цвета в тестах сравнивать через `to_html()`:
  `Color` из `.tres` (6 знаков) не равен `Color("#hex")` побитно. → 104.

## Задача 4: сохранение

- `scripts/autoload/save_game.gd` (автозагрузка `SaveGame` после `GameState` в `project.godot`),
  `GameState.to_dict/from_dict` (терпит мусор в файле), `Main`: `SaveGame.load_now()` до создания кота,
  автосохранение по сигналам прогресса через `Callable.unbind(1)`, сохранение при закрытии окна.
- Грабли: `JSON.parse_string` печатает `ERROR` движка на повреждённом файле, и Makefile валит прогон —
  разбирать через `JSON.new().parse()`. Тесты с `Main` ставят `SaveGame.path = "user://test_save.json"`
  в `before_each` и `clear()` в `after_each`. → 109.

## Задача 5: ворота

- `scripts/world/gate.gd` (StaticBody3D, прутья BoxMesh, `refresh(satiety)`), `WorldBuilder` читает `"gates"`,
  в `yard.json` ворота в проёме арки (0, 0, 10.5), HUD `SatietyLabel` («Сытость N/10» / «Кафе открыто»),
  `Main` подписывает `opened` на вспышку. Тест проёма арки теперь ждёт `gate_0`, а после сытости 10 — пусто. → 111.

## Задача 6: будка пряжи

- `gen/yarn_shop.py` (открытый перёд по +Y Blender = −Z Godot; плита пола 3 см без коллайдера),
  `scenes/world/yarn_shop.tscn` (стенки-коллайдеры, `Zone`, `Respawn`, `ViewPoint`, `YarnPlay`),
  `scripts/world/yarn_shop.gd`; `WorldBuilder` читает `"shop"`; в раскладке будка (−4.5, 0, −1.5) `rot 180`
  входом к спавну. `Cat.in_safe_zone` (удары не проходят), `Cat.input_enabled`; `Dog` считает кота в зоне
  спрятанным; `CameraRig.shop_view`; `Main.respawn_position()` берёт маркер будки. → 117.

## Задачи 7–8: экраны

- `scripts/ui/shop_menu.gd` + `.tscn`, `scripts/ui/menu_input.gd` (узел с `PROCESS_MODE_ALWAYS`, опрашивает
  `eat`/`album`/`pause` через `Input.is_action_just_pressed`: события от `Input.action_press` в тестах не
  приходят в `_unhandled_input`, а `Main` на паузе замирает). `Main.open_shop/close_shop`,
  `on_interact_pressed/on_back_pressed/on_album_pressed`. Камера-витрина едет в `YarnShop.view_position()`
  (точка у входа, поворачивается с будкой); мировое смещение упиралось в стенку. → 120.
- `album_menu.gd` (карточка — `VBoxContainer` с прямыми детьми `Rarity/Name/Count`), `pause_menu.gd`,
  `title.gd` + `title.tscn` — главная сцена; `Makefile` `shot` передаёт `res://scenes/main.tscn` явно;
  действия `album` (Tab/Y) и `pause` (Esc/Start); таймеры велосипедиста и спавна — `create_timer(t, false)`.
- Грабли паузы: ожидания GUT (`wait_seconds`) сами стоят на паузе — прогон зависает; в тесте паузы ждать
  `get_tree().create_timer(t, true).timeout`. После `reset_progress()` автосохранение сразу пишет чистое
  состояние — тест принимает «файла нет или yarn=0». → 124.

## Задача 9: кафе

- `gen/cafe_table.py`, `chair.py`, `umbrella.py`, `cafe_sign.py`; раскладка: стены z=28, вывеска, 5 столов
  с коллайдерами столешниц, 8 стульев, 3 зонта (рядом со столами, не в центре — стойка попала бы в коллайдер
  и под точку спавна), баки, кусты, лужа; еда на столах (y 0,75), вторая оса на высоте 1,1 над десертным
  столом (`Wasp.configure` читает `height`); два клубочка на столах. Итог: 61 пропс, 16 точек спавна,
  4 опасности, 12 клубочков. → 124 теста, все инварианты раскладки проходят.

## Задача 10: документация, `make replay`, дорожная карта, `CLAUDE.md`.

## Ревью плана 3 и исправления

Ревьюер (критичных нет, 6 важных) — все закрыты через падающие тесты, коммит «Правки по ревью плана 3»:
собранные клубочки возвращались после перезапуска (`GameState.yarn_taken` + ключ позиции у `YarnPickup`,
`Main` удаляет собранные после `SaveGame.load_now()`); HUD строил только 3 слота зубов (теперь 5, видимость по
`mouth_capacity`, HBox шире); вторая оса на h 1,1/r 1,2 никого не доставала (теперь h 1,0/r 0,8: край стола
опасен); в витрине кот мог остаться невидимым после упора камеры в стену (`target.visible = true` в режиме
`shop_view`); E на паузе открывал магазин поверх паузы (`not get_tree().paused`); купленные скины нельзя было
переодеть (кнопка купленного скина — «надеть»/«✓ надет», `select_skin` бесплатно). Итог: 131 GUT-тест.

---

## План 4. Полировка под ролик (`docs/superpowers/plans/2026-10-08-snack-run-04-polish.md`)

Ветка `plan-4-polish` от `main`. План с полным кодом лежит в приложении; ниже — что сделано на самом
деле и где план пришлось поправить (все такие места записаны как `Ruling:` в журнале и в коде комментариями).
Числа тестов в контрольных точках — `func test_` в `tests/` на коммите задачи (`git grep -h '^func test_' <коммит> -- tests | wc -l`).
Одиночный прогон GUT: `GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gselect=test_theme`
(флаг `-gselect=<подстрока имени файла>`; `-gtest=` не фильтрует).

## Задача 1: тема UI, HUD, заставка

1. Шрифт: `curl -sL -o assets/fonts/Nunito.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf"`
   и `OFL.txt` оттуда же (277 КБ, SIL OFL). Создать `assets/ui/theme.tres`, добавить в `project.godot` секцию
   `[gui] theme/custom="res://assets/ui/theme.tres"`, `scripts/core/mouse.gd`, тест `tests/unit/test_theme.gd`.
2. `scenes/ui/hud.tscn` переписан: плашка `Status` (сердечки, полоска сытости с подписью, клубочки), `Mouth`,
   `GoalPanel/Goal`, `BellPanel/Bell`; узлы с `unique_name_in_owner`, в `hud.gd` ссылки `%Имя`. Тесты HUD ходят
   через `hud.get_node("%Satiety")` и `%BellPanel`.
3. `scenes/ui/title.tscn`: кнопка `Continue` («Продолжить», видна при наличии сохранения), `Play` → «Новая игра».
   `title.gd`: `switch_scenes` (тесты ставят `false`), `has_save/new_game/continue_game`. В `new_game` сначала
   `GameState.reset()`, потом `SaveGame.clear()`: рядом с `Main` сигналы `reset()` вызывают автосохранение.
4. Контрольная точка: `make test-godot` зелёный (133), `make shot SHOT=build/shot_ui.png` — белые округлые плашки,
   Nunito, графитовый текст. Коммит «UI: тема Nunito…».

## Задача 2: глаза и выражения

1. `tools/blender/palette.py`: цвет `eye_white` (#F4F1E8) — не из спека, чтобы скины (`sr_cream`) не красили глаза;
   `tools/blender/tests/test_lib.py`: 18 цветов вместо 17.
2. `tools/blender/cat_eyes.py` (bbox вершин головы → центры глаз → четыре набора `eyes_normal/scared/happy/dizzy`,
   слитые в один меш каждый, скин к кости `head` весом 1, armature-модификатор); `cat.py` возвращает `[arm, mesh] + eyes`.
   Тест `tools/blender/tests/test_cat_eyes.py` (4 теста, включая «чеврон „^“, а не „v“»). `make assets ONLY=cat` → 1607 tri.
3. Godot: `scripts/player/cat_face.gd` (`bind/threaten/cheer/update`, приоритет оглушён > испуг > довольный),
   в `cat.gd` поле `face`, обводка у `eyes_*` снимается (`material_overlay = null`), `face.update` первой строкой
   `_physics_process`, `cheer()` в `try_eat`, методы `threaten/cheer`. `dog.gd` зовёт `cat.threaten()` в ALERT/CHASE,
   только если собака ближе `VISION_RANGE` (6 м) — иначе испуг не гаснет, пока собака гонится вдали.
4. Проверка анфас: служебный скрипт `-s` с `cat.glb` (без автозагрузок, иначе `cat.gd` не компилируется),
   камере задавать `transform` (в `_init()` `global_position`/`look_at` не применяются). По кадру белок обычных
   глаз уменьшен с 16 до 14 мм.
5. Контрольная точка: `make test-blender` → `Ran 16 tests OK`; `make test-godot` зелёный (137). Коммит «Кот: четыре набора глаз…».

## Задача 3: частицы

`scripts/visual/effects.gd` (`Effects.burst`, `CPUParticles3D`, группа `fx`, самоудаление по `finished`);
`Main._on_food_eaten` (цвет редкости лучшей еды), `_on_cat_hit` (золотые звёзды), `YarnPickup` (сиреневый + `cat.cheer()`).
Тесты `tests/integration/test_effects.gd` и два в `test_main.gd`. Контрольная точка: 140 GUT. Коммит «Частицы…».

## Задача 4: звук

1. Kenney: страница `https://kenney.nl/assets/<slug>` содержит ссылку на zip (`grep -oE 'https://kenney\.nl/media/pages/assets/[^"]*\.zip'`).
   Паки `impact-sounds` и `interface-sounds`, файлы в `Audio/`: `pluck_001.ogg` → `pickup.ogg`, `drop_002.ogg` → `eat.ogg`,
   `impactPunch_medium_000.ogg` → `hit.ogg`, `impactBell_heavy_000.ogg` → `bell.ogg`; `License.txt` → `assets/sfx/LICENSE_kenney.txt`.
2. `tools/audio/gen_sfx.py` (stdlib: `wave`, синтез писка 900→520 Гц и лая 190→120 Гц) и цель `make sfx` → `meow.wav`, `bark.wav`.
   `assets/sfx/README.md` с таблицей источников.
3. `scripts/autoload/sfx.gd` (автозагрузка `Sfx` после `SaveGame`): пул из 6 `AudioStreamPlayer`, `play(name, pitch_jitter)`,
   `has`, `counts`, `reset_counters`. Подключения по событиям: `Cat.take_hit` (hit + meow, после проверки неуязвимости),
   `Main._on_food_eaten` (eat), звонок велосипедиста (bell), `FoodPickup`/`YarnPickup` (pickup), `Dog` при переходе в ALERT (bark).
4. Тесты: `tests/unit/test_sfx.gd`, в `test_dog.gd` «один удар — один звук», в `test_main.gd` «eat». Headless-аудио (Dummy)
   ошибок не даёт. Контрольная точка: 144 GUT. Коммит «Звук: шесть эффектов…».

## Задача 5: камера, прозрачность, виньетка

`camera_rig.gd`: `_unhandled_input` (мышь при `MOUSE_MODE_CAPTURED`), `turn_by_pixels`, `apply_arm_length` → `set_fade`
(альфа от длины пружины: 0,15 при ≤ 0,3 м, 1 при ≥ 0,9 м), витрина ставит `fade = 1`. `cat.gd`: `fade`, `set_fade`,
`_apply_fade` (альфа + `TRANSPARENCY_ALPHA` на всех материалах и обводке), скин после перекраски восстанавливает `fade`.
`assets/shaders/vignette.gdshader` + `Vignette/Rect` в `main.tscn` (CanvasLayer 0, `mouse_filter = 2`). `Main`: `Mouse.capture(true)`
в `_ready`, `false` при паузе/магазине. Тесты в `test_cat_scene.gd` (прозрачность, скин + прозрачность, мышь) и `test_main.gd` (виньетка).
Проверка виньетки по пикселям: угол 230→189, центр не тронут. Контрольная точка: 147 GUT. Коммит «Камера…».

## Задача 6: собака спит, будка

1. `tools/blender/dog_sleep.py`: `reset_pose`, `apply_pose` (корпус вниз на 62 % высоты над лапами через `location` корня в
   локальных осях кости, лапы `scale.y = 0,45`, цели IK подняты на 25 % просадки, голова на 0,75 рад — знак выбирается по
   результату), `make_sleep_action` (кадры 1/24/48, на 24-м вдох). **Поза ставится при снятом action**, иначе
   `view_layer.update()` перезаписывает кости уже записанными кадрами и клип статичный. `dog.py` зовёт
   `make_sleep_action(arm)` после `clean_action`. Тест `test_dog_sleep.py` (4 теста). `make assets ONLY=dog` → клипы idle/sleep/walk.
2. `chase_brain.gd`: `update(..., cat_safe := false)` — в CHASE при `cat_safe` сразу RETURN, в ALERT — IDLE. `dog.gd` передаёт
   `in_safe_zone` кота. `yarn_shop.tscn`: `Walls/Floor` (2,2 × 0,03 × 2,2 на y 0,015).
3. Тесты: `test_chase_brain.gd`, `test_dog.gd` (RETURN за 3 кадра, idle играет `sleep`), `test_dog_asset.gd` (sleep ≈ 2 с),
   `test_yarn_shop.gd` (луч упирается в плиту на 0,03). Контрольная точка: `Ran 20 tests OK`, 151 GUT. Коммит «Собака…».

## Задача 7: дыры мира

`Main.KILL_Y = -5`, `_physics_process` → `fall_respawn()` (еда из зубов теряется, сердечки не трогаются, телепорт к будке);
`_on_cat_hit` не рассыпает еду при `hearts == 0`; `reset_progress` выключает `autosave` на время `GameState.reset()`, потом
`SaveGame.clear()`; `SpillSpawner` кладёт еду на `pos.y`; `MenuInput` закрывает магазин/альбом по `ui_cancel` (B геймпада).
Тесты в `test_main.gd` (3), `test_hit.gd` (1), `test_menus.gd` (сброс без файла, `ui_cancel`). Контрольная точка: 156 GUT.

## Задача 8: баланс

`tests/unit/test_balance.gd` — жадный маршрут по точкам спавна двора (z < 10,5), 2 м/с, 0,6 с на подбор, после каждых
трёх — к ближайшему укрытию и 2 с. Оценка: **32 с при пороге 10** (< 180 с), порог не меняется. Контрольная точка: 158 GUT.

## Задача 9: экспорт mac-билда

`make templates` (скрипт `tools/release/fetch_templates.sh` качает 1,28 ГБ `Godot_v4.7.2-stable_export_templates.tpz` восемью
параллельными диапазонами — один поток с GitHub шёл 150 КБ/с — и кладёт `macos.zip` и `version.txt`
в `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`),
`export_presets.cfg` (macOS, universal, `codesign/codesign=1` — встроенная ad-hoc подпись без сертификата, нотаризации нет),
`make export` → `build/SnackRun.zip` (62,7 МБ, внутри `Snack Run.app` — имя с пробелом, как `config/name`). Экспорт для universal
требует в `project.godot` строку `textures/vram_compression/import_etc2_astc=true` в `[rendering]` (иначе «Невозможно экспортировать для
Universal или Arm64…»). Проверка запуска: `unzip -q -o build/SnackRun.zip -d build && "build/Snack Run.app/Contents/MacOS/Snack Run" --quit-after 60; echo $?` → 0.

## Задача 10: эта документация, `make replay` (в приложение добавлены `.cfg/.tres/.gdshader/.txt`, `tools/audio`), дорожная карта, `CLAUDE.md`.

## Ревью плана 4 и исправления

Ревьюер (критичных нет, 2 важных, 8 минорных): экспорт был задокументирован до выполнения (шаблоны качались) — выполнен,
см. задачу 9; рассыпанная еда на `pos.y` висела в воздухе вокруг стола кафе и балкона (радиус разлёта 1–2 м больше
столешницы) — `SpillSpawner` кладёт каждую порцию лучом вниз по слою `WORLD` на поверхность под точкой
(`test_spilled_food_lands_on_surface_below`). Минорные отложены в дорожную карту: `reset_progress` ставит `autosave = true`
безусловно; `addons/*` не исключён из pack; `build/` без `.gdignore`; B геймпада не закрывает паузу; оценка баланса —
нижняя граница; «рентген» полупрозрачного кота (depth draw). Итог: 158 GUT-тестов, 20 Blender.

---

## План 5. Визуальная полировка (`docs/superpowers/plans/2026-10-09-snack-run-05-visual.md`)

Ветка `plan-5-visual` от `main`. Спек 2.8 и решения владельца №15–19 (`01-decisions.md`). План с полным кодом — в приложении;
ниже — что сделано на самом деле и где план поправлен (все такие места — `Ruling:` в журнале исполнителя).

## Задача 1: картинки (OpenAI) и их подключение

1. `tools/images/gen.py` (stdlib `urllib`, ключ только из `OPENAI_API_KEY`), `tools/images/manifest.json` (17 картинок:
   8 иконок еды, сердечко, фон заставки, облака, 3 плаката, 3 декали), цель `make images` (генерирует только отсутствующие,
   `FORCE=1` — все; один файл: `python3 tools/images/gen.py --force <путь>`). Модели: `gpt-image-2.5-flare` для иконок (11 с,
   ≈500 токенов), `gpt-image-2.5-sunburst` для крупных. Генерация 17 файлов ≈ 4 мин.
2. `FoodDef.icon_path/icon()`; слоты HUD — `TextureRect "Icon"` 48×48 + скрытый `Label "Name"` (тесты читают текст через
   `find_child("Name", true, false)`); карточки альбома — `TextureRect "Icon"` 96×96, закрытые тёмные (`self_modulate`);
   заставка — `TextureRect "Background"` с `title_bg.png`, под `VBox` соседняя плашка `Panel`, обе смещены вправо
   (`anchor 0.68`), чтобы не закрывать кота на арте; логотип и слоган снова графитовые (на белой плашке белый текст не виден).
3. Тесты: `tests/unit/test_images.gd` (манифест покрывает всю еду, файлы существуют), HUD, альбом, заставка.
   Контрольная точка: 161 GUT. Коммиты «Картинки…», «Заставка: меню справа».

## Задача 2: кот — сглаживание и пучки

1. `tools/blender/cat.py`: `smooth_body(mesh)` — **сначала `bmesh.ops.remove_doubles` (1e-4)**, потом `SUBSURF` уровня 1 первым
   в стеке модификаторов и smooth-шейдинг. Без сварки вершин импортированный glb-меш (разрезан по нормалям/UV) под
   subdivision разъезжается в мозаику. Бюджет `gen/cat.py` 8000 (триангулированный меш ×6, не ×4).
2. `tools/blender/cat_eyes.py`: `group_bbox(mesh, bone)` с откатом порога 0,5 → 0,25 → head/tail кости; `_attach(obj, arm, bone)`.
   `tools/blender/cat_fluff.py`: щёчные кисточки (3 конуса на щёку, назад и вниз), грудка, кончик хвоста (`Bone.007`),
   усы (6 цилиндров 0,8 мм), ошейник (тор у **конца** кости шеи `Bone.002` — её начало у плеч) с жетоном.
   `cat.gd` снимает обводку с `eyes_*`, `whiskers`, `eyelids`.
3. Тесты `test_cat_fluff.py` (5), в `test_cat_eyes.py` словарь наборов только по префиксу `eyes_`. `make assets ONLY=cat` → 6226 tri.
   Кадры анфас/профиль служебным скриптом `-s` (к `cat.glb` добавить `HeadScaler`, `LegScaler`, `TailWiggle` вручную).

## Задача 3: глаза в глазницах, моргание

`palette.py` + `eye_green #6FA04A` (19 цветов); `_eyeball`: белок-эллипсоид (0,55 по оси взгляда) утоплен на 40 %, радужка,
зрачок, блик; набор `blink` (горизонтальная ресница); `CatFace`: `blink_in` 3–5 с, `blink_left` 0,12 с, моргание только
поверх `normal`. **Веки-козырьки убраны**: три варианта (над глазом, у лба, на краю яблока) читались как брови или бруски.
Порог теста «не утоплен» — `hi.y − 0,010` (глаза выше носа). Контрольная точка: 162 GUT, 28 Blender. Кот 6730 tri.

## Задача 4: лапы и хвост

`scripts/player/leg_scaler.gd` (верхние кости лап ×0,8, корень вниз на 20 % высоты от среднего начала верхних костей до стопы —
таз `Bone` выше суставов), `tail_wiggle.gd` (синус ±7°, 2,5 Гц, сдвиг фазы 0,7 по `Bone.004–007`, поворот вокруг локальной Z).
Тесты сравнивают два экземпляра `cat.glb` на одном кадре `idle` через `skeleton_updated`/`get_bone_global_pose`.
Контрольная точка: 164 GUT.

## Задача 5: тун v2

`assets/shaders/outline_fur.gdshader` (cull_front, unshaded, blend_mix, depth_draw_always; шум ширины по `floor(UV·40)`,
`alpha`); `Toon.apply(root, width, character)` — rim 0,5/0,6 и `jitter 0,25` у персонажей, `make_outline(width, jitter)`;
`Cat._apply_fade` ставит `alpha` обводке через `set_shader_parameter`. Контрольная точка: 165 GUT.

## Задача 6: свет

`scenes/world/lighting.tscn`: солнце −65°/30°, 1,2, `light_angular_distance 1,5`, `shadow_blur 1,5`, 4 каскада на 30 м;
`Fill` (−65°/210°, `#9FC4E8`, 0,25, без теней); окружение: `ambient_light_source = 3` (SKY; 1 — DISABLED, 2 — COLOR),
SSAO 0,3/1,5, SSR, glow 0,4/порог 1,2, насыщенность 1,1, tonemap linear; `ProceduralSkyMaterial` с `sky_cover = clouds.png`.
`WorldBuilder._make_water` для пропсов с `"water": true` (лужи помечены в `yard.json` — файл многострочный, поле вставлено
после строки `"model": "puddle",`). Контрольная точка: 170 GUT. Кадр: `build/shot_light.png`.

## Задача 7: VFX

`Effects`: `dust/hearts/sparkles/trail/zzz/leaves` + группы `burst/hearts/dust` для тестов. **Грабля:** одноразовая
`CPUParticles3D`, созданная во время физического шага (удар, приземление), получает `finished` в том же кадре и с
`finished → queue_free` исчезала, не родив частиц — теперь эмиссия включается после `add_child`, удаление по таймеру
`lifetime + 0,3 с` (`_free_later`); это починило и всплески удара плана 4. Кот: `_after_move` (сквош при приземлении/прыжке,
пыль при беге), `squash`, `flash` (белым только три материала скина, потом `_apply_skin`), `take_hit` зовёт `flash` и
`camera_rig.shake`; `CameraRig.shake` смещает `SpringArm3D.position`. Еда ≥ редкая — `Sparkles`; оса — `Trail`;
велосипедист — `Dust` только в пути; собака в IDLE — `zzz` раз в 1,2 с; `Lighting` — `Leaves`. В тесте приземления прыжок
через `Input.action_press("jump")` (внешний `velocity.y` гасится шагом на полу), пыль ищется как новый узел группы `dust`.
Контрольная точка: 179 GUT.

## Задача 8: мир

`gen/grass.py` (40 tri), `gen/ivy.py` (24 tri, квады в плоскости XZ Blender, `max_dim 2.5`); `WorldBuilder`: `"solid": false`
— без коллайдеров и с двусторонними материалами; `"decals"` — `QuadMesh` с текстурой (`ALPHA_SCISSOR`, `CULL_DISABLED`),
плашмя на y+0,01 (`rotation −90° X`) или вертикально (`wall: true`); `yard.json` + 7 кустов, 12 пучков травы, 3 плюща
(верхняя полоса стены y 2,2), 8 декалей (люк, трещины ×2, листья ×2, плакаты ×3 под окнами на y 0,8, лицо на z −13,78).
Куст у западного угла сдвинут (лежал на клубочке — ловит тест инвариантов). Тест рассыпанной еды принимает любую
поверхность под точкой (на стул у кафе тоже можно) и фиксирует `rng.seed`. Контрольная точка: 182 GUT. Кадр: `build/shot_world.png`.

## Задача 9: эта документация, `make replay`, дорожная карта, `CLAUDE.md`.

Порядок коммитов в `main`: план (4ac398e, b410f94) → задачи 1–8 → документация (8bbbead) → правки ревью (c48f430, см. ниже;
`make replay` запускался после них) → fast-forward merge. Три PNG — жёсткие зависимости проекта (`assets/images/ui/heart.png`
через `preload`, `world/clouds.png` и `title/title_bg.png` через `ext_resource` сцен): без них игра не стартует; остальные 14
деградируют мягко (иконки еды → пустой слот).

## Ревью плана 5 и исправления

Ревьюер (1 критичная, 2 важных, 12 минорных). Критичная: `LegScaler` считал и применял просадку по локальной Y скелета,
а у кота она идёт **вдоль тела** (верх скелета — +Z): корень уезжал на 2,4 см назад, стопы поднимались на 2 см, а тест мерил
ту же ось и был зелёным. Исправление: `up_local = (skel.global_transform.basis.inverse() * Vector3.UP).normalized()`,
высоты через `dot(up_local)`, смещение `−up_local * drop`; тест теперь меряет мировые координаты всех четырёх стоп и корня
на клипах idle/walk/run (`test_short_legs_keep_feet_on_the_ground`). Важные: шум обводки считался по UV, которых у мешей из
Blender-скриптов нет (`UV = 0` → ширина ровно −25 %) — хэш по `VERTEX_ID`, при `jitter = 0` шума нет; белки глаз выпирали
сбоку и вперёд относительно локальной поверхности морды — `cat_eyes.local_front/local_halfwidth`, центр глаза по ним,
`SINK 0,5`, `WHITE_R 13 мм`, тест по локальной поверхности с боковым ограничением. Минорные отложены в дорожную карту:
жёсткие зависимости от трёх PNG (`heart.png` через `preload`, `clouds.png`, `title_bg.png`); мипмапы/сжатие PNG;
сквош 1,118/0,93 вместо 1,2/0,85 (объём сохраняется); листья рождаются ниже земли (бокс y 2±3); таймер одноразовых
частиц без учёта `explosiveness`; обводка поверх полупрозрачного кота (depth draw); `mesh == null` в не-solid пропсах;
`gen.py` ловит только `HTTPError`; белый кот при `SkinCatalog.get_by_id == null`; плакаты за кустами, плющ-«конфетти»,
плашка заставки задевает глаз кота, линии моргания висят перед мордой, жетон не виден спереди. Итог: 182 GUT, 28 Blender.

---

## После плана 5: минорные замечания ревью (ветка `polish-minors`, слита в main)

Без плейтеста владельца (его решение). Код: `Effects` — `heart.png` через `load` с розовым фолбэком, таймер одноразовых
частиц `lifetime·(2−explosiveness)+0,3`, листья рождаются из бокса над землёй; `Cat._fade_material` при `fade < 1` ставит
`DEPTH_DRAW_ALWAYS`; `_apply_skin` — фолбэк на `DEFAULT_SKIN`; `WorldBuilder` — защита `mesh == null`; `gen.py` ловит
`URLError`/таймаут/битый ответ. Раскладка: плакат с лапками на западную стену (`rot 90`), плющ и кусты только в пределах
северной стены (x −9…9), кусты не перед плакатами; тест `test_wall_decals_and_ivy_hang_on_real_walls` (на старой раскладке
проваливался: плакат −11 и плющ −10 висели в воздухе). Плющ 26 листьев в два ряда (`max_tris 120`); линии моргания/«^»/«×»
на 4,5 мм от центра глаза; плашка заставки `anchor 0,72`; облака перегенерированы промптом «много мелких облаков».
Контрольная точка: 183 GUT, 28 Blender.

## Текстуры мира и экспорт

В `.import` картинок `assets/images/world/*.png` и `assets/images/ui/heart.png`: `compress/mode=2` (VRAM), `mipmaps/generate=true`
(декали и плакаты под углом не мерцают). Иконки UI остаются без сжатия. `make export` → `build/SnackRun.zip` 71 МБ, запуск
`"build/Snack Run.app/Contents/MacOS/Snack Run" --quit-after 60` → код 0. Подпись коммитов с этого шага — Claude Opus 5.5.

## Разрешение окна и шрифт (замечание владельца 2026-10-09)

Владелец: «разрешение маленькое, тексты мелкие, шрифт будто не применяется к кириллице». Причины: на Retina (масштаб 2)
окно 1280×720 физических пикселей выходило вдвое меньше и интерфейс не масштабировался; вариативный Nunito без явного
веса даёт ExtraLight 200; символов ♥ ♡ ◎ ✓ в Nunito нет — подстановка из системного шрифта. Исправления: в `project.godot`
`window/size/mode=2` (развёрнуто), `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"` (база 1280×720
масштабируется); `assets/ui/nunito_bold.tres` — `FontVariation` с `wght 700`, тема на него, кегль 24; сердечки HUD — иконки
`heart.png` (потерянные блёклые), клубочек — новая иконка `assets/images/ui/yarn.png` (манифест + `make images`); магазин:
«Клубочков: N», цена с иконкой, «куплено»/«надет» вместо ✓. Тесты `test_theme` (вес, кегль, масштабирование, нет чужих
символов), `test_hud` (иконки). `make shot` теперь снимает развёрнутое окно (флаг `--resolution` перекрывается режимом окна).

## План 6. Текстуры крупных поверхностей (`docs/superpowers/plans/2026-10-09-snack-run-06-textures.md`, спек 2.9)

Решение владельца №21 — «гибрид». Ветка `plan-6-textures`. В манифест добавлены три бесшовные текстуры
(`assets/images/textures/asphalt.png`, `paving.png`, `stucco.png`, модель `gpt-image-2.5-sunburst`, промпты «seamless tileable…
straight from above… flat even lighting… edges wrap seamlessly»); бесшовность проверена плиткой 2×2 (`Image.blit_rect` в
скрипте `-s`) — все три тайлятся с первой генерации. `scripts/visual/surface_textures.gd` (`SurfaceTextures.TABLE` «меш →
файл, тайл в метрах», `apply(root)`, `texture_or_null`): по имени меша (`ground`, `sidewalk`, `wall`) ставит текстуру,
белый `albedo_color`, `uv1_triplanar` + `uv1_world_triplanar`, `uv1_scale = 1/тайл`; `Main._ready` зовёт его после
`Toon.apply($DistrictYard)`. Тайлы подобраны по кадру: асфальт 4 м, плитка 1,2 м (при 2 м плитка была крупнее кота), штукатурка
4,5 м. Импорт текстур: `compress/mode=2`, `mipmaps/generate=true`. Тест `tests/integration/test_surface_textures.gd` (3):
нужные текстуры и трипланар у трёх мешей, окна/бак/лужа/коробка плоские, без файла текстуры не ошибка. Контрольная точка: 189 GUT.

## Этап 2: спек и план 7 «Смена суток»

Брейншторм этапа 2 (решения владельца №22–24 в `01-decisions.md`): опасности парка — все четыре (голуби, садовник,
дождеватели, ребёнок); смена суток ≈ 5 мин меняет правила; парк — ворота из кафе при сытости 25. Спек
`docs/superpowers/specs/2026-10-09-snack-run-stage2-park-design.md` (ночной сторож — предложение агента, подтверждено вместе
со спеком). План `docs/superpowers/plans/2026-10-09-snack-run-07-day-cycle.md`, ветка `plan-7-day-cycle`.

- Иконки фазы `assets/images/ui/{sun,sunset,moon}.png` — манифест + `make images`.
- `scripts/world/day_cycle.gd` (`DayCycle`: `CYCLE 300`, `phase_at`, `phase_progress`, `light_at` с ключевыми кадрами
  день/закат/ночь и smoothstep, `lamps_on` [165, 285), `wrap_time`). **Грабля:** статическая функция `wrap` конфликтует со
  встроенной `wrap()` GDScript — вызов `DayCycle.wrap()` падает «Nonexistent function 'wrap' in base 'GDScript'».
- `scripts/world/day_night.gd` (`DayNight`, узел в `lighting.tscn`, группа `day_night`): время, применение света/неба/облаков,
  группы `night_lights` (фонари) и `night_windows` (стёкла стен светятся `#FFD9A0` ночью), сигнал `phase_changed`,
  статические `current_phase/is_night` (без узла — день).
- `WorldBuilder`: каждому `lamp` — `SpotLight3D "NightLight"` (2,45 м вниз, 50°, 6 м); стёкла `wall_glass*` — в `night_windows`.
- `Rarity.NIGHT_WEIGHTS` (40/30/20/10), `pick_weighted(..., weights)`, `FoodSpawnPoint` ночью берёт ночные веса.
- `Dog.sees_cat()` ночью false. HUD: плашка `PhasePanel` справа (иконка + полоска фазы).
- `DevTools`: `++ --phase=<сек>` ставит время и замораживает цикл; `make shot PHASE=220`.
- Тесты: `test_day_cycle.gd` (5), `test_day_night.gd` (7), `test_rarity.gd` (+1). Ночь по кадру притушена: солнце 0,22,
  ambient 0,18. Кадры: `build/shot_phase_165.png`, `build/shot_phase_220.png`.

## Ревью плана 7 и исправления

Ревьюер (0 критичных, 1 важная, 8 минорных). Важная: `DayNight._apply` каждый кадр перезаписывал небо, ambient и материалы
окон (небо — источник ambient и SSR, лишний пересчёт). Теперь свет пишется только при изменении (`light_writes`,
`_last_light`), фонари/окна — при переключении или появлении новых узлов в группах. Минорные исправлены: ночь посреди
погони — `ChaseBrain.give_up()`; свой экземпляр `Environment`/`Sky` на инстанс (`duplicate(true)` в `_ready`); ленивая
привязка HUD к `DayNight`; `--phase=night` понимает слова (`DayCycle.parse_time`), `make shot` без `PHASE` время не трогает.
Отложено: иконки фаз 700–950 КБ (уменьшить до 256 px); ночные веса применяются ко всем точкам, а не только к «тёмным».

## План 8. Район «Парк» (`docs/superpowers/plans/2026-10-09-snack-run-08-park.md`)

Ветка `plan-8-park` (от ветки плана 7). Картинки по манифесту: текстуры `grass.png`, `gravel.png`, иконки 6 вкусняшек.
Blender: `lib.join(name, objs)` (слить объекты в один меш с материалами по граням), `gen/park_ground.py` (меши `lawn` и `path`),
`fountain.py` (вода — меши `fountain_water*`), `slide.py`, `swings.py`, `sandbox.py`, `kiosk.py`, `shed.py`, `flowerbed.py`,
`food_{popcorn,bagel,sandwich,corn,cotton_candy,cupcake}.py`; бюджеты песочницы и клумбы уложены уменьшением сегментов.
Godot: `data/food/*.tres` (+6, каталог 14), `data/layout/park.json` (104 пропса: пол парка с коллайдером 30×32 в (0, 45),
забор по периметру с проёмом x 12, фонтан, площадка, аллея, 8 фонарей, киоск, сторожка, деревья, клумбы, кусты-укрытия
без коллизии, трава; 6 укрытий, 12 точек спавна с `foods`, 12 клубочков, ворота `satiety 25`, `label`), второй
`WorldBuilder` `ParkBuilder` в `district_yard.tscn`; `FoodSpawnPoint.foods` (фильтр еды точки), `Gate.label`,
`WorldBuilder` — частичная зеркальность воды по имени меша; `SurfaceTextures`: `lawn` 2 м, `path` 0,8 м (по кадру);
`GameState.PARK_GATE = 25`, HUD «Сытость n/10» → «До парка n/25» → «Парк открыт»; фонари ярче (4, 7 м), плафоны светятся
ночью. `DevTools`: `++ --at=x,y,z[,yaw°]` ставит кота и поворачивает камеру (`make shot AT=0,0.1,33,180`).
Тесты: `test_park.gd` (8), HUD, старые тесты счёта (14 вкусняшек, 24 клубочка, 14 карточек альбома).
Кадры: `build/shot_park.png`, `build/shot_park_night.png`.

## Ревью плана 8 и исправления

Ревьюер (0 критичных, 2 важных, 10 минорных). Важные: (1) кот запрыгивал на куст (верх 0,78 м, прыжок 0,84 м) и с него
перелетал забор 1,1 м — у всех секций забора парка коллайдер 1,8 м (`test_perimeter_fence_is_too_high_to_jump_from_any_prop`);
(2) без списка `foods` точки двора и кафе раздавали еду парка (каталог 4/4/3/3) — у точек `yard.json` явный `foods` по
редкостям двора (`test_yard_spawns_never_give_park_food`). Минорные исправлены: фильтр еды без пересчёта списка на каждой
итерации и с `push_warning`, если редкость не пересекается со списком; мёртвый код ската горки; `lib.join` не оставляет
сирот. Отложено: квадратный коллайдер круглой чаши фонтана (углы на 0,66 м), сплошной коллайдер песочницы, скат горки без
коллайдера; пол парка через `colliders` у `park_ground`, а не отдельный `ParkFloor` (Ruling: так он в той же раскладке,
что и парк). Модели плана 9 (люди и голубь) легли в ту же ветку до слияния.

## План 9. Опасности парка (`docs/superpowers/plans/2026-10-09-snack-run-09-park-hazards.md`)

Ветка `plan-9-hazards`. Анимации по правилу владельца — из бесплатных CC0-паков, ничего не рисовалось:
- Люди: [Animated Human Low Poly (Quaternius)](https://opengameart.org/content/animated-human-low-poly), архив
  `https://opengameart.org/sites/default/files/Animated%20Human%20by%20%40Quaternius_0.zip` → `third_party/quaternius_animated_human/`
  (`AnimatedHuman.blend`, `ClothedLightSkin2.png`, `LICENSE.txt`, `README.md`). Клипы Idle/Walk/Run/Working → idle/walk/run/work.
- Голубь: [Low poly Pigeon (mujtaba-io)](https://opengameart.org/node/167919), файл `genuinely-my-pigeon-extended-furthur.blend`
  → `third_party/pigeon_mujtaba/pigeon.blend` (+README). Клипы flap-wings/idle → flap/idle.
- `tools/blender/human.py`: перекраска по текстуре-палитре — цвет текстуры под UV каждой грани → класс (кожа, волосы, штаны,
  рубашка) → материал палитры по роли (`ROLES`: садовник зелёный/оливковый, ребёнок жёлтый/голубой 1,1 м, сторож синий/графит);
  **разворот по позе клипа walk** (`forward_vector`): по позе покоя модель в игре смотрела вбок — клипы поворачивают таз.
  `tools/blender/pigeon.py`: корпус `asphalt`, шея `sea_light`, лапы `coral`, длина 0,3 м. Генераторы `gen/{gardener,kid,guard,pigeon,sprinkler}.py`.
  Тест `tools/blender/tests/test_park_people.py` (3).
- Godot: `Sprinkler` (цикл 20 с: 11 стоит, 1 булькает, 8 поливает радиус 2 м; работает и ночью; `Cat.wet` ×0,6 на 4 с,
  повторное намокание продлевает); `PigeonFlock` (5 голубей, `decide()` — кража у идущего кота с едой ближе 1,5 м, разлёт
  от бегущего ближе 2,5 м, перерыв 10 с, ночью стаи нет; `GameState.steal_last()`); `ParkPerson` (база людей: модель,
  маршрут `path`, присутствие по фазе); `Gardener` (каждые 15–25 с шипит 1 с и поливает 4 с конусом 3 м / 40°, касание
  не ранит, ночью спит); `Kid` (конус 50° / 7 м, 1,1× шага кота, `ChaseBrain` с `alert_time 0,4` и `chase_max 6`; поймал —
  `Cat.pet(2)`: стоит довольный, еда выпадает через `GameState.cat_petted` → `Main` рассыпает, сердечко цело, потом
  неуязвимость; вечером и ночью дома); `Guard` (только ночью, патруль, фонарик-`SpotLight3D`, видит в луче 30° / 8 м или
  кота под горящим фонарём ближе 14 м, погоня как у собаки). `ChaseBrain.alert_time/chase_max` стали полями.
- Звуки синтезом (`make sfx`): `hiss.wav`, `sprinkle.wav`, `coo.wav`. Расстановка: `hazards` в `park.json` (2 стаи, садовник
  с маршрутом, 3 дождевателя со сдвигом фаз, ребёнок у площадки, сторож с маршрутом по аллеям).
- Тесты: `test_sprinkler*.gd`, `test_pigeon*.gd`, `test_park_people.gd` (8), `test_park.gd` (+опасности), `test_game_state.gd`.
  Кадры: `build/people.png`, `build/shot_park_hazards.png`, `build/shot_park_guard.png`.

## Ревью плана 9 и исправления

Ревьюер (0 критичных, 3 важных, 9 минорных). Исправлено: отсутствующие люди (сторож днём, ребёнок вечером и ночью, садовник
ночью) были невидимыми стенами — `ParkPerson.sync_presence` снимает `collision_layer` (`test_absent_people_are_not_invisible_walls`);
недостающие тесты по Review Focus (касание сторожа днём, ребёнка ночью, спрятавшийся кот у стаи, кража после перерыва,
продление намокания); `teleport` сушит кота и снимает «гладит»; садовник ночью не шипит; мёртвая строка в `Cat.pet`;
`LICENSE.txt` у голубя. Rulings: голуби крадут у кота, который **не бежит** (стоит или идёт) — спек «идёт шагом» прочитан
как «не бегом», иначе стоящий у стаи кот был бы неуязвим; сторож видит кота «под фонарём» в радиусе 14 м без учёта
направления, ребёнок настораживается за 0,4 с — чисел в спеке нет. Отложено: луч сторожа и струя садовника без проверки
видимости (через забор; сторож может погнаться за котом во дворе при открытых воротах); капли перед поливом; голуби
улетают по прямой и телепортируются назад; расписание садовника не вынесено в статическую функцию.

## Масштаб ×3 и рельеф: спек (`docs/superpowers/specs/2026-10-09-snack-run-scale-terrain-design.md`)

Замечание владельца: «все раунды плоские и довольно мелкие». Решения: районы ×3 по стороне (двор 180×180, парк 90×96,
порт 120×102); рельеф всех трёх типов (террасы и лестницы, плавные холмы, крыши); порядок — сначала двор и парк, потом
порт. Планы 10 (рельеф), 11 (генератор раскладки + двор ×3), 12 (парк ×3); порт сдвинут в планы 13–15.

## План 10. Рельеф (`docs/superpowers/plans/2026-10-09-snack-run-10-terrain.md`)

Ветка `plan-10-terrain`.
- `tools/terrain/terrain_gen.py` (stdlib): описание `data/terrain_src/*.json` (размер, начало, базовая высота, `features`:
  `hill` — купол cos², `basin`, `terrace` — плато через max, `flat`; `paint` — прямоугольник или круг с мягким краем) →
  `data/terrain/*.json` (сетка высот с шагом 1 м и RGBA-карта покрытий в base64). `make terrain`, тесты `make test-tools` (6).
- `scripts/world/terrain.gd` (`Terrain`): тайлы меша 30×30 м (SurfaceTool), коллизия `HeightMapShape3D` (тело `Floor`, слой WORLD,
  центр в середине сетки), `ShaderMaterial` `assets/shaders/terrain.gdshader` (тун, 4 канала текстур, камень `stone.png` на
  крутых гранях). `height_at` повторяет триангуляцию меша и коллизии; `Terrain.surface_height(tree, x, z, fallback)`.
- `WorldBuilder`: `terrain_path`; `_place(item)` — y из раскладки становится смещением над рельефом, `"snap": false` — абсолютная
  высота; `kit_colliders` — наклонные коллайдеры лестниц и пандусов; `"rot"` у коллайдеров; **все тела ставятся в позицию до
  `add_child`** (`_add_at`). Ключ клубочка — по позиции из раскладки (правка рельефа не ломает сохранения).
- Набор террас `tools/blender/terrace_kit.py`: `retaining_wall{1,2,3}`, `terrace_stairs{1,2,3}`, `ramp{1,2,3}` (`gen/*.py`).
  Демо `scenes/dev/terrain_demo.tscn` (`data/layout/terrain_demo.json`), кадр `build/shot_terrain.png`.
- Двор и парк переведены на плоский рельеф (`data/terrain_src/yard.json`, `park.json`): `ground.glb`, коробка `Floor` и
  `park_ground` убраны из сцены. Тест `test_terrain.gd` (12): луч против `height_at`, склон без скольжения, подъём по пандусу и
  лестнице, прыжок с террасы без урона, регрессия «тела раскладки на первом кадре».
- Rulings: меш рельефа строится в Godot, а не в Blender (один источник высот для меша, коллизии и `height_at`); подпорные
  стены в демо `"snap": false`.

## Ревью плана 10 и исправления

Ревьюер (0 критичных, 2 важных, 12 минорных; совпадение луча и `height_at` проверено на 17 161 точке, ≤ 3·10⁻⁶ м).
Исправлено: плита-коллайдер лестницы шла через внутренние углы ступеней (кот тонул до 20 см) — теперь через середины проступей,
сдвиг на полступени к началу (`test_stairs_collider_meets_every_tread_top`); коту задан `floor_max_angle` 40° из спека, обрыв
террасы 1 м (45° в карте высот) пешком больше не проходится (`test_cat_cannot_walk_up_a_one_metre_terrace`, в демо-рельеф
добавлена терраса 1 м). Ruling: линия плиты через середины проступей, а не через носки — у носка кот утопает, у задней кромки
висит не больше чем на 10 см, в среднем по ступени ноль. Отложено — в дорожной карте.

## План 11. Генератор раскладки и двор ×3 (`docs/superpowers/plans/2026-10-09-snack-run-11-yard-x3.md`)

Ветка `plan-11-yard-x3`.
- Рельеф в масштабе: плоский тайл 30×30 — один квад (`Terrain.triangle_count`; двор ×3 — 25 244 треугольника при лимите
  40 000); `height_at` без данных отвечает 0; подпорная стена толщиной 1 м закрывает всю ячейку обрыва (центр на кромке + 0,5).
- Модель `garage` (3×5,5 м, крыша 2,28 м, ворота по +Z).
- `tools/layout/layout_gen.py` (stdlib): описание `data/layout_src/yard.json` → `data/layout/yard.json` + `data/terrain_src/yard.json`;
  `make layout` (затем сам `make terrain`). Ядро — прежний двор `data/layout_src/yard_core.json` без изменений (ключи клубочков
  сохранений те же). Операции: `perimeter` (модули встык, сторона не кратная модулю — последний прижат к концу и сдвинут на 5 см
  внутрь), `terrace` (элемент рельефа, подпорные стены, лестницы и пандусы, полосы обрыва и подходы 3 м закрыты для россыпи),
  `garage_row` (цепочка на крышу: стопка ящиков 0,6 → бак 1,12 → бак с двумя ящиками 1,72 → крыша 2,28), `hill`, `paint`
  (покрытие в ключе `surface`), `place`, `scatter`. Два прохода: структура всех зон, затем россыпь. Образцы флагов моделей
  (`colliders`, `solid`, `outline`) берутся из ядра; пятна — по явным коллайдерам. Инварианты (еда и клубочки не внутри
  пропсов, приподнятое — на достижимой цепочкой ≤ 0,8 м опоре, уникальные позиции клубочков) проверяет сам генератор.
- Двор 180×180 (x −90…90, z −150…30): ядро и улица с кафе у южного края, гаражи (2 ряда по 8), площадка на террасе 2 м,
  сквер с холмом 3 м, верхний двор на террасе 2 м с домами и балконами, веранда кафе на террасе 1 м, окраины; край закрыт
  стенами домов, проход только в парк. Еды 64, клубочков 52, укрытий 27; 3 собаки, 4 осы, 2 велосипедиста. Трава по умолчанию,
  асфальт на ядре, улице и гаражах.
- Оса летает на `height` над рельефом; мелкие пропсы гаснут за 40 м, фонари за 35 м, каскады теней 40 м.
- Тесты: `tools/layout/tests/test_layout_gen.py` (14), `test_yard_x3.gd` (6), правки `test_world_builder`, `test_yarn`,
  `test_terrain`, `test_wasp`, `test_lighting`. Кадры `build/shot_{garages,playground,upper,veranda,hill,overview}.png`
  (`make shot AT=x,y,z,yaw`, yaw 0 — взгляд на север, −Z).

## Ревью плана 11 и исправления

Ревьюер (0 критичных, 1 важное, 9 минорных) проверил достижимость и закрытость края собственным дампом поверхности
двора лучами и поиском в ширину. Исправлено: собака верхнего двора после погони шла домой по прямой, упиралась в подпорную
стену и стояла так до конца игры — возврат дольше 8 с переносит её домой (`test_dog_returns_home_onto_terrace_even_through_wall`).
Отложено — в дорожной карте. Вопрос владельцу: арку кафе с воротами по сытости 10 можно обойти по улице (так было и в 60×60).

## План 12. Парк ×3, вода и арка кафе (`docs/superpowers/plans/2026-10-09-snack-run-12-park-x3.md`)

Владелец: «делай сейчас все, не жди моих тестов или оценки, принимай решения сам» — планы 12–15 идут подряд без показа.
- Арка кафе: забор (коллайдер 1,8 м) вдоль улицы на z 10,9 по всей ширине двора — в кафе только через ворота по сытости 10
  (на z 10,5 стоит клубочек ядра). `perimeter` получил `extra` — флаги каждого модуля.
- Вода (`scripts/world/water.gd`, `assets/shaders/water.gdshader`): Area3D под поверхностью (на 0,15 м ниже уровня), кот `drown()`:
  1 с тонет, еда из зубов потеряна, сердечко цело, затем ближайший маркер группы `shore` и 2 с неуязвимости; звук `splash.wav`
  синтезом. Раскладка: `water_zones` (pos абсолютный, y — уровень) и `shore`.
- Генератор: операция `pond` (котловина, вода, 8 маркеров берега на r + 1,5), укрытие `bush`. Модель `gazebo` (пол 0,3 м,
  6 столбов, крыша), коллайдеры в описании.
- Парк 90×96 (x −45…45, z 29…125): ядро — прежний парк без боковых и северного заборов (`data/layout_src/park_core.json`);
  холм (0, 92) r 18 h 3 с беседкой и аллеей фонарей; пруд (−28, 66) r 11, глубина 1,5, вода −0,5; роща на востоке; северный
  луг; забор по x ±45 и z 125. Еды 35, клубочков 28, укрытий 17; опасностей ×2. Тест `test_park_x3.gd` (6).

## Ревью плана 12 и исправления

Ревьюер (0 критичных, 2 важных, 8 минорных) подтвердил заливкой проходимости закрытую арку и край парка, сухой берег, ключи
и раздельную еду районов. Исправлено: удар и «погладить» проходили по тонущему коту (`test_drowning_cat_cannot_be_hit_or_petted`);
вода с ALPHA шла прозрачным проходом без отражений SSR — теперь непрозрачная (`test_water_is_opaque_for_reflections`);
камера после возврата из воды летела через пруд — переносится к коту (`test_camera_follows_cat_back_to_shore`). Отложено — в дорожной карте.

## План 13. Район «Порт» и вода (`docs/superpowers/plans/2026-10-09-snack-run-13-port.md`)

Ветка `plan-13-port`.
- Картинки (`make images`, OpenAI `gpt-image-2.5`): текстуры `sand.png`, `planks.png`, иконки шести вкусняшек порта.
  Каналы рельефа `sand` (3 м) и `planks` (2 м).
- Модели: `boat`, `boat_upturned`, `barrel`, `bollard`, `deckchair`, `buoy`, `food_{shrimp,fries,squid,fish_sandwich,sushi,golden_fish}`.
- `Floater` (`scripts/world/floater.gd`, AnimatableBody3D, `sync_to_physics`): подъём ±amp и крен ±roll по синусу, период,
  фаза; раскладка `floaters` (pos абсолютный). Кот стоит на лодке и качается вместе с ней.
- Еда порта (альбом 20, 6/6/4/4): креветка, картошка фри, кальмар, рыбный сэндвич, суши, золотая рыбка (в точках спавна нет —
  только из ведра рыбака, план 15). Альбом — 5 колонок, иконки 64; `++ --album` открывает его для кадра.
- Генератор: `terrace` получил `sides`, `gaps`, `ground` (подножие стен), `wall_h` (модель стены), `level` (абсолютная высота
  плато — в `terrain_gen` высота террасы абсолютная); операции `flat` и `water` (зона воды + явные маркеры берега); `defaults` —
  флаги моделей из ядер других районов.
- Порт x −60…60, z 125…227, база −2: набережная (камень) на уровне 0 с парапетом 0,7 к пляжу, двумя лестницами и пандусом;
  причал (доски) на −1 с лестницей с набережной, парапетом и проёмами к лодкам; пляж −2 с дюнами, шезлонгами, зонтами и
  перевёрнутой лодкой-укрытием; море и гавань: дно −3,5, вода −2,3; 3 лодки, 5 бочек, 4 буйка. Ворота в северном заборе парка
  (x −6) при сытости 50. Еды 35, клубочков 25, укрытий 14. Тесты `test_port.gd` (6), `test_floater*.gd`.

## Известные грабли (сводка, чтобы не искать по тексту)

**Godot 4.7:** `class_name` виден после `make import`; GUT не падает на parse error (grep в Makefile);
`--headless` не рендерит; `.blend` в проекте → `.gdignore`; клипы из glb без лупа; модификаторы
скелета читать в `skeleton_updated`; AABB скинового меша уже в метрах; `grow` в пространстве
модели; `var x := f()` без типа возврата — ошибка парсинга; Filmic выцветает палитру.

**Blender 5.2:** `action.layers[].strips[].channelbags[].fcurves`; `rotation_mode = XYZ` после
импорта glTF; лишняя Icosphere от импортёра; активный action теряется при экспорте ACTIONS;
`select_all` в фоне не сбрасывает выделение; `dimensions` после `view_layer.update()`, без
масштаба родителя; `--python-exit-code 1`; Principled по `type`; масштаб арматуры не применять.

**UniMate:** CPU (`sampling.device`), requirements без `+cu124`, ручная разметка суставов, шим
`blender` для venv-`bpy`, чекпоинт докачивать с `-C -`. Позы лёжа/сидя для четвероногих не получаются.

**План 3:** ожидания GUT стоят на паузе дерева (ждать `create_timer(t, true)`); `Input.action_press` не
даёт событий `_unhandled_input` — меню опрашивать `is_action_just_pressed` из узла `ALWAYS`; `Main` не
делать `ALWAYS` (дети унаследуют и не встанут на паузу); `JSON.parse_string` печатает ERROR движка;
`Color` из `.tres` сравнивать через `to_html()`; камера-витрина — точка на будке, не мировое смещение.

**План 5:** импортированный glb-меш перед subdivision сваривать (`remove_doubles`), иначе мозаика; subdivision на
триангулированном меше ×6; `CPUParticles3D` из физического шага: эмиссию включать после `add_child`, удалять по таймеру,
не по `finished`; `ambient_light_source`: 1 = DISABLED, 3 = SKY; внешний `velocity.y` у кота гасится шагом на полу — в тестах
прыгать через `Input.action_press("jump")`; в тестах с нетипизированным `main` писать `var x: Тип = main.f()`; `yard.json`
многострочный — правки скриптом по строкам, не регуляркой; служебный рендер `-s` к `cat.glb` добавляет модификаторы вручную
(в glb их нет); картинки с «прозрачным» фоном у gpt-image имеют альфу до 253, не 255.

**План 9:** модели людей из Mixamo-подобных ригов разворачивать по позе клипа, а не покоя; статическую логику опасностей (`decide`, `phase_at`) держать отдельно для юнит-тестов; кот в тестах «бежит» только реальным `Input.action_press` (состояние пересчитывается каждый кадр); `Array[FoodDef]` чистить `clear()`, не присваивать `[]`.

**План 4:** одиночный прогон GUT — `-gselect=`; пары Area3D фиксируются по позициям в момент `add_child`
(узлы в тестах ставить `position` **до** `add_child`, иначе кот в точке собаки ловит удар на первом кадре); в скрипте
`-s` (SceneTree) автозагрузок нет и `global_position`/`look_at` в `_init()` не применяются — задавать `transform`;
в Blender при записи клипа поза ставится при снятом action (иначе `view_layer.update()` возвращает записанные кадры);
`keyframe_insert` на pose bone сам создаёт слот action (Blender 5); `GameState.reset()` рядом с `Main` тут же
автосохраняется — файл стирать после сброса или выключать `autosave`; Dummy-аудио в headless не ругается на `play()`.

**План 2 (Godot):** GUT 9.7 считает ошибки движка провалом → `failure_error_types` без `engine`;
поля чужих узлов через `set/get/call`; `home`/`anchor` брать на первом физическом кадре, не в `_ready`;
`ProgressBar` клампит значение; в тестах с падающим котом нужен пол.
**План 2 (Blender):** объектные каналы в actions (`Dog.blend` Idle) выкидывать; меш с поворотом
относительно арматуры запекать в вершины и сбрасывать `arm.matrix_world`; лимиты треугольников:
сфера 12×8 = 176, тор 16×8 = 256, скруглённый бокс с 3 сегментами = 188.

**План 10:** тела раскладки, добавленные в начало координат и сдвинутые после `add_child`, на первом физическом кадре
выталкивают кота сквозь тонкий `HeightMapShape3D` — ставить `transform` до `add_child`; подъём по пандусу в тестах медленнее
(ждать 300 кадров); новые glb видны тестам только после `make import`; `unittest discover` для `tools/terrain/tests` — с `-p`, без `-t`.

**План 11:** раскладку двора править только в `data/layout_src/yard.json` и пересобирать `make layout`; ящик — 0,3 м (стопки
через 0,3); россыпь делать после всей структуры; в описании ключ `type` занят операцией; у еды без `foods` блюда любого района.

**План 12:** у `perimeter` сторона «n» — меньший z, «s» — больший (север парка — «s»); вода — `Water` + маркеры `shore`, кот тонет
только погрузившись на 0,15 м; тест плоских тайлов пишет свой рельеф в `user://`.

**План 13:** высота `terrace` в `terrain_gen` — абсолютная (у генератора раскладки — `level`); одинаковые имена узлов Godot
переименовывает в `@Класс@N` — давать номер; в headless окно 1280×1280 — размеры UI мерить минимальным размером, а не окном.

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
`blender` для venv-`bpy`, чекпоинт докачивать с `-C -`.

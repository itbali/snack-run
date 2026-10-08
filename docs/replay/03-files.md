# Приложение: содержимое всех файлов проекта

Сгенерировано `make replay` из текущего дерева. Не редактировать руками.
Для каждого файла: путь относительно корня проекта и полное содержимое.
Отступы в GDScript и Makefile — табы; в Python проекта — тоже табы, кроме
`palette.py` и тестов Blender (пробелы). Копировать как есть.

Файлов: 50

## `CLAUDE.md`

````markdown
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
3. `docs/superpowers/plans/2026-10-07-snack-run-01-foundation.md` — план 1 (выполнен, слит в main 2026-10-08). Образец формата для планов 2–4.
4. `docs/superpowers/notes/2026-10-07-unimate-attempt.md` — как заработал UniMate на Mac и все найденные грабли.
5. `reference/*.png` — три концепт-арта (ключевой кадр, карта мира, артборд ассетов).

## Правила владельца проекта

- Движок Godot 4.7.2, ассеты генерируются Python-скриптами в Blender 5.2.2 (не руками в GUI).
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
make run           # запустить игру (WASD, Shift бег, Space прыжок, Q/R камера)
```
Пути инструментов: `/Applications/Godot.app/Contents/MacOS/Godot`, `/Applications/Blender.app/Contents/MacOS/Blender`.
Просмотр glb: `blender -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb`.
Инспекция рига: `blender -b <file.blend> --python tools/blender/rig_inspect.py`.

## Структура

- `scenes/main.tscn` + `scripts/main.gd` — собирает свет, двор, кота, камеру.
- `scripts/player/cat_motion.gd` — чистая логика (static, без узлов) → тесты в `tests/unit/`.
- `scripts/player/cat.gd` (CharacterBody3D, состояния idle/walk/run/jump; hide/hit — план 2), `camera_rig.gd`, `head_scaler.gd`.
- `scripts/visual/toon.gd` — `Toon.apply(root, width_m)`; ширина в метрах, пересчитывается под масштаб узла.
- `scripts/autoload/input_setup.gd` (InputMap в коде), `dev_tools.gd` (`++ --screenshot=path`).
- `tools/blender/`: `palette.py`, `lib.py` (rounded_box, world_extent, tri_count, check_asset), `export.py`, `build.py`, `cat.py`, `gen/*.py` (каждый: `SPEC` + `build()`).
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

**UniMate на Mac** (подробно в заметке): venv Python 3.10 через `uv`, requirements без `+cu124`, `sampling.device = cpu` в `config.json` чекпоинта (MPS не умеет float64), ручная `annotation.json` (авторазметка путает спину и хвост), шим `blender` → venv-python с pip-`bpy` для `run_animate_motion.sh`. Окружение жило в scratchpad и не сохранилось; чекпоинт 1,2 ГБ качается с HF заново.

## Статус и что дальше

- План 1 выполнен и слит в `main` (2026-10-08). Отложенные мелочи из ревью перечислены в конце дорожной карты.
- Следующий шаг: написать план 2 «Игровой цикл» по дорожной карте, опираясь на реальные интерфейсы `Cat`, `CameraRig`, `Toon`, `build.py`. Учесть: Box3 висит в воздухе, коробку сделать читаемой, высота прыжка 0,84 м против баков 1,1 м, состояние fall, мышь для камеры, прозрачность кота у стены вместо скрытия.
- Открытый вопрос владельцу: лицензия весов UniMate для сгенерированных движений (код MIT, для весов явной лицензии не найдено).
````

## `Makefile`

```makefile
SHELL   := /bin/bash
GODOT   ?= /Applications/Godot.app/Contents/MacOS/Godot
BLENDER ?= /Applications/Blender.app/Contents/MacOS/Blender
SHOT    ?= build/shot.png

.PHONY: import test test-godot test-blender assets shot run replay

import:
	$(GODOT) --headless --path . --import

test: test-blender test-godot

test-godot: import
	mkdir -p build
	set -o pipefail; $(GODOT) --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee build/gut.log
	@! grep -q "SCRIPT ERROR" build/gut.log || (echo "Ошибки скриптов в тестах, см. build/gut.log"; exit 1)

test-blender:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/tests/run.py

assets:
	$(BLENDER) -b --python-exit-code 1 --python tools/blender/build.py -- $(ONLY)

shot: import
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 ++ --screenshot=$(SHOT)

run: import
	$(GODOT) --path .

replay:
	python3 tools/replay/build_files_md.py
```

## `project.godot`

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

## `.gutconfig.json`

```json
{
  "dirs": ["res://tests/"],
  "include_subdirs": true,
  "should_exit": true,
  "log_level": 1,
  "prefix": "test_"
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

## `scenes/main.tscn`

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

[node name="Collision" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.09, 0)
shape = SubResource("shape")

[node name="Model" parent="." instance=ExtResource("2")]
```

## `scenes/world/district_yard.tscn`

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
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0)
```

## `scenes/world/lighting.tscn`

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
ambient_light_energy = 0.45
tonemap_mode = 0

[node name="Lighting" type="Node3D"]
script = ExtResource("1")

[node name="Sun" type="DirectionalLight3D" parent="."]
light_color = Color(1, 0.945, 0.839, 1)
light_energy = 1.0
shadow_enabled = true

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")
```

## `scripts/autoload/dev_tools.gd`

```gdscript
extends Node
## Инструменты разработчика. Запуск: godot --path . ++ --screenshot=build/shot.png

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_and_quit(arg.trim_prefix("--screenshot="))


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

## `scripts/main.gd`

```gdscript
extends Node3D
## Собирает мир, кота и камеру.

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")


func _ready() -> void:
	Toon.apply($DistrictYard, Toon.OUTLINE_NONE)
	var rig := RigScene.instantiate() as CameraRig
	rig.name = "CameraRig"
	var cat := CatScene.instantiate() as Cat
	cat.name = "Cat"
	cat.camera_rig = rig
	rig.target = cat
	add_child(rig)
	add_child(cat)
	cat.global_position = $DistrictYard/Spawn.global_position
	rig.global_position = cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	(rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()
```

## `scripts/player/camera_rig.gd`

```gdscript
class_name CameraRig
extends Node3D
## Третье лицо: пружина 1,8 м, взгляд с высоты 0,6 м, наклон −14°, сглаживание 8/с (спек 2.3).

const HEIGHT := 0.6
const DISTANCE := 1.8
const SMOOTH := 8.0
const HIDE_BELOW := 0.9
const YAW_SPEED := 2.2
const PITCH_DEG := -14.0

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

## `scripts/player/cat.gd`

```gdscript
class_name Cat
extends CharacterBody3D
## Узел кота: читает ввод, двигает тело через CatMotion, переключает клипы.

signal state_changed(state: StringName)

const FALLBACK := {&"run": [&"walk", 1.8], &"jump": [&"idle", 1.0], &"hide": [&"idle", 1.0], &"hit": [&"idle", 1.0]}
const TURN_SPEED := 12.0
const LOOPING_CLIPS := ["idle", "walk", "run", "hide"]   # jump и hit играют один раз

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

## `scripts/tools/look_at_target.gd`

```gdscript
extends Camera3D
## Смотрит на точку target_point после входа в дерево.

@export var target_point := Vector3(0, 0.15, 0)

func _ready() -> void:
	look_at(target_point, Vector3.UP)
```

## `scripts/visual/toon.gd`

```gdscript
class_name Toon
extends RefCounted
## Переводит материалы в тун-режим и добавляет обводку инвертированным hull-ом (спек 2.3).

const OUTLINE_COLOR := Color("#394151")
const OUTLINE_CHARACTER := 0.006   # метры; 0,02 из первой версии спека на 35-см коте рвёт hull
const OUTLINE_FOOD := 0.004
const OUTLINE_NONE := 0.0


## outline_width задаётся в метрах: grow работает в пространстве модели, поэтому
## для вложенных в масштабированный узел мешей (скиновый кот) ширина пересчитывается.
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
		mi.material_overlay = _make_outline(outline_width / _world_scale(mi))
	return surfaces


static func _world_scale(mi: MeshInstance3D) -> float:
	if not mi.is_inside_tree():
		return 1.0
	var s := mi.global_transform.basis.get_scale().x
	return s if s > 0.0001 else 1.0


static func _make_outline(width: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = OUTLINE_COLOR
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = width
	return m
```

## `scripts/world/lighting.gd`

```gdscript
extends Node3D
## Солнце под 50° к горизонту, с юго-востока (спек 2.3).

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
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
	var mesh := cat.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
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

func test_camera_rig_hides_target_when_too_close() -> void:
	var cat = _spawn()
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	rig.target = cat
	add_child_autofree(rig)
	rig.apply_arm_length(0.5)   # имитация упора в стену
	assert_false(cat.visible)
	rig.apply_arm_length(3.5)
	assert_true(cat.visible)

func test_locomotion_clips_loop() -> void:
	# Ревью: idle/walk/run без зацикливания останавливаются через 1,7 с.
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["idle", "walk", "run", "hide"]:
		assert_eq(ap.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, "клип %s должен зацикливаться" % clip)
```

## `tests/integration/test_main.gd`

```gdscript
extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

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
	for a in ["move_left", "move_right", "move_forward", "move_back", "run", "jump", "hide", "eat", "cam_left", "cam_right"]:
		assert_true(InputMap.has_action(a), "нет действия " + a)
```

## `tests/unit/test_smoke.gd`

```gdscript
extends GutTest

func test_godot_version_is_4_7() -> void:
	var v := Engine.get_version_info()
	assert_eq(v.major, 4)
	assert_eq(v.minor, 7)
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

func test_outline_width_is_in_meters_under_scaled_parent() -> void:
	# Ревью: grow считается в пространстве модели, у скинового кота масштаб скелета 0,2.
	var parent := Node3D.new()
	parent.scale = Vector3.ONE * 0.2
	add_child_autofree(parent)
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	parent.add_child(mi)
	Toon.apply(mi, 0.02)
	assert_almost_eq((mi.material_overlay as StandardMaterial3D).grow_amount, 0.1, 0.001)
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
палитра, масштаб 0,35 м, разворот мордой по -Z Godot."""
import math
import os

import bpy

import palette

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


def face_forward(arm):
	"""Поворачивает арматуру так, чтобы вектор таз→голова смотрел по +Y Blender (= -Z Godot)."""
	arm.rotation_mode = "XYZ"   # импортёр glTF ставит QUATERNION, и правка rotation_euler игнорируется
	hips = arm.data.bones["Bone"].head_local
	head = arm.data.bones["head"].head_local
	d = arm.matrix_world.to_3x3() @ (head - hips)
	angle = math.atan2(d.y, d.x)
	arm.rotation_euler.z += math.pi / 2 - angle
	bpy.context.view_layer.update()
	d2 = arm.matrix_world.to_3x3() @ (head - hips)
	print(f"КОТ СМОТРИТ: ({d2.x:.2f}, {d2.y:.2f}, {d2.z:.2f}), ожидается +Y")


def rescale(arm, mesh):
	bpy.context.view_layer.update()
	factor = TARGET_LENGTH / max(mesh.dimensions)
	arm.scale = (arm.scale.x * factor, arm.scale.y * factor, arm.scale.z * factor)


def build():
	arm, mesh = load_canonical()
	add_source_actions(arm)
	add_generated_clips(arm, mesh)
	arm.animation_data_create()
	arm.animation_data.action = None   # активный action экспортёр в режиме ACTIONS теряет
	for pb in arm.pose.bones:
		pb.rotation_mode = "QUATERNION"
	recolor(mesh)
	face_forward(arm)
	rescale(arm, mesh)
	arm.name = "CatRig"
	mesh.name = "cat"
	return [arm, mesh]
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

## `tools/blender/gen/cat.py`

```python
"""Генератор кота: оборачивает cat.py для build.py."""
import cat

SPEC = {"max_tris": 2500, "max_dim": 0.6, "animations": True}


def build():
	return cat.build()
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
	walk.location = (-10, 10, -0.06)   # верх на 0: заподлицо с коллизией пола
	return [asphalt, walk]
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
]
EXCLUDE_DIRS = {"addons", "build", ".godot", ".superpowers", "assets"}
LANG = {".py": "python", ".gd": "gdscript", ".tscn": "", ".json": "json", ".md": "markdown",
        ".godot": "ini", "Makefile": "makefile", ".gitignore": "", ".gdignore": ""}


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

## План 2. Игровой цикл

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

## План 3. Хаб и прогрессия

Результат: магазин пряжи, альбом, клубочки, ворота в кафе, сохранение.

- Клубочки в мире и бонус за карточки; арка в кафе по сытости 10.
- Магазин: экран, товары из `.tres` (сердечки, вместимость, скорость, тихие
  шаги, 3 скина), котёнок играет с клубочками на фоне, точка возрождения.
- Альбом: сетка карточек по редкостям. Меню, пауза. Сохранение JSON в `user://`.
- Кафе: пропсы (столы, зонты, вывеска, дорога), спавны редкой еды.

## План 4. Полировка под ролик

- Эмоции глаз (4 материала), «чиби»-пропорции лап, частицы при съедании и
  ударе, 6 звуков CC0, виньетка, экспорт mac-билда.
- Плейтест балансa: время до арки 2–3 мин, иначе порог 6 (спек 3.3).
- Этапы 2+ (парк, сутки, порт) — отдельные спеки.

## Отложено сознательно

Пропорции лап и выражения глаз котёнка (спек 2.1, 2.4) перенесены в план 4,
чтобы план 1 дал играбельного кота раньше. Голова увеличивается уже в плане 1.

## Отложенные мелочи из ревью плана 1 (взять в план 2 или 4)

- Box3 в `district_yard.tscn` на x=2,0 висит в воздухе рядом с Box1; должен стоять на Box1.
- Коробка цвета sand на тротуаре sand не читается; другой цвет или обводка.
- 9× «Parameter material is null» в `build/gut.log` при `free_all` под dummy-рендерером; причина не выяснена.
- `test_input_actions_registered` тавтологичен (автозагрузка уже зарегистрировала действия).
- Клип jump 1,96 с при физическом прыжке 0,75 с; нет состояния fall при спуске с объектов.
- `cat.py` при отсутствии клипа только печатает предупреждение; `make assets` успешен без клипа.
- Переименовать `tools/blender/cat.py` → `cat_asset.py` (двусмысленность с `gen/cat.py`).
- Имена костей `Bone`/`head` в `cat.py` вынести в константы с комментарием.
- Баки 1,12 м недостижимы прыжком 0,84 м (спек 3.1 «прыжок на бак»): ступени/лестницы или высота прыжка.
- Кот прячется целиком при упоре камеры в стену (порог 0,9 м при дистанции 1,8 м); рассмотреть прозрачность.
- Камера только Q/R, добавить мышь/правый стик.
- Лицензия весов UniMate для сгенерированных движений — уточнить владельцу.
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
```


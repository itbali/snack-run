# Snack Run, план 4: Полировка под ролик

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Довести вертикальный срез до состояния «красиво на видео»: UI в стиле спека (Nunito, белые плашки), эмоции глаз кота, частицы, шесть звуков, камера мышью с прозрачным котом и виньеткой, спящая собака, закрытые дыры мира (kill-plane, будка), проверка баланса, mac-билд.

**Architecture:** Глаза — четыре набора мешей, привязанных к кости головы в Blender и переключаемых в Godot чистым классом `CatFace`; звуки — автозагрузка `Sfx` с пулом плееров, по одному вызову на игровое событие; частицы — статический `Effects.burst`; камера владеет прозрачностью кота через `Cat.set_fade`, скин её не трогает; поза «спит» собаки — процедурный клип Blender (UniMate не дал позу лёжа); UI — один `Theme`-ресурс, подключённый проектом.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript, GUT 9.7.1, Blender 5.2.2 (bpy/bmesh), glTF, Python 3 (stdlib, синтез WAV), make, curl.

**Spec:** `docs/superpowers/specs/2026-10-07-snack-run-design.md` (2.1 стиль, 2.3 камера, 2.4 эмоции, 2.5 собака, 2.6 UI, 2.7 звук, 3.2 удар, 3.3 баланс, 3.5 будка). Дорожная карта: `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md` (раздел «План 4» и список отложенных мелочей). Образцы: планы 1–3. Памятка: `CLAUDE.md`.

## Global Constraints

- Godot 4.7.2, GDScript, Forward+; `GODOT=/Applications/Godot.app/Contents/MacOS/Godot`, `BLENDER=/Applications/Blender.app/Contents/MacOS/Blender`.
- Только бесплатные ассеты: шрифт Nunito (SIL OFL, с `OFL.txt` рядом), звуки Kenney (CC0, с лицензией рядом), остальное генерируется скриптами. Анимации не рисовать руками: клип «спит» — процедурный скрипт, потому что готового нет (решение владельца № 8).
- Модели только скриптами Blender (`tools/blender/**`), кот ≤ 2500 треугольников (сейчас 807), собака ≤ 2500 (602). Палитра `tools/blender/palette.py`; имена материалов `sr_*`; скин перекрашивает только `sr_cat_orange`, `sr_cream`, `sr_coral`.
- Камера: 1,8 м, наклон −14°, обводка 0,006 м для персонажей (спек 2.3). Мышь крутит только вокруг кота (yaw).
- Слои коллизий: `Layers.WORLD = 1`, `CAT = 2`, `HAZARD = 4`, `AREA = 8`.
- Тесты: GUT с `.gutconfig.json`, `make test-godot` падает на `SCRIPT ERROR` и на любых `^ERROR:` кроме «Parameter "material" is null». Любые `Input.mouse_mode` только через `Mouse.capture()` (в headless ничего не делает). Таймеры в тестах при паузе — `get_tree().create_timer(t, true)`.
- Русские тексты, английские идентификаторы, коммиты с `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`; к `.glb/.gd/.ogg/.wav/.ttf/.gdshader/.tres` добавлять `*.import`/`*.uid`, которые появляются после `make import`.
- В интеграционных тестах `GameState.reset()` в `before_each`; там, где создаётся `Main`, ещё и `SaveGame.path = "user://test_save.json"` + `SaveGame.clear()` в `after_each`.

## Отклонения от спека, принятые заранее

- Эмоции (спек 2.4): не смена материала на плоскости лица, а четыре набора мешей (`eyes_normal/scared/happy/dizzy`), привязанных к кости головы; виден один. У модели Quaternius нет UV-плоскости лица, меши дают тот же кадр.
- «Чиби»-пропорции лап (спек 2.1) не делаются: голова уже ×1,4, а укорочение костей сломало бы клипы UniMate, записанные на канонический скелет. Зафиксировано как сознательный отказ.
- Белок глаз `#F4F1E8` — цвет вне палитры спека, чтобы скины (перекрашивают `sr_cream`) не трогали глаза.
- Звуки (спек 2.7): четыре из паков Kenney (подбор, съедание, удар, звонок), два синтезированы скриптом (писк кота, лай): в CC0-паках Kenney нет голосов животных, freesound требует аккаунт и ключ API.
- Виньетка — шейдер на `ColorRect` поверх 3D (Forward+ не имеет встроенной виньетки).
- Падение за край мира (спек молчит): возврат к будке без потери сердечка, еда из зубов теряется.
- Обморок: еда из зубов не рассыпается, а теряется (спек 3.2 «потеряна»); при обычном ударе рассыпается, как раньше.
- Собака при коте в будке уходит домой сразу, а не через 2 с («в будку собаки не заходят», спек 3.5); укрытия по-прежнему теряют след через 2 с.
- Mac-билд подписывается встроенной ad-hoc подписью Godot (без сертификата и нотаризации): на этой машине запускается, на чужой Gatekeeper предупредит.
- Space в магазине покупает выделенный товар — это стандартное поведение `ui_accept`, не меняется. B на геймпаде (`ui_cancel`) закрывает магазин и альбом.

## Review Focus

1. Чёрный скин: глаза остаются белыми с графитовыми зрачками (скин перекрашивает только три материала тела). Тест в задаче 2.
2. Выражения снимаются сами: «оглушён» после `STUN_TIME`, «испуг» через 0,4 с после последнего сигнала от собаки, «довольный» через 1 с; приоритет оглушён > испуг > довольный. Тест в задаче 2.
3. Звук на событие, не на кадр: кот полсекунды в зоне собаки — один «hit» (повторные удары блокирует неуязвимость). Тест в задаче 4.
4. Прозрачность кота у стены снимается при отходе; смена скина во время затенения не возвращает непрозрачность; в витрине кот непрозрачен. Тесты в задаче 5.
5. Kill-plane срабатывает только ниже −5 м: кот на балконе (y = 1,0) и на столе кафе (0,75) остаётся на месте. Тест в задаче 7.

---

## Структура файлов

```
assets/fonts/Nunito.ttf, OFL.txt          # шрифт (SIL OFL)
assets/ui/theme.tres                      # тема: Nunito, белые плашки, кнопки
assets/sfx/{pickup,eat,hit,bell}.ogg      # Kenney CC0 + LICENSE_kenney.txt
assets/sfx/{meow,bark}.wav                # синтез tools/audio/gen_sfx.py
assets/sfx/README.md                      # источники и лицензии
assets/shaders/vignette.gdshader
scripts/core/mouse.gd                     # Mouse.capture(on) с защитой от headless
scripts/player/cat_face.gd                # CatFace: выражения глаз
scripts/player/cat.gd                     # + face, threaten/cheer, set_fade
scripts/player/camera_rig.gd              # + мышь, прозрачность вместо скрытия
scripts/visual/effects.gd                 # Effects.burst
scripts/autoload/sfx.gd                   # автозагрузка Sfx
scripts/hazards/chase_brain.gd            # + cat_safe
scripts/hazards/dog.gd                    # + лай, threaten, будка
scripts/ui/hud.gd  title.gd  menu_input.gd
scripts/world/spill_spawner.gd            # еда на высоте кота
scripts/main.gd                           # + частицы, звуки, kill-plane, мышь, сброс
scenes/ui/hud.tscn  title.tscn  scenes/main.tscn (виньетка)  scenes/world/yarn_shop.tscn (плита)
tools/blender/cat_eyes.py  cat.py (+глаза)  dog_sleep.py  dog.py (+sleep)  palette.py (+eye_white)
tools/blender/tests/test_cat_eyes.py  test_dog_sleep.py
tools/audio/gen_sfx.py
export_presets.cfg  Makefile (+sfx, templates, export)
tests/unit/test_theme.gd  test_sfx.gd  test_balance.gd  test_chase_brain.gd (+)
tests/integration/test_effects.gd  test_cat_scene.gd (+)  test_dog.gd (+)  test_dog_asset.gd (+)
tests/integration/test_main.gd (+)  test_menus.gd (+)  test_hud.gd (±)  test_yarn_shop.gd (+)
docs/replay/02-procedure.md (+план 4)  tools/replay/build_files_md.py (+новые типы)
```

Первая «картинка для ролика» появляется после задачи 2 (глаза): на этом месте сделать `make shot` и посмотреть кадр. Порядок задач — по видимости в кадре: UI → глаза → частицы → звук → камера → собака и будка → дыры мира → баланс → экспорт → документация.

---

### Task 1: Тема UI, HUD на плашках, заставка «Продолжить / Новая игра»

**Files:**
- Create: `assets/fonts/Nunito.ttf`, `assets/fonts/OFL.txt`, `assets/ui/theme.tres`, `scripts/core/mouse.gd`, `tests/unit/test_theme.gd`
- Modify: `project.godot`, `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`, `scenes/ui/title.tscn`, `scripts/ui/title.gd`, `tests/integration/test_hud.gd`, `tests/integration/test_menus.gd`

**Interfaces:**
- Produces: `Mouse.capture(on: bool) -> void` (статический, в headless no-op; задача 5 пользуется им в `Main`); узлы HUD с уникальными именами `%Hearts %Satiety %SatietyLabel %Yarn %Mouth %Goal %Bell %BellPanel` (методы `hearts_text/mouth_names/yarn_text/satiety_label_text/flash_bell` без изменений); `Title.has_save() -> bool`, `Title.new_game()`, `Title.continue_game()`, `Title.switch_scenes: bool` (тесты ставят `false`).

- [ ] **Step 1: Скачать шрифт**

```bash
mkdir -p assets/fonts
curl -sL -o assets/fonts/Nunito.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf"
curl -sL -o assets/fonts/OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/OFL.txt"
ls -la assets/fonts && head -3 assets/fonts/OFL.txt
```
Expected: `Nunito.ttf` ≈ 277 КБ, `OFL.txt` начинается с «Copyright 2014 The Nunito Project Authors».

- [ ] **Step 2: Падающий тест темы**

`tests/unit/test_theme.gd`:
```gdscript
extends GutTest

func test_project_theme_uses_nunito_and_rounded_panels() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), "res://assets/ui/theme.tres")
	var theme := load("res://assets/ui/theme.tres") as Theme
	assert_not_null(theme, "нет темы")
	if theme == null:
		return
	assert_not_null(theme.default_font, "шрифт по умолчанию задан")
	assert_eq(theme.default_font.resource_path, "res://assets/fonts/Nunito.ttf")
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	assert_not_null(panel, "плашка PanelContainer — StyleBoxFlat")
	if panel == null:
		return
	assert_gt(panel.corner_radius_top_left, 8, "округлые углы")
	assert_gt(panel.shadow_size, 0, "мягкая тень")
	assert_eq(theme.get_color("font_color", "Label").to_html(false), "394151", "графитовый текст")
```

- [ ] **Step 3: Запустить, убедиться, что падает**

Run: `make import >/dev/null && $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/unit/test_theme.gd 2>&1 | tail -8`
Expected: FAIL на `gui/theme/custom` (пустая строка вместо пути).

- [ ] **Step 4: Тема, настройка проекта, Mouse**

`assets/ui/theme.tres`:
```
[gd_resource type="Theme" load_steps=8 format=3]

[ext_resource type="FontFile" path="res://assets/fonts/Nunito.ttf" id="1"]

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
default_font_size = 20
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

В `project.godot` добавить секцию (между `[editor_plugins]` и `[rendering]`, порядок секций не важен):
```ini
[gui]

theme/custom="res://assets/ui/theme.tres"
```

`scripts/core/mouse.gd`:
```gdscript
class_name Mouse
extends RefCounted
## Захват мыши для камеры. В headless (тесты, импорт) ничего не делает: там DisplayServer без мыши.


static func capture(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE
```

- [ ] **Step 5: Тест темы зелёный**

Run: `make import >/dev/null && $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/unit/test_theme.gd 2>&1 | tail -5`
Expected: `1 passed`. Если `default_font.resource_path` пустой — шрифт не импортировался: проверить `assets/fonts/Nunito.ttf.import` после `make import`.

- [ ] **Step 6: Падающие тесты HUD и заставки**

В `tests/integration/test_hud.gd` заменить обращения к узлам:
```gdscript
func test_satiety_and_goal_labels() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	GameState.eat_all()
	# Полоска показывает прогресс до порога арки (10) и упирается в максимум.
	assert_eq((hud.get_node("%Satiety") as ProgressBar).value, float(GameState.SATIETY_GATE))
	assert_eq((hud.get_node("%Goal") as Label).text, "Открой новых карточек: 1/3")

func test_bell_flash_shows_and_hides() -> void:
	hud.flash_bell("🔔 Велосипед!", 0.1)
	assert_true((hud.get_node("%BellPanel") as PanelContainer).visible)
	await wait_seconds(0.25)
	assert_false((hud.get_node("%BellPanel") as PanelContainer).visible)

func test_hud_elements_sit_on_white_panels() -> void:
	# Спек 2.6: сердечки, сытость и клубочки на одной плашке; цель и звонок — на своих.
	for path in ["%Hearts", "%Satiety", "%Yarn", "%Goal", "%Bell"]:
		var n := hud.get_node(path) as Control
		var p := n
		while p and not (p is PanelContainer):
			p = p.get_parent() as Control
		assert_not_null(p, "%s лежит на PanelContainer" % path)
	assert_eq((hud.get_node("%Yarn") as Label).get_theme_color("font_color").to_html(false), "394151", "счётчик клубочков графитовый, читается на любом фоне")
```

В `tests/integration/test_menus.gd` заменить `test_title_scene_has_play_button` на:
```gdscript
func test_title_offers_continue_only_with_save() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/ui/title.tscn")
	var title := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title.switch_scenes = false
	add_child_autofree(title)
	assert_false((title.get_node("VBox/Continue") as Button).visible, "без сохранения «Продолжить» скрыта")
	assert_eq((title.get_node("VBox/Play") as Button).text, "Новая игра")
	SaveGame.save_now()
	var title2 := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title2.switch_scenes = false
	add_child_autofree(title2)
	assert_true((title2.get_node("VBox/Continue") as Button).visible, "с сохранением «Продолжить» видна")
	title2.new_game()
	assert_false(FileAccess.file_exists(SaveGame.path), "«Новая игра» стирает сохранение")
```

- [ ] **Step 7: Запустить, убедиться, что падают**

Run: `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/integration/test_hud.gd -gtest=res://tests/integration/test_menus.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head`
Expected: падения на `%Satiety` (узел не найден) и `switch_scenes` (нет свойства).

- [ ] **Step 8: HUD на плашках**

`scenes/ui/hud.tscn` целиком:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]

[node name="Hud" type="CanvasLayer"]
script = ExtResource("1")

[node name="Status" type="PanelContainer" parent="."]
offset_left = 20.0
offset_top = 16.0
offset_right = 280.0
offset_bottom = 130.0

[node name="VBox" type="VBoxContainer" parent="Status"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="Hearts" type="Label" parent="Status/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.961, 0.455, 0.522, 1)
theme_override_font_sizes/font_size = 30
text = "♥♥♥"

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

[node name="Yarn" type="Label" parent="Status/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 22
text = "◎ 0"

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
```

`scripts/ui/hud.gd` — заменить блок `@onready` и две функции:
```gdscript
@onready var _hearts: Label = %Hearts
@onready var _satiety: ProgressBar = %Satiety
@onready var _satiety_label: Label = %SatietyLabel
@onready var _yarn: Label = %Yarn
@onready var _mouth: HBoxContainer = %Mouth
@onready var _goal: Label = %Goal
@onready var _bell: Label = %Bell
@onready var _bell_panel: PanelContainer = %BellPanel
```
В `_ready()` строку `_bell.visible = false` заменить на `_bell_panel.visible = false`; слоты зубов оставить (их `PanelContainer` теперь берут плашку из темы). `flash_bell`:
```gdscript
func flash_bell(text := "🔔 Велосипед!", seconds := 2.0) -> void:
	_bell.text = text
	_bell_panel.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _bell_panel.visible = false)
```
Описание класса обновить: «HUD на белых плашках темы (спек 2.6)».

- [ ] **Step 9: Заставка**

`scenes/ui/title.tscn`: узлу `Logo` добавить `theme_override_colors/font_color = Color(1, 1, 1, 1)`, узлу `Tagline` — тоже; между `Tagline` и `Play` вставить:
```
[node name="Continue" type="Button" parent="VBox"]
layout_mode = 2
text = "Продолжить"
```
и у `Play` поменять текст на `text = "Новая игра"`.

`scripts/ui/title.gd` целиком:
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
	SaveGame.clear()
	GameState.reset()
	_go()


func _go() -> void:
	if switch_scenes:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
```

- [ ] **Step 10: Тесты зелёные, весь прогон**

Run: `make test-godot 2>&1 | tail -4`
Expected: все тесты зелёные (131 + 2 новых), без `SCRIPT ERROR`.

- [ ] **Step 11: Посмотреть кадр**

Run: `make shot SHOT=build/shot_ui.png` и открыть `build/shot_ui.png`.
Expected: слева вверху белая округлая плашка с сердечками, полоской и «◎ 0», внизу слева плашка цели, шрифт Nunito (округлые буквы). Если плашки нет — тема не подхватилась: проверить `gui/theme/custom` в `project.godot`.

- [ ] **Step 12: Коммит**

```bash
git add assets/fonts assets/ui project.godot scripts/core/mouse.gd scripts/ui/hud.gd scenes/ui/hud.tscn scripts/ui/title.gd scenes/ui/title.tscn tests/unit/test_theme.gd tests/integration/test_hud.gd tests/integration/test_menus.gd
git add -A assets/fonts assets/ui   # *.import
git commit -m "UI: тема Nunito с белыми плашками, HUD на плашках, заставка «Продолжить / Новая игра»

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Глаза и эмоции кота

**Files:**
- Create: `tools/blender/cat_eyes.py`, `tools/blender/tests/test_cat_eyes.py`, `scripts/player/cat_face.gd`
- Modify: `tools/blender/palette.py`, `tools/blender/cat.py`, `scripts/player/cat.gd`, `scripts/hazards/dog.gd`, `tests/integration/test_cat_scene.gd`, `tests/integration/test_dog.gd`, `assets/models/cat.glb` (пересборка)

**Interfaces:**
- Consumes: `cat.build()` (Blender), `Toon.apply`, `CatSkin.apply`, `Cat.STUN_TIME = 1.0`, `Cat.stunned_left`.
- Produces: в `cat.glb` четыре `MeshInstance3D` `eyes_normal`, `eyes_scared`, `eyes_happy`, `eyes_dizzy` под `Skeleton3D` (скин к кости `head`); `CatFace` (RefCounted): `bind(model: Node) -> int`, `threaten()`, `cheer()`, `update(delta: float, stunned: bool) -> StringName`, `expression: StringName`, `HAPPY_TIME = 1.0`, `THREAT_TIME = 0.4`; `Cat.face: CatFace`, `Cat.threaten()`, `Cat.cheer()`; `Dog` зовёт `cat.threaten()` каждый физический кадр в ALERT и CHASE; `cat_eyes.head_bbox(mesh) -> (Vector, Vector)`.

- [ ] **Step 1: Падающий Blender-тест**

`tools/blender/tests/test_cat_eyes.py`:
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
        cls.eyes = {o.name: o for o in cls.objs[2:]}

    def _world(self, o):
        bpy.context.view_layer.update()
        return [o.matrix_world @ v.co for v in o.data.vertices]

    def test_four_sets_skinned_to_head(self):
        self.assertEqual(set(self.eyes), {"eyes_normal", "eyes_scared", "eyes_happy", "eyes_dizzy"})
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

    def test_budget(self):
        self.assertEqual(lib.check_asset(self.objs, max_tris=2500, max_dim=0.6), [])
```

- [ ] **Step 2: Запустить, убедиться, что падает**

Run: `make test-blender 2>&1 | tail -6`
Expected: `ModuleNotFoundError: No module named 'cat_eyes'`.

- [ ] **Step 3: Палитра, модуль глаз, вызов из cat.py**

В `tools/blender/palette.py` в `PALETTE` после `"rarity_legendary"` добавить строку:
```python
    "eye_white": "#F4F1E8",   # белок глаз; не из спека, чтобы скины (sr_cream) не красили глаза
```

`tools/blender/cat_eyes.py`:
```python
"""Глаза кота: четыре набора мешей (обычные, испуг, довольный, оглушён) на кости головы.
В Godot одновременно виден один набор, переключает CatFace (спек 2.4). Координаты считаются
от bbox вершин головы, поэтому глаза всегда на морде, как бы ни был отмасштабирован риг."""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import lib

EYE_SETS = ("normal", "scared", "happy", "dizzy")
HEAD_GROUP = "head"
SPHERE = {"segments": 8, "rings": 6}   # 80 треугольников на сферу


def head_bbox(mesh):
	"""Мировой bbox вершин, привязанных к кости головы весом > 0,5."""
	bpy.context.view_layer.update()
	gi = mesh.vertex_groups[HEAD_GROUP].index
	pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices
	       if any(g.group == gi and g.weight > 0.5 for g in v.groups)]
	lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
	hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
	return lo, hi


def eye_centers(lo, hi):
	"""Центры левого и правого глаза: верхняя треть морды, чуть утоплены в переднюю грань (+Y)."""
	x = (hi.x - lo.x) * 0.22
	y = hi.y - 0.012
	z = lo.z + (hi.z - lo.z) * 0.68
	return Vector((-x, y, z)), Vector((x, y, z))


def _line(name, center, angle_deg, length, radius, material):
	"""Штрих в плоскости лица XZ: цилиндр вдоль X, повёрнутый на angle вокруг Y (оси взгляда).
	Положительный угол опускает +X-конец штриха."""
	c = lib.cylinder(name, radius=radius, depth=length, segments=6, material=material)
	c.rotation_euler = (0.0, math.pi / 2 + math.radians(angle_deg), 0.0)
	c.location = center
	return c


def _parts(kind, side, c):
	p = f"eye_{kind}_{side}"
	fwd = Vector((0.0, 1.0, 0.0))
	if kind == "normal":
		w = lib.sphere(p + "_w", 0.016, material="eye_white", **SPHERE)
		w.location = c
		k = lib.sphere(p + "_k", 0.0075, material="ink", **SPHERE)
		k.location = c + fwd * 0.010 + Vector((0.0, 0.0, 0.001))
		return [w, k]
	if kind == "scared":
		w = lib.sphere(p + "_w", 0.019, material="eye_white", **SPHERE)
		w.location = c
		k = lib.sphere(p + "_k", 0.004, material="ink", **SPHERE)
		k.location = c + fwd * 0.016 + Vector((0.0, 0.0, 0.004))
		return [w, k]
	if kind == "happy":   # «^»: левый штрих поднимается к центру, правый — от центра вниз
		a = _line(p + "_a", c + Vector((-0.006, 0.006, -0.002)), -35, 0.016, 0.0025, "ink")
		b = _line(p + "_b", c + Vector((0.006, 0.006, -0.002)), 35, 0.016, 0.0025, "ink")
		return [a, b]
	a = _line(p + "_a", c + fwd * 0.006, 45, 0.026, 0.0025, "ink")    # dizzy: «×»
	b = _line(p + "_b", c + fwd * 0.006, -45, 0.026, 0.0025, "ink")
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


def _attach(obj, arm):
	"""Переводит меш в пространство арматуры и скинит его к кости головы весом 1,0."""
	bpy.context.view_layer.update()
	obj.data.transform(arm.matrix_world.inverted() @ obj.matrix_world)
	obj.matrix_world = Matrix.Identity(4)
	obj.parent = arm
	obj.matrix_parent_inverse = Matrix.Identity(4)
	vg = obj.vertex_groups.new(name=HEAD_GROUP)
	vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")
	mod = obj.modifiers.new("Armature", "ARMATURE")
	mod.object = arm
	bpy.context.view_layer.update()


def build_eyes(arm, mesh):
	"""Четыре объекта eyes_<набор>, дети арматуры. Звать после face_forward и rescale."""
	lo, hi = head_bbox(mesh)
	left, right = eye_centers(lo, hi)
	out = []
	for kind in EYE_SETS:
		parts = _parts(kind, "l", left) + _parts(kind, "r", right)
		obj = _join(f"eyes_{kind}", parts)
		_attach(obj, arm)
		out.append(obj)
	return out
```

В `tools/blender/cat.py`: добавить `import cat_eyes` после `import palette`; в `build()` заменить хвост:
```python
	rescale(arm, mesh)
	eyes = cat_eyes.build_eyes(arm, mesh)
	arm.name = "CatRig"
	mesh.name = "cat"
	return [arm, mesh] + eyes
```
И дописать в docstring модуля: «плюс четыре набора глаз (cat_eyes.py)».

- [ ] **Step 4: Blender-тесты зелёные, пересобрать кота**

Run: `make test-blender 2>&1 | tail -4`
Expected: `Ran 16 tests ... OK`. Если `test_happy_chevrons_point_up` падает — поменять знаки углов `-35/35` местами в `_parts` (один раз, по результату теста), не трогая остальное.

Run: `make assets ONLY=cat 2>&1 | grep -E "ОК|ОШИБКА"`
Expected: `ОК cat -> assets/models/cat.glb (≈1600 tri)`; число ≤ 2500.

- [ ] **Step 5: Падающие Godot-тесты**

В `tests/integration/test_cat_scene.gd`: в `test_cat_starts_idle_with_toon_materials` строку с `find_children(...)[0]` заменить на `var mesh := cat.find_child("cat", true, false) as MeshInstance3D` (первым ребёнком скелета теперь может быть набор глаз без обводки). Добавить:
```gdscript
func test_eye_sets_exist_and_only_normal_is_visible() -> void:
	var cat = _spawn()
	var names := []
	for mi in cat.find_children("eyes_*", "MeshInstance3D", true, false):
		names.append(String(mi.name))
		assert_null((mi as MeshInstance3D).material_overlay, "у глаз нет обводки: 6 мм на 3-см глазу — рамка")
	names.sort()
	assert_eq(names, ["eyes_dizzy", "eyes_happy", "eyes_normal", "eyes_scared"])
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
```

В `tests/integration/test_dog.gd` добавить:
```gdscript
func test_chasing_dog_scares_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(0.5)
	assert_eq(dog.brain.state, ChaseBrain.State.ALERT)
	assert_eq(cat.face.expression, &"scared", "насторожившаяся собака пугает кота")
	cat.global_position = Vector3(0, 0.05, 12)   # дальше 6 м: собака ещё гонится, но угрозы рядом нет
	await wait_seconds(0.8)
	assert_eq(cat.face.expression, &"normal", "испуг гаснет без сигналов от собаки")
```

- [ ] **Step 6: Запустить, убедиться, что падают**

Run: `make import >/dev/null && $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/integration/test_cat_scene.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head`
Expected: падения `Invalid access to property 'face'` (и обводка на глазах есть).

- [ ] **Step 7: CatFace, Cat, Dog**

`scripts/player/cat_face.gd`:
```gdscript
class_name CatFace
extends RefCounted
## Выражения глаз (спек 2.4): оглушён > испуг > довольный > обычные.
## Переключает видимость мешей eyes_* из cat.glb; сам узлов не создаёт.

const SETS: Array[StringName] = [&"normal", &"scared", &"happy", &"dizzy"]
const HAPPY_TIME := 1.0
const THREAT_TIME := 0.4   # собака обновляет угрозу каждый физический кадр; без обновлений испуг гаснет

var expression: StringName = &"normal"
var happy_left := 0.0
var threat_left := 0.0
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
	var want: StringName = &"normal"
	if stunned:
		want = &"dizzy"
	elif threat_left > 0.0:
		want = &"scared"
	elif happy_left > 0.0:
		want = &"happy"
	if want != expression:
		_show(want)
	return expression


func _show(which: StringName) -> void:
	expression = which
	for key in _meshes:
		(_meshes[key] as MeshInstance3D).visible = key == which
```

`scripts/player/cat.gd`: добавить поле `var face := CatFace.new()` после `var invulnerable_left := 0.0`; в `_ready()` после `Toon.apply(_model, Toon.OUTLINE_CHARACTER)` вставить:
```gdscript
	for mi in _model.find_children("eyes_*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = null   # обводка 6 мм на 3-см глазу — рамка
	face.bind(_model)
```
В начало `_physics_process` (первой строкой) добавить `face.update(delta, stunned_left > 0.0)`. В `try_eat()` перед `ate.emit(items)` добавить `face.cheer()`. Добавить методы:
```gdscript
func threaten() -> void:
	## Собака насторожилась или гонится: зовётся каждый физический кадр, пока угроза есть.
	face.threaten()


func cheer() -> void:
	face.cheer()
```

`scripts/hazards/dog.gd`: в `_physics_process` после `var s := brain.update(...)` добавить
```gdscript
	if c and c.has_method("threaten") and s in [ChaseBrain.State.ALERT, ChaseBrain.State.CHASE] and global_position.distance_to(c.global_position) < VISION_RANGE:
		c.call("threaten")   # испуг, пока собака насторожилась или гонится и она ближе 6 м
```

- [ ] **Step 8: Тесты зелёные**

Run: `make test-godot 2>&1 | tail -4`
Expected: всё зелёное (+4 теста), `Ran 16` Blender не трогаем.

- [ ] **Step 9: Кадр для проверки глаз**

Run: `make shot SHOT=build/shot_eyes.png`, открыть `build/shot_eyes.png`.
Expected: у кота на морде два белых глаза с тёмными зрачками, без тёмной рамки, смотрят вперёд (камера сзади — видны краем). Если глаза на затылке или внутри головы — смотреть `eye_centers` (y = hi.y − 0.012 должен быть у носа; в Blender +Y — вперёд после `face_forward`).

- [ ] **Step 10: Коммит**

```bash
git add tools/blender/palette.py tools/blender/cat_eyes.py tools/blender/cat.py tools/blender/tests/test_cat_eyes.py assets/models/cat.glb assets/models/cat.glb.import scripts/player/cat_face.gd scripts/player/cat.gd scripts/hazards/dog.gd tests/integration/test_cat_scene.gd tests/integration/test_dog.gd
git add -A scripts/player   # *.uid
git commit -m "Кот: четыре набора глаз на кости головы и выражения (оглушён/испуг/довольный)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Частицы при съедании, ударе и клубочке

**Files:**
- Create: `scripts/visual/effects.gd`, `tests/integration/test_effects.gd`
- Modify: `scripts/main.gd`, `scripts/food/yarn_pickup.gd`, `tests/integration/test_main.gd`

**Interfaces:**
- Consumes: `GameState.food_eaten(items)`, `GameState.cat_hit(spilled)`, `Rarity.COLORS`, `FoodDef.tier`.
- Produces: `Effects.burst(parent: Node, pos: Vector3, color: Color, amount := 24, size := 0.05, speed := 2.0) -> CPUParticles3D` (одноразовый, в группе `"fx"`, сам удаляется по `finished`); `Effects.YARN_COLOR`, `Effects.HIT_COLOR`; `Main._on_food_eaten(items: Array)`.

- [ ] **Step 1: Падающие тесты**

`tests/integration/test_effects.gd`:
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
```

В `tests/integration/test_main.gd` добавить:
```gdscript
func test_eating_spawns_burst_in_rarity_color() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))   # редкая, синяя
	GameState.eat_all()
	var fx := get_tree().get_nodes_in_group("fx")
	assert_eq(fx.size(), 1, "один всплеск на съедание")
	if fx.size() == 1:
		assert_eq((fx[0] as CPUParticles3D).color, Rarity.COLORS[Rarity.Tier.RARE])

func test_hit_spawns_star_burst() -> void:
	var main := _spawn_main()
	var cat = main.find_child("Cat", true, false)
	await wait_physics_frames(30)
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	var fx := get_tree().get_nodes_in_group("fx")
	assert_eq(fx.size(), 1)
	if fx.size() == 1:
		assert_eq((fx[0] as CPUParticles3D).color, Effects.HIT_COLOR)
```

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `make import >/dev/null && $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/integration/test_effects.gd -gtest=res://tests/integration/test_main.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head`
Expected: `Identifier "Effects" not declared` / 0 узлов в группе fx.

- [ ] **Step 3: Effects и подключение**

`scripts/visual/effects.gd`:
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
	p.one_shot = true
	p.emitting = false
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
	p.finished.connect(p.queue_free)
	return p
```

`scripts/main.gd`: в `_ready()` после `GameState.cat_hit.connect(_on_cat_hit)` добавить `GameState.food_eaten.connect(_on_food_eaten)`. Заменить `_on_cat_hit` и добавить `_on_food_eaten`:
```gdscript
func _on_food_eaten(items: Array) -> void:
	var top: int = Rarity.Tier.COMMON
	for f in items:
		top = maxi(top, f.tier)
	Effects.burst(self, _cat.global_position + Vector3(0, 0.25, 0), Rarity.COLORS[top])


func _on_cat_hit(spilled: Array) -> void:
	Effects.burst(self, _cat.global_position + Vector3(0, 0.3, 0), Effects.HIT_COLOR, 16, 0.06, 1.5)
	if spilled.is_empty():
		return
	_spill.spill_around(_cat.global_position, spilled)
```

`scripts/food/yarn_pickup.gd`, `_on_body`:
```gdscript
func _on_body(body: Node3D) -> void:
	if not body.is_in_group("cat"):
		return
	GameState.take_yarn(key)
	if body.has_method("cheer"):
		body.call("cheer")
	Effects.burst(get_parent(), global_position + Vector3(0, 0.1, 0), Effects.YARN_COLOR, 16, 0.04)
	set_deferred("monitoring", false)
	queue_free()
```

- [ ] **Step 4: Тесты зелёные**

Run: `make test-godot 2>&1 | tail -4`
Expected: всё зелёное (+3). Если в `test_yarn.gd` клубочек подбирается без родителя-Node3D — `get_parent()` там есть (клубочки лежат в контейнере `WorldBuilder` или в тестовом `Node3D`).

- [ ] **Step 5: Коммит**

```bash
git add scripts/visual/effects.gd tests/integration/test_effects.gd scripts/main.gd scripts/food/yarn_pickup.gd tests/integration/test_main.gd
git add -A scripts/visual
git commit -m "Частицы: всплеск цвета редкости при съедании, звёзды при ударе, сиреневый при клубочке

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Шесть звуков

**Files:**
- Create: `assets/sfx/pickup.ogg`, `eat.ogg`, `hit.ogg`, `bell.ogg` (Kenney CC0), `assets/sfx/LICENSE_kenney.txt`, `assets/sfx/meow.wav`, `bark.wav` (синтез), `assets/sfx/README.md`, `tools/audio/gen_sfx.py`, `scripts/autoload/sfx.gd`, `tests/unit/test_sfx.gd`
- Modify: `project.godot` (автозагрузка `Sfx`), `Makefile` (цель `sfx`), `scripts/main.gd`, `scripts/player/cat.gd`, `scripts/food/food_pickup.gd`, `scripts/food/yarn_pickup.gd`, `scripts/hazards/dog.gd`, `tests/integration/test_dog.gd`, `tests/integration/test_main.gd`

**Interfaces:**
- Produces: автозагрузка `Sfx`: `play(name: StringName, pitch_jitter := 0.06) -> AudioStreamPlayer` (null, если звука нет или `enabled == false`), `has(name) -> bool`, `last_played: StringName`, `counts: Dictionary` (имя → сколько раз сыграно), `reset_counters()`; имена: `pickup, eat, hit, meow, bark, bell`.
- Правило: один `play()` на игровое событие (сигнал), никогда из `_process`.

- [ ] **Step 1: Скачать паки Kenney и выбрать файлы**

```bash
S=/tmp/snack_scratch/kenney; mkdir -p $S && cd $S
for slug in impact-sounds interface-sounds; do
  url=$(curl -sL "https://kenney.nl/assets/$slug" | grep -oE 'https://kenney\.nl/media/pages/assets/[^"]*\.zip' | head -1)
  echo "$slug -> $url"; curl -sL -o $slug.zip "$url" && mkdir -p $slug && unzip -q -o $slug.zip -d $slug
done
find $S -iname "*.ogg" | grep -iE "pluck_001|drop_002|impactPunch_medium_000|impactBell_heavy_000"
find $S -iname "License*"
```
Expected: четыре `.ogg` найдены (пути вида `.../Audio/pluck_001.ogg`) и два `License.txt` (CC0). Если какого-то имени нет — `ls` папки `Audio` и взять ближайший по смыслу (pluck/select → подбор; drop → съедание; impactPunch → удар; impactBell → звонок), записать Ruling в журнал.

```bash
cd <проект> && mkdir -p assets/sfx
cp "$(find $S -iname pluck_001.ogg | head -1)" assets/sfx/pickup.ogg
cp "$(find $S -iname drop_002.ogg | head -1)" assets/sfx/eat.ogg
cp "$(find $S -iname impactPunch_medium_000.ogg | head -1)" assets/sfx/hit.ogg
cp "$(find $S -iname impactBell_heavy_000.ogg | head -1)" assets/sfx/bell.ogg
cp "$(find $S/impact-sounds -iname 'License*' | head -1)" assets/sfx/LICENSE_kenney.txt
ls -la assets/sfx
```

- [ ] **Step 2: Синтез писка и лая**

`tools/audio/gen_sfx.py`:
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


if __name__ == "__main__":
	write("meow.wav", meow())
	write("bark.wav", bark())
	print("ОК assets/sfx/meow.wav, assets/sfx/bark.wav")
```

В `Makefile`: в `.PHONY` добавить `sfx`, цель:
```make
sfx:
	python3 tools/audio/gen_sfx.py
```
Run: `make sfx && ls -la assets/sfx/*.wav`
Expected: `meow.wav` ≈ 19 КБ, `bark.wav` ≈ 17 КБ. Послушать можно `afplay assets/sfx/meow.wav` (необязательно).

`assets/sfx/README.md`:
```markdown
# Звуки (спек 2.7)

| Файл | Событие | Источник | Лицензия |
|---|---|---|---|
| pickup.ogg | подбор еды | Kenney «Interface Sounds», pluck_001 | CC0 (LICENSE_kenney.txt) |
| eat.ogg | съедание | Kenney «Interface Sounds», drop_002 | CC0 |
| hit.ogg | удар | Kenney «Impact Sounds», impactPunch_medium_000 | CC0 |
| bell.ogg | звонок велосипеда | Kenney «Impact Sounds», impactBell_heavy_000 | CC0 |
| meow.wav | писк кота | синтез `tools/audio/gen_sfx.py` | проект |
| bark.wav | лай | синтез `tools/audio/gen_sfx.py` | проект |

Паки: https://kenney.nl/assets/interface-sounds, https://kenney.nl/assets/impact-sounds.
```

- [ ] **Step 3: Падающие тесты**

`tests/unit/test_sfx.gd`:
```gdscript
extends GutTest

func before_each() -> void:
	Sfx.reset_counters()

func test_all_six_streams_exist() -> void:
	for key in [&"pickup", &"eat", &"hit", &"meow", &"bark", &"bell"]:
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

В `tests/integration/test_dog.gd` добавить (Review Focus 3):
```gdscript
func test_dog_contact_plays_hit_once_and_barks_on_alert() -> void:
	Sfx.reset_counters()
	cat.global_position = Vector3(0, 0.05, -0.2)   # перед носом: собака сразу настораживается и бьёт касанием
	await wait_physics_frames(30)   # полсекунды в зоне собаки
	assert_eq(GameState.hearts, 2)
	assert_eq(Sfx.counts.get(&"hit", 0), 1, "один удар — один звук, не по кадрам")
	assert_eq(Sfx.counts.get(&"meow", 0), 1)
	assert_eq(Sfx.counts.get(&"bark", 0), 1, "лай при входе в ALERT, один раз за настороженность")
```

В `tests/integration/test_main.gd` добавить:
```gdscript
func test_eating_plays_eat_sound() -> void:
	var main := _spawn_main()
	await wait_physics_frames(2)
	Sfx.reset_counters()
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	GameState.eat_all()
	assert_eq(Sfx.last_played, &"eat")
```

- [ ] **Step 4: Запустить, убедиться, что падают**

Run: `make import >/dev/null && $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/unit/test_sfx.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head`
Expected: `Identifier "Sfx" not declared`.

- [ ] **Step 5: Автозагрузка Sfx и подключение**

`scripts/autoload/sfx.gd`:
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
}
const POOL := 6
const VOLUME_DB := {&"bark": -4.0, &"bell": -2.0, &"meow": -3.0}

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

`project.godot`, секция `[autoload]`, после `SaveGame`:
```ini
Sfx="*res://scripts/autoload/sfx.gd"
```

Подключения (по одному вызову на событие):
- `scripts/food/food_pickup.gd`, `_on_body_entered`: внутри `if GameState.pick_up(food):` первой строкой `Sfx.play(&"pickup")`.
- `scripts/food/yarn_pickup.gd`, `_on_body`: после `GameState.take_yarn(key)` добавить `Sfx.play(&"pickup", 0.15)`.
- `scripts/player/cat.gd`, `take_hit`: сразу после `if invulnerable_left > 0.0 or ...: return` добавить `Sfx.play(&"hit")` и `Sfx.play(&"meow", 0.12)` — один вызов на реальный удар (повторные блокирует неуязвимость), и звук есть и без `Main` (тест собаки).
- `scripts/main.gd`: в `_on_food_eaten` первой строкой `Sfx.play(&"eat")`; в `_ready()` подключение звонка заменить на
  ```gdscript
  			c.bell.connect(func() -> void:
  				hud.flash_bell()
  				Sfx.play(&"bell"))
  ```
- `scripts/hazards/dog.gd`: поле `var _last_state: int = ChaseBrain.State.IDLE`; в `_physics_process` после `var s := brain.update(...)`:
  ```gdscript
  	if s == ChaseBrain.State.ALERT and _last_state != ChaseBrain.State.ALERT:
  		Sfx.play(&"bark")
  	_last_state = s
  ```

- [ ] **Step 6: Тесты зелёные**

Run: `make test-godot 2>&1 | tail -4`
Expected: всё зелёное (+4). В `build/gut.log` не должно быть `ERROR:` про аудио (headless использует Dummy-драйвер звука; `play()` без ошибок).

- [ ] **Step 7: Коммит**

```bash
git add assets/sfx tools/audio/gen_sfx.py Makefile project.godot scripts/autoload/sfx.gd tests/unit/test_sfx.gd scripts/main.gd scripts/player/cat.gd scripts/food/food_pickup.gd scripts/food/yarn_pickup.gd scripts/hazards/dog.gd tests/integration/test_dog.gd tests/integration/test_main.gd
git add -A assets/sfx scripts/autoload
git commit -m "Звук: шесть эффектов (Kenney CC0 + синтез писка и лая), автозагрузка Sfx, один вызов на событие

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Камера мышью, прозрачный кот у стены, виньетка

**Files:**
- Create: `assets/shaders/vignette.gdshader`
- Modify: `scripts/player/camera_rig.gd`, `scripts/player/cat.gd`, `scripts/main.gd`, `scenes/main.tscn`, `tests/integration/test_cat_scene.gd`, `tests/integration/test_main.gd`

**Interfaces:**
- Consumes: `Mouse.capture` (задача 1), `CatSkin.apply`.
- Produces: `CameraRig.turn_by_pixels(dx: float)`, `CameraRig.MOUSE_SENS = 0.004`, `CameraRig.FADE_FULL = 0.3`; `Cat.fade: float` (1 = непрозрачен), `Cat.set_fade(alpha: float)`. Контракт: прозрачностью владеет камера (`apply_arm_length` → `set_fade`), скин после перекраски сам восстанавливает текущий `fade`; витрина ставит `fade = 1`.

- [ ] **Step 1: Падающие тесты**

В `tests/integration/test_cat_scene.gd` заменить `test_camera_rig_hides_target_when_too_close` на:
```gdscript
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
	rig.apply_arm_length(3.5)
	assert_almost_eq(cat.fade, 1.0, 0.001, "отошли от стены — непрозрачен")
	assert_eq(_body_material(cat).transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)

func test_skin_change_keeps_fade() -> void:
	# Review Focus 4
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	cat.set_fade(0.4)
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	assert_almost_eq(_body_material(cat).albedo_color.a, 0.4, 0.01, "скин не возвращает непрозрачность")
	GameState.reset()

func test_mouse_turns_camera() -> void:
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	add_child_autofree(rig)
	var before: Basis = rig.yaw_basis()
	rig.turn_by_pixels(100.0)
	assert_false(rig.yaw_basis().is_equal_approx(before), "100 px мыши поворачивают камеру")
```

В `tests/integration/test_main.gd` добавить:
```gdscript
func test_vignette_overlay_exists_and_ignores_mouse() -> void:
	var main := _spawn_main()
	var rect := main.get_node("Vignette/Rect") as ColorRect
	assert_not_null(rect)
	if rect == null:
		return
	assert_true(rect.material is ShaderMaterial)
	assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_lt((main.get_node("Vignette") as CanvasLayer).layer, (main.get_node("Hud") as CanvasLayer).layer + 1, "виньетка под HUD")
```

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/integration/test_cat_scene.gd -gtest=res://tests/integration/test_main.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head`
Expected: падения на `fade`, `turn_by_pixels`, `Vignette/Rect`.

- [ ] **Step 3: Камера**

`scripts/player/camera_rig.gd`: константы
```gdscript
const MOUSE_SENS := 0.004   # рад на пиксель
const FADE_FULL := 0.3      # при такой длине пружины кот почти прозрачен (0,15)
```
Добавить:
```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_by_pixels((event as InputEventMouseMotion).relative.x)


func turn_by_pixels(dx: float) -> void:
	_yaw -= dx * MOUSE_SENS
```
В `_physics_process`, ветка `shop_view`: после `target.visible = true` добавить `_set_target_fade(1.0)`. Заменить `apply_arm_length` и добавить помощник:
```gdscript
func apply_arm_length(length: float) -> void:
	# Камера упёрлась в стену: кот не исчезает, а становится прозрачным (замечание ревью плана 1).
	_set_target_fade(clampf((length - FADE_FULL) / (HIDE_BELOW - FADE_FULL), 0.15, 1.0))


func _set_target_fade(alpha: float) -> void:
	if target.has_method("set_fade"):
		target.call("set_fade", alpha)
	else:
		target.visible = alpha > 0.5
```
Описание класса дополнить: «мышь/правый стик крутят yaw, наклон фиксирован».

- [ ] **Step 4: Кот**

`scripts/player/cat.gd`: поле `var fade := 1.0   # 1 = непрозрачен; значением владеет камера (set_fade), скин его не трогает`. В `_apply_skin` после `CatSkin.apply(_model, skin)` добавить:
```gdscript
		if fade < 1.0:
			_apply_fade()
```
Методы:
```gdscript
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
		_fade_material(m3.material_overlay as StandardMaterial3D)


func _fade_material(mat: StandardMaterial3D) -> void:
	if mat == null:
		return
	mat.albedo_color.a = fade
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if fade >= 0.999 else BaseMaterial3D.TRANSPARENCY_ALPHA
```

- [ ] **Step 5: Виньетка и мышь в Main**

`assets/shaders/vignette.gdshader`:
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

`scenes/main.tscn`: добавить ресурсы и узлы (после `MenuInput`):
```
[ext_resource type="Shader" path="res://assets/shaders/vignette.gdshader" id="9"]

[sub_resource type="ShaderMaterial" id="vignette_mat"]
shader = ExtResource("9")
```
(ext_resource — к остальным ext_resource вверху, sub_resource — после них) и
```
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
HUD остаётся на слое 1 (по умолчанию), виньетка на 0 — под ним.

`scripts/main.gd`: в конце `_ready()` добавить `Mouse.capture(true)`; в `_set_paused(on)` добавить `Mouse.capture(not on)`; в `open_shop()` первой строкой `Mouse.capture(false)`; в `close_shop()` в ветке реального закрытия (после `_cat.input_enabled = true`) добавить `Mouse.capture(true)`.

- [ ] **Step 6: Тесты зелёные**

Run: `make test-godot 2>&1 | tail -4`
Expected: всё зелёное (+4, −1 заменённый). `test_shop_view_makes_cat_visible_even_if_camera_was_pinned` по-прежнему зелёный (витрина ставит и `visible`, и `fade = 1`).

- [ ] **Step 7: Проверить руками и кадром**

Run: `make shot SHOT=build/shot_vignette.png` — края кадра затемнены, центр чистый. `make run` (быстро, 20 с): мышь крутит камеру, Esc показывает курсор и паузу, после «Продолжить» мышь снова захвачена; у стены будки кот становится полупрозрачным, не исчезает.

- [ ] **Step 8: Коммит**

```bash
git add assets/shaders scripts/player/camera_rig.gd scripts/player/cat.gd scripts/main.gd scenes/main.tscn tests/integration/test_cat_scene.gd tests/integration/test_main.gd
git add -A assets/shaders
git commit -m "Камера: поворот мышью, прозрачный кот у стены вместо скрытия, виньетка

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Собака спит, не заходит в будку; плита будки

**Files:**
- Create: `tools/blender/dog_sleep.py`, `tools/blender/tests/test_dog_sleep.py`
- Modify: `tools/blender/dog.py`, `assets/models/dog.glb` (пересборка), `scripts/hazards/chase_brain.gd`, `scripts/hazards/dog.gd`, `scenes/world/yarn_shop.tscn`, `tests/unit/test_chase_brain.gd`, `tests/integration/test_dog.gd`, `tests/integration/test_dog_asset.gd`, `tests/integration/test_yarn_shop.gd`

**Interfaces:**
- Consumes: риг собаки (`Bone` корень, `Bone.001` позвоночник, `head`, цепочки лап `Bone.014/015/016`, `017/018/019`, `008/009/010`, `011/012/013`, цели IK `IKFrontRight/IKFrontLeft/IKBackLeft/IKBackRight`, IK chain 2 на `Bone.015/018/009/012`), `Dog.play_clip(&"sleep")` (уже падает на `idle`, если клипа нет).
- Produces: клип `sleep` в `dog.glb` (48 кадров, 2 с, зациклен в `Dog._ready`); `dog_sleep.apply_pose(arm, breath=0.0)`, `dog_sleep.reset_pose(arm)`, `dog_sleep.make_sleep_action(arm)`; `ChaseBrain.update(delta, sees_cat, cat_hidden, at_home, cat_safe := false)` — в CHASE при `cat_safe` сразу RETURN, в ALERT — IDLE; в `yarn_shop.tscn` коллайдер плиты `Walls/Floor` (2,2 × 0,03 × 2,2, верх на y = 0,03).

- [ ] **Step 1: Падающие Blender-тесты**

`tools/blender/tests/test_dog_sleep.py`:
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

- [ ] **Step 2: Запустить, убедиться, что падает**

Run: `make test-blender 2>&1 | tail -5`
Expected: `ModuleNotFoundError: No module named 'dog_sleep'`.

- [ ] **Step 3: Поза и клип**

`tools/blender/dog_sleep.py`:
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
Если `keyframe_insert` ругается на отсутствие слота (Blender 5: «action has no slot»), перед циклом добавить:
```python
	slot = action.slots.new(id_type="OBJECT", name=arm.name)
	arm.animation_data.action_slot = slot
```

В `tools/blender/dog.py`: `import dog_sleep`; в `build()` после цикла по `ACTION_MAP` (до `split_material_by_height`) добавить `dog_sleep.make_sleep_action(arm)`; в docstring модуля заменить «клипы idle/walk» на «клипы idle/walk и процедурный sleep».

- [ ] **Step 4: Blender-тесты зелёные, пересобрать собаку**

Run: `make test-blender 2>&1 | tail -4`
Expected: `Ran 20 tests ... OK`. Если «корпус опущен» не проходит — `root.location` ушёл не вниз: напечатать `root.head.z` до и после и проверить знак `_local_offset` (локальные оси корневой кости).

Run: `make assets ONLY=dog 2>&1 | grep -E "ОК|ОШИБКА" && $BLENDER -b --python tools/blender/tests/list_glb.py -- assets/models/dog.glb 2>/dev/null | grep -iE "anim|sleep" | head`
Expected: `ОК dog ...`, в списке анимаций `sleep` (если `list_glb.py` принимает другие аргументы — посмотреть его шапку).

- [ ] **Step 5: Падающие Godot-тесты**

`tests/unit/test_chase_brain.gd` добавить:
```gdscript
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

`tests/integration/test_dog.gd`: заменить `test_safe_zone_cancels_chase`:
```gdscript
func test_safe_zone_cancels_chase() -> void:
	# Review Focus 5 плана 3, ужесточено планом 4: «в будку собаки не заходят» — уходит сразу.
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	cat.in_safe_zone = true
	await wait_physics_frames(3)
	assert_eq(dog.brain.state, ChaseBrain.State.RETURN, "в безопасной зоне собака разворачивается сразу")

func test_idle_dog_plays_sleep_clip() -> void:
	cat.global_position = Vector3(0, 0.05, 8)   # за спиной: иначе собака с первого кадра в ALERT
	await wait_physics_frames(3)
	var ap := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("sleep"), "в dog.glb есть клип sleep")
	assert_eq(ap.current_animation, "sleep")
	assert_eq(ap.get_animation("sleep").loop_mode, Animation.LOOP_LINEAR)
```

`tests/integration/test_dog_asset.gd` добавить:
```gdscript
func test_dog_has_sleep_clip_of_two_seconds() -> void:
	var dog := (load("res://assets/models/dog.glb") as PackedScene).instantiate()
	add_child_autofree(dog)
	var ap := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(ap.has_animation("sleep"))
	assert_between(ap.get_animation("sleep").length, 1.8, 2.2)
```

`tests/integration/test_yarn_shop.gd` добавить:
```gdscript
func test_floor_plate_is_solid() -> void:
	await wait_physics_frames(2)
	var space := world.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0, 1, -5), Vector3(0, -1, -5), Layers.WORLD)
	var hit := space.intersect_ray(q)
	assert_false(hit.is_empty(), "луч вниз в будке во что-то упирается")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 0.03, 0.005, "упирается в плиту будки, а не в землю")
```

- [ ] **Step 6: Запустить, убедиться, что падают**

Run: `make import >/dev/null && $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/unit/test_chase_brain.gd -gtest=res://tests/integration/test_dog.gd -gtest=res://tests/integration/test_yarn_shop.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head`
Expected: падения: лишний аргумент `update`, RETURN не наступил, плита 0.0 вместо 0.03. (`sleep` уже зелёный после пересборки — это ожидаемо: тест закрепляет ассет.)

- [ ] **Step 7: Код**

`scripts/hazards/chase_brain.gd`, `update`:
```gdscript
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
				if _t >= ALERT_TIME:
					state = State.CHASE
					_t = 0.0
					_hidden_t = 0.0
		State.CHASE:
			if cat_safe:
				state = State.RETURN   # «в будку собаки не заходят» (спек 3.5): уходит сразу, не через 2 с
			else:
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

`scripts/hazards/dog.gd`, `_physics_process`: строку `var s := brain.update(delta, sees_cat(), cat_hidden, at_home)` заменить на
```gdscript
	var cat_safe: bool = c != null and bool(c.get("in_safe_zone"))
	var s := brain.update(delta, sees_cat(), cat_hidden, at_home, cat_safe)
```

`scenes/world/yarn_shop.tscn`: добавить
```
[sub_resource type="BoxShape3D" id="floor"]
size = Vector3(2.2, 0.03, 2.2)
```
и узел после `Right`:
```
[node name="Floor" type="CollisionShape3D" parent="Walls"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.015, 0)
shape = SubResource("floor")
```
В `tools/blender/gen/yarn_shop.py` комментарий «тонкая плита без коллайдера» заменить на «плита; коллайдер в yarn_shop.tscn (Walls/Floor)».

- [ ] **Step 8: Тесты зелёные**

Run: `make test-godot 2>&1 | tail -4`
Expected: всё зелёное (+4).

- [ ] **Step 9: Коммит**

```bash
git add tools/blender/dog_sleep.py tools/blender/dog.py tools/blender/gen/yarn_shop.py tools/blender/tests/test_dog_sleep.py assets/models/dog.glb assets/models/dog.glb.import scripts/hazards/chase_brain.gd scripts/hazards/dog.gd scenes/world/yarn_shop.tscn tests/unit/test_chase_brain.gd tests/integration/test_dog.gd tests/integration/test_dog_asset.gd tests/integration/test_yarn_shop.gd
git commit -m "Собака: процедурный клип «спит», уходит сразу при коте в будке; плита будки с коллайдером

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Дыры мира: kill-plane, еда при обмороке, высота рассыпанной еды, сброс без записи, B на геймпаде

**Files:**
- Modify: `scripts/main.gd`, `scripts/world/spill_spawner.gd`, `scripts/ui/menu_input.gd`, `tests/integration/test_main.gd`, `tests/integration/test_menus.gd`, `tests/integration/test_hit.gd`

**Interfaces:**
- Produces: `Main.KILL_Y = -5.0`, `Main.fall_respawn()`; `SpillSpawner.spill_around(pos, foods)` кладёт еду на `pos.y`; `MenuInput` реагирует на `ui_cancel` при открытом магазине/альбоме; `Main.reset_progress()` не оставляет файла сохранения.

- [ ] **Step 1: Падающие тесты**

`tests/integration/test_main.gd` добавить:
```gdscript
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

`tests/integration/test_hit.gd` добавить (посмотреть `before_each` файла: там есть `SpillSpawner` или `Main`; если нет — создать `SpillSpawner.new()` в тесте):
```gdscript
func test_spilled_food_lands_at_cat_height() -> void:
	var spawner := SpillSpawner.new()
	add_child_autofree(spawner)
	var out: Array = spawner.spill_around(Vector3(-11.3, 1.0, -9.0), [FoodCatalog.get_by_id(&"cookie")])
	assert_eq(out.size(), 1)
	assert_almost_eq((out[0] as Node3D).global_position.y, 1.0, 0.001, "еда с балкона не уходит под площадку")
```

`tests/integration/test_menus.gd`: в `test_reset_progress_clears_save_and_state` блок `if FileAccess.file_exists(...)` заменить на
```gdscript
	assert_false(FileAccess.file_exists(SaveGame.path), "после сброса файла сохранения нет (reset() не должен тут же писать нули)")
```
и добавить:
```gdscript
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
```

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/integration/test_main.gd -gtest=res://tests/integration/test_menus.gd -gtest=res://tests/integration/test_hit.gd 2>&1 | grep -E "passed|failed|FAIL|SCRIPT ERROR" | head -12`
Expected: kill-plane — кот далеко от будки; обморок — 1 рассыпанная еда; высота — 0.0; сброс — файл есть; ui_cancel — магазин открыт.

- [ ] **Step 3: Код**

`scripts/main.gd`:
```gdscript
const KILL_Y := -5.0   # ниже этого кот считается упавшим за край мира


func _physics_process(_delta: float) -> void:
	if _cat and _cat.global_position.y < KILL_Y:
		fall_respawn()


func fall_respawn() -> void:
	## Падение за край мира: назад к будке без потери сердечка; еда из зубов теряется.
	GameState.spill()
	_cat.teleport(respawn_position())
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
```
`_on_cat_hit`: после всплеска и звуков заменить проверку:
```gdscript
	if spilled.is_empty() or GameState.hearts == 0:
		return   # при обмороке еда потеряна (спек 3.2), рассыпать нечего
	_spill.spill_around(_cat.global_position, spilled)
```
`reset_progress`:
```gdscript
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

`scripts/world/spill_spawner.gd`: `p.global_position = Vector3(pos.x + cos(ang) * r, pos.y, pos.z + sin(ang) * r)`; комментарий класса дополнить «на высоте кота (балкон)».

`scripts/ui/menu_input.gd`, `_process`:
```gdscript
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_main.call("on_back_pressed")
	elif Input.is_action_just_pressed("ui_cancel") and _menu_open():
		_main.call("on_back_pressed")   # B на геймпаде закрывает магазин и альбом
	elif Input.is_action_just_pressed("album"):
		_main.call("on_album_pressed")
	elif Input.is_action_just_pressed("eat"):
		_main.call("on_interact_pressed")


func _menu_open() -> bool:
	return bool(_main.get("shop_menu").is_open) or bool(_main.get("album_menu").is_open)
```
(Esc входит и в `pause`, и в `ui_cancel`; первая ветка побеждает, двойного срабатывания нет.)

- [ ] **Step 4: Тесты зелёные**

Run: `make test-godot 2>&1 | tail -4`
Expected: всё зелёное (+5). Если `test_kill_plane_ignores_balcony_and_tables` падает на столе кафе — проверить высоту стола в `yard.json` (точка спавна `[0, 0.75, 17]`) и поставить кота на 0,2 выше неё.

- [ ] **Step 5: Коммит**

```bash
git add scripts/main.gd scripts/world/spill_spawner.gd scripts/ui/menu_input.gd tests/integration/test_main.gd tests/integration/test_menus.gd tests/integration/test_hit.gd
git commit -m "Мир: kill-plane с возвратом к будке, еда при обмороке теряется, рассыпанная еда на высоте кота, сброс без записи, B закрывает меню

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Плейтест баланса (оценка времени до арки)

**Files:**
- Create: `tests/unit/test_balance.gd`
- Modify (только если оценка > 180 с): `scripts/autoload/game_state.gd` (`SATIETY_GATE`), `data/layout/yard.json` (`gates[0].satiety`), тесты HUD/ворот, где зашито 10.

**Interfaces:**
- Consumes: `WorldBuilder.load_layout(path) -> Dictionary`, `WorldBuilder._v3(arr) -> Vector3`, `Rarity.WEIGHTS/SATIETY`, `CatMotion.WALK_SPEED = 2.0`, `GameState.MOUTH_CAPACITY = 3`, `GameState.SATIETY_GATE`.
- Produces: `test_balance.estimate_seconds(layout, target) -> float` — модель спека 3.3: шаг 2 м/с, 0,6 с на подбор, после каждых трёх подборов — к ближайшему укрытию и 2 с на съедание; только точки двора (z < 10,5).

- [ ] **Step 1: Тест-оценка**

`tests/unit/test_balance.gd`:
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

- [ ] **Step 2: Запустить**

Run: `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gtest=res://tests/unit/test_balance.gd 2>&1 | grep -E "оценка|passed|failed|FAIL|SCRIPT ERROR"`
Expected: напечатана оценка (ожидается 60–120 с) и `2 passed`. Это тест, который должен пройти сразу: он закрепляет правило спека, а не новую логику. Если оценка ≥ 180 с или сытости не хватает — выполнить правило спека: `SATIETY_GATE := 6`, в `yard.json` у ворот `"satiety": 6`, поправить тесты с числом 10 (`test_hud.gd`, `test_gate.gd`, `test_game_state.gd`), записать Ruling.

- [ ] **Step 3: Коммит**

```bash
git add tests/unit/test_balance.gd
git commit -m "Баланс: оценка времени до арки по раскладке двора как тест (спек 3.3)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Экспорт mac-билда

**Files:**
- Create: `export_presets.cfg`
- Modify: `Makefile` (цели `templates`, `export`), `.gitignore` (без изменений: `build/` уже игнорируется)

**Interfaces:**
- Produces: `make templates` ставит шаблоны 4.7.2 в `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (скачивает 1,2 ГБ один раз в `build/templates.tpz`); `make export` → `build/SnackRun.zip` с `SnackRun.app` внутри.

- [ ] **Step 1: Шаблоны экспорта**

В `Makefile`: в `.PHONY` добавить `templates export`; переменные и цели:
```make
TEMPLATES_DIR := $(HOME)/Library/Application Support/Godot/export_templates/4.7.2.stable
TPZ_URL := https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz

templates:
	mkdir -p "$(TEMPLATES_DIR)" build
	[ -f build/templates.tpz ] || curl -L -C - -o build/templates.tpz "$(TPZ_URL)"
	unzip -o -j build/templates.tpz 'templates/macos.zip' 'templates/version.txt' -d "$(TEMPLATES_DIR)"
	ls -la "$(TEMPLATES_DIR)"

export: import
	mkdir -p build
	$(GODOT) --headless --path . --export-release "macOS" build/SnackRun.zip
	ls -la build/SnackRun.zip && unzip -l build/SnackRun.zip | head -5
```
Run: `make templates 2>&1 | tail -4` (скачивание 1,2 ГБ: несколько минут; `curl -C -` докачивает при обрыве).
Expected: в папке `macos.zip` (≈ 150 МБ) и `version.txt` с `4.7.2.stable`.

- [ ] **Step 2: Пресет**

`export_presets.cfg` (Godot сам дополнит недостающие ключи значениями по умолчанию):
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
`codesign/codesign=1` — встроенная ad-hoc подпись без сертификата (на Apple Silicon неподписанный бинарник не запускается). Если экспорт ругается на подпись — поставить `0` и записать Ruling.

- [ ] **Step 3: Экспорт**

Run: `make export 2>&1 | tail -8`
Expected: без строк `ERROR`, `build/SnackRun.zip` > 50 МБ, в листинге `SnackRun.app/Contents/MacOS/SnackRun`. Проверка запуска без висящего окна: `rm -rf build/SnackRun.app && unzip -q -o build/SnackRun.zip -d build && build/SnackRun.app/Contents/MacOS/SnackRun --quit-after 60; echo $?` — код 0 доказывает, что бинарник подписан и стартует.

- [ ] **Step 4: Коммит**

```bash
git add export_presets.cfg Makefile
git commit -m "Экспорт mac-билда: пресет macOS (universal, ad-hoc подпись), make templates / make export

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Документация, replay, дорожная карта, CLAUDE.md

**Files:**
- Modify: `docs/replay/02-procedure.md`, `docs/replay/README.md`, `tools/replay/build_files_md.py`, `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`, `CLAUDE.md`; регенерировать `docs/replay/03-files.md`.

- [ ] **Step 1: Приложение файлов**

В `tools/replay/build_files_md.py`: убрать `"assets"` из `EXCLUDE_DIRS`; в `INCLUDE` добавить
```python
    "export_presets.cfg", "tools/audio/*.py", "assets/ui/*.tres", "assets/shaders/*.gdshader",
    "assets/sfx/README.md", "assets/fonts/OFL.txt",
```
и в `LANG`: `".cfg": "ini", ".tres": "", ".gdshader": "glsl", ".txt": ""`. Двоичные файлы (`.ttf/.ogg/.wav/.glb`) в приложение не входят — в процедуре описано, откуда их взять.
Run: `make replay`
Expected: `docs/replay/03-files.md: N файлов` (N ≈ 165).

- [ ] **Step 2: Процедура плана 4**

В `docs/replay/02-procedure.md` перед разделом «Известные грабли» добавить раздел «План 4. Полировка под ролик» по образцу разделов планов 2–3: ветка `plan-4-polish`, задачи 1–10 с командами (скачивание шрифта и паков Kenney, `make sfx`, `make assets ONLY=cat`/`ONLY=dog`, `make templates`, `make export`), контрольные точки (число тестов после каждой задачи, `make shot` после задач 1, 2, 5), ревью и исправления. В «Известные грабли» добавить новые (что бы ни встретилось при исполнении: слоты action в Blender 5, IK при позе, импорт шрифта, headless-аудио, экспорт). В `docs/replay/README.md` обновить «Что считается успехом» (число тестов, `make export`).

- [ ] **Step 3: Дорожная карта и памятка**

В дорожной карте: заголовок «План 4 ... — ВЫПОЛНЕН 2026-10-08», короткий «Результат», в списке «Отложенные мелочи» пометить закрытые пункты («✓ план 4») и оставить открытые (оса и сладкая еда, обход препятствий собакой, баки недостижимы прыжком, коробка-укрытие, скины как наборы цветов, повторный Toon во дворе, респавн еды 30–90 с, лицензия весов UniMate). В `CLAUDE.md`: раздел «Грабли плана 4», статус «Планы 1–4 выполнены», команды `make sfx/templates/export`, структура (новые файлы).

- [ ] **Step 4: Полный прогон и коммит**

Run: `rm -rf .godot && make test 2>&1 | tail -4`
Expected: Blender `Ran 20 tests ... OK`, GUT все зелёные.
```bash
git add docs/replay tools/replay/build_files_md.py docs/superpowers/plans/2026-10-07-snack-run-roadmap.md CLAUDE.md
git commit -m "Документация плана 4: процедура воспроизведения, приложение файлов, дорожная карта, CLAUDE.md

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## Самопроверка плана

- **Покрытие спека/дорожной карты:** эмоции глаз (задача 2), пропорции лап (сознательный отказ, записан), частицы (3), 6 звуков (4), виньетка (5), mac-билд (9), плейтест баланса (8), спящая собака (6), UI спека 2.6 (1). Отложенные мелочи: закрываются kill-plane, еда при обмороке, высота рассыпанной еды, сброс прогресса, B на геймпаде, будка (собака, плита), камера (мышь, прозрачность), заставка, счётчик клубочков; остальные остаются в дорожной карте.
- **Типы и имена:** `CatFace.update(delta: float, stunned: bool) -> StringName`; `Cat.face`, `Cat.threaten()`, `Cat.cheer()`, `Cat.set_fade(alpha)`, `Cat.fade`; `CameraRig.turn_by_pixels(dx)`; `Effects.burst(parent, pos, color, amount, size, speed)`; `Sfx.play(name, pitch_jitter)`, `Sfx.counts`, `Sfx.reset_counters()`; `ChaseBrain.update(..., cat_safe := false)`; `Main.fall_respawn()`, `Main.KILL_Y`; `Mouse.capture(on)`; `Title.switch_scenes/new_game/continue_game/has_save`. Имена узлов HUD `%Hearts %Satiety %SatietyLabel %Yarn %Mouth %Goal %Bell %BellPanel`; мешей глаз `eyes_normal/scared/happy/dizzy`.
- **Review Focus → тесты:** 1 → `test_black_skin_keeps_eye_colors` (задача 2); 2 → `test_expression_priority_and_timers` (2); 3 → `test_dog_contact_plays_hit_once_and_barks_on_alert` (4); 4 → `test_skin_change_keeps_fade`, `test_camera_rig_fades_target_instead_of_hiding` (5); 5 → `test_kill_plane_ignores_balcony_and_tables` (7).
- **Зависимости между задачами:** 1 даёт `Mouse` для 5; 2 даёт `cheer()` для клубочка в 3 и `threaten()` для собаки; 4 использует `_on_food_eaten/_on_cat_hit` из 3; 7 правит `_on_cat_hit` из 3–4 (показан целиком фрагмент проверки). Порядок задач обязателен.

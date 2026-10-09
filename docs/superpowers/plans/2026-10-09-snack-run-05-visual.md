# Snack Run, план 5: Визуальная полировка

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Привести кадр к референсу: круглый пушистый кот с глазами в глазницах, яркий день с мягкими тенями, живые VFX, зелень и декали, иконки и арты из сгенерированных картинок.

**Architecture:** Кот облагораживается в Blender-пайплайне (сглаживание, новые наборы глаз, пучки/усы/ошейник отдельными скиновыми мешами) и модификаторами скелета в Godot (короткие лапы, хвост); обводка персонажей становится шейдером с шумом, тун-материал получает rim; свет и пост живут в `lighting.tscn`; VFX — статические фабрики в `Effects` и реакции на события в `Cat`/`Main`; 2D-картинки генерирует `tools/images/gen.py` по манифесту и они подключаются как текстуры UI, неба и декалей.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript, GUT 9.7.1, Blender 5.2.2 (bpy/bmesh), glTF, Python 3 (stdlib `urllib`), OpenAI Images API (`gpt-image-2.5-sunburst`/`-flare`), make.

**Spec:** `docs/superpowers/specs/2026-10-07-snack-run-design.md`, раздел 2.8 (все числа оттуда), плюс 2.3, 2.4. Решения владельца: `docs/replay/01-decisions.md` №15–19. Образцы: планы 1–4. Памятка: `CLAUDE.md`.

## Global Constraints

- Godot 4.7.2, GDScript, Forward+; `GODOT=/Applications/Godot.app/Contents/MacOS/Godot`, `BLENDER=/Applications/Blender.app/Contents/MacOS/Blender`.
- 3D-ассеты только скриптами Blender; 2D-картинки — только `tools/images/gen.py` по `manifest.json`, ключ только из `OPENAI_API_KEY` (в репозиторий и логи не попадает). Готовые PNG коммитятся вместе с `*.import`.
- Бюджеты: кот ≤ 6000 треугольников (спек 2.8), собака ≤ 2500, пропс ≤ 800; палитра `tools/blender/palette.py` (+ `eye_green #6FA04A`).
- Клипы кота и собаки не меняются; всё новое движение — модификаторы скелета и твины поверх клипов.
- Обводка персонажей 0,006 м, еды 0,004 м (в метрах, пересчёт под масштаб узла сохраняется); у глаз обводки нет.
- Тесты: GUT (`make test-godot`, падает на `SCRIPT ERROR` и `^ERROR:` кроме известного шума), Blender (`make test-blender`); одиночный прогон `-gselect=<имя>`; в тестах с котом нужен пол; позиции узлов ставить до `add_child`; `Input.mouse_mode` только через `Mouse.capture`.
- Русские тексты, английские идентификаторы, коммиты с `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Скриншоты для проверки глазами: `make shot SHOT=build/x.png` (сцена целиком), служебные рендеры `-s` без автозагрузок (`cat.glb`, не `cat.tscn`) — камере задавать `transform`.

## Отклонения от спека, принятые заранее

- Hit-stop (замедление времени при ударе) не делаем: `Engine.time_scale` ломает таймеры тестов и паузы; вспышка + тряска камеры достаточно.
- Внутренняя сторона ушей у модели Quaternius уже коралловая (`sr_coral`), отдельные меши не нужны.
- Сердечки при съедании — спрайты сгенерированной иконки на `QuadMesh` в `CPUParticles3D` (единственное место, где 2D-картинка попадает в 3D помимо неба и декалей).
- Иконки сердечка и клубочка в HUD остаются текстовыми («♥», «◎»): их тесты и вид уже устоялись; иконки еды заменяют текст в слотах «в зубах» (текст остаётся в скрытом `Label` для тестов).
- Плющ и трава — геометрия Blender (квады и конусы), не частицы; декали — квады с текстурой, не `Decal`-узлы (они не работают с тун-материалами без текстур).

## Review Focus

1. Переодевание скина после вспышки удара: вспышка восстанавливает цвета скина, а не базовые (чёрный кот не становится рыжим на 0,1 с и после). Тест в задаче 7.
2. Прозрачность у стены теперь трогает и шейдерную обводку: при `fade < 1` обводка полупрозрачна, при 1 — непрозрачна; смена скина не сбрасывает. Тест в задаче 5.
3. Короткие лапы: лапы стоят на земле (кот не висит и не тонет) во всех клипах — проверяется по позе стопы в `skeleton_updated` относительно варианта без модификатора. Тест в задаче 4.
4. Моргание не перебивает испуг/оглушение/довольство и не «залипает» закрытым (0,12 с). Тест в задаче 3.
5. Манифест картинок покрывает все id еды из `FoodCatalog`, и каждый файл манифеста существует в репозитории (при воспроизведении без ключа игра всё равно собирается: отсутствующая иконка — пустой слот, не ошибка). Тест в задаче 1.

---

## Структура файлов

```
tools/images/gen.py, manifest.json           # генерация картинок; make images
assets/images/ui/food_<id>.png (8), heart.png
assets/images/title/title_bg.png
assets/images/world/clouds.png, poster_{cafe,cat,paws}.png, decal_{manhole,cracks,leaves}.png
tools/blender/cat.py (+subdivision, smooth)  cat_eyes.py (v2 + blink)  cat_fluff.py (пучки, усы, ошейник)
tools/blender/palette.py (+eye_green)        gen/grass.py  gen/ivy.py
tools/blender/tests/test_cat_eyes.py (±)  test_cat_fluff.py  test_lib.py (19 цветов)
assets/shaders/outline_fur.gdshader
scripts/visual/toon.gd (rim, шейдерная обводка)  effects.gd (+dust, hearts, sparkles, zzz, leaves)
scripts/player/cat.gd (+сквош, пыль, вспышка)  cat_face.gd (+blink)  leg_scaler.gd  tail_wiggle.gd  camera_rig.gd (+shake)
scripts/world/lighting.gd + scenes/world/lighting.tscn (свет, небо, пост)  world_builder.gd (+decals, water)
scripts/food/food_def.gd (+icon)  food_pickup.gd (+искры)  scripts/hazards/wasp.gd, cyclist.gd, dog.gd (+шлейф, пыль, zzz)
scripts/ui/hud.gd (+иконки слотов)  album_menu.gd (+иконки)  scenes/ui/title.tscn (+фон)
data/layout/yard.json (+decals, water, кусты, трава, плющ)
tests/unit/test_images.gd  test_toon.gd (±)  tests/integration/test_cat_scene.gd (+)  test_cat_asset.gd (±)  test_lighting.gd  test_effects.gd (+)  test_world_builder.gd (+)  test_hud.gd (+)  test_menus.gd (+)  test_food.gd (+)
```

Порядок: картинки (видны сразу в UI) → кот (сглаживание, пучки) → глаза → лапы и хвост → тун v2 → свет → VFX → мир → документация. Кадр для проверки глазами после задач 2, 3, 5, 6, 8.

---

### Task 1: Генерация картинок и их подключение (иконки еды, заставка, заготовки для неба и декалей)

**Files:**
- Create: `tools/images/gen.py`, `tools/images/manifest.json`, `assets/images/**`, `tests/unit/test_images.gd`
- Modify: `Makefile`, `scripts/food/food_def.gd`, `scripts/ui/hud.gd`, `scripts/ui/album_menu.gd`, `scenes/ui/title.tscn`, `tests/integration/test_hud.gd`, `tests/integration/test_menus.gd`

**Interfaces:**
- Produces: `make images [FORCE=1]`; `FoodDef.icon_path() -> String` (`res://assets/images/ui/food_<id>.png`) и `FoodDef.icon() -> Texture2D` (null, если файла нет); слоты HUD: `PanelContainer` → `HBoxContainer` → `TextureRect "Icon"` (48×48) + `Label "Name"` (скрыт); карточка альбома: `TextureRect "Icon"` (96×96) между `Rarity` и `Name`, у закрытой `self_modulate = Color(0.2, 0.2, 0.25)`; заставка: `TextureRect "Background"` (`assets/images/title/title_bg.png`, `EXPAND_IGNORE_SIZE`, `STRETCH_KEEP_ASPECT_COVERED`); файлы `assets/images/world/clouds.png`, `poster_*.png`, `decal_*.png` для задач 6 и 8; `assets/images/ui/heart.png` для задачи 7.

- [ ] **Step 1: Падающий тест манифеста**

`tests/unit/test_images.gd`:
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

- [ ] **Step 2: Запустить, убедиться, что падает**

Run: `make import >/dev/null; $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gselect=test_images 2>&1 | grep -E "passed|Failed|SCRIPT ERROR" | head -3`
Expected: `SCRIPT ERROR` — у `FoodDef` нет `icon()`; файла манифеста нет.

- [ ] **Step 3: Скрипт генерации и манифест**

`tools/images/gen.py`:
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


def main(argv):
	force = "--force" in argv
	key = os.environ.get("OPENAI_API_KEY", "")
	entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["images"]
	todo = [e for e in entries if force or not (ROOT / e["file"]).exists()]
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

`tools/images/manifest.json` (промпты по-английски: модель так точнее держит стиль; описание по-русски в `note`):
```json
{
  "style_note": "Все промпты дополняются STYLE из gen.py: плоский мультяшный стиль, графитовая обводка, пастель.",
  "images": [
    {"file": "assets/images/ui/food_sausage.png", "note": "иконка сосиски", "background": "transparent",
     "prompt": "Game icon of a single plump sausage with a small bite mark, warm red-brown (#BD4045) with lighter highlights, centered, transparent background"},
    {"file": "assets/images/ui/food_cookie.png", "note": "иконка печенья", "background": "transparent",
     "prompt": "Game icon of a round chocolate chip cookie, sandy (#D3AB87) with dark chips, centered, transparent background"},
    {"file": "assets/images/ui/food_pizza.png", "note": "иконка пиццы", "background": "transparent",
     "prompt": "Game icon of a pizza slice with pepperoni, crust #D3AB87, cheese #FABE32, pepperoni #BD4045, centered, transparent background"},
    {"file": "assets/images/ui/food_hotdog.png", "note": "иконка хот-дога", "background": "transparent",
     "prompt": "Game icon of a hot dog in a bun with a mustard zigzag, bun #D3AB87, sausage #BD4045, mustard #FABE32, centered, transparent background"},
    {"file": "assets/images/ui/food_croissant.png", "note": "иконка круассана", "background": "transparent",
     "prompt": "Game icon of a golden croissant, #FAAE45 with #D3AB87 shading, centered, transparent background"},
    {"file": "assets/images/ui/food_fish.png", "note": "иконка рыбы", "background": "transparent",
     "prompt": "Game icon of a whole cartoon fish, silver-blue (#2F9CCF) with a cute eye, centered, transparent background"},
    {"file": "assets/images/ui/food_donut.png", "note": "иконка пончика", "background": "transparent",
     "prompt": "Game icon of a ring donut with pink (#F57485) glaze and colorful sprinkles, centered, transparent background"},
    {"file": "assets/images/ui/food_ice_cream.png", "note": "иконка мороженого", "background": "transparent",
     "prompt": "Game icon of a soft-serve ice cream cone, cream (#FCD3A1) swirl and sandy (#D3AB87) waffle cone, centered, transparent background"},
    {"file": "assets/images/ui/heart.png", "note": "сердечко для частиц", "background": "transparent",
     "prompt": "Game icon of a simple glossy heart, coral pink (#F57485) with a white highlight, centered, transparent background"},
    {"file": "assets/images/title/title_bg.png", "note": "фон заставки", "size": "1536x1024", "model": "gpt-image-2.5-sunburst", "quality": "high",
     "prompt": "Wide illustration for a cozy game title screen: a fluffy orange kitten with big green eyes and a white chest crouches on a sunny city sidewalk next to a pizza slice, green bins and a bench behind, blue sky with cumulus clouds, warm midday light, soft shadows, lots of greenery. Leave the center-bottom area calm and uncluttered for menu buttons. No text."},
    {"file": "assets/images/world/clouds.png", "note": "слой облаков для неба (sky_cover)", "size": "1536x1024", "background": "transparent", "model": "gpt-image-2.5-sunburst",
     "prompt": "Seamless wide panoramic layer of scattered fluffy white cumulus clouds, cartoon style with soft shading, clouds only, lots of empty space between them, transparent background, suitable for tiling across a sky dome"},
    {"file": "assets/images/world/poster_cafe.png", "note": "плакат кафе", "model": "gpt-image-2.5-sunburst",
     "prompt": "Square chalkboard poster for a street cafe with the text 'Good Food Better Days' in friendly hand lettering, a small paw print and a croissant doodle, dark board with chalk colors"},
    {"file": "assets/images/world/poster_cat.png", "note": "плакат с котом", "model": "gpt-image-2.5-sunburst",
     "prompt": "Square street poster of a cute cartoon cat face silhouette in white on a dark green (#458B59) background, slightly weathered paper look, no text"},
    {"file": "assets/images/world/poster_paws.png", "note": "плакат с лапками",
     "prompt": "Square playful poster with a trail of cat paw prints in coral pink (#F57485) on cream (#FCD3A1) paper, no text"},
    {"file": "assets/images/world/decal_manhole.png", "note": "люк на асфальт", "background": "transparent",
     "prompt": "Top-down round cast iron manhole cover with a simple grid pattern, dark grey (#5A5C6B) with lighter rim, centered, transparent background"},
    {"file": "assets/images/world/decal_cracks.png", "note": "трещины на асфальте", "background": "transparent",
     "prompt": "Top-down subtle asphalt cracks and a faint dark stain, thin graphite lines, mostly empty, transparent background"},
    {"file": "assets/images/world/decal_leaves.png", "note": "опавшие листья", "background": "transparent",
     "prompt": "Top-down scatter of a few small fallen leaves in olive (#A9B087), leaf green (#458B59) and sand (#D3AB87), transparent background"}
  ]
}
```

В `Makefile`: в `.PHONY` добавить `images`, цель:
```make
images:
	python3 tools/images/gen.py $(if $(FORCE),--force,)
```
Run: `make images 2>&1 | tail -17`
Expected: 17 строк `ОК …` (≈ 500 токенов на иконку, 3–6 тыс. на крупные), 2–4 минуты. Посмотреть каждую через Read: иконки на прозрачном фоне с обводкой, облака с прозрачностью (если фон у облаков непрозрачный — перегенерировать с `FORCE=1` один файл, временно оставив в манифесте только его, и вернуть манифест). `make import` после генерации.

- [ ] **Step 4: FoodDef.icon, HUD, альбом, заставка**

`scripts/food/food_def.gd` добавить:
```gdscript
func icon_path() -> String:
	return "res://assets/images/ui/food_%s.png" % id


func icon() -> Texture2D:
	## Иконка из сгенерированных картинок; без файла — null (пустой слот, не ошибка).
	var path := icon_path()
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
```

`scripts/ui/hud.gd`, `_ready()` — цикл слотов заменить:
```gdscript
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
		label.visible = false   # текст остаётся для тестов и подписи, в кадре — иконка
		row.add_child(label)
		panel.add_child(row)
		_mouth.add_child(panel)
```
`mouth_names()` и `_on_mouth` ищут `Name` через `find_child("Name", true, false)`; в `_on_mouth` добавить `(panels[i].find_child("Icon", true, false) as TextureRect).texture = items[i].icon() if i < items.size() else null`.

`scripts/ui/album_menu.gd`, `_make_card`: после `card.add_child(strip)`:
```gdscript
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = f.icon()
	card.add_child(icon)
```
и в `refresh()`: `(card.get_node("Icon") as TextureRect).self_modulate = Color.WHITE if n > 0 else Color(0.2, 0.2, 0.25)` (закрытая карточка — тёмный силуэт, спек 2.6).

`scenes/ui/title.tscn`: узел `Background` (ColorRect) заменить на
```
[ext_resource type="Texture2D" path="res://assets/images/title/title_bg.png" id="2"]

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
```
(ext_resource к остальным вверху). Кнопки — внутри `PanelContainer` поверх: обернуть `VBox` в `PanelContainer "Panel"` с теми же якорями (центр, 360×300), чтобы текст читался на арте.

Тесты: в `test_hud.gd` добавить
```gdscript
func test_mouth_slot_shows_food_icon() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))
	var icon := hud.get_node("%Mouth").get_child(0).find_child("Icon", true, false) as TextureRect
	assert_not_null(icon.texture, "в слоте иконка пиццы")
	assert_eq(icon.texture.resource_path, "res://assets/images/ui/food_pizza.png")
	GameState.eat_all()
	assert_null((hud.get_node("%Mouth").get_child(0).find_child("Icon", true, false) as TextureRect).texture, "пустой слот без иконки")
```
в `test_menus.gd` (в `test_album_shows_cards_locked_and_unlocked`) после проверки `donut.modulate.a`:
```gdscript
	assert_not_null((pizza.get_node("Icon") as TextureRect).texture, "у карточки иконка")
	assert_lt((donut.get_node("Icon") as TextureRect).self_modulate.r, 0.5, "закрытая карточка — тёмный силуэт")
```
и в `test_title_offers_continue_only_with_save`: `assert_not_null((title.get_node("Background") as TextureRect).texture, "фон заставки — арт")`.

- [ ] **Step 5: Тесты зелёные, кадр**

Run: `make test-godot 2>&1 | tail -3`
Expected: всё зелёное (+4). `make shot SHOT=build/shot_icons.png` после `GameState.pick_up` не сделать из CLI — проверить альбом/слоты в `make run` (подобрать еду, Tab): иконки видны. Заставку посмотреть: `$GODOT --path . --resolution 1280x720 res://scenes/ui/title.tscn ++ --screenshot=build/shot_title.png`.

- [ ] **Step 6: Коммит**

```bash
git add tools/images Makefile assets/images scripts/food/food_def.gd scripts/ui/hud.gd scripts/ui/album_menu.gd scenes/ui/title.tscn tests/unit/test_images.gd tests/integration/test_hud.gd tests/integration/test_menus.gd
git add -A assets/images tests/unit
git commit -m "Картинки: генерация по манифесту (OpenAI gpt-image-2.5), иконки еды в HUD и альбоме, арт заставки

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Кот — сглаживание, пучки шерсти, усы, ошейник

**Files:**
- Create: `tools/blender/cat_fluff.py`, `tools/blender/tests/test_cat_fluff.py`
- Modify: `tools/blender/cat.py`, `tools/blender/cat_eyes.py` (общие помощники), `tools/blender/gen/cat.py` (`max_tris 6000`), `tools/blender/tests/test_cat_eyes.py` (бюджет 6000), `scripts/player/cat.gd` (обводка не на усах), `assets/models/cat.glb`

**Interfaces:**
- Consumes: `cat_eyes._join(name, objs)`, `cat_eyes._attach(obj, arm, bone)` (параметр кости появляется здесь), `cat_eyes.group_bbox(mesh, bone) -> (lo, hi)` (обобщение `head_bbox`).
- Produces: в `cat.glb` меши `fluff_cheeks` (кость `head`), `fluff_chest` (`Bone.001`), `fluff_tail` (`Bone.007`), `whiskers` (`head`), `collar` (`Bone.002`); у меша `cat` модификатор `Subdivision` уровня 1 и smooth-шейдинг; `cat_fluff.build_fluff(arm, mesh) -> list[Object]`.

- [ ] **Step 1: Падающий Blender-тест**

`tools/blender/tests/test_cat_fluff.py`:
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
        self.assertTrue(lo.z - 0.02 < cz < hi.z + 0.02, "ошейник на высоте шеи")
        mats = {m.name for m in self.parts["collar"].data.materials}
        self.assertEqual(mats, {"sr_coral", "sr_rarity_legendary"}, "коралловый ремешок и золотой жетон")

    def test_budget(self):
        self.assertEqual(lib.check_asset(self.objs, max_tris=6000, max_dim=0.6), [])
```
В `tools/blender/tests/test_cat_eyes.py` в `test_budget` заменить `max_tris=2500` на `6000`.

- [ ] **Step 2: Запустить, убедиться, что падает**

Run: `make test-blender 2>&1 | grep -E "ModuleNotFound|^Ran|^OK|FAILED" | head -3`
Expected: `ModuleNotFoundError: No module named 'cat_fluff'`.

- [ ] **Step 3: Помощники в cat_eyes, модуль пучков, сглаживание в cat.py**

В `tools/blender/cat_eyes.py`:
```python
def group_bbox(mesh, bone):
	"""Мировой bbox вершин, привязанных к кости bone весом > 0,5."""
	bpy.context.view_layer.update()
	gi = mesh.vertex_groups[bone].index
	pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices
	       if any(g.group == gi and g.weight > 0.5 for g in v.groups)]
	lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
	hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
	return lo, hi


def head_bbox(mesh):
	return group_bbox(mesh, HEAD_GROUP)
```
(старое тело `head_bbox` удалить), а `_attach(obj, arm)` → `_attach(obj, arm, bone=HEAD_GROUP)` с `vg = obj.vertex_groups.new(name=bone)`.

`tools/blender/cat_fluff.py`:
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
	w = hi.x - lo.x
	for side in (-1.0, 1.0):
		base = Vector((side * (hi.x if side > 0 else -lo.x) * 0.92, hi.y - 0.03, lo.z + 0.35 * (hi.z - lo.z)))
		for i, tilt in enumerate((-0.35, 0.0, 0.35)):
			c = lib.cone(f"cheek_{'r' if side > 0 else 'l'}{i}", radius=0.007, depth=0.022, segments=6, material=CREAM)
			d = Vector((side, -0.4, -0.2 + tilt))
			_oriented(c, d)
			c.location = base + d.normalized() * 0.009 + Vector((0.0, 0.0, tilt * 0.01))
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
	ring.location = head + axis * 0.004
	tag = lib.cylinder("collar_tag", radius=0.012, depth=0.004, segments=10, material="rarity_legendary")
	tag.rotation_euler = (math.pi / 2, 0.0, 0.0)   # плоский диск в плоскости XZ, лицом вперёд
	tag.location = ring.location + Vector((0.0, 0.0, -major)) + Vector((0.0, 0.004, 0.0))
	return [ring, tag]


def build_fluff(arm, mesh):
	"""Пять объектов, дети арматуры. Звать после face_forward и rescale, до/после глаз — не важно."""
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
Примечание: `lib.cone/cylinder` принимают `segments`, `lib.torus` — нет (16×8). `_join` берёт материал первой грани каждого объекта, для ошейника два объекта → два материала.

`tools/blender/cat.py`: `import cat_fluff`; новая функция и вызовы в `build()`:
```python
def smooth_body(mesh):
	"""Один уровень subdivision при экспорте (export_apply применяет модификаторы, кроме арматуры) и smooth."""
	mod = mesh.modifiers.new("Subdivision", "SUBSURF")
	mod.levels = 1
	mod.render_levels = 1
	mesh.modifiers.move(mesh.modifiers.find(mod.name), 0)   # до Armature
	for p in mesh.data.polygons:
		p.use_smooth = True
```
и в `build()`:
```python
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
`tools/blender/gen/cat.py`: `SPEC = {"max_tris": 6000, "max_dim": 0.6, "animations": True}`.

`scripts/player/cat.gd`, в `_ready()`: цикл снятия обводки расширить на усы:
```gdscript
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("eyes_") or mi.name == "whiskers":
			(mi as MeshInstance3D).material_overlay = null   # обводка на глазах — рамка, на усах — клякса
```

- [ ] **Step 4: Blender-тесты зелёные, пересборка, кадр**

Run: `make test-blender 2>&1 | grep -E "^(Ran|OK|FAILED|FAIL|AssertionError)"` → `Ran 25 tests ... OK`. Если `test_collar_sits_on_the_neck` падает по высоте — напечатать `lo.z, hi.z, head.z` кости `Bone.002` и поправить `ring.location` (кость шеи может начинаться у плеч).
Run: `make assets ONLY=cat 2>&1 | grep -E "ОК|ОШИБКА"` → ≤ 6000 tri. `make import`.
Run: служебный рендер анфас и 3/4 (`-s` скрипт из плана 4, `build/front_normal.png`): кот круглый, щёки с кисточками, усы, грудка, ошейник с жетоном. По кадру допускается подвинуть числа в `_cheeks/_whiskers/_collar` (записать Ruling).
Run: `make test-godot 2>&1 | tail -3` → зелёные (старые тесты кота не ломаются; `test_cat_asset` проверяет `assert_has` материалов).

- [ ] **Step 5: Коммит**

```bash
git add tools/blender/cat.py tools/blender/cat_eyes.py tools/blender/cat_fluff.py tools/blender/gen/cat.py tools/blender/tests/test_cat_fluff.py tools/blender/tests/test_cat_eyes.py assets/models/cat.glb assets/models/cat.glb.import scripts/player/cat.gd
git commit -m "Кот: сглаживание, щёчные кисточки, грудка, кончик хвоста, усы, ошейник с жетоном

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Глаза в глазницах и моргание

**Files:**
- Modify: `tools/blender/palette.py` (+`eye_green`), `tools/blender/cat_eyes.py` (`_parts` v2, набор `blink`), `tools/blender/tests/test_lib.py` (19 цветов), `tools/blender/tests/test_cat_eyes.py`, `scripts/player/cat_face.gd`, `tests/integration/test_cat_scene.gd`, `assets/models/cat.glb`

**Interfaces:**
- Produces: `EYE_SETS = ("normal", "scared", "happy", "dizzy", "blink")`; материалы глаз `sr_eye_white`, `sr_eye_green`, `sr_ink`, `sr_cat_orange` (веко — красится скином как тело); `CatFace.BLINK_TIME = 0.12`, `CatFace.blink_in: float` (секунд до следующего моргания), `CatFace.blink_left: float`; выражение `&"blink"` показывается только поверх `&"normal"`.

- [ ] **Step 1: Падающие тесты**

`tools/blender/tests/test_cat_eyes.py` добавить:
```python
    def test_eyes_are_sunk_into_the_head(self):
        lo, hi = cat_eyes.head_bbox(self.mesh)
        ys = [p.y for p in self._world(self.eyes["eyes_normal"])]
        self.assertLess(max(ys), hi.y + 0.004, "белок выступает из морды не больше чем на 4 мм")
        self.assertGreater(max(ys), hi.y - 0.004, "но не утоплен целиком")

    def test_normal_eyes_have_green_iris_and_lid(self):
        mats = {m.name for m in self.eyes["eyes_normal"].data.materials}
        self.assertTrue({"sr_eye_white", "sr_eye_green", "sr_ink", "sr_cat_orange"} <= mats, mats)

    def test_blink_set_exists(self):
        self.assertIn("eyes_blink", self.eyes)
```
и в `test_four_sets_skinned_to_head` множество имён дополнить `"eyes_blink"`; в `test_lib.py` — 19 цветов.

`tests/integration/test_cat_scene.gd` добавить (Review Focus 4):
```gdscript
func test_blink_only_over_normal_and_releases() -> void:
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
```

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `make test-blender 2>&1 | grep -E "^(FAIL|Ran|OK|FAILED)" | head -4` → падают три новых (нет `eyes_blink`, белок торчит на 14 мм, нет `sr_eye_green`); GUT `-gselect=test_cat_scene` → `blink_in` не существует.

- [ ] **Step 3: Глаза v2**

`tools/blender/palette.py`: после `eye_white` добавить `"eye_green": "#6FA04A",   # радужка (спек 2.8)`.

В `tools/blender/cat_eyes.py`: `EYE_SETS = ("normal", "scared", "happy", "dizzy", "blink")`; `_parts` заменить целиком:
```python
def _eyeball(p, c, white_r, iris_r, pupil_r, pop):
	"""Глаз в глазнице: белок-эллипсоид утоплен в голову, радужка/зрачок/блик на его передней поверхности.
	pop — насколько белок выдвинут вперёд (0 = центр на 40 % радиуса внутри головы)."""
	fwd = Vector((0.0, 1.0, 0.0))
	up = Vector((0.0, 0.0, 1.0))
	w = lib.sphere(p + "_w", white_r, material="eye_white", **SPHERE)
	w.scale = (1.0, 0.55, 1.0)
	w.location = c - fwd * (white_r * 0.4 - pop)
	front = w.location + fwd * (white_r * 0.55)
	iris = lib.sphere(p + "_i", iris_r, material="eye_green", **SPHERE)
	iris.scale = (1.0, 0.35, 1.0)
	iris.location = front - fwd * (iris_r * 0.35 * 0.6)
	pupil = lib.sphere(p + "_k", pupil_r, material="ink", **SPHERE)
	pupil.scale = (1.0, 0.3, 1.0)
	pupil.location = iris.location + fwd * 0.0015
	glint = lib.sphere(p + "_g", pupil_r * 0.45, material="eye_white", segments=6, rings=4)
	glint.location = pupil.location + fwd * 0.0015 + Vector((-pupil_r * 0.4, 0.0, pupil_r * 0.45))
	lid = lib.rounded_box(p + "_lid", (white_r * 2.2, 0.006, 0.006), bevel=0.0, material="cat_orange")
	lid.rotation_euler = (math.radians(20.0), 0.0, 0.0)   # козырёк чуть наклонён вперёд
	lid.location = c + up * (white_r * 0.85) + fwd * 0.003
	return [w, iris, pupil, glint, lid]


def _parts(kind, side, c):
	p = f"eye_{kind}_{side}"
	fwd = Vector((0.0, 1.0, 0.0))
	if kind == "normal":
		return _eyeball(p, c, 0.014, 0.0085, 0.0045, 0.0)
	if kind == "scared":
		return _eyeball(p, c, 0.016, 0.006, 0.0025, 0.004)   # белок выпучен на 4 мм, зрачок точкой
	if kind == "happy":   # «^»: левый штрих поднимается к центру, правый — от центра вниз
		a = _line(p + "_a", c + Vector((-0.006, 0.006, -0.002)), -35, 0.016, 0.0025, "ink")
		b = _line(p + "_b", c + Vector((0.006, 0.006, -0.002)), 35, 0.016, 0.0025, "ink")
		return [a, b]
	if kind == "blink":   # закрытый глаз: одна горизонтальная ресница
		return [_line(p + "_a", c + fwd * 0.006, 0, 0.024, 0.0025, "ink")]
	a = _line(p + "_a", c + fwd * 0.006, 45, 0.026, 0.0025, "ink")    # dizzy: «×»
	b = _line(p + "_b", c + fwd * 0.006, -45, 0.026, 0.0025, "ink")
	return [a, b]
```
`lib.rounded_box` с `bevel=0.0` даёт простой параллелепипед (без модификатора); у него нет smooth — ок для козырька. Центр `c` остаётся `eye_centers` (y = hi.y − 0.012): белок радиуса 14 мм, утопленный на 40 %, выступает на 14·0,55·(1−0,4) ≈ 4,6 мм от c, то есть ≤ hi.y − 0.012 + 0.0046 → внутри 4 мм от морды.

`scripts/player/cat_face.gd`: константы и поля
```gdscript
const BLINK_TIME := 0.12
const BLINK_MIN := 3.0
const BLINK_MAX := 5.0

var blink_in := randf_range(BLINK_MIN, BLINK_MAX)   # секунд до следующего моргания
var blink_left := 0.0
```
`SETS` дополнить `&"blink"`; в `update()` после пересчёта таймеров:
```gdscript
	blink_in -= delta
	if blink_in <= 0.0:
		blink_left = BLINK_TIME
		blink_in = randf_range(BLINK_MIN, BLINK_MAX)
	blink_left = maxf(blink_left - delta, 0.0)
```
и после выбора `want`: `if want == &"normal" and blink_left > 0.0: want = &"blink"`.

- [ ] **Step 4: Тесты зелёные, пересборка, кадр**

Run: `make test-blender` → `Ran 28 tests ... OK`; `make assets ONLY=cat`; `make import`; `make test-godot` → зелёные (+1). Рендер анфас пятью наборами (скрипт `-s` из плана 4 с `EXPR` + `"blink"`): глаза в глазницах с веком, зелёная радужка, блик; по кадру допускается править радиусы и `pop` (Ruling).

- [ ] **Step 5: Коммит**

```bash
git add tools/blender/palette.py tools/blender/cat_eyes.py tools/blender/tests/test_cat_eyes.py tools/blender/tests/test_lib.py scripts/player/cat_face.gd tests/integration/test_cat_scene.gd assets/models/cat.glb assets/models/cat.glb.import
git commit -m "Кот: глаза в глазницах с веком, зелёной радужкой и бликом; моргание

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: «Чиби»-лапы и покачивание хвоста

**Files:**
- Create: `scripts/player/leg_scaler.gd`, `scripts/player/tail_wiggle.gd`
- Modify: `scripts/player/cat.gd`, `tests/integration/test_cat_scene.gd`

**Interfaces:**
- Produces: `LegScaler` (`SkeletonModifier3D`): `upper_bones = ["Bone.014", "Bone.017", "Bone.008", "Bone.011"]`, `foot_bones = ["Bone.016", "Bone.019", "Bone.010", "Bone.013"]`, `root_bone = "Bone"`, `leg_scale = 0.8`, `drop: float` (в единицах скелета, считается в `_ready` из rest-позы); `TailWiggle` (`SkeletonModifier3D`): `bones = ["Bone.004", "Bone.005", "Bone.006", "Bone.007"]`, `amplitude = 0.12`, `frequency = 2.5`, `phase_step = 0.7`. `Cat._ready` добавляет оба после `HeadScaler`.

- [ ] **Step 1: Падающие тесты** (Review Focus 3)

`tests/integration/test_cat_scene.gd`:
```gdscript
var _foot_y := {}
var _hip_y := {}

func _capture(skel: Skeleton3D, key: String) -> void:
	var foot := skel.find_bone("Bone.016")
	var hip := skel.find_bone("Bone")
	skel.skeleton_updated.connect(func() -> void:
		_foot_y[key] = skel.get_bone_global_pose(foot).origin.y
		_hip_y[key] = skel.get_bone_global_pose(hip).origin.y)

func test_short_legs_keep_feet_on_the_ground() -> void:
	# Два экземпляра cat.glb на одном кадре клипа idle: с LegScaler и без.
	var plain := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	var short := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	add_child_autofree(plain)
	add_child_autofree(short)
	var ls := LegScaler.new()
	short.find_child("Skeleton3D", true, false).add_child(ls)
	for n in [plain, short]:
		(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).play("idle")
	_capture(plain.find_child("Skeleton3D", true, false), "plain")
	_capture(short.find_child("Skeleton3D", true, false), "short")
	await wait_process_frames(3)
	assert_gt(ls.drop, 0.0, "просадка корня посчитана из rest-позы")
	assert_almost_eq(_foot_y["short"], _foot_y["plain"], 0.15, "стопа на той же высоте (единицы скелета ≈ 3 см)")
	assert_lt(_hip_y["short"], _hip_y["plain"] - ls.drop * 0.8, "таз опустился примерно на drop")

var _tail_rot := []

func test_tail_wiggles_over_time() -> void:
	var cat = _spawn()
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	var idx := skel.find_bone("Bone.006")
	skel.skeleton_updated.connect(func() -> void: _tail_rot.append(skel.get_bone_pose_rotation(idx)))
	await wait_seconds(0.25)
	assert_gt(_tail_rot.size(), 5)
	assert_false((_tail_rot[0] as Quaternion).is_equal_approx(_tail_rot[-1]), "поза хвоста меняется (помимо клипа idle — в нём хвост почти статичен)")
```

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `$GODOT ... -gselect=test_cat_scene` → `Identifier "LegScaler" not declared`.

- [ ] **Step 3: Модификаторы**

`scripts/player/leg_scaler.gd`:
```gdscript
class_name LegScaler
extends SkeletonModifier3D
## «Чиби»-лапы поверх любого клипа (спек 2.8): верхние кости лап равномерно в 0,8, корень
## опускается на 20 % высоты ноги, посчитанной из rest-позы, чтобы стопы остались на земле.

@export var upper_bones: Array[StringName] = [&"Bone.014", &"Bone.017", &"Bone.008", &"Bone.011"]
@export var foot_bones: Array[StringName] = [&"Bone.016", &"Bone.019", &"Bone.010", &"Bone.013"]
@export var root_bone: StringName = &"Bone"
@export var leg_scale := 0.8
var drop := 0.0   # единицы скелета


func _ready() -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var hip := skel.find_bone(root_bone)
	var hip_y := skel.get_bone_global_rest(hip).origin.y
	var foot_y := INF
	for b in foot_bones:
		var i := skel.find_bone(b)
		if i >= 0:
			foot_y = minf(foot_y, skel.get_bone_global_rest(i).origin.y)
	if foot_y < INF and hip >= 0:
		drop = (hip_y - foot_y) * (1.0 - leg_scale)


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
		skel.set_bone_pose_position(root, skel.get_bone_pose_position(root) - Vector3(0.0, drop, 0.0))
```
`scripts/player/tail_wiggle.gd`:
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
`scripts/player/cat.gd`, `_ready()`: после добавления `HeadScaler`:
```gdscript
		for mod in [LegScaler.new(), TailWiggle.new()]:
			mod.name = mod.get_class() if mod.get_class() != "SkeletonModifier3D" else "Mod"
			skel.add_child(mod)
```
(проще: `var ls := LegScaler.new(); ls.name = "LegScaler"; skel.add_child(ls)` и так же `TailWiggle`).

- [ ] **Step 4: Тесты зелёные, кадр**

Run: `make import; make test-godot` → зелёные (+2). Если стопа ушла (`assert_almost_eq` по 0,15), значит корень и стопы не в одной вертикали скелета — напечатать `hip_y/foot_y` и проверить, что Y скелета — вверх (`CatRig` вращается только вокруг Y). Рендер анфас/профиль: лапы короче, кот ниже и «плотнее», стопы на земле. `make shot` в игре — кот не парит и не тонет (`test_cat_lands_on_ground` по-прежнему зелёный: коллизия не менялась).

- [ ] **Step 5: Коммит**

```bash
git add scripts/player/leg_scaler.gd scripts/player/tail_wiggle.gd scripts/player/cat.gd tests/integration/test_cat_scene.gd
git add -A scripts/player
git commit -m "Кот: короткие «чиби»-лапы и покачивание хвоста модификаторами скелета

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Тун v2 — rim-свет и «шерстяная» обводка шейдером

**Files:**
- Create: `assets/shaders/outline_fur.gdshader`
- Modify: `scripts/visual/toon.gd`, `scripts/player/cat.gd` (альфа обводки), `scripts/hazards/dog.gd`, `wasp.gd`, `cyclist.gd` (вызов с `character = true`), `tests/unit/test_toon.gd`, `tests/integration/test_cat_scene.gd`

**Interfaces:**
- Produces: `Toon.apply(root, outline_width := OUTLINE_CHARACTER, character := false) -> int`; при `character` у материалов `rim_enabled = true, rim = 0.5, rim_tint = 0.6`, обводка — `ShaderMaterial` (`outline_fur.gdshader`) с параметрами `width` (в единицах модели), `jitter` (0.25 для персонажей, 0 иначе), `frequency 40`, `color`, `alpha`; `Toon.OUTLINE_JITTER = 0.25`; `Cat._fade_material` ставит `alpha` обводке через `set_shader_parameter`.

- [ ] **Step 1: Падающие тесты**

`tests/unit/test_toon.gd`: в `test_apply_sets_toon_modes_and_outline` блок про `outline` заменить:
```gdscript
	var outline := mi.material_overlay as ShaderMaterial
	assert_not_null(outline, "обводка — шейдерный hull")
	assert_eq(outline.shader.resource_path, "res://assets/shaders/outline_fur.gdshader")
	assert_almost_eq(float(outline.get_shader_parameter("width")), 0.02, 0.0001)
	assert_almost_eq(float(outline.get_shader_parameter("jitter")), 0.0, 0.0001, "у пропсов и еды шерсти нет")
	assert_eq((outline.get_shader_parameter("color") as Color).to_html(false), Toon.OUTLINE_COLOR.to_html(false))
	assert_false(m.rim_enabled, "у не-персонажей rim выключен")
```
в `test_outline_width_is_in_meters_under_scaled_parent`: `(mi.material_overlay as ShaderMaterial).get_shader_parameter("width")` ≈ 0.1. Добавить:
```gdscript
func test_character_gets_rim_and_fur_jitter() -> void:
	var mi := _make_mesh()
	Toon.apply(mi, 0.006, true)
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	assert_true(m.rim_enabled)
	assert_almost_eq(m.rim, 0.5, 0.01)
	assert_almost_eq(m.rim_tint, 0.6, 0.01)
	assert_almost_eq(float((mi.material_overlay as ShaderMaterial).get_shader_parameter("jitter")), Toon.OUTLINE_JITTER, 0.001)
```
`tests/integration/test_cat_scene.gd`, в `test_camera_rig_fades_target_instead_of_hiding` после проверки тела (Review Focus 2):
```gdscript
	var outline := _body_outline(cat)
	assert_almost_eq(float(outline.get_shader_parameter("alpha")), cat.fade, 0.01, "обводка тоже полупрозрачна")
```
и после возврата к 1.0: `assert_almost_eq(float(_body_outline(cat).get_shader_parameter("alpha")), 1.0, 0.001)`; помощник:
```gdscript
func _body_outline(cat) -> ShaderMaterial:
	return (cat.find_child("cat", true, false) as MeshInstance3D).material_overlay as ShaderMaterial
```
В `test_skin_change_keeps_fade` добавить `assert_almost_eq(float(_body_outline(cat).get_shader_parameter("alpha")), 0.4, 0.01)`.

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `-gselect=test_toon` → `material_overlay` не ShaderMaterial (null после каста).

- [ ] **Step 3: Шейдер и Toon**

`assets/shaders/outline_fur.gdshader`:
```glsl
shader_type spatial;
render_mode cull_front, unshaded, blend_mix, depth_draw_always;
// Инвертированный hull с «рваной» шириной: силуэт персонажа читается как пушистый (спек 2.8).
uniform vec4 color : source_color = vec4(0.224, 0.255, 0.318, 1.0);
uniform float width = 0.006;      // в единицах модели (Toon пересчитывает метры под масштаб узла)
uniform float jitter = 0.0;       // доля width: 0 — ровная обводка, 0.25 — шерсть
uniform float frequency = 40.0;   // частота шума по UV
uniform float alpha = 1.0;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	float n = hash2(floor(UV * frequency)) * 2.0 - 1.0;   // UV стабильны по вершинам, обводка не «кипит» в движении
	VERTEX += NORMAL * width * (1.0 + jitter * n);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = alpha * color.a;
}
```

`scripts/visual/toon.gd`:
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


## outline_width задаётся в метрах: grow работает в пространстве модели, поэтому
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
Вызовы: `cat.gd` → `Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)`; `dog.gd`, `wasp.gd`, `cyclist.gd` — так же с `true`. В `cat.gd` `_apply_fade`: строку про overlay заменить на
```gdscript
		var outline := m3.material_overlay as ShaderMaterial
		if outline:
			outline.set_shader_parameter("alpha", fade)
```
и `_fade_material` больше не получает overlay.

- [ ] **Step 4: Тесты зелёные, кадр**

Run: `make import; make test-godot` → зелёные. `make shot SHOT=build/shot_fur.png`: силуэт кота с мелкой «рваной» обводкой, светлый rim по краям спины и ушей; собака и оса — тоже. Если обводка «кипит» при движении (в `make run`) — значит у меша нет UV и шум идёт от нуля: тогда это ровная обводка, оставить. Если шум слишком крупный — `frequency` 60.

- [ ] **Step 5: Коммит**

```bash
git add assets/shaders/outline_fur.gdshader scripts/visual/toon.gd scripts/player/cat.gd scripts/hazards/dog.gd scripts/hazards/wasp.gd scripts/hazards/cyclist.gd tests/unit/test_toon.gd tests/integration/test_cat_scene.gd
git add -A assets/shaders
git commit -m "Тун v2: rim-свет персонажей и шейдерная обводка с «шерстяным» шумом

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Свет, небо, лужи, пост-обработка

**Files:**
- Create: `tests/integration/test_lighting.gd`
- Modify: `scenes/world/lighting.tscn`, `scripts/world/lighting.gd`, `scripts/world/world_builder.gd` (`water`), `data/layout/yard.json` (у луж `"water": true`), `tests/integration/test_world_builder.gd`

**Interfaces:**
- Consumes: `assets/images/world/clouds.png` (задача 1).
- Produces: узлы `Lighting/Sun` (65°, 30°, `#FFF1D6`, 1.2, тени, `light_angular_distance 1.5`, `shadow_blur 1.5`, `directional_shadow_max_distance 30`, 4 каскада), `Lighting/Fill` (−65°, 210°, `#9FC4E8`, 0.25, без теней), `WorldEnvironment` с ambient от неба (0.6), SSAO (0.3/1.5), SSR, glow (0.4, порог 1.2), adjustments (saturation 1.1), tonemap linear; небо `ProceduralSkyMaterial` (верх `#4A9BE0`, горизонт `#CFE6F8`) с `sky_cover = clouds.png`; `WorldBuilder._build_prop` при `p.water == true` делает материалы модели зеркальными (`roughness 0.05, metallic 0.0, specular 1.0`, без тун-диффуза) и считает `water_built`.

- [ ] **Step 1: Падающие тесты**

`tests/integration/test_lighting.gd`:
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
	assert_almost_eq(sun.directional_shadow_max_distance, 30.0, 0.1)

func test_fill_light_from_the_sky_without_shadows() -> void:
	var fill := light.get_node("Fill") as DirectionalLight3D
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
	assert_eq(sky.sky_cover.resource_path, "res://assets/images/world/clouds.png")
```
`tests/integration/test_world_builder.gd` добавить:
```gdscript
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
```

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `-gselect=test_lighting` → нет узла `Fill`, углы 50°; `-gselect=test_world_builder` → нет `water_built`.

- [ ] **Step 3: Свет и небо**

`scenes/world/lighting.tscn` целиком:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/world/lighting.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/images/world/clouds.png" id="2"]

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
ambient_light_source = 1
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
directional_shadow_max_distance = 30.0

[node name="Fill" type="DirectionalLight3D" parent="."]
light_color = Color(0.624, 0.769, 0.910, 1)
light_energy = 0.25
shadow_enabled = false

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("env")
```
`ambient_light_source = 1` — это `AMBIENT_SOURCE_SKY`; `directional_shadow_mode = 2` — `SHADOW_PARALLEL_4_SPLITS`. `scripts/world/lighting.gd`:
```gdscript
extends Node3D
## Яркий день по референсу (спек 2.8): солнце 65° с юго-востока, заполняющий свет неба с обратной стороны.

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-65.0, 30.0, 0.0)
	$Fill.rotation_degrees = Vector3(-65.0, 210.0, 0.0)
```

`scripts/world/world_builder.gd`: поле `var water_built := 0`; в `_build_prop` после `Toon.apply(...)`:
```gdscript
	if bool(p.get("water", false)):
		_make_water(model)
		water_built += 1
```
и метод:
```gdscript
func _make_water(model: Node3D) -> void:
	## Лужа: зеркальный материал, отражает небо через SSR окружения (спек 2.8).
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m == null:
				continue
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
			m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
			m.roughness = 0.05
			m.metallic = 0.0
			m.metallic_specular = 1.0
```
`data/layout/yard.json`: у каждого пропса `"model": "puddle"` добавить `"water": true` (скриптом: `python3 - <<'PY' … for p in d["props"]: if p["model"]=="puddle": p["water"]=True … json.dump(indent=2, ensure_ascii=False)` — сохранить форматирование как в файле; проверить `git diff --stat`, что менялись только строки луж).

- [ ] **Step 4: Тесты зелёные, кадр и замер**

Run: `make import; make test-godot` → зелёные (+5). `make shot SHOT=build/shot_light.png`: небо синее с облаками, тени мягкие и короче, в лужах отражение неба; замер пикселей как в плане 4 (небо в верхней трети кадра синее: `b > r`), тень под котом мягкая (градиент на краю ≥ 3 px). Если SSAO даёт грязные пятна на лоуполи — `ssao_intensity 1.0`. Если SSR не виден в лужах (камера низко, малый угол) — оставить, это для кадров сверху.

- [ ] **Step 5: Коммит**

```bash
git add scenes/world/lighting.tscn scripts/world/lighting.gd scripts/world/world_builder.gd data/layout/yard.json tests/integration/test_lighting.gd tests/integration/test_world_builder.gd
git add -A tests/integration
git commit -m "Свет: яркий день, мягкие тени, заполняющий свет, SSAO, SSR для луж, glow, облака на небе

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: VFX и «жизнь»: сквош, пыль, вспышка, тряска, сердечки, искры, шлейф, листья, «z»

**Files:**
- Modify: `scripts/visual/effects.gd`, `scripts/player/cat.gd`, `scripts/player/camera_rig.gd`, `scripts/main.gd`, `scripts/food/food_pickup.gd`, `scripts/hazards/wasp.gd`, `scripts/hazards/cyclist.gd`, `scripts/hazards/dog.gd`, `scripts/world/lighting.gd`, `tests/integration/test_effects.gd`, `test_cat_scene.gd`, `test_food.gd`, `test_main.gd`, `test_dog.gd`, `test_lighting.gd`

**Interfaces:**
- Produces: `Effects.dust(parent, pos, amount := 12) -> CPUParticles3D` (песочный `#D3AB87`, вверх-в стороны, 0,5 с); `Effects.hearts(parent, pos) -> CPUParticles3D` (`QuadMesh` 0,06 м с `assets/images/ui/heart.png`, billboard, 6 штук вверх); `Effects.sparkles(parent, color) -> CPUParticles3D` (постоянные, 8 штук, радиус 0,12 м, не one-shot); `Effects.trail(parent, color, amount := 10) -> CPUParticles3D` (постоянный шлейф); `Effects.zzz(parent, pos) -> Label3D` («z», всплывает 1,2 с, самоудаляется); `Effects.leaves(parent, extents := Vector3(15, 3, 15)) -> CPUParticles3D` (40 листьев, 8 с, дрейф). `Cat.squash(scale_y: float, duration := 0.12)` (твин `_model.scale`), поле `was_on_floor`, `Cat.flash(seconds := 0.1)` (все материалы тела белые, потом `_apply_skin` + `_apply_fade`), `Cat.flashing: bool`; `CameraRig.shake(amplitude := 0.05, seconds := 0.2)` (смещение `SpringArm3D.position` по шуму); `FoodPickup` с `food.tier >= Rarity.Tier.RARE` имеет ребёнка `Sparkles`; `Wasp` — `Trail`; `Cyclist` — `Dust` (emitting только в `riding`); `Dog` в IDLE раз в 1,2 с зовёт `Effects.zzz`; `Lighting` — ребёнок `Leaves`.

- [ ] **Step 1: Падающие тесты**

`tests/integration/test_effects.gd` добавить:
```gdscript
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
```
`tests/integration/test_cat_scene.gd` (нужен пол: в этом файле `_spawn` без пола — создать помощник `_spawn_on_floor()` по образцу `test_dog.gd`):
```gdscript
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
	cat.velocity.y = 3.0   # подбросить
	await wait_physics_frames(2)
	assert_false(cat.is_on_floor())
	var n0 := get_tree().get_nodes_in_group("fx").size()
	await wait_physics_frames(60)
	assert_true(cat.is_on_floor(), "приземлился")
	assert_gt(get_tree().get_nodes_in_group("fx").size(), n0, "пыль при приземлении")
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
`tests/integration/test_food.gd` добавить (посмотреть, как там создаётся `FoodPickup`; если помощника нет — через `PickupScene.instantiate()` + `setup(def)`):
```gdscript
func test_rare_food_sparkles_common_does_not() -> void:
	var rare := (load("res://scenes/food/food_pickup.tscn") as PackedScene).instantiate() as FoodPickup
	rare.setup(FoodCatalog.get_by_id(&"pizza"))
	add_child_autofree(rare)
	var plain := (load("res://scenes/food/food_pickup.tscn") as PackedScene).instantiate() as FoodPickup
	plain.setup(FoodCatalog.get_by_id(&"cookie"))
	add_child_autofree(plain)
	assert_not_null(rare.find_child("Sparkles", false, false), "редкая еда искрится")
	assert_eq((rare.find_child("Sparkles", false, false) as CPUParticles3D).color, Rarity.COLORS[Rarity.Tier.RARE])
	assert_null(plain.find_child("Sparkles", false, false), "обычная — нет")
```
`tests/integration/test_dog.gd` добавить:
```gdscript
func test_sleeping_dog_emits_zzz() -> void:
	await wait_seconds(1.5)
	assert_eq(dog.brain.state, ChaseBrain.State.IDLE)
	var zs := 0
	for n in get_tree().get_nodes_in_group("fx"):
		if n is Label3D and n.text == "z":
			zs += 1
	assert_gt(zs, 0, "над спящей собакой всплывает «z»")
```
`tests/integration/test_lighting.gd`: `assert_not_null(light.get_node_or_null("Leaves"), "листья по ветру")`. `tests/integration/test_main.gd`: в `test_eating_spawns_burst_in_rarity_color` ожидать в группе `fx` два узла (всплеск + сердечки): `assert_eq(fx.size(), 2, "всплеск и сердечки")` и проверять цвет у того, что `CPUParticles3D` с `mesh is SphereMesh`. Велосипедист/оса: в `test_wasp.gd` `assert_not_null(wasp.find_child("Trail", false, false))`, в `test_cyclist.gd` `assert_not_null(c.find_child("Dust", false, false))` и `emitting` только после `_depart` (если тест департа есть — дополнить там).

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `make test-godot 2>&1 | grep -E "Failed|SCRIPT ERROR" | head -8` → нет `Effects.dust`, `squash`, `flash`, `shake_left`, `Sparkles`, `Leaves`.

- [ ] **Step 3: Effects**

В `scripts/visual/effects.gd` добавить (после `burst`):
```gdscript
const DUST_COLOR := Color("#D3AB87")
const HeartTexture := preload("res://assets/images/ui/heart.png")


static func _particles(parent: Node, name: String, one_shot: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = name
	p.add_to_group("fx")
	p.one_shot = one_shot
	parent.add_child(p)
	if one_shot:
		p.finished.connect(p.queue_free)
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
	p.global_position = pos
	p.emitting = true
	return p


static func hearts(parent: Node, pos: Vector3) -> CPUParticles3D:
	## Сердечки при съедании: спрайты сгенерированной иконки, плывут вверх.
	var p := _particles(parent, "Hearts", true)
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
	mat.albedo_texture = HeartTexture
	quad.material = mat
	p.mesh = quad
	p.global_position = pos
	p.emitting = true
	return p


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
	p.emitting = true
	return p


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
	p.emitting = true
	return p


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


static func leaves(parent: Node, extents := Vector3(15, 3, 15)) -> CPUParticles3D:
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
	p.position = Vector3(0, 2.0, 0)
	p.emitting = true
	return p
```

- [ ] **Step 4: Кот, камера, еда, опасности, свет**

`scripts/player/cat.gd`:
```gdscript
const RUN_DUST_EVERY := 0.25
const FLASH_COLOR := Color.WHITE

var was_on_floor := true
var flashing := false
var _run_dust_t := 0.0
var _squash: Tween
```
В конце `_physics_process` (после `state = CatMotion.pick_state(...)`) и в ветке `input_enabled == false` перед `return` — вызвать `_after_move(delta)`:
```gdscript
func _after_move(delta: float) -> void:
	## Приземление: сплющить и пыль; бег: пыль каждые 0,25 с.
	var on_floor := is_on_floor()
	if on_floor and not was_on_floor:
		squash(0.8, 0.12)
		Effects.dust(get_parent(), global_position)
	elif not on_floor and was_on_floor and velocity.y > 1.0:
		squash(1.15, 0.1)   # вытянуться в прыжке
	was_on_floor = on_floor
	if state == &"run" and on_floor:
		_run_dust_t += delta
		if _run_dust_t >= RUN_DUST_EVERY:
			_run_dust_t = 0.0
			Effects.dust(get_parent(), global_position, 6)
	else:
		_run_dust_t = 0.0


func squash(scale_y: float, duration := 0.12) -> void:
	if _squash:
		_squash.kill()
	_model.scale = Vector3(1.0 / sqrt(scale_y), scale_y, 1.0 / sqrt(scale_y))
	_squash = create_tween()
	_squash.tween_property(_model, "scale", Vector3.ONE, duration * 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func flash(seconds := 0.1) -> void:
	## Вспышка белым при ударе; после — цвета надетого скина и текущая прозрачность.
	flashing = true
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or String(m3.name).begins_with("eyes_"):
			continue
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m:
				m.albedo_color = Color(FLASH_COLOR, m.albedo_color.a)
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		flashing = false
		_apply_skin(GameState.skin)
		_restore_non_skin_colors())
```
Скин перекрашивает только три роли; остальные материалы (белок, зрачок, пучки — кремовые = роль belly, ок; `sr_eye_white`, `sr_ink`, `sr_eye_green`, `sr_rarity_legendary`) после вспышки нужно вернуть: проще не трогать их во вспышке — в `flash` красить только материалы с именем из `CatSkin.ROLE_BY_MATERIAL` (тело, грудка, акцент): тогда `_apply_skin` восстанавливает всё, и `_restore_non_skin_colors` не нужен. Так и сделать: условие `if m and CatSkin.ROLE_BY_MATERIAL.has(m.resource_name)`; таймер зовёт только `flashing = false; _apply_skin(GameState.skin)` (в `_apply_skin` уже есть восстановление `fade`). В `take_hit` после `Sfx.play(&"meow", 0.12)`: `flash()` и `if camera_rig: camera_rig.shake()`. В `_apply_skin`: если `flashing`, выходить сразу (чтобы смена скина во время вспышки не перекрасила раньше времени — тест этого не требует, но так честно).

`scripts/player/camera_rig.gd`:
```gdscript
var shake_left := 0.0
var _shake_amp := 0.05
var _shake_time := 0.2


func shake(amplitude := 0.05, seconds := 0.2) -> void:
	_shake_amp = amplitude
	_shake_time = seconds
	shake_left = seconds
```
в `_physics_process` после `rotation.y = _yaw` (до ветки витрины):
```gdscript
	if shake_left > 0.0:
		shake_left = maxf(shake_left - delta, 0.0)
		var k := _shake_amp * (shake_left / _shake_time)
		_arm.position = Vector3(randf_range(-k, k), randf_range(-k, k), 0.0)
	else:
		_arm.position = Vector3.ZERO
```
`scripts/main.gd`, `_on_food_eaten`: после всплеска `Effects.hearts(self, _cat.global_position + Vector3(0, 0.35, 0))`.
`scripts/food/food_pickup.gd`, в конце `_build_visual`: `if food.tier >= Rarity.Tier.RARE: Effects.sparkles(self, Rarity.COLORS[food.tier])`.
`scripts/hazards/wasp.gd`, `_ready`: `Effects.trail(self, Color("#5A5C6B"), 8)`. `scripts/hazards/cyclist.gd`: поле `var _dust: CPUParticles3D`; в `_ready`: `_dust = Effects.trail(self, Effects.DUST_COLOR, 12); _dust.emitting = false; _dust.name = "Dust"; _dust.position = Vector3(0, 0.1, 0.4)`; в `_depart`: `_dust.emitting = true`; при завершении проезда — `false`. `scripts/hazards/dog.gd`: поле `var _zzz_t := 0.0`; в ветке IDLE: `_zzz_t += delta; if _zzz_t >= 1.2: _zzz_t = 0.0; Effects.zzz(get_parent(), global_position + Vector3(0, 0.45, 0))`; в других ветках `_zzz_t = 0.0`. `scripts/world/lighting.gd`, `_ready`: `Effects.leaves(self)`.

- [ ] **Step 5: Тесты зелёные, глазами**

Run: `make test-godot` → зелёные. `make run`: прыжок — вытянулся, приземлился — сплющился и пыль; бег — пыль; удар — белая вспышка и тряска; съел — сердечки; редкая еда искрится; у осы шлейф; листья летят; над собакой «z». Если листья слишком заметны — `amount 25`.

- [ ] **Step 6: Коммит**

```bash
git add scripts/visual/effects.gd scripts/player/cat.gd scripts/player/camera_rig.gd scripts/main.gd scripts/food/food_pickup.gd scripts/hazards/wasp.gd scripts/hazards/cyclist.gd scripts/hazards/dog.gd scripts/world/lighting.gd tests/integration
git commit -m "VFX: сквош-стретч и пыль кота, вспышка и тряска при ударе, сердечки, искры редкой еды, шлейфы, листья, «z» у собаки

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Мир — зелень, декали, плакаты

**Files:**
- Create: `tools/blender/gen/grass.py`, `tools/blender/gen/ivy.py`, `assets/models/grass.glb`, `ivy.glb`
- Modify: `scripts/world/world_builder.gd` (`decals`), `data/layout/yard.json` (кусты, трава, плющ, декали, плакаты), `tests/integration/test_world_builder.gd`

**Interfaces:**
- Produces: `WorldBuilder` читает `"decals": [{"texture": "assets/images/world/decal_manhole.png", "pos": [x, y, z], "size": [w, h], "rot": 0, "wall": false}]` — квад `MeshInstance3D` (`QuadMesh`, материал с `albedo_texture`, `transparency = ALPHA_SCISSOR`, `cull_mode = CULL_DISABLED`), лежит плашмя на `y + 0.01` (или вертикально при `wall: true`, лицом по `rot`), контейнер `Decals`, счётчик `decals_built`; модели `grass.glb` (5 конусов, ≤ 120 tri, 0,25 м) и `ivy.glb` (полоса 2 × 1 м из 12 листьев-квадов, ≤ 60 tri), без коллайдеров (`"colliders": []` в раскладке даёт пустой список → без коллизии: поправить `_build_prop`, чтобы пустой список не заменялся AABB — ввести ключ `"solid": false`).

- [ ] **Step 1: Падающие тесты**

`tests/integration/test_world_builder.gd` добавить:
```gdscript
func test_decals_are_textured_quads_on_ground_and_walls() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"decals": [
		{"texture": "assets/images/world/decal_manhole.png", "pos": [1, 0, 2], "size": [1.0, 1.0]},
		{"texture": "assets/images/world/poster_cafe.png", "pos": [0, 1.5, -13.9], "size": [1.2, 1.2], "rot": 0, "wall": true}]})
	assert_eq(b.decals_built, 2)
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
	assert_eq(b.decals_built, data["decals"].size(), "все текстуры декалей существуют")
```
Blender-тесты: `tools/blender/tests/test_lib.py` не трогаем; у `grass`/`ivy` проверка бюджета через `build.py`.

- [ ] **Step 2: Запустить, убедиться, что падают**

Run: `-gselect=test_world_builder` → нет `decals_built`, нет моделей `grass`/`ivy`.

- [ ] **Step 3: Генераторы, декали, раскладка**

`tools/blender/gen/grass.py`:
```python
"""Пучок травы: пять узких конусов, чуть наклонённых в стороны."""
import math

import lib

SPEC = {"max_tris": 120, "max_dim": 0.3}


def build():
	parts = []
	for i in range(5):
		a = i * 2 * math.pi / 5
		c = lib.cone(f"grass_{i}" if i else "grass", radius=0.02, depth=0.22, segments=5, material="leaf" if i % 2 else "olive")
		c.location = (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.11)
		c.rotation_euler = (math.sin(a) * 0.35, -math.cos(a) * 0.35, 0.0)
		parts.append(c)
	return lib.group(parts)
```
`tools/blender/gen/ivy.py`:
```python
"""Плющ: полоса 2 × 1 м из листьев-квадов, висит на стене (плоскость XZ, лицом по -Y Blender = +Z Godot... см. ниже)."""
import math
import random

import bmesh
import bpy

import lib
import palette

SPEC = {"max_tris": 60, "max_dim": 2.1}


def build():
	rnd = random.Random(3)
	bm = bmesh.new()
	for i in range(12):
		x = -0.9 + i * 0.16 + rnd.uniform(-0.03, 0.03)
		z = 0.15 + (i % 3) * 0.3 + rnd.uniform(-0.05, 0.05)
		s = rnd.uniform(0.12, 0.18)
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
Квады плюща лежат в плоскости XZ Blender (y = 0) — в Godot это плоскость XY, лицом по ±Z; у материала в Godot ставится `cull_mode = CULL_DISABLED` через `Toon`? Нет — `Toon` не трогает cull. Поэтому в `_build_prop` для `solid: false` моделей дополнительно `m.cull_mode = BaseMaterial3D.CULL_DISABLED` на всех материалах (листья видны с обеих сторон).

`scripts/world/world_builder.gd`:
- поле `var decals_built := 0`; в `build()` после пропсов: `for d in data.get("decals", []): _build_decal(d)`.
- в `_build_prop`: `var solid := bool(p.get("solid", true))`; коллайдеры строить только если `solid`; после `Toon.apply` для не-solid: двусторонние материалы:
```gdscript
	if not solid:
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
				if m:
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
```
- метод:
```gdscript
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
	var pos := _v3(d["pos"])
	var wall := bool(d.get("wall", false))
	mi.global_position = pos + (Vector3.ZERO if wall else Vector3(0, 0.01, 0))
	mi.rotation_degrees = Vector3(0.0, float(d.get("rot", 0)), 0.0) if wall else Vector3(-90.0, float(d.get("rot", 0)), 0.0)
	decals_built += 1
```
`QuadMesh` лежит в плоскости XY лицом по +Z; поворот −90° по X кладёт его плашмя лицом вверх; для стены `rot` = поворот стены (плакат на северной стене z = −13.9 лицом на юг: `rot 0` даёт лицо по +Z — верно).

`data/layout/yard.json` (скриптом, сохраняя формат): добавить пропсы
- кусты вдоль северной стены: `{"model": "bush", "pos": [x, 0, -13.0], "rot": r}` для x ∈ {−11, −7, −3, 1, 5, 9} (не перекрывая дверь/окна — двери у x ≈ −8 и 5? посмотреть `door` в раскладке и сдвинуть кусты на 1,5 м от дверей);
- трава (`"solid": false`): 12 точек у бордюров и углов: `[-12.5, 0, -12.5], [12.5, 0, -12.5], [-12.5, 0, 9], [12.5, 0, 9], [-6, 0, -12.8], [6, 0, -12.8], [-12.8, 0, -3], [12.8, 0, -3], [3.5, 0, 4.2], [-3, 0, 1.5], [8.5, 0, -5], [-8.5, 0, 9.5]` (поправить те, что попадают в коллайдеры: тест `test_spawn_points_and_hideouts_are_not_inside_props` не про траву, но визуально);
- плющ (`"solid": false`): три полосы на северной стене `{"model": "ivy", "pos": [x, 1.6, -13.85], "rot": 0}` для x ∈ {−10, 2, 8}, одна на боковой стене, если она есть в раскладке;
- `"decals"`: люк `[3, 0, -2]` 1×1; трещины `[-6, 0, 4]` 2×2 и `[8, 0, -9]` 1.5×1.5; листья `[-2, 0, -6]` 2×2, `[6, 0, 6]` 2×2 (под деревьями); плакаты на северной стене `poster_cafe` `[−5, 1.5, −13.9]` 1.2×1.2, `poster_cat` `[3.5, 1.6, −13.9]` 1×1, `poster_paws` у кафе (если там есть стена; иначе на будке пряжи не вешать — она модель). Координаты стены: `wall` стоит в `[0, 0, -14]` с толщиной ~0,2 → лицо на z ≈ −13.9; проверить `_model_aabb` стены в тесте `test_real_yard_layout_loads` или напечатать.

Run: `make assets ONLY=grass && make assets ONLY=ivy` → `ОК`; `make import`.

- [ ] **Step 4: Тесты зелёные, кадр**

Run: `make test-godot` → зелёные (+3; старые инварианты раскладки — `≥ 24 пропсов`, `все модели существуют` — остаются). `make shot SHOT=build/shot_world.png`: у стены кусты и плющ, плакаты, на асфальте люк; трава у бордюров. Если плакат «смотрит в стену» — `rot 180`.

- [ ] **Step 5: Коммит**

```bash
git add tools/blender/gen/grass.py tools/blender/gen/ivy.py assets/models/grass.glb assets/models/grass.glb.import assets/models/ivy.glb assets/models/ivy.glb.import scripts/world/world_builder.gd data/layout/yard.json tests/integration/test_world_builder.gd
git commit -m "Мир: кусты и плющ на фасаде, трава пучками, декали и плакаты из сгенерированных картинок

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Документация, replay, дорожная карта, CLAUDE.md

**Files:**
- Modify: `docs/replay/02-procedure.md` (раздел «План 5» перед «Известные грабли» + новые грабли), `docs/replay/README.md`, `tools/replay/build_files_md.py` (`tools/images/*.py`, `tools/images/manifest.json`), `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md` (план 5 ВЫПОЛНЕН, список отложенного), `CLAUDE.md` (команды `make images`, структура, грабли плана 5, статус).

- [ ] **Step 1:** Записать в `02-procedure.md` по задачам: команды, контрольные точки (число тестов — по `git grep -h '^func test_' <коммит> -- tests | wc -l`), что смотрели в кадрах; грабли, которые встретились. В `01-decisions.md` решения уже есть (№14–19).
- [ ] **Step 2:** `make replay`; `rm -rf .godot && make test` → всё зелёное.
- [ ] **Step 3:** Коммит «Документация плана 5…».

---

## Самопроверка плана

- **Покрытие спека 2.8:** кот — задачи 2, 3, 4, 5; свет/небо/лужи/пост — 6; VFX — 7; мир — 8; картинки — 1 (и их использование в 6, 7, 8). Hit-stop — сознательно нет (см. отклонения).
- **Имена:** `Toon.apply(root, width, character)`, `Toon.make_outline(width, jitter)`, `Effects.dust/hearts/sparkles/trail/zzz/leaves`, `Cat.squash/flash/flashing/was_on_floor`, `CameraRig.shake/shake_left`, `CatFace.blink_in/blink_left/BLINK_TIME`, `LegScaler.drop`, `TailWiggle`, `WorldBuilder.decals_built/water_built`, `FoodDef.icon/icon_path`, `cat_eyes.group_bbox/_attach(obj, arm, bone)`, `cat_fluff.build_fluff`.
- **Review Focus → тесты:** 1 → `test_flash_turns_white_then_restores_skin` (7); 2 → проверки `alpha` обводки в `test_camera_rig_fades_target_instead_of_hiding` и `test_skin_change_keeps_fade` (5); 3 → `test_short_legs_keep_feet_on_the_ground` (4); 4 → `test_blink_only_over_normal_and_releases` (3); 5 → `test_manifest_covers_all_food_and_files_exist` (1).
- **Зависимости:** 1 даёт картинки для 6 (облака), 7 (сердечко), 8 (декали); 2 вводит `group_bbox/_attach(bone)` для 3; 5 меняет тип обводки, на который опираются тесты прозрачности из плана 4 (переписаны в 5); 7 использует `_body_material` из `test_cat_scene` (есть). Порядок обязателен.

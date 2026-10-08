# Snack Run, план 3: Хаб и прогрессия

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Дать игре прогрессию между сессиями: клубочки, магазин пряжи с улучшениями и скинами, ворота в кафе по сытости, альбом, пауза, заставка, сохранение и район кафе за дорогой.

**Architecture:** Всё новое состояние живёт в `GameState` (клубочки, покупки, скин) с чистыми методами `can_buy/buy/to_dict/from_dict`; магазин и скины — ресурсы `.tres`; сохранение — автозагрузка `SaveGame`, которая пишет JSON только по явному вызову из `Main`; мир расширяется через `WorldBuilder` (ворота, будка, клубочки, кафе) из того же `yard.json`; экраны — `CanvasLayer` с `process_mode = ALWAYS`; камера получает режим «витрина» для магазина.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript, GUT 9.7.1, Blender 5.2.2 (bpy/bmesh), glTF, make.

**Spec:** `docs/superpowers/specs/2026-10-07-snack-run-design.md` (2.4 скины, 2.6 UI, 3.4 прогрессия, 3.5 магазин, 4 экраны и кафе). Дорожная карта: `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`. Образцы: планы 1–2. Памятка: `CLAUDE.md`.

## Global Constraints

- Godot 4.7.2, GDScript, Forward+; `GODOT=/Applications/Godot.app/Contents/MacOS/Godot`, `BLENDER=/Applications/Blender.app/Contents/MacOS/Blender`.
- Модели только скриптами Blender (`tools/blender/gen/*.py`, `SPEC` + `build()`), пропс ≤ 800 треугольников (будка ≤ 1500), палитра `tools/blender/palette.py`.
- Слои коллизий: `Layers.WORLD = 1`, `CAT = 2`, `HAZARD = 4`, `AREA = 8`. Все Area3D: layer 8, mask 2.
- Магазин (спек 3.5), цены в клубочках: восстановить сердечки 2; +1 макс. сердечко 8 и 15 (до 5); зубы 3→4 за 6, 4→5 за 12; бег +15% за 10; тише шаги (конус собаки −30%) за 10; скины по 12.
- Клубочки: 10–15 на район, без респавна, +3 за каждую новую карточку альбома.
- Ворота в кафе открываются при сытости `GameState.SATIETY_GATE = 10`.
- Между сессиями сохраняются: альбом, сытость, клубочки, покупки, выбранный скин, цель. Не сохраняются: сердечки, еда в зубах, позиция.
- Сигнатуры, которые меняются в этом плане: `CatMotion.step(velocity, direction, running, on_floor, jump, delta, speed_mult := 1.0)`, `CatMotion.pick_state(velocity, on_floor, running, speed_mult := 1.0)`.
- Все `get_tree().create_timer(...)` игровых узлов (велосипедист, спавн еды) вызываются с `process_always = false`, чтобы пауза их останавливала.
- Русские тексты, английские идентификаторы, коммиты с `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`; к `.glb`/`.gd` добавлять `*.import`/`*.uid`; в интеграционных тестах `GameState.reset()` в `before_each`, а там, где создаётся `Main`, ещё и `SaveGame.path = "user://test_save.json"` + `SaveGame.clear()` в `after_each`.

## Отклонения от спека, принятые заранее

- Сытость сохраняется между сессиями, поэтому со второго запуска ворота в кафе открыты сразу (спек 3.4 про «открывает ворота» выполняется один раз за прогресс игрока). Полоска сытости при ≥ 10 остаётся полной, подпись «Кафе открыто».
- Скины «серый полосатый» и «сиамский» одноцветными материалами не передать: скин = набор из трёх цветов (тело, грудка, акцент).
- «Котёнок на фоне играет с клубочками» реализован 3D-ракурсом: камера переезжает к будке, вокруг кота катаются три декоративных клубочка, кот в idle. Ввод кота на время экрана блокируется (`Cat.input_enabled = false`).
- Магазин открывается клавишей E (действие `eat`) внутри будки; заход в будку сам по себе ничего не открывает.
- Точка возрождения — маркер будки; стартовая точка игры остаётся `Spawn`.
- Шрифт по умолчанию, иконок еды нет (план 4).

## Review Focus

1. Покупка при нехватке клубочков: ничего не списывается, товар не выдаётся, кнопка выключена. Тест в задаче 2.
2. Повторная покупка одноразового улучшения (скорость, скин): невозможна; «восстановить сердечки» при полных сердечках недоступна. Тест в задаче 2.
3. Повреждённый или чужой `save.json` (не JSON, не словарь, лишние/отсутствующие ключи): игра стартует с чистым состоянием и не падает. Тест в задаче 4.
4. Пауза: велосипедист не выезжает, еда не респавнится, кот не двигается; после закрытия альбома/паузы кот не остаётся замороженным. Тесты в задаче 8.
5. Кот забегает в будку с собакой на хвосте: в будке удара нет, собака через 2 с уходит домой. Тест в задаче 6.

---

## Структура файлов

```
scripts/core/shop_item.gd         # ShopItem (Resource)
scripts/core/shop_catalog.gd      # ShopCatalog.all()
scripts/core/cat_skin.gd          # CatSkin (Resource) + static apply()
scripts/core/skin_catalog.gd      # SkinCatalog.all()/get_by_id()
scripts/autoload/game_state.gd    # + yarn, upgrades, skin, buy, to_dict/from_dict
scripts/autoload/save_game.gd     # SaveGame: path, save_now, load_now, clear
scripts/food/yarn_pickup.gd       # YarnPickup (Area3D)
scripts/world/gate.gd             # Gate (StaticBody3D)
scripts/world/yarn_shop.gd        # YarnShop (Node3D): зона, точка возрождения, декор
scripts/world/world_builder.gd    # + gates, shop, yarn
scripts/player/cat_motion.gd      # + speed_mult
scripts/player/cat.gd             # + input_enabled, in_safe_zone, скин
scripts/player/camera_rig.gd      # + shop_view
scripts/hazards/dog.gd            # + stealth, безопасная зона
scripts/ui/hud.gd                 # + клубочки, «Кафе открыто»
scripts/ui/shop_menu.gd  album_menu.gd  pause_menu.gd  title.gd
scripts/main.gd                   # + сохранение, экраны, магазин, ворота
scenes/food/yarn_pickup.tscn  scenes/world/gate.tscn  scenes/world/yarn_shop.tscn
scenes/ui/shop_menu.tscn  album_menu.tscn  pause_menu.tscn  title.tscn
data/shop/*.tres (10)  data/skins/*.tres (4)  data/layout/yard.json (+gates, shop, yarn, кафе)
tools/blender/gen/{yarn,yarn_shop,cafe_table,chair,umbrella,cafe_sign}.py
tests/unit/test_shop.gd  test_save.gd  test_skins.gd
tests/integration/test_yarn.gd  test_gate.gd  test_yarn_shop.gd  test_shop_menu.gd  test_menus.gd
```

Первое, что можно показать в ролике, появляется после задачи 7 (будка + экран магазина с котом и клубочками).

---

### Task 1: Клубочки

**Files:**
- Modify: `scripts/autoload/game_state.gd`, `scripts/ui/hud.gd`, `scenes/ui/hud.tscn`, `scripts/world/world_builder.gd`, `data/layout/yard.json`
- Create: `tools/blender/gen/yarn.py`, `scripts/food/yarn_pickup.gd`, `scenes/food/yarn_pickup.tscn`
- Test: `tests/unit/test_game_state.gd` (дополнить), `tests/integration/test_yarn.gd`, `tests/integration/test_world_builder.gd` (дополнить)

**Interfaces:**
- Produces: `GameState.yarn: int`, `GameState.YARN_PER_CARD = 3`, `signal yarn_changed(count: int)`, `func add_yarn(n: int) -> void`, `func spend_yarn(n: int) -> bool`; `YarnPickup` (Area3D, `scenes/food/yarn_pickup.tscn`), группа `"yarn"`, при касании кота `GameState.add_yarn(1)` и `queue_free()`; `WorldBuilder` читает `"yarn": [{"pos": [x,y,z]}]`, счётчик `yarn_built`; `Hud.yarn_text() -> String` (например `"◎ 3"`); `assets/models/yarn.glb`.

- [ ] **Step 1: Падающие тесты**

В `tests/unit/test_game_state.gd` добавить:
```gdscript
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
```

`tests/integration/test_yarn.gd`:
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
```

В `tests/integration/test_world_builder.gd` добавить:
```gdscript
func test_yarn_balls_in_layout_stand_on_something() -> void:
	var world := _yard_with_floor()
	await wait_physics_frames(3)
	var data := BuilderScript.load_layout("res://data/layout/yard.json")
	assert_between(data["yarn"].size(), 10, 15, "10–15 клубочков на район (спек 3.4)")
	var space := world.get_world_3d().direct_space_state
	for y in world.find_children("*", "YarnPickup", true, false):
		var pos: Vector3 = (y as Node3D).global_position
		var ray := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.1, 0), pos + Vector3(0, -3, 0), Layers.WORLD)
		var hit := space.intersect_ray(ray)
		assert_false(hit.is_empty(), "под клубочком %s пусто" % pos)
		if not hit.is_empty():
			assert_lt(pos.y - hit["position"].y, 0.3, "клубочек %s висит в воздухе" % pos)
		assert_eq(_prop_at(world, pos + Vector3(0, 0.1, 0)), "", "клубочек %s внутри пропса" % pos)
```
И в `test_build_from_dictionary_counts_nodes` добавить в словарь `"yarn": [{"pos": [3, 0, 3]}]` и проверку `assert_eq(b.yarn_built, 1)`.

Run: `make test-godot` → красный (`add_yarn` не существует, `yarn_pickup.tscn` нет, `yarn_built` нет).

- [ ] **Step 2: GameState**

В `scripts/autoload/game_state.gd`:
```gdscript
signal yarn_changed(count: int)
const YARN_PER_CARD := 3
var yarn := 0
```
В `reset()` добавить `yarn = 0` и `yarn_changed.emit(yarn)`. В `eat_all()` в ветке новой карточки (`if not album.has(f.id):`) добавить `yarn += YARN_PER_CARD`, а после цикла — `yarn_changed.emit(yarn)`. Новые методы:
```gdscript
func add_yarn(n: int) -> void:
	yarn += n
	yarn_changed.emit(yarn)


func spend_yarn(n: int) -> bool:
	if n > yarn:
		return false
	yarn -= n
	yarn_changed.emit(yarn)
	return true
```

- [ ] **Step 3: Модель и пикап**

`tools/blender/gen/yarn.py`:
```python
"""Клубочек пряжи 0,16 м: сфера с двумя лентами-торами."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.2}


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
Run: `make assets ONLY=yarn` → `ОК yarn`.

`scripts/food/yarn_pickup.gd`:
```gdscript
class_name YarnPickup
extends Area3D
## Клубочек: валюта магазина. Лежит в труднодоступном месте, не респавнится (спек 3.4).

@onready var _visual: Node3D = $Visual
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
	GameState.add_yarn(1)
	set_deferred("monitoring", false)
	queue_free()
```

`scenes/food/yarn_pickup.tscn`:
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

- [ ] **Step 4: WorldBuilder, HUD, раскладка**

В `scripts/world/world_builder.gd`: константа `const YarnScene := preload("res://scenes/food/yarn_pickup.tscn")`, поле `var yarn_built := 0`, в `build()` после спавнов:
```gdscript
	for y in data.get("yarn", []):
		_build_yarn(y)
```
и метод:
```gdscript
func _build_yarn(y: Dictionary) -> void:
	var node := YarnScene.instantiate() as YarnPickup
	_container("Yarn").add_child(node)
	node.global_position = _v3(y["pos"])
	yarn_built += 1
```

В `scenes/ui/hud.tscn` добавить узел:
```
[node name="Yarn" type="Label" parent="."]
offset_left = 24.0
offset_top = 92.0
offset_right = 224.0
offset_bottom = 124.0
theme_override_colors/font_color = Color(0.706, 0.427, 0.710, 1)
theme_override_font_sizes/font_size = 24
text = "◎ 0"
```
В `scripts/ui/hud.gd`: `@onready var _yarn: Label = $Yarn`, в `_ready()` `GameState.yarn_changed.connect(_on_yarn)` и `_on_yarn(GameState.yarn)`, методы:
```gdscript
func yarn_text() -> String:
	return _yarn.text


func _on_yarn(count: int) -> void:
	_yarn.text = "◎ %d" % count
```

В `data/layout/yard.json` добавить ключ `"yarn"` (12 штук, все на опоре: пол, площадка лестницы y=1,0, верх коробки-стопки 0,6, сиденье лавки 0,45, под машинами):
```json
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
    {"pos": [9.2, 0.0, -11.0]},
    {"pos": [-9.4, 0.0, 10.9]}
  ]
```
(`[-10.9, 0.5, -11.0]` — центр второй ступени: её коллайдер `offset [0, 0.25, 0.5]`, size `[1.2, 0.5, 0.5]` → z −11,25…−10,75, верх y 0,5; площадка z −9,55…−8,35, верх 1,0; сиденье лавки верх 0,5; `[1.9, 0, 10.5]` — у правого пилона арки, вне его коллайдера x 1,2…1,7. Каждая позиция должна проходить инвариант «стоит на опоре и не внутри коллайдера».)

Run: `make import && make test-godot` → зелёный, включая инвариант «на опоре». Если клубочек у лестницы висит: сверить с коллайдерами лестницы в JSON и подвинуть по z.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_state.gd scripts/ui scenes/ui scripts/world/world_builder.gd data/layout/yard.json tools/blender/gen/yarn.py assets/models/yarn.glb assets/models/yarn.glb.import scripts/food/yarn_pickup.gd scripts/food/yarn_pickup.gd.uid scenes/food/yarn_pickup.tscn tests
git commit -m "Клубочки: валюта, бонус за карточки, пикапы из раскладки, счётчик в HUD

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Товары магазина и покупки

**Files:**
- Create: `scripts/core/shop_item.gd`, `scripts/core/shop_catalog.gd`, `data/shop/{refill_hearts,max_heart_4,max_heart_5,mouth_4,mouth_5,speed,quiet,skin_black,skin_grey,skin_siamese}.tres`
- Modify: `scripts/autoload/game_state.gd`
- Test: `tests/unit/test_shop.gd`

**Interfaces:**
- Produces: `ShopItem` (Resource): `id: StringName`, `display_name: String`, `price: int`, `kind: String` (`"refill"`, `"max_heart"`, `"mouth"`, `"speed"`, `"quiet"`, `"skin"`), `value: int` (новый максимум сердечек / вместимость зубов; для остальных 0), `skin_id: StringName`, `requires: StringName` (id предпосылки или пусто), `order: int`; `ShopCatalog.all() -> Array[ShopItem]` (по `order`), `ShopCatalog.get_by_id(id) -> ShopItem`; `GameState`: `var upgrades := {}` (id → true), `var skin: StringName = &"orange"`, `var speed_mult := 1.0`, `var stealth_mult := 1.0`, `signal upgrade_bought(id: StringName)`, `signal skin_changed(id: StringName)`, `func can_buy(item: ShopItem) -> bool`, `func buy(item: ShopItem) -> bool`, `func owns(id: StringName) -> bool`, `func select_skin(id: StringName) -> bool` (только купленный или `&"orange"`), `func owned_skins() -> Array[StringName]`.

- [ ] **Step 1: Падающий тест**

`tests/unit/test_shop.gd`:
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
	assert_true(gs.can_buy(_item("refill_hearts")) == false)

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

Run: `make test-godot` → `Identifier "ShopCatalog" not declared`.

- [ ] **Step 2: Ресурсы**

`scripts/core/shop_item.gd`:
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

`scripts/core/shop_catalog.gd`:
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

Десять `.tres` по одному шаблону (`data/shop/refill_hearts.tres`):
```
[gd_resource type="Resource" script_class="ShopItem" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/core/shop_item.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"refill_hearts"
display_name = "Восстановить сердечки"
price = 2
kind = "refill"
value = 0
skin_id = &""
requires = &""
order = 1
```
Остальные (меняются только поля):
- `max_heart_4`: «+1 сердечко (до 4)», 8, `max_heart`, value 4, requires пусто, order 2.
- `max_heart_5`: «+1 сердечко (до 5)», 15, `max_heart`, value 5, requires `&"max_heart_4"`, order 3.
- `mouth_4`: «Зубы вмещают 4», 6, `mouth`, value 4, order 4.
- `mouth_5`: «Зубы вмещают 5», 12, `mouth`, value 5, requires `&"mouth_4"`, order 5.
- `speed`: «Бег быстрее на 15%», 10, `speed`, order 6.
- `quiet`: «Тише шаги: собака видит хуже», 10, `quiet`, order 7.
- `skin_black`: «Скин: чёрный с белой грудкой», 12, `skin`, skin_id `&"black"`, order 8.
- `skin_grey`: «Скин: серый», 12, `skin`, skin_id `&"grey"`, order 9.
- `skin_siamese`: «Скин: сиамский», 12, `skin`, skin_id `&"siamese"`, order 10.
(Удобно сгенерировать одним Python-циклом, как `.tres` еды в плане 2.)

- [ ] **Step 3: GameState**

Добавить в `scripts/autoload/game_state.gd`:
```gdscript
signal upgrade_bought(id: StringName)
signal skin_changed(id: StringName)

const SPEED_BONUS := 1.15
const STEALTH_BONUS := 0.7
const DEFAULT_SKIN := &"orange"

var upgrades := {}                       # id товара -> true
var skin: StringName = DEFAULT_SKIN
var speed_mult := 1.0
var stealth_mult := 1.0
```
В `reset()`: `upgrades = {}`, `skin = DEFAULT_SKIN`, `_apply_upgrades()`, `skin_changed.emit(skin)`. Методы:
```gdscript
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
```

Run: `make import && make test-godot` → 8 тестов `test_shop.gd` зелёные, старые не сломаны.

- [ ] **Step 4: Commit**

```bash
git add scripts/core/shop_item.gd scripts/core/shop_catalog.gd scripts/core/*.uid data/shop scripts/autoload/game_state.gd tests/unit/test_shop.gd tests/unit/test_shop.gd.uid
git commit -m "Магазин как данные: 10 товаров, покупки и улучшения в GameState

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Применение улучшений: скорость, тихие шаги, скины

**Files:**
- Create: `scripts/core/cat_skin.gd`, `scripts/core/skin_catalog.gd`, `data/skins/{orange,black,grey,siamese}.tres`
- Modify: `scripts/player/cat_motion.gd`, `scripts/player/cat.gd`, `scripts/hazards/dog.gd`
- Test: `tests/unit/test_cat_motion.gd` (дополнить), `tests/unit/test_skins.gd`, `tests/integration/test_dog.gd` (дополнить), `tests/integration/test_cat_scene.gd` (дополнить)

**Interfaces:**
- Produces: `CatMotion.step(..., delta, speed_mult := 1.0)` и `pick_state(velocity, on_floor, running, speed_mult := 1.0)`; `CatSkin` (Resource): `id`, `display_name`, `body: Color`, `belly: Color`, `accent: Color`; `static func CatSkin.apply(model: Node, skin: CatSkin) -> int` (число перекрашенных поверхностей; поверхности узнаются по `resource_name` материала: `sr_cat_orange` → body, `sr_cream` → belly, `sr_coral` → accent); `SkinCatalog.all()`, `SkinCatalog.get_by_id(id) -> CatSkin`; `Cat` перекрашивается при `GameState.skin_changed` и использует `GameState.speed_mult`; `Dog.sees_cat()` использует `VISION_HALF_ANGLE * GameState.stealth_mult`.

- [ ] **Step 1: Падающие тесты**

В `tests/unit/test_cat_motion.gd`:
```gdscript
func test_speed_mult_scales_walk_and_state_threshold() -> void:
	var v := Vector3.ZERO
	for i in 120:
		v = CatMotion.step(v, Vector3(0, 0, -1), false, true, false, D, 1.15)
	assert_almost_eq(v.z, -CatMotion.WALK_SPEED * 1.15, 0.01)
	assert_eq(CatMotion.pick_state(v, true, false, 1.15), &"walk", "ускоренная ходьба — всё ещё walk")
	assert_eq(CatMotion.pick_state(Vector3(0, 0, -4.6), true, true, 1.15), &"run")
```

`tests/unit/test_skins.gd`:
```gdscript
extends GutTest

func test_catalog_has_four_skins() -> void:
	assert_eq(SkinCatalog.all().size(), 4)
	var black := SkinCatalog.get_by_id(&"black")
	assert_not_null(black)
	assert_eq(black.body, Color("#394151"))
	assert_eq(black.belly, Color("#FCD3A1"))

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
	assert_eq((mi.get_surface_override_material(0) as StandardMaterial3D).albedo_color, Color("#394151"))
	assert_eq((mi.get_surface_override_material(1) as StandardMaterial3D).albedo_color, Color.WHITE, "чужой материал не тронут")
```

В `tests/integration/test_cat_scene.gd`:
```gdscript
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
				assert_eq(m.albedo_color, Color("#394151"), "тело перекрашено в чёрный")
	assert_true(found, "у кота есть поверхность тела")
	GameState.reset()
```

В `tests/integration/test_dog.gd`:
```gdscript
func test_quiet_upgrade_narrows_dog_cone() -> void:
	cat.global_position = Vector3(3.0, 0.05, -3.4)   # ≈41° от носа собаки: внутри 45°, вне 31,5°
	await wait_physics_frames(3)
	assert_true(dog.sees_cat(), "без улучшения видит на 41°")
	GameState.add_yarn(10)
	GameState.buy(ShopCatalog.get_by_id(&"quiet"))
	assert_false(dog.sees_cat(), "с тихими шагами конус 31,5° — не видит")
```

Run: `make test-godot` → красный (`SkinCatalog`, лишние аргументы `step`).

- [ ] **Step 2: Реализация**

`scripts/player/cat_motion.gd` — заменить сигнатуры:
```gdscript
static func step(velocity: Vector3, direction: Vector3, running: bool, on_floor: bool, jump: bool, delta: float, speed_mult := 1.0) -> Vector3:
	var speed := (RUN_SPEED if running else WALK_SPEED) * speed_mult
```
(остальное тело без изменений) и
```gdscript
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

`scripts/core/cat_skin.gd`:
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

`scripts/core/skin_catalog.gd`:
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

Четыре `data/skins/*.tres` (шаблон `orange.tres`):
```
[gd_resource type="Resource" script_class="CatSkin" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/core/cat_skin.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"orange"
display_name = "Рыжий"
body = Color(0.980392, 0.682353, 0.270588, 1)
belly = Color(0.988235, 0.827451, 0.631373, 1)
accent = Color(0.960784, 0.454902, 0.521569, 1)
```
- `black.tres`: id `black`, «Чёрный с белой грудкой», body `#394151` = `Color(0.223529, 0.254902, 0.317647, 1)`, belly `#FCD3A1`, accent `#F57485`.
- `grey.tres`: id `grey`, «Серый», body `#5A5C6B` = `Color(0.352941, 0.360784, 0.419608, 1)`, belly `#FCD3A1`, accent `#B46DB5` = `Color(0.705882, 0.427451, 0.709804, 1)`.
- `siamese.tres`: id `siamese`, «Сиамский», body `#FCD3A1`, belly `#D3AB87` = `Color(0.827451, 0.670588, 0.529412, 1)`, accent `#394151`.

В `scripts/visual/toon.gd`, в `_apply_to_mesh`, после `mat = (src as StandardMaterial3D).duplicate()` добавить `mat.resource_name = src.resource_name` (скины узнают поверхности по имени материала; `duplicate()` имя может не сохранить).

`scripts/player/cat.gd`: в `_ready()` после `Toon.apply(...)`:
```gdscript
	_apply_skin(GameState.skin)
	GameState.skin_changed.connect(_apply_skin)
```
метод:
```gdscript
func _apply_skin(id: StringName) -> void:
	var skin := SkinCatalog.get_by_id(id)
	if skin:
		CatSkin.apply(_model, skin)
```
В `_physics_process` два вызова: `velocity = CatMotion.step(velocity, dir, running, is_on_floor(), jump, delta, GameState.speed_mult)` и `state = CatMotion.pick_state(velocity, is_on_floor(), running, GameState.speed_mult)` (ветки с нулевым направлением множителя не требуют).

`scripts/hazards/dog.gd`, в `sees_cat()`:
```gdscript
	return Perception.in_cone(global_position, forward, c.global_position, VISION_HALF_ANGLE * GameState.stealth_mult, VISION_RANGE)
```

Run: `make import && make test-godot` → зелёный.

- [ ] **Step 3: Commit**

```bash
git add scripts/core data/skins scripts/player scripts/hazards/dog.gd tests
git commit -m "Улучшения в деле: множитель скорости, тихие шаги, скины кота

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Сохранение между сессиями

**Files:**
- Create: `scripts/autoload/save_game.gd`
- Modify: `project.godot` (автозагрузка `SaveGame`), `scripts/autoload/game_state.gd` (`to_dict/from_dict`), `scripts/main.gd` (загрузка при старте, сохранение по событиям и при закрытии окна)
- Test: `tests/unit/test_save.gd`, `tests/integration/test_hit.gd` и `tests/integration/test_main.gd` (переопределить путь сохранения)

**Interfaces:**
- Produces: автозагрузка `SaveGame`: `var path := "user://save.json"`, `func save_now() -> bool`, `func load_now() -> bool` (false, если файла нет или он повреждён; состояние при этом сбрасывается в чистое), `func clear() -> void` (удаляет файл), `const VERSION = 1`; `GameState.to_dict() -> Dictionary` (ключи `version, album, satiety, yarn, upgrades, skin, goal_target, goal_done`), `GameState.from_dict(d: Dictionary) -> void` (терпит отсутствующие ключи и неверные типы, пересчитывает улучшения, `hearts = max_hearts`, `mouth = []`, эмитит все сигналы). `Main` сохраняет при `album_changed`, `satiety_changed`, `yarn_changed`, `upgrade_bought`, `skin_changed` и при `NOTIFICATION_WM_CLOSE_REQUEST`; `Main.autosave := true`.

- [ ] **Step 1: Падающий тест**

`tests/unit/test_save.gd`:
```gdscript
extends GutTest

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const TEST_PATH := "user://test_save_unit.json"

func before_each() -> void:
	GameState.reset()
	SaveGame.path = TEST_PATH
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()
	GameState.reset()

func test_round_trip_keeps_progress_but_not_hearts_or_mouth() -> void:
	GameState.add_yarn(20)
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
	assert_eq(GameState.yarn, 20 - 10 - 12 + 3)
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
```

В `tests/integration/test_hit.gd` и `tests/integration/test_main.gd` в начало `before_each()` добавить `SaveGame.path = "user://test_save.json"` и `SaveGame.clear()`, и добавить `func after_each() -> void: SaveGame.clear()`. Также в `test_hit.gd` добавить:
```gdscript
func test_main_autosaves_on_progress() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	GameState.eat_all()
	await wait_process_frames(1)
	assert_true(FileAccess.file_exists(SaveGame.path), "после съедания прогресс сохранён")
```

Run: `make test-godot` → `Identifier "SaveGame" not declared`.

- [ ] **Step 2: Реализация**

`scripts/autoload/save_game.gd`:
```gdscript
extends Node
## Сохранение прогресса в JSON. Пишет только по явному вызову save_now() (из Main).

const VERSION := 1

var path := "user://save.json"


func save_now() -> bool:
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
	var parsed = JSON.parse_string(text)
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

В `scripts/autoload/game_state.gd`:
```gdscript
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
(В `reset()` уже есть `_apply_upgrades()` из задачи 2.)

`project.godot`, секция `[autoload]`, после `GameState`:
```ini
SaveGame="*res://scripts/autoload/save_game.gd"
```

`scripts/main.gd`: поле `var autosave := true`; в `_ready()` перед созданием кота: `SaveGame.load_now()`, а в конце:
```gdscript
	for sig in [GameState.album_changed, GameState.satiety_changed, GameState.yarn_changed, GameState.upgrade_bought, GameState.skin_changed]:
		sig.connect(_on_progress_changed.unbind(1))
```
и методы:
```gdscript
func _on_progress_changed() -> void:
	if autosave:
		SaveGame.save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave:
		SaveGame.save_now()
```
(`unbind(1)` снимает единственный аргумент сигнала; у всех пяти сигналов ровно один аргумент.)

Run: `make import && make test-godot` → зелёный. Если `test_hit`/`test_main` оставляют `user://test_save.json`, проверить `after_each`.

- [ ] **Step 3: Commit**

```bash
git add scripts/autoload/save_game.gd scripts/autoload/save_game.gd.uid scripts/autoload/game_state.gd project.godot scripts/main.gd tests
git commit -m "Сохранение прогресса: SaveGame, to_dict/from_dict, автосохранение из Main

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Ворота в кафе по сытости

**Files:**
- Create: `scripts/world/gate.gd`, `scenes/world/gate.tscn`
- Modify: `scripts/world/world_builder.gd` (ключ `gates`), `data/layout/yard.json`, `scripts/main.gd` (вспышка HUD), `scripts/ui/hud.gd` (подпись «Кафе открыто»)
- Test: `tests/integration/test_gate.gd`, `tests/integration/test_world_builder.gd` (дополнить)

**Interfaces:**
- Produces: `Gate` (StaticBody3D, `scenes/world/gate.tscn`): `@export var satiety_required := 10`, `@export var size := Vector3(2.4, 2.6, 0.3)`, `var open: bool`, `signal opened`, `func refresh(satiety: int) -> void`; закрытые ворота: `collision_layer = Layers.WORLD`, 5 вертикальных прутьев (`MeshInstance3D` с `BoxMesh`, материал `#394151` unshaded) видимы; открытые: `collision_layer = 0`, прутья скрыты. `WorldBuilder`: `"gates": [{"pos", "rot", "size", "satiety"}]`, `gates_built`, контейнер `Gates`. `Hud.satiety_label_text() -> String` («Сытость 3/10» или «Кафе открыто»).

- [ ] **Step 1: Падающие тесты**

`tests/integration/test_gate.gd`:
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

В `tests/integration/test_world_builder.gd`: в словарь первого теста добавить `"gates": [{"pos": [0, 0, 5], "satiety": 10}]` и `assert_eq(b.gates_built, 1)`; в `test_arch_opening_and_tree_sides_are_passable` заменить проверку проёма арки на:
```gdscript
	assert_eq(_prop_at(world, Vector3(0, 0.5, 10.5)), "gate_0", "в проёме арки стоят закрытые ворота")
	GameState.satiety = GameState.SATIETY_GATE
	GameState.satiety_changed.emit(GameState.satiety)
	await wait_physics_frames(2)
	assert_eq(_prop_at(world, Vector3(0, 0.5, 10.5)), "", "после открытия проём свободен")
```
(Вызов `_prop_at` исключает только `Floor`, ворота — обычный `StaticBody3D` в слое WORLD, их имя `gate_0`.)

Run: `make test-godot` → красный.

- [ ] **Step 2: Реализация**

`scripts/world/gate.gd`:
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

@onready var _shape: CollisionShape3D = $Collision
@onready var _bars: Node3D = $Bars


func _ready() -> void:
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

`scenes/world/gate.tscn`:
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

`scripts/world/world_builder.gd`: `const GateScene := preload("res://scenes/world/gate.tscn")`, `var gates_built := 0`, в `build()` после дороги и до опасностей:
```gdscript
	for g in data.get("gates", []):
		_build_gate(g)
```
метод:
```gdscript
func _build_gate(g: Dictionary) -> void:
	var node := GateScene.instantiate() as Gate
	node.name = "gate_%d" % gates_built
	node.satiety_required = int(g.get("satiety", GameState.SATIETY_GATE))
	node.size = _v3(g.get("size", [2.4, 2.6, 0.3]))
	_container("Gates").add_child(node)
	node.global_position = _v3(g["pos"])
	node.rotation_degrees.y = float(g.get("rot", 0))
	gates_built += 1
```

`data/layout/yard.json`: добавить ключ
```json
  "gates": [{"pos": [0, 0, 10.5], "rot": 0, "size": [2.4, 2.6, 0.3], "satiety": 10}],
```

В `scenes/ui/hud.tscn` добавить:
```
[node name="SatietyLabel" type="Label" parent="."]
offset_left = 232.0
offset_top = 62.0
offset_right = 460.0
offset_bottom = 86.0
theme_override_font_sizes/font_size = 16
text = "Сытость 0/10"
```
В `scripts/ui/hud.gd` `@onready var _satiety_label: Label = $SatietyLabel`, в `_on_satiety`:
```gdscript
	_satiety_label.text = "Кафе открыто" if value >= GameState.SATIETY_GATE else "Сытость %d/%d" % [value, GameState.SATIETY_GATE]
```
и `func satiety_label_text() -> String: return _satiety_label.text`.

`scripts/main.gd` в конце `_ready()`:
```gdscript
	for g in get_tree().get_nodes_in_group("gates"):
		g.opened.connect(func() -> void: hud.flash_bell("🎉 Арка в кафе открыта!", 3.0))
```
и в `Gate._ready()` первой строкой `add_to_group("gates")`.

Run: `make import && make test-godot` → зелёный. `make shot`: в проёме арки (далеко впереди) видны тёмные прутья.

- [ ] **Step 3: Commit**

```bash
git add scripts/world scenes/world data/layout/yard.json scripts/main.gd scripts/ui scenes/ui tests
git commit -m "Ворота в кафе: закрыты до сытости 10, открываются с вспышкой в HUD

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Будка пряжи: модель, безопасная зона, точка возрождения, декор

**Files:**
- Create: `tools/blender/gen/yarn_shop.py`, `scripts/world/yarn_shop.gd`, `scenes/world/yarn_shop.tscn`
- Modify: `scripts/world/world_builder.gd` (ключ `shop`), `data/layout/yard.json`, `scripts/player/cat.gd` (`in_safe_zone`, `input_enabled`), `scripts/hazards/dog.gd`, `scripts/main.gd` (`respawn_position()`), `scripts/player/camera_rig.gd` (`shop_view`)
- Test: `tests/integration/test_yarn_shop.gd`, `tests/integration/test_hit.gd` (точка возрождения), `tests/integration/test_dog.gd` (безопасная зона)

**Interfaces:**
- Produces: `assets/models/yarn_shop.glb` (будка 2,2×2,2×2,4 м, открытый перёд по −Z Godot); `YarnShop` (Node3D, `scenes/world/yarn_shop.tscn`, группа `"yarn_shop"`): `@onready var zone: Area3D`, `func respawn_position() -> Vector3` (маркер `Respawn` внутри будки), `var cat_inside: bool`, `signal cat_entered`, `signal cat_exited`, декор `YarnPlay` (3 шарика, катаются по кругу r 0,5 м, скорость 1 рад/с); `WorldBuilder`: `"shop": {"pos", "rot"}` → один узел, `shop_built`; `Cat`: `var in_safe_zone := false` (ставит зона), `var input_enabled := true` (при false ввод игнорируется, кот стоит), `take_hit` игнорирует удары при `in_safe_zone`; `Dog`: кот в безопасной зоне считается спрятанным (`sees_cat()` false и `cat_hidden` true для `ChaseBrain`); `Main.respawn_position() -> Vector3` (будка, иначе `Spawn`); `CameraRig`: `var shop_view := false`, `const SHOP_OFFSET := Vector3(1.4, 0.6, 1.4)` (камера у кота спереди-сбоку, смотрит на кота).

- [ ] **Step 1: Модель**

`tools/blender/gen/yarn_shop.py`:
```python
"""Будка «Пряжа»: пол, задняя и две боковые стенки, навес, полка с клубочками.
Открытый перёд по +Y Blender (= -Z Godot), задняя стенка на -Y Blender (= +Z Godot)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.6}


def build():
	floor = lib.rounded_box("yarn_shop", (2.2, 2.2, 0.08), bevel=0.02, segments=1, material="sand")
	floor.location.z = 0.04
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
Run: `make assets ONLY=yarn_shop` → `ОК`.

- [ ] **Step 2: Падающие тесты**

`tests/integration/test_yarn_shop.gd`:
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
```

В `tests/integration/test_dog.gd`:
```gdscript
func test_safe_zone_cancels_chase() -> void:
	# Review Focus 5
	cat.global_position = Vector3(0, 0.05, -4)
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	cat.in_safe_zone = true
	await wait_seconds(2.3)
	assert_eq(dog.brain.state, ChaseBrain.State.RETURN, "в безопасной зоне собака теряет кота через 2 с")
```

В `tests/integration/test_hit.gd` заменить две строки про `spawn` на:
```gdscript
	var spawn: Vector3 = main.respawn_position()
	assert_lt(cat.global_position.distance_to(spawn), 0.5)
	assert_true(cat.in_safe_zone or main.find_child("YarnShop", true, false) == null, "возрождение в будке")
```
В `test_world_builder.gd` первый тест: добавить `"shop": {"pos": [4, 0, 4], "rot": 0}` и `assert_eq(b.shop_built, 1)`.

Run: `make import && make test-godot` → красный.

- [ ] **Step 3: Реализация**

`scripts/world/yarn_shop.gd`:
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

`scenes/world/yarn_shop.tscn` (будка смотрит открытым передом по −Z; зона и маркер внутри):
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

[node name="Zone" type="Area3D" parent="."]

[node name="Shape" type="CollisionShape3D" parent="Zone"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
shape = SubResource("zone")

[node name="Respawn" type="Marker3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0.2)

[node name="YarnPlay" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.08, -0.2)
```
(Задняя стенка будки в glb на Blender −Y = Godot +Z, поэтому коллайдер `Back` на z +1,04.)

`scripts/world/world_builder.gd`: `const YarnShopScene := preload("res://scenes/world/yarn_shop.tscn")`, `var shop_built := 0`, в `build()` после ворот:
```gdscript
	if data.has("shop"):
		_build_shop(data["shop"])
```
```gdscript
func _build_shop(s: Dictionary) -> void:
	var node := YarnShopScene.instantiate() as YarnShop
	node.name = "YarnShop"
	add_child(node)
	node.global_position = _v3(s["pos"])
	node.rotation_degrees.y = float(s.get("rot", 0))
	shop_built += 1
```

`data/layout/yard.json`: добавить `"shop": {"pos": [-4.5, 0, -1.5], "rot": 0}` (открытый перёд на −Z, то есть в сторону стены двора; чтобы вход смотрел на спавн, `"rot": 180`). Взять `"rot": 180`: тогда задняя стенка на z −2,54, вход с z −0,46 к спавну (0, 0, 0). Проверить, что точки спавна/укрытия не внутри (инвариант теста уже есть; ближайшие: коробка (−2, −1) на x −2,3…−1,7 — чисто).

`scripts/player/cat.gd`: поля `var in_safe_zone := false` и `var input_enabled := true`; в `take_hit()` условие `if invulnerable_left > 0.0 or stunned_left > 0.0 or hidden or in_safe_zone: return`; в `_physics_process` после обработки оглушения:
```gdscript
	if not input_enabled:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		state = CatMotion.pick_state(velocity, is_on_floor(), false)
		return
```

`scripts/hazards/dog.gd`: в `sees_cat()` условие `if c == null or c.get("hidden") or c.get("in_safe_zone"): return false`; в `_physics_process` `var cat_hidden: bool = c != null and (bool(c.get("hidden")) or bool(c.get("in_safe_zone")))`.

`scripts/player/camera_rig.gd`: `var shop_view := false`, `const SHOP_OFFSET := Vector3(1.4, 0.6, 1.4)`; в `_physics_process` после вычисления `goal`:
```gdscript
	if shop_view:
		var want := target.global_position + SHOP_OFFSET
		global_position = global_position.lerp(want, 1.0 - exp(-SMOOTH * delta))
		look_at(target.global_position + Vector3(0, 0.15, 0), Vector3.UP)
		_arm.spring_length = 0.0
		return
	_arm.spring_length = DISTANCE
	rotation = Vector3(0, _yaw, 0)
```
(при выходе из режима витрины поворот возвращается к `_yaw`; `SpringArm3D` снова 1,8 м.)

`scripts/main.gd`: метод
```gdscript
func respawn_position() -> Vector3:
	var shop := get_tree().get_first_node_in_group("yarn_shop")
	if shop:
		return shop.respawn_position()
	return $DistrictYard/Spawn.global_position
```
и в `respawn_cat()` заменить `$DistrictYard/Spawn.global_position` на `respawn_position()`.

Run: `make import && make test-godot` → зелёный. `make shot SHOT=build/p3task6.png`: слева от кота будка с сиреневыми стенками и коралловой крышей, внутри катаются клубочки.

- [ ] **Step 4: Commit**

```bash
git add tools/blender/gen/yarn_shop.py assets/models/yarn_shop.glb assets/models/yarn_shop.glb.import scripts/world scenes/world data/layout/yard.json scripts/player scripts/hazards/dog.gd scripts/main.gd tests
git commit -m "Будка пряжи: безопасная зона, точка возрождения, клубочки-декор, витринная камера

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Экран магазина

**Files:**
- Create: `scripts/ui/shop_menu.gd`, `scenes/ui/shop_menu.tscn`, `scripts/ui/menu_input.gd`
- Modify: `scripts/main.gd`, `scenes/main.tscn`
- Test: `tests/integration/test_shop_menu.gd`

**Interfaces:**
- Produces: `ShopMenu` (CanvasLayer, `scenes/ui/shop_menu.tscn`, `process_mode = ALWAYS`, `layer = 20`): `signal closed`, `func open() -> void`, `func close() -> void`, `var is_open: bool`, `func item_buttons() -> Array[Button]` (в порядке `ShopCatalog.all()`, текст «Название — N ◎», `disabled = not GameState.can_buy(item)`, купленные помечены «✓»), `func refresh() -> void`, `func yarn_text() -> String`; клавиша `ui_cancel` (Esc) закрывает. `Main`: `var shop_menu: ShopMenu`, `func open_shop() -> void` / `func close_shop() -> void` (блокируют ввод кота, включают `camera_rig.shop_view`, прячут HUD); открытие по действию `eat`, когда `cat.in_safe_zone` и кот не спрятан.

- [ ] **Step 1: Падающий тест**

`tests/integration/test_shop_menu.gd`:
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
	assert_eq(main.shop_menu.yarn_text(), "◎ 0")
	assert_true(speed_btn.text.ends_with("✓"))
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
```

Run: `make test-godot` → красный (`open_shop` нет).

- [ ] **Step 2: Реализация**

`scripts/ui/shop_menu.gd`:
```gdscript
class_name ShopMenu
extends CanvasLayer
## Экран магазина пряжи: список товаров, баланс, покупка (спек 3.5).

signal closed

var is_open := false
var _buttons: Array[Button] = []

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
		b.pressed.connect(_on_buy.bind(item))
		_list.add_child(b)
		_buttons.append(b)
	_close.pressed.connect(close)
	GameState.yarn_changed.connect(func(_c: int) -> void: refresh())
	GameState.hearts_changed.connect(func(_h: int, _m: int) -> void: refresh())
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
	_yarn.text = "◎ %d" % GameState.yarn
	var items := ShopCatalog.all()
	for i in _buttons.size():
		var item := items[i]
		var owned := item.kind != "refill" and GameState.owns(item.id)
		_buttons[i].text = "%s — %d ◎%s" % [item.display_name, item.price, " ✓" if owned else ""]
		_buttons[i].disabled = owned or not GameState.can_buy(item)


func _on_buy(item: ShopItem) -> void:
	if GameState.buy(item):
		refresh()
```

`scenes/ui/shop_menu.tscn`:
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
offset_left = -420.0
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
text = "◎ 0"

[node name="List" type="VBoxContainer" parent="Panel/Margin/VBox"]
layout_mode = 2

[node name="Close" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Закрыть (Esc)"
```

`scenes/main.tscn`: добавить `[ext_resource type="PackedScene" path="res://scenes/ui/shop_menu.tscn" id="5"]` и узел `[node name="ShopMenu" parent="." instance=ExtResource("5")]`.

Ввод меню опрашивается, а не ловится событиями: `Input.action_press` в тестах не порождает `InputEvent`, а при паузе дерева `Main` (`PROCESS_MODE_INHERIT`) замирает вместе с котом. Поэтому отдельный узел `scripts/ui/menu_input.gd` с `process_mode = ALWAYS`:
```gdscript
class_name MenuInput
extends Node
## Опрашивает клавиши меню (E в будке, Tab, Esc) и дёргает Main. Работает и на паузе.

@onready var _main: Node = get_parent()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("eat"):
		_main.call("on_interact_pressed")
```
В `scenes/main.tscn` добавить узел `[node name="MenuInput" type="Node" parent="."]` со `script = ExtResource("8")` (ресурс `[ext_resource type="Script" path="res://scripts/ui/menu_input.gd" id="8"]`).

`scripts/main.gd`: `@onready var shop_menu: ShopMenu = $ShopMenu`; в `_ready()`: `shop_menu.closed.connect(close_shop)`; методы:
```gdscript
func on_interact_pressed() -> void:
	if _cat and _cat.in_safe_zone and not _cat.hidden and not shop_menu.is_open:
		open_shop()


func open_shop() -> void:
	_cat.input_enabled = false
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
```
(`close_shop()` вызывается и кнопкой, и сигналом `closed`: первый вызов закрывает меню и выходит, сигнал `closed` вызывает его снова и возвращает управление. Esc в магазине обрабатывает `MenuInput` в задаче 8.)

Run: `make import && make test-godot` → зелёный. `make run`: подойти к будке, нажать E — камера подъезжает к коту, рядом катаются клубочки, справа панель товаров; Esc закрывает.

- [ ] **Step 3: Commit**

```bash
git add scripts/ui scenes/ui/shop_menu.tscn scripts/main.gd scenes/main.tscn tests/integration/test_shop_menu.gd tests/integration/test_shop_menu.gd.uid
git commit -m "Экран магазина: товары, баланс, покупка, витринная камера и блокировка ввода

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Альбом, пауза, заставка; таймеры уважают паузу

**Files:**
- Create: `scripts/ui/album_menu.gd`, `scenes/ui/album_menu.tscn`, `scripts/ui/pause_menu.gd`, `scenes/ui/pause_menu.tscn`, `scripts/ui/title.gd`, `scenes/ui/title.tscn`
- Modify: `scripts/autoload/input_setup.gd` (действия `album`, `pause`), `scripts/main.gd`, `scenes/main.tscn`, `project.godot` (`run/main_scene`), `Makefile` (`shot` снимает `main.tscn`), `scripts/hazards/cyclist.gd`, `scripts/food/food_spawn_point.gd` (`create_timer(..., false)`)
- Test: `tests/integration/test_menus.gd`, `tests/unit/test_cat_motion.gd` (действия)

**Interfaces:**
- Produces: действия `album` (Tab, JOY_BUTTON_Y) и `pause` (Escape, JOY_BUTTON_START); `AlbumMenu` (CanvasLayer, `scenes/ui/album_menu.tscn`): `is_open`, `open()/close()`, `signal closed`, `func cards() -> Array[Control]` (по `FoodCatalog.all()` отсортированным по редкости, у карточки `name = id`, дочерний `Label` `Name` с названием или «???», `Label` `Count` «×N», `ColorRect` `Rarity` цвета редкости, `modulate.a = 0.4` у закрытых); `PauseMenu` (CanvasLayer): `is_open`, `open()/close()`, кнопки `Continue`, `ResetProgress`, `Quit`, сигналы `resumed`, `reset_requested`; `Title` (`scenes/ui/title.tscn`, главная сцена): кнопка «Играть» → `change_scene_to_file("res://scenes/main.tscn")`, «Выход» → `quit()`. `Main`: `album_menu`, `pause_menu`, `func toggle_album()`, `func toggle_pause()`, `func reset_progress()` (очищает сохранение, `GameState.reset()`, возрождает кота); пока открыт альбом или пауза — `get_tree().paused = true`.

- [ ] **Step 1: Падающие тесты**

В `tests/unit/test_cat_motion.gd`, в `test_input_actions_registered`, расширить список действий: `..., "cam_left", "cam_right", "album", "pause"`.

`tests/integration/test_menus.gd`:
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
	assert_eq(cards.size(), 8)
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
	await wait_seconds(0.6)
	assert_signal_not_emitted(c, "bell", "во время паузы велосипедист не звонит")
	var p0: Vector3 = cat.global_position
	Input.action_press("move_forward")
	await wait_seconds(0.3)
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
	assert_false(FileAccess.file_exists(SaveGame.path))
	assert_false(get_tree().paused)

func test_title_scene_has_play_button() -> void:
	var title := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	add_child_autofree(title)
	var play := title.find_child("Play", true, false) as Button
	assert_not_null(play)
	assert_eq(play.text, "Играть")
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/ui/title.tscn")
```

Run: `make test-godot` → красный.

- [ ] **Step 2: Действия и таймеры**

`scripts/autoload/input_setup.gd`: в `ACTIONS` добавить `"album": [KEY_TAB]`, `"pause": [KEY_ESCAPE]`; в `PAD_BUTTONS` — `"album": JOY_BUTTON_Y`, `"pause": JOY_BUTTON_START`.

`scripts/hazards/cyclist.gd`: оба `get_tree().create_timer(x)` → `get_tree().create_timer(x, false)`. `scripts/food/food_spawn_point.gd`: `get_tree().create_timer(delay, false)`.

- [ ] **Step 3: Альбом**

`scripts/ui/album_menu.gd`:
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
	var card := PanelContainer.new()
	card.name = String(f.id)
	card.custom_minimum_size = Vector2(150, 90)
	var v := VBoxContainer.new()
	card.add_child(v)
	var strip := ColorRect.new()
	strip.name = "Rarity"
	strip.color = Rarity.COLORS[f.tier]
	strip.custom_minimum_size = Vector2(0, 8)
	v.add_child(strip)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)
	var count := Label.new()
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(count)
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
```

`scenes/ui/album_menu.tscn`:
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
columns = 4

[node name="Close" type="Button" parent="Panel/Margin/VBox"]
layout_mode = 2
text = "Закрыть (Tab)"
```

- [ ] **Step 4: Пауза и заставка**

`scripts/ui/pause_menu.gd`:
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

`scenes/ui/pause_menu.tscn`:
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

`scripts/ui/title.gd`:
```gdscript
extends Control
## Заставка: главная сцена проекта.

@onready var _play: Button = $VBox/Play
@onready var _quit: Button = $VBox/Quit


func _ready() -> void:
	_play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_quit.pressed.connect(func() -> void: get_tree().quit())
	_play.grab_focus()
```

`scenes/ui/title.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/ui/title.gd" id="1"]

[node name="Title" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.396, 0.620, 0.812, 1)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -180.0
offset_top = -140.0
offset_right = 180.0
offset_bottom = 140.0
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

[node name="Play" type="Button" parent="VBox"]
layout_mode = 2
text = "Играть"

[node name="Quit" type="Button" parent="VBox"]
layout_mode = 2
text = "Выход"
```

`project.godot`: `run/main_scene="res://scenes/ui/title.tscn"`. `Makefile`, цель `shot`:
```makefile
shot: import
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 res://scenes/main.tscn ++ --screenshot=$(SHOT)
```

`scenes/main.tscn`: ресурсы `id="6"` (`album_menu.tscn`) и `id="7"` (`pause_menu.tscn`), узлы `AlbumMenu`, `PauseMenu`.

`scripts/main.gd`: `@onready var album_menu: AlbumMenu = $AlbumMenu`, `@onready var pause_menu: PauseMenu = $PauseMenu`; в `_ready()`:
```gdscript
	album_menu.closed.connect(func() -> void: _set_paused(false))
	pause_menu.resumed.connect(func() -> void: _set_paused(false))
	pause_menu.reset_requested.connect(reset_progress)
```
В `scripts/ui/menu_input.gd` расширить `_process` (Esc — один выход для всех экранов, Tab — альбом):
```gdscript
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_main.call("on_back_pressed")
	elif Input.is_action_just_pressed("album"):
		_main.call("on_album_pressed")
	elif Input.is_action_just_pressed("eat"):
		_main.call("on_interact_pressed")
```
методы `Main`:
```gdscript
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
```
и:
```gdscript
func _set_paused(on: bool) -> void:
	get_tree().paused = on


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
	SaveGame.clear()
	GameState.reset()
	if pause_menu.is_open:
		pause_menu.close()
	_set_paused(false)
	respawn_cat()
```
`Main` остаётся `PROCESS_MODE_INHERIT` (иначе его дети — кот, опасности, спавны — унаследовали бы `ALWAYS` и не замирали бы). Клавиши на паузе ловит `MenuInput` (`ALWAYS`), а `toggle_pause()`/`toggle_album()` — обычные методы, их можно звать и на паузе.

Run: `make import && make test-godot` → зелёный. Проверить `make shot` (снимает игру, а не заставку) и `make run` (стартует заставка, «Играть» ведёт в двор; Tab — альбом, Esc — пауза).

- [ ] **Step 5: Commit**

```bash
git add scripts/ui scenes/ui scripts/main.gd scenes/main.tscn project.godot Makefile scripts/autoload/input_setup.gd scripts/hazards/cyclist.gd scripts/food/food_spawn_point.gd tests
git commit -m "Альбом, пауза и заставка; таймеры игры уважают паузу

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Кафе за дорогой

**Files:**
- Create: `tools/blender/gen/cafe_table.py`, `chair.py`, `umbrella.py`, `cafe_sign.py`
- Modify: `data/layout/yard.json`, `scripts/hazards/wasp.gd` (`height` из JSON)
- Test: `tests/integration/test_world_builder.gd` (дополнить)

**Interfaces:**
- Produces: `assets/models/cafe_table.glb` (столешница r 0,45 на высоте 0,75), `chair.glb`, `umbrella.glb` (купол r 1,2 на 2,2 м), `cafe_sign.glb`; раскладка кафе за дорогой: 5 столов с коллайдерами столешниц, 8 стульев, 3 зонта, вывеска, 3 стены-модуля на z=28, 2 бака, кусты; точки спавна: редкая у столов, очень редкая на столах (y 0,75), легендарная под осой на десертном столе; оса №2 с `height` 1,1; клубочки 2 шт. на столах (в пределах 10–15 на район учтены в задаче 1 — заменить две наземные позиции на столы). `Wasp.configure` читает `height`.

- [ ] **Step 1: Ужесточить тест**

В `tests/integration/test_world_builder.gd`, в `test_real_yard_layout_loads`, расширить проверки:
```gdscript
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
	assert_eq(data["hazards"].size(), 4, "две осы, собака, велосипедист")
```
Run: `make test-godot` → красный.

- [ ] **Step 2: Генераторы**

`tools/blender/gen/cafe_table.py`:
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
`tools/blender/gen/chair.py`:
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
`tools/blender/gen/umbrella.py`:
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
`tools/blender/gen/cafe_sign.py`:
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
Run: `make assets` → все `ОК`.

- [ ] **Step 3: Раскладка и оса на высоте**

`scripts/hazards/wasp.gd`, `configure()`:
```gdscript
	radius = float(hz.get("radius", radius))
	height = float(hz.get("height", height))
```

В `data/layout/yard.json` добавить к `props`:
```json
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
    {"model": "puddle", "pos": [-6, 0, 19], "rot": 30}
```
(Зонты стоят рядом со столами, а не в центре: стойка в центре стола попала бы в коллайдер и под точку спавна. Стулья — не укрытия: по спеку укрытия в кафе не нужны.) Стул ставится спинкой к столу при `rot 180` на −z стороне... спинка стула в модели на −Y Blender = +Z Godot; стул на z 16,2 с `rot 180` обращён спинкой к −z, сиденьем к столу — верно; стул на z 17,8 с `rot 0` спинкой к +z — верно.

К `spawn_points` добавить:
```json
    {"pos": [-4, 0, 15.3], "allowed": [1]},
    {"pos": [4, 0, 15.3], "allowed": [1]},
    {"pos": [0, 0.75, 17], "allowed": [2]},
    {"pos": [-2, 0.75, 21], "allowed": [2]},
    {"pos": [2, 0.75, 21], "allowed": [3]},
    {"pos": [7, 0, 20], "allowed": [0, 1]}
```
К `hazards` добавить `{"type": "wasp", "pos": [2, 1.1, 21], "radius": 1.2, "height": 1.1}`. В `yarn` заменить две наземные позиции `[9.2, 0.0, -11.0]` и `[-9.4, 0.0, 10.9]` на `[-4, 0.75, 17]` и `[4, 0.75, 17]` (на столах, где нет еды).

Сквозной проход: дорога z=12 между аркой (10,5) и кафе; велосипедист сбивает на дороге. Заставить кота пересекать дорогу — именно задумка спека («быстрый путь, но опасно»).

Run: `make import && make test-godot` → зелёный, включая инварианты «на опоре» для точек на столах (коллайдер столешницы 0,9×0,06 на y 0,69…0,75) и клубочков.

`make shot SHOT=build/p3task9.png`: за аркой видны зонты и столы. Дополнительно общий план сверху (камера `(2, 16, 30)` → `(0, 0, 14)`) — кафе за дорогой читается.

- [ ] **Step 4: Commit**

```bash
git add tools/blender/gen assets/models data/layout/yard.json scripts/hazards/wasp.gd tests/integration/test_world_builder.gd
git commit -m "Кафе за дорогой: столы, стулья, зонты, вывеска, еда на столах, вторая оса

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Документация воспроизведения и дорожная карта

**Files:**
- Modify: `docs/replay/02-procedure.md`, `docs/replay/03-files.md` (через `make replay`), `docs/superpowers/plans/2026-10-07-snack-run-roadmap.md`, `CLAUDE.md`

- [ ] **Step 1:** В `docs/replay/02-procedure.md` перед «Известные грабли» добавить раздел «План 3. Хаб и прогрессия» по задачам 1–9: файлы (ссылка на приложение), команды сборки, контрольные точки (число тестов, что видно на `make shot`), все `Ruling:` из журнала как грабли.
- [ ] **Step 2:** `make replay`; в дорожной карте заголовок плана 3 → «ВЫПОЛНЕН <дата>», список отложенных мелочей обновить; в `CLAUDE.md` обновить структуру (`scripts/core/shop_*`, `cat_skin`, `save_game`, `scripts/ui/*`, `scripts/world/gate.gd`, `yarn_shop.gd`), статус («следующий шаг: план 4 «Полировка под ролик»») и грабли этого плана.
- [ ] **Step 3:** `rm -rf .godot && make test` → зелёный. Коммит «Документация плана 3: процедура воспроизведения, приложение файлов, статус».

---

## Готово, когда

- `rm -rf .godot && make test` зелёный (12 Blender-тестов, ≈120 GUT-тестов).
- `make run`: заставка → «Играть»; клубочки собираются и считаются в HUD; E в будке открывает магазин с котом и клубочками в кадре; покупки меняют скорость, конус собаки, окрас; ворота в арке открываются при сытости 10 с вспышкой; за дорогой кафе с едой на столах; Tab — альбом с карточками по редкостям, Esc — пауза; после перезапуска альбом, клубочки, покупки и скин на месте, сердечки полные.
- `docs/replay/` дописан, `make replay` выполнен, дорожная карта и `CLAUDE.md` обновлены.

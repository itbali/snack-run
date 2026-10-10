extends GutTest

const HudScene := preload("res://scenes/ui/hud.tscn")

var hud

func before_each() -> void:
	KeyBindings.path = "user://test_settings.cfg"   # не читать настройки владельца
	KeyBindings.reset()
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
	assert_eq(hud.satiety_label_text(), "До порта 25/50", "план 17: после парка цель — ворота в порт")
	GameState.satiety = 50
	GameState.satiety_changed.emit(50)
	assert_eq(hud.satiety_label_text(), "Порт открыт")
	GameState.satiety = 4
	GameState.satiety_changed.emit(4)
	assert_eq(hud.satiety_label_text(), "Сытость 4/10")

func test_port_gate_matches_game_state_constant() -> void:
	var gates: Array = WorldBuilder.load_layout("res://data/layout/park.json")["gates"]
	assert_true(gates.any(func(g): return int(g["satiety"]) == GameState.PORT_GATE), "ворота в порт — GameState.PORT_GATE")

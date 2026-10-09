extends GutTest

const HudScene := preload("res://scenes/ui/hud.tscn")

var hud

func before_each() -> void:
	GameState.reset()
	hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)

func test_hearts_reflect_state() -> void:
	assert_eq(hud.hearts_text(), "♥♥♥")
	GameState.take_hit()
	assert_eq(hud.hearts_text(), "♥♥♡")

func test_mouth_slots_show_names() -> void:
	GameState.pick_up(FoodCatalog.get_by_id(&"pizza"))
	assert_eq(hud.mouth_names(), ["Пицца", "", ""])

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

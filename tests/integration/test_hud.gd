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
	assert_eq((hud.get_node("Satiety") as ProgressBar).value, float(GameState.SATIETY_GATE))
	assert_eq((hud.get_node("Goal") as Label).text, "Открой новых карточек: 1/3")

func test_bell_flash_shows_and_hides() -> void:
	hud.flash_bell("🔔 Велосипед!", 0.1)
	assert_true((hud.get_node("Bell") as Label).visible)
	await wait_seconds(0.25)
	assert_false((hud.get_node("Bell") as Label).visible)

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

func test_interact_does_not_open_shop_while_paused() -> void:
	cat.global_position = main.respawn_position()
	await wait_physics_frames(3)
	main.toggle_pause()
	main.on_interact_pressed()
	assert_false(main.shop_menu.is_open, "на паузе магазин не открывается")
	main.toggle_pause()

func test_owned_skins_can_be_reselected() -> void:
	GameState.add_yarn(24)
	main.open_shop()
	var buttons: Array = main.shop_menu.item_buttons()
	var black_btn: Button = buttons[7]
	var grey_btn: Button = buttons[8]
	black_btn.pressed.emit()
	grey_btn.pressed.emit()
	assert_eq(GameState.skin, &"grey")
	assert_false(black_btn.disabled, "купленный скин можно надеть снова")
	assert_true(black_btn.text.ends_with("надеть"))
	black_btn.pressed.emit()
	assert_eq(GameState.skin, &"black")
	assert_eq(GameState.yarn, 0, "повторный выбор бесплатен")
	assert_true(black_btn.text.ends_with("✓ надет"))
	main.close_shop()

extends GutTest
## План 17: экран «Управление и помощь» — видеть и менять клавиши.

const MainScene := preload("res://scenes/main.tscn")
var main

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	KeyBindings.path = "user://test_settings.cfg"
	KeyBindings.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(3)

func after_each() -> void:
	KeyBindings.reset()
	KeyBindings.path = "user://settings.cfg"
	SaveGame.clear()

func test_pause_menu_opens_controls_with_all_actions() -> void:
	main.toggle_pause()
	var btn := main.pause_menu.find_child("Controls", true, false) as Button
	assert_not_null(btn, "в паузе есть «Управление и помощь»")
	btn.pressed.emit()
	var menu = main.controls_menu
	assert_true(menu.is_open)
	assert_eq(menu.rows().size(), KeyBindings.REBINDABLE.size())
	assert_true(menu.help_text().contains("укрыт"), "есть краткие правила")
	assert_eq(menu.key_button("jump").text, "Пробел")
	menu.close()
	main.toggle_pause()

func test_rebind_through_menu_and_cancel_with_esc() -> void:
	main.toggle_pause()
	var menu = main.controls_menu
	menu.open()
	menu.start_capture("jump")
	assert_eq(menu.key_button("jump").text, "нажмите клавишу…")
	menu.handle_key(KEY_ESCAPE)
	assert_eq(KeyBindings.keys_of("jump"), [KEY_SPACE], "Esc — отмена, а не новая клавиша")
	menu.start_capture("jump")
	menu.handle_key(KEY_J)
	assert_eq(KeyBindings.keys_of("jump"), [KEY_J])
	assert_eq(menu.key_button("jump").text, "J")
	assert_true(FileAccess.file_exists(KeyBindings.path), "настройки сохранены")
	menu.reset_bindings()
	assert_eq(KeyBindings.keys_of("jump"), [KEY_SPACE])
	menu.close()
	main.toggle_pause()

func test_close_labels_follow_bindings() -> void:
	KeyBindings.rebind("album", KEY_J)
	main.toggle_album()
	assert_true((main.album_menu.find_child("Close", true, false) as Button).text.contains("(J)"))
	main.toggle_album()

func test_controls_menu_is_drawn_above_pause_and_tutorial() -> void:
	# Кадр плана 17: меню паузы рисовалось поверх «Управления».
	for other in [main.pause_menu, main.album_menu, main.shop_menu, main.tutorial]:
		assert_gt(main.controls_menu.layer, (other as CanvasLayer).layer, "выше %s" % other.name)

func test_gamepad_back_cancels_capture_and_closes() -> void:
	main.toggle_pause()
	var menu = main.controls_menu
	(main.pause_menu.find_child("Controls", true, false) as Button).grab_focus()   # геймпад: A на «Управлении»
	menu.open()
	menu.start_capture("jump")
	main.on_cancel_pressed()
	assert_eq(menu.capturing, "", "B отменяет ожидание")
	assert_true(menu.is_open)
	await wait_process_frames(1)
	main.on_cancel_pressed()
	assert_false(menu.is_open, "второе B закрывает экран")
	assert_true(main.pause_menu.is_open, "пауза остаётся")
	assert_true(main.pause_menu.find_child("Controls", true, false).has_focus(), "фокус вернулся на кнопку")
	main.toggle_pause()

func test_panel_is_opaque() -> void:
	var sb := (main.controls_menu.get_node("Panel") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(sb)
	if sb:
		assert_almost_eq(sb.bg_color.a, 1.0, 0.01, "сквозь панель не просвечивает пауза")

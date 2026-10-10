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
	assert_eq(cards.size(), 20, "8 карточек двора, 6 парка и 6 порта")
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
	assert_not_null((pizza.get_node("Icon") as TextureRect).texture, "у карточки иконка")
	assert_lt((donut.get_node("Icon") as TextureRect).self_modulate.r, 0.5, "закрытая карточка — тёмный силуэт")
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
	# Ожидания GUT сами стоят на паузе, поэтому ждём таймером с process_always = true.
	await get_tree().create_timer(0.6, true).timeout
	assert_signal_not_emitted(c, "bell", "во время паузы велосипедист не звонит")
	var p0: Vector3 = cat.global_position
	Input.action_press("move_forward")
	await get_tree().create_timer(0.3, true).timeout
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
	assert_false(FileAccess.file_exists(SaveGame.path), "после сброса файла сохранения нет (reset() не должен тут же писать нули)")
	assert_false(get_tree().paused)

func test_title_offers_continue_only_with_save() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/ui/title.tscn")
	var title := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title.switch_scenes = false
	add_child_autofree(title)
	assert_false((title.get_node("VBox/Continue") as Button).visible, "без сохранения «Продолжить» скрыта")
	assert_eq((title.get_node("VBox/Play") as Button).text, "Новая игра")
	assert_not_null((title.get_node("Background") as TextureRect).texture, "фон заставки — арт")
	SaveGame.save_now()
	var title2 := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title2.switch_scenes = false
	add_child_autofree(title2)
	assert_true((title2.get_node("VBox/Continue") as Button).visible, "с сохранением «Продолжить» видна")
	title2.new_game()
	assert_false(FileAccess.file_exists(SaveGame.path), "«Новая игра» стирает сохранение")

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

func test_album_with_twenty_cards_fits_the_window() -> void:
	# План 13: 20 карточек (двор, парк, порт) — панель альбома целиком в окне 1280×720.
	var m := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(m)
	await wait_process_frames(3)
	m.toggle_album()
	await wait_process_frames(3)
	var panel := m.album_menu.get_node("Panel") as Control
	var view := Rect2(Vector2.ZERO, panel.get_viewport_rect().size)
	var need := panel.get_combined_minimum_size()
	# Окно игры 1280×720 (stretch canvas_items): в headless окно другое, поэтому меряем минимальный размер панели.
	assert_lte(need.y, 700.0, "альбом по высоте влезает в 720: %s" % need)
	assert_lte(need.x, 1260.0, "альбом по ширине влезает в 1280: %s" % need)
	m.toggle_album()

func test_dev_album_fill_does_not_touch_the_save() -> void:
	# Ревью плана 13: ++ --album открывал все карточки и сохранял их в настоящий save.json.
	DevTools.fill_album(main)
	assert_false(main.autosave, "кадр альбома не пишет сохранение")
	main.autosave = true

func test_title_has_controls_screen() -> void:
	# План 17: «Управление» на заставке — до начала игры видно и меняются клавиши.
	var title := (load("res://scenes/ui/title.tscn") as PackedScene).instantiate()
	title.set("switch_scenes", false)
	add_child_autofree(title)
	await wait_process_frames(2)
	var btn := title.find_child("Controls", true, false) as Button
	assert_not_null(btn)
	btn.pressed.emit()
	var menu := title.find_child("ControlsMenu", true, false) as ControlsMenu
	assert_not_null(menu)
	assert_true(menu.is_open)
	menu.close()

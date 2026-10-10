extends GutTest
## План 17: обучение по шагам с текущими клавишами; один раз; можно пропустить.

const MainScene := preload("res://scenes/main.tscn")
var main
var cat

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	KeyBindings.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(5)
	cat = main.find_child("Cat", true, false)

func after_each() -> void:
	for a in ["move_forward", "run", "jump"]:
		Input.action_release(a)
	KeyBindings.reset()
	SaveGame.clear()

func _tut():
	return main.tutorial

func test_fresh_game_walks_through_all_steps() -> void:
	var t = _tut()
	assert_true(t.visible)
	assert_eq(t.step_id(), &"move")
	assert_true(t.text().contains("W"), "подсказка с клавишами: %s" % t.text())
	cat.global_position += Vector3(3, 0, 0)
	await wait_physics_frames(3)
	assert_eq(t.step_id(), &"run")
	Input.action_press("move_forward")
	Input.action_press("run")
	await wait_physics_frames(20)
	Input.action_release("run")
	Input.action_release("move_forward")
	assert_eq(t.step_id(), &"jump")
	KeyBindings.rebind("jump", KEY_J)
	await wait_physics_frames(2)
	assert_true(t.text().contains("J"), "после переназначения подсказка показывает новую клавишу")
	Input.action_press("jump")
	await wait_physics_frames(3)
	Input.action_release("jump")
	await wait_physics_frames(3)
	assert_eq(t.step_id(), &"food")
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	await wait_physics_frames(2)
	assert_eq(t.step_id(), &"hide")
	cat.hidden = true
	await wait_physics_frames(2)
	assert_eq(t.step_id(), &"eat")
	GameState.eat_all()
	await wait_physics_frames(2)
	assert_eq(t.step_id(), &"shop")
	cat.hidden = false
	main.open_shop()
	await wait_physics_frames(2)
	main.close_shop()
	await wait_physics_frames(2)
	assert_true(GameState.tutorial_done)
	assert_false(t.visible)
	assert_true(GameState.to_dict().get("tutorial_done", false), "в сохранении")

func test_skip_from_pause_menu() -> void:
	main.toggle_pause()
	var btn := main.pause_menu.find_child("SkipTutorial", true, false) as Button
	assert_not_null(btn)
	assert_true(btn.visible)
	btn.pressed.emit()
	assert_true(GameState.tutorial_done)
	assert_false(_tut().visible)
	assert_false(btn.visible, "после пропуска кнопки нет")
	main.toggle_pause()

func test_not_shown_when_done() -> void:
	GameState.finish_tutorial()
	SaveGame.save_now()   # перезапуск: Main читает сохранение
	var m2 = MainScene.instantiate()
	add_child_autofree(m2)
	await wait_physics_frames(3)
	assert_false(m2.tutorial.visible)

func test_old_save_with_progress_skips_tutorial() -> void:
	var d := GameState.to_dict()
	d.erase("tutorial_done")
	d["satiety"] = 12
	GameState.from_dict(d)
	assert_true(GameState.tutorial_done, "старое сохранение с прогрессом — без обучения")
	d["satiety"] = 0
	d["album"] = {}
	GameState.from_dict(d)
	assert_false(GameState.tutorial_done, "пустое старое сохранение — с обучением")

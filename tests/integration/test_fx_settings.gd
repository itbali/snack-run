extends GutTest
## План 18: размытие вдали (DoF) с настройкой, блики на воде, пылинки днём и светлячки ночью.

const MainScene := preload("res://scenes/main.tscn")
var main

func before_each() -> void:
	GameState.reset()
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	KeyBindings.path = "user://test_settings.cfg"
	GameSettings.path = "user://test_settings.cfg"
	GameSettings.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(3)

func after_each() -> void:
	GameSettings.reset()
	GameSettings.path = "user://settings.cfg"
	KeyBindings.path = "user://settings.cfg"
	SaveGame.clear()

func _camera() -> Camera3D:
	return main.find_child("Camera3D", true, false) as Camera3D

func test_far_blur_on_by_default_and_toggle_persists() -> void:
	var attrs := _camera().attributes as CameraAttributesPractical
	assert_not_null(attrs)
	assert_true(attrs.dof_blur_far_enabled, "по умолчанию даль размыта")
	assert_gt(attrs.dof_blur_far_distance, 15.0, "кот и ближний план — резкие")
	main.toggle_pause()
	main.controls_menu.open()
	var cb := main.controls_menu.find_child("Blur", true, false) as CheckButton
	assert_not_null(cb, "переключатель в «Управлении и настройках»")
	cb.button_pressed = false
	assert_false(attrs.dof_blur_far_enabled)
	assert_true(GameSettings.particles, "переключатель размытия не трогает частицы")
	GameSettings.load_saved()
	assert_false(GameSettings.blur, "сохранилось")
	main.controls_menu.close()
	main.toggle_pause()

func test_main_has_ambient_fx() -> void:
	assert_not_null(main.find_child("AmbientFx", true, false))

func test_ambient_particles_by_phase_and_setting() -> void:
	var dn = get_tree().get_first_node_in_group("day_night")   # фаза суток — та, что видит игра (узел Main)
	dn.set("time_scale", 0.0)
	dn.set_time(10.0)
	var fx := AmbientFx.new()
	add_child_autofree(fx)
	await wait_process_frames(3)
	assert_true((fx.get_node("Motes") as CPUParticles3D).emitting, "днём пылинки")
	assert_false((fx.get_node("Fireflies") as CPUParticles3D).emitting)
	dn.set_time(220.0)
	await wait_process_frames(3)
	assert_true((fx.get_node("Fireflies") as CPUParticles3D).emitting, "ночью светлячки")
	GameSettings.set_particles(false, get_tree())
	await wait_process_frames(2)
	assert_false((fx.get_node("Fireflies") as CPUParticles3D).emitting, "частицы выключаются настройкой")

func test_water_has_sparkles() -> void:
	var shader := load("res://assets/shaders/water.gdshader") as Shader
	assert_true(shader.code.contains("sparkle"), "блики на воде")

func test_rebinding_keeps_video_settings() -> void:
	# Ревью плана 18: KeyBindings.save переписывал файл целиком — секция [video] пропадала.
	GameSettings.set_blur(false, get_tree())
	KeyBindings.rebind("jump", KEY_J)
	KeyBindings.save()
	GameSettings.reset()
	GameSettings.load_saved()
	assert_false(GameSettings.blur, "размытие осталось выключенным")
	KeyBindings.reset()

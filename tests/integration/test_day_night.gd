extends GutTest

const LightingScene := preload("res://scenes/world/lighting.tscn")
const DogScene := preload("res://scenes/hazards/dog.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")

var light
var dn

func before_each() -> void:
	GameState.reset()
	light = LightingScene.instantiate()
	add_child_autofree(light)
	dn = light.get_node("DayNight")
	await wait_process_frames(1)

func after_each() -> void:
	get_tree().paused = false

func test_light_follows_time() -> void:
	dn.set_time(50.0)
	var sun := light.get_node("Sun") as DirectionalLight3D
	assert_almost_eq(sun.light_energy, 1.2, 0.01)
	dn.set_time(220.0)
	assert_almost_eq(sun.light_energy, 0.22, 0.01)
	var env: Environment = (light.get_node("WorldEnvironment") as WorldEnvironment).environment
	assert_almost_eq(env.ambient_light_energy, 0.18, 0.01)
	assert_eq(((env.sky.sky_material as ProceduralSkyMaterial).sky_top_color).to_html(false), "0b1633")
	assert_eq(dn.phase, &"night")
	assert_true(DayNight.is_night(get_tree()))

func test_phase_signal_and_lamps() -> void:
	var lamp := SpotLight3D.new()
	lamp.add_to_group("night_lights")
	add_child_autofree(lamp)
	watch_signals(dn)
	dn.set_time(50.0)
	assert_false(lamp.visible, "днём фонарь выключен")
	dn.set_time(200.0)
	assert_signal_emitted_with_parameters(dn, "phase_changed", [&"night"])
	assert_true(lamp.visible, "ночью фонарь горит")

func test_windows_glow_at_night() -> void:
	var b := WorldBuilder.new()
	add_child_autofree(b)
	b.build({"props": [{"model": "wall", "pos": [0, 0, 0]}]})
	var glass: MeshInstance3D = null
	for mi in b.find_children("wall_glass*", "MeshInstance3D", true, false):
		glass = mi
	assert_not_null(glass, "у стены есть стёкла")
	if glass == null:
		return
	dn.set_time(50.0)
	assert_false((glass.get_surface_override_material(0) as StandardMaterial3D).emission_enabled, "днём окна не светятся")
	dn.set_time(220.0)
	var m := glass.get_surface_override_material(0) as StandardMaterial3D
	assert_true(m.emission_enabled, "ночью в окнах тёплый свет")
	assert_eq(m.emission.to_html(false), "ffd9a0")

func test_time_advances_and_pause_stops_it() -> void:
	# Review Focus 1
	dn.set_time(10.0)
	dn.time_scale = 20.0
	await wait_seconds(0.2)
	assert_gt(dn.time, 12.0, "время идёт")
	get_tree().paused = true
	var t0: float = dn.time
	await get_tree().create_timer(0.2, true).timeout
	assert_almost_eq(dn.time, t0, 0.001, "на паузе цикл стоит")

func test_dog_sleeps_through_the_night_and_wakes_by_day() -> void:
	# Review Focus 3
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, -4)
	add_child_autofree(cat)
	var dog = DogScene.instantiate()
	dog.position = Vector3(0, 0.05, 0)
	add_child_autofree(dog)
	dn.set_time(220.0)
	await wait_physics_frames(3)
	assert_false(dog.sees_cat(), "ночью собака спит и не замечает кота")
	dn.set_time(50.0)
	await wait_physics_frames(3)
	assert_true(dog.sees_cat(), "днём снова видит")

func test_without_day_night_it_is_day() -> void:
	# Review Focus 2
	light.free()
	await wait_process_frames(1)
	assert_false(DayNight.is_night(get_tree()))
	assert_eq(DayNight.current_phase(get_tree()), &"day")

func test_hud_shows_phase_icon() -> void:
	var hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)
	dn.set_time(50.0)
	var icon := hud.get_node("%PhaseIcon") as TextureRect
	assert_eq(icon.texture.resource_path, "res://assets/images/ui/sun.png")
	dn.set_time(200.0)
	assert_eq(icon.texture.resource_path, "res://assets/images/ui/moon.png")

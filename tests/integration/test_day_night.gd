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

func test_hold_phases_do_not_rewrite_light_every_frame() -> void:
	# Ревью плана 7 (I1): в фазах удержания небо и материалы не перезаписываются каждый кадр.
	dn.set_time(50.0)
	var w0: int = dn.light_writes
	dn.set_time(60.0)
	dn.set_time(70.0)
	assert_eq(dn.light_writes, w0, "днём свет постоянен — записей нет")
	dn.set_time(160.0)
	assert_gt(dn.light_writes, w0, "на закате свет меняется")

func test_lamp_added_at_night_lights_up() -> void:
	dn.set_time(220.0)
	var lamp := SpotLight3D.new()
	lamp.visible = false
	lamp.add_to_group("night_lights")
	add_child_autofree(lamp)
	await wait_process_frames(2)
	assert_true(lamp.visible, "фонарь, построенный ночью, горит")

func test_night_ends_an_ongoing_chase() -> void:
	# Ревью плана 7 (M1): ночь, наступившая посреди погони, укладывает собаку спать.
	var cat = CatScene.instantiate()
	cat.position = Vector3(0, 0.05, -4)
	add_child_autofree(cat)
	var dog = DogScene.instantiate()
	dog.position = Vector3(0, 0.05, 0)
	add_child_autofree(dog)
	dn.set_time(50.0)
	dn.time_scale = 0.0
	await wait_seconds(1.3)
	assert_eq(dog.brain.state, ChaseBrain.State.CHASE)
	dn.set_time(220.0)
	await wait_physics_frames(3)
	assert_true(dog.brain.state in [ChaseBrain.State.RETURN, ChaseBrain.State.IDLE], "ночью погоня прекращается")

func test_two_lighting_instances_do_not_share_sky() -> void:
	# Ревью плана 7 (M2)
	var other = LightingScene.instantiate()
	add_child_autofree(other)
	await wait_process_frames(1)
	other.get_node("DayNight").time_scale = 0.0
	dn.set_time(220.0)
	var sky_other := ((other.get_node("WorldEnvironment") as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial)
	assert_ne(sky_other.sky_top_color.to_html(false), "0b1633", "у второй сцены своё небо")

func test_hud_binds_even_if_created_before_lighting() -> void:
	# Ревью плана 7 (M3)
	light.free()
	var hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)
	var l2 = LightingScene.instantiate()
	add_child_autofree(l2)
	l2.get_node("DayNight").set_time(220.0)
	await wait_process_frames(2)
	assert_eq((hud.get_node("%PhaseIcon") as TextureRect).texture.resource_path, "res://assets/images/ui/moon.png")

func test_phase_names_parse() -> void:
	assert_almost_eq(DayCycle.parse_time("night"), 225.0, 0.01)
	assert_almost_eq(DayCycle.parse_time("evening"), 165.0, 0.01)
	assert_almost_eq(DayCycle.parse_time("120"), 120.0, 0.01)

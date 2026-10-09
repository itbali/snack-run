extends GutTest

var light

func before_each() -> void:
	light = (load("res://scenes/world/lighting.tscn") as PackedScene).instantiate()
	add_child_autofree(light)
	await wait_process_frames(1)

func test_sun_is_high_warm_and_soft() -> void:
	var sun := light.get_node("Sun") as DirectionalLight3D
	assert_almost_eq(sun.rotation_degrees.x, -65.0, 0.1)
	assert_almost_eq(sun.rotation_degrees.y, 30.0, 0.1)
	assert_almost_eq(sun.light_energy, 1.2, 0.01)
	assert_true(sun.shadow_enabled)
	assert_almost_eq(sun.light_angular_distance, 1.5, 0.01, "мягкая полутень")
	assert_almost_eq(sun.shadow_blur, 1.5, 0.01)
	assert_eq(sun.directional_shadow_mode, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
	assert_almost_eq(sun.directional_shadow_max_distance, 40.0, 0.1, "каскады на 40 м (спек «Масштаб», раздел 5)")

func test_fill_light_from_the_sky_without_shadows() -> void:
	var fill := light.get_node_or_null("Fill") as DirectionalLight3D
	assert_not_null(fill, "заполняющий свет")
	if fill == null:
		return
	assert_false(fill.shadow_enabled)
	assert_almost_eq(fill.light_energy, 0.25, 0.01)
	assert_almost_eq(fill.rotation_degrees.y, 210.0, 0.1)
	assert_eq(fill.light_color.to_html(false), "9fc4e8")

func test_environment_has_ao_ssr_glow_and_clouds() -> void:
	var env: Environment = (light.get_node("WorldEnvironment") as WorldEnvironment).environment
	assert_eq(env.ambient_light_source, Environment.AMBIENT_SOURCE_SKY)
	assert_almost_eq(env.ambient_light_sky_contribution, 1.0, 0.01)
	assert_almost_eq(env.ambient_light_energy, 0.6, 0.01)
	assert_true(env.ssao_enabled)
	assert_almost_eq(env.ssao_radius, 0.3, 0.01)
	assert_true(env.ssr_enabled, "лужи отражают небо")
	assert_true(env.glow_enabled)
	assert_almost_eq(env.glow_hdr_threshold, 1.2, 0.01)
	assert_eq(env.tonemap_mode, Environment.TONE_MAPPER_LINEAR)
	assert_true(env.adjustment_enabled)
	assert_almost_eq(env.adjustment_saturation, 1.1, 0.01)
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	assert_not_null(sky.sky_cover, "слой облаков из сгенерированной картинки")
	if sky.sky_cover:
		assert_eq(sky.sky_cover.resource_path, "res://assets/images/world/clouds.png")

func test_leaves_drift_over_the_yard() -> void:
	assert_not_null(light.get_node_or_null("Leaves"), "листья по ветру")

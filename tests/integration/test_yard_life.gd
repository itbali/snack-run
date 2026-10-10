extends GutTest
## План 20: живой двор — ветер в кронах, бабочки, птицы, прохожие, бельё, дымок из труб, фон звуков.

const MainScene := preload("res://scenes/main.tscn")
var main

func before_each() -> void:
	GameState.reset()
	GameState.tutorial_done = true
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	KeyBindings.path = "user://test_settings.cfg"
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(5)

func after_each() -> void:
	SaveGame.clear()

func _life() -> Node:
	return main.find_child("YardLife", true, false)

func _dn():
	return get_tree().get_first_node_in_group("day_night")

func test_wind_sways_trees_and_laundry() -> void:
	var life := _life()
	assert_not_null(life)
	var swayed: Array = life.call("swaying")
	assert_gt(swayed.size(), 50, "кроны, кусты и бельё на ветру")
	var n := swayed[0] as Node3D
	var r0 := n.rotation
	await wait_physics_frames(20)
	assert_false(n.rotation.is_equal_approx(r0), "качается")
	var lp: Array = (WorldBuilder.load_layout("res://data/layout/yard.json")["props"] as Array).filter(func(p): return p["model"] == "laundry")
	assert_gte(lp.size(), 4, "верёвки с бельём во дворе")

func test_butterflies_by_day_not_at_night() -> void:
	var b := get_tree().get_nodes_in_group("butterflies")
	assert_gte(b.size(), 8)
	assert_true((b[0] as Node3D).visible)
	_dn().set("time_scale", 0.0)
	_dn().set_time(220.0)
	await wait_process_frames(3)
	assert_false((b[0] as Node3D).visible, "ночью бабочки спят")

func test_bird_flock_crosses_the_sky() -> void:
	var flock := main.find_child("SkyBirds", true, false) as Node3D
	assert_not_null(flock)
	assert_gte(flock.get_child_count(), 4)
	var p0 := (flock.get_child(0) as Node3D).global_position
	await wait_physics_frames(30)
	assert_gt((flock.get_child(0) as Node3D).global_position.distance_to(p0), 0.5, "летят")
	assert_gt((flock.get_child(0) as Node3D).global_position.y, 8.0, "над крышами")

func test_pedestrians_walk_and_are_harmless() -> void:
	var peds := get_tree().get_nodes_in_group("pedestrians")
	assert_gte(peds.size(), 3)
	var p := peds[0] as Node3D
	var x0 := p.global_position
	await wait_physics_frames(40)
	assert_gt(p.global_position.distance_to(x0), 0.3, "идут")
	var cat = main.find_child("Cat", true, false)
	cat.global_position = p.global_position
	await wait_physics_frames(10)
	assert_eq(GameState.hearts, 3, "прохожие не бьют")
	assert_false(p.is_in_group("hazards"))

func test_chimneys_smoke() -> void:
	assert_gte(get_tree().get_nodes_in_group("chimney_smoke").size(), 8)

func test_ambience_birds_by_day_crickets_at_night() -> void:
	var amb := main.find_child("Ambience", true, false) as AudioStreamPlayer
	assert_not_null(amb)
	assert_true(amb.playing)
	assert_true(amb.stream.resource_path.ends_with("birds.wav"))
	_dn().set("time_scale", 0.0)
	_dn().set_time(220.0)
	await wait_process_frames(3)
	assert_true(amb.stream.resource_path.ends_with("crickets.wav"), "ночью сверчки")

func test_ambience_loops_whole_file() -> void:
	# Ревью плана 20: loop_end по сжатым байтам — петля 1,6 с вместо 8.
	var amb := main.find_child("Ambience", true, false) as AudioStreamPlayer
	var s := amb.stream as AudioStreamWAV
	assert_almost_eq(float(s.loop_end), s.get_length() * s.mix_rate, s.mix_rate * 0.05, "петля — весь файл")

extends GutTest
## План 21: звуки опасностей слышны только рядом (булькали дождеватели парка на всю карту); музыка день/ночь с громкостью.

const MainScene := preload("res://scenes/main.tscn")
var main

func before_each() -> void:
	GameState.reset()
	GameState.tutorial_done = true
	SaveGame.path = "user://test_save.json"
	SaveGame.clear()
	GameSettings.path = "user://test_settings.cfg"
	KeyBindings.path = "user://test_settings.cfg"
	GameSettings.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(3)

func after_each() -> void:
	SaveGame.clear()
	GameSettings.reset()

func test_far_hazard_sound_is_silent_near_one_is_heard() -> void:
	var cat = main.find_child("Cat", true, false)
	Sfx.reset_counters()
	assert_null(Sfx.play_at(&"sprinkle", cat.global_position + Vector3(60, 0, 0)), "дождеватель в парке не слышен во дворе")
	assert_ne(Sfx.last_played, &"sprinkle")
	var near := Sfx.play_at(&"sprinkle", cat.global_position + Vector3(5, 0, 0))
	assert_not_null(near)
	var mid := Sfx.play_at(&"sprinkle", cat.global_position + Vector3(18, 0, 0))
	assert_lt(mid.volume_db, near.volume_db, "дальше — тише")

func test_hazards_use_positional_sounds() -> void:
	for f in ["sprinkler", "wave", "gull", "pigeon_flock", "forklift", "fisher", "gardener", "dog"]:
		var code := FileAccess.get_file_as_string("res://scripts/hazards/%s.gd" % f)
		assert_false(code.contains("Sfx.play(&"), "%s: звук только через play_at" % f)

func test_no_cyclist_banner() -> void:
	var hud = main.hud
	for c in get_tree().get_nodes_in_group("hazards"):
		if c.has_signal("bell"):
			c.emit_signal("bell")
	await wait_process_frames(2)
	assert_false(hud.get_node("BellPanel").visible, "уведомления о велосипедисте нет")

func test_music_day_and_night_with_volume_setting() -> void:
	assert_true(Music.playing(), "музыка играет")
	assert_true(Music.current_track().contains("day_"))
	get_tree().get_first_node_in_group("day_night").set("time_scale", 0.0)
	get_tree().get_first_node_in_group("day_night").set_time(220.0)
	await wait_seconds(0.3)
	assert_true(Music.current_track().contains("night_"), "ночью — ночная петля")
	GameSettings.set_music(0.0, get_tree())
	assert_almost_eq(Music.volume, 0.0, 0.001)
	GameSettings.load_saved()
	assert_almost_eq(GameSettings.music, 0.0, 0.001, "громкость сохранена")
	GameSettings.set_music(0.7, get_tree())

func test_night_music_keeps_playing_and_day_loops_rotate() -> void:
	# Ревью плана 21 (I2): ночная петля кончалась через 52 с и до утра была тишина.
	var dn = get_tree().get_first_node_in_group("day_night")
	dn.set("time_scale", 0.0)
	dn.set_time(220.0)
	await wait_seconds(0.3)
	var s: AudioStream = Music._a.stream
	assert_true(s is AudioStreamOggVorbis and (s as AudioStreamOggVorbis).loop, "ночная петля зациклена")
	dn.set_time(50.0)
	await wait_seconds(2.5)
	var t0 := Music.current_track()
	Music.set("_play_t", Music.ROTATE)
	await wait_process_frames(3)
	assert_ne(Music.current_track(), t0, "дневные петли сменяются по таймеру")
	assert_true(Music._b.playing, "смена кроссфейдом, старая ещё звучит")

func test_sprinkler_heard_only_close() -> void:
	# Ревью плана 21: три дождевателя ядра парка в 26 м всё ещё булькали в ритм.
	var cat = main.find_child("Cat", true, false)
	assert_null(Sfx.play_at(&"sprinkle", cat.global_position + Vector3(14, 0, 0), 0.1, Sfx.NEAR_RANGE), "дождеватель за 14 м не слышен")
	var code := FileAccess.get_file_as_string("res://scripts/hazards/sprinkler.gd")
	assert_true(code.contains("Sfx.NEAR_RANGE"))

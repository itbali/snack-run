extends GutTest

func before_each() -> void:
	Sfx.reset_counters()

func test_all_six_streams_exist() -> void:
	for key in [&"pickup", &"eat", &"hit", &"meow", &"bark", &"bell"]:
		assert_true(Sfx.has(key), "нет звука %s" % key)

func test_play_assigns_stream_and_counts() -> void:
	var p := Sfx.play(&"eat")
	assert_not_null(p)
	if p:
		assert_eq(p.stream.resource_path, "res://assets/sfx/eat.ogg")
	assert_eq(Sfx.last_played, &"eat")
	assert_eq(Sfx.counts.get(&"eat", 0), 1)
	assert_null(Sfx.play(&"nope"), "неизвестный звук не падает")

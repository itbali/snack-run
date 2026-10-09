extends GutTest
## План 14: чистая логика опасностей порта (спек порта, раздел 3).

func test_gull_dives_only_on_cat_with_food_below() -> void:
	assert_true(Gull.decide(4.0, true, false, false, 0.0, false), "кот с едой в 4 м — пикирует")
	assert_false(Gull.decide(7.0, true, false, false, 0.0, false), "дальше 6 м — нет")
	assert_false(Gull.decide(4.0, false, false, false, 0.0, false), "без еды — нет")
	assert_false(Gull.decide(4.0, true, true, false, 0.0, false), "спрятан — нет")
	assert_false(Gull.decide(4.0, true, false, true, 0.0, false), "в безопасной зоне — нет")
	assert_false(Gull.decide(4.0, true, false, false, 3.0, false), "перерыв — нет")
	assert_false(Gull.decide(4.0, true, false, false, 0.0, true), "ночью спит")

func test_wave_cycle_14s() -> void:
	# 0…3 накат, 3…6 откат, 6…12,5 тихо, 12,5…14 пена перед следующим накатом.
	assert_almost_eq(Wave.front_at(0.0), 0.0, 0.01)
	assert_almost_eq(Wave.front_at(3.0), 5.0, 0.01, "дальше всего через 3 с")
	assert_almost_eq(Wave.front_at(1.5), 2.5, 0.6, "накат идёт")
	assert_almost_eq(Wave.front_at(6.0), 0.0, 0.01, "откатилась")
	assert_almost_eq(Wave.front_at(9.0), 0.0, 0.01)
	assert_almost_eq(Wave.front_at(17.0), 5.0, 0.01, "период 14 с")
	assert_true(Wave.foam(13.0), "пена за 1,5 с")
	assert_false(Wave.foam(10.0))

func test_forklift_states() -> void:
	assert_eq(Forklift.next_state(&"wait", 3.0, 5.0, false), &"wait", "стоит у штабеля")
	assert_eq(Forklift.next_state(&"wait", 5.0, 5.0, false), &"horn", "потом гудит")
	assert_eq(Forklift.next_state(&"horn", 1.0, 5.0, false), &"horn")
	assert_eq(Forklift.next_state(&"horn", 1.5, 5.0, false), &"drive", "через 1,5 с едет")
	assert_eq(Forklift.next_state(&"drive", 2.0, 5.0, true), &"wait", "ночью стоит")
	assert_eq(Forklift.next_state(&"wait", 9.0, 5.0, true), &"wait")

func test_crab_burrow_chase_hide() -> void:
	assert_eq(Crab.decide(&"burrow", 2.5, false, 0.0, 0.0, false), &"chase", "кот ближе 3 м — выбегает")
	assert_eq(Crab.decide(&"burrow", 3.5, false, 0.0, 0.0, false), &"burrow")
	assert_eq(Crab.decide(&"burrow", 3.5, false, 0.0, 0.0, true), &"chase", "ночью радиус 4 м")
	assert_eq(Crab.decide(&"chase", 1.0, true, 1.0, 0.0, false), &"hide", "кот прыгнул над крабом")
	assert_eq(Crab.decide(&"chase", 1.0, false, 5.0, 0.0, false), &"hide", "5 с погони")
	assert_eq(Crab.decide(&"chase", 1.0, false, 2.0, 0.0, false), &"chase")
	assert_eq(Crab.decide(&"hide", 1.0, false, 0.0, 3.0, false), &"hide", "6 с в норке")
	assert_eq(Crab.decide(&"hide", 1.0, false, 0.0, 0.0, false), &"burrow", "потом снова сторожит")

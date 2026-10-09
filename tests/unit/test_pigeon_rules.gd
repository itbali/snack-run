extends GutTest
## Решение стаи голубей (спек этапа 2, раздел 3).

func test_steal_only_from_walking_cat_with_food_near() -> void:
	assert_eq(PigeonFlock.decide(1.2, false, 2, false, false, 0.0, false), &"steal")
	assert_eq(PigeonFlock.decide(2.0, false, 2, false, false, 0.0, false), &"none", "дальше 1,5 м — нет")
	assert_eq(PigeonFlock.decide(1.2, false, 0, false, false, 0.0, false), &"none", "нет еды в зубах")

func test_running_cat_scatters_flock() -> void:
	assert_eq(PigeonFlock.decide(2.2, true, 2, false, false, 0.0, false), &"scatter")
	assert_eq(PigeonFlock.decide(1.0, true, 0, false, false, 0.0, false), &"scatter", "разгоняет и без еды")

func test_no_theft_from_hidden_or_safe_cat_on_cooldown_or_at_night() -> void:
	# Review Focus 1
	assert_eq(PigeonFlock.decide(1.0, false, 2, true, false, 0.0, false), &"none", "спрятался")
	assert_eq(PigeonFlock.decide(1.0, false, 2, false, true, 0.0, false), &"none", "в будке")
	assert_eq(PigeonFlock.decide(1.0, false, 2, false, false, 4.0, false), &"none", "перерыв после кражи")
	assert_eq(PigeonFlock.decide(1.0, false, 2, false, false, 0.0, true), &"none", "ночью спят")

extends GutTest
## План 15: цикл рыбака (спек порта, раздел 4).

func test_fisher_cycle() -> void:
	assert_eq(Fisher.next_phase(&"watch", 5.0, 12.0), &"watch", "смотрит на воду")
	assert_eq(Fisher.next_phase(&"watch", 12.0, 12.0), &"bite", "клюёт")
	assert_eq(Fisher.next_phase(&"bite", 0.5, 12.0), &"bite")
	assert_eq(Fisher.next_phase(&"bite", 1.0, 12.0), &"pull", "вытягивает")
	assert_eq(Fisher.next_phase(&"pull", 1.9, 12.0), &"pull")
	assert_eq(Fisher.next_phase(&"pull", 2.0, 12.0), &"look", "рыба в ведре — смотрит в ведро")
	assert_eq(Fisher.next_phase(&"look", 2.9, 12.0), &"look")
	assert_eq(Fisher.next_phase(&"look", 3.0, 12.0), &"watch", "снова к воде")

func test_shoo_only_close_to_bucket() -> void:
	assert_true(Fisher.shoos(0.8, false, false))
	assert_false(Fisher.shoos(1.2, false, false), "дальше 1 м — нет")
	assert_false(Fisher.shoos(0.5, true, false), "спрятанного не видит")
	assert_false(Fisher.shoos(0.5, false, true), "в безопасной зоне — нет")

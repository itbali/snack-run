extends GutTest

const TEST_PATH := "user://test_save_unit.json"

func before_each() -> void:
	GameState.reset()
	SaveGame.path = TEST_PATH
	SaveGame.clear()

func after_each() -> void:
	SaveGame.clear()
	GameState.reset()

func test_round_trip_keeps_progress_but_not_hearts_or_mouth() -> void:
	GameState.add_yarn(30)
	GameState.buy(ShopCatalog.get_by_id(&"speed"))
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	GameState.pick_up(FoodCatalog.get_by_id(&"donut"))
	GameState.eat_all()
	GameState.take_hit()
	GameState.pick_up(FoodCatalog.get_by_id(&"fish"))
	assert_true(SaveGame.save_now())
	GameState.reset()
	assert_true(SaveGame.load_now())
	assert_eq(GameState.album[&"donut"], 1)
	assert_eq(GameState.satiety, 15)
	assert_eq(GameState.yarn, 30 - 10 - 12 + 3)
	assert_true(GameState.owns(&"speed"))
	assert_almost_eq(GameState.speed_mult, 1.15, 0.001)
	assert_eq(GameState.skin, &"black")
	assert_eq(GameState.goal_done, 1)
	assert_eq(GameState.hearts, GameState.max_hearts, "сердечки не сохраняются, старт с полными")
	assert_eq(GameState.mouth.size(), 0, "еда в зубах не сохраняется")

func test_load_without_file_returns_false_and_keeps_clean_state() -> void:
	assert_false(SaveGame.load_now())
	assert_eq(GameState.yarn, 0)

func test_corrupted_file_gives_clean_state() -> void:
	# Review Focus 3
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{ это не json")
	f.close()
	assert_false(SaveGame.load_now())
	assert_eq(GameState.yarn, 0)
	assert_eq(GameState.album.size(), 0)
	var g := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	g.store_string("[1, 2, 3]")
	g.close()
	assert_false(SaveGame.load_now())
	var h := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	h.store_string('{"version": 1, "yarn": "много", "album": 5, "upgrades": {"speed": true}}')
	h.close()
	assert_true(SaveGame.load_now(), "частично валидный файл принимается")
	assert_eq(GameState.yarn, 0, "строка вместо числа игнорируется")
	assert_eq(GameState.album.size(), 0, "число вместо словаря игнорируется")
	assert_true(GameState.owns(&"speed"))

func test_clear_removes_file() -> void:
	SaveGame.save_now()
	assert_true(FileAccess.file_exists(TEST_PATH))
	SaveGame.clear()
	assert_false(FileAccess.file_exists(TEST_PATH))

func test_taken_yarn_keys_round_trip() -> void:
	GameState.take_yarn("1.5,0.6,1.5")
	assert_eq(GameState.yarn, 1)
	assert_true(GameState.is_yarn_taken("1.5,0.6,1.5"))
	SaveGame.save_now()
	GameState.reset()
	assert_false(GameState.is_yarn_taken("1.5,0.6,1.5"))
	SaveGame.load_now()
	assert_true(GameState.is_yarn_taken("1.5,0.6,1.5"), "список собранных клубочков сохраняется")

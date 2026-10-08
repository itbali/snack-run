extends GutTest

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var gs: Node
var sausage: FoodDef
var donut: FoodDef

func before_each() -> void:
	gs = GameStateScript.new()
	add_child_autofree(gs)
	sausage = FoodCatalog.get_by_id(&"sausage")
	donut = FoodCatalog.get_by_id(&"donut")

func test_initial_state() -> void:
	assert_eq(gs.hearts, 3)
	assert_eq(gs.mouth.size(), 0)
	assert_eq(gs.satiety, 0)
	assert_eq(gs.goal_target, 3)

func test_pick_up_until_full() -> void:
	watch_signals(gs)
	assert_true(gs.pick_up(sausage))
	assert_true(gs.pick_up(sausage))
	assert_true(gs.pick_up(donut))
	assert_true(gs.mouth_full())
	assert_false(gs.pick_up(sausage), "четвёртая не помещается")
	assert_eq(gs.mouth.size(), 3)
	assert_signal_emit_count(gs, "mouth_changed", 3)

func test_eat_all_adds_satiety_album_and_one_heart() -> void:
	gs.hearts = 1
	gs.pick_up(sausage)
	gs.pick_up(donut)
	watch_signals(gs)
	var eaten: Array = gs.eat_all()
	assert_eq(eaten.size(), 2)
	assert_eq(gs.mouth.size(), 0)
	assert_eq(gs.satiety, 1 + 15)
	assert_eq(gs.album[&"sausage"], 1)
	assert_eq(gs.album[&"donut"], 1)
	assert_eq(gs.hearts, 2, "ровно +1 сердечко за съедание")
	assert_signal_emitted(gs, "food_eaten")
	assert_signal_emitted(gs, "satiety_changed")

func test_eat_with_empty_mouth_is_noop() -> void:
	# Review Focus 2
	gs.hearts = 2
	watch_signals(gs)
	assert_eq(gs.eat_all().size(), 0)
	assert_eq(gs.hearts, 2)
	assert_eq(gs.satiety, 0)
	assert_signal_not_emitted(gs, "food_eaten")

func test_eat_does_not_exceed_max_hearts() -> void:
	gs.pick_up(sausage)
	gs.eat_all()
	assert_eq(gs.hearts, 3)

func test_take_hit_spills_and_costs_heart() -> void:
	gs.pick_up(sausage)
	gs.pick_up(donut)
	watch_signals(gs)
	var fainted: bool = gs.take_hit()
	assert_false(fainted)
	assert_eq(gs.hearts, 2)
	assert_eq(gs.mouth.size(), 0)
	var spilled: Array = get_signal_parameters(gs, "cat_hit")[0]
	assert_eq(spilled.size(), 2)

func test_third_hit_faints_and_revive_restores() -> void:
	gs.take_hit()
	gs.take_hit()
	watch_signals(gs)
	assert_true(gs.take_hit())
	assert_signal_emitted(gs, "cat_fainted")
	assert_eq(gs.hearts, 0)
	gs.pick_up(sausage)
	gs.revive()
	assert_eq(gs.hearts, 3)
	assert_eq(gs.mouth.size(), 0, "еда в зубах теряется")

func test_goal_counts_only_new_cards_and_advances() -> void:
	watch_signals(gs)
	for i in 3:
		gs.pick_up(sausage)
		gs.eat_all()
	assert_eq(gs.goal_done, 1, "три сосиски = одна новая карточка")
	gs.pick_up(donut)
	gs.eat_all()
	gs.pick_up(FoodCatalog.get_by_id(&"fish"))
	gs.eat_all()
	assert_signal_emitted(gs, "goal_completed")
	assert_eq(gs.goal_target, 5)
	assert_eq(gs.goal_done, 0)

func test_reset_clears_everything() -> void:
	gs.pick_up(sausage)
	gs.eat_all()
	gs.take_hit()
	gs.reset()
	assert_eq(gs.hearts, 3)
	assert_eq(gs.satiety, 0)
	assert_eq(gs.album.size(), 0)
	assert_eq(gs.goal_target, 3)

func test_yarn_add_spend_and_card_bonus() -> void:
	watch_signals(gs)
	gs.add_yarn(2)
	assert_eq(gs.yarn, 2)
	assert_false(gs.spend_yarn(5), "нельзя уйти в минус")
	assert_eq(gs.yarn, 2)
	assert_true(gs.spend_yarn(2))
	assert_eq(gs.yarn, 0)
	gs.pick_up(sausage)
	gs.eat_all()
	assert_eq(gs.yarn, 3, "+3 за новую карточку")
	gs.pick_up(sausage)
	gs.eat_all()
	assert_eq(gs.yarn, 3, "повтор карточки клубочков не даёт")
	assert_signal_emitted(gs, "yarn_changed")

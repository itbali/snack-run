extends GutTest

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var gs: Node

func before_each() -> void:
	gs = GameStateScript.new()
	add_child_autofree(gs)

func _item(id: String) -> ShopItem:
	return ShopCatalog.get_by_id(StringName(id))

func test_catalog_matches_spec_prices() -> void:
	assert_eq(ShopCatalog.all().size(), 10)
	assert_eq(_item("refill_hearts").price, 2)
	assert_eq(_item("max_heart_4").price, 8)
	assert_eq(_item("max_heart_5").price, 15)
	assert_eq(_item("mouth_4").price, 6)
	assert_eq(_item("mouth_5").price, 12)
	assert_eq(_item("speed").price, 10)
	assert_eq(_item("quiet").price, 10)
	assert_eq(_item("skin_black").price, 12)
	assert_eq(_item("max_heart_5").requires, &"max_heart_4")

func test_cannot_buy_without_yarn() -> void:
	# Review Focus 1
	gs.add_yarn(5)
	assert_false(gs.can_buy(_item("speed")))
	assert_false(gs.buy(_item("speed")))
	assert_eq(gs.yarn, 5)
	assert_false(gs.owns(&"speed"))

func test_buy_speed_once_only() -> void:
	# Review Focus 2
	gs.add_yarn(25)
	watch_signals(gs)
	assert_true(gs.buy(_item("speed")))
	assert_eq(gs.yarn, 15)
	assert_almost_eq(gs.speed_mult, 1.15, 0.001)
	assert_signal_emitted(gs, "upgrade_bought")
	assert_false(gs.can_buy(_item("speed")), "повторно не продаётся")
	assert_eq(gs.yarn, 15)

func test_quiet_reduces_dog_cone() -> void:
	gs.add_yarn(10)
	gs.buy(_item("quiet"))
	assert_almost_eq(gs.stealth_mult, 0.7, 0.001)

func test_max_hearts_chain_and_refill() -> void:
	gs.add_yarn(30)
	assert_false(gs.can_buy(_item("max_heart_5")), "сначала четвёртое сердечко")
	assert_true(gs.buy(_item("max_heart_4")))
	assert_eq(gs.max_hearts, 4)
	assert_eq(gs.hearts, 4, "новое сердечко сразу полное")
	assert_true(gs.buy(_item("max_heart_5")))
	assert_eq(gs.max_hearts, 5)
	assert_false(gs.can_buy(_item("refill_hearts")), "сердечки полные — нечего восстанавливать")
	gs.take_hit()
	assert_true(gs.can_buy(_item("refill_hearts")))
	assert_true(gs.buy(_item("refill_hearts")))
	assert_eq(gs.hearts, 5)
	assert_false(gs.can_buy(_item("refill_hearts")))

func test_mouth_capacity_chain() -> void:
	gs.add_yarn(20)
	assert_false(gs.can_buy(_item("mouth_5")))
	gs.buy(_item("mouth_4"))
	assert_eq(gs.mouth_capacity, 4)
	gs.buy(_item("mouth_5"))
	assert_eq(gs.mouth_capacity, 5)

func test_skins_buy_and_select() -> void:
	gs.add_yarn(12)
	watch_signals(gs)
	assert_false(gs.select_skin(&"black"), "не куплен")
	assert_true(gs.buy(_item("skin_black")))
	assert_eq(gs.skin, &"black", "купленный скин сразу надевается")
	assert_signal_emitted(gs, "skin_changed")
	assert_true(gs.select_skin(&"orange"))
	assert_eq(gs.owned_skins(), [&"orange", &"black"])
	assert_false(gs.can_buy(_item("skin_black")), "скин одноразовый")

func test_reset_clears_shop_state() -> void:
	gs.add_yarn(30)
	gs.buy(_item("speed"))
	gs.buy(_item("skin_black"))
	gs.reset()
	assert_eq(gs.yarn, 0)
	assert_eq(gs.upgrades.size(), 0)
	assert_eq(gs.skin, &"orange")
	assert_almost_eq(gs.speed_mult, 1.0, 0.001)

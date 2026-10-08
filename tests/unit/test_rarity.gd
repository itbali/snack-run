extends GutTest

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func test_weights_follow_spec() -> void:
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.COMMON], 60)
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.RARE], 25)
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.VERY_RARE], 12)
	assert_eq(Rarity.WEIGHTS[Rarity.Tier.LEGENDARY], 3)
	assert_eq(Rarity.SATIETY[Rarity.Tier.LEGENDARY], 15)

func test_pick_weighted_proportions() -> void:
	var rng := _rng(7)
	var counts := {0: 0, 1: 0, 2: 0, 3: 0}
	for i in 10000:
		counts[Rarity.pick_weighted([0, 1, 2, 3], rng)] += 1
	assert_between(counts[0] / 10000.0, 0.57, 0.63, "обычная ~60%")
	assert_between(counts[3] / 10000.0, 0.02, 0.045, "легендарная ~3%")

func test_pick_weighted_respects_allowed() -> void:
	var rng := _rng(1)
	for i in 200:
		var t := Rarity.pick_weighted([Rarity.Tier.RARE, Rarity.Tier.LEGENDARY], rng)
		assert_true(t == Rarity.Tier.RARE or t == Rarity.Tier.LEGENDARY)

func test_pick_weighted_empty_gives_common() -> void:
	assert_eq(Rarity.pick_weighted([], _rng(1)), Rarity.Tier.COMMON)

func test_catalog_has_eight_foods_two_per_tier() -> void:
	assert_eq(FoodCatalog.all().size(), 8)
	for t in 4:
		assert_eq(FoodCatalog.by_tier(t).size(), 2, "по две еды в редкости %d" % t)
	var donut := FoodCatalog.get_by_id(&"donut")
	assert_not_null(donut)
	assert_eq(donut.tier, Rarity.Tier.LEGENDARY)
	assert_true(donut.sweet)
	assert_eq(donut.satiety(), 15)
	assert_eq(donut.display_name, "Пончик")

extends GutTest
## План 13: качание лодок и бочек — подъём ±amp, крен ±roll, период, фаза (спек порта, раздел 2).

func test_offset_is_periodic_and_bounded() -> void:
	for i in 40:
		var t := i * 0.173
		var o := Floater.offset_at(t, 0.12, 6.0, 3.5, 1.0)
		assert_between(o.x, -0.1201, 0.1201)
		assert_between(o.y, -6.001, 6.001)
		var o2 := Floater.offset_at(t + 3.5, 0.12, 6.0, 3.5, 1.0)
		assert_almost_eq(o2.x, o.x, 0.0001, "период по подъёму")
		assert_almost_eq(o2.y, o.y, 0.0001, "период по крену")

func test_phase_shifts_motion() -> void:
	var a := Floater.offset_at(0.5, 0.12, 6.0, 3.5, 0.0)
	var b := Floater.offset_at(0.5, 0.12, 6.0, 3.5, 2.0)
	assert_gt(absf(a.x - b.x), 0.02, "разные фазы — разное положение")

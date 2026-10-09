extends GutTest
## Цикл дождевателя (спек этапа 2, раздел 3): 12 с стоит, из них последняя 1 с — предупреждение, 8 с работает.

func test_phases() -> void:
	assert_eq(Sprinkler.phase_at(0.0), &"off")
	assert_eq(Sprinkler.phase_at(10.9), &"off")
	assert_eq(Sprinkler.phase_at(11.5), &"warn")
	assert_eq(Sprinkler.phase_at(12.0), &"on")
	assert_eq(Sprinkler.phase_at(19.9), &"on")
	assert_eq(Sprinkler.phase_at(20.0), &"off", "цикл 20 с")

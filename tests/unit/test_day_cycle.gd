extends GutTest

func test_phases_by_time() -> void:
	assert_eq(DayCycle.phase_at(0.0), &"day")
	assert_eq(DayCycle.phase_at(149.9), &"day")
	assert_eq(DayCycle.phase_at(160.0), &"evening")
	assert_eq(DayCycle.phase_at(200.0), &"night")
	assert_eq(DayCycle.phase_at(280.0), &"morning")
	assert_eq(DayCycle.phase_at(300.0), &"day", "цикл замыкается")
	assert_eq(DayCycle.phase_at(-10.0), &"morning", "отрицательное время оборачивается")

func test_phase_progress_counts_to_next_phase() -> void:
	assert_almost_eq(DayCycle.phase_progress(75.0), 0.5, 0.001)
	assert_almost_eq(DayCycle.phase_progress(225.0), 0.5, 0.001)

func test_keyframes_hold_and_blend() -> void:
	var day := DayCycle.light_at(50.0)
	assert_almost_eq(day["sun_pitch"], -65.0, 0.01)
	assert_almost_eq(day["sun_energy"], 1.2, 0.001)
	assert_eq((day["sun_color"] as Color).to_html(false), "fff1d6")
	var night := DayCycle.light_at(220.0)
	assert_almost_eq(night["sun_energy"], 0.22, 0.001)
	assert_almost_eq(night["ambient"], 0.18, 0.001)
	assert_eq((night["sky_top"] as Color).to_html(false), "0b1633")
	var mid := DayCycle.light_at(157.5)   # середина перехода день → закат
	assert_almost_eq(mid["sun_energy"], (1.2 + 0.8) / 2.0, 0.01)

func test_wrap_is_continuous() -> void:
	# Review Focus 4
	var a := DayCycle.light_at(299.99)
	var b := DayCycle.light_at(0.0)
	assert_almost_eq(a["sun_energy"], b["sun_energy"], 0.01)
	assert_almost_eq(a["sun_pitch"], b["sun_pitch"], 0.1)

func test_lamps_on_from_dusk_to_dawn() -> void:
	assert_false(DayCycle.lamps_on(100.0))
	assert_true(DayCycle.lamps_on(170.0))
	assert_true(DayCycle.lamps_on(250.0))
	assert_false(DayCycle.lamps_on(290.0))

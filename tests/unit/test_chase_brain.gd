extends GutTest

var brain: ChaseBrain

func before_each() -> void:
	brain = ChaseBrain.new()

func _run(seconds: float, sees: bool, hidden: bool, at_home := false) -> int:
	var t := 0.0
	var s := brain.state
	while t < seconds:
		s = brain.update(0.1, sees, hidden, at_home)
		t += 0.1
	return s

func test_idle_until_sees_then_alert_then_chase() -> void:
	assert_eq(_run(1.0, false, false), ChaseBrain.State.IDLE)
	assert_eq(brain.update(0.1, true, false, true), ChaseBrain.State.ALERT)
	assert_eq(_run(0.5, true, false), ChaseBrain.State.ALERT, "насторожилась ещё не секунду")
	assert_eq(_run(0.6, true, false), ChaseBrain.State.CHASE)

func test_chase_times_out_after_8s() -> void:
	brain.update(0.1, true, false, true)
	_run(1.1, true, false)
	assert_eq(brain.state, ChaseBrain.State.CHASE)
	assert_eq(_run(7.0, true, false), ChaseBrain.State.CHASE)
	assert_eq(_run(1.2, true, false), ChaseBrain.State.RETURN)

func test_loses_track_after_2s_continuous_hidden_only() -> void:
	# Review Focus 5
	brain.update(0.1, true, false, true)
	_run(1.1, true, false)
	_run(1.5, false, true)
	_run(0.3, true, false)   # выглянул на 0,3 с — счётчик сбрасывается
	assert_eq(_run(1.5, false, true), ChaseBrain.State.CHASE, "суммарно 3 с, но не подряд")
	assert_eq(_run(0.6, false, true), ChaseBrain.State.RETURN, "2,1 с подряд")

func test_return_becomes_idle_at_home() -> void:
	brain.state = ChaseBrain.State.RETURN
	assert_eq(brain.update(0.1, false, false, false), ChaseBrain.State.RETURN)
	assert_eq(brain.update(0.1, false, false, true), ChaseBrain.State.IDLE)

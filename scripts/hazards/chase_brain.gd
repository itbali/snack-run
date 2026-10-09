class_name ChaseBrain
extends RefCounted
## Конечный автомат погони (спек 3.2, собака): idle → alert (1 с) → chase → return.

enum State { IDLE, ALERT, CHASE, RETURN }

const ALERT_TIME := 1.0
const CHASE_MAX := 8.0
const LOST_HIDDEN := 2.0

var state: int = State.IDLE
var _t := 0.0
var _hidden_t := 0.0


func reset() -> void:
	state = State.IDLE
	_t = 0.0
	_hidden_t = 0.0


func give_up() -> void:
	## Погоня обрывается извне (наступила ночь): собака идёт домой спать.
	if state == State.ALERT or state == State.CHASE:
		state = State.RETURN
		_t = 0.0


func update(delta: float, sees_cat: bool, cat_hidden: bool, at_home: bool, cat_safe := false) -> int:
	match state:
		State.IDLE:
			if sees_cat and not cat_hidden:
				state = State.ALERT
				_t = 0.0
		State.ALERT:
			if cat_safe:
				state = State.IDLE   # кот уже в будке: не стоит и не лает
				_t = 0.0
			else:
				_t += delta
				if _t >= ALERT_TIME:
					state = State.CHASE
					_t = 0.0
					_hidden_t = 0.0
		State.CHASE:
			if cat_safe:
				state = State.RETURN   # «в будку собаки не заходят» (спек 3.5): уходит сразу, не через 2 с
			else:
				_t += delta
				_hidden_t = _hidden_t + delta if cat_hidden else 0.0
				if _t >= CHASE_MAX or _hidden_t >= LOST_HIDDEN:
					state = State.RETURN
		State.RETURN:
			if at_home:
				state = State.IDLE
				_t = 0.0
	return state

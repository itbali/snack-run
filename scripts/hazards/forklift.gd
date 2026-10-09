class_name Forklift
extends Node3D
## Погрузчик на причале (спек порта, раздел 3): стоит у штабеля 4–6 с, 1,5 с гудит, едет 3 м/с с ящиком к следующей точке
## маршрута; ночью стоит. Касание — удар, как у велосипедиста.

const SPEED := 3.0
const HORN := 1.5


static func next_state(state: StringName, t_in_state: float, wait: float, night: bool) -> StringName:
	## drive → wait по прибытии решает узел; здесь — переходы по времени и ночь.
	if night:
		return &"wait"
	match state:
		&"wait":
			return &"horn" if t_in_state >= wait else &"wait"
		&"horn":
			return &"drive" if t_in_state >= HORN else &"horn"
	return state

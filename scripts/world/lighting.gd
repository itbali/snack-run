extends Node3D
## Свет района: солнце (днём 65° с юго-востока, ведёт DayNight), заполняющий свет неба с обратной стороны, листья.

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-65.0, 30.0, 0.0)
	$Fill.rotation_degrees = Vector3(-65.0, 210.0, 0.0)
	Effects.leaves(self)

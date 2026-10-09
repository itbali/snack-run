extends Node3D
## Яркий день по референсу (спек 2.8): солнце 65° с юго-востока, заполняющий свет неба с обратной стороны.

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-65.0, 30.0, 0.0)
	$Fill.rotation_degrees = Vector3(-65.0, 210.0, 0.0)

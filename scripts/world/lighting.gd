extends Node3D
## Солнце под 50° к горизонту, с юго-востока (спек 2.3).

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)

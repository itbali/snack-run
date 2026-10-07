extends Camera3D
## Смотрит на точку target_point после входа в дерево.

@export var target_point := Vector3(0, 0.15, 0)

func _ready() -> void:
	look_at(target_point, Vector3.UP)

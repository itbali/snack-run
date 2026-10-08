class_name Mouse
extends RefCounted
## Захват мыши для камеры. В headless (тесты, импорт) ничего не делает: там DisplayServer без мыши.


static func capture(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE

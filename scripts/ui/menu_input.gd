class_name MenuInput
extends Node
## Опрашивает клавиши меню (E в будке, Tab, Esc, B геймпада) и дёргает Main. Работает и на паузе.

@onready var _main: Node = get_parent()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_main.call("on_back_pressed")
	elif Input.is_action_just_pressed("ui_cancel"):
		_main.call("on_cancel_pressed")   # B на геймпаде: «Управление», магазин, альбом (Esc ловит ветка выше)
	elif Input.is_action_just_pressed("album"):
		_main.call("on_album_pressed")
	elif Input.is_action_just_pressed("eat"):
		_main.call("on_interact_pressed")


func _menu_open() -> bool:
	return bool(_main.get("shop_menu").is_open) or bool(_main.get("album_menu").is_open)

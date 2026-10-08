extends Control
## Заставка: главная сцена проекта.

@onready var _play: Button = $VBox/Play
@onready var _quit: Button = $VBox/Quit


func _ready() -> void:
	_play.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_quit.pressed.connect(func() -> void: get_tree().quit())
	_play.grab_focus()

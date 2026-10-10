extends Control
## Заставка: главная сцена проекта. «Продолжить» видна только при наличии сохранения.

var switch_scenes := true   # тесты выключают, чтобы не подменять сцену дерева GUT

@onready var _continue: Button = $VBox/Continue
@onready var _play: Button = $VBox/Play
@onready var _quit: Button = $VBox/Quit


func _ready() -> void:
	Mouse.capture(false)
	_continue.visible = has_save()
	_continue.pressed.connect(continue_game)
	_play.pressed.connect(new_game)
	_quit.pressed.connect(func() -> void: get_tree().quit())
	var menu := ControlsMenu.new()   # план 17: клавиши видно и можно поменять до начала игры
	menu.name = "ControlsMenu"
	menu.standalone = true
	add_child(menu)
	var controls := Button.new()
	controls.name = "Controls"
	controls.text = "Управление"
	controls.pressed.connect(menu.open)
	_quit.add_sibling(controls)
	_quit.get_parent().move_child(controls, _quit.get_index())
	(_continue if _continue.visible else _play).grab_focus()


func has_save() -> bool:
	return FileAccess.file_exists(SaveGame.path)


func continue_game() -> void:
	_go()


func new_game() -> void:
	GameState.reset()   # сначала сброс: его сигналы могут вызвать автосохранение, файл стираем после
	SaveGame.clear()
	_go()


func _go() -> void:
	if switch_scenes:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

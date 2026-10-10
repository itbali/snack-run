class_name PauseMenu
extends CanvasLayer
## Пауза: продолжить, сбросить прогресс, выйти.

signal resumed
signal reset_requested
signal controls_requested
signal skip_tutorial_requested

var is_open := false

@onready var _continue: Button = $Panel/Margin/VBox/Continue
@onready var _reset: Button = $Panel/Margin/VBox/ResetProgress
@onready var _quit: Button = $Panel/Margin/VBox/Quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_continue.pressed.connect(close)
	_reset.pressed.connect(func() -> void: reset_requested.emit())
	_quit.pressed.connect(func() -> void: get_tree().quit())
	# План 17: «Управление и помощь» и «Пропустить обучение» — перед «Выйти».
	var controls := Button.new()
	controls.name = "Controls"
	controls.text = "Управление и помощь"
	controls.pressed.connect(func() -> void: controls_requested.emit())
	_quit.add_sibling(controls)
	_quit.get_parent().move_child(controls, _quit.get_index())
	var skip := Button.new()
	skip.name = "SkipTutorial"
	skip.text = "Пропустить обучение"
	skip.pressed.connect(func() -> void:
		skip_tutorial_requested.emit()
		skip.visible = false)
	_quit.add_sibling(skip)
	_quit.get_parent().move_child(skip, _quit.get_index())


func open() -> void:
	(find_child("SkipTutorial", true, false) as Button).visible = not GameState.tutorial_done
	is_open = true
	visible = true
	_continue.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	resumed.emit()

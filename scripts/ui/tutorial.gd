class_name Tutorial
extends CanvasLayer
## Обучение (план 17): подсказка вверху экрана по шагам с текущими клавишами; шаг закрывается действием игрока.
## Игра не ставится на паузу. Пройдено или пропущено — GameState.tutorial_done (в сохранении), больше не показывается.

const STEPS := [&"move", &"run", &"jump", &"food", &"hide", &"eat", &"shop"]

var step := 0
var _cat: Node3D
var _main: Node
var _start := Vector3.ZERO
var _ate := false
var _label: Label
var _panel: PanelContainer


func setup(main: Node, cat: Node3D) -> void:
	_main = main
	_cat = cat


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme = load("res://assets/ui/theme.tres")
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.position.y = 16
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_panel.add_child(margin)
	_label = Label.new()
	_label.name = "Hint"
	_label.add_theme_font_size_override("font_size", 20)
	margin.add_child(_label)
	GameState.food_eaten.connect(func(_items: Array) -> void: _ate = true)
	visible = not GameState.tutorial_done
	if _cat:
		_start = _cat.global_position


func step_id() -> StringName:
	return STEPS[mini(step, STEPS.size() - 1)]


func text() -> String:
	return _label.text


func skip() -> void:
	GameState.finish_tutorial()
	visible = false


func _hint() -> String:
	var k := KeyBindings.key_name
	match step_id():
		&"move":
			return "Ходи: %s %s %s %s" % [k.call("move_forward"), k.call("move_left"), k.call("move_back"), k.call("move_right")]
		&"run":
			return "Беги: держи %s" % k.call("run")
		&"jump":
			return "Прыгай: %s" % k.call("jump")
		&"food":
			return "Подбери вкусняшку — просто подойди к ней"
		&"hide":
			return "Спрячься в укрытии (коробка, скамейка, куст): %s" % k.call("hide")
		&"eat":
			return "Съешь в укрытии: %s" % k.call("eat")
		&"shop":
			return "Клубочки — деньги: в будке пряжи нажми %s" % k.call("eat")
	return ""


func _done() -> bool:
	match step_id():
		&"move":
			return _cat.global_position.distance_to(_start) > 2.0
		&"run":
			return _cat.get("state") == &"run"
		&"jump":
			return _cat.get("state") == &"jump"
		&"food":
			return not GameState.mouth.is_empty()
		&"hide":
			return bool(_cat.get("hidden"))
		&"eat":
			return _ate
		&"shop":
			return _main != null and bool(_main.get("shop_menu").is_open)
	return false


func _physics_process(_delta: float) -> void:
	if GameState.tutorial_done:
		visible = false
		return
	if _cat == null:
		return
	if _done():
		step += 1
		_ate = false
		if step >= STEPS.size():
			skip()
			return
	_label.text = "Обучение %d/%d · %s" % [step + 1, STEPS.size(), _hint()]

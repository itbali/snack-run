class_name Hud
extends CanvasLayer
## HUD на белых плашках темы: сердечки, сытость, слоты зубов, клубочки, цель сессии, вспышка звонка (спек 2.6).

const HEART_FULL := "♥"
const HEART_EMPTY := "♡"
const MAX_MOUTH := 5   # максимум после улучшений магазина

@onready var _hearts: Label = %Hearts
@onready var _satiety: ProgressBar = %Satiety
@onready var _satiety_label: Label = %SatietyLabel
@onready var _yarn: Label = %Yarn
@onready var _mouth: HBoxContainer = %Mouth
@onready var _goal: Label = %Goal
@onready var _bell: Label = %Bell
@onready var _bell_panel: PanelContainer = %BellPanel


func _ready() -> void:
	_satiety.max_value = GameState.SATIETY_GATE
	_bell_panel.visible = false
	for i in MAX_MOUTH:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(90, 32)
		var label := Label.new()
		label.name = "Name"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(label)
		_mouth.add_child(panel)
	GameState.hearts_changed.connect(_on_hearts)
	GameState.mouth_changed.connect(_on_mouth)
	GameState.satiety_changed.connect(_on_satiety)
	GameState.goal_changed.connect(_on_goal)
	GameState.goal_completed.connect(_on_goal_completed)
	GameState.yarn_changed.connect(_on_yarn)
	GameState.upgrade_bought.connect(func(_id: StringName) -> void: _refresh_slots())
	_refresh_slots()
	_on_yarn(GameState.yarn)
	_on_hearts(GameState.hearts, GameState.max_hearts)
	_on_mouth(GameState.mouth)
	_on_satiety(GameState.satiety)
	_on_goal(GameState.goal_done, GameState.goal_target)


func hearts_text() -> String:
	return _hearts.text


func mouth_names() -> Array[String]:
	var out: Array[String] = []
	for panel in _mouth.get_children():
		if panel.visible:
			out.append((panel.get_node("Name") as Label).text)
	return out


func _refresh_slots() -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		panels[i].visible = i < GameState.mouth_capacity


func yarn_text() -> String:
	return _yarn.text


func _on_yarn(count: int) -> void:
	_yarn.text = "◎ %d" % count


func flash_bell(text := "🔔 Велосипед!", seconds := 2.0) -> void:
	_bell.text = text
	_bell_panel.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _bell_panel.visible = false)


func _on_hearts(hearts: int, max_hearts: int) -> void:
	_hearts.text = HEART_FULL.repeat(hearts) + HEART_EMPTY.repeat(max_hearts - hearts)


func _on_mouth(items: Array) -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		var label := panels[i].get_node("Name") as Label
		label.text = items[i].display_name if i < items.size() else ""


func satiety_label_text() -> String:
	return _satiety_label.text


func _on_satiety(value: int) -> void:
	_satiety.value = value
	_satiety_label.text = "Кафе открыто" if value >= GameState.SATIETY_GATE else "Сытость %d/%d" % [value, GameState.SATIETY_GATE]


func _on_goal(done: int, target: int) -> void:
	_goal.text = "Открой новых карточек: %d/%d" % [done, target]


func _on_goal_completed(target: int) -> void:
	flash_bell("🎉 Цель выполнена: %d карточек!" % target, 3.0)

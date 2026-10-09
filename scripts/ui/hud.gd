class_name Hud
extends CanvasLayer
## HUD на белых плашках темы: сердечки, сытость, слоты зубов, клубочки, цель сессии, вспышка звонка (спек 2.6).

const HEART_ICON := "res://assets/images/ui/heart.png"
const YARN_ICON := "res://assets/images/ui/yarn.png"
const HEART_LOST_ALPHA := 0.3
const MAX_MOUTH := 5   # максимум после улучшений магазина

@onready var _hearts: HBoxContainer = %Hearts
@onready var _yarn_icon: TextureRect = %YarnIcon
@onready var _satiety: ProgressBar = %Satiety
@onready var _satiety_label: Label = %SatietyLabel
@onready var _yarn: Label = %Yarn
@onready var _mouth: HBoxContainer = %Mouth
@onready var _goal: Label = %Goal
@onready var _bell: Label = %Bell
@onready var _bell_panel: PanelContainer = %BellPanel


func _ready() -> void:
	_satiety.max_value = GameState.SATIETY_GATE
	_yarn_icon.texture = _icon(YARN_ICON)
	_bell_panel.visible = false
	for i in MAX_MOUTH:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 64)
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.name = "Name"
		label.visible = false   # текст остаётся для тестов и подписи, в кадре — иконка еды
		row.add_child(label)
		panel.add_child(row)
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
	## Состояние сердечек для тестов: «осталось/всего» (на экране — иконки).
	var full := 0
	for h in _hearts.get_children():
		if (h as TextureRect).modulate.a > 0.9:
			full += 1
	return "%d/%d" % [full, _hearts.get_child_count()]


static func _icon(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func mouth_names() -> Array[String]:
	var out: Array[String] = []
	for panel in _mouth.get_children():
		if panel.visible:
			out.append((panel.find_child("Name", true, false) as Label).text)
	return out


func _refresh_slots() -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		panels[i].visible = i < GameState.mouth_capacity


func yarn_text() -> String:
	return _yarn.text


func _on_yarn(count: int) -> void:
	_yarn.text = "%d" % count


func flash_bell(text := "🔔 Велосипед!", seconds := 2.0) -> void:
	_bell.text = text
	_bell_panel.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _bell_panel.visible = false)


func _on_hearts(hearts: int, max_hearts: int) -> void:
	while _hearts.get_child_count() < max_hearts:
		var t := TextureRect.new()
		t.custom_minimum_size = Vector2(34, 34)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture = _icon(HEART_ICON)
		_hearts.add_child(t)
	while _hearts.get_child_count() > max_hearts:
		var last := _hearts.get_child(_hearts.get_child_count() - 1)
		_hearts.remove_child(last)
		last.free()
	for i in _hearts.get_child_count():
		(_hearts.get_child(i) as TextureRect).modulate.a = 1.0 if i < hearts else HEART_LOST_ALPHA


func _on_mouth(items: Array) -> void:
	var panels := _mouth.get_children()
	for i in panels.size():
		var label := panels[i].find_child("Name", true, false) as Label
		label.text = items[i].display_name if i < items.size() else ""
		(panels[i].find_child("Icon", true, false) as TextureRect).texture = items[i].icon() if i < items.size() else null


func satiety_label_text() -> String:
	return _satiety_label.text


func _on_satiety(value: int) -> void:
	_satiety.value = value
	_satiety_label.text = "Кафе открыто" if value >= GameState.SATIETY_GATE else "Сытость %d/%d" % [value, GameState.SATIETY_GATE]


func _on_goal(done: int, target: int) -> void:
	_goal.text = "Открой новых карточек: %d/%d" % [done, target]


func _on_goal_completed(target: int) -> void:
	flash_bell("🎉 Цель выполнена: %d карточек!" % target, 3.0)

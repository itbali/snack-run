class_name ShopMenu
extends CanvasLayer
## Экран магазина пряжи: список товаров, баланс, покупка (спек 3.5).

signal closed

var is_open := false
var _buttons: Array[Button] = []
var _yarn_icon: Texture2D = load("res://assets/images/ui/yarn.png") if ResourceLoader.exists("res://assets/images/ui/yarn.png") else null

@onready var _list: VBoxContainer = $Panel/Margin/VBox/List
@onready var _yarn: Label = $Panel/Margin/VBox/Yarn
@onready var _close: Button = $Panel/Margin/VBox/Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for item in ShopCatalog.all():
		var b := Button.new()
		b.name = String(item.id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.expand_icon = true
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_on_buy.bind(item))
		_list.add_child(b)
		_buttons.append(b)
	_close.pressed.connect(close)
	GameState.yarn_changed.connect(func(_c: int) -> void: refresh())
	GameState.hearts_changed.connect(func(_h: int, _m: int) -> void: refresh())
	GameState.skin_changed.connect(func(_id: StringName) -> void: refresh())
	refresh()


func open() -> void:
	_close.text = "Закрыть (%s)" % KeyBindings.key_name("pause")   # текущая клавиша (план 17)
	is_open = true
	visible = true
	refresh()
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


func item_buttons() -> Array[Button]:
	return _buttons


func yarn_text() -> String:
	return _yarn.text


func refresh() -> void:
	_yarn.text = "Клубочков: %d" % GameState.yarn
	var items := ShopCatalog.all()
	for i in _buttons.size():
		var item := items[i]
		var owned := item.kind != "refill" and GameState.owns(item.id)
		if item.kind == "skin" and owned:
			# Купленный скин можно переодевать бесплатно.
			var worn := GameState.skin == item.skin_id
			_buttons[i].text = "%s — %s" % [item.display_name, "надет" if worn else "надеть"]
			_buttons[i].icon = null
			_buttons[i].disabled = worn
			continue
		_buttons[i].text = "%s — куплено" % item.display_name if owned else "%s — %d" % [item.display_name, item.price]
		_buttons[i].icon = null if owned else _yarn_icon   # цена в клубочках: иконка справа от числа
		_buttons[i].disabled = owned or not GameState.can_buy(item)


func _on_buy(item: ShopItem) -> void:
	if item.kind == "skin" and GameState.owns(item.id):
		GameState.select_skin(item.skin_id)
		refresh()
		return
	if GameState.buy(item):
		refresh()

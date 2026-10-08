class_name AlbumMenu
extends CanvasLayer
## Альбом вкусняшек: сетка карточек по редкостям (спек 2.6, 3.4).

signal closed

const LOCKED_ALPHA := 0.4

var is_open := false
var _cards: Array[Control] = []

@onready var _grid: GridContainer = $Panel/Margin/VBox/Grid
@onready var _close: Button = $Panel/Margin/VBox/Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var foods := FoodCatalog.all().duplicate()
	foods.sort_custom(func(a: FoodDef, b: FoodDef) -> bool: return a.tier < b.tier or (a.tier == b.tier and a.id < b.id))
	for f in foods:
		_grid.add_child(_make_card(f))
	_close.pressed.connect(close)


func _make_card(f: FoodDef) -> Control:
	var card := VBoxContainer.new()   # карточка — сам контейнер: Rarity/Name/Count его прямые дети
	card.name = String(f.id)
	card.custom_minimum_size = Vector2(150, 90)
	var strip := ColorRect.new()
	strip.name = "Rarity"
	strip.color = Rarity.COLORS[f.tier]
	strip.custom_minimum_size = Vector2(0, 8)
	card.add_child(strip)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	var count := Label.new()
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(count)
	card.set_meta("food", f)
	_cards.append(card)
	return card


func open() -> void:
	is_open = true
	visible = true
	refresh()
	_close.grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	closed.emit()


func cards() -> Array[Control]:
	return _cards


func refresh() -> void:
	for card in _cards:
		var f: FoodDef = card.get_meta("food")
		var n: int = GameState.album.get(f.id, 0)
		(card.get_node("Name") as Label).text = f.display_name if n > 0 else "???"
		(card.get_node("Count") as Label).text = "×%d" % n
		card.modulate.a = 1.0 if n > 0 else LOCKED_ALPHA

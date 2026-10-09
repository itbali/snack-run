class_name Gate
extends StaticBody3D
## Ворота района: закрыты, пока сытость меньше порога (спек 3.4).

signal opened

const BAR_COLOR := Color("#394151")
const BARS := 5

@export var satiety_required := GameState.SATIETY_GATE
@export var size := Vector3(2.4, 2.6, 0.3)
var open := false
var label := "🎉 Арка в кафе открыта!"   # сообщение при открытии (раскладка задаёт своё)

@onready var _shape: CollisionShape3D = $Collision
@onready var _bars: Node3D = $Bars


func _ready() -> void:
	add_to_group("gates")
	collision_mask = 0
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	_shape.position.y = size.y / 2.0
	_build_bars()
	GameState.satiety_changed.connect(refresh)
	refresh(GameState.satiety)


func _build_bars() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = BAR_COLOR
	for i in BARS:
		var mi := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.06, size.y, 0.06)
		bar.material = mat
		mi.mesh = bar
		mi.position = Vector3(-size.x / 2.0 + size.x * (i + 0.5) / BARS, size.y / 2.0, 0.0)
		_bars.add_child(mi)
	var rail := MeshInstance3D.new()
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(size.x, 0.06, 0.06)
	rail_mesh.material = mat
	rail.mesh = rail_mesh
	rail.position = Vector3(0.0, size.y * 0.5, 0.0)
	_bars.add_child(rail)


func refresh(satiety: int) -> void:
	var now_open := satiety >= satiety_required
	if now_open == open:
		collision_layer = 0 if open else Layers.WORLD
		return
	open = now_open
	collision_layer = 0 if open else Layers.WORLD
	_bars.visible = not open
	if open:
		opened.emit()

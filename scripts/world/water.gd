class_name Water
extends Area3D
## Вода (спек порта, раздел 2): поверхность на уровне узла; кот, погрузившийся на SINK м ниже поверхности, тонет
## и возвращается на ближайший маркер группы shore. Пруд парка и море порта — один узел.

const SINK := 0.15
const WaterShader := preload("res://assets/shaders/water.gdshader")

@export var size := Vector3(10, 3, 10)   # ширина, глубина зоны под поверхностью, длина
var level: float:
	get:
		return global_position.y


func _ready() -> void:
	add_to_group("water")
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, size.z)
	shape.shape = box
	shape.position.y = -SINK - size.y / 2.0
	add_child(shape)
	var surface := MeshInstance3D.new()
	surface.name = "Surface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.z)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	surface.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = WaterShader
	surface.material_override = mat
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	body_entered.connect(_on_body)


func _on_body(body: Node3D) -> void:
	if body.has_method("drown"):
		body.call("drown", nearest_shore(get_tree(), body.global_position, level))


static func nearest_shore(tree: SceneTree, pos: Vector3, water_level := 0.0) -> Vector3:
	## Ближайший маркер берега; без маркеров — та же точка над водой.
	var best := Vector3(pos.x, water_level + 1.0, pos.z)
	var best_d := INF
	for m in tree.get_nodes_in_group("shore"):
		var p: Vector3 = (m as Node3D).global_position
		var d := Vector2(p.x - pos.x, p.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = p
	return best

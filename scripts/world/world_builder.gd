class_name WorldBuilder
extends Node3D
## Строит район из data/layout/*.json: пропсы с коллизией, укрытия, точки спавна, опасности, дорога.

const MODELS_DIR := "res://assets/models"
const HAZARD_SCENES := {
	"dog": "res://scenes/hazards/dog.tscn",
	"wasp": "res://scenes/hazards/wasp.tscn",
	"cyclist": "res://scenes/hazards/cyclist.tscn",
}
const HideoutScene := preload("res://scenes/hideouts/hideout.tscn")
const SpawnScene := preload("res://scenes/food/food_spawn_point.tscn")
const YarnScene := preload("res://scenes/food/yarn_pickup.tscn")
const GateScene := preload("res://scenes/world/gate.tscn")

@export var layout_path := ""
var props_built := 0
var hideouts_built := 0
var spawns_built := 0
var hazards_built := 0
var yarn_built := 0
var gates_built := 0


func _ready() -> void:
	if layout_path != "":
		build(load_layout(layout_path))


static func load_layout(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "не удалось разобрать " + path)
	return parsed


static func _v3(arr: Array) -> Vector3:
	return Vector3(arr[0], arr[1], arr[2])


func _container(name: String) -> Node3D:
	var n := get_node_or_null(name) as Node3D
	if n == null:
		n = Node3D.new()
		n.name = name
		add_child(n)
	return n


func build(data: Dictionary) -> void:
	for p in data.get("props", []):
		_build_prop(p)
	for h in data.get("hideouts", []):
		_build_hideout(h)
	for s in data.get("spawn_points", []):
		_build_spawn(s)
	for y in data.get("yarn", []):
		_build_yarn(y)
	_build_road(data.get("road", {}))
	for g in data.get("gates", []):
		_build_gate(g)
	for hz in data.get("hazards", []):
		_build_hazard(hz)


func _build_prop(p: Dictionary) -> void:
	var model_path := "%s/%s.glb" % [MODELS_DIR, p["model"]]
	if not ResourceLoader.exists(model_path):
		push_warning("нет модели " + model_path)
		return
	var body := StaticBody3D.new()
	body.name = "%s_%d" % [p["model"], props_built]
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	body.add_child(model)
	var colliders: Array = p.get("colliders", [])
	if colliders.is_empty():
		var aabb := _model_aabb(model)
		colliders = [{"size": [aabb.size.x, aabb.size.y, aabb.size.z],
			"offset": [aabb.position.x + aabb.size.x / 2, aabb.position.y + aabb.size.y / 2, aabb.position.z + aabb.size.z / 2]}]
	for i in colliders.size():
		var c: Dictionary = colliders[i]
		var shape := CollisionShape3D.new()
		shape.name = "Shape%d" % i
		var box := BoxShape3D.new()
		box.size = _v3(c["size"])
		shape.shape = box
		shape.position = _v3(c.get("offset", [0, 0, 0]))
		body.add_child(shape)
	_container("Props").add_child(body)
	body.global_position = _v3(p["pos"])
	body.rotation_degrees.y = float(p.get("rot", 0))
	Toon.apply(model, Toon.OUTLINE_FOOD if p.get("outline", false) else Toon.OUTLINE_NONE)
	props_built += 1


func _model_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = _local_xf(mi, model)
		box = xf * box
		result = box if first else result.merge(box)
		first = false
	return result


func _local_xf(node: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n := node
	while n != null and n != root:
		xf = n.transform * xf
		n = n.get_parent() as Node3D
	return xf


func _build_hideout(h: Dictionary) -> void:
	var node := HideoutScene.instantiate() as Hideout
	node.kind = StringName(h.get("kind", "box"))
	node.size = _v3(h.get("size", [0.6, 0.4, 0.5]))
	_container("Hideouts").add_child(node)
	node.global_position = _v3(h["pos"])
	node.rotation_degrees.y = float(h.get("rot", 0))
	hideouts_built += 1


func _build_spawn(s: Dictionary) -> void:
	var node := SpawnScene.instantiate() as FoodSpawnPoint
	var allowed: Array = []
	for t in s.get("allowed", [0]):
		allowed.append(int(t))   # JSON даёт float, ключи словарей Rarity — int
	node.allowed = allowed
	_container("Spawns").add_child(node)
	node.global_position = _v3(s["pos"])
	spawns_built += 1


func _build_road(road: Dictionary) -> void:
	var path := Path3D.new()
	path.name = "Road"
	var curve := Curve3D.new()
	for pt in road.get("points", []):
		curve.add_point(_v3(pt))
	path.curve = curve
	add_child(path)


func _build_hazard(hz: Dictionary) -> void:
	var type_name: String = hz.get("type", "")
	var scene_path: String = HAZARD_SCENES.get(type_name, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("опасность пропущена: " + type_name)
		return
	var node := (load(scene_path) as PackedScene).instantiate() as Node3D
	node.name = "%s_%d" % [type_name, hazards_built]
	if node.has_method("configure"):
		node.call("configure", hz, self)
	_container("Hazards").add_child(node)
	node.global_position = _v3(hz["pos"])
	node.rotation_degrees.y = float(hz.get("rot", 0))
	hazards_built += 1


func _build_yarn(y: Dictionary) -> void:
	var node := YarnScene.instantiate() as YarnPickup
	_container("Yarn").add_child(node)
	node.global_position = _v3(y["pos"])
	yarn_built += 1


func _build_gate(g: Dictionary) -> void:
	var node := GateScene.instantiate() as Gate
	node.name = "gate_%d" % gates_built
	node.satiety_required = int(g.get("satiety", GameState.SATIETY_GATE))
	node.size = _v3(g.get("size", [2.4, 2.6, 0.3]))
	_container("Gates").add_child(node)
	node.global_position = _v3(g["pos"])
	node.rotation_degrees.y = float(g.get("rot", 0))
	gates_built += 1

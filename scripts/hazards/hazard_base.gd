class_name HazardBase
extends CharacterBody3D
## Общее для опасностей: слои, дом, ссылка на кота, hit-зона, гравитация.

const GRAVITY := 12.0

@export var walk_speed := 1.5
@export var run_speed := 4.8
var home: Vector3
var cat: Node3D
var _home_set := false

@onready var hit_zone: Area3D = $HitZone


func _ready() -> void:
	add_to_group("hazards")
	collision_layer = Layers.HAZARD
	collision_mask = Layers.WORLD
	hit_zone.collision_layer = Layers.AREA
	hit_zone.collision_mask = Layers.CAT
	hit_zone.monitorable = false
	hit_zone.body_entered.connect(_on_hit_body)


func _ensure_home() -> void:
	# WorldBuilder ставит global_position после add_child, поэтому дом фиксируется на первом физическом кадре.
	if not _home_set:
		home = global_position
		_home_set = true


func configure(_hz: Dictionary, _builder: Node3D) -> void:
	pass


func _find_cat() -> Node3D:
	if cat == null or not is_instance_valid(cat):
		cat = get_tree().get_first_node_in_group("cat") as Node3D
	return cat


func _on_hit_body(body: Node3D) -> void:
	if body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0


func move_towards_point(target: Vector3, speed: float, delta: float) -> float:
	## Двигает по горизонтали к точке; возвращает оставшееся расстояние.
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > 0.05:
		var dir := to / dist
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()
	return dist

class_name Wasp
extends Node3D
## Оса: кружит вокруг точки (сладкая еда), жалит касанием, не преследует (спек 3.2).

@export var radius := 2.5
@export var angular_speed := 0.8
@export var height := 0.5
var anchor: Vector3
var _anchored := false
var _angle := 0.0
var _t := 0.0

@onready var _hit: Area3D = $HitZone
@onready var _model: Node3D = $Model
@onready var _wing_l: Node3D = _model.find_child("wasp_wing_l", true, false)
@onready var _wing_r: Node3D = _model.find_child("wasp_wing_r", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	radius = float(hz.get("radius", radius))
	height = float(hz.get("height", height))


func _ready() -> void:
	add_to_group("hazards")
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.body_entered.connect(_on_body)
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	Effects.trail(self, Color("#5A5C6B"), 8)


func _physics_process(delta: float) -> void:
	if not _anchored:
		anchor = global_position   # позиция задаётся после add_child, поэтому якорь берём здесь
		_anchored = true
	_t += delta
	_angle += angular_speed * delta
	_place()
	if _wing_l and _wing_r:
		var flap := sin(_t * 60.0) * 0.6
		_wing_l.rotation.y = 0.25 + flap
		_wing_r.rotation.y = -0.25 - flap


func _place() -> void:
	var bob := sin(_t * 4.0) * 0.08
	if radius > 0.0:
		global_position = Vector3(anchor.x + cos(_angle) * radius, height + bob, anchor.z + sin(_angle) * radius)
		rotation.y = PI - _angle   # головой (−Z модели) по касательной движения
	else:
		global_position = Vector3(anchor.x, height + bob, anchor.z)


func _on_body(body: Node3D) -> void:
	if body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)

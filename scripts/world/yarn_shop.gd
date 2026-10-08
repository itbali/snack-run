class_name YarnShop
extends Node3D
## Будка пряжи: безопасная зона, точка возрождения, вход в магазин (спек 3.5).

signal cat_entered
signal cat_exited

const BALL_RADIUS := 0.5
const BALL_SPEED := 1.0

var cat_inside := false
var _t := 0.0

@onready var zone: Area3D = $Zone
@onready var _model: Node3D = $Model
@onready var _play: Node3D = $YarnPlay


func _ready() -> void:
	add_to_group("yarn_shop")
	zone.collision_layer = Layers.AREA
	zone.collision_mask = Layers.CAT
	zone.monitorable = false
	zone.body_entered.connect(_on_enter)
	zone.body_exited.connect(_on_exit)
	Toon.apply(_model, Toon.OUTLINE_NONE)
	var ball_scene := load("res://assets/models/yarn.glb") as PackedScene
	for i in 3:
		var ball := ball_scene.instantiate() as Node3D
		_play.add_child(ball)
	Toon.apply(_play, Toon.OUTLINE_FOOD)


func _process(delta: float) -> void:
	_t += delta
	for i in _play.get_child_count():
		var ball := _play.get_child(i) as Node3D
		var a := _t * BALL_SPEED + i * TAU / 3.0
		ball.position = Vector3(cos(a) * BALL_RADIUS, 0.0, sin(a) * BALL_RADIUS * 0.6)
		ball.rotation.x += delta * 4.0


func respawn_position() -> Vector3:
	return ($Respawn as Node3D).global_position


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = true
		body.set("in_safe_zone", true)
		cat_entered.emit()


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = false
		body.set("in_safe_zone", false)
		cat_exited.emit()

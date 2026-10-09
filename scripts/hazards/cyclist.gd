class_name Cyclist
extends Node3D
## Велосипедист: ждёт 12–20 с, звонит, через 2 с выезжает по дороге (Path3D) и сбивает на ней кота.

signal bell

@export var speed := 6.0
@export var interval_min := 12.0
@export var interval_max := 20.0
@export var bell_lead := 2.0
var path: Path3D
var riding := false
var _progress := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _hit: Area3D = $HitZone
@onready var _model: Node3D = $Model


func configure(_hz: Dictionary, builder: Node3D) -> void:
	var road := builder.get_node_or_null("Road")
	if road is Path3D:
		set_path(road)


func set_path(p: Path3D) -> void:
	path = p
	if is_inside_tree() and not riding:
		start_cycle()


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	_hit.collision_layer = Layers.AREA
	_hit.collision_mask = Layers.CAT
	_hit.monitorable = false
	_hit.monitoring = false
	_hit.body_entered.connect(_on_body)
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	visible = false
	if path:
		start_cycle()


func start_cycle() -> void:
	var wait := _rng.randf_range(interval_min, interval_max)
	get_tree().create_timer(wait, false).timeout.connect(_ring)


func _ring() -> void:
	if not is_inside_tree():
		return
	bell.emit()
	get_tree().create_timer(bell_lead, false).timeout.connect(_depart)


func _depart() -> void:
	if not is_inside_tree() or path == null:
		return
	riding = true
	_progress = 0.0
	visible = true
	_hit.set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if not riding or path == null:
		return
	var length := path.curve.get_baked_length()
	_progress += speed * delta
	if _progress >= length:
		riding = false
		visible = false
		_hit.set_deferred("monitoring", false)
		start_cycle()
		return
	var pos := path.curve.sample_baked(_progress)
	var ahead := path.curve.sample_baked(minf(_progress + 0.5, length))
	global_position = path.global_transform * pos
	var dir := (path.global_transform * ahead) - global_position
	if dir.length() > 0.01:
		rotation.y = atan2(-dir.x, -dir.z)


func _on_body(body: Node3D) -> void:
	if riding and body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)

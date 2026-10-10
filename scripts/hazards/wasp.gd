class_name Wasp
extends Node3D
## Оса: кружит вокруг точки (сладкая еда), жалит касанием, не преследует (спек 3.2).

@export var radius := 2.5
@export var angular_speed := 0.8
@export var height := 0.5
var anchor: Vector3
var ground := 0.0   # высота рельефа под якорем: оса летает на height над землёй (план 11)
var _anchored := false
## План 21: кот ближе NOTICE — зависает и трясётся (WARN), затем пикирует по прямой (DIVE), возвращается, отдыхает.
const NOTICE := 4.0
const WARN := 0.6
const DIVE_SPEED := 7.0
const DIVE_MAX := 1.0
const REST := 3.0
var mode: StringName = &"orbit"   # orbit | warn | dive | back
var cooldown_left := 0.0
var _mode_t := 0.0
var _dive_to := Vector3.ZERO
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
		ground = Terrain.surface_height(get_tree(), anchor.x, anchor.z, 0.0)
		_anchored = true
	_t += delta
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	_mode_t += delta
	var c := get_tree().get_first_node_in_group("cat") as Node3D
	match mode:
		&"orbit":
			_angle += angular_speed * delta
			_place()
			if c and cooldown_left <= 0.0 and not bool(c.get("hidden")) and not bool(c.get("in_safe_zone")) \
					and Vector2(c.global_position.x - anchor.x, c.global_position.z - anchor.z).length() < NOTICE:
				mode = &"warn"
				_mode_t = 0.0
		&"warn":
			_model.position = Vector3(randf_range(-0.03, 0.03), randf_range(-0.03, 0.03), 0)   # трясётся — предупреждение
			if c:
				var to := c.global_position - global_position
				rotation.y = atan2(-to.x, -to.z)
				_dive_to = c.global_position + Vector3(0, 0.15, 0)
			if _mode_t >= WARN:
				_model.position = Vector3.ZERO
				mode = &"dive"
				_mode_t = 0.0
		&"dive":
			var step := DIVE_SPEED * delta
			var to := _dive_to - global_position
			if to.length() <= step or _mode_t >= DIVE_MAX:
				mode = &"back"
				_mode_t = 0.0
				cooldown_left = REST
			else:
				global_position += to.normalized() * step
				for b in _hit.get_overlapping_bodies():
					_on_body(b)
		&"back":
			var home_p := Vector3(anchor.x + cos(_angle) * radius, ground + height, anchor.z + sin(_angle) * radius)
			global_position = global_position.move_toward(home_p, 3.0 * delta)
			if global_position.distance_to(home_p) < 0.05:
				mode = &"orbit"
	if _wing_l and _wing_r:
		var flap := sin(_t * 60.0) * 0.6
		_wing_l.rotation.y = 0.25 + flap
		_wing_r.rotation.y = -0.25 - flap


func _place() -> void:
	var bob := sin(_t * 4.0) * 0.08
	if radius > 0.0:
		global_position = Vector3(anchor.x + cos(_angle) * radius, ground + height + bob, anchor.z + sin(_angle) * radius)
		rotation.y = PI - _angle   # головой (−Z модели) по касательной движения
	else:
		global_position = Vector3(anchor.x, ground + height + bob, anchor.z)


func _on_body(body: Node3D) -> void:
	if body.is_in_group("cat") and body.has_method("take_hit"):
		body.call("take_hit", global_position)

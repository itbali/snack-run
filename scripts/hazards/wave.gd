class_name Wave
extends Node3D
## Волна на пляже (спек порта, раздел 3): каждые 14 с накат на 5 м за 3 с и откат за 3 с; за 1,5 с — пена и шум.

const PERIOD := 14.0
const RUN := 3.0
const REACH := 5.0
const FOAM_LEAD := 1.5


static func front_at(t: float) -> float:
	## Насколько вглубь пляжа дошла вода (метры от линии воды).
	var u := fposmod(t, PERIOD)
	if u <= RUN:
		return REACH * u / RUN   # линейно: игроку легко прочитать, докуда дойдёт вода
	if u <= 2.0 * RUN:
		return REACH * (1.0 - (u - RUN) / RUN)
	return 0.0


static func foam(t: float) -> bool:
	return fposmod(t, PERIOD) >= PERIOD - FOAM_LEAD

const THROW := 1.5
const WET := 4.0
const WaterShader := preload("res://assets/shaders/water.gdshader")

@export var width := 20.0          # вдоль линии воды (ось X)
@export var inland := -1.0         # куда суша от линии воды по оси Z: −1 — к −Z
@export var offset := 0.0          # сдвиг фазы, с
var hits := 0
var ground := 0.0
var _t := 0.0
var _hit_this_roll := false
var _foam_sounded := false
var _strip: MeshInstance3D
var _foam: CPUParticles3D


func configure(hz: Dictionary, _builder: Node3D) -> void:
	width = float(hz.get("width", width))
	inland = float(hz.get("inland", inland))
	offset = float(hz.get("offset", offset))


func _ready() -> void:
	add_to_group("hazards")
	_strip = MeshInstance3D.new()
	_strip.name = "Strip"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1, 1)
	_strip.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = WaterShader
	_strip.material_override = mat
	_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_strip)
	_foam = CPUParticles3D.new()
	_foam.name = "Foam"
	_foam.emitting = false
	_foam.amount = 40
	_foam.lifetime = 0.8
	_foam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_foam.emission_box_extents = Vector3(width / 2.0, 0.02, 0.3)
	_foam.direction = Vector3.UP
	_foam.spread = 30.0
	_foam.initial_velocity_min = 0.3
	_foam.initial_velocity_max = 0.8
	_foam.gravity = Vector3(0, -2, 0)
	var dot := SphereMesh.new()
	dot.radius = 0.06
	dot.height = 0.12
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#F4F1E8")
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.material = fm
	_foam.mesh = dot
	add_child(_foam)
	ground = global_position.y
	_update_strip(0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	var t := _t + offset
	var u := fposmod(t, PERIOD)
	var front := front_at(t)
	_update_strip(front)
	var foaming := foam(t)
	_foam.emitting = foaming or front > 0.0
	_foam.position = Vector3(0, 0.05, inland * front)
	if foaming and not _foam_sounded:
		Sfx.play(&"wave")
		_foam_sounded = true
	if u < RUN:
		_check_cat(front)
	else:
		_hit_this_roll = false
		if not foaming:
			_foam_sounded = false


func _update_strip(front: float) -> void:
	_strip.visible = front > 0.05
	_strip.scale = Vector3(width, 1.0, maxf(front, 0.01))
	_strip.position = Vector3(0, 0.04, inland * front / 2.0)


func _check_cat(front: float) -> void:
	## Накат: кот на мокрой полосе отброшен вглубь пляжа на 1,5 м и мокрый — один раз за накат (спек порта, раздел 3).
	if _hit_this_roll:
		return
	var c := get_tree().get_first_node_in_group("cat") as Node3D
	if c == null or bool(c.get("hidden")):
		return
	var local := c.global_position - global_position
	var depth := local.z * inland   # насколько кот вглубь суши от линии воды
	if absf(local.x) > width / 2.0 or depth < -0.5 or depth > front or absf(local.y) > 0.8:
		return
	_hit_this_roll = true
	hits += 1
	c.global_position += Vector3(0, 0.1, inland * THROW)
	c.set("velocity", Vector3.ZERO)
	if c.has_method("wet"):
		c.call("wet", WET)
	if c.has_method("squash"):
		c.call("squash", 0.8, 0.15)

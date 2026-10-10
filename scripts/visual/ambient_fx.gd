class_name AmbientFx
extends Node3D
## Атмосфера вокруг кота (план 18): днём — пылинки в солнце, ночью — светлячки (светятся, ловит glow). Следует за целью.

var target: Node3D
var _night := false

@onready var _motes := _make("Motes", Color(1, 0.98, 0.9, 0.7), 0.025, 40, 6.0, false)
@onready var _flies := _make("Fireflies", Color("#FABE32"), 0.05, 24, 4.0, true)


func _ready() -> void:
	add_to_group("ambient_fx")
	refresh()


func _make(n: String, color: Color, size: float, amount: int, life: float, glow: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = n
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(6, 1.5, 6)
	p.position.y = 1.3
	p.gravity = Vector3(0, 0.02, 0)
	p.direction = Vector3(1, 0.3, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.local_coords = false
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true   # color_ramp — плавное появление и угасание
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 6.0   # ярче порога glow — светлячки светятся
	mesh.material = m
	p.mesh = mesh
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.add_point(0.8, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	add_child(p)
	return p


func refresh() -> void:
	if _motes == null:
		return
	_night = DayNight.is_night(get_tree())
	var day_on := GameSettings.particles and not _night
	var night_on := GameSettings.particles and _night
	if _motes.emitting != day_on:
		_motes.emitting = day_on
	if _flies.emitting != night_on:
		_flies.emitting = night_on


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position
	refresh()   # дёшево: emitting меняется только при смене фазы или настройки

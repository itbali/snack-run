class_name YardLife
extends Node3D
## Живой двор (план 20): ветер в кронах, кустах и белье; бабочки у цветов; стайка птиц над крышами; дымок из труб;
## фон звуков — птицы днём, сверчки ночью. Узел Main, собирает пропсы всех районов.

const SWAY_MODELS := ["tree", "tree_pine", "bush", "bush_flowers"]
const SMOKE_MODELS := {"house_a": Vector3(1.6, 6.2 + 1.75, -3.3), "house_shallow": Vector3(1.6, 3.1 + 1.75, -0.9)}
const PigeonModel := preload("res://assets/models/pigeon.glb")

var _sway: Array[Node3D] = []
var _phase: Array[float] = []
var _base: Array[Vector3] = []
var _t := 0.0
var _butterflies: Array[Node3D] = []
var _flock: Node3D
var _flock_t := 0.0
var _amb: AudioStreamPlayer
var _night := false


func swaying() -> Array[Node3D]:
	return _sway


func setup(district: Node) -> void:
	var flowers: Array[Vector3] = []
	for props in district.find_children("Props", "Node3D", true, false):
		for body in props.get_children():
			var model_name := String(body.name).rsplit("_", true, 1)[0]
			var model := body.get_node_or_null("Model") as Node3D
			if model == null:
				continue
			if model_name in SWAY_MODELS:
				_add_sway(model, body.global_position)
			elif model_name == "laundry":
				for mi in model.find_children("laundry_cloth*", "MeshInstance3D", true, false):
					_add_sway(mi, body.global_position + Vector3(randf(), 0, randf()))
			if model_name in ["bush_flowers", "flowerbed"]:
				flowers.append((body as Node3D).global_position)
			if SMOKE_MODELS.has(model_name) and int(absf(body.global_position.x * 7.0 + body.global_position.z * 3.0)) % 3 == 0:
				_add_smoke(body as Node3D, SMOKE_MODELS[model_name])   # дымит каждая третья труба — летний день
	_make_butterflies(flowers)
	_make_flock()
	_make_ambience()


func _add_sway(n: Node3D, pos: Vector3) -> void:
	_sway.append(n)
	_phase.append(pos.x * 0.37 + pos.z * 0.23)
	_base.append(n.rotation)


func _add_smoke(house: Node3D, local: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.name = "ChimneySmoke"
	p.add_to_group("chimney_smoke")
	p.amount = 6
	p.lifetime = 3.5
	p.direction = Vector3(0.3, 1, 0)
	p.spread = 12.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.7
	p.gravity = Vector3(0.15, 0.1, 0)
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.45
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	mesh.material = m
	p.mesh = mesh
	var fade := Gradient.new()
	fade.set_color(0, Color(0.92, 0.92, 0.95, 0.0))
	fade.add_point(0.15, Color(0.92, 0.92, 0.95, 0.55))
	fade.set_color(fade.get_point_count() - 1, Color(0.85, 0.85, 0.9, 0.0))
	p.color_ramp = fade
	p.local_coords = false
	p.visibility_range_end = 70.0
	add_child(p)
	p.global_position = house.global_transform * local
	p.emitting = true


func _make_butterflies(flowers: Array[Vector3]) -> void:
	if flowers.is_empty():
		flowers = [Vector3.ZERO]
	var colors := [Color("#F57485"), Color("#FABE32"), Color("#B46DB5"), Color("#2F9CCF"), Color("#FCD3A1")]
	for i in 14:
		var b := Node3D.new()
		b.name = "Butterfly%d" % i
		b.add_to_group("butterflies")
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[i % colors.size()]
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		for side in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			w.name = "WingL" if side < 0 else "WingR"
			var q := QuadMesh.new()
			q.size = Vector2(0.09, 0.07)
			q.center_offset = Vector3(side * 0.045, 0, 0)
			w.mesh = q
			w.material_override = m
			w.rotation_degrees.x = -90
			b.add_child(w)
		b.set_meta("anchor", flowers[i % flowers.size()] + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)))
		b.set_meta("seed", randf() * 100.0)
		add_child(b)
		_butterflies.append(b)


func _make_flock() -> void:
	_flock = Node3D.new()
	_flock.name = "SkyBirds"
	add_child(_flock)
	for i in 6:
		var p := PigeonModel.instantiate() as Node3D
		p.position = Vector3(randf_range(-2.5, 2.5), randf_range(-0.6, 0.6), i * 1.1)
		p.scale = Vector3.ONE * 1.4
		_flock.add_child(p)
		var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap and ap.has_animation("flap"):
			ap.get_animation("flap").loop_mode = Animation.LOOP_LINEAR
			ap.play("flap")
	_restart_flock()


func _restart_flock() -> void:
	var z := randf_range(-120.0, 20.0)
	var from := Vector3(-110, randf_range(13, 18), z)
	_flock.global_position = from
	_flock.rotation.y = -PI / 2   # летят по +X
	_flock_t = 0.0


func _make_ambience() -> void:
	_amb = AudioStreamPlayer.new()
	_amb.name = "Ambience"
	_amb.volume_db = -16.0
	add_child(_amb)
	_set_ambience(DayNight.current_phase(get_tree()) == &"night")


func _set_ambience(night: bool) -> void:
	_night = night
	var path := "res://assets/sfx/crickets.wav" if night else "res://assets/sfx/birds.wav"
	if not ResourceLoader.exists(path):
		return
	var s := load(path) as AudioStreamWAV
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = int(s.get_length() * s.mix_rate)   # в сэмплах; data — сжатые байты (QOA), не длина (ревью плана 20)
	_amb.stream = s
	_amb.play()


func _process(delta: float) -> void:
	_t += delta
	var gust := 1.0 + 0.5 * sin(_t * 0.31)   # порывы
	for i in _sway.size():
		var n := _sway[i]
		var ph := _phase[i]
		n.rotation = _base[i] + Vector3(sin(_t * 1.3 + ph) * 0.025 * gust, 0, sin(_t * 1.7 + ph * 1.3) * 0.035 * gust)
	var night := DayNight.current_phase(get_tree()) == &"night"
	if _amb and night != _night:
		_set_ambience(night)
	for b in _butterflies:
		b.visible = not night
		if night:
			continue
		var a: Vector3 = b.get_meta("anchor")
		var sd: float = b.get_meta("seed")
		var pos := a + Vector3(sin(_t * 0.7 + sd) * 1.6, 0, cos(_t * 0.53 + sd * 1.7) * 1.6)
		var ground := Terrain.surface_height(get_tree(), pos.x, pos.z, 0.0)
		pos.y = ground + 1.05 + 0.3 * sin(_t * 1.9 + sd)   # над клумбами и цветущими кустами, а не в них
		var d := pos - b.global_position
		b.global_position = pos
		if d.length() > 0.0001:
			b.rotation.y = atan2(-d.x, -d.z)
		var flap := sin(_t * 22.0 + sd) * 0.9
		(b.get_node("WingL") as Node3D).rotation.z = flap
		(b.get_node("WingR") as Node3D).rotation.z = -flap
	_flock.visible = not night
	_flock_t += delta
	_flock.global_position += Vector3(6.0 * delta, sin(_flock_t * 0.8) * 0.3 * delta, 0)
	if _flock.global_position.x > 110.0:
		_restart_flock()

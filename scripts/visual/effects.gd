class_name Effects
extends RefCounted
## Одноразовые всплески частиц: съедание (цвет редкости), удар (золотые звёзды), клубочек (сиреневый).
## CPUParticles3D, а не GPU: работает и под dummy-рендерером тестов, цвет задаётся напрямую.

const YARN_COLOR := Color("#B46DB5")
const HIT_COLOR := Color("#FABE32")


static func burst(parent: Node, pos: Vector3, color: Color, amount := 24, size := 0.05, speed := 2.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Burst"
	p.add_to_group("fx")
	p.add_to_group("burst")   # одноразовые всплески событий: тесты считают их отдельно от постоянных эффектов
	p.one_shot = true
	p.emitting = false   # включается после add_child, иначе из физического шага finished приходит сразу
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -4.0, 0)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color = color
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	_free_later(p)
	return p


## Одноразовые системы удаляются по таймеру, а не по finished: созданные во время физического шага
## CPUParticles3D шлют finished в том же кадре и исчезали бы, не родив ни одной частицы.
static func _free_later(p: CPUParticles3D) -> void:
	p.get_tree().create_timer(p.lifetime + 0.3, false).timeout.connect(p.queue_free)


const DUST_COLOR := Color("#D3AB87")
const HeartTexture := preload("res://assets/images/ui/heart.png")


static func _particles(parent: Node, name: String, one_shot: bool) -> CPUParticles3D:
	## Узел создаётся выключенным и без родителя: фабрика настраивает его, затем зовёт _start.
	var p := CPUParticles3D.new()
	p.name = name
	p.add_to_group("fx")
	p.one_shot = one_shot
	p.emitting = false
	p.set_meta("fx_parent", parent)
	return p


static func _start(p: CPUParticles3D, pos := Vector3.INF) -> CPUParticles3D:
	(p.get_meta("fx_parent") as Node).add_child(p)
	if pos != Vector3.INF:
		p.global_position = pos
	p.emitting = true
	if p.one_shot:
		_free_later(p)
	return p


static func _sphere_mesh(radius := 0.5) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	return mesh


static func dust(parent: Node, pos: Vector3, amount := 12) -> CPUParticles3D:
	## Пыль при приземлении и беге: песочные шарики, расходятся в стороны и тают.
	var p := _particles(parent, "Dust", true)
	p.add_to_group("dust")
	p.amount = amount
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 85.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.2
	p.gravity = Vector3(0, -1.0, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.06
	p.color = DUST_COLOR
	p.mesh = _sphere_mesh()
	return _start(p, pos)


static func hearts(parent: Node, pos: Vector3) -> CPUParticles3D:
	## Сердечки при съедании: спрайты сгенерированной иконки, плывут вверх.
	var p := _particles(parent, "Hearts", true)
	p.add_to_group("hearts")
	p.amount = 6
	p.lifetime = 1.0
	p.explosiveness = 0.6
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.2
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = HeartTexture
	quad.material = mat
	p.mesh = quad
	return _start(p, pos)


static func sparkles(parent: Node, color: Color) -> CPUParticles3D:
	## Постоянные искры вокруг редкой еды (спек 2.8).
	var p := _particles(parent, "Sparkles", false)
	p.amount = 8
	p.lifetime = 1.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.25
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.015
	p.scale_amount_max = 0.03
	p.color = color
	p.mesh = _sphere_mesh()
	return _start(p)


static func trail(parent: Node, color: Color, amount := 10) -> CPUParticles3D:
	## Шлейф за осой/велосипедом: частицы остаются в мире (local_coords = false).
	var p := _particles(parent, "Trail", false)
	p.amount = amount
	p.lifetime = 0.6
	p.local_coords = false
	p.direction = Vector3.DOWN
	p.spread = 40.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.02
	p.scale_amount_max = 0.04
	p.color = color
	p.mesh = _sphere_mesh()
	return _start(p)


static func zzz(parent: Node, pos: Vector3) -> Label3D:
	## «z» над спящей собакой: всплывает 1,2 с и исчезает.
	var z := Label3D.new()
	z.name = "Zzz"
	z.add_to_group("fx")
	z.text = "z"
	z.font_size = 48
	z.pixel_size = 0.004
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.modulate = Color("#394151")
	parent.add_child(z)
	z.global_position = pos
	var tw := z.create_tween()
	tw.tween_property(z, "global_position", pos + Vector3(0.15, 0.35, 0), 1.2)
	tw.parallel().tween_property(z, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tw.tween_callback(z.queue_free)
	return z


static func leaves(parent: Node, extents := Vector3(15, 3, 15)) -> CPUParticles3D:
	## Листья по ветру над двором: медленный дрейф, вращение, 40 штук на 8 с.
	var p := _particles(parent, "Leaves", false)
	p.amount = 40
	p.lifetime = 8.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(1, -0.2, 0.3)
	p.spread = 20.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, -0.15, 0)
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.07
	p.color = Color("#A9B087")
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 0.6)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	p.mesh = quad
	_start(p)
	p.position = Vector3(0, 2.0, 0)
	return p

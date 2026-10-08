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
	p.one_shot = true
	p.emitting = false
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
	p.finished.connect(p.queue_free)
	return p

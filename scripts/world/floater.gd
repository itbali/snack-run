class_name Floater
extends AnimatableBody3D
## Качающаяся опора в воде — лодка или бочка (спек порта, раздел 2): подъём ±amp, крен ±roll_deg вокруг продольной оси,
## период period, сдвиг фазы phase. Кот стоит на ней: AnimatableBody3D с sync_to_physics переносит его вместе с собой.

@export var amp := 0.12
@export var roll_deg := 6.0
@export var period := 3.5
@export var phase := 0.0
@export var solid := true   # false — декоративная опора (буёк), без коллизии
var base: Transform3D
var _t := 0.0


static func offset_at(t: float, a: float, roll: float, p: float, ph: float) -> Vector2:
	## (подъём в метрах, крен в градусах) в момент t; крен опережает подъём на четверть периода.
	var w := TAU * t / p + ph
	return Vector2(a * sin(w), roll * cos(w))


func _ready() -> void:
	add_to_group("floaters")
	collision_layer = Layers.WORLD if solid else 0
	collision_mask = 0
	sync_to_physics = true
	base = transform


func _physics_process(delta: float) -> void:
	_t += delta
	var o := offset_at(_t, amp, roll_deg, period, phase)
	transform = Transform3D(base.basis * Basis(Vector3.BACK, deg_to_rad(o.y)), base.origin + Vector3(0, o.x, 0))

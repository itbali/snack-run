class_name Sprinkler
extends Node3D
## Дождеватель газона (спек этапа 2, раздел 3): цикл 20 с — 11 с стоит, 1 с булькает (предупреждение),
## 8 с поливает круг радиусом RADIUS. Кот под струёй мокнет (замедление, без урона). Работает и ночью.

const CYCLE := 20.0
const WARN_AT := 11.0
const ON_AT := 12.0
const RADIUS := 2.0
const WET_TIME := 4.0
const WATER := Color("#9FD3F0")

@export var time := 0.0          # сдвиг фазы задаёт раскладка, чтобы зоны не работали синхронно
var phase: StringName = &"off"
var _spray: CPUParticles3D
var _bubbles: CPUParticles3D

@onready var _zone: Area3D = $Zone
@onready var _model: Node3D = $Model


static func phase_at(t: float) -> StringName:
	var w := fposmod(t, CYCLE)
	if w >= ON_AT:
		return &"on"
	if w >= WARN_AT:
		return &"warn"
	return &"off"


func configure(hz: Dictionary, _builder: Node3D) -> void:
	time = float(hz.get("offset", 0.0))


func _ready() -> void:
	add_to_group("hazards")
	_zone.collision_layer = Layers.AREA
	_zone.collision_mask = Layers.CAT
	_zone.monitorable = false
	Toon.apply(_model, Toon.OUTLINE_FOOD)
	_spray = Effects.trail(self, WATER, 60)
	_spray.name = "Spray"
	_spray.local_coords = true
	_spray.direction = Vector3.UP
	_spray.spread = 75.0
	_spray.initial_velocity_min = 3.0
	_spray.initial_velocity_max = 4.2
	_spray.gravity = Vector3(0, -9.0, 0)
	_spray.lifetime = 0.9
	_spray.position = Vector3(0, 0.16, 0)
	_spray.emitting = false
	_bubbles = Effects.trail(self, WATER, 10)
	_bubbles.name = "Bubbles"
	_bubbles.local_coords = true
	_bubbles.direction = Vector3.UP
	_bubbles.spread = 20.0
	_bubbles.initial_velocity_min = 0.3
	_bubbles.initial_velocity_max = 0.6
	_bubbles.position = Vector3(0, 0.16, 0)
	_bubbles.emitting = false


func _physics_process(delta: float) -> void:
	time += delta
	var p := phase_at(time)
	if p != phase:
		phase = p
		_spray.emitting = phase == &"on"
		_bubbles.emitting = phase == &"warn"
		if phase == &"warn":
			Sfx.play_at(&"sprinkle", global_position, 0.1)
	if phase == &"on":
		for body in _zone.get_overlapping_bodies():
			if body.is_in_group("cat") and body.has_method("wet") and not bool(body.get("hidden")):
				body.call("wet", WET_TIME)

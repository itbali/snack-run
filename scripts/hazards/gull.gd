class_name Gull
extends Node3D
## Чайка (спек порта, раздел 3): кружит на 4 м радиусом 3–4 м; кот с едой ближе 6 м по горизонтали — 1 с тень и крик,
## затем бросок в точку, где был кот: удар и последняя еда унесена; перерыв 8 с; ночью спит на насесте.

const DIVE_DIST := 6.0
const COOLDOWN := 8.0


static func decide(dist_h: float, has_food: bool, hidden: bool, safe: bool, cooldown: float, night: bool) -> bool:
	return not night and not hidden and not safe and has_food and cooldown <= 0.0 and dist_h < DIVE_DIST

const HEIGHT := 4.0
const RADIUS := 3.5
const ANGULAR := 0.9
const WARN := 1.0
const DIVE := 0.45
const RISE := 1.2
const STRIKE := 0.9

var mode: StringName = &"circle"   # circle | warn | dive | rise | sleep
var cooldown_left := 0.0
var perch_h := 0.0   # высота насеста над якорем (тумба, фонарь): ночью спит там (спек: на столбах)
var anchor: Vector3
var ground := 0.0
var _anchored := false
var _angle := 0.0
var _t := 0.0
var _target := Vector3.ZERO
var _from := Vector3.ZERO

@onready var _model: Node3D = $Model
@onready var _shadow: MeshInstance3D = $Shadow
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	_angle = float(hz.get("phase", 0.0))
	perch_h = float(hz.get("perch_h", 0.0))


func _ready() -> void:
	add_to_group("hazards")
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["flap", "idle"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_play(&"flap")


func _play(clip: StringName) -> void:
	if _anim and _anim.has_animation(clip) and _anim.current_animation != clip:
		_anim.play(clip, 0.2)


func _cat() -> Node3D:
	return get_tree().get_first_node_in_group("cat") as Node3D


func _physics_process(delta: float) -> void:
	if not _anchored:
		anchor = global_position   # насест: позицию ставит WorldBuilder до add_child, тест — до add_child
		ground = Terrain.surface_height(get_tree(), anchor.x, anchor.z, anchor.y)
		_anchored = true
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	_t += delta
	var night := DayNight.is_night(get_tree())
	var c := _cat()
	match mode:
		&"sleep":
			if not night:
				mode = &"circle"
				_play(&"flap")
			return
		&"circle":
			if night:
				mode = &"sleep"
				global_position = anchor + Vector3(0, perch_h, 0)
				_shadow.visible = false
				_play(&"idle")
				return
			_angle += ANGULAR * delta
			var p := Vector3(anchor.x + cos(_angle) * RADIUS, ground + HEIGHT + sin(_t * 2.0) * 0.1, anchor.z + sin(_angle) * RADIUS)
			_face(p - global_position)
			global_position = p
			if c and decide(Vector2(c.global_position.x - p.x, c.global_position.z - p.z).length(), not GameState.mouth.is_empty(),
					bool(c.get("hidden")), bool(c.get("in_safe_zone")), cooldown_left, night):
				mode = &"warn"
				_t = 0.0
				_target = c.global_position
				_shadow.global_position = _target + Vector3(0, 0.03, 0)
				_shadow.scale = Vector3.ONE * 0.2
				_shadow.visible = true
				Sfx.play(&"gull")
		&"warn":
			_shadow.scale = Vector3.ONE * lerpf(0.2, 1.0, clampf(_t / WARN, 0.0, 1.0))   # тень растёт
			if _t >= WARN:
				mode = &"dive"
				_t = 0.0
				_from = global_position
		&"dive":
			var k := clampf(_t / DIVE, 0.0, 1.0)
			var p := _from.lerp(_target + Vector3(0, 0.3, 0), k)
			_face(p - global_position)
			global_position = p
			if k >= 1.0:
				_strike(c)
				mode = &"rise"
				_t = 0.0
				_shadow.visible = false
				cooldown_left = COOLDOWN
		&"rise":
			var back := Vector3(anchor.x + cos(_angle) * RADIUS, ground + HEIGHT, anchor.z + sin(_angle) * RADIUS)
			global_position = global_position.lerp(back, clampf(delta * 3.0, 0.0, 1.0))
			if _t >= RISE:
				mode = &"circle"


func _strike(c: Node3D) -> void:
	## Бросок в точку, где был кот: попал — удар и последняя еда унесена (остальное в зубах).
	if c == null or not c.has_method("take_peck"):
		return
	if GameState.mouth.is_empty() or DayNight.is_night(get_tree()):
		return   # за секунду предупреждения еда пропала или наступила ночь — красть нечего
	var d := c.global_position - _target
	if Vector2(d.x, d.z).length() <= STRIKE and absf(d.y) < 1.2:
		c.call("take_peck", global_position)


func _face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.001:
		rotation.y = atan2(-dir.x, -dir.z)

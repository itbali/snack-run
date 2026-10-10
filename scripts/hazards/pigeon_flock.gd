class_name PigeonFlock
extends Node3D
## Стая голубей (спек этапа 2, раздел 3): бродят и клюют у точки; у кота с едой в зубах, идущего шагом ближе
## 1,5 м, один голубь выхватывает последнюю еду и улетает (перерыв 10 с); бегущий кот разгоняет стаю на 10 с.
## Ночью спят на ветках (стаи нет). Не бьют.

const PigeonModel := preload("res://assets/models/pigeon.glb")
const COUNT := 5
const WANDER := 1.5
const STEAL_DIST := 1.5
const SCATTER_DIST := 2.5
const COOLDOWN := 10.0
const WALK := 0.35
const CREEP_DIST := 6.0
const CREEP_SPEED := 0.9
const LEASH := 3.5          # дальше от дома стая не уходит, без еды возвращается (ревью плана 21)
const HOME_SPEED := 0.6
var home := Vector3.INF

var mode: StringName = &"idle"      # idle | scattered | sleep
var cooldown_left := 0.0
var _rng := RandomNumberGenerator.new()
var _targets: Array[Vector3] = []
var _fly: Array[float] = []          # >0 — голубь в полёте (секунды до возвращения)


static func decide(dist: float, running: bool, mouth: int, hidden: bool, safe: bool, cooldown: float, night: bool) -> StringName:
	if night or hidden or safe:
		return &"none"
	if running and dist < SCATTER_DIST:
		return &"scatter"
	if cooldown <= 0.0 and mouth > 0 and dist < STEAL_DIST:
		return &"steal"
	return &"none"


func configure(_hz: Dictionary, _builder: Node3D) -> void:
	pass


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	for i in COUNT:
		var p := PigeonModel.instantiate() as Node3D
		p.name = "Pigeon%d" % i
		add_child(p)
		p.position = _random_spot()
		p.rotation.y = _rng.randf_range(0.0, TAU)
		Toon.apply(p, Toon.OUTLINE_CHARACTER, true)
		_targets.append(_random_spot())
		_fly.append(0.0)
		_play(p, "idle")


func pigeons() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for c in get_children():
		if String(c.name).begins_with("Pigeon"):
			out.append(c)
	return out


func _random_spot() -> Vector3:
	var a := _rng.randf_range(0.0, TAU)
	var r := _rng.randf_range(0.2, WANDER)
	return Vector3(cos(a) * r, 0.0, sin(a) * r)


func _play(p: Node3D, clip: String) -> void:
	var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(clip):
		ap.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		if ap.current_animation != clip:
			ap.play(clip)


func _physics_process(delta: float) -> void:
	var night := DayNight.is_night(get_tree())
	visible = not night
	if night:
		mode = &"sleep"
		return
	if mode == &"sleep":
		mode = &"idle"
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	var cat := get_tree().get_first_node_in_group("cat") as Node3D
	if cat:
		var d := Vector2(cat.global_position.x - global_position.x, cat.global_position.z - global_position.z).length()
		var action := decide(d, cat.get("state") == &"run", GameState.mouth.size(), bool(cat.get("hidden")),
			bool(cat.get("in_safe_zone")), cooldown_left, night)
		if action == &"steal":
			_steal()
		elif action == &"scatter" and mode != &"scattered":
			_scatter()
	if mode == &"scattered" and cooldown_left <= 0.0:
		mode = &"idle"
	if home == Vector3.INF:
		home = global_position
	var crept := false
	if cat and mode == &"idle" and not GameState.mouth.is_empty() and cooldown_left <= 0.0 and cat.get("state") != &"run" \
			and not bool(cat.get("hidden")) and not bool(cat.get("in_safe_zone")):
		var to := cat.global_position - global_position
		to.y = 0.0
		if to.length() < CREEP_DIST and to.length() > 1.0:
			var next := global_position + to.normalized() * CREEP_SPEED * delta   # стая подбирается к коту с едой (план 21)
			var off := Vector2(next.x - home.x, next.z - home.z)
			if off.length() > LEASH:
				off = off.normalized() * LEASH
			global_position = Vector3(home.x + off.x, global_position.y, home.z + off.y)
			crept = true
	if not crept:
		var back := Vector3(home.x - global_position.x, 0, home.z - global_position.z)
		if back.length() > 0.05:
			global_position += back.normalized() * minf(HOME_SPEED * delta, back.length())
	if global_position.distance_to(home) > 0.01:
		global_position.y = Terrain.surface_height(get_tree(), global_position.x, global_position.z, home.y)
	_move_birds(delta)


func _steal() -> void:
	if GameState.steal_last() == null:
		return
	cooldown_left = COOLDOWN
	Sfx.play_at(&"coo", global_position, 0.15)
	var ps := pigeons()
	if not ps.is_empty():
		_fly[_rng.randi_range(0, ps.size() - 1)] = COOLDOWN


func _scatter() -> void:
	mode = &"scattered"
	cooldown_left = COOLDOWN
	Sfx.play_at(&"coo", global_position, 0.2)
	for i in _fly.size():
		_fly[i] = COOLDOWN


func _move_birds(delta: float) -> void:
	var ps := pigeons()
	for i in ps.size():
		var p := ps[i]
		if _fly[i] > 0.0:
			_fly[i] = maxf(_fly[i] - delta, 0.0)
			_play(p, "flap")
			var up := 3.0 if _fly[i] > COOLDOWN * 0.5 else -3.0   # взлёт, потом возвращение
			p.position += (Vector3(p.position.x, 0, p.position.z).normalized() * 1.5 + Vector3(0, up, 0)) * delta
			p.position.y = clampf(p.position.y, 0.0, 8.0)
			if _fly[i] <= 0.0:
				p.position = _random_spot()
			continue
		_play(p, "idle")
		var to := _targets[i] - p.position
		to.y = 0.0
		if to.length() < 0.05:
			_targets[i] = _random_spot()
		else:
			var step := to.normalized() * minf(WALK * delta, to.length())
			p.position += step
			p.rotation.y = lerp_angle(p.rotation.y, atan2(-to.x, -to.z), 6.0 * delta)
